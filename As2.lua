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

---------------------------------------------------------------------------
-- MAIN TAB
---------------------------------------------------------------------------
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

---------------------------------------------------------------------------
-- STORY TAB
---------------------------------------------------------------------------
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

---------------------------------------------------------------------------
-- TOWER TAB
---------------------------------------------------------------------------
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

---------------------------------------------------------------------------
-- EVENT TAB
---------------------------------------------------------------------------
Tabs.Event:AddParagraph({
    Title = "Rush Mode Configuration",
    Content = "Auto join Artifact/Relic Rush only if you are near SpawnLocation (<= 500 flat studs)."
})

local RushModeDropdown = Tabs.Event:AddDropdown("RushModeSelect", {
    Title = "Select Rush Mode",
    Values = {"artifact_rush", "relic_rush"},
    Multi = false,
    Default = "artifact_rush",
})

local RushStageDropdown = Tabs.Event:AddDropdown("RushStageSelect", {
    Title = "Select Stage (1 - 3)",
    Values = {"1", "2", "3"},
    Multi = false,
    Default = "1",
})

local ToggleRush = Tabs.Event:AddToggle("AutoRushToggle", {Title = "Auto Join Rush Mode", Default = false })

Tabs.Event:AddParagraph({
    Title = "Maid Sash Event",
    Content = "Teleports to Maid Sash, interacts with the ProximityPrompt, and fires the portal request."
})

local ToggleEvent = Tabs.Event:AddToggle("AutoEventToggle", {Title = "Auto Join Event NPC", Default = false })

Tabs.Event:AddParagraph({
    Title = "Event Dungeon Loop",
    Content = "Automatically runs 'The Eclipse' (Stage 1, Normal) on loop."
})

local ToggleEventDungeon = Tabs.Event:AddToggle("AutoEventDungeonToggle", {Title = "Auto Loop Event Dungeon", Default = false })

---------------------------------------------------------------------------
-- REMOTES & HÀM KIỂM TRA SẢNH DÙNG CHUNG (TẤT CẢ CÁC MAP)
---------------------------------------------------------------------------
local Remote = game:GetService("ReplicatedStorage"):WaitForChild("API"):WaitForChild("Utils"):WaitForChild("network"):WaitForChild("RemoteEvent")
local LocalPlayer = game.Players.LocalPlayer

-- Khởi tạo bộ nhớ Master ẩn lưu trạng thái mong muốn thực tế của người chơi
local MasterState = {
    Dungeon = false,
    Story = false,
    Tower = false,
    EventNPC = false,
    EventDungeon = false,
    Rush = false
}

-- Biến cờ khóa trung gian chặn đứng lỗi phản hồi ngược từ SetValue()
local UI_Lock = false

-- Hàm quét vị trí sảnh độc lập hoạt động chính xác 100% của bạn
local function checkLobbyValid()
    local lobby = workspace:FindFirstChild("Lobby")
    local spawnPart = lobby and lobby:FindFirstChild("SpawnLocation")
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    
    if lobby and spawnPart and root then
        local playerPlanePos = Vector2.new(root.Position.X, root.Position.Z)
        local spawnPlanePos = Vector2.new(spawnPart.Position.X, spawnPart.Position.Z)
        local flatDistance = (playerPlanePos - spawnPlanePos).Magnitude
        
        if flatDistance <= 500 then
            return true, flatDistance
        end
        return false, flatDistance
    end
    return false, 0
end

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
        local root = char:WaitForChild("HumanoidRootPart", 3)
        if root then
            root.CFrame = npcInstance:GetPivot()
            task.wait(0.5)
        end
    end
end

---------------------------------------------------------------------------
-- SEQUENCE FUNCTIONS
---------------------------------------------------------------------------
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
        local root = character.HumanoidRootPart
        local distance = (root.Position - targetPos).Magnitude
        
        if distance > 10 then
            root.CFrame = CFrame.new(targetPos)
        else
            local prompt = npc:FindFirstChildWhichIsA("ProximityPrompt", true)
            if prompt then
                fireproximityprompt(prompt)
            end
            Remote:FireServer(unpack({"portal_start"}))
        end
    end
end

local function runEventDungeonSequence()
    Remote:FireServer(unpack({"battle_start", "portals", "The Eclipse", 1, "Normal"}))
end

---------------------------------------------------------------------------
-- ĐỒNG BỘ TOÀN BỘ CHẾ ĐỘ: TỰ ĐỘNG KHÓA / TỰ ĐỘNG BẬT LẠI KHI KHẢ NĂNG <= 500
---------------------------------------------------------------------------

-- 1. Chế độ Dungeon (Main Tab)
local dungeonThreadStarted = false
ToggleAuto:OnChanged(function()
    if UI_Lock then return end
    MasterState.Dungeon = Options.AutoJoinToggle.Value
    
    if MasterState.Dungeon and not dungeonThreadStarted then
        dungeonThreadStarted = true
        task.spawn(function()
            while true do
                if MasterState.Dungeon then
                    local inLobby = checkLobbyValid()
                    if inLobby then
                        if not Options.AutoJoinToggle.Value then 
                            UI_Lock = true; ToggleAuto:SetValue(true); UI_Lock = false 
                        end
                        pcall(runDungeonSequence)
                    else
                        if Options.AutoJoinToggle.Value then 
                            UI_Lock = true; ToggleAuto:SetValue(false); UI_Lock = false 
                        end
                    end
                end
                task.wait(5)
            end
        end)
    end
end)

-- 2. Chế độ Story (Cốt truyện)
local storyThreadStarted = false
ToggleStory:OnChanged(function()
    if UI_Lock then return end
    MasterState.Story = Options.AutoStoryToggle.Value
    
    if MasterState.Story and not storyThreadStarted then
        storyThreadStarted = true
        task.spawn(function()
            while true do
                if MasterState.Story then
                    local inLobby = checkLobbyValid()
                    if inLobby then
                        if not Options.AutoStoryToggle.Value then 
                            UI_Lock = true; ToggleStory:SetValue(true); UI_Lock = false 
                        end
                        pcall(runStorySequence)
                    else
                        if Options.AutoStoryToggle.Value then 
                            UI_Lock = true; ToggleStory:SetValue(false); UI_Lock = false 
                        end
                    end
                end
                task.wait(5)
            end
        end)
    end
end)

-- 3. Chế độ Tower (Leo tháp)
local towerThreadStarted = false
ToggleTower:OnChanged(function()
    if UI_Lock then return end
    MasterState.Tower = Options.AutoTowerToggle.Value
    
    if MasterState.Tower and not towerThreadStarted then
        towerThreadStarted = true
        task.spawn(function()
            while true do
                if MasterState.Tower then
                    local inLobby = checkLobbyValid()
                    if inLobby then
                        if not Options.AutoTowerToggle.Value then 
                            UI_Lock = true; ToggleTower:SetValue(true); UI_Lock = false 
                        end
                        pcall(runTowerSequence)
                    else
                        if Options.AutoTowerToggle.Value then 
                            UI_Lock = true; ToggleTower:SetValue(false); UI_Lock = false 
                        end
                    end
                end
                task.wait(6)
            end
        end)
    end
end)

-- 4. Chế độ Event NPC (Maid Sash)
local eventNPCThreadStarted = false
ToggleEvent:OnChanged(function()
    if UI_Lock then return end
    MasterState.EventNPC = Options.AutoEventToggle.Value
    
    if MasterState.EventNPC and not eventNPCThreadStarted then
        eventNPCThreadStarted = true
        task.spawn(function()
            while true do
                if MasterState.EventNPC then
                    local inLobby = checkLobbyValid()
                    if inLobby then
                        if not Options.AutoEventToggle.Value then 
                            UI_Lock = true; ToggleEvent:SetValue(true); UI_Lock = false 
                        end
                        pcall(runEventSequence)
                    else
                        if Options.AutoEventToggle.Value then 
                            UI_Lock = true; ToggleEvent:SetValue(false); UI_Lock = false 
                        end
                    end
                end
                task.wait(1)
            end
        end)
    end
end)

-- 5. Chế độ Event Dungeon Loop
local eventDungeonThreadStarted = false
ToggleEventDungeon:OnChanged(function()
    if UI_Lock then return end
    MasterState.EventDungeon = Options.AutoEventDungeonToggle.Value
    
    if MasterState.EventDungeon and not eventDungeonThreadStarted then
        eventDungeonThreadStarted = true
        task.spawn(function()
            while true do
                if MasterState.EventDungeon then
                    local inLobby = checkLobbyValid()
                    if inLobby then
                        if not Options.AutoEventDungeonToggle.Value then 
                            UI_Lock = true; ToggleEventDungeon:SetValue(true); UI_Lock = false 
                        end
                        pcall(runEventDungeonSequence)
                    else
                        if Options.AutoEventDungeonToggle.Value then 
                            UI_Lock = true; ToggleEventDungeon:SetValue(false); UI_Lock = false 
                        end
                    end
                end
                task.wait(5)
            end
        end)
    end
end)

-- 6. Chế độ Rush Mode (Artifact/Relic)
local rushThreadStarted = false
ToggleRush:OnChanged(function()
    if UI_Lock then return end 
    MasterState.Rush = Options.AutoRushToggle.Value
    
    if MasterState.Rush and not rushThreadStarted then
        rushThreadStarted = true
        task.spawn(function()
            while true do
                if MasterState.Rush then
                    local inLobby = checkLobbyValid()
                    if inLobby then
                        if not Options.AutoRushToggle.Value then 
                            UI_Lock = true; ToggleRush:SetValue(true); UI_Lock = false 
                        end
                        local mode = Options.RushModeSelect.Value or "artifact_rush"
                        local stage = tonumber(Options.RushStageSelect.Value) or 1
                        Remote:FireServer(unpack({"battle_start", mode, "Double Dungeon", stage, "Normal"}))
                    else
                        if Options.AutoRushToggle.Value then 
                            UI_Lock = true; ToggleRush:SetValue(false); UI_Lock = false 
                        end
                    end
                end
                task.wait(3)
            end
        end)
    end
end)

---------------------------------------------------------------------------
-- MANAGERS & CONFIGS
---------------------------------------------------------------------------
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
    Content = "All Modes synchronized with Auto-Resume Logic!",
    Duration = 5
})

SaveManager:LoadAutoloadConfig()
