local QBCore = exports['qb-core']:GetCoreObject()

local dispatchOpen = false
local currentCalls = {}
local currentCallIndex = 1
local lastShotTime = 0
local lastVehicleEntered = nil
local isInCombat = false
local combatStartTime = 0
local lastWeaponDamageTime = 0
local lastObjectDamageTime = 0
local lastCollisionTime = 0
local lastRandomAlertTime = nil
local dispatchBlips = {}

local meleeWeapons = {
    [`WEAPON_UNARMED`] = true,
    [`WEAPON_DAGGER`] = true,
    [`WEAPON_BAT`] = true,
    [`WEAPON_BOTTLE`] = true,
    [`WEAPON_CROWBAR`] = true,
    [`WEAPON_FLASHLIGHT`] = true,
    [`WEAPON_GOLFCLUB`] = true,
    [`WEAPON_HAMMER`] = true,
    [`WEAPON_HATCHET`] = true,
    [`WEAPON_KNUCKLE`] = true,
    [`WEAPON_KNIFE`] = true,
    [`WEAPON_MACHETE`] = true,
    [`WEAPON_SWITCHBLADE`] = true,
    [`WEAPON_NIGHTSTICK`] = true,
    [`WEAPON_WRENCH`] = true,
    [`WEAPON_BATTLEAXE`] = true,
    [`WEAPON_POOLCUE`] = true,
    [`WEAPON_STONE_HATCHET`] = true
}

local function GetStreetName(coords)
    local streetHash, crossingHash = GetStreetNameAtCoord(coords.x, coords.y, coords.z)
    local streetName = GetStreetNameFromHashKey(streetHash)
    local crossingName = GetStreetNameFromHashKey(crossingHash)

    if crossingName and crossingName ~= "" then
        return streetName .. " - " .. crossingName
    else
        return streetName
    end
end

local function IsPlayerPolice()
    local PlayerData = QBCore.Functions.GetPlayerData()
    return PlayerData.job and Config.IsPoliceJob(PlayerData.job.name)
end

local function CreateDispatchBlip(coords, priority, title)
    local blip = AddBlipForCoord(coords.x, coords.y, coords.z)

    if priority == Config.Priority.HIGH then
        SetBlipSprite(blip, 161)
        SetBlipColour(blip, 1)
        SetBlipScale(blip, 1.2)
    elseif priority == Config.Priority.MEDIUM then
        SetBlipSprite(blip, 161)
        SetBlipColour(blip, 5)
        SetBlipScale(blip, 1.0)
    else
        SetBlipSprite(blip, 161)
        SetBlipColour(blip, 0)
        SetBlipScale(blip, 0.8)
    end

    SetBlipAsShortRange(blip, false)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(title)
    EndTextCommandSetBlipName(blip)

    if not dispatchBlips then dispatchBlips = {} end
    table.insert(dispatchBlips, {
        blip = blip,
        coords = coords,
        title = title,
        priority = priority
    })

    return blip
end

local function ToggleDispatch()
    if not IsPlayerPolice() then return end

    dispatchOpen = not dispatchOpen
    SetNuiFocus(false, false)
    SendNUIMessage({
        type = "toggleDispatch",
        show = dispatchOpen
    })

    if dispatchOpen then
        TriggerServerEvent('alpha-dispatch:server:getCalls')
        
        TriggerEvent('alpha-dispatch:client:dispatchOpened')
        
        Citizen.SetTimeout(500, function()
            QBCore.Functions.Notify("Press G to set GPS waypoint to current call", "info", 3000)
        end)
        
        Citizen.SetTimeout(3500, function()
            QBCore.Functions.Notify("Use LEFT/RIGHT arrow keys to navigate between calls", "info", 3000)
        end)
    end
end

local function UpdateDispatchUI()
    if #currentCalls == 0 then
        SendNUIMessage({
            type = "updateCall",
            call = nil,
            currentIndex = 0,
            totalCalls = 0
        })
        return
    end

    local currentCall = currentCalls[currentCallIndex]
    if not currentCall then return end

    local timeText = currentCall.created or "Recent"
    if currentCall.created then
        timeText = "Received at " .. currentCall.created
    else
        timeText = "Recent call"
    end

    local playerCoords = GetEntityCoords(PlayerPedId())
    local distance = #(playerCoords - currentCall.coords)
    local distanceText = ""
    if distance > 1000 then
        distanceText = string.format("%.1f km away", distance / 1000)
    else
        distanceText = string.format("%.0f m away", distance)
    end

    SendNUIMessage({
        type = "updateCall",
        call = {
            id = currentCall.id,
            code = currentCall.code,
            title = currentCall.title,
            location = currentCall.location,
            coords = currentCall.coords,
            priority = currentCall.priority,
            timeAgo = timeText,
            distance = distanceText,
            vehicle = currentCall.vehicle,
            weapon = currentCall.weapon,
            suspect = currentCall.suspect,
            responded = currentCall.responded,
            created = currentCall.created
        },
        currentIndex = currentCallIndex,
        totalCalls = #currentCalls
    })
end

local function SetGPSWaypoint(coords, location)
    if coords and coords.x and coords.y then
        SetNewWaypoint(coords.x, coords.y)
        QBCore.Functions.Notify("GPS waypoint set to: " .. (location or "Emergency Location"), "success")
        
        return true
    else
        QBCore.Functions.Notify("Invalid coordinates for GPS waypoint", "error")
        return false
    end
end

RegisterCommand('toggledispatch', function()
    ToggleDispatch()
end, false)

RegisterCommand('dispatch', function()
    ToggleDispatch()
end, false)

RegisterCommand('opendispatch', function()
    if not IsPlayerPolice() then
        QBCore.Functions.Notify("You must be a police officer to use dispatch", "error")
        return
    end
    if not dispatchOpen then
        ToggleDispatch()
    end
end, false)

RegisterCommand('closedispatch', function()
    if dispatchOpen then
        ToggleDispatch()
    end
end, false)

RegisterKeyMapping('toggledispatch', 'Toggle Dispatch', 'keyboard', Config.KeyMapping.OPEN_DISPATCH)

RegisterCommand('setgpswaypoint', function()
    if not IsPlayerPolice() then
        QBCore.Functions.Notify("You must be a police officer to use this feature", "error")
        return
    end
    
    if #currentCalls > 0 and currentCallIndex <= #currentCalls then
        local currentCall = currentCalls[currentCallIndex]
        if currentCall and currentCall.coords then
            SetGPSWaypoint(currentCall.coords, currentCall.location)
            
            TriggerServerEvent('alpha-dispatch:server:respondToCall', currentCall.id)
            
            currentCall.responded = true
            if dispatchOpen then
                UpdateDispatchUI()
            end
        else
            QBCore.Functions.Notify("No valid coordinates for this call", "error")
        end
    else
        QBCore.Functions.Notify("No active calls", "error")
    end
end, false)

RegisterKeyMapping('setgpswaypoint', 'Set GPS Waypoint to Current Call', 'keyboard', Config.KeyMapping.SET_GPS)

RegisterCommand('nextcall', function()
    if not IsPlayerPolice() then return end
    if not dispatchOpen then return end
    
    if currentCallIndex < #currentCalls then
        currentCallIndex = currentCallIndex + 1
        UpdateDispatchUI()
        QBCore.Functions.Notify("Viewing call " .. currentCallIndex .. " of " .. #currentCalls, "primary", 1000)
    else
        QBCore.Functions.Notify("Already at the last call", "error", 1000)
    end
end, false)

RegisterCommand('prevcall', function()
    if not IsPlayerPolice() then return end
    if not dispatchOpen then return end
    
    if currentCallIndex > 1 then
        currentCallIndex = currentCallIndex - 1
        UpdateDispatchUI()
        QBCore.Functions.Notify("Viewing call " .. currentCallIndex .. " of " .. #currentCalls, "primary", 1000)
    else
        QBCore.Functions.Notify("Already at the first call", "error", 1000)
    end
end, false)

RegisterKeyMapping('nextcall', 'Next Dispatch Call', 'keyboard', Config.KeyMapping.NEXT_CALL)
RegisterKeyMapping('prevcall', 'Previous Dispatch Call', 'keyboard', Config.KeyMapping.PREV_CALL)

RegisterCommand('panic', function(source, args)
    local playerPed = PlayerPedId()
    local coords = GetEntityCoords(playerPed)
    local location = GetStreetName(coords)
    
    local playerData = QBCore.Functions.GetPlayerData()
    local callTitle = playerData.job.name:upper() .. " OFFICER PANIC BUTTON"
    local officerName = playerData.charinfo.firstname .. " " .. playerData.charinfo.lastname
    local officerRank = playerData.job.grade.name
    
    local message = "Officer " .. officerRank .. " " .. officerName .. " has pressed their panic button"
    
    TriggerServerEvent('alpha-dispatch:server:sendAlert', {
        code = Config.Codes.PANIC,
        title = callTitle,
        location = location,
        coords = coords,
        priority = Config.Priority.HIGH,
        suspect = message
    })
    
    QBCore.Functions.Notify("Panic button activated! Backup requested at your location.", "error", 5000)
end, false)

RegisterKeyMapping('panic', 'Emergency Panic Button', 'keyboard', Config.KeyMapping.PANIC)

RegisterCommand('pickup', function(source, args)
    local playerPed = PlayerPedId()
    local coords = GetEntityCoords(playerPed)
    local location = GetStreetName(coords)
    
    local playerData = QBCore.Functions.GetPlayerData()
    local callTitle = "OFFICER REQUESTING PICKUP"
    local officerName = playerData.charinfo.firstname .. " " .. playerData.charinfo.lastname
    local officerRank = playerData.job.grade.name
    
    local message = "Officer " .. officerRank .. " " .. officerName .. " is requesting a pickup"
    
    TriggerServerEvent('alpha-dispatch:server:sendAlert', {
        code = Config.Codes.PICKUP,
        title = callTitle,
        location = location,
        coords = coords,
        priority = Config.Priority.LOW,
        suspect = message
    })
    
    QBCore.Functions.Notify("Pickup requested at your location.", "success", 5000)
end, false)

RegisterKeyMapping('pickup', 'Request Officer Pickup', 'keyboard', Config.KeyMapping.PICKUP)

RegisterCommand('911', function(source, args)
    if #args < 1 then
        QBCore.Functions.Notify("Please provide a message for your 911 call", "error")
        return
    end
    
    local message = table.concat(args, " ")
    local playerPed = PlayerPedId()
    local coords = GetEntityCoords(playerPed)
    local location = GetStreetName(coords)
    
    local playerData = QBCore.Functions.GetPlayerData()
    local callerName = playerData.charinfo.firstname .. " " .. playerData.charinfo.lastname
    local phoneNumber = playerData.charinfo.phone
    
    local callerInfo = callerName .. " (" .. phoneNumber .. ")"
    
    TriggerServerEvent('alpha-dispatch:server:sendAlert', {
        code = Config.Codes.EMERGENCY,
        title = "911 Emergency Call",
        location = location,
        coords = coords,
        priority = Config.Priority.MEDIUM,
        suspect = callerInfo,
        weapon = message
    })
    
    QBCore.Functions.Notify("Your 911 call has been received. Emergency services have been notified.", "success", 5000)
end, false)

RegisterNUICallback('closeDispatch', function(data, cb)
    if data.isMovableMode then
        cb('movable')
        return
    end
    
    if dispatchOpen then
        ToggleDispatch()
    end
    cb('ok')
end)

RegisterNUICallback('previousCall', function(data, cb)
    if currentCallIndex > 1 then
        currentCallIndex = currentCallIndex - 1
        UpdateDispatchUI()
    end
    cb('ok')
end)

RegisterNUICallback('nextCall', function(data, cb)
    if currentCallIndex < #currentCalls then
        currentCallIndex = currentCallIndex + 1
        UpdateDispatchUI()
    end
    cb('ok')
end)

RegisterNUICallback('goToCall', function(data, cb)
    local index = tonumber(data.index)
    if index and index >= 1 and index <= #currentCalls then
        currentCallIndex = index
        UpdateDispatchUI()
    end
    cb('ok')
end)

RegisterNUICallback('respondToCall', function(data, cb)
    if #currentCalls > 0 then
        local currentCall = currentCalls[currentCallIndex]
        if currentCall then
            if currentCall.coords and currentCall.coords.x and currentCall.coords.y then
                SetGPSWaypoint(currentCall.coords, currentCall.location)
                
                TriggerServerEvent('alpha-dispatch:server:respondToCall', currentCall.id)
                
                currentCall.responded = true
                UpdateDispatchUI()
                
                if Config.AutoCloseDispatch then
                    Citizen.SetTimeout(1000, function()
                        if dispatchOpen then
                            ToggleDispatch()
                        end
                    end)
                end
            else
                QBCore.Functions.Notify("No coordinates available for this call", "error")
            end
        else
            QBCore.Functions.Notify("Invalid call data", "error")
        end
    else
        QBCore.Functions.Notify("No active calls", "error")
    end
    cb('ok')
end)

RegisterNetEvent('alpha-dispatch:client:newAlert', function(call, totalCalls)
    if not IsPlayerPolice() then return end

    table.insert(currentCalls, 1, call)

    if #currentCalls > 10 then
        table.remove(currentCalls, #currentCalls)
    end

    currentCallIndex = 1

    CreateDispatchBlip(call.coords, call.priority, call.title)

    local soundFile = ""
    if call.priority == Config.Priority.HIGH then
        soundFile = "dispatch_high_priority.wav"
    elseif call.priority == Config.Priority.MEDIUM then
        soundFile = "dispatch_medium_priority.wav"
    else
        soundFile = "dispatch_low_priority.wav"
    end

    SendNUIMessage({
        type = "playSound",
        sound = soundFile,
        priority = call.priority,
        isNewAlert = true
    })

    if Config.AutoOpenDispatch and not dispatchOpen then
        ToggleDispatch()

        if Config.AutoCloseDispatch then
            Citizen.SetTimeout(10000, function()
                if dispatchOpen then
                    ToggleDispatch()
                end
            end)
        end
    end

    if dispatchOpen then
        UpdateDispatchUI()
    end

    QBCore.Functions.Notify(call.code .. " - " .. call.title .. " at " .. call.location, "error", 5000)
    
    Citizen.SetTimeout(1000, function()
        QBCore.Functions.Notify("Press G to set GPS waypoint to this call", "info", 3000)
    end)
end)

RegisterNetEvent('alpha-dispatch:client:receiveCalls', function(calls)
    currentCalls = calls
    currentCallIndex = 1
    
    if dispatchOpen then
        UpdateDispatchUI()
    end
end)

RegisterNetEvent('alpha-dispatch:client:updateCall', function(call, index, totalCalls)
    if not IsPlayerPolice() then return end
    
    for i, existingCall in ipairs(currentCalls) do
        if existingCall.id == call.id then
            currentCalls[i] = call
            
            if dispatchOpen and currentCallIndex == i then
                UpdateDispatchUI()
            end
            
            break
        end
    end
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)

        if Config.RealTimeDetection.ENABLED then
            local playerPed = PlayerPedId()
            local coords = GetEntityCoords(playerPed)
            local isPolice = IsPlayerPolice()

            local shouldDetect = true
            if Config.RealTimeDetection.EXCLUDE_POLICE and isPolice then
                shouldDetect = false
            end

            if shouldDetect then
                if IsPedShooting(playerPed) then
                    local currentTime = GetGameTimer()
                    if currentTime - lastShotTime > 1000 then
                        local weapon = GetSelectedPedWeapon(playerPed)

                        if not meleeWeapons[weapon] then
                            local isSilenced = false
                            if Config.RealTimeDetection.SILENCED_WEAPONS_IGNORED then
                                local suppressorComponents = {
                                    GetHashKey("COMPONENT_AT_PI_SUPP"),
                                    GetHashKey("COMPONENT_AT_PI_SUPP_02"),
                                    GetHashKey("COMPONENT_AT_AR_SUPP"),
                                    GetHashKey("COMPONENT_AT_AR_SUPP_02"),
                                    GetHashKey("COMPONENT_AT_SR_SUPP")
                                }

                                for _, component in ipairs(suppressorComponents) do
                                    if HasPedGotWeaponComponent(playerPed, weapon, component) then
                                        isSilenced = true
                                        break
                                    end
                                end
                            end

                            if not isSilenced then
                                local location = GetStreetName(coords)
                                TriggerServerEvent('alpha-dispatch:server:shotsDetected', weapon, coords, location)
                                lastShotTime = currentTime
                            end
                        end
                    end
                end

                local vehicle = GetVehiclePedIsIn(playerPed, false)
                if vehicle ~= 0 and vehicle ~= lastVehicleEntered then
                    if GetPedInVehicleSeat(vehicle, -1) == playerPed then
                        local driverPed = nil
                        for i = -1, 6 do
                            local ped = GetPedInVehicleSeat(vehicle, i)
                            if ped ~= 0 and ped ~= playerPed then
                                driverPed = ped
                                break
                            end
                        end
                        
                        if driverPed ~= nil or IsVehicleStolen(vehicle) then
                            local primaryColor, secondaryColor = GetVehicleColours(vehicle)
                            local vehicleData = {
                                model = GetDisplayNameFromVehicleModel(GetEntityModel(vehicle)),
                                color = Config.Colors[primaryColor] or "Unknown",
                                secondaryColor = Config.Colors[secondaryColor] or "Unknown",
                                plate = string.gsub(GetVehicleNumberPlateText(vehicle) or "Unknown", "%s+", "")
                            }
                            
                            local location = GetStreetName(coords)
                            TriggerServerEvent('alpha-dispatch:server:carJackingDetected', coords, vehicleData, location)
                        end
                    end
                    lastVehicleEntered = vehicle
                elseif vehicle == 0 then
                    lastVehicleEntered = nil
                end

                if vehicle ~= 0 and GetPedInVehicleSeat(vehicle, -1) == playerPed then
                    local currentTime = GetGameTimer()
                    local speed = GetEntitySpeed(vehicle) * 3.6 
                    
                    if speed > 50 and currentTime - (lastRandomAlertTime or 0) > 30000 then 
                        if math.random() < 0.1 then
                            local location = GetStreetName(coords)
                            local vehicleData = {
                                model = GetDisplayNameFromVehicleModel(GetEntityModel(vehicle)),
                                plate = string.gsub(GetVehicleNumberPlateText(vehicle) or "Unknown", "%s+", "")
                            }
                            
                            TriggerServerEvent('alpha-dispatch:server:randomVehicleAlert', coords, vehicleData, location)
                            lastRandomAlertTime = currentTime
                        end
                    end
                end

                if vehicle ~= 0 and GetPedInVehicleSeat(vehicle, -1) == playerPed then
                    local currentTime = GetGameTimer()
                    if IsVehicleDamaged(vehicle) and currentTime - (lastCollisionTime or 0) > 5000 then
                        local location = GetStreetName(coords)
                        local vehicleData = {
                            model = GetDisplayNameFromVehicleModel(GetEntityModel(vehicle)),
                            plate = string.gsub(GetVehicleNumberPlateText(vehicle) or "Unknown", "%s+", "")
                        }
                        
                        TriggerServerEvent('alpha-dispatch:server:vehicleCollision', coords, vehicleData, location)
                        lastCollisionTime = currentTime
                    end
                end

                local isHittingObject = false
                
                if IsPedInMeleeCombat(playerPed) or IsPedInCombat(playerPed, 0) then
                    local weapon = GetSelectedPedWeapon(playerPed)
                    if meleeWeapons[weapon] then
                        local hit, entity = GetEntityPlayerIsFreeAimingAt(PlayerId())
                        if hit and entity ~= 0 then
                            local entityType = GetEntityType(entity)
                            if entityType == 3 then
                                isHittingObject = true
                            end
                        end
                        
                        if not isInCombat then
                            isInCombat = true
                            combatStartTime = GetGameTimer()
                        elseif GetGameTimer() - combatStartTime > 3000 then
                            local location = GetStreetName(coords)
                            TriggerServerEvent('alpha-dispatch:server:fightDetected', coords, location)
                            combatStartTime = GetGameTimer() + 10000
                        end
                    end
                else
                    local hit, entity = GetEntityPlayerIsFreeAimingAt(PlayerId())
                    if hit and entity ~= 0 then
                        local entityType = GetEntityType(entity)
                        if entityType == 3 then
                            local weapon = GetSelectedPedWeapon(playerPed)
                            if meleeWeapons[weapon] and IsControlPressed(0, 24) then
                                isHittingObject = true
                                
                                if not isInCombat then
                                    isInCombat = true
                                    combatStartTime = GetGameTimer()
                                elseif GetGameTimer() - combatStartTime > 2000 then
                                    local location = GetStreetName(coords)
                                    TriggerServerEvent('alpha-dispatch:server:fightDetected', coords, location)
                                    combatStartTime = GetGameTimer() + 10000
                                end
                            end
                        end
                    end
                    
                    if not isHittingObject then
                        isInCombat = false
                    end
                end
            end
        else
            Citizen.Wait(1000)
        end
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        if dispatchOpen then
            SetNuiFocus(false, false)
            dispatchOpen = false
        end
                if dispatchBlips then
            for _, blipData in ipairs(dispatchBlips) do
                if DoesBlipExist(blipData.blip) then
                    RemoveBlip(blipData.blip)
                end
            end
            dispatchBlips = {}
        end
    end
end)

RegisterNetEvent('QBCore:Client:OnJobUpdate', function(JobInfo)
    if dispatchOpen and not Config.IsPoliceJob(JobInfo.name) then
        ToggleDispatch()
    end
end)

exports('IsDispatchOpen', function()
    return dispatchOpen
end)

exports('GetCurrentCalls', function()
    return currentCalls
end)

exports('OpenDispatch', function()
    if IsPlayerPolice() and not dispatchOpen then
        ToggleDispatch()
    end
end)

exports('CloseDispatch', function()
    if dispatchOpen then
        ToggleDispatch()
    end
end)

AddEventHandler('gameEventTriggered', function(name, args)
    if name == 'CEventNetworkEntityDamage' then
        local victim, attacker, damage, weapon = args[1], args[2], args[4], args[5]
        local attackerPed = PlayerPedId()

        if IsPedInAnyVehicle(attackerPed, false) then
            return
        end

        if attacker == attackerPed and Config.RealTimeDetection.ENABLED then
            local currentTime = GetGameTimer()
            local coords = GetEntityCoords(attackerPed)
            local isPolice = IsPlayerPolice()
            
            if Config.RealTimeDetection.EXCLUDE_POLICE and isPolice then
                return
            end
            
            local victimType = GetEntityType(victim)
            
            if victimType == 2 then
                return
            end
            
            if victimType == 3 then
                if currentTime - lastWeaponDamageTime > 5000 then
                    local location = GetStreetName(coords)
                    TriggerServerEvent('alpha-dispatch:server:fightDetected', coords, location)
                    lastWeaponDamageTime = currentTime
                end
                return
            end
            
            if meleeWeapons[weapon] or weapon == 0 then
                if currentTime - lastWeaponDamageTime > 5000 and victimType == 1 then
                    local location = GetStreetName(coords)
                    TriggerServerEvent('alpha-dispatch:server:fightDetected', coords, location)
                    lastWeaponDamageTime = currentTime
                end
            else
                if currentTime - lastWeaponDamageTime > 2000 and victimType == 1 then
                    local location = GetStreetName(coords)
                    TriggerServerEvent('alpha-dispatch:server:shotsDetected', weapon, coords, location)
                    lastWeaponDamageTime = currentTime
                end
            end
        end
    end
end)

AddEventHandler('gameEventTriggered', function(name, args)
    if name == 'CEventNetworkEntityDamage' then
        local victim = args[1]
        local victimType = GetEntityType(victim)
        
        if victimType == 3 then
            local currentTime = GetGameTimer()
            
            if currentTime - (lastObjectDamageTime or 0) > 5000 then
                local playerPed = PlayerPedId()
                local coords = GetEntityCoords(playerPed)
                local location = GetStreetName(coords)
                
                TriggerServerEvent('alpha-dispatch:server:fightDetected', coords, location)
                lastObjectDamageTime = currentTime
            end
        end
    end
end)

RegisterCommand('cleardispatchblips', function()
    if not IsPlayerPolice() then
        QBCore.Functions.Notify("You must be a police officer to use this command", "error")
        return
    end

    if dispatchBlips then
        for _, blipData in ipairs(dispatchBlips) do
            if DoesBlipExist(blipData.blip) then
                RemoveBlip(blipData.blip)
            end
        end
        dispatchBlips = {}
        QBCore.Functions.Notify("All dispatch blips cleared", "success")
    end
end, false)

RegisterCommand('showdispatchblips', function()
    if not IsPlayerPolice() then
        QBCore.Functions.Notify("You must be a police officer to use this command", "error")
        return
    end

    if dispatchBlips then
        for _, blipData in ipairs(dispatchBlips) do
            if not DoesBlipExist(blipData.blip) then
                local newBlip = AddBlipForCoord(blipData.coords.x, blipData.coords.y, blipData.coords.z)
                
                if blipData.priority == Config.Priority.HIGH then
                    SetBlipSprite(newBlip, 161)
                    SetBlipColour(newBlip, 1)
                    SetBlipScale(newBlip, 1.2)
                elseif blipData.priority == Config.Priority.MEDIUM then
                    SetBlipSprite(newBlip, 161)
                    SetBlipColour(newBlip, 5)
                    SetBlipScale(newBlip, 1.0)
                else
                    SetBlipSprite(newBlip, 161)
                    SetBlipColour(newBlip, 0)
                    SetBlipScale(newBlip, 0.8)
                end

                SetBlipAsShortRange(newBlip, false)
                BeginTextCommandSetBlipName("STRING")
                AddTextComponentString(blipData.title)
                EndTextCommandSetBlipName(newBlip)
                
                blipData.blip = newBlip
            end
        end
        QBCore.Functions.Notify("All dispatch blips restored", "success")
    end
end, false)


