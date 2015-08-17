-- Matthew Cormack (@johnjoemcbob)
-- 17/08/15
-- Grapple hook rope entity
-- Fired by the player & moves towards their target,
-- Reels the player in when it hits the target
-- If the target is an entity, also reels the entity in
-- Rope is drawn using render.DrawBeam

if SERVER then
	AddCSLuaFile( "shared.lua" )
end

ENT.Type = "anim"

-- The direction to fire the grapple in, set when it is fired in init.lua
ENT.Direction = Vector( 0, 0, 0 )

-- Flag for when the grapple has collided with either the world or an entity,
-- and the player should begin reeling in
ENT.GrappleAttached = false

-- The speed at which to shoot out the hook
ENT.CastSpeed = 1500 * 5009

-- The speed at which to reel in the player
ENT.ReelSpeed = 1500 * 100

-- The multiplier on the inverted object speed for when grappling against players/entities
ENT.InvertSpeedMultiplier = 0.001

-- The distance at which to stop reeling in
ENT.MinDistance = 100

local RopeMaterial = Material( "cable/cable" )

function ENT:Initialize()
	-- Initialize shared properties
	self:DrawShadow( false )
	self:SetSolid( SOLID_BBOX )
	self:SetCustomCollisionCheck( true )

	if SERVER then
		-- Physics enabled, gravity disabled
		self:PhysicsInitSphere( 5, "default" )
		self:SetMoveType( MOVETYPE_VPHYSICS )
		if ( self:GetPhysicsObject() and IsValid( self:GetPhysicsObject() ) ) then
			self:GetPhysicsObject():EnableGravity( false )
			self:GetPhysicsObject():SetVelocity( self.Direction * self.CastSpeed )
		end

		-- Replicate the owner to clients
		self:SetOwnerIndex( self.Owner:EntIndex() )

		-- Spawn and parent the visual models representing the hook
		self.VisualModels = {}
		for hook = 1, 4 do
			local hookmodel = ents.Create( "prop_dynamic" )
				hookmodel:SetModel( "models/props_junk/meathook001a.mdl" )
				hookmodel:SetAngles( Angle( 0, 90 * hook, 90 ) )
				hookmodel:SetPos( self:GetPos() + ( self:GetAngles():Right() * -5 ) )
				hookmodel:SetModelScale( 0.5, 0 )
			hookmodel:Spawn()
			hookmodel:SetParent( self )
			table.insert( self.VisualModels, hookmodel )
		end

		-- Rotate the hook to face the target
		self:SetAngles( self.Direction:Angle() + Angle( -90, 0, 0 ) )
	end
end

function ENT:SetupDataTables()
	self:NetworkVar( "Int", 0, "OwnerIndex" )
end

function ENT:Think()
	if ( IsValid( self.Owner ) and ( self.GrappleAttached ~= false ) ) then
		local grappletype = type( self.GrappleAttached )
		local direction, distance
		-- Moving object
			if ( ( grappletype == "Player" ) or ( grappletype == "Entity" ) ) then
				direction = self.GrappleAttached:GetPos() - self.Owner:GetPos()
				distance = self.GrappleAttached:GetPos():Distance( self.Owner:GetPos() )

				-- In player/entity case, move both towards each other
				if ( distance < self.MinDistance ) then
					direction = Vector( 0, 0, 0 )
				end
				local velocity = direction:GetNormalized() * self.GrappleAttached:GetPhysicsObject():GetMass() * FrameTime() * -self.ReelSpeed * self.InvertSpeedMultiplier
				self.GrappleAttached:SetVelocity( velocity )
				-- Entity has a physics object, set velocity on that too
				if ( grappletype == "Entity" ) then
					self.GrappleAttached:GetPhysicsObject():SetVelocity( velocity )
				end

				-- Ensure the player is not stuck to the ground
				self.GrappleAttached:SetGroundEntity( nil )
			-- Static world position
			else
				direction = self.GrappleAttached - self.Owner:GetPos()
				distance = self.GrappleAttached:Distance( self.Owner:GetPos() )
			end
			if ( distance < self.MinDistance ) then
				direction = Vector( 0, 0, 0 )
			end
		self.Owner:SetVelocity( direction:GetNormalized() * FrameTime() * self.ReelSpeed - self.Owner:GetVelocity() )

		-- Ensure the player is not stuck to the ground
		self.Owner:SetGroundEntity( nil )
	end
end

function ENT:PhysicsCollide( data, phys )
	local entity
	local hitpos = data.HitPos
	local mattype = MAT_GRASS
	-- Hit world, check for skybox
	if ( data.HitEntity:EntIndex() == 0 ) then
		local trace = util.TraceLine(
			{
				start = self:GetPos(),
				endpos = self:GetPos() + ( ( hitpos - self:GetPos() ) * 100 ),
				mask = MASK_SOLID_BRUSHONLY
			}
		)
		mattype = trace.MatType
		hitpos = trace.HitPos
	-- Otherwise use the entity
	else
		entity = data.HitEntity
	end
	self:Attach( { Entity = entity, HitPos = hitpos, HitNormal = data.HitNormal, MatType = mattype } )
end

function ENT:Attach( trace )
	-- Flagged as disabled
	if ( self.DisableAttach ) then return end
	-- Don't attach to skyboxes
	if ( trace.MatType == MAT_DEFAULT ) then
		-- Disable ever being able to attach
		self.DisableAttach = true

		-- Enable gravity on the hook
		local phys = self:GetPhysicsObject()
		if ( phys and IsValid( phys ) ) then
			phys:EnableGravity( true )
			phys:SetVelocity( Vector( 0, 0, 0 ) )
		end

		return
	end

	-- Remove collision from the attached hook
	self:PhysicsDestroy()
	self:SetSolid( SOLID_NONE )
	self:SetAngles( trace.HitNormal:Angle() + Angle( -90, 0, 0 ) )
	self:SetPos( trace.HitPos )

	-- Flag as attached to something
	self.GrappleAttached = trace.HitPos

	if ( IsValid( trace.Entity ) ) then
		-- Parent the hook to the entity/world
		self:SetParent( trace.Entity )

		-- Flag as attached to an object
		self.GrappleAttached = trace.Entity
	end
end

function ENT:OnRemove()
	if ( SERVER ) then
		-- Remove the visual models
		for k, hookmodel in pairs( self.VisualModels ) do
			hookmodel:Remove()
		end
	end
end

if ( CLIENT ) then
	function ENT:Draw()
		-- Draw the grapple rope from the owning player to the entity position
		render.SetMaterial( RopeMaterial )
		render.DrawBeam(
			self:GetPos(),
			ents.GetByIndex( self:GetOwnerIndex() ):EyePos() - Vector( 0, 0, 10 ),
			2, 
			0, 1, 
			Color( 255, 255, 255, 255 )
		)
	end
end