-- Blox Fruits Elite Hunter Tracker - Complete Version
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

-- Remove old UI if exists
local oldUI = PlayerGui:FindFirstChild("EliteHunterGui")
if oldUI then
    oldUI:Destroy()
end

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
            -- Call "EliteHunter" with "Progress" to get count
            local result = comm:InvokeServer("EliteHunter", "Progress")
            
            if result then
                if type(result) == "string" then
                    -- Parse "so far, you have defeated X elite enemies for me."
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
            -- Call "EliteHunter" to check availability
            local result = comm:InvokeServer("EliteHunter")
            
            if result and type(result) == "string" then
                local msg = string.lower(result)
                -- If message says "don't have anything", no quest available
                if string.find(msg, "don't have anything") or string.find(msg, "come back later") then
                    hasQuest = false
                else
                    -- Any other response means quest is available/active
                    hasQuest = true
                end
            elseif result == true or result == 1 then
                hasQuest = true
            end
        end
    end)
    
    return hasQuest
end

-- CREATE UI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "EliteHunterGui"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = PlayerGui

-- Main Frame (long horizontal rectangle at top)
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 500, 0, 80)
MainFrame.AnchorPoint = Vector2.new(0.5, 0)
MainFrame.Position = UDim2.new(0.5, 0, 0, 15)
MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
MainFrame.BorderSizePixel = 0
MainFrame.Parent = ScreenGui

-- Rounded corners
local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 12)
UICorner.Parent = MainFrame

-- Rainbow border stroke
local UIStroke = Instance.new("UIStroke")
UIStroke.Color = Color3.fromRGB(255, 0, 0)
UIStroke.Thickness = 3
UIStroke.Transparency = 0
UIStroke.Parent = MainFrame

-- Rainbow animation for border
spawn(function()
    local hue = 0
    while wait(0.03) do
        if not MainFrame.Parent then break end
        hue = (hue + 0.005) % 1
        UIStroke.Color = Color3.fromHSV(hue, 1, 1)
    end
end)

-- Container for content
local ContentFrame = Instance.new("Frame")
ContentFrame.Size = UDim2.new(1, -20, 1, -20)
ContentFrame.Position = UDim2.new(0, 10, 0, 10)
ContentFrame.BackgroundTransparency = 1
ContentFrame.Parent = MainFrame

-- Player Name Label
local PlayerNameLabel = Instance.new("TextLabel")
PlayerNameLabel.Name = "PlayerName"
PlayerNameLabel.Size = UDim2.new(1, -20, 0, 25)
PlayerNameLabel.Position = UDim2.new(0, 10, 0, 5)
PlayerNameLabel.BackgroundTransparency = 1
PlayerNameLabel.Font = Enum.Font.GothamBold
PlayerNameLabel.TextSize = 18
PlayerNameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
PlayerNameLabel.Text = "Player: " .. Player.Name
PlayerNameLabel.TextXAlignment = Enum.TextXAlignment.Left
PlayerNameLabel.Parent = ContentFrame

-- Elite Progress Label
local ProgressLabel = Instance.new("TextLabel")
ProgressLabel.Name = "Progress"
ProgressLabel.Size = UDim2.new(0.48, -10, 0, 22)
ProgressLabel.Position = UDim2.new(0, 10, 0, 32)
ProgressLabel.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
ProgressLabel.BorderSizePixel = 0
ProgressLabel.Font = Enum.Font.GothamBold
ProgressLabel.TextSize = 15
ProgressLabel.TextColor3 = Color3.fromRGB(100, 200, 255)
ProgressLabel.Text = "Elite Quests: ..."
ProgressLabel.TextXAlignment = Enum.TextXAlignment.Center
ProgressLabel.Parent = ContentFrame

-- Rounded corners for progress
local ProgressCorner = Instance.new("UICorner")
ProgressCorner.CornerRadius = UDim.new(0, 6)
ProgressCorner.Parent = ProgressLabel

-- Status Label
local StatusLabel = Instance.new("TextLabel")
StatusLabel.Name = "Status"
StatusLabel.Size = UDim2.new(0.48, -10, 0, 22)
StatusLabel.Position = UDim2.new(0.52, 0, 0, 32)
StatusLabel.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
StatusLabel.BorderSizePixel = 0
StatusLabel.Font = Enum.Font.GothamBold
StatusLabel.TextSize = 15
StatusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
StatusLabel.Text = "Status: Checking..."
StatusLabel.TextXAlignment = Enum.TextXAlignment.Center
StatusLabel.Parent = ContentFrame

-- Rounded corners for status
local StatusCorner = Instance.new("UICorner")
StatusCorner.CornerRadius = UDim.new(0, 6)
StatusCorner.Parent = StatusLabel

-- Update function
local function updateEliteInfo()
    local success, err = pcall(function()
        -- Update player name (show display name if different)
        local displayName = Player.DisplayName
        if displayName ~= Player.Name then
            PlayerNameLabel.Text = "Player: " .. displayName .. " (@" .. Player.Name .. ")"
        else
            PlayerNameLabel.Text = "Player: " .. Player.Name
        end
        
        -- Update progress
        local progress = GetEliteProgress()
        ProgressLabel.Text = "Elite Quests: " .. tostring(progress)
        
        -- Update status
        local hasQuest = HasEliteQuest()
        if hasQuest then
            StatusLabel.Text = "Status: Quest Available"
            StatusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
        else
            StatusLabel.Text = "Status: No Quest"
            StatusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
        end
        
        print("[Elite Hunter] Progress: " .. progress .. " | Quest Available: " .. tostring(hasQuest))
    end)
    
    if not success then
        warn("[Elite Hunter] Update failed: " .. tostring(err))
    end
end

-- Initial update with delay
print("[Elite Hunter] Waiting 2 seconds before first update...")
task.wait(2)
updateEliteInfo()

-- Auto-update loop every 3 seconds
spawn(function()
    while wait(3) do
        if ScreenGui.Parent then
            updateEliteInfo()
        else
            print("[Elite Hunter] UI removed, stopping updates")
            break
        end
    end
end)

-- Success message
print("=================================")
print("✓ Elite Hunter Tracker Loaded!")
print("✓ Position: Top center of screen")
print("✓ Auto-updates every 3 seconds")
print("✓ Rainbow border effect active")
print("=================================")
print("Features:")
print("  - Player Name display")
print("  - Elite Quests completed count")
print("  - Quest availability status")
print("=================================")
print("Status Colors:")
print("  🟢 Green = Quest Available")
print("  🔴 Red = No Quest (come back later)")
print("=================================")