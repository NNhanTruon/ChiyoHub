local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

local Window = Fluent:CreateWindow({
    Title = "NhanP Hub",
    SubTitle = "Fixed & Optimized Version",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = false,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl
})

local Tabs = {
    Main = Window:AddTab({ Title = "Main", Icon = "play" }),
    Story = Window:AddTab({ Title = "Story", Icon = "book" }),
    Tower = Window:AddTab({ Title = "Tower", Icon = "layers" }),
    Event = Window:AddTab({ Title = "Event", Icon = "calendar" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" })
}

local Options = Fluent.Options

local function getMapList(path)
    local list = {}
    local success, folder = pcall(function() return path:GetChildren() end)
    if success and folder then
        for _, item in ipairs(folder) do
            table.insert(list, item.Name)
        end
    end
    if #list == 0 then table.insert(list, "None") end
    return list
end

local storyMaps = getMapList(game:GetService("ReplicatedStorage"):WaitForChild("API"):WaitForChild("Gamemode"):WaitForChild("story"))
local raidMaps = getMapList(game:GetService("ReplicatedStorage"):WaitForChild("API"):WaitForChild("Gamemode"):WaitForChild("raid"))

Tabs.Main:AddParagraph({
    Title = "System Status",
    Content = "Configure your game mode settings and enable Auto Join."
})

local ModeDropdown = Tabs.Main:AddDropdown("GameMode", {
    Title = "Select Game Mode",
    Values = {"Infinite", "Raid"},
    Multi = false,
    Default = "Infinite",
})

local MapDropdown = Tabs.Main:AddDropdown("MapSelect", {
    Title = "Select Map",
    Values = storyMaps,
    Multi = false,
    Default = storyMaps[1],
})

local StageDropdown = Tabs.Main:AddDropdown("StageSelect", {
    Title = "Select Stage",
    Values = {"1", "2", "3", "4", "5", "6"},
    Multi = false,
    Default = "1",
})

ModeDropdown:OnChanged(function(Value)
    if Value == "Infinite" then
        MapDropdown:SetValues(storyMaps)
    elseif Value == "Raid" then
        MapDropdown:SetValues(raidMaps)
    end
end)

local ToggleAuto = Tabs.Main:AddToggle("AutoJoinToggle", {Title = "Auto Loop Dungeon", Default = false })

Tabs.Story:AddParagraph({
    Title = "Story Mode Configuration",
    Content = "Automatically sends battle_start requests for Story Mode."
})

local StoryMapDropdown = Tabs.Story:AddDropdown("StoryMapSelect", {
    Title = "Select Story Map",
    Values = storyMaps,
    Multi = false,
    Default = storyMaps[1],
})

local StoryStageDropdown = Tabs.Story:AddDropdown("StoryStageSelect", {
    Title = "Select Stage (1 - 8)",
    Values = {"1", "2", "3", "4", "5", "6", "7", "8"},
    Multi = false,
    Default = "1",
})

local StoryDifficultyDropdown = Tabs.Story:AddDropdown("StoryDiffSelect", {
    Title = "Select Difficulty",
    Values = {"Normal", "Hard", "Nightmare"},
    Multi = false,
    Default = "Normal",
})

local ToggleStory = Tabs.Story:AddToggle("AutoStoryToggle", {Title = "Auto Play Story", Default = false })

Tabs.Tower:AddParagraph({
    Title = "Tower Configuration",
    Content = "Teleports to the NPC to load the GUI, scans your highest unlocked floor, and joins automatically."
})

local TowerModeDropdown = Tabs.Tower:AddDropdown("TowerModeSelect", {
    Title = "Select Tower Type",
    Values = {"Tower", "Hard Tower"},
    Multi = false,
    Default = "Tower",
})

local ToggleTower = Tabs.Tower:AddToggle("AutoTowerToggle", {Title = "Auto Climb Tower", Default = false })

Tabs.Event:AddParagraph({
    Title = "Maid Sash Event Configuration",
    Content = "Teleports to Maid Sash, interacts with the ProximityPrompt, and fires the portal request."
})

local ToggleEvent = Tabs.Event:AddToggle("AutoEventToggle", {Title = "Auto Join Event", Default = false })

local Remote = game:GetService("ReplicatedStorage"):WaitForChild("API"):WaitForChild("Utils"):WaitForChild("network"):WaitForChild("RemoteEvent")
local LocalPlayer = game.Players.LocalPlayer

local function fireTouch(targetPart)
    if not targetPart then return end
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local root = char:WaitForChild("HumanoidRootPart", 3)
    if root and firetouchinterest then
        firetouchinterest(root, targetPart, 1)
        task.wait(0.1)
        firetouchinterest(root, targetPart, 0)
    end
end

local function teleportToNPC(npcInstance)
    if npcInstance and npcInstance:IsA("Model") then
        local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
        local hrp = char:WaitForChild("HumanoidRootPart", 3)
        if hrp then
            hrp.CFrame = npcInstance:GetPivot()
            task.wait(0.5)
        end
    end
end

local function runDungeonSequence()
    local currentMode = Options.GameMode.Value
    local selectedMap = Options.MapSelect.Value
    local targetStage = tonumber(Options.StageSelect.Value) or 1
    
    if currentMode == "Infinite" then
        local infRooms = workspace:WaitForChild("Rooms"):WaitForChild("infinite")
        local targetRoom = infRooms:GetChildren()[4]
        if targetRoom and targetRoom:FindFirstChild("Touch") then
            fireTouch(targetRoom.Touch)
        end
        task.wait(0.5)
        Remote:FireServer(unpack({"room_select", selectedMap, targetStage}))
        task.wait(0.5)
        Remote:FireServer(unpack({"room_start"}))

    elseif currentMode == "Raid" then
        local raidRooms = workspace:WaitForChild("Rooms"):WaitForChild("raid")
        local targetRoom = raidRooms:GetChildren()[6]
        if targetRoom and targetRoom:FindFirstChild("Touch") then
            fireTouch(targetRoom.Touch)
        end
        task.wait(1.5)
        Remote:FireServer(unpack({"room_select", selectedMap, targetStage}))
        task.wait(1.5)
        Remote:FireServer(unpack({"room_start"}))
    end
end

local function runStorySequence()
    local selectedMap = Options.StoryMapSelect.Value
    local targetStage = tonumber(Options.StoryStageSelect.Value) or 1
    local diff = Options.StoryDiffSelect.Value or "Normal"
    
    Remote:FireServer(unpack({"battle_start", "story", selectedMap, targetStage, diff}))
end

local function runTowerSequence()
    local chosenTower = Options.TowerModeSelect.Value
    local mainGui = LocalPlayer:WaitForChild("PlayerGui"):WaitForChild("main")
    local finalHighestFloor = 1

    if chosenTower == "Tower" then
        local npc = workspace:WaitForChild("Lobby"):WaitForChild("NPC"):WaitForChild("Tower")
        teleportToNPC(npc)

        local gridPath = mainGui:WaitForChild("Tower"):WaitForChild("Base"):WaitForChild("Content"):WaitForChild("Grid")
        
        local maxFloor = 1
        for _, item in ipairs(gridPath:GetChildren()) do
            local num = tonumber(item.Name)
            if num and num > maxFloor then
                maxFloor = num
            end
        end
        finalHighestFloor = maxFloor

        Remote:FireServer(unpack({"battle_start", "tower", "Tower", finalHighestFloor, "Normal"}))

    elseif chosenTower == "Hard Tower" then
        local npc = workspace:WaitForChild("Lobby"):WaitForChild("NPC"):WaitForChild("HardTower")
        teleportToNPC(npc)

        local hardTowerFolder = mainGui:WaitForChild("HardTower")
        
        local maxFloor = 1
        for _, item in ipairs(hardTowerFolder:GetChildren()) do
            local num = tonumber(item.Name)
            if num and num > maxFloor then
                maxFloor = num
            end
        end
        finalHighestFloor = maxFloor

        Remote:FireServer(unpack({"battle_start", "hardTower", "Tower", finalHighestFloor, "Normal"}))
    end
end

local function runEventSequence()
    local npc = workspace:FindFirstChild("Maid Sash")
    local character = LocalPlayer.Character
    
    if npc and character and character:FindFirstChild("HumanoidRootPart") then
        local targetPos = npc:GetPivot().Position
        local hrp = character.HumanoidRootPart
        local distance = (hrp.Position - targetPos).Magnitude
        
        if distance > 10 then
            hrp.CFrame = CFrame.new(targetPos)
        else
            local prompt = npc:FindFirstChildWhichIsA("ProximityPrompt", true)
            if prompt then
                fireproximityprompt(prompt)
            end
            Remote:FireServer(unpack({"portal_start"}))
        end
    end
end

task.spawn(function()
    while true do
        task.wait(5)
        if Options.AutoJoinToggle and Options.AutoJoinToggle.Value then
            local success, err = pcall(runDungeonSequence)
            if not success then warn("Auto Dungeon Error: ", err) end
        end
        if Fluent.Unloaded then break end
    end
end)

task.spawn(function()
    while true do
        task.wait(5)
        if Options.AutoStoryToggle and Options.AutoStoryToggle.Value then
            local success, err = pcall(runStorySequence)
            if not success then warn("Auto Story Error: ", err) end
        end
        if Fluent.Unloaded then break end
    end
end)

task.spawn(function()
    while true do
        task.wait(6)
        if Options.AutoTowerToggle and Options.AutoTowerToggle.Value then
            local success, err = pcall(runTowerSequence)
            if not success then warn("Auto Tower Error: ", err) end
        end
        if Fluent.Unloaded then break end
    end
end)

task.spawn(function()
    while true do
        task.wait(1)
        if Options.AutoEventToggle and Options.AutoEventToggle.Value then
            local success, err = pcall(runEventSequence)
            if not success then warn("Auto Event Error: ", err) end
        end
        if Fluent.Unloaded then break end
    end
end)

SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({})
InterfaceManager:SetFolder("NhanPHubConfig")
SaveManager:SetFolder("NhanPHubConfig/configs")
InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)

Window:SelectTab(Tabs.Main)

Fluent:Notify({
    Title = "System Ready",
    Content = "NhanP Hub executed successfully!",
    Duration = 5
})

SaveManager:LoadAutoloadConfig()
