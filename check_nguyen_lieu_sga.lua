-- Blox Fruits Material Counter UI - Complete Version
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

-- Remove old UI if exists
local oldUI = PlayerGui:FindFirstChild("MaterialCounterGui")
if oldUI then
    oldUI:Destroy()
end

-- UTILITY FUNCTIONS
local function norm(s)
    if not s then return "" end
    return tostring(s):gsub("[%s%-%_]", ""):lower()
end

-- Get RemoteFunction for inventory
local function getCommF()
    if not ReplicatedStorage then return nil end
    local rem = ReplicatedStorage:FindFirstChild("Remotes")
    if not rem then return nil end
    return rem:FindFirstChild("CommF_")
end

-- Get inventory via RemoteFunction
local function remoteGetInventory()
    local comm = getCommF()
    if not comm then return nil end

    local ok, inv = pcall(function()
        return comm:InvokeServer("getInventory")
    end)

    if ok then return inv end
    return nil
end

-- Main function to get material count (improved version from Mirage Helper)
local function GetMaterialCount(materialName)
    local total = 0
    
    -- Get inventory via RemoteFunction
    local inv = remoteGetInventory()

    -- Fallback to Player.Data.Inventory if remote fails
    if not inv then
        local ok, dinv = pcall(function()
            return Player:FindFirstChild("Data") 
                and Player.Data:FindFirstChild("Inventory") 
                and Player.Data.Inventory:GetChildren()
        end)
        inv = ok and dinv or nil
    end

    if not inv then 
        warn("[Material Counter] No inventory found")
        return 0 
    end

    -- Debug: print all items
    print("[Material Counter] Searching for: " .. materialName)
    
    -- Search through inventory items
    for _, v in pairs(inv) do
        local itemName = ""
        
        -- Get item name (handle both table and Instance)
        if type(v) == "table" then
            itemName = v.Name or ""
        elseif type(v) == "userdata" and v.Name then
            itemName = v.Name
        else
            itemName = tostring(v)
        end

        -- Normalize and compare
        local normalizedItem = norm(itemName)
        local normalizedSearch = norm(materialName)
        
        -- Check if this item matches
        if string.find(normalizedItem, normalizedSearch, 1, true) then
            print("[Material Counter] Found match: " .. itemName)
            
            local count = 1
            
            -- Method 1: Check for Value property directly
            if type(v) == "userdata" and v.Value then
                local val = tonumber(v.Value)
                if val then
                    count = val
                    print("[Material Counter] Count from .Value: " .. count)
                end
            end
            
            -- Method 2: Check children for NumberValue/IntValue
            if count == 1 and type(v) == "userdata" and v.GetChildren then
                for _, child in pairs(v:GetChildren()) do
                    if child:IsA("NumberValue") or child:IsA("IntValue") then
                        local num = tonumber(child.Value)
                        if num then
                            count = num
                            print("[Material Counter] Count from child: " .. count)
                            break
                        end
                    end
                end
            end
            
            -- Method 3: If it's a table, look for Count or Value key
            if count == 1 and type(v) == "table" then
                if v.Count then
                    count = tonumber(v.Count) or 1
                    print("[Material Counter] Count from table.Count: " .. count)
                elseif v.Value then
                    count = tonumber(v.Value) or 1
                    print("[Material Counter] Count from table.Value: " .. count)
                end
            end
            
            total = total + count
        end
    end

    print("[Material Counter] Total for " .. materialName .. ": " .. total)
    return total
end

-- CREATE UI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "MaterialCounterGui"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = PlayerGui

-- Main Frame (rounded rectangle)
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 200, 0, 110)
MainFrame.Position = UDim2.new(0, 15, 0.15, -55)
MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
MainFrame.BorderSizePixel = 0
MainFrame.Parent = ScreenGui

-- Rounded corners
local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 10)
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

-- Container for items
local ItemContainer = Instance.new("Frame")
ItemContainer.Size = UDim2.new(1, -20, 1, -20)
ItemContainer.Position = UDim2.new(0, 10, 0, 10)
ItemContainer.BackgroundTransparency = 1
ItemContainer.Parent = MainFrame

-- Layout
local UIListLayout = Instance.new("UIListLayout")
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.Padding = UDim.new(0, 8)
UIListLayout.Parent = ItemContainer

-- Create material label function
local function createMaterialLabel(name, order, color)
    local Label = Instance.new("TextLabel")
    Label.Name = name .. "Label"
    Label.Size = UDim2.new(1, 0, 0, 25)
    Label.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
    Label.BorderSizePixel = 0
    Label.Text = name .. ": ..."
    Label.TextColor3 = color
    Label.TextSize = 14
    Label.Font = Enum.Font.GothamBold
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.TextYAlignment = Enum.TextYAlignment.Center
    Label.LayoutOrder = order
    Label.Parent = ItemContainer
    
    -- Rounded corners for each item
    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 6)
    Corner.Parent = Label
    
    -- Padding
    local Padding = Instance.new("UIPadding")
    Padding.PaddingLeft = UDim.new(0, 10)
    Padding.Parent = Label
    
    return Label
end

-- Create 3 material labels
local DarkFragmentLabel = createMaterialLabel("Dark Fragment", 1, Color3.fromRGB(138, 43, 226))
local DemonicWispLabel = createMaterialLabel("Demonic Wisp", 2, Color3.fromRGB(255, 69, 58))
local VampireFangLabel = createMaterialLabel("Vampire Fang", 3, Color3.fromRGB(255, 215, 0))

-- Update function with debug logging
local function updateMaterialCounts()
    local success, err = pcall(function()
        print("[Material Counter] Starting update...")
        
        local darkCount = GetMaterialCount("Dark Fragment")
        local demonicCount = GetMaterialCount("Demonic Wisp")
        local vampireCount = GetMaterialCount("Vampire Fang")
        
        print("[Material Counter] Dark Fragment: " .. tostring(darkCount))
        print("[Material Counter] Demonic Wisp: " .. tostring(demonicCount))
        print("[Material Counter] Vampire Fang: " .. tostring(vampireCount))
        
        DarkFragmentLabel.Text = "Dark Fragment: " .. tostring(darkCount)
        DemonicWispLabel.Text = "Demonic Wisp: " .. tostring(demonicCount)
        VampireFangLabel.Text = "Vampire Fang: " .. tostring(vampireCount)
        
        print("[Material Counter] UI updated successfully")
    end)
    
    if not success then
        warn("[Material Counter] Update failed: " .. tostring(err))
    end
end

-- Initial update with longer delay
print("[Material Counter] Waiting 3 seconds before first update...")
task.wait(3)
updateMaterialCounts()

-- Auto-update loop every 3 seconds
spawn(function()
    while wait(3) do
        if ScreenGui.Parent then
            updateMaterialCounts()
        else
            print("[Material Counter] UI removed, stopping updates")
            break
        end
    end
end)

-- Success message
print("=================================")
print("✓ Material Counter UI Loaded!")
print("✓ Position: Top-left (0.15)")
print("✓ Auto-updates every 2 seconds")
print("✓ Rainbow border effect active")
print("=================================")
print("Materials tracked:")
print("  - Dark Fragment")
print("  - Demonic Wisp")
print("  - Vampire Fang")
print("=================================")