-- Author: Jordan Brown (@DrMelon)
-- 17/08/2015
-- Arcade Mode DLC for SkyView - Stat-Tracking Props
-- This, and the stats within, are for a currently-active prop only and not the global stats
-- for each kind of prop. Those will be handled separately.

if SERVER then
	AddCSLuaFile( "shared.lua" )
end

ENT.Type = "anim"

-- Stats
ENT.TimesBounced = 0
ENT.PlayersKilled = 0
ENT.TimesGrappled = 0
ENT.OtherPropsHit = 0
ENT.SamePropsHit = 0
--ENT.ThrownBy = nil
ENT.LastGrappledBy = nil
ENT.RecentlyBounced = 0
ENT.RemoveTime = 0
ENT.NearMissRadius = 100
ENT.NearMissTime = 0.7
ENT.NearPlayers = nil
ENT.CollidedPlayers = nil
ENT.LastBounce = 0
ENT.BetweenBounceTime = 1
ENT.IsHoming = false
ENT.HomingTarget = nil
--ENT.JustThrown = 0
--ENT.Owner = nil

-- Prop Models Table
local PropModels =
{
	"models/props_c17/FurnitureBathtub001a.mdl",
	"models/props_borealis/bluebarrel001.mdl",
	"models/props_c17/furnitureStove001a.mdl",
	"models/props_c17/FurnitureFridge001a.mdl",
	"models/props_c17/oildrum001.mdl",
	"models/props_c17/oildrum001_explosive.mdl",
	"models/props_junk/PlasticCrate01a.mdl",
	"models/props_c17/FurnitureSink001a.mdl",
	"models/props_c17/FurnitureCouch001a.mdl",
	"models/Combine_Helicopter/helicopter_bomb01.mdl",
	"models/props_combine/breenglobe.mdl",
	"models/props_combine/breenchair.mdl",
	"models/props_docks/dock01_cleat01a.mdl",
	"models/props_interiors/VendingMachineSoda01a.mdl",
	"models/props_interiors/Furniture_Couch01a.mdl",
	"models/props_junk/plasticbucket001a.mdl",
	"models/props_lab/filecabinet02.mdl",
	"models/props_trainstation/trashcan_indoor001a.mdl",
	"models/props_vehicles/apc_tire001.mdl",
	"models/props_wasteland/light_spotlight01_lamp.mdl",
	"models/props_junk/TrafficCone001a.mdl"
}

function ENT:Initialize()
	-- Set up physics
	if ( SERVER ) then
		if ( self:GetModel() == "models/error.mdl" ) then
			self:SetModel(table.Random(PropModels))
		end
		self:PhysicsInit( SOLID_VPHYSICS )
		--self:PhysWake()

		self.RemoveTime = CurTime() + SkyView.Config.RemovePropTime

		local phys = self:GetPhysicsObject()
		if ( phys and IsValid( phys ) ) then
			phys:EnableDrag( false )
			--phys:Wake()
		end
	end

	self:SetCustomCollisionCheck( true )

	self.NearPlayers = {}
	self.CollidedPlayers = {}
	self.IsHoming = false
	self.HomingTarget = false
end

function ENT:SetupDataTables()
	-- Thrown-By and Owner Vals
	self:NetworkVar("Entity", 0, "ThrownBy")
	self:NetworkVar("Entity", 1, "PropOwner")
	-- JustThrown Value
	self:NetworkVar("Float", 0, "JustThrown")
end

function ENT:Think()
	if( SERVER ) then
		-- Apply homing logic
		self:HomeIn()

		-- Tick down recently bounced timer.
		self.RecentlyBounced = self.RecentlyBounced - 1
		if(self.RecentlyBounced < 0) then
			self.RecentlyBounced = 0
		end

		-- Tick down just-thrown timer
		self:SetJustThrown(math.max(self:GetJustThrown() - 100 * FrameTime(),0))

		-- Tick down until removal of the prop
		if ( CurTime() > self.RemoveTime ) then
			self:Remove()
		end

		-- Near miss logic;
		-- Find near by players and flag them for collision checking, if they collide within a certain time (either before or after)
		-- then they are removed from the near miss tracking; otherwise the stat is incremented and a message displayed
		if ( not self.IsActiveShield ) then
			local nearents = ents.FindInSphere( self:GetPos(), self.NearMissRadius )
			for k, ent in pairs( nearents ) do
				if ( ent:IsPlayer() ) then
					-- Only count a near miss with the throwing player if the entity has existed for a while, and bounced back
					if ( ( self:GetJustThrown() == 0 ) or ( ent ~= self.Owner ) ) then
						if ( not self.NearPlayers[ent:EntIndex()] ) then
							self.NearPlayers[ent:EntIndex()] = CurTime()
						end
					end
				end
			end
		end

		-- Check players that have been near against players which have collided to find those who narrowly missed the object
		for plyindex, neartime in pairs( self.NearPlayers ) do
			if ( ( CurTime() - self.NearMissTime ) > neartime ) then
				local ply = ents.GetByIndex( plyindex )

				-- The time since the player was logged as near
				local nearstarttime = CurTime() - neartime

				-- The time since the player last collided with this prop
				local timedif = math.abs( CurTime() - ( self.CollidedPlayers[plyindex] or CurTime() ) )

				-- Player has died recently, ignore near miss
				if ( ( ply.Stats["death"] and ( ( CurTime() - ply.Stats["death"].LastIncrement ) <= math.max( nearstarttime, timedif ) ) ) or ( not ply:Alive() ) ) then
					self.NearPlayers[plyindex] = nil
					continue
				end

				-- Has never collided with the player, or did so some time ago
				if ( ( not self.CollidedPlayers[plyindex] ) or ( timedif > self.NearMissTime ) ) then
					GAMEMODE:EventFired( ply, "NearMiss", { self } )

					-- Flag this as a collision to delay near miss messages for this player and this prop
					self.NearPlayers[plyindex] = nil
					self.CollidedPlayers[plyindex] = CurTime() + 10
				end
			end
		end
	end
end

function ENT:ReflectVector( vec, normal, bounce )
	return bounce * ( -2 * ( vec:Dot( normal ) ) * normal + vec )
end

function ENT:PhysicsCollide( colData, collider )
	if( SERVER ) then
		-- Make em bouncy
		local hitEnt = colData.HitEntity

		local bounceVel = self:ReflectVector( colData.OurOldVelocity, colData.HitNormal, SkyView.Config.ReflectNum )

		local phys = self:GetPhysicsObject()
		if ( phys and IsValid( phys ) ) then
			if(!hitEnt:IsWorld() and !string.find(hitEnt:GetClass(), "func")) then
				if (hitEnt.MeShield) then
					hitEnt:EmitSound(SkyView:RandomShieldSound())
					-- Get velocity based on the shield angles
					local bounceVel = self:GetAngles():Forward() * -10000
					phys:SetVelocity(bounceVel)
				end
			elseif(hitEnt:IsWorld() or string.find(hitEnt:GetClass(), "func")) then
				-- In an attempt to stop physics crashes, props can only bounce every so often
				if ( CurTime() >= self.LastBounce ) then
					phys:SetVelocity(bounceVel)
					self.LastBounce = CurTime() + self.BetweenBounceTime
				end
			end
		end

		-- Near miss logic
		if ( hitEnt:IsPlayer() ) then
			self.CollidedPlayers[hitEnt:EntIndex()] = CurTime()
		end

		-- Stats
		if(colData.Speed > 50) then
			self.TimesBounced = self.TimesBounced + 1
			self.RecentlyBounced = 60 -- engage bounce timer.
		end

		if(hitEnt:GetClass() == "sky_physprop" or hitEnt:GetClass() == "prop_physics") then
			if(hitEnt:GetModel() == self:GetModel()) then
				self.SamePropsHit = self.SamePropsHit + 1
			end
			self.OtherPropsHit = self.OtherPropsHit + 1
		end
	end
end

function ENT:OnRemove()

end

function ENT:HomeIn()
	if(self.IsHoming == false) then
		return
	end
	-- Apply force towards stored target
	if(self.HomingTarget and IsValid(self.HomingTarget) and self.HomingTarget:Alive()) then
		local flightVector = self.HomingTarget:GetPos() - self:GetPos()
		flightVector:Normalize()
		flightVector = flightVector * 2000
		local phys = self:GetPhysicsObject()
		if ( phys and IsValid( phys ) ) then
			phys:SetVelocity(phys:GetVelocity() + flightVector)
		end
	else -- Try to find a target
		local nearbyEnts = ents.FindInSphere(self:GetPos(), 350)
		for k, v in pairs(nearbyEnts) do
			if(v != nil and IsValid(v) and v:IsPlayer() and v != self:GetThrownBy() and v:Alive()) then
				self.HomingTarget = v
				-- Beep
				self:EmitSound("npc/roller/mine/rmine_tossed1.wav")
			end
		end
	end
end

function ENT:Throw( from, velocity, owner )
	self:SetPos( from )
	self:GetPhysicsObject():SetVelocity( velocity )
	if( owner != nil and IsValid(owner)) then
		self:SetThrownBy(owner)

		if(owner.HasPowerup and owner:GetBuff(2) != nil) then
			-- Check to see if they have homing prop buff
			self.IsHoming = true
			self.HomingTarget = nil
			-- Add trail, same colour as the player
			local playercol = owner:GetPlayerColor()
			util.SpriteTrail( self, 0, Color( playercol.x * 255, playercol.y * 255, playercol.z * 255 ), true, 15, 5, 3.5, 1 / 20 * 0.5, "trails/smoke.vmt" )

		end
	end
	self:SetJustThrown(1)
end
