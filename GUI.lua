-- Integrated GUI Script with All Features
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Wait for character and HRP
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")

-- Configuration for Auto-Slap (from your snippet)
local DETECTION_RADIUS = 15
local COOLDOWN_TIME = 0.6
local AUTO_SLAP_ENABLED = true
local canSlap = true
local equipped = false
local currentGlove = nil

--------------------------------------------
-- Create our custom GUI (not the original auto-slap GUI)
local screenGui = Instance.new("ScreenGui")
screenGui.Parent = PlayerGui

-- Move the frame up a bit so that all buttons are visible
local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 200, 0, 350)
frame.Position = UDim2.new(0.8, 0, 0.1, 0)
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
frame.Parent = screenGui

-- Helper function to create buttons within the frame
local function createButton(text, callback)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, -10, 0, 40)
    -- Calculate button Y position based on count of existing buttons (only count TextButtons)
    local count = 0
    for _, child in ipairs(frame:GetChildren()) do
        if child:IsA("TextButton") then
            count = count + 1
        end
    end
    button.Position = UDim2.new(0, 5, 0, 5 + count * 45)
    button.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.Text = text
    button.Font = Enum.Font.SourceSansBold
    button.TextSize = 20
    button.Parent = frame
    button.MouseButton1Click:Connect(function()
        callback()
        -- For toggle buttons (e.g. Auto Slap) change background color to a slight green hue if enabled.
        if text == "Auto Slap" then
            button.BackgroundColor3 = AUTO_SLAP_ENABLED and Color3.fromRGB(50,255,50) or Color3.fromRGB(0,0,0)
        end
    end)
    return button
end

--------------------------------------------
-- Other Functionality

-- 1. Delete Cube of Death (one line)
local function deleteCubeOfDeath()
    local cube = game.Workspace.Arena.CubeOfDeathArea:FindFirstChild("the cube of death(i heard it kills)")
    if cube then cube:Destroy() end
end

-- 2. Delete Death Barriers
local function deleteDeathBarriers()
    local barrierNames = {"AntiDefaultArena", "Antidream", "ArenaBarrier", "DEATHBARRIER", "DEATHBARRIER2", "dedBarrier"}
    for _, name in ipairs(barrierNames) do
        local barrier = game.Workspace:FindFirstChild(name)
        if barrier then barrier:Destroy() end
    end
end

-- 3. Enable AntiVoid: Clone main island grass, rename to antivoid, set size and transparency.
local function enableAntiVoid()
    local island = game.Workspace.Arena:FindFirstChild("main island")
    if island and not island:FindFirstChild("antivoid") then
        local grass = island:FindFirstChild("Grass")
        if grass then
            local clone = grass:Clone()
            clone.Name = "antivoid"
            clone.Parent = island
            clone.Size = Vector3.new(1.5, 2048, 2048)
            clone.Transparency = 1
        end
    end
end

-- 4. Disable AntiVoid
local function disableAntiVoid()
    local island = game.Workspace.Arena:FindFirstChild("main island")
    if island then
        local antivoid = island:FindFirstChild("antivoid")
        if antivoid then antivoid:Destroy() end
    end
end

-- 5. Toggle Anti-Knockback (Do not change this)
local function toggleAntiKnockback()
    local playerChar = game.Workspace:FindFirstChild(LocalPlayer.Name)
    if playerChar then
        local ragdolled = playerChar:FindFirstChild("Ragdolled")
        local rootPart = playerChar:FindFirstChild("HumanoidRootPart")
        if ragdolled and rootPart then
            task.spawn(function()
                while true do
                    if ragdolled.Value then
                        rootPart.Anchored = true
                    else
                        rootPart.Anchored = false
                    end
                    task.wait(0.1)
                end
            end)
        end
    end
end

--------------------------------------------
-- Auto-Slap Functions (exactly as in your provided script)

-- Function to get the currently equipped glove
local function getEquippedGlove()
    if Character then
        for _, tool in pairs(Character:GetChildren()) do
            if tool:IsA("Tool") then
                return tool -- Return whatever glove is being held
            end
        end
    end
    return nil
end

-- Function to slap a player
local function slapPlayer(targetPlayer)
    if not canSlap or not equipped then return end
    local glove = getEquippedGlove()
    if not glove then return end -- Ensure the player is holding something
    glove:Activate() -- Activate the tool
    if _G.slaptrack then
        _G.slaptrack:Play()
    end
    local targetHRP = targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart")
    if targetHRP and ReplicatedStorage:FindFirstChild("KSHit") then
        ReplicatedStorage.KSHit:FireServer(targetHRP)
    end
    -- Set cooldown
    canSlap = false
    task.delay(COOLDOWN_TIME, function()
        canSlap = true
    end)
end

-- Function to find the nearest valid player
local function findNearestValidPlayer()
    local closestPlayer = nil
    local closestDistance = DETECTION_RADIUS
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local playerCharacter = player.Character
            if playerCharacter and
               playerCharacter:FindFirstChild("HumanoidRootPart") and
               playerCharacter:FindFirstChild("Humanoid") and
               playerCharacter.Humanoid.Health > 0 then
                local distance = (playerCharacter.HumanoidRootPart.Position - HumanoidRootPart.Position).Magnitude
                if distance < closestDistance then
                    closestDistance = distance
                    closestPlayer = player
                end
            end
        end
    end
    return closestPlayer
end

-- Equip detection for Auto-Slap
local function onToolEquipped(tool)
    equipped = true
    currentGlove = tool.Name -- Store the name of the equipped glove
    print(currentGlove .. " equipped - Auto slap activated")
end

local function onToolUnequipped(tool)
    equipped = false
    currentGlove = nil
    print("Glove unequipped - Auto slap deactivated")
end

local function setupCharacter(char)
    Character = char
    if not Character then return end
    task.spawn(function()
        HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
    end)
    Character.ChildAdded:Connect(function(child)
        if child:IsA("Tool") then
            onToolEquipped(child)
        end
    end)
    Character.ChildRemoved:Connect(function(child)
        if child:IsA("Tool") then
            onToolUnequipped(child)
        end
    end)
    for _, tool in pairs(Character:GetChildren()) do
        if tool:IsA("Tool") then
            onToolEquipped(tool)
        end
    end
end

LocalPlayer.CharacterAdded:Connect(setupCharacter)
setupCharacter(Character)

-- Auto-Slap Loop using the provided code
task.spawn(function()
    while true do
        if AUTO_SLAP_ENABLED and equipped and canSlap then
            local nearestPlayer = findNearestValidPlayer()
            if nearestPlayer then
                slapPlayer(nearestPlayer)
            end
        end
        RunService.Heartbeat:Wait()
    end
end)

--------------------------------------------
-- Add Buttons to the GUI Frame
createButton("Delete Cube of Death", deleteCubeOfDeath)
createButton("Delete Death Barriers", deleteDeathBarriers)
createButton("Enable AntiVoid", enableAntiVoid)
createButton("Disable AntiVoid", disableAntiVoid)
createButton("Toggle Anti-Knockback", toggleAntiKnockback)
createButton("Auto Slap", function() 
    AUTO_SLAP_ENABLED = not AUTO_SLAP_ENABLED 
end)
