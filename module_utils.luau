-- module_utils.luau
-- UPF Utility Functions (Clean Architecture - LUAU MODE)
-- Características Luau: Tipos estrictos, tuplas, casts explícitos, uniones

local UPF: table = _G.UPF :: table
if not UPF then
    warn("UPF missing")
    return
end

local Players: PlayersService = game:GetService("Players")
local LocalPlayer: Player = Players.LocalPlayer

-- =========================
-- TYPE DEFINITIONS
-- =========================

type UtilsTable = {
    WaitForCharacter: (number?) -> (BasePart?, boolean),
    ClearForces: (BasePart?) -> nil,
    SafeRollback: (BasePart?, CFrame?) -> nil,
}

-- =========================
-- UTILITIES IMPLEMENTATION
-- =========================

local Utils: UtilsTable = {} :: UtilsTable

-- Esperar al personaje con timeout tipado
function Utils.WaitForCharacter(timeout: number?): (BasePart?, boolean)
    local timeVal: number = (timeout :: number?) or 10 :: number
    local char: Model? = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    
    -- Cast explícito para asegurar que es un Model
    local model: Model = char :: Model
    
    local ok1: boolean = pcall(function(): nil
        model:WaitForChild("Humanoid", timeVal)
    end)
    
    local ok2: boolean = pcall(function(): nil
        model:WaitForChild("HumanoidRootPart", timeVal)
    end)
    
    -- Retorno de tupla tipada
    return model :: BasePart?, (ok1 and ok2) :: boolean
end

-- Limpiar fuerzas físicas con tipos estrictos
function Utils.ClearForces(part: BasePart?): nil
    if not part or not part:IsA("BasePart") then return end
    
    pcall(function(): nil
        -- Cast explícito de Vector3.zero
        part.AssemblyLinearVelocity = Vector3.zero :: Vector3
        part.AssemblyAngularVelocity = Vector3.zero :: Vector3
    end)
    
    for _, v: Instance in ipairs(part:GetChildren()) do
        if v:IsA("BodyVelocity") or v:IsA("LinearVelocity") or v:IsA("BodyAngularVelocity") then
            pcall(function(): nil
                v:Destroy()
            end)
        end
    end
end

-- Rollback seguro con validación de tipos
function Utils.SafeRollback(rootPart: BasePart?, prevCFrame: CFrame?): nil
    if not rootPart or not prevCFrame then return end
    
    pcall(function(): nil
        rootPart.CFrame = prevCFrame :: CFrame
    end)
    
    Utils.ClearForces(rootPart)
end

-- =========================
-- REGISTRO EN UPF
-- =========================

UPF.Utils = UPF.Utils or {} :: table
for k: string, v: any in pairs(Utils) do
    UPF.Utils[k] = v
end

print("✅ Utils registered (Luau typed)")
