--[[
    feito por KG$
    v6: painel com abas + detecção de progresso + Auto Estudar (CLIQUE CORRIGIDO)
--]]

--==================== CONFIG ====================--
local CONFIG = {
    CONTAINER        = "PopulacaoNPC",
    MAX_INDEX        = 45,
    USE_PHYSICS      = true,
    INFINITE         = true,
    SPEED            = 55,
    FRONT_DISTANCE   = 5,
    FRONT_DIST_MIN   = 1.8,
    ARRIVE_EPS       = 0.2,
    PHYS_EPS         = 2.5,
    WAYPOINT_EPS     = 2.5,
    APPROACH_TIMEOUT = 25,
    MIN_SPEED        = 20,
    LOW_SPEED_TIME   = 2,
    SPEED_SAMPLE     = 0.2,
    SPACE_INTERVAL   = 0.1,
    SPACE_HOLD       = 0.03,
    RECOVERY_CYCLE   = 2,
    RECOVERY_PAUSE   = 0.3,
    RECOVERY_REPATH  = 1.0,
    MIN_NORMAL_Y     = 0.70,
    MAX_GROUND_DELTA = 6,
    PROBE_UP         = 3,
    PROBE_DOWN       = 12,
    PROBE_SIDE       = 0.7,
    WAYPOINT_TIMEOUT = 1.5,
    STUCK_WINDOW     = 0.4,
    STUCK_MIN_MOVE   = 0.6,
    STUCK_RETRIES    = 3,
    REPATH_DIST      = 4,
    REPATH_COOLDOWN  = 0.4,
    SETTLE_DELAY     = 0.05,
    PRESS_COUNT      = 5,
    PRESS_HOLD       = 0.02,
    PRESS_INTERVAL   = 0.05,
    NPC_COOLDOWN     = 0.05,
    COOLDOWN         = 30,
    COOLDOWN_PAD     = 0.5,
    FAIL_COOLDOWN    = 3,
    MAX_WAIT         = 5,
    OFFSET_Y         = 2.5,
    FRONT_MODE       = "npc",
    ESP_ENABLED      = true,
    ESP_MAX_DIST     = 3000,
    ESP_UPDATE       = 0.1,
    MISSION_LOOP     = false,
    MISSION_STF      = true,
    APOIO_MIN        = 2,
    APOIO_MAX        = 3,
}

local STUDY = {
    LOOP          = true,
    DURATION      = 10,         
    WAIT_AFTER    = 2,          
    HOLD_E_TIME   = 7,          
    PROMPT_ACTION = "Preparar Debate",
    CATEGORY_TEXT = "SEG",             
    GUI_TIMEOUT   = 8,          
}

local AGENT_PARAMS = {
    AgentRadius    = 2.5,
    AgentHeight    = 5,
    AgentCanJump   = true,
    AgentJumpHeight = 7,
    AgentMaxSlope  = 45,
    WaypointSpacing = 6,
}

--==================== TEMA ====================--
local THEME = {
    BG      = Color3.fromRGB(14, 14, 20),
    CARD    = Color3.fromRGB(26, 26, 38),
    OFF     = Color3.fromRGB(46, 45, 64),
    STROKE  = Color3.fromRGB(58, 56, 84),
    ACCENT  = Color3.fromRGB(139, 92, 246),
    ACCENT2 = Color3.fromRGB(99, 102, 241),
    TEXT    = Color3.fromRGB(240, 240, 250),
    MUTED   = Color3.fromRGB(140, 140, 165),
    GOOD    = Color3.fromRGB(74, 222, 128),
    WARN    = Color3.fromRGB(251, 191, 36),
    BAD     = Color3.fromRGB(248, 113, 113),
    INFO    = Color3.fromRGB(167, 139, 250),
    PINK    = Color3.fromRGB(244, 114, 182),
}

local ESP_COLORS = {
    free     = THEME.GOOD,
    cooldown = THEME.WARN,
    target   = THEME.PINK,
}

--==================== SERVICES ====================--
local Players       = game:GetService("Players")
local Workspace     = game:GetService("Workspace")
local VIM           = game:GetService("VirtualInputManager")
local UIS           = game:GetService("UserInputService")
local RunService    = game:GetService("RunService")
local TweenService  = game:GetService("TweenService")
local Pathfinding   = game:GetService("PathfindingService")
local CoreGui       = game:GetService("CoreGui")
local VirtualUser   = game:GetService("VirtualUser")
local LP            = Players.LocalPlayer

local running = false
local dragging, dragStart, startPos = false, nil, nil
local cooldowns = {}
local activeContainer = nil
local currentTarget = nil
local doneCount = 0
local mode = nil
local connections = {}
local clearAllESP

--==================== HELPERS DE UI ====================--
local function getParentGui()
    local ok, hui = pcall(function() return gethui and gethui() or nil end)
    if ok and hui then return hui end
    local ok2, cg = pcall(function() return CoreGui end)
    if ok2 and cg then return cg end
    return LP:WaitForChild("PlayerGui")
end

local function new(class, props, parent)
    local inst = Instance.new(class)
    if props then for k, v in pairs(props) do inst[k] = v end end
    if parent then inst.Parent = parent end
    return inst
end

local function round(inst, radius)
    return new("UICorner", { CornerRadius = UDim.new(0, radius) }, inst)
end

local function outline(inst, color, thickness, transparency)
    return new("UIStroke", {
        Color = color, Thickness = thickness or 1, Transparency = transparency or 0,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    }, inst)
end

local function tween(inst, t, props)
    TweenService:Create(inst, TweenInfo.new(t, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props):Play()
end

--==================== GUI (TABS) ====================--
local guiParent = getParentGui()
for _, n in ipairs({ "NPCInteractvip", "NPCInteractESP" }) do
    local old = guiParent:FindFirstChild(n)
    if old then old:Destroy() end
end

local gui = new("ScreenGui", {
    Name = "NPCInteractvip", ResetOnSpawn = false, IgnoreGuiInset = true,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 999,
})
gui.Parent = guiParent
pcall(function() syn.protect_gui(gui) end)

local PANEL_W, PANEL_H = 260, 350
local HEADER_H = 38
local TABS_H   = 28
local STATUS_H = 22

local main = new("Frame", {
    Name = "Main", Size = UDim2.fromOffset(PANEL_W, PANEL_H), Position = UDim2.new(0, 40, 0, 40),
    BackgroundColor3 = THEME.BG, BorderSizePixel = 0, Active = true, ClipsDescendants = true,
}, gui)
round(main, 12)

local mainStroke = outline(main, Color3.new(1, 1, 1), 1.2, 0.5)
new("UIGradient", { Rotation = 90, Color = ColorSequence.new(THEME.ACCENT, THEME.ACCENT2) }, mainStroke)
new("UIGradient", {
    Rotation = 90,
    Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(32, 24, 60)),
        ColorSequenceKeypoint.new(0.4, THEME.BG),
        ColorSequenceKeypoint.new(1, THEME.BG),
    }),
}, main)

local popScale = new("UIScale", { Scale = 0.9 }, main)
TweenService:Create(popScale, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()

--==== HEADER ====--
local header = new("Frame", { Name = "Header", Size = UDim2.new(1, 0, 0, HEADER_H), BackgroundTransparency = 1, Active = true }, main)
local logo = new("Frame", {
    Size = UDim2.fromOffset(22, 22), Position = UDim2.new(0, 10, 0.5, -11),
    BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0,
}, header)
round(logo, 6)
new("UIGradient", { Rotation = 45, Color = ColorSequence.new(THEME.ACCENT, THEME.ACCENT2) }, logo)
new("TextLabel", {
    Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1,
    Font = Enum.Font.GothamBlack, TextSize = 12, TextColor3 = Color3.new(1, 1, 1), Text = "K",
}, logo)

new("TextLabel", {
    Size = UDim2.new(0, 180, 0, 16), Position = UDim2.new(0, 38, 0.5, -10),
    BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 12,
    TextColor3 = THEME.TEXT, TextXAlignment = Enum.TextXAlignment.Left, Text = "KGS PANEL",
}, header)

new("TextLabel", {
    Size = UDim2.new(0, 180, 0, 12), Position = UDim2.new(0, 38, 0.5, 4),
    BackgroundTransparency = 1, Font = Enum.Font.Gotham, TextSize = 9,
    TextColor3 = THEME.MUTED, TextXAlignment = Enum.TextXAlignment.Left, Text = "NPC Interact • Premium",
}, header)

local function headerButton(text, xOffset)
    local b = new("TextButton", {
        AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, xOffset, 0.5, 0),
        Size = UDim2.fromOffset(24, 24), BackgroundColor3 = THEME.CARD, BorderSizePixel = 0,
        AutoButtonColor = false, Text = text, Font = Enum.Font.GothamBold, TextSize = 14, TextColor3 = THEME.MUTED,
    }, header)
    round(b, 6)
    b.MouseEnter:Connect(function() tween(b, 0.12, { BackgroundColor3 = THEME.OFF, TextColor3 = THEME.TEXT }) end)
    b.MouseLeave:Connect(function() tween(b, 0.12, { BackgroundColor3 = THEME.CARD, TextColor3 = THEME.MUTED }) end)
    return b
end

local minBtn   = headerButton("-", -38)
local closeBtn = headerButton("×", -8)

new("Frame", {
    Size = UDim2.new(1, 0, 0, 1), Position = UDim2.new(0, 0, 0, HEADER_H),
    BackgroundColor3 = THEME.STROKE, BackgroundTransparency = 0.35, BorderSizePixel = 0,
}, main)

--==== TAB BAR ====--
local tabBar = new("Frame", { Size = UDim2.new(1, 0, 0, TABS_H), Position = UDim2.new(0, 0, 0, HEADER_H + 1), BackgroundTransparency = 1 }, main)
new("UIPadding", { PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6), PaddingTop = UDim.new(0, 3), PaddingBottom = UDim.new(0, 3) }, tabBar)
new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 3), SortOrder = Enum.SortOrder.LayoutOrder }, tabBar)

local tabs = {}
local pages = {}

local function selectTab(name)
    for n, btn in pairs(tabs) do
        local on = (n == name)
        tween(btn, 0.15, { BackgroundColor3 = on and THEME.ACCENT or THEME.CARD, TextColor3 = on and Color3.new(1, 1, 1) or THEME.MUTED })
    end
    for _, page in ipairs(pages) do page.Visible = (page.Name == name) end
end

local function tabButton(text, name, order)
    local b = new("TextButton", {
        Size = UDim2.new(1/5, -3, 1, 0), BackgroundColor3 = THEME.CARD, BorderSizePixel = 0,
        AutoButtonColor = false, Font = Enum.Font.GothamBold, TextSize = 9, TextColor3 = THEME.MUTED, Text = text, LayoutOrder = order,
    }, tabBar)
    round(b, 5)
    tabs[name] = b
    b.MouseButton1Click:Connect(function() selectTab(name) end)
    return b
end

tabButton("FARM",    "Farm",    1)
tabButton("MISSÃO",  "Missão",  2)
tabButton("ESTUDAR", "Estudar", 3)
tabButton("ESP",     "ESP",     4)
tabButton("INFO",    "Info",    5)

--==== CONTENT ====--
local content = new("Frame", {
    Name = "Content", Size = UDim2.new(1, 0, 1, -(HEADER_H + 1 + TABS_H + STATUS_H)),
    Position = UDim2.new(0, 0, 0, HEADER_H + 1 + TABS_H), BackgroundTransparency = 1, ClipsDescendants = true,
}, main)

local function makePage(name, order)
    local p = new("ScrollingFrame", {
        Name = name, Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, BorderSizePixel = 0,
        ScrollBarThickness = 3, ScrollBarImageColor3 = THEME.ACCENT, ScrollBarImageTransparency = 0.5,
        CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y, Visible = false, ClipsDescendants = true,
    }, content)
    new("UIPadding", { PaddingTop = UDim.new(0, 6), PaddingBottom = UDim.new(0, 6), PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8) }, p)
    new("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, p)
    table.insert(pages, p)
    return p
end

local farmPage    = makePage("Farm",    1)
local missionPage = makePage("Missão",  2)
local studyPage   = makePage("Estudar", 3)
local espPage     = makePage("ESP",     4)
local infoPage    = makePage("Info",    5)

--==== STATUS BAR ====--
local statusBar = new("Frame", {
    Size = UDim2.new(1, -16, 0, STATUS_H - 4), Position = UDim2.new(0, 8, 1, -(STATUS_H - 2)),
    BackgroundColor3 = THEME.CARD, BorderSizePixel = 0,
}, main)
round(statusBar, 5)
outline(statusBar, THEME.STROKE, 1, 0.5)

local statusDot = new("Frame", { Size = UDim2.fromOffset(7, 7), Position = UDim2.new(0, 8, 0.5, -3), BackgroundColor3 = THEME.MUTED, BorderSizePixel = 0 }, statusBar)
round(statusDot, 4)

local status = new("TextLabel", {
    Size = UDim2.new(1, -26, 1, 0), Position = UDim2.new(0, 20, 0, 0), BackgroundTransparency = 1,
    Font = Enum.Font.GothamMedium, TextSize = 10, TextColor3 = THEME.TEXT, TextXAlignment = Enum.TextXAlignment.Left,
    TextTruncate = Enum.TextTruncate.AtEnd, Text = "Parado",
}, statusBar)

--==== HELPERS DE CONTEÚDO ====--
local function card(parent, order)
    local f = new("Frame", {
        Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = THEME.CARD, BorderSizePixel = 0, LayoutOrder = order,
    }, parent)
    round(f, 8)
    outline(f, THEME.STROKE, 1, 0.5)
    new("UIPadding", { PaddingTop = UDim.new(0, 6), PaddingBottom = UDim.new(0, 6), PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8) }, f)
    new("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }, f)
    return f
end

local function createToggle(parent, text, initial, callback, order)
    local row = new("Frame", { Size = UDim2.new(1, 0, 0, 24), BackgroundTransparency = 1, LayoutOrder = order }, parent)
    new("TextLabel", {
        Size = UDim2.new(1, -50, 1, 0), BackgroundTransparency = 1, Font = Enum.Font.GothamMedium,
        TextSize = 11, TextColor3 = THEME.TEXT, TextXAlignment = Enum.TextXAlignment.Left, Text = text,
    }, row)
    local track = new("TextButton", {
        AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.fromOffset(34, 18),
        BackgroundColor3 = THEME.OFF, BorderSizePixel = 0, AutoButtonColor = false, Text = "",
    }, row)
    round(track, 9)
    local knob = new("Frame", {
        Size = UDim2.fromOffset(12, 12), AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 3, 0.5, 0),
        BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0,
    }, track)
    round(knob, 6)
    local state = initial
    local function render(animate)
        local t = animate and 0.18 or 0
        tween(track, t, { BackgroundColor3 = state and THEME.ACCENT or THEME.OFF })
        tween(knob, t, { Position = state and UDim2.new(0, 19, 0.5, 0) or UDim2.new(0, 3, 0.5, 0) })
    end
    render(false)
    track.MouseButton1Click:Connect(function() state = not state; render(true); callback(state) end)
    return function(v) state = v; render(true) end
end

local function buttonLabel(parent, size, text)
    return new("TextLabel", {
        Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Font = Enum.Font.GothamBold,
        TextSize = size, TextColor3 = Color3.new(1, 1, 1), TextStrokeTransparency = 0.75, ZIndex = 2, Text = text,
    }, parent)
end

--==== FARM PAGE ====--
local farmCard = card(farmPage, 1)
local speedRow = new("Frame", { Size = UDim2.new(1, 0, 0, 24), BackgroundTransparency = 1, LayoutOrder = 1 }, farmCard)
new("TextLabel", {
    Size = UDim2.new(1, -62, 1, 0), BackgroundTransparency = 1, Font = Enum.Font.GothamMedium, TextSize = 11,
    TextColor3 = THEME.TEXT, TextXAlignment = Enum.TextXAlignment.Left, Text = "Velocidade",
}, speedRow)

local speedBox = new("TextBox", {
    AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.fromOffset(54, 20),
    BackgroundColor3 = THEME.OFF, BorderSizePixel = 0, Font = Enum.Font.GothamBold, TextSize = 11,
    TextColor3 = THEME.TEXT, Text = tostring(CONFIG.SPEED), ClearTextOnFocus = false,
}, speedRow)
round(speedBox, 5)
local speedStroke = outline(speedBox, THEME.STROKE, 1, 0.3)

local function applySpeed()
    local n = tonumber(speedBox.Text)
    if n then CONFIG.SPEED = math.clamp(n, 16, 500) end
    speedBox.Text = tostring(CONFIG.SPEED)
end
speedBox.Focused:Connect(function() tween(speedStroke, 0.12, { Color = THEME.ACCENT, Transparency = 0 }) end)
speedBox.FocusLost:Connect(function() tween(speedStroke, 0.12, { Color = THEME.STROKE, Transparency = 0.3 }); applySpeed() end)

createToggle(farmCard, "Física + rota", CONFIG.USE_PHYSICS, function(v) CONFIG.USE_PHYSICS = v end, 2)
createToggle(farmCard, "Loop infinito", CONFIG.INFINITE, function(v) CONFIG.INFINITE = v end, 3)
createToggle(farmCard, "Frente pelo NPC", CONFIG.FRONT_MODE == "npc", function(v) CONFIG.FRONT_MODE = v and "npc" or "approach" end, 4)

local statsRow = new("Frame", { Size = UDim2.new(1, 0, 0, 44), BackgroundTransparency = 1, LayoutOrder = 2 }, farmPage)
new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }, statsRow)

local function statCard(caption, color, order)
    local c = new("Frame", { Size = UDim2.new(1/3, -3, 1, 0), BackgroundColor3 = THEME.CARD, BorderSizePixel = 0, LayoutOrder = order }, statsRow)
    round(c, 8)
    outline(c, THEME.STROKE, 1, 0.5)
    local num = new("TextLabel", {
        Size = UDim2.new(1, 0, 0, 22), Position = UDim2.new(0, 0, 0, 4), BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold, TextSize = 15, TextColor3 = color, Text = "0",
    }, c)
    new("TextLabel", {
        Size = UDim2.new(1, 0, 0, 12), Position = UDim2.new(0, 0, 0, 27), BackgroundTransparency = 1,
        Font = Enum.Font.Gotham, TextSize = 9, TextColor3 = THEME.MUTED, Text = caption,
    }, c)
    return num
end

local statDone = statCard("Feitos",   THEME.INFO, 1)
local statFree = statCard("Livres",   THEME.GOOD, 2)
local statCool = statCard("Cooldown", THEME.WARN, 3)

local function setStats(done, free, cool)
    statDone.Text = tostring(done); statFree.Text = tostring(free); statCool.Text = tostring(cool)
end

local button = new("TextButton", {
    Size = UDim2.new(1, 0, 0, 36), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0,
    AutoButtonColor = false, Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = Color3.new(1, 1, 1), Text = "", LayoutOrder = 3,
}, farmPage)
round(button, 8)
local buttonGradient = new("UIGradient", { Rotation = 0, Color = ColorSequence.new(THEME.ACCENT, THEME.ACCENT2) }, button)
local buttonText = buttonLabel(button, 12, "FARM NPC")

--==== MISSÃO PAGE ====--
local missionCard = card(missionPage, 1)
createToggle(missionCard, "Loop missão", CONFIG.MISSION_LOOP, function(v) CONFIG.MISSION_LOOP = v end, 1)
createToggle(missionCard, "Passar no STF", CONFIG.MISSION_STF, function(v) CONFIG.MISSION_STF = v end, 2)

local apoioRow = new("Frame", { Size = UDim2.new(1, 0, 0, 24), BackgroundTransparency = 1, LayoutOrder = 3 }, missionCard)
new("TextLabel", {
    Size = UDim2.new(1, -88, 1, 0), BackgroundTransparency = 1, Font = Enum.Font.GothamMedium, TextSize = 11,
    TextColor3 = THEME.TEXT, TextXAlignment = Enum.TextXAlignment.Left, Text = "Apoios (mín/máx)",
}, apoioRow)

local function smallBox(xOffset, initial, onCommit)
    local box = new("TextBox", {
        AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, xOffset, 0.5, 0), Size = UDim2.fromOffset(36, 20),
        BackgroundColor3 = THEME.OFF, BorderSizePixel = 0, Font = Enum.Font.GothamBold, TextSize = 11,
        TextColor3 = THEME.TEXT, Text = tostring(initial), ClearTextOnFocus = false,
    }, apoioRow)
    round(box, 5)
    box.FocusLost:Connect(function() onCommit(box) end)
    return box
end

local minBox, maxBox
minBox = smallBox(-44, CONFIG.APOIO_MIN, function(b)
    local n = math.floor(tonumber(b.Text) or CONFIG.APOIO_MIN)
    CONFIG.APOIO_MIN = math.clamp(n, 1, 5)
    if CONFIG.APOIO_MIN > CONFIG.APOIO_MAX then CONFIG.APOIO_MAX = CONFIG.APOIO_MIN; maxBox.Text = tostring(CONFIG.APOIO_MAX) end
    b.Text = tostring(CONFIG.APOIO_MIN)
end)
maxBox = smallBox(0, CONFIG.APOIO_MAX, function(b)
    local n = math.floor(tonumber(b.Text) or CONFIG.APOIO_MAX)
    CONFIG.APOIO_MAX = math.clamp(n, 1, 5)
    if CONFIG.APOIO_MAX < CONFIG.APOIO_MIN then CONFIG.APOIO_MIN = CONFIG.APOIO_MAX; minBox.Text = tostring(CONFIG.APOIO_MIN) end
    b.Text = tostring(CONFIG.APOIO_MAX)
end)

--==== PROGRESSO / RETOMADA (UI) ====--
local MISSION_STATE = { enabled = true, hasFolder = false, hasStamp = false, apoiosDone = 0 }
local stepLabel
local progressCard = card(missionPage, 2)
createToggle(progressCard, "Continuar de onde parou", MISSION_STATE.enabled, function(v) MISSION_STATE.enabled = v end, 1)

stepLabel = new("TextLabel", {
    Size = UDim2.new(1, 0, 0, 14), BackgroundTransparency = 1, Font = Enum.Font.Gotham, TextSize = 10,
    TextColor3 = THEME.INFO, TextXAlignment = Enum.TextXAlignment.Left, Text = "Etapa: 1. Pegar pasta", LayoutOrder = 2,
}, progressCard)

local progRow = new("Frame", { Size = UDim2.new(1, 0, 0, 22), BackgroundTransparency = 1, LayoutOrder = 3 }, progressCard)
new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }, progRow)

local scanBtn = new("TextButton", {
    Size = UDim2.new(0.5, -2, 1, 0), BackgroundColor3 = THEME.ACCENT, BorderSizePixel = 0, AutoButtonColor = false,
    Font = Enum.Font.GothamBold, TextSize = 10, TextColor3 = Color3.new(1, 1, 1), Text = "Detectar", LayoutOrder = 1,
}, progRow)
round(scanBtn, 5)

local resetBtn = new("TextButton", {
    Size = UDim2.new(0.5, -2, 1, 0), BackgroundColor3 = THEME.OFF, BorderSizePixel = 0, AutoButtonColor = false,
    Font = Enum.Font.GothamBold, TextSize = 10, TextColor3 = THEME.TEXT, Text = "Resetar", LayoutOrder = 2,
}, progRow)
round(resetBtn, 5)

local missionButton = new("TextButton", {
    Size = UDim2.new(1, 0, 0, 36), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, AutoButtonColor = false,
    Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = Color3.new(1, 1, 1), Text = "", LayoutOrder = 3,
}, missionPage)
round(missionButton, 8)
local missionGradient = new("UIGradient", { Rotation = 0, Color = ColorSequence.new(THEME.PINK, THEME.ACCENT) }, missionButton)
local missionText = buttonLabel(missionButton, 12, "FARM MISSÃO")

--==== ESTUDAR PAGE ====--
local studyCard = card(studyPage, 1)
createToggle(studyCard, "Loop de estudo", STUDY.LOOP, function(v) STUDY.LOOP = v end, 1)

local catRow = new("Frame", { Size = UDim2.new(1, 0, 0, 24), BackgroundTransparency = 1, LayoutOrder = 2 }, studyCard)
new("TextLabel", {
    Size = UDim2.new(1, -62, 1, 0), BackgroundTransparency = 1, Font = Enum.Font.GothamMedium,
    TextSize = 11, TextColor3 = THEME.TEXT, TextXAlignment = Enum.TextXAlignment.Left, Text = "Categoria (Ex: SEG)",
}, catRow)

local catBox = new("TextBox", {
    AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.fromOffset(54, 20),
    BackgroundColor3 = THEME.OFF, BorderSizePixel = 0, Font = Enum.Font.GothamBold, TextSize = 11,
    TextColor3 = THEME.TEXT, Text = STUDY.CATEGORY_TEXT, ClearTextOnFocus = false,
}, catRow)
round(catBox, 5)
catBox.FocusLost:Connect(function() STUDY.CATEGORY_TEXT = catBox.Text end)

local durRow = new("Frame", { Size = UDim2.new(1, 0, 0, 24), BackgroundTransparency = 1, LayoutOrder = 3 }, studyCard)
new("TextLabel", {
    Size = UDim2.new(1, -62, 1, 0), BackgroundTransparency = 1, Font = Enum.Font.GothamMedium,
    TextSize = 11, TextColor3 = THEME.TEXT, TextXAlignment = Enum.TextXAlignment.Left, Text = "Duração (s)",
}, durRow)

local durBox = new("TextBox", {
    AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.fromOffset(54, 20),
    BackgroundColor3 = THEME.OFF, BorderSizePixel = 0, Font = Enum.Font.GothamBold, TextSize = 11,
    TextColor3 = THEME.TEXT, Text = tostring(STUDY.DURATION), ClearTextOnFocus = false,
}, durRow)
round(durBox, 5)
durBox.FocusLost:Connect(function()
    local n = tonumber(durBox.Text)
    if n then STUDY.DURATION = math.clamp(n, 1, 60) end
    durBox.Text = tostring(STUDY.DURATION)
end)

local studyStepLabel = new("TextLabel", {
    Size = UDim2.new(1, 0, 0, 14), BackgroundTransparency = 1, Font = Enum.Font.Gotham, TextSize = 10,
    TextColor3 = THEME.INFO, TextXAlignment = Enum.TextXAlignment.Left, Text = "Status: parado", LayoutOrder = 4,
}, studyCard)

local studyButton = new("TextButton", {
    Size = UDim2.new(1, 0, 0, 36), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, AutoButtonColor = false,
    Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = Color3.new(1, 1, 1), Text = "", LayoutOrder = 2,
}, studyPage)
round(studyButton, 8)
local studyGradient = new("UIGradient", { Rotation = 0, Color = ColorSequence.new(THEME.INFO, THEME.ACCENT) }, studyButton)
local studyText = buttonLabel(studyButton, 12, "AUTO ESTUDAR")

--==== ESP PAGE ====--
local espCard = card(espPage, 1)
createToggle(espCard, "ESP de NPCs", CONFIG.ESP_ENABLED, function(v)
    CONFIG.ESP_ENABLED = v
    if not v and clearAllESP then clearAllESP() end
end, 1)

local legend = new("Frame", { Size = UDim2.new(1, 0, 0, 16), BackgroundTransparency = 1, LayoutOrder = 2 }, espCard)
new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 10), VerticalAlignment = Enum.VerticalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder }, legend)

local function legendItem(color, text, order)
    local item = new("Frame", { Size = UDim2.fromOffset(0, 14), AutomaticSize = Enum.AutomaticSize.X, BackgroundTransparency = 1, LayoutOrder = order }, legend)
    new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 4), VerticalAlignment = Enum.VerticalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder }, item)
    local dot = new("Frame", { Size = UDim2.fromOffset(7, 7), BackgroundColor3 = color, BorderSizePixel = 0, LayoutOrder = 1 }, item)
    round(dot, 4)
    new("TextLabel", { Size = UDim2.fromOffset(0, 14), AutomaticSize = Enum.AutomaticSize.X, BackgroundTransparency = 1, Font = Enum.Font.Gotham, TextSize = 10, TextColor3 = THEME.MUTED, Text = text, LayoutOrder = 2 }, item)
end

legendItem(ESP_COLORS.free,     "Livre",    1)
legendItem(ESP_COLORS.cooldown, "Cooldown", 2)
legendItem(ESP_COLORS.target,   "Alvo",     3)

local espCount = new("TextLabel", {
    Size = UDim2.new(1, 0, 0, 14), BackgroundTransparency = 1, Font = Enum.Font.Gotham, TextSize = 10,
    TextColor3 = THEME.MUTED, TextXAlignment = Enum.TextXAlignment.Left, Text = "0 NPCs rastreados", LayoutOrder = 3,
}, espCard)

--==== INFO PAGE ====--
local infoCard = card(infoPage, 1)
new("TextLabel", { Size = UDim2.new(1, 0, 0, 14), BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 11, TextColor3 = THEME.TEXT, TextXAlignment = Enum.TextXAlignment.Left, Text = "KGS PANEL — v6", LayoutOrder = 1 }, infoCard)
new("TextLabel", { Size = UDim2.new(1, 0, 0, 12), BackgroundTransparency = 1, Font = Enum.Font.Gotham, TextSize = 10, TextColor3 = THEME.MUTED, TextXAlignment = Enum.TextXAlignment.Left, Text = "feito por KG$", LayoutOrder = 2 }, infoCard)
new("TextLabel", { Size = UDim2.new(1, 0, 0, 12), BackgroundTransparency = 1, Font = Enum.Font.Gotham, TextSize = 10, TextColor3 = THEME.MUTED, TextXAlignment = Enum.TextXAlignment.Left, Text = "NPC Interact • Premium • Abas + Auto Estudar", LayoutOrder = 3 }, infoCard)

selectTab("Farm")

--==== MINIMIZAR / DRAG ====--
local collapsed = false
minBtn.MouseButton1Click:Connect(function()
    collapsed = not collapsed
    local target = collapsed and UDim2.fromOffset(PANEL_W, HEADER_H) or UDim2.fromOffset(PANEL_W, PANEL_H)
    tween(main, 0.2, { Size = target })
    minBtn.Text = collapsed and "+" or "-"
end)

header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging  = true; dragStart = input.Position; startPos  = main.Position
    end
end)

connections[#connections + 1] = UIS.InputChanged:Connect(function(input)
    if not dragging then return end
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        local delta = input.Position - dragStart
        main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

connections[#connections + 1] = UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
end)

--==================== HELPERS ====================--
local function setStatus(txt, color)
    status.Text = txt
    statusDot.BackgroundColor3 = color or THEME.MUTED
end

local RED_GRAD = ColorSequence.new(Color3.fromRGB(244, 63, 94), Color3.fromRGB(190, 24, 93))

local function setButton(active)
    local farmOn    = active and mode == "farm"
    local missionOn = active and mode == "mission"
    local studyOn   = active and mode == "study"

    buttonText.Text = farmOn and "PARAR FARM NPC" or "FARM NPC"
    buttonGradient.Color = farmOn and RED_GRAD or ColorSequence.new(THEME.ACCENT, THEME.ACCENT2)

    missionText.Text = missionOn and "PARAR FARM MISSÃO" or "FARM MISSÃO"
    missionGradient.Color = missionOn and RED_GRAD or ColorSequence.new(THEME.PINK, THEME.ACCENT)
    
    if studyText and studyGradient then
        studyText.Text = studyOn and "PARAR ESTUDO" or "AUTO ESTUDAR"
        studyGradient.Color = studyOn and RED_GRAD or ColorSequence.new(THEME.INFO, THEME.ACCENT)
    end
end

local function getContainer()
    local direct = Workspace:FindFirstChild(CONFIG.CONTAINER)
    if direct then return direct end
    for _, d in ipairs(Workspace:GetDescendants()) do
        if d.Name == CONFIG.CONTAINER then return d end
    end
    return nil
end

local function getNpcPart(npc)
    if npc:IsA("BasePart") then return npc end
    local hrp = npc:FindFirstChild("HumanoidRootPart")
    if hrp and hrp:IsA("BasePart") then return hrp end
    if npc.PrimaryPart then return npc.PrimaryPart end
    for _, d in ipairs(npc:GetDescendants()) do
        if d:IsA("BasePart") then return d end
    end
    return nil
end

local function isAlive(npc)
    local hum = npc:FindFirstChildOfClass("Humanoid")
    if hum and hum.Health <= 0 then return false end
    return true
end

local function getHRP()
    local char = LP.Character
    return char and char:FindFirstChild("HumanoidRootPart") or nil
end

local function getHumanoid()
    local char = LP.Character
    return char and char:FindFirstChildOfClass("Humanoid") or nil
end

--==================== COOLDOWN POR NPC ====================--
local function onCooldown(npc)
    local until_ = cooldowns[npc]
    if not until_ then return false end
    if not npc.Parent then cooldowns[npc] = nil; return false end
    if os.clock() >= until_ then cooldowns[npc] = nil; return false end
    return true
end

local function setCooldown(npc, seconds) cooldowns[npc] = os.clock() + seconds end

local function minCooldownWait()
    local soonest = math.huge
    for npc, until_ in pairs(cooldowns) do
        if npc.Parent then
            local left = until_ - os.clock()
            if left < soonest then soonest = left end
        else cooldowns[npc] = nil end
    end
    if soonest == math.huge then return 0 end
    return math.max(soonest, 0)
end

local function countCooldown()
    local n = 0
    for npc in pairs(cooldowns) do
        if npc.Parent and onCooldown(npc) then n += 1 end
    end
    return n
end

--==================== ALVOS ====================--
local function isEligible(npc)
    return isAlive(npc) and getNpcPart(npc) ~= nil and not onCooldown(npc)
end

local function countRemaining(container)
    local n = 0
    for _, obj in ipairs(container:GetChildren()) do
        if isEligible(obj) then n += 1 end
    end
    return n
end

local function findNearest(container)
    local hrp = getHRP()
    if not hrp then return nil end
    local myPos = hrp.Position
    local best, bestDist = nil, math.huge
    for _, obj in ipairs(container:GetChildren()) do
        if isEligible(obj) then
            local part = getNpcPart(obj)
            if part then
                local d = (part.Position - myPos).Magnitude
                if d < bestDist then best, bestDist = obj, d end
            end
        end
    end
    return best, bestDist
end

local function boostPrompts(npc)
    for _, d in ipairs(npc:GetDescendants()) do
        if d:IsA("ProximityPrompt") then
            pcall(function() d.MaxActivationDistance = math.max(d.MaxActivationDistance, 80); d.HoldDuration = 0 end)
        end
    end
end

--==================== DETECÇÃO DE PROGRESSO ====================--
local function scanInventory(patterns)
    local containers = {}
    local bp = LP:FindFirstChild("Backpack")
    if bp then table.insert(containers, bp) end
    if LP.Character then table.insert(containers, LP.Character) end
    for _, c in ipairs(containers) do
        for _, item in ipairs(c:GetChildren()) do
            local n = item.Name:lower()
            for _, pat in ipairs(patterns) do
                if n:find(pat, 1, true) then return item end
            end
        end
    end
    return nil
end

local function scanValue(patterns)
    local roots = {}
    local pg = LP:FindFirstChild("PlayerGui")
    if pg then table.insert(roots, pg) end
    if LP.Character then table.insert(roots, LP.Character) end
    local best = nil
    for _, root in ipairs(roots) do
        for _, v in ipairs(root:GetDescendants()) do
            if v:IsA("IntValue") or v:IsA("NumberValue") then
                local n = v.Name:lower()
                for _, pat in ipairs(patterns) do
                    if n:find(pat, 1, true) then
                        local val = tonumber(v.Value) or 0
                        if not best or val > best then best = val end
                    end
                end
            end
        end
    end
    return best
end

local function detectMissionProgress()
    if scanInventory({"pasta", "documento", "protocolo", "folder"}) then MISSION_STATE.hasFolder = true end
    if scanInventory({"carimbo", "parecer", "stamp"}) then MISSION_STATE.hasStamp = true end
    local apoios = scanValue({"apoio", "support", "assinatura"})
    if apoios then MISSION_STATE.apoiosDone = math.max(MISSION_STATE.apoiosDone, apoios) end
    local step
    if not MISSION_STATE.hasFolder then step = "1. Pegar pasta"
    elseif CONFIG.MISSION_STF and not MISSION_STATE.hasStamp then step = "2. Carimbar STF"
    elseif MISSION_STATE.apoiosDone < CONFIG.APOIO_MIN then step = string.format("3. Coletar apoios (%d/%d)", MISSION_STATE.apoiosDone, CONFIG.APOIO_MIN)
    else step = "4. Entregar no Planalto" end
    return step
end

local function resetMissionState()
    MISSION_STATE.hasFolder  = false
    MISSION_STATE.hasStamp   = false
    MISSION_STATE.apoiosDone = 0
end

scanBtn.MouseButton1Click:Connect(function()
    local step = detectMissionProgress()
    stepLabel.Text = "Etapa: " .. step
    setStatus("Detectado: " .. step, THEME.INFO)
end)

resetBtn.MouseButton1Click:Connect(function()
    resetMissionState()
    stepLabel.Text = "Etapa: 1. Pegar pasta"
    setStatus("Progresso resetado", THEME.WARN)
end)

--==================== ESP ====================--
local espFolder = new("Folder", { Name = "NPCInteractESP" }, guiParent)
local espObjects = {}
local espContainer, espContainerT = nil, 0

local function createESP(npc, part)
    local box = new("SelectionBox", { Adornee = npc, LineThickness = 0.04, Color3 = ESP_COLORS.free, SurfaceColor3 = ESP_COLORS.free, SurfaceTransparency = 0.88 }, espFolder)
    local bb = new("BillboardGui", { Adornee = part, AlwaysOnTop = true, Size = UDim2.fromOffset(150, 38), StudsOffset = Vector3.new(0, 4.5, 0), LightInfluence = 0, ResetOnSpawn = false }, espFolder)
    local pill = new("Frame", { Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = THEME.BG, BackgroundTransparency = 0.2, BorderSizePixel = 0 }, bb)
    round(pill, 8)
    local pillStroke = outline(pill, ESP_COLORS.free, 1.2, 0)
    local nameLbl = new("TextLabel", { Size = UDim2.new(1, -8, 0, 17), Position = UDim2.new(0, 4, 0, 3), BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = THEME.TEXT, TextTruncate = Enum.TextTruncate.AtEnd, Text = npc.Name }, pill)
    local infoLbl = new("TextLabel", { Size = UDim2.new(1, -8, 0, 14), Position = UDim2.new(0, 4, 0, 20), BackgroundTransparency = 1, Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = ESP_COLORS.free, Text = "" }, pill)
    return { box = box, bb = bb, stroke = pillStroke, nameLbl = nameLbl, infoLbl = infoLbl }
end

local function clearESP(npc)
    local o = espObjects[npc]
    if o then
        pcall(function() o.box:Destroy() end)
        pcall(function() o.bb:Destroy() end)
        espObjects[npc] = nil
    end
end

clearAllESP = function() for npc in pairs(espObjects) do clearESP(npc) end end

local function resolveContainer()
    if activeContainer and activeContainer.Parent then return activeContainer end
    if espContainer and espContainer.Parent then return espContainer end
    if os.clock() - espContainerT >= 2 then espContainerT = os.clock(); espContainer = getContainer() end
    return espContainer
end

local function tick()
    local container = resolveContainer()
    if container then setStats(doneCount, countRemaining(container), countCooldown()) end
    if not CONFIG.ESP_ENABLED then clearAllESP(); espCount.Text = "ESP desligado"; return end
    if not container then clearAllESP(); espCount.Text = "Container não encontrado"; return end
    local hrp = getHRP()
    local myPos = hrp and hrp.Position
    local seen = {}
    local count = 0
    for _, npc in ipairs(container:GetChildren()) do
        local part = getNpcPart(npc)
        if part and isAlive(npc) then
            local dist = myPos and (part.Position - myPos).Magnitude or 0
            if dist <= CONFIG.ESP_MAX_DIST then
                seen[npc] = true; count += 1
                local o = espObjects[npc]
                if not o then o = createESP(npc, part); espObjects[npc] = o end
                if o.bb.Adornee ~= part then o.bb.Adornee = part end
                local color, state
                if running and npc == currentTarget then color, state = ESP_COLORS.target, "ALVO"
                elseif onCooldown(npc) then
                    local left = math.max((cooldowns[npc] or 0) - os.clock(), 0)
                    color, state = ESP_COLORS.cooldown, string.format("%ds", math.ceil(left))
                else color, state = ESP_COLORS.free, "livre" end
                o.box.Color3 = color; o.box.SurfaceColor3 = color; o.stroke.Color = color
                o.nameLbl.Text = npc.Name; o.infoLbl.TextColor3 = color
                o.infoLbl.Text = string.format("%d studs  •  %s", dist, state)
            end
        end
    end
    for npc in pairs(espObjects) do if not seen[npc] then clearESP(npc) end end
    espCount.Text = string.format("%d NPCs rastreados", count)
end

local tickAcc = 0
connections[#connections + 1] = RunService.Heartbeat:Connect(function(dt)
    tickAcc += dt
    if tickAcc < CONFIG.ESP_UPDATE then return end
    tickAcc = 0
    pcall(tick)
end)

--==================== RAYCAST / FRENTE ====================--
local function newRayParams(ignore)
    local params = RaycastParams.new()
    local okFilter = pcall(function() params.FilterType = Enum.RaycastFilterType.Exclude end)
    if not okFilter then pcall(function() params.FilterType = Enum.RaycastFilterType.Blacklist end) end
    params.FilterDescendantsInstances = ignore
    params.IgnoreWater = true
    pcall(function() params.RespectCanCollide = true end)
    return params
end

local function raycastClear(fromPos, toPos, ignore)
    local res = Workspace:Raycast(fromPos, toPos - fromPos, newRayParams(ignore))
    if res then return res.Distance end
    return nil
end

local function buildFrontCF(part, npc)
    local npcPos = part.Position
    local dir
    if CONFIG.FRONT_MODE == "npc" then dir = part.CFrame.LookVector
    else
        local hrp = getHRP()
        dir = hrp and (npcPos - hrp.Position) or part.CFrame.LookVector
    end
    dir = Vector3.new(dir.X, 0, dir.Z)
    if dir.Magnitude < 0.05 then dir = Vector3.new(part.CFrame.LookVector.X, 0, part.CFrame.LookVector.Z) end
    if dir.Magnitude < 0.05 then dir = Vector3.new(0, 0, 1) end
    dir = dir.Unit
    local sign = (CONFIG.FRONT_MODE == "npc") and 1 or -1
    local baseY = npcPos.Y + CONFIG.OFFSET_Y
    local dist = CONFIG.FRONT_DISTANCE
    local ignore = { npc }
    if LP.Character then ignore[#ignore + 1] = LP.Character end
    local fromPos = npcPos + Vector3.new(0, 0.5, 0)
    local hitDist = raycastClear(fromPos, fromPos + dir * sign * (dist + 1), ignore)
    if hitDist then dist = math.clamp(hitDist - 1.0, CONFIG.FRONT_DIST_MIN, CONFIG.FRONT_DISTANCE) end
    local standPos = Vector3.new(npcPos.X + dir.X * dist * sign, baseY, npcPos.Z + dir.Z * dist * sign)
    local facePos = Vector3.new(npcPos.X, baseY, npcPos.Z)
    return CFrame.lookAt(standPos, facePos)
end

local function flatDist(a, b)
    local dx = a.X - b.X
    local dz = a.Z - b.Z
    return math.sqrt(dx * dx + dz * dz)
end

--==================== TECLA SPACE ====================--
local function tapSpace()
    task.spawn(function()
        pcall(function()
            VIM:SendKeyEvent(true, "Space", false, game)
            task.wait(CONFIG.SPACE_HOLD)
            VIM:SendKeyEvent(false, "Space", false, game)
        end)
    end)
end

local function releaseSpace()
    pcall(function() VIM:SendKeyEvent(false, "Space", false, game) end)
end

--==================== VALIDAÇÃO DE WAYPOINT ====================--
local function probeGround(pos, ignore)
    local from = pos + Vector3.new(0, CONFIG.PROBE_UP, 0)
    local to   = pos - Vector3.new(0, CONFIG.PROBE_DOWN, 0)
    return Workspace:Raycast(from, to - from, newRayParams(ignore))
end

local function hitWalkable(hit, refY)
    if not hit then return false end
    if hit.Normal.Y < CONFIG.MIN_NORMAL_Y then return false end
    if math.abs(hit.Position.Y - refY) > CONFIG.MAX_GROUND_DELTA then return false end
    return true
end

local function waypointWalkable(wpPos, wpY, fromPos, ignore)
    local dir = Vector3.new(wpPos.X - fromPos.X, 0, wpPos.Z - fromPos.Z)
    if dir.Magnitude < 0.1 then dir = Vector3.new(0, 0, 1) end
    dir = dir.Unit
    local side = Vector3.new(-dir.Z, 0, dir.X) * CONFIG.PROBE_SIDE
    if not hitWalkable(probeGround(wpPos, ignore), wpY) then return false end
    local left  = hitWalkable(probeGround(wpPos + side, ignore), wpY)
    local right = hitWalkable(probeGround(wpPos - side, ignore), wpY)
    return left or right
end

--==================== CAMINHADA COM ROTA ====================--
local function walkDynamic(getTarget, eps, timeout, extraIgnore, label)
    local hrp = getHRP()
    local hum = getHumanoid()
    if not hrp or not hum then return false end

    local ignore = {}
    if LP.Character then ignore[#ignore + 1] = LP.Character end
    if activeContainer then ignore[#ignore + 1] = activeContainer end
    if extraIgnore then for _, v in ipairs(extraIgnore) do ignore[#ignore + 1] = v end end

    local oldSpeed = hum.WalkSpeed
    hum.WalkSpeed = CONFIG.SPEED

    local t0 = os.clock()
    local arrived = false
    local lastCompute = 0
    local lastTarget = nil
    local waypoints, wpIndex = nil, 1
    local forceRepath = false
    local blockConn = nil
    local computing = false

    local validIdx, validOk = nil, true
    local wpStartT = os.clock()

    local progPos = hrp.Position
    local progT = os.clock()
    local stuckHits = 0

    local recovering = false
    local lowT = 0
    local samplePos = hrp.Position
    local sampleT = os.clock()
    local lastSpace = 0
    local cycleStart = 0

    local function clearPath()
        if blockConn then pcall(function() blockConn:Disconnect() end); blockConn = nil end
        waypoints = nil; wpIndex = 1; validIdx = nil
    end

    local function advanceWaypoint()
        wpIndex += 1; validIdx = nil; wpStartT = os.clock(); progPos = hrp.Position; progT = os.clock(); stuckHits = 0
    end

    local function requestPath(fromPos, toPos)
        if computing then return end
        computing = true
        task.spawn(function()
            local path = Pathfinding:CreatePath(AGENT_PARAMS)
            local ok = pcall(function() path:ComputeAsync(fromPos, toPos) end)
            if ok and running and path.Status == Enum.PathStatus.Success then
                local wps = path:GetWaypoints()
                if #wps > 1 then table.remove(wps, 1) end
                if #wps > 0 then
                    if blockConn then pcall(function() blockConn:Disconnect() end) end
                    blockConn = path.Blocked:Connect(function() forceRepath = true end)
                    waypoints = wps; wpIndex = 1; validIdx = nil; wpStartT = os.clock()
                    progPos = hrp.Position; progT = os.clock(); stuckHits = 0
                end
            end
            computing = false
        end)
    end

    while running do
        if os.clock() - t0 > timeout then break end
        local raw = getTarget()
        if not raw then break end
        local targetPos = Vector3.new(raw.X, hrp.Position.Y, raw.Z)
        if flatDist(targetPos, hrp.Position) <= eps then arrived = true; break end

        local now = os.clock()
        if now - sampleT >= CONFIG.SPEED_SAMPLE then
            local v = flatDist(hrp.Position, samplePos) / math.max(now - sampleT, 0.001)
            samplePos = hrp.Position; sampleT = now
            if v < CONFIG.MIN_SPEED then
                lowT += CONFIG.SPEED_SAMPLE
                if lowT >= CONFIG.LOW_SPEED_TIME and not recovering then
                    recovering = true; cycleStart = os.clock(); lastSpace = 0
                    if label then setStatus("Recuperando: " .. label, THEME.WARN) end
                    forceRepath = true; lastCompute = 0
                end
            else lowT = 0 end
        end

        if recovering then
            local t = os.clock()
            if (t - cycleStart) >= (CONFIG.RECOVERY_CYCLE + CONFIG.RECOVERY_PAUSE) then cycleStart = t end
            if (t - cycleStart) < CONFIG.RECOVERY_CYCLE and (t - lastSpace) >= CONFIG.SPACE_INTERVAL then lastSpace = t; tapSpace() end
        end

        local needRepath = forceRepath or recovering or (not waypoints) or (lastTarget and flatDist(targetPos, lastTarget) > CONFIG.REPATH_DIST)
        local repathGap = recovering and CONFIG.RECOVERY_REPATH or CONFIG.REPATH_COOLDOWN

        if needRepath and not computing and (os.clock() - lastCompute) >= repathGap then
            forceRepath = false; lastCompute = os.clock(); lastTarget = targetPos
            requestPath(hrp.Position, targetPos)
        end

        local moved = false
        local guard = 0
        local wp = waypoints and waypoints[wpIndex]

        while wp and guard < 8 do
            guard += 1
            local wpPos = Vector3.new(wp.Position.X, hrp.Position.Y, wp.Position.Z)
            if flatDist(wpPos, hrp.Position) <= CONFIG.WAYPOINT_EPS then
                if wp.Action == Enum.PathWaypointAction.Jump then hum.Jump = true end
                advanceWaypoint(); wp = waypoints and waypoints[wpIndex]
            else
                if recovering then validOk = true
                elseif validIdx ~= wpIndex then validOk = waypointWalkable(wpPos, wp.Position.Y, hrp.Position, ignore); validIdx = wpIndex end

                if validOk then hum:MoveTo(wpPos); moved = true; break
                else advanceWaypoint(); wp = waypoints and waypoints[wpIndex] end
            end
        end

        if not moved then
            hum:MoveTo(targetPos)
            if waypoints and wpIndex > #waypoints and not computing then forceRepath = true; lastCompute = 0 end
        end

        local dt = RunService.Heartbeat:Wait()

        if not recovering and wp and validIdx == wpIndex then
            local limit = math.max(CONFIG.WAYPOINT_TIMEOUT, (flatDist(wp.Position, hrp.Position) / math.max(CONFIG.SPEED, 1)) * 2.5)
            if os.clock() - wpStartT > limit then advanceWaypoint(); if not computing then forceRepath = true; lastCompute = 0 end end
        end

        if os.clock() - progT >= CONFIG.STUCK_WINDOW then
            local movedDist = flatDist(hrp.Position, progPos)
            progPos = hrp.Position; progT = os.clock()
            if movedDist < CONFIG.STUCK_MIN_MOVE then
                stuckHits += 1; hum.Jump = true
                if stuckHits >= CONFIG.STUCK_RETRIES then stuckHits = 0; advanceWaypoint(); if not computing then forceRepath = true; lastCompute = 0 end end
            else stuckHits = 0 end
        end
    end

    releaseSpace()
    hum:MoveTo(hrp.Position)
    hum.WalkSpeed = oldSpeed
    clearPath()
    return arrived
end

local function followFrontPhysics(npc, part)
    return walkDynamic(function()
        if not npc.Parent then return nil end
        if not part or not part.Parent then part = getNpcPart(npc); if not part then return nil end end
        return buildFrontCF(part, npc).Position
    end, CONFIG.PHYS_EPS, CONFIG.APPROACH_TIMEOUT, { npc }, npc.Name)
end

--==================== MOVIMENTO CFrame ====================--
local function followFrontCFrame(npc, part, speed)
    local hrp = getHRP()
    if not hrp then return false end
    if not part then return false end

    local wasAnchored = hrp.Anchored
    hrp.Anchored = true

    local cv = Instance.new("CFrameValue")
    cv.Value = hrp.CFrame
    local conn = cv:GetPropertyChangedSignal("Value"):Connect(function() local h = getHRP(); if h then h.CFrame = cv.Value end end)

    local tw
    local function retarget(targetCF, dur)
        if tw then pcall(function() tw:Cancel() end) end
        tw = TweenService:Create(cv, TweenInfo.new(dur, Enum.EasingStyle.Linear), { Value = targetCF })
        tw:Play()
    end

    local t0 = os.clock()
    local arrived = false
    local dt = 1 / 60

    while running do
        if os.clock() - t0 > CONFIG.APPROACH_TIMEOUT then break end
        if not npc.Parent then break end
        if not part.Parent then part = getNpcPart(npc); if not part then break end end
        local target = buildFrontCF(part, npc)
        local dist = (target.Position - hrp.Position).Magnitude

        if dist <= CONFIG.ARRIVE_EPS then
            retarget(target, math.max(dist / math.max(speed, 1), 0.03))
            local current = tw
            while running and current.PlaybackState == Enum.PlaybackState.Playing do RunService.Heartbeat:Wait() end
            arrived = true; break
        end

        retarget(target, math.max(dist / math.max(speed, 1), dt * 1.5))
        dt = RunService.Heartbeat:Wait()
    end

    if tw then pcall(function() tw:Cancel() end) end
    conn:Disconnect(); cv:Destroy()
    hrp.Anchored = wasAnchored
    return arrived
end

local function followFront(npc, part, speed)
    if CONFIG.USE_PHYSICS then return followFrontPhysics(npc, part) end
    return followFrontCFrame(npc, part, speed)
end

--==================== INTERAÇÃO ====================--
local function pressE()
    for i = 1, CONFIG.PRESS_COUNT do
        if not running then break end
        pcall(function()
            VIM:SendKeyEvent(true, "E", false, game)
            task.wait(CONFIG.PRESS_HOLD)
            VIM:SendKeyEvent(false, "E", false, game)
        end)
        if i < CONFIG.PRESS_COUNT then task.wait(CONFIG.PRESS_INTERVAL) end
    end
end

--==================== LOOP ====================--
local function stop()
    running = false; currentTarget = nil
    releaseSpace()
    local hrp = getHRP()
    local hum = getHumanoid()
    if hrp and hum then pcall(function() hum:MoveTo(hrp.Position) end) end
    setStatus("Parado", THEME.MUTED)
    setButton(false)
end

local function start()
    if running then return end
    applySpeed()
    local hrp = getHRP()
    if not hrp then setStatus("Personagem não encontrado", THEME.BAD); return end

    cooldowns = {}; doneCount = 0; mode = "farm"; running = true; setButton(true); setStatus("Procurando NPCs...", THEME.INFO)

    task.spawn(function()
        local container = getContainer()
        if not container then setStatus("PopulacaoNPC não encontrado", THEME.BAD); stop(); return end
        activeContainer = container

        local remaining = countRemaining(container)
        if remaining == 0 then setStatus("Nenhum NPC válido encontrado", THEME.BAD); stop(); return end
        setStatus("Rodando...", THEME.ACCENT)

        local failed = false
        while running do
            if not container or not container.Parent then
                container = getContainer()
                if not container then setStatus("PopulacaoNPC não encontrado", THEME.BAD); failed = true; break end
                activeContainer = container
            end

            local npc = findNearest(container)
            currentTarget = npc
            if not npc then
                if CONFIG.INFINITE and running then
                    local waitSec = math.min(minCooldownWait() + 0.15, CONFIG.MAX_WAIT)
                    setStatus(string.format("Aguardando cooldown (%.1fs)...", waitSec), THEME.WARN)
                    local wt = os.clock()
                    while running and (os.clock() - wt) < waitSec do task.wait(0.1) end
                    continue
                end
                break
            end

            boostPrompts(npc)
            setStatus("Indo: " .. npc.Name, THEME.INFO)
            local part = getNpcPart(npc)
            local ok = false
            if part then ok = followFront(npc, part, CONFIG.SPEED) end

            if ok and running then
                setStatus("Interagindo: " .. npc.Name, THEME.PINK)
                task.wait(CONFIG.SETTLE_DELAY)
                pressE()
                setCooldown(npc, CONFIG.COOLDOWN + CONFIG.COOLDOWN_PAD)
                doneCount += 1
                setStats(doneCount, countRemaining(container), countCooldown())
            elseif running then
                setStatus("Falhou: " .. npc.Name, THEME.BAD)
                setCooldown(npc, CONFIG.FAIL_COOLDOWN)
            end
            task.wait(CONFIG.NPC_COOLDOWN)
        end

        local finishedNaturally = running
        running = false; currentTarget = nil; setButton(false)
        if finishedNaturally and not failed then setStatus("Concluído", THEME.GOOD) end
    end)
end

--==================== MISSÃO ====================--
local MISSION = {
    CONGRESSO_IN  = "EntradasSaidas.CongressoEntrada.Pivo.AcessoPrompt",
    CONGRESSO_OUT = "EntradasSaidas.CongressoSaida.Pivo.AcessoPrompt",
    PASTA         = "AssessoriaParadas.Protocolo_Congresso.Balcao.AssessoriaParadaPrompt",
    STF_IN        = "EntradasSaidas.SupremoEntrada.Pivo.AcessoPrompt",
    STF_OUT       = "EntradasSaidas.SupremoSaida.Pivo.AcessoPrompt",
    STF_PARECER   = "AssessoriaParadas.Protocolo_STF.Balcao.AssessoriaParadaPrompt",
    PLANALTO_IN   = "EntradasSaidas.PlantaltoEntrada.Pivo.AcessoPrompt",
    PASTA_MODEL    = "AssessoriaParadas.Protocolo_Congresso",
    STF_MODEL      = "AssessoriaParadas.Protocolo_STF",
    PLANALTO_MODEL = "AssessoriaParadas.Protocolo_Planalto",
    DELIVER_WORDS = { "entreg", "pasta", "documento" },
    PLANALTO_OUT  = "EntradasSaidas.PlanaltoSaida.Pivo.AcessoPrompt",
}

MISSION.POS = {
    [MISSION.CONGRESSO_IN]   = Vector3.new(417.8, 9.4, 665.7),
    [MISSION.CONGRESSO_OUT]  = Vector3.new(-500.0, 5.4, 376.7),
    [MISSION.STF_IN]         = Vector3.new(233.8, 8.4, 816.7),
    [MISSION.STF_OUT]        = Vector3.new(233.8, 8.4, 825.2),
    [MISSION.PLANALTO_IN]    = Vector3.new(228.5, 12.4, 544.7),
    [MISSION.PLANALTO_OUT]   = Vector3.new(241.4, 12.4, 535.6),
    [MISSION.PASTA_MODEL]    = Vector3.new(-478.0, 2.5, 364.0),
    [MISSION.STF_MODEL]      = Vector3.new(248.2, 4.8, 827.0),
    [MISSION.PLANALTO_MODEL] = Vector3.new(246.0, 8.9, 544.0),
}

local function streamAt(pos, timeout)
    if not pos or not Workspace.StreamingEnabled then return end
    pcall(function() LP:RequestStreamAroundAsync(pos, timeout or 3) end)
end

local function findPromptByPath(path)
    local cur = Workspace
    for name in string.gmatch(path, "[^%.]+") do
        cur = cur and cur:FindFirstChild(name)
        if not cur then return nil end
    end
    if cur and cur:IsA("ProximityPrompt") then return cur end
    return nil
end

local function promptPos(prompt)
    local p = prompt and prompt.Parent
    if not p then return nil end
    if p:IsA("BasePart") then return p.Position end
    if p:IsA("Attachment") then return p.WorldPosition end
    if p:IsA("Model") then local ok, cf = pcall(function() return p:GetPivot() end); if ok then return cf.Position end end
    return nil
end

local function boostPrompt(prompt)
    pcall(function()
        prompt.MaxActivationDistance = math.max(prompt.MaxActivationDistance, 40)
        prompt.HoldDuration = 0
        prompt.RequiresLineOfSight = false
    end)
end

local function firePrompt(prompt)
    boostPrompt(prompt)
    if typeof(fireproximityprompt) == "function" then
        local ok = pcall(function() fireproximityprompt(prompt) end)
        if ok then return true end
    end
    pressE()
    return true
end

local function missionWait(sec)
    local t = os.clock()
    while running and (os.clock() - t) < sec do task.wait(0.05) end
    return running
end

local function waitPrompt(path, pos, sec)
    local t = os.clock()
    local p = findPromptByPath(path)
    while not p and running and (os.clock() - t) < sec do streamAt(pos, 2); task.wait(0.15); p = findPromptByPath(path) end
    return p
end

local function walkToPrompt(path, label, eps)
    local known = MISSION.POS[path]
    local prompt = findPromptByPath(path)
    if not prompt and known then setStatus("Carregando mapa: " .. label, THEME.WARN); prompt = waitPrompt(path, known, 3) end
    local pos = (prompt and promptPos(prompt)) or known
    if not pos then setStatus("Não achei: " .. label, THEME.BAD); return nil end
    if prompt then boostPrompt(prompt) end

    setStatus("Indo: " .. label, THEME.INFO)
    local e = eps or 4
    local ok = walkDynamic(function() return pos end, e, 40, nil, label)
    if not ok and running then streamAt(pos, 3); ok = walkDynamic(function() return pos end, e + 2, 25, nil, label) end
    if not ok or not running then return nil end
    if not (prompt and prompt.Parent) then prompt = waitPrompt(path, pos, 5) end
    if not prompt then setStatus("Prompt não apareceu: " .. label, THEME.BAD); return nil end
    boostPrompt(prompt)
    return prompt
end

local function passDoor(path, label)
    local prompt = walkToPrompt(path, label, 4)
    if not prompt or not running then return false end
    setStatus("Porta: " .. label, THEME.PINK)
    if not missionWait(0.2) then return false end
    local hrp = getHRP()
    local before = hrp and hrp.Position
    firePrompt(prompt)
    local t = os.clock()
    while running and (os.clock() - t) < 2 do
        local h = getHRP()
        if h and before and (h.Position - before).Magnitude > 5 then break end
        task.wait(0.05)
    end
    return missionWait(0.5)
end

local function findInstanceByPath(path)
    local cur = Workspace
    for name in string.gmatch(path, "[^%.]+") do
        cur = cur and cur:FindFirstChild(name)
        if not cur then return nil end
    end
    return cur
end

local function counterPrompt(modelPath)
    local model = findInstanceByPath(modelPath)
    if not model then return nil, nil end
    for _, d in ipairs(model:GetDescendants()) do
        if d:IsA("ProximityPrompt") then return d, model end
    end
    return nil, model
end

local function counterPos(model, prompt)
    local p = prompt and promptPos(prompt)
    if p then return p end
    local b = model:FindFirstChild("Balcao")
    if b and b:IsA("BasePart") then return b.Position end
    local ok, cf = pcall(function() return model:GetPivot() end)
    if ok then return cf.Position end
    return nil
end

local function goToCounter(modelPath, label, eps)
    local known = MISSION.POS[modelPath]
    local prompt, model = counterPrompt(modelPath)
    if not model and known then streamAt(known, 3); prompt, model = counterPrompt(modelPath) end
    local pos = (model and counterPos(model, prompt)) or known
    if not pos then return nil, "Não achei: " .. label end

    setStatus("Indo: " .. label, THEME.INFO)
    local e = eps or 6
    local ok = walkDynamic(function() return pos end, e, 40, nil, label)
    if not ok and running then ok = walkDynamic(function() return pos end, e + 3, 25, nil, label) end
    if not ok or not running then return nil, "Não consegui chegar: " .. label end

    streamAt(pos, 2)
    prompt = counterPrompt(modelPath)
    local t = os.clock()
    while running and not (prompt and prompt.Enabled) and (os.clock() - t) < 8 do
        setStatus("Esperando prompt: " .. label, THEME.WARN)
        task.wait(0.2)
        prompt = counterPrompt(modelPath)
    end
    if not prompt then return nil, "Sem prompt no balcão: " .. label end
    if not prompt.Enabled then return nil, "Prompt desativado no balcão: " .. label end
    return prompt
end

local function useCounter(modelPath, label)
    local prompt, why = goToCounter(modelPath, label, 6)
    if not running then return false end
    if not prompt then setStatus(why or ("Falhou: " .. label), THEME.BAD); return false end
    setStatus("Interagindo: " .. label, THEME.PINK)
    if not missionWait(0.3) then return false end
    firePrompt(prompt)
    return missionWait(1.0)
end

local function insideCongresso()
    local hrp = getHRP()
    local a = MISSION.POS[MISSION.CONGRESSO_IN]
    local b = MISSION.POS[MISSION.CONGRESSO_OUT]
    if not hrp or not a or not b then return false end
    return (b - hrp.Position).Magnitude < (a - hrp.Position).Magnitude
end

local function collectApoios(target)
    local container = getContainer()
    if not container then setStatus("PopulacaoNPC não encontrado", THEME.BAD); return false end
    activeContainer = container

    local got = 0
    local idle = 0
    doneCount = 0

    while running and got < target do
        if not container.Parent then container = getContainer(); if not container then return false end; activeContainer = container end
        local npc = findNearest(container)
        currentTarget = npc
        if not npc then
            idle += 1
            if idle > 12 then return false end
            local waitSec = math.min(minCooldownWait() + 0.15, CONFIG.MAX_WAIT)
            setStatus(string.format("Apoios %d/%d: aguardando (%.1fs)", got, target, waitSec), THEME.WARN)
            missionWait(waitSec); continue
        end
        idle = 0
        boostPrompts(npc)
        setStatus(string.format("Apoios %d/%d: indo %s", got, target, npc.Name), THEME.INFO)
        local part = getNpcPart(npc)
        local ok = false
        if part then ok = followFront(npc, part, CONFIG.SPEED) end
        if ok and running then
            setStatus(string.format("Apoios %d/%d: %s", got, target, npc.Name), THEME.PINK)
            task.wait(CONFIG.SETTLE_DELAY)
            pressE()
            setCooldown(npc, CONFIG.COOLDOWN + CONFIG.COOLDOWN_PAD)
            got += 1; doneCount = got
        elseif running then setCooldown(npc, CONFIG.FAIL_COOLDOWN) end
        task.wait(CONFIG.NPC_COOLDOWN)
    end
    currentTarget = nil
    return running and got >= target
end

local function findDeliveryPrompt()
    local hrp = getHRP()
    if not hrp then return nil end
    local best, bestD = nil, 40
    for _, d in ipairs(Workspace:GetDescendants()) do
        if d:IsA("ProximityPrompt") and d.Enabled then
            local txt = (d.ActionText .. " " .. d.ObjectText):lower()
            local isDoor = txt:find("entrar", 1, true) or txt:find("sair", 1, true)
            if not isDoor then
                for _, w in ipairs(MISSION.DELIVER_WORDS) do
                    if txt:find(w, 1, true) then
                        local p = promptPos(d)
                        if p then
                            local dist = (p - hrp.Position).Magnitude
                            if dist < bestD then best, bestD = d, dist end
                        end
                        break
                    end
                end
            end
        end
    end
    return best
end

local function deliver()
    local found, why = goToCounter(MISSION.PLANALTO_MODEL, "balcao do Planalto", 6)
    if not running then return false end
    if not found then
        setStatus("Procurando prompt de entrega...", THEME.INFO)
        local t = os.clock()
        while running and (os.clock() - t) < 3 do
            found = findDeliveryPrompt()
            if found then break end
            task.wait(0.5)
        end
        if not running then return false end
        if not found then return false, why or "Falhou: chegar ao Planalto" end
    end
    if not found then return false, "No Planalto, mas sem prompt de entrega. Rode o scanner aqui." end
    setStatus("Entregando...", THEME.PINK)
    firePrompt(found)
    if not missionWait(1.0) then return false end
    return running
end

local function startMission()
    if running then return end
    applySpeed()
    if not getHRP() then setStatus("Personagem não encontrado", THEME.BAD); return end

    mode = "mission"; cooldowns = {}; doneCount = 0; running = true; setButton(true); setStatus("Iniciando missão...", THEME.INFO)

    task.spawn(function()
        local ok, msg = pcall(function()
            if MISSION_STATE.enabled then
                local step = detectMissionProgress()
                stepLabel.Text = "Etapa: " .. step
                setStatus("Continuando de: " .. step, THEME.INFO)
                missionWait(0.5)
            end

            repeat
                if MISSION_STATE.enabled and MISSION_STATE.hasFolder then
                    setStatus("Pasta já obtida, pulando Congresso", THEME.INFO)
                    missionWait(0.3)
                else
                    if not insideCongresso() then
                        if not passDoor(MISSION.CONGRESSO_IN, "porta do Congresso") then return "Falhou: entrar no Congresso" end
                    end
                    if not useCounter(MISSION.PASTA_MODEL, "Retirar pasta") then return "Falhou: retirar a pasta" end
                    if not passDoor(MISSION.CONGRESSO_OUT, "saída do Congresso") then return "Falhou: sair do Congresso" end
                    MISSION_STATE.hasFolder = true
                    stepLabel.Text = "Etapa: " .. detectMissionProgress()
                end

                if CONFIG.MISSION_STF then
                    if MISSION_STATE.enabled and MISSION_STATE.hasStamp then
                        setStatus("STF já carimbado, pulando", THEME.INFO)
                        missionWait(0.3)
                    else
                        if not passDoor(MISSION.STF_IN, "porta do STF") then return "Falhou: entrar no STF" end
                        if not useCounter(MISSION.STF_MODEL, "Carimbar parecer") then return "Falhou: carimbar parecer" end
                        if not passDoor(MISSION.STF_OUT, "saída do STF") then return "Falhou: sair do STF" end
                        MISSION_STATE.hasStamp = true
                        stepLabel.Text = "Etapa: " .. detectMissionProgress()
                    end
                end

                local lo = math.clamp(CONFIG.APOIO_MIN, 1, 5)
                local hi = math.clamp(CONFIG.APOIO_MAX, lo, 5)
                local target = math.random(lo, hi)
                local already = (MISSION_STATE.enabled and MISSION_STATE.apoiosDone) or 0
                local needed  = target - already
                if needed > 0 then
                    if not collectApoios(needed) then return "Falhou: coletar apoios" end
                else setStatus("Apoios já completos, pulando", THEME.INFO) end
                MISSION_STATE.apoiosDone = target
                stepLabel.Text = "Etapa: " .. detectMissionProgress()

                local delivered, derr = deliver()
                if not delivered then return derr or "Falhou: entrega" end
                resetMissionState()
                stepLabel.Text = "Etapa: 1. Pegar pasta"
            until not (running and CONFIG.MISSION_LOOP)
        end)

        local wasRunning = running
        running = false; currentTarget = nil; setButton(false)
        if wasRunning then
            if not ok then setStatus("Erro: " .. tostring(msg), THEME.BAD)
            elseif msg then setStatus(msg, THEME.BAD)
            else setStatus("Missão concluída", THEME.GOOD) end
        end
    end)
end

--==================== AUTO ESTUDAR ====================--
local function guiRoots()
    local roots = {}
    local ok, hui = pcall(function() return gethui and gethui() or nil end)
    if ok and hui then table.insert(roots, hui) end
    local ok2, cg = pcall(function() return CoreGui end)
    if ok2 and cg then table.insert(roots, cg) end
    local pg = LP:FindFirstChild("PlayerGui")
    if pg then table.insert(roots, pg) end
    return roots
end

local function findVisibleButtons(needle)
    needle = (needle or ""):lower()
    local out = {}
    for _, root in ipairs(guiRoots()) do
        for _, d in ipairs(root:GetDescendants()) do
            if d:IsA("GuiButton") and d.Visible then
                local vis, p = true, d
                while p and p ~= root do
                    if p:IsA("GuiObject") and not p.Visible then vis = false; break end
                    p = p.Parent
                end
                if vis and d.AbsoluteSize.Magnitude > 4 then
                    local hit = false
                    if d:IsA("TextButton") and (d.Text or ""):lower():find(needle, 1, true) then hit = true end
                    if not hit then
                        for _, c in ipairs(d:GetDescendants()) do
                            if c:IsA("TextLabel") and (c.Text or ""):lower():find(needle, 1, true) then hit = true; break end
                        end
                    end
                    if hit then table.insert(out, d) end
                end
            end
        end
    end
    return out
end

-- Procura o botão azul (ou o maior botão) que não esteja escrito "indisponível"
local function findStudyButtonAuto()
    local blueBtn = nil
    local largestBtn = nil
    local maxArea = 0

    for _, root in ipairs(guiRoots()) do
        for _, d in ipairs(root:GetDescendants()) do
            if d:IsA("GuiButton") and d.Visible then
                local vis, p = true, d
                while p and p ~= root do
                    if p:IsA("GuiObject") and not p.Visible then vis = false; break end
                    p = p.Parent
                end
                
                if vis and d.AbsoluteSize.X > 80 and d.AbsoluteSize.Y > 20 then
                    local txt = ""
                    if d:IsA("TextButton") then txt = txt .. " " .. d.Text:lower() end
                    for _, c in ipairs(d:GetDescendants()) do
                        if c:IsA("TextLabel") then txt = txt .. " " .. c.Text:lower() end
                    end
                    
                    if not txt:find("indispon") then
                        local c = d.BackgroundColor3
                        local isBlue = (c.B > 0.5 and c.B > c.R + 0.1)
                        
                        if not isBlue then
                            for _, child in ipairs(d:GetChildren()) do
                                if child:IsA("UIGradient") then
                                    for _, kp in ipairs(child.Color.Keypoints) do
                                        local kc = kp.Value
                                        if kc.B > 0.5 and kc.B > kc.R + 0.1 then isBlue = true end
                                    end
                                end
                            end
                        end
                        
                        if d:IsA("ImageButton") then
                            local ic = d.ImageColor3
                            if ic.B > 0.5 and ic.B > ic.R + 0.1 then isBlue = true end
                        end

                        local area = d.AbsoluteSize.X * d.AbsoluteSize.Y
                        if isBlue then blueBtn = d end
                        if d.AbsoluteSize.X > 150 and d.AbsoluteSize.Y > 30 and area > maxArea then
                            maxArea = area; largestBtn = d
                        end
                    end
                end
            end
        end
    end
    return blueBtn or largestBtn
end

-- Simula o clique de 3 formas diferentes para garantir que funcione
local function clickButton(btn)
    if not btn then return false end
    
    -- Método 1: getconnections (Dispara os eventos do botão diretamente)
    local fired = false
    local function tryFire(sig)
        if not sig then return end
        local ok, conns = pcall(getconnections, sig)
        if ok and conns then
            for _, c in ipairs(conns) do
                pcall(function() c:Fire() end)
                fired = true
            end
        end
    end
    tryFire(btn.MouseButton1Click)
    tryFire(btn.Activated)
    if fired then return true end

    -- Método 2: VirtualUser (Simula o clique do jogador)
    local pos = btn.AbsolutePosition + (btn.AbsoluteSize / 2)
    local clicked = false
    pcall(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton1(Vector2.new(pos.X, pos.Y), btn)
        clicked = true
    end)
    if clicked then return true end

    -- Método 3: VIM (Fallback do mouse)
    pcall(function()
        VIM:SendMouseMoveEvent(pos.X, pos.Y, 0)
        task.wait(0.05)
        VIM:SendMouseButtonEvent(pos.X, pos.Y, 0, true, game, 0)
        task.wait(0.05)
        VIM:SendMouseButtonEvent(pos.X, pos.Y, 0, false, game, 0)
    end)
    return true
end

local function findDebatePrompt()
    local hrp = getHRP()
    if not hrp then return nil end
    local best, bestD = nil, 200 
    for _, d in ipairs(Workspace:GetDescendants()) do
        if d:IsA("ProximityPrompt") and d.Enabled then
            if (d.ActionText or ""):lower():find(STUDY.PROMPT_ACTION:lower(), 1, true) then
                local p = promptPos(d)
                if p then
                    local dist = (p - hrp.Position).Magnitude
                    if dist < bestD then best, bestD = d, dist end
                end
            end
        end
    end
    return best
end

local function holdE(seconds)
    if not running then return end
    task.spawn(function()
        pcall(function()
            VIM:SendKeyEvent(true, "E", false, game)
            task.wait(seconds or 7)
            VIM:SendKeyEvent(false, "E", false, game)
        end)
    end)
end

local function startStudy()
    if running then return end
    applySpeed()
    if not getHRP() then setStatus("Personagem não encontrado", THEME.BAD); return end

    mode = "study"; running = true; setButton(true)
    setStatus("Estudo: procurando balcão...", THEME.INFO)
    studyStepLabel.Text = "Status: procurando 'Preparar Debate'"

    task.spawn(function()
        local cycles = 0

        while running do
            local prompt = findDebatePrompt()
            if not prompt then
                setStatus("Prompt 'Preparar Debate' não encontrado perto", THEME.WARN)
                studyStepLabel.Text = "Status: prompt não achado"
                if not STUDY.LOOP then break end
                missionWait(3); continue
            end

            local pos = promptPos(prompt)
            if not pos then missionWait(1); continue end

            boostPrompt(prompt)
            setStatus("Indo até o balcão...", THEME.INFO)
            studyStepLabel.Text = "Status: andando até o balcão"

            local ok = walkDynamic(function() return pos end, 5, 40, nil, "balcão")
            if not ok or not running then
                setStatus("Falhou: caminhar até o balcão", THEME.BAD)
                if not STUDY.LOOP then break end
                missionWait(1.5); continue
            end

            prompt = findDebatePrompt() or prompt
            boostPrompt(prompt)
            setStatus("Segurando E por " .. STUDY.HOLD_E_TIME .. "s...", THEME.INFO)
            studyStepLabel.Text = "Status: segurando E (" .. STUDY.HOLD_E_TIME .. "s)"
            
            if typeof(fireproximityprompt) == "function" then
                pcall(function() fireproximityprompt(prompt) end)
            end
            holdE(STUDY.HOLD_E_TIME)
            
            local guiT = os.clock()
            local catBtn = nil
            while running and (os.clock() - guiT) < STUDY.GUI_TIMEOUT do
                local btns = findVisibleButtons(STUDY.CATEGORY_TEXT)
                if #btns > 0 then catBtn = btns[1]; break end
                task.wait(0.2)
            end

            if not catBtn then
                setStatus("GUI não abriu ou categoria '"..STUDY.CATEGORY_TEXT.."' não achada", THEME.WARN)
                studyStepLabel.Text = "Status: GUI falhou"
                pcall(function() VIM:SendKeyEvent(false, "Escape", false, game) end)
                if not STUDY.LOOP then break end
                missionWait(2); continue
            end

            setStatus("Selecionando: " .. STUDY.CATEGORY_TEXT, THEME.INFO)
            clickButton(catBtn)
            task.wait(0.5)

            -- Procura o botão azul após carregar a categoria
            setStatus("Procurando botão de estudar...", THEME.INFO)
            local studyBtn = nil
            local stT = os.clock()
            while running and (os.clock() - stT) < 5 do
                studyBtn = findStudyButtonAuto()
                if studyBtn then break end
                task.wait(0.2)
            end

            if not studyBtn then
                setStatus("Botão de estudar não encontrado ou INDISPONÍVEL", THEME.BAD)
                studyStepLabel.Text = "Status: botão indisponível"
                pcall(function() VIM:SendKeyEvent(false, "Escape", false, game) end)
                if not STUDY.LOOP then break end
                missionWait(3); continue
            end

            cycles += 1
            setStatus(string.format("Estudando (%d) — %ds", cycles, STUDY.DURATION), THEME.PINK)
            studyStepLabel.Text = string.format("Status: estudando (%d)", cycles)
            
            -- CLIQUE NO BOTÃO AZUL
            clickButton(studyBtn)

            local t0 = os.clock()
            while running and (os.clock() - t0) < STUDY.DURATION do
                task.wait(0.25)
            end

            setStatus("Fechando GUI...", THEME.INFO)
            local closeBtn = findVisibleButtons("x")
            if #closeBtn > 0 then
                clickButton(closeBtn[1])
            else
                pcall(function()
                    VIM:SendKeyEvent(true, "Escape", false, game)
                    task.wait(0.05)
                    VIM:SendKeyEvent(false, "Escape", false, game)
                end)
            end
            task.wait(0.5)

            local wt = os.clock()
            while running and (os.clock() - wt) < STUDY.WAIT_AFTER do
                task.wait(0.1)
            end

            if not STUDY.LOOP then break end
        end

        running = false; currentTarget = nil
        setButton(false)
        studyStepLabel.Text = "Status: parado"
        setStatus("Estudo parado", THEME.MUTED)
    end)
end

--==================== CONEXÕES FINAIS ====================--
button.MouseButton1Click:Connect(function()
    if running then stop() else start() end
end)

missionButton.MouseButton1Click:Connect(function()
    if running then stop() else startMission() end
end)

studyButton.MouseButton1Click:Connect(function()
    if running then stop() else startStudy() end
end)

closeBtn.MouseButton1Click:Connect(function()
    stop()
    for _, c in ipairs(connections) do pcall(function() c:Disconnect() end) end
    clearAllESP()
    pcall(function() espFolder:Destroy() end)
    pcall(function() gui:Destroy() end)
end)

setStatus("Parado", THEME.MUTED)
setButton(false)
