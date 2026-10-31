--==================================================
-- KGSVIP SERVER
-- Roblox Studio | Luau
-- Interação segura com NPCs
--==================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local pastaNPC = workspace:WaitForChild("PopulacaoNPC")

local DISTANCIA_MAXIMA = 12
local INTERVALO = 2
local APOIO_POR_INTERACAO = 1

-- Eventos de comunicação
local pastaRemotes = ReplicatedStorage:FindFirstChild("KGSVIP_Remotes")

if not pastaRemotes then
    pastaRemotes = Instance.new("Folder")
    pastaRemotes.Name = "KGSVIP_Remotes"
    pastaRemotes.Parent = ReplicatedStorage
end

local solicitarInteracao = pastaRemotes:FindFirstChild("InteragirNPC")

if not solicitarInteracao then
    solicitarInteracao = Instance.new("RemoteEvent")
    solicitarInteracao.Name = "InteragirNPC"
    solicitarInteracao.Parent = pastaRemotes
end

local ultimoUso = {}

local function obterParte(npc)
    if not npc or not npc:IsA("Model") then
        return nil
    end

    return npc.PrimaryPart
        or npc:FindFirstChild("HumanoidRootPart")
        or npc:FindFirstChildWhichIsA("BasePart")
end

local function obterApoio(player)
    local leaderstats = player:FindFirstChild("leaderstats")
    local apoio = leaderstats and leaderstats:FindFirstChild("Apoio")

    if apoio and (apoio:IsA("IntValue") or apoio:IsA("NumberValue")) then
        return apoio
    end

    return nil
end

solicitarInteracao.OnServerEvent:Connect(function(player, npc)
    if typeof(npc) ~= "Instance" then
        return
    end

    if not npc:IsA("Model") or not npc:IsDescendantOf(pastaNPC) then
        return
    end

    local personagem = player.Character
    local raiz = personagem and personagem:FindFirstChild("HumanoidRootPart")
    local parte = obterParte(npc)

    if not raiz or not parte then
        return
    end

    -- Confere a distância no servidor.
    if (raiz.Position - parte.Position).Magnitude > DISTANCIA_MAXIMA then
        return
    end

    -- Limita a frequência de interação.
    local agora = os.clock()
    local ultimo = ultimoUso[player.UserId] or 0

    if agora - ultimo < INTERVALO then
        return
    end

    ultimoUso[player.UserId] = agora

    -- Confirma se o NPC possui o mecanismo de interação.
    local prompt = npc:FindFirstChildWhichIsA("ProximityPrompt", true)

    if not prompt or not prompt.Enabled then
        return
    end

    -- IMPORTANTE:
    -- Conecte aqui o sistema REAL de apoio do seu jogo.
    -- Não adicionamos apoio automaticamente porque isso
    -- poderia duplicar ou substituir a regra existente.
    print(player.Name .. " solicitou interação com " .. npc.Name)
end)

Players.PlayerRemoving:Connect(function(player)
    ultimoUso[player.UserId] = nil
end)

print("KGSVIP Server carregado.")
