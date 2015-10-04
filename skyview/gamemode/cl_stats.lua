-- Matthew Cormack (@johnjoemcbob)
-- 04/10/15
-- Stat tracking clientside net receive

local function Receive_Stats_Server( length )
	local stats = net.ReadTable()
	for model, info in pairs( stats ) do
		for statkey, statval in pairs( info ) do
			GAMEMODE.PropDescriptions[model][statkey] = statval
		end
	end
end
net.Receive( "Stats_Server", Receive_Stats_Server )