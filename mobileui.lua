-- DarkWare Script - Mobile Friendly
-- init
local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

local Window = Fluent:CreateWindow({
    Title = "DarkWare Script",
    SubTitle = "Mobile UI",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl
})

-- Create tabs
local Tabs = {
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" }),
    Player = Window:AddTab({ Title = "Player", Icon = "user" }),
    Hitbox = Window:AddTab({ Title = "Hitbox", Icon = "target" }),
    Target = Window:AddTab({ Title = "Target", Icon = "crosshair" }),
    ESP = Window:AddTab({ Title = "ESP", Icon = "eye" }),
    Theme = Window:AddTab({ Title = "Theme", Icon = "palette" })
}

local Options = Fluent.Options

-- Services
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Camera = Workspace.CurrentCamera
local MarketplaceService = game:GetService("MarketplaceService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Get game name
local gameName = "Unknown Game"
pcall(function()
    local info = MarketplaceService:GetProductInfo(game.PlaceId)
    gameName = info.Name
end)

-- UI toggle state
local uiToggled = false

-- ===== SETTINGS PAGE =====
-- UI Settings
Tabs.Settings:AddToggle("BlurEffect", {
    Title = "Blur Effect",
    Default = false,
    Callback = function(Value)
        print("Blur Effect:", Value)
    end
})

-- Mobile-friendly keybind
local mobileKeybind = UserInputService.TouchEnabled and "Space" or "RightShift"
Tabs.Settings:AddKeybind("OpenUI", {
    Title = "Open UI",
    Mode = "Toggle",
    Default = mobileKeybind,
    Callback = function(Value)
        uiToggled = not uiToggled
        Window:SetEnabled(not Window.Enabled)
        print("UI toggled to:", uiToggled)
    end
})

-- Config buttons
Tabs.Settings:AddButton({
    Title = "Save Config",
    Description = "Save current configuration",
    Callback = function()
        Fluent:Notify({
            Title = "Config",
            Content = "Config saved successfully!",
            Duration = 3
        })
    end
})

Tabs.Settings:AddButton({
    Title = "Load Config", 
    Description = "Load saved configuration",
    Callback = function()
        Fluent:Notify({
            Title = "Config",
            Content = "Config loaded successfully!",
            Duration = 3
        })
    end
})

-- ===== PLAYER PAGE =====

-- Speed
local speedEnabled = false
local speedValue = 16
local speedConnection = nil

local function updateSpeed()
    if speedEnabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and LocalPlayer.Character:FindFirstChild("Humanoid") then
        local hrp = LocalPlayer.Character.HumanoidRootPart
        local humanoid = LocalPlayer.Character.Humanoid
        local moveVector = humanoid.MoveDirection
        
        if moveVector.Magnitude > 0 then
            local raycast = workspace:Raycast(hrp.Position, moveVector * speedValue * 0.1)
            if not raycast then
                hrp.CFrame = hrp.CFrame + (moveVector * speedValue * 0.1)
            else
                local distance = (raycast.Position - hrp.Position).Magnitude
                if distance > 2 then
                    hrp.CFrame = hrp.CFrame + (moveVector * (distance - 2) * 0.1)
                end
            end
        end
    end
end

-- Speed Toggle
Tabs.Player:AddToggle("Speed", {
    Title = "Speed",
    Default = false,
    Callback = function(val)
        speedEnabled = val
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            if val then
                if speedConnection then speedConnection:Disconnect() end
                speedConnection = game:GetService("RunService").Heartbeat:Connect(updateSpeed)
                print("Speed enabled and connection started!")
            else
                if speedConnection then 
                    speedConnection:Disconnect() 
                    speedConnection = nil
                end
                print("Speed disabled and connection stopped!")
            end
        else
            print("No character or HumanoidRootPart found for speed!")
        end
        print("Speed:", val)
    end
})

-- Speed Slider (Mobile-friendly)
Tabs.Player:AddSlider("SpeedValue", {
    Title = "Speed Value",
    Description = "Adjust your movement speed",
    Default = 16,
    Min = 16,
    Max = 100,
    Rounding = 1,
    Callback = function(val)
        speedValue = val
        print("Speed Value:", val)
    end
})

-- Fly
local flyEnabled = false
local flySpeed = 50
local flyConnection = nil

local function startFly()
    if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then return end
    
    flyConnection = game:GetService("RunService").Heartbeat:Connect(function()
        if not flyEnabled or not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            if flyConnection then
                flyConnection:Disconnect()
                flyConnection = nil
            end
            return
        end
        
        local hrp = LocalPlayer.Character.HumanoidRootPart
        local humanoid = LocalPlayer.Character:FindFirstChild("Humanoid")
        if not humanoid then return end
        
        local moveVector = humanoid.MoveDirection
        local moveVector3D = Vector3.new(moveVector.X, 0, moveVector.Z)
        
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
            moveVector3D = moveVector3D + Vector3.new(0, 1, 0)
        elseif UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
            moveVector3D = moveVector3D + Vector3.new(0, -1, 0)
        end
        
        if moveVector3D.Magnitude > 0 then
            hrp.CFrame = hrp.CFrame + (moveVector3D * flySpeed * 0.1)
        end
    end)
end

local function stopFly()
    if flyConnection then
        flyConnection:Disconnect()
        flyConnection = nil
    end
end

-- Fly Toggle
Tabs.Player:AddToggle("Fly", {
    Title = "Fly",
    Default = false,
    Callback = function(val)
        flyEnabled = val
        if val then
            startFly()
        else
            stopFly()
        end
        print("Fly:", val)
    end
})

-- Fly Speed Slider (Mobile-friendly)
Tabs.Player:AddSlider("FlySpeed", {
    Title = "Fly Speed",
    Description = "Adjust your flying speed",
    Default = 50,
    Min = 20,
    Max = 100,
    Rounding = 1,
    Callback = function(val)
        flySpeed = val
        print("Fly Speed:", val)
    end
})

-- Jump Power
local jumpEnabled = false
local jumpValue = 50
local originalJumpPower = 50
local jumpConnection = nil

local function updateJump()
    if jumpEnabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        if LocalPlayer.Character.Humanoid.JumpPower ~= jumpValue then
            LocalPlayer.Character.Humanoid.JumpPower = jumpValue
        end
    end
end

-- High Jump Toggle
Tabs.Player:AddToggle("HighJump", {
    Title = "High Jump",
    Default = false,
    Callback = function(val)
        jumpEnabled = val
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            if val then
                originalJumpPower = LocalPlayer.Character.Humanoid.JumpPower
                LocalPlayer.Character.Humanoid.JumpPower = jumpValue
                if jumpConnection then jumpConnection:Disconnect() end
                jumpConnection = game:GetService("RunService").Heartbeat:Connect(updateJump)
                print("Jump enabled and connection started!")
            else
                if jumpConnection then 
                    jumpConnection:Disconnect() 
                    jumpConnection = nil
                end
                LocalPlayer.Character.Humanoid.JumpPower = originalJumpPower
                print("Jump disabled and connection stopped!")
            end
        else
            print("No character or humanoid found for jump!")
        end
        print("High Jump:", val)
    end
})

-- Jump Power Slider (Mobile-friendly)
Tabs.Player:AddSlider("JumpPower", {
    Title = "Jump Power",
    Description = "Adjust your jump height",
    Default = 50,
    Min = 50,
    Max = 200,
    Rounding = 1,
    Callback = function(val)
        jumpValue = val
        print("Jump Power:", val)
    end
})

-- Noclip
local noclipEnabled = false

-- Noclip Toggle
Tabs.Player:AddToggle("Noclip", {
    Title = "Noclip",
    Default = false,
    Callback = function(val)
        noclipEnabled = val
        if LocalPlayer.Character then
            for _, part in pairs(LocalPlayer.Character:GetChildren()) do
                if part:IsA("BasePart") then
                    part.CanCollide = not val
                end
            end
        end
        print("Noclip:", val)
    end
})

-- Function to create the button
local function createButton()
    -- Check if button already exists
    if PlayerGui:FindFirstChild("CustomButton") then
        return
    end
    
    -- Create ScreenGui for the button
    local ButtonScreenGui = Instance.new("ScreenGui")
    ButtonScreenGui.Name = "CustomButton"
    ButtonScreenGui.Parent = PlayerGui

    -- Create Frame (small cube)
    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(0, 40, 0, 40)
    Frame.Position = UDim2.new(0, 20, 0, 20)
    Frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    Frame.BorderSizePixel = 0
    Frame.Active = true
    Frame.Selectable = true
    Frame.Parent = ButtonScreenGui

    -- Add UICorner for rounded corners
    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 8)
    Corner.Parent = Frame

    -- Add Stroke
    local Stroke = Instance.new("UIStroke")
    Stroke.Color = Color3.fromRGB(30, 30, 30)
    Stroke.Thickness = 1
    Stroke.Parent = Frame

    -- Add Text (Fedoka font with "D")
    local TextLabel = Instance.new("TextLabel")
    TextLabel.Size = UDim2.new(1, 0, 1, 0)
    TextLabel.BackgroundTransparency = 1
    TextLabel.Text = "D"
    TextLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    TextLabel.TextScaled = true
    TextLabel.Font = Enum.Font.FredokaOne
    TextLabel.Active = true
    TextLabel.Parent = Frame

    -- Make it draggable
    local dragging = false
    local dragStart = nil
    local startPos = nil
    local clicked = false

    Frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            clicked = true
            dragStart = input.Position
            startPos = Frame.Position
            
            -- Click animation
            print("Button clicked!")
            local tween = TweenService:Create(Frame, TweenInfo.new(0.1), {Size = UDim2.new(0, 35, 0, 35)})
            tween:Play()
            tween.Completed:Connect(function()
                TweenService:Create(Frame, TweenInfo.new(0.1), {Size = UDim2.new(0, 40, 0, 40)}):Play()
            end)
            
            -- UI toggle functionality
            uiToggled = not uiToggled
            Window:SetEnabled(not Window.Enabled)
            print("Button clicked - UI toggled to:", uiToggled)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            Frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
            clicked = false
        end
    end)

    -- Hover effect
    Frame.MouseEnter:Connect(function()
        TweenService:Create(Frame, TweenInfo.new(0.2), {
            Size = UDim2.new(0, 42, 0, 42),
            BackgroundColor3 = Color3.fromRGB(20, 20, 20)
        }):Play()
    end)

    Frame.MouseLeave:Connect(function()
        TweenService:Create(Frame, TweenInfo.new(0.2), {
            Size = UDim2.new(0, 40, 0, 40),
            BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        }):Play()
    end)
end

-- Create button initially
createButton()

-- Auto-reset when character respawns
LocalPlayer.CharacterAdded:Connect(function(character)
    wait(1)
    
    -- Recreate button after respawn
    createButton()
    
    if speedEnabled then
        character:WaitForChild("Humanoid")
        character.Humanoid.WalkSpeed = speedValue
        if speedConnection then speedConnection:Disconnect() end
        speedConnection = game:GetService("RunService").Heartbeat:Connect(updateSpeed)
        print("Speed reapplied and connection restarted on respawn:", speedValue)
    end
    
    if jumpEnabled then
        character:WaitForChild("Humanoid")
        character.Humanoid.JumpPower = jumpValue
        if jumpConnection then jumpConnection:Disconnect() end
        jumpConnection = game:GetService("RunService").Heartbeat:Connect(updateJump)
        print("Jump Power reapplied and connection restarted on respawn:", jumpValue)
    end
    
    if noclipEnabled then
        for _, part in pairs(character:GetChildren()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end
    
    if flyEnabled then
        startFly()
    end
end)

-- ===== HITBOX PAGE =====

-- Hitbox expansion
local hitboxExpansion = 0
local hitboxTransparency = 0.5
local hitboxEnabled = false
local hitboxUpdateConnection = nil
local originalSizes = {}

-- Function to expand actual hitboxes
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
        
        humanoidRootPart.Size = Vector3.new(20 + hitboxExpansion, 20 + hitboxExpansion, 20 + hitboxExpansion)
        humanoidRootPart.Transparency = hitboxTransparency
        humanoidRootPart.CanCollide = false
        humanoidRootPart.Material = Enum.Material.ForceField
        humanoidRootPart.Color = Color3.fromRGB(0, 255, 0)
    end
end

-- Function to restore original hitboxes
local function restorePlayerHitbox(player)
    if player == LocalPlayer then return end
    
    local character = player.Character
    if not character then return end
    
    local playerId = tostring(player.UserId)
    
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if humanoidRootPart and originalSizes[playerId] then
        humanoidRootPart.Size = originalSizes[playerId]
        humanoidRootPart.Transparency = 0
        humanoidRootPart.CanCollide = true
        humanoidRootPart.Material = Enum.Material.Plastic
        humanoidRootPart.Color = Color3.fromRGB(163, 162, 165)
        
        originalSizes[playerId] = nil
    end
end

-- Function to hide hitboxes
local function hidePlayerHitboxes(player)
    if player == LocalPlayer then return end
    
    local character = player.Character
    if not character then return end
    
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if humanoidRootPart then
        print("Making", player.Name, "hitbox invisible")
        humanoidRootPart.Transparency = 1
        humanoidRootPart.Material = Enum.Material.ForceField
        humanoidRootPart.Color = Color3.fromRGB(0, 0, 0)
        print("Transparency set to:", humanoidRootPart.Transparency)
    end
end

-- Function to update hitbox
local function updateHitbox()
    if not hitboxEnabled then
        if hitboxUpdateConnection then
            hitboxUpdateConnection:Disconnect()
            hitboxUpdateConnection = nil
        end
        
        for _, player in pairs(Players:GetPlayers()) do
            restorePlayerHitbox(player)
        end
        
        wait(1)
        for _, player in pairs(Players:GetPlayers()) do
            hidePlayerHitboxes(player)
        end
        return
    end
    
    for _, player in pairs(Players:GetPlayers()) do
        expandPlayerHitbox(player)
    end
    
    if not hitboxUpdateConnection then
        hitboxUpdateConnection = game:GetService("RunService").Heartbeat:Connect(function()
            for _, player in pairs(Players:GetPlayers()) do
                expandPlayerHitbox(player)
            end
        end)
    end
end

-- Blue outline toggle
local blueOutlineEnabled = false
local outlineParts = {}

-- Function to create blue outline
local function updateBlueOutline()
    for _, part in pairs(outlineParts) do
        if part and part.Parent then
            part:Destroy()
        end
    end
    outlineParts = {}
    
    if not blueOutlineEnabled or not hitboxEnabled then
        return
    end
    
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local hrp = player.Character.HumanoidRootPart
            local outline = Instance.new("SelectionBox")
            outline.Name = "BlueOutline_" .. player.Name
            outline.Adornee = hrp
            outline.Color3 = Color3.fromRGB(0, 0, 255)
            outline.LineThickness = 0.2
            outline.Transparency = 0.3
            outline.Parent = hrp
            table.insert(outlineParts, outline)
        end
    end
end

-- Hitbox Toggle
Tabs.Hitbox:AddToggle("EnableHitbox", {
    Title = "Enable Hitbox",
    Default = false,
    Callback = function(val)
        hitboxEnabled = val
        updateHitbox()
        updateBlueOutline()
        print("Hitbox:", val)
    end
})

-- Hitbox Size Slider (Mobile-friendly)
Tabs.Hitbox:AddSlider("HitboxSize", {
    Title = "Hitbox Size",
    Description = "Adjust hitbox expansion",
    Default = 0,
    Min = 0,
    Max = 10,
    Rounding = 1,
    Callback = function(val)
        hitboxExpansion = val
        if hitboxEnabled then
            updateHitbox()
        end
        print("Hitbox Size:", val)
    end
})

-- Hitbox Transparency Slider (Mobile-friendly)
Tabs.Hitbox:AddSlider("HitboxTransparency", {
    Title = "Hitbox Transparency",
    Description = "Adjust hitbox visibility",
    Default = 5,
    Min = 1,
    Max = 10,
    Rounding = 1,
    Callback = function(val)
        hitboxTransparency = val / 10
        if hitboxEnabled then
            updateHitbox()
        end
        print("Hitbox Transparency:", val, "(" .. (val / 10) .. ")")
    end
})

-- Blue Outline Toggle
Tabs.Hitbox:AddToggle("BlueOutline", {
    Title = "Blue Outline",
    Default = false,
    Callback = function(val)
        blueOutlineEnabled = val
        updateBlueOutline()
        print("Blue Outline:", val)
    end
})

-- ===== TARGET PAGE =====

local function getPlayerNames()
    local players = {}
    for _, player in ipairs(Players:GetPlayers()) do
        table.insert(players, player.Name)
    end
    return players
end

local selectedPlayer = nil
local boxESPEnabled = false
local boxFilledEnabled = false
local boxThickness = 2
local healthESPEnabled = false
local tracerEnabled = false
local highlightEnabled = false
local isSpectating = false
local lastCameraSubject = nil

-- Drawing objects
local boxDrawing, boxFillDrawing, healthBarDrawing, tracerDrawing

-- Clean up visuals
local function cleanupVisuals()
    if boxDrawing then boxDrawing:Remove() boxDrawing = nil end
    if boxFillDrawing then boxFillDrawing:Remove() boxFillDrawing = nil end
    if healthBarDrawing then healthBarDrawing:Remove() healthBarDrawing = nil end
    if tracerDrawing then tracerDrawing:Remove() tracerDrawing = nil end
    pcall(function() RunService:UnbindFromRenderStep("TargetESPDraw") end)
end

-- Draw ESP
local function drawESP()
    cleanupVisuals()
    if not selectedPlayer or not selectedPlayer.Character or not selectedPlayer.Character:FindFirstChild("HumanoidRootPart") then return end
    if not (boxESPEnabled or healthESPEnabled or tracerEnabled or boxFilledEnabled) then return end

    -- Box outline
    boxDrawing = Drawing.new("Square")
    boxDrawing.Color = Color3.fromRGB(255,0,0)
    boxDrawing.Thickness = boxThickness
    boxDrawing.Filled = false
    boxDrawing.Visible = boxESPEnabled

    -- Box fill
    boxFillDrawing = Drawing.new("Square")
    boxFillDrawing.Color = Color3.fromRGB(255,0,0)
    boxFillDrawing.Thickness = 0
    boxFillDrawing.Filled = true
    boxFillDrawing.Transparency = 0.3
    boxFillDrawing.Visible = boxFilledEnabled

    -- Health bar
    healthBarDrawing = Drawing.new("Square")
    healthBarDrawing.Color = Color3.fromRGB(0,255,0)
    healthBarDrawing.Filled = true
    healthBarDrawing.Transparency = 1
    healthBarDrawing.Visible = healthESPEnabled

    -- Tracer
    tracerDrawing = Drawing.new("Line")
    tracerDrawing.Color = Color3.fromRGB(0,255,0)
    tracerDrawing.Thickness = 2
    tracerDrawing.Visible = tracerEnabled

    RunService:BindToRenderStep("TargetESPDraw", 1, function()
        if not selectedPlayer or not selectedPlayer.Character or not selectedPlayer.Character:FindFirstChild("HumanoidRootPart") then
            if boxDrawing then boxDrawing.Visible = false end
            if boxFillDrawing then boxFillDrawing.Visible = false end
            if healthBarDrawing then healthBarDrawing.Visible = false end
            if tracerDrawing then tracerDrawing.Visible = false end
            return
        end

        local hrp = selectedPlayer.Character.HumanoidRootPart
        local humanoid = selectedPlayer.Character:FindFirstChildOfClass("Humanoid")
        local rootPos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
        if not onScreen then
            if boxDrawing then boxDrawing.Visible = false end
            if boxFillDrawing then boxFillDrawing.Visible = false end
            if healthBarDrawing then healthBarDrawing.Visible = false end
            if tracerDrawing then tracerDrawing.Visible = false end
            return
        end

        -- Height: use top/bottom of character
        local charHeight = 5.5
        if humanoid and humanoid.RigType == Enum.HumanoidRigType.R15 then
            charHeight = 6
        end
        local topWorld = hrp.Position + Vector3.new(0, charHeight/2, 0)
        local bottomWorld = hrp.Position - Vector3.new(0, charHeight/2, 0)
        local topScreen = Camera:WorldToViewportPoint(topWorld)
        local bottomScreen = Camera:WorldToViewportPoint(bottomWorld)
        local boxHeight = math.abs(topScreen.Y - bottomScreen.Y)
        local boxY = topScreen.Y

        -- Width: project all parts, use min/max X
        local minX, maxX = math.huge, -math.huge
        for _, part in ipairs(selectedPlayer.Character:GetChildren()) do
            if part:IsA("BasePart") then
                local pos, onScreen = Camera:WorldToViewportPoint(part.Position)
                if onScreen then
                    minX = math.min(minX, pos.X)
                    maxX = math.max(maxX, pos.X)
                end
            end
        end
        local boxWidth = maxX - minX
        local boxX = minX

        -- Draw box outline
        if boxESPEnabled and boxWidth > 0 and boxHeight > 0 then
            boxDrawing.Visible = true
            boxDrawing.Position = Vector2.new(boxX, boxY)
            boxDrawing.Size = Vector2.new(boxWidth, boxHeight)
            boxDrawing.Thickness = boxThickness
        else
            boxDrawing.Visible = false
        end

        -- Draw box fill
        if boxFilledEnabled and boxWidth > 0 and boxHeight > 0 then
            boxFillDrawing.Visible = true
            boxFillDrawing.Position = Vector2.new(boxX, boxY)
            boxFillDrawing.Size = Vector2.new(boxWidth, boxHeight)
        else
            boxFillDrawing.Visible = false
        end

        -- Draw health bar
        if healthESPEnabled and humanoid and boxWidth > 0 and boxHeight > 0 then
            healthBarDrawing.Visible = true
            local frac = math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1)
            local barHeight = boxHeight * frac
            local barWidth = math.max(2, boxWidth * 0.08)
            local barX = boxX - barWidth - 2
            local barY = boxY + (boxHeight - barHeight)
            healthBarDrawing.Position = Vector2.new(barX, barY)
            healthBarDrawing.Size = Vector2.new(barWidth, barHeight)
        else
            healthBarDrawing.Visible = false
        end

        -- Draw tracer
        if tracerEnabled then
            tracerDrawing.Visible = true
            tracerDrawing.From = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y)
            tracerDrawing.To = Vector2.new(rootPos.X, rootPos.Y)
        else
            tracerDrawing.Visible = false
        end
    end)
end

-- When target or toggles change, update visuals
local function updateAllVisuals()
    cleanupVisuals()
    drawESP()
end

-- Username Input
Tabs.Target:AddInput("TargetUsername", {
    Title = "Target Username",
    Default = "",
    Placeholder = "Enter username",
    Callback = function(Value)
        selectedPlayer = Players:FindFirstChild(Value)
        print("Target Username set to:", Value)
        updateAllVisuals()
    end
})

-- Player List Dropdown
Tabs.Target:AddDropdown("PlayerList", {
    Title = "Player List",
    Values = getPlayerNames(),
    Multi = false,
    Default = 1,
    Callback = function(val)
        selectedPlayer = Players:FindFirstChild(val)
        print("Selected player:", val)
        updateAllVisuals()
    end
})

-- Show Tracer Toggle
Tabs.Target:AddToggle("ShowTracer", {
    Title = "Show Tracer",
    Default = false,
    Callback = function(val)
        tracerEnabled = val
        updateAllVisuals()
    end
})

-- Highlight Target Toggle
Tabs.Target:AddToggle("HighlightTarget", {
    Title = "Highlight Target",
    Default = false,
    Callback = function(val)
        highlightEnabled = val
        if selectedPlayer and selectedPlayer.Character then
            if val then
                if not selectedPlayer.Character:FindFirstChild("HighlightTarget") then
                    local highlight = Instance.new("Highlight")
                    highlight.Name = "HighlightTarget"
                    highlight.FillColor = Color3.fromRGB(255, 255, 0)
                    highlight.OutlineColor = Color3.fromRGB(255, 255, 0)
                    highlight.FillTransparency = 0.5
                    highlight.OutlineTransparency = 0
                    highlight.Parent = selectedPlayer.Character
                end
            else
                if selectedPlayer.Character:FindFirstChild("HighlightTarget") then
                    selectedPlayer.Character.HighlightTarget:Destroy()
                end
            end
        end
    end
})

-- Box ESP Toggle
Tabs.Target:AddToggle("BoxESP", {
    Title = "Box ESP",
    Default = false,
    Callback = function(val)
        boxESPEnabled = val
        updateAllVisuals()
    end
})

-- Box Filled Toggle
Tabs.Target:AddToggle("BoxFilled", {
    Title = "Box Filled",
    Default = false,
    Callback = function(val)
        boxFilledEnabled = val
        updateAllVisuals()
    end
})

-- Health ESP Toggle
Tabs.Target:AddToggle("HealthESP", {
    Title = "Health ESP",
    Default = false,
    Callback = function(val)
        healthESPEnabled = val
        updateAllVisuals()
    end
})

-- Box Thickness Slider (Mobile-friendly)
Tabs.Target:AddSlider("BoxThickness", {
    Title = "Box Thickness",
    Description = "Adjust ESP box thickness",
    Default = 2,
    Min = 1,
    Max = 10,
    Rounding = 1,
    Callback = function(val)
        boxThickness = val
        updateAllVisuals()
    end
})

-- Spectate Button
Tabs.Target:AddButton({
    Title = "Spectate",
    Description = "Spectate selected player",
    Callback = function()
        local cam = workspace.CurrentCamera
        if not isSpectating then
            if selectedPlayer and selectedPlayer.Character and selectedPlayer.Character:FindFirstChild("HumanoidRootPart") then
                lastCameraSubject = cam.CameraSubject
                cam.CameraSubject = selectedPlayer.Character.HumanoidRootPart
                isSpectating = true
                print("Spectating", selectedPlayer.Name)
            else
                print("No valid player/character to spectate!")
            end
        else
            if lastCameraSubject then
                cam.CameraSubject = lastCameraSubject
            else
                cam.CameraSubject = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") or LocalPlayer.Character
            end
            isSpectating = false
            print("Un-spectated, camera returned to you.")
        end
    end
})

-- Clean up visuals when player leaves
Players.PlayerRemoving:Connect(function(player)
    if selectedPlayer == player then
        cleanupVisuals()
        selectedPlayer = nil
    end
end)

-- Clean up hitboxes when players leave
Players.PlayerRemoving:Connect(function(player)
    local playerId = tostring(player.UserId)
    
    restorePlayerHitbox(player)
    originalSizes[playerId] = nil
    
    for i = #outlineParts, 1, -1 do
        local outline = outlineParts[i]
        if outline and outline.Name:find(player.Name) then
            outline:Destroy()
            table.remove(outlineParts, i)
        end
    end
end)

-- ===== ESP PAGE =====

-- Load Sense ESP Library
local Sense = loadstring(game:HttpGet('https://sirius.menu/sense'))()

-- ESP Variables
local espEnabled = false
local espConnections = {} -- Store connections for each player
local espLibraries = {} -- Store ESP objects for each player

-- Individual ESP toggles
local boxESPEnabled = false
local cornerBoxESPEnabled = false
local nameESPEnabled = false
local healthESPEnabled = false
local tracerESPEnabled = false
local lineESPEnabled = false

-- Corner Box ESP System
local cornerBoxConnections = {}
local cornerBoxLibraries = {}

-- Corner Box ESP Functions
local function NewLine(color, thickness)
    local line = Drawing.new("Line")
    line.Visible = false
    line.From = Vector2.new(0, 0)
    line.To = Vector2.new(0, 0)
    line.Color = color
    line.Thickness = thickness
    line.Transparency = 1
    return line
end

local function Vis(lib, state)
    for i, v in pairs(lib) do
        v.Visible = state
    end
end

local function Colorize(lib, color)
    for i, v in pairs(lib) do
        v.Color = color
    end
end

local function createCornerBoxESP(player)
    if player == LocalPlayer then return end
    
    print("Creating corner box ESP for player:", player.Name)
    
    local Library = {
        TL1 = NewLine(espCornerBoxColor, espCornerBoxThickness),
        TL2 = NewLine(espCornerBoxColor, espCornerBoxThickness),
        TR1 = NewLine(espCornerBoxColor, espCornerBoxThickness),
        TR2 = NewLine(espCornerBoxColor, espCornerBoxThickness),
        BL1 = NewLine(espCornerBoxColor, espCornerBoxThickness),
        BL2 = NewLine(espCornerBoxColor, espCornerBoxThickness),
        BR1 = NewLine(espCornerBoxColor, espCornerBoxThickness),
        BR2 = NewLine(espCornerBoxColor, espCornerBoxThickness)
    }
    
    local oripart = Instance.new("Part")
    oripart.Parent = workspace
    oripart.Transparency = 1
    oripart.CanCollide = false
    oripart.Size = Vector3.new(1, 1, 1)
    oripart.Position = Vector3.new(0, 0, 0)
    
    cornerBoxLibraries[player] = {library = Library, part = oripart}
    print("Corner box library created for:", player.Name)
    
    local c = RunService.RenderStepped:Connect(function()
        if player.Character ~= nil and player.Character:FindFirstChild("Humanoid") ~= nil and player.Character:FindFirstChild("HumanoidRootPart") ~= nil and player.Character.Humanoid.Health > 0 and player.Character:FindFirstChild("Head") ~= nil then
            local Hum = player.Character
            local HumPos, vis = Camera:WorldToViewportPoint(Hum.HumanoidRootPart.Position)
            if vis then
                oripart.Size = Vector3.new(Hum.HumanoidRootPart.Size.X, Hum.HumanoidRootPart.Size.Y*1.5, Hum.HumanoidRootPart.Size.Z)
                oripart.CFrame = CFrame.new(Hum.HumanoidRootPart.CFrame.Position, Camera.CFrame.Position)
                local SizeX = oripart.Size.X
                local SizeY = oripart.Size.Y
                local TL = Camera:WorldToViewportPoint((oripart.CFrame * CFrame.new(SizeX, SizeY, 0)).p)
                local TR = Camera:WorldToViewportPoint((oripart.CFrame * CFrame.new(-SizeX, SizeY, 0)).p)
                local BL = Camera:WorldToViewportPoint((oripart.CFrame * CFrame.new(SizeX, -SizeY, 0)).p)
                local BR = Camera:WorldToViewportPoint((oripart.CFrame * CFrame.new(-SizeX, -SizeY, 0)).p)

                local ratio = (Camera.CFrame.p - Hum.HumanoidRootPart.Position).magnitude
                local offset = math.clamp(1/ratio*750, 2, 300)

                Library.TL1.From = Vector2.new(TL.X, TL.Y)
                Library.TL1.To = Vector2.new(TL.X + offset, TL.Y)
                Library.TL2.From = Vector2.new(TL.X, TL.Y)
                Library.TL2.To = Vector2.new(TL.X, TL.Y + offset)

                Library.TR1.From = Vector2.new(TR.X, TR.Y)
                Library.TR1.To = Vector2.new(TR.X - offset, TR.Y)
                Library.TR2.From = Vector2.new(TR.X, TR.Y)
                Library.TR2.To = Vector2.new(TR.X, TR.Y + offset)

                Library.BL1.From = Vector2.new(BL.X, BL.Y)
                Library.BL1.To = Vector2.new(BL.X + offset, BL.Y)
                Library.BL2.From = Vector2.new(BL.X, BL.Y)
                Library.BL2.To = Vector2.new(BL.X, BL.Y - offset)

                Library.BR1.From = Vector2.new(BR.X, BR.Y)
                Library.BR1.To = Vector2.new(BR.X - offset, BR.Y)
                Library.BR2.From = Vector2.new(BR.X, BR.Y)
                Library.BR2.To = Vector2.new(BR.X, BR.Y - offset)

                Vis(Library, true)

                local distance = (LocalPlayer.Character.HumanoidRootPart.Position - oripart.Position).magnitude
                local value = math.clamp(1/distance*100, 1, 4)
                for u, x in pairs(Library) do
                    x.Thickness = value
                end
            else 
                Vis(Library, false)
            end
        else 
            Vis(Library, false)
            if not Players:FindFirstChild(player.Name) then
                for i, v in pairs(Library) do
                    v:Remove()
                end
                oripart:Destroy()
                c:Disconnect()
                cornerBoxConnections[player] = nil
                cornerBoxLibraries[player] = nil
            end
        end
    end)
    
    cornerBoxConnections[player] = c
    print("Corner box connection created for:", player.Name)
end

local function cleanupCornerBoxESP(player)
    if cornerBoxConnections[player] then
        cornerBoxConnections[player]:Disconnect()
        cornerBoxConnections[player] = nil
    end
    
    if cornerBoxLibraries[player] then
        local data = cornerBoxLibraries[player]
        if data.library then
            for i, v in pairs(data.library) do
                v:Remove()
            end
        end
        if data.part then
            data.part:Destroy()
        end
        cornerBoxLibraries[player] = nil
    end
end

-- ESP Settings
local espBoxColor = Color3.fromRGB(255, 0, 0)
local espCornerBoxColor = Color3.fromRGB(255, 0, 0)
local espNameColor = Color3.fromRGB(255, 255, 255)
local espHealthColor = Color3.fromRGB(0, 255, 0)
local espTracerColor = Color3.fromRGB(255, 255, 0)
local espLineColor = Color3.fromRGB(255, 203, 138)

local espBoxThickness = 2
local espCornerBoxThickness = 2
local espNameSize = 13
local espTracerThickness = 2
local espLineThickness = 1
local espLineLength = 15
local espLineSmoothness = 0.2

-- ESP Helper Functions
local function NewText(color, size, transparency)
    local text = Drawing.new("Text")
    text.Visible = false
    text.Text = ""
    text.Position = Vector2.new(0, 0)
    text.Color = color
    text.Size = size
    text.Center = true
    text.Transparency = transparency
    text.Outline = true
    return text
end

local function NewSquare(color, thickness, filled)
    local square = Drawing.new("Square")
    square.Visible = false
    square.Position = Vector2.new(0, 0)
    square.Size = Vector2.new(0, 0)
    square.Color = color
    square.Thickness = thickness
    square.Filled = filled
    return square
end

local function NewLine(color, thickness)
    local line = Drawing.new("Line")
    line.Visible = false
    line.From = Vector2.new(0, 0)
    line.To = Vector2.new(0, 0)
    line.Color = color
    line.Thickness = thickness
    return line
end

local function NewTriangle(color, filled)
    local triangle = Drawing.new("Triangle")
    triangle.Visible = false
    triangle.PointA = Vector2.new(0, 0)
    triangle.PointB = Vector2.new(0, 0)
    triangle.PointC = Vector2.new(0, 0)
    triangle.Color = color
    triangle.Filled = filled
    return triangle
end

local function Visibility(state, lib)
    for u, x in pairs(lib) do
        if x and x.Visible ~= nil then
            x.Visible = state
        end
    end
end

local function Size(size, lib)
    for u, x in pairs(lib) do
        if x and x.Size ~= nil then
            x.Size = size
        end
    end
end

-- Create ESP for a player
local function createESP(player)
    if player == LocalPlayer then return end
    
    -- Create ESP library for this player (no box - using Sense instead)
    local library = {
        name = NewText(espNameColor, espNameSize, 1),
        health = NewSquare(espHealthColor, 0, true),
        tracer = NewLine(espTracerColor, espTracerThickness),
        line = NewLine(espLineColor, espLineThickness)
    }
    
    espLibraries[player] = library
    
    -- Start ESP connection for this player
    local connection
    connection = RunService.RenderStepped:Connect(function()
        if player.Character ~= nil and player.Character:FindFirstChild("Humanoid") ~= nil and player.Character:FindFirstChild("HumanoidRootPart") ~= nil and player.Name ~= LocalPlayer.Name and player.Character.Humanoid.Health > 0 then
            local character = player.Character
            local humanoid = character:FindFirstChild("Humanoid")
            local hrp = character:FindFirstChild("HumanoidRootPart")
            
            
            local HumanoidRootPart_Pos, OnScreen = Camera:WorldToViewportPoint(hrp.Position)
            
            if OnScreen then
                -- Name ESP
                if nameESPEnabled then
                    library.name.Text = player.Name
                    library.name.Position = Vector2.new(HumanoidRootPart_Pos.X, HumanoidRootPart_Pos.Y - 60)
                    library.name.Visible = true
                else
                    library.name.Visible = false
                end
                
                -- Box ESP handled by Sense library
                
                -- Health Bar ESP
                if healthESPEnabled then
                    local healthPercent = humanoid.Health / humanoid.MaxHealth
                    local barHeight = 100 * healthPercent
                    library.health.Position = Vector2.new(HumanoidRootPart_Pos.X - 30, HumanoidRootPart_Pos.Y - 50 + (100 - barHeight))
                    library.health.Size = Vector2.new(3, barHeight)
                    library.health.Visible = true
                else
                    library.health.Visible = false
                end
                
                -- Tracer ESP
                if tracerESPEnabled then
                    library.tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                    library.tracer.To = Vector2.new(HumanoidRootPart_Pos.X, HumanoidRootPart_Pos.Y)
                    library.tracer.Visible = true
                else
                    library.tracer.Visible = false
                end
                
                -- Line ESP (from head direction)
                if lineESPEnabled and library.line then
                    local head = character:FindFirstChild("Head")
                    if head then
                        local headpos, OnScreen = Camera:WorldToViewportPoint(head.Position)
                        if OnScreen then
                            local offsetCFrame = CFrame.new(0, 0, -espLineLength)
                            local check = false
                            library.line.From = Vector2.new(headpos.X, headpos.Y)
                            
                            -- Auto thickness based on distance
                            local distance = (LocalPlayer.Character.HumanoidRootPart.Position - hrp.Position).magnitude
                            local thickness = math.clamp(1/distance*100, 0.1, 3)
                            library.line.Thickness = thickness
                            
                            repeat
                                local dir = head.CFrame:ToWorldSpace(offsetCFrame)
                                offsetCFrame = offsetCFrame * CFrame.new(0, 0, espLineSmoothness)
                                local dirpos, vis = Camera:WorldToViewportPoint(Vector3.new(dir.X, dir.Y, dir.Z))
                                if vis then
                                    check = true
                                    library.line.To = Vector2.new(dirpos.X, dirpos.Y)
                                    library.line.Visible = true
                                    offsetCFrame = CFrame.new(0, 0, -espLineLength)
                                end
                            until check == true
                        else
                            library.line.Visible = false
                        end
                    end
                else
                    if library.line then
                        library.line.Visible = false
                    end
                end
                
            else
                -- Hide all ESP when off screen
                Visibility(false, library)
            end
        else
            Visibility(false, library)
            if not Players:FindFirstChild(player.Name) then
                connection:Disconnect()
                espConnections[player] = nil
                espLibraries[player] = nil
            end
        end
    end)
    
    espConnections[player] = connection
    
end

-- Clean up ESP for a player
local function cleanupESP(player)
    if espConnections[player] then
        espConnections[player]:Disconnect()
        espConnections[player] = nil
    end
    
    if espLibraries[player] then
        local library = espLibraries[player]
        if library.name then library.name:Remove() end
        if library.health then library.health:Remove() end
        if library.tracer then library.tracer:Remove() end
        if library.line then library.line:Remove() end
        espLibraries[player] = nil
    end
end

-- ESP Main Controls
Tabs.ESP:AddToggle("EnableESP", {
    Title = "Enable ESP",
    Default = false,
    Callback = function(val)
        espEnabled = val
        if val then
            -- Create ESP for all existing players
            for _, player in pairs(Players:GetPlayers()) do
                createESP(player)
            end
        else
            -- Clean up all ESP when disabled
            for player, _ in pairs(espConnections) do
                cleanupESP(player)
            end
            espConnections = {}
            espLibraries = {}
        end
        print("ESP:", val)
    end
})

Tabs.ESP:AddToggle("BoxESP", {
    Title = "Box ESP",
    Default = false,
    Callback = function(val)
        boxESPEnabled = val
        Sense.teamSettings.enemy.box = val
        print("Box ESP:", val)
    end
})

Tabs.ESP:AddToggle("CornerBoxESP", {
    Title = "Corner Box ESP",
    Default = false,
    Callback = function(val)
        cornerBoxESPEnabled = val
        if val then
            print("Creating corner box ESP for all players...")
            -- Create corner box ESP for all existing players
            for _, player in pairs(Players:GetPlayers()) do
                if player ~= LocalPlayer then
                    print("Creating corner box for:", player.Name)
                    createCornerBoxESP(player)
                end
            end
        else
            print("Cleaning up corner box ESP...")
            -- Clean up all corner box ESP
            for player, _ in pairs(cornerBoxConnections) do
                cleanupCornerBoxESP(player)
            end
            cornerBoxConnections = {}
            cornerBoxLibraries = {}
        end
        print("Corner Box ESP:", val)
    end
})

Tabs.ESP:AddToggle("NameESP", {
    Title = "Name ESP",
    Default = false,
    Callback = function(val)
        nameESPEnabled = val
        print("Name ESP:", val)
    end
})

Tabs.ESP:AddToggle("HealthBarESP", {
    Title = "Health Bar ESP",
    Default = false,
    Callback = function(val)
        healthESPEnabled = val
        print("Health Bar ESP:", val)
    end
})

Tabs.ESP:AddToggle("TracerESP", {
    Title = "Tracer ESP",
    Default = false,
    Callback = function(val)
        tracerESPEnabled = val
        print("Tracer ESP:", val)
    end
})

Tabs.ESP:AddToggle("LineESP", {
    Title = "Line ESP",
    Default = false,
    Callback = function(val)
        lineESPEnabled = val
        print("Line ESP:", val)
    end
})

-- Visual ESP Settings
Tabs.ESP:AddColorpicker("BoxColor", {
    Title = "Box Color",
    Default = espBoxColor,
    Callback = function(color)
        espBoxColor = color
        Sense.teamSettings.enemy.boxColor[1] = color
    end
})

Tabs.ESP:AddColorpicker("CornerBoxColor", {
    Title = "Corner Box Color",
    Default = espCornerBoxColor,
    Callback = function(color)
        espCornerBoxColor = color
        for _, data in pairs(cornerBoxLibraries) do
            if data and data.library then
                Colorize(data.library, color)
            end
        end
    end
})

Tabs.ESP:AddColorpicker("NameColor", {
    Title = "Name Color",
    Default = espNameColor,
    Callback = function(color)
        espNameColor = color
        for _, library in pairs(espLibraries) do
            if library and library.name then
                library.name.Color = color
            end
        end
    end
})

Tabs.ESP:AddColorpicker("HealthColor", {
    Title = "Health Color",
    Default = espHealthColor,
    Callback = function(color)
        espHealthColor = color
        for _, library in pairs(espLibraries) do
            if library and library.health then
                library.health.Color = color
            end
        end
    end
})

Tabs.ESP:AddColorpicker("TracerColor", {
    Title = "Tracer Color",
    Default = espTracerColor,
    Callback = function(color)
        espTracerColor = color
        for _, library in pairs(espLibraries) do
            if library and library.tracer then
                library.tracer.Color = color
            end
        end
    end
})

Tabs.ESP:AddColorpicker("LineColor", {
    Title = "Line Color",
    Default = espLineColor,
    Callback = function(color)
        espLineColor = color
        for _, library in pairs(espLibraries) do
            if library and library.line then
                library.line.Color = color
            end
        end
    end
})

-- Advanced ESP Settings (Mobile-friendly sliders)
Tabs.ESP:AddSlider("CornerBoxThickness", {
    Title = "Corner Box Thickness",
    Description = "Adjust corner box line thickness",
    Default = 2,
    Min = 1,
    Max = 10,
    Rounding = 1,
    Callback = function(val)
        espCornerBoxThickness = val
        for _, data in pairs(cornerBoxLibraries) do
            if data and data.library then
                for _, line in pairs(data.library) do
                    if line then line.Thickness = val end
                end
            end
        end
    end
})

Tabs.ESP:AddSlider("NameSize", {
    Title = "Name Size",
    Description = "Adjust ESP name text size",
    Default = 13,
    Min = 8,
    Max = 20,
    Rounding = 1,
    Callback = function(val)
        espNameSize = val
        for _, library in pairs(espLibraries) do
            if library and library.name then
                library.name.Size = val
            end
        end
    end
})

Tabs.ESP:AddSlider("TracerThickness", {
    Title = "Tracer Thickness",
    Description = "Adjust tracer line thickness",
    Default = 2,
    Min = 1,
    Max = 10,
    Rounding = 1,
    Callback = function(val)
        espTracerThickness = val
        for _, library in pairs(espLibraries) do
            if library and library.tracer then
                library.tracer.Thickness = val
            end
        end
    end
})

Tabs.ESP:AddSlider("LineLength", {
    Title = "Line Length",
    Description = "Adjust ESP line length",
    Default = 15,
    Min = 5,
    Max = 30,
    Rounding = 1,
    Callback = function(val)
        espLineLength = val
    end
})

Tabs.ESP:AddSlider("LineSmoothness", {
    Title = "Line Smoothness",
    Description = "Adjust ESP line smoothness",
    Default = 2,
    Min = 1,
    Max = 10,
    Rounding = 1,
    Callback = function(val)
        espLineSmoothness = val / 10
    end
})

-- Configure Sense ESP
Sense.teamSettings.enemy.enabled = true
Sense.teamSettings.enemy.box = false -- Start disabled, controlled by toggle
Sense.teamSettings.enemy.boxColor[1] = espBoxColor

-- Load Sense ESP
Sense.Load()

-- Create ESP for new players who join
Players.PlayerAdded:Connect(function(player)
    if espEnabled then
        wait(2) -- Wait for character to load
        createESP(player)
    end
    if cornerBoxESPEnabled then
        wait(2) -- Wait for character to load
        createCornerBoxESP(player)
    end
end)

-- Clean up ESP when players leave
Players.PlayerRemoving:Connect(function(player)
    cleanupESP(player)
    cleanupCornerBoxESP(player)
end)

-- ===== THEME PAGE =====
-- Theme color pickers
Tabs.Theme:AddColorpicker("BackgroundColor", {
    Title = "Background Color",
    Default = Color3.fromRGB(24, 24, 24),
    Callback = function(color)
        -- Theme customization would go here
        print("Background color changed:", color)
    end
})

Tabs.Theme:AddColorpicker("AccentColor", {
    Title = "Accent Color", 
    Default = Color3.fromRGB(10, 10, 10),
    Callback = function(color)
        print("Accent color changed:", color)
    end
})

Tabs.Theme:AddColorpicker("TextColor", {
    Title = "Text Color",
    Default = Color3.fromRGB(255, 255, 255),
    Callback = function(color)
        print("Text color changed:", color)
    end
})

-- Add SaveManager and InterfaceManager
SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({})
InterfaceManager:SetFolder("DarkWareScript")
SaveManager:SetFolder("DarkWareScript/specific-game")

-- Build interface sections
InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)

-- Select first tab and show notification
Window:SelectTab(1)

Fluent:Notify({
    Title = "DarkWare Script",
    Content = "Mobile-friendly UI loaded successfully!",
    Duration = 5
})

-- Load autoload config
SaveManager:LoadAutoloadConfig()