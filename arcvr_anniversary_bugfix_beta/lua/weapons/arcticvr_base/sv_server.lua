local shootsys = CreateConVar("arcticvr_shootsys","1",FCVAR_ARCHIVE)

function SWEP:Deploy()
    self:SendWeapon(true, false)
    return true
end

function SWEP:Holster()
    return true
end

function SWEP:SendWeapon(justowner, full)
    local owner = self:GetOwner()
    if justowner and not IsValid(owner) then return end

    net.Start("avr_sendatts")
    net.WriteEntity(self)

    net.WriteUInt(table.Count(self.Attachments), 10)

    for i, k in pairs(self.Attachments) do
        if not k.Installed then
            net.WriteUInt(0, 24)
            continue
        end

        local atttbl = ArcticVR.AttachmentTable[k.Installed]
        local id = atttbl.ID

        net.WriteUInt(id, 24)
    end

    if full then
        net.WriteBool(true)

        net.WriteString(self.Magazine or "")
        net.WriteUInt(self.LoadedRounds, 16)
        net.WriteUInt(self.Chambered, 8)
    else
        net.WriteBool(false)
    end

    if justowner then
        net.Send(owner)
    else
        net.Broadcast()
    end
end

function SWEP:VR_Melee(src, vel)
    if CLIENT then return end
    if self.NextMeleeAttack > CurTime() then return end

    local owner = self:GetOwner()
    if owner:IsPlayer() then
        owner:LagCompensation( true )
    end

    owner:FireBullets({
        Damage = self.MeleeDamage,
        Src = src,
        Dir = vel:GetNormalized(),
        Tracer = 0,
        Distance = 8,
        Force = self.MeleeDamage / 3,
        Callback = function(att, tr, dmg)
            dmg:SetDamageType(self.MeleeDamageType)
        end
    })

    if owner:IsPlayer() then
        owner:LagCompensation( false )
    end

    self.NextMeleeAttack = CurTime() + self.MeleeDelay
end

function SWEP:VR_Shoot(src, ang, cycle)
    if CLIENT then return end
    cycle = cycle or true

    local num = self:GetAttOverride("Override_Num") or self.Num
    local owner = self:GetOwner()

    for i = 1, num do

        local sang = ang + (AngleRand() * self.Spread * 0.1 * self:GetBuff("Buff_Spread"))

        local se = self.ShootEntity

        se = self:GetAttOverride("Override_ShootEntity") or se

        if se then
            local rocket = ents.Create(se)

            if not rocket:IsValid() then print("INVALID ROUND!!!" .. se) return false end

            local tr = util.TraceLine({
                start = src,
                endpos = src + (sang:Forward() * 50),
                filter = owner
            })

            rocket.ExtraProjectileData = self.ExtraProjectileData or {}
            rocket:SetAngles(sang + (self.ProjectileOffset or Angle(0, 0, 0)))
            rocket:SetPos(tr.HitPos)
            rocket:SetOwner(owner)
            rocket:Spawn()
            rocket:Activate()
            constraint.NoCollide(owner, rocket, 0, 0)
            rocket:GetPhysicsObject():SetVelocity(owner:GetAbsVelocity())
            rocket:GetPhysicsObject():SetVelocityInstantaneous(ang:Forward() * self.MuzzleVelocity * self:GetBuff("Buff_MuzzleVelocity"))
        else
            local tcol = self:GetAttOverride("OverrideTracerCol") or self.TracerCol
            local twidth = self.TracerWidth + self:GetBuffAdditive("Buff_TracerWidth")

            local dmgmin = self.DamageMin * self:GetBuff("Buff_DamageMin")
            local dmgmax = self.DamageMax * self:GetBuff("Buff_DamageMax")

            local sniperized = dmgmin > dmgmax

            if sniperized and self:GetAttOverride("DeSniperize") then
                local a = dmgmin
                dmgmin = dmgmax
                dmgmax = a
            elseif not sniperized and self:GetAttOverride("Sniperize") then
                local a = dmgmin
                dmgmin = dmgmax
                dmgmax = a
            end


            if shootsys:GetBool() then
                if ArcticVR.IsPhysicalBullets() then
                    ArcticVR:ShootPhysicalBullet(src, sang,
                    self.MuzzleVelocity * self:GetBuff("Buff_MuzzleVelocity"),
                    {
                        c = tcol,
                        --l = weapon.TracerLen,
                        w = twidth
                    },
                    dmgmin,
                    dmgmax,
                    self.MaxRange * self:GetBuff("Buff_MaxRange"),
                    self,
                    owner,
                    self.Penetration * self:GetBuff("Buff_Penetration"),
                    self.ShootCallback)
                else
                if owner:IsPlayer() then
                    owner:LagCompensation( true )
                end
                    owner:FireBullets({
                        Attacker = owner,
                        Damage = (dmgmin + dmgmax) / 2,
                        Force = (dmgmin + dmgmax) / 6,
                        Tracer = 1,
                        Spread = 0, -- Vector(1, 1, 0) * self.Spread, -- dafuq
                        Src = src,
                        Dir = sang:Forward(),
                        IgnoreEntity = owner,
                        TracerName = self.TracerOverride
                    })
                if owner:IsPlayer() then
                    owner:LagCompensation( false )
                end

                end
            else
                if owner:IsPlayer() then
                    owner:LagCompensation( true )
                end

                if not ArcticVR.IsPhysicalBullets() then
                        owner:FireBullets({
                        Attacker = owner,
                        Damage = (dmgmin + dmgmax) / 2,
                        Force = (dmgmin + dmgmax) / 6,
                        Tracer = 1,
                        Spread = 0,
                        Src = src,
                        Dir = sang:Forward(),
                        IgnoreEntity = owner,
                        TracerName = self.TracerOverride
                    })
                if owner:IsPlayer() then
                    owner:LagCompensation( false )
                end
                else
                    ArcticVR:ShootPhysicalBullet(src, sang,
                    self.MuzzleVelocity * self:GetBuff("Buff_MuzzleVelocity"),
                    {
                        c = tcol,
                        --l = weapon.TracerLen,
                        w = twidth
                    },
                    dmgmin,
                    dmgmax,
                    self.MaxRange * self:GetBuff("Buff_MaxRange"),
                    self,
                    owner,
                    self.Penetration * self:GetBuff("Buff_Penetration"),
                    self.ShootCallback)
                end
            end

        end

    end

    if not self.NonAutoloading then
        self:Cycle()
    end
end