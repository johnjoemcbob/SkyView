-- Matthew Cormack
-- 22/08/15
-- Round system

GM.RoundStates = {
	Begin = 1,
	Progress = 2,
	End = 3
}
GM.CurrentRoundState = 1

function GM:PlayerInitialSpawn_Round( ply )
	-- First player to join, start round
	if ( self.CurrentRoundState == self.RoundStates.Begin ) then
		self:RoundStart()
		return
	-- Only player on the server, reset and start
	elseif ( ( #player.GetAll() ) <= 2 ) then
		self:RoundReset()
		self:RoundStart()
		return
	end

	-- Any new joining players should not spawn mid round
	ply:SetDeaths( SkyView.Config.MaxLivesPerPlayer )

	-- Kill quitely after the base function spawns them
	timer.Simple( 0.1, function()
		ply:KillSilent()
	end )
end

function GM:RoundStart()
	self.CurrentRoundState = self.RoundStates.Progress

	for k, ply in pairs( player.GetAll() ) do
		-- Choose a random colour
		local col = GAMEMODE.PlayerColours[math.random( 1, #GAMEMODE.PlayerColours)]
			col = Vector( col.r / 255, col.g / 255, col.b / 255 )
		ply:SetPlayerColor( col )
	end
end

function GM:RoundEnd()
	self.CurrentRoundState = self.RoundStates.End

	-- Timer to reset the round and then start a new one
	timer.Simple( 5, function()
		GAMEMODE:RoundReset()
		GAMEMODE:RoundStart()
	end )
end

function GM:RoundReset()
	-- Reset the round and give all players max lives again
	for k, ply in pairs( player.GetAll() ) do
		ply:SetDeaths( 0 )
		ply:SetNWInt( "sky_score", 0 )
		ply:UnSpectate()
		ply.SpectatingNumber = nil
		ply:Spawn()
	end

	-- Cleanup the map
	game.CleanUpMap()
end

-- Player's have a limited number of lives each round, after which they become spectators
function GM:PlayerDeathThink( ply )
	if ( ply:Deaths() >= SkyView.Config.MaxLivesPerPlayer ) then
		if ( not ply.SpectatingNumber ) then
			for k, otherply in pairs( player.GetAll() ) do
				if ( ( ply ~= otherply ) and otherply:Alive() ) then
					ply:Spectate( OBS_MODE_IN_EYE )
					ply:SpectateEntity( otherply )
					break
				end
			end
			ply.SpectatingNumber = 1
		end
		return
	else
		ply:Spawn()
	end

	self.BaseClass:PlayerDeathThink( ply )
end

function GM:KeyPress_Round( ply, key )
	if ( ply.SpectatingNumber and ( key == IN_ATTACK ) ) then
		-- Find all possible players who could be spectated
		local possiblespectates = {}
			for k, otherply in pairs( player.GetAll() ) do
				if ( ( ply ~= otherply ) and otherply:Alive() ) then
					table.insert( possiblespectates, otherply )
				end
			end
		-- Change the currently spectated player
		ply.SpectatingNumber = ply.SpectatingNumber + 1
			if ( ply.SpectatingNumber > #possiblespectates ) then
				ply.SpectatingNumber = 1
			end
		ply:SpectateEntity( possiblespectates[ply.SpectatingNumber] )
	end
end

-- Check for round end conditions after each player death
hook.Add( "PlayerDeath", "SKY_Round_PlayerDeath", function()
	-- Find the remaining lives of every player
	local playersleft = 0
		for k, ply in pairs( player.GetAll() ) do
			if ( ply:Deaths() < SkyView.Config.MaxLivesPerPlayer ) then
				playersleft = playersleft + 1
			end
		end
	if ( ( ( #player.GetAll() > 1 ) and ( playersleft <= 1 ) ) or ( playersleft == 0 ) ) then
		GAMEMODE:RoundEnd()
	end
end )