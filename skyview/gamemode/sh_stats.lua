-- Matthew Cormack (@johnjoemcbob)
-- 19/08/15
-- Shared statistic descriptions for tracking
-- This file contains the statistic descriptions and logic
-- Used to track player based stats such as;
-- -	Number of jumps
-- -	Distance travelled
-- -	Times grappled
--
-- sh_stats.lua;
-- Each element of GM.Stats contains functions to be called on various player
-- based events (e.g. death, jumping, grapple fired), as well as messages/sounds
-- for when the stat increases (if any), the score to award the player (if any),
-- the id of any prerequisite stats, and a list of positions this stat was achieved
-- at
--
-- sv_stats.lua;
-- The player then has a table of stat ids, which includes data about when they
-- last incremented the stat, the current progress towards the next increment,
-- and the total number of increments
--
-- Current list of stat events which can be called (please copy exactly);
-- -	OnPlayerDeath
-- -	OnPlayerJump
-- -	OnPlayerDoubleJump
-- -	OnPlayerGrappleJump
-- -	OnGrappleHookFired
-- -	OnGrappleHookRetracted
-- -	OnGrappleHookAttached
-- -	OnTravelOverProp (called when the player is travelling above a prop)
-- -	OnNearMiss (called from within sky_physprop when a player narrowly avoids it)
-- -	OnDelayedAcquisition (called when a stat has a delayed check, normally used to see if the player dies soon after)
-- -  OnPowerupAcquired (called when a player gets a powerup via any means)
GM.Stats = {}

GM.Stats["nearmiss"] = {
	Name = "Near Misses: %i",
	Message = "A prop narrowly missed {self}",
	--MessageType = "",
	Sound = "skyview/announcer/near_miss.mp3",
	Score = 50,
	ProgressIncrement = 1, -- The amount to increment each time this stat tracks
	ProgressMax = 1, -- The amount of progress required before it is counted as achieved on the player and progress is reset
	Prerequisite = nil,
	PrerequisiteTime = 0,
	OnNearMiss = function( self, ply, args )
		return ply,  -- Flag to add to stat progress (within sv_stats.lua)
		{
			self = ply:Nick()
		}
	end
}
GM.Stats["death"] = {
	Name = "Deaths: %i",
	--Message = "{self} died (how?)",
	MessageType = "death",
	--Sound = "vo/Breencast/br_collaboration01.wav",
	Score = 0,
	ProgressIncrement = 1, -- The amount to increment each time this stat tracks
	ProgressMax = 1, -- The amount of progress required before it is counted as achieved on the player and progress is reset
	Prerequisite = nil,
	PrerequisiteTime = 0,
	OnPlayerDeath = function( self, ply, args )
		return ply,  -- Flag to add to stat progress (within sv_stats.lua)
		{
			self = ply:Nick()
		}
	end
}
GM.Stats["death_suicide"] = {
	Name = "Suicides: %i",
	Message = "{self} suicided",
	MessageType = "death",
	--Sound = "vo/Breencast/br_collaboration02.wav",
	Score = -100,
	ProgressIncrement = 1, -- The amount to increment each time this stat tracks
	ProgressMax = 1, -- The amount of progress required before it is counted as achieved on the player and progress is reset
	Prerequisite = "death",
	PrerequisiteTime = 0,
	OnPlayerDeath = function( self, ply, args )
		-- If the player was also the attacker, it was a suicide
		if ( ply == args[2] ) then
			return ply,  -- Flag to add to stat progress (within sv_stats.lua)
			{
				self = ply:Nick()
			}
		end
	end
}
GM.Stats["death_world"] = {
	Name = "Gravity Deaths: %i",
	Message = "{self} fell",
	MessageType = "death",
	--Sound = "vo/Breencast/br_collaboration02.wav",
	Score = -150,
	ProgressIncrement = 1, -- The amount to increment each time this stat tracks
	ProgressMax = 1, -- The amount of progress required before it is counted as achieved on the player and progress is reset
	Prerequisite = "death",
	PrerequisiteTime = 0,
	OnPlayerDeath = function( self, ply, args )
		-- If the attacker was the world, it was fall damage
		if ( args[2]:IsWorld() ) then
			return ply,  -- Flag to add to stat progress (within sv_stats.lua)
			{
				self = ply:Nick()
			}
		end
	end
}
GM.Stats["death_world_sky"] = {
	Name = "SkyFail Gravity Deaths: %i",
	Message = "{self} fell to their death trying to grapple the sky",
	MessageType = "death",
	--Sound = "vo/Breencast/br_collaboration02.wav",
	Score = -150,
	ProgressIncrement = 1, -- The amount to increment each time this stat tracks
	ProgressMax = 1, -- The amount of progress required before it is counted as achieved on the player and progress is reset
	Prerequisite = "death_world",
	PrerequisiteTime = 0,
	OnPlayerDeath = function( self, ply, args )
		-- If the player recently grappled the sky
		if ( GAMEMODE:EventCheckPrerequisite( ply, "grapple_hitsky", 5 ) ) then
			return ply,  -- Flag to add to stat progress (within sv_stats.lua)
			{
				self = ply:Nick()
			}
		end
	end
}
GM.Stats["death_suicide_grapple"] = {
	Name = "Suicides by Hook: %i",
	Message = "{self} reeled in a big one",
	MessageType = "death",
	--Sound = "vo/Breencast/br_collaboration02.wav",
	Score = -200,
	ProgressIncrement = 1, -- The amount to increment each time this stat tracks
	ProgressMax = 1, -- The amount of progress required before it is counted as achieved on the player and progress is reset
	Prerequisite = "death_suicide",
	PrerequisiteTime = 0,
	OnPlayerDeath = function( self, ply, args )
		-- If this prop was grappled into themselves
		if ( args[1].LastGrappledBy == ply ) then
			return ply,  -- Flag to add to stat progress (within sv_stats.lua)
			{
				self = ply:Nick()
			}
		end
	end
}
GM.Stats["kill"] = {
	Name = "Kills: %i",
	Message = "{self} killed {victim}",
	MessageType = "kill",
	--Sound = "weapons/flaregun/fire.wav",
	Score = 0,
	ProgressIncrement = 1, -- The amount to increment each time this stat tracks
	ProgressMax = 1, -- The amount of progress required before it is counted as achieved on the player and progress is reset
	Prerequisite = nil,
	PrerequisiteTime = 0,
	OnPlayerDeath = function( self, ply, args )
		-- Killed someone else
		if ( ( ply ~= args[2] ) and ( args[2]:GetClass() == "player" ) ) then
			return args[2],  -- Flag to add to stat progress (within sv_stats.lua)
			{
				self = args[2]:Nick(),
				victim = ply:Nick()
			}
		end
	end
}
GM.Stats["kill_prop"] = {
	Name = "Prop Kills: %i",
	Message = "{self} prop killed {victim}",
	MessageType = "kill",
	Sound = "skyview/announcer/prop_kill.mp3",
	Score = 150,
	ProgressIncrement = 1, -- The amount to increment each time this stat tracks
	ProgressMax = 1, -- The amount of progress required before it is counted as achieved on the player and progress is reset
	Prerequisite = nil,
	PrerequisiteTime = 0,
	OnPlayerDeath = function( self, ply, args )
		-- Killed them with a prop
		if ( ( ply ~= args[2] ) and ( args[2]:GetClass() == "player" ) and ( args[1]:GetClass() == "sky_physprop" ) and ( not args[1].IsShield ) ) then
			return args[2],  -- Flag to add to stat progress (within sv_stats.lua)
			{
				self = args[2]:Nick(),
				victim = ply:Nick()
			}
		end
	end
}
GM.Stats["kill_shield"] = {
	Name = "Shield Kills: %i",
	Message = "{self} shield bashed {victim}",
	MessageType = "kill",
	Sound = "skyview/announcer/shield_kill.mp3",
	Score = 500,
	ProgressIncrement = 1, -- The amount to increment each time this stat tracks
	ProgressMax = 1, -- The amount of progress required before it is counted as achieved on the player and progress is reset
	Prerequisite = nil,
	PrerequisiteTime = 0,
	OnPlayerDeath = function( self, ply, args )
		-- Killed them with a shield
		if ( ( args[2]:GetClass() == "player" ) and ( args[1]:GetClass() == "sky_physprop" ) and args[1].IsShield ) then
			-- Change message type depending on if it was a self kill or another player kill
			if ( ply ~= args[2] ) then
				return args[2],  -- Flag to add to stat progress (within sv_stats.lua)
				{
					self = args[2]:Nick(),
					victim = ply:Nick()
				}
			end
		end
	end
}
GM.Stats["kill_shield_self"] = {
	Name = "Shield Kills: %i",
	Message = "{self} shield bashed themselves",
	MessageType = "death",
	Sound = "skyview/announcer/shield_kill.mp3",
	Score = -500,
	ProgressIncrement = 1, -- The amount to increment each time this stat tracks
	ProgressMax = 1, -- The amount of progress required before it is counted as achieved on the player and progress is reset
	Prerequisite = nil,
	PrerequisiteTime = 0,
	OnPlayerDeath = function( self, ply, args )
		-- Killed them with a shield
		if ( ( args[2]:GetClass() == "player" ) and ( args[1]:GetClass() == "sky_physprop" ) and args[1].IsShield ) then
			-- Change message type depending on if it was a self kill or another player kill
			if ( ply == args[2] ) then
				return args[2],  -- Flag to add to stat progress (within sv_stats.lua)
				{
					self = args[2]:Nick(),
					victim = ply:Nick()
				}
			end
		end
	end
}
GM.Stats["grapple_fired"] = {
	Name = "Grapples Fired: %i",
	--Message = "grapple fired",
	--Sound = "vo/Breencast/br_collaboration02.wav",
	Score = 0,
	ProgressIncrement = 1, -- The amount to increment each time this stat tracks
	ProgressMax = 1, -- The amount of progress required before it is counted as achieved on the player and progress is reset
	Prerequisite = nil,
	PrerequisiteTime = 0,
	OnGrappleHookFired = function( self, ply, args )
		return ply,  -- Flag to add to stat progress (within sv_stats.lua)
		{
			self = ply:Nick()
		}
	end
}
GM.Stats["grapple_hitsky"] = {
	Name = "Grapple Sky Hits: %i",
	Message = "{self} tried to grapple the sky",
	--Sound = "vo/Breencast/br_collaboration02.wav",
	Score = -50,
	ProgressIncrement = 1, -- The amount to increment each time this stat tracks
	ProgressMax = 1, -- The amount of progress required before it is counted as achieved on the player and progress is reset
	Prerequisite = nil,
	PrerequisiteTime = 0,
	OnGrappleHookAttached = function( self, ply, args )
		-- Hit skybox
		if ( args.MatType == MAT_DEFAULT ) then
			return ply,  -- Flag to add to stat progress (within sv_stats.lua)
			{
				self = ply:Nick()
			}
		end
	end
}
GM.Stats["grapple_attached"] = {
	Name = "Grapples Attached: %i",
	--Message = "grapple attached to something",
	--Sound = "vo/Breencast/br_collaboration02.wav",
	Score = 0,
	ProgressIncrement = 1, -- The amount to increment each time this stat tracks
	ProgressMax = 1, -- The amount of progress required before it is counted as achieved on the player and progress is reset
	Prerequisite = nil,
	PrerequisiteTime = 0,
	OnGrappleHookAttached = function( self, ply, args )
		-- Hit not skybox
		if ( args.MatType ~= MAT_DEFAULT ) then
			return ply,  -- Flag to add to stat progress (within sv_stats.lua)
			{
				self = ply:Nick()
			}
		end
	end
}
GM.Stats["grapple_retracted"] = {
	Name = "Grapples Retracted: %i",
	--Message = "grapple retracted",
	--Sound = "vo/Breencast/br_collaboration02.wav",
	Score = 0,
	ProgressIncrement = 1, -- The amount to increment each time this stat tracks
	ProgressMax = 1, -- The amount of progress required before it is counted as achieved on the player and progress is reset
	Prerequisite = nil,
	PrerequisiteTime = 0,
	OnGrappleHookRetracted = function( self, ply, args )
		return ply,  -- Flag to add to stat progress (within sv_stats.lua)
		{
			self = ply:Nick()
		}
	end
}
GM.Stats["jump"] = {
	Name = "Jumps: %i",
	--Message = "jumped",
	--Sound = "weapons/flaregun/fire.wav",
	Score = 0,
	ProgressIncrement = 1, -- The amount to increment each time this stat tracks
	ProgressMax = 1, -- The amount of progress required before it is counted as achieved on the player and progress is reset
	Prerequisite = nil,
	PrerequisiteTime = 0,
	OnPlayerJump = function( self, ply, args )
		return ply,  -- Flag to add to stat progress (within sv_stats.lua)
		{
			self = ply:Nick()
		}
	end
}
GM.Stats["doublejump"] = {
	Name = "Double Jumps: %i",
	--Message = "double jumped",
	--Sound = "vo/Breencast/br_collaboration02.wav",
	Score = 0,
	ProgressIncrement = 1, -- The amount to increment each time this stat tracks
	ProgressMax = 1, -- The amount of progress required before it is counted as achieved on the player and progress is reset
	Prerequisite = nil,
	PrerequisiteTime = 0,
	OnPlayerDoubleJump = function( self, ply, args )
		return ply,  -- Flag to add to stat progress (within sv_stats.lua)
		{
			self = ply:Nick()
		}
	end
}
GM.Stats["grapplejump"] = {
	Name = "Grapple Jumps: %i",
	--Message = "grapple jumped",
	--Sound = "vo/Breencast/br_collaboration02.wav",
	Score = 0,
	ProgressIncrement = 1, -- The amount to increment each time this stat tracks
	ProgressMax = 1, -- The amount of progress required before it is counted as achieved on the player and progress is reset
	Prerequisite = nil,
	PrerequisiteTime = 0,
	OnPlayerGrappleJump = function( self, ply, args )
		return ply,  -- Flag to add to stat progress (within sv_stats.lua)
		{
			self = ply:Nick()
		}
	end
}
GM.Stats["traveloverprop"] = {
	Name = "Travelled over %i props",
	--Message = "overprop",
	--Sound = "vo/Breencast/br_collaboration02.wav",
	Score = 0,
	ProgressIncrement = 1, -- The amount to increment each time this stat tracks
	ProgressMax = 1, -- The amount of progress required before it is counted as achieved on the player and progress is reset
	Prerequisite = nil,
	PrerequisiteTime = 0,
	Cooldown = 3,
	OnTravelOverProp = function( self, ply, args )
		return ply,  -- Flag to add to stat progress (within sv_stats.lua)
		{
			self = ply:Nick()
		}
	end
}
GM.Stats["grappleoverprop"] = {
	Name = "Leapt over %i props",
	Message = "{self} Leap Frogged",
	Sound = "vo/coast/odessa/male01/nlo_cheer01.wav",
	Score = 1000,
	ProgressIncrement = 1, -- The amount to increment each time this stat tracks
	ProgressMax = 1, -- The amount of progress required before it is counted as achieved on the player and progress is reset
	Prerequisite = nil,
	PrerequisiteTime = 0,
	Cooldown = 2.5,
	DelayedAcquisition = 0.5,
	OnTravelOverProp = function( self, ply, args )
		if ( args.LastGrappledBy and ( args.LastGrappledBy == ply ) and ( not args.IsShield ) ) then
			return ply,  -- Flag to add to stat progress (within sv_stats.lua)
			{
				self = ply:Nick()
			}
		end
	end,
	OnDelayedAcquisition = function( self, ply )
		if ( ( ( not ply.Stats["death"] ) or ( ( CurTime() - ply.Stats["death"].LastIncrement ) > 1 ) ) and ply:Alive() ) then
			return ply  -- Flag to add to stat progress (within sv_stats.lua)
		end
	end
}
GM.Stats["pickuppowerup"] = {
	Name = "Picked up %i powerups.",
	Message = "{self} picked up {powerupname}!",
	Score = 500,
	ProgressIncrement = 1,
	ProgressMax = 1,
	Prequisite = nil,
	PrerequisiteTime = 0,
	Cooldown = 0.1,
	DelayedAcquisition = 0.0,
	OnPowerupAcquired = function( self, ply, power )
		print(GAMEMODE.Buffs[power[2]].Name)
		return ply,
		{
			self = ply:Nick(),
			powerupname = GAMEMODE.Buffs[power[2]].Name
		}
	end,
	OnDelayedAcquisition = function( self, ply )
		if ( ( ( not ply.Stats["death"] ) or ( ( CurTime() - ply.Stats["death"].LastIncrement ) > 1 ) ) and ply:Alive() ) then
			return ply  -- Flag to add to stat progress (within sv_stats.lua)
		end
	end
}
