function SWEP:DetectMeleeStrike(ply)
	local vm = g_VR.viewModel
	if not vm then return end
	if not IsValid(vm) then return end
	if not self.BoneIndices.bladestart then return end
	if not self.BoneIndices.bladeend then return end
	if self.NextMeleeAttack > CurTime() then return end
	-- if we are swinging fast enough
	local vel = g_VR.tracking.pose_righthand.vel:Length() / 40
	if vel < self.MeleeVelThreshold then return end
	-- detect hit targets
	local startatt = vm:LookupAttachment("bladestart")
	local endatt = vm:LookupAttachment("bladeend")
	local startbone = vm:GetAttachment(startatt).Pos
	local endbone = vm:GetAttachment(endatt).Pos
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
		local hs = "MeleeHitSound"
		if tr2.MatType == MAT_FLESH or tr2.MatType == MAT_ALIENFLESH or tr2.MatType == MAT_ANTLION then
			hs = "MeleeStrikeSound"
		end

		self:PlayNetworkedSound(nil, hs)
		net.Start("avr_meleeattack")
		net.WriteFloat(src[1])
		net.WriteFloat(src[2])
		net.WriteFloat(src[3])
		net.WriteVector(g_VR.tracking.pose_righthand.vel)
		net.SendToServer()
	end
end