--==================================================
-- KGSVIP | PAINEL + TELEPORTE NPC
-- PC + MOBILE | PARA TESTES NO PROPRIO JOGO
--==================================================

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- CONFIGURACAO
local PASTA_NPC = "PopulacaoNPC"

local antiga = playerGui:FindFirstChild("KGSVIP")
if antiga then
    antiga:Destroy()
end

-- CORES
local BLUE = Color3.fromRGB(0, 145, 255)
local LIGHT_BLUE = Color3.fromRGB(65, 190, 255)
local BG = Color3.fromRGB(12, 15, 24)
local CARD = Color3.fromRGB(24, 29, 43)
local WHITE = Color3.fromRGB(245, 248, 255)
local GRAY = Color3.fromRGB(150, 162, 183)
local GREEN = Color3.fromRGB(35, 190, 115)
local RED = Color3.fromRGB(220, 65, 75)

-- ESTADO
local indiceNPC = 1
local espAtivo = false
local destaques = {}

-- GUI
local gui = Instance.new("ScreenGui")
gui.Name = "KGSVIP"
gui.ResetOnSpawn = false
gui.DisplayOrder = 100
gui.Parent = playerGui

local function arredondar(obj, raio)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, raio)
    c.Parent = obj
end

local function contorno(obj, cor, espessura)
    local s = Instance.new("UIStroke")
    s.Color = cor
    s.Thickness = espessura or 1
    s.Transparency = 0.15
    s.Parent = obj
end

local function criarBotao(parent, nome, label, pos, tamanho)
    local b = Instance.new("TextButton")
    b.Name = nome
    b.Text = label
    b.Position = pos
    b.Size = tamanho
    b.BackgroundColor3 = CARD
    b.TextColor3 = WHITE
    b.Font = Enum.Font.GothamBold
    b.TextSize = 13
    b.TextWrapped = true
    b.AutoButtonColor = true
    b.Parent = parent
    arredondar(b, 9)
    return b
end

local function criarTexto(parent, label, pos, tamanho, fonte)
    local t = Instance.new("TextLabel")
    t.Text = label
    t.Position = pos
    t.Size = tamanho
    t.BackgroundTransparency = 1
    t.TextColor3 = WHITE
    t.Font = Enum.Font.GothamMedium
    t.TextSize = fonte or 13
    t.TextXAlignment = Enum.TextXAlignment.Left
    t.Parent = parent
    return t
end

-- JANELA
local painel = Instance.new("Frame")
painel.Name = "PainelPrincipal"
painel.Size = UDim2.new(0, 320, 0, 390)
painel.Position = UDim2.new(0.5, -160, 0.5, -195)
painel.BackgroundColor3 = BG
painel.BorderSizePixel = 0
painel.Parent = gui
arredondar(painel, 15)
contorno(painel, BLUE, 1.5)

local limite = Instance.new("UISizeConstraint")
limite.MinSize = Vector2.new(285, 370)
limite.MaxSize = Vector2.new(360, 420)
limite.Parent = painel

-- CABECALHO
local cabecalho = Instance.new("Frame")
cabecalho.Size = UDim2.new(1, 0, 0, 53)
cabecalho.BackgroundColor3 = CARD
cabecalho.BorderSizePixel = 0
cabecalho.Parent = painel
arredondar(cabecalho, 14)

local titulo = criarTexto(
    cabecalho,
    "KG$  |  KGSVIP",
    UDim2.new(0, 15, 0, 3),
    UDim2.new(1, -65, 0, 26),
    17
)
titulo.TextColor3 = LIGHT_BLUE
titulo.Font = Enum.Font.GothamBold

local subtitulo = criarTexto(
    cabecalho,
    "PAINEL DE CONTROLE",
    UDim2.new(0, 16, 0, 29),
    UDim2.new(1, -70, 0, 16),
    9
)
subtitulo.TextColor3 = GRAY

local minimizar = criarBotao(
    cabecalho, "Minimizar", "—",
    UDim2.new(1, -42, 0, 10),
    UDim2.new(0, 30, 0, 30)
)

-- CONTEUDO
local conteudo = Instance.new("Frame")
conteudo.Position = UDim2.new(0, 13, 0, 63)
conteudo.Size = UDim2.new(1, -26, 1, -75)
conteudo.BackgroundTransparency = 1
conteudo.Parent = painel

local status = criarTexto(
    conteudo,
    "●  PAINEL CARREGADO",
    UDim2.new(0, 2, 0, 0),
    UDim2.new(1, -4, 0, 24)
)
status.TextColor3 = GREEN

local npcLabel = criarTexto(
    conteudo,
    "NPC selecionado: procurando...",
    UDim2.new(0, 2, 0, 27),
    UDim2.new(1, -4, 0, 25)
)
npcLabel.TextColor3 = LIGHT_BLUE

local teleportar = criarBotao(
    conteudo, "TeleportarNPC", "TELEPORTAR NPC",
    UDim2.new(0, 0, 0, 59),
    UDim2.new(1, 0, 0, 40)
)
teleportar.BackgroundColor3 = BLUE

local proximoNPC = criarBotao(
    conteudo, "ProximoNPC", "PRÓXIMO NPC",
    UDim2.new(0, 0, 0, 106),
    UDim2.new(0.5, -5, 0, 37)
)

local esp = criarBotao(
    conteudo, "ESP", "ESP: OFF",
    UDim2.new(0.5, 5, 0, 106),
    UDim2.new(0.5, -5, 0, 37)
)

local farm = criarBotao(
    conteudo, "Farm", "FARM: OFF",
    UDim2.new(0, 0, 0, 151),
    UDim2.new(1, 0, 0, 37)
)

local parar = criarBotao(
    conteudo, "Parar", "PARAR",
    UDim2.new(0, 0, 0, 196),
    UDim2.new(1, 0, 0, 37)
)
parar.BackgroundColor3 = RED

local aviso = criarTexto(
    conteudo,
    "Teleporte disponível para testes no seu próprio jogo.",
    UDim2.new(0, 2, 0, 243),
    UDim2.new(1, -4, 0, 38),
    10
)
aviso.TextColor3 = GRAY
aviso.TextWrapped = true

local abrir = criarBotao(
    gui, "AbrirPainel", "ABRIR KGSVIP",
    UDim2.new(0, 15, 0.5, -20),
    UDim2.new(0, 125, 0, 42)
)
abrir.BackgroundColor3 = BLUE
abrir.Visible = false

-- BUSCAR NPCS PELOS NOMES ORIGINAIS
local function obterNPCs()
    local pasta = workspace:FindFirstChild(PASTA_NPC)
    local lista = {}

    if not pasta then
        return lista
    end

    for _, obj in ipairs(pasta:GetChildren()) do
        if obj:IsA("Model")
            and obj.Name:match("^NPC%s*%-%s*%d+$") then

            local humanoid = obj:FindFirstChildOfClass("Humanoid")
            local root = obj:FindFirstChild("HumanoidRootPart")
                or obj.PrimaryPart

            if humanoid and root and humanoid.Health > 0 then
                table.insert(lista, obj)
            end
        end
    end

    table.sort(lista, function(a, b)
        local numeroA = tonumber(a.Name:match("%d+")) or 0
        local numeroB = tonumber(b.Name:match("%d+")) or 0
        return numeroA < numeroB
    end)

    return lista
end

local function obterNPCSelecionado()
    local lista = obterNPCs()

    if #lista == 0 then
        npcLabel.Text = "NPC selecionado: nenhum"
        status.Text = "●  NPCs NÃO ENCONTRADOS"
        status.TextColor3 = RED
        return nil, lista
    end

    indiceNPC = ((indiceNPC - 1) % #lista) + 1
    local npc = lista[indiceNPC]

    npcLabel.Text = "NPC selecionado: " .. npc.Name
    return npc, lista
end

-- TELEPORTE
teleportar.Activated:Connect(function()
    local npc = obterNPCSelecionado()
    if not npc then
        aviso.Text = "Confira se os NPCs estão em Workspace > PopulacaoNPC."
        return
    end

    local personagem = player.Character
    local root = personagem and personagem:FindFirstChild("HumanoidRootPart")
    local npcRoot = npc:FindFirstChild("HumanoidRootPart")
        or npc.PrimaryPart

    if not root or not npcRoot then
        status.Text = "●  PERSONAGEM OU NPC INDISPONÍVEL"
        status.TextColor3 = RED
        return
    end

    -- Posiciona o personagem ao lado do NPC.
    root.CFrame = npcRoot.CFrame * CFrame.new(3, 0, 0)

    status.Text = "●  TELEPORTE SOLICITADO"
    status.TextColor3 = GREEN
end)

-- PROXIMO NPC
proximoNPC.Activated:Connect(function()
    local lista = obterNPCs()

    if #lista == 0 then
        obterNPCSelecionado()
        return
    end

    indiceNPC = (indiceNPC % #lista) + 1
    obterNPCSelecionado()
end)

-- ESP VISUAL
local function atualizarESP()
    for _, destaque in ipairs(destaques) do
        if destaque then
            destaque:Destroy()
        end
    end

    table.clear(destaques)

    if not espAtivo then
        return
    end

    for _, npc in ipairs(obterNPCs()) do
        local h = Instance.new("Highlight")
        h.Name = "KGSVIP_ESP"
        h.Adornee = npc
        h.FillColor = BLUE
        h.OutlineColor = LIGHT_BLUE
        h.FillTransparency = 0.75
        h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        h.Parent = gui
        table.insert(destaques, h)
    end
end

esp.Activated:Connect(function()
    espAtivo = not espAtivo
    esp.Text = espAtivo and "ESP: ON" or "ESP: OFF"
    esp.BackgroundColor3 = espAtivo and BLUE or CARD
    atualizarESP()
end)

-- FARM VISUAL: NAO CONCEDE RECOMPENSAS
local farmAtivo = false

farm.Activated:Connect(function()
    farmAtivo = not farmAtivo
    farm.Text = farmAtivo and "FARM: ON" or "FARM: OFF"
    farm.BackgroundColor3 = farmAtivo and GREEN or CARD

    aviso.Text = farmAtivo
        and "Modo visual ativado; interação não implementada."
        or "Modo visual desativado."
end)

parar.Activated:Connect(function()
    farmAtivo = false
    farm.Text = "FARM: OFF"
    farm.BackgroundColor3 = CARD

    espAtivo = false
    esp.Text = "ESP: OFF"
    esp.BackgroundColor3 = CARD
    atualizarESP()

    status.Text = "●  FUNÇÕES DESLIGADAS"
    status.TextColor3 = GRAY
    aviso.Text = "Painel parado."
end)

-- MINIMIZAR E REABRIR
minimizar.Activated:Connect(function()
    painel.Visible = false
    abrir.Visible = true
end)

abrir.Activated:Connect(function()
    painel.Visible = true
    abrir.Visible = false
end)

-- ARRASTAR COM MOUSE OU TOQUE
local arrastando = false
local inicio
local posicaoInicial
local entradaMovimento

cabecalho.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then

        arrastando = true
        inicio = input.Position
        posicaoInicial = painel.Position

        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                arrastando = false
            end
        end)
    end
end)

cabecalho.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch then
        entradaMovimento = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if arrastando and (
        input == entradaMovimento
        or input.UserInputType == Enum.UserInputType.MouseMovement
    ) then
        local delta = input.Position - inicio

        painel.Position = UDim2.new(
            posicaoInicial.X.Scale,
            posicaoInicial.X.Offset + delta.X,
            posicaoInicial.Y.Scale,
            posicaoInicial.Y.Offset + delta.Y
        )
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        arrastando = false
    end
end)

-- ATUALIZACAO
task.spawn(function()
    while gui.Parent do
        obterNPCSelecionado()

        if espAtivo then
            atualizarESP()
        end

        task.wait(5)
    end
end)

obterNPCSelecionado()
print("KGSVIP carregado com teleporte NPC.")xt = "Status: parando..."
end)

proximo.Activated:Connect(function()
    local lista = obterNPCs()

    if #lista > 0 then
        alvoIndex = (alvoIndex % #lista) + 1
    end

    atualizarAlvo()
end)

espBotao.Activated:Connect(function()
    espAtivo = not espAtivo
    espBotao.Text = espAtivo and "ESP: ON" or "ESP: OFF"
    espBotao.BackgroundColor3 = espAtivo and AZUL or CARD
    atualizarESP()
end)

minimizar.Activated:Connect(function()
    janela.Visible = false
    abrir.Visible = true
end)

abrir.Activated:Connect(function()
    janela.Visible = true
    abrir.Visible = false
end)

-- ARRASTAR COM MOUSE OU TOQUE
local arrastando = false
local inicioToque
local posInicial

cabecalho.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then

        arrastando = true
        inicioToque = input.Position
        posInicial = janela.Position
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if arrastando and (
        input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch
    ) then
        local delta = input.Position - inicioToque

        janela.Position = UDim2.new(
            posInicial.X.Scale,
            posInicial.X.Offset + delta.X,
            posInicial.Y.Scale,
            posInicial.Y.Offset + delta.Y
        )
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        arrastando = false
    end
end)

-- ATUALIZAR LISTA PERIODICAMENTE
task.spawn(function()
    while gui.Parent do
        atualizarAlvo()
        if espAtivo then
            atualizarESP()
        end
        task.wait(5)
    end
end)

modoTeleporte.BackgroundColor3 = AZUL
atualizarAlvo()

print("KGSVIP carregado.")
