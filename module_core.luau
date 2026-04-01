-- module_core.luau
-- UPF Core (Heart of the System - LUAU MODE)
-- Características Luau: Tipos estrictos, estados tipados, casts explícitos

-- =========================
-- TYPE DEFINITIONS
-- =========================

type UPFState = {
    ScriptRunning: boolean,
    ProtectionEnabled: boolean,
    ProtectionManualOverride: boolean?,
    GodModeEnabled: boolean,
    SmartMode: "SAFE" | "AGGRESSIVE" | "CUSTOM",
    AutoReturnEnabled: boolean,
    ReturnCooldown: number,
    LastAutoReturn: number,
    FlingEvents: number,
}

type UPFConnections = {
    [string]: RBXScriptConnection?,
}

type UPFModule = {
    Character: Model?,
    Humanoid: Humanoid?,
    RootPart: BasePart?,
    SafeMode: boolean,
    Throttle: boolean,
    Analyzer: any?,
    Admin: any?,
    Brain: any?,
    Resilience: any?,
}

-- =========================
-- CORE INITIALIZATION
-- =========================

if _G.UPF and _G.UPF.CoreLoaded then
    warn("UPF Core already loaded.")
    return
end

_G.UPF = _G.UPF or {} :: table
local UPF: table = _G.UPF

local Players: PlayersService = game:GetService("Players")
local RunService: RunServiceService = game:GetService("RunService")
local CoreGui: CoreGuiService = game:GetService("CoreGui")

-- Mark core as loaded
UPF.CoreLoaded = true :: boolean
UPF.Connections = UPF.Connections or {} :: UPFConnections
UPF.State = UPF.State or {} :: UPFState
UPF.Settings = UPF.Settings or {} :: table

-- =========================
-- DEFAULT STATE (Typed)
-- =========================

UPF.State.ScriptRunning = true :: boolean
UPF.State.ProtectionEnabled = (UPF.Settings.protection_enabled :: boolean?) or false :: boolean
UPF.State.ProtectionManualOverride = (UPF.Settings.protection_manual_override :: boolean?) or nil :: boolean?
UPF.State.GodModeEnabled = (UPF.Settings.godmode_enabled :: boolean?) or false :: boolean
UPF.State.SmartMode = (UPF.Settings.smart_mode :: string?) or "SAFE" :: "SAFE" | "AGGRESSIVE" | "CUSTOM"
UPF.State.AutoReturnEnabled = (UPF.Settings.auto_return_enabled :: boolean?) or true :: boolean
UPF.State.ReturnCooldown = (UPF.Settings.return_cooldown :: number?) or 5 :: number
UPF.State.LastAutoReturn = UPF.State.LastAutoReturn or 0 :: number
UPF.State.FlingEvents = UPF.State.FlingEvents or 0 :: number

-- Character references (nullable)
UPF.Character = nil :: Model?
UPF.Humanoid = nil :: Humanoid?
UPF.RootPart = nil :: BasePart?
UPF.SafeMode = false :: boolean
UPF.Throttle = false :: boolean

-- Early exit checks
if UPF.SafeMode then
    return -- no hacer nada
end

if UPF.Throttle then
    task.wait(0.2)
end

local LocalPlayer: Player = Players.LocalPlayer

-- =========================
-- CHARACTER UPDATE FUNCTION
-- =========================

local function UpdateCharacter(char: Model?): nil
    UPF.Character = char :: Model?
    
    -- WaitForChild con timeout tipado
    local humanoid: Humanoid? = char:FindFirstChild("Humanoid") or char:WaitForChild("Humanoid", 5 :: number)
    local rootPart: BasePart? = char:FindFirstChild("HumanoidRootPart") or char:WaitForChild("HumanoidRootPart", 5 :: number)
    
    UPF.Humanoid = humanoid :: Humanoid?
    UPF.RootPart = rootPart :: BasePart?
end

-- Initialize character if exists
if LocalPlayer.Character then
    UpdateCharacter(LocalPlayer.Character)
end

-- Connect character added event
UPF.Connections.CharacterAdded = LocalPlayer.CharacterAdded:Connect(UpdateCharacter)

-- =========================
-- PUBLIC API
-- =========================

-- Toggle protection with optional parameter
function UPF:ToggleProtection(on: boolean?): nil
    local newState: boolean = if on == nil then not self.State.ProtectionEnabled else on :: boolean
    self.State.ProtectionEnabled = newState :: boolean
    
    print("UPF:Protection ->", tostring(self.State.ProtectionEnabled))
    
    if self.SaveSettings then
        pcall(function(): nil
            self:SaveSettings()
        end)
    end
end

-- Shutdown system gracefully
function UPF:Shutdown(): nil
    print("UPF:Shutting down...")
    self.State.ScriptRunning = false :: boolean
    self.State.ProtectionEnabled = false :: boolean
    
    -- Disconnect all connections
    for k: string, conn: RBXScriptConnection? in pairs(self.Connections) do
        pcall(function(): nil
            if type(conn) == "userdata" and conn.Disconnect then
                conn:Disconnect()
            end
            self.Connections[k] = nil
        end)
    end
    
    -- Remove UI if exists (PlayerGui or CoreGui)
    pcall(function(): nil
        local plr: Player = LocalPlayer
        if plr and plr:FindFirstChild("PlayerGui") then
            local g: GuiObject? = plr.PlayerGui:FindFirstChild("ProtectionUI")
            if g then g:Destroy() end
        end
        local cg: GuiObject? = CoreGui:FindFirstChild("ProtectionUI")
        if cg then cg:Destroy() end
    end)
end

-- =========================
-- MAIN HEARTBEAT LOOP
-- =========================

RunService.Heartbeat:Connect(function(): nil
    local char: Model? = game.Players.LocalPlayer.Character

    -- Analyzer tracking (if available)
    if UPF.Analyzer then
        local analyzer: any = UPF.Analyzer :: any
        if analyzer.TrackCharacter and analyzer.Evaluate then
            analyzer:TrackCharacter(char)
            analyzer:Evaluate()
        end
    end

    -- Admin detector (if available)
    if UPF.Admin then
        local admin: any = UPF.Admin :: any
        if admin.Check then
            admin:Check()
        end
    end

    -- Brain tick (if available)
    if UPF.Brain then
        local brain: any = UPF.Brain :: any
        if brain.Tick then
            brain:Tick()
        end
    end

    -- Resilience check (if available and not in SafeMode)
    if UPF.Resilience and not UPF.SafeMode then
        local resilience: any = UPF.Resilience :: any
        if resilience.Check then
            resilience:Check(char)
        end
    end
end)

print("✅ Core initialized (Luau typed)")
