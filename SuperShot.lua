--[[
    超级射击 · v4 模块化版
    第1段/共4段 — 公共底座 (必须最先执行)
    提供: 通知 / 悬浮球工厂 / 模块注册 / 全局卸载
    第2段=透视  第3段=静默瞄准  第4段=飞行
    每个功能段可单独执行, 也可以按 1→2→3→4 全粘 = 合体完整版
    注意: 重新执行第1段会清掉已加载的功能模块, 需重新执行
]]

if getgenv().SuperShotUnload then pcall(getgenv().SuperShotUnload) end

local Players      = game:GetService("Players")
local RunService   = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer

local SS = {
    BallRefs = {},   -- [label] = {frame, refresh}
    Unloads  = {},   -- 各功能模块的卸载函数
}
getgenv().SuperShot = SS

-- 球布局 (改这里)
local BallLayout = {
    StartX = 0.90,
    StartY = 0.28,
    Gap    = 0.12,
    Size   = 52,
    SmallSize = 44,
}

-- ---------- 通知 ----------
function getgenv().SuperShotNotify(text, duration)
    duration = duration or 2
    local ok = pcall(function()
        local gui = Instance.new("ScreenGui")
        gui.Name = "SuperShot_Notify_" .. tostring(math.random(1e6))
        gui.ResetOnSpawn = false
        gui.Parent = LocalPlayer:WaitForChild("PlayerGui")
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(0, 340, 0, 30)
        label.Position = UDim2.new(1, -360, 1, -60)
        label.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
        label.BackgroundTransparency = 0.25
        label.TextColor3 = Color3.fromRGB(255, 255, 255)
        label.Font = Enum.Font.GothamBold
        label.TextSize = 14
        label.Text = text
        label.Parent = gui
        task.delay(duration, function() gui:Destroy() end)
    end)
    if not ok then print("[SuperShot] " .. text) end
end
local notify = getgenv().SuperShotNotify

-- ---------- 悬浮球工厂 (功能模块共用) ----------
-- 点击 = 开关, 按住拖动 = 移动, 传 holdSet 时按住生效
function getgenv().SuperShotMakeBall(order, label, onToggle, getState, colors, small, holdSet)
    local size = small and BallLayout.SmallSize or BallLayout.Size

    -- 同名球已存在 → 先清掉 (模块重执行时替换)
    local old = SS.BallRefs[label]
    if old then pcall(function() old.frame.Parent:Destroy() end) end

    local holder = Instance.new("ScreenGui")
    holder.Name = "SuperShot_Ball_" .. label
    holder.ResetOnSpawn = false
    holder.DisplayOrder = 100 + order
    holder.IgnoreGuiInset = true
    holder.Parent = LocalPlayer:WaitForChild("PlayerGui")

    local frame = Instance.new("Frame")
    frame.Name = "Ball"
    frame.Size = UDim2.fromOffset(size, size)
    frame.Position = UDim2.new(BallLayout.StartX, 0, BallLayout.StartY + order * BallLayout.Gap, 0)
    frame.BackgroundColor3 = colors.off
    frame.BackgroundTransparency = 0.15
    frame.BorderSizePixel = 0
    frame.Parent = holder

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = frame

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(255, 255, 255)
    stroke.Transparency = 0.6
    stroke.Thickness = 1.5
    stroke.Parent = frame

    local text = Instance.new("TextLabel")
    text.Size = UDim2.fromScale(1, 1)
    text.BackgroundTransparency = 1
    text.Font = Enum.Font.GothamBold
    text.TextSize = small and 18 or 22
    text.TextColor3 = Color3.fromRGB(255, 255, 255)
    text.Text = label
    text.Parent = frame

    local stateLabel = Instance.new("TextLabel")
    stateLabel.Size = UDim2.new(0, size, 0, 14)
    stateLabel.Position = UDim2.new(0, 0, 1, 2)
    stateLabel.BackgroundTransparency = 1
    stateLabel.Font = Enum.Font.Gotham
    stateLabel.TextSize = 11
    stateLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
    stateLabel.TextStrokeTransparency = 0.4
    stateLabel.Text = small and "" or "关"
    stateLabel.Parent = frame

    local function refresh()
        if getState then
            local on = getState()
            frame.BackgroundColor3 = on and colors.on or colors.off
            stateLabel.Text = on and "开" or "关"
            stateLabel.TextColor3 = on and colors.on or Color3.fromRGB(180, 180, 180)
        end
    end

    local dragging = false
    local dragStart, startPos
    local moved = false

    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch
            or input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            moved = false
            dragStart = input.Position
            startPos = frame.Position
            if holdSet then
                holdSet(true)
                refresh()
            end
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                    if holdSet then
                        holdSet(false)
                        refresh()
                    end
                    if not moved and onToggle then
                        onToggle()
                        refresh()
                    end
                end
            end)
        end
    end)

    frame.InputChanged:Connect(function(input)
        if dragging
            and (input.UserInputType == Enum.UserInputType.Touch
                or input.UserInputType == Enum.UserInputType.MouseMovement) then
            local delta = input.Position - dragStart
            if math.abs(delta.X) > 8 or math.abs(delta.Y) > 8 then
                moved = true
            end
            local cam = workspace.CurrentCamera
            local absX = math.clamp(startPos.X.Offset + delta.X, 0, cam.ViewportSize.X - size)
            local absY = math.clamp(startPos.Y.Offset + delta.Y, 0, cam.ViewportSize.Y - size)
            frame.Position = UDim2.new(0, absX, 0, absY)
        end
    end)

    SS.BallRefs[label] = { frame = frame, refresh = refresh }
    refresh()
    return frame
end

-- ---------- 模块注册 ----------
function getgenv().SuperShotRegister(name, unloadFn)
    table.insert(SS.Unloads, unloadFn)
    print("[SuperShot] 模块已注册: " .. name)
end

-- ---------- 球状态自动刷新 ----------
SS.TickConn = RunService.RenderStepped:Connect(function()
    for _, ref in pairs(SS.BallRefs) do
        pcall(ref.refresh)
    end
end)

-- ---------- 全局卸载 ----------
getgenv().SuperShotUnload = function()
    for _, fn in ipairs(SS.Unloads) do
        pcall(fn)
    end
    for _, ref in pairs(SS.BallRefs) do
        pcall(function() ref.frame.Parent:Destroy() end)
    end
    SS.BallRefs = {}
    SS.Unloads = {}
    if SS.TickConn then
        pcall(function() SS.TickConn:Disconnect() end)
        SS.TickConn = nil
    end
    notify("[SuperShot] 已全部卸载 (hook 重进游戏彻底还原)")
end

notify("[SuperShot] 底座加载完成 | 可执行第2/3/4段", 2)
print("[SuperShot] base loaded — v4 模块化")

--[[
    第2段/共4段 — 透视模块 (独立可跑)
    依赖: 必须先执行第1段
    功能: 所有人形模型框线/名字/距离/血条 (含NPC人机), 视球开关
]]

if not getgenv().SuperShot then
    warn("[SuperShot] 请先执行第1段(公共底座)")
    return
end

local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")

local SS           = getgenv().SuperShot
local LocalPlayer  = Players.LocalPlayer
local Camera       = workspace.CurrentCamera
local notify       = getgenv().SuperShotNotify

-- ===== 本模块配置 (改这里) =====
local CFG = {
    Enabled     = true,     -- 加载即开启
    IncludeNPCs = true,     -- 人机也画
    MaxDistance = 2000,
    TeamCheck   = false,    -- true = 只显示敌人
    Boxes       = true,
    Names       = true,
    Distance    = true,
    HealthBar   = true,
    EnemyColor  = Color3.fromRGB(255, 64, 64),
    TeamColor   = Color3.fromRGB(64, 255, 128),
}
-- ===============================

-- 模块重执行前先卸旧的
if SS.UnloadESP then pcall(SS.UnloadESP) end

local ESP = { enabled = CFG.Enabled, dead = false, objects = {} }
SS.ESP = ESP
SS.ESPObjects = ESP.objects   -- 供静默瞄准段共用目标库

-- ---------- GUI 容器 ----------
local espGui = Instance.new("ScreenGui")
espGui.Name = "SuperShot_ESP"
espGui.ResetOnSpawn = false
espGui.IgnoreGuiInset = true
espGui.DisplayOrder = 50
espGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

-- ---------- 注册/注销 ----------
local function removeESP(model)
    local t = ESP.objects[model]
    if t then
        pcall(function() t.frame:Destroy() end)
        ESP.objects[model] = nil
    end
end

local function createESP(model, player)
    if not model or model == LocalPlayer.Character then return end
    if ESP.objects[model] then return end

    local frame = Instance.new("Frame")
    frame.BackgroundTransparency = 1
    frame.BorderSizePixel = 0
    frame.Visible = false
    frame.Parent = espGui

    local stroke = Instance.new("UIStroke")
    stroke.Thickness = 1.5
    stroke.Transparency = 0.2
    stroke.Color = CFG.EnemyColor
    stroke.Parent = frame

    local name = Instance.new("TextLabel")
    name.BackgroundTransparency = 1
    name.Size = UDim2.new(1, 0, 0, 16)
    name.Position = UDim2.new(0, 0, 0, -18)
    name.Font = Enum.Font.GothamBold
    name.TextSize = 12
    name.TextXAlignment = Enum.TextXAlignment.Center
    name.TextStrokeTransparency = 0.4
    name.Text = ""
    name.Visible = CFG.Names
    name.Parent = frame

    local dist = Instance.new("TextLabel")
    dist.BackgroundTransparency = 1
    dist.Size = UDim2.new(1, 0, 0, 14)
    dist.Position = UDim2.new(0, 0, 1, 2)
    dist.Font = Enum.Font.Gotham
    dist.TextSize = 11
    dist.TextXAlignment = Enum.TextXAlignment.Center
    dist.TextStrokeTransparency = 0.4
    dist.Text = ""
    dist.Visible = CFG.Distance
    dist.Parent = frame

    local healthBg = Instance.new("Frame")
    healthBg.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    healthBg.BackgroundTransparency = 0.35
    healthBg.BorderSizePixel = 0
    healthBg.Position = UDim2.new(0, -7, 0, 0)
    healthBg.Size = UDim2.new(0, 4, 1, 0)
    healthBg.Visible = CFG.HealthBar
    healthBg.Parent = frame

    local healthFill = Instance.new("Frame")
    healthFill.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
    healthFill.BorderSizePixel = 0
    healthFill.AnchorPoint = Vector2.new(0, 1)
    healthFill.Position = UDim2.new(0, 0, 1, 0)
    healthFill.Size = UDim2.new(1, 0, 1, 0)
    healthFill.Parent = healthBg

    ESP.objects[model] = {
        frame = frame, stroke = stroke,
        name = name, dist = dist,
        healthBg = healthBg, healthFill = healthFill,
        player = player,
    }
end

local function registerModel(model)
    if not model or not model:IsA("Model") then return end
    if model == LocalPlayer.Character then return end
    if ESP.objects[model] then return end
    local hum = model:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    local plr = Players:GetPlayerFromCharacter(model)
    if not plr and not CFG.IncludeNPCs then return end
    createESP(model, plr)
end

-- ---------- 动态捕获 ----------
local conns = {}

-- 初始扫描 (含已生成的NPC)
for _, obj in ipairs(workspace:GetDescendants()) do
    if obj:IsA("Humanoid") and obj.Parent then
        registerModel(obj.Parent)
    end
end

for _, plr in ipairs(Players:GetPlayers()) do
    if plr.Character then registerModel(plr.Character) end
    table.insert(conns, plr.CharacterAdded:Connect(function(char)
        task.defer(registerModel, char)
    end))
end
table.insert(conns, Players.PlayerAdded:Connect(function(plr)
    plr.CharacterAdded:Connect(function(char)
        task.defer(registerModel, char)
    end)
end))

-- NPC 生成即捕获
table.insert(conns, workspace.DescendantAdded:Connect(function(obj)
    if obj:IsA("Humanoid") and obj.Parent then
        task.defer(registerModel, obj.Parent)
    end
end))

-- 周期兜底 + 清理消失模型
task.spawn(function()
    while not ESP.dead do
        pcall(function()
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr.Character then registerModel(plr.Character) end
            end
            if CFG.IncludeNPCs then
                for _, m in ipairs(workspace:GetChildren()) do
                    if m:IsA("Model") and m:FindFirstChildOfClass("Humanoid") then
                        registerModel(m)
                    end
                end
            end
            for model in pairs(ESP.objects) do
                if not model.Parent then removeESP(model) end
            end
        end)
        task.wait(1)
    end
end)

-- ---------- 每帧刷新 ----------
local updateConn
updateConn = RunService.RenderStepped:Connect(function()
    for model, t in pairs(ESP.objects) do
        local root = model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart
        local hum  = model:FindFirstChildOfClass("Humanoid")
        local show = ESP.enabled
            and model.Parent
            and root and hum and hum.Health > 0
            and model ~= LocalPlayer.Character

        if show then
            local rootPos, onScreen = Camera:WorldToViewportPoint(root.Position)
            local dist = (Camera.CFrame.Position - root.Position).Magnitude
            local sameTeam = t.player and t.player.Team and LocalPlayer.Team
                and t.player.Team == LocalPlayer.Team

            if not onScreen
                or dist > CFG.MaxDistance
                or (CFG.TeamCheck and sameTeam) then
                show = false
            else
                local okBB, cf, size = pcall(model.GetBoundingBox, model)
                if okBB and size then
                    local topV    = Camera:WorldToViewportPoint(cf.Position + Vector3.new(0, size.Y / 2, 0))
                    local bottomV = Camera:WorldToViewportPoint(cf.Position - Vector3.new(0, size.Y / 2, 0))
                    local h = math.abs(bottomV.Y - topV.Y)
                    if h > 1 then
                        local w = h / 2
                        local color = sameTeam and CFG.TeamColor or CFG.EnemyColor

                        t.frame.Visible = true
                        t.frame.Position = UDim2.fromOffset(topV.X - w / 2, topV.Y)
                        t.frame.Size = UDim2.fromOffset(w, h)
                        t.stroke.Color = color

                        if CFG.Names then
                            t.name.Text = t.player and t.player.DisplayName or model.Name
                            t.name.TextColor3 = color
                            t.name.Visible = true
                        else
                            t.name.Visible = false
                        end

                        if CFG.Distance then
                            t.dist.Text = string.format("[%d]", dist)
                            t.dist.TextColor3 = color
                            t.dist.Visible = true
                        else
                            t.dist.Visible = false
                        end

                        if CFG.HealthBar then
                            local pct = math.clamp(hum.Health / math.max(hum.MaxHealth, 1), 0, 1)
                            t.healthFill.Size = UDim2.new(1, 0, pct, 0)
                            t.healthFill.BackgroundColor3 =
                                Color3.fromRGB(255 - 255 * pct, 255 * pct, 0)
                            t.healthBg.Visible = true
                        else
                            t.healthBg.Visible = false
                        end
                    else
                        show = false
                    end
                else
                    show = false
                end
            end
        end

        if not show then
            t.frame.Visible = false
        end
    end
end)

-- ---------- 卸载 ----------
SS.UnloadESP = function()
    ESP.enabled = false
    ESP.dead = true
    if updateConn then pcall(function() updateConn:Disconnect() end) end
    for _, c in ipairs(conns) do pcall(function() c:Disconnect() end) end
    for model in pairs(ESP.objects) do removeESP(model) end
    pcall(function() espGui:Destroy() end)
    SS.ESPObjects = nil
    SS.ESP = nil
    notify("[透视] 已卸载")
end
getgenv().SuperShotRegister("ESP", SS.UnloadESP)

-- ---------- 开关球 (视 · 屏幕第5位) ----------
getgenv().SuperShotMakeBall(4, "视", function()
    ESP.enabled = not ESP.enabled
    notify("[透视] " .. (ESP.enabled and "开启" or "关闭"))
end, function() return ESP.enabled end,
    { on = Color3.fromRGB(60, 140, 255), off = Color3.fromRGB(70, 70, 70) })

notify("[透视] 模块加载完成", 2)
print("[SuperShot] ESP loaded")

--[[
    第3段/共4段 — 静默瞄准模块 v4.1 (独立可跑)
    依赖: 必须先执行第1段
    功能: 屏幕中心准星锁定, 支持人机NPC
    v4.1 变更: 命中递交三层钩子
        层1 Raycast  — 劫持 workspace.Raycast / FindPartOnRay (客户端射线类)
        层2 Args     — 劫持 FireServer/InvokeServer, 替换 Vector3 和 CFrame 参数
                       (经典枪械源码 FireServer(mouse.Hit) 传的就是 CFrame!)
        层3 Camera   — 劫持 Camera.CFrame 读取: 游戏脚本读相机算弹道时
                       读到的是已对准目标的假 CFrame, 你屏幕上准星不动
        Mode = "All" 三层全上; 定位到哪层有效后, 改成单层省性能
    目标库: 透视段(第2段)已加载时共用其目标库; 未加载则自己扫描
]]

if not getgenv().SuperShot then
    warn("[SuperShot] 请先执行第1段(公共底座)")
    return
end

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local SS          = getgenv().SuperShot
local LocalPlayer = Players.LocalPlayer
local Camera      = workspace.CurrentCamera
local notify      = getgenv().SuperShotNotify

-- ===== 本模块配置 (改这里) =====
local CFG = {
    Enabled       = true,     -- 加载即开启
    HitPart       = "Head",   -- "Head" / "HumanoidRootPart"
    FOV           = 120,      -- 中心锁定圈半径 (像素)
    AimFromCenter = true,     -- 安卓: 屏幕中心为准星
    TeamCheck     = true,     -- 不打真人队友 (人机默认敌人)
    WallCheck     = false,
    -- "Raycast" / "Args" / "Camera" / "Both"(=层1+层2) / "All"(全上, 排查推荐)
    Mode          = "All",
    SpoofCFrame   = "Look",   -- 层2遇到CFrame参数: "Look"只改朝向保留原点 / "Position"整个换命中点
    ArgIndex      = nil,      -- 手动指定替换第几个参数, 例: 3
    Args          = nil,      -- 或多个, 例: {3, 5}
    Offset        = Vector3.new(0, 0, 0),
    DebugRemotes  = false,    -- true = 打印网络包调用 + 锁定目标 (排查递交层用)
}
-- ===============================

-- 模块重执行前先卸旧的
if SS.UnloadSA then pcall(SS.UnloadSA) end

local SilentAim = { enabled = CFG.Enabled, dead = false, target = nil }
SS.SilentAim = SilentAim

-- ---------- 目标库: 共用透视段的, 没有就自己扫 ----------
local ownModels = {}
local ownConns = {}
local ownStarted = false

local function startOwnScan()
    if ownStarted then return end
    ownStarted = true

    local function register(model)
        if model:IsA("Model") and not ownModels[model]
            and model ~= LocalPlayer.Character
            and model:FindFirstChildOfClass("Humanoid") then
            ownModels[model] = { player = Players:GetPlayerFromCharacter(model) }
        end
    end

    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Humanoid") and obj.Parent then register(obj.Parent) end
    end
    table.insert(ownConns, workspace.DescendantAdded:Connect(function(obj)
        if obj:IsA("Humanoid") and obj.Parent then
            task.defer(register, obj.Parent)
        end
    end))
    task.spawn(function()
        while not SilentAim.dead do
            pcall(function()
                for m in pairs(ownModels) do
                    if not m.Parent then ownModels[m] = nil end
                end
                for _, plr in ipairs(Players:GetPlayers()) do
                    if plr.Character then register(plr.Character) end
                end
            end)
            task.wait(1)
        end
    end)
end

local function getTargets()
    if SS.ESPObjects then
        return SS.ESPObjects   -- 透视段的目标库 (实时引用)
    end
    startOwnScan()
    return ownModels
end

-- ---------- 目标筛选 ----------
local function validTargetModel(model)
    if not model or not model.Parent then return false end
    if model == LocalPlayer.Character then return false end
    local hum = model:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return false end
    local entry = getTargets()[model]
    if entry and entry.player then
        local plr = entry.player
        if CFG.TeamCheck
            and plr.Team and LocalPlayer.Team
            and plr.Team == LocalPlayer.Team then
            return false
        end
    end
    return true
end

local function getTargetPart(model)
    if not model then return nil end
    return model:FindFirstChild(CFG.HitPart)
        or model:FindFirstChild("HumanoidRootPart")
        or model.PrimaryPart
end

local function aimPoint(part)
    return part.Position + CFG.Offset
end

local function getAimOrigin()
    if CFG.AimFromCenter then
        local vp = Camera.ViewportSize
        return Vector2.new(vp.X / 2, vp.Y / 2)
    end
    local m = UserInputService:GetMouseLocation()
    return Vector2.new(m.X, m.Y)
end

local function getClosestTarget()
    local origin = getAimOrigin()
    local best, bestDist = nil, CFG.FOV
    for model in pairs(getTargets()) do
        if validTargetModel(model) then
            local part = getTargetPart(model)
            if part then
                local pos, onScreen = Camera:WorldToViewportPoint(part.Position)
                if onScreen then
                    local d = (Vector2.new(pos.X, pos.Y) - origin).Magnitude
                    if d < bestDist then
                        if not CFG.WallCheck then
                            bestDist, best = d, part
                        else
                            local params = RaycastParams.new()
                            params.FilterType = Enum.RaycastFilterType.Exclude
                            params.FilterDescendantsInstances = { Camera, LocalPlayer.Character }
                            local hit = workspace:Raycast(
                                Camera.CFrame.Position,
                                part.Position - Camera.CFrame.Position,
                                params
                            )
                            if not hit or hit.Instance:IsDescendantOf(model) then
                                bestDist, best = d, part
                            end
                        end
                    end
                end
            end
        end
    end
    return best
end

-- ---------- 参数替换器: Vector3 直换, CFrame 按 SpoofCFrame 处理 ----------
local function makeSpoofed(v, aimAt)
    local t = typeof(v)
    if t == "Vector3" then
        return aimAt, true
    elseif t == "CFrame" and CFG.SpoofCFrame then
        if CFG.SpoofCFrame == "Position" then
            return CFrame.new(aimAt), true
        end
        local pos = v.Position
        if (aimAt - pos).Magnitude > 0.001 then
            return CFrame.new(pos, aimAt), true   -- 保留原点, 朝向对准目标
        end
    end
    return v, false
end

-- ---------- 层1: Raycast 劫持 (客户端射线类) ----------
if (CFG.Mode == "Raycast" or CFG.Mode == "Both" or CFG.Mode == "All") then
    if hookfunction and newcclosure then
        local ok, err = pcall(function()
            local oldRaycast
            oldRaycast = hookfunction(workspace.Raycast, newcclosure(
                function(self, origin, direction, params)
                    if SilentAim.enabled and SilentAim.target and SilentAim.target.Parent then
                        local aimAt = aimPoint(SilentAim.target)
                        local mag = direction.Magnitude
                        local newDir = (aimAt - origin)
                        if newDir.Magnitude > 0 then
                            direction = newDir.Unit * mag
                        end
                    end
                    return oldRaycast(self, origin, direction, params)
                end
            ))
        end)
        if not ok then
            warn("[SuperShot] Raycast hook 失败: " .. tostring(err))
        end
    else
        warn("[SuperShot] 执行器不支持 hookfunction, Raycast 模式跳过")
    end
end

-- ---------- 层2: __namecall 劫持 (网络包坐标) ----------
if (CFG.Mode == "Args" or CFG.Mode == "Both" or CFG.Mode == "All")
    and hookmetamethod and newcclosure and getnamecallmethod then
    local oldNamecall
    oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
        local method = getnamecallmethod()

        if CFG.DebugRemotes and (method == "FireServer" or method == "InvokeServer") then
            local args, out = { ... }, {}
            for i, v in ipairs(args) do
                out[i] = typeof(v) .. "(" .. tostring(v) .. ")"
            end
            print(("[SuperShot] %s :: %s"):format(self:GetFullName(), table.concat(out, ", ")))
        end

        if (method == "FireServer" or method == "InvokeServer")
            and SilentAim.enabled
            and SilentAim.target
            and SilentAim.target.Parent then

            local args = { ... }
            local aimAt = aimPoint(SilentAim.target)
            local indices = CFG.Args
                or (CFG.ArgIndex and { CFG.ArgIndex } or nil)
            local replaced = false

            if indices then
                for _, i in ipairs(indices) do
                    local nv, changed = makeSpoofed(args[i], aimAt)
                    if changed then
                        args[i] = nv
                        replaced = true
                    end
                end
            else
                for i, v in ipairs(args) do
                    local nv, changed = makeSpoofed(v, aimAt)
                    if changed then
                        args[i] = nv
                        replaced = true
                    end
                end
            end

            if replaced then
                return oldNamecall(self, unpack(args))
            end
        end

        if method == "FindPartOnRay"
            and SilentAim.enabled
            and SilentAim.target
            and SilentAim.target.Parent then
            local args = { ... }
            local ray = args[1]
            if typeof(ray) == "Ray" then
                local origin = ray.Origin
                local dir = (aimPoint(SilentAim.target) - origin)
                if dir.Magnitude > 0 then
                    args[1] = Ray.new(origin, dir.Unit * ray.Direction.Magnitude)
                    return oldNamecall(self, unpack(args))
                end
            end
        end

        return oldNamecall(self, ...)
    end))
elseif CFG.Mode == "Args" then
    warn("[SuperShot] 执行器不支持 hookmetamethod, Args 模式跳过")
end

-- ---------- 层3: Camera.CFrame 劫持 (相机弹道类) ----------
-- 游戏脚本读 Camera.CFrame / LookVector 算射击方向时, 读到的是对准目标的假值
if (CFG.Mode == "Camera" or CFG.Mode == "All") then
    if hookmetamethod and newcclosure then
        local ok, err = pcall(function()
            local oldIndex
            oldIndex = hookmetamethod(game, "__index", newcclosure(function(self, key)
                if key == "CFrame" or key == "CoordinateFrame" or key == "LookVector" then
                    local cam = oldIndex(workspace, "CurrentCamera")
                    if self == cam
                        and SilentAim.enabled
                        and SilentAim.target
                        and SilentAim.target.Parent then
                        local aimAt = aimPoint(SilentAim.target)
                        if key == "LookVector" then
                            local pos = oldIndex(self, "Position")
                            local dir = (aimAt - pos)
                            if dir.Magnitude > 0.001 then
                                return dir.Unit
                            end
                            return oldIndex(self, key)
                        end
                        local real = oldIndex(self, key)
                        local pos = real.Position
                        if (aimAt - pos).Magnitude > 0.001 then
                            return CFrame.new(pos, aimAt)
                        end
                        return real
                    end
                end
                return oldIndex(self, key)
            end))
        end)
        if not ok then
            warn("[SuperShot] Camera __index hook 失败: " .. tostring(err))
        end
    else
        warn("[SuperShot] 执行器不支持 hookmetamethod, Camera 模式跳过")
    end
end

-- ---------- 每帧锁定刷新 ----------
local saConn
local lastTargetName
saConn = RunService.RenderStepped:Connect(function()
    if SilentAim.dead then return end
    SilentAim.target = SilentAim.enabled and getClosestTarget() or nil

    if CFG.DebugRemotes then
        local name = nil
        if SilentAim.target and SilentAim.target.Parent then
            name = SilentAim.target.Parent.Name
        end
        if name ~= lastTargetName then
            lastTargetName = name
            if name then
                print("[SuperShot] 锁定: " .. name)
            end
        end
    end
end)

-- ---------- 卸载 ----------
SS.UnloadSA = function()
    SilentAim.enabled = false
    SilentAim.dead = true
    SilentAim.target = nil
    if saConn then pcall(function() saConn:Disconnect() end) end
    for _, c in ipairs(ownConns) do pcall(function() c:Disconnect() end) end
    ownModels = {}
    SS.SilentAim = nil
    notify("[静默瞄准] 已卸载 (hook 需重进游戏还原)")
end
getgenv().SuperShotRegister("SilentAim", SS.UnloadSA)

-- ---------- 开关球 (瞄 · 屏幕第1位) ----------
getgenv().SuperShotMakeBall(0, "瞄", function()
    SilentAim.enabled = not SilentAim.enabled
    notify("[静默瞄准] " .. (SilentAim.enabled and "开启" or "关闭"))
end, function() return SilentAim.enabled end,
    { on = Color3.fromRGB(60, 220, 90), off = Color3.fromRGB(70, 70, 70) })

notify("[静默瞄准] v4.1 三层钩子加载完成", 2)
print("[SuperShot] SilentAim v4.1 loaded — Mode=" .. CFG.Mode)

--[[
    第4段/共4段 — 飞行模块 (独立可跑)
    依赖: 必须先执行第1段
    功能: 摇杆驱动飞行, 升/降球按住生效
    双模式: Velocity(物理推) / CFrame(坐标位移, 被反飞拦截就用这个)
]]

if not getgenv().SuperShot then
    warn("[SuperShot] 请先执行第1段(公共底座)")
    return
end

local RunService = game:GetService("RunService")

local SS     = getgenv().SuperShot
local LocalPlayer = game:GetService("Players").LocalPlayer
local notify = getgenv().SuperShotNotify

-- ===== 本模块配置 (改这里) =====
local CFG = {
    Mode          = "Velocity", -- "Velocity" 物理推 / "CFrame" 坐标位移
    Speed         = 120,
    VerticalSpeed = 80,
    NoClip        = false,
}
-- ===============================

-- 模块重执行前先卸旧的
if SS.UnloadFly then pcall(SS.UnloadFly) end

local Fly = {
    enabled = false, ascend = false, descend = false, dead = false,
    bv = nil, bg = nil, conn = nil, noclipConn = nil,
}
SS.Fly = Fly

-- ---------- 工具 ----------
local function getHRP()
    local char = game:GetService("Players").LocalPlayer.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function getHum()
    local char = game:GetService("Players").LocalPlayer.Character
    return char and char:FindFirstChildOfClass("Humanoid")
end

local function stopFly()
    Fly.enabled = false
    Fly.ascend = false
    Fly.descend = false
    if Fly.bv then pcall(function() Fly.bv:Destroy() end) Fly.bv = nil end
    if Fly.bg then pcall(function() Fly.bg:Destroy() end) Fly.bg = nil end
end

-- 每帧保活: 反飞删 BodyMover 就立刻补
local function ensureFlyBody(root)
    if CFG.Mode == "Velocity" then
        if not Fly.bv or Fly.bv.Parent ~= root then
            if Fly.bv then pcall(function() Fly.bv:Destroy() end) end
            Fly.bv = Instance.new("BodyVelocity")
            Fly.bv.MaxForce = Vector3.new(1e9, 1e9, 1e9)
            Fly.bv.Velocity = Vector3.zero
            Fly.bv.Parent = root
        end
    end
    if not Fly.bg or Fly.bg.Parent ~= root then
        if Fly.bg then pcall(function() Fly.bg:Destroy() end) end
        Fly.bg = Instance.new("BodyGyro")
        Fly.bg.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
        Fly.bg.P = 1e5
        Fly.bg.D = 500
        Fly.bg.CFrame = root.CFrame
        Fly.bg.Parent = root
    end
end

local function startFly()
    local hrp, hum = getHRP(), getHum()
    if not hrp or not hum or hum.Health <= 0 then
        notify("[飞行] 角色未就绪")
        return
    end

    stopFly()
    Fly.enabled = true

    Fly.conn = RunService.RenderStepped:Connect(function(dt)
        if Fly.dead then return end
        local root = getHRP()
        local hum = getHum()
        if not root or not hum or hum.Health <= 0 then
            stopFly()
            return
        end
        ensureFlyBody(root)

        local vel = hum.MoveDirection * CFG.Speed
        if Fly.ascend then
            vel += Vector3.new(0, CFG.VerticalSpeed, 0)
        end
        if Fly.descend then
            vel -= Vector3.new(0, CFG.VerticalSpeed, 0)
        end

        if CFG.Mode == "CFrame" then
            root.CFrame = root.CFrame + vel * dt
        else
            if Fly.bv then
                Fly.bv.Velocity = vel
            end
        end

        local look = workspace.CurrentCamera.CFrame.LookVector
        if Fly.bg then
            Fly.bg.CFrame = CFrame.new(root.Position, root.Position + Vector3.new(look.X, 0, look.Z))
        end
    end)

    if CFG.NoClip then
        Fly.noclipConn = RunService.Stepped:Connect(function()
            local char = game:GetService("Players").LocalPlayer.Character
            if char then
                for _, p in ipairs(char:GetDescendants()) do
                    if p:IsA("BasePart") and p.CanCollide then
                        p.CanCollide = false
                    end
                end
            end
        end)
    end
end

-- ---------- 卸载 ----------
SS.UnloadFly = function()
    Fly.dead = true
    stopFly()
    if Fly.conn then pcall(function() Fly.conn:Disconnect() end) Fly.conn = nil end
    if Fly.noclipConn then pcall(function() Fly.noclipConn:Disconnect() end) Fly.noclipConn = nil end
    SS.Fly = nil
    notify("[飞行] 已卸载")
end
getgenv().SuperShotRegister("Fly", SS.UnloadFly)

-- ---------- 开关球 (飞/升/降 · 屏幕第2/3/4位) ----------
getgenv().SuperShotMakeBall(1, "飞", function()
    if Fly.enabled then
        stopFly()
        notify("[飞行] 关闭")
    else
        startFly()
        if Fly.enabled then notify("[飞行] 开启 | 摇杆移动, 按住升降球") end
    end
end, function() return Fly.enabled end,
    { on = Color3.fromRGB(230, 80, 60), off = Color3.fromRGB(70, 70, 70) })

getgenv().SuperShotMakeBall(2, "升", nil,
    function() return Fly.ascend end,
    { on = Color3.fromRGB(255, 170, 60), off = Color3.fromRGB(70, 70, 70) },
    true, function(v) Fly.ascend = v end)

getgenv().SuperShotMakeBall(3, "降", nil,
    function() return Fly.descend end,
    { on = Color3.fromRGB(255, 170, 60), off = Color3.fromRGB(70, 70, 70) },
    true, function(v) Fly.descend = v end)

notify("[飞行] 模块加载完成", 2)
print("[SuperShot] Fly loaded")
