-- test = {
--     {
--         model = "prop_tv_flat_01",
--         position = vector3(-1374.42, -527.81, 30.41),
--         rotation = vector3(0.0, 0.0, 0.0),
--         test = "This is a test"
--     },
--     {
--         model = "prop_tv_flat_01",
--         position = vector3(-1374.42 + 1.0, -527.81, 30.41),
--         rotation = vector3(0.0, 0.0, 0.0),
--     },
-- }

-- if not IsDuplicityVersion() then goto client end
-- -- -- -- -- -- -- -- -- -- --
-- -- ▄▀▀ ██▀ █▀▄ █ █ ██▀ █▀▄
-- -- ▄█▀ █▄▄ █▀▄ ▀▄▀ █▄▄ █▀▄
-- -- -- -- -- -- -- -- -- -- --
-- _entityData = CreateReboundEntity(test[1])
-- SetReboundSyncData(_entityData, "occupied", true)


-- if not IsDuplicityVersion() then return end
-- ::client::

-- AddRegisteredFunction(function(entityData)
--     print(entityData.id)
--     if entityData.test then
--         print("Entity with test has been registered: " .. entityData.test)
--         SetOnSpawn(entityData, function()
--             print("Entity with test has spawned for local player: " .. entityData.test, entityData.occupied)
--         end)
--         SetOnSyncKeyChange(entityData, function(entityData, key, value)
--             print("Entity with test has changed key: " .. key .. " to " .. value)
--         end)
--     end
-- end)


