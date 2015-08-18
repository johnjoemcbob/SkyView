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
ENT.ThrownBy = nil
ENT.LastGrappledBy = nil
ENT.RecentlyBounced = 0
ENT.JustThrown = 0
ENT.Owner = nil

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
	-- Set model from table.

	
	-- Set up physics
	if ( SERVER ) then
		self:SetModel(table.Random(PropModels))
		self:PhysicsInit( SOLID_VPHYSICS )	
		self:PhysWake()
		self:SetCustomCollisionCheck( true )
	end


	
end

function ENT:Think()
	-- Tick down recently bounced timer.
	self.RecentlyBounced = self.RecentlyBounced - 1
	if(self.RecentlyBounced < 0) then
		self.RecentlyBounced = 0
	end
	
	-- Tick down just-thrown timer
	self.JustThrown = self.JustThrown - 100 * FrameTime()
	if(self.JustThrown < 0) then 
		self.JustThrown = 0
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
		
		if(!hitEnt:IsWorld() and !string.find(hitEnt:GetClass(), "func")) then 
			if (hitEnt.MeShield) then
				hitEnt:EmitSound(SkyView:RandomShieldSound())
				self:GetPhysicsObject():SetVelocity(bounceVel)
			end
		elseif(hitEnt:IsWorld() or string.find(hitEnt:GetClass(), "func")) then
			self:GetPhysicsObject():SetVelocity(bounceVel)
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
	if ( SERVER ) then
		print("==== MODEL DIED ====")
		print("Times Bounced: " .. self.TimesBounced)
		print("Players Killed: " .. self.PlayersKilled)
		print("Times Grappled: " .. self.TimesGrappled)
		print("Times Collided With A Prop: " .. self.OtherPropsHit)
		print("Times Collided With Same Prop: " .. self.SamePropsHit)
		print(self.JustThrown)
		print("====================")
	end
end

function ENT:Throw( from, velocity, owner )
	self:SetPos( from )
	self:GetPhysicsObject():SetVelocity( velocity )
	if( owner != nil and IsValid(owner)) then
		self.ThrownBy = owner
	end
	self.JustThrown = 0.5
end