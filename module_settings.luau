-- module_settings.luau
-- UPF Settings Manager (Persistence Ready - LUAU MODE)
-- Características Luau: Tipos estrictos, definiciones de tabla, casts explícitos

local HttpService: HttpServiceService = game:GetService("HttpService")

local SETTINGS_FILENAME: string = "upf_config.json"

-- =========================
-- TYPE DEFINITIONS
-- =========================

type SettingsTable = {
    protection_enabled: boolean,
    protection_manual_override: boolean?,
    godmode_enabled: boolean,
    smart_mode: "SAFE" | "AGGRESSIVE" | "CUSTOM",
    auto_return_enabled: boolean,
    return_cooldown: number,
    audio_shield_enabled: boolean,
    audio_shield_radius: number,
    audio_shield_level: number,
}

-- =========================
-- GLOBAL STATE (Typed)
-- =========================

-- Inicialización segura con tipos
local Settings: SettingsTable = (Settings :: any) or {
    protection_enabled = false :: boolean,
    protection_manual_override = nil :: boolean?,
    godmode_enabled = false :: boolean,
    smart_mode = "SAFE" :: "SAFE" | "AGGRESSIVE" | "CUSTOM",
    auto_return_enabled = true :: boolean,
    return_cooldown = 5 :: number,
    audio_shield_enabled = false :: boolean,
    audio_shield_radius = 20 :: number,
    audio_shield_level = 0.25 :: number,
}

-- Variables globales externas (referencias para compatibilidad)
local ProtectionEnabled: boolean? = (ProtectionEnabled :: any)
local ProtectionManualOverride: boolean? = (ProtectionManualOverride :: any)
local GodModeEnabled: boolean? = (GodModeEnabled :: any)
local SmartMode: string? = (SmartMode :: any)
local AutoReturnEnabled: boolean? = (AutoReturnEnabled :: any)
local ReturnCooldown: number? = (ReturnCooldown :: any)

-- =========================
-- FILE I/O HELPERS
-- =========================

local function try_readfile(path: string): string?
    if type(readfile) ~= "function" then return nil end
    local ok: boolean, content: string? = pcall(readfile, path)
    if ok and content then return content :: string end
    return nil
end

local function try_writefile(path: string, content: string): boolean
    if type(writefile) ~= "function" then return false end
    local ok: boolean = pcall(writefile, path, content)
    return ok :: boolean
end

-- =========================
-- LOAD SETTINGS
-- =========================

function LoadUPFSettings(): boolean
    local src: string? = try_readfile(SETTINGS_FILENAME) or (_G.UPF_LOCAL_SETTINGS :: string?)
    if not src then return false end

    local ok: boolean, parsed: any = pcall(function(): any
        return HttpService:JSONDecode(src :: string)
    end)

    if not ok or type(parsed) ~= "table" then return false end

    local settingsParsed: SettingsTable = (parsed :: any)

    -- Copiar valores con validación de tipos
    for k: string, v: any in pairs(settingsParsed) do
        if Settings[k] ~= nil then
            Settings[k] = v
        end
    end

    -- Sincronizar con variables globales externas (si existen)
    pcall(function(): nil
        ProtectionEnabled = Settings.protection_enabled
        ProtectionManualOverride = Settings.protection_manual_override
        GodModeEnabled = Settings.godmode_enabled
        SmartMode = Settings.smart_mode
        AutoReturnEnabled = Settings.auto_return_enabled
        ReturnCooldown = Settings.return_cooldown or (ReturnCooldown :: number?)
    end)

    return true
end

-- =========================
-- SAVE SETTINGS
-- =========================

function SaveUPFSettings(): boolean
    pcall(function(): nil
        -- Actualizar tabla local desde variables globales si cambian
        Settings.protection_enabled = (ProtectionEnabled :: boolean?) or Settings.protection_enabled
        Settings.protection_manual_override = (ProtectionManualOverride ~= nil) and ProtectionManualOverride or Settings.protection_manual_override
        Settings.godmode_enabled = (GodModeEnabled :: boolean?) or Settings.godmode_enabled
        Settings.smart_mode = (SmartMode :: string?) or Settings.smart_mode
        Settings.auto_return_enabled = (AutoReturnEnabled :: boolean?) or Settings.auto_return_enabled
        Settings.return_cooldown = (ReturnCooldown :: number?) or Settings.return_cooldown
        -- audio fields kept in Settings by module_audio
    end)

    local encoded: string = HttpService:JSONEncode(Settings :: SettingsTable)
    local ok: boolean = try_writefile(SETTINGS_FILENAME, encoded)

    if not ok then
        -- Fallback: guardar en memoria global si falla el archivo
        _G.UPF_LOCAL_SETTINGS = encoded
    end

    return ok
end

-- =========================
-- INITIALIZATION
-- =========================

-- Cargar al iniciar
LoadUPFSettings()
print("✅ Settings module loaded (persistence ready)")

-- =========================
-- EXPOSE TO GLOBAL API
-- =========================

_G.UPF = _G.UPF or {} :: table
_G.UPF.SaveSettings = _G.UPF.SaveSettings or SaveUPFSettings
_G.UPF.LoadSettings = _G.UPF.LoadSettings or LoadUPFSettings

print("✅ Settings functions exposed to _G.UPF (SaveSettings / LoadSettings)")
