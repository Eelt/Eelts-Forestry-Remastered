require "Map/CGlobalObjectSystem"
require "Map/CGlobalObject"

Eelt_CTreeGrowthObject = CGlobalObject:derive("Eelt_CTreeGrowthObject")

function Eelt_CTreeGrowthObject:new(luaSystem, globalObject)
    return CGlobalObject.new(self, luaSystem, globalObject)
end

Eelt_CTreeGrowthSystem = CGlobalObjectSystem:derive("Eelt_CTreeGrowthSystem")

function Eelt_CTreeGrowthSystem:new()
    return CGlobalObjectSystem.new(self, "Eelt_TreeGrowth")
end

function Eelt_CTreeGrowthSystem:newLuaObject(globalObject)
    return Eelt_CTreeGrowthObject:new(self, globalObject)
end

function Eelt_CTreeGrowthSystem:isValidIsoObject(isoObject)
    return instanceof(isoObject, "IsoTree")
        and isoObject:getName() == EeltsForestryRemastered_TreeGrowthSprites.ADOPTED_NAME
end

CGlobalObjectSystem.RegisterSystemClass(Eelt_CTreeGrowthSystem)
