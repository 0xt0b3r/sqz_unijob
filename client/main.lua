local CurrentActionData, handcuffTimer, dragStatus, blipsCops, currentTask = {}, {}, {}, {}, {}
local HasAlreadyEnteredMarker, isBussy, isHandcuffed, hasAlreadyJoined, playerInService = false, false, false, false, false
local LastStation, LastPart, LastPartNum, LastEntity, CurrentAction, CurrentActionMsg
dragStatus.isDragged, isInShopMenu = false, false
local CurrentlyTowedVehicle = nil
ESX = nil

Citizen.CreateThread(function()
	while ESX == nil do
		TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
		Citizen.Wait(0)
	end

	while ESX.GetPlayerData().job == nil do
		Citizen.Wait(10)
	end

	ESX.PlayerData = ESX.GetPlayerData()
end)

Citizen.CreateThread(function()
	for k,v in pairs(Config.Blips) do
		local blip = AddBlipForCoord(v.BlipCoords)
		SetBlipSprite (blip, v.Sprite)
		SetBlipDisplay(blip, v.Display)
		SetBlipScale  (blip, v.Scale)
		SetBlipColour (blip, v.Colour)
		SetBlipAsShortRange(blip, true)

		BeginTextCommandSetBlipName('STRING')
		AddTextComponentSubstringPlayerName(v.Name)
		EndTextCommandSetBlipName(blip)
	end
end)

function OpenCloakRoomMenu()
	ESX.TriggerServerCallback('esx_eden_clotheshop:getPlayerDressing', function(dressing)
          local elements = {}

          for i=1, #dressing, 1 do
            table.insert(elements, {label = dressing[i], value = i})
          end

          ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'player_dressing', {
              title    = _U('player_clothes'),
              align    = Config.MenuAlign,
              elements = elements,
            }, function(data, menu)

              TriggerEvent('skinchanger:getSkin', function(skin)

                ESX.TriggerServerCallback('esx_eden_clotheshop:getPlayerOutfit', function(clothes)

                  TriggerEvent('skinchanger:loadClothes', skin, clothes)
                  TriggerEvent('esx_skin:setLastSkin', skin)

                  TriggerEvent('skinchanger:getSkin', function(skin)
                    TriggerServerEvent('esx_skin:save', skin)
                  end)
				  
				  ESX.ShowNotification(_U('loaded_outfit'))
				  HasLoadCloth = true
                end, data.current.value)
              end)
            end, function(data, menu)
              menu.close()
			  
			  CurrentAction     = 'menu_cloakroom'
			  CurrentActionData = {}
            end
          )
        end)
end

function OpenBuyWeaponsMenu()
	local elements = {}
	local playerPed = PlayerPedId()

	for k,v in ipairs(Config.AuthorizedWeapons[ESX.PlayerData.job.name]) do
		local weaponNum, weapon = ESX.GetWeapon(v.weapon)
		local components, label = {}
		local hasWeapon = HasPedGotWeapon(playerPed, GetHashKey(v.weapon), false)

		if v.components then
			for i=1, #v.components do
				if v.components[i] then
					local component = weapon.components[i]
					local hasComponent = HasPedGotWeaponComponent(playerPed, GetHashKey(v.weapon), component.hash)

					if hasComponent then
						label = ('%s: <span style="color:green;">%s</span>'):format(component.label, _U('armory_owned'))
					else
						if v.components[i] > 0 then
							label = ('%s: <span style="color:green;">%s</span>'):format(component.label, _U('armory_item', ESX.Math.GroupDigits(v.components[i])))
						else
							label = ('%s: <span style="color:green;">%s</span>'):format(component.label, _U('armory_free'))
						end
					end

					table.insert(components, {
						label = label,
						componentLabel = component.label,
						hash = component.hash,
						name = component.name,
						price = v.components[i],
						hasComponent = hasComponent,
						componentNum = i
					})
				end
			end
		end

		if hasWeapon and v.components then
			label = ('%s: <span style="color:green;">></span>'):format(weapon.label)
		elseif hasWeapon and not v.components then
			label = ('%s: <span style="color:green;">%s</span>'):format(weapon.label, _U('armory_owned'))
		else
			if v.price > 0 then
				label = ('%s: <span style="color:green;">%s</span>'):format(weapon.label, _U('armory_item', ESX.Math.GroupDigits(v.price)))
			else
				label = ('%s: <span style="color:green;">%s</span>'):format(weapon.label, _U('armory_free'))
			end
		end

		table.insert(elements, {
			label = label,
			weaponLabel = weapon.label,
			name = weapon.name,
			components = components,
			price = v.price,
			hasWeapon = hasWeapon
		})
	end

	ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'armory_buy_weapons', {
		title    = _U('armory_weapontitle'),
		align    = Config.MenuAlign,
		elements = elements
	}, function(data, menu)
		if data.current.hasWeapon then
			if #data.current.components > 0 then
				OpenWeaponComponentShop(data.current.components, data.current.name, menu)
			end
		else
			ESX.TriggerServerCallback('sqz_jobs:buyWeapon', function(bought)
				if bought then
					if data.current.price > 0 then
						ESX.ShowNotification(_U('armory_bought', data.current.weaponLabel, ESX.Math.GroupDigits(data.current.price)))
					end

					menu.close()
					OpenBuyWeaponsMenu()
				else
					ESX.ShowNotification(_U('armory_money'))
				end
			end, data.current.name, 1)
		end
	end, function(data, menu)
		menu.close()
	end)
end

function OpenWeaponComponentShop(components, weaponName, parentShop)
	ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'armory_buy_weapons_components', {
		title    = _U('armory_componenttitle'),
		align    = Config.MenuAlign,
		elements = components
	}, function(data, menu)
		if data.current.hasComponent then
			ESX.ShowNotification(_U('armory_hascomponent'))
		else
			ESX.TriggerServerCallback('sqz_jobs:buyWeapon', function(bought)
				if bought then
					if data.current.price > 0 then
						ESX.ShowNotification(_U('armory_bought', data.current.componentLabel, ESX.Math.GroupDigits(data.current.price)))
					end

					menu.close()
					parentShop.close()
					OpenBuyWeaponsMenu()
				else
					ESX.ShowNotification(_U('armory_money'))
				end
			end, weaponName, 2, data.current.componentNum)
		end
	end, function(data, menu)
		menu.close()
	end)
end

function OpenPutStocksMenu()
	ESX.TriggerServerCallback('sqz_jobs:getPlayerInventory', function(inventory)
		local elements = {}

		for i=1, #inventory.items, 1 do
			local item = inventory.items[i]

			if item.count > 0 then
				table.insert(elements, {
					label = item.label .. ' x' .. item.count,
					type = 'item_standard',
					value = item.name
				})
			end
		end

		ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'stocks_menu', {
			title    = _U('inventory'),
			align    = Config.MenuAlign,
			elements = elements
		}, function(data, menu)
			local itemName = data.current.value

			ESX.UI.Menu.Open('dialog', GetCurrentResourceName(), 'stocks_menu_put_item_count', {
				title = _U('quantity')
			}, function(data2, menu2)
				local count = tonumber(data2.value)
				print(count)
				if not count then
					ESX.ShowNotification(_U('quantity_invalid'))
				else
					menu2.close()
					menu.close()
					TriggerServerEvent('sqz_jobs:putStockItems', itemName, count)

					Citizen.Wait(300)
					OpenPutStocksMenu()
				end
			end, function(data2, menu2)
				menu2.close()
			end)
		end, function(data, menu)
			menu.close()
		end)
	end)
end

function OpenGetWeaponMenu()
	ESX.TriggerServerCallback('sqz_jobs:getArmoryWeapons', function(weapons)
		local elements = {}

		for i=1, #weapons, 1 do
			if weapons[i].count > 0 then
				table.insert(elements, {
					label = 'x' .. weapons[i].count .. ' ' .. ESX.GetWeaponLabel(weapons[i].name),
					value = weapons[i].name
				})
			end
		end

		ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'armory_get_weapon', {
			title    = _U('get_weapon_menu'),
			align    = Config.MenuAlign,
			elements = elements
		}, function(data, menu)
			menu.close()

			ESX.TriggerServerCallback('sqz_jobs:removeArmoryWeapon', function()
				OpenGetWeaponMenu()
			end, data.current.value)
		end, function(data, menu)
			menu.close()
		end)
	end)
end

function OpenGetStocksMenu()
	ESX.TriggerServerCallback('sqz_jobs:getStockItems', function(items)
		local elements = {}

		for i=1, #items, 1 do
			table.insert(elements, {
				label = 'x' .. items[i].count .. ' ' .. items[i].label,
				value = items[i].name
			})
		end

		ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'stocks_menu', {
			title    = _U('stock'),
			align    = Config.MenuAlign,
			elements = elements
		}, function(data, menu)
			local itemName = data.current.value

			ESX.UI.Menu.Open('dialog', GetCurrentResourceName(), 'stocks_menu_get_item_count', {
				title = _U('quantity')
			}, function(data2, menu2)
				local count = tonumber(data2.value)

				if not count then
					ESX.ShowNotification(_U('quantity_invalid'))
				else
					menu2.close()
					menu.close()
					TriggerServerEvent('sqz_jobs:getStockItem', itemName, count)

					Citizen.Wait(300)
					OpenGetStocksMenu()
				end
			end, function(data2, menu2)
				menu2.close()
			end)
		end, function(data, menu)
			menu.close()
		end)
	end)
end

function OpenPutWeaponMenu()
	local elements   = {}
	local playerPed  = PlayerPedId()
	local weaponList = ESX.GetWeaponList()

	for i=1, #weaponList, 1 do
		local weaponHash = GetHashKey(weaponList[i].name)

		if HasPedGotWeapon(playerPed, weaponHash, false) and weaponList[i].name ~= 'WEAPON_UNARMED' then
			table.insert(elements, {
				label = weaponList[i].label,
				value = weaponList[i].name
			})
		end
	end

	ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'armory_put_weapon', {
		title    = _U('put_weapon_menu'),
		align    = Config.MenuAlign,
		elements = elements
	}, function(data, menu)
		menu.close()

		ESX.TriggerServerCallback('sqz_jobs:addArmoryWeapon', function()
			OpenPutWeaponMenu()
		end, data.current.value, true)
	end, function(data, menu)
		menu.close()
	end)
end

function OpenArmoryMenu(station)
	local elements = {
		{label = _U('put_weapon'), value = 'put_weapon'},
		{label = _U('deposit_object'), value = 'put_stock'}
	}

	if Config.Jobs[ESX.PlayerData.job.name].Zones[station].BuyWeapon and ESX.PlayerData.job.grade >= Config.Jobs[ESX.PlayerData.job.name].Zones[station].BuyWeaponGrade then
		table.insert(elements, {label = _U('buy_weapon'),     value = 'buy_weapons'})
	end

	if ESX.PlayerData.job.grade >= Config.Jobs[ESX.PlayerData.job.name].Zones[station].GetWeaponGrade then
		table.insert(elements, {label = _U('get_weapon'),     value = 'get_weapon'})
	end

	if ESX.PlayerData.job.grade >= Config.Jobs[ESX.PlayerData.job.name].Zones[station].GetStockGrade then
		table.insert(elements, {label = _U('get_stock'),     value = 'get_stock'})
	end		

	ESX.UI.Menu.CloseAll()

	ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'armory', {
		title    = _U('armory'),
		align    = Config.MenuAlign,
		elements = elements
	}, function(data, menu)

		if data.current.value == 'get_weapon' then
			OpenGetWeaponMenu()
		elseif data.current.value == 'put_weapon' then
			OpenPutWeaponMenu()
		elseif data.current.value == 'buy_weapons' then
			OpenBuyWeaponsMenu()
		elseif data.current.value == 'put_stock' then
			OpenPutStocksMenu()
		elseif data.current.value == 'get_stock' then
			OpenGetStocksMenu()
		end

	end, function(data, menu)
		menu.close()

		CurrentAction     = 'menu_armory'
		CurrentActionMsg  = _U('open_armory')
		CurrentActionData = {station = station}
	end)
end

Citizen.CreateThread(function()
	while true do
		Citizen.Wait(0)
			if ESX.PlayerData.job ~= nil and ESX.PlayerData.job.name ~= 'unemployed' then
			local playerCoords = GetEntityCoords(PlayerPedId())
			local isInMarker, hasExited, letSleep = false, false, true
			local currentZoneIndex, currentPart, currentPartNum
			local zones = nil
			for _, wljobs in pairs(Config.WhitelistedJobs) do
				if ESX.PlayerData.job.name == wljobs then
				zones = Config.Jobs[ESX.PlayerData.job.name].Zones
				end
			if ESX.PlayerData.job.name == wljobs then
			for k,v in pairs(zones) do
				local distance = GetDistanceBetweenCoords(playerCoords, v.Pos.x, v.Pos.y, v.Pos.z, true)

					if (v.Marker ~= -1 and distance < Config.DrawDistance) then
						letSleep = false
						DrawMarker(v.Marker, v.Pos.x, v.Pos.y, v.Pos.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, v.Size.x, v.Size.y, v.Size.z, v.Color.r, v.Color.g, v.Color.b, 100, false, true, 2, false, nil, nil, false)
						local distance = GetDistanceBetweenCoords(playerCoords, v.Pos.x, v.Pos.y, v.Pos.z, true)
						if distance <= 2.5  then
						DrawText3Ds(v.Pos.x, v.Pos.y, v.Pos.z + 0.3, tostring(v.MotionText))
						end
					end
				if distance < v.Size.x then
					letSleep, isInMarker, currentZone, currentZoneIndex = false, true, v, k
					break
				end
			end
			end
			end

			if isInMarker and not HasAlreadyEnteredMarker or (isInMarker and (LastStation ~= currentStation or LastPart ~= currentPart or LastPartNum ~= currentPartNum)) then
				if
					(LastStation and LastPart and LastPartNum) and
					(LastStation ~= currentStation or LastPart ~= currentPart or LastPartNum ~= currentPartNum)
				then
					TriggerEvent('sqz_jobs:hasExitedMarker', LastStation, LastPart, LastPartNum)
					hasExited = true
				end

				HasAlreadyEnteredMarker = true
				LastStation             = currentStation
				LastPart                = currentPart
				LastPartNum             = currentPartNum

				TriggerEvent('sqz_jobs:hasEnteredMarker', currentZoneIndex, currentZone, currentPartNum)
			end

			if not hasExited and not isInMarker and HasAlreadyEnteredMarker then
				HasAlreadyEnteredMarker = false
				TriggerEvent('sqz_jobs:hasExitedMarker', LastStation, LastPart, LastPartNum)
			end

			if letSleep then
				Citizen.Wait(500)
			end
		end
	end

end)
-- Key Controls
Citizen.CreateThread(function()
	while true do
		Citizen.Wait(0)
		if ESX.PlayerData.job ~= nil then
			if IsControlJustReleased(0, 38)  then

				if CurrentAction == 'menu_cloakroom' then
					OpenCloakRoomMenu()					
				elseif CurrentAction == 'menu_armory' then
						OpenArmoryMenu(CurrentActionData.station, CurrentActionData.partNum)
				elseif CurrentAction == 'delete_vehicle' then
					local playerPed = PlayerPedId()
					local vehicle = GetVehiclePedIsIn(playerPed)
					TaskLeaveVehicle(playerPed, vehicle, 0)
					Wait(1700)
					ESX.Game.DeleteVehicle(CurrentActionData.vehicle)
				elseif CurrentAction == 'menu_vehicle_spawner' then
					OpenVehicleSpawnerMenu(CurrentActionData.station, CurrentActionData.partNum)
				elseif CurrentAction == 'menu_heli_spawner' then
					OpenAirCraftSpawnerMenu(CurrentActionData.station, CurrentActionData.partNum)					
				elseif CurrentAction == 'menu_boss_actions' then
					ESX.UI.Menu.CloseAll()
					TriggerEvent('esx_society:openBossMenu', ESX.PlayerData.job.name, function(data, menu)
						menu.close()
						CurrentAction     = 'menu_boss_actions'
						CurrentActionData = {}
					end, { wash = Config.AllowedActions[ESX.PlayerData.job.name].CanWash }) -- disable washing money
				elseif CurrentAction == 'remove_entity' then
					DeleteEntity(CurrentActionData.entity)
				end

				CurrentAction = nil
			end
		if IsControlJustReleased(0, 167) and ESX.PlayerData.job.name ~= 'unemployed' then
			for _, blackjobs in pairs(Config.BlacklistedF6jobs) do
				if ESX.PlayerData.job.name ~= blackjobs then
				OpenF6ControlMenu()
				end
			end
		end			
	end
end
end)

function OpenF6ControlMenu()
	ESX.UI.Menu.CloseAll()
	local elements = {
			{label = _U('citizen_interaction'), value = 'citizen_interaction'},
					}
			if Config.AllowedActions[ESX.PlayerData.job.name].HasMechanicActions then
				table.insert(elements, {label = _U('vehicle_interaction'), value = 'vehicle_interaction'})
			end
			ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'f6_actions', {
				title    = _U('job_actions_menu'),
				align    = Config.MenuAlign,
				elements = elements
			}, function(data, menu)

		if data.current.value == 'citizen_interaction' then
			local elements = {
				{label = _U('billing'), value = 'billing'}
			}
			if Config.AllowedActions[ESX.PlayerData.job.name].CanRevive then
				table.insert(elements, {label = _U('revive'), value = 'revive'})
			end
			if Config.AllowedActions[ESX.PlayerData.job.name].HasBodyActions then
				table.insert(elements, {label = _U('search'), value = 'search'})
				table.insert(elements, {label = _U('handcuff'), value = 'handcuff'})
				table.insert(elements, {label = _U('un_hadncuff'), value = 'uncuff'})
				table.insert(elements, {label = _U('drag'), value = 'drag'})
				table.insert(elements, {label = _U('put_in_vehicle'), value = 'put_in_vehicle'})
				table.insert(elements, {label = _U('out_the_vehicle'), value = 'out_the_vehicle'})				
			end
			if Config.AllowedActions[ESX.PlayerData.job.name].CanRevive then
				table.insert(elements, {label = _U('revive'), value = 'revive'})
			end
			ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'citizen_interaction', {
				title    = _U('citizen_interaction'),
				align    = Config.MenuAlign,
				elements = elements
			}, function(data2, menu2)
				local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()
				local closestPlayer = PlayerPedId()
			if closestPlayer ~= -1 and closestDistance <= 3.0 then
				local action = data2.current.value
			if action == 'billing' then
						ESX.UI.Menu.Open('dialog', GetCurrentResourceName(), 'billingsqwaefwa', {
								title = _U('billing_amount')
								}, function(data, menu)
									ESX.UI.Menu.CloseAll()
						ESX.UI.Menu.Open('dialog', GetCurrentResourceName(), 'billing1507', {
								title = _U('billing_label')
								}, function(data3, menu3)
									local amount = tonumber(data.value)
									local billinglabel = data3.value
								if billinglabel == nil then
									ESX.ShowNotification(_U('billing_label_empty'))
								elseif amount == nil then
									ESX.ShowNotification(_U('billing_ammount_empty'))
								else
									menu.close()
									local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()
									if closestPlayer == -1 or closestDistance > 3.0 then
											ESX.ShowNotification(_U('no_players_near'))
										else
										local playerPed        = GetPlayerPed(-1)
											if Config.UseAnimations then
											TaskStartScenarioInPlace(playerPed, 'CODE_HUMAN_MEDIC_TIME_OF_DEATH', 0, true)
											end
											if Config.UseAnimations and not Config.UseMythic_Progressbar then
												Citizen.Wait(5000)
												ClearPedTasks(playerPed)
											end
											if Config.UseMythic_Progressbar then
											TriggerEvent("mythic_progressbar:client:progress", {
       										name = "faktura_not_fine_sqz_jobs",
        									duration = 20000,
       										label = "VYPISUJEŠ FAKTURU",
        									useWhileDead = false,
        									canCancel = false,
        									controlDisables = {
            									disableMovement = true,
            									disableCarMovement = true,
            									disableMouse = false,
            									disableCombat = true,
        										}
    										}, function(status)
											end)
											end
									ESX.UI.Menu.CloseAll()
									if Config.UseMythic_Progressbar then
                 					Citizen.Wait(5000)
									ClearPedTasks(playerPed)
									end
           				TriggerServerEvent('esx_billing:sendBill', GetPlayerServerId(closestPlayer), 'society_'..ESX.PlayerData.job.name, billinglabel, amount)
						ESX.ShowNotification(_U('bill_sent'))
						end
						end
						end, function(data, menu)
							menu.close()
						end)	
						end, function(data3, menu3)
							menu3.close()
						end)
			elseif action == 'search' then
				OpenBodySearchMenu(closestPlayer)				
			elseif action == 'handcuff' then
						local target, distance = ESX.Game.GetClosestPlayer()
						local target = GetPlayerPed()
						playerheading = GetEntityHeading(GetPlayerPed(-1))
						playerlocation = GetEntityForwardVector(PlayerPedId())
						playerCoords = GetEntityCoords(GetPlayerPed(-1))
						local target_id = GetPlayerServerId(target)
						if distance <= 2.0 then
							TriggerServerEvent('sqz_jobs:requestarrest', target_id, playerheading, playerCoords, playerlocation)
						else
							ESX.ShowNotification(_U('no_players_near'))
						end
						TriggerServerEvent('sqz_jobs:handcuff', GetPlayerServerId(closestPlayer))
			elseif action == 'uncuff' then
						local target, distance = ESX.Game.GetClosestPlayer()
						playerheading = GetEntityHeading(GetPlayerPed(-1))
						playerlocation = GetEntityForwardVector(PlayerPedId())
						playerCoords = GetEntityCoords(GetPlayerPed(-1))
						local target_id = GetPlayerServerId(target)
						if distance <= 2.0 then
							TriggerServerEvent('sqz_jobs:requestrelease', target_id, playerheading, playerCoords, playerlocation)
						else
							ESX.ShowNotification(_U('no_players_near'))
						end	
			elseif action == 'drag' then
						TriggerServerEvent('sqz_jobs:drag', GetPlayerServerId(closestPlayer))
			elseif action == 'put_in_vehicle' then
						TriggerServerEvent('sqz_jobs:putInVehicle', GetPlayerServerId(closestPlayer))
			elseif action == 'out_the_vehicle' then
						TriggerServerEvent('sqz_jobs:OutVehicle', GetPlayerServerId(closestPlayer))
			elseif action == 'revive' then	
					local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()
					local closestPlayerPed = GetPlayerPed(closestPlayer)
					local health = GetEntityHealth(closestPlayerPed)
					  if health == 0 then
					  local playerPed = GetPlayerPed(-1)
								TaskStartScenarioInPlace(playerPed, 'CODE_HUMAN_MEDIC_TEND_TO_DEAD', 0, true)
								Wait(10000)
								ClearPedTasks(playerPed)
								if GetEntityHealth(closestPlayerPed) == 0 then
								TriggerServerEvent('sqz_jobs:revive', GetPlayerServerId(closestPlayer))
								end
					 end	
			else
				ESX.ShowNotification(_U('no_players_near'))
			end
		end
		end, function(data2, menu2)
			menu2.close()
		end)
	end
	if data.current.value == 'vehicle_interaction' then
			local elements  = {}
			local playerPed = PlayerPedId()
			local vehicle = ESX.Game.GetVehicleInDirection()

			if Config.AllowedActions[ESX.PlayerData.job.name].HasMechanicActions then
				table.insert(elements, {label = _U('fix_vehicle'), value = 'fix_vehicle'})
				table.insert(elements, {label = _U('clean_vehicle'), value = 'clean_vehicle'})
				table.insert(elements, {label = _U('impound'), value = 'impound'})
				table.insert(elements, {label = _U('dep_vehicle'), value = 'dep_vehicle'})
				table.insert(elements, {label = _U('lock_pick_vehicle'), value = 'hijack_vehicle'})
			end
			ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'vehicle_interaction', {
				title    = _U('vehicle_interaction'),
				align    = Config.MenuAlign,
				elements = elements
			}, function(data2, menu2)
				local coords  = GetEntityCoords(playerPed)
				vehicle = ESX.Game.GetVehicleInDirection()
				if DoesEntityExist(vehicle) then
			if data2.current.value == 'hijack_vehicle' then
				local playerPed = PlayerPedId()
				local vehicle   = ESX.Game.GetVehicleInDirection()
				local coords    = GetEntityCoords(playerPed)
					if IsPedSittingInAnyVehicle(playerPed) then
						ESx.ShowNotification(_U('not_in_veh'))
						return
					end
					if DoesEntityExist(vehicle) then
						if not isBussy then
							isBussy = true
							if Config.UseAnimations then
							TaskStartScenarioInPlace(playerPed, 'WORLD_HUMAN_WELDING', 0, true)
							end
							if Config.UseAnimations and not Config.UseMythic_Progressbar then
								Citizen.Wait(10000)
								ClearPedTasksImmediately(playerPed)
							end
							if Config.UseMythic_Progressbar then
				    		TriggerEvent("mythic_progressbar:client:progress", {
       							name = "vehicle_hijack_unlock_sqz_jobs:11",
       							duration = 10000,
        						label = _U("unlocking_vehicle"),
        						useWhileDead = false,
        						canCancel = false,
        						controlDisables = {
            						disableMovement = true,
            						disableCarMovement = true,
            						disableMouse = false,
            						disableCombat = true,
        							}
    							}, function(status)
							end)
							end
							if Config.UseMythic_Progressbar then
								Citizen.Wait(10000)
							end
							SetVehicleDoorsLocked(vehicle, 1)
							SetVehicleDoorsLockedForAllPlayers(vehicle, false)
							ClearPedTasksImmediately(playerPed)
							ESX.ShowNotification(_U('vehicle_opened'))
							isBussy = false
						end
						end
			elseif data2.current.value == 'fix_vehicle' then
				local playerPed = PlayerPedId()
				local vehicle   = ESX.Game.GetVehicleInDirection()
				local coords    = GetEntityCoords(playerPed)
				if IsPedSittingInAnyVehicle(playerPed) then
						ESX.ShowNotification(_U('not_in_veh'))
					return
				end
			if DoesEntityExist(vehicle) then
				if not isBussy then
					isBussy = true
				if Config.UseAnimations then
				TaskStartScenarioInPlace(playerPed, 'PROP_HUMAN_BUM_BIN', 0, true)
				end
				if Config.UseAnimations and not Config.UseMythic_Progressbar then
					Citizen.Wait(10000)
					ClearPedTasksImmediately(playerPed)
				end
				if Config.UseMythic_Progressbar then
				TriggerEvent("mythic_progressbar:client:progress", {
        			name = "repair_vehicle_raw_jobs:11",
       				duration = 20000,
        			label = _U("repairing_vehicle"),
        			useWhileDead = false,
        			canCancel = false,
        				controlDisables = {
            				disableMovement = true,
            				disableCarMovement = true,
            				disableMouse = false,
            				disableCombat = true,
        					}
    				}, function(status)
				end)
				end
				if Config.UseMythic_Progressbar then
					Citizen.Wait(10000)
				end
					SetVehicleFixed(vehicle)
					SetVehicleDeformationFixed(vehicle)
					SetVehicleUndriveable(vehicle, false)
					SetVehicleEngineOn(vehicle, true, true)
					ClearPedTasksImmediately(playerPed)
					ESX.ShowNotification(_U('repaired_veh'))
					isBussy = false
			end
			end
		elseif data2.current.value == 'clean_vehicle' then
			local playerPed = PlayerPedId()
			local vehicle   = ESX.Game.GetVehicleInDirection()
			local coords    = GetEntityCoords(playerPed)

			if IsPedSittingInAnyVehicle(playerPed) then
				ESX.ShowNotification(_U('not_in_veh'))
				return
			end
			if DoesEntityExist(vehicle) then
				if not isBussy then
					isBussy = true
				if Config.UseAnimations then
				TaskStartScenarioInPlace(playerPed, 'WORLD_HUMAN_MAID_CLEAN', 0, true)
				end
				if Config.UseAnimations and not Config.UseMythic_Progressbar then
					Citizen.Wait(20000)
					ClearPedTasksImmediately(playerPed)
				end
				if Config.UseMythic_Progressbar then
				TriggerEvent("mythic_progressbar:client:progress", {
        			name = "clean_vehicle_15rwajobs:11",
        			duration = 20000,
        			label = _U("cleaning_vehicle"),
        			useWhileDead = false,
        			canCancel = false,
        			controlDisables = {
            			disableMovement = true,
            			disableCarMovement = true,
            			disableMouse = false,
            			disableCombat = true,
        			}
    				}, function(status)
					end)
				end
				if Config.UseMythic_Progressbar then
					Citizen.Wait(20000)
				end
				SetVehicleDirtLevel(vehicle, 0)
				ClearPedTasksImmediately(playerPed)
				ESX.ShowNotification(_U('veh_clean'))
				isBussy = false
			end
			end
		elseif data2.current.value == 'impound' then
			if DoesEntityExist(vehicle) then
				if not isBussy then
					isBussy = true
					ClearPedTasks(playerPed)
					DeleteObject(vehicle)
					isBussy = false
				end
			end
			Citizen.Wait(500)
		elseif data2.current.value == 'dep_vehicle' then
			local playerPed = PlayerPedId()
			local vehicle = GetVehiclePedIsIn(playerPed, true)

			local towmodel = GetHashKey('flatbed')
			local isVehicleTow = IsVehicleModel(vehicle, towmodel)

			if isVehicleTow then
				local targetVehicle = ESX.Game.GetVehicleInDirection()

				if CurrentlyTowedVehicle == nil then
					if targetVehicle ~= 0 then
						if not IsPedInAnyVehicle(playerPed, true) then
							if vehicle ~= targetVehicle then
								AttachEntityToEntity(targetVehicle, vehicle, 20, -0.5, -5.0, 1.0, 0.0, 0.0, 0.0, false, false, false, false, 20, true)
								CurrentlyTowedVehicle = targetVehicle
								ESX.ShowNotification(_U('veh_attached'))
							else
								ESX.ShowNotification(_U('can_not_self_veh'))
							end
						end
					end
				else
					AttachEntityToEntity(CurrentlyTowedVehicle, vehicle, 20, -0.5, -12.0, 1.0, 0.0, 0.0, 0.0, false, false, false, false, 20, true)
					DetachEntity(CurrentlyTowedVehicle, true, true)

					CurrentlyTowedVehicle = nil
					ESX.ShowNotification(_U('veh_attached'))
				end
			else
				ESX.ShowNotification(_U('no_veh_near'))	
			end
		else
			ESX.ShowNotification(_U('no_veh_near'))	
		end
		end
		end, function(data2, menu2)
			menu2.close()
		end)
	end
	end, function(data, menu)
		menu.close()
	end)
end

function OpenBodySearchMenu(player)
	ESX.TriggerServerCallback('sqz_jobs:getOtherPlayerData', function(data)
		local elements = {}

		for i=1, #data.accounts, 1 do
			if data.accounts[i].name == 'black_money' and data.accounts[i].money > 0 then
				table.insert(elements, {
					label    = _U('confiscate_dirty', ESX.Math.Round(data.accounts[i].money)),
					value    = 'black_money',
					itemType = 'item_account',
					amount   = data.accounts[i].money
				})

				break
			end
		end

		table.insert(elements, {label = _U('guns_label')})

		for i=1, #data.weapons, 1 do
			table.insert(elements, {
				label    = _U('confiscate_weapon', ESX.GetWeaponLabel(data.weapons[i].name), data.weapons[i].ammo),
				value    = data.weapons[i].name,
				itemType = 'item_weapon',
				amount   = data.weapons[i].ammo
			})
		end

		table.insert(elements, {label = _U('inventory_label')})

		for i=1, #data.inventory, 1 do
			if data.inventory[i].count > 0 then
				table.insert(elements, {
					label    = _U('confiscate_inv', data.inventory[i].count, data.inventory[i].label),
					value    = data.inventory[i].name,
					itemType = 'item_standard',
					amount   = data.inventory[i].count
				})
			end
		end

		ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'body_search', {
			title    = _U('search'),
			align    = Config.MenuAlign,
			elements = elements
		}, function(data, menu)
			if data.current.value then
				TriggerServerEvent('sqz_jobs:confiscatePlayerItem', GetPlayerServerId(player), data.current.itemType, data.current.value, data.current.amount)
				OpenBodySearchMenu(player)
			end
		end, function(data, menu)
			menu.close()
		end)
	end, GetPlayerServerId(player))
end

RegisterNetEvent('sqz_jobs:getarrested')
AddEventHandler('sqz_jobs:getarrested', function(playerheading, playercoords, playerlocation)
	
	playerPed = GetPlayerPed(-1)
	SetCurrentPedWeapon(playerPed, GetHashKey('WEAPON_UNARMED'), true) -- unarm player
	local x, y, z   = table.unpack(playercoords + playerlocation * 1.0)
	SetEntityCoords(GetPlayerPed(-1), x, y, z)
	SetEntityHeading(GetPlayerPed(-1), playerheading)
	Citizen.Wait(250)
	loadanimdict('mp_arrest_paired')
	TaskPlayAnim(GetPlayerPed(-1), 'mp_arrest_paired', 'crook_p2_back_right', 8.0, -8, 3750 , 2, 0, 0, 0, 0)
	Citizen.Wait(4000)
	isHandcuffed = true
	TriggerEvent('sqz_jobs:handcuff')
	loadanimdict('mp_arresting')
	TaskPlayAnim(GetPlayerPed(-1), 'mp_arresting', 'idle', 8.0, -8, -1, 49, 0.0, false, false, false)
end)

RegisterNetEvent('sqz_jobs:doarrested')
AddEventHandler('sqz_jobs:doarrested', function()
	Citizen.Wait(250)
	loadanimdict('mp_arrest_paired')
	TaskPlayAnim(GetPlayerPed(-1), 'mp_arrest_paired', 'cop_p2_back_right', 8.0, -8,3750, 2, 0, 0, 0, 0)
	Citizen.Wait(3000)

end) 

RegisterNetEvent('sqz_jobs:handcuff')
AddEventHandler('sqz_jobs:handcuff', function()
	local playerPed = PlayerPedId()
	
	if isHandcuffed then
		RequestAnimDict('mp_arresting')
		while not HasAnimDictLoaded('mp_arresting') do
			Citizen.Wait(1000)
		end

		TaskPlayAnim(playerPed, 'mp_arresting', 'idle', 8.0, -8, -1, 49, 0, 0, 0, 0)

		SetEnableHandcuffs(playerPed, true)
		DisablePlayerFiring(playerPed, true)
		DisableControlAction(0, 73, true) -- Disable clearing animation
		SetCurrentPedWeapon(playerPed, GetHashKey('WEAPON_UNARMED'), true) -- unarm player
		SetPedCanPlayGestureAnims(playerPed, false)
		--FreezeEntityPosition(playerPed, true)
		DisplayRadar(false)

	end
end)

RegisterNetEvent('raw_jobs:getuncuffed')
AddEventHandler('raw_jobs:getuncuffed', function(playerheading, playercoords, playerlocation)
	local x, y, z   = table.unpack(playercoords + playerlocation * 1.0)
	SetEntityCoords(GetPlayerPed(-1), x, y, z)
	SetEntityHeading(GetPlayerPed(-1), playerheading)
	Citizen.Wait(250)
	loadanimdict('mp_arresting')
	TaskPlayAnim(GetPlayerPed(-1), 'mp_arresting', 'b_uncuff', 8.0, -8,-1, 2, 0, 0, 0, 0)
	Citizen.Wait(5500)
	isHandcuffed = false
	ClearPedSecondaryTask(playerPed)
	SetEnableHandcuffs(playerPed, false)
	DisablePlayerFiring(playerPed, false)
	DisableControlAction(0, 73, true) -- Disable clearing animation
	SetPedCanPlayGestureAnims(playerPed, true)
	DisplayRadar(true)
	ClearPedTasks(GetPlayerPed(-1))
end)

RegisterNetEvent('sqz_jobs:douncuffing')
AddEventHandler('sqz_jobs:douncuffing', function()
	Citizen.Wait(250)
	loadanimdict('mp_arresting')
	TaskPlayAnim(GetPlayerPed(-1), 'mp_arresting', 'a_uncuff', 8.0, -8,-1, 2, 0, 0, 0, 0)
	Citizen.Wait(5500)
	ClearPedTasks(GetPlayerPed(-1))
end)

RegisterNetEvent('sqz_jobs:drag')
AddEventHandler('sqz_jobs:drag', function(playerId)
	if isHandcuffed then
		dragStatus.isDragged = not dragStatus.isDragged
		dragStatus.PlayerId = playerId
	end
end)

Citizen.CreateThread(function()
	local wasDragged

	while true do
		Citizen.Wait(0)
		local playerPed = PlayerPedId()

		if isHandcuffed and dragStatus.isDragged then
			local targetPed = GetPlayerPed(GetPlayerFromServerId(dragStatus.PlayerId))

			if DoesEntityExist(targetPed) and IsPedOnFoot(targetPed) and not IsPedDeadOrDying(targetPed, true) then
				if not wasDragged then
					AttachEntityToEntity(playerPed, targetPed, 11816, 0.54, 0.54, 0.0, 0.0, 0.0, 0.0, false, false, false, false, 2, true)
					wasDragged = true
				else
					Citizen.Wait(1000)
				end
			else
				wasDragged = false
				dragStatus.isDragged = false
				DetachEntity(playerPed, true, false)
			end
		elseif wasDragged then
			wasDragged = false
			DetachEntity(playerPed, true, false)
		else
			Citizen.Wait(500)
		end
	end
end)

RegisterNetEvent('sqz_jobs:putInVehicle')
AddEventHandler('sqz_jobs:putInVehicle', function()
	if isHandcuffed then
		local playerPed = PlayerPedId()
		local coords = GetEntityCoords(playerPed)

		if IsAnyVehicleNearPoint(coords, 5.0) then
			local vehicle = GetClosestVehicle(coords, 5.0, 0, 71)

			if DoesEntityExist(vehicle) then
				local maxSeats, freeSeat = GetVehicleMaxNumberOfPassengers(vehicle)

				for i=maxSeats - 1, 0, -1 do
					if IsVehicleSeatFree(vehicle, i) then
						freeSeat = i
						break
					end
				end

				if freeSeat then
					TaskWarpPedIntoVehicle(playerPed, vehicle, freeSeat)
					dragStatus.isDragged = false
				end
			end
		end
	end
end)
-- Handcuff
Citizen.CreateThread(function()
	while true do
		Citizen.Wait(0)
		local playerPed = PlayerPedId()

		if isHandcuffed then
			--DisableControlAction(0, 1, true) -- Disable pan
			--DisableControlAction(0, 2, true) -- Disable tilt
			DisableControlAction(0, 24, true) -- Attack
			DisableControlAction(0, 257, true) -- Attack 2
			DisableControlAction(0, 25, true) -- Aim
			DisableControlAction(0, 263, true) -- Melee Attack 1
			--DisableControlAction(0, 32, true) -- W
			--DisableControlAction(0, 34, true) -- A
			--DisableControlAction(0, 31, true) -- S
			--DisableControlAction(0, 30, true) -- D

			DisableControlAction(0, 45, true) -- Reload
			DisableControlAction(0, 22, true) -- Jump
			DisableControlAction(0, 44, true) -- Cover
			DisableControlAction(0, 37, true) -- Select Weapon
			DisableControlAction(0, 23, true) -- Also 'enter'?

			DisableControlAction(0, 288,  true) -- Disable phone
			DisableControlAction(0, 289, true) -- Inventory
			DisableControlAction(0, 170, true) -- Animations
			DisableControlAction(0, 167, true) -- Job

			DisableControlAction(0, 0, true) -- Disable changing view
			DisableControlAction(0, 26, true) -- Disable looking behind
			DisableControlAction(0, 73, true) -- Disable clearing animation
			DisableControlAction(2, 199, true) -- Disable pause screen

			DisableControlAction(0, 59, true) -- Disable steering in vehicle
			DisableControlAction(0, 71, true) -- Disable driving forward in vehicle
			DisableControlAction(0, 72, true) -- Disable reversing in vehicle

			DisableControlAction(2, 36, true) -- Disable going stealth

			DisableControlAction(0, 47, true)  -- Disable weapon
			DisableControlAction(0, 264, true) -- Disable melee
			DisableControlAction(0, 257, true) -- Disable melee
			DisableControlAction(0, 140, true) -- Disable melee
			DisableControlAction(0, 141, true) -- Disable melee
			DisableControlAction(0, 142, true) -- Disable melee
			DisableControlAction(0, 143, true) -- Disable melee
			DisableControlAction(0, 75, true)  -- Disable exit vehicle
			DisableControlAction(27, 75, true) -- Disable exit vehicle

			if IsEntityPlayingAnim(playerPed, 'mp_arresting', 'idle', 3) ~= 1 then
				ESX.Streaming.RequestAnimDict('mp_arresting', function()
					TaskPlayAnim(playerPed, 'mp_arresting', 'idle', 8.0, -8, -1, 49, 0.0, false, false, false)
				end)
			end
		else
			Citizen.Wait(500)
		end
	end
end)
RegisterNetEvent('sqz_jobs:OutVehicle')
AddEventHandler('sqz_jobs:OutVehicle', function()
	local playerPed = PlayerPedId()

	if IsPedSittingInAnyVehicle(playerPed) then
		local vehicle = GetVehiclePedIsIn(playerPed, false)
		TaskLeaveVehicle(playerPed, vehicle, 16)
	end
end)

AddEventHandler('sqz_jobs:hasEnteredMarker', function(station, zone, partNum)
	if currentZone.Type == 'Cloakroom' then
		CurrentAction     = 'menu_cloakroom'
		CurrentActionData = {}
	elseif currentZone.Type == 'Armory' then
		CurrentAction     = 'menu_armory'
		CurrentActionData = {station = station}
	elseif currentZone.Type == 'Vehicles' then
		CurrentAction     = 'menu_vehicle_spawner'
		CurrentActionData = {station = station}
	elseif currentZone.Type == 'Aircrafts' then
		CurrentAction = 'menu_heli_spawner'
		CurrentActionData = {station = station}
	elseif currentZone.Type == 'VehicleDeleter' then
		local playerPed = PlayerPedId()
		local coords    = GetEntityCoords(playerPed)
		if IsPedInAnyVehicle(playerPed,  false) then
			local vehicle = GetVehiclePedIsIn(playerPed, false)
			if DoesEntityExist(vehicle) then
				CurrentAction     = 'delete_vehicle'
				CurrentActionData = {vehicle = vehicle}
			end
		end
	elseif currentZone.Type == 'BossActions' then
		CurrentAction     = 'menu_boss_actions'
		CurrentActionData = {}
	end
end)

function DrawText3Ds(x,y,z, text)
    local onScreen,_x,_y=World3dToScreen2d(x,y,z)
    local px,py,pz=table.unpack(GetGameplayCamCoords())
    
    SetTextScale(0.5, 0.35)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    SetTextEntry("STRING")
    SetTextCentre(1)
    AddTextComponentString(text)
    DrawText(_x,_y)
    local factor = (string.len(text)) / 200
    DrawRect(_x,_y+0.0105, 0.025+ factor, 0.05, 41, 11, 41, 150)
end

function OpenVehicleSpawnerMenu(station, partNum)

	ESX.UI.Menu.CloseAll()

		local elements = {}

		local vehicles = Config.AuthorizedVehicles[ESX.PlayerData.job.name]
		for i=1, #vehicles, 1 do
			table.insert(elements, { label = vehicles[i].label, model = vehicles[i].model})
		end

		ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'vehicle_spawner',
		{
			title    = _U('vehicle_menu'),
			align    = Config.MenuAlign,
			elements = elements
		}, function(data, menu)
			menu.close()
			local foundSpawn, spawnPoint = GetAvailableVehicleSpawnPoint(station, part, partNum)
			if foundSpawn then
					ESX.Game.SpawnVehicle(data.current.model, spawnPoint.coords, spawnPoint.heading, function(vehicle)
						if Config.UseLegacyFuel then
						exports["LegacyFuel"]:SetFuel(vehicle, 100)
						end						
						TaskWarpPedIntoVehicle(PlayerPedId(), vehicle, -1)
						SetVehicleMaxMods(vehicle)
					end)
			end

		end, function(data, menu)
			menu.close()

			CurrentAction     = 'menu_vehicle_spawner'
			CurrentActionMsg  = 'Stiskni [E] pro výber vozidla'
			CurrentActionData = {station = station, partNum = partNum}
		end)

end

function OpenAirCraftSpawnerMenu(station, partNum)

		ESX.UI.Menu.CloseAll()
	
			local elements = {}
	
			local vehicles = Config.AuthorizedAirCrafts[ESX.PlayerData.job.name]
			for i=1, #vehicles, 1 do
				table.insert(elements, { label = vehicles[i].label, model = vehicles[i].model})
			end
	
			ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'helicopter_spawner',
			{
				title    = _U('helicopter_menu'),
				align    = Config.MenuAlign,
				elements = elements
			}, function(data, menu)
				menu.close()
				local foundSpawn, spawnPoint = GetAvailableVehicleSpawnPoint(station, part, partNum)
				if foundSpawn then
						ESX.Game.SpawnVehicle(data.current.model, spawnPoint.coords, spawnPoint.heading, function(vehicle)				
							TaskWarpPedIntoVehicle(PlayerPedId(), vehicle, -1)
							SetVehicleMaxMods(vehicle)
						end)
				end
	
			end, function(data, menu)
				menu.close()
	
				CurrentAction     = 'menu_heli_spawner'
				CurrentActionData = {station = station, partNum = partNum}
			end)
	
end
function GetAvailableVehicleSpawnPoint(station, part, partNum)
	local spawnPoints = Config.Jobs[ESX.PlayerData.job.name].Zones[CurrentActionData.station].SpawnPoints
	local found, foundSpawnPoint = false, nil

	for i=1, #spawnPoints, 1 do
		if ESX.Game.IsSpawnPointClear(spawnPoints[i].coords, spawnPoints[i].radius) then
			found, foundSpawnPoint = true, spawnPoints[i]
			break
		end
	end

	if found then
		return true, foundSpawnPoint
	else
		ESX.ShowNotification(_U('vehicle_blocked'))
		return false
	end
end

function SetVehicleMaxMods(vehicle)
    local props = {  }
    props = {
    modEngine       = 2,
    modBrakes       = 2,
    modTransmission = 2,
    modSuspension   = 3,
    }
    ESX.Game.SetVehicleProperties(vehicle, props)
end