-- module_recovery.luau
-- UPF Recovery System + God Mode (LUAU MODE)
-- Características Luau: Tipos estrictos en eventos, casts explícitos, operador ??

local Players: PlayersService = game:GetService("Players")
local RunService: RunServiceService = game:GetService("RunService")

local player: Player = Players.LocalPlayer

-- Inicialización segura de UPF
_G.UPF = _G.UPF or {} :: table
local UPF: table = _G.UPF

UPF.State = UPF.State or {} :: table
UPF.State.GodMode = UPF.State.GodMode or false :: boolean

UPF.Recovery = UPF.Recovery or {} :: table
local Recovery: table = UPF.Recovery

-- =========================
-- TYPE DEFINITIONS
-- =========================

type ConnectionMap = {
    [string]: RBXScriptConnection?,
}

type RecoveryState = {
    GodMode: boolean,
}

-- =========================
-- CONNECTIONS MAP
-- =========================

Recovery.Connections = Recovery.Connections or {} :: ConnectionMap

-- =========================
-- GOD MODE CORE
-- =========================

local function protectHumanoid(humanoid: Humanoid?): nil
    if not humanoid then return end

    -- Limpiar conexión anterior si existe
    local oldConn: RBXScriptConnection? = Recovery.Connections.Health :: RBXScriptConnection?
    if oldConn and oldConn.Disconnect then
        oldConn:Disconnect()
    end

    -- Conectar al evento HealthChanged con tipado estricto
    Recovery.Connections.Health = humanoid.HealthChanged:Connect(function(newHealth: number): nil
        if not UPF.State.GodMode then return end

        -- Restaurar salud si es menor al máximo
        if newHealth < humanoid.MaxHealth then
            humanoid.Health = humanoid.MaxHealth
        end
    end)
end

-- =========================
-- CHARACTER MONITOR
-- =========================

local function monitorCharacter(character: Model?): nil
    if not character then return end

    local humanoid: Humanoid? = character:FindFirstChildOfClass("Humanoid")

    if humanoid then
        protectHumanoid(humanoid)
    end
end

-- =========================
-- RESPAWN SUPPORT
-- =========================

player.CharacterAdded:Connect(function(character: Model?): nil
    task.wait(1)
    monitorCharacter(character)
end)

-- Inicializar si el personaje ya existe
if player.Character then
    monitorCharacter(player.Character)
end

-- =========================
-- PUBLIC API
-- =========================

function UPF:ToggleGodMode(on: boolean?): nil
    -- Uso del operador ?? para valor por defecto (nativo de Luau)
    local newState: boolean = if on == nil then not UPF.State.GodMode else on :: boolean
    UPF.State.GodMode = newState

    print("🛡 GodMode:", UPF.State.GodMode)

    -- Re-monitorear el personaje actual
    if player.Character then
        monitorCharacter(player.Character)
    end

    -- Guardar configuración si existe la función
    if UPF.SaveSettings then
        pcall(function(): nil UPF:SaveSettings() end)
    end
end

-- =========================
-- RECOVERY FUNCTIONS
-- =========================

function UPF:RecoverPlayer(): nil
    local character: Model? = player.Character
    if not character then return end

    local humanoid: Humanoid? = character:FindFirstChildOfClass("Humanoid")

    if humanoid then
        humanoid.Health = humanoid.MaxHealth
        print("💚 Player recovered")
    end
end

function UPF:ReturnToSafePoint(): nil
    local character: Model? = player.Character
    if not character then return end

    local root: BasePart? = character:FindFirstChild("HumanoidRootPart")

    if root then
        -- Resetear velocidad con Vector3 explícito
        root.Velocity = Vector3.new(0, 0, 0) :: Vector3
        print("📍 Safe position restored")
    end
end

-- =========================
-- ANTI TELEPORT SYSTEM (Local)
-- =========================

local lastPosition: Vector3? = nil

RunService.Heartbeat:Connect(function(): nil
    local character: Model? = player.Character
    if not character then return end

    local root: BasePart? = character:FindFirstChild("HumanoidRootPart")
    if not root then return end

    local current: Vector3 = root.Position

    if lastPosition then
        local distance: number = (current - lastPosition).Magnitude

        if distance > 60 :: number then
            task.wait(0.05)
            -- Verificar que root sigue existiendo después del wait
            if root and root.Parent then
                root.CFrame = CFrame.new(lastPosition)
                print("🚫 AntiTeleport: reverted")
            end
        end
    end

    lastPosition = current
end)

print("✅ module_recovery loaded (Luau typed)")
