include("shared.lua")
include("shared/sh_config.lua")
include( "cl_scoreboard.lua" )
include( "cl_deathnotice.lua" )

surface.CreateFont("skyview_firstplayerfont", {
	font = "Droid Sans Mono",
	size = ScreenScale(50),
	shadow = true,
	bold = true
} )

surface.CreateFont("skyview_firstplayerfont2", {
	font = "Droid Sans Mono",
	size = ScreenScale(15),
	shadow = true,
	bold = true
} )

surface.CreateFont("skyview_noticefont", {
	font = "Impact",
	size = ScreenScale(16),
	shadow = true,
	bold = true
} )

surface.CreateFont("skyview_scorefont", {
	font = "Impact",
	size = ScreenScale(30),
	shadow = true,
	bold = true
} )

local myView = 90
local LastDisplayedScore = 0
local ScoreShake = 0

net.Receive("skyview_firstplayerscreen", function(ply)
	local FirstScreenMenu = vgui.Create("DFrame")
	FirstScreenMenu:SetPos(0, 0)
	FirstScreenMenu:SetTitle("")
	FirstScreenMenu:SetSize(ScrW(), ScrH())
	FirstScreenMenu:ShowCloseButton(false)
	FirstScreenMenu:MakePopup()
	FirstScreenMenu.Paint = function() 
		draw.RoundedBox(2, 0, 0, ScrW(), ScrH(), Color(20, 20, 20, 255))
	end 

	local firstTextDone = false 
	local FirstScreenText = vgui.Create("DLabel", FirstScreenMenu)
	FirstScreenText:SetPos(0, ScrH()/4)
	FirstScreenText.Think = function()
		local myposX, myposY = FirstScreenText:GetPos()
		if(myposX < ScrW()/2.6) then 
			FirstScreenText:SetPos(myposX+6, myposY)
		elseif(myposX >= ScrW()/2.6) then
			firstTextDone = true 
		end 
	end

	FirstScreenText:SetText("Welcome to SkyView")
	FirstScreenText:SetFont("skyview_firstplayerfont")
	FirstScreenText:SetTextColor(Color(255, 255, 255))
	FirstScreenText:SizeToContents()

	--ScrH()/2.7
	local readybutton_exist = false 
	local FirstScreenText2 = vgui.Create("DLabel", FirstScreenMenu)
	FirstScreenText2:SetPos(-500, ScrH()/2.8)
	FirstScreenText2:SetText("A game about shooting objects at your enemy")
	FirstScreenText2.Think = function()
		local myposX, myposY = FirstScreenText2:GetPos()
		if firstTextDone then 
			if(myposX < ScrW()/2.6) then 
				FirstScreenText2:SetPos(myposX+7, myposY)
			elseif(myposX >= ScrW()/2.6) then 
				timer.Simple(1.5, function()
					if (!readybutton_exist) then
						readybutton_exist = true 
						local ReadyButton = vgui.Create("DButton", FirstScreenMenu)
						ReadyButton:SetPos(ScrW()/2, ScrH()/2.2)
						ReadyButton:SetFont("skyview_firstplayerfont2")
						ReadyButton:SetWide(ScrW()/6)
						ReadyButton:SetTall(ScrH()/12)
						ReadyButton:SetText("Ready")
						ReadyButton:SetTextColor(Color(255, 255, 255, 255))
						local r_ReadyButton = 0
						local max_ReadyButton = 255
						local goUp_ReadyButton = true 
						local goDown_ReadyButton = false 
						ReadyButton.Paint = function()
							if(r_ReadyButton >= max_ReadyButton && goUp_ReadyButton) then 
								goDown_ReadyButton = true 
								goUp_ReadyButton = false 
							elseif(r_ReadyButton <= 0 && goDown_ReadyButton) then 
								goUp_ReadyButton = true 
								goDown_ReadyButton = false 
							end 
							if(goUp_ReadyButton) then 
								r_ReadyButton = r_ReadyButton + 1
							elseif(goDown_ReadyButton) then 
								r_ReadyButton = r_ReadyButton - 1
							end
							surface.SetDrawColor(r_ReadyButton, 0, 0, 255)
							ReadyButton:DrawOutlinedRect()
						end
						ReadyButton.DoClick = function()
							FirstScreenMenu:Close()
						end
					end
				end )
			end
		end
	end
	FirstScreenText2:SetFont("skyview_firstplayerfont2")
	FirstScreenText2:SetTextColor(Color(109, 34, 206))
	FirstScreenText2:SizeToContents()
end )

if !SkyView.Config.FirstPerson then
	function GM:CalcView(ply, pos, angles, fov)
		local view = {}
		local trace_area = {}
		trace_area.start = ply:EyePos()
		trace_area.endpos = ply:EyePos()+Vector(0, 0, 600)
		trace_area.filter = ply 
		local trace = util.TraceLine(trace_area)
		local hitPos = trace.HitPos 
		hitPos.z = hitPos.z*0.95
		view.origin = Vector(hitPos.x, hitPos.y, hitPos.z)
		local angles = ply:GetAngles()
		view.angles = Angle(90, math.NormalizeAngle(angles.y), math.NormalizeAngle(angles.z))
		view.fov = fov

		return view
	end
	function GM:ShouldDrawLocalPlayer()
		return true 
	end
end

hook.Add( "PreDrawHalos", "SKY_PreDrawHalos", function()
	if ( SkyView.Config.ShowHalos ) then
		for k, ply in pairs( player.GetAll() ) do
			if ( not ply:Alive() ) then continue end

			halo.Add( { ply }, Color( 150, 150, 255 ), 5, 5, 2, true, true )
			local col = ply:GetPlayerColor()
				col = Color( col.x * 255, col.y * 255, col.z * 255 )
			halo.Add( { ply }, col, 1, 1, 2, true, true )
		end
		halo.Add( ents.FindByClass( "sky_grapple" ), Color( 150, 150, 255 ), 5, 5, 2, true, true )
		for k, ent in pairs( ents.FindByClass( "sky_grapple" ) ) do
			halo.Add( { ent }, ent:GetColor(), 1, 1, 2, true, true )
		end
	end
end )


function GM:HUDShouldDraw(name)
	if name == "CHudHealth" then 
		return false 
	end 
	return true 
end 

function GM:HUDPaint()
	local padding = 16
	local x = ScrW() / 2
	local y = ScrH() / 16

	-- Find the required width for the score text
	local font = "skyview_scorefont"
	local text = LocalPlayer():GetNWInt( "sky_score" )
	local textspectatee = LocalPlayer():GetNWString( "sky_spectatee" )
	local textround = LocalPlayer():GetNWString( "sky_round" )
	if ( text ~= LastDisplayedScore ) then
		ScoreShake = 100
		LastDisplayedScore = text
	else
		ScoreShake = math.max( ScoreShake - 3, 0 )
	end
	surface.SetFont( font )

	-- Display the score text
	local width, height = surface.GetTextSize( text )
	local col = LocalPlayer():GetPlayerColor()
		col = Color( col.x * 255, col.y * 255, col.z * 255 )
	draw.TextRotated( text, x, y - ( height / 2 ), col, font, math.sin( CurTime() * ScoreShake ) * 30 )

	-- Display the round status text
	width, height = surface.GetTextSize( textround )
	y = ScrH() / 7
	draw.TextRotated( textround, x, y - ( height / 2 ), Color( 255, 255, 255 ), font, 0 )

	-- Display the spectatee name text
	width, height = surface.GetTextSize( textspectatee )
	y = ScrH() / 12 * 10
	draw.TextRotated( textspectatee, x, y - ( height / 2 ), Color( 255, 255, 255 ), font, 0 )
end

function GM:RenderScreenspaceEffects()
	local tab = {}
	tab[ "$pp_colour_addr" ] = 0
	tab[ "$pp_colour_addg" ] = 0
	tab[ "$pp_colour_addb" ] = 0
	tab[ "$pp_colour_brightness" ] = 0
	tab[ "$pp_colour_contrast" ] = 1
	tab[ "$pp_colour_colour" ] = 1
	tab[ "$pp_colour_mulr" ] = 0
	tab[ "$pp_colour_mulg" ] = 1
	tab[ "$pp_colour_mulb" ] = 1 
	DrawColorModify(tab)
end 

-- From http://wiki.garrysmod.com/page/cam/PushModelMatrix
function draw.TextRotated( text, x, y, color, font, ang )
	render.PushFilterMag( TEXFILTER.ANISOTROPIC )
	render.PushFilterMin( TEXFILTER.ANISOTROPIC )
	surface.SetFont( font )
	surface.SetTextColor( color )
	surface.SetTextPos( 0, 0 )
	local textWidth, textHeight = surface.GetTextSize( text )
	local rad = -math.rad( ang )
	x = x - ( math.cos( rad ) * textWidth / 2 + math.sin( rad ) * textHeight / 2 )
	y = y + ( math.sin( rad ) * textWidth / 2 + math.cos( rad ) * textHeight / 2 )
	local m = Matrix()
	m:SetAngles( Angle( 0, ang, 0 ) )
	m:SetTranslation( Vector( x, y, 0 ) )
	cam.PushModelMatrix( m )
		draw.TextShadow(
			{
				text = text,
				font = font,
				pos = { 0, 0 },
				xalign = 0,
				yalign = 4,
				color = color
			},
			2,
			255
		)
	cam.PopModelMatrix()
	render.PopFilterMag()
	render.PopFilterMin()
end