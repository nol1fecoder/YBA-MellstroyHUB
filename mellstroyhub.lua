-- Utility Hub (LocalScript) - FIXED VERSION
-- Исправлены проблемы с отображением GUI и стабильностью

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local PathfindingService = game:GetService("PathfindingService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Ждем загрузки игрока
if not LocalPlayer then
    repeat task.wait() until Players.LocalPlayer
    LocalPlayer = Players.LocalPlayer
end

-- Debug logging
local DebugEnabled = true
local GuiLogBuffer = {}
local function dbg(msg)
    if DebugEnabled then
        pcall(function() print("[UtilityHub] "..tostring(msg)) end)
    end
    table.insert(GuiLogBuffer, tostring(msg))
    if #GuiLogBuffer > 400 then
        for i = 1, 150 do table.remove(GuiLogBuffer, 1) end
    end
end

-- Settings
local Settings = {
    AutoFarm = false,
    AutoSell = false,
    AutoLuckyBuy = false,
    AutoPB = false,
    AimAssist = false,
    Chams = false,
    AimFOV = 120,
    AimSmoothing = 0.12,
    AutoFarmWalkspeed = 45,
    DefaultWalkspeed = 16,
    MoveStopDistance = 3,
    PathTimeout = 14,
    AutoFarmScanInterval = 0.6,
    AutoSellInterval = 2.5,
    AutoLuckyInterval = 1.0,
    AutoPBInterval = 0.12,
    PromptSearchDistance = 300,
    Keybinds = {
        ToggleMenu = Enum.KeyCode.RightShift,
        ToggleAutoFarm = Enum.KeyCode.Y,
        ToggleAutoSell = Enum.KeyCode.U,
        ToggleLucky = Enum.KeyCode.I,
        TogglePB = Enum.KeyCode.F,
        ToggleAim = Enum.KeyCode.G
    }
}

local Remotes = { Sell = nil, Buy = nil, Item = nil, Block = nil }
local RemoteCandidates = {
    Sell = {"SellRemote", "SellAll", "SellService", "SellEvent", "Remote_Sell"},
    Buy = {"ShopRemote", "BuyRemote", "PurchaseRemote", "ShopBuy", "Remote_Buy"},
    Item = {"ItemRemote", "PickupRemote", "GiveItem", "CollectRemote"},
    Block = {"BlockRemote", "PBRemote", "BlockEvent", "BlockAction"}
}

-- ANTI-CHEAT BYPASS
local OldNamecallTP
local isHooked = false
local NamecallBypassRemote = nil

local function hookTPBypass()
    if not newcclosure or not hookmetamethod then 
        dbg("Bypass functions not available")
        return 
    end
    if isHooked then return end
    
    local gotoBtn = new(entry, "TextButton", {
        Text = "Goto",
        Size = UDim2.new(0, 50, 0, 24),
        Position = UDim2.new(1, -58, 0.5, -12),
        BackgroundColor3 = Color3.fromRGB(90, 140, 200),
        TextColor3 = Color3.fromRGB(255, 255, 255),
        Font = Enum.Font.GothamBold,
        TextSize = 11
    })
    new(gotoBtn, "UICorner", {CornerRadius = UDim.new(0, 5)})
    
    gotoBtn.MouseButton1Click:Connect(function()
        task.spawn(function()
            if player and player.Character then
                local success = gotoPlayer(player)
                if success then
                    dbg("Телепорт к "..player.Name.." выполнен")
                else
                    dbg("Не удалось добраться до "..player.Name)
                end
            end
        end)
    end)
    
    PlayerEntries[player] = {Frame = entry, Goto = gotoBtn}
end

local function removePlayerEntry(player)
    local e = PlayerEntries[player]
    if e and e.Frame then
        pcall(function() e.Frame:Destroy() end)
    end
    PlayerEntries[player] = nil
end

-- Добавляем текущих игроков
for _, p in ipairs(Players:GetPlayers()) do
    if p ~= LocalPlayer then
        createPlayerEntry(p)
    end
end

-- Отслеживаем новых игроков
Players.PlayerAdded:Connect(function(pl)
    if pl ~= LocalPlayer then
        createPlayerEntry(pl)
    end
end)

Players.PlayerRemoving:Connect(removePlayerEntry)

-- Debug log
createSectionLabel("📋 Лог событий")

local logFrame = new(Content, "Frame", {
    Size = UDim2.new(1, 0, 0, 150),
    BackgroundColor3 = Color3.fromRGB(48, 54, 66)
})
new(logFrame, "UICorner", {CornerRadius = UDim.new(0, 8)})

local logScroll = new(logFrame, "ScrollingFrame", {
    Size = UDim2.new(1, -12, 1, -12),
    Position = UDim2.new(0, 6, 0, 6),
    BackgroundTransparency = 1,
    ScrollBarThickness = 6
})
new(logScroll, "UIListLayout", {Padding = UDim.new(0, 2)})
logScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y

local function refreshGuiLog()
    for _, c in ipairs(logScroll:GetChildren()) do
        if c:IsA("TextLabel") then c:Destroy() end
    end
    
    local startIdx = math.max(1, #GuiLogBuffer - 50)
    for i = startIdx, #GuiLogBuffer do
        local logLabel = new(logScroll, "TextLabel", {
            Text = GuiLogBuffer[i],
            BackgroundTransparency = 1,
            TextColor3 = Color3.fromRGB(200, 200, 200),
            Font = Enum.Font.Code,
            TextSize = 11,
            Size = UDim2.new(1, -8, 0, 16),
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd
        })
    end
end

-- Обновляем лог каждую секунду
task.spawn(function()
    while ScreenGui and ScreenGui.Parent do
        refreshGuiLog()
        task.wait(1)
    end
end)

dbg("Все элементы GUI добавлены!")

-- Keyboard shortcuts
UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
    
    local key = input.KeyCode
    
    if key == Settings.Keybinds.ToggleMenu then
        MainFrame.Visible = not MainFrame.Visible
        dbg("Меню "..(MainFrame.Visible and "открыто" or "закрыто"))
        
    elseif key == Settings.Keybinds.ToggleAutoFarm then
        Settings.AutoFarm = not Settings.AutoFarm
        afBtn.Text = Settings.AutoFarm and "ON" or "OFF"
        afBtn.BackgroundColor3 = Settings.AutoFarm and Color3.fromRGB(0,160,230) or Color3.fromRGB(88,96,110)
        if Settings.AutoFarm then startAutoFarm() else stopAutoFarm() end
        
    elseif key == Settings.Keybinds.ToggleAutoSell then
        Settings.AutoSell = not Settings.AutoSell
        asBtn.Text = Settings.AutoSell and "ON" or "OFF"
        asBtn.BackgroundColor3 = Settings.AutoSell and Color3.fromRGB(0,160,230) or Color3.fromRGB(88,96,110)
        if Settings.AutoSell then startAutoSell() else stopAutoSell() end
        
    elseif key == Settings.Keybinds.ToggleLucky then
        Settings.AutoLuckyBuy = not Settings.AutoLuckyBuy
        alBtn.Text = Settings.AutoLuckyBuy and "ON" or "OFF"
        alBtn.BackgroundColor3 = Settings.AutoLuckyBuy and Color3.fromRGB(0,160,230) or Color3.fromRGB(88,96,110)
        if Settings.AutoLuckyBuy then startAutoLuckyBuy() else stopAutoLuckyBuy() end
        
    elseif key == Settings.Keybinds.TogglePB then
        Settings.AutoPB = not Settings.AutoPB
        apbBtn.Text = Settings.AutoPB and "ON" or "OFF"
        apbBtn.BackgroundColor3 = Settings.AutoPB and Color3.fromRGB(0,160,230) or Color3.fromRGB(88,96,110)
        if Settings.AutoPB then startAutoPB() else stopAutoPB() end
        
    elseif key == Settings.Keybinds.ToggleAim then
        Settings.AimAssist = not Settings.AimAssist
        aimBtn.Text = Settings.AimAssist and "ON" or "OFF"
        aimBtn.BackgroundColor3 = Settings.AimAssist and Color3.fromRGB(0,160,230) or Color3.fromRGB(88,96,110)
    end
end)

-- Sync walkspeed on respawn
LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(0.3)
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if humanoid then
        Settings.DefaultWalkspeed = humanoid.WalkSpeed or Settings.DefaultWalkspeed
        if Settings.AutoFarm then
            humanoid.WalkSpeed = Settings.AutoFarmWalkspeed
        end
    end
    resolveNamecallRemote()
    dbg("Персонаж респавнился")
end)

-- Setup players highlighting
Players.PlayerAdded:Connect(function(player)
    if Settings.Chams then
        setupHighlightForPlayer(player)
    end
end)

Players.PlayerRemoving:Connect(function(player)
    if Highlights[player] then
        pcall(function() Highlights[player]:Destroy() end)
        Highlights[player] = nil
    end
end)

-- Initial setup
autoResolveRemotes()
resolveNamecallRemote()

dbg("=================================")
dbg("🚀 Utility Hub загружен успешно!")
dbg("=================================")
dbg("Горячие клавиши:")
dbg("  RightShift - Открыть/закрыть меню")
dbg("  Y - AutoFarm")
dbg("  U - AutoSell")
dbg("  I - Auto Lucky Buy")
dbg("  F - Auto Perfect Block")
dbg("  G - Aim Assist")
dbg("=================================")
dbg("GUI готов к использованию!")

-- Показываем уведомление
task.spawn(function()
    local notification = new(ScreenGui, "Frame", {
        Size = UDim2.new(0, 300, 0, 60),
        Position = UDim2.new(0.5, -150, 0, -80),
        BackgroundColor3 = Color3.fromRGB(50, 200, 100),
        BorderSizePixel = 0
    })
    new(notification, "UICorner", {CornerRadius = UDim.new(0, 10)})
    
    local notifText = new(notification, "TextLabel", {
        Size = UDim2.new(1, -20, 1, -20),
        Position = UDim2.new(0, 10, 0, 10),
        BackgroundTransparency = 1,
        Text = "✅ Utility Hub загружен!\nНажмите RightShift для открытия",
        TextColor3 = Color3.fromRGB(255, 255, 255),
        Font = Enum.Font.GothamBold,
        TextSize = 13,
        TextWrapped = true
    })
    
    -- Анимация появления
    notification:TweenPosition(
        UDim2.new(0.5, -150, 0, 20),
        Enum.EasingDirection.Out,
        Enum.EasingStyle.Back,
        0.5,
        true
    )
    
    task.wait(3)
    
    -- Анимация исчезновения
    notification:TweenPosition(
        UDim2.new(0.5, -150, 0, -80),
        Enum.EasingDirection.In,
        Enum.EasingStyle.Back,
        0.5,
        true
    )
    
    task.wait(0.6)
    notification:Destroy()
end) success = pcall(function()
        OldNamecallTP = hookmetamethod(game, '__namecall', newcclosure(function(self, ...)
            local Arguments = {...}
            local Method = getnamecallmethod()
            
            if Method == "InvokeServer" and Arguments[1] == "idklolbrah2de" then
                return "___XP DE KEY"
            end
            
            return OldNamecallTP(self, ...)
        end))
        isHooked = true
        dbg("Bypass hook установлен успешно")
    end)
    
    if not success then
        dbg("Bypass hook не удалось установить (executor не поддерживает)")
    end
end

pcall(hookTPBypass)

-- Utility functions
local function new(parent, class, props)
    local inst = Instance.new(class)
    if props then
        for k, v in pairs(props) do
            if k ~= "Parent" then
                pcall(function() inst[k] = v end)
            end
        end
    end
    if parent then inst.Parent = parent end
    return inst
end

local function isRemoteObject(obj)
    return obj and (obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction"))
end

local function tryResolveRemoteByNames(list)
    for _, name in ipairs(list) do
        local rem = ReplicatedStorage:FindFirstChild(name, true)
        if rem and isRemoteObject(rem) then
            return rem
        end
    end
    return nil
end

local function autoResolveRemotes()
    Remotes.Sell = tryResolveRemoteByNames(RemoteCandidates.Sell)
    Remotes.Buy = tryResolveRemoteByNames(RemoteCandidates.Buy)
    Remotes.Item = tryResolveRemoteByNames(RemoteCandidates.Item)
    Remotes.Block = tryResolveRemoteByNames(RemoteCandidates.Block)
    dbg(("Remotes: Sell=%s Buy=%s Item=%s Block=%s"):format(
        tostring(Remotes.Sell and Remotes.Sell.Name or "nil"),
        tostring(Remotes.Buy and Remotes.Buy.Name or "nil"),
        tostring(Remotes.Item and Remotes.Item.Name or "nil"),
        tostring(Remotes.Block and Remotes.Block.Name or "nil")
    ))
end

local function safeFire(remote, ...)
    if not remote then return false end
    local ok = pcall(function() remote:FireServer(...) end)
    return ok
end

local function getRootPart(character)
    if not character then return nil end
    return character:FindFirstChild("HumanoidRootPart") or 
           character:FindFirstChild("Torso") or 
           character:FindFirstChild("UpperTorso")
end

local function randomOffset(magnitude)
    magnitude = magnitude or 0.4
    return Vector3.new((math.random()-0.5)*2*magnitude, 0, (math.random()-0.5)*2*magnitude)
end

-- Resolve bypass remote
local function resolveNamecallRemote()
    if NamecallBypassRemote then return end
    local char = LocalPlayer.Character
    if not char then return end
    
    NamecallBypassRemote = char:FindFirstChild("RemoteEvent") 
        or char:FindFirstChild("MoveRemote") 
        or char:FindFirstChild("InputRemote") 
        or ReplicatedStorage:FindFirstChild("InputRemote")
    
    if NamecallBypassRemote then
        dbg("NamecallBypassRemote найден: "..NamecallBypassRemote:GetFullName())
    end
end

-- Teleport with bypass
local function teleportToPosition(targetPos)
    local character = LocalPlayer.Character
    local HRP = character and getRootPart(character)
    
    if not HRP then 
        dbg("Телепорт: нет HRP")
        return false 
    end
    
    if not NamecallBypassRemote or not isHooked then
        dbg("Телепорт: bypass не готов, используем обычную телепортацию")
        HRP.CFrame = CFrame.new(targetPos) * CFrame.new(0, 1, 0)
        return true
    end
    
    local targetCFrame = CFrame.new(targetPos)
    local finalCFrame = targetCFrame * CFrame.new(0, 1, 0)
    
    pcall(function()
        safeFire(NamecallBypassRemote, "InputBegan", {
            Input = Enum.KeyCode.W,
            CFrame = finalCFrame
        })
        
        HRP.CFrame = finalCFrame
        
        safeFire(NamecallBypassRemote, "InputEnded", {
            Input = Enum.KeyCode.W,
        })
        
        dbg("Телепортировался к: "..tostring(targetPos))
    end)
    
    return true
end

-- Pathfinding
local function computePath(startPos, endPos)
    local ok, path = pcall(function()
        local p = PathfindingService:CreatePath({
            AgentRadius = 2,
            AgentHeight = 5,
            AgentCanJump = true,
            AgentMaxSlope = 45
        })
        p:ComputeAsync(startPos, endPos)
        return p
    end)
    if not ok or not path then return nil end
    if path.Status == Enum.PathStatus.Success then return path end
    return nil
end

local function moveToWithPath(targetPos, stopDist, timeout)
    stopDist = stopDist or Settings.MoveStopDistance
    timeout = timeout or Settings.PathTimeout
    if not LocalPlayer.Character then return false end
    local humanoid = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    local hrp = getRootPart(LocalPlayer.Character)
    if not humanoid or not hrp then return false end

    local path = computePath(hrp.Position, targetPos)
    if not path then
        humanoid:MoveTo(targetPos + randomOffset(0.6))
        humanoid.MoveToFinished:Wait()
        return (hrp.Position - targetPos).Magnitude <= stopDist
    end

    local waypoints = path:GetWaypoints()
    for _, wp in ipairs(waypoints) do
        if wp.Action == Enum.PathWaypointAction.Jump then humanoid.Jump = true end
        humanoid:MoveTo(wp.Position + randomOffset(0.3))
        humanoid.MoveToFinished:Wait()
        if (hrp.Position - targetPos).Magnitude <= stopDist then return true end
    end
    return (hrp.Position - targetPos).Magnitude <= stopDist
end

local function smoothApproach(targetPos)
    local ok = moveToWithPath(targetPos, Settings.MoveStopDistance, Settings.PathTimeout)
    if ok then return true end
    
    if not LocalPlayer.Character then return false end
    local hrp = getRootPart(LocalPlayer.Character)
    if not hrp then return false end
    
    local dist = (hrp.Position - targetPos).Magnitude
    local duration = math.clamp(dist / 28, 0.12, 1.2)
    
    pcall(function()
        local tween = TweenService:Create(hrp, 
            TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), 
            {CFrame = CFrame.new(targetPos + randomOffset(0.2))}
        )
        tween:Play()
        task.wait(duration + 0.05)
    end)
    
    hrp = getRootPart(LocalPlayer.Character)
    return hrp and ((hrp.Position - targetPos).Magnitude <= Settings.MoveStopDistance)
end

-- Proximity prompt interaction
local function interactPrompt(prompt)
    if not prompt then return false end
    if typeof(fireproximityprompt) == "function" then
        pcall(function() fireproximityprompt(prompt, 1) end)
        return true
    end
    if prompt:IsA("ProximityPrompt") then
        pcall(function()
            if prompt.InputHoldEnd then
                prompt:InputHoldEnd()
            end
        end)
        return true
    end
    return false
end

-- Scan for pickups
local function scanForPickups()
    local items = {}
    local containers = {}
    
    if workspace:FindFirstChild("Item_Spawns") then 
        table.insert(containers, workspace.Item_Spawns) 
    end
    if workspace:FindFirstChild("Items") then 
        table.insert(containers, workspace.Items) 
    end
    table.insert(containers, workspace)

    local function considerModel(m)
        if not m or items[m] then return end
        
        local primary = m.PrimaryPart or m:FindFirstChildWhichIsA("BasePart")
        local prompt = m:FindFirstChildWhichIsA("ProximityPrompt", true)
        
        if primary and prompt then
            items[m] = {Model = m, Primary = primary, Prompt = prompt}
        end
    end

    for _, container in ipairs(containers) do
        if container then
            for _, obj in ipairs(container:GetDescendants()) do
                if obj:IsA("Model") or obj:IsA("BasePart") then
                    considerModel(obj)
                end
            end
        end
    end

    return items
end

-- Auto loops
local autoFarmThread
local function startAutoFarm()
    if autoFarmThread then return end
    autoFarmThread = task.spawn(function()
        dbg("AutoFarm запущен")
        while Settings.AutoFarm do
            local char = LocalPlayer.Character
            if char then
                local hrp = getRootPart(char)
                if hrp then
                    local items = scanForPickups()
                    for model, info in pairs(items) do
                        if not Settings.AutoFarm then break end
                        if model and info.Primary and info.Prompt and info.Primary.Parent then
                            local approached = pcall(function() 
                                return smoothApproach(info.Primary.Position) 
                            end)
                            if approached then
                                interactPrompt(info.Prompt)
                                task.wait(0.1)
                            end
                        end
                        task.wait(0.05)
                    end
                end
            end
            task.wait(Settings.AutoFarmScanInterval)
        end
        dbg("AutoFarm остановлен")
        autoFarmThread = nil
    end)
end

local function stopAutoFarm()
    Settings.AutoFarm = false
    autoFarmThread = nil
end

local autoSellThread
local function startAutoSell()
    if autoSellThread then return end
    autoSellThread = task.spawn(function()
        dbg("AutoSell запущен")
        while Settings.AutoSell do
            if Remotes.Sell then
                safeFire(Remotes.Sell, "SellAll")
                dbg("AutoSell: remote fired")
            end
            task.wait(Settings.AutoSellInterval)
        end
        dbg("AutoSell остановлен")
        autoSellThread = nil
    end)
end

local function stopAutoSell()
    Settings.AutoSell = false
    autoSellThread = nil
end

local autoLuckyThread
local function startAutoLuckyBuy()
    if autoLuckyThread then return end
    autoLuckyThread = task.spawn(function()
        dbg("AutoLuckyBuy запущен")
        while Settings.AutoLuckyBuy do
            if Remotes.Buy then
                safeFire(Remotes.Buy, "BuyItem", "Lucky")
                dbg("AutoLuckyBuy: remote fired")
            end
            task.wait(Settings.AutoLuckyInterval)
        end
        dbg("AutoLuckyBuy остановлен")
        autoLuckyThread = nil
    end)
end

local function stopAutoLuckyBuy()
    Settings.AutoLuckyBuy = false
    autoLuckyThread = nil
end

local autoPBThread
local function startAutoPB()
    if autoPBThread then return end
    autoPBThread = task.spawn(function()
        dbg("AutoPB запущен")
        while Settings.AutoPB do
            if Remotes.Block then
                safeFire(Remotes.Block, "StartBlock")
            end
            task.wait(Settings.AutoPBInterval)
        end
        dbg("AutoPB остановлен")
        autoPBThread = nil
    end)
end

local function stopAutoPB()
    Settings.AutoPB = false
    autoPBThread = nil
end

-- Chams
local Highlights = {}
local function setupHighlightForPlayer(player)
    if player == LocalPlayer then return end
    if Highlights[player] then
        pcall(function() Highlights[player]:Destroy() end)
    end
    if player.Character then
        local highlight = Instance.new("Highlight")
        highlight.Name = "UH_Highlight"
        highlight.Parent = player.Character
        highlight.FillColor = Color3.fromRGB(0, 200, 255)
        highlight.OutlineColor = Color3.fromRGB(20, 20, 20)
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        highlight.Enabled = Settings.Chams
        Highlights[player] = highlight
    end
end

local function enableChams()
    Settings.Chams = true
    for _, p in ipairs(Players:GetPlayers()) do 
        setupHighlightForPlayer(p) 
    end
end

local function disableChams()
    Settings.Chams = false
    for _, hl in pairs(Highlights) do
        pcall(function() hl:Destroy() end)
    end
    Highlights = {}
end

-- Aim Assist
local function findClosestTarget()
    local myHRP = LocalPlayer.Character and getRootPart(LocalPlayer.Character)
    if not myHRP then return nil end
    local best = nil
    local bestDist = Settings.AimFOV
    
    for _, pl in ipairs(Players:GetPlayers()) do
        if pl ~= LocalPlayer and pl.Character then
            local humanoid = pl.Character:FindFirstChildOfClass("Humanoid")
            if humanoid and humanoid.Health > 0 then
                local hrp = getRootPart(pl.Character)
                if hrp then
                    local dist = (hrp.Position - myHRP.Position).Magnitude
                    if dist <= bestDist then
                        bestDist = dist
                        best = hrp
                    end
                end
            end
        end
    end
    return best
end

RunService.RenderStepped:Connect(function()
    if Settings.AimAssist and Camera then
        local target = findClosestTarget()
        if target then
            local camPos = Camera.CFrame.Position
            local aimCFrame = CFrame.new(camPos, target.Position)
            Camera.CFrame = Camera.CFrame:Lerp(aimCFrame, Settings.AimSmoothing)
        end
    end
end)

-- Goto player
local function gotoPlayer(player)
    if not player or not player.Character then return false end
    local targetHRP = getRootPart(player.Character)
    if not targetHRP then return false end
    
    local offsetDirs = {Vector3.new(3,0,0), Vector3.new(-3,0,0), Vector3.new(0,0,3), Vector3.new(0,0,-3)}
    local targetPos = targetHRP.Position + offsetDirs[math.random(1, #offsetDirs)]

    if NamecallBypassRemote and isHooked then
        local success = teleportToPosition(targetPos)
        if success then
            dbg("Goto: телепорт к "..player.Name)
            return true
        end
    end

    local approached = pcall(function() 
        return smoothApproach(targetPos) 
    end)
    
    if approached then
        dbg("Goto: подошел к "..player.Name)
        return true
    end
    
    return false
end

-- ============ GUI CREATION (ИСПРАВЛЕНО) ============
dbg("Создание GUI...")

-- Определяем родителя для GUI
local GuiParent = game:GetService("CoreGui")
local testOk = pcall(function()
    local t = Instance.new("ScreenGui")
    t.Name = "UH_Test"
    t.Parent = GuiParent
    task.wait()
    t:Destroy()
end)

if not testOk then 
    dbg("CoreGui недоступен, используем PlayerGui")
    GuiParent = LocalPlayer:WaitForChild("PlayerGui")
end

-- Удаляем старые копии
pcall(function()
    local old = GuiParent:FindFirstChild("UtilityHubGUI")
    if old then old:Destroy() end
end)

task.wait(0.1)

-- Создаем GUI
local ScreenGui = new(GuiParent, "ScreenGui", {
    Name = "UtilityHubGUI",
    ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    DisplayOrder = 999
})

local MainFrame = new(ScreenGui, "Frame", {
    Size = UDim2.new(0, 520, 0, 600),
    Position = UDim2.new(0.5, -260, 0.5, -300),
    BackgroundColor3 = Color3.fromRGB(42, 48, 60),
    BorderSizePixel = 0,
    Visible = true,
    Active = true,
    Draggable = true
})

new(MainFrame, "UICorner", {CornerRadius = UDim.new(0, 12)})

local Header = new(MainFrame, "TextLabel", {
    Size = UDim2.new(1, -24, 0, 40),
    Position = UDim2.new(0, 12, 0, 8),
    BackgroundTransparency = 1,
    Text = "🛠️ Utility Hub (Fixed)",
    TextColor3 = Color3.fromRGB(230, 230, 230),
    Font = Enum.Font.GothamBold,
    TextSize = 18,
    TextXAlignment = Enum.TextXAlignment.Left
})

local CloseBtn = new(MainFrame, "TextButton", {
    Size = UDim2.new(0, 30, 0, 30),
    Position = UDim2.new(1, -40, 0, 10),
    BackgroundColor3 = Color3.fromRGB(200, 50, 50),
    Text = "X",
    TextColor3 = Color3.fromRGB(255, 255, 255),
    Font = Enum.Font.GothamBold,
    TextSize = 16
})
new(CloseBtn, "UICorner", {CornerRadius = UDim.new(0, 8)})
CloseBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = false
end)

local Content = new(MainFrame, "ScrollingFrame", {
    Size = UDim2.new(1, -24, 1, -70),
    Position = UDim2.new(0, 12, 0, 56),
    BackgroundTransparency = 1,
    ScrollBarImageColor3 = Color3.fromRGB(120, 130, 150),
    ScrollBarThickness = 8,
    BorderSizePixel = 0
})

local Layout = new(Content, "UIListLayout", {
    Padding = UDim.new(0, 8),
    SortOrder = Enum.SortOrder.LayoutOrder
})

Content.AutomaticCanvasSize = Enum.AutomaticSize.Y

dbg("GUI создан успешно!")

-- Helper functions для создания элементов
local function createSectionLabel(text)
    local label = new(Content, "TextLabel", {
        Size = UDim2.new(1, 0, 0, 24),
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = Color3.fromRGB(220, 220, 220),
        Font = Enum.Font.GothamBold,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left
    })
    return label
end

local function createToggle(text, initial, callback)
    local frame = new(Content, "Frame", {
        Size = UDim2.new(1, 0, 0, 44),
        BackgroundColor3 = Color3.fromRGB(56, 62, 74)
    })
    new(frame, "UICorner", {CornerRadius = UDim.new(0, 8)})
    
    local label = new(frame, "TextLabel", {
        Text = text,
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        TextSize = 13,
        TextColor3 = Color3.fromRGB(235, 235, 235),
        Position = UDim2.new(0, 12, 0, 0),
        Size = UDim2.new(0.65, 0, 1, 0),
        TextXAlignment = Enum.TextXAlignment.Left
    })
    
    local btn = new(frame, "TextButton", {
        Size = UDim2.new(0, 80, 0, 28),
        Position = UDim2.new(1, -90, 0.5, -14),
        BackgroundColor3 = initial and Color3.fromRGB(0, 160, 230) or Color3.fromRGB(88, 96, 110),
        Text = initial and "ON" or "OFF",
        TextColor3 = Color3.fromRGB(255, 255, 255),
        Font = Enum.Font.GothamBold,
        TextSize = 12
    })
    new(btn, "UICorner", {CornerRadius = UDim.new(0, 6)})
    
    btn.MouseButton1Click:Connect(function()
        local newState = (btn.Text == "OFF")
        btn.Text = newState and "ON" or "OFF"
        btn.BackgroundColor3 = newState and Color3.fromRGB(0, 160, 230) or Color3.fromRGB(88, 96, 110)
        pcall(callback, newState)
    end)
    
    return frame, btn
end

local function createButton(text, callback)
    local frame = new(Content, "Frame", {
        Size = UDim2.new(1, 0, 0, 36),
        BackgroundColor3 = Color3.fromRGB(56, 62, 74)
    })
    new(frame, "UICorner", {CornerRadius = UDim.new(0, 8)})
    
    local btn = new(frame, "TextButton", {
        Size = UDim2.new(1, -12, 1, -8),
        Position = UDim2.new(0, 6, 0, 4),
        Text = text,
        BackgroundColor3 = Color3.fromRGB(80, 100, 140),
        TextColor3 = Color3.fromRGB(240, 240, 240),
        Font = Enum.Font.Gotham,
        TextSize = 13
    })
    new(btn, "UICorner", {CornerRadius = UDim.new(0, 6)})
    
    btn.MouseButton1Click:Connect(function()
        pcall(callback)
    end)
    
    return frame, btn
end

-- Build GUI
dbg("Добавление элементов управления...")

createSectionLabel("⚙️ Основные функции")

local afFrame, afBtn = createToggle("AutoFarm (сбор предметов)", false, function(state)
    Settings.AutoFarm = state
    if state then
        startAutoFarm()
    else
        stopAutoFarm()
    end
end)

local asFrame, asBtn = createToggle("AutoSell (автопродажа)", false, function(state)
    Settings.AutoSell = state
    if state then startAutoSell() else stopAutoSell() end
end)

local alFrame, alBtn = createToggle("Auto Lucky Buy", false, function(state)
    Settings.AutoLuckyBuy = state
    if state then startAutoLuckyBuy() else stopAutoLuckyBuy() end
end)

local apbFrame, apbBtn = createToggle("Auto Perfect Block", false, function(state)
    Settings.AutoPB = state
    if state then startAutoPB() else stopAutoPB() end
end)

createSectionLabel("🎯 Бой")

local aimFrame, aimBtn = createToggle("Aim Assist (автонаведение)", false, function(state)
    Settings.AimAssist = state
end)

local chFrame, chBtn = createToggle("Chams (подсветка игроков)", false, function(state)
    if state then enableChams() else disableChams() end
end)

createSectionLabel("🔧 Утилиты")

createButton("🔍 Сканировать Remotes", function()
    autoResolveRemotes()
    dbg("Сканирование завершено")
end)

createSectionLabel("👥 Игроки")

local playersContainer = new(Content, "Frame", {
    Size = UDim2.new(1, 0, 0, 200),
    BackgroundColor3 = Color3.fromRGB(56, 62, 74)
})
new(playersContainer, "UICorner", {CornerRadius = UDim.new(0, 8)})

local playersScroll = new(playersContainer, "ScrollingFrame", {
    Size = UDim2.new(1, -12, 1, -12),
    Position = UDim2.new(0, 6, 0, 6),
    BackgroundTransparency = 1,
    ScrollBarThickness = 6
})
new(playersScroll, "UIListLayout", {Padding = UDim.new(0, 4)})
playersScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y

local PlayerEntries = {}

local function createPlayerEntry(player)
    if PlayerEntries[player] or player == LocalPlayer then return end
    
    local entry = new(playersScroll, "Frame", {
        Size = UDim2.new(1, -8, 0, 36),
        BackgroundColor3 = Color3.fromRGB(70, 76, 88)
    })
    new(entry, "UICorner", {CornerRadius = UDim.new(0, 6)})
    
    local nameLabel = new(entry, "TextLabel", {
        Text = player.Name,
        BackgroundTransparency = 1,
        TextColor3 = Color3.fromRGB(230, 230, 230),
        Font = Enum.Font.Gotham,
        TextSize = 12,
        Position = UDim2.new(0, 8, 0, 0),
        Size = UDim2.new(0.6, 0, 1, 0),
        TextXAlignment = Enum.TextXAlignment.Left
    })
    
    local
