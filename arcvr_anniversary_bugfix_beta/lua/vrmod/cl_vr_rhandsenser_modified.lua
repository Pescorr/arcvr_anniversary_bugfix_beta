local Rhandenable = CreateClientConVar("VR_RhandSenser_Enable", "1", true, FCVAR_ARCHIVE)
local Rhandrange = CreateClientConVar("VR_RhandSensor_speed", "200", true, FCVAR_ARCHIVE)
local Rhandcommand = CreateClientConVar("VR_RhandSensor_detectcmd", "+feedbacker;-feedbacker", true, FCVAR_ARCHIVE)
-- local Rhandfalse = CreateClientConVar("VR_RhandSensor_undetectcmd","-feedbacker")
local Rhandbutton = CreateClientConVar("VRdevRhandSensor_devtest", 1)
VRRhandsenser = {
	MASK_ATTACK = IN_ATTACK,
	MASK_NATTACK = bit.bnot(IN_ATTACK),
	rhandsenserLastPos = Vector(),
	hold = false,
	lastHold = false,
	nextTick = 0.05,
	hitSpeed = Rhandrange:GetInt() ^ 2,
	rhandsenser = {{}}
}

function VRRhandsenser.CreateMove(cmd)
	local ply = LocalPlayer()
	local wep = ply:GetActiveWeapon()
	if IsValid(wep) then
		local buttons = cmd:GetButtons()
		local attack = bit.band(buttons, VRRhandsenser.MASK_ATTACK) > 0
		VRRhandsenser.hold = attack
		cmd:SetButtons(bit.band(buttons, VRRhandsenser.MASK_NATTACK))
	end
end

function VRRhandsenser.rhandsenserTick(ply)
	local currentTick = engine.TickCount()
	local tickInterval = engine.TickInterval()
	if currentTick > VRRhandsenser.nextTick then
		local rhandsenserOffset = Vector(2, 2, 2)
		local angleZero = Angle()
		local rhandsenserPos = LocalToWorld(rhandsenserOffset, angleZero, vrmod.GetRightHandPose())
		local vel = (rhandsenserPos - VRRhandsenser.rhandsenserLastPos) / tickInterval
		if vel:LengthSqr() > VRRhandsenser.hitSpeed then
			local trace = util.TraceLine(
				{
					start = VRRhandsenser.rhandsenserLastPos,
					endpos = rhandsenserPos,
					filter = ply,
					mask = MASK_ALL
				}
			)

			if Rhandbutton:GetBool() then
				if trace.Hit then
					-- Get the name of the entity that was hit by the trace
					local hitEntity = trace.Entity
					local entityName = IsValid(hitEntity) and hitEntity:GetClass() or "No_Entity"
					-- Get the closest bone information if the entity is of type C_BaseAnimating
					local boneName, boneIndex = "No_BoneData", -1
					if hitEntity:IsValid() then
						local closestDist = math.huge
						for i = 0, hitEntity:GetBoneCount() - 1 do
							local bonePos = hitEntity:GetBonePosition(i)
							local dist = trace.HitPos:Distance(bonePos)
							if dist < closestDist then
								closestDist = dist
								boneName = hitEntity:GetBoneName(i)
								boneIndex = i
							end
						end
					end

					-- Print the information
					print("Entity Name:", entityName, "Closest Bone:", boneName, "Bone Index:", boneIndex, "World Coordinates:", trace.HitPos)
					LocalPlayer():ConCommand(Rhandcommand:GetString())
					VRRhandsenser.nextTick = currentTick + math.floor(1 / tickInterval)
				end
			end
			-- if not trace.Hit or not Rhandbutton:GetBool() or not RHandFalse == "" then
			-- LocalPlayer():ConCommand(Rhandfalse:GetString())
			-- end
		end

		VRRhandsenser.rhandsenserLastPos = rhandsenserPos
		debugoverlay.Sphere(rhandsenserPos, 1, 0.1, Color(255, 0, 0))
	end
end

function VRRhandsenser.Tick()
	local ply = LocalPlayer()
	if not IsValid(ply) then return end
	if not Rhandenable:GetBool() then return end
	VRRhandsenser.rhandsenserTick(ply)
end

function VRRhandsenser.VRModStart(player)
	if player == LocalPlayer() then
		hook.Add("CreateMove", "VRRhandsenser_Creatersenser", VRRhandsenser.Creatersenser)
		hook.Add("Tick", "VRRhandsenser_Tick", VRRhandsenser.Tick)
	end
end

function VRRhandsenser.VRModExit(player)
	if player == LocalPlayer() then
		hook.Remove("CreateMove", "VRRhandsenser_Creatersenser")
		hook.Remove("Tick", "VRRhandsenser_Tick")
		hook.Remove("VRMod_Input", "vrutil_hook_Rhandsenser")
	end
end

hook.Add("VRMod_Start", "VRRhandsenser_VRMod_Start", VRRhandsenser.VRModStart)
hook.Add("VRMod_Exit", "VRRhandsenser_VRMod_Exit", VRRhandsenser.VRModExit)