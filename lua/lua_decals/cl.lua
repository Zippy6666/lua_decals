local ENT           = FindMetaTable("Entity")
local invis         = Color(255,255,255,1)
local didBulletHook = false
local mat1          = Material("decals/flesh/blood1")
local mat2          = Material("decals/flesh/blood2")
local mat3          = Material("decals/flesh/blood3")
local mat4          = Material("decals/flesh/blood4")
local mat5          = Material("decals/flesh/blood5")
local alienmat1     = Material("decals/alienflesh/shot1")
local alienmat2     = Material("decals/alienflesh/shot2")
local alienmat3     = Material("decals/alienflesh/shot3")
local alienmat4     = Material("decals/alienflesh/shot4")
local alienmat5     = Material("decals/alienflesh/shot5")
local antmat1       = Material("decals/antlion/shot1")
local antmat2       = Material("decals/antlion/shot2")
local antmat3       = Material("decals/antlion/shot3")
local antmat4       = Material("decals/antlion/shot4")
local antmat5       = Material("decals/antlion/shot5")
local fleshMats     = {mat1, mat2, mat3, mat4, mat5}
local alienMats     = {alienmat1, alienmat2, alienmat3, alienmat4, alienmat5}
local antlionMats   = {antmat1, antmat2, antmat3, antmat4, antmat5}
local preventDecalExWrapper = false

-- Adds another model duplicate that renders on top of the original model, 
-- this model can then have decals applied to it
-- You can create as many layers as you want, but be aware that each layer is another model to render
-- so it can get expensive
function ENT:LUADecals_AddModelLayer() --> CSEnt | nil
    if self:IsWorld() then return end -- This is not supported for the world
    
    self.LUADecals_ModelLayers = self.LUADecals_ModelLayers or {}

    local mdlLayer = ClientsideModel(self:GetModel(), RENDERGROUP_TRANSLUCENT)
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
    mdlLayer:SetRenderMode(RENDERMODE_TRANSADD)
    mdlLayer:SetColor(invis)

    -- Keep track of number of decals on layer
    mdlLayer.LuaDecals_nAppliedDecals = 0

    -- Spawn
    mdlLayer:Spawn()

    -- Add to entity's model layers table
    mdlLayer:CONV_StoreInTable(self.LUADecals_ModelLayers)

    -- Debug: Remove after delay.
    -- SafeRemoveEntityDelayed(mdlLayer, 30)

    return mdlLayer
end

-- Pushes a new decal to the entity.
-- If many decals have been applied to the model,
-- create a new layer and start applying to it instead,
-- until that one fills up as well, and move on to the next layer
-- and so on..
-- Returns:
--      bool: true if success, else false
function ENT:LUADecals_Add(
    material,   -- : Material
    pos,        -- : Vector
    nrm,        -- : Vector
    col,        -- : Color
    width,      -- : number
    height,     -- : number
    n_limit     -- : number
) --> bool
    if self:IsWorld() then return false end -- This is not supported for the world

    -- Apply to layer

    local mdlLayer
    local layerN

    -- No model layers yet, then add our first
    if !self.LUADecals_ModelLayers then
        print("creating first layer for", self)

        mdlLayer = self:LUADecals_AddModelLayer()
        layerN = 1
    else
        -- ..we have model layers, get the latest one
        mdlLayer = self.LUADecals_ModelLayers[#self.LUADecals_ModelLayers]

        -- If this layer has reached its limit..
        if mdlLayer.LuaDecals_nAppliedDecals >= n_limit then
            -- Add a new one:
            mdlLayer = self:LUADecals_AddModelLayer()
        end

        layerN = #self.LUADecals_ModelLayers
    end

    if IsValid(mdlLayer) then
        -- Prevent endless loop with wrapper func
        preventDecalExWrapper = true

        -- Apply decal
        util.DecalEx(material, mdlLayer, pos, nrm, col, width, height)
        preventDecalExWrapper = false

        -- Increment decal count
        mdlLayer.LuaDecals_nAppliedDecals = mdlLayer.LuaDecals_nAppliedDecals + 1
        print(material, mdlLayer.LuaDecals_nAppliedDecals, "decals added to", self, ", layer number: ", layerN)
        
        -- Success
        return true
    end

    return false
end

-- EXPERIMENTAL: Add a wrapper for util.DecalEx so that fancy blood mods
-- utilize this system unwillingly
util.DecalEx = conv.wrapFunc( "luadecals_override", util.DecalEx, function(material, entToApplyTo, pos, nrm, col, width, height)
    if preventDecalExWrapper then return end

    -- Override
    local success = entToApplyTo:LUADecals_Add(material, pos, nrm, col, width, height, 3)
    
    if success == true then
        -- Don't return success directly!! returning false here would still skip the
        -- regular call
        return true
    end
end)

-- Fire bullet hook clientside, will only exist in multiplayer!
hook.Add("EntityFireBullets", "luadecals_bulletimpact", function( ent, data )
    if didBulletHook then return end

    data.Callback = conv.wrapFunc2( data.Callback or function(...) end, nil, function(_, attacker, tr)
        local mat
        if tr.MatType == MAT_ANTLION then
            mat = antlionMats[math.random(1, #antlionMats)]
        elseif tr.MatType == MAT_FLESH then
            mat = fleshMats[math.random(1, #fleshMats)]
        elseif tr.MatType == MAT_ALIENFLESH then
            mat = alienMats[math.random(1, #alienMats)]
        end

        if mat then
            print(mat)
            tr.Entity:LUADecals_Add(mat, tr.HitPos, tr.HitNormal, color_white, 1, 1, 5 )
        end
    end)

    didBulletHook = true
    hook.Run("EntityFireBullets", ent, data)
    didBulletHook = false

    return true
end)

-- Single player alternative to the hook above..
net.Receive("luadecals_sendBulletImpactToCl", function()
    local pos =    net.ReadVector()
    local nrm =    net.ReadNormal()
    local matType =    net.ReadUInt(7)
    local ent =    net.ReadEntity()     

    if IsValid(ent) then
        local mat
        if matType == MAT_ANTLION then
            mat = antlionMats[math.random(1, #antlionMats)]
        elseif matType == MAT_FLESH then
            mat = fleshMats[math.random(1, #fleshMats)]
        elseif matType == MAT_ALIENFLESH then
            mat = alienMats[math.random(1, #alienMats)]
        end

        if mat then
            ent:LUADecals_Add(mat, pos, nrm, color_white, 1, 1, 5 )
        end
    end
end)

-- Transfer entity's decal layers onto server ragdoll
hook.Add("EntityRemoved", "luadecals_transfer_to_rag", function( ent )
    if !ent.LUADecals_ModelLayers then return end

    local fndEntToTransferTo = false

    if ent:IsNPC() || ent:IsNextBot() then
        -- Find nearby ents when removed
        -- if it is a ragdoll with its model
        -- transfer layers to it
        for _, fndEnt in ipairs(ents.FindInSphere(ent:GetPos(), 50)) do
            if fndEnt:GetClass() == "prop_ragdoll" && fndEnt:GetModel()==ent:GetModel() then
                for _, mdlLayer in ipairs(ent.LUADecals_ModelLayers) do
                    mdlLayer:SetParent(fndEnt)
                end

                -- Hold reference to old entitys layer table
                fndEnt.LUADecals_ModelLayers = ent.LUADecals_ModelLayers

                -- Copy decal count
                fndEnt.LUADecals_nAppliedDecals = ent.LuaDecals_nAppliedDecals

                fndEntToTransferTo = true
                break
            end
        end
    end

    -- Remove decal layers of removed entity if no
    -- ent found to transfer to
    if !fndEntToTransferTo then
        for _, mdlLayer in ipairs(ent.LUADecals_ModelLayers) do
            mdlLayer:Remove()
        end

        print("found nothing to transfer to")
    end
end)

-- Transfer entity's decal layers when the entity turns into a client ragdoll
hook.Add("CreateClientsideRagdoll", "luadecals_tranfer", function( ent, rag )
    for _, mdlLayer in ipairs(ent.LUADecals_ModelLayers or {}) do
        mdlLayer:SetParent(rag)
    end

    ent.LUADecals_ModelLayers = nil -- Point layer table of ent back at nothing
end)

-- Command interface for adding a model layer
concommand.Add("luadecals_addmodellayer", function(ply, cmd, args)
    local tr = ply:GetEyeTrace()
    tr.Entity:LUADecals_AddModelLayer()
end)

-- Command interface for applying decal
concommand.Add("luadecals_add", function(ply, cmd, args)
    local tr = ply:GetEyeTrace()

    tr.Entity:LUADecals_Add(Material("decals/flesh/blood1"), tr.HitPos, tr.HitNormal, color_white, 1, 1, 5 )
end)