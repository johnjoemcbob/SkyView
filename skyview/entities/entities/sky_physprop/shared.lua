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
		self:PhysWake()

		self.RemoveTime = CurTime() + SkyView.Config.RemovePropTime

		local phys = self:GetPhysicsObject()
		if ( phys and IsValid( phys ) ) then
			phys:EnableDrag( false )
		end
	end

	self:SetCustomCollisionCheck( true )
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
					phys:SetVelocity(bounceVel)
				end
			elseif(hitEnt:IsWorld() or string.find(hitEnt:GetClass(), "func")) then
				phys:SetVelocity(bounceVel)
			end
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

function ENT:Throw( from, velocity, owner )
	self:SetPos( from )
	self:GetPhysicsObject():SetVelocity( velocity )
	if( owner != nil and IsValid(owner)) then
		self:SetThrownBy(owner)
	end
	self:SetJustThrown(1)
end