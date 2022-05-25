REVIVE_CONTROL = 51
RESPAWN_CONTROL = 45
dead = false
deadinVeh = false
timeout = 6
hold = 4
start = false
animationWeapon = ''
weaponType = ''

-- Timeout & Respawn Loop --
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if dead then
            while timeout > 0 do
                timeout = timeout - 1
                Citizen.Wait(1000)
            end
        else
            timeout = 6
        end
        if start then
            while hold > 0 do
                hold = hold - 1
                Citizen.Wait(1000)
            end
        else
            hold = 4
        end
    end
end)

RegisterNetEvent("ItsMatOG:StopDeath")
AddEventHandler("ItsMatOG:StopDeath", function(status)
	dead = status
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        while dead and not deadinVeh do
            Citizen.Wait(0)
            RequestAnimDict('dead')
            TaskPlayAnim(PlayerPedId(), 'dead', 'dead_e', 8.0, -8.0, -1, 2, 0, false, false, false)
        end
    end
end)

local spawnpoints = {
    vector3(-496, -336, 35), -- Mount Zonah
    vector3(316, -583, 44), -- Pillbox Hill
    vector3(307, -1434, 30), -- Central Los Santos
    vector3(1816, 3679, 35), -- Sandy Shores
    vector3(-243, 6326, 33), -- Paleto
}

function GetClosestSpawn(table)
    local ClosestCoord = nil
    local ClosestDistance = 100000
    local playerPed = PlayerPedId()
    local Coord = GetEntityCoords(playerPed)
    for _, v in pairs(table) do
        local Distance = #(v - Coord)
        if Distance <= ClosestDistance then
            ClosestDistance = Distance
            ClosestCoord = v
        end
    end
    return ClosestCoord
end

-- Main Death Loop --
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        local ped = GetPlayerPed(-1)
        local vehicle = GetVehiclePedIsIn(ped, false)
        if IsEntityDead(ped) and not IsPedInVehicle(ped, vehicle, false) then
            local playerPos = GetEntityCoords(ped, true)
            SetCurrentPedWeapon(ped, GetHashKey("WEAPON_UNARMED"), true)
            ClearPedTasks(ped)
            Citizen.Wait(200)
            while not HasAnimDictLoaded('dead') do
                RequestAnimDict('dead')
                Wait(0)
            end
	        NetworkResurrectLocalPlayer(playerPos, true, true, false)
            RequestAnimDict('dead')
			TaskPlayAnim(PlayerPedId(), 'dead', 'dead_e', 8.0, -8.0, -1, 2, 0, false, false, false)
            SetPlayerInvincible(PlayerId(), true)
            SetEntityMaxHealth(ped, 200)
            SetPedArmour(ped, 0)
            dead = true
        elseif IsEntityDead(ped) and IsPedInVehicle(ped, vehicle, false) then
            SetCurrentPedWeapon(ped, GetHashKey("WEAPON_UNARMED"), true)
            SetPedArmour(ped, 0)
            dead = true
            deadinVeh = true
        end
        if IsEntityPlayingAnim(GetPlayerPed(PlayerId()), "dead", "dead_e", 3) then
            DisableControlAction(0, 37, true)
            DisableControlAction(0, 75, true)
            DisableControlAction(0, 289, true)
            SetPlayerInvincible(PlayerId(), true)
            if timeout > 0 then
                SetPlayerInvincible(PlayerId(), true)
                DisplayHelpText("~r~You have died, please wait . . .")
            elseif timeout == 0 then
                SetPlayerInvincible(PlayerId(), true)
                DisplayHelpText("Hold ~INPUT_CONTEXT~ to ~g~revive ~w~in place\nHold ~INPUT_RELOAD~ to ~b~respawn ~w~at a hospital.")
                while IsControlPressed(0, REVIVE_CONTROL) and dead do
                    Citizen.Wait(0)
                    start = true
                    SetPlayerInvincible(PlayerId(), true)
                    DrawMissionText("Hold for ~y~" .. hold .. " ~w~more second(s)...")
                    if IsControlJustReleased(0, REVIVE_CONTROL) and hold > 0 then
                        hold = 4
                    elseif IsControlPressed(0, REVIVE_CONTROL) and hold == 0 then
                        RevivePed(ped)
                    end
                end
                while IsControlPressed(0, RESPAWN_CONTROL) and dead do
                    Citizen.Wait(0)
                    start = true
                    SetPlayerInvincible(PlayerId(), true)
                    DrawMissionText("Hold for ~y~" .. hold .. " ~w~more second(s)...")
                    if IsControlJustReleased(0, RESPAWN_CONTROL) and hold > 0 then
                        hold = 4
                    elseif IsControlPressed(0, RESPAWN_CONTROL) and hold == 0 then
                        coords = GetClosestSpawn(spawnpoints)
				        RespawnPed(ped, coords)
                    end
                end
            end
        elseif IsEntityDead(ped) and deadinVeh then
            if timeout > 0 then
                drawNotification("~r~You have died, please wait . . .")
            elseif timeout == 0 then
                drawNotification("Hold [E] to ~g~revive ~w~in place\nHold [R] to ~b~respawn ~w~at a hospital.")
                while IsControlPressed(0, REVIVE_CONTROL) and dead do
                    Citizen.Wait(0)
                    start = true
                    SetPlayerInvincible(PlayerId(), true)
                    if IsControlJustReleased(0, REVIVE_CONTROL) and hold > 0 then
                        hold = 4
                    elseif IsControlPressed(0, REVIVE_CONTROL) and hold == 0 then
                        local playerPos = GetEntityCoords(ped, true)
                        NetworkResurrectLocalPlayer(playerPos, true, true, false)
                        RevivePed(ped)
                    end
                end
                while IsControlPressed(0, RESPAWN_CONTROL) and dead do
                    Citizen.Wait(0)
                    start = true
                    SetPlayerInvincible(PlayerId(), true)
                    if IsControlJustReleased(0, RESPAWN_CONTROL) and hold > 0 then
                        hold = 4
                    elseif IsControlPressed(0, RESPAWN_CONTROL) and hold == 0 then
                        coords = GetClosestSpawn(spawnpoints)
				        RespawnPed(ped, coords)
                    end
                end
            end
        end
    end
end)

AddEventHandler('onClientMapStart', function()
	exports.spawnmanager:spawnPlayer()
	Citizen.Wait(2500)
	exports.spawnmanager:setAutoSpawn(false)
end)

RegisterCommand('die', function(source)
    local playerPed = PlayerPedId()
    RequestAnimDict('mp_suicide')
    while not HasAnimDictLoaded('mp_suicide') do
        Citizen.Wait(0)
    end
    if HasPedGotWeapon(playerPed, GetHashKey('WEAPON_PISTOL'), false) then
        weaponType = 'weapon_pistol'
        animationWeapon = 'pistol'
    elseif HasPedGotWeapon(playerPed, GetHashKey('WEAPON_COMBATPISTOL'), false) then
        weaponType = 'weapon_combatpistol'
        animationWeapon = 'pistol'
    else
        weaponType = 'weapon_pill'
        animationWeapon = 'pill'
    end
    TriggerEvent("wwrp:setWaistbandAnim", false)
    SetCurrentPedWeapon(playerPed, GetHashKey(weaponType), true)
    if animationWeapon == 'pistol' then
        TaskPlayAnim(playerPed, "mp_suicide", "pistol", 8.0, 1.0, -1, 2, 0, 0, 0, 0)
        Citizen.Wait(500)
        SetPedShootRate(playerPed, 1000)
        SetPedShootsAtCoord(playerPed, 0.0, 0.0, 0.0, 0)
        Citizen.Wait(3000)
        ClearPedTasks(playerPed)
        ClearEntityLastDamageEntity(playerPed)
        SetEntityHealth(playerPed, 0)
    else
        TaskPlayAnim(playerPed, "mp_suicide", "pill", 8.0, 1.0, -1, 2, 0, 0, 0, 0)
        Citizen.Wait(5000)
        ClearPedTasks(playerPed)
        ClearEntityLastDamageEntity(playerPed)
        SetEntityHealth(playerPed, 0)
    end
end, false)
TriggerEvent("chat:addSuggestion", "/die", "Kill your player ped. Usage: /die")

RegisterCommand('revive', function(source)
    local ped = GetPlayerPed(-1)
    local vehicle = GetVehiclePedIsIn(ped, false)
    if IsEntityPlayingAnim(GetPlayerPed(PlayerId()), "dead", "dead_e", 3) then
        ClearPedTasks(ped)
        ClearPedTasksImmediately(ped)
        RevivePed(ped)
    elseif IsEntityDead(ped) and deadinVeh then
        local playerPos = GetEntityCoords(ped, true)
        NetworkResurrectLocalPlayer(playerPos, true, true, false)
        RevivePed(ped)
    end
end, false)
TriggerEvent("chat:addSuggestion", "/revive", "Revive yourself. Usage: /revive")

function RevivePed(ped)
    dead = false
    timeout = 6
    start = false
    hold = 4
    while not HasAnimDictLoaded('get_up@directional@movement@from_seated@injured') do
        RequestAnimDict('get_up@directional@movement@from_seated@injured')
        Wait(0)
    end
    PlaySoundFrontend(-1, "1st_Person_Transition", "PLAYER_SWITCH_CUSTOM_SOUNDSET", 1)
    Citizen.Wait(200)
    RequestAnimDict('get_up@directional@movement@from_seated@injured')
    TaskPlayAnim(PlayerPedId(), 'get_up@directional@movement@from_seated@injured', 'getup_l_0', 8.0, -8.0, 2000, 2, 0, false, false, false)
    drawNotification("~g~Revived: ~w~You have been revived in place.")
    Citizen.Wait(2000)
    ClearPedTasks(ped)
    SetEntityMaxHealth(ped, 200)
    StopEntityFire(GetPlayerPed(-1))
	isInvincible = false
	ClearPedBloodDamage(ped)
end

function RespawnPed(ped, coords)
    dead = false
    timeout = 6
    start = false
    hold = 4
    PlaySoundFrontend(-1, "Zoom_Out", "DLC_HEIST_PLANNING_BOARD_SOUNDS", 1)
    DoScreenFadeOut(500)
    Citizen.Wait(2000)
	ClearPedTasks(ped)
    SetEntityMaxHealth(ped, 200)
	SetEntityCoordsNoOffset(ped, coords.x, coords.y, coords.z, false, false, false, true)
	NetworkResurrectLocalPlayer(coords.x, coords.y, coords.z, 0.0, true, false)
	SetPlayerInvincible(ped, false) 
	TriggerEvent('playerSpawned', coords.x, coords.y, coords.z, 0.0)
	ClearPedBloodDamage(ped)
    DoScreenFadeIn(500)
    PlaySoundFrontend(-1, "Zoom_In", "DLC_HEIST_PLANNING_BOARD_SOUNDS", 1)
    drawNotification("~w~You have been ~b~respawned ~w~at the ~y~nearest hospital~w~.")
end

function drawNotification(text)
    SetNotificationTextEntry("STRING")
    AddTextComponentString(text)
    DrawNotification(false, false)
end

function DisplayHelpText(text)
    SetTextComponentFormat("STRING")
    AddTextComponentString(text)
    DisplayHelpTextFromStringLabel(0, 0, 0, -1)
end

function DrawMissionText(msg, time)
	ClearPrints()
	BeginTextCommandPrint('STRING')
	AddTextComponentSubstringPlayerName(msg)
	EndTextCommandPrint(time, true)
end