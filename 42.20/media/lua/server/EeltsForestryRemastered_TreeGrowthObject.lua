if isClient() then return end

require "Map/SGlobalObject"
require "EeltsForestryRemastered_TreeSeasons"

Eelt_STreeGrowthObject = SGlobalObject:derive("Eelt_STreeGrowthObject")

function Eelt_STreeGrowthObject:new(luaSystem, globalObject)
    return SGlobalObject.new(self, luaSystem, globalObject)
end

function Eelt_STreeGrowthObject:initNew()
    self.tileset = nil
    self.stage = 0
    self.enteredHour = getGameTime():getWorldAgeHours()
    self.planted = false
end

function Eelt_STreeGrowthObject:adoptFrom(isoObject, tileset, stage, planted)
    self.tileset = tileset
    self.stage = stage
    self.enteredHour = getGameTime():getWorldAgeHours()
    self.planted = planted and true or false
end

-- Called when the gos bin is missing, so rebuild what we can from the tree itself
function Eelt_STreeGrowthObject:stateFromIsoObject(isoObject)
    local sprites = EeltsForestryRemastered_TreeGrowthSprites
    local sprite = isoObject:getSprite()
    local tileset, stage = sprites.identify(sprite and sprite:getName())
    self.tileset = tileset
    self.stage = stage or 0
    self.enteredHour = getGameTime():getWorldAgeHours()
    self.planted = false
end

function Eelt_STreeGrowthObject:stateToIsoObject(isoObject)
    local sprites = EeltsForestryRemastered_TreeGrowthSprites
    local spriteName = self.tileset and sprites.getBase(self.tileset, self.stage)
    if not spriteName then return end

    local sprite = getSprite(spriteName)
    if not sprite then return end

    isoObject:setSprite(sprite)

    -- A deciduous base sprite is bare, so the season overlay carries the foliage
    self.overlaySeason = self:displaySeason()
    self:applyOverlay(isoObject)

    if isServer() then isoObject:transmitUpdatedSpriteToClients() end

    local square = isoObject:getSquare()
    if square then square:RecalcAllWithNeighbours(true) end
end

function Eelt_STreeGrowthObject.currentSeason()
    return EeltsForestryRemastered_TreeSeasons.current()
end

function Eelt_STreeGrowthObject:displaySeason(season, progress, staggered)
    return EeltsForestryRemastered_TreeSeasons.lookFor(self.x, self.y, season, progress, staggered)
end

function Eelt_STreeGrowthObject:debugSeason()
    local treeSeasons = EeltsForestryRemastered_TreeSeasons
    local stagger = treeSeasons.staggerFor(self.x, self.y)
    local progress = treeSeasons.progress()
    local season = getClimateManager():getSeasonName()
    local position = treeSeasons.yearPosition(season, progress)
    local leafOut, summer, first, deep, down = treeSeasons.boundariesFor(stagger)

    return string.format("x=%s y=%s stagger=%.4f season=%s progress=%.4f position=%s result=%s vanilla=%s",
        tostring(self.x), tostring(self.y), stagger, tostring(season), progress,
        position and string.format("%.4f", position) or "nil",
        tostring(self:displaySeason(season, progress, true)),
        tostring(self:displaySeason(season, progress, false)))
        .. string.format(" | leafOut=%.4f summer=%.4f firstColour=%.4f deepColour=%.4f leavesDown=%.4f staggered=%s",
        leafOut, summer, first, deep, down, tostring(treeSeasons.staggerEnabled()))
end

function Eelt_STreeGrowthObject:applyOverlay(isoObject)
    local sprites = EeltsForestryRemastered_TreeGrowthSprites
    local attached = isoObject:getAttachedAnimSprite()
    if attached then attached:clear() end

    local spriteName = self.tileset and sprites.getOverlay(self.tileset, self.stage, self.overlaySeason)
    if not spriteName then return end

    local sprite = getSprite(spriteName)
    if not sprite then return end

    -- A tree built by IsoTree.new has no overlay list, only an engine placed one does
    if not attached then
        isoObject:setAttachedAnimSprite(ArrayList.new())
        attached = isoObject:getAttachedAnimSprite()
        if not attached then return end
    end

    attached:add(sprite:newInstance())
end

-- Recording the season before the tree is reachable would leave it stale for good, and
-- correction owns trees far outside any loaded chunk
function Eelt_STreeGrowthObject:refreshOverlay(season, progress, staggered)
    local display = self:displaySeason(season, progress, staggered)
    if display == self.overlaySeason then return end

    local isoObject = self:getIsoObject()
    if not isoObject then return end

    self.overlaySeason = display
    self:applyOverlay(isoObject)
    if isServer() then isoObject:transmitUpdatedSpriteToClients() end
end

function Eelt_STreeGrowthObject:isReadyToGrow(hoursPerStage)
    if not self.tileset then return false end
    if self.stage >= EeltsForestryRemastered_TreeGrowthSprites.MAX_STAGE then return false end
    local entered = self.enteredHour or getGameTime():getWorldAgeHours()
    return getGameTime():getWorldAgeHours() - entered >= hoursPerStage
end

-- Advances every stage the elapsed time has paid for, keeping the part of the next one already
-- earned, so a tree returned to repeatedly ends up level with one that was never unloaded
function Eelt_STreeGrowthObject:catchUp(hoursPerStage)
    local sprites = EeltsForestryRemastered_TreeGrowthSprites
    if not self.tileset or self.stage >= sprites.MAX_STAGE then return 0 end
    if not hoursPerStage or hoursPerStage <= 0 then return 0 end

    local entered = self.enteredHour or getGameTime():getWorldAgeHours()
    local due = math.floor((getGameTime():getWorldAgeHours() - entered) / hoursPerStage)
    if due < 1 then return 0 end

    local gained = math.min(due, sprites.MAX_STAGE - self.stage)
    self.stage = self.stage + gained
    self.enteredHour = entered + due * hoursPerStage

    local isoObject = self:getIsoObject()
    if isoObject then self:stateToIsoObject(isoObject) end
    self:updateOnClient()
    return gained
end

function Eelt_STreeGrowthObject:grow()
    self.stage = math.min(self.stage + 1, EeltsForestryRemastered_TreeGrowthSprites.MAX_STAGE)
    self.enteredHour = getGameTime():getWorldAgeHours()

    local isoObject = self:getIsoObject()
    if isoObject then self:stateToIsoObject(isoObject) end
    self:updateOnClient()
end
