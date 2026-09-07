EeltsForestryRemastered_TreeGrowthSprites = {}

local sprites = EeltsForestryRemastered_TreeGrowthSprites

sprites.MAX_STAGE = 7

-- Renaming an adopted tree is what makes vanilla erosion relinquish it
sprites.ADOPTED_NAME = "Eelt_AdoptedTree"

sprites.species = {
    "e_americanholly_1",
    "e_canadianhemlock_1",
    "e_virginiapine_1",
    "e_riverbirch_1",
    "e_cockspurhawthorn_1",
    "e_dogwood_1",
    "e_carolinasilverbell_1",
    "e_yellowwood_1",
    "e_easternredbud_1",
    "e_redmaple_1",
    "e_americanlinden_1",
}

sprites.evergreen = {
    ["e_americanholly_1"] = true,
    ["e_canadianhemlock_1"] = true,
    ["e_virginiapine_1"] = true,
}

local function sheetFor(tileset, infix)
    return (string.gsub(tileset, "_1$", infix .. "_1"))
end

local function sheetNameFor(tileset, stage)
    if stage <= 3 then return tileset end
    if stage <= 5 then return sheetFor(tileset, "JUMBO") end
    if stage == 6 then return sheetFor(tileset, "JUMBOXL") end
    return sheetFor(tileset, "JUMBOXXL")
end

-- How erosion lays a sheet out: season position by stage, position 0 being the bare base
local function sheetIndex(position, stage)
    if stage <= 3 then return position * 4 + stage end
    if stage <= 5 then return position * 2 + (stage - 4) end
    return position
end

local function spriteFor(tileset, stage, position)
    return sheetNameFor(tileset, stage) .. "_" .. sheetIndex(position, stage)
end

local function baseSpriteFor(tileset, stage)
    return spriteFor(tileset, stage, 0)
end

-- Winter and late autumn carry no overlay, which is why a bare base is correct for them
local SEASON_POSITION = {
    ["Spring"] = 2,
    ["Early Summer"] = 3,
    ["Autumn"] = 5,
}

-- A deciduous base sprite is the bare tree; every leafy look is an overlay
function sprites.getOverlay(tileset, stage, seasonName)
    if sprites.evergreen[tileset] then return nil end
    local position = SEASON_POSITION[seasonName]
    if not position then return nil end
    return spriteFor(tileset, stage, position)
end

sprites.base = {}
sprites.byName = {}

local function register(tileset, spriteName, stage)
    sprites.byName[spriteName] = { tileset = tileset, stage = stage }
end

for _, tileset in ipairs(sprites.species) do
    sprites.base[tileset] = {}
    for stage = 0, sprites.MAX_STAGE do
        sprites.base[tileset][stage] = baseSpriteFor(tileset, stage)
    end

    -- Every index the game addresses, so a tree wearing a seasonal or snow variant still resolves
    for index = 0, 23 do
        register(tileset, tileset .. "_" .. index, index % 4)
    end
    for index = 0, 11 do
        register(tileset, sheetFor(tileset, "JUMBO") .. "_" .. index, 4 + (index % 2))
    end
    for index = 0, 5 do
        register(tileset, sheetFor(tileset, "JUMBOXL") .. "_" .. index, 6)
        register(tileset, sheetFor(tileset, "JUMBOXXL") .. "_" .. index, 7)
    end
end

function sprites.getBase(tileset, stage)
    local byStage = sprites.base[tileset]
    return byStage and byStage[stage]
end

function sprites.identify(spriteName)
    local entry = spriteName and sprites.byName[spriteName]
    if not entry then return nil, nil end
    return entry.tileset, entry.stage
end
