--****************************************************************************
--**
--**  File     :  /cdimage/units/XSL0001/XSL0001_script.lua
--**  Author(s):  Drew Staltman, Jessica St. Croix, Gordon Duclos
--**
--**  Summary  :  Seraphim Commander Script
--**
--**  Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************
local ACUUnit = import('/lua/defaultunits.lua').ACUUnit
local Buff = import('/lua/sim/Buff.lua')
local SWeapons = import('/lua/seraphimweapons.lua')
local SDFChronotronCannonWeapon = SWeapons.SDFChronotronCannonWeapon
local SDFChronotronOverChargeCannonWeapon = SWeapons.SDFChronotronCannonOverChargeWeapon
local SIFCommanderDeathWeapon = SWeapons.SIFCommanderDeathWeapon
local EffectTemplate = import('/lua/EffectTemplates.lua')
local EffectUtil = import('/lua/EffectUtilities.lua')
local SIFLaanseTacticalMissileLauncher = SWeapons.SIFLaanseTacticalMissileLauncher
local AIUtils = import('/lua/ai/aiutilities.lua')

XSL0001 = Class(ACUUnit) {
    Weapons = {
        DeathWeapon = Class(SIFCommanderDeathWeapon) {},
        ChronotronCannon = Class(SDFChronotronCannonWeapon) {},
        Missile = Class(SIFLaanseTacticalMissileLauncher) {
            OnCreate = function(self)
                SIFLaanseTacticalMissileLauncher.OnCreate(self)
                self:SetWeaponEnabled(false)
            end,
        },
        OverCharge = Class(SDFChronotronOverChargeCannonWeapon) {},
    },

    __init = function(self)
        ACUUnit.__init(self, 'ChronotronCannon')
    end,

    OnCreate = function(self)
        ACUUnit.OnCreate(self)
        self:SetCapturable(false)
        self:SetupBuildBones()
        self:HideBone('Back_Upgrade', true)
        self:HideBone('Right_Upgrade', true)
        self:HideBone('Left_Upgrade', true)
        -- Restrict what enhancements will enable later
        self:AddBuildRestriction( categories.SERAPHIM * (categories.BUILTBYTIER2COMMANDER + categories.BUILTBYTIER3COMMANDER) )
    end,

    OnStopBeingBuilt = function(self,builder,layer)
        ACUUnit.OnStopBeingBuilt(self,builder,layer)
        self:SetWeaponEnabledByLabel('ChronotronCannon', true)
        self:ForkThread(self.GiveInitialResources)
        self.ShieldEffectsBag = {}
    end,

    PlayCommanderWarpInEffect = function(self)
        self:HideBone(0, true)
        self:SetUnSelectable(true)
        self:SetBusy(true)
        self:SetBlockCommandQueue(true)
        self:ForkThread(self.WarpInEffectThread)
    end,

    WarpInEffectThread = function(self)
        self:PlayUnitSound('CommanderArrival')
        self:CreateProjectile( '/effects/entities/UnitTeleport01/UnitTeleport01_proj.bp', 0, 1.35, 0, nil, nil, nil):SetCollision(false)
        WaitSeconds(2.1)
        self:ShowBone(0, true)
        self:HideBone('Back_Upgrade', true)
        self:HideBone('Right_Upgrade', true)
        self:HideBone('Left_Upgrade', true)
        self:SetUnSelectable(false)
        self:SetBusy(false)
        self:SetBlockCommandQueue(false)

        local totalBones = self:GetBoneCount() - 1
        local army = self:GetArmy()
        for k, v in EffectTemplate.UnitTeleportSteam01 do
            for bone = 1, totalBones do
                CreateAttachedEmitter(self,bone,army, v)
            end
        end

        WaitSeconds(6)
    end,

    CreateBuildEffects = function( self, unitBeingBuilt, order )
        EffectUtil.CreateSeraphimUnitEngineerBuildingEffects( self, unitBeingBuilt, self:GetBlueprint().General.BuildBones.BuildEffectBones, self.BuildEffectsBag )
    end,

    GetUnitsToBuff = function(self, bp)
        local unitCat = ParseEntityCategory( bp.UnitCategory or 'BUILTBYTIER3FACTORY + BUILTBYQUANTUMGATE + NEEDMOBILEBUILD')
        local brain = self:GetAIBrain()
        local all = brain:GetUnitsAroundPoint(unitCat, self:GetPosition(), bp.Radius, 'Ally')
        local units = {}

        for _, u in all do
            if not u.Dead and not u:IsBeingBuilt() then
                table.insert(units, u)
            end
        end

        return units
    end,

    RegenBuffThread = function(self, type)
        local bp = self:GetBlueprint().Enhancements[type]
        local buff = 'SeraphimACU' .. type

        while not self.Dead do
            local units = self:GetUnitsToBuff(bp)
            for _,unit in units do
                Buff.ApplyBuff(unit, buff)
            end
            WaitSeconds(5)
        end
    end,

    CreateEnhancement = function(self, enh)
        ACUUnit.CreateEnhancement(self, enh)

        local bp = self:GetBlueprint().Enhancements[enh]

        -- Regenerative Aura
        if enh == 'RegenAura' or enh == 'AdvancedRegenAura' then
            local buff
            local type

            buff = 'SeraphimACU' .. enh

            if not Buffs[buff] then
                local buff_bp = {
                    Name = buff,
                    DisplayName = buff,
                    BuffType = 'COMMANDERAURA',
                    Stacks = 'REPLACE',
                    Duration = 5,
                    Affects = {
                        RegenPercent = {
                            Add = 0,
                            Mult = bp.RegenPerSecond or 0.1,
                            Ceil = bp.RegenCeiling,
                            Floor = bp.RegenFloor,
                        },
                    },
                }

                if enh == 'AdvancedRegenAura' then
                    buff_bp.Affects.MaxHealth =
                    {
                            Add = 0,
                            Mult = bp.MaxHealthFactor or 1.0,
                            DoNoFill = true,
                }
            end

                BuffBlueprint(buff_bp)
            end

            if not Buffs[buff .. 'SelfBuff'] then   -- AURA SELF BUFF
                BuffBlueprint {
                    Name = buff .. 'SelfBuff',
                    DisplayName = buff .. 'SelfBuff',
                    BuffType = 'COMMANDERAURAFORSELF',
                    Stacks = 'REPLACE',
                    Duration = -1,
                    Affects = {
                        MaxHealth = {
                            Add = bp.ACUAddHealth or 0,
                            Mult = 1,
                        },
                    },
                }
            end

            Buff.ApplyBuff(self, buff .. 'SelfBuff')
            table.insert( self.ShieldEffectsBag, CreateAttachedEmitter( self, 'XSL0001', self:GetArmy(), '/effects/emitters/seraphim_regenerative_aura_01_emit.bp' ) )
            if self.RegenThreadHandle then
                KillThread(self.RegenThreadHandle)
                self.RegenThreadHandle = nil
            end

            self.RegenThreadHandle = self:ForkThread(self.RegenBuffThread, enh)
        elseif enh == 'RegenAuraRemove' or enh == 'AdvancedRegenAuraRemove' then
            if self.ShieldEffectsBag then
                for k, v in self.ShieldEffectsBag do
                    v:Destroy()
                end
		        self.ShieldEffectsBag = {}
		    end

            KillThread(self.RegenThreadHandle)
            self.RegenThreadHandle = nil
            for _, b in {'SeraphimACURegenAura', 'SeraphimACUAdvancedRegenAura'} do
                if Buff.HasBuff(self, b .. 'SelfBuff') then
                    Buff.RemoveBuff(self, b .. 'SelfBuff')
                end
            end
        elseif enh == 'ResourceAllocation' then
            local bp = self:GetBlueprint().Enhancements[enh]
            local bpEcon = self:GetBlueprint().Economy
            if not bp then return end
            self:SetProductionPerSecondEnergy(bp.ProductionPerSecondEnergy + bpEcon.ProductionPerSecondEnergy or 0)
            self:SetProductionPerSecondMass(bp.ProductionPerSecondMass + bpEcon.ProductionPerSecondMass or 0)
        elseif enh == 'ResourceAllocationRemove' then
            local bpEcon = self:GetBlueprint().Economy
            self:SetProductionPerSecondEnergy(bpEcon.ProductionPerSecondEnergy or 0)
            self:SetProductionPerSecondMass(bpEcon.ProductionPerSecondMass or 0)
        elseif enh == 'ResourceAllocationAdvanced' then
            local bp = self:GetBlueprint().Enhancements[enh]
            local bpEcon = self:GetBlueprint().Economy
            if not bp then return end
            self:SetProductionPerSecondEnergy(bp.ProductionPerSecondEnergy + bpEcon.ProductionPerSecondEnergy or 0)
            self:SetProductionPerSecondMass(bp.ProductionPerSecondMass + bpEcon.ProductionPerSecondMass or 0)
        elseif enh == 'ResourceAllocationAdvancedRemove' then
            local bpEcon = self:GetBlueprint().Economy
            self:SetProductionPerSecondEnergy(bpEcon.ProductionPerSecondEnergy or 0)
            self:SetProductionPerSecondMass(bpEcon.ProductionPerSecondMass or 0)
        --Damage Stabilization
        elseif enh == 'DamageStabilization' then
            if not Buffs['SeraphimACUDamageStabilization'] then
               BuffBlueprint {
                    Name = 'SeraphimACUDamageStabilization',
                    DisplayName = 'SeraphimACUDamageStabilization',
                    BuffType = 'ACUUPGRADEDMG',
                    Stacks = 'ALWAYS',
                    Duration = -1,
                    Affects = {
                        MaxHealth = {
                            Add = bp.NewHealth,
                            Mult = 1.0,
                        },
                        Regen = {
                            Add = bp.NewRegenRate,
                            Mult = 1.0,
                        },
                    },
                }
            end
            if Buff.HasBuff( self, 'SeraphimACUDamageStabilization' ) then
                Buff.RemoveBuff( self, 'SeraphimACUDamageStabilization' )
            end
            Buff.ApplyBuff(self, 'SeraphimACUDamageStabilization')
      	elseif enh == 'DamageStabilizationAdvanced' then
            if not Buffs['SeraphimACUDamageStabilizationAdv'] then
               BuffBlueprint {
                    Name = 'SeraphimACUDamageStabilizationAdv',
                    DisplayName = 'SeraphimACUDamageStabilizationAdv',
                    BuffType = 'ACUUPGRADEDMG',
                    Stacks = 'ALWAYS',
                    Duration = -1,
                    Affects = {
                        MaxHealth = {
                            Add = bp.NewHealth,
                            Mult = 1.0,
                        },
                        Regen = {
                            Add = bp.NewRegenRate,
                            Mult = 1.0,
                        },
                    },
                }
            end
            if Buff.HasBuff( self, 'SeraphimACUDamageStabilizationAdv' ) then
                Buff.RemoveBuff( self, 'SeraphimACUDamageStabilizationAdv' )
            end
            Buff.ApplyBuff(self, 'SeraphimACUDamageStabilizationAdv')
        elseif enh == 'DamageStabilizationAdvancedRemove' then
            -- since there's no way to just remove an upgrade anymore, if we're remove adv, were removing both
            if Buff.HasBuff( self, 'SeraphimACUDamageStabilizationAdv' ) then
                Buff.RemoveBuff( self, 'SeraphimACUDamageStabilizationAdv' )
            end
            if Buff.HasBuff( self, 'SeraphimACUDamageStabilization' ) then
                Buff.RemoveBuff( self, 'SeraphimACUDamageStabilization' )
            end
        elseif enh == 'DamageStabilizationRemove' then
            if Buff.HasBuff( self, 'SeraphimACUDamageStabilization' ) then
                Buff.RemoveBuff( self, 'SeraphimACUDamageStabilization' )
            end
        --Teleporter
        elseif enh == 'Teleporter' then
            self:AddCommandCap('RULEUCC_Teleport')
        elseif enh == 'TeleporterRemove' then
            self:RemoveCommandCap('RULEUCC_Teleport')
        -- Tactical Missile
        elseif enh == 'Missile' then
            self:AddCommandCap('RULEUCC_Tactical')
            self:AddCommandCap('RULEUCC_SiloBuildTactical')
            self:SetWeaponEnabledByLabel('Missile', true)
        elseif enh == 'MissileRemove' then
            self:RemoveCommandCap('RULEUCC_Tactical')
            self:RemoveCommandCap('RULEUCC_SiloBuildTactical')
            self:SetWeaponEnabledByLabel('Missile', false)
        --T2 Engineering
        elseif enh =='AdvancedEngineering' then
            local bp = self:GetBlueprint().Enhancements[enh]
            if not bp then return end
            local cat = ParseEntityCategory(bp.BuildableCategoryAdds)
            self:RemoveBuildRestriction(cat)
            if not Buffs['SeraphimACUT2BuildRate'] then
                BuffBlueprint {
                    Name = 'SeraphimACUT2BuildRate',
                    DisplayName = 'SeraphimACUT2BuildRate',
                    BuffType = 'ACUBUILDRATE',
                    Stacks = 'REPLACE',
                    Duration = -1,
                    Affects = {
                        BuildRate = {
                            Add =  bp.NewBuildRate - self:GetBlueprint().Economy.BuildRate,
                            Mult = 1,
                        },
                        MaxHealth = {
                            Add = bp.NewHealth,
                            Mult = 1.0,
                        },
                        Regen = {
                            Add = bp.NewRegenRate,
                            Mult = 1.0,
                        },
                    },
                }
            end
            Buff.ApplyBuff(self, 'SeraphimACUT2BuildRate')
	    -- Engymod addition: After fiddling with build restrictions, update engymod build restrictions
	    self:updateBuildRestrictions()

        elseif enh =='AdvancedEngineeringRemove' then
            local bp = self:GetBlueprint().Economy.BuildRate
            if not bp then return end
            self:RestoreBuildRestrictions()
            self:AddBuildRestriction( categories.SERAPHIM * (categories.BUILTBYTIER2COMMANDER + categories.BUILTBYTIER3COMMANDER) )
            if Buff.HasBuff( self, 'SeraphimACUT2BuildRate' ) then
                Buff.RemoveBuff( self, 'SeraphimACUT2BuildRate' )
	     end
	    -- Engymod addition: After fiddling with build restrictions, update engymod build restrictions
	    self:updateBuildRestrictions()

        --T3 Engineering
        elseif enh =='T3Engineering' then
            local bp = self:GetBlueprint().Enhancements[enh]
            if not bp then return end
            local cat = ParseEntityCategory(bp.BuildableCategoryAdds)
            self:RemoveBuildRestriction(cat)
            if not Buffs['SeraphimACUT3BuildRate'] then
                BuffBlueprint {
                    Name = 'SeraphimACUT3BuildRate',
                    DisplayName = 'SeraphimCUT3BuildRate',
                    BuffType = 'ACUBUILDRATE',
                    Stacks = 'REPLACE',
                    Duration = -1,
                    Affects = {
                        BuildRate = {
                            Add =  bp.NewBuildRate - self:GetBlueprint().Economy.BuildRate,
                            Mult = 1,
                        },
                        MaxHealth = {
                            Add = bp.NewHealth,
                            Mult = 1.0,
                        },
                        Regen = {
                            Add = bp.NewRegenRate,
                            Mult = 1.0,
                        },
                    },
                }
            end
            Buff.ApplyBuff(self, 'SeraphimACUT3BuildRate')
	    -- Engymod addition: After fiddling with build restrictions, update engymod build restrictions
	    self:updateBuildRestrictions()
        elseif enh =='T3EngineeringRemove' then
            local bp = self:GetBlueprint().Economy.BuildRate
            if not bp then return end
            self:RestoreBuildRestrictions()
            if Buff.HasBuff( self, 'SeraphimACUT3BuildRate' ) then
                Buff.RemoveBuff( self, 'SeraphimACUT3BuildRate' )
            end
            self:AddBuildRestriction( categories.SERAPHIM * ( categories.BUILTBYTIER2COMMANDER + categories.BUILTBYTIER3COMMANDER) )
	    -- Engymod addition: After fiddling with build restrictions, update engymod build restrictions
	    self:updateBuildRestrictions()
        --Blast Attack
        elseif enh == 'BlastAttack' then
            local wep = self:GetWeaponByLabel('ChronotronCannon')
            wep:AddDamageRadiusMod(bp.NewDamageRadius or 5)
            wep:AddDamageMod(bp.AdditionalDamage)
        elseif enh == 'BlastAttackRemove' then
            local wep = self:GetWeaponByLabel('ChronotronCannon')
            wep:AddDamageRadiusMod(-self:GetBlueprint().Enhancements['BlastAttack'].NewDamageRadius) -- unlimited AOE bug fix by brute51 [117]
            wep:AddDamageMod(-self:GetBlueprint().Enhancements['BlastAttack'].AdditionalDamage)
        --Heat Sink Augmentation
        elseif enh == 'RateOfFire' then
            local wep = self:GetWeaponByLabel('ChronotronCannon')
            wep:ChangeRateOfFire(bp.NewRateOfFire or 2)
            wep:ChangeMaxRadius(bp.NewMaxRadius or 44)
            local oc = self:GetWeaponByLabel('OverCharge')
            oc:ChangeMaxRadius(bp.NewMaxRadius or 44)
        elseif enh == 'RateOfFireRemove' then
            local wep = self:GetWeaponByLabel('ChronotronCannon')
            local bpDisrupt = self:GetBlueprint().Weapon[1].RateOfFire
            wep:ChangeRateOfFire(bpDisrupt or 1)
            bpDisrupt = self:GetBlueprint().Weapon[1].MaxRadius
            wep:ChangeMaxRadius(bpDisrupt or 22)
            local oc = self:GetWeaponByLabel('OverCharge')
            oc:ChangeMaxRadius(bpDisrupt or 22)
        end
    end,
}

TypeClass = XSL0001
