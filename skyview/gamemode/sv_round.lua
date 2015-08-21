
-- Player's have a limited number of lives each round, after which they become spectators
function GM:PlayerDeathThink( ply )
	if ( ply:Deaths() >= SkyView.Config.MaxLivesPerPlayer ) then
		for k, otherply in pairs( player.GetAll() ) do
			if ( ( ply ~= otherply ) and otherply:Alive() ) then
				ply:Spectate( OBS_MODE_IN_EYE )
				ply:SpectateEntity( otherply )
				break
			end
		end
		return
	else
		ply:Spawn()
	end

	self.BaseClass:PlayerDeathThink( ply )
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
	if ( playersleft <= 1 ) then
		timer.Simple( 5, function()
			GAMEMODE:RoundReset()
		end )
	end
end )

function GM:RoundReset()
	-- Reset the round and give all players max lives again
	for k, ply in pairs( player.GetAll() ) do
		ply:SetDeaths( 0 )
		ply:SetFrags( 0 )
		ply:UnSpectate()
		ply:Spawn()
	end

	-- Cleanup the map
	game.CleanUpMap()
end