local QBCore = exports['qb-core']:GetCoreObject()

local dispatchCalls = {}
local callIdCounter = 1
local playerCooldowns = {}

if Config.Database.ENABLED then
    Citizen.CreateThread(function()
        MySQL.Async.execute([[
            CREATE TABLE IF NOT EXISTS `dispatch_calls` (
                `id` int(11) NOT NULL AUTO_INCREMENT,
                `call_id` int(11) NOT NULL,
                `code` varchar(10) NOT NULL,
                `title` varchar(255) NOT NULL,
                `location` varchar(255) NOT NULL,
                `coords` text NOT NULL,
                `priority` varchar(10) NOT NULL,
                `vehicle_data` text DEFAULT NULL,
                `weapon_data` varchar(255) DEFAULT NULL,
                `suspect_data` varchar(255) DEFAULT NULL,
                `responded` tinyint(1) DEFAULT 0,
                `responding_officers` text DEFAULT NULL,
                `created_at` timestamp DEFAULT CURRENT_TIMESTAMP,
                `responded_at` timestamp NULL DEFAULT NULL,
                PRIMARY KEY (`id`),
                KEY `call_id` (`call_id`),
                KEY `created_at` (`created_at`)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
        ]], {}, function(result)
        end)
    end)
end


local function GetVehicleInfo(vehicle)
    if not DoesEntityExist(vehicle) then return nil end

    local model = GetEntityModel(vehicle)
    local displayName = GetDisplayNameFromVehicleModel(model)
    local primaryColor, secondaryColor = GetVehicleColours(vehicle)
    local plate = GetVehicleNumberPlateText(vehicle)

    return {
        model = displayName,
        color = Config.Colors[primaryColor] or "Unknown",
        secondaryColor = Config.Colors[secondaryColor] or "Unknown",
        plate = plate and string.gsub(plate, "%s+", "") or "Unknown"
    }
end

local function GetWeaponName(weaponHash)
    for _, weapon in ipairs(Config.Weapons) do
        if GetHashKey(weapon.hash) == weaponHash then
            return weapon.label
        end
    end
    return "Unknown Weapon"
end

local function GetAlertPriority(alertType)
    for _, robbery in ipairs(Config.HighPriorityRobberies) do
        if string.find(string.lower(alertType), string.lower(robbery)) then
            return Config.Priority.HIGH
        end
    end
    
    for _, robbery in ipairs(Config.MediumPriorityRobberies) do
        if string.find(string.lower(alertType), string.lower(robbery)) then
            return Config.Priority.MEDIUM
        end
    end
    
    return Config.Priority.LOW
end

local function IsPlayerOnCooldown(playerId, alertType)
    if not Config.DetectionCooldowns[alertType] then return false end
    
    local playerKey = playerId .. "_" .. alertType
    local lastAlert = playerCooldowns[playerKey]
    
    if not lastAlert then return false end
    
    local currentTime = GetGameTimer()
    local cooldownTime = Config.DetectionCooldowns[alertType]
    
    return (currentTime - lastAlert) < cooldownTime
end

local function SetPlayerCooldown(playerId, alertType)
    if Config.DetectionCooldowns[alertType] then
        local playerKey = playerId .. "_" .. alertType
        playerCooldowns[playerKey] = GetGameTimer()
    end
end


local function CreateDispatchCall(data)
    local callId = callIdCounter
    callIdCounter = callIdCounter + 1

    if not data.coords or not data.title then
        return nil
    end

    local call = {
        id = callId,
        code = data.code or Config.Codes.EMERGENCY,
        title = data.title,
        location = data.location,
        coords = data.coords,
        priority = data.priority or Config.Priority.LOW,
        timestamp = os.time(),
        serverTime = os.time(), 
        vehicle = data.vehicle,
        weapon = data.weapon,
        suspect = data.suspect,
        responded = false,
        units = {},
        created = os.date("%H:%M:%S")
    }

    table.insert(dispatchCalls, call)

    if #dispatchCalls > 10 then
        table.remove(dispatchCalls, 1)
    end

    if Config.Database.ENABLED then
        local vehicleJson = call.vehicle and json.encode(call.vehicle) or nil
        local coordsJson = json.encode({x = call.coords.x, y = call.coords.y, z = call.coords.z})

        MySQL.Async.execute('INSERT INTO dispatch_calls (call_id, code, title, location, coords, priority, vehicle_data, weapon_data, suspect_data) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)', {
            call.id,
            call.code,
            call.title,
            call.location,
            coordsJson,
            call.priority,
            vehicleJson,
            call.weapon,
            call.suspect
        })
    end

    return call
end

local function SendDispatchAlert(call)
    local players = QBCore.Functions.GetPlayers()
    
    for _, playerId in ipairs(players) do
        local Player = QBCore.Functions.GetPlayer(playerId)
        if Player and Config.IsPoliceJob(Player.PlayerData.job.name) then
            TriggerClientEvent('alpha-dispatch:client:newAlert', playerId, call, #dispatchCalls)
        end
    end
end


RegisterNetEvent('alpha-dispatch:server:sendAlert', function(data)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)

    if not Player then return end

    if not data.location then
        return
    end

    local coords = data.coords or GetEntityCoords(GetPlayerPed(src))
    local priority = data.priority or GetAlertPriority(data.title or "")

    local call = CreateDispatchCall({
        code = data.code,
        title = data.title,
        location = data.location,
        coords = coords,
        priority = priority,
        vehicle = data.vehicle,
        weapon = data.weapon,
        suspect = data.suspect
    })

    if call then
        SendDispatchAlert(call)
    end
end)


RegisterNetEvent('alpha-dispatch:server:shotsDetected', function(weaponHash, coords, location)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)

    if not Player then
        return
    end

    if not Config.RealTimeDetection.ENABLED then
        return
    end

    if Config.RealTimeDetection.EXCLUDE_POLICE and Config.IsPoliceJob(Player.PlayerData.job.name) then
        return
    end

    if IsPlayerOnCooldown(src, "SHOTS_FIRED") then
        return
    end

    local weaponName = GetWeaponName(weaponHash)
    local alertLocation = location or "Unknown Location"

    local call = CreateDispatchCall({
        code = Config.Codes.SHOTS_FIRED,
        title = "Shots Fired",
        location = alertLocation,
        coords = coords,
        priority = Config.Priority.LOW,
        weapon = weaponName,
        suspect = Player.PlayerData.charinfo.firstname .. " " .. Player.PlayerData.charinfo.lastname
    })

    if call then
        SetPlayerCooldown(src, "SHOTS_FIRED")
        SendDispatchAlert(call)
    end
end)


RegisterNetEvent('alpha-dispatch:server:carJackingDetected', function(coords, vehicleData, location)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)

    if not Player or not Config.RealTimeDetection.ENABLED then return end

    if Config.RealTimeDetection.EXCLUDE_POLICE and Config.IsPoliceJob(Player.PlayerData.job.name) then
        return
    end


    if IsPlayerOnCooldown(src, "CAR_JACKING") then return end

    local alertLocation = location or "Unknown Location"

    local call = CreateDispatchCall({
        code = Config.Codes.CAR_JACKING,
        title = "Car Jacking",
        location = alertLocation,
        coords = coords,
        priority = Config.Priority.HIGH,
        vehicle = vehicleData
    })

    if call then
        SetPlayerCooldown(src, "CAR_JACKING")
        SendDispatchAlert(call)
    end
end)

RegisterNetEvent('alpha-dispatch:server:randomVehicleAlert', function(coords, vehicleData, location)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)

    if not Player or not Config.RealTimeDetection.ENABLED then return end

    if Config.RealTimeDetection.EXCLUDE_POLICE and Config.IsPoliceJob(Player.PlayerData.job.name) then
        return
    end

    if IsPlayerOnCooldown(src, "RANDOM_VEHICLE") then return end

    local alertLocation = location or "Unknown Location"
    local alertTypes = {
        "Suspicious Vehicle",
        "Reckless Driving",
        "Vehicle Disturbance",
        "Traffic Violation"
    }
    local randomAlert = alertTypes[math.random(#alertTypes)]

    local call = CreateDispatchCall({
        code = Config.Codes.TRAFFIC_VIOLATION,
        title = randomAlert,
        location = alertLocation,
        coords = coords,
        priority = Config.Priority.LOW,
        vehicle = vehicleData,
        suspect = Player.PlayerData.charinfo.firstname .. " " .. Player.PlayerData.charinfo.lastname
    })

    if call then
        SetPlayerCooldown(src, "RANDOM_VEHICLE")
        SendDispatchAlert(call)
    end
end)

RegisterNetEvent('alpha-dispatch:server:fightDetected', function(coords, location)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)

    if not Player or not Config.RealTimeDetection.ENABLED then return end

    if Config.RealTimeDetection.EXCLUDE_POLICE and Config.IsPoliceJob(Player.PlayerData.job.name) then
        return
    end

    if IsPlayerOnCooldown(src, "FIGHT") then return end

    local alertLocation = location or "Unknown Location"

    local call = CreateDispatchCall({
        code = Config.Codes.FIGHT,
        title = "Fight In Progress",
        location = alertLocation,
        coords = coords,
        priority = Config.Priority.LOW
    })

    if call then
        SetPlayerCooldown(src, "FIGHT")
        SendDispatchAlert(call)
    end
end)


RegisterNetEvent('alpha-dispatch:server:getCalls', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player or not Config.IsPoliceJob(Player.PlayerData.job.name) then return end
    
    TriggerClientEvent('alpha-dispatch:client:receiveCalls', src, dispatchCalls)
end)


RegisterNetEvent('alpha-dispatch:server:respondToCall', function(callId)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)

    if not Player or not Config.IsPoliceJob(Player.PlayerData.job.name) then return end

    local officerName = Player.PlayerData.charinfo.firstname .. " " .. Player.PlayerData.charinfo.lastname
    local badgeNumber = Player.PlayerData.job.grade.name or "Unknown"

    if not callId and #dispatchCalls > 0 then
        callId = dispatchCalls[1].id
    end

    local callFound = false
    for i, call in ipairs(dispatchCalls) do
        if call.id == callId then
            callFound = true
            call.responded = true
            call.respondingOfficer = officerName
            call.badgeNumber = badgeNumber
            call.respondedAt = os.time()

            if Config.Database.ENABLED and Config.Database.LOG_RESPONSES then
                MySQL.Async.execute('UPDATE dispatch_calls SET responded = 1, responding_officers = ?, responded_at = NOW() WHERE call_id = ?', {
                    json.encode({
                        name = officerName,
                        badge = badgeNumber,
                        citizenid = Player.PlayerData.citizenid
                    }),
                    callId
                })
            end
                        
            local players = QBCore.Functions.GetPlayers()
            for _, playerId in ipairs(players) do
                local targetPlayer = QBCore.Functions.GetPlayer(tonumber(playerId))
                if targetPlayer and Config.IsPoliceJob(targetPlayer.PlayerData.job.name) then
                    TriggerClientEvent('alpha-dispatch:client:updateCall', playerId, call, i, #dispatchCalls)
                    if tonumber(playerId) ~= src then 
                        TriggerClientEvent('QBCore:Notify', playerId, officerName .. " (" .. badgeNumber .. ") is responding to " .. call.code .. " - " .. call.title, "info")
                    end
                end
            end
            
            break
        end
    end
    
    if not callFound then
        TriggerClientEvent('QBCore:Notify', src, "Could not find the call in the system", "error")
    end
end)

exports('SendDispatchAlert', function(data)
    if not data or not data.coords or not data.title or not data.location then
        return false
    end

    local priority = data.priority or GetAlertPriority(data.title)

    local call = CreateDispatchCall({
        code = data.code or Config.Codes.EMERGENCY,
        title = data.title,
        location = data.location,
        coords = data.coords,
        priority = priority,
        vehicle = data.vehicle,
        weapon = data.weapon,
        suspect = data.suspect
    })

    if call then
        SendDispatchAlert(call)
        return call.id
    end
    return false
end)

exports('GetActiveCalls', function()
    return dispatchCalls
end)

exports('ClearAllCalls', function()
    dispatchCalls = {}
    callIdCounter = 1

    local players = QBCore.Functions.GetPlayers()
    for _, playerId in ipairs(players) do
        local Player = QBCore.Functions.GetPlayer(playerId)
        if Player and Config.IsPoliceJob(Player.PlayerData.job.name) then
            TriggerClientEvent('alpha-dispatch:client:receiveCalls', playerId, {})
        end
    end
end)




QBCore.Commands.Add('cleardispatch', 'Clear all dispatch calls (Admin Only)', {}, false, function(source, args)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return end


    if not QBCore.Functions.HasPermission(source, 'admin') then
        TriggerClientEvent('QBCore:Notify', source, 'You do not have permission to use this command', 'error')
        return
    end

    exports['alpha-dispatch']:ClearAllCalls()
    TriggerClientEvent('QBCore:Notify', source, 'All dispatch calls cleared', 'success')
end)





QBCore.Commands.Add('togglepolicedetection', 'Toggle police detection (Admin Only)', {}, false, function(source, args)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return end


    if not QBCore.Functions.HasPermission(source, 'admin') then
        TriggerClientEvent('QBCore:Notify', source, 'You do not have permission to use this command', 'error')
        return
    end

    Config.RealTimeDetection.EXCLUDE_POLICE = not Config.RealTimeDetection.EXCLUDE_POLICE
    local status = Config.RealTimeDetection.EXCLUDE_POLICE and "disabled" or "enabled"
    TriggerClientEvent('QBCore:Notify', source, 'Police detection ' .. status, 'primary')
end)


Citizen.CreateThread(function()
    while true do
        Citizen.Wait(1800000) 

        local currentTime = os.time()
        local cleanedCalls = {}

        for _, call in ipairs(dispatchCalls) do

            if currentTime - call.timestamp < 7200 then
                table.insert(cleanedCalls, call)
            end
        end

        dispatchCalls = cleanedCalls

        if Config.Database.ENABLED then
            local cleanupDays = Config.Database.CLEANUP_DAYS or 30
            MySQL.Async.execute('DELETE FROM dispatch_calls WHERE created_at < DATE_SUB(NOW(), INTERVAL ? DAY)', {
                cleanupDays
            }, function(result)
            end)
        end
    end
end)