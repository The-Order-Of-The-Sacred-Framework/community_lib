loadedModules = {}

function Require(modulePath, resourceName)
    if resourceName and type(resourceName) ~= "string" then
        resourceName = GetCurrentResourceName()
    end

    if not resourceName then
        resourceName = "community_lib"
    end

    local id = resourceName .. ":" .. modulePath
    if loadedModules[id] then
        print("Returning cached module [" .. id .. "]")
        return loadedModules[id]
    end

    local file = LoadResourceFile(resourceName, modulePath)
    if not file then
        error("Error loading file [" .. id .. "]")
    end

    local chunk, loadErr = load(file, id)
    if not chunk then
        error("Error wrapping module [" .. id .. "] Message: " .. loadErr)
    end

    local success, result = pcall(chunk)
    if not success then
        error("Error executing module [" .. id .. "] Message: " .. result)
    end
    loadedModules[id] = result
    return result
end

cLib = {
    Require = Require,
    Callback = Callback or Require("shared/callbacks.lua"),
    Ids = Ids or Require("shared/ids.lua"),
    ReboundEntities = ReboundEntities or Require("shared/rebound_entities.lua"),
    Tables = Tables or Require("shared/tables.lua"),
    Math = Math or Require("shared/math.lua"),
    LA = LA or Require("shared/la.lua"),
    Perlin = Perlin or Require("shared/perlin.lua"),
}

exports('cLib', cLib)

if not IsDuplicityVersion() then goto client end

cLib.SQL = SQL or Require("server/sqlHandler.lua")
cLib.Logs = Logs or Require("server/logs.lua")
cLib.LootTables = LootTables or Require("server/lootTables.lua")

if IsDuplicityVersion() then return cLib end
::client::

cLib.Gizmo = Gizmo or Require("client/gizmo.lua")
cLib.Scaleform = Scaleform or Require("client/scaleform.lua")
cLib.Utility = Utility or Require("client/utility.lua")
cLib.PlaceableObject = PlaceableObject or Require("client/object_placer.lua")


return cLib