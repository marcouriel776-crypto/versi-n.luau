-- module_antikick.luau
-- UPF Anti-Kick Protection (Stealth - LUAU MODE)
-- Características Luau: Tipado estricto, casts explícitos, sintaxis avanzada

local mt: table = getrawmetatable(game) :: table
setreadonly(mt, false)

local old: any = mt.__namecall

-- Hook con tipado estricto y casts explícitos
mt.__namecall = newcclosure(function(self: any, ...: any): any
    local method: string = getnamecallmethod()

    -- Intercepta llamadas a Kick
    if method == "Kick" then
        -- Log silencioso (sin print innecesario para stealth)
        warn("[UPF-AntiKick] Interceptado")
        return nil
    end

    -- Llamada original con argumentos pasados
    return old(self, ...)
end :: (...any) -> any)

setreadonly(mt, true)

print("✅ AntiKick v2 loaded (Luau typed)")
