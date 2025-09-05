local ENT = FindMetaTable("Entity")
local invis = Color(255,255,255,1)

-- Adds another model duplicate that renders on top of the original model, 
-- this model can then have decals applied to it
-- You can create as many layers as you want, but be aware that each layer is another model to render
-- so it can get expensive
function ENT:LUADecals_AddModelLayer() --> CSEnt | nil
    self.LUADecals_ModelLayers = self.LUADecals_ModelLayers or {}

    local mdlLayer = ClientsideModel(self:GetModel(), RENDERGROUP_OPAQUE)
    if !mdlLayer then 
        return 
    end

    -- Mimic the original entity's position and angles
    mdlLayer:SetPos(self:GetPos())
    mdlLayer:SetAngles(self:GetAngles())

    -- Bone merge
    mdlLayer:SetParent(self)
    mdlLayer:AddEffects(EF_BONEMERGE)

    -- Make barely visible
    mdlLayer:SetRenderMode(RENDERMODE_TRANSCOLOR)
    mdlLayer:SetColor(invis)

    -- Keep track of number of decals on layer
    mdlLayer.LuaDecals_nAppliedDecals = 0

    -- Spawn
    mdlLayer:Spawn()

    -- Add to entity's model layers table
    mdlLayer:CONV_StoreInTable(self.LUADecals_ModelLayers)

    -- Debug: Remove after delay.
    SafeRemoveEntityDelayed(mdlLayer, 30)

    print("NEW layer created", mdlLayer)

    return mdlLayer
end

-- Pushes a new decal to the entity.
-- If many decals have been applied to the model,
-- create a new layer and start applying to it instead,
-- until that one fills up as well, and move on to the next layer
-- and so on..
function ENT:LUADecals_Add(
    material,   -- : Material
    pos,        -- : Vector
    nrm,        -- : Vector
    col,        -- : Color
    width,      -- : number
    height,     -- : number
    n_limit     -- : number
) --> nil
    -- Init n applied decals counter
    self.LuaDecals_nAppliedDecals = self.LuaDecals_nAppliedDecals or 0

    local entToApplyTo = self

    -- Apply to layer instead if limit reached
    if self.LuaDecals_nAppliedDecals >= n_limit then
        local mdlLayer

        -- No model layers yet, then add our first
        if !self.LUADecals_ModelLayers then
            print("creating first layer for", self)
            mdlLayer = self:LUADecals_AddModelLayer()
        else
            -- ..we have model layers, get the latest one
            mdlLayer = self.LUADecals_ModelLayers[#self.LUADecals_ModelLayers]

            -- If this layer has reached its limit..
            if mdlLayer.LuaDecals_nAppliedDecals >= n_limit then
                -- Add a new one:
                mdlLayer = self:LUADecals_AddModelLayer()
            end
        end

        entToApplyTo = mdlLayer
    end

    -- Apply decal
    if IsValid(entToApplyTo) then
        util.DecalEx(material, entToApplyTo, pos, nrm, col, width, height)

        -- Increment decal count
        entToApplyTo.LuaDecals_nAppliedDecals = entToApplyTo.LuaDecals_nAppliedDecals + 1
        print(entToApplyTo.LuaDecals_nAppliedDecals, "decals added to", entToApplyTo)
    end
end

-- Command interface for adding a model layer
concommand.Add("luadecals_addmodellayer", function(ply, cmd, args)
    local tr = ply:GetEyeTrace()
    tr.Entity:LUADecals_AddModelLayer()
end)

-- Command interface for applying decal
concommand.Add("luadecals_add", function(ply, cmd, args)
    local tr = ply:GetEyeTrace()

    tr.Entity:LUADecals_Add(Material("decals/flesh/blood1"), tr.HitPos, tr.HitNormal, color_white, 1, 1, 8 )
end)