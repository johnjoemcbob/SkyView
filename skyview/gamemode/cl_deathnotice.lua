include( "vgui_gamenotice.lua" )

local function CreateDeathNotify()
	local x, y = ScrW(), ScrH()

	g_DeathNotify = vgui.Create( "DNotify" )
	
	g_DeathNotify:SetPos( 0, 25 )
	g_DeathNotify:SetSize( x - ( 25 ), y )
	g_DeathNotify:SetAlignment( 9 )
	g_DeathNotify:SetSkin( GAMEMODE.HudSkin )
	g_DeathNotify:SetLife( 4 )
	g_DeathNotify:ParentToHUD()
end
hook.Add( "InitPostEntity", "CreateDeathNotify", CreateDeathNotify )

local function RecvPlayerAction( length )
	local ply 		= net.ReadEntity()
	local action 	= net.ReadString()
	local sound 	= net.ReadString()

	if ( not IsValid( ply ) ) then return end

	if ( string.len( action ) ~= 0 ) then
		GAMEMODE:AddPlayerAction( ply, action )
	end

	if ( string.len( sound ) ~= 0 ) then
		surface.PlaySound( sound )
	end
end
net.Receive( "PlayerAction", RecvPlayerAction )

function GM:AddPlayerAction( ply, ... )
	if ( !IsValid( g_DeathNotify ) ) then return end

	local pnl = vgui.Create( "GameNotice", g_DeathNotify )
		for k, v in ipairs({...}) do
			pnl:AddText( v )
		end
		pnl.Player = ply
	g_DeathNotify:AddItem( pnl )
end