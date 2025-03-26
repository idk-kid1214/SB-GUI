-- Integrated GUI Script with Toggleable Anti-Knockback, Sprint, and Auto Slap

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Automatically clone this script to StarterGui so it's always present.
task.spawn(function()
    local clone = script:Clone()
    clone.Parent = StarterGui
end)

-- Wait for character and HRP
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")

-- Configuration
local DETECTION_RADIUS = 15
local COOLDOWN_TIME = 0.6
local AUTO_SLAP_ENABLED = false
local ANTI_KNOCKBACK_ENABLED = false
local SPRINT_ENABLED = false
local canSlap = true
local equipped = false
local currentGlove = nil

--------------------------------------------
-- Create GUI
local screenGui = Instance.new("ScreenGui")
screenGui.Parent = PlayerGui

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 200, 0, 400)
frame.Position = UDim2.new(0.8, 0, 0.05, 0) -- Moved up so no button is cut off
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
frame.Parent = screenGui

-- Helper function to create buttons
local function createButton(text, callback)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, -10, 0, 40)
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
        callback(button)
    end)
    return button
end

--------------------------------------------
-- Other Functions
local function toggleAutoFarm(button)
    AUTOFARM_ENABLED = not AUTOFARM_ENABLED
    button.BackgroundColor3 = AUTOFARM_ENABLED and Color3.fromRGB(50, 255, 50) or Color3.fromRGB(0, 0, 0)

    if AUTOFARM_ENABLED then
        task.spawn(function()
            while AUTOFARM_ENABLED do
                local players = Players:GetPlayers()
                if #players > 1 then
                    local target = players[math.random(1, #players)]
                    if target ~= LocalPlayer and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
                        local targetHRP = target.Character.HumanoidRootPart
                        local myHRP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                        local myGlove = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Tool")

                        if myHRP and targetHRP then
                            -- Calculate position 3.2 studs behind the target
                            local direction = (targetHRP.CFrame.LookVector * -3.2) -- Move backwards
                            local newPosition = targetHRP.Position + direction

                            -- Teleport behind the target
                            myHRP.Anchored = true
                            myHRP.CFrame = CFrame.new(newPosition, targetHRP.Position) -- Face target

                            -- Auto-slap after teleporting
                            if myGlove then
                                task.wait(0.1) -- Small delay to ensure position update
                                myGlove:Activate()
                                ReplicatedStorage.KSHit:FireServer(targetHRP)
                            end
                        end
                    end
                end
                task.wait(1) -- Wait 1 second before teleporting again
            end

            -- Unanchor when disabled
            local myHRP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if myHRP then
                myHRP.Anchored = false
            end
        end)
    end
end


-- Delete Cube of Death (one line)
local function deleteCubeOfDeath()
    local cube = game.Workspace.Arena.CubeOfDeathArea:FindFirstChild("the cube of death(i heard it kills)")
    if cube then cube:Destroy() end
end

-- Delete Death Barriers
local function deleteDeathBarriers()
    local barrierNames = {"AntiDefaultArena", "Antidream", "ArenaBarrier", "DEATHBARRIER", "DEATHBARRIER2", "dedBarrier"}
    for _, name in ipairs(barrierNames) do
        local barrier = game.Workspace:FindFirstChild(name)
        if barrier then barrier:Destroy() end
    end
end

-- Enable AntiVoid
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

-- Disable AntiVoid
local function disableAntiVoid()
    local island = game.Workspace.Arena:FindFirstChild("main island")
    if island then
        local antivoid = island:FindFirstChild("antivoid")
        if antivoid then antivoid:Destroy() end
    end
end

-- Toggleable Anti-Knockback Function
local function toggleAntiKnockback(button)
    ANTI_KNOCKBACK_ENABLED = not ANTI_KNOCKBACK_ENABLED
    button.BackgroundColor3 = ANTI_KNOCKBACK_ENABLED and Color3.fromRGB(50, 255, 50) or Color3.fromRGB(0, 0, 0)
    
    if not ANTI_KNOCKBACK_ENABLED then
        HumanoidRootPart.Anchored = false
    else
        task.spawn(function()
            while ANTI_KNOCKBACK_ENABLED do
                local playerChar = game.Workspace:FindFirstChild(LocalPlayer.Name)
                if playerChar then
                    local ragdolled = playerChar:FindFirstChild("Ragdolled")
                    if ragdolled then
                        HumanoidRootPart.Anchored = ragdolled.Value
                    end
                end
                task.wait(0.1)
            end
        end)
    end
end

-- Toggle Sprint Function
local function toggleSprint(button)
    SPRINT_ENABLED = not SPRINT_ENABLED
    button.BackgroundColor3 = SPRINT_ENABLED and Color3.fromRGB(50, 255, 50) or Color3.fromRGB(0, 0, 0)
    Humanoid.WalkSpeed = SPRINT_ENABLED and 50 or 16
end

--------------------------------------------
-- Auto-Slap Functions (from provided script)

local function getEquippedGlove()
    if Character then
        for _, tool in pairs(Character:GetChildren()) do
            if tool:IsA("Tool") then
                return tool -- Return whichever glove is held
            end
        end
    end
    return nil
end

local function slapPlayer(targetPlayer)
    if not canSlap or not equipped then return end
    local glove = getEquippedGlove()
    if not glove then return end -- Make sure the player is holding something
    glove:Activate() -- Activate the tool
    if _G.slaptrack then _G.slaptrack:Play() end
    local targetHRP = targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart")
    if targetHRP and ReplicatedStorage:FindFirstChild("KSHit") then
        ReplicatedStorage.KSHit:FireServer(targetHRP)
    end
    canSlap = false
    task.delay(COOLDOWN_TIME, function() canSlap = true end)
end

local function toggleAutoSlap(button)
    AUTO_SLAP_ENABLED = not AUTO_SLAP_ENABLED
    button.BackgroundColor3 = AUTO_SLAP_ENABLED and Color3.fromRGB(50, 255, 50) or Color3.fromRGB(0, 0, 0)
end

task.spawn(function()
    while true do
        if AUTO_SLAP_ENABLED and equipped and canSlap then
            local nearestPlayer = nil
            local closestDistance = DETECTION_RADIUS
            for _, player in pairs(Players:GetPlayers()) do
                if player ~= LocalPlayer and player.Character then
                    local distance = (player.Character.HumanoidRootPart.Position - HumanoidRootPart.Position).Magnitude
                    if distance < closestDistance then
                        closestDistance = distance
                        nearestPlayer = player
                    end
                end
            end
            if nearestPlayer then
                slapPlayer(nearestPlayer)
            end
        end
        RunService.Heartbeat:Wait()
    end
end)

--------------------------------------------
-- Tool Equip Monitoring for Auto-Slap
local function onToolEquipped(tool)
    equipped = true
    currentGlove = tool.Name
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

--------------------------------------------
-- Add Buttons to the GUI
createButton("Delete Cube of Death", deleteCubeOfDeath)
createButton("Delete Death Barriers", deleteDeathBarriers)
createButton("Enable AntiVoid", enableAntiVoid)
createButton("Disable AntiVoid", disableAntiVoid)
createButton("Toggle Anti-Knockback", toggleAntiKnockback)
createButton("Auto Slap", toggleAutoSlap)
createButton("Sprint", toggleSprint)
createButton("Toggle Autofarm", toggleAutoFarm)
local Players = game:GetService("Players")
local player = Players.LocalPlayer

local function onCharacterAdded(character)
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid.Died:Connect(function()
            player.CharacterAdded:Wait() -- Wait for the new character to spawn
            loadstring(game:HttpGet('https://raw.githubusercontent.com/idk-kid1214/SB-GUI/refs/heads/main/GUI.lua'))()
        end)
    end
end

if player.Character then
    onCharacterAdded(player.Character)
end

player.CharacterAdded:Connect(onCharacterAdded)
