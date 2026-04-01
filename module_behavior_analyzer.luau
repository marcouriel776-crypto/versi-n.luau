-- module_behavior_analyzer.luau
-- UPF Behavior Analyzer (AI Logic - LUAU MODE)
-- Características Luau: Tipos estrictos en arrays, operador +=, casts explícitos

local UPF: table = getgenv().UPF :: table

-- =========================
-- TYPE DEFINITIONS
-- =========================

type VelocityHistory = {number}
type AnalyzerFlags = {
    SuspiciousMovement: boolean,
}

type AnalyzerTable = {
    TrackCharacter: (Model?) -> nil,
    Evaluate: () -> nil,
}

-- =========================
-- ANALYZER IMPLEMENTATION
-- =========================

local Analyzer: AnalyzerTable = {}
UPF.Analyzer = Analyzer

-- Historial de velocidades con tipo estricto
local velocityHistory: VelocityHistory = {}
local lastCheck: number = 0

-- Umbral de detección
local VELOCITY_THRESHOLD: number = 120
local SPIKE_LIMIT: number = 5
local HISTORY_SIZE: number = 20
local CHECK_INTERVAL: number = 2

-- =========================
-- TRACK CHARACTER
-- =========================

function Analyzer:TrackCharacter(char: Model?): nil
    local root: BasePart? = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return end

    -- Cálculo de velocidad con cast explícito
    local v: number = root.Velocity.Magnitude
    
    -- Insertar en historial
    table.insert(velocityHistory, v)

    -- Mantener tamaño limitado (FIFO)
    if #velocityHistory > HISTORY_SIZE then
        table.remove(velocityHistory, 1)
    end
end

-- =========================
-- EVALUATE BEHAVIOR
-- =========================

function Analyzer:Evaluate(): nil
    local currentTime: number = tick()
    
    -- Evitar chequeos demasiado frecuentes
    if currentTime - lastCheck < CHECK_INTERVAL then return end
    lastCheck = currentTime

    local spikes: number = 0

    -- Contar picos de velocidad (OPERADOR += NATIVO DE LUAU)
    for _, v: number in ipairs(velocityHistory) do
        if v > VELOCITY_THRESHOLD then
            spikes += 1
        end
    end

    -- Inicializar banderas si no existen
    UPF.Flags = UPF.Flags or {} :: AnalyzerFlags

    -- Determinar si hay comportamiento sospechoso
    if spikes > SPIKE_LIMIT then
        warn("[UPF.AI] comportamiento anómalo detectado")
        UPF.Flags.SuspiciousMovement = true :: boolean
    else
        UPF.Flags.SuspiciousMovement = false :: boolean
    end
end

-- =========================
-- EXPORT
-- =========================

return Analyzer :: AnalyzerTable
