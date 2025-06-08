Config = {}

Config.Priority = {
    HIGH = 'high',
    MEDIUM = 'medium',
    LOW = 'low'
}

Config.HighPriorityRobberies = {
    "Casino Robbery",
    "Art Asylum Robbery",
    "Maze Bank",
    "Paleto Bank",
    "Pacific Bank",
    "DigitalDen Robbery",
    "Laundromat Robbery",
    "Cash Exchange Robbery",
    "Fleeca Robbery",
    "Bobcat Security"
}

Config.MediumPriorityRobberies = {
    "Store Robbery",
    "House Robbery",
    "ATM Robbery",
    "Fight In Progress",
    "Car Rob",
    "Car Jacking",
    "Shots Fired"
}

Config.Sounds = {
    HIGH_PRIORITY = true,
    MEDIUM_PRIORITY = true,
    LOW_PRIORITY = true
}

Config.Codes = {
    ROBBERY = "10-90",
    PANIC = "10-99",
    PICKUP = "10-25",
    EMERGENCY = "911",
    FIGHT = "10-10",
    CAR_ROB = "10-60",
    CAR_JACKING = "10-61",
    SHOTS_FIRED = "10-71"
}

Config.KeyMapping = {
    OPEN_DISPATCH = "F9",
    SET_GPS = "G",
    NEXT_CALL = "RIGHT",
    PREV_CALL = "LEFT",
    PANIC = "F5",
    PICKUP = "F6",
    MOVE_DISPATCH = "F11"
}

Config.PoliceJobs = {
    "police",
    "sheriff",
    "statepolice",
    "trooper"
}

Config.AutoOpenDispatch = true

Config.AutoCloseDispatch = false

Config.DetectionCooldowns = {
    SHOTS_FIRED = 2000,    
    CAR_JACKING = 5000,    
    CAR_ROBBERY = 10000,   
    FIGHT = 5000           
}

Config.RealTimeDetection = {
    ENABLED = true,
    EXCLUDE_POLICE = false,
    INCLUDE_TIMESTAMPS = true,
    SILENCED_WEAPONS_IGNORED = false
}


Config.Database = {
    ENABLED = false,                 
    TABLE_NAME = "dispatch_calls",   
    LOG_RESPONSES = true,            
    CLEANUP_DAYS = 30                
}


Config.Blips = {
    ENABLED = true,                  
    DURATION = 600,                  
    FADE_DISTANCE = 1000             
}

Config.Colors = {
    [0] = "Black",
    [1] = "Graphite",
    [2] = "Black Steel",
    [3] = "Dark Silver",
    [4] = "Silver",
    [5] = "Blue Silver",
    [6] = "Steel Gray",
    [7] = "Shadow Silver",
    [8] = "Stone Silver",
    [9] = "Midnight Silver",
    [10] = "Gun Metal",
    [11] = "Anthracite Grey",
    [12] = "Matte Black",
    [13] = "Matte Gray",
    [14] = "Light Grey",
    [15] = "Chrome",
    [16] = "White",
    [17] = "Frost White",
    [18] = "Cream",
    [19] = "Biege",
    [20] = "Brown",
    [21] = "Dark Brown",
    [22] = "Light Brown",
    [23] = "Red",
    [24] = "Dark Red",
    [25] = "Orange",
    [26] = "Yellow",
    [27] = "Green",
    [28] = "Dark Green",
    [29] = "Light Green",
    [30] = "Blue",
    [31] = "Dark Blue",
    [32] = "Light Blue",
    [33] = "Purple",
    [34] = "Dark Purple",
    [35] = "Pink",
    [36] = "Salmon",
    [37] = "Hot Pink",
    [38] = "Bronze",
    [39] = "Gold",
    [40] = "Silver",
    [41] = "Bright Purple",
    [42] = "Bright Blue",
    [43] = "Bright Green",
    [44] = "Bright Orange",
    [45] = "Bright Yellow",
    [46] = "Bright Red",
    [47] = "Metallic Black",
    [48] = "Metallic Gray",
    [49] = "Metallic White",
    [50] = "Metallic Blue",
    [51] = "Metallic Green",
    [52] = "Metallic Red",
    [53] = "Metallic Orange",
    [54] = "Metallic Yellow",
    [55] = "Metallic Purple"
}

Config.Weapons = {
    {hash = "WEAPON_PISTOL", label = "Pistol"},
    {hash = "WEAPON_PISTOL_MK2", label = "Pistol Mk II"},
    {hash = "WEAPON_COMBATPISTOL", label = "Combat Pistol"},
    {hash = "WEAPON_APPISTOL", label = "AP Pistol"},
    {hash = "WEAPON_STUNGUN", label = "Stun Gun"},
    {hash = "WEAPON_PISTOL50", label = "Pistol .50"},
    {hash = "WEAPON_SNSPISTOL", label = "SNS Pistol"},
    {hash = "WEAPON_SNSPISTOL_MK2", label = "SNS Pistol Mk II"},
    {hash = "WEAPON_HEAVYPISTOL", label = "Heavy Pistol"},
    {hash = "WEAPON_VINTAGEPISTOL", label = "Vintage Pistol"},
    {hash = "WEAPON_FLAREGUN", label = "Flare Gun"},
    {hash = "WEAPON_MARKSMANPISTOL", label = "Marksman Pistol"},
    {hash = "WEAPON_REVOLVER", label = "Heavy Revolver"},
    {hash = "WEAPON_REVOLVER_MK2", label = "Heavy Revolver Mk II"},
    {hash = "WEAPON_DOUBLEACTION", label = "Double Action Revolver"},
    {hash = "WEAPON_RAYPISTOL", label = "Up-n-Atomizer"},
    {hash = "WEAPON_CERAMICPISTOL", label = "Ceramic Pistol"},
    {hash = "WEAPON_NAVYREVOLVER", label = "Navy Revolver"},
    {hash = "WEAPON_GADGETPISTOL", label = "Perico Pistol"},
    
    {hash = "WEAPON_MICROSMG", label = "Micro SMG"},
    {hash = "WEAPON_SMG", label = "SMG"},
    {hash = "WEAPON_SMG_MK2", label = "SMG Mk II"},
    {hash = "WEAPON_ASSAULTSMG", label = "Assault SMG"},
    {hash = "WEAPON_COMBATPDW", label = "Combat PDW"},
    {hash = "WEAPON_MACHINEPISTOL", label = "Machine Pistol"},
    {hash = "WEAPON_MINISMG", label = "Mini SMG"},
    {hash = "WEAPON_RAYCARBINE", label = "Unholy Hellbringer"},
    
    {hash = "WEAPON_PUMPSHOTGUN", label = "Pump Shotgun"},
    {hash = "WEAPON_PUMPSHOTGUN_MK2", label = "Pump Shotgun Mk II"},
    {hash = "WEAPON_SAWNOFFSHOTGUN", label = "Sawed-Off Shotgun"},
    {hash = "WEAPON_ASSAULTSHOTGUN", label = "Assault Shotgun"},
    {hash = "WEAPON_BULLPUPSHOTGUN", label = "Bullpup Shotgun"},
    {hash = "WEAPON_MUSKET", label = "Musket"},
    {hash = "WEAPON_HEAVYSHOTGUN", label = "Heavy Shotgun"},
    {hash = "WEAPON_DBSHOTGUN", label = "Double Barrel Shotgun"},
    {hash = "WEAPON_AUTOSHOTGUN", label = "Sweeper Shotgun"},
    {hash = "WEAPON_COMBATSHOTGUN", label = "Combat Shotgun"},
    
    {hash = "WEAPON_ASSAULTRIFLE", label = "Assault Rifle"},
    {hash = "WEAPON_ASSAULTRIFLE_MK2", label = "Assault Rifle Mk II"},
    {hash = "WEAPON_CARBINERIFLE", label = "Carbine Rifle"},
    {hash = "WEAPON_CARBINERIFLE_MK2", label = "Carbine Rifle Mk II"},
    {hash = "WEAPON_ADVANCEDRIFLE", label = "Advanced Rifle"},
    {hash = "WEAPON_SPECIALCARBINE", label = "Special Carbine"},
    {hash = "WEAPON_SPECIALCARBINE_MK2", label = "Special Carbine Mk II"},
    {hash = "WEAPON_BULLPUPRIFLE", label = "Bullpup Rifle"},
    {hash = "WEAPON_BULLPUPRIFLE_MK2", label = "Bullpup Rifle Mk II"},
    {hash = "WEAPON_COMPACTRIFLE", label = "Compact Rifle"},
    {hash = "WEAPON_MILITARYRIFLE", label = "Military Rifle"},
    
    {hash = "WEAPON_MG", label = "MG"},
    {hash = "WEAPON_COMBATMG", label = "Combat MG"},
    {hash = "WEAPON_COMBATMG_MK2", label = "Combat MG Mk II"},
    {hash = "WEAPON_GUSENBERG", label = "Gusenberg Sweeper"},
    
    {hash = "WEAPON_SNIPERRIFLE", label = "Sniper Rifle"},
    {hash = "WEAPON_HEAVYSNIPER", label = "Heavy Sniper"},
    {hash = "WEAPON_HEAVYSNIPER_MK2", label = "Heavy Sniper Mk II"},
    {hash = "WEAPON_MARKSMANRIFLE", label = "Marksman Rifle"},
    {hash = "WEAPON_MARKSMANRIFLE_MK2", label = "Marksman Rifle Mk II"},
    
    {hash = "WEAPON_RPG", label = "RPG"},
    {hash = "WEAPON_GRENADELAUNCHER", label = "Grenade Launcher"},
    {hash = "WEAPON_GRENADELAUNCHER_SMOKE", label = "Smoke Grenade Launcher"},
    {hash = "WEAPON_MINIGUN", label = "Minigun"},
    {hash = "WEAPON_FIREWORK", label = "Firework Launcher"},
    {hash = "WEAPON_RAILGUN", label = "Railgun"},
    {hash = "WEAPON_HOMINGLAUNCHER", label = "Homing Launcher"},
    {hash = "WEAPON_COMPACTLAUNCHER", label = "Compact Grenade Launcher"},
    {hash = "WEAPON_RAYMINIGUN", label = "Widowmaker"},
    
    {hash = "WEAPON_GRENADE", label = "Grenade"},
    {hash = "WEAPON_BZGAS", label = "BZ Gas"},
    {hash = "WEAPON_MOLOTOV", label = "Molotov Cocktail"},
    {hash = "WEAPON_STICKYBOMB", label = "Sticky Bomb"},
    {hash = "WEAPON_PROXMINE", label = "Proximity Mine"},
    {hash = "WEAPON_SNOWBALL", label = "Snowball"},
    {hash = "WEAPON_PIPEBOMB", label = "Pipe Bomb"},
    {hash = "WEAPON_BALL", label = "Baseball"},
    {hash = "WEAPON_SMOKEGRENADE", label = "Smoke Grenade"},
    {hash = "WEAPON_FLARE", label = "Flare"},
    
    {hash = "WEAPON_DAGGER", label = "Dagger"},
    {hash = "WEAPON_BAT", label = "Baseball Bat"},
    {hash = "WEAPON_BOTTLE", label = "Broken Bottle"},
    {hash = "WEAPON_CROWBAR", label = "Crowbar"},
    {hash = "WEAPON_UNARMED", label = "Fists"},
    {hash = "WEAPON_FLASHLIGHT", label = "Flashlight"},
    {hash = "WEAPON_GOLFCLUB", label = "Golf Club"},
    {hash = "WEAPON_HAMMER", label = "Hammer"},
    {hash = "WEAPON_HATCHET", label = "Hatchet"},
    {hash = "WEAPON_KNUCKLE", label = "Brass Knuckles"},
    {hash = "WEAPON_KNIFE", label = "Knife"},
    {hash = "WEAPON_MACHETE", label = "Machete"},
    {hash = "WEAPON_SWITCHBLADE", label = "Switchblade"},
    {hash = "WEAPON_NIGHTSTICK", label = "Nightstick"},
    {hash = "WEAPON_WRENCH", label = "Wrench"},
    {hash = "WEAPON_BATTLEAXE", label = "Battle Axe"},
    {hash = "WEAPON_POOLCUE", label = "Pool Cue"},
    {hash = "WEAPON_STONE_HATCHET", label = "Stone Hatchet"}
}

function Config.IsPoliceJob(job)
    for _, policeJob in ipairs(Config.PoliceJobs) do
        if job == policeJob then
            return true
        end
    end
    return false
end