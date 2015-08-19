-- Matthew Cormack (@johnjoemcbob)
-- 19/08/15
-- Serverside statistic tracking hooks
-- This file contains functions and hooks for providing individual stats access
-- to key game events
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

function GM:PlayerInitialSpawn_Stats( ply )
	ply.Stats = {}
end

function GM:Think_Stats()
	-- Loop through stats in alphabetical order
	-- NOTE: Taken from the base Garry's Mod PrintTable function (https://github.com/garrynewman/garrysmod/blob/02158910200e8e91482dc8e3fde647b5f33da31d/garrysmod/lua/includes/util.lua)
	local statnames = table.GetKeys( self.Stats )

	table.sort( statnames, function( a, b )
		if ( isnumber( a ) && isnumber( b ) ) then return a < b end
		return tostring( a ) < tostring( b )
	end )

	for i = 1, #statnames do
		local statname = statnames[ i ]
		local stat = self.Stats[ statname ]

		for k, ply in pairs( player.GetAll() ) do
			if ( ply.Stats[statname] and ply.Stats[statname].DelayedAcquisition and ( CurTime() >= ply.Stats[statname].DelayedAcquisition ) ) then
				local shouldaquire = stat:OnDelayedAcquisition( ply )
				if ( shouldaquire ) then
					self:EventAcquisition( ply, statname, stat )
				end
				ply.Stats[statname].DelayedAcquisition = nil
			end
		end
	end
end

-- Function called throughout the gamemode by hooks and other important gameplay logic,
-- in order to facilitate stat tracking
function GM:EventFired( ply, event, args )
	if ( not SkyView.Config.StatTracking ) then return end

	-- Loop through stats in alphabetical order
	-- NOTE: Taken from the base Garry's Mod PrintTable function (https://github.com/garrynewman/garrysmod/blob/02158910200e8e91482dc8e3fde647b5f33da31d/garrysmod/lua/includes/util.lua)
	local statnames = table.GetKeys( self.Stats )

	table.sort( statnames, function( a, b )
		if ( isnumber( a ) && isnumber( b ) ) then return a < b end
		return tostring( a ) < tostring( b )
	end )

	for i = 1, #statnames do
		local statname = statnames[ i ]
		local stat = self.Stats[ statname ]

		-- Check stat prerequisites
		if (
			stat.Prerequisite and
			(
				( not ply.Stats[stat.Prerequisite] ) or
				( ( CurTime() - ply.Stats[stat.Prerequisite].LastIncrement ) > stat.PrerequisiteTime )
			)
		) then
			continue
		end

		-- Ensure this stat exists on the player
		if ( not ply.Stats[statname] ) then
			ply.Stats[statname] = {
				Progress = 0,
				TotalIncrements = 0,
				Cooldown = CurTime(),
				LastIncrement = 0
			}
		end

		if ( not ply.Stats[statname].DelayedAcquisition ) then
			local functionname = "On"..event
			if ( stat[functionname] ) then
				local addprogress = stat[functionname]( ply, args )
				if ( addprogress ) then
					if ( stat.Cooldown ) then
						if ( CurTime() < ply.Stats[statname].Cooldown ) then
							continue
						end
						ply.Stats[statname].Cooldown = CurTime() + stat.Cooldown
					end
					if ( stat.DelayedAcquisition ) then
						ply.Stats[statname].DelayedAcquisition = CurTime() + stat.DelayedAcquisition
						return
					end

					self:EventAcquisition( ply, statname, stat )
				end
			end
		end
	end
end

function GM:EventAcquisition( ply, statname, stat )
	-- Add to inbetween progress
	ply.Stats[statname].LastProgress = CurTime()
	ply.Stats[statname].Progress = ply.Stats[statname].Progress + 1

	-- Has enough progress to increment
	if ( ply.Stats[statname].Progress >= stat.ProgressMax ) then
		-- Reset inbetween progress
		ply.Stats[statname].Progress = 0

		-- Increment stat
		ply.Stats[statname].LastIncrement = CurTime()
		ply.Stats[statname].TotalIncrements = ply.Stats[statname].TotalIncrements + 1

		-- Display increment message
		if ( stat.Message ) then
			ply:ChatPrint( stat.Message .. " " .. ply.Stats[statname].TotalIncrements .. " times" )
		end

		-- Play increment sound
		if ( stat.Sound ) then
			ply:EmitSound( stat.Sound )
		end

		ply:AddFrags( stat.Score )
	end
end

hook.Add( "PlayerDeath", "SKY_STAT_PlayerDeath", function( ply, inflictor, attacker )
	-- Custom logic for if the inflictor was a prop, and who it was thrown by
	if( inflictor:GetClass() == "sky_physprop" ) then
		if( inflictor:GetThrownBy() != nil and IsValid( inflictor:GetThrownBy() ) ) then
			attacker = inflictor:GetThrownBy()
		end
	end

	GAMEMODE:EventFired( ply, "PlayerDeath", { inflictor, attacker } )
end )