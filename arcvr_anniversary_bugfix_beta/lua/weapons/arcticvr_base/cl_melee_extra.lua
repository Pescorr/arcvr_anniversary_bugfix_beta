local cv_allowgunmelee = false or CreateConVar("arcticvr_gunmelee", "1", FCVAR_REPLICATED + FCVAR_NOTIFY + FCVAR_ARCHIVE)
local cv_usegunmelee = CreateClientConVar("arcticvr_gunmelee_client", "1", FCVAR_ARCHIVE)
local cv_allowfist = false or CreateConVar("arcticvr_fist", "1", FCVAR_REPLICATED + FCVAR_NOTIFY + FCVAR_ARCHIVE)
local cv_usefist = CreateClientConVar("arcticvr_fist_client", "1", FCVAR_ARCHIVE)
local cv_allowkick = false or CreateConVar("arcticvr_kick", "0", FCVAR_REPLICATED + FCVAR_NOTIFY + FCVAR_ARCHIVE)
local cv_usekick = CreateClientConVar("arcticvr_kick_client", "0", FCVAR_ARCHIVE)
function SWEP:DetectMeleeweapon(ply)
    if cv_usegunmelee:GetBool() and cv_allowgunmelee:GetBool() then
        local vm = g_VR.viewModel
        if not vm then return end
        if not IsValid(vm) then return end
        if not vm:GetAttachment(1) then return end
        if self.NextMeleeAttack > CurTime() then return end
        -- if we are swinging fast enough
        local vel = g_VR.tracking.pose_righthand.vel:Length() / 40
        if vel < self.MeleeVelThreshold then return end
        -- detect hit targets
        local startbone = vm:GetAttachment(1).Pos
        local endbone = vm:GetAttachment(2).Pos
        local tr = util.TraceLine(
            {
                start = startbone,
                endpos = endbone,
                mask = MASK_ALL,
                filter = LocalPlayer()
            }
        )

        -- submit attack
        if tr.Hit then
            self.NextMeleeAttack = CurTime() + self.MeleeDelay
            local src = tr.HitPos + (tr.HitNormal * -2)
            local tr2 = util.TraceLine(
                {
                    start = src,
                    endpos = src + (g_VR.tracking.pose_righthand.vel:GetNormalized() * 8),
                    mask = MASK_ALL
                }
            )

            if not tr2.Hit then return end
            -- local hs = "MeleeHitSound"
            -- if tr2.MatType == MAT_FLESH or tr2.MatType == MAT_ALIENFLESH or tr2.MatType == MAT_ANTLION then
            --     hs = "MeleeStrikeSound"
            -- end
            -- self:PlayNetworkedSound(nil, hs)
            net.Start("avr_meleeattack_weapon")
            net.WriteFloat(src[1])
            net.WriteFloat(src[2])
            net.WriteFloat(src[3])
            net.WriteVector(g_VR.tracking.pose_righthand.vel)
            net.SendToServer()
        end
    end
end

function SWEP:DetectMeleelefthand(ply)
    if cv_usefist:GetBool() and cv_allowfist:GetBool() then
        local vm = g_VR.viewModel
        if not vm then return end
        if not IsValid(vm) then return end
        if self.NextMeleeAttack > CurTime() then return end
        -- if we are swinging fast enough
        local vel = g_VR.tracking.pose_lefthand.vel:Length() / 40
        local vel2 = g_VR.tracking.pose_lefthand.vel:Length() / 40
        if vel < self.MeleeVelThreshold and vel2 < self.MeleeVelThreshold then return end
        -- detect hit targets
        local startbone = g_VR.tracking.pose_lefthand.pos
        local endbone = g_VR.tracking.pose_lefthand.pos
        local tr = util.TraceLine(
            {
                start = startbone,
                endpos = endbone,
                mask = MASK_ALL,
                filter = LocalPlayer()
            }
        )

        -- submit attack
        if tr.Hit then
            self.NextMeleeAttack = CurTime() + self.MeleeDelay
            local src = tr.HitPos + (tr.HitNormal * -2)
            local tr2 = util.TraceLine(
                {
                    start = src,
                    endpos = src + (g_VR.tracking.pose_lefthand.vel:GetNormalized() * 8),
                    mask = MASK_ALL
                }
            )

            if not tr2.Hit then return end
            -- local hs = "MeleeHitSound"
            -- if tr2.MatType == MAT_FLESH or tr2.MatType == MAT_ALIENFLESH or tr2.MatType == MAT_ANTLION then
            --     hs = "MeleeStrikeSound"
            -- end
            -- self:PlayNetworkedSound(nil, hs)
            net.Start("avr_meleeattack_lefthand")
            net.WriteFloat(src[1])
            net.WriteFloat(src[2])
            net.WriteFloat(src[3])
            net.WriteVector(g_VR.tracking.pose_lefthand.vel:GetNormalized())
            net.SendToServer()
        end
    end
end

-- local cv_dmggunmelee = CreateConvar("arcticvr_gunmelee_damage","10",FCVAR_REPLICATED) or 0
function SWEP:DetectMeleerighthand(ply)
    if cv_usefist:GetBool() and cv_allowfist:GetBool() then
        local vm = g_VR.viewModel
        if not vm then return end
        if not IsValid(vm) then return end
        if self.NextMeleeAttack > CurTime() then return end
        -- if we are swinging fast enough
        local vel = g_VR.tracking.pose_righthand.vel:Length() / 40
        local vel2 = g_VR.tracking.pose_righthand.vel:Length() / 40
        if vel < self.MeleeVelThreshold and vel2 < self.MeleeVelThreshold then return end
        -- detect hit targets
        local startbone = g_VR.tracking.pose_righthand.pos
        local endbone = g_VR.tracking.pose_righthand.pos
        local tr = util.TraceLine(
            {
                start = startbone,
                endpos = endbone,
                mask = MASK_ALL,
                filter = LocalPlayer()
            }
        )

        -- submit attack
        if tr.Hit then
            self.NextMeleeAttack = CurTime() + self.MeleeDelay
            local src = tr.HitPos + (tr.HitNormal * -2)
            local tr2 = util.TraceLine(
                {
                    start = src,
                    endpos = src + (g_VR.tracking.pose_righthand.vel:GetNormalized() * 8),
                    mask = MASK_ALL
                }
            )

            if not tr2.Hit then return end
            -- local hs = "MeleeHitSound"
            -- if tr2.MatType == MAT_FLESH or tr2.MatType == MAT_ALIENFLESH or tr2.MatType == MAT_ANTLION then
            --     hs = "MeleeStrikeSound"
            -- end
            -- self:PlayNetworkedSound(nil, hs)
            net.Start("avr_meleeattack_righthand")
            net.WriteFloat(src[1])
            net.WriteFloat(src[2])
            net.WriteFloat(src[3])
            net.WriteVector(g_VR.tracking.pose_righthand.vel:GetNormalized())
            net.SendToServer()
        end
    end
end

function SWEP:DetectMeleeleftfoot(ply)
    if cv_usekick:GetBool() and cv_allowkick:GetBool() then
        local vm = g_VR.viewModel
        if not vm then return end
        if not IsValid(vm) then return end
        if self.NextMeleeAttack > CurTime() then return end
        -- if we are swinging fast enough
        local vel = g_VR.tracking.pose_lefthand.vel:Length() / 40
        local vel2 = g_VR.tracking.pose_lefthand.vel:Length() / 40
        if vel < self.MeleeVelThreshold and vel2 < self.MeleeVelThreshold then return end
        -- detect hit targets
        local startbone = g_VR.tracking.pose_leftfoot.pos
        local endbone = g_VR.tracking.pose_leftfoot.pos
        local tr = util.TraceLine(
            {
                start = startbone,
                endpos = endbone,
                mask = MASK_ALL,
                filter = LocalPlayer()
            }
        )

        -- submit attack
        if tr.Hit then
            self.NextMeleeAttack = CurTime() + self.MeleeDelay
            local src = tr.HitPos + (tr.HitNormal * -2)
            local tr2 = util.TraceLine(
                {
                    start = src,
                    endpos = src + (g_VR.tracking.pose_lefthand.vel:GetNormalized() * 8),
                    mask = MASK_ALL
                }
            )

            if not tr2.Hit then return end
            -- local hs = "MeleeHitSound"
            -- if tr2.MatType == MAT_FLESH or tr2.MatType == MAT_ALIENFLESH or tr2.MatType == MAT_ANTLION then
            --     hs = "MeleeStrikeSound"
            -- end
            -- self:PlayNetworkedSound(nil, hs)
            net.Start("avr_meleeattack_leftfoot")
            net.WriteFloat(src[1])
            net.WriteFloat(src[2])
            net.WriteFloat(src[3])
            net.WriteVector(g_VR.tracking.pose_lefthand.vel:GetNormalized())
            net.SendToServer()
        end
    end
end

function SWEP:DetectMeleerightfoot(ply)
    if cv_usekick:GetBool() and cv_allowkick:GetBool() then
        local vm = g_VR.viewModel
        if not vm then return end
        if not IsValid(vm) then return end
        if self.NextMeleeAttack > CurTime() then return end
        -- if we are swinging fast enough
        local vel = g_VR.tracking.pose_righthand.vel:Length() / 40
        local vel2 = g_VR.tracking.pose_righthand.vel:Length() / 40
        if vel < self.MeleeVelThreshold and vel2 < self.MeleeVelThreshold then return end
        -- detect hit targets
        local startbone = g_VR.tracking.pose_rightfoot.pos
        local endbone = g_VR.tracking.pose_rightfoot.pos
        local tr = util.TraceLine(
            {
                start = startbone,
                endpos = endbone,
                mask = MASK_ALL,
                filter = LocalPlayer()
            }
        )

        -- submit attack
        if tr.Hit then
            self.NextMeleeAttack = CurTime() + self.MeleeDelay
            local src = tr.HitPos + (tr.HitNormal * -2)
            local tr2 = util.TraceLine(
                {
                    start = src,
                    endpos = src + (g_VR.tracking.pose_righthand.vel:GetNormalized() * 8),
                    mask = MASK_ALL
                }
            )

            if not tr2.Hit then return end
            -- local hs = "MeleeHitSound"
            -- if tr2.MatType == MAT_FLESH or tr2.MatType == MAT_ALIENFLESH or tr2.MatType == MAT_ANTLION then
            --     hs = "MeleeStrikeSound"
            -- end
            -- self:PlayNetworkedSound(nil, hs)
            net.Start("avr_meleeattack_rightfoot")
            net.WriteFloat(src[1])
            net.WriteFloat(src[2])
            net.WriteFloat(src[3])
            net.WriteVector(g_VR.tracking.pose_righthand.vel:GetNormalized())
            net.SendToServer()
        end
    end
end