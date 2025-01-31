Scaleform = {}
local function SetupScaleform(scaleform, Buttons)
    local scaleform = RequestScaleformMovie(scaleform)
    local timeout = 5000
    while not HasScaleformMovieLoaded(scaleform) and timeout > 0 do
        timeout = timeout - 1
        Wait(0)
    end
    assert(timeout > 0, 'Scaleform failed to load')

    DrawScaleformMovieFullscreen(scaleform, 255, 255, 255, 0, 0)
    for i = 1,#Buttons do
        PushScaleformMovieFunction(scaleform, Buttons[i].type)
        if Buttons[i].int then PushScaleformMovieFunctionParameterInt(Buttons[i].int) end
        if Buttons[i].keyIndex then
            if type(Buttons[i].keyIndex) == "table" then
                for _, v in pairs(Buttons[i].keyIndex) do N_0xe83a3e3557a56640(GetControlInstructionalButton(2, v, true)) end
            else
                ScaleformMovieMethodAddParamPlayerNameString(GetControlInstructionalButton(2, Buttons[i].keyIndex[1], true))
            end
        end
        if Buttons[i].name then
            BeginTextCommandScaleformString("STRING")
            AddTextComponentScaleform(Buttons[i].name)
            EndTextCommandScaleformString()
        end
        if Buttons[i].type == 'SET_BACKGROUND_COLOUR' then
            for u = 1,4 do PushScaleformMovieFunctionParameterInt(80) end
        end
        PopScaleformMovieFunctionVoid()
    end
    return scaleform
end

function Scaleform.SetupInstructionalButtons(buttons)
    buttons = buttons or {
        -- {type = "CLEAR_ALL"},
        -- {type = "SET_CLEAR_SPACE", int = 200},
        -- {type = "SET_DATA_SLOT", name = config?.place_object?.name or 'Place Object:', keyIndex = config?.place_object?.key or {223}, int = 5},
        -- {type = "SET_DATA_SLOT", name = config?.cancel_placement?.name or 'Cancel Placement:', keyIndex = config?.cancel_placement?.key or {222}, int = 4},
        -- {type = "SET_DATA_SLOT", name = config?.snap_to_ground?.name or 'Snap to Ground:', keyIndex = config?.snap_to_ground?.key or {19}, int = 1},
        -- {type = "SET_DATA_SLOT", name = config?.rotate?.name or 'Rotate:', keyIndex = config?.rotate?.key or {14, 15}, int = 2},
        -- {type = "SET_DATA_SLOT", name = config?.distance?.name or 'Distance:', keyIndex = config?.distance?.key or {14,15,36}, int = 3},
        -- {type = "SET_DATA_SLOT", name = config?.toggle_placement?.name or 'Toggle Placement:', keyIndex = config?.toggle_placement?.key or {199}, int = 0},
        -- {type = "DRAW_INSTRUCTIONAL_BUTTONS"},
        -- {type = "SET_BACKGROUND_COLOUR"},
    }
    local scaleform = SetupScaleform("instructional_buttons", buttons)
    return scaleform
end

exports("Scaleform", Scaleform)
return Scaleform