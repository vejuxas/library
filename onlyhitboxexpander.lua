-- Instant Hitbox Expander with Toggle + Triggerbot
-- Press T or click button to toggle hitbox
-- Press Y or click button to toggle triggerbot

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

-- Configuration (reads from _G.hitboxConfig or uses defaults)
local config = _G.hitboxConfig or {
    hitboxSize = 25,
    hitboxTransparency = 0.3,
    hitboxColor = Color3.fromRGB(1, 97, 121),
    outlineColor = Color3.fromRGB(255, 255, 255),
    hitboxKey = "T",
    triggerKey = "Y"
}

-- Toggle states
local hitboxEnabled = false
local triggerEnabled = false

-- Store original sizes
local originalSizes = {}
local selectionBoxes = {}

-- Triggerbot cooldown
local lastTriggerTime = 0
local triggerCooldown = 0  -- 650ms between shots (matches Da Hood gun cooldown)

-- Create UI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "HitboxToggleUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local hitboxButton = Instance.new("TextButton")
hitboxButton.Size = UDim2.new(0, 120, 0, 40)
hitboxButton.Position = UDim2.new(1, -130, 0, 10)  -- Top right
hitboxButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
hitboxButton.BorderSizePixel = 2
hitboxButton.BorderColor3 = Color3.fromRGB(0, 0, 255)
hitboxButton.Text = "Hitbox: OFF"
hitboxButton.TextColor3 = Color3.fromRGB(255, 255, 255)
hitboxButton.TextSize = 14
hitboxButton.Font = Enum.Font.GothamBold
hitboxButton.Parent = screenGui

local triggerButton = Instance.new("TextButton")
triggerButton.Size = UDim2.new(0, 120, 0, 40)
triggerButton.Position = UDim2.new(1, -130, 0, 55)  -- Below hitbox button, top right
triggerButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
triggerButton.BorderSizePixel = 2
triggerButton.BorderColor3 = Color3.fromRGB(255, 0, 0)
triggerButton.Text = "Trigger: OFF"
triggerButton.TextColor3 = Color3.fromRGB(255, 255, 255)
triggerButton.TextSize = 14
triggerButton.Font = Enum.Font.GothamBold
triggerButton.Parent = screenGui

local corner1 = Instance.new("UICorner")
corner1.CornerRadius = UDim.new(0, 6)
corner1.Parent = hitboxButton

local corner2 = Instance.new("UICorner")
corner2.CornerRadius = UDim.new(0, 6)
corner2.Parent = triggerButton

-- Function to expand hitbox
local function expandPlayerHitbox(player)
    if player == LocalPlayer then return end
    
    local character = player.Character
    if not character then return end
    
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if humanoidRootPart then
        local playerId = tostring(player.UserId)
        
        if not originalSizes[playerId] then
            originalSizes[playerId] = humanoidRootPart.Size
        end
        
        humanoidRootPart.Size = Vector3.new(config.hitboxSize, config.hitboxSize, config.hitboxSize)
        humanoidRootPart.Transparency = 1 -- Fully transparent so it doesn't block anything
        humanoidRootPart.CanCollide = false
        humanoidRootPart.CanTouch = false
        humanoidRootPart.Material = Enum.Material.ForceField
        humanoidRootPart.Color = config.hitboxColor
        
        -- Add blue outline
        if not selectionBoxes[playerId] then
            local selectionBox = Instance.new("SelectionBox")
            selectionBox.Adornee = humanoidRootPart
            selectionBox.Color3 = config.outlineColor
            selectionBox.LineThickness = 0.05
            selectionBox.Parent = humanoidRootPart
            selectionBoxes[playerId] = selectionBox
        end
    end
end

-- Function to restore hitbox
local function restorePlayerHitbox(player)
    if player == LocalPlayer then return end
    
    local character = player.Character
    if not character then return end
    
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if humanoidRootPart then
        local playerId = tostring(player.UserId)
        
        if originalSizes[playerId] then
            humanoidRootPart.Size = originalSizes[playerId]
            humanoidRootPart.Transparency = 1
            humanoidRootPart.CanCollide = false
            humanoidRootPart.Material = Enum.Material.Plastic
        end
        
        -- Remove outline
        if selectionBoxes[playerId] then
            selectionBoxes[playerId]:Destroy()
            selectionBoxes[playerId] = nil
        end
    end
end

-- Function to check if target is enemy
local function isEnemy(target)
    if not target then return false end
    
    local player = Players:GetPlayerFromCharacter(target.Parent)
    if not player then return false end
    if player == LocalPlayer then return false end
    
    local character = player.Character
    if not character then return false end
    
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.Health <= 0 then return false end
    
    return true
end

-- Function to get mouse target
local function getMouseTarget()
    local target = Mouse.Target
    if not target then return nil end
    
    -- Check if it's a player part
    if target.Parent and target.Parent:FindFirstChildOfClass("Humanoid") then
        return target
    end
    
    return nil
end

-- Weapon names from the game's system
local weaponNames = {
    "[Glock]", "[Silencer]", "[Shotgun]", "[Rifle]", "[SMG]", "[AR]",
    "[RPG]", "[GrenadeLauncher]", "[P90]", "[SilencerAR]", "[Revolver]",
    "[AK47]", "[TacticalShotgun]", "[DrumGun]", "[Flamethrower]",
    "[AUG]", "[LMG]", "[Double-Barrel SG]", "[Drum-Shotgun]", "[Flintlock]"
}

-- Function to get current weapon (custom game system)
local function getCurrentTool()
    local character = LocalPlayer.Character
    if not character then return nil end
    
    -- Check for standard tool
    for _, child in pairs(character:GetChildren()) do
        if child:IsA("Tool") then
            return child
        end
    end
    
    -- Check for custom weapons (game-specific)
    for _, weaponName in pairs(weaponNames) do
        local weapon = character:FindFirstChild(weaponName)
        if weapon then
            return weapon
        end
    end
    
    return nil
end

-- Function to simulate click (multiple methods for compatibility)
local function triggerClick()
    local currentTime = tick()
    if currentTime - lastTriggerTime < triggerCooldown then
        return
    end
    lastTriggerTime = currentTime
    
    local tool = getCurrentTool()
    
    if tool then
        -- Method 1: Properly activate the tool (triggers Tool.Activated event)
        pcall(function()
            tool:Activate()
        end)
        
        -- Wait a tiny bit then deactivate
        task.wait(0.01)
        
        pcall(function()
            tool:Deactivate()
        end)
    end
    
    -- Method 2: Mouse simulation for games that need it
    pcall(function()
        mouse1press()
        task.wait(0.01)
        mouse1release()
    end)
end

-- Toggle hitbox function
local function toggleHitbox()
    hitboxEnabled = not hitboxEnabled
    
    if hitboxEnabled then
        hitboxButton.Text = "Hitbox: ON"
        hitboxButton.BackgroundColor3 = Color3.fromRGB(0, 100, 0)
        print("Hitbox Expander enabled!")
    else
        hitboxButton.Text = "Hitbox: OFF"
        hitboxButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        print("Hitbox Expander disabled!")
        -- Restore all hitboxes
        for _, player in pairs(Players:GetPlayers()) do
            restorePlayerHitbox(player)
        end
    end
end

-- Toggle triggerbot function
local function toggleTrigger()
    triggerEnabled = not triggerEnabled
    
    if triggerEnabled then
        triggerButton.Text = "Trigger: ON"
        triggerButton.BackgroundColor3 = Color3.fromRGB(0, 100, 0)
        triggerButton.BorderColor3 = Color3.fromRGB(0, 255, 0)
        print("Triggerbot enabled!")
    else
        triggerButton.Text = "Trigger: OFF"
        triggerButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        triggerButton.BorderColor3 = Color3.fromRGB(255, 0, 0)
        print("Triggerbot disabled!")
    end
end

-- Button click handlers
hitboxButton.MouseButton1Click:Connect(toggleHitbox)
triggerButton.MouseButton1Click:Connect(toggleTrigger)

-- Keyboard input handlers
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == Enum.KeyCode[config.hitboxKey] then
        toggleHitbox()
    elseif input.KeyCode == Enum.KeyCode[config.triggerKey] then
        toggleTrigger()
    end
end)

-- Keep hitboxes expanded when enabled
RunService.Heartbeat:Connect(function()
    if hitboxEnabled then
        for _, player in pairs(Players:GetPlayers()) do
            expandPlayerHitbox(player)
        end
    end
end)

-- Triggerbot loop
RunService.RenderStepped:Connect(function()
    if not triggerEnabled then return end
    
    -- Check if player has a tool equipped
    local tool = getCurrentTool()
    if not tool then return end
    
    local target = getMouseTarget()
    if target and isEnemy(target) then
        triggerClick()
    end
end)

-- Additional bypass when enabled
RunService.Heartbeat:Connect(function()
    if hitboxEnabled then
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                local hrp = player.Character.HumanoidRootPart
                -- Try to disconnect monitoring connections
                pcall(function()
                    local connections = getconnections(hrp.Changed)
                    for _, connection in pairs(connections) do
                        connection:Disconnect()
                    end
                end)
            end
        end
    end
end)

-- Handle new players joining
Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function()
        wait(0.5)
        if hitboxEnabled then
            expandPlayerHitbox(player)
        end
    end)
end)

-- Handle player respawning
for _, player in pairs(Players:GetPlayers()) do
    player.CharacterAdded:Connect(function()
        wait(0.5)
        if hitboxEnabled then
            expandPlayerHitbox(player)
        end
    end)
end

-- Clean up when players leave
Players.PlayerRemoving:Connect(function(player)
    local playerId = tostring(player.UserId)
    originalSizes[playerId] = nil
    if selectionBoxes[playerId] then
        selectionBoxes[playerId]:Destroy()
        selectionBoxes[playerId] = nil
    end
end)

print("Hitbox Expander + Triggerbot loaded!")
print("Press " .. config.hitboxKey .. " to toggle hitbox")
print("Press " .. config.triggerKey .. " to toggle triggerbot")




