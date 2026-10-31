--==================================================
-- KGSVIP | FARM AUTOMATICO
-- Interface para o proprio jogo no Roblox Studio
-- PC + MOBILE
--==================================================

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local pastaNPC = workspace:WaitForChild("PopulacaoNPC")

local antiga = playerGui:FindFirstChild("KGSVIP")
if antiga then
    antiga:Destroy()
end

-- CORES
local FUNDO = Color3.fromRGB(10, 12, 20)
local CARD = Color3.fromRGB(20, 25, 38)
local AZUL = Color3.fromRGB(0, 145, 255)
local AZUL_CLARO = Color3.fromRGB(65, 190, 255)
local VERDE = Color3.fromRGB(30, 200, 120)
local VERMELHO = Color3.fromRGB(235, 65, 75)
local BRANCO = Color3.fromRGB(245, 248, 255)
local CINZA = Color3.fromRGB(155, 165, 185)

-- ESTADO
local executando = false
local modo = "TELEPORTE"
local alvoIndex = 1
local espAtivo = false
local destaques = {}
local conexaoFarm

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

local function contorno(obj, cor)
    local s = Instance.new("UIStroke")
    s.Color = cor
    s.Thickness = 1.5
    s.Transparency = 0.15
    s.Parent = obj
end

local function botao(parent, texto, pos, tamanho)
    local b = Instance.new("TextButton")
    b.Size = tamanho
    b.Position = pos
    b.Text = texto
    b.TextSize = 13
    b.TextWrapped = true
    b.Font = Enum.Font.GothamBold
    b.TextColor3 = BRANCO
    b.BackgroundColor3 = CARD
    b.AutoButtonColor = true
    b.Parent = parent
    arredondar(b, 8)
    return b
end

local function texto(parent, conteudo, pos, tamanho)
    local t = Instance.new("TextLabel")
    t.Size = tamanho
    t.Position = pos
    t.Text = conteudo
    t.TextColor3 = BRANCO
    t.TextSize = 12
    t.Font = Enum.Font.GothamMedium
    t.TextXAlignment = Enum.TextXAlignment.Left
    t.BackgroundTransparency = 1
    t.Parent = parent
    return t
end

-- JANELA
local janela = Instance.new("Frame")
janela.Name = "Painel"
janela.Size = UDim2.new(0, 310, 0, 350)
janela.Position = UDim2.new(0.5, -155, 0.5, -175)
janela.BackgroundColor3 = FUNDO
janela.BorderSizePixel = 0
janela.Parent = gui
arredondar(janela, 14)
contorno(janela, AZUL)

local limite = Instance.new("UISizeConstraint")
limite.MinSize = Vector2.new(285, 330)
limite.MaxSize = Vector2.new(350, 380)
limite.Parent = janela

-- CABECALHO
local cabecalho = Instance.new("Frame")
cabecalho.Size = UDim2.new(1, 0, 0, 44)
cabecalho.BackgroundColor3 = CARD
cabecalho.BorderSizePixel = 0
cabecalho.Parent = janela
arredondar(cabecalho, 12)

local titulo = texto(
    cabecalho,
    "KGSVIP  |  FARM",
    UDim2.new(0, 13, 0, 0),
    UDim2.new(1, -65, 1, 0)
)
titulo.TextColor3 = AZUL_CLARO
titulo.TextSize = 15
titulo.Font = Enum.Font.GothamBold

local minimizar = botao(
    cabecalho, "—",
    UDim2.new(1, -39, 0, 8),
    UDim2.new(0, 28, 0, 27)
)

-- CONTEUDO
local conteudo = Instance.new("Frame")
conteudo.Position = UDim2.new(0, 12, 0, 52)
conteudo.Size = UDim2.new(1, -24, 1, -62)
conteudo.BackgroundTransparency = 1
conteudo.Parent = janela

local status = texto(
    conteudo,
    "Status: aguardando",
    UDim2.new(0, 0, 0, 0),
    UDim2.new(1, 0, 0, 23)
)
status.TextColor3 = CINZA

local npcLabel = texto(
    conteudo,
    "NPC: procurando...",
    UDim2.new(0, 0, 0, 25),
    UDim2.new(1, 0, 0, 23)
)

local modoTeleporte = botao(
    conteudo, "MODO TELEPORTE",
    UDim2.new(0, 0, 0, 54),
    UDim2.new(0.5, -4, 0, 35)
)

local modoAndar = botao(
    conteudo, "MODO ANDAR",
    UDim2.new(0.5, 4, 0, 54),
    UDim2.new(0.5, -4, 0, 35)
)

local iniciar = botao(
    conteudo, "INICIAR FARM",
    UDim2.new(0, 0, 0, 98),
    UDim2.new(1, 0, 0, 39)
)
iniciar.BackgroundColor3 = VERDE

local proximo = botao(
    conteudo, "PROXIMO NPC",
    UDim2.new(0, 0, 0, 145),
    UDim2.new(0.5, -4, 0, 35)
)

local espBotao = botao(
    conteudo, "ESP: OFF",
    UDim2.new(0.5, 4, 0, 145),
    UDim2.new(0.5, -4, 0, 35)
)

local parar = botao(
    conteudo, "PARAR FARM",
    UDim2.new(0, 0, 0, 189),
    UDim2.new(1, 0, 0, 35)
)
parar.BackgroundColor3 = VERMELHO

local informacao = texto(
    conteudo,
    "Interacao: depende do sistema de apoio do jogo.",
    UDim2.new(0, 0, 0, 234),
    UDim2.new(1, 0, 0, 40)
)
informacao.TextColor3 = CINZA
informacao.TextWrapped = true

local abrir = botao(
    gui, "ABRIR KGSVIP",
    UDim2.new(0, 15, 0.5, -20),
    UDim2.new(0, 120, 0, 40)
)
abrir.BackgroundColor3 = AZUL
abrir.Visible = false

-- ENCONTRAR NPCS
local function obterNPCs()
    local lista = {}

    for _, obj in ipairs(pastaNPC:GetChildren()) do
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
        local na = tonumber(a.Name:match("%d+")) or 0
        local nb = tonumber(b.Name:match("%d+")) or 0
        return na < nb
    end)

    return lista
end

local function atualizarAlvo()
    local lista = obterNPCs()

    if #lista == 0 then
        npcLabel.Text = "NPC: nenhum encontrado"
        return nil, lista
    end

    alvoIndex = math.clamp(alvoIndex, 1, #lista)
    npcLabel.Text = "NPC: " .. lista[alvoIndex].Name

    return lista[alvoIndex], lista
end

-- DESTACAR NPCS
local function atualizarESP()
    for _, destaque in pairs(destaques) do
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
        h.FillColor = AZUL
        h.OutlineColor = AZUL_CLARO
        h.FillTransparency = 0.75
        h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        h.Parent = gui

        table.insert(destaques, h)
    end
end

-- PERSONAGEM
local function personagem()
    local char = player.Character
    if not char then return nil, nil end

    local humanoid = char:FindFirstChildOfClass("Humanoid")
    local root = char:FindFirstChild("HumanoidRootPart")

    return humanoid, root
end

-- PROCURAR INTERACAO EXISTENTE
local function encontrarPrompt(npc)
    for _, obj in ipairs(npc:GetDescendants()) do
        if obj:IsA("ProximityPrompt") then
            return obj
        end
    end
    return nil
end

-- IR ATE O NPC
local function irAteNPC(npc)
    local humanoid, root = personagem()
    if not humanoid or not root then return false end

    local npcRoot = npc:FindFirstChild("HumanoidRootPart")
        or npc.PrimaryPart

    if not npcRoot then return false end

    if modo == "TELEPORTE" then
        -- Teleporte local para testes no proprio jogo.
        root.CFrame = npcRoot.CFrame * CFrame.new(0, 0, 3)
        return true
    end

    humanoid:MoveTo(npcRoot.Position + npcRoot.CFrame.LookVector * 3)

    local limiteTempo = os.clock() + 8
    while os.clock() < limiteTempo and executando do
        if (root.Position - npcRoot.Position).Magnitude <= 10 then
            return true
        end
        task.wait(0.2)
    end

    return (root.Position - npcRoot.Position).Magnitude <= 10
end

-- CICLO AUTOMATICO
local function cicloFarm()
    while executando do
        local npc, lista = atualizarAlvo()

        if not npc or #lista == 0 then
            status.Text = "Status: sem NPCs validos"
            task.wait(2)
        else
            status.Text = "Status: indo para " .. npc.Name

            local chegou = irAteNPC(npc)

            if chegou and executando then
                local prompt = encontrarPrompt(npc)

                if prompt and prompt.Enabled then
                    status.Text = "Status: interacao encontrada"
                    informacao.Text =
                        "Prompt: " .. prompt.ActionText ..
                        " | Tecla: " .. prompt.KeyboardKeyCode.Name

                    -- O prompt continua usando o sistema normal do jogo.
                    -- Este LocalScript nao concede apoio nem simula
                    -- uma recompensa do servidor.
                else
                    status.Text = "Status: NPC sem ProximityPrompt"
                    informacao.Text =
                        "Adicione ou confira o ProximityPrompt deste NPC."
                end

                task.wait(2)

                if executando then
                    local novaLista = obterNPCs()
                    if #novaLista > 0 then
                        alvoIndex = (alvoIndex % #novaLista) + 1
                    end
                end
            else
                task.wait(1)
            end
        end
    end

    status.Text = "Status: parado"
end

-- BOTOES
modoTeleporte.Activated:Connect(function()
    modo = "TELEPORTE"
    modoTeleporte.BackgroundColor3 = AZUL
    modoAndar.BackgroundColor3 = CARD
    status.Text = "Modo: teleporte"
end)

modoAndar.Activated:Connect(function()
    modo = "ANDAR"
    modoAndar.BackgroundColor3 = AZUL
    modoTeleporte.BackgroundColor3 = CARD
    status.Text = "Modo: caminhada"
end)

iniciar.Activated:Connect(function()
    if executando then return end

    executando = true
    iniciar.Text = "FARM ATIVO"
    iniciar.BackgroundColor3 = VERDE

    task.spawn(cicloFarm)
end)

parar.Activated:Connect(function()
    executando = false
    iniciar.Text = "INICIAR FARM"
    iniciar.BackgroundColor3 = VERDE
    status.Text = "Status: parando..."
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
