require "RadioCom/ISRadioInteractions"
require "EeltsForestryRemastered_Planting"

-- Line 11 of "Home VHS: Tree Planting Guide", the one about firming the soil back in.
-- OnDeviceText passes the line's translation key rather than the bare uuid
local PLANTING_LINE = "RM_9d6b0b33-78b5-47c2-8194-2396e4e0ef39"
local LEARN_COMMAND = "learnedTreePlanting"

local function isPlantingLine(guid)
    return guid == PLANTING_LINE
end

local function announce(player)
    HaloTextHelper.addGoodText(player, getText("IGUI_Eelt_LearnedTreePlanting"))
end

local function markKnown(player)
    local key = EeltsForestryRemastered_Planting.KNOWN_KEY
    local modData = player:getModData()
    if modData[key] then return false end
    modData[key] = true
    return true
end

local function grant(player)
    if not markKnown(player) then return end
    if isServer() then
        sendServerCommand(player, EeltsForestryRemastered_Planting.MODULE, LEARN_COMMAND, {})
    else
        announce(player)
    end
end

-- Vanilla marks the line known only once it has decided to process it, so the transition
-- from unknown to known is its own once per player guard and there is no need for another
local function install()
    local instance = ISRadioInteractions:getInstance()
    if not instance or instance.Eelt_checkPlayer then return end

    local ISRadioInteractions_checkPlayer = instance.checkPlayer
    instance.Eelt_checkPlayer = ISRadioInteractions_checkPlayer

    instance.checkPlayer = function(player, _guid, _interactCodes, _x, _y, _z, _line, _source)
        local watched = player ~= nil and isPlantingLine(_guid) and player:isKnownMediaLine(_guid)

        ISRadioInteractions_checkPlayer(player, _guid, _interactCodes, _x, _y, _z, _line, _source)

        if player and not watched and isPlantingLine(_guid) and player:isKnownMediaLine(_guid) then
            grant(player)
        end
    end
end

local function onServerCommand(module, command, args)
    if module ~= EeltsForestryRemastered_Planting.MODULE or command ~= LEARN_COMMAND then return end
    local player = getPlayer()
    if player and markKnown(player) then announce(player) end
end

Events.OnGameBoot.Add(install)
if not isServer() then Events.OnServerCommand.Add(onServerCommand) end
