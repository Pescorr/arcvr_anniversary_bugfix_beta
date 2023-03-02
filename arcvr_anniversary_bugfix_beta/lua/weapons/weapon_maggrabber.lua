-- ------------------------------------------------------------------------
-- originally a portal gun mod but stripped and turned into a mag grabber because why not --
-- WRITTEN BY WHEATLEY - http://steamcommunity.com/id/wheatley_wl/
-- ------------------------------------------------------------------------

AddCSLuaFile()

SWEP.Author			= "ArcVR"
SWEP.Purpose		= "Grab magazines"
SWEP.Category		= "Arctic VR"

SWEP.Spawnable			= true

SWEP.ViewModel			= "models/weapons/v_maggrabber.mdl"
SWEP.WorldModel			= "models/weapons/w_physics.mdl"

SWEP.ViewModelFOV		= 90

SWEP.RefireInterval		= 0.45

SWEP.Primary.ClipSize		= -1
SWEP.Primary.DefaultClip	= -1
SWEP.Primary.Automatic		= true
SWEP.Primary.Ammo			= "none"

SWEP.Secondary.ClipSize		= -1
SWEP.Secondary.DefaultClip	= -1
SWEP.Secondary.Automatic	= true
SWEP.Secondary.Ammo			= "none"

SWEP.Weight				= 2
SWEP.AutoSwitchTo		= false
SWEP.AutoSwitchFrom		= false

SWEP.PrintName			= "Maggrabber"
SWEP.Slot				= 0
SWEP.SlotPos			= 4
SWEP.DrawAmmo			= false
SWEP.DrawCrosshair		= false

SWEP.CanFirePortal1		= false
SWEP.CanFirePortal2		= false
SWEP.HoldenProp			= NULL
SWEP.NextAllowedPickup	= 0
SWEP.PickupSound		= nil
SWEP.LastPortal			= false

SWEP.TPEnts = {
	"player",
	"prop_physics",
	"prop_combine_ball",
	"npc_grenade_frag",
	"crossbow_bolt",
	"npc_rollermine",
	"npc_cscanner",
	"npc_clawscanner",
	"npc_manhack",
	"portal_energy_pelet",
	"npc_turret_floor",
	"prop_vehicle_prisoner_pod",
}

local pickable = {
	"models/props/metal_box.mdl",
	"models/props/futbol.mdl",
	"models/props/sphere.mdl",
	"models/props/metal_box_fx_fizzler.mdl",
	"models/props/turret_01.mdl",
	"models/props/reflection_cube.mdl",
	"npc_turret_floor",
	"npc_manhack",
	"models/props/radio_reference.mdl",
	"models/props/security_camera.mdl",
	"models/props/security_camera_prop_reference.mdl",
	"models/props_bts/bts_chair.mdl",
	"models/props_bts/bts_clipboard.mdl",
	"models/props_underground/underground_weighted_cube.mdl",
	"models/XQM/panel360.mdl"
}

SWEP.BadSurfaces = {
	"prop_dynamic",
	"prop_static",
	"func_door",
	"func_button",
	"func_door_rotating",
	"portal2_emancipationgrid"
}

if SERVER then
	util.AddNetworkString( "PORTALGUN_PICKUP_PROP" )
	util.AddNetworkString( "PORTALGUN_SHOOT_PORTAL" )
end

net.Receive( "PORTALGUN_SHOOT_PORTAL", function()
	local pl = net.ReadEntity()
	local port = net.ReadEntity()
	local type = ( ( net.ReadFloat() == 1 ) and true or false )

	if type then
		pl:SetNWEntity( "PORTALGUN_PORTALS_RED", port )
	else
		pl:SetNWEntity( "PORTALGUN_PORTALS_BLUE", port )
	end
end )

if SERVER then
	concommand.Add( "portalmod_clearportals", function( ply )
		for _, v in ipairs( ents.GetAll() ) do
			if IsValid( v ) and ply:GetNWEntity( "PORTALGUN_PORTALS_RED" ) == v then
				SafeRemoveEntity( v )
			elseif IsValid( v ) and ply:GetNWEntity( "PORTALGUN_PORTALS_BLUE" ) == v then
				SafeRemoveEntity( v )
			end
		end
	end )
end

function SWEP:Initialize()
	self:SetWeaponHoldType( "shotgun" )
	if CLIENT then
		self:EmitSound( "" )
	end
end

local function PortalTrace( ent )
	if IsValid( ent ) then
		if ent:IsPlayer() then return false end -- players
		if ent:IsWeapon() then return false end
		if table.HasValue( pickable, ent:GetModel() ) or table.HasValue( pickable, ent:GetClass() ) then return false end -- some props
	end
	return true
end

function SWEP:PrimaryAttack()
	if not self.CanFirePortal1 or IsValid( self.HoldenProp ) then return end
	self:SetNextPrimaryFire( CurTime() + self.RefireInterval )
	self:SetNextSecondaryFire( CurTime() + self.RefireInterval )
	local owner = self:GetOwner()
	if IsValid( owner ) and owner:WaterLevel() >= 3 then self:PlayFizzleAnimation() return end

	if not self:CanPlacePortal( false ) then return end

	self.LastPortal = false
	self:FirePortal( false )
end

function SWEP:SecondaryAttack()
	if not self.CanFirePortal2 or IsValid( self.HoldenProp ) then return end
	self:SetNextPrimaryFire( CurTime() + self.RefireInterval )
	self:SetNextSecondaryFire( CurTime() + self.RefireInterval )
	local owner = self:GetOwner()
	if IsValid( owner ) and owner:WaterLevel() >= 3 then self:PlayFizzleAnimation() return end

	if not self:CanPlacePortal( true ) then return end

	self.LastPortal = true
	self:FirePortal( true )
end

function SWEP:CanPlacePortal( type )
	local pass = true
	local tr
	local owner = self:GetOwner()
	if owner ~= NULL and owner:IsPlayer() then
		tr = util.TraceLine( {
			start = owner:EyePos(),
			endpos = owner:EyePos() + ( owner:EyeAngles():Forward() ) * 30000,
			filter = PortalTrace,
			mask = MASK_SHOT_PORTAL
		} )
	else
		tr = util.TraceLine( {
			start = self:GetPos(),
			endpos = self:GetPos() + ( -self:GetAngles():Forward() ) * 30000,
			filter = PortalTrace
		} )
	end

	local size = tr.Entity ~= NULL and ( tr.Entity:OBBMaxs() - tr.Entity:OBBMins() ):Length() or 0
	local portalsize = 134
	if size < portalsize and not tr.Entity:IsWorld() then pass = false end

	if IsValid( tr.Entity ) and string.sub( tr.Entity:GetClass(), 1, 4 ) == "sent" then pass = false end
	if IsValid( tr.Entity ) and tr.Entity:IsNPC() then pass = false end
	if IsValid( tr.Entity ) and table.HasValue( self.BadSurfaces, tr.Entity:GetClass() ) then pass = false end
	if IsValid( tr.Entity ) and tr.Entity:GetNWBool( "INVALID_SURFACE" ) then pass = false end
	if tr.MatType == MAT_GLASS then pass = false end
	if tr.HitSky then pass = false end

	return pass
end

function SWEP:PickupProp( ent )
	if /*table.HasValue( pickable, ent:GetModel() ) or table.HasValue( pickable, ent:GetClass() )*/ true then
		self.HoldenProp = ent
		self.HoldenProp.HoldingByPlayer = true
		ent:SetSolid( SOLID_NONE )
		ent.CanBePickedUp = ent:GetNWBool( "DISABLE_PORTABLE" )
		ent:SetNWBool( "DISABLE_PORTABLE", true )

		if SERVER then
			net.Start( "PORTALGUN_PICKUP_PROP" )
				net.WriteEntity( self )
				net.WriteEntity( ent )
			net.Send( self:GetOwner() )
		end
		return true
	end
	return false
end

function SWEP:DropProp()
	if self.HoldenProp == NULL then return false end
	if IsValid( self.HoldenProp ) then
		self.HoldenProp:SetSolid( SOLID_VPHYSICS )
		local po = self.HoldenProp:GetPhysicsObject()
		if IsValid( po ) then
			po:Wake()
		end
		self.HoldenProp.HoldingByPlayer = false
	end

	-- for mark unportable tool
	if self.HoldenProp.CanBePickedUp ~= nil then
		self.HoldenProp:SetNWBool( "DISABLE_PORTABLE", self.HoldenProp.CanBePickedUp )
	else
		self.HoldenProp:SetNWBool( "DISABLE_PORTABLE", false )
	end

	self:SendWeaponAnim( ACT_VM_IDLE )
	self.HoldenProp = NULL

	if SERVER then
		net.Start( "PORTALGUN_PICKUP_PROP" )
			net.WriteEntity( self )
			net.WriteEntity( NULL )
		net.Send( self:GetOwner() )
	end
	return true
end

function SWEP:Think()
	local owner = self:GetOwner()
	if not owner then return end
	-- HOLDING FUNC
	if IsValid( self.HoldenProp ) then
		local tr = util.TraceLine( {
			start = owner:EyePos(),
			endpos = owner:EyePos() + owner:EyeAngles():Forward() * -30,
			filter = { owner, self.HoldenProp }
		} )
		self.HoldenProp:SetPos( tr.HitPos - self.HoldenProp:OBBCenter() )
		self.HoldenProp:SetAngles( owner:EyeAngles() )
	elseif not IsValid( self.HoldenProp ) and self.HoldenProp ~= NULL then
		self:DropProp()
	end

	if owner:KeyDown( IN_USE ) and self.NextAllowedPickup < CurTime() and SERVER then
		local ply = owner
		self.NextAllowedPickup = CurTime() + 0.4
		local tr = util.TraceLine( {
			start = ply:EyePos(),
			endpos = ply:EyePos() + ply:EyeAngles():Forward() * 150,
			filter = ply
		} )

		-- DROP FUNC
		if IsValid( self.HoldenProp ) and self.HoldenProp ~= NULL and self:DropProp() then return end

		-- PICKUP FUNC
		if IsValid( tr.Entity ) then
			local entsize = ( tr.Entity:OBBMaxs() - tr.Entity:OBBMins() ):Length() / 2
			if entsize > 45 then return end
			if not IsValid( self.HoldenProp ) and tr.Entity:GetMoveType() ~= 2 and self:PickupProp( tr.Entity ) then return end
		end

		self:EmitSound( "weapons/physcannon/physcannon_dryfire.wav" )
	end
end

function SWEP:FirePortal( type )
	local ent
	local owner = self:GetOwner()
	if SERVER then
		local tr
		if owner ~= NULL and owner:IsPlayer() then
			tr = util.TraceLine( {
				start = owner:EyePos(),
				endpos = owner:EyePos() + ( owner:EyeAngles():Forward() ) * 30000,
				filter = PortalTrace,
				mask = MASK_SHOT_PORTAL
			} )
		else
			tr = util.TraceLine( {
				start = self:GetPos(),
				endpos = self:GetPos() + ( -self:GetAngles():Forward() ) * 30000,
				filter = PortalTrace
			} )
		end

		-- mask

		local portalpos = tr.HitPos
		local portalang
		local ownerent = tr.Entity

		if tr.HitNormal == Vector( 0, 0, 1 ) then
			portalang = tr.HitNormal:Angle() + Angle( 180, owner:GetAngles().y, 180 )
		elseif tr.HitNormal == Vector( 0, 0, -1 ) then
			portalang = tr.HitNormal:Angle() + Angle( 180, owner:GetAngles().y, 180 )
		else
			portalang = tr.HitNormal:Angle() - Angle( 180, 0, 0 )
		end

		local tr_up = util.TraceLine( {
			start = tr.HitPos,
			endpos = tr.HitPos + tr.HitNormal:Angle():Up() * 50,
			filter = ent
		} )

		local tr_down = util.TraceLine( {
			start = tr.HitPos,
			endpos = tr.HitPos - tr.HitNormal:Angle():Up() * 50,
			filter = ent
		} )

		local tr_left = util.TraceLine( {
			start = tr.HitPos,
			endpos = tr.HitPos + tr.HitNormal:Angle():Right() * 30,
			filter = ent
		} )

		local tr_right = util.TraceLine( {
			start = tr.HitPos,
			endpos = tr.HitPos - tr.HitNormal:Angle():Right() * 30,
			filter = ent
		} )

		local r = tr.HitNormal:Angle():Right()
		local u = tr.HitNormal:Angle():Up()

		local tr_right_pl = util.TraceLine( {
			start = tr.HitPos - r * 30,
			endpos = ( tr.HitPos - r * 30 ) - ( tr.HitNormal:Angle():Forward() * 1 ),
			filter = ent
		} )

		local tr_left_pl = util.TraceLine( {
			start = tr.HitPos + r * 30,
			endpos = ( tr.HitPos + r * 30 ) - ( tr.HitNormal:Angle():Forward() * 1 ),
			filter = ent
		} )

		local tr_top_pl = util.TraceLine( {
			start = tr.HitPos + u * 48,
			endpos = ( tr.HitPos + u * 48 ) - ( tr.HitNormal:Angle():Forward() * 1 ),
			filter = ent
		} )

		local tr_bot_pl = util.TraceLine( {
			start = tr.HitPos - u * 48,
			endpos = ( tr.HitPos - u * 48 ) - ( tr.HitNormal:Angle():Forward() * 1 ),
			filter = ent
		} )

		if tr_up.Hit and tr_down.Hit or tr_left.Hit and tr_right.Hit or not tr_right_pl.Hit or not tr_left_pl.Hit or not tr_bot_pl.Hit or not tr_top_pl.Hit then return end

		ent:SetNWBool( "PORTALTYPE", type )

		local ang = tr.HitNormal:Angle() - Angle( 90, 0, 0 )

		local coords = Vector( 35, 35, 25 )

		coords:Rotate( ang )

		u = tr.HitNormal:Angle():Up()
		local lr_fract = Vector( 0, 0, 0 )
		local ud_fract = Vector( 0, 0, 0 )

		if tr_left.Hit then
			lr_fract = ( ( r * 30 ) * ( 1 - tr_left.Fraction ) )
		elseif tr_right.Hit then
			lr_fract = ( -( r * 30 ) * ( 1 - tr_right.Fraction ) )
		end

		if tr_up.Hit then
			ud_fract = ( u * 50 ) * ( 1 - tr_up.Fraction )
		elseif tr_down.Hit then
			ud_fract = -( u * 50 ) * ( 1 - tr_down.Fraction )
		end

		ent:SetPos( portalpos - lr_fract - ud_fract )

		ent:SetAngles( portalang )
		ent.RealOwner = owner
		ent.ParentEntity = ownerent
		ent.AllowedEntities = self.TPEnts
		ent:Spawn()
		if tr.HitNormal == Vector( 0, 0, 1 ) then
			ent.PlacedOnGroud = true
		elseif tr.HitNormal == Vector( 0, 0, -1 ) then
			ent.PlacedOnCeiling = true
		end
		if not ownerent:IsWorld() then
			ent:SetParent( ownerent )
		end
		ent:SetNWEntity( "portalowner", owner )

		self:RemoveSelectedPortal( type ) -- remove old portal

		if type then
			owner:SetNWEntity( "PORTALGUN_PORTALS_RED", ent )
		else
			owner:SetNWEntity( "PORTALGUN_PORTALS_BLUE", ent )
		end

		if SERVER then
			net.Start( "PORTALGUN_SHOOT_PORTAL" )
				net.WriteEntity( owner )
				net.WriteEntity( ent )
				net.WriteFloat( ( type == true ) and 1 or 0 )
			net.Broadcast()
		end
	end

	if CLIENT then
		if type then
			local p1 = owner:GetNWEntity( "PORTALGUN_PORTALS_RED", ent )
			if IsValid( p1 ) then p1.RealOwner = owner end
		else
			local p1 = owner:GetNWEntity( "PORTALGUN_PORTALS_BLUE", ent )
			if IsValid( p1 ) then p1.RealOwner = owner end
		end
	end
end

function SWEP:RemoveSelectedPortal( type )
	local owner = self:GetOwner()
	for i, v in ipairs( ents.GetAll() ) do
		if IsValid( v ) and type == true and owner:GetNWEntity( "PORTALGUN_PORTALS_RED" ) == v then
			SafeRemoveEntity( v )
		elseif IsValid( v ) and type == false and owner:GetNWEntity( "PORTALGUN_PORTALS_BLUE" ) == v then
			SafeRemoveEntity( v )
		end
	end
end

function SWEP:Reload()
	local owner = self:GetOwner()
	if SERVER then
		self:RemoveSelectedPortal( true )
		self:RemoveSelectedPortal( false )
	end
	if IsValid( owner ) then
		owner:SetNWEntity( "PORTALGUN_PORTALS_RED", NULL )

		owner:SetNWEntity( "PORTALGUN_PORTALS_BLUE", NULL )
	end
end

function SWEP:OnRemove()
	local owner = self:GetOwner()
	if SERVER and owner and not owner:Alive() then
		self:RemoveSelectedPortal( true )
		self:RemoveSelectedPortal( false )
	end
	if IsValid( owner ) then
		owner:SetNWEntity( "PORTALGUN_PORTALS_RED", NULL )

		owner:SetNWEntity( "PORTALGUN_PORTALS_BLUE", NULL )
	end
end

function SWEP:AcceptInput( input )
	if input == "FirePortal1" then self:PrimaryAttack() end
	if input == "FirePortal2" then self:SecondaryAttack() end
end

function SWEP:KeyValue( k, v )
	if k == "CanFirePortal1" then if v == "1" then self.CanFirePortal1 = true return end self.CanFirePortal1 = false end
	if k == "CanFirePortal2" then if v == "1" then self.CanFirePortal2 = true return end self.CanFirePortal2 = false end
end

net.Receive( "PORTALGUN_PICKUP_PROP", function()
	local selfEnt = net.ReadEntity()
	local ent = net.ReadEntity()

	if not IsValid( ent ) then
		if selfEnt.PickupSound then
			selfEnt.PickupSound:Stop()
			selfEnt.PickupSound = nil
			EmitSound( Sound( "" ), selfEnt:GetPos(), 1, CHAN_AUTO, 0.4, 100, 0, 100 )
		end
	else
		if not selfEnt.PickupSound and CLIENT then
			selfEnt.PickupSound = CreateSound( selfEnt, "weapons/russels_pull.wav" )
			selfEnt.PickupSound:Play()
			selfEnt.PickupSound:ChangeVolume( 0.5, 0 )
		end
	end

	selfEnt.HoldenProp = ent
end )