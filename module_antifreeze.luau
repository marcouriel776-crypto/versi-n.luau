-- module_antifreeze.luau
-- UPF Anti Freeze + Network Popup Remover (LUAU MODE)
-- Características Luau: Tipos estrictos en efectos, casts explícitos, lógica de detección robusta

local Players: PlayersService = game:GetService("Players")
local Lighting: LightingService = game:GetService("Lighting")
local CoreGui: CoreGuiService = game:GetService("CoreGui")
local RunService: RunServiceService = game:GetService("RunService")

local player: Player = Players.LocalPlayer

-- Inicialización segura de UPF
_G.UPF = _G.UPF or {} :: table
local UPF: table = _G.UPF

UPF.State = UPF.State or {} :: table
UPF.State.AntiFreeze = UPF.State.AntiFreeze or true :: boolean

UPF.AntiFreeze = UPF.AntiFreeze or {} :: table
local AntiFreeze: table = UPF.AntiFreeze

-- =========================
-- TYPE DEFINITIONS
-- =========================

type ConnectionMap = {
    [string]: RBXScriptConnection?,
}

type AntiFreezeState = {
    AntiFreeze: boolean,
}

-- =========================
-- CONNECTIONS MAP
-- =========================

AntiFreeze.Connections = AntiFreeze.Connections or {} :: ConnectionMap

-- =========================
-- REMOVE VISUAL FREEZE EFFECTS
-- =========================

local function clearVisualFreeze(): nil
    for _, v: Instance in pairs(Lighting:GetChildren()) do
        if v:IsA("BlurEffect") then
            local blur: BlurEffect = v :: BlurEffect
            blur:Destroy()
        end

        if v:IsA("ColorCorrectionEffect") then
            local color: ColorCorrectionEffect = v :: ColorCorrectionEffect
            if color.Saturation < 0 then
                color:Destroy()
            end
        end
    end
end

-- =========================
-- REMOVE NETWORK POPUPS
-- =========================

local function scanGui(gui: Instance): nil
    if not gui:IsA("ScreenGui") then return end

    local screenGui: ScreenGui = gui :: ScreenGui
    local text: string = screenGui.Name:lower()

    -- Lista de palabras clave para detectar popups de desconexión
    local keywords: {string} = {"disconnect", "connection", "network", "internet", "reconnect", "loading"}

    for _, keyword: string in ipairs(keywords) do
        if text:find(keyword) then
            print("🧊 UPF AntiFreeze removed:", screenGui.Name)
            screenGui:Destroy()
            return
        end
    end
end

-- =========================
-- GUI MONITOR
-- =========================

local function monitorGui(): nil
    local oldConn: RBXScriptConnection? = AntiFreeze.Connections.Gui :: RBXScriptConnection?
    if oldConn and oldConn.Disconnect then
        oldConn:Disconnect()
    end

    AntiFreeze.Connections.Gui = CoreGui.ChildAdded:Connect(function(child: Instance): nil
        if not UPF.State.AntiFreeze then return end

        task.wait(0.5)

        pcall(function(): nil
            scanGui(child)
        end)
    end)
end

-- =========================
-- FRAME FREEZE DETECTOR
-- =========================

local function detectFrameFreeze(): nil
    local last: number = tick()

    local oldConn: RBXScriptConnection? = AntiFreeze.Connections.Heartbeat :: RBXScriptConnection?
    if oldConn and oldConn.Disconnect then
        oldConn:Disconnect()
    end

    AntiFreeze.Connections.Heartbeat = RunService.Heartbeat:Connect(function(): nil
        if not UPF.State.AntiFreeze then return end

        local now: number = tick()

        -- Si el frame tardó más de 3 segundos, se considera freeze
        if now - last > 3 :: number then
            print("🧊 UPF Freeze detected -> recovering")
            clearVisualFreeze()

            if UPF.RecoverPlayer then
                pcall(function(): nil UPF:RecoverPlayer() end)
            end
        end

        last = now
    end)
end

-- =========================
-- PUBLIC API
-- =========================

function UPF:ToggleAntiFreeze(on: boolean?): nil
    -- Uso del operador inline if para valor por defecto
    local newState: boolean = if on == nil then not UPF.State.AntiFreeze else on :: boolean
    UPF.State.AntiFreeze = newState

    print("🧊 AntiFreeze:", UPF.State.AntiFreeze)

    if UPF.State.AntiFreeze then
        monitorGui()
        detectFrameFreeze()
        clearVisualFreeze()
    end

    if UPF.SaveSettings then
        pcall(function(): nil UPF:SaveSettings() end)
    end
end

-- =========================
-- START SYSTEM
-- =========================

monitorGui()
detectFrameFreeze()

print("✅ module_antifreeze loaded (Luau typed)")
