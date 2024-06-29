local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local camera = game.Workspace.CurrentCamera

-- GUI erstellen
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "TrackingGUI"
ScreenGui.Parent = player:WaitForChild("PlayerGui")

local ToggleButton = Instance.new("TextButton")
ToggleButton.Size = UDim2.new(0, 100, 0, 50)
ToggleButton.Position = UDim2.new(1, -110, 0, 10)
ToggleButton.Text = "Toggle Off"
ToggleButton.Parent = ScreenGui

local TargetBox = Instance.new("Frame")
TargetBox.Size = UDim2.new(0, 10, 0, 10) -- Kleine Box
TargetBox.BackgroundColor3 = Color3.new(1, 0, 0)
TargetBox.Visible = false
TargetBox.AnchorPoint = Vector2.new(0.5, 0.5)
TargetBox.Parent = ScreenGui

local ESPContainer = Instance.new("Folder")
ESPContainer.Name = "ESPContainer"
ESPContainer.Parent = ScreenGui

local trackingEnabled = false
local trackedPlayer = nil

local function toggleTracking()
    trackingEnabled = not trackingEnabled
    ToggleButton.Text = trackingEnabled and "Toggle On" or "Toggle Off"
    TargetBox.Visible = trackingEnabled
    if trackingEnabled then
        trackedPlayer = trackedPlayer or getNearestPlayer()
    else
        trackedPlayer = nil
    end
end

ToggleButton.MouseButton1Click:Connect(toggleTracking)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if input.KeyCode == Enum.KeyCode.T and not gameProcessed then
        toggleTracking()
    end
end)

local function createESP(player)
    local esp = Instance.new("BillboardGui")
    esp.Name = player.Name .. "_ESP"
    esp.Size = UDim2.new(0, 100, 0, 50)
    esp.StudsOffset = Vector3.new(0, 2, 0)
    esp.AlwaysOnTop = true
    
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Text = player.Name
    nameLabel.Size = UDim2.new(1, 0, 0.5, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.TextColor3 = Color3.new(1, 1, 1)
    nameLabel.TextStrokeTransparency = 0
    nameLabel.Parent = esp
    
    local healthLabel = Instance.new("TextLabel")
    healthLabel.Text = "Health: " .. math.floor(player.Character.Humanoid.Health)
    healthLabel.Size = UDim2.new(1, 0, 0.5, 0)
    healthLabel.Position = UDim2.new(0, 0, 0.5, 0)
    healthLabel.BackgroundTransparency = 1
    healthLabel.TextColor3 = Color3.new(1, 1, 1)
    healthLabel.TextStrokeTransparency = 0
    healthLabel.Parent = esp
    
    local espBox = Instance.new("BoxHandleAdornment")
    espBox.Name = player.Name .. "_ESPBox"
    espBox.Adornee = player.Character
    espBox.Size = player.Character:GetExtentsSize()
    espBox.Color3 = Color3.new(math.random(), math.random(), math.random())
    espBox.Transparency = 0.5
    espBox.ZIndex = 1
    espBox.AlwaysOnTop = true
    espBox.Parent = ESPContainer
    
    esp.Parent = ESPContainer
    
    return esp, espBox
end

local function updateESP(esp, espBox, player)
    local healthLabel = esp:FindFirstChildOfClass("TextLabel")
    if healthLabel then
        healthLabel.Text = "Health: " .. math.floor(player.Character.Humanoid.Health)
    end
    
    espBox.Size = player.Character:GetExtentsSize()
    espBox.Adornee = player.Character
end

local function getNearestPlayer()
    local nearestPlayer = nil
    local shortestDistance = math.huge

    for _, otherPlayer in pairs(Players:GetPlayers()) do
        if otherPlayer ~= player and otherPlayer.Character and otherPlayer.Character:FindFirstChild("HumanoidRootPart") then
            local distance = (otherPlayer.Character.HumanoidRootPart.Position - player.Character.HumanoidRootPart.Position).magnitude
            if distance < shortestDistance then
                shortestDistance = distance
                nearestPlayer = otherPlayer
            end
        end
    end

    return nearestPlayer
end

local function onCharacterAdded(character)
    character:WaitForChild("HumanoidRootPart")
    character:WaitForChild("Head")
    
    local esp, espBox = createESP(character.Parent)
    
    character.Parent.ChildAdded:Connect(function(child)
        if child:IsA("Humanoid") then
            local newEsp, newEspBox = createESP(character.Parent)
            esp:Destroy()
            espBox:Destroy()
            esp = newEsp
            espBox = newEspBox
        end
    end)
end

player.CharacterAdded:Connect(onCharacterAdded)
if player.Character then
    onCharacterAdded(player.Character)
end

RunService.RenderStepped:Connect(function()
    if not ScreenGui.Parent then
        ScreenGui.Parent = player:WaitForChild("PlayerGui")
    end
    
    if trackingEnabled and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
        if not trackedPlayer or not trackedPlayer.Character or not trackedPlayer.Character:FindFirstChild("HumanoidRootPart") then
            trackedPlayer = getNearestPlayer()
        end
        
        if trackedPlayer and trackedPlayer.Character and trackedPlayer.Character:FindFirstChild("HumanoidRootPart") then
            camera.CFrame = CFrame.new(camera.CFrame.Position, trackedPlayer.Character.HumanoidRootPart.Position)
            
            local screenPosition, onScreen = camera:WorldToScreenPoint(trackedPlayer.Character.HumanoidRootPart.Position)
            if onScreen then
                TargetBox.Position = UDim2.new(0, screenPosition.X, 0, screenPosition.Y)
                TargetBox.Visible = true
            else
                TargetBox.Visible = false
            end
        else
            TargetBox.Visible = false
        end
    else
        TargetBox.Visible = false
    end
    
    for _, otherPlayer in pairs(Players:GetPlayers()) do
        if otherPlayer ~= player and otherPlayer.Character and otherPlayer.Character:FindFirstChild("HumanoidRootPart") then
            local esp = ESPContainer:FindFirstChild(otherPlayer.Name .. "_ESP")
            local espBox = ESPContainer:FindFirstChild(otherPlayer.Name .. "_ESPBox")
            if not esp or not espBox then
                esp, espBox = createESP(otherPlayer)
            end
            updateESP(esp, espBox, otherPlayer)
        end
    end
end)
