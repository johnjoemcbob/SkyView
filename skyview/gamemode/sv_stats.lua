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

util.AddNetworkString( "PlayerAction" )

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
					local increment = self:EventAcquisition( ply, statname, stat )
					-- Only display the message if there has been adequate progress
					if ( increment ) then
						self:EventSendMessage( ply, statname, stat, ply.Stats[statname].Data )
					end
				end
				ply.Stats[statname].Data = nil
				ply.Stats[statname].DelayedAcquisition = nil
			end
		end
	end
end

-- Function called throughout the gamemode by hooks and other important gameplay logic,
-- in order to facilitate stat tracking
function GM:EventFired( ply, event, args )
	if ( not SkyView.Config.StatTracking ) then return end

	-- Table of buffered messages to iterate backwards through after the main event loop
	-- Any messages with a MessageType are added to this, so that only one of each type is
	-- displayed (i.e. one death message, one kill message, etc)
	local messages = {}

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
		if ( not self:EventCheckPrerequisite( ply, stat.Prerequisite, stat.PrerequisiteTime ) ) then
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
				local addprogress, data = stat[functionname]( stat, ply, args )
				if ( addprogress ) then
					if ( stat.Cooldown ) then
						if ( CurTime() < addprogress.Stats[statname].Cooldown ) then
							continue
						end
						addprogress.Stats[statname].Cooldown = CurTime() + stat.Cooldown
					end
					if ( stat.DelayedAcquisition ) then
						addprogress.Stats[statname].DelayedAcquisition = CurTime() + stat.DelayedAcquisition
						addprogress.Stats[statname].Data = data
						return
					end

					local increment = self:EventAcquisition( addprogress, statname, stat )
					if ( increment ) then
						-- Display message or buffer it for display after the event loop
						if ( stat.MessageType ) then
							-- Add player's name to the message type, so each player can have one of each message per event loop
							table.insert( messages, { type = stat.MessageType..tostring( addprogress:Nick() ), ply = addprogress, statname = statname, stat = stat, data = data } )
						else
							-- Display the message now
							self:EventSendMessage( addprogress, statname, stat, data )
						end
					end
				end
			end
		end
	end

	-- Send the buffered messages now
	self:EventSendBufferedMessages( messages )
end

function GM:EventAcquisition( ply, statname, stat )
	if ( not ply.Stats[statname] ) then
		ply.Stats[statname] = {
			Progress = 0,
			TotalIncrements = 0,
			Cooldown = CurTime(),
			LastIncrement = 0
		}
	end

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

		-- Increment player score
		ply:SetNWInt( "sky_score", ply:GetNWInt( "sky_score" ) + stat.Score )

		return true
	end

	return false
end

function GM:EventSendBufferedMessages( messages )
	-- Table of the currently used up message types
	local typeused = {}

	-- Iterate backwards through all messages
	for messageindex = #messages, 1, -1 do
		local message = messages[messageindex]
		if ( not typeused[message.type] ) then
			-- Display the message
			self:EventSendMessage( message.ply, message.statname, message.stat, message.data )

			-- Flag this message type as used up for the current event loop
			typeused[message.type] = true
		end
	end
end

function GM:EventSendMessage( ply, statname, stat, data )
	-- Send to client, which will display any messages/play any sounds
	net.Start( "PlayerAction" )
		net.WriteEntity( ply )
		net.WriteString( replace_vars(
			stat.Message,
			data
		) )
		net.WriteString( self:EventSelectSound( ply.Stats[statname], stat.Sound ) )
	net.Broadcast()
end

function GM:EventCheckPrerequisite( ply, prerequisite, retime )
	if (
		prerequisite and
		(
			( not ply.Stats[prerequisite] ) or
			( ( CurTime() - ply.Stats[prerequisite].LastIncrement ) > retime )
		)
	) then
		return false
	end
	return true
end

function GM:EventSelectSound( stat, soundfile )
	local soundtable = self.Sounds[soundfile]
	-- Has an entry (is an id), decide which possible sound to play
	if ( soundtable ) then
		local selectedsoundfile
			-- Find all possible sounds based on the number of increments to this stat
			local possiblesounds = {}
			local maxratio = 0
				for k, sound in pairs( soundtable ) do
					if ( ( stat.TotalIncrements or 0 ) >= sound.MinIncrement ) then
						table.insert( possiblesounds, sound )
						maxratio = maxratio + sound.Chance
					end
				end
			-- Find a random number from 1 to the max ratio, then loop through the possible
			-- sounds and find the range in which the number lies
			local randomratio = math.random( 1, maxratio )
			local currentratio = 0
			for k, sound in pairs( possiblesounds ) do
				-- Add the current sound's chance to the old ratio, and check again if the
				-- random ratio is within this range
				currentratio = currentratio + sound.Chance
				if ( randomratio <= currentratio ) then
					selectedsoundfile = sound.File
					break
				end
			end
		return selectedsoundfile
	-- Does not have an entry, play the sound file
	else
		return soundfile or ""
	end
end

hook.Add( "PlayerDeath", "SKY_STAT_PlayerDeath", function( ply, inflictor, attacker )
	-- Custom logic for if the inflictor was a prop, and who it was thrown by
	if ( inflictor:GetClass() == "sky_physprop" ) then
		if ( inflictor:GetThrownBy() != nil and IsValid( inflictor:GetThrownBy() ) ) then
			attacker = inflictor:GetThrownBy()
		end
		if ( inflictor.IsShield ) then
			if ( inflictor.LastGrappledBy and IsValid( inflictor.LastGrappledBy ) ) then
				attacker = inflictor.LastGrappledBy
			else
				attacker = inflictor.Owner
			end
		end
	end

	GAMEMODE:EventFired( ply, "PlayerDeath", { inflictor, attacker } )
	if ( attacker:IsPlayer() and ( ply ~= attacker ) ) then
		GAMEMODE:EventFired( attacker, "PlayerKilled", { inflictor, ply } )
	end
end )

-- From http://lua-users.org/wiki/StringInterpolation by http://lua-users.org/wiki/MarkEdgar
function replace_vars( str, vars )
	if ( not str ) then return "" end

	-- Allow replace_vars{str, vars} syntax as well as replace_vars(str, {vars})
	if ( not vars ) then
		vars = str
		str = vars[1]
	end
	return ( string.gsub(
		str,
		"({([^}]+)})",
		function( whole, i )
			return vars[i] or whole
		end
	) )
end