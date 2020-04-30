# sqz_unijob

First I would like to tell you that this resource is made by me but I did not write everything by me.
##The script I editted is [esx_policejob](https://github.com/ESX-Org/esx_policejob). So lets go and use this as well :-)

Next the other things is, that this script was made, because I saw many servers having resources and jobs like:
esx_mafiajob, esx_vagosjob, esx_gangjob, esx_carteljob and these resources did not have anything more than this script
(at lease I think :-) ) and these scripts were taking about 0.46ms each and it is a lot.

This script includes basic things as: 
**handcuffing, uncuffing (with animations), draging person, searching person, putting person it/out of vehicle, revivng persons, billing, cleaning, repairing, deleting, attaching vehicles** and helicopter, vehicle spawner/deleter, config for blips, buying weapons with configuration, storage rooms (with permission config) and etc. ...

## Features overview
- Easy config and easy job adding
- Citizen interactions
- Vehicle interactions
- Revive
- Vehicle and helicopters easy configuration
- Beter optimalization the other
- 3dText instead of Help text
- Own label of billings

## Requierements
- es_extended (using weight system)
- esx_menu_default and esx_menu_dialog
- esx_society
- esx_billing
- esx_datastore
- esx_addonaccount
- esx_addoninventory

Lets see, how to install the script: *(This script was made to help beginning server which are at the start to be easy to configure)*
## Instalation:
```
1) Put sqz_unijob into your resources folder
2) Open config and add jobs info Config.Jobs:
```
### Script config:
```
Config.Jobs.sandy_mechanic = { -- This is name of job you have in your database
	Zones = {
		Armory = {
			Pos = {x = 1737.55, y = 3709.25, z = 34.13},
			Size = {x = 0.7, y = 0.7, z = 0.7},
			Color = {r = 204, g = 204, b = 0},
			Marker = 22,
			Type = 'Armory',
			MotionText = _U('armory_open'),
			BuyWeapon = true, -- This allows you to buy weapons in this Armory (if you have multiple armories and you do not want to have buy weapon in all of them, simply cahnge it to false
			BuyWeaponGrade = 0, -- This is the least grade you must have to be allowed to buy weapons ( grade 0, 1, 2, 3, 4, 5, ... is now able to buy weapons)
			GetWeaponGrade = 0, -- This is the least grade you must have to be able to withdraw weapons from the armory (at some servers I have see that somebody was stealing thing from armories :D ( grade 0, 1, 2, 3, 4, 5, ... is now able to witdraw weapons) (Everybody can deposit weapons)
			GetStockGrade = 0, -- This is the least grade you must have to be able to withdraw things from the armory (at some servers I have see that somebody was stealing thing from armories :D ( grade 0, 1, 2, 3, 4, 5, ... is now able to witdraw weapons) (Everybody can deposit weapons)
		},	  	
	Cloakroom = {
			Pos = {x = 1743, y = 1743.3, z = 34.19}, -- This is the place where you can change your saved clothes (you have to buy then in clotheshop)
			Size = {x = 0.7, y = 0.7, z = 0.7},
			Color = {r = 204, g = 204, b = 0},
			Marker = 22,
			Type = 'Cloakroom',
			MotionText = _U('cloakroom_open'),
		},
	BossActions = {
			Pos = {x = 1732.47, y = 3716.52, z = 34.11}, -- This is the place where you open BossMenu (only grade with name boss is allowed (depends on your esx_society edits)
			Size = {x = 0.7, y = 0.7, z = 0.7},
			Color = {r = 204, g = 204, b = 0},
			Marker = 22,
			Type = 'BossActions',
			MotionText = _U('bossmenu_open'),
	},
	Vehicles = {
			Pos = {x = 1723.49, y = 3705.44, z = 34.18}, -- This is the spawnpoint where you see menu with vehicles which you can spawn
			Size = {x = 0.7, y = 0.7, z = 0.7},
			Color = {r = 204, g = 204, b = 0},
			Marker = 36,
			MotionText = _U('vehicles_open'),
			Type = 'Vehicles',
			SpawnPoints = { -- Here you configure spawnpoints, where the vehicle will be spawned (Chcecks if the spawnpoint is clear), you can add as much as you want
					{coords = vector3(1722.02, 3713.56, 34.22), heading = 90.0, radius = 6.0},
					{coords = vector3(1726.88, 3716.97, 34.13), heading = 90.0, radius = 6.0}
		}
		},	
	VehicleDeletePoint = { -- here you add vehicle deleter points. It can delete helicopters, car, bikes, boats...
			Pos = {x = 1731.5, y = 3709.37, z = 33.28},
			Size = {x = 3.5, y = 3.5, z = 1.0},
			Color = {r = 255, g = 0, b = 0},
			Marker = 1,
			Type = 'VehicleDeleter',
			MotionText = _U('vehicles_open_park'),	
		},			
	HeliSpawn = { -- This is marker which opens you menu where you choose which plane you want to spawn.
		Pos = {x = 463.45, y = -982.62, z = 43.69},
		Size = {x = 0.7, y = 0.7, z = 0.7},
		Color = {r = 204, g = 204, b = 0},
		Marker = 36,
		MotionText = _U('aircrafts_open'),
		Type = 'Aircrafts',
		SpawnPoints = { -- Here you configure spawnpoints, where the vehicle will be spawned (Chcecks if the spawnpoint is clear), you can add as much as you want, smae as vehicles
				{coords = vector3(449.84, -981.04, 43.69), heading = 93.96, radius = 6.0}
	      }
	  },
    }
}
```
```
3) Configure blips you want use, lower is everything you need to set about blips
```
```
Config.Blips = {
	sandy_mechanic = {
		BlipCoords = vector3(1729.84, 3700.28, 39.38), -- Coords for the blip
		Sprite = 104, -- Blips sprite (icon on the map)
		Display = 4, -- Display
		Scale = 1.0, -- Size of the blip
		Color = 2, -- Color of the blip
		Name = 'Sandy Mechanic' -- Name of the blip
	} --Lower you can add other blips, again as much as you want :-)
}
```
```
Config.BlacklistedF6jobs          = {'police', 'unemployed'} -- These jobs wont be effected by sqz_unijob script F6 menu
Config.WhitelistedJobs			  = {'sandy_mechanic'} -- You have to add job names here to make the markers work
Config.UseAnimations			  = true -- Enables/Diasbles animations for fixing vehicle, writing bills and etc. ...
Config.UseMythic_Progressbar	  = true -- Enables/Diasbles opening Mythic progress bar while doing an animation
Config.NeedItemCuffs			  = true -- Enables/Diasbles requirement of handcuffs as item
Config.UseLegacyFuel			  = false -- If true, your vehicle after taking it from garage will have 100%fuel (requires LegacyFuel script)
Config.EnableLicenses			  = true
Config.MenuAlign 				  = 'top-left' -- Position of ESX Menu
```
```
Config.AuthorizedVehicles = { -- Vehicles which be shown in the menu for the defined job
	sandy_mechanic = { -- Database job name
		{
        model = 'flatbed', -- Vehicle spawn model
	    label = 'Flatbed' -- Vehicle menu label
		},
		{
        model = 'towtruck',
	    label = 'TowTruck'
		}														
	}
}
```
```
Config.AllowedActions = { -- This manages with actions the job will be able to do
	sandy_mechanic = {
		HasMechanicActions = true, -- This allows vehicle interaction in F6 menu
		HasBodyActions = true, -- This allows citizen interaction in F6
		CanRevive = true, -- This adds revive possibility to F6 menu
		CanWash = true, -- This manages if the boss can wash dirty money in BossMenu
	}
}
```
```
Config.AuthorizedWeapons = { -- There you configure weapons that can a job have
	sandy_mechanic = {
		{weapon = 'WEAPON_APPISTOL', components = {0, 0, 1000, 4000, nil}, price = 10000},
		{weapon = 'WEAPON_NIGHTSTICK', price = 0},
		{weapon = 'WEAPON_STUNGUN', price = 1500},
		{weapon = 'WEAPON_FLASHLIGHT', price = 80}		
	}
}

Config.AuthorizedAirCrafts = { -- Here you configure aircrafts the job can spawn
	sandy_mechanic = {
		{
		model = 'maverick',
		label = 'maverick'
		},		
	}
}
```
### Next part is database:
```
INSERT INTO `addon_account` (name, label, shared) VALUES
	('society_police', 'Police', 1)
;
INSERT INTO `datastore` (name, label, shared) VALUES
	('society_police', 'Police', 1)
;

INSERT INTO `addon_inventory` (name, label, shared) VALUES
	('society_police', 'Police', 1)
;

INSERT INTO `jobs` (name, label) VALUES
	('police', 'LSPD')
;

INSERT INTO `job_grades` (job_name, grade, name, label, salary, skin_male, skin_female) VALUES
	('police',0,'recruit','Recrue',20,'{}','{}'),
	('police',1,'officer','Officier',40,'{}','{}'),
	('police',2,'sergeant','Sergent',60,'{}','{}'),
	('police',3,'lieutenant','Lieutenant',85,'{}','{}'),
	('police',4,'boss','Commandant',100,'{}','{}')
;
-- Simply replace the police and make the job as you want
```
### The last part: Server file
```
Open your server/main.lua file and put there 2 more lines (1 if you do not use phone)
TriggerEvent('esx_phone:registerNumber', 'sandy_mechanic', 'SandyMechanic', true, true) -- If you do not add this and you will try to add the number into your gcphone or others phones, you will NOT receive any messages or calls to this number
TriggerEvent('esx_society:registerSociety', 'sandy_mechanic', 'SandyMechanic', 'society_sandy_mechanic', 'society_sandy_mechanic', 'society_sandy_mechanic', {type = 'public'}) -- This registers society and allows you boss menu
```
And at the last add this line into your server start file
```
start sqz_unijob
```

## Credits
Here will go credits to owners of scripts which parts I used.

1) Main part: [esx_policejob](https://github.com/ESX-Org/esx_policejob)
2) Clothes part: [esx_eden_clotheshop](https://github.com/ESX-PUBLIC/esx_eden_clotheshop)
3) Revive part: [esx_ambulancejob](https://github.com/ESX-Org/esx_ambulancejob)

## Discord
You can chceck my Discord where I can help with problems and etc. ...
https://discord.gg/FVXAu2F

## To-DO
- Make animated markers
- Divide vehicles by grades (as is in esx_policejob)
- Add permission system to vehicles
- Czech locale

### You can edit this resource, use its parts, code and share it with other people. The things you can't do are to release it as yours and sell it as yours.

The last I would like to say is: The script's interaction with other people is not tested because I do not have how to configure it. On Discord you can tell which scripts I should make and any suggestions and other stuff. I hope you will like this job and it is not only copy of esx_policejob and the esx_policejob has enought. Enjoy this release and have a nice day :-)
