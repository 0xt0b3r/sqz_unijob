ESX = nil

TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

TriggerEvent('esx_phone:registerNumber', 'sandy_mechanic', 'SandyMechanic', true, true)
TriggerEvent('esx_society:registerSociety', 'sandy_mechanic', 'SandyMechanic', 'society_sandy_mechanic', 'society_sandy_mechanic', 'society_sandy_mechanic', {type = 'public'})

RegisterServerEvent('sqz_jobs:requestarrest')
AddEventHandler('sqz_jobs:requestarrest', function(targetid, playerheading, playerCoords,  playerlocation)
    local xPlayer = ESX.GetPlayerFromId(source)
    
    if Config.NeedItemCuffs then
        local pouta = xPlayer.getInventoryItem('cuffs')
        if pouta.count >= 1 then
   	        xPlayer.removeInventoryItem('cuffs', 1)
            TriggerClientEvent('sqz_jobs:getarrested', targetid, playerheading, playerCoords, playerlocation)
            TriggerClientEvent('sqz_jobs:doarrested', source)
	    else
	        xPlayer.showNotification(_U('no_cuffs'))
        end
    else
	TriggerClientEvent('sqz_jobs:getarrested', targetid, playerheading, playerCoords, playerlocation)
    TriggerClientEvent('sqz_jobs:doarrested', source)
    end
end)

RegisterServerEvent('sqz_jobs:requestrelease')
AddEventHandler('sqz_jobs:requestrelease', function(targetid, playerheading, playerCoords,  playerlocation)
    local xPlayer = ESX.GetPlayerFromId(source)
    if Config.NeedItemCuffs then
        xPlayer.addInventoryItem('cuffs', 1)
        xPlayer.showNotification(_U('received_cuffs'))
    end
    TriggerClientEvent('sqz_jobs:getuncuffed', targetid, playerheading, playerCoords, playerlocation)
    TriggerClientEvent('sqz_jobs:douncuffing', source)
end)

RegisterNetEvent('sqz_jobs:drag')
AddEventHandler('sqz_jobs:drag', function(target)
	TriggerClientEvent('sqz_jobs:drag', target, source)
end)

RegisterNetEvent('sqz_jobs:putInVehicle')
AddEventHandler('sqz_jobs:putInVehicle', function(target)
		TriggerClientEvent('sqz_jobs:putInVehicle', target)
end)

RegisterNetEvent('sqz_jobs:OutVehicle')
AddEventHandler('sqz_jobs:OutVehicle', function(target)
	TriggerClientEvent('sqz_jobs:OutVehicle', target)
end)

RegisterServerEvent('sqz_jobs:revive')
AddEventHandler('sqz_jobs:revive', function(target)
  TriggerClientEvent('esx_ambulancejob:revive', target)
end)

ESX.RegisterServerCallback('sqz_jobs:buyWeapon', function(source, cb, weaponName, type, componentNum)
	local xPlayer = ESX.GetPlayerFromId(source)
	local authorizedWeapons, selectedWeapon = Config.AuthorizedWeapons[xPlayer.job.name]

	for k,v in ipairs(authorizedWeapons) do
		if v.weapon == weaponName then
			selectedWeapon = v
			break
		end
	end

	if not selectedWeapon then
		print(('sqz_jobs: %s attempted to buy an invalid weapon.'):format(xPlayer.identifier))
		cb(false)
	else
		-- Weapon
		if type == 1 then
			if xPlayer.getMoney() >= selectedWeapon.price then
				xPlayer.removeMoney(selectedWeapon.price)
				xPlayer.addWeapon(weaponName, 100)

				cb(true)
			else
				cb(false)
			end

		-- Weapon Component
		elseif type == 2 then
			local price = selectedWeapon.components[componentNum]
			local weaponNum, weapon = ESX.GetWeapon(weaponName)
			local component = weapon.components[componentNum]

			if component then
				if xPlayer.getMoney() >= price then
					xPlayer.removeMoney(price)
					xPlayer.addWeaponComponent(weaponName, component.name)

					cb(true)
				else
					cb(false)
				end
			else
				print(('sqz_jobs: %s attempted to buy an invalid weapon component.'):format(xPlayer.identifier))
				cb(false)
			end
		end
	end
end)

ESX.RegisterServerCallback('sqz_jobs:getStockItems', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    print('society_'..xPlayer.job.name)
	TriggerEvent('esx_addoninventory:getSharedInventory', 'society_'..xPlayer.job.name, function(inventory)
		cb(inventory.items)
	end)
end)

ESX.RegisterServerCallback('sqz_jobs:getPlayerInventory', function(source, cb)
	local xPlayer = ESX.GetPlayerFromId(source)
	local items   = xPlayer.inventory

	cb({items = items})
end)

RegisterNetEvent('sqz_jobs:putStockItems')
AddEventHandler('sqz_jobs:putStockItems', function(itemName, count, station)
	local xPlayer = ESX.GetPlayerFromId(source)
	local sourceItem = xPlayer.getInventoryItem(itemName)
	TriggerEvent('esx_addoninventory:getSharedInventory', 'society_'..xPlayer.job.name, function(inventory)
		local inventoryItem = inventory.getItem(itemName)

		-- does the player have enough of the item?
		if sourceItem.count >= count and count > 0 then
			xPlayer.removeInventoryItem(itemName, count)
			inventory.addItem(itemName, count)
			xPlayer.showNotification(_U('have_deposited', count, inventoryItem.label))
		else
			xPlayer.showNotification(_U('quantity_invalid'))
		end
	end)
end)

RegisterNetEvent('sqz_jobs:getStockItem')
AddEventHandler('sqz_jobs:getStockItem', function(itemName, count)
	local _source = source
	local xPlayer = ESX.GetPlayerFromId(_source)

	TriggerEvent('esx_addoninventory:getSharedInventory', 'society_'..xPlayer.job.name, function(inventory)
		local inventoryItem = inventory.getItem(itemName)

		-- is there enough in the society?
		if count > 0 and inventoryItem.count >= count then

			-- can the player carry the said amount of x item?
			if xPlayer.canCarryItem(itemName, count) then
				inventory.removeItem(itemName, count)
				xPlayer.addInventoryItem(itemName, count)
				xPlayer.showNotification(_U('have_withdrawn', count, inventoryItem.label))
			else
				xPlayer.showNotification(_U('quantity_invalid'))
			end
		else
			xPlayer.showNotification(_U('quantity_invalid'))
		end
	end)
end)

ESX.RegisterServerCallback('sqz_jobs:getArmoryWeapons', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
	TriggerEvent('esx_datastore:getSharedDataStore', 'society_'..xPlayer.job.name, function(store)
		local weapons = store.get('weapons')

		if weapons == nil then
			weapons = {}
		end

		cb(weapons)
	end)
end)

ESX.RegisterServerCallback('sqz_jobs:addArmoryWeapon', function(source, cb, weaponName, removeWeapon)
	local xPlayer = ESX.GetPlayerFromId(source)

	if removeWeapon then
		xPlayer.removeWeapon(weaponName)
	end
	TriggerEvent('esx_datastore:getSharedDataStore', 'society_'..xPlayer.job.name, function(store)
		local weapons = store.get('weapons') or {}
		local foundWeapon = false

		for i=1, #weapons, 1 do
			if weapons[i].name == weaponName then
				weapons[i].count = weapons[i].count + 1
				foundWeapon = true
				break
			end
		end

		if not foundWeapon then
			table.insert(weapons, {
				name  = weaponName,
				count = 1
			})
		end

		store.set('weapons', weapons)
		cb()
	end)
end)

ESX.RegisterServerCallback('sqz_jobs:removeArmoryWeapon', function(source, cb, weaponName)
	local xPlayer = ESX.GetPlayerFromId(source)
	xPlayer.addWeapon(weaponName, 500)

	TriggerEvent('esx_datastore:getSharedDataStore', 'society_'..xPlayer.job.name, function(store)
		local weapons = store.get('weapons') or {}

		local foundWeapon = false

		for i=1, #weapons, 1 do
			if weapons[i].name == weaponName then
				weapons[i].count = (weapons[i].count > 0 and weapons[i].count - 1 or 0)
				foundWeapon = true
				break
			end
		end

		if not foundWeapon then
			table.insert(weapons, {
				name = weaponName,
				count = 0
			})
		end

		store.set('weapons', weapons)
		cb()
	end)
end)

RegisterNetEvent('sqz_jobs:confiscatePlayerItem')
AddEventHandler('sqz_jobs:confiscatePlayerItem', function(target, itemType, itemName, amount)
	local _source = source
	local sourceXPlayer = ESX.GetPlayerFromId(_source)
	local targetXPlayer = ESX.GetPlayerFromId(target)

	if sourceXPlayer.job.name ~= 'police' then
		print(('sqz_jobs: %s attempted to confiscate!'):format(xPlayer.identifier))
		return
	end

	if itemType == 'item_standard' then
		local targetItem = targetXPlayer.getInventoryItem(itemName)
		local sourceItem = sourceXPlayer.getInventoryItem(itemName)

		-- does the target player have enough in their inventory?
		if targetItem.count > 0 and targetItem.count <= amount then

			-- can the player carry the said amount of x item?
			if sourceXPlayer.canCarryItem(itemName, sourceItem.count) then
				targetXPlayer.removeInventoryItem(itemName, amount)
				sourceXPlayer.addInventoryItem   (itemName, amount)
				sourceXPlayer.showNotification(_U('you_confiscated', amount, sourceItem.label, targetXPlayer.name))
				targetXPlayer.showNotification(_U('got_confiscated', amount, sourceItem.label, sourceXPlayer.name))
			else
				sourceXPlayer.showNotification(_U('quantity_invalid'))
			end
		else
			sourceXPlayer.showNotification(_U('quantity_invalid'))
		end

	elseif itemType == 'item_account' then
		targetXPlayer.removeAccountMoney(itemName, amount)
		sourceXPlayer.addAccountMoney   (itemName, amount)

		sourceXPlayer.showNotification(_U('you_confiscated_account', amount, itemName, targetXPlayer.name))
		targetXPlayer.showNotification(_U('got_confiscated_account', amount, itemName, sourceXPlayer.name))

	elseif itemType == 'item_weapon' then
		if amount == nil then amount = 0 end
		targetXPlayer.removeWeapon(itemName, amount)
		sourceXPlayer.addWeapon   (itemName, amount)

		sourceXPlayer.showNotification(_U('you_confiscated_weapon', ESX.GetWeaponLabel(itemName), targetXPlayer.name, amount))
		targetXPlayer.showNotification(_U('got_confiscated_weapon', ESX.GetWeaponLabel(itemName), amount, sourceXPlayer.name))
	end
end)

ESX.RegisterServerCallback('sqz_jobs:getOtherPlayerData', function(source, cb, target, notify)
	local xPlayer = ESX.GetPlayerFromId(target)

	if notify then
		xPlayer.showNotification(_U('being_searched'))
	end

	if xPlayer then
		local data = {
			name = xPlayer.getName(),
			job = xPlayer.job.label,
			grade = xPlayer.job.grade_label,
			inventory = xPlayer.getInventory(),
			accounts = xPlayer.getAccounts(),
			weapons = xPlayer.getLoadout()
		}
			data.dob = xPlayer.get('dateofbirth')
			data.height = xPlayer.get('height')

			if xPlayer.get('sex') == 'm' then data.sex = 'male' else data.sex = 'female' end

		TriggerEvent('esx_status:getStatus', target, 'drunk', function(status)
			if status then
				data.drunk = ESX.Math.Round(status.percent)
			end

			if Config.EnableLicenses then
				TriggerEvent('esx_license:getLicenses', target, function(licenses)
					data.licenses = licenses
					cb(data)
				end)
			else
				cb(data)
			end
		end)
	end
end)