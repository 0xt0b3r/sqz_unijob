Config                            = {}
Config.DrawDistance               = 100.0
--JobConfig
Config.Jobs						  = {} 
Config.MaxInService               = -1
Config.Locale                     = 'en'
Config.BlacklistedF6jobs          = {'police', 'unemployed'}
Config.WhitelistedJobs			  = {'sandy_mechanic'}
Config.UseAnimations			  = true -- Enables/Diasbles animations for fixing vehicle, writing bills and etc. ...
Config.UseMythic_Progressbar	  = true -- Enables/Diasbles opening Mythic progress bar while doing an animation
Config.NeedItemCuffs			  = true -- Enables/Diasbles requirement of handcuffs as item
Config.UseLegacyFuel			  = false -- If true, your vehicle after taking it from garage will have 100%fuel (requires LegacyFuel script)
Config.EnableLicenses			  = true
Config.MenuAlign 				  = 'top-left' -- Position of ESX Menu

--Blips
Config.Blips = {
	sandy_mechanic = {
		BlipCoords = vector3(1729.84, 3700.28, 39.38),
		Sprite = 104,
		Display = 4,
		Scale = 1.0,
		Color = 2,
		Name = 'Sandy Mechanic'
	}
}

Config.Jobs.sandy_mechanic = {
	Zones = {
		Armory = {
			Pos = {x = 1737.55, y = 3709.25, z = 34.13},
			Size = {x = 0.7, y = 0.7, z = 0.7},
			Color = {r = 204, g = 204, b = 0},
			Marker = 22,
			Type = 'Armory',
			MotionText = _U('armory_open'),
			BuyWeapon = true,
			BuyWeaponGrade = 0,
			GetWeaponGrade = 0,
			GetStockGrade = 0,
		},	  	
	Cloakroom = {
			Pos = {x = 1743, y = 1743.3, z = 34.19},
			Size = {x = 0.7, y = 0.7, z = 0.7},
			Color = {r = 204, g = 204, b = 0},
			Marker = 22,
			Type = 'Cloakroom',
			MotionText = _U('cloakroom_open'),
		},
	BossActions = {
			Pos = {x = 1732.47, y = 3716.52, z = 34.11},
			Size = {x = 0.7, y = 0.7, z = 0.7},
			Color = {r = 204, g = 204, b = 0},
			Marker = 22,
			Type = 'BossActions',
			MotionText = _U('bossmenu_open'),
	},
	Vehicles = {
			Pos = {x = 1723.49, y = 3705.44, z = 34.18},
			Size = {x = 0.7, y = 0.7, z = 0.7},
			Color = {r = 204, g = 204, b = 0},
			Marker = 36,
			MotionText = _U('vehicles_open'),
			Type = 'Vehicles',
			SpawnPoints = {
					{coords = vector3(1722.02, 3713.56, 34.22), heading = 90.0, radius = 6.0},
					{coords = vector3(1726.88, 3716.97, 34.13), heading = 90.0, radius = 6.0}
		}
		},	
	VehicleDeletePoint = {
			Pos = {x = 1731.5, y = 3709.37, z = 33.28},
			Size = {x = 3.5, y = 3.5, z = 1.0},
			Color = {r = 255, g = 0, b = 0},
			Marker = 1,
			Type = 'VehicleDeleter',
			MotionText = _U('vehicles_open_park'),	
		},			
	HeliSpawn = {
		Pos = {x = 463.45, y = -982.62, z = 43.69},
		Size = {x = 0.7, y = 0.7, z = 0.7},
		Color = {r = 204, g = 204, b = 0},
		Marker = 36,
		MotionText = _U('aircrafts_open'),
		Type = 'Aircrafts',
		SpawnPoints = {
				{coords = vector3(449.84, -981.04, 43.69), heading = 93.96, radius = 6.0}
	}
	},
}
}

Config.AuthorizedVehicles = {
	sandy_mechanic = {
		{
        model = 'flatbed',
	    label = 'Flatbed'
		},
		{
        model = 'towtruck',
	    label = 'TowTruck'
		}														
	}
}

Config.AllowedActions = {
	sandy_mechanic = {
		HasMechanicActions = true,
		HasBodyActions = true,
		CanRevive = true,
		CanWash = true,
	}
}

Config.AuthorizedWeapons = {
	sandy_mechanic = {
		{weapon = 'WEAPON_APPISTOL', components = {0, 0, 1000, 4000, nil}, price = 10000},
		{weapon = 'WEAPON_NIGHTSTICK', price = 0},
		{weapon = 'WEAPON_STUNGUN', price = 1500},
		{weapon = 'WEAPON_FLASHLIGHT', price = 80}		
	}
}

Config.AuthorizedAirCrafts = {
	sandy_mechanic = {
		{
		model = 'maverick',
		label = 'maverick'
		},		
	}
}