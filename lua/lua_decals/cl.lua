local ENT = FindMetaTable("Entity")

-- Adds another model duplicate that renders on top of the original model, 
-- this model can then have decals applied to it
-- You can create as many layers as you want, but be aware that each layer is another model to render
-- so it can get expensive
function ENT:LUADecals_AddModelLayer()
    local mdl = ClientsideModel(self:GetModel(), RENDERGROUP_OPAQUE)
    
    -- Mimic the original entity's position and angles
    mdl:SetPos(self:GetPos())
    mdl:SetAngles(self:GetAngles())
    
    -- Bone merge
    mdl:SetParent(self)
    mdl:AddEffects(EF_BONEMERGE)

    -- Debug: color however we like
    mdl:SetRenderMode(RENDERMODE_TRANSCOLOR)
    mdl:SetColor(Color(255,0,0,255))

    -- Spawn
    mdl:Spawn()

    -- Debug: remove after 1 second
    timer.Simple(1, function()
        mdl:Remove()
    end)
end

-- Command interface for adding a model layer
concommand.Add("luadecals_addmodellayer", function(ply, cmd, args)
    local tr = ply:GetEyeTrace()
    tr.Entity:LUADecals_AddModelLayer()
end)
