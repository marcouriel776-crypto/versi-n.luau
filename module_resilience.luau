-- module_resilience.luau
-- UPF Resilience System (Final Pro Stable - LUAU MODE)
-- Características Luau: Tipos estrictos en estado, casts explícitos, lógica de "stuck" robusta

local Players: PlayersService = game:GetService("Players")
local RunService: RunServiceService = game:GetService("RunService")

local LocalPlayer: Player = Players.LocalPlayer

-- Inicialización segura de UPF
_G.UPF = _G.UPF or {} :: table
local UPF: table = _G.UPF

UPF.State = UPF.State or {} :: table
UPF.State.Resilience = UPF.State.Resilience or {} :: table

-- =========================
-- TYPE DEFINITIONS
-- =========================

type ResilienceState = {
    paused: boolean,
    stuckTime: number,
    lastRecovery: number,
    lastMoveTick: number,
    lastPos: Vector3?,
    lastStuckTrigger: number,
    stuckCooldown: number,
}

type ResilienceTable = {
    Pause: () -> nil,
    Resume: () -> nil,
    AttemptRecovery: () -> nil,
    Check: (Model?) -> nil,
}

-- =========================
-- STATE INITIALIZATION
-- =========================

local RES: ResilienceState = (UPF.State.Resilience :: ResilienceState)

-- Inicializar valores por defecto con tipos estrictos
RES.paused = RES.paused or false :: boolean
RES.stuckTime = RES.stuckTime or 6 :: number
RES.lastRecovery = RES.lastRecovery or 0 :: number
RES.lastMoveTick = RES.lastMoveTick or tick() :: number
RES.lastPos = RES.lastPos or nil :: Vector3?
RES.lastStuckTrigger = RES.lastStuckTrigger or 0 :: number
RES.stuckCooldown = RES.stuckCooldown or 8 :: number

UPF.Resilience = UPF.Resilience or {} :: ResilienceTable

-- =========================
-- HELPERS
-- =========================

local function getRoot(): BasePart?
    local char: Model? = LocalPlayer and LocalPlayer.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function localRecover(): nil
    local root: BasePart? = getRoot()
    if not root then return end

    -- Cooldown anti-spam con cast explícito
    if tick() - RES.lastRecovery < 2 :: number then return end
    RES.lastRecovery = tick()

    pcall(function(): nil
        -- Resetear velocidades con Vector3.zero explícito
        root.AssemblyLinearVelocity = Vector3.zero :: Vector3
        root.AssemblyAngularVelocity = Vector3.zero :: Vector3
    end)

    if type(UPF.RecoverPlayer) == "function" then
        pcall(function(): nil UPF:RecoverPlayer() end)
    end

    if type(UPF.ReturnToSafePoint) == "function" then
        pcall(function(): nil UPF:ReturnToSafePoint() end)
    end

    print("[resilience] local recovery executed")
end

-- =========================
-- API
-- =========================

function UPF.Resilience.Pause(): nil
    RES.paused = true :: boolean
    print("[resilience] paused")
end

function UPF.Resilience.Resume(): nil
    RES.paused = false :: boolean
    print("[resilience] resumed")
end

function UPF.Resilience.AttemptRecovery(): nil
    localRecover()
end

-- Compatibilidad externa (opcional)
function UPF.Resilience:Check(character: Model?): nil
    if not character then return end

    local root: BasePart? = character:FindFirstChild("HumanoidRootPart")
    if not root then return end

    local velocity: number = root.Velocity.Magnitude

    -- Lógica de recuperación si está muy lento
    if velocity < 1 :: number and tick() - RES.lastRecovery > 5 :: number then
        RES.lastRecovery = tick()
        -- Levantar ligeramente al jugador
        root.CFrame = root.CFrame + Vector3.new(0, 5, 0) :: CFrame
    end
end

-- =========================
-- CORE LOGIC (Stuck Detection)
-- =========================

local function checkStuck(): nil
    if RES.paused then return end

    local root: BasePart? = getRoot()
    if not root then
        RES.lastPos = nil
        RES.lastMoveTick = tick()
        return
    end

    local pos: Vector3 = root.Position
    local vel: number = 0

    pcall(function(): nil
        vel = root.AssemblyLinearVelocity.Magnitude
    end)

    if RES.lastPos then
        local dist: number = (pos - RES.lastPos).Magnitude

        if dist > 0.5 :: number or vel > 1 :: number then
            -- Jugador se movió
            RES.lastMoveTick = tick()
        else
            local now: number = tick()

            if now - RES.lastMoveTick >= RES.stuckTime then
                -- Evitar spam infinito
                if now - RES.lastStuckTrigger >= RES.stuckCooldown then
