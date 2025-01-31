-- Credit: https://github.com/citizenfx/lua/blob/luaglm-dev/cfx/libs/scripts/examples/dataview.lua
local dataView = setmetatable({
    EndBig = ">",
    EndLittle = "<",
    Types = {
        Int8 = { code = "i1" },
        Uint8 = { code = "I1" },
        Int16 = { code = "i2" },
        Uint16 = { code = "I2" },
        Int32 = { code = "i4" },
        Uint32 = { code = "I4" },
        Int64 = { code = "i8" },
        Uint64 = { code = "I8" },
        Float32 = { code = "f", size = 4 }, -- a float (native size)
        Float64 = { code = "d", size = 8 }, -- a double (native size)

        LuaInt = { code = "j" }, -- a lua_Integer
        UluaInt = { code = "J" }, -- a lua_Unsigned
        LuaNum = { code = "n" }, -- a lua_Number
        String = { code = "z", size = -1, }, -- zero terminated string
    },

    FixedTypes = {
        String = { code = "c" }, -- a fixed-sized string with n bytes
        Int = { code = "i" }, -- a signed int with n bytes
        Uint = { code = "I" }, -- an unsigned int with n bytes
    },
}, {
    __call = function(_, length)
        return dataView.ArrayBuffer(length)
    end
})
dataView.__index = dataView

--[[ Create an ArrayBuffer with a size in bytes --]]
function dataView.ArrayBuffer(length)
    return setmetatable({
        blob = string.blob(length),
        length = length,
        offset = 1,
        cangrow = true,
    }, dataView)
end

--[[ Wrap a non-internalized string --]]
function dataView.Wrap(blob)
    return setmetatable({
        blob = blob,
        length = blob:len(),
        offset = 1,
        cangrow = true,
    }, dataView)
end

--[[ Return the underlying bytebuffer --]]
function dataView:Buffer() return self.blob end
function dataView:ByteLength() return self.length end
function dataView:ByteOffset() return self.offset end
function dataView:SubView(offset, length)
    return setmetatable({
        blob = self.blob,
        length = length or self.length,
        offset = 1 + offset,
        cangrow = false,
    }, dataView)
end

--[[ Return the Endianness format character --]]
local function ef(big) return (big and dataView.EndBig) or dataView.EndLittle end

--[[ Helper function for setting fixed datatypes within a buffer --]]
local function packblob(self, offset, value, code)
    -- If cangrow is false the dataview represents a subview, i.e., a subset
    -- of some other string view. Ensure the references are the same before
    -- updating the subview
    local packed = self.blob:blob_pack(offset, code, value)
    if self.cangrow or packed == self.blob then
        self.blob = packed
        self.length = packed:len()
        return true
    else
        return false
    end
end

--[[
    Create the API by using dataView.Types
--]]
for label,datatype in pairs(dataView.Types) do
    if not datatype.size then  -- cache fixed encoding size
        datatype.size = string.packsize(datatype.code)
    elseif datatype.size >= 0 and string.packsize(datatype.code) ~= datatype.size then
        local msg = "Pack size of %s (%d) does not match cached length: (%d)"
        error(msg:format(label, string.packsize(datatype.code), datatype.size))
        return nil
    end

    dataView["Get" .. label] = function(self, offset, endian)
        offset = offset or 0
        if offset >= 0 then
            local o = self.offset + offset
            local v,_ = self.blob:blob_unpack(o, ef(endian) .. datatype.code)
            return v
        end
        return nil
    end

    dataView["Set" .. label] = function(self, offset, value, endian)
        if offset >= 0 and value then
            local o = self.offset + offset
            local v_size = (datatype.size < 0 and value:len()) or datatype.size
            if self.cangrow or ((o + (v_size - 1)) <= self.length) then
                if not packblob(self, o, value, ef(endian) .. datatype.code) then
                    error("cannot grow subview")
                end
            else
                error("cannot grow dataview")
            end
        end
        return self
    end
end

for label,datatype in pairs(dataView.FixedTypes) do
    datatype.size = -1 -- Ensure cached encoding size is invalidated

    dataView["GetFixed" .. label] = function(self, offset, typelen, endian)
        if offset >= 0 then
            local o = self.offset + offset
            if (o + (typelen - 1)) <= self.length then
                local code = ef(endian) .. "c" .. tostring(typelen)
                local v,_ = self.blob:blob_unpack(o, code)
                return v
            end
        end
        return nil -- Out of bounds
    end

    dataView["SetFixed" .. label] = function(self, offset, typelen, value, endian)
        if offset >= 0 and value then
            local o = self.offset + offset
            if self.cangrow or ((o + (typelen - 1)) <= self.length) then
                local code = ef(endian) .. "c" .. tostring(typelen)
                if not packblob(self, o, value, code) then
                    error("cannot grow subview")
                end
            else
                error("cannot grow dataview")
            end
        end
        return self
    end
end


-- CREDITS
-- Andyyy7666: https://github.com/overextended/ox_lib/pull/453
-- AvarianKnight: https://forum.cfx.re/t/allow-drawgizmo-to-be-used-outside-of-fxdk/5091845/8?u=demi-automatic
local dataview = dataView
local enableScale = false -- allow scaling mode. doesnt scale collisions and resets when physics are applied it seems
local gizmoEnabled = false
local currentMode = 'translate'
local isRelative = false
local currentEntity

-- FUNCTIONS

local function normalize(x, y, z)
    local length = math.sqrt(x * x + y * y + z * z)
    if length == 0 then
        return 0, 0, 0
    end
    return x / length, y / length, z / length
end

local identityMatrix = {
    vector3(1, 0, 0),
    vector3(0, 1, 0),
    vector3(0, 0, 1)
}
local function makeEntityMatrix(entity)
    local f, r, u, a = GetEntityMatrix(entity)
    local view = dataview.ArrayBuffer(60)

    view:SetFloat32(0, r[1])
        :SetFloat32(4, r[2])
        :SetFloat32(8, r[3])
        :SetFloat32(12, 0)
        :SetFloat32(16, f[1])
        :SetFloat32(20, f[2])
        :SetFloat32(24, f[3])
        :SetFloat32(28, 0)
        :SetFloat32(32, u[1])
        :SetFloat32(36, u[2])
        :SetFloat32(40, u[3])
        :SetFloat32(44, 0)
        :SetFloat32(48, a[1])
        :SetFloat32(52, a[2])
        :SetFloat32(56, a[3])
        :SetFloat32(60, 1)

    return view
end

local function applyEntityMatrix(entity, view)
    local x1, y1, z1 = view:GetFloat32(16), view:GetFloat32(20), view:GetFloat32(24)
    local x2, y2, z2 = view:GetFloat32(0), view:GetFloat32(4), view:GetFloat32(8)
    local x3, y3, z3 = view:GetFloat32(32), view:GetFloat32(36), view:GetFloat32(40)
    local tx, ty, tz = view:GetFloat32(48), view:GetFloat32(52), view:GetFloat32(56)

    if not enableScale then
        x1, y1, z1 = normalize(x1, y1, z1)
        x2, y2, z2 = normalize(x2, y2, z2)
        x3, y3, z3 = normalize(x3, y3, z3)
    end

    SetEntityMatrix(entity,
        x1, y1, z1,
        x2, y2, z2,
        x3, y3, z3,
        tx, ty, tz
    )
end

-- LOOPS

function RegisterButtonHandler(button, onPressed, onReleased)
    onPressed = onPressed and type(onPressed) == 'function' and onPressed
    onReleased = onReleased and type(onReleased) == 'function' and onReleased
    DisableControlAction(0, button, true)
    local pressed = IsDisabledControlJustPressed(0, button)
    local released = IsDisabledControlJustReleased(0, button)
    return (pressed and onPressed and onPressed()) or (released and onReleased and onReleased())
end


local function gizmoLoop(entity, onConfirm, onUpdate, onCancel)
    EnterCursorMode()

    if IsEntityAPed(entity) then
        SetEntityAlpha(entity, 200)
    else
        SetEntityDrawOutline(entity, true)
    end

    while gizmoEnabled and DoesEntityExist(entity) do
        Wait(0)
        
        DisableControlAction(0, 24, true)  -- lmb
        DisableControlAction(0, 25, true)  -- rmb
        DisableControlAction(0, 140, true) -- r
        DisableControlAction(0, 245, true) --t
        DisablePlayerFiring(PlayerId(), true)

        local matrixBuffer = makeEntityMatrix(entity)
        local changed = DrawGizmo(matrixBuffer:Buffer(), 'Editor1')
        if changed then
            print(GetEntityCoords(entity))
            applyEntityMatrix(entity, matrixBuffer)
            SetEntityCoords(entity, GetEntityCoords(entity))
        end

        if onUpdate and type(onUpdate) == 'function' then onUpdate(entity, GetEntityCoords(entity), GetEntityRotation(entity)) end
        --controles
        --frontend confirm 18 [ENTER]
        RegisterButtonHandler(191, function()
            if not gizmoEnabled then return end
            gizmoEnabled = false
            if onConfirm and type(onConfirm) == 'function' then onConfirm(entity, GetEntityCoords(entity), GetEntityRotation(entity)) end
        end)
        --frontend cancel 202 [BACKSPACE]
        RegisterButtonHandler(202, function()
            if not gizmoEnabled then return end
            gizmoEnabled = false
            if onCancel and type(onCancel) == 'function' then onCancel(entity, GetEntityCoords(entity), GetEntityRotation(entity)) end
            CreateThread(function()
                local timeout = 100
                while timeout > 0 do
                    DisableFrontendThisFrame()
                    timeout = timeout - 1
                    Wait(1)
                end
            end)
        end)
        --register e
        RegisterButtonHandler(38, function()
            if not gizmoEnabled then return end
            gizmoEnabled = false      
            local playerPos = GetEntityCoords(PlayerPedId())
            local entityPos = GetFinalRenderedCamCoord()
            local depth = #(playerPos - entityPos) -- Vector3 distance
            Utility.CreatePlaceableObject({spawned = entity}, nil, onConfirm, onUpdate, onCancel, {depth = depth})
        end)

        --ctrl
        RegisterButtonHandler(36, function()
            if not gizmoEnabled then return end
            LeaveCursorMode()
        end, function()
            EnterCursorMode()
        end)

        RegisterButtonHandler(19, function()
            if not gizmoEnabled then return end
            PlaceObjectOnGroundProperly_2(currentEntity)
        end)
    end

    LeaveCursorMode()

    if DoesEntityExist(entity) then
        if IsEntityAPed(entity) then SetEntityAlpha(entity, 255) end
        SetEntityDrawOutline(entity, false)
    end

    gizmoEnabled = false
    currentEntity = nil
    return true
end

-- local function textUILoop()
--     CreateThread(function()
--         while gizmoEnabled do
--             Wait(100)
--             local scaleText = (enableScale and '[S]     - Scale Mode  \n') or ''
--             lib.showTextUI(
--                 ('Current Mode: %s | %s  \n'):format(currentMode, (isRelative and 'Relative') or 'World') ..
--                 '[W]     - Translate Mode  \n' ..
--                 '[R]     - Rotate Mode  \n' ..
--                 scaleText ..
--                 '[Q]     - Relative/World  \n' ..
--                 '[LALT]  - Snap To Ground  \n' ..
--                 '[ENTER] - Done Editing  \n'
--             )
--         end
--         lib.hideTextUI()
--     end)
-- end

-- EXPORTS


local function useGizmo(entity, onConfirm, onUpdate, onCancel)
    gizmoEnabled = true
    currentEntity = entity
    -- textUILoop()
    gizmoLoop(entity, onConfirm, onUpdate, onCancel)

    return {
        handle = entity,
        position = GetEntityCoords(entity),
        rotation = GetEntityRotation(entity)
    }
end

exports("useGizmo", useGizmo)

Gizmo = {}
local running = false
function Gizmo.UseGizmo(obj, onConfirm, onUpdate, onCancel)
    if running then return end
    running = true

    --instructional buttons
    local scaleform = Scaleform.SetupInstructionalButtons({
        {type = "CLEAR_ALL"},
        {type = "SET_CLEAR_SPACE", int = 200},
        {type = "SET_DATA_SLOT", name = 'Translate:', keyIndex = {245}, int = 1},
        {type = "SET_DATA_SLOT", name = 'Scale:', keyIndex = {33}, int = 2},
        {type = "SET_DATA_SLOT", name = 'Rotate:', keyIndex = {45}, int = 3},
        {type = "SET_DATA_SLOT", name = 'Snap to Ground:', keyIndex = {19}, int = 4},
        {type = "SET_DATA_SLOT", name = 'Toggle Camera:', keyIndex = {36}, int = 5},
        {type = "SET_DATA_SLOT", name = 'Cancel Placement:', keyIndex = {202}, int = 6},
        {type = "SET_DATA_SLOT", name = 'Toggle Gizmo:', keyIndex = {38}, int = 7},
        {type = "DRAW_INSTRUCTIONAL_BUTTONS"},
        {type = "SET_BACKGROUND_COLOUR"},
    })
    local quit = false
    CreateThread(function()
        while not quit do
            DrawScaleformMovieFullscreen(scaleform, 255, 255, 255, 255, 0)
            Wait(0)
        end
        running = false
    end)

    quit = useGizmo(obj, onConfirm, onUpdate, onCancel)
    running = false
end
exports("UseGizmo", Gizmo.UseGizmo)


--got rid of the cancer
-- lib.addKeybind({
--     name = '_gizmoLocal',
--     description = 'toggle gizmo to be local to the entity instead of world',
--     defaultKey = 'Q',
--     onPressed = function(self)
--         if not gizmoEnabled then return end
--         isRelative = not isRelative
--         ExecuteCommand('+gizmoLocal')
--     end,
--     onReleased = function (self)
--         ExecuteCommand('-gizmoLocal')
--     end
-- })

-- lib.addKeybind({
--     name = 'gizmoclose',
--     description = 'close gizmo',
--     defaultKey = 'RETURN',
--     onPressed = function(self)
--         if not gizmoEnabled then return end
--         gizmoEnabled = false
--     end,
-- })

-- lib.addKeybind({
--     name = 'gizmoSnapToGround',
--     description = 'snap current gizmo object to floor/surface',
--     defaultKey = 'LMENU',
--     onPressed = function(self)
--         if not gizmoEnabled then return end
--         PlaceObjectOnGroundProperly_2(currentEntity)
--     end,
-- })

-- if enableScale then
--     lib.addKeybind({
--         name = '_gizmoScale',
--         description = 'Sets mode for the gizmo to scale',
--         defaultKey = 'S',
--         onPressed = function(self)
--             if not gizmoEnabled then return end
--             currentMode = 'Scale'
--             ExecuteCommand('+gizmoScale')
--         end,
--         onReleased = function (self)
--             ExecuteCommand('-gizmoScale')
--         end
--     })
-- end


--onreousrcestop

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        if not gizmoEnabled then return end
        gizmoEnabled = false
        LeaveCursorMode()
    end
end)

return Gizmo