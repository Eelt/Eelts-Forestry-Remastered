if isClient() then return end

require "Map/SGlobalObject"

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

-- Erosion staggers the turn with a per square magic number; this is the stable equivalent.
-- Operands stay well inside 32 bits because the game's lua overflows % past Integer.MAX_VALUE
local function staggerFor(x, y)
    return ((((x or 0) % 1000) * 73 + (((y or 0) % 1000) * 179)) % 997) / 997
end

local function seasonProgress()
    local ok, progress = pcall(function()
        local seasons = ErosionMain.getInstance():getSeasons()
        local days = seasons:getSeasonDays()
        if days <= 0 then return 1.0 end
        return seasons:getSeasonDay() / days
    end)
    if ok and progress then return progress end
    return 1.0
end

-- Deliberately skips vanilla's split summer, which tints trees from early July
function Eelt_STreeGrowthObject:displaySeason()
    local season = getClimateManager():getSeasonName()
    if season == "Spring" or season == "Early Summer" then return season end
    if season ~= "Autumn" then return nil end

    local stagger = staggerFor(self.x, self.y)
    local progress = seasonProgress()
    if progress < stagger * 0.35 then return "Early Summer" end
    if progress >= 0.75 + stagger * 0.2 then return nil end
    return "Autumn"
end

function Eelt_STreeGrowthObject:debugSeason()
    local stagger = staggerFor(self.x, self.y)
    local progress = seasonProgress()
    return string.format("x=%s y=%s stagger=%.4f progress=%.4f turnAt=%.4f fallAt=%.4f season=%s result=%s",
        tostring(self.x), tostring(self.y), stagger, progress,
        stagger * 0.35, 0.75 + stagger * 0.2,
        tostring(getClimateManager():getSeasonName()), tostring(self:displaySeason()))
end

function Eelt_STreeGrowthObject:applyOverlay(isoObject)
    local sprites = EeltsForestryRemastered_TreeGrowthSprites
    local attached = isoObject:getAttachedAnimSprite()
    if attached then attached:clear() end

    local spriteName = self.tileset and sprites.getOverlay(self.tileset, self.stage, self:displaySeason())
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

function Eelt_STreeGrowthObject:refreshOverlay()
    local season = self:displaySeason()
    if season == self.overlaySeason then return end
    self.overlaySeason = season

    local isoObject = self:getIsoObject()
    if not isoObject then return end
    self:applyOverlay(isoObject)
    if isServer() then isoObject:transmitUpdatedSpriteToClients() end
end

function Eelt_STreeGrowthObject:isReadyToGrow(hoursPerStage)
    if not self.tileset then return false end
    if self.stage >= EeltsForestryRemastered_TreeGrowthSprites.MAX_STAGE then return false end
    local entered = self.enteredHour or getGameTime():getWorldAgeHours()
    return getGameTime():getWorldAgeHours() - entered >= hoursPerStage
end

function Eelt_STreeGrowthObject:grow()
    self.stage = math.min(self.stage + 1, EeltsForestryRemastered_TreeGrowthSprites.MAX_STAGE)
    self.enteredHour = getGameTime():getWorldAgeHours()

    local isoObject = self:getIsoObject()
    if isoObject then self:stateToIsoObject(isoObject) end
    self:updateOnClient()
end
