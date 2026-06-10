local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

local Window = Fluent:CreateWindow({
    Title = "Auto Dungeon Control",
    SubTitle = "Fixed & Optimized Version",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = false,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl
})

-- KHỞI TẠO CÁC TAB BIỆT LẬP
local Tabs = {
    Main = Window:AddTab({ Title = "Main", Icon = "play" }),
    Story = Window:AddTab({ Title = "Story", Icon = "book" }), -- Tab Story riêng biệt
    Event = Window:AddTab({ Title = "Event", Icon = "calendar" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" })
}

local Options = Fluent.Options

-- --- LẤY DỮ LIỆU ĐỘNG TỪ GAME ---
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

-- =======================================================
--            TAB MAIN (DUNGEON: INFINITE & RAID)
-- =======================================================
Tabs.Main:AddParagraph({
    Title = "Cấu hình Dungeon",
    Content = "Hãy cấu hình chế độ Infinite hoặc Raid và nhấn Bật Auto."
})

local ModeDropdown = Tabs.Main:AddDropdown("GameMode", {
    Title = "Chọn Chế Độ Chơi",
    Values = {"Infinite", "Raid"},
    Multi = false,
    Default = "Infinite",
})

local MapDropdown = Tabs.Main:AddDropdown("MapSelect", {
    Title = "Chọn Bản Đồ (Map)",
    Values = storyMaps,
    Multi = false,
    Default = storyMaps[1],
})

local StageDropdown = Tabs.Main:AddDropdown("StageSelect", {
    Title = "Chọn Stage",
    Description = "Chọn phân đoạn từ 1 đến 6",
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

local ToggleAuto = Tabs.Main:AddToggle("AutoJoinToggle", {Title = "Bật Auto Loop Dungeon", Default = false })


-- =======================================================
--                     TAB STORY (RIÊNG BIỆT)
-- =======================================================
Tabs.Story:AddParagraph({
    Title = "Cấu hình Chế Độ Story",
    Content = "Tự động gửi gói tin battle_start cho chế độ Cốt Truyện."
})

local StoryMapDropdown = Tabs.Story:AddDropdown("StoryMapSelect", {
    Title = "Chọn Bản Đồ (Story Map)",
    Values = storyMaps,
    Multi = false,
    Default = storyMaps[1],
})

local StoryStageDropdown = Tabs.Story:AddDropdown("StoryStageSelect", {
    Title = "Chọn Stage (1 - 8)",
    Values = {"1", "2", "3", "4", "5", "6", "7", "8"},
    Multi = false,
    Default = "1",
})

local StoryDifficultyDropdown = Tabs.Story:AddDropdown("StoryDiffSelect", {
    Title = "Chọn Độ Khó",
    Values = {"Normal", "Hard", "Nightmare"},
    Multi = false,
    Default = "Normal",
})

local ToggleStory = Tabs.Story:AddToggle("AutoStoryToggle", {Title = "Bật Auto Play Story", Default = false })


-- =======================================================
--                     TAB EVENT (GUI)
-- =======================================================
Tabs.Event:AddParagraph({
    Title = "Cấu hình Event Maid Sash",
    Content = "Tự động dịch chuyển đến Maid Sash, tương tác ProximityPrompt và gửi lệnh tham gia portal."
})

local ToggleEvent = Tabs.Event:AddToggle("AutoEventToggle", {Title = "Bật Auto Join Event", Default = false })


-- =======================================================
--                   LOGIC XỬ LÝ GAME
-- =======================================================
local Remote = game:GetService("ReplicatedStorage"):WaitForChild("API"):WaitForChild("Utils"):WaitForChild("network"):WaitForChild("RemoteEvent")
local LocalPlayer = game.Players.LocalPlayer

-- Hàm giả lập chạm bộ phận
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

-- Xử lý Dungeon (Infinite / Raid)
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

-- Xử lý Story riêng
local function runStorySequence()
    local selectedMap = Options.StoryMapSelect.Value
    local targetStage = tonumber(Options.StoryStageSelect.Value) or 1
    local diff = Options.StoryDiffSelect.Value or "Normal"
    
    local args = {
        "battle_start",
        "story",
        selectedMap,
        targetStage,
        diff
    }
    Remote:FireServer(unpack(args))
end

-- Hàm di chuyển và tương tác Event
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

-- =======================================================
--                 VÒNG LẶP CHẠY NGẦM (LOOP)
-- =======================================================

-- Vòng lặp chính cho Dungeon (Mỗi 5 giây)
task.spawn(function()
    while true do
        task.wait(5)
        if Options.AutoJoinToggle and Options.AutoJoinToggle.Value then
            local success, err = pcall(runDungeonSequence)
            if not success then warn("Lỗi thực thi Auto Dungeon: ", err) end
        end
        if Fluent.Unloaded then break end
    end
end)

-- Vòng lặp chính cho Story (Mỗi 5 giây)
task.spawn(function()
    while true do
        task.wait(5)
        if Options.AutoStoryToggle and Options.AutoStoryToggle.Value then
            local success, err = pcall(runStorySequence)
            if not success then warn("Lỗi thực thi Auto Story: ", err) end
        end
        if Fluent.Unloaded then break end
    end
end)

-- Vòng lặp chính cho Event (Mỗi 1 giây)
task.spawn(function()
    while true do
        task.wait(1)
        if Options.AutoEventToggle and Options.AutoEventToggle.Value then
            local success, err = pcall(runEventSequence)
            if not success then warn("Lỗi thực thi Auto Event: ", err) end
        end
        if Fluent.Unloaded then break end
    end
end)


-- =======================================================
--                 QUẢN LÝ CẤU HÌNH (SETTINGS)
-- =======================================================
SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({})
InterfaceManager:SetFolder("AutoDungeonConfig")
SaveManager:SetFolder("AutoDungeonConfig/configs")
InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)

Window:SelectTab(Tabs.Main)

Fluent:Notify({
    Title = "Hệ thống sẵn sàng",
    Content = "Đã tách riêng Tab Story và sửa hoàn toàn lỗi giao diện!",
    Duration = 5
})

SaveManager:LoadAutoloadConfig()
