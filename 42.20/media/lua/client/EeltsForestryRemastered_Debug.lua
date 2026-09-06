
print("Eelt's Forestry Remastered Mod: file loaded (parse time)")

local function onGameStart()
    print("Eelt's Forestry Remastered Mod: OnGameStart fired, Hello World!")
end
Events.OnGameStart.Add(onGameStart)

local function onMainMenuEnter()
    print("Eelt's Forestry Remastered Mod: main menu reached, Hello World!")
end
Events.OnMainMenuEnter.Add(onMainMenuEnter)
