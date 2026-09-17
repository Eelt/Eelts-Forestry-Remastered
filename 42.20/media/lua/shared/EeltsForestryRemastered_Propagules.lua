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
