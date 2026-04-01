-- module_protection.luau
-- UPF Protection Core (FIXED PRO - LUAU MODE)
-- Características Luau: Operador +=, tipos estrictos, casts explícitos

local UPF: table = _G.UPF :: table
if not UPF then
    warn("UPF missing")
    return
end

local RunService: RunServiceService = game:GetService("RunService")

-- =========================
-- TYPE DEFINITIONS
-- =========================

type ProtectionState = {
    BlockedEvents: number,
    LastSafePosition: CFrame?,
}

-- =========================
-- STATE INIT
-- =========================

UPF.State.Protection = UPF.State.Protection or {} :: ProtectionState
UPF.State.Protection.BlockedEvents = UPF.State.Protection.BlockedEvents or 0 :: number
UPF.State.LastSafePosition = UPF.State.LastSafePosition or nil :: CFrame?

-- Constants with explicit types
local MAX_DISTANCE_PER_FRAME: number = 60 :: number
local MAX_LINEAR_VELOCITY: number = 120 :: number

-- Position tracking
local lastPosition: Vector3? = nil

-- =========================
-- PROTECTION HEARTBEAT
-- =========================

UPF.Connections.ProtectionHeartbeat = RunService.Heartbeat:Connect(function(): nil

    -- Early exits with type safety
    if not UPF.State.ScriptRunning then return end
    if not UPF.State.ProtectionEnabled then return end
    if not UPF.RootPart or not UPF.Humanoid then return end

    local rootPart: BasePart = UPF.RootPart :: BasePart
    local currentPos: Vector3 = rootPart.Position

    -- Initialize last position if null
    if not lastPosition then
        lastPosition = currentPos
        return
    end

    -- Calculate distance
    local dist: number = (currentPos - lastPosition).Magnitude

    -- Calculate velocity safely
    local vel: number = 0 :: number
    pcall(function(): nil
        vel = rootPart.AssemblyLinearVelocity.Magnitude
    end)

    -- 🔴 IGNORAR FLING (alta velocidad)
    -- Si la velocidad es muy alta, asumimos que es un fling y no revertimos
    if vel > 120 :: number then
        lastPosition = currentPos
        return
    end

    -- 🔴 IGNORAR CAÍDA AL VACÍO
    -- Si estamos muy abajo, no hacemos nada (podría ser respawn o caída intencional)
    if currentPos.Y < -20 :: number then
        return
    end

    -- 🛡️ DETECCIÓN TELEPORT
    if dist > MAX_DISTANCE_PER_FRAME then
        if UPF.State.LastSafePosition then
            pcall(function(): nil
                -- Usar la utilidad SafeRollback para revertir
                if UPF.Utils and UPF.Utils.SafeRollback then
                    UPF.Utils.SafeRollback(rootPart, UPF.State.LastSafePosition)
                end
            end)
        end

        -- Limpiar fuerzas físicas
        if UPF.Utils and UPF.Utils.ClearForces then
            UPF.Utils.ClearForces(rootPart)
        end

        -- Incrementar contador de eventos bloqueados (OPERADOR += NATIVO DE LUAU)
        UPF.State.Protection.BlockedEvents += 1
    end

    -- 🛡️ ANTI-FLING (extra)
    -- Si la velocidad supera el límite, limpiar fuerzas
    if vel > MAX_LINEAR_VELOCITY then
        if UPF.Utils and UPF.Utils.ClearForces then
            UPF.Utils.ClearForces(rootPart)
        end
        UPF.State.Protection.BlockedEvents += 1
    end

    -- ✅ GUARDAR POSICIÓN SEGURA REAL
    -- Solo si estamos tocando suelo y la velocidad es baja
    local floorMaterial: Material = UPF.Humanoid.FloorMaterial
    if floorMaterial ~= Enum.Material.Air and vel < 10 :: number then
        UPF.State.LastSafePosition = rootPart.CFrame
    end

    -- Actualizar última posición
    lastPosition = currentPos

end)

print("✅ Protection PRO loaded (Luau typed)")
