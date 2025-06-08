local QBCore = exports['qb-core']:GetCoreObject()

local function IsPlayerPolice()
    local PlayerData = QBCore.Functions.GetPlayerData()
    return PlayerData.job and Config.IsPoliceJob(PlayerData.job.name)
end

local demoModeActive = false

RegisterCommand('movedispatch', function()
    if not IsPlayerPolice() then return end
        local isDispatchOpen = dispatchOpen
    
    if not isDispatchOpen then
        demoModeActive = true
        SendNUIMessage({
            type = 'openDemoDispatch'
        })
        SetNuiFocus(true, true)
        QBCore.Functions.Notify("Position Setup Mode: Drag the window to move, use S/M/L buttons to resize, or drag the right edge to adjust width. Click Save when done.", "primary", 7000)
    else
        SendNUIMessage({
            type = 'toggleMovable'
        })
        QBCore.Functions.Notify("Movable mode: Drag to move, S/M/L buttons to resize, or drag right edge to adjust width. Click Save when done.", "primary", 7000)
    end
end, false)

TriggerEvent('chat:addSuggestion', '/movedispatch', 'Toggle movable mode for the dispatch window (move, resize, and save position)')

RegisterKeyMapping('movedispatch', 'Toggle Dispatch Movable Mode', 'keyboard', Config.KeyMapping.MOVE_DISPATCH)

RegisterNUICallback('saveDispatchPosition', function(data, cb)
    SetResourceKvp('dispatch_position_x', tostring(data.x))
    SetResourceKvp('dispatch_position_y', tostring(data.y))
    
    if data.width then
        SetResourceKvp('dispatch_width', tostring(data.width))
    end
    
    if demoModeActive then
        demoModeActive = false
        SendNUIMessage({
            type = 'closeDemoDispatch'
        })
        SetNuiFocus(false, false)
        QBCore.Functions.Notify("Dispatch position saved successfully! It will be used whenever you open dispatch.", "success", 5000)
    end
    
    cb('ok')
end)

RegisterNUICallback('cancelDemoMode', function(data, cb)
    if demoModeActive then
        demoModeActive = false
        SendNUIMessage({
            type = 'closeDemoDispatch'
        })
        SetNuiFocus(false, false)
        QBCore.Functions.Notify("Position setup canceled. No changes were made to your dispatch position.", "error", 5000)
    end
    
    cb('ok')
end)

RegisterNUICallback('resetNuiFocus', function(data, cb)
    SetNuiFocus(false, false)
    cb('ok')
end)

 function LoadSavedDispatchPosition()
    local x = GetResourceKvpString('dispatch_position_x')
    local y = GetResourceKvpString('dispatch_position_y')
    local width = GetResourceKvpString('dispatch_width')
    
    if x and y then
        SendNUIMessage({
            type = 'setDispatchPosition',
            x = tonumber(x),
            y = tonumber(y),
            width = width and tonumber(width) or nil
        })
    end
end

 RegisterNetEvent('alpha-dispatch:client:dispatchOpened')
AddEventHandler('alpha-dispatch:client:dispatchOpened', function()
    LoadSavedDispatchPosition()
end)