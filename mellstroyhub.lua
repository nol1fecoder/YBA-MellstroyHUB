local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = game.Workspace.CurrentCamera

local COLOR = {
    TORNADO_GRAY = Color3.fromRGB(150, 160, 170),
    DARK_ACCENT = Color3.fromRGB(35, 35, 40),
    BACKGROUND = Color3.fromRGB(20, 20, 25),
    TEXT_BRIGHT = Color3.fromRGB(240, 240, 240),
    ACCENT_ON = Color3.fromRGB(0, 200, 255),
    REBIND = Color3.fromRGB(255, 150, 0),
    FRIEND_ADD = Color3.fromRGB(40, 200, 120),
    FRIEND_REMOVE = Color3.fromRGB(220, 80, 80),
    STATUS_OFF = Color3.fromRGB(50, 50, 55),
    TEXT_OFF = Color3.fromRGB(200, 200, 200),
    INFO_TEXT = Color3.fromRGB(120, 120, 120),
}

local Settings = {
    AutoPB = false,
    GERAim = false,
    LeadPrediction = false,
    ESPEnabled = false,
    PBMode = 1,
    AimFOV = 99,
    PBKey = Enum.KeyCode.F,
    GERKeyToggle = Enum.KeyCode.G,
    BlockModeKey = Enum.KeyCode.V,
    BackgroundImage = "",
    ShowBackground = false,
    Friends = {}
}

local AttackTimings = {
    ["Kick Barrage"] = 0, ["Sticky Fingers Finisher"] = 0.35, ["Gun_Shot1"] = 0.15, ["Heavy_Charge"] = 0.35, ["Erasure"] = 0.35,
    ["Disc"] = 0.35, ["Propeller Charge"] = 0.35, ["Platinum Slam"] = 0.2, ["Chomp"] = 0.25, ["Scary Monsters Bite"] = 0.25,
    ["D4C Love Train Finisher"] = 0.35, ["D4C Finisher"] = 0.35, ["Tusk ACT 4 Finisher"] = 0.35, ["Gold Experience Finisher"] = 0.35,
    ["Gold Experience Requiem Finisher"] = 0.35, ["Scary Monsters Finisher"] = 0.35, ["White Album Finisher"] = 0.35,
    ["Star Platinum Finisher"] = 0.35, ["Star Platinum: The World Finisher"] = 0.35, ["King Crimson Finisher"] = 0.35,
    ["King Crimson Requiem Finisher"] = 0.35, ["Crazy Diamond Finisher"] = 0.35, ["The World Alternate Universe Finisher"] = 0.35,
    ["The World Finisher"] = 0.45, ["The World Finisher2"] = 0.45, ["Purple Haze Finisher"] = 0.35, ["Hermit Purple Finisher"] = 0.35,
    ["Made in Heaven Finisher"] = 0.35, ["Whitesnake Finisher"] = 0.40, ["C-Moon Finisher"] = 0.35, ["Red Hot Chili Pepper Finisher"] = 0.35,
    ["Six Pistols Finisher"] = 0.45, ["Stone Free Finisher"] = 0.35, ["Ora Kicks"] = 0.12, ["lightning_jabs"] = 0.15,
    ["The World Kicks"] = 0.12, ["Muda Kicks"] = 0.12,
}

local PlayerEntries = {}
local ESPObjects = {}
local isListeningForKey = false
local keyToRebind = nil
local aimConnection = nil
local remoteEvent = nil
local clickSound = Instance.new("Sound")
clickSound.SoundId = "rbxassetid://6895079853"
clickSound.Volume = 0.5
clickSound.Parent = game.SoundService

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "GERMenu"
ScreenGui.Parent = game.CoreGui
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.ResetOnSpawn = false

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 380, 0, 620) 
MainFrame.Position = UDim2.new(0.5, -190, 0.5, -310) 
MainFrame.BackgroundColor3 = COLOR.BACKGROUND
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.ClipsDescendants = true
MainFrame.Parent = ScreenGui

Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 15)
Instance.new("UIStroke", MainFrame).Color = COLOR.TORNADO_GRAY
MainFrame.UIStroke.Thickness = 1.5
MainFrame.UIStroke.Transparency = 0.7

local BackgroundImageLabel = Instance.new("ImageLabel", MainFrame)
BackgroundImageLabel.Size = UDim2.new(1, 0, 1, 0)
BackgroundImageLabel.BackgroundTransparency = 1
BackgroundImageLabel.ImageTransparency = 0.7
BackgroundImageLabel.ScaleType = Enum.ScaleType.Crop
BackgroundImageLabel.Visible = false
BackgroundImageLabel.ZIndex = 1
Instance.new("UICorner", BackgroundImageLabel).CornerRadius = UDim.new(0, 15)

local Gradient = Instance.new("UIGradient", MainFrame)
Gradient.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(25, 25, 30)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(15, 15, 20))
}
Gradient.Rotation = 45
Gradient.ZIndex = 2

local TitleBar = Instance.new("Frame", MainFrame)
TitleBar.Size = UDim2.new(1, 0, 0, 50)
TitleBar.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
TitleBar.ZIndex = 3
Instance.new("UICorner", TitleBar).CornerRadius = UDim.new(0, 15)

local Title = Instance.new("TextLabel", TitleBar)
Title.Size = UDim2.new(1, -60, 1, 0)
Title.Position = UDim2.new(0, 20, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "Mellstroy Hub (Classic)"
Title.TextColor3 = COLOR.TORNADO_GRAY
Title.TextSize = 24
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.ZIndex = 4

local Content = Instance.new("ScrollingFrame", MainFrame)
Content.Size = UDim2.new(1, -30, 1, -100)
Content.Position = UDim2.new(0, 15, 0, 60)
Content.BackgroundTransparency = 1
Content.BorderSizePixel = 0
Content.ScrollBarThickness = 4
Content.ScrollBarImageColor3 = COLOR.TORNADO_GRAY
Content.AutomaticCanvasSize = Enum.AutomaticSize.None
Content.ZIndex = 3

local ContentLayout = Instance.new("UIListLayout", Content)
ContentLayout.SortOrder = Enum.SortOrder.LayoutOrder
ContentLayout.Padding = UDim.new(0, 10)

local function playClickSound()
    clickSound:Play()
end

local function createButton(text, parent, isKeyBind)
    local Button = Instance.new("TextButton")
    Button.Size = UDim2.new(1, -10, 0, 45)
    Button.BackgroundColor3 = COLOR.DARK_ACCENT
    Button.BorderSizePixel = 0
    Button.Text = ""
    Button.AutoButtonColor = false
    Button.Parent = parent
    Button.ZIndex = 4

    Instance.new("UICorner", Button).CornerRadius = UDim.new(0, 10)

    local ButtonText = Instance.new("TextLabel", Button)
    ButtonText.Size = UDim2.new(1, -20, 1, 0)
    ButtonText.Position = UDim2.new(0, 10, 0, 0)
    ButtonText.BackgroundTransparency = 1
    ButtonText.Text = text
    ButtonText.TextColor3 = COLOR.TEXT_BRIGHT
    ButtonText.TextSize = 16
    ButtonText.Font = Enum.Font.GothamBold
    ButtonText.TextXAlignment = Enum.TextXAlignment.Left
    ButtonText.ZIndex = 5

    local Status = Instance.new("TextLabel", Button)
    Status.Size = UDim2.new(0, 50, 0, 25)
    Status.BackgroundColor3 = COLOR.STATUS_OFF
    Status.BorderSizePixel = 0
    Status.Text = "OFF"
    Status.TextColor3 = COLOR.TEXT_OFF
    Status.TextSize = 12
    Status.Font = Enum.Font.GothamBold
    Status.ZIndex = 5

    local KeyDisplay = nil

    if isKeyBind then
        ButtonText.Size = UDim2.new(1, -130, 1, 0)
        Status.Position = UDim2.new(1, -115, 0.5, -12.5)
        KeyDisplay = Instance.new("TextButton", Button)
        KeyDisplay.Size = UDim2.new(0, 50, 0, 25)
        KeyDisplay.Position = UDim2.new(1, -60, 0.5, -12.5)
        KeyDisplay.BackgroundColor3 = COLOR.DARK_ACCENT
        KeyDisplay.BorderSizePixel = 0
        KeyDisplay.Text = "KEY"
        KeyDisplay.TextColor3 = COLOR.TORNADO_GRAY
        KeyDisplay.TextSize = 12
        KeyDisplay.Font = Enum.Font.GothamBold
        KeyDisplay.ZIndex = 5
        Instance.new("UICorner", KeyDisplay).CornerRadius = UDim.new(0, 8)
    else
        Status.Position = UDim2.new(1, -60, 0.5, -12.5)
    end
    Instance.new("UICorner", Status).CornerRadius = UDim.new(0, 8)

    Button.MouseEnter:Connect(function()
        TweenService:Create(Button, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(45, 45, 50)}):Play()
    end)
    Button.MouseLeave:Connect(function()
        TweenService:Create(Button, TweenInfo.new(0.2), {BackgroundColor3 = COLOR.DARK_ACCENT}):Play()
    end)

    return Button, Status, KeyDisplay
end

local function createSlider(text, min, max, default, parent)
    local Container = Instance.new("Frame", parent)
    Container.Size = UDim2.new(1, -10, 0, 60)
    Container.BackgroundColor3 = COLOR.DARK_ACCENT
    Container.BorderSizePixel = 0
    Container.ZIndex = 4
    Instance.new("UICorner", Container).CornerRadius = UDim.new(0, 10)

    local Label = Instance.new("TextLabel", Container)
    Label.Size = UDim2.new(1, -100, 0, 25)
    Label.Position = UDim2.new(0, 10, 0, 5)
    Label.BackgroundTransparency = 1
    Label.Text = text
    Label.TextColor3 = COLOR.TEXT_BRIGHT
    Label.TextSize = 14
    Label.Font = Enum.Font.GothamBold
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.ZIndex = 5

    local ValueLabel = Instance.new("TextLabel", Container)
    ValueLabel.Size = UDim2.new(0, 70, 0, 25)
    ValueLabel.Position = UDim2.new(1, -80, 0, 5)
    ValueLabel.BackgroundTransparency = 1
    ValueLabel.Text = tostring(default)
    ValueLabel.TextColor3 = COLOR.TORNADO_GRAY
    ValueLabel.TextSize = 14
    ValueLabel.Font = Enum.Font.GothamBold
    ValueLabel.ZIndex = 5

    local SliderBack = Instance.new("Frame", Container)
    SliderBack.Size = UDim2.new(1, -20, 0, 6)
    SliderBack.Position = UDim2.new(0, 10, 0, 40)
    SliderBack.BackgroundColor3 = COLOR.STATUS_OFF
    SliderBack.BorderSizePixel = 0
    SliderBack.ZIndex = 5
    Instance.new("UICorner", SliderBack).CornerRadius = UDim.new(1, 0)

    local SliderFill = Instance.new("Frame", SliderBack)
    SliderFill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)  
    SliderFill.BackgroundColor3 = COLOR.ACCENT_ON
    SliderFill.BorderSizePixel = 0
    SliderFill.ZIndex = 6
    Instance.new("UICorner", SliderFill).CornerRadius = UDim.new(1, 0)
    
    local dragging = false
    local function updateSlider(inputPos)
        local absPos = SliderBack.AbsolutePosition
        local relX = math.clamp((inputPos.X - absPos.X) / SliderBack.AbsoluteSize.X, 0, 1)
        local newVal = math.floor(min + relX * (max - min))
        SliderFill.Size = UDim2.new(relX, 0, 1, 0)
        ValueLabel.Text = tostring(newVal)
        Settings.AimFOV = newVal
    end
    
    SliderBack.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            updateSlider(UserInputService:GetMouseLocation())
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            updateSlider(UserInputService:GetMouseLocation())
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)

    return Container, ValueLabel
end

local function createTextBox(text, parent)
    local Container = Instance.new("Frame", parent)
    Container.Size = UDim2.new(1, -10, 0, 70)
    Container.BackgroundColor3 = COLOR.DARK_ACCENT
    Container.BorderSizePixel = 0
    Container.ZIndex = 4
    Instance.new("UICorner", Container).CornerRadius = UDim.new(0, 10)

    local Label = Instance.new("TextLabel", Container)
    Label.Size = UDim2.new(1, -20, 0, 20)
    Label.Position = UDim2.new(0, 10, 0, 5)
    Label.BackgroundTransparency = 1
    Label.Text = text
    Label.TextColor3 = COLOR.TEXT_BRIGHT
    Label.TextSize = 14
    Label.Font = Enum.Font.GothamBold
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.ZIndex = 5

    local TextBox = Instance.new("TextBox", Container)
    TextBox.Size = UDim2.new(1, -20, 0, 30)
    TextBox.Position = UDim2.new(0, 10, 0, 30)
    TextBox.BackgroundColor3 = COLOR.STATUS_OFF
    TextBox.BorderSizePixel = 0
    TextBox.Text = ""
    TextBox.PlaceholderText = "Image URL..."
    TextBox.TextColor3 = COLOR.TEXT_BRIGHT
    TextBox.PlaceholderColor3 = COLOR.INFO_TEXT
    TextBox.TextSize = 12
    TextBox.Font = Enum.Font.Gotham
    TextBox.ClearTextOnFocus = false
    TextBox.ZIndex = 5
    Instance.new("UICorner", TextBox).CornerRadius = UDim.new(0, 8)

    return Container, TextBox
end

local AutoPBButton, AutoPBStatus, AutoPBKeyDisplay = createButton("Auto Perfect Block", Content, true)
AutoPBKeyDisplay.Text = Settings.PBKey.Name
local GERAimButton, GERAimStatus, GERAimKeyDisplay = createButton("GER Aim Toggle", Content, true)
GERAimKeyDisplay.Text = Settings.GERKeyToggle.Name
local PBModeButton, PBModeStatus, PBModeKeyDisplay = createButton("Block Mode", Content, true)
PBModeKeyDisplay.Text = Settings.BlockModeKey.Name
local LeadPredButton, LeadPredStatus = createButton("Lead Prediction", Content, false)
local ESPButton, ESPStatus = createButton("ESP Enable", Content, false)
local FOVSlider, FOVValue = createSlider("Aim FOV (studs)", 30, 500, Settings.AimFOV, Content) 

local BGTitle = Instance.new("TextLabel", Content)
BGTitle.Size = UDim2.new(1, -10, 0, 25)
BGTitle.BackgroundTransparency = 1
BGTitle.Text = "Background Image"
BGTitle.TextColor3 = COLOR.TORNADO_GRAY
BGTitle.Font = Enum.Font.GothamBold
BGTitle.TextSize = 16
BGTitle.ZIndex = 4

local BGContainer, BGTextBox = createTextBox("Image URL", Content)
local BGToggleButton, BGToggleStatus = createButton("Show Background", Content, false)

local FriendsTitle = Instance.new("TextLabel", Content)
FriendsTitle.Size = UDim2.new(1, -10, 0, 30)
FriendsTitle.BackgroundTransparency = 1
FriendsTitle.Text = "Server Players"
FriendsTitle.TextColor3 = COLOR.TORNADO_GRAY
FriendsTitle.Font = Enum.Font.GothamBold
FriendsTitle.TextSize = 18
FriendsTitle.ZIndex = 4

local PlayerListFrame = Instance.new("ScrollingFrame", Content)
PlayerListFrame.Size = UDim2.new(1, -10, 0, 150) 
PlayerListFrame.BackgroundTransparency = 1
PlayerListFrame.BorderSizePixel = 0 
PlayerListFrame.ScrollBarThickness = 4 
PlayerListFrame.ScrollBarImageColor3 = COLOR.TORNADO_GRAY
PlayerListFrame.ZIndex = 4
local PlayerListLayout = Instance.new("UIListLayout", PlayerListFrame)
PlayerListLayout.Padding = UDim.new(0, 5)
PlayerListLayout.SortOrder = Enum.SortOrder.LayoutOrder

local Footer = Instance.new("Frame", MainFrame)
Footer.Size = UDim2.new(1, 0, 0, 40)
Footer.Position = UDim2.new(0, 0, 1, -40)
Footer.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
Footer.ZIndex = 3
Instance.new("UICorner", Footer).CornerRadius = UDim.new(0, 15)

local InfoText = Instance.new("TextLabel", Footer)
InfoText.Size = UDim2.new(1, -20, 1, 0)
InfoText.Position = UDim2.new(0, 10, 0, 0)
InfoText.BackgroundTransparency = 1
InfoText.Text = "RightShift - Menu | F/G/V - Toggles | X - Use GER Aim"
InfoText.TextColor3 = COLOR.INFO_TEXT
InfoText.TextSize = 12
InfoText.Font = Enum.Font.Gotham
InfoText.TextXAlignment = Enum.TextXAlignment.Left
InfoText.ZIndex = 4

local function updateCanvasSizes()
    task.wait()
    PlayerListFrame.CanvasSize = UDim2.new(0, 0, 0, PlayerListLayout.AbsoluteContentSize.Y)
    Content.CanvasSize = UDim2.new(0, 0, 0, ContentLayout.AbsoluteContentSize.Y)
end

local function updateToggleStatus(Status, settingState)
    Status.Text = settingState and "ON" or "OFF"
    Status.BackgroundColor3 = settingState and COLOR.ACCENT_ON or COLOR.STATUS_OFF
    Status.TextColor3 = settingState and Color3.fromRGB(30, 30, 30) or COLOR.TEXT_OFF
end

local function toggleFeature(settingName, statusElement)
    Settings[settingName] = not Settings[settingName]
    updateToggleStatus(statusElement, Settings[settingName])
    playClickSound()
end

local function updateFriendButton(button, playerName)
    if Settings.Friends[playerName] then
        button.Text = "Remove"
        button.BackgroundColor3 = COLOR.FRIEND_REMOVE
        button.TextColor3 = COLOR.TEXT_BRIGHT
    else
        button.Text = "Add"
        button.BackgroundColor3 = COLOR.FRIEND_ADD
        button.TextColor3 = Color3.fromRGB(30, 30, 30)
    end
end

local function createPlayerEntry(player)
    if PlayerEntries[player] then return end
    
    local Entry = Instance.new("Frame", PlayerListFrame)
    Entry.Size = UDim2.new(1, 0, 0, 35)
    Entry.BackgroundColor3 = COLOR.DARK_ACCENT
    Entry.BorderSizePixel = 0
    Entry.ZIndex = 5
    Instance.new("UICorner", Entry).CornerRadius = UDim.new(0, 8)

    local NameLabel = Instance.new("TextLabel", Entry)
    NameLabel.Size = UDim2.new(1, -100, 1, 0)
    NameLabel.Position = UDim2.new(0, 10, 0, 0)
    NameLabel.BackgroundTransparency = 1
    NameLabel.Text = player.Name
    NameLabel.TextColor3 = COLOR.TEXT_BRIGHT
    NameLabel.Font = Enum.Font.Gotham
    NameLabel.TextSize = 14
    NameLabel.TextXAlignment = Enum.TextXAlignment.Left
    NameLabel.ZIndex = 6

    local FriendButton = Instance.new("TextButton", Entry)
    FriendButton.Size = UDim2.new(0, 70, 0, 25)
    FriendButton.Position = UDim2.new(1, -80, 0.5, -12.5)
    FriendButton.BorderSizePixel = 0
    FriendButton.Font = Enum.Font.GothamBold
    FriendButton.TextSize = 12
    FriendButton.ZIndex = 6
    Instance.new("UICorner", FriendButton).CornerRadius = UDim.new(0, 6)

    updateFriendButton(FriendButton, player.Name)

    FriendButton.MouseButton1Click:Connect(function()
        Settings.Friends[player.Name] = not Settings.Friends[player.Name]
        updateFriendButton(FriendButton, player.Name)
    end)
    
    PlayerEntries[player] = Entry
    updateCanvasSizes()
end

local function removePlayerEntry(player)
    if PlayerEntries[player] then
        PlayerEntries[player]:Destroy()
        PlayerEntries[player] = nil
        updateCanvasSizes()
    end
    Settings.Friends[player.Name] = nil
end

local function clearESP()
    for _, espObj in pairs(ESPObjects) do
        for _, drawing in pairs(espObj) do
            if drawing then drawing:Remove() end
        end
    end
    ESPObjects = {}
end

local function createESPForPlayer(player)
    if ESPObjects[player] or not player.Character then return end
    
    local Box = Drawing.new("Square")
    Box.Visible = false
    Box.Color = Color3.new(1, 1, 1)
    Box.Thickness = 2
    Box.Transparency = 1
    Box.Filled = false
    
    local NameTag = Drawing.new("Text")
    NameTag.Visible = false
    NameTag.Color = Color3.new(1, 1, 1)
    NameTag.Size = 16
    NameTag.Center = true
    NameTag.Outline = true
    NameTag.Text = player.Name
    
    local Tracer = Drawing.new("Line")
    Tracer.Visible = false
    Tracer.Color = Color3.new(1, 1, 1)
    Tracer.Thickness = 1
    Tracer.Transparency = 1
    
    local Distance = Drawing.new("Text")
    Distance.Visible = false
    Distance.Color = Color3.new(1, 1, 1)
    Distance.Size = 14
    Distance.Center = true
    Distance.Outline = true
    
    ESPObjects[player] = {Box = Box, NameTag = NameTag, Tracer = Tracer, Distance = Distance}
end

local function updateESP()
    if not Settings.ESPEnabled then
        clearESP()
        return
    end
    
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            if not ESPObjects[player] then
                createESPForPlayer(player)
            end
            
            local character = player.Character
            local hrp = character:FindFirstChild("HumanoidRootPart")
            local humanoid = character:FindFirstChild("Humanoid")
            
            if hrp and humanoid and humanoid.Health > 0 then
                local espObj = ESPObjects[player]
                local vector, onScreen = Camera:WorldToViewportPoint(hrp.Position)
                
                if onScreen then
                    local headPos = character:FindFirstChild("Head")
                    if headPos then
                        local headVector = Camera:WorldToViewportPoint(headPos.Position + Vector3.new(0, 0.5, 0))
                        local legVector = Camera:WorldToViewportPoint(hrp.Position - Vector3.new(0, 3, 0))
                        
                        local height = math.abs(headVector.Y - legVector.Y)
                        local width = height / 2
                        
                        espObj.Box.Size = Vector2.new(width, height)
                        espObj.Box.Position = Vector2.new(vector.X - width / 2, headVector.Y)
                        espObj.Box.Visible = true
                        
                        espObj.NameTag.Position = Vector2.new(vector.X, headVector.Y - 20)
                        espObj.NameTag.Visible = true
                        
                        espObj.Tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                        espObj.Tracer.To = Vector2.new(vector.X, legVector.Y)
                        espObj.Tracer.Visible = true
                        
                        local myHRP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                        if myHRP then
                            local dist = math.floor((myHRP.Position - hrp.Position).Magnitude)
                            espObj.Distance.Text = tostring(dist) .. " studs"
                            espObj.Distance.Position = Vector2.new(vector.X, legVector.Y + 5)
                            espObj.Distance.Visible = true
                        end
                    end
                else
                    espObj.Box.Visible = false
                    espObj.NameTag.Visible = false
                    espObj.Tracer.Visible = false
                    espObj.Distance.Visible = false
                end
            end
        end
    end
end

local function checkSound(soundID)
    local soundsFolder = game.ReplicatedStorage:FindFirstChild("Sounds")
    if not soundsFolder then return nil end

    for _, v in soundsFolder:GetChildren() do
        if v:IsA("Sound") and v.SoundId == soundID then return v.Name end
    end
    return nil
end

local function performBlock(mode)
    local character = LocalPlayer.Character
    if not character or not remoteEvent then return end

    pcall(function()
        if mode == 2 then
            remoteEvent:FireServer("InputEnded", {Input = Enum.KeyCode.E})
            remoteEvent:FireServer("InputEnded", {Input = Enum.KeyCode.R})
            task.wait(0.03)
        end
        remoteEvent:FireServer("StartBlocking")
        task.wait(0.48)
        remoteEvent:FireServer("StopBlocking")
    end)
end

local function checkPBMove(character, moveName)
    if not Settings.AutoPB or not AttackTimings[moveName] then return end
    
    local targetHRP = character:FindFirstChild("HumanoidRootPart")
    local myHRP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not myHRP or not targetHRP then return end
    
    local distance = (myHRP.Position - targetHRP.Position).Magnitude
    if distance < 35 then 
        task.spawn(function()
            task.wait(AttackTimings[moveName])
            performBlock(Settings.PBMode) 
        end)
    end
end

local function getClosestPlayer()
    local closest, shortestDist = nil, math.huge
    local myHRP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not myHRP then return nil end

    for _, player in Players:GetPlayers() do
        if player ~= LocalPlayer and player.Character and not Settings.Friends[player.Name] then
            local humanoid = player.Character:FindFirstChild("Humanoid")
            local rootPart = player.Character:FindFirstChild("HumanoidRootPart")
            if humanoid and humanoid.Health > 0 and rootPart then
                local dist = (myHRP.Position - rootPart.Position).Magnitude
                if dist < shortestDist and dist < Settings.AimFOV then 
                    closest = player
                    shortestDist = dist
                end
            end
        end
    end
    return closest
end

local function getPredictedPosition(targetHRP)
    if not Settings.LeadPrediction then return targetHRP.Position end
    
    local velocity = targetHRP.AssemblyLinearVelocity or targetHRP.Velocity
    if velocity then
        return targetHRP.Position + (velocity * 0.1)
    end
    return targetHRP.Position
end

local function setupPlayer(player)
    if not player.Character then return end

    local connection
    connection = player.Character.DescendantAdded:Connect(function(child)
        if Settings.AutoPB and child:IsA("Sound") and child.SoundId then
            task.wait(0.05)
            local moveName = checkSound(child.SoundId)
            if moveName then 
                checkPBMove(player.Character, moveName)
            end
        end
    end)
    
    player.CharacterRemoving:Connect(function()
        if connection then connection:Disconnect() end
    end)
end

local function setupRemoteEvent(character)
    remoteEvent = character:FindFirstChild("RemoteEvent")
end

AutoPBButton.MouseButton1Click:Connect(function()
    if not isListeningForKey and (not AutoPBKeyDisplay or UserInputService:GetMouseLocation().X < AutoPBKeyDisplay.AbsolutePosition.X) then
        toggleFeature("AutoPB", AutoPBStatus)
    end
end)

GERAimButton.MouseButton1Click:Connect(function()
    if not isListeningForKey and (not GERAimKeyDisplay or UserInputService:GetMouseLocation().X < GERAimKeyDisplay.AbsolutePosition.X) then
        toggleFeature("GERAim", GERAimStatus)
    end
end)

PBModeButton.MouseButton1Click:Connect(function()
    if not isListeningForKey and (not PBModeKeyDisplay or UserInputService:GetMouseLocation().X < PBModeKeyDisplay.AbsolutePosition.X) then
        Settings.PBMode = Settings.PBMode == 1 and 2 or 1
        local modeText = Settings.PBMode == 1 and "Normal" or "Interrupt"
        PBModeStatus.Text = modeText
        PBModeStatus.BackgroundColor3 = Settings.PBMode == 2 and COLOR.REBIND or COLOR.STATUS_OFF
        playClickSound()
    end
end)

LeadPredButton.MouseButton1Click:Connect(function()
    toggleFeature("LeadPrediction", LeadPredStatus)
end)

ESPButton.MouseButton1Click:Connect(function()
    toggleFeature("ESPEnabled", ESPStatus)
    if not Settings.ESPEnabled then
        clearESP()
    end
end)

BGToggleButton.MouseButton1Click:Connect(function()
    Settings.ShowBackground = not Settings.ShowBackground
    updateToggleStatus(BGToggleStatus, Settings.ShowBackground)
    BackgroundImageLabel.Visible = Settings.ShowBackground
    playClickSound()
end)

BGTextBox.FocusLost:Connect(function(enterPressed)
    if enterPressed then
        Settings.BackgroundImage = BGTextBox.Text
        if Settings.BackgroundImage ~= "" then
            BackgroundImageLabel.Image = Settings.BackgroundImage
        end
    end
end)

AutoPBKeyDisplay.MouseButton1Click:Connect(function()
    if isListeningForKey then return end
    isListeningForKey = true
    keyToRebind = "PBKey"
    AutoPBKeyDisplay.Text = "[...]"
    AutoPBKeyDisplay.BackgroundColor3 = COLOR.REBIND
    AutoPBKeyDisplay.TextColor3 = Color3.fromRGB(30, 30, 30)
end)

GERAimKeyDisplay.MouseButton1Click:Connect(function()
    if isListeningForKey then return end
    isListeningForKey = true
    keyToRebind = "GERKeyToggle"
    GERAimKeyDisplay.Text = "[...]"
    GERAimKeyDisplay.BackgroundColor3 = COLOR.REBIND
    GERAimKeyDisplay.TextColor3 = Color3.fromRGB(30, 30, 30)
end)

PBModeKeyDisplay.MouseButton1Click:Connect(function()
    if isListeningForKey then return end
    isListeningForKey = true
    keyToRebind = "BlockModeKey"
    PBModeKeyDisplay.Text = "[...]"
    PBModeKeyDisplay.BackgroundColor3 = COLOR.REBIND
    PBModeKeyDisplay.TextColor3 = Color3.fromRGB(30, 30, 30)
end)

UserInputService.InputBegan:Connect(function(input, processed)
    local KeyCode = input.KeyCode

    if isListeningForKey and not processed and KeyCode.Value ~= 0 and KeyCode ~= Enum.KeyCode.RightShift then
        local KeyDisplayElement
        if keyToRebind == "PBKey" then
            Settings.PBKey = KeyCode
            KeyDisplayElement = AutoPBKeyDisplay
        elseif keyToRebind == "GERKeyToggle" then
            Settings.GERKeyToggle = KeyCode
            KeyDisplayElement = GERAimKeyDisplay
        elseif keyToRebind == "BlockModeKey" then
            Settings.BlockModeKey = KeyCode
            KeyDisplayElement = PBModeKeyDisplay
        end
        isListeningForKey = false
        if KeyDisplayElement then
            KeyDisplayElement.Text = KeyCode.Name
            KeyDisplayElement.BackgroundColor3 = COLOR.DARK_ACCENT
            KeyDisplayElement.TextColor3 = COLOR.TORNADO_GRAY
        end
        keyToRebind = nil
        playClickSound()
        return
    end

    if KeyCode == Settings.PBKey and not isListeningForKey and not processed then
        toggleFeature("AutoPB", AutoPBStatus)
    elseif KeyCode == Settings.GERKeyToggle and not isListeningForKey and not processed then
        toggleFeature("GERAim", GERAimStatus)
    elseif KeyCode == Settings.BlockModeKey and not isListeningForKey and not processed then
        Settings.PBMode = Settings.PBMode == 1 and 2 or 1
        local modeText = Settings.PBMode == 1 and "Normal" or "Interrupt"
        PBModeStatus.Text = modeText
        PBModeStatus.BackgroundColor3 = Settings.PBMode == 2 and COLOR.REBIND or COLOR.STATUS_OFF
        playClickSound()
    elseif KeyCode == Enum.KeyCode.RightShift then
        MainFrame.Visible = not MainFrame.Visible
    elseif not processed and KeyCode == Enum.KeyCode.X and Settings.GERAim and remoteEvent then
        local target = getClosestPlayer()
        if target and target.Character then
            local targetHRP = target.Character:FindFirstChild("HumanoidRootPart")
            if targetHRP then
                if aimConnection then aimConnection:Disconnect() end

                aimConnection = RunService.RenderStepped:Connect(function()
                    if targetHRP and targetHRP.Parent and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                        local myHRP = LocalPlayer.Character.HumanoidRootPart
                        if (targetHRP.Position - myHRP.Position).Magnitude <= Settings.AimFOV then
                            local predictedPos = getPredictedPosition(targetHRP)
                            local lookVector = (predictedPos - Camera.CFrame.Position).Unit
                            local newCFrame = CFrame.new(Camera.CFrame.Position, Camera.CFrame.Position + lookVector)
                            Camera.CFrame = Camera.CFrame:Lerp(newCFrame, 0.5)
                        else
                            aimConnection:Disconnect()
                            aimConnection = nil
                            remoteEvent:FireServer("InputEnded", {Input = Enum.KeyCode.X})
                        end
                    else
                        if aimConnection then aimConnection:Disconnect(); aimConnection = nil end
                        remoteEvent:FireServer("InputEnded", {Input = Enum.KeyCode.X})
                    end
                end)
                remoteEvent:FireServer("InputBegan", {Input = Enum.KeyCode.X})
            end
        end
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.X and remoteEvent then
        if aimConnection then aimConnection:Disconnect(); aimConnection = nil end
        remoteEvent:FireServer("InputEnded", {Input = Enum.KeyCode.X})
    end
end)

RunService.RenderStepped:Connect(function()
    if Settings.ESPEnabled then
        updateESP()
    end
end)

updateToggleStatus(AutoPBStatus, Settings.AutoPB)
updateToggleStatus(GERAimStatus, Settings.GERAim)
updateToggleStatus(LeadPredStatus, Settings.LeadPrediction)
updateToggleStatus(ESPStatus, Settings.ESPEnabled)
updateToggleStatus(BGToggleStatus, Settings.ShowBackground)
local modeText = Settings.PBMode == 1 and "Normal" or "Interrupt"
PBModeStatus.Text = modeText
PBModeStatus.BackgroundColor3 = Settings.PBMode == 2 and COLOR.REBIND or COLOR.STATUS_OFF

for _, player in Players:GetPlayers() do 
    if player ~= LocalPlayer then 
        setupPlayer(player) 
        createPlayerEntry(player) 
    end 
end

Players.PlayerAdded:Connect(function(player) 
    createPlayerEntry(player) 
    player.CharacterAdded:Connect(function(character) task.wait(0.5); setupPlayer(player) end) 
end)

Players.PlayerRemoving:Connect(function(player)
    removePlayerEntry(player)
    if ESPObjects[player] then
        for _, drawing in pairs(ESPObjects[player]) do
            if drawing then drawing:Remove() end
        end
        ESPObjects[player] = nil
    end
end)

LocalPlayer.CharacterAdded:Connect(function(char) task.wait(0.1); setupRemoteEvent(char) end)
if LocalPlayer.Character then setupRemoteEvent(LocalPlayer.Character) end

updateCanvasSizes()
