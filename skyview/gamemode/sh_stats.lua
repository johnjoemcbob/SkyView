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
-- -	OnDelayedAcquisition (called when a stat has a delayed check, normally used to see if the player dies soon after)
GM.Stats = {}

GM.Stats["death"] = {
	Name = "Deaths",
	--Message = "Stat tracking sees your death",
	--Sound = "vo/Breencast/br_collaboration01.wav",
	Score = 0,
	ProgressIncrement = 1, -- The amount to increment each time this stat tracks
	ProgressMax = 1, -- The amount of progress required before it is counted as achieved on the player and progress is reset
	Prerequisite = nil,
	PrerequisiteTime = 0,
	OnPlayerDeath = function( ply, args )
		return true -- Flag to add to stat progress (within sv_stats.lua)
	end
}
GM.Stats["death_suicide"] = {
	Name = "Suicides",
	--Message = "suicide death",
	--Sound = "vo/Breencast/br_collaboration02.wav",
	Score = -1,
	ProgressIncrement = 1, -- The amount to increment each time this stat tracks
	ProgressMax = 1, -- The amount of progress required before it is counted as achieved on the player and progress is reset
	Prerequisite = "death",
	PrerequisiteTime = 0,
	OnPlayerDeath = function( ply, args )
		-- If the player was also the attacker, it was a suicide
		if ( ply == args[2] ) then
			return true -- Flag to add to stat progress (within sv_stats.lua)
		end
	end
}
GM.Stats["death_suicide_grapple"] = {
	Name = "Suicides by Hook",
	Message = "grappled into suicide",
	--Sound = "vo/Breencast/br_collaboration02.wav",
	Score = -2,
	ProgressIncrement = 1, -- The amount to increment each time this stat tracks
	ProgressMax = 1, -- The amount of progress required before it is counted as achieved on the player and progress is reset
	Prerequisite = "death_suicide",
	PrerequisiteTime = 0,
	OnPlayerDeath = function( ply, args )
		-- If this prop was grappled into themselves
		if ( args[1].LastGrappledBy == ply ) then
			return true -- Flag to add to stat progress (within sv_stats.lua)
		end
	end
}
GM.Stats["grapple_fired"] = {
	Name = "Grapples Fired",
	--Message = "grapple fired",
	--Sound = "vo/Breencast/br_collaboration02.wav",
	Score = 0,
	ProgressIncrement = 1, -- The amount to increment each time this stat tracks
	ProgressMax = 1, -- The amount of progress required before it is counted as achieved on the player and progress is reset
	Prerequisite = nil,
	PrerequisiteTime = 0,
	OnGrappleHookFired = function( ply, args )
		return true -- Flag to add to stat progress (within sv_stats.lua)
	end
}
GM.Stats["grapple_hitsky"] = {
	Name = "Grapple Sky Hits",
	Message = "Tried to grapple the sky",
	--Sound = "vo/Breencast/br_collaboration02.wav",
	Score = 0,
	ProgressIncrement = 1, -- The amount to increment each time this stat tracks
	ProgressMax = 1, -- The amount of progress required before it is counted as achieved on the player and progress is reset
	Prerequisite = nil,
	PrerequisiteTime = 0,
	OnGrappleHookAttached = function( ply, args )
		-- Hit skybox
		if ( args.MatType == MAT_DEFAULT ) then
			return true -- Flag to add to stat progress (within sv_stats.lua)
		end
	end
}
GM.Stats["grapple_attached"] = {
	Name = "Grapples Attached",
	--Message = "grapple attached to something",
	--Sound = "vo/Breencast/br_collaboration02.wav",
	Score = 0,
	ProgressIncrement = 1, -- The amount to increment each time this stat tracks
	ProgressMax = 1, -- The amount of progress required before it is counted as achieved on the player and progress is reset
	Prerequisite = nil,
	PrerequisiteTime = 0,
	OnGrappleHookAttached = function( ply, args )
		-- Hit not skybox
		if ( args.MatType ~= MAT_DEFAULT ) then
			return true -- Flag to add to stat progress (within sv_stats.lua)
		end
	end
}
GM.Stats["grapple_retracted"] = {
	Name = "Grapples Retracted",
	--Message = "grapple retracted",
	--Sound = "vo/Breencast/br_collaboration02.wav",
	Score = 0,
	ProgressIncrement = 1, -- The amount to increment each time this stat tracks
	ProgressMax = 1, -- The amount of progress required before it is counted as achieved on the player and progress is reset
	Prerequisite = nil,
	PrerequisiteTime = 0,
	OnGrappleHookRetracted = function( ply, args )
		return true -- Flag to add to stat progress (within sv_stats.lua)
	end
}
GM.Stats["jump"] = {
	Name = "Jumps",
	--Message = "jumped",
	--Sound = "vo/Breencast/br_collaboration02.wav",
	Score = 0,
	ProgressIncrement = 1, -- The amount to increment each time this stat tracks
	ProgressMax = 1, -- The amount of progress required before it is counted as achieved on the player and progress is reset
	Prerequisite = nil,
	PrerequisiteTime = 0,
	OnPlayerJump = function( ply, args )
		return true -- Flag to add to stat progress (within sv_stats.lua)
	end
}
GM.Stats["doublejump"] = {
	Name = "Double Jumps",
	--Message = "double jumped",
	--Sound = "vo/Breencast/br_collaboration02.wav",
	Score = 0,
	ProgressIncrement = 1, -- The amount to increment each time this stat tracks
	ProgressMax = 1, -- The amount of progress required before it is counted as achieved on the player and progress is reset
	Prerequisite = nil,
	PrerequisiteTime = 0,
	OnPlayerDoubleJump = function( ply, args )
		return true -- Flag to add to stat progress (within sv_stats.lua)
	end
}
GM.Stats["grapplejump"] = {
	Name = "Grapple Jumps",
	--Message = "grapple jumped",
	--Sound = "vo/Breencast/br_collaboration02.wav",
	Score = 0,
	ProgressIncrement = 1, -- The amount to increment each time this stat tracks
	ProgressMax = 1, -- The amount of progress required before it is counted as achieved on the player and progress is reset
	Prerequisite = nil,
	PrerequisiteTime = 0,
	OnPlayerGrappleJump = function( ply, args )
		return true -- Flag to add to stat progress (within sv_stats.lua)
	end
}
GM.Stats["traveloverprop"] = {
	Name = "Travelled over props",
	--Message = "overprop",
	--Sound = "vo/Breencast/br_collaboration02.wav",
	Score = 0,
	ProgressIncrement = 1, -- The amount to increment each time this stat tracks
	ProgressMax = 1, -- The amount of progress required before it is counted as achieved on the player and progress is reset
	Prerequisite = nil,
	PrerequisiteTime = 0,
	Cooldown = 3,
	OnTravelOverProp = function( ply, args )
		return true -- Flag to add to stat progress (within sv_stats.lua)
	end
}
GM.Stats["grappleoverprop"] = {
	Name = "Travelled over props",
	Message = "DAAAAAAMN SON",
	Sound = "vo/coast/odessa/male01/nlo_cheer01.wav",
	Score = 10,
	ProgressIncrement = 1, -- The amount to increment each time this stat tracks
	ProgressMax = 1, -- The amount of progress required before it is counted as achieved on the player and progress is reset
	Prerequisite = nil,
	PrerequisiteTime = 0,
	Cooldown = 2.5,
	DelayedAcquisition = 0.5,
	OnTravelOverProp = function( ply, args )
		if ( args.LastGrappledBy and ( args.LastGrappledBy == ply ) ) then
			return true -- Flag to add to stat progress (within sv_stats.lua)
		end
	end,
	OnDelayedAcquisition = function( self, ply )
		if ( ( ( not ply.Stats["death"] ) or ( ( CurTime() - ply.Stats["death"].LastIncrement ) > 1 ) ) and ply:Alive() ) then
			print( CurTime() - ply.Stats["death"].LastIncrement )
			return true -- Flag to add to stat progress (within sv_stats.lua)
		end
	end
}