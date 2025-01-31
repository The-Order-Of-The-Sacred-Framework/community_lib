local Perlin = {}

-- Permutation table for random gradients
local perm = {}
local grad3 = {
    {1,1,0}, {-1,1,0}, {1,-1,0}, {-1,-1,0},
    {1,0,1}, {-1,0,1}, {1,0,-1}, {-1,0,-1},
    {0,1,1}, {0,-1,1}, {0,1,-1}, {0,-1,-1}
}

-- Initialize permutation table
local function ShufflePermutation()
    local p = {}
    for i = 0, 255 do
        p[i] = i
    end
    for i = 255, 1, -1 do
        local j = math.random(i + 1) - 1
        p[i], p[j] = p[j], p[i]
    end
    for i = 0, 255 do
        perm[i] = p[i]
        perm[i + 256] = p[i] -- Repeat for wrapping
    end
end

ShufflePermutation() -- Randomize on load

-- Dot product helper
local function Dot(g, x, y, z)
    return g[1] * x + g[2] * y + (z and g[3] * z or 0)
end

-- Fade function (smootherstep)
local function Fade(t)
    return t * t * t * (t * (t * 6 - 15) + 10)
end

-- Linear interpolation
local function Lerp(a, b, t)
    return a + (b - a) * t
end

-- **Perlin Noise 1D**
function Perlin.Noise1D(x)
    local X = math.floor(x) & 255
    x = x - math.floor(x)
    local u = Fade(x)

    local a = perm[X]
    local b = perm[X + 1]

    return Lerp(a, b, u) * (2 / 255) - 1
end

-- **Perlin Noise 2D**
function Perlin.Noise2D(x, y)
    local X = math.floor(x) & 255
    local Y = math.floor(y) & 255
    x, y = x - math.floor(x), y - math.floor(y)

    local u, v = Fade(x), Fade(y)

    local aa = perm[X] + Y
    local ab = perm[X] + Y + 1
    local ba = perm[X + 1] + Y
    local bb = perm[X + 1] + Y + 1

    return Lerp(
        Lerp(Dot(grad3[perm[aa] % 12 + 1], x, y), Dot(grad3[perm[ba] % 12 + 1], x - 1, y), u),
        Lerp(Dot(grad3[perm[ab] % 12 + 1], x, y - 1), Dot(grad3[perm[bb] % 12 + 1], x - 1, y - 1), u),
        v
    )
end

-- **Perlin Noise 3D**
function Perlin.Noise3D(x, y, z)
    local X = math.floor(x) & 255
    local Y = math.floor(y) & 255
    local Z = math.floor(z) & 255
    x, y, z = x - math.floor(x), y - math.floor(y), z - math.floor(z)

    local u, v, w = Fade(x), Fade(y), Fade(z)

    local aaa = perm[X] + Y + Z
    local aba = perm[X] + Y + Z + 1
    local aab = perm[X] + Y + 1 + Z
    local abb = perm[X] + Y + 1 + Z + 1
    local baa = perm[X + 1] + Y + Z
    local bba = perm[X + 1] + Y + Z + 1
    local bab = perm[X + 1] + Y + 1 + Z
    local bbb = perm[X + 1] + Y + 1 + Z + 1

    return Lerp(
        Lerp(
            Lerp(Dot(grad3[perm[aaa] % 12 + 1], x, y, z), Dot(grad3[perm[baa] % 12 + 1], x - 1, y, z), u),
            Lerp(Dot(grad3[perm[aab] % 12 + 1], x, y - 1, z), Dot(grad3[perm[bab] % 12 + 1], x - 1, y - 1, z), u),
            v
        ),
        Lerp(
            Lerp(Dot(grad3[perm[aba] % 12 + 1], x, y, z - 1), Dot(grad3[perm[bba] % 12 + 1], x - 1, y, z - 1), u),
            Lerp(Dot(grad3[perm[abb] % 12 + 1], x, y - 1, z - 1), Dot(grad3[perm[bbb] % 12 + 1], x - 1, y - 1, z - 1), u),
            v
        ),
        w
    )
end

exports('Perlin', Perlin)
return Perlin
