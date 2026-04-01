-- installer.luau
-- UPF Auto-Installer for Delta (LUAU MODE)
-- Características Luau: Tipos estrictos en rutas, casts explícitos, verificación de permisos robusta

-- =========================
-- CONFIGURACIÓN
-- =========================

local TARGET_DIR: string = "/storage/emulated/0/Delta/Autoexecute/"
local TARGET_FILE: string = TARGET_DIR .. "loader_v4.luau"

local SOURCE_URL: string = "https://github.com/marcouriel776-crypto/versi-n.luau/blob/main/loader_v4.luau"

-- NOTA: Este instalador busca instalar loader.lua (versión Lua clásica)
-- Si quieres que instale la versión Luau, cambia TARGET_FILE a "loader.luau"
-- y asegúrate de que el executor soporte Luau en la ruta de autoejecución.

-- =========================
-- TYPE DEFINITIONS
-- =========================

type FileResult = (boolean, string?)
type BoolResult = (boolean, string?)

-- =========================
-- UTILIDADES
-- =========================

local function safe_pcall(fn: any, ...: any): (boolean, any?)
    local ok: boolean, res: any? = pcall(fn, ...)
    return ok, res
end

local function file_exists(path: string): boolean
    if type(readfile) ~= "function" then
        return false
    end
    local ok: boolean = pcall(readfile, path)
    return ok
end

local function ensure_write_access(): BoolResult
    if type(writefile) ~= "function" then
        return false, "writefile not available"
    end

    local test_file: string = TARGET_DIR .. "_upf_write_test.tmp"
    local ok: boolean, err: string? = pcall(writefile, test_file, "test")
    
    if not ok then
        return false, err
    end

    -- Limpiar archivo de prueba
    pcall(function(): nil
        if type(delfile) == "function" then
            delfile(test_file)
        end
    end)

    return true, nil
end

-- =========================
-- AUTOINSTALACIÓN
-- =========================

local function autoinstall(): nil
    -- Verificar si ya está instalado
    if file_exists(TARGET_FILE) then
        print("[loader] ✅ Ya instalado en " .. TARGET_FILE)
        return
    end

    print("[loader] Intentando autoinstalar...")

    -- Verificar existencia de la carpeta
    local folder_ok: boolean = true
    if type(listfiles) == "function" then
        local ok: boolean = pcall(function(): nil
            listfiles(TARGET_DIR)
        end)
        folder_ok = ok
    end

    if not folder_ok then
        warn("[loader] ❌ La carpeta no existe o no es accesible: " .. TARGET_DIR)
        warn("[loader] Crea la carpeta manualmente o verifica la ruta correcta.")
        return
    end

    -- Verificar permisos de escritura
    local can_write: boolean, write_err: string? = ensure_write_access()
    if not can_write then
        warn("[loader] ❌ No se puede escribir en la carpeta. Error: " .. tostring(write_err))
        warn("[loader] Asegúrate de que Delta tenga permisos de almacenamiento.")
        return
    end
    print("[loader] ✅ Permisos de escritura OK")

    -- Descargar script desde GitHub
    local source: string?
    local download_ok: boolean, content: any? = safe_pcall(game.HttpGet, game, SOURCE_URL)
    
    if download_ok and content and #content :: string > 0 then
        source = content :: string
        print("[loader] ✅ Script descargado desde GitHub")
    end

    if not source then
        warn("[loader] ❌ No se pudo descargar el loader.")
        return
    end

    -- Escribir archivo
    local write_ok: boolean, write_err2: string? = pcall(writefile, TARGET_FILE, source)
    if write_ok then
        print("[loader] ✅ Autoinstalado correctamente en " .. TARGET_FILE)
        print("[loader] 🚀 A partir de ahora se ejecutará solo al inyectar Delta.")
    else
        warn("[loader] ❌ Error al escribir: " .. tostring(write_err2))
    end
end

-- Ejecutar instalación
autoinstall()

print("✅ installer.luau ejecutado")
