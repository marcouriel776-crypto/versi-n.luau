-- module_admin_detector.luau
-- UPF Admin Detector (Keyword Scan - LUAU MODE)
-- Características Luau: Tipos estrictos en arrays, casts explícitos, sintaxis moderna

local Players: PlayersService = game:GetService("Players")
local UPF: table = getgenv().UPF :: table

-- =========================
-- TYPE DEFINITIONS
-- =========================

type AdminKeywords = {string}
type AdminFlags = {
    AdminPresent: boolean,
}

type AdminTable = {
    Check: () -> nil,
}

-- =========================
-- ADMIN DETECTOR IMPLEMENTATION
-- =========================

local Admin: AdminTable = {}
UPF.Admin = Admin

-- Palabras clave con tipo estricto
local keywords: AdminKeywords = {"mod", "admin", "owner", "staff"}

-- =========================
-- CHECK FOR ADMINS
-- =========================

function Admin:Check(): nil
    for _, p: Player in ipairs(Players:GetPlayers()) do
        local name: string = string.lower(p.Name)

        for _, k: string in ipairs(keywords) do
            -- Búsqueda de palabra clave con cast explícito
            if string.find(name, k :: string) then
                warn("[UPF-Admin] posible admin detectado:", p.Name)

                -- Inicializar banderas si no existen
                UPF.Flags = UPF.Flags or {} :: AdminFlags
                UPF.Flags.AdminPresent = true :: boolean
                return
            end
        end
    end

    -- Si no se encuentra ningún admin, establecer en falso
    UPF.Flags = UPF.Flags or {} :: AdminFlags
    UPF.Flags.AdminPresent = false :: boolean
end

-- =========================
-- EXPORT
-- =========================

return Admin :: AdminTable
