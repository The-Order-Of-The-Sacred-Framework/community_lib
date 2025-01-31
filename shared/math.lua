Math = {}

function Math.Clamp(value, min, max)
    return math.min(math.max(value, min), max)
end

function Math.Remap(value, min, max, newMin, newMax)
    return newMin + (value - min) / (max - min) * (newMax - newMin)
end

function Math.PointInRadius(radius)
    local angle = math.rad(math.random(0, 360))
    return vector2(radius * math.cos(angle), radius * math.sin(angle))
end

function Math.Normalize(value, min, max)
    if max == min then return 0 end -- Avoid division by zero
    return (value - min) / (max - min)
end

function Math.Normalize2D(x, y)
    if type(x) == "vector2" then
        x, y = x.x, x.y
    end
    local length = math.sqrt(x*x + y*y)
    return length ~= 0 and vector2(x / length, y / length) or vector2(0, 0)
end

function Math.Normalize3D(x, y, z)
    if type(x) == "vector3" then
        x, y, z = x.x, x.y, x.z
    end
    local length = math.sqrt(x*x + y*y + z*z)
    return length ~= 0 and vector3(x / length, y / length, z / length) or vector3(0, 0, 0)
end

function Math.Normalize4D(x, y, z, w)
    if type(x) == "vector4" then
        x, y, z, w = x.x, x.y, x.z, x.w
    end
    local length = math.sqrt(x*x + y*y + z*z + w*w)
    return length ~= 0 and vector4(x / length, y / length, z / length, w / length) or vector4(0, 0, 0, 0)
end

function Math.DirectionToTarget(fromV3, toV3)
    return Math.Normalize3D(toV3.x - fromV3.x, toV3.y - fromV3.y, toV3.z - fromV3.z)
end

exports('Math', Math)
return Math