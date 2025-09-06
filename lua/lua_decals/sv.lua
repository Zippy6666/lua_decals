if !game.SinglePlayer() then return end -- SINGLE PLAYER ONLY

util.AddNetworkString("luadecals_sendBulletImpactToCl")

-- Single player-way of detecting bullet impacts so that we can apply our decal layers
local didBulletHook = false
hook.Add("EntityFireBullets", "luadecals_bulletimpact", function( ent, data )
    if didBulletHook then return end

    -- Default wounds disabled for LUA decals...
    if Entity(1):GetInfoNum("luadecals_enable", 0) == 0 then return end

    data.Callback = conv.wrapFunc2( data.Callback or function(...) end, nil, function(_, attacker, tr)
        net.Start("luadecals_sendBulletImpactToCl")
        net.WriteVector(tr.HitPos)
        net.WriteNormal(tr.HitNormal)
        net.WriteUInt(tr.MatType, 7)
        net.WriteEntity(tr.Entity)        
        net.Send(Entity(1))
    end)

    didBulletHook = true
    hook.Run("EntityFireBullets", ent, data)
    didBulletHook = false

    return true
end)