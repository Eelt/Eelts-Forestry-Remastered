local PREFIX = "Eelt's Forestry Remastered: "

local GUIDE_TITLE_EN = "Tree Planting Guide"
local VHS_CATEGORY = "Home-VHS"
local ONE_IN = 260

-- Where a homeowner would keep a gardening tape
local ROOMS = {
    livingroom = true,
    shed = true,
    garagestorage = true,
    closet = true,
    storageunit = true,
}

local CONTAINERS = {
    shelves = true,
    sidetable = true,
    desk = true,
    wardrobe = true,
    crate = true,
}

local guide, searched

-- The guide is registered with spawning = 0, so it is never assigned to a tape by the
-- media system and has to be put on one directly
local function findGuide()
    if searched then return guide end
    searched = true

    local media = getZomboidRadio() and getZomboidRadio():getRecordedMedia()
    local list = media and media:getAllMediaForCategory(VHS_CATEGORY)
    for i = 0, list and list:size() - 1 or -1 do
        local data = list:get(i)
        if data:getTitleEN() == GUIDE_TITLE_EN then
            guide = data
            return guide
        end
    end

    print(PREFIX .. "could not find the " .. GUIDE_TITLE_EN .. " recording, the tape will not spawn")
    return nil
end

local function onFillContainer(roomName, containerType, container)
    if not ROOMS[roomName] or not CONTAINERS[containerType] then return end
    if ZombRand(ONE_IN) ~= 0 then return end

    local data = findGuide()
    if not data then return end

    local tape = container:AddItem("Base.VHS_Home")
    if tape then tape:setRecordedMediaData(data) end
end

Events.OnFillContainer.Add(onFillContainer)
