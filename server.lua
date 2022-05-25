RegisterNetEvent('ItsMatOG:cancelDeath')
AddEventHandler('ItsMatOG:cancelDeath', function(player, status)
    TriggerClientEvent('ItsMatOG:StopDeath', player, status)
end)