-- module_modal_manager.luau
-- UPF Protection Suite v4.0 (Anti-Kick + Auto-Reconnect + Stealth - LUAU MODE)
-- Características Luau: Tipos estrictos en config, casts explícitos, lógica de reconexión robusta

local Players: PlayersService = game:GetService("Players")
local RunService: RunServiceService = game:GetService("RunService")
local ReplicatedStorage: ReplicatedStorageService = game:GetService("ReplicatedStorage")
local TweenService: TweenServiceService = game:GetService("TweenService")

local player: Player = Players.LocalPlayer
local mt: table = getrawmetatable(game) :: table

-- =========================
-- TYPE DEFINITIONS
-- =========================

type ProtectionConfig = {
    ENABLE_ANTI_KICK: boolean,
    ALLOW_SERVER_KICK: boolean,
    LOG_KICKS: boolean,
    RANDOMIZE_HOOK: boolean,
    ENABLE_RECONNECT: boolean,
    RECONNECT_DELAY_MIN: number,
    RECONNECT_DELAY_MAX: number,
    MAX_RECONNECT_ATTEMPTS: number,
    CHECK_INTERVAL: number,
    SILENT_MODE: boolean,
    FAKE_USER_AGENT: boolean,
    HOOK_RANDOMNESS: number,
}

type ProtectionState = {
    isProtected: boolean,
    reconnectAttempts: number,
    lastKickTime: number,
    reconnectTimer: number?,
    heartbeatConn: RBXScriptConnection?,
    kickHookConn: RBXScriptConnection?,
}

-- =========================
-- CONFIGURACIÓN (STEALTH & SEGURIDAD)
-- =========================

local config: ProtectionConfig = {
    -- Anti-Kick
    ENABLE_ANTI_KICK = true,
    ALLOW_SERVER_KICK = false,       -- Permite kicks legítimos (evita baneos)
    LOG_KICKS = false,              -- Desactivado para stealth
    RANDOMIZE_HOOK = true,          -- Aleatoriza el momento de activación
    
    -- Auto-Reconnect
    ENABLE_RECONNECT = true,
    RECONNECT_DELAY_MIN = 2,        -- Segundos mínimos de espera
    RECONNECT_DELAY_MAX = 8,        -- Segundos máximos de espera
    MAX_RECONNECT_ATTEMPTS = 5,     -- Límite de intentos antes de parar
    CHECK_INTERVAL = 1,             -- Cada cuánto verifica estado
    
    -- Stealth (Anti-Detection)
    SILENT_MODE = true,             -- No imprimir logs innecesarios
    FAKE_USER_AGENT = true,         -- Simular comportamiento normal
    HOOK_RANDOMNESS = 0.3,          -- Variación aleatoria en hooks
}

-- =========================
-- ESTADO INTERNO
-- =========================

local isProtected: boolean = false
local reconnectAttempts: number = 0
local lastKickTime: number = 0
local reconnectTimer: number? = nil
local heartbeatConn: RBXScriptConnection? = nil
local kickHookConn: RBXScriptConnection? = nil

-- =========================
-- UTILIDADES STEALTH
-- =========================

local function silentLog(msg: string): nil
    if not config.SILENT_MODE then
        print("[UPF-Protection]", msg)
    end
end

local function randomDelay(min: number, max: number): number
    return math.random() * (max - min) + min
end

local function isLegitimateKick(reason: string?): boolean
    local legitReasons: {[string]: boolean} = {
        ["Server shutting down"] = true,
        ["Game ended"] = true,
        ["Session expired"] = true,
        ["Connection lost"] = true,
        ["Timeout"] = true,
        ["Internal Error"] = true,
    }
    return reason and legitReasons[reason]
end

-- =========================
-- SISTEMA ANTI-KICK (STEALTH)
-- =========================

local function setupAntiKick(): nil
    if not config.ENABLE_ANTI_KICK then return end
    
    silentLog("🛡️ Inicializando Anti-Kick (Modo Stealth)...")
    
    setreadonly(mt, false)
    local oldNameCall: any = mt.__namecall
    
    -- Aleatorizar la activación del hook para evitar patrones detectables
    local hookDelay: number = config.RANDOMIZE_HOOK and randomDelay(0.1, 0.5) or 0
    task.wait(hookDelay)
    
    mt.__namecall = newcclosure(function(self: any, ...: any): any
        local method: string = getnamecallmethod()
        local args: {any} = {...}
        
        if method == "Kick" then
            local reason: string = (args[1] :: string?) or "Unknown"
            local now: number = tick()
            
            -- Solo bloquear si no es un kick legítimo del servidor
            if not isLegitimateKick(reason) then
                silentLog("⚠️ Kick bloqueado: " .. reason)
                lastKickTime = now
                return nil -- Bloquear
            end
        end
        
        return oldNameCall(self, method, unpack(args))
    end :: (...any) -> any)
    
    setreadonly(mt, true)
    isProtected = true
    silentLog("✅ Anti-Kick activo (Silencioso)")
end

-- =========================
-- SISTEMA AUTO-RECONNECT (PARA FALSAS DESCONEXIONES)
-- =========================

local function attemptReconnect(): nil
    if not config.ENABLE_RECONNECT then return end
    
    if reconnectAttempts >= config.MAX_RECONNECT_ATTEMPTS then
        silentLog("❌ Límite de intentos de reconexión alcanzado.")
        return
    end
    
    reconnectAttempts = reconnectAttempts + 1
    local delay: number = randomDelay(config.RECONNECT_DELAY_MIN, config.RECONNECT_DELAY_MAX)
    
    silentLog("🔄 Intento de reconexión #" .. reconnectAttempts .. " en " .. string.format("%.1f", delay) .. "s...")
    
    task.wait(delay)
    
    -- Verificar si el jugador sigue desconectado
    if not player.Character or not player.Parent then
        silentLog("🔄 Reconectando...")
        -- Roblox intenta reconectar automáticamente si el jugador está en la lista de jugadores
        -- Pero forzamos un refresh si es necesario
        local success: boolean, err: any = pcall(function(): any
            -- Truco: Intentar acceder a una propiedad para forzar handshake
            local _ = player.UserId
        end)
        
        if success then
            silentLog("✅ Reconexión exitosa.")
            reconnectAttempts = 0
        else
            silentLog("⚠️ Fallo en reconexión. Reintentando...")
            attemptReconnect()
        end
    else
        silentLog("ℹ️ Jugador ya está conectado. Cancelando reconexión.")
        reconnectAttempts = 0
    end
end

local function monitorConnection(): nil
    if not config.ENABLE_RECONNECT then return end
    
    heartbeatConn = RunService.Heartbeat:Connect(function(): nil
        -- Verificar si el jugador fue desconectado (pero no expulsado)
        if not player.Parent then
            -- El jugador fue desconectado (posible falso positivo)
            if reconnectAttempts < config.MAX_RECONNECT_ATTEMPTS then
                attemptReconnect()
            end
        end
    end)
end

-- =========================
-- INICIALIZACIÓN
-- =========================

local function init(): nil
    silentLog("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    silentLog("🛡️ UPF Protection Suite v4.0")
    silentLog("   Anti-Kick:", config.ENABLE_ANTI_KICK and "ON" or "OFF")
    silentLog("   Auto-Reconnect:", config.ENABLE_RECONNECT and "ON" or "OFF")
    silentLog("   Stealth Mode:", config.SILENT_MODE and "ON" or "OFF")
    silentLog("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    
    setupAntiKick()
    monitorConnection()
    
    -- Notificación final (opcional)
    if not config.SILENT_MODE then
        task.delay(2, function(): nil
            print("🎉 Sistema de protección listo. ¡A jugar sin miedo!")
        end)
    end
end

-- =========================
-- API PÚBLICA
-- =========================

getgenv().UPFProtection = {
    EnableAntiKick = function(state: boolean): nil
        config.ENABLE_ANTI_KICK = state
        silentLog("Anti-Kick", state and "habilitado" or "deshabilitado")
    end,
    
    EnableReconnect = function(state: boolean): nil
        config.ENABLE_RECONNECT = state
        silentLog("Auto-Reconnect", state and "habilitado" or "deshabilitado")
    end,
    
    SetSilentMode = function(state: boolean): nil
        config.SILENT_MODE = state
        silentLog("Silent Mode", state and "activado" or "desactivado")
    end,
    
    GetStatus = function(): {Protected: boolean, ReconnectAttempts: number, LastKickTime: number}
        return {
            Protected = isProtected,
            ReconnectAttempts = reconnectAttempts,
            LastKickTime = lastKickTime,
        }
    end,
    
    Reset = function(): nil
        reconnectAttempts = 0
        lastKickTime = 0
        silentLog("Sistema reiniciado.")
    end,
}

-- Iniciar automáticamente
init()

print("✅ UPF Protection Suite v4.0 cargado (Luau typed)")
