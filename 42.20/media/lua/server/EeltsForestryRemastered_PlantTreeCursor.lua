-- Server folder because ISBuildingObject lives there and is not yet defined when client lua parses
require "BuildingObjects/ISBuildingObject"
require "EeltsForestryRemastered_Planting"

Eelt_PlantTreeCursor = ISBuildingObject:derive("Eelt_PlantTreeCursor")

local function predicateDigPlow(item)
    return not item:isBroken() and item:hasTag(ItemTag.DIG_PLOW)
end

-- A kind is a full type plus the species stamped on it, the same key the menu collapses a stack by
function Eelt_PlantTreeCursor.kindOf(item)
    local species = EeltsForestryRemastered_Propagules.getSpecies(item)
    return { fullType = item:getFullType(), species = species, key = item:getFullType() .. "|" .. tostring(species) }
end

function Eelt_PlantTreeCursor:isValid(square)
    return EeltsForestryRemastered_Planting.isPlantableSquare(square)
end

function Eelt_PlantTreeCursor:render(x, y, z, square)
    local colour = self:isValid(square) and getCore():getGoodHighlitedColor() or getCore():getBadHighlitedColor()
    renderIsoRect(x + 1, y + 1, z, 1, colour:getR(), colour:getG(), colour:getB(), 0.5, 1)
end

function Eelt_PlantTreeCursor:nextPropagule()
    local planting = EeltsForestryRemastered_Planting
    local propagules = EeltsForestryRemastered_Propagules
    local kind, claimed = self.kind, self.claimed
    return self.character:getInventory():getFirstEvalRecurse(function(item)
        if claimed[item:getID()] then return false end
        if item:getFullType() ~= kind.fullType then return false end
        if propagules.getSpecies(item) ~= kind.species then return false end
        return planting.isPlantableItem(item)
    end)
end

function Eelt_PlantTreeCursor:create(x, y, z, north, sprite)
    local playerObj = self.character
    local square = getCell():getGridSquare(x, y, z)
    local tool = playerObj:getInventory():getFirstTagEvalRecurse(ItemTag.DIG_PLOW, predicateDigPlow)
    local propagule = self:nextPropagule()
    if not square or not tool or not propagule then
        getCell():setDrag(nil, self.player)
        return
    end

    -- Walked here rather than in walkTo, which tryBuild skips under the build cheat and which would clear the queue
    if not luautils.walkAdj(playerObj, square, true) then return end
    ISTimedActionQueue.add(Eelt_PlantTreeAction:new(playerObj, square, propagule, tool))
    self.claimed[propagule:getID()] = true
    if not self:nextPropagule() then
        getCell():setDrag(nil, self.player)
    end
end

function Eelt_PlantTreeCursor:getAPrompt()
    return getText("ContextMenu_Eelt_PlantTree")
end

function Eelt_PlantTreeCursor:getLBPrompt()
    return nil
end

function Eelt_PlantTreeCursor:getRBPrompt()
    return nil
end

function Eelt_PlantTreeCursor:new(character, kind)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o:init()
    o.character = character
    o.player = character:getPlayerNum()
    o.kind = kind
    o.claimed = {}
    o.skipBuildAction = true
    o.skipWalk2 = true
    o.noNeedHammer = true
    return o
end
