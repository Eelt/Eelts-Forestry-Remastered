require "EeltsForestryRemastered_Planting"

local PREFIX = "Eelt's Forestry Remastered: "

local function describe(tree)
    local sprites = EeltsForestryRemastered_TreeGrowthSprites
    local sprite = tree:getSprite()
    local spriteName = sprite and sprite:getName() or "nil"
    local tileset, stage
    if sprites then tileset, stage = sprites.identify(spriteName) end

    local attached = tree:getAttachedAnimSprite()
    local overlay = "none"
    if attached and attached:size() > 0 then
        local first = attached:get(0)
        overlay = first and first:getName() or "unnamed"
    end

    print(string.format("%sname=%s sprite=%s overlay=%s season=%s species=%s stage=%s size=%d logs=%d",
        PREFIX, tostring(tree:getName()), spriteName, overlay,
        tostring(getClimateManager():getSeasonName()), tostring(tileset), tostring(stage),
        tree:getSize(), tree:getLogYield()))

    local system = Eelt_STreeGrowthSystem and Eelt_STreeGrowthSystem.instance
    local square = tree:getSquare()
    local luaObject = system and square and system:getLuaObjectOnSquare(square)
    if not luaObject then return end

    local ok, seasonDay, seasonDays = pcall(function()
        local seasons = ErosionMain.getInstance():getSeasons()
        return seasons:getSeasonDay(), seasons:getSeasonDays()
    end)
    print(string.format("%s  displaySeason=%s stored=%s seasonDay=%s seasonDays=%s readable=%s",
        PREFIX, tostring(luaObject:displaySeason()), tostring(luaObject.overlaySeason),
        tostring(seasonDay), tostring(seasonDays), tostring(ok)))
    print(PREFIX .. "  " .. luaObject:debugSeason())
end

local function adoptOrGrow(tree)
    local system = Eelt_STreeGrowthSystem and Eelt_STreeGrowthSystem.instance
    if not system then
        print(PREFIX .. "growth system not loaded")
        return
    end

    local square = tree:getSquare()
    if not square then return end

    local luaObject = system:getLuaObjectOnSquare(square)
    if luaObject then
        luaObject:grow()
    else
        system:adoptTree(square, tree)
        luaObject = system:getLuaObjectOnSquare(square)
    end

    if luaObject then
        print(string.format("%sstage=%s overlaySeason=%s planted=%s", PREFIX,
            tostring(luaObject.stage), tostring(luaObject.overlaySeason), tostring(luaObject.planted)))
    end
    describe(tree)
end

-- Month is 0 based, matching the erosion demo debug controls
local function skipMonth(tree)
    local gameTime = GameTime.getInstance()
    gameTime:setMonth(gameTime:getMonth() + 1)
    if gameTime:getMonth() >= 12 then
        gameTime:setMonth(0)
        gameTime:setYear(gameTime:getYear() + 1)
    end

    local lastDay = gameTime:daysInMonth(gameTime:getYear(), gameTime:getMonth()) - 1
    if gameTime:getDay() > lastDay then gameTime:setDay(lastDay) end

    -- ErosionMain only recomputes the season on its own timer, so nudge it directly
    pcall(function()
        ErosionMain.getInstance():getSeasons():setDay(gameTime:getDay(), gameTime:getMonth(), gameTime:getYear())
    end)

    -- The overlay normally waits for the hourly tick, which a date jump does not trigger
    local system = Eelt_STreeGrowthSystem and Eelt_STreeGrowthSystem.instance
    if system then system:refreshAllOverlays() end

    print(string.format("%syear=%d month=%d day=%d season=%s adopted=%d", PREFIX,
        gameTime:getYear(), gameTime:getMonth(), gameTime:getDay(),
        tostring(getClimateManager():getSeasonName()),
        system and system.system:getObjectCount() or -1))
    describe(tree)
end

-- Adoption and growth ride Events.EveryHours, which a date jump never triggers
local function forceTick(tree)
    local system = Eelt_STreeGrowthSystem and Eelt_STreeGrowthSystem.instance
    if not system then
        print(PREFIX .. "growth system not loaded")
        return
    end

    local before = system.system:getObjectCount()
    Eelt_STreeGrowthSystem.everyHour()
    print(string.format("%sforced tick, adopted %d -> %d", PREFIX,
        before, system.system:getObjectCount()))
    describe(tree)
end

-- A tree is not in worldobjects, only the ground blend is, so reach it through the square
local function findTree(worldobjects)
    for i = 1, worldobjects and #worldobjects or 0 do
        local square = worldobjects[i] and worldobjects[i]:getSquare()
        local tree = square and square:getTree()
        if tree then return tree end
    end
    return nil
end

local function isDebugAllowed(player)
    if isClient() then
        local playerObj = getSpecificPlayer(player)
        return playerObj and playerObj:getRole():hasCapability(Capability.UseDebugContextMenu)
    end
    return isDebugEnabled()
end

local function findSquare(worldobjects)
    for i = 1, worldobjects and #worldobjects or 0 do
        local square = worldobjects[i] and worldobjects[i]:getSquare()
        if square then return square end
    end
    return nil
end

local function describePropagules(worldobjects, playerObj)
    local propagules = EeltsForestryRemastered_Propagules
    local found = 0
    local items = playerObj:getInventory():getItems()
    for i = 0, items and items:size() - 1 or -1 do
        local item = items:get(i)
        if propagules.isPlantable(item) then
            found = found + 1
            local poison = instanceof(item, "Food") and item:getPoisonPower() or 0
            print(string.format("%s%s species=%s poison=%d", PREFIX, item:getFullType(),
                tostring(propagules.getSpecies(item)), poison))
        end
    end
    if found == 0 then print(PREFIX .. "no propagules carried") end
end

local function plantSpecies(worldobjects, playerObj, square, tileset)
    if EeltsForestryRemastered_TreePlanting then
        EeltsForestryRemastered_TreePlanting.plantTree(square, tileset)
        return
    end

    local planting = EeltsForestryRemastered_Planting
    sendClientCommand(playerObj, planting.MODULE, planting.PLANT_COMMAND,
        { x = square:getX(), y = square:getY(), z = square:getZ(), species = tileset })
end

local SURVEY_RADIUS = 40

-- The debug console runs in its own lua state and cannot see the mod's globals, so anything
-- worth reading has to be reachable from here
local function zoneAt(x, y)
    local propagules = EeltsForestryRemastered_Propagules
    local zones = getZones(x, y, 0)
    for i = 0, zones and zones:size() - 1 or -1 do
        local zone = zones:get(i)
        local weights = propagules.zoneSpecies[zone:getType()]
        if weights then return zone:getType(), weights end
    end
    return nil, nil
end

local function tally(into, order, key)
    if into[key] then
        into[key] = into[key] + 1
    else
        into[key] = 1
        order[#order + 1] = key
    end
end

-- A radius of forty squares crosses zone boundaries, so each tree is judged against the pool
-- on its own square rather than the one under the player
local function surveyTrees(worldobjects, playerObj)
    local sprites = EeltsForestryRemastered_TreeGrowthSprites
    local cell = getCell()
    if not cell or not playerObj then return end

    local px = math.floor(playerObj:getX())
    local py = math.floor(playerObj:getY())
    local pz = math.floor(playerObj:getZ())

    local counts, order = {}, {}
    local stray, strayOrder = {}, {}
    local zones, zoneOrder = {}, {}
    local total, adopted, unknown, inPool, outOfPool, noPool = 0, 0, 0, 0, 0, 0

    for x = px - SURVEY_RADIUS, px + SURVEY_RADIUS do
        for y = py - SURVEY_RADIUS, py + SURVEY_RADIUS do
            local square = cell:getGridSquare(x, y, pz)
            local tree = square and square:getTree()
            if tree then
                total = total + 1
                if tree:getName() == sprites.ADOPTED_NAME then adopted = adopted + 1 end

                local sprite = tree:getSprite()
                local tileset = sprites.identify(sprite and sprite:getName())
                if not tileset then
                    unknown = unknown + 1
                else
                    tally(counts, order, tileset)

                    local zoneType, weights = zoneAt(x, y)
                    tally(zones, zoneOrder, zoneType or "no pool")
                    if not weights then
                        noPool = noPool + 1
                    elseif weights[tileset] then
                        inPool = inPool + 1
                    else
                        outOfPool = outOfPool + 1
                        tally(stray, strayOrder, tileset)
                    end
                end
            end
        end
    end

    if total == 0 then
        print(string.format("%ssurvey r=%d at %d,%d: no trees", PREFIX, SURVEY_RADIUS, px, py))
        return
    end

    print(string.format("%ssurvey r=%d at %d,%d: %d trees, %d taken over, %d unrecognised",
        PREFIX, SURVEY_RADIUS, px, py, total, adopted, unknown))
    print(string.format("%s  %d right for their own square, %d wrong, %d on squares with no pool",
        PREFIX, inPool, outOfPool, noPool))

    table.sort(zoneOrder, function(a, b) return zones[a] > zones[b] end)
    local parts = {}
    for _, zoneType in ipairs(zoneOrder) do
        parts[#parts + 1] = string.format("%s %d", zoneType, zones[zoneType])
    end
    print(PREFIX .. "  zones covered: " .. table.concat(parts, ", "))

    table.sort(order, function(a, b) return counts[a] > counts[b] end)
    for _, tileset in ipairs(order) do
        print(string.format("%s  %-26s %4d %5.1f%%  %d wrong for their square",
            PREFIX, tileset, counts[tileset], counts[tileset] / total * 100, stray[tileset] or 0))
    end
end

-- Walks the whole year without waiting for it, so the five stages and how far the stagger
-- spreads each one can be read off in one go
local function yearSweep(worldobjects, playerObj)
    local system = Eelt_STreeGrowthSystem and Eelt_STreeGrowthSystem.instance
    if not system then
        print(PREFIX .. "growth system not loaded")
        return
    end

    local sprites = EeltsForestryRemastered_TreeGrowthSprites
    local cell = getCell()
    if not cell or not playerObj then return end

    local px = math.floor(playerObj:getX())
    local py = math.floor(playerObj:getY())
    local pz = math.floor(playerObj:getZ())

    local owned = {}
    for x = px - SURVEY_RADIUS, px + SURVEY_RADIUS do
        for y = py - SURVEY_RADIUS, py + SURVEY_RADIUS do
            local square = cell:getGridSquare(x, y, pz)
            local tree = square and square:getTree()
            if tree and tree:getName() == sprites.ADOPTED_NAME then
                local luaObject = system:getLuaObjectOnSquare(square)
                if luaObject and luaObject.tileset and not sprites.evergreen[luaObject.tileset] then
                    owned[#owned + 1] = luaObject
                end
            end
        end
    end

    if #owned == 0 then
        print(PREFIX .. "no deciduous trees the mod owns nearby")
        return
    end

    local LOOKS = { "Spring", "Early Summer", "Late Summer", "Autumn" }
    print(string.format("%syear sweep: %d deciduous trees the mod owns", PREFIX, #owned))
    print(PREFIX .. "  season          progress    bare  spring   green   tint    deep")

    for _, season in ipairs({ "Spring", "Early Summer", "Autumn", "Winter" }) do
        for step = 0, 10, 2 do
            local progress = step / 10
            local counts = { bare = 0 }
            for _, look in ipairs(LOOKS) do counts[look] = 0 end
            for _, luaObject in ipairs(owned) do
                local look = luaObject:displaySeason(season, progress, true)
                local key = look or "bare"
                counts[key] = (counts[key] or 0) + 1
            end
            print(string.format("%s  %-13s   %4.2f   %6d  %6d  %6d  %6d  %6d",
                PREFIX, season, progress, counts.bare, counts["Spring"],
                counts["Early Summer"], counts["Late Summer"], counts["Autumn"]))
        end
    end
end

local function boundaryReport()
    local boundary = EeltsForestryRemastered_ErosionBoundary
    if not boundary then
        print(PREFIX .. "erosion boundary not loaded")
        return
    end
    boundary.report()
end

local function toggleBoundaryLog()
    local boundary = EeltsForestryRemastered_ErosionBoundary
    if not boundary then
        print(PREFIX .. "erosion boundary not loaded")
        return
    end
    boundary.verbose = not boundary.verbose
    print(PREFIX .. "correction logging " .. (boundary.verbose and "on" or "off"))
end

-- ErosionMain only recomputes the season on its own timer, so every date jump nudges it
local function advanceOneDay(gameTime)
    local day = gameTime:getDay() + 1
    local lastDay = gameTime:daysInMonth(gameTime:getYear(), gameTime:getMonth()) - 1
    if day > lastDay then
        day = 0
        local month = gameTime:getMonth() + 1
        if month >= 12 then
            month = 0
            gameTime:setYear(gameTime:getYear() + 1)
        end
        gameTime:setMonth(month)
    end
    gameTime:setDay(day)

    pcall(function()
        ErosionMain.getInstance():getSeasons():setDay(gameTime:getDay(), gameTime:getMonth(), gameTime:getYear())
    end)
end

-- A month lands on the same date every time, which steps straight over the deep autumn window
local function skipWeek(tree)
    local gameTime = GameTime.getInstance()
    for _ = 1, 7 do advanceOneDay(gameTime) end

    local system = Eelt_STreeGrowthSystem and Eelt_STreeGrowthSystem.instance
    if system then system:refreshAllOverlays() end

    print(string.format("%syear=%d month=%d day=%d season=%s", PREFIX,
        gameTime:getYear(), gameTime:getMonth(), gameTime:getDay(),
        tostring(getClimateManager():getSeasonName())))
    describe(tree)
end

-- Steps a year a day at a time and prints what the season model reports, because Early Summer
-- reporting 142 days and Autumn 64 does not reconcile with autumn starting in early September
local function logSeasonYear()
    local gameTime = GameTime.getInstance()
    local seasons = EeltsForestryRemastered_TreeSeasons

    local startYear, startMonth, startDay = gameTime:getYear(), gameTime:getMonth(), gameTime:getDay()
    local last = nil

    print(PREFIX .. "season year log: date, season, day of season, length of season, progress")
    for _ = 1, 365 do
        advanceOneDay(gameTime)

        local name = tostring(getClimateManager():getSeasonName())
        local seasonDay, seasonDays = -1, -1
        pcall(function()
            local erosion = ErosionMain.getInstance():getSeasons()
            seasonDay, seasonDays = erosion:getSeasonDay(), erosion:getSeasonDays()
        end)

        -- Only the changes matter, plus a line a week so the run is readable
        if name ~= last or seasonDay <= 1 or seasonDay % 7 == 0 then
            print(string.format("%s  %04d-%02d-%02d  %-13s day %3d of %3d  progress %.4f%s",
                PREFIX, gameTime:getYear(), gameTime:getMonth() + 1, gameTime:getDay() + 1,
                name, seasonDay, seasonDays, seasons.progress(),
                name ~= last and "   <- season change" or ""))
        end
        last = name
    end

    gameTime:setYear(startYear)
    gameTime:setMonth(startMonth)
    gameTime:setDay(startDay)
    pcall(function()
        ErosionMain.getInstance():getSeasons():setDay(startDay, startMonth, startYear)
    end)

    local system = Eelt_STreeGrowthSystem and Eelt_STreeGrowthSystem.instance
    if system then system:refreshAllOverlays() end
    print(string.format("%sseason year log done, date restored to %04d-%02d-%02d",
        PREFIX, startYear, startMonth + 1, startDay + 1))
end

-- Four overlay positions exist and the mod only ever asks for three, so this puts each one
-- on a tree to be looked at. The hourly tick puts the real season back
local function showFoliage(tree, seasonName)
    local system = Eelt_STreeGrowthSystem and Eelt_STreeGrowthSystem.instance
    local square = tree:getSquare()
    local luaObject = system and square and system:getLuaObjectOnSquare(square)
    if not luaObject then
        print(PREFIX .. "the mod does not own this tree")
        return
    end

    luaObject.overlaySeason = seasonName
    luaObject:applyOverlay(tree)
    if isServer() then tree:transmitUpdatedSpriteToClients() end
    square:RecalcAllWithNeighbours(true)

    local sprites = EeltsForestryRemastered_TreeGrowthSprites
    print(string.format("%sshowing %s: %s", PREFIX, tostring(seasonName),
        tostring(sprites.getOverlay(luaObject.tileset, luaObject.stage, seasonName) or "bare")))
end

local function addTreeOptions(context, tree)
    local option = context:addOption("Eelt's Forestry Remastered Debuggers", tree, nil)
    local submenu = ISContextMenu:getNew(context)
    context:addSubMenu(option, submenu)

    submenu:addOption("Adopt or grow one stage", tree, adoptOrGrow)
    submenu:addOption("Inspect this tree", tree, describe)
    submenu:addOption("Skip one month", tree, skipMonth)
    submenu:addOption("Skip one week", tree, skipWeek)
    submenu:addOption("Force a growth tick", tree, forceTick)

    local foliageOption = submenu:addOption("Show a foliage look", nil, nil)
    local foliageMenu = ISContextMenu:getNew(submenu)
    submenu:addSubMenu(foliageOption, foliageMenu)
    foliageMenu:addOption("Spring", tree, showFoliage, "Spring")
    foliageMenu:addOption("Summer green", tree, showFoliage, "Early Summer")
    foliageMenu:addOption("Tinted, the July look", tree, showFoliage, "Late Summer")
    foliageMenu:addOption("Autumn colour", tree, showFoliage, "Autumn")
    foliageMenu:addOption("Bare", tree, showFoliage, nil)
end

local function addPlantingOptions(context, worldobjects, playerObj, square)
    local option = context:addOption("Eelt's Forestry Remastered Planting", nil, nil)
    local submenu = ISContextMenu:getNew(context)
    context:addSubMenu(option, submenu)

    submenu:addOption("Inspect held propagules", worldobjects, describePropagules, playerObj)
    submenu:addOption("Survey trees around me", worldobjects, surveyTrees, playerObj)
    submenu:addOption("Year sweep", worldobjects, yearSweep, playerObj)
    submenu:addOption("Log a season year", nil, logSeasonYear)
    submenu:addOption("Boundary totals", nil, boundaryReport)
    submenu:addOption("Toggle correction logging", nil, toggleBoundaryLog)

    local speciesOption = submenu:addOption("Plant a species here", nil, nil)
    local speciesMenu = ISContextMenu:getNew(submenu)
    submenu:addSubMenu(speciesOption, speciesMenu)

    for _, tileset in ipairs(EeltsForestryRemastered_TreeGrowthSprites.species) do
        speciesMenu:addOption(EeltsForestryRemastered_Planting.speciesName(tileset),
            worldobjects, plantSpecies, playerObj, square, tileset)
    end
end

local function onFillWorldObjectContextMenu(player, context, worldobjects, test)
    if test or not isDebugAllowed(player) then return end

    local tree = findTree(worldobjects)
    if tree then addTreeOptions(context, tree) end

    local square = findSquare(worldobjects)
    local playerObj = getSpecificPlayer(player)
    if square and playerObj then addPlantingOptions(context, worldobjects, playerObj, square) end
end

Events.OnFillWorldObjectContextMenu.Add(onFillWorldObjectContextMenu)
