-- Matthew Cormack (@johnjoemcbob)
-- 06/08/15
-- Buff/debuff serverside logic

util.AddNetworkString( "DC_Client_Buff" )

function SendClientBuffInformation( ply, id )
	-- Send the relevant information about this control point to any players within it
	net.Start( "DC_Client_Buff" )
		net.WriteFloat( tonumber( id or 0 ) )
		local timeout = 0
			if ( ply:GetBuff( id ) ) then
				timeout = ply:GetBuff( id ) - CurTime()
			end
		net.WriteFloat( tonumber( timeout ) )
	net.Send( ply )
end

local plymeta = FindMetaTable( "Player" )

function plymeta:AddBuff( id )
	if ( id <= 0 ) then return end
	if ( self.Ghost ) then return end
	if ( not self.Buffs ) then self.Buffs = {} end

	-- If the buff doesn't exist currently on the player, initialize it
	if ( not self:GetBuff( id ) ) then
		GAMEMODE.Buffs[id]:Init( self )
	end

	-- Flag as affecting this player
	self.Buffs[id] = CurTime() + GAMEMODE.Buffs[id].Time

	-- Send to client
	SendClientBuffInformation( self, id )
end

function plymeta:RemoveBuff( id )
	if ( id <= 0 ) then return end
	if ( not self.Buffs ) then self.Buffs = {} end

	-- Run the cleanup logic of this buff on the player
	if ( self:GetBuff( id ) ) then
		GAMEMODE.Buffs[id]:Remove( self )
	end

	-- Flag as not affecting this player
	self.Buffs[id] = nil

	-- Send to client
	SendClientBuffInformation( self, id )
end

function plymeta:GetBuff( id )
	if ( not self.Buffs ) then self.Buffs = {} end
	return self.Buffs[id]
end

function GM:PlayerInitialSpawn_Buff( ply )
	ply.Buffs = {}
end

function GM:Think_Buff()
	for k, ply in pairs( player.GetAll() ) do
		-- Run logic on every player and every buff to find if the buff should be added to that player
		for m, buff in pairs( self.Buffs ) do
			local add = buff:ThinkActivate( ply )
				if( add ) then
					-- Start the buff removal timer
					ply:AddBuff( m )
				end
		end

		-- Run logic on every buff currently active on the player for unique logic
		for m, buff in pairs( ply.Buffs ) do
			if ( buff ) then
				-- Buff still has time remaining to run logic
				if ( buff > CurTime() ) then
					-- Run the main buff logic on the player
					self.Buffs[m]:Think( ply )
				-- Time up on the buff, remove
				else
					-- Time up, remove timer
					ply:RemoveBuff( m )
				end
			end
		end
	end
end