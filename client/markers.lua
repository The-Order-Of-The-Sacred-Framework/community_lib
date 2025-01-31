Marker = {}

function Marker.DrawMarker(data)
    local position = data.position or vector3(0.0, 0.0, 0.0)
    local offset = data.offset or vector3(0.0, 0.0, 0.0)
    local marker = data.marker or 1
    local pos = vector3(position.x + offset.x, position.y + offset.y, position.z + offset.z)
    local rotation = data.rotation or vector3(0, 0, 0)
    local size = data.size or vector3(1.0, 1.0, 1.0)
    local color = data.color or vector3(0, 255, 0)
    local alpha = data.alpha or 255
    local bobUpAndDown = data.bobUpAndDown
    DrawMarker(
        marker,
        pos.x, pos.y, pos.z,
        0.0, 0.0, 0.0,
        rotation.x, rotation.y, rotation.z,
        size.x, size.y, size.z,
        color.r, color.g, color.b, alpha,
        bobUpAndDown, false, false
    )
end

exports("Makrer", Marker)

return Marker