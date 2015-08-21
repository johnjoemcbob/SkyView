include( "vgui_gamenotice.lua" )

local Sound_OrchestraHit = Sound( "skyview/orch.wav" )

local BasePitch = 60
local MaxPitch = 200
local CurrentOrchPitch = BasePitch
local NextPitchDown = nil

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

hook.Add( "Think", "SKY_Notice_Think", function()
	if ( NextPitchDown and ( CurTime() > NextPitchDown ) ) then
		CurrentOrchPitch = BasePitch
		NextPitchDown = nil
	end
end )

local function RecvPlayerAction( length )
	local ply 		= net.ReadEntity()
	local action 	= net.ReadString()
	local soundfile	= net.ReadString()

	if ( not IsValid( ply ) ) then return end

	if ( string.len( action ) ~= 0 ) then
		GAMEMODE:AddPlayerAction( ply, action )

		-- Up pitch and play orchestra hit
		CurrentOrchPitch = math.Clamp( CurrentOrchPitch + 5, BasePitch, MaxPitch )
		sound.Play( Sound_OrchestraHit, LocalPlayer():EyePos(), 150, CurrentOrchPitch )
		NextPitchDown = CurTime() + 5
		--surface.PlaySound( "skyview/orch.wav" )
	end

	if ( string.len( soundfile ) ~= 0 ) then
		timer.Simple( 0.2, function()
			--surface.PlaySound( soundfile )
		end )
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