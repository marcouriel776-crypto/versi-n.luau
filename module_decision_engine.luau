-- module_decision_engine.luau
-- UPF Decision Engine (Brain Logic - LUAU MODE)
-- Características Luau: Tipos estrictos en banderas, casts explícitos, flujo de control tipado

local UPF: table = getgenv().UPF :: table

-- =========================
-- TYPE DEFINITIONS
-- =========================

type FlagsTable = {
    AdminPresent: boolean?,
    SuspiciousMovement: boolean?,
}

type BrainTable = {
    Tick: () -> nil,
}

-- =========================
-- BRAIN IMPLEMENTATION
-- =========================

local Brain: BrainTable = {}
UPF.Brain = Brain

-- =========================
-- DECISION TICK
-- =========================

function Brain:Tick(): nil
    -- Obtener banderas con fallback seguro
    local flags: FlagsTable = (UPF.Flags :: FlagsTable?) or {}

    -- Lógica de Modo Seguro (Admin Detection)
    if flags.AdminPresent then
        warn("[UPF-Brain] modo seguro activado (admin presente)")
        UPF.SafeMode = true :: boolean
    else
        UPF.SafeMode = false :: boolean
    end

    -- Lógica de Throttle (Behavior Analysis)
    if flags.SuspiciousMovement then
        warn("[UPF-Brain] reduciendo actividad por comportamiento")
        UPF.Throttle = true :: boolean
    else
        UPF.Throttle = false :: boolean
    end
end

-- =========================
-- EXPORT
-- =========================

return Brain :: BrainTable
