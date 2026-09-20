require "EeltsForestryRemastered_TreeGrowthSprites"

EeltsForestryRemastered_Propagules = {}

local propagules = EeltsForestryRemastered_Propagules

-- The tileset name, not the display name, so it keys straight into the sprite tables
propagules.SPECIES_KEY = "Eelt_Species"

-- What each propagule is allowed to become. A cone never grows a broadleaf
propagules.eligible = {
    ["Base.Sapling"] = EeltsForestryRemastered_TreeGrowthSprites.species,
    ["Base.Pinecone"] = { "e_virginiapine_1", "e_canadianhemlock_1" },
    ["Base.HollyBerry"] = { "e_americanholly_1" },
}

-- Species a forage zone's biome actually places, weighted by the summed jumbo, xl and xxl
-- probabilities from the biome files. Only relative presence matters at stage 0
propagules.zoneSpecies = {
    PHForest = { ["e_virginiapine_1"] = 0.7 },
    PHMixForest = {
        ["e_virginiapine_1"] = 0.4,
        ["e_dogwood_1"] = 0.12,
        ["e_redmaple_1"] = 0.2,
        ["e_americanlinden_1"] = 0.15,
    },
    PRForest = {
        ["e_easternredbud_1"] = 0.3,
        ["e_cockspurhawthorn_1"] = 0.3,
        ["e_carolinasilverbell_1"] = 0.3,
    },
    BirchForest = { ["e_riverbirch_1"] = 0.8 },
    BirchMixForest = {
        ["e_riverbirch_1"] = 0.4,
        ["e_dogwood_1"] = 0.17,
        ["e_redmaple_1"] = 0.18,
        ["e_americanlinden_1"] = 0.15,
    },
    OrganicForest = {
        ["e_dogwood_1"] = 0.35,
        ["e_redmaple_1"] = 0.35,
        ["e_americanlinden_1"] = 0.3,
    },
    -- Vanilla's yellowwood_jumbo_xl feature holds a silverbell sprite, so its mass counts as silverbell
    FarmForest = {
        ["e_yellowwood_1"] = 0.25,
        ["e_redmaple_1"] = 0.35,
        ["e_carolinasilverbell_1"] = 0.4,
    },
    DeepForest = {
        ["e_canadianhemlock_1"] = 0.35,
        ["e_americanholly_1"] = 0.35,
        ["e_redmaple_1"] = 0.1,
        ["e_dogwood_1"] = 0.1,
        ["e_americanlinden_1"] = 0.05,
    },
    Vegitation = { ["e_easternredbud_1"] = 1.0 },
}

-- Three zones share farmmix_forest
local farmMix = {
    ["e_yellowwood_1"] = 0.13,
    ["e_redmaple_1"] = 0.35,
    ["e_carolinasilverbell_1"] = 0.2,
    ["e_dogwood_1"] = 0.22,
    ["e_americanlinden_1"] = 0.15,
}
propagules.zoneSpecies.Farm = farmMix
propagules.zoneSpecies.FarmLand = farmMix
propagules.zoneSpecies.FarmMixForest = farmMix

-- Plain Forest is clay shore and clay lake, which define no tree features of their own, so
-- it takes the mixture of the woods beside it and its own near empty ceiling below
propagules.zoneSpecies.Forest = propagules.zoneSpecies.OrganicForest

function propagules.isPlantable(item)
    local fullType = item and item:getFullType()
    return fullType ~= nil and propagules.eligible[fullType] ~= nil
end

function propagules.getSpecies(item)
    if not item then return nil end
    local modData = item:getModData()
    return modData and modData[propagules.SPECIES_KEY] or nil
end

function propagules.stamp(item, tileset)
    if not item or not tileset then return end
    item:getModData()[propagules.SPECIES_KEY] = tileset
end

-- Read the zone directly; forageSystem.getForageZoneAt registers a forage zone as a side effect
function propagules.zoneWeightsAt(x, y)
    local zones = getZones(x, y, 0)
    for i = 0, zones and zones:size() - 1 or -1 do
        local byZone = propagules.zoneSpecies[zones:get(i):getType()]
        if byZone then return byZone end
    end
    return nil
end

-- A nil eligible list means every species the weights name, which is what a bare square asks
-- for. Returns nil when nothing weighted is eligible, leaving the fallback to the caller
function propagules.rollFromWeights(weights, eligible)
    if not weights then return nil end

    local candidates, total = {}, 0
    if eligible then
        for _, tileset in ipairs(eligible) do
            local weight = weights[tileset]
            if weight and weight > 0 then
                total = total + weight
                candidates[#candidates + 1] = { tileset = tileset, weight = weight }
            end
        end
    else
        for tileset, weight in pairs(weights) do
            if weight > 0 then
                total = total + weight
                candidates[#candidates + 1] = { tileset = tileset, weight = weight }
            end
        end
    end

    if total <= 0 then return nil end

    local roll = ZombRand(math.floor(total * 1000)) / 1000
    for _, candidate in ipairs(candidates) do
        roll = roll - candidate.weight
        if roll < 0 then return candidate.tileset end
    end
    return candidates[#candidates].tileset
end

function propagules.rollSpecies(fullType, x, y)
    local eligible = propagules.eligible[fullType]
    if not eligible or #eligible == 0 then return nil end
    if #eligible == 1 then return eligible[1] end

    local rolled = propagules.rollFromWeights(propagules.zoneWeightsAt(x, y), eligible)
    if rolled then return rolled end

    -- Nothing local the propagule can become, so any of them will do
    return eligible[ZombRand(#eligible) + 1]
end

function propagules.speciesFor(item, x, y)
    return propagules.getSpecies(item) or propagules.rollSpecies(item:getFullType(), x, y)
end

-- Trees per thousand squares, measured as slots across the whole map and scaled by the share
-- worldgen actually turns into a trunk. Keyed by worldgen biome rather than by forage zone,
-- because a zone's own count describes how the land was used and not what it can carry:
-- FarmLand is farmmix_forest with the trees kept off it, and townhouse and the two clay
-- shores really do carry none, since all three take the no_tree subbiome
local REALISATION = 0.71

propagules.biomeDensity = {
    primary_forest = 223.3 * REALISATION,
    birch_forest = 192.9 * REALISATION,
    organic_forest = 184.8 * REALISATION,
    farmmix_forest = 129.8 * REALISATION,
    pr_forest = 100.1 * REALISATION,
    ph_forest = 95.3 * REALISATION,
    phmix_forest = 95.3 * REALISATION,
    farm_forest = 88.7 * REALISATION,
    birchmix_forest = 75.9 * REALISATION,
    vegitation = 33.7 * REALISATION,
    townhouse = 0,
    clay_shore = 0,
    clay_lake = 0,
}

-- The mapping BiomeMapConfig.lua makes, for the zones that reach lua
local ZONE_BIOME = {
    DeepForest = "primary_forest",
    BirchForest = "birch_forest",
    OrganicForest = "organic_forest",
    FarmMixForest = "farmmix_forest",
    Farm = "farmmix_forest",
    FarmLand = "farmmix_forest",
    PRForest = "pr_forest",
    PHForest = "ph_forest",
    PHMixForest = "phmix_forest",
    FarmForest = "farm_forest",
    BirchMixForest = "birchmix_forest",
    Vegitation = "vegitation",
    TownZone = "townhouse",
    TrailerPark = "townhouse",
    Forest = "clay_shore",
}

propagules.zoneDensity = {}
for zone, biome in pairs(ZONE_BIOME) do
    propagules.zoneDensity[zone] = propagules.biomeDensity[biome]
end

propagules.CROWD_RADIUS = 4
propagules.MIN_SPACING = 1

local DENSITY_OPTION = "EeltsForestryRemastered.RecoveryDensityMultiplier"

function propagules.densityMultiplier()
    local option = getSandboxOptions():getOptionByName(DENSITY_OPTION)
    local multiplier = option and option:getValue() or 1.0
    if multiplier < 0 then multiplier = 1.0 end
    return multiplier
end

function propagules.zoneDensityAt(x, y)
    local zones = getZones(x, y, 0)
    for i = 0, zones and zones:size() - 1 or -1 do
        local density = propagules.zoneDensity[zones:get(i):getType()]
        if density then return density end
    end
    return nil
end

-- Filling greedily settles above the limit rather than at it, because every square left empty
-- ends with at least the limit around it and most end with more. Dividing the target density
-- by the neighbourhood overshot by up to forty percent, worst where the target was lowest, so
-- the limit is read back from the density each one actually reaches. Measured over a 200 by
-- 200 field at CROWD_RADIUS 4, and tied to that radius
local SATURATION = {
    26.3, 45.0, 60.9, 75.6, 88.9, 101.8, 113.7,
    124.7, 135.1, 145.0, 154.6, 163.0, 171.2, 177.7,
}

-- How many trees may stand within CROWD_RADIUS of a square. The first limit that reaches the
-- zone's density is taken, so recovery lands a little above the target rather than under it
function propagules.crowdLimitAt(x, y)
    local density = propagules.zoneDensityAt(x, y)
    if not density then return nil end

    density = density * propagules.densityMultiplier()
    if density <= 0 then return 0 end

    for limit = 1, #SATURATION do
        if SATURATION[limit] >= density then return limit end
    end
    return #SATURATION
end

-- A stand should reseed as itself, so neighbours add weight to their own species. A species
-- the zone does not grow needs several of them before it counts at all
local BIAS_PER_TREE = 0.08
local BIAS_CAP = 0.5
local FOREIGN_MIN = 3

local PLANTED_PARENT_OPTION = "EeltsForestryRemastered.PlantedTreeParents"
local PARENTS_DISABLED, PARENTS_NATIVE, PARENTS_ALL = 1, 2, 3

function propagules.plantedParentMode()
    local option = getSandboxOptions():getOptionByName(PLANTED_PARENT_OPTION)
    return option and option:getValue() or PARENTS_DISABLED
end

-- neighbours maps a tileset to { wild = n, planted = n }
function propagules.biasedWeights(weights, neighbours)
    if not weights then return nil end

    local mode = propagules.plantedParentMode()
    local biased = {}
    for tileset, weight in pairs(weights) do biased[tileset] = weight end

    for tileset, counts in pairs(neighbours or {}) do
        local native = (weights[tileset] or 0) > 0
        local count = counts.wild or 0
        if mode == PARENTS_ALL or (mode == PARENTS_NATIVE and native) then
            count = count + (counts.planted or 0)
        end

        if count > 0 and (native or count >= FOREIGN_MIN) then
            local bonus = math.min(count * BIAS_PER_TREE, BIAS_CAP)
            biased[tileset] = (biased[tileset] or 0) + bonus
        end
    end

    return biased
end
