-- module_audio.luau
-- UPF Audio Shield (Clean Architecture - LUAU MODE)
-- Características Luau: Tipado estricto, tipos personalizados, sintaxis avanzada

local Players: PlayersService = game:GetService("Players")
local RunService: RunServiceService = game:GetService("RunService")

local UPF: table = _G.UPF :: table
if not UPF then
    warn("UPF not initialized before Audio module")
    return
end

local LocalPlayer: Player = Players.LocalPlayer

UPF.State = UPF.State or {} :: table
UPF.Settings = UPF.Settings or {} :: table
UPF.Connections = UPF.Connections or {} :: table

--------------------------------------------------
-- TYPE DEFINITIONS
--------------------------------------------------

type AudioState = {
    Enabled: boolean,
    Radius: number,
    Level: number,
}

type VolumeMap = {[Sound]: number}

--------------------------------------------------
-- STATE INIT
--------------------------------------------------

UPF.State.Audio = UPF.State.Audio or {
    Enabled = UPF.Settings.audio_shield_enabled or false :: boolean,
    Radius = UPF.Settings.audio_shield_radius or 20 :: number,
    Level = UPF.Settings.audio_shield_level or 0.25 :: number,
} :: AudioState

local OriginalVolumes: VolumeMap = setmetatable({}, {__mode = "k"})

--------------------------------------------------
-- INTERNAL FUNCTIONS
--------------------------------------------------

local function saveOriginal(sound: Sound?): nil
    if sound and not OriginalVolumes[sound] then
        OriginalVolumes[sound] = sound.Volume :: number
    end
end

local function setVolume(sound: Sound?, v: number): nil
    if sound then
        pcall(function(): nil
            sound.Volume = v :: number
        end)
    end
end

local function restoreSound(sound: Sound?): nil
    if sound and OriginalVolumes[sound] then
        pcall(function(): nil
            sound.Volume = OriginalVolumes[sound] :: number
        end)
        OriginalVolumes[sound] = nil :: number?
    end
end

local function applyShieldToCharacter(plr: Player, shieldOn: boolean): nil
    if not plr.Character then return end

    for _, obj: Instance in ipairs(plr.Character:GetDescendants()) do
        if obj:IsA("Sound") then
            local sound: Sound = obj :: Sound
            if shieldOn then
                saveOriginal(sound)
                setVolume(sound, UPF.State.Audio.Level :: number)
            else
                restoreSound(sound)
            end
        end
    end
end

local function isPlayerNear(plr: Player): boolean
    if not plr.Character or not LocalPlayer.Character then return false end
    
    local hrpA: BasePart? = plr.Character:FindFirstChild("HumanoidRootPart")
    local hrpB: BasePart? = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    
    if not hrpA or not hrpB then return false end
    
    return (hrpA.Position - hrpB.Position).Magnitude <= UPF.State.Audio.Radius :: number
end

--------------------------------------------------
-- HEARTBEAT LOOP
--------------------------------------------------

UPF.Connections.AudioShieldHeartbeat = RunService.Heartbeat:Connect(function(): nil
    if not UPF.State.Audio.Enabled then
        return
    end

    if not LocalPlayer.Character then return end

    for _, plr: Player in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            local ok: boolean, near: boolean = pcall(isPlayerNear, plr)

            if ok and near then
                applyShieldToCharacter(plr, true :: boolean)
            else
                applyShieldToCharacter(plr, false :: boolean)
            end
        end
    end
end)

--------------------------------------------------
-- PUBLIC METHODS
--------------------------------------------------

function UPF:ToggleAudioShield(on: boolean?): nil
    local state: boolean = if on == nil then not UPF.State.Audio.Enabled else on :: boolean
    UPF.State.Audio.Enabled = state :: boolean

    UPF.Settings.audio_shield_enabled = UPF.State.Audio.Enabled
    if UPF.SaveSettings then
        UPF:SaveSettings()
    end

    print("🔊 Audio Shield:", UPF.State.Audio.Enabled)
end

function UPF:SetAudioShieldRadius(r: number?): nil
    local radius: number = math.max(1, tonumber(r) or UPF.State.Audio.Radius)
    UPF.State.Audio.Radius = radius :: number
    UPF.Settings.audio_shield_radius = UPF.State.Audio.Radius

    if UPF.SaveSettings then
        UPF:SaveSettings()
    end
end

function UPF:SetAudioShieldLevel(l: number?): nil
    local level: number = math.clamp(tonumber(l) or UPF.State.Audio.Level, 0, 1)
    UPF.State.Audio.Level = level :: number
    UPF.Settings.audio_shield_level = UPF.State.Audio.Level

    if UPF.SaveSettings then
        UPF:SaveSettings()
    end
end

print("✅ Audio module v2 loaded (UPF connected)")
