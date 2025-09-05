local ENT = FindMetaTable("Entity")

LUADecals.ents = {} 

function ENT:LUADecals_Add(material_name, pos, nrm)
    -- Initialize if not done already.
    if !self.LUADecals then 
        self.LUADecals /* : Sequence[LUADecal] */ = {} 

        table.insert(LUADecals.ents, self)
    end

    local mat = Material(material_name)

    -- Add LUADecal object to self.
    local lua_decal = {
        imesh = Mesh(mat),
        mat = mat,
        size = 1,

        -- Freeze position and angle for now
        pos = pos,
        nrm = nrm,
    }

    table.insert(self.LUADecals, lua_decal)
end

-- Console command to add a decal.
concommand.Add("lua_decals_add", function(ply)
    local tr = ply:GetEyeTrace()
    local ent = tr.Entity
    
    if !IsValid(ent) then return end

    ent:LUADecals_Add("decals/concrete/shot1", tr.HitPos, tr.HitNormal)
end)

-- Continuous hook.
hook.Add("PostDrawTranslucentRenderables", "lua_decals", function()
    for ent_tbl_idx = 1, #LUADecals.ents do
        
        local ent = LUADecals.ents[ent_tbl_idx]
        
        -- If entity went invalid, remove it from the list.
        if !IsValid(ent) then 
            table.remove(LUADecals.ents, ent_tbl_idx)
            continue
        end

        -- Make sure decal table exists.
        if !ent.LUADecals then
            error("LUADecals: Entity in global list but has no .LUADecals table!")
        end

        -- Get meshes for this entity.
        -- local meshes = util.GetModelMeshes(ent:GetModel())
        -- if !meshes then 
        --     -- No meshes, fine, skip
        --     continue 
        -- end

        -- Draw each decal on this entity.
        for decal_idx = 1, #ent.LUADecals do
            local lua_decal = ent.LUADecals[decal_idx]
            
            -- 
        end
    end
end)