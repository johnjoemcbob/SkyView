-- Author: Jordan Brown (@DrMelon)
-- 19/08/2015
-- Arcade Mode DLC for SkyView - Powerups
-- This is the base for all powerups to inherit from.

if SERVER then
	AddCSLuaFile( "shared.lua" )
end


ENT.Type = "anim"

ENT.PowerupModel = "models/props_junk/Shoe001a.mdl"
ENT.PowerupColor = Color( 255, 255, 80, 200 )
ENT.PowerupScale = 3
ENT.PowerupPickupRadius = 30
ENT.PowerupBuffNumber = 1


function ENT:Initialize()
	-- Set model
	self:SetModel( self.PowerupModel )
	
	-- Set color of powerups
	self:SetMaterial( "models/debug/debugwhite" )
	self:SetColor( self.PowerupColor )
	
	-- Set render modes properly
	self.RenderGroup =  RENDERGROUP_BOTH 
	self:SetRenderMode( RENDERMODE_TRANSCOLOR )
	
	self:SetAngles( Angle( 0, 0, 0 ) )
	
	self:SetModelScale( self.PowerupScale )
	
	--self:SetCollisionGroup( COLLISION_GROUP_PLAYER )
	--self:SetSolid( SOLID_BBOX )
	
end

function ENT:Think()
	if( CLIENT ) then
		-- ROTATE SLOWLY, WOBBLE ON AXIS
		self:SetAngles( self:GetAngles() + Angle( 0, 45 * FrameTime(), 0 ) )
		self:SetAngles( self:GetAngles() + Angle( math.sin( CurTime() * 10 ) / 8, 0, 0 ) )
		
		-- Float up and down a bit
		self:SetPos( self:GetPos() + Vector( 0, 0, math.cos(CurTime() * 2) / 30 ) ) 
	end
	
	-- Check for a collision with a player
	local nearbyEnts = ents.FindInSphere( self:GetPos(), self.PowerupPickupRadius )
	for k, v in pairs(nearbyEnts) do
		if( v:IsPlayer() and IsValid(v)) then
			if ( GAMEMODE:PlayerHasThisPowerup(v, self.PowerupBuffNumber) == false ) then 
				v:AddBuff(self.PowerupBuffNumber) 
				self:Remove()
			end
		end
	end
	
end