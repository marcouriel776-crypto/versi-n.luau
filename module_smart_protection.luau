-- module_smart_protection.luau
-- UPF Smart Protection (SAFE VERSION - LUAU MODE)
-- Características Luau: Tipado estricto en detección, casts explícitos

local RunService: RunServiceService = game:GetService("RunService")
local Players: PlayersService = game:GetService("Players")

local LocalPlayer: Player = Players.LocalPlayer

-- Inicialización segura de UPF
_G.UPF = _G.UPF or {} :: table
local UPF: table = _G.UPF

UPF.State = UPF.State or {} :: table
UPF.State.Smart = UPF.State.Smart or {} :: table

-- =========================
-- TYPE DEFINITIONS
-- =========================

type SmartState = {
    LastCheck: number?,
    DetectedPlayers: {[string]: boolean},
}

-- =========================
-- SMART DETECTION LOGIC
-- =========================

local function checkPlayers(): nil
    for _, plr: Player in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            local char: Model = plr.Character :: Model
            local hrp: BasePart? = char:FindFirstChild("HumanoidRootPart")
            
            if hrp then
                -- Cálculo de velocidad con cast explícito
                local vel: number = hrp.AssemblyLinearVelocity.Magnitude
                
                -- Umbral de detección de fling
                if vel > 150 :: number then
                    warn("[UPF-Smart] ⚠️ Possible flinger:", plr.Name)
                    -- Aquí podrías agregar lógica de respuesta si es necesario
                end
            end
        end
    end
end

-- =========================
-- CONNECTION MANAGEMENT
-- =========================

UPF.Connections = UPF.Connections or {} :: table

-- Limpieza segura de conexión anterior
if UPF.Connections.Smart then
    local oldConn: RBXScriptConnection? = UPF.Connections.Smart :: RBXScriptConnection?
    pcall(function(): nil
        if oldConn and oldConn.Disconnect then
            oldConn:Disconnect()
        end
    end)
end

-- Crear nueva conexión con tipado
UPF.Connections.Smart = RunService.Heartbeat:Connect(function(): nil
    pcall(checkPlayers)
end)

print("✅ Smart Protection (no conflict) loaded (Luau typed)")
