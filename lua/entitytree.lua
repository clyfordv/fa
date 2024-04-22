local Entity = import('/lua/sim/Entity.lua').Entity
local FireEffects = import("/lua/effecttemplates.lua").TreeBurning01
local ApplyWindDirection = import("/lua/effectutilities.lua").ApplyWindDirection
local CreateScorchMarkSplat = import("/lua/defaultexplosions.lua").CreateScorchMarkSplat
local GetRandomFloat = import("/lua/utilities.lua").GetRandomFloat

local BurningTrees = 0
local MaximumBurningTrees = 150

-- upvalue for performance
local Random = Random
local ForkThread = ForkThread
local DamageArea = DamageArea
local WaitTicks = coroutine.yield
local CreateEmitterAtEntity = CreateEmitterAtEntity
local CreateLightParticleIntel = CreateLightParticleIntel

local TrashBag = TrashBag
local TrashAdd = TrashBag.Add
local TrashDestroy = TrashBag.Destroy

local EntityMethods = moho.entity_methods
local EntityDestroy = EntityMethods.Destroy
local EntitySetMesh = EntityMethods.SetMesh
local EntitySetScale = EntityMethods.SetScale
local EntityBeenDestroyed = EntityMethods.BeenDestroyed

local EffectMethods = moho.IEffect
local EffectScaleEmitter = EffectMethods.ScaleEmitter
local EffectOffsetEmitter = EffectMethods.OffsetEmitter
local EffectSetEmitterCurveParam = EffectMethods.SetEmitterCurveParam

local StringGsub = string.gsub

local TableInsert = table.insert

---@class EntityTree : Entity
---@field Trash TrashBag
---@field EntityId string
---@field Blueprint PropBlueprint -- it's an entity, but we're making it from a prop blueprint
---@field CachePosition Vector
---@field Fallen? boolean
---@field Burning? boolean
---@field NoBurn? boolean
EntityTree = Class(Entity) {

    ---@param self EntityTree
    ---@param spec EntitySpec
    OnCreate = function(self, spec)
        LOG('EntityTree on create')
        self.Trash = TrashBag()
        self.EntityId = self:GetEntityId()
        self.Blueprint = spec.Blueprint

        EntitySetMesh(self, self.Blueprint.Display.MeshBlueprint)
        local scale = self.Blueprint.Display.UniformScale
        EntitySetScale(self, scale, scale, scale)

        self:SetPosition(spec.Pos, true)
        self:SetOrientation(spec.Quat, true)
        self.CachePosition = spec.Pos

        self.Collider = self:CreateProjectileAtBone('DummyCollider', 0)
        self.Collider.Parent = self
        self.Collider:SetCollisionShape('Box', 0, self.Blueprint.SizeY/2 ,0 , self.Blueprint.SizeX, self.Blueprint.SizeY/2, self.Blueprint.SizeZ)
    end,

    ---@param self EntityTree
    OnDestroy = function(self)
        LOG('EntityTree on destroy')
        Entity.OnDestroy(self)

        -- reduce burning tree count
        if self.Burning then 
            BurningTrees = BurningTrees - 1
        end
    end,

    --- Collision check with projectiles
    ---@param self EntityTree
    ---@param other Projectile
    ---@return boolean
    OnCollisionCheck = function(self, other)
        LOG('EntityTree on collision check')
        return not self.Fallen
    end,

    --- Collision check with units
    ---@param self EntityTree
    ---@param targetType string
    ---@param targetEntity Unit
    OnCollision = function(self, targetType, targetEntity)
        local pos = self.CachePosition
        local tPos = targetEntity:GetPosition()
        LOG('EntityTree on collision')
        if self.Fallen then
            return
        end

        if self:BeenDestroyed() then
            return
        end

        -- change internal state
        self.Fallen = true
        TrashAdd(self.Trash, ForkThread(self.FallThread, self, tPos[1] - pos[1], 0, tPos[3] - pos[3], 0.5))
        self:PlayUprootingEffect(targetEntity)
    end,

    --- When damaged in some fashion - note that the tree can only be destroyed by disintegrating 
    --- damage and that the base class is not called accordingly.
    ---@param self EntityTree
    ---@param instigator Unit
    ---@param amount number
    ---@param direction number
    ---@param type DamageType
    OnDamage = function(self, instigator, amount, direction, type)
        LOG('EntityTree on damage')
        if self:BeenDestroyed() then
            return
        end

        local canFall = not self.Fallen 
        local canBurn = (not self.Burning) and (not self.NoBurn)

        --EntityDestroy(self)
        --if true then return end
        if type == 'Disintegrate' or type == "Reclaimed" then
            -- we just got obliterated
            EntityDestroy(self)

        elseif type == 'Force' or type == "TreeForce" then
            if canFall then
                -- change internal state
                self.NoBurn = true
                self.Fallen = true
                TrashAdd(self.Trash, ForkThread(self.FallThread, self, direction[1], direction[2], direction[3], 0.5))

                -- change the mesh
                --EntitySetMesh(self, self.Blueprint.Display.MeshBlueprintWrecked)
            end

        elseif type == 'Nuke' and canBurn then
            -- slight chance we catch fire
            if Random(1, 250) < 5 then
                self:Burn()
            end

        elseif (type == 'Fire' or type == 'TreeFire') and canBurn then 
            -- fire type damage, slightly higher odds to catch fire
            if Random(1, 35) <= 2 then
                self:Burn()
            end
        end
        
        if (type ~= 'Force') and (type ~= 'Fire') and canBurn and canFall then 
            -- any damage type but force can cause a burn
            if Random(1, 20) <= 1 then
                self:Burn()
            end
            self.Fallen = true
            TrashAdd(self.Trash, ForkThread(self.FallThread, self, direction[1], direction[2], direction[3], 0.5))
        end
    end,

    --- Uprooting effect when the tree falls over
    ---@param self EntityTree
    ---@param instigator Unit
    PlayUprootingEffect = function(self, instigator)
        CreateEmitterAtEntity( self, -1, '/effects/emitters/tree_uproot_01_emit.bp' )
        self:PlaySound('TreeFall')
    end,

    --- Contains all the falling logic
    ---@param self EntityTree
    ---@param dx number
    ---@param dy number
    ---@param dz number
    ---@param depth number
    FallThread = function(self, dx, dy, dz, depth)
        -- make it fall down
        -- we wait one tick, then SinkAway imperceptibly to prevent weird entity wiggling
        self:PushOver(dx, dy, dz, depth)
        WaitTicks(1)
        self:SinkAway(-.001)

        -- no longer be able to catch fire after a while
        WaitTicks(150 + Random(0, 50))
        self.NoBurn = true

        -- make it sink after a while
        --WaitTicks(150 + Random(0, 50))
        --self:SinkAway(-.1)

        -- get rid of it when it is completely below the terrain
        --WaitTicks(100)
        --EntityDestroy(self)
    end,

    ---@param self EntityTree
    Burn = function(self)
        -- limit maximum number of burning trees on the map
        if Random(1, MaximumBurningTrees) > BurningTrees then 
            BurningTrees = BurningTrees + 1

            self.Burning = true 
            TrashAdd(self.Trash, ForkThread(self.BurnThread, self))
        end
    end,

    --- Contains all the burning logic
    ---@param self EntityTree
    BurnThread = function(self)

        -- used throughout this function
        local trash = self.Trash
        local position = self.CachePosition

        local effect
        local effects = { }
        local effectsHead = 1

        local fireSize = 0.75 * Random() + 0.25

        -- fire effect
        for k, v in FireEffects do

            effect = CreateEmitterAtEntity(self, -1, v )
            EffectOffsetEmitter(effect, 0, 0.15, 0)
            EffectScaleEmitter(effect, 3)

            -- keep track
            effects[effectsHead] = effect
            effectsHead = effectsHead + 1

            -- add it to trash bag
            TrashAdd(trash, effect)
        end

        -- add randomness to direction of smoke
        ApplyWindDirection(effects[3], 1.0)

        -- light splash
        effect = CreateLightParticleIntel( self, -1, -1, 1.5, 10, 'glow_03', 'ramp_flare_02' )

        -- sounds
        self:PlaySound('BurnStart')
        self:PlayAmbientSound('BurnLoop')

        -- wait a bit before we change to a scorched tree
        WaitTicks(50 + Random(0, 10))
        EntitySetMesh(self, self.Blueprint.Display.MeshBlueprintWrecked)

        -- more fire effects
        for i = 5, 1, -1 do

            -- do not change the distort effect
            effects[1]:ScaleEmitter(3 + fireSize * (5 - i))
            effects[3]:ScaleEmitter(3 + fireSize * (5 - i))

            -- hold up a bit
            WaitTicks(20 + Random(10, 50))

            -- try and spread out the fire
            if i == 3 then
                DamageArea(self, position, 1, 1, 'TreeFire', true)
            end
        end

        -- wait a bit before we make a scorch mark
        WaitTicks(50 + Random(0, 10))
        CreateScorchMarkSplat( self, 0.5, -1 )

        -- try and spread the fire
        DamageArea(self, position, 1, 1, 'TreeFire', true)

        -- stop all sound
        self:PlayAmbientSound(nil)

        -- destroy all effects
        for k = 1, effectsHead - 1 do 
            effects[k]:Destroy()
        end

        -- add smoke effect removed when the tree is destroyed
        effect = CreateEmitterAtEntity(self, -1, FireEffects[3] )
        EffectScaleEmitter(effect, 2 + Random())
        ApplyWindDirection(effect, 0.75)
        TrashAdd(trash, effect)

        -- fall down in a random direction if we didn't before
        if not self.Fallen then 
            self.Fallen = true
            self:FallThread(Random() * 2 - 1, 0, Random() * 2 - 1, 0.25)
        end
    end,

    ---@param self EntityTree
    ---@param sound string The identifier in the prop blueprint.
    PlaySound = function(self, sound)
        local bp = self.Blueprint.Audio
        if bp and bp[sound] then
            self:PlaySound(bp[sound])
        end
    end,

    ---@param self EntityTree
    ---@param sound string
    PlayAmbientSound = function(self, sound)
        if sound == nil then
            self:SetAmbientSound(nil, nil)
        else
            local bp = self.Blueprint.Audio
            if bp and bp[sound] then
                self:SetAmbientSound(bp[sound], nil)
            end
        end
    end,
}