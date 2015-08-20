AddCSLuaFile( "cl_buff.lua" )
AddCSLuaFile("shared.lua") --send to clients
AddCSLuaFile("shared/sh_config.lua")
AddCSLuaFile( "vgui_gamenotice.lua" )
AddCSLuaFile( "cl_deathnotice.lua" )
AddCSLuaFile( "sh_stats.lua" )
AddCSLuaFile( "sh_buff.lua" )

//make dirs to access later
file.CreateDir("skyview")
file.CreateDir("skyview/players")
//

//make net requests possible
util.AddNetworkString("skyview_firstplayerscreen")
//


--Gamemode Includes
include("shared/sh_config.lua") --load our config file
include("shared.lua") --load shared.lua file
include( "sh_buff.lua" )
include( "sh_stats.lua" )

include( "sv_buff.lua" )
include( "sv_stats.lua" )
//


//Some tables
//Model Table
local Models = 
{
 "models/player/Group01/Female_01.mdl",
 "models/player/Group01/Female_02.mdl",
 "models/player/Group01/Female_03.mdl",
 "models/player/Group01/Female_04.mdl",
 "models/player/Group01/Female_06.mdl",
 "models/player/group01/male_01.mdl",
 "models/player/Group01/Male_02.mdl",
 "models/player/Group01/male_03.mdl",
 "models/player/Group01/Male_04.mdl",
 "models/player/Group01/Male_05.mdl",
 "models/player/Group01/Male_06.mdl",
 "models/player/Group01/Male_07.mdl",
 "models/player/Group01/Male_08.mdl",
 "models/player/Group01/Male_09.mdl"
}
//

//Prop Models Table
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


//When a shield is hit sounds
local ShieldHitSounds =
{
	"ambient/energy/zap5.wav",
	"ambient/energy/zap6.wav",
	"ambient/energy/zap7.wav",
	"ambient/energy/zap8.wav",
	"ambient/energy/zap9.wav"
}
//

//SkyView Functions

function SkyView:PlayerExists(ply) --check if player exists
	return file.Exists("skyview/players/"..ply.FileID..".txt", "DATA")
end

function SkyView:CreatePlayer(ply) --create player func
	file.Write("skyview/players/"..ply.FileID..".txt", " ")
end

function SkyView:ShowFirstScreen(ply)
	net.Start("skyview_firstplayerscreen")
	net.Send(ply)
end

function SkyView:RandomShieldSound()
	local soundO, key = table.Random(ShieldHitSounds)
	return soundO
end

//Base Functions

function GM:PlayerInitialSpawn(ply)
	-- Found in sv_stats.lua
	self:PlayerInitialSpawn_Stats( ply )

	if SkyView.Config.FirstPerson then
    	ply:SetWalkSpeed(700)
        ply:SetRunSpeed(600)
        ply:SetJumpPower(0)
        ply:SetGravity(1.1)
       end
	ply:SetModel(table.Random(Models))
	ply.ShieldMade = false
	ply.PropCD = 0
	ply.InAir = false  
	ply.Jumped = false 
	ply.JumpTime = 0
	ply.Shield = nil 
	ply.HasPowerup = false
	self:PlayerInitialSpawn_Buff( ply )
	ply.FileID = ply:SteamID():gsub(":", "-")
	if !SkyView:PlayerExists(ply) then 
		--player doesn't exist 
		SkyView:ShowFirstScreen(ply) --show them the first screen
		SkyView:CreatePlayer(ply) --make their player
	end
end

function GM:PlayerSpawn(ply)
	ply.PropCD = CurTime()+0.2
	for k, buff in pairs( self.Buffs ) do
		ply:RemoveBuff( k )
	end	
end



function GM:PostPlayerDeath( ply )
	-- Remove and grapples when the player dies
	RemoveGrapple( ply )

	-- If any players are attached to this player, attach them instead to the death ragdoll
	for k, otherply in pairs( player.GetAll() ) do
		-- This player was attached to the now dead player
		if (
			otherply.Grapple and otherply.GrappleHook and IsValid( otherply.GrappleHook ) and
			otherply.GrappleHook.GrappleAttached and ( otherply.GrappleHook.GrappleAttached == ply )
		) then
			-- Attach instead to their ragdoll
			local ragdoll = ply:GetRagdollEntity()
			local data = {}
				data.Entity = ragdoll
				data.HitPos = ragdoll:GetPos()
				data.HitNormal = otherply.GrappleHook:GetAngles():Up()
				data.MatType = MAT_GRASS
			otherply.GrappleHook:Attach( data )
		end
	end
	
	-- Remove all buffs and powerups
	ply.HasPowerup = false
	for k, buff in pairs( self.Buffs ) do
		ply:RemoveBuff( k )
	end	
	
end

-- Death stats!
function GM:PlayerDeath( ply, inflictor, attacker )
	--self.BaseClass:PlayerDeath( ply, inflictor, attacker )

	if( inflictor:GetClass() == "sky_physprop" ) then
		if( inflictor:GetThrownBy() != nil and IsValid( inflictor:GetThrownBy() ) ) then
			attacker = inflictor:GetThrownBy()
			if( attacker == ply ) then
				-- Suicide by Prop + 1
				
				-- Check if they grappled themselves a deadly object
				if ( inflictor.LastGrappledBy == ply ) then
					PrintMessage( HUD_PRINTTALK, ply:Name() .. " reeled in a big one." )
					
				-- Check  bounce timer on prop for rebound suicide.
				elseif (inflictor.RecentlyBounced > 0 and inflictor.TimesBounced > 2 ) then
					PrintMessage( HUD_PRINTTALK, ply:Name() .. " got a nasty, bouncy, surprise." )
					
					
				else
					-- Somehow walked in front of it.
					PrintMessage( HUD_PRINTTALK, ply:Name() .. " couldn't dodge themselves." )
				end
			else
				-- Someone else threw it
				-- Check grapple on prop for grapple kill.
				if( inflictor.LastGrappledBy == attacker ) then
					PrintMessage( HUD_PRINTTALK, attacker:Name() .. " whiplashed " .. ply:Name() .. "." ) 
					
				-- Player grappled the attackers prop towards them
				elseif( inflictor.LastGrappledBy == ply ) then
					PrintMessage( HUD_PRINTTALK, ply:Name() .. " played " .. attacker:Name() .. "'s claw game and lost. ")
				
				-- Check bounce timer on prop for rebound kill.
				elseif( inflictor.RecentlyBounced > 0  and inflictor.TimesBounced > 2 ) then
					PrintMessage( HUD_PRINTTALK, attacker:Name() .. " played squash with " .. ply:Name() .. "." )
					
				else
					-- Normal kill.
					PrintMessage( HUD_PRINTTALK, attacker:Name() .. " ground " .. ply:Name() .. " into a paste." )
				end
				attacker:AddFrags( 1 )
			end
		end

		-- Check for multikill
		if(inflictor.PlayersKilled > 0) then
			PrintMessage( HUD_PRINTTALK, "MULTI KILL!" )
		end

		-- This prop has killed people. O:
		inflictor.PlayersKilled = inflictor.PlayersKilled + 1
	end
end

function GM:KeyPress(ply, key)
	if ply:Alive() then
		if key == IN_USE then
			AddGrapple( ply )
			ply.InAir = true
			ply.Jumped = true
		end
		if key == IN_ATTACK and !ply.ShieldMade and !ply.Grapple then
			if ply.PropCD == 0 or ply.PropCD > 0 and CurTime() >= ply.PropCD then
				local prop = ents.Create("sky_physprop")
					local pos = ply:GetPos()
					local fireangle = ply:EyeAngles()
						-- If the player is on the ground they cannot fire downwards, or they will harm themselves
						-- if ( ply:IsOnGround() ) then
							-- fireangle.p = math.Clamp( fireangle.p, -180, 0 )
						-- end
					local forward = fireangle:Forward()
					local throwPos = ply:EyePos() + ( forward * 10 )
					local throwVelocity = nil
					
					if SkyView.Config.FirstPerson then
						throwVelocity = ( forward * 2000 + ply:GetVelocity() )
					else
						throwVelocity = ( ply:GetForward() * 2000 + ply:GetVelocity() )
						--Why we did the thing above? Because when we're in the sky view, we can't aim where we shoot.
					end
					prop:SetAngles( fireangle )
				prop:Spawn()
				
				-- Throw the prop, setting its owner
				prop:Throw( throwPos, throwVelocity, ply )
				prop:SetPropOwner(ply)

				ply.PropCD = CurTime()+SkyView.Config.PropSpawnCoolDown
			end
		end
	end
end

function GM:KeyRelease( ply, key )
	if ply:Alive() then
		if key == IN_USE then
			RemoveGrapple( ply )
		end
	end
end

function GM:Think()
	self:Think_Stats()
	-- Used to update buffs on players, function located within sv_buff.lua
	self:Think_Buff()

	for k,v in pairs(player.GetAll()) do 
		if v:Alive() then
			-- Shield
			if v:KeyDown(IN_ATTACK2) then
				if !v.ShieldMade then
					v.ShieldMade = true

					local shield = ents.Create("sky_physprop")
						shield:SetPos(v:EyePos()+v:GetForward()*50)
						shield:SetAngles(v:GetAngles())
						shield.IsShield = true
						shield:SetModel("models/props_interiors/VendingMachineSoda01a_door.mdl")
						shield.MeShield = true
						shield.Owner = v
					shield:Spawn()
					v.Shield = shield

					local obj = shield:GetPhysicsObject()
					if ( obj and IsValid( obj ) ) then
						obj:SetMass( 90000 )
					end
				else
					v.Shield.RemoveTime = CurTime() + SkyView.Config.RemovePropTime
				end
			elseif !v:KeyDown(IN_ATTACK2) and v.ShieldMade then
				if ( v.Shield and IsValid( v.Shield ) ) then
					v.Shield:Remove()
				end
				v.ShieldMade = false
			end
			if v.ShieldMade and v.Shield and IsValid( v.Shield ) then
				v.Shield:SetPos(v:EyePos()+v:GetForward()*50)
				v.Shield:SetAngles(v:GetAngles())
			end

			-- If on the grapple hook & reeling in, jumping can launch you into the air
			if (
				v:KeyDown( IN_JUMP ) and
				v.Grapple and v.GrappleHook and IsValid( v.GrappleHook ) and
				( v.GrappleHook.GrappleAttached ~= false )
			) then
				-- Jump
			 	v:SetVelocity( Vector( 0, 0, 400 ) )
				GAMEMODE:EventFired( v, "PlayerGrappleJump" )

				-- Increase the velocity of the attached item (if it's an entity)
				if ( type( v.GrappleHook.GrappleAttached ) == "Entity" ) then
					local phys = v.GrappleHook.GrappleAttached:GetPhysicsObject()
					if ( phys and IsValid( phys ) ) then
						phys:SetVelocity(
							phys:GetVelocity() / v.GrappleHook.InvertSpeedMultiplier
						)
					end
				end
				-- Remove the hook
				RemoveGrapple( v )
			elseif v:KeyDown(IN_JUMP) and v.InAir and !v.Jumped then
				if CurTime() >= v.JumpTime then
				 	v.Jumped = true 
				 	v:SetVelocity(Vector(0,0,300))
				 	v.JumpTime = 0
					GAMEMODE:EventFired( v, "PlayerDoubleJump" )
				end
			elseif v:KeyDown(IN_JUMP) and v:IsOnGround() then
				if v.JumpTime == 0 then 
					v.JumpTime = CurTime()+SkyView.Config.DoubleJumpTime
				end
				v:SetVelocity(Vector(0,0,300))
				v.InAir = true
				v.Jumped = false
				GAMEMODE:EventFired( v, "PlayerJump" )
			-- Set ability to normal/double jump if on ground and not grappling
			elseif v:OnGround() and ( ( not v.Grapple ) or ( not v.GrappleHook ) or ( not IsValid( v.GrappleHook ) ) or ( not v.GrappleHook.GrappleAttached) ) then 
				v.InAir = false 
				v.Jumped = false 
				v.JumpTime = 0
			end

			-- Pass over props
			for _, prop in pairs( ents.FindInSphere( v:GetPos(), 200 ) ) do
				-- Is a prop
				if ( ( prop:GetClass() == "sky_physprop" ) or ( prop:GetClass() == "prop_physics" ) ) then
					-- Is close on every axis, but under on the z
					local horizontaldistance = v:GetPos():Distance( Vector( prop:GetPos().x, prop:GetPos().y, v:GetPos().z ) )
					local verticaldistance = prop:GetPos().z - v:GetPos().z
					if ( ( horizontaldistance < 200 ) and ( verticaldistance > -200 ) and ( verticaldistance < 0 ) ) then
						GAMEMODE:EventFired( v, "TravelOverProp", prop )
					end
				end
			end
		else
			-- Don't remove the shield on player death, to allow for it rolling around
			-- (Cleans up after SkyView.Config.RemovePropTime)
			v.Shield = nil
		end
	end
end

function GM:GetFallDamage( ply, speed )
	-- Don't take damage if still reeling in
	if ( ply.Grapple and IsValid( ply.GrappleHook ) and ply.GrappleHook.GrappleAttached ) then
		return 0
	end
	return 10
end

function GM:PlayerDisconnected( ply )
	RemoveGrapple( ply )
end

function AddGrapple( ply )
	-- For some reason the old hook is still around, delete
	RemoveGrapple( ply )

	-- Create the grapple
	ply.Grapple = true

	-- Create the grapple hook physics object, which will fly forward of the player
	local col = GAMEMODE.PlayerColours[math.random( 1, #GAMEMODE.PlayerColours)]
		col = Vector( col.r / 255, col.g / 255, col.b / 255 )
	ply:SetPlayerColor( col )
	ply.GrappleHook = ents.Create( "sky_grapple" )
		ply.GrappleHook:SetPos( ply:EyePos() )
		ply.GrappleHook.Direction = ply:EyeAngles():Forward()
		ply.GrappleHook.Owner = ply
		col = ply:GetPlayerColor()
			col = Color( col.x * 255, col.y * 255, col.z * 255 )
		ply.GrappleHook:SetColor( col )
	ply.GrappleHook:Spawn()
end

function RemoveGrapple( ply )
	-- Delete the grapple
	ply.Grapple = false

	if ( ply.GrappleHook and IsValid( ply.GrappleHook ) ) then
		-- Entity defined function to play a grapple retract animation before removal
		ply.GrappleHook:HookRemove()
	end

	-- Enable gravity on the player
	ply:SetGravity( 1.1 )
	ply:SetMoveType( MOVETYPE_WALK )
end

-- For powerups/buffs
function GM:PlayerHasThisPowerup( ply, powerupnum )
	for k, v in pairs(ply.Buffs) do
		if(k == powerupnum) then
			return true
		end
	end
	
	return false
end