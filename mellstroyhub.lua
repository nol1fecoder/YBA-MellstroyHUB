-- Utility Hub (LocalScript) - ENHANCED WITH BYPASS
-- Features: Aim Assist, AutoPB, AutoFarm, AutoSell, AutoLuckyBuy, Friend List, Toggle Menu, Clickable Buttons, Scrollable Menu, Persistent Slider, Goto (WITH ANTI-CHEAT BYPASS)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local PathfindingService = game:GetService("PathfindingService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

if not LocalPlayer then
    warn("This script must run as a LocalScript.")
    return
end

-- ==================== NAMECALL HOOK FOR ANTI-CHEAT BYPASS ====================
local OldNamecallTP
local isHooked = false
local NamecallBypassRemote = nil

local function hookTPBypass()
    if not newcclosure or not hookmetamethod then return end
    if isHooked then return end
    
    OldNamecallTP = hookmetamethod(game, '__namecall', newcclosure(function(self, ...)
        local Arguments = {...}
        local Method = getnamecallmethod()
        
        -- Спуфинг InvokeServer для обхода анти-чита
        if Method == "InvokeServer" and Arguments[1] == "idklolbrah2de" then
            return "___XP DE KEY"
        end
        
        return OldNamecallTP(self, ...)
    end))
    isHooked = true
end

pcall(hookTPBypass)

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

-- Settings and state
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

-- Remote candidate names to try auto-resolving
local RemoteCandidates = {
    Sell = {"SellRemote", "SellAll", "SellService", "SellEvent", "Remote_Sell"},
    Buy = {"ShopRemote", "BuyRemote", "PurchaseRemote", "ShopBuy", "Remote_Buy"},
    Item = {"ItemRemote", "PickupRemote", "GiveItem", "CollectRemote"},
    Block = {"BlockRemote", "PBRemote", "BlockEvent", "BlockAction"}
}

local Remotes = { Sell = nil, Buy = nil, Item = nil, Block = nil }

-- Utility functions
local function new(parent, class, props)
    local inst = Instance.new(class)
    if props then
        for k, v in pairs(props) do
            if k == "Parent" then
                inst.Parent = v
            else
                pcall(function() inst[k] = v end)
            end
        end
    end
    if parent and not inst.Parent then inst.Parent = parent end
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
    dbg(("Remotes resolved: Sell=%s Buy=%s Item=%s Block=%s"):format(
        tostring(Remotes.Sell and Remotes.Sell.Name or "nil"),
        tostring(Remotes.Buy and Remotes.Buy.Name or "nil"),
        tostring(Remotes.Item and Remotes.Item.Name or "nil"),
        tostring(Remotes.Block and Remotes.Block.Name or "nil")
    ))
end

local function safeFire(remote, ...)
    if not remote then return false end
    local ok, err = pcall(function() remote:FireServer(...) end)
    if not ok then dbg("safeFire error: "..tostring(err)) end
    return ok
end

local function safeInvoke(remote, ...)
    if not remote then return nil end
    local ok, res = pcall(function() return remote:InvokeServer(...) end)
    if not ok then dbg("safeInvoke error: "..tostring(res)) return nil end
    return res
end

local function getRootPart(character)
    if not character then return nil end
    return character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Torso") or character:FindFirstChild("UpperTorso")
end

local function randomOffset(magnitude)
    magnitude = magnitude or 0.4
    return Vector3.new((math.random()-0.5)*2*magnitude, 0, (math.random()-0.5)*2*magnitude)
end

-- ==================== RESOLVE NAMECALL BYPASS REMOTE ====================
local function resolveNamecallRemote()
    if NamecallBypassRemote then return end
    local char = LocalPlayer.Character
    if not char then return end
    
    NamecallBypassRemote = char:FindFirstChild("RemoteEvent") 
        or char:FindFirstChild("MoveRemote") 
        or char:FindFirstChild("InputRemote") 
        or ReplicatedStorage:FindFirstChild("InputRemote")
    
    if NamecallBypassRemote then
        dbg("NamecallBypassRemote found: "..NamecallBypassRemote:GetFullName())
    end
end

-- ==================== TELEPORT WITH BYPASS ====================
local function teleportToPosition(targetPos)
    local character = LocalPlayer.Character
    local HRP = character and getRootPart(character)
    
    if not HRP or not NamecallBypassRemote or not isHooked then 
        dbg("Teleport bypass not ready")
        return false 
    end
    
    local targetCFrame = CFrame.new(targetPos)
    local finalCFrame = targetCFrame * CFrame.new(0, 1, 0)
    
    pcall(function()
        -- Спуфинг начала движения
        safeFire(NamecallBypassRemote, "InputBegan", {
            Input = Enum.KeyCode.W,
            CFrame = finalCFrame
        })
        
        -- Телепортация
        HRP.CFrame = finalCFrame
        
        -- Спуфинг завершения движения
        safeFire(NamecallBypassRemote, "InputEnded", {
            Input = Enum.KeyCode.W,
        })
        
        dbg("Teleported to: "..tostring(targetPos))
    end)
    
    return true
end

-- Pathfinding & movement (ORIGINAL - NOT REMOVED)
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
        local ok = humanoid.MoveToFinished:Wait()
        return ok and ((hrp.Position - targetPos).Magnitude <= stopDist)
    end

    local waypoints = path:GetWaypoints()
    local lastPos = hrp.Position
    local started = tick()
    for _, wp in ipairs(waypoints) do
        if wp.Action == Enum.PathWaypointAction.Jump then humanoid.Jump = true end
        local wpPos = wp.Position + randomOffset(0.3)
        humanoid:MoveTo(wpPos)
        humanoid.MoveToFinished:Wait()
        if (hrp.Position - targetPos).Magnitude <= stopDist then return true end
        if tick() - started > timeout then return false end
        if (hrp.Position - lastPos).Magnitude < 0.2 and (tick() - started) > (timeout * 0.3) then
            return false
        end
        lastPos = hrp.Position
        task.wait(0.01)
    end
    return (hrp.Position - targetPos).Magnitude <= stopDist
end

local function safeTweenCFrame(part, targetCFrame, duration)
    local ok, t = pcall(function()
        return TweenService:Create(part, TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {CFrame = targetCFrame})
    end)
    if ok and t then
        pcall(function() t:Play() end)
        task.wait(duration + 0.05)
    end
end

local function smoothApproach(targetPos)
    local ok = moveToWithPath(targetPos, Settings.MoveStopDistance, Settings.PathTimeout)
    if ok then return true end
    if not LocalPlayer.Character then return false end
    local hrp = getRootPart(LocalPlayer.Character)
    if not hrp then return false end
    local dist = (hrp.Position - targetPos).Magnitude
    local duration = math.clamp(dist / 28, 0.12, 1.2)
    local tweenOk, err = pcall(function()
        safeTweenCFrame(hrp, CFrame.new(targetPos + randomOffset(0.2), targetPos), duration)
    end)
    if not tweenOk then dbg("smoothApproach tween error: "..tostring(err)) end
    hrp = getRootPart(LocalPlayer.Character)
    return hrp and ((hrp.Position - targetPos).Magnitude <= Settings.MoveStopDistance)
end

-- Proximity prompt interaction (ORIGINAL - NOT REMOVED)
local function interactPrompt(prompt)
    if not prompt then return false end
    if typeof(fireproximityprompt) == "function" then
        pcall(function() fireproximityprompt(prompt, 1) end)
        return true
    end
    if prompt:IsA("ProximityPrompt") then
        pcall(function()
            if prompt.InputHoldBegin and prompt.InputHoldEnd then
                prompt:InputHoldBegin()
                task.wait(0.05)
                prompt:InputHoldEnd()
            else
                prompt:InputHoldEnd()
            end
        end)
        return true
    end
    return false
end

-- Scanning items for AutoFarm (ORIGINAL - NOT REMOVED)
local function scanForPickups()
    local items = {}
    local containers = {}
    if workspace:FindFirstChild("Item_Spawns") then table.insert(containers, workspace.Item_Spawns) end
    if workspace:FindFirstChild("Items") then table.insert(containers, workspace.Items) end
    table.insert(containers, workspace)

    local function considerModel(m)
        if not m then return end
        if items[m] then return end
        local primary = m.PrimaryPart or m:FindFirstChildWhichIsA("BasePart")
        local prompt = nil
        for _, d in ipairs(m:GetDescendants()) do
            if d:IsA("ProximityPrompt") then
                prompt = d
                break
            end
        end
        if primary and prompt then
            items[m] = {Model = m, Primary = primary, Prompt = prompt}
            return
        end
        if m:IsA("BasePart") then
            local p = m:FindFirstChildWhichIsA("ProximityPrompt")
            if p then
                items[m] = {Model = m, Primary = m, Prompt = p}
            end
        end
    end

    for _, container in ipairs(containers) do
        if container and container:IsA and container:IsA("Instance") then
            for _, obj in ipairs(container:GetDescendants()) do
                if obj:IsA("Model") then
                    considerModel(obj)
                elseif obj:IsA("BasePart") and obj:FindFirstChildWhichIsA("ProximityPrompt") then
                    considerModel(obj)
                elseif obj:IsA("ProximityPrompt") then
                    local mdl = obj.Parent and obj.Parent:FindFirstAncestorWhichIsA("Model")
                    if mdl then considerModel(mdl) else considerModel(obj.Parent) end
                end
            end
        end
    end

    return items
end

-- Auto loops (ORIGINAL - NOT REMOVED, ALL FEATURES INTACT)
local autoFarmThread
local function startAutoFarm()
    if autoFarmThread then return end
    autoFarmThread = task.spawn(function()
        dbg("AutoFarm started")
        while Settings.AutoFarm do
            if not LocalPlayer.Character then
                task.wait(0.5)
            else
                local hrp = getRootPart(LocalPlayer.Character)
                if hrp then
                    local items = scanForPickups()
                    for model, info in pairs(items) do
                        if not Settings.AutoFarm then break end
                        if not model or not info.Primary or not info.Prompt or not info.Primary.Parent then
                            items[model] = nil
                        else
                            local pos = info.Primary.Position
                            local approached = false
                            local ok, err = pcall(function() approached = smoothApproach(pos) end)
                            if not ok then
                                dbg("AutoFarm: smoothApproach pcall error: "..tostring(err))
                                approached = false
                            end
                            if approached then
                                pcall(function() interactPrompt(info.Prompt) end)
                                task.wait(0.08 + math.random() * 0.08)
                            end
                        end
                        task.wait(0.04)
                    end
                end
                task.wait(Settings.AutoFarmScanInterval)
            end
        end
        dbg("AutoFarm stopped")
        autoFarmThread = nil
    end)
end

local function stopAutoFarm()
    Settings.AutoFarm = false
    autoFarmThread = nil
end

local autoSellThread
local function attemptSellViaRemote()
    if Remotes.Sell then
        local ok = safeFire(Remotes.Sell, "SellAll")
        if ok then return true end
        ok = safeFire(Remotes.Sell, "Sell")
        if ok then return true end
        ok = safeFire(Remotes.Sell, "SellEverything")
        if ok then return true end
        pcall(function() Remotes.Sell:FireServer() end)
        return true
    end
    return false
end

local function startAutoSell()
    if autoSellThread then return end
    autoSellThread = task.spawn(function()
        dbg("AutoSell started")
        while Settings.AutoSell do
            local did = false
            if attemptSellViaRemote() then
                did = true
                dbg("AutoSell: remote fired")
            else
                local hrp = LocalPlayer.Character and getRootPart(LocalPlayer.Character)
                if hrp then
                    for _, obj in ipairs(workspace:GetDescendants()) do
                        if obj:IsA("ProximityPrompt") then
                            local text = tostring(obj.ObjectText or obj.Name or ""):lower()
                            if string.find(text, "sell") or string.find(text, "vendor") or string.find(text, "merchant") then
                                local parentPart = obj.Parent
                                if parentPart and parentPart:IsA("BasePart") then
                                    if (parentPart.Position - hrp.Position).Magnitude < Settings.PromptSearchDistance then
                                        local okApproach = smoothApproach(parentPart.Position)
                                        if okApproach then
                                            interactPrompt(obj)
                                            did = true
                                            dbg("AutoSell: used prompt at "..parentPart:GetFullName())
                                            break
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
            if not did then dbg("AutoSell: nothing found this cycle") end
            task.wait(Settings.AutoSellInterval + math.random() * 0.6)
        end
        dbg("AutoSell stopped")
        autoSellThread = nil
    end)
end

local function stopAutoSell()
    Settings.AutoSell = false
    autoSellThread = nil
end

local autoLuckyThread
local function attemptBuyViaRemote()
    if Remotes.Buy then
        local ok = safeFire(Remotes.Buy, "BuyItem", "Lucky")
        if ok then return true end
        ok = safeFire(Remotes.Buy, "Buy", "Lucky")
        if ok then return true end
        ok = safeFire(Remotes.Buy, "Purchase", "Lucky")
        if ok then return true end
        pcall(function() Remotes.Buy:FireServer() end)
        return true
    end
    return false
end

local function startAutoLuckyBuy()
    if autoLuckyThread then return end
    autoLuckyThread = task.spawn(function()
        dbg("AutoLuckyBuy started")
        while Settings.AutoLuckyBuy do
            local did = false
            if attemptBuyViaRemote() then
                did = true
                dbg("AutoLuckyBuy: remote fired")
            else
                for _, obj in ipairs(workspace:GetDescendants()) do
                    if obj:IsA("ProximityPrompt") then
                        local text = tostring(obj.ObjectText or obj.Name or ""):lower()
                        if string.find(text, "lucky") or string.find(text, "gacha") or string.find(text, "crate") then
                            local parentPart = obj.Parent
                            if parentPart and parentPart:IsA("BasePart") then
                                local okApproach = smoothApproach(parentPart.Position)
                                if okApproach then
                                    interactPrompt(obj)
                                    did = true
                                    dbg("AutoLuckyBuy: used prompt at "..parentPart:GetFullName())
                                    break
                                end
                            end
                        end
                    end
                end
            end
            if not did then dbg("AutoLuckyBuy: nothing found this cycle") end
            task.wait(Settings.AutoLuckyInterval + math.random() * 0.6)
        end
        dbg("AutoLuckyBuy stopped")
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
        dbg("AutoPB started")
        while Settings.AutoPB do
            if not Remotes.Block then
                Remotes.Block = tryResolveRemoteByNames(RemoteCandidates.Block)
            end
            local did = false
            if Remotes.Block then
                pcall(function() Remotes.Block:FireServer("StartBlock") end)
                did = true
            else
                local humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                if humanoid then
                    local original = humanoid.WalkSpeed
                    humanoid.WalkSpeed = math.max(4, (original or 16) * 0.45)
                    task.wait(0.06 + math.random() * 0.08)
                    if humanoid then humanoid.WalkSpeed = original end
                    did = true
                end
            end
            if not did then dbg("AutoPB: no action this tick") end
            task.wait(Settings.AutoPBInterval + math.random() * 0.03)
        end
        dbg("AutoPB stopped")
        autoPBThread = nil
    end)
end

local function stopAutoPB()
    Settings.AutoPB = false
    autoPBThread = nil
end

-- Chams (Highlights) - ORIGINAL, NOT REMOVED
local Highlights = {}
local function setupHighlightForPlayer(player)
    if player == LocalPlayer then return end
    if Highlights[player] then
        pcall(function() Highlights[player]:Destroy() end)
        Highlights[player] = nil
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
    player.CharacterAdded:Connect(function()
        if Settings.Chams then
            task.delay(0.05, function() setupHighlightForPlayer(player) end)
        end
    end)
end

local function enableChams()
    Settings.Chams = true
    for _, p in ipairs(Players:GetPlayers()) do setupHighlightForPlayer(p) end
    Players.PlayerAdded:Connect(setupHighlightForPlayer)
    Players.PlayerRemoving:Connect(function(pl)
        if Highlights[pl] then
            pcall(function() Highlights[pl]:Destroy() end)
            Highlights[pl] = nil
        end
    end)
end

local function disableChams()
    Settings.Chams = false
    for _, hl in pairs(Highlights) do
        pcall(function() hl:Destroy() end)
    end
    Highlights = {}
end

-- Aim Assist - ORIGINAL, NOT REMOVED
local function findClosestTarget()
    local myHRP = LocalPlayer.Character and getRootPart(LocalPlayer.Character)
    if not myHRP then return nil end
    local best = nil
    local bestDist = Settings.AimFOV
    for _, pl in ipairs(Players:GetPlayers()) do
        if pl ~= LocalPlayer and pl.Character and pl.Character:FindFirstChildOfClass("Humanoid") and pl.Character.Humanoid.Health > 0 then
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

-- Friend list utilities - ORIGINAL, NOT REMOVED
local function isFriendWithLocal(player)
    if not player or not player.UserId then return false end
    local ok, res = pcall(function() return LocalPlayer:IsFriendsWith(player.UserId) end)
    if ok then return res else return false end
end

-- ==================== IMPROVED GOTO WITH BYPASS ====================
local function gotoPlayer(player)
    if not player or not player.Character then
        dbg("Goto failed: target invalid")
        return false
    end
    local targetHRP = getRootPart(player.Character)
    if not targetHRP then
        dbg("Goto failed: target has no root part")
        return false
    end
    if not LocalPlayer.Character then
        dbg("Goto failed: local character missing")
        return false
    end

    local offsetDirs = {Vector3.new(3,0,0), Vector3.new(-3,0,0), Vector3.new(0,0,3), Vector3.new(0,0,-3)}
    local chosenOffset = offsetDirs[math.random(1, #offsetDirs)]
    local targetPos = targetHRP.Position + chosenOffset

    -- ===== НОВЫЙ МЕТОД: ИСПОЛЬЗУЕМ BYPASS ТЕЛЕПОРТАЦИЮ =====
    if NamecallBypassRemote and isHooked then
        dbg("Using bypass teleport for Goto")
        local success = teleportToPosition(targetPos)
        if success then
            dbg("Goto: teleported to "..player.Name.." using bypass")
            return true
        else
            dbg("Goto: bypass teleport failed, trying pathfinding")
        end
    end

    -- Fallback: старый метод с pathfinding (если bypass недоступен)
    local humanoid = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    local originalSpeed
    if humanoid then
        originalSpeed = humanoid.WalkSpeed
        humanoid.WalkSpeed = math.clamp((originalSpeed or 16) * 1.6, 12, 60)
    end

    local approached = false
    local ok, err = pcall(function()
        approached = smoothApproach(targetPos)
    end)
    if not ok then
        dbg("gotoPlayer: smoothApproach pcall error: "..tostring(err))
        approached = false
    end

    if humanoid and originalSpeed then
        humanoid.WalkSpeed = originalSpeed
    end

    if approached then
        dbg("Goto: approached "..player.Name)
        return true
    else
        dbg("Goto: failed to approach "..player.Name)
        return false
    end
end

-- GUI creation (ORIGINAL - ALL INTACT, NOT REMOVED)
local GuiParent = CoreGui
local testOk = pcall(function()
    local t = Instance.new("ScreenGui")
    t.Name = "UH_Test"
    t.Parent = GuiParent
    t:Destroy()
end)
if not testOk then GuiParent = LocalPlayer:WaitForChild("PlayerGui") end

local ScreenGui = new(GuiParent, "ScreenGui", {Name = "UtilityHubGUI", ResetOnSpawn = false})
local MainFrame = new(ScreenGui, "Frame", {
    Size = UDim2.new(0, 520, 0, 740),
    Position = UDim2.new(0.5, -260, 0.5, -370),
    BackgroundColor3 = Color3.fromRGB(42, 48, 60),
    BorderSizePixel = 0,
    Visible = true
})
new(MainFrame, "UICorner", {CornerRadius = UDim.new(0, 12)})
new(MainFrame, "UIStroke", {Color = Color3.fromRGB(60, 68, 82), Thickness = 1, Transparency = 0.7})

local Header = new(MainFrame, "TextLabel", {
    Size = UDim2.new(1, -24, 0, 48),
    Position = UDim2.new(0, 12, 0, 8),
    BackgroundTransparency = 1,
    Text = "Utility Hub (Enhanced Goto)",
    TextColor3 = Color3.fromRGB(230, 230, 230),
    Font = Enum.Font.GothamBold,
    TextSize = 20,
    TextXAlignment = Enum.TextXAlignment.Left
})

local Content = new(MainFrame, "ScrollingFrame", {
    Size = UDim2.new(1, -24, 1, -88),
    Position = UDim2.new(0, 12, 0, 56),
    BackgroundTransparency = 1,
    ScrollBarImageColor3 = Color3.fromRGB(120, 130, 150),
    ScrollBarThickness = 10
})
new(Content, "UIListLayout", {Padding = UDim.new(0, 8)})
Content.AutomaticCanvasSize = Enum.AutomaticSize.Y

local function createSectionLabel(text)
    return new(Content, "TextLabel", {
        Size = UDim2.new(1, 0, 0, 22),
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = Color3.fromRGB(220, 220, 220),
        Font = Enum.Font.GothamBold,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left
    })
end

local function createToggle(text, initial, callback)
    local frame = new(Content, "Frame", {Size = UDim2.new(1, 0, 0, 44), BackgroundColor3 = Color3.fromRGB(56, 62, 74)})
    new(frame, "UICorner", {CornerRadius = UDim.new(0, 8)})
    new(frame, "UIStroke", {Color = Color3.fromRGB(70, 78, 92), Thickness = 1, Transparency = 0.7})
    new(frame, "TextLabel", {
        Text = text,
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        TextSize = 14,
        TextColor3 = Color3.fromRGB(235,235,235),
        Position = UDim2.new(0, 12, 0, 8),
        Size = UDim2.new(0.7, -12, 1, -16),
        TextXAlignment = Enum.TextXAlignment.Left
    })
    local btn = new(frame, "TextButton", {
        Size = UDim2.new(0, 96, 0, 28),
        Position = UDim2.new(1, -110, 0.5, -14),
        BackgroundColor3 = initial and Color3.fromRGB(0,160,230) or Color3.fromRGB(88, 96, 110),
        Text = initial and "ON" or "OFF",
        TextColor3 = Color3.fromRGB(20,20,20),
        AutoButtonColor = false
    })
    new(btn, "UICorner", {CornerRadius = UDim.new(0, 8)})
    btn.MouseButton1Click:Connect(function()
        local newState = not (btn.Text == "ON")
        btn.Text = newState and "ON" or "OFF"
        btn.BackgroundColor3 = newState and Color3.fromRGB(0,160,230) or Color3.fromRGB(88,96,110)
        pcall(function() callback(newState) end)
    end)
    return frame, btn
end

local function createButton(text, fn)
    local frame = new(Content, "Frame", {Size = UDim2.new(1, 0, 0, 40), BackgroundColor3 = Color3.fromRGB(56,62,74)})
    new(frame, "UICorner", {CornerRadius = UDim.new(0, 8)})
    new(frame, "UIStroke", {Color = Color3.fromRGB(70,78,92), Thickness = 1, Transparency = 0.7})
    local btn = new(frame, "TextButton", {
        Size = UDim2.new(1, -16, 1, -12),
        Position = UDim2.new(0, 8, 0, 6),
        Text = text,
        BackgroundColor3 = Color3.fromRGB(92, 100, 116),
        TextColor3 = Color3.fromRGB(240,240,240),
        Font = Enum.Font.Gotham,
        TextSize = 14
    })
    new(btn, "UICorner", {CornerRadius = UDim.new(0, 8)})
    btn.MouseButton1Click:Connect(function() pcall(fn) end)
    return frame, btn
end

local function createSlider(text, min, max, default, callback)
    local frame = new(Content, "Frame", {Size = UDim2.new(1, 0, 0, 66), BackgroundColor3 = Color3.fromRGB(56,62,74)})
    new(frame, "UICorner", {CornerRadius = UDim.new(0, 8)})
    new(frame, "UIStroke", {Color = Color3.fromRGB(70,78,92), Thickness = 1, Transparency = 0.7})
    new(frame, "TextLabel", {Text = text, BackgroundTransparency = 1, TextColor3 = Color3.fromRGB(235,235,235), Font = Enum.Font.Gotham, TextSize = 13, Position = UDim2.new(0, 12, 0, 8)})
    local valueLabel = new(frame, "TextLabel", {Text = tostring(default), BackgroundTransparency = 1, TextColor3 = Color3.fromRGB(200,200,200), Font = Enum.Font.GothamBold, TextSize = 13, Position = UDim2.new(1, -66, 0, 8), Size = UDim2.new(0, 54, 0, 18)})
    local back = new(frame, "Frame", {Size = UDim2.new(1, -24, 0, 12), Position = UDim2.new(0, 12, 0, 36), BackgroundColor3 = Color3.fromRGB(80,88,100)})
    new(back, "UICorner", {CornerRadius = UDim.new(1, 0)})
    local fill = new(back, "Frame", {Size = UDim2.new((default - min) / (max - min), 0, 1, 0), BackgroundColor3 = Color3.fromRGB(0,160,230)})
    new(fill, "UICorner", {CornerRadius = UDim.new(1, 0)})

    local dragging = false

    back.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            UserInputService.MouseIconEnabled = true
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local abs = back.AbsolutePosition
            local mx = UserInputService:GetMouseLocation().X
            local rel = math.clamp((mx - abs.X) / back.AbsoluteSize.X, 0, 1)
            fill.Size = UDim2.new(rel, 0, 1, 0)
            local val = math.floor(min + rel * (max - min))
            valueLabel.Text = tostring(val)
            pcall(function() callback(val) end)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
            UserInputService.MouseIconEnabled = true
        end
    end)

    local function refresh()
        local cur = tonumber(valueLabel.Text) or default
        local rel = (cur - min) / math.max(1, (max - min))
        fill.Size = UDim2.new(math.clamp(rel, 0, 1), 0, 1, 0)
    end

    ScreenGui:GetPropertyChangedSignal("AbsoluteSize"):Connect(refresh)
    Content:GetPropertyChangedSignal("AbsoluteSize"):Connect(refresh)
    task.spawn(function()
        while ScreenGui and ScreenGui.Parent do
            refresh()
            task.wait(0.9)
        end
    end)

    return frame, valueLabel
end

-- Build GUI controls (ALL ORIGINAL FEATURES)
createSectionLabel("Core")
local afFrame, afBtn = createToggle("AutoFarm (collect items)", false, function(state)
    Settings.AutoFarm = state
    if state then
        local humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            Settings.DefaultWalkspeed = humanoid.WalkSpeed or Settings.DefaultWalkspeed
            humanoid.WalkSpeed = Settings.AutoFarmWalkspeed
        end
        startAutoFarm()
    else
        stopAutoFarm()
        local humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if humanoid then humanoid.WalkSpeed = Settings.DefaultWalkspeed end
    end
end)

local asFrame, asBtn = createToggle("AutoSell", false, function(state)
    Settings.AutoSell = state
    if state then startAutoSell() else stopAutoSell() end
end)

local alFrame, alBtn = createToggle("Auto Lucky Buy", false, function(state)
    Settings.AutoLuckyBuy = state
    if state then startAutoLuckyBuy() else stopAutoLuckyBuy() end
end)

local apbFrame, apbBtn = createToggle("Auto Perfect Block (safe)", false, function(state)
    Settings.AutoPB = state
    if state then startAutoPB() else stopAutoPB() end
end)

local aimFrame, aimBtn = createToggle("Aim Assist", false, function(state)
    Settings.AimAssist = state
end)

local sliderFrame, sliderValue = createSlider("Aim FOV (studs)", 30, 600, Settings.AimFOV, function(val)
    Settings.AimFOV = val
end)
createSlider("Aim Smoothing (0-100)", 0, 100, math.floor(Settings.AimSmoothing * 100), function(val)
    Settings.AimSmoothing = math.clamp(val / 100, 0, 1)
end)

local chFrame, chBtn = createToggle("Chams (Highlight players)", false, function(state)
    Settings.Chams = state
    if state then enableChams() else disableChams() end
end)

createSectionLabel("Remotes & Tools")
createButton("Scan ReplicatedStorage for Remotes", function()
    local found = {}
    for _, o in ipairs(ReplicatedStorage:GetDescendants()) do
        if isRemoteObject(o) then found[o:GetFullName()] = true end
    end
    local count = 0 for _ in pairs(found) do count = count + 1 end
    dbg("ReplicatedStorage remotes found: "..tostring(count))
end)
createButton("Auto Resolve Common Remotes", function() autoResolveRemotes() end)

createSectionLabel("Players / Friends (Enhanced Goto)")
local playersContainer = new(Content, "Frame", {Size = UDim2.new(1,0,0,260), BackgroundTransparency = 1})
local playersScroll = new(playersContainer, "ScrollingFrame", {Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1, ScrollBarThickness = 8})
new(playersScroll, "UIListLayout", {Padding = UDim.new(0,6)})
playersScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y

local PlayerEntries = {}
local LocalSavedFriends = {}

local function updateSavedFriendsLabel()
end

local function createPlayerEntry(player)
    if PlayerEntries[player] then return end
    local entry = new(playersScroll, "Frame", {Size = UDim2.new(1, -8, 0, 44), BackgroundColor3 = Color3.fromRGB(56,62,74)})
    new(entry, "UICorner", {CornerRadius = UDim.new(0,6)})
    new(entry, "UIStroke", {Color = Color3.fromRGB(70,78,92), Thickness = 1, Transparency = 0.7})

    local gotoBtn = new(entry, "TextButton", {Text = "Goto", Size = UDim2.new(0, 58, 0, 28), Position = UDim2.new(0, 6, 0.5, -14), BackgroundColor3 = Color3.fromRGB(90, 140, 200), TextColor3 = Color3.fromRGB(20,20,20)})
    new(gotoBtn, "UICorner", {CornerRadius = UDim.new(0,6)})

    local nameLabel = new(entry, "TextLabel", {Text = player.Name, BackgroundTransparency = 1, TextColor3 = Color3.fromRGB(230,230,230), Font = Enum.Font.Gotham, TextSize = 13, Position = UDim2.new(0, 74, 0, 0), Size = UDim2.new(0.45,0,1,0), TextXAlignment = Enum.TextXAlignment.Left})

    local friendBadge = new(entry, "TextLabel", {Text = "", BackgroundTransparency = 1, TextColor3 = Color3.fromRGB(180,180,180), Font = Enum.Font.Gotham, TextSize = 12, Position = UDim2.new(0.52, 8, 0, 0), Size = UDim2.new(0.22, 0, 1, 0)})

    local addBtn = new(entry, "TextButton", {Text = "Add", Size = UDim2.new(0, 58, 0, 28), Position = UDim2.new(1, -70, 0.5, -14), BackgroundColor3 = Color3.fromRGB(120, 180, 120), TextColor3 = Color3.fromRGB(20,20,20)})
    new(addBtn, "UICorner", {CornerRadius = UDim.new(0,6)})

    gotoBtn.MouseButton1Click:Connect(function()
        task.spawn(function()
            if player and player.Character then
                local ok = gotoPlayer(player)
                if not ok then dbg("Goto button: failed to reach "..tostring(player.Name)) end
            else
                dbg("Goto button: player or character not present")
            end
        end)
    end)

    addBtn.MouseButton1Click:Connect(function()
        if not LocalSavedFriends[player.UserId] then
            LocalSavedFriends[player.UserId] = {Name = player.Name, Time = tick()}
            addBtn.Text = "Added"
            addBtn.BackgroundColor3 = Color3.fromRGB(180, 200, 120)
            dbg("Added "..player.Name.." to local favorites")
        else
            LocalSavedFriends[player.UserId] = nil
            addBtn.Text = "Add"
            addBtn.BackgroundColor3 = Color3.fromRGB(120, 180, 120)
            dbg("Removed "..player.Name.." from local favorites")
        end
        updateSavedFriendsLabel()
    end)

    PlayerEntries[player] = {Frame = entry, Badge = friendBadge, Goto = gotoBtn, Add = addBtn}
    local function updateBadge()
        local ok, res = pcall(function() return LocalPlayer:IsFriendsWith(player.UserId) end)
        if ok and res then
            friendBadge.Text = "Friend"
            friendBadge.TextColor3 = Color3.fromRGB(120, 220, 140)
        else
            friendBadge.Text = ""
        end
    end
    updateBadge()
    player.Changed:Connect(function() updateBadge() end)
end

local function removePlayerEntry(player)
    local e = PlayerEntries[player]
    if e and e.Frame then
        pcall(function() e.Frame:Destroy() end)
    end
    PlayerEntries[player] = nil
    if player and player.UserId and LocalSavedFriends[player.UserId] then
        LocalSavedFriends[player.UserId] = nil
    end
end

for _, p in ipairs(Players:GetPlayers()) do
    if p ~= LocalPlayer then createPlayerEntry(p) end
end
Players.PlayerAdded:Connect(function(pl) if pl ~= LocalPlayer then createPlayerEntry(pl) end end)
Players.PlayerRemoving:Connect(removePlayerEntry)

createSectionLabel("Debug Log")
local logFrame = new(Content, "Frame", {Size = UDim2.new(1,0,0,220), BackgroundColor3 = Color3.fromRGB(48,54,66)})
new(logFrame, "UICorner", {CornerRadius = UDim.new(0,8)})
local logScroll = new(logFrame, "ScrollingFrame", {Size = UDim2.new(1, -16, 1, -16), Position = UDim2.new(0,8,0,8), BackgroundTransparency = 1, ScrollBarThickness = 8})
new(logScroll, "UIListLayout", {Padding = UDim.new(0,6)})
logScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y

local function refreshGuiLog()
    for _, c in ipairs(logScroll:GetChildren()) do if c:IsA("TextLabel") then c:Destroy() end end
    local startIdx = math.max(1, #GuiLogBuffer - 150)
    for i = startIdx, #GuiLogBuffer do
        new(logScroll, "TextLabel", {Text = GuiLogBuffer[i], BackgroundTransparency = 1, TextColor3 = Color3.fromRGB(200,200,200), Font = Enum.Font.Gotham, TextSize = 12, Size = UDim2.new(1, 0, 0, 16)})
    end
end

task.spawn(function()
    while ScreenGui and ScreenGui.Parent do
        refreshGuiLog()
        task.wait(0.8)
    end
end)

-- Keyboard shortcuts (ALL ORIGINAL)
UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
    local key = input.KeyCode
    if key == Settings.Keybinds.ToggleMenu then
        MainFrame.Visible = not MainFrame.Visible
    elseif key == Settings.Keybinds.ToggleAutoFarm then
        afBtn:CaptureFocus()
        Settings.AutoFarm = not Settings.AutoFarm
        afBtn.Text = Settings.AutoFarm and "ON" or "OFF"
        afBtn.BackgroundColor3 = Settings.AutoFarm and Color3.fromRGB(0,160,230) or Color3.fromRGB(88,96,110)
        if Settings.AutoFarm then startAutoFarm() else stopAutoFarm() end
    elseif key == Settings.Keybinds.ToggleAutoSell then
        asBtn:CaptureFocus()
        Settings.AutoSell = not Settings.AutoSell
        asBtn.Text = Settings.AutoSell and "ON" or "OFF"
        asBtn.BackgroundColor3 = Settings.AutoSell and Color3.fromRGB(0,160,230) or Color3.fromRGB(88,96,110)
        if Settings.AutoSell then startAutoSell() else stopAutoSell() end
    elseif key == Settings.Keybinds.ToggleLucky then
        alBtn:CaptureFocus()
        Settings.AutoLuckyBuy = not Settings.AutoLuckyBuy
        alBtn.Text = Settings.AutoLuckyBuy and "ON" or "OFF"
        alBtn.BackgroundColor3 = Settings.AutoLuckyBuy and Color3.fromRGB(0,160,230) or Color3.fromRGB(88,96,110)
        if Settings.AutoLuckyBuy then startAutoLuckyBuy() else stopAutoLuckyBuy() end
    elseif key == Settings.Keybinds.TogglePB then
        apbBtn:CaptureFocus()
        Settings.AutoPB = not Settings.AutoPB
        apbBtn.Text = Settings.AutoPB and "ON" or "OFF"
        apbBtn.BackgroundColor3 = Settings.AutoPB and Color3.fromRGB(0,160,230) or Color3.fromRGB(88,96,110)
        if Settings.AutoPB then startAutoPB() else stopAutoPB() end
    elseif key == Settings.Keybinds.ToggleAim then
        aimBtn:CaptureFocus()
        Settings.AimAssist = not Settings.AimAssist
        aimBtn.Text = Settings.AimAssist and "ON" or "OFF"
        aimBtn.BackgroundColor3 = Settings.AimAssist and Color3.fromRGB(0,160,230) or Color3.fromRGB(88,96,110)
    end
end)

-- Sync walk speed on respawn
LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(0.2)
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if humanoid then
        Settings.DefaultWalkspeed = humanoid.WalkSpeed or Settings.DefaultWalkspeed
        if Settings.AutoFarm then humanoid.WalkSpeed = Settings.AutoFarmWalkspeed end
    end
    -- Resolve bypass remote on respawn
    resolveNamecallRemote()
end)

-- Initial resolve
autoResolveRemotes()
resolveNamecallRemote()

dbg("Utility Hub loaded with enhanced Goto bypass.")
dbg("Bypass hook status: "..(isHooked and "ACTIVE" or "INACTIVE"))
