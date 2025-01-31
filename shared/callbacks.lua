Callbacks = {}
cbData = {}
Callback = Callback or  {}

local resource = GetCurrentResourceName() or 'unknown'

local clientToServerName = resource .. ':server:CS:TriggerCallback'
local clientToServerBackToClientName = resource .. ':client:CSC:TriggerCallback'


local serverToClientName = resource .. ':client:SC:TriggerCallback'
local serverToClientBackToServerName = resource .. ':server:SCS:TriggerCallback'


exports('Callback', Callback)

if not IsDuplicityVersion() then goto client end

-- -- -- -- -- -- -- -- -- --
-- ▄▀▀ ██▀ █▀▄ █ █ ██▀ █▀▄ 
-- ▄█▀ █▄▄ █▀▄ ▀▄▀ █▄▄ █▀▄ 
-- -- -- -- -- -- -- -- -- --



-- client to server rebound
function Callback.Register(name, callback, all)
    Callback[name] = {
        callback = callback,
        toAll = all
    }
end

RegisterNetEvent(clientToServerName, function(name, ...)
    local src = source
    local data = Callback[name]
    if not data then return end   
    local func = data.callback
    if not func then return end
    local toAll = data.toAll and -1 or src
    local cb = function(...)
        TriggerClientEvent(clientToServerBackToClientName, toAll, name, ...)
    end
    func(src, cb, ...)
end)
-----------------------------

-- server to client rebound

function Callback.Trigger(name, src, func, ...)
    if src == nil then src = -1 end
    local p = promise.new()
    cbData[name] = {cb = func, p = p}
    if type(src) == 'table' then
        for i, d in pairs(src) do
            TriggerClientEvent(serverToClientName, tonumber(d), name, ...)
        end
        return Citizen.Await(p)
    end
    TriggerClientEvent(serverToClientName, tonumber(src), name, ...)
    return Citizen.Await(p)
end

RegisterNetEvent(serverToClientBackToServerName, function(name, ...)
    print('Rebound')
    local data = cbData[name]
    if not data then return end
    local func = data.cb
    if not func then return end
    data.p:resolve(func(...) or true)
    cbData[name] = nil
end)
-----------------------------
exports('RegisterCallback', Callback.Register)
exports('TriggerCallback', Callback.Trigger)


-- -- -- -- -- -- -- -- -- --
-- ▄▀▀ █   █ ██▀ █▄ █ ▀█▀ 
-- ▀▄▄ █▄▄ █ █▄▄ █ ▀█  █  
-- -- -- -- -- -- -- -- -- --
if IsDuplicityVersion() then return Callback end
::client::


cbRebounds = {}
function Callback.Register(name, callback, all)
    Callback[name] = {
        callback = callback,
    }
end


function Callback.RegisterRebound(name, callback)
    cbRebounds[name] = callback
end


-- client to server rebound
function Callback.Trigger(name, func, ...)   
    local p = promise.new()
    TriggerServerEvent(clientToServerName, name, ...)
    cbData[name] = {cb = func, p = p}
    CreateThread(function()
        Wait(5000)
        if cbData[name] then
            cbData[name].p:resolve()
            cbData[name] = nil
        end
    end)
    print('Triggered')
    return Citizen.Await(p)
end

RegisterNetEvent(clientToServerBackToClientName, function(name, ...)
    local clientRebound = cbRebounds[name]
    if clientRebound then
        clientRebound(...)
    end
    local data = cbData[name]
    if not data then return end
    local func = data.cb
    if not func then return end
    data.p:resolve(func(...) or true)
    cbData[name] = nil
end)
-----------------------------

-- server to client rebound
RegisterNetEvent(serverToClientName, function(name, ...)
    local data = Callback[name]
    if not data then return end
    local func = data.callback
    if not func then return end
    local cb = function(...)
        TriggerServerEvent(serverToClientBackToServerName, name, ...)
    end
    func(cb, ...)
end)
-----------------------------

exports('RegisterCallback', Callback.Register)
exports('RegisterRebound', Callback.RegisterRebound)
exports('TriggerCallback', Callback.Trigger)

return Callback