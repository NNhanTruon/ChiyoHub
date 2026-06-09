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

local Tabs = {
    Main = Window:AddTab({ Title = "Main", Icon = "play" }),
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

local infMaps = getMapList(game:GetService("ReplicatedStorage"):WaitForChild("API"):WaitForChild("Gamemode"):WaitForChild("story"))
local raidMaps = getMapList(game:GetService("ReplicatedStorage"):WaitForChild("API"):WaitForChild("Gamemode"):WaitForChild("raid"))

-- --- CÁC BIẾN CẤU HÌNH ---
local Config = {
    Mode = "Infinite", 
    SelectedMap = infMaps[1] or "Rome",
    Stage = 1,
    AutoLoop = false
}

-- --- GIAO DIỆN CHÍNH (GUI) ---
Tabs.Main:AddParagraph({
    Title = "Trạng thái hệ thống",
    Content = "Hãy cấu hình chế độ chơi và nhấn Bật Auto."
})

-- Chọn chế độ
local ModeDropdown = Tabs.Main:AddDropdown("GameMode", {
    Title = "Chọn Chế Độ Chơi",
    Values = {"Infinite", "Raid"},
    Multi = false,
    Default = "Infinite",
})

-- Chọn map (Cập nhật danh sách theo chế độ)
local MapDropdown = Tabs.Main:AddDropdown("MapSelect", {
    Title = "Chọn Bản Đồ (Map)",
    Values = infMaps,
    Multi = false,
    Default = infMaps[1],
})

-- ĐÃ CHUYỂN ĐỔI: Sử dụng Dropdown thay vì Slider để chọn Stage
local StageDropdown = Tabs.Main:AddDropdown("StageSelect", {
    Title = "Chọn Stage",
    Description = "Chọn phân đoạn từ 1 đến 6 (Áp dụng cho cả Inf và Raid)",
    Values = {"1", "2", "3", "4", "5", "6"},
    Multi = false,
    Default = "1",
})

ModeDropdown:OnChanged(function(Value)
    Config.Mode = Value
    if Value == "Infinite" then
        MapDropdown:SetValues(infMaps)
        MapDropdown:SetValue(infMaps[1])
    elseif Value == "Raid" then
        MapDropdown:SetValues(raidMaps)
        MapDropdown:SetValue(raidMaps[1])
    end
end)

MapDropdown:OnChanged(function(Value)
    Config.SelectedMap = Value
end)

-- Lắng nghe thay đổi của Stage Dropdown và ép kiểu về Number
StageDropdown:OnChanged(function(Value)
    Config.Stage = tonumber(Value) or 1
end)

-- Công tắc kích hoạt Loop
local ToggleAuto = Tabs.Main:AddToggle("AutoJoinToggle", {Title = "Bật Auto Loop (Mỗi 5s)", Default = false })

ToggleAuto:OnChanged(function()
    Config.AutoLoop = Options.AutoJoinToggle.Value
end)

-- --- HÀM XỬ LÝ LOGIC CHẠM VÀ GỬI REMOTE ---
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

local function runSequence()
    local targetStage = tonumber(Config.Stage) or 1
    
    if Config.Mode == "Infinite" then
        -- Bước 1: Giả lập chạm phòng Infinite thứ 4
        local infRooms = workspace:WaitForChild("Rooms"):WaitForChild("infinite")
        local targetRoom = infRooms:GetChildren()[4]
        if targetRoom and targetRoom:FindFirstChild("Touch") then
            fireTouch(targetRoom.Touch)
        end
        task.wait(0.5)

        -- Bước 2: Chọn màn hình Infinite với số Stage lấy từ Dropdown
        Remote:FireServer(unpack({"room_select", Config.SelectedMap, targetStage}))
        task.wait(0.5)

        -- Bước 3: Vào màn
        Remote:FireServer(unpack({"room_start"}))

    elseif Config.Mode == "Raid" then
        -- Bước 1: Giả lập chạm phòng Raid thứ 6
        local raidRooms = workspace:WaitForChild("Rooms"):WaitForChild("raid")
        local targetRoom = raidRooms:GetChildren()[6]
        if targetRoom and targetRoom:FindFirstChild("Touch") then
            fireTouch(targetRoom.Touch)
        end
        task.wait(1.5)

        -- Bước 2: Chọn màn hình Raid với số Stage lấy từ Dropdown
        Remote:FireServer(unpack({"room_select", Config.SelectedMap, targetStage}))
        task.wait(1.5)

        -- Bước 3: Vào màn
        Remote:FireServer(unpack({"room_start"}))
    end
end

-- --- VÒNG LẶP CHẠY NGẦM THỜI GIAN 5 GIÂY ---
task.spawn(function()
    while true do
        task.wait(5)
        if Config.AutoLoop then
            local success, err = pcall(function()
                runSequence()
            end)
            if not success then
                warn("Lỗi thực thi Auto Loop: ", err)
            end
        end
        if Fluent.Unloaded then break end
    end
end)

-- Quản lý cấu hình lưu trữ tiện ích Fluent
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
    Content = "Đã chuyển đổi Stage sang dạng Dropdown thành công!",
    Duration = 5
})

SaveManager:LoadAutoloadConfig()

