-- Hitbox Expander Core Script
-- Do not modify this file directly, configure settings in the loader

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- Get settings from global config
local config = _G.HitboxExpanderConfig or {}

-- Variables
local hitboxEnabled = config.Enabled or false
local hitboxSize = config.Size or 10
local hitboxTransparency = config.Transparency or 0.5
local hitboxColor = config.Color or Color3.fromRGB(0, 255, 0)
local rainbowEnabled = config.Rainbow or false
local teamCheck = config.TeamCheck or false
local hitboxMaterial = config.Material or "ForceField"

local originalSizes = {}
local hitboxUpdateConnection = nil
local rainbowHue = 0

-- Material conversion
local materialEnum = {
    ["ForceField"] = Enum.Material.ForceField,
    ["Neon"] = Enum.Material.Neon,
    ["Glass"] = Enum.Material.Glass,
    ["Plastic"] = Enum.Material.Plastic,
    ["SmoothPlastic"] = Enum.Material.SmoothPlastic
}

-- Function to expand hitboxes
local function expandPlayerHitbox(player)
    if player == LocalPlayer then return end
    
    -- Team check
    if teamCheck and player.Team == LocalPlayer.Team and player.Team ~= nil then
        return
    end
    
    local character = player.Character
    if not character then return end
    
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if humanoidRootPart then
        local playerId = tostring(player.UserId)
        
        if not originalSizes[playerId] then
            originalSizes[playerId] = humanoidRootPart.Size
        end
        
        humanoidRootPart.Size = Vector3.new(hitboxSize, hitboxSize, hitboxSize)
        humanoidRootPart.Transparency = hitboxTransparency
        humanoidRootPart.CanCollide = false
        humanoidRootPart.Material = materialEnum[hitboxMaterial] or Enum.Material.ForceField
        
        -- Apply rainbow or normal color
        if rainbowEnabled then
            humanoidRootPart.Color = Color3.fromHSV(rainbowHue, 1, 1)
        else
            humanoidRootPart.Color = hitboxColor
        end
    end
end

-- Function to restore hitboxes
local function restorePlayerHitbox(player)
    if player == LocalPlayer then return end
    
    local character = player.Character
    if not character then return end
    
    local playerId = tostring(player.UserId)
    
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if humanoidRootPart and originalSizes[playerId] then
        humanoidRootPart.Size = originalSizes[playerId]
        humanoidRootPart.Transparency = 1
        humanoidRootPart.CanCollide = false
        humanoidRootPart.Material = Enum.Material.Plastic
        humanoidRootPart.Color = Color3.fromRGB(163, 162, 165)
        
        originalSizes[playerId] = nil
    end
end

-- Function to start hitbox expander
local function startHitboxExpander()
    if hitboxUpdateConnection then
        hitboxUpdateConnection:Disconnect()
        hitboxUpdateConnection = nil
    end
    
    if not hitboxEnabled then
        -- Restore all hitboxes
        for _, player in pairs(Players:GetPlayers()) do
            restorePlayerHitbox(player)
        end
        return
    end
    
    -- Expand all current players
    for _, player in pairs(Players:GetPlayers()) do
        expandPlayerHitbox(player)
    end
    
    -- Start update loop
    hitboxUpdateConnection = RunService.Heartbeat:Connect(function()
        -- Update rainbow hue
        if rainbowEnabled then
            rainbowHue = rainbowHue + 0.002
            if rainbowHue >= 1 then
                rainbowHue = 0
            end
        end
        
        for _, player in pairs(Players:GetPlayers()) do
            expandPlayerHitbox(player)
        end
    end)
    
    print("[Hitbox Expander] Started with size:", hitboxSize)
end

-- Handle new players
Players.PlayerAdded:Connect(function(player)
    wait(2)
    if hitboxEnabled then
        expandPlayerHitbox(player)
    end
end)

-- Handle players leaving
Players.PlayerRemoving:Connect(function(player)
    local playerId = tostring(player.UserId)
    originalSizes[playerId] = nil
end)

-- Start the expander
startHitboxExpander()

print("[Hitbox Expander] Loaded successfully!")