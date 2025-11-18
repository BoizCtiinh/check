-- Blox Fruits Elite Hunter V2 - Final Version
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

print("========================================")
print("Elite Hunter V2 - Initializing...")
print("========================================")

-- STEP 1: CHOOSE TEAM FIRST
print("[1/3] Choosing team...")

local function ChooseTeam()
    -- Method 1: RemoteFunction (fastest)
    local success1 = pcall(function()
        local remotes = ReplicatedStorage:FindFirstChild("Remotes")
        if remotes then
            local commF = remotes:FindFirstChild("CommF_")
            if commF then
                commF:InvokeServer("SetTeam", "Pirates")
                print("✓ Team set via RemoteFunction")
                return true
            end
        end
    end)
    
    if success1 then
        task.wait(0.5)
        if Player.Team then
            print("✓ Team confirmed: " .. tostring(Player.Team))
            return true
        end
    end
    
    -- Method 2: UI Click (backup)
    print("Trying UI method...")
    local attempts = 0
    repeat
        attempts = attempts + 1
        task.wait(0.5)
        
        pcall(function()
            local main = PlayerGui:FindFirstChild("Main")
            if main then
                local chooseTeam = main:FindFirstChild("ChooseTeam")
                if chooseTeam and chooseTeam.Visible then
                    local container = chooseTeam:FindFirstChild("Container")
                    if container then
                        local pirates = container:FindFirstChild("Pirates")
                        if pirates then
                            -- Find and click button
                            for _, child in pairs(pirates:GetDescendants()) do
                                if child:IsA("TextButton") then
                                    for _, connection in pairs(getconnections(child.Activated)) do
                                        connection:Fire()
                                    end
                                    print("✓ Clicked Pirates button")
                                    break
                                end
                            end
                        end
                    end
                end
            end
        end)
        
    until Player.Team ~= nil or attempts >= 10
    
    if Player.Team then
        print("✓ Team selected: " .. tostring(Player.Team))
        return true
    else
        warn("⚠ Could not select team after " .. attempts .. " attempts")
        return false
    end
end

-- Execute team selection
ChooseTeam()
task.wait(1)

-- STEP 2: LOAD/SAVE CONFIG
print("[2/3] Loading configuration...")

-- Config file path
local CONFIG_FILE = "elite_hunter_config.json"

-- Load config from file
local function loadConfig()
    local success, result = pcall(function()
        if readfile and isfile and isfile(CONFIG_FILE) then
            local content = readfile(CONFIG_FILE)
            local config = HttpService:JSONDecode(content)
            print("✓ Config loaded from file")
            return config
        end
    end)
    
    if success and result then
        return result
    end
    
    -- Default config
    print("✓ Using default config")
    return {
        autoHop = false
    }
end

-- Save config to file
local function saveConfig(config)
    pcall(function()
        if writefile then
            local json = HttpService:JSONEncode(config)
            writefile(CONFIG_FILE, json)
            print("✓ Config saved to: " .. CONFIG_FILE)
        else
            warn("⚠ writefile not supported by executor")
        end
    end)
end

-- Load initial config
local savedConfig = loadConfig()

-- CONFIG
local AUTO_HOP_ENABLED = savedConfig.autoHop
local CHECK_INTERVAL = 5
local HOP_DELAY = 3

-- STATE
local isHopping = false
local lastCheckTime = 0

-- Remove old UI if exists
local oldUI = PlayerGui:FindFirstChild("EliteHunterV2Gui")
if oldUI then
    oldUI:Destroy()
end

-- STEP 3: CREATE UI
print("[3/3] Creating UI...")

-- UTILITY FUNCTIONS
local function getCommF()
    if not ReplicatedStorage then return nil end
    local rem = ReplicatedStorage:FindFirstChild("Remotes")
    if not rem then return nil end
    return rem:FindFirstChild("CommF_")
end

-- Get Elite Hunter progress
local function GetEliteProgress()
    local progress = 0
    
    pcall(function()
        local comm = getCommF()
        if comm then
            local result = comm:InvokeServer("EliteHunter", "Progress")
            
            if result then
                if type(result) == "string" then
                    local num = string.match(result, "defeated (%d+) elite")
                    if num then
                        progress = tonumber(num) or 0
                    end
                elseif type(result) == "number" then
                    progress = result
                end
            end
        end
    end)
    
    return progress
end

-- Check if Elite Quest is available
local function HasEliteQuest()
    local hasQuest = false
    
    pcall(function()
        local comm = getCommF()
        if comm then
            local result = comm:InvokeServer("EliteHunter")
            
            if result and type(result) == "string" then
                local msg = string.lower(result)
                if string.find(msg, "don't have anything") or string.find(msg, "come back later") then
                    hasQuest = false
                else
                    hasQuest = true
                end
            elseif result == true or result == 1 then
                hasQuest = true
            end
        end
    end)
    
    return hasQuest
end

-- Server Hop Function
local function ServerHop()
    if isHopping then return end
    isHopping = true
    
    print("[Elite Hunter V2] Starting server hop...")
    
    local success, result = pcall(function()
        local servers = {}
        local req = syn and syn.request or http and http.request or http_request or request
        
        if req then
            local response = req({
                Url = string.format("https://games.roblox.com/v1/games/%s/servers/Public?sortOrder=Asc&limit=100", game.PlaceId),
                Method = "GET"
            })
            
            if response and response.Body then
                local data = HttpService:JSONDecode(response.Body)
                
                if data and data.data then
                    for _, server in pairs(data.data) do
                        if server.playing < server.maxPlayers and server.id ~= game.JobId then
                            table.insert(servers, server.id)
                        end
                    end
                end
            end
        end
        
        if #servers > 0 then
            local randomServer = servers[math.random(1, #servers)]
            print("[Elite Hunter V2] Teleporting to server: " .. randomServer)
            TeleportService:TeleportToPlaceInstance(game.PlaceId, randomServer, Player)
        else
            print("[Elite Hunter V2] No servers found, using fallback")
            TeleportService:Teleport(game.PlaceId, Player)
        end
    end)
    
    if not success then
        warn("[Elite Hunter V2] Hop failed: " .. tostring(result))
        pcall(function()
            TeleportService:Teleport(game.PlaceId, Player)
        end)
    end
    
    task.wait(5)
    isHopping = false
end

-- CREATE UI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "EliteHunterV2Gui"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = PlayerGui

-- Main Frame
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 520, 0, 110)
MainFrame.AnchorPoint = Vector2.new(0.5, 0)
MainFrame.Position = UDim2.new(0.5, 0, 0, 15)
MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
MainFrame.BorderSizePixel = 0
MainFrame.Parent = ScreenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 12)
UICorner.Parent = MainFrame

-- Rainbow border
local UIStroke = Instance.new("UIStroke")
UIStroke.Color = Color3.fromRGB(255, 0, 0)
UIStroke.Thickness = 3
UIStroke.Transparency = 0
UIStroke.Parent = MainFrame

spawn(function()
    local hue = 0
    while wait(0.03) do
        if not MainFrame.Parent then break end
        hue = (hue + 0.005) % 1
        UIStroke.Color = Color3.fromHSV(hue, 1, 1)
    end
end)

-- Content Frame
local ContentFrame = Instance.new("Frame")
ContentFrame.Size = UDim2.new(1, -20, 1, -20)
ContentFrame.Position = UDim2.new(0, 10, 0, 10)
ContentFrame.BackgroundTransparency = 1
ContentFrame.Parent = MainFrame

-- Title
local TitleLabel = Instance.new("TextLabel")
TitleLabel.Name = "Title"
TitleLabel.Size = UDim2.new(1, -20, 0, 25)
TitleLabel.Position = UDim2.new(0, 10, 0, 5)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextSize = 18
TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleLabel.Text = "Elite Hunter V2 - Player: " .. Player.Name
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Parent = ContentFrame

-- Progress Label
local ProgressLabel = Instance.new("TextLabel")
ProgressLabel.Name = "Progress"
ProgressLabel.Size = UDim2.new(0.48, -10, 0, 22)
ProgressLabel.Position = UDim2.new(0, 10, 0, 35)
ProgressLabel.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
ProgressLabel.BorderSizePixel = 0
ProgressLabel.Font = Enum.Font.GothamBold
ProgressLabel.TextSize = 15
ProgressLabel.TextColor3 = Color3.fromRGB(100, 200, 255)
ProgressLabel.Text = "Elite Quests: ..."
ProgressLabel.TextXAlignment = Enum.TextXAlignment.Center
ProgressLabel.Parent = ContentFrame

local ProgressCorner = Instance.new("UICorner")
ProgressCorner.CornerRadius = UDim.new(0, 6)
ProgressCorner.Parent = ProgressLabel

-- Status Label
local StatusLabel = Instance.new("TextLabel")
StatusLabel.Name = "Status"
StatusLabel.Size = UDim2.new(0.48, -10, 0, 22)
StatusLabel.Position = UDim2.new(0.52, 0, 0, 35)
StatusLabel.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
StatusLabel.BorderSizePixel = 0
StatusLabel.Font = Enum.Font.GothamBold
StatusLabel.TextSize = 15
StatusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
StatusLabel.Text = "Status: Checking..."
StatusLabel.TextXAlignment = Enum.TextXAlignment.Center
StatusLabel.Parent = ContentFrame

local StatusCorner = Instance.new("UICorner")
StatusCorner.CornerRadius = UDim.new(0, 6)
StatusCorner.Parent = StatusLabel

-- Auto Hop Toggle Button
local ToggleButton = Instance.new("TextButton")
ToggleButton.Name = "ToggleButton"
ToggleButton.Size = UDim2.new(0.48, -10, 0, 22)
ToggleButton.Position = UDim2.new(0, 10, 0, 62)
ToggleButton.BackgroundColor3 = Color3.fromRGB(60, 60, 65)
ToggleButton.BorderSizePixel = 0
ToggleButton.Font = Enum.Font.GothamBold
ToggleButton.TextSize = 14
ToggleButton.TextColor3 = Color3.fromRGB(255, 100, 100)
ToggleButton.Text = "Auto Hop: OFF"
ToggleButton.Parent = ContentFrame

local ToggleCorner = Instance.new("UICorner")
ToggleCorner.CornerRadius = UDim.new(0, 6)
ToggleCorner.Parent = ToggleButton

-- Manual Hop Button
local HopButton = Instance.new("TextButton")
HopButton.Name = "HopButton"
HopButton.Size = UDim2.new(0.48, -10, 0, 22)
HopButton.Position = UDim2.new(0.52, 0, 0, 62)
HopButton.BackgroundColor3 = Color3.fromRGB(60, 60, 65)
HopButton.BorderSizePixel = 0
HopButton.Font = Enum.Font.GothamBold
HopButton.TextSize = 14
HopButton.TextColor3 = Color3.fromRGB(100, 200, 255)
HopButton.Text = "Hop Server Now"
HopButton.Parent = ContentFrame

local HopCorner = Instance.new("UICorner")
HopCorner.CornerRadius = UDim.new(0, 6)
HopCorner.Parent = HopButton

-- Update button UI based on loaded config
local function updateToggleButtonUI()
    if AUTO_HOP_ENABLED then
        ToggleButton.Text = "Auto Hop: ON"
        ToggleButton.TextColor3 = Color3.fromRGB(100, 255, 100)
        ToggleButton.BackgroundColor3 = Color3.fromRGB(40, 80, 40)
    else
        ToggleButton.Text = "Auto Hop: OFF"
        ToggleButton.TextColor3 = Color3.fromRGB(255, 100, 100)
        ToggleButton.BackgroundColor3 = Color3.fromRGB(60, 60, 65)
    end
end

-- Set initial button state
updateToggleButtonUI()

-- Toggle Auto Hop
ToggleButton.MouseButton1Click:Connect(function()
    AUTO_HOP_ENABLED = not AUTO_HOP_ENABLED
    
    updateToggleButtonUI()
    
    -- Save config
    saveConfig({
        autoHop = AUTO_HOP_ENABLED
    })
    
    print("[Elite Hunter V2] Auto Hop " .. (AUTO_HOP_ENABLED and "ENABLED" or "DISABLED"))
end)

-- Manual Hop Button
HopButton.MouseButton1Click:Connect(function()
    if not isHopping then
        StatusLabel.Text = "Status: Hopping..."
        StatusLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
        print("[Elite Hunter V2] Manual server hop triggered")
        task.wait(1)
        ServerHop()
    else
        print("[Elite Hunter V2] Already hopping, please wait")
    end
end)

-- Update function
local function updateEliteInfo()
    local success, err = pcall(function()
        local progress = GetEliteProgress()
        ProgressLabel.Text = "Elite Quests: " .. tostring(progress)
        
        local hasQuest = HasEliteQuest()
        
        if hasQuest then
            StatusLabel.Text = "Status: Quest Available"
            StatusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
        else
            StatusLabel.Text = "Status: No Quest"
            StatusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
            
            -- Auto hop if enabled
            if AUTO_HOP_ENABLED and not isHopping then
                local currentTime = tick()
                if currentTime - lastCheckTime >= CHECK_INTERVAL then
                    lastCheckTime = currentTime
                    print("[Elite Hunter V2] No quest found, hopping in " .. HOP_DELAY .. " seconds...")
                    StatusLabel.Text = "Status: Hopping in " .. HOP_DELAY .. "s"
                    StatusLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
                    task.wait(HOP_DELAY)
                    ServerHop()
                end
            end
        end
    end)
    
    if not success then
        warn("[Elite Hunter V2] Update failed: " .. tostring(err))
    end
end

-- Initial update
print("✓ UI Created")
task.wait(2)
updateEliteInfo()

-- Auto-update loop
spawn(function()
    while wait(CHECK_INTERVAL) do
        if ScreenGui.Parent then
            updateEliteInfo()
        else
            print("[Elite Hunter V2] UI removed, stopping")
            break
        end
    end
end)

-- Success message
print("========================================")
print("✓ Elite Hunter V2 Loaded Successfully!")
print("✓ Team: " .. tostring(Player.Team))
print("✓ Auto Hop: " .. (AUTO_HOP_ENABLED and "ON" or "OFF"))
print("✓ Config File: " .. CONFIG_FILE)
print("========================================")