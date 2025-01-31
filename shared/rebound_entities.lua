-- -- -- -- -- -- -- -- -- --
-- ▄▀▀ █▄█ ▄▀▄ █▀▄ ██▀ █▀▄ --
-- ▄█▀ █ █ █▀█ █▀▄ █▄▄ █▄▀ --
-- -- -- -- -- -- -- -- -- --
local Entities = {}
local isServer = IsDuplicityVersion()

local registeredFunctions = {}
ReboundEntities = {}

--- Global Add function which fire when an entity is registered
--- @param func function = function(entityData: table)
--- @return number = ID
function ReboundEntities.AddFunction(func)
    assert(func, "Func is nil")
    assert(type(func) == "function", "Func is not a function")
    table.insert(registeredFunctions, func)
    return #registeredFunctions
end

--- Remove a registered function
--- @param id number
function ReboundEntities.RemoveFunction(id)
    assert(id, "ID is nil")
    assert(registeredFunctions[id], "ID not found")
    registeredFunctions[id] = false
end

--- Internal: Fire all registered functions
--- @vararg any
local function FireFunctions(...)
    for k, v in pairs(registeredFunctions) do
        if v then
            v(...)
        end
    end
end

--- Convert a table to an entityData object
--- @param entityData table = {model: string, position: vector3, id: string || nil}
--- @return table = {model: string, position: vector3, id: string, entity: number, isServer: boolean || nil}
function ReboundEntities.Register(entityData)
    assert(entityData, "Entity data is nil")
    local position = entityData.position
    assert(position, "Position is nil")
    local id = entityData.id or Ids.CreateUniqueId(Entities)
    entityData.isServer = isServer
    entityData.id = tostring(id)
    local entityData = setmetatable(entityData, {
        __tostring = function()
            return entityData.id
        end
    })
    Entities[id] = entityData
    FireFunctions(entityData)
    return entityData
end

-- Internal
local function Unregister(id)
    Entities[id] = nil
end

function ReboundEntities.GetSyncData(entityData, key)
    return entityData[key]
end

--- Get all entityDatas registered
--- @return table = {entityData: table}
function ReboundEntities.GetAll()
    return Entities
end

--- Get an entityData by its id
--- @param id string
--- @return table = {model: string, position: vector3, id: string, entity: number, isServer: boolean}
function ReboundEntities.GetById(id)
    id = tostring(id)
    return Entities[id]
end

--- Get all entities by their model
--- @param model string
--- @return table = {entityData: table}
function ReboundEntities.GetByModel(model)
    local entities = {}
    for k, v in pairs(Entities) do
        if v.model == model then
            table.insert(entities, v)
        end
    end
    return entities
end

--- Get the closest entityData to a position
--- @param pos vector3
--- @return table = {model: string, position: vector3, id: string, entity: number, isServer: boolean}
function ReboundEntities.GetClosest(pos)
    local closest = nil
    local closestDist = 9999
    for k, v in pairs(Entities) do
        local dist = #(pos - v.pos)
        if dist < closestDist then
            closest = v
            closestDist = dist
        end
    end
    return closest
end

--- Get all entities within a radius of a position
--- @param pos vector3
--- @param radius number
--- @return table = {entityData: table}
function ReboundEntities.GetWithinRadius(pos, radius)
    local entities = {}
    for k, v in pairs(Entities) do
        local dist = #(pos - v.pos)
        if dist < radius then
            table.insert(entities, v)
        end
    end
    return entities
end

function ReboundEntities.SetOnSyncKeyChange(entityData, cb)
    entityData.onSyncKeyChange = cb
end

exports('ReboundEntities', ReboundEntities)

if not isServer then goto client end
-- -- -- -- -- -- -- -- -- --
-- ▄▀▀ ██▀ █▀▄ █ █ ██▀ █▀▄ --
-- ▄█▀ █▄▄ █▀▄ ▀▄▀ █▄▄ █▀▄ --
-- -- -- -- -- -- -- -- -- --

--- Create a rebound entity
--- @param entityData object = {model: string, position: vector3, rotation: vector3 || nil}
--- @param src number = Who to send to. Defaults: -1
--- @return table = {model: string, position: vector3, rotation: vector3, id: string, entity: number, isServer: boolean}
function ReboundEntities.Create(entityData, src)
    local entity = ReboundEntities.Register(entityData)
    assert(entity, "Failed to register entity")
    assert(entity.position, "Entity position is nil")
    entity.rotation = entity.rotation or vector3(0, 0, 0)
    src = src and tonumber(src) or -1
    TriggerClientEvent("mrc-entity:client:CreateReboundEntity", src, entity)
    return entity
end

function ReboundEntities.SetCheckRestricted(entityData, cb)
    assert(type(cb) == "function", "Check restricted is not a function")
    entityData.restricted = cb
end

function ReboundEntities.CheckRestricted(src, entityData)
    src = tonumber(src)
    if not entityData.restricted then return false end
    if src == -1 then return true end
    return entityData.restricted(src, entityData) or false
end

function ReboundEntities.Refresh(src)
    src= tonumber(src)
    local list = ReboundEntities.GetAccessibleList(src)
    TriggerClientEvent("mrc-entity:client:CreateReboundEntities", src, list)
end

--- Delete a rebound entity
--- @param id string = The entity id: string || entityData: object
--- @return boolean
function ReboundEntities.Delete(id)
    Unregister(id)
    TriggerClientEvent("mrc-entity:client:DeleteReboundEntity", -1, id)
end

-- Create multiple rebound entities
--- @param entityDatas table = {entityData: object}
--- @param src number = Who to send to. Defaults: -1
--- @return table = {entityData: object}
function ReboundEntities.CreateMultiple(entityDatas, src, restricted)
    src = src and tonumber(src) or -1
    local _entityDatas = {}
    for k, v in pairs(entityDatas) do
        local entity = ReboundEntities.Register(v)
        assert(entity, "Failed to register entity")
        assert(entity.position, "Entity position is nil")
        entity.rotation = entity.rotation or vector3(0, 0, 0)
        
        if restricted then 
            ReboundEntities.SetCheckRestricted(entity, restricted)
        end
        if not ReboundEntities.CheckRestricted(src, entity) then
            _entityDatas[entity.id] = entity
        end
    end
   
    TriggerClientEvent("mrc-entity:client:CreateReboundEntities", src, _entityDatas)
    return _entityDatas
end

--- Sets data to be synced to clients for a rebound entity
--- @param entityData object = {model: string, position: vector3, rotation: vector3, id: string, entity: number, isServer: boolean}
--- @param key string
--- @param value any
function ReboundEntities.SetSyncData(entityData, key, value)
    if entityData.onSyncKeyChange then
        value = entityData.onSyncKeyChange(entityData, key, value) or value
    end
    entityData[key] = value
    TriggerClientEvent("mrc-entity:client:SetReboundSyncData", -1, entityData.id, key, value)
end

function ReboundEntities.GetAccessibleList(src)
    src = tonumber(src)
    local list = {}
    for k, data in pairs(ReboundEntities.GetAll()) do
        if not ReboundEntities.CheckRestricted(src, data) then
            list[data.id] = data
        end
    end
    return list
end

RegisterNetEvent("playerJoining", function(src, _)
    ReboundEntities.Refresh(src)
end)

AddEventHandler('onResourceStart', function(resource)
    if resource == GetCurrentResourceName() then
        Wait(1000)
        local players = GetPlayers()
        for k, src in pairs(players) do
            ReboundEntities.Refresh(src)
        end
    end
end)

::client::
if isServer then return ReboundEntities end
-- -- -- -- -- -- -- -- -- --
--  ▄▀▀ █   █ ██▀ █▄ █ ▀█▀ --
--  ▀▄▄ █▄▄ █ █▄▄ █ ▀█  █  --
-- -- -- -- -- -- -- -- -- --

--- Loads a model into memory
--- @param model : Model name <string> || Model hash <number>
--- @return modelHash : number
function ReboundEntities.LoadModel(model)
    assert(model, "Model is nil")
    model = type(model) == "number" and model or GetHashKey(model)
    local timeout = 100
    RequestModel(model)
    while not HasModelLoaded(model) and timeout > 0 do
        timeout = timeout - 1
        Wait(100)
    end
    assert(timeout > 0, string.format("Failed to load model %s", model))
    return model
end

--- Spawns an entity
--- @param entityData : table = {model: string, position: vector3, rotation: vector3 || nil, onSpawn: function || nil}
--- @return entity : number
function ReboundEntities.Spawn(entityData)
    local model = entityData.model
    local position = entityData.position
    assert(position, "Position is nil")
    local rotation = entityData.rotation or vector3(0, 0, 0)
    local entity = nil
    if model then 
        model = ReboundEntities.LoadModel(model)
        entity = CreateObject(model, position.x, position.y, position.z, false, false, false)
        SetEntityRotation(entity, rotation.x, rotation.y, rotation.z)
    end

    local onSpawn = entityData.onSpawn
    if onSpawn and type(onSpawn) == "function" then
        onSpawn(entityData, entity)
    end
    -- dont forget to save the entity to the entityData table in the spawn loop
    return entity, true
end

--- Set the onSpawn callback for an entity. Triggered after the entity is created.
--- @param id : string || entityData : object
--- @param cb : function(entityData: object, entity: number)
--- @return success : boolean
function ReboundEntities.SetOnSpawn(id, cb)
    id = tostring(id)
    local entity = ReboundEntities.GetById(id)
    assert(entity, "Entity not found")
    entity.onSpawn = cb
    return true
end

--- Despawns an entity
--- @param entityData : entity || table = {entity: number, onDespawn: function || nil}
function ReboundEntities.Despawn(entityData)
    assert(entityData, "Entity data is nil")
    local entity = entityData.entity
    local onDespawn = entityData.onDespawn
    if onDespawn and type(onDespawn) == "function" then
        onDespawn(entityData, entity)
    end
    if entity and DoesEntityExist(entity) then 
        DeleteEntity(entity)   
    end
    return nil, nil
end

--- Set the onDespawn callback for an entity. Triggered before the entity is deleted.
--- @param id : string || entityData : object
--- @param cb : function(entityData: object, entity: number)
--- @return success : boolean
function ReboundEntities.SetOnDespawn(id, cb)
    id = tostring(id)
    local entity = ReboundEntities.GetById(id)
    assert(entity, "Entity not found")
    entity.onDespawn = cb
    return true
end

local spawnLoopRunning = false

--- Internal function to spawn entities in a loop
--- @param distanceToCheck : number || nil
--- @param waitTime : number || nil
function ReboundEntities.SpawnLoop(distanceToCheck, waitTime)
    if spawnLoopRunning then return end
    spawnLoopRunning = true
    distanceToCheck = distanceToCheck or 50
    waitTime = waitTime or 2500
    CreateThread(function()
        while spawnLoopRunning do
            for k, v in pairs(Entities) do
                if not v.restricted then 
                    local pos = GetEntityCoords(PlayerPedId())
                    local dist = #(pos - v.position)
                    if dist <= distanceToCheck and (not v.entity and not v.inRange) then
                        v.entity, v.inRange = ReboundEntities.Spawn(v)
                    elseif dist > distanceToCheck and (v.entity or v.inRange) then
                        v.entity, v.inRange = ReboundEntities.Despawn(v)
                    end
                elseif v.entity then
                    v.entity = ReboundEntities.Despawn(v)
                end
            end
            Wait(waitTime)
        end
    end)
end

--- Get an entity by its entity number
--- @param entity : number
--- @return entityData : table
function ReboundEntities.GetByEntity(entity)
    for k, v in pairs(Entities) do
        if v.entity == entity then
            return v
        end
    end
end

--- Create a client side only, rebound entity
--- @param entityData : table = {model: string, position: vector3, rotation: vector3 || nil}
--- @return entity : table
function ReboundEntities.CreateClient(entityData)
    local entity = ReboundEntities.Register(entityData)
    if not entity then return end
    ReboundEntities.SpawnLoop()
    return entity
end

--- Delete a client side only, rebound entity
--- @param id : string || entityData : table
--- @return success : boolean
function ReboundEntities.DeleteClient(id)
    id = tostring(id)
    local entityData = ReboundEntities.GetById(id)
    local isServer = entityData.isServer
    assert(not isServer, "Cannot delete server entity from client")
    local entity = entityData.entity
    if entity then
        ReboundEntities.Despawn(entityData)
    end
    Unregister(id)
    return true
end

--- Create multiple client only, rebound entities
--- @param entityDatas : table = {entityData: table = {model: string, position: vector3, rotation: vector3 || nil}}
--- @return _entityDatas : objects
function ReboundEntities.CreateMultipleClient(entityDatas)
    local _entityDatas = {}
    for k, v in pairs(entityDatas) do
        local entityData = ReboundEntities.CreateClient(v)
        entityDatas[entityData.id] = entityData
    end
    return _entityDatas
end

--- Delete multiple client only, rebound entities
--- @param ids : table = {string || entityData: table}
function ReboundEntities.DeleteMultipleClient(ids)
    for k, v in pairs(ids) do
        ReboundEntities.DeleteClient(v)
    end
end

-- -- -- -- internal -- -- -- --
local function DeleteFromServer(id)
    id = tostring(id)
    local entityData = ReboundEntities.GetById(id)
    if not entityData then return end
    entityData.isServer = nil
    ReboundEntities.DeleteClient(id)
end

local function DeleteMultipleFromServer(ids)
    for k, v in pairs(ids) do
        DeleteFromServer(v)
    end
end
-- -- -- -- -- -- -- -- -- --

RegisterNetEvent("mrc-entity:client:CreateReboundEntity", function(entityData)
    ReboundEntities.CreateClient(entityData)
end)

RegisterNetEvent("mrc-entity:client:DeleteReboundEntity", function(id)
    DeleteFromServer(id)
end)

RegisterNetEvent("mrc-entity:client:CreateReboundEntities", function(entityDatas)
    ReboundEntities.CreateMultipleClient(entityDatas)
end)

RegisterNetEvent("mrc-entity:client:DeleteReboundEntities", function(ids)
    DeleteMultipleFromServer(ids)
end)

RegisterNetEvent("mrc-entity:client:SetReboundSyncData", function(id, key, value)
    local entityData = ReboundEntities.GetById(id)
    if not entityData then return end
    if entityData.onSyncKeyChange then
        value = entityData.onSyncKeyChange(entityData, key, value) or value
    end
    entityData[key] = value
end)

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        spawnLoopRunning = false
        for k, v in pairs(Entities) do
            if v.entity then
                DeleteEntity(tonumber(v.entity))
            end
        end
    end
end)

return ReboundEntities
