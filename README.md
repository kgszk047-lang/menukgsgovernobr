--==================================================
-- KGS VIP | ROBLOX STUDIO
-- Linguagem: Luau
-- Compatível com PC e Mobile
--==================================================

local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Evita interface duplicada
local antiga = playerGui:FindFirstChild("KGSVIP")

if antiga then
    antiga:Destroy()
end

-- CORES
local AZUL = Color3.fromRGB(0, 145, 255)
local FUNDO = Color3.fromRGB(13, 16, 25)
local CARD = Color3.fromRGB(28, 33, 47)
local BRANCO = Color3.fromRGB(255, 255, 255)
local VERDE = Color3.fromRGB(35, 200, 120)

-- INTERFACE
local gui = Instance.new("ScreenGui")
gui.Name = "KGSVIP"
gui.ResetOnSpawn = false
gui.DisplayOrder = 100
gui.Parent = playerGui

-- JANELA
local janela = Instance.new("Frame")
janela.Name = "Painel"
janela.Size = UDim2.new(0, 320, 0, 300)
janela.Position = UDim2.new(0.5, -160, 0.5, -150)
janela.BackgroundColor3 = FUNDO
janela.BorderSizePixel = 0
janela.Parent = gui

Instance.new("UICorner", janela).CornerRadius =
    UDim.new(0, 12)

local contorno = Instance.new("UIStroke")
contorno.Color = AZUL
contorno.Thickness = 2
contorno.Parent = janela

-- TÍTULO
local titulo = Instance.new("TextLabel")
titulo.Size = UDim2.new(1, -55, 0, 45)
titulo.Position = UDim2.new(0, 12, 0, 0)
titulo.BackgroundTransparency = 1
titulo.Text = "KG$  |  KGSVIP"
titulo.TextColor3 = AZUL
titulo.TextSize = 20
titulo.Font = Enum.Font.GothamBold
titulo.TextXAlignment = Enum.TextXAlignment.Left
titulo.Parent = janela

-- BOTÃO MINIMIZAR
local minimizar = Instance.new("TextButton")
minimizar.Size = UDim2.new(0, 35, 0, 30)
minimizar.Position = UDim2.new(1, -43, 0, 7)
minimizar.Text = "—"
minimizar.TextColor3 = BRANCO
minimizar.BackgroundColor3 = CARD
minimizar.TextSize = 18
minimizar.Parent = janela

Instance.new("UICorner", minimizar).CornerRadius =
    UDim.new(0, 8)

-- ÁREA DOS BOTÕES
local conteudo = Instance.new("Frame")
conteudo.Position = UDim2.new(0, 12, 0, 55)
conteudo.Size = UDim2.new(1, -24, 1, -65)
conteudo.BackgroundTransparency = 1
conteudo.Parent = janela

local lista = Instance.new("UIListLayout")
lista.Padding = UDim.new(0, 9)
lista.SortOrder = Enum.SortOrder.LayoutOrder
lista.Parent = conteudo

-- STATUS
local status = Instance.new("TextLabel")
status.Size = UDim2.new(1, 0, 0, 24)
status.BackgroundTransparency = 1
status.Text = "KGSVIP iniciado"
status.TextColor3 = VERDE
status.TextSize = 12
status.Font = Enum.Font.Gotham
status.LayoutOrder = 0
status.Parent = conteudo

-- CRIADOR DE BOTÕES
local function criarBotao(texto, ordem, callback)
    local botao = Instance.new("TextButton")

    botao.Size = UDim2.new(1, 0, 0, 42)
    botao.BackgroundColor3 = CARD
    botao.TextColor3 = BRANCO
    botao.Text = texto
    botao.TextSize = 14
    botao.Font = Enum.Font.GothamSemibold
    botao.LayoutOrder = ordem
    botao.Parent = conteudo

    Instance.new("UICorner", botao).CornerRadius =
        UDim.new(0, 8)

    botao.Activated:Connect(callback)

    return botao
end

-- ESP VISUAL DOS NPCs
local espAtivo = false
local destaques = {}

local function limparESP()
    for modelo, destaque in pairs(destaques) do
        if destaque then
            destaque:Destroy()
        end

        destaques[modelo] = nil
    end
end

local function atualizarESP()
    limparESP()

    if not espAtivo then
        return
    end

    local pasta = workspace:FindFirstChild("PopulacaoNPC")

    if not pasta then
        status.Text = "Pasta PopulacaoNPC não encontrada"
        status.TextColor3 = Color3.fromRGB(255, 180, 60)
        return
    end

    for _, npc in ipairs(pasta:GetChildren()) do
        if npc:IsA("Model") then
            local destaque = Instance.new("Highlight")
            destaque.Name = "KGSVIP_ESP"
            destaque.FillColor = AZUL
            destaque.OutlineColor = BRANCO
            destaque.FillTransparency = 0.65
            destaque.Adornee = npc
            destaque.Parent = gui

            destaques[npc] = destaque
        end
    end

    status.Text = "ESP: " .. tostring(#pasta:GetChildren()) .. " NPCs"
    status.TextColor3 = VERDE
end

criarBotao("ESP NPC: LIGAR / DESLIGAR", 1, function()
    espAtivo = not espAtivo

    if espAtivo then
        atualizarESP()
    else
        limparESP()
        status.Text = "ESP desativado"
        status.TextColor3 = BRANCO
    end
end)

-- LOCALIZAR NPC MAIS PRÓXIMO
criarBotao("LOCALIZAR NPC MAIS PRÓXIMO", 2, function()
    local pasta = workspace:FindFirstChild("PopulacaoNPC")
    local personagem = player.Character
    local raiz = personagem and personagem:FindFirstChild("HumanoidRootPart")

    if not pasta or not raiz then
        status.Text = "NPCs ou personagem não encontrados"
        status.TextColor3 = Color3.fromRGB(255, 180, 60)
        return
    end

    local maisProximo
    local menorDistancia = math.huge

    for _, npc in ipairs(pasta:GetChildren()) do
        local parte = npc:IsA("Model") and
            (npc.PrimaryPart or npc:FindFirstChild("HumanoidRootPart"))

        if parte and parte:IsA("BasePart") then
            local distancia = (raiz.Position - parte.Position).Magnitude

            if distancia < menorDistancia then
                menorDistancia = distancia
                maisProximo = npc
            end
        end
    end

    if maisProximo then
        status.Text = "NPC próximo: " .. maisProximo.Name
        status.TextColor3 = VERDE
    else
        status.Text = "Nenhum NPC válido encontrado"
        status.TextColor3 = Color3.fromRGB(255, 180, 60)
    end
end)

-- BOTÃO MINIMIZAR
local abrir = Instance.new("TextButton")
abrir.Name = "ReabrirKGSVIP"
abrir.Size = UDim2.new(0, 115, 0, 40)
abrir.Position = UDim2.new(0, 15, 0.5, -20)
abrir.BackgroundColor3 = AZUL
abrir.TextColor3 = BRANCO
abrir.Text = "ABRIR KGSVIP"
abrir.TextSize = 13
abrir.Font = Enum.Font.GothamBold
abrir.Visible = false
abrir.Parent = gui

Instance.new("UICorner", abrir).CornerRadius =
    UDim.new(0, 8)

minimizar.Activated:Connect(function()
    janela.Visible = false
    abrir.Visible = true
end)

abrir.Activated:Connect(function()
    janela.Visible = true
    abrir.Visible = false
end)

print("KGSVIP carregado com sucesso!")
