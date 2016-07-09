include( "shared.lua" )
include( "shared/sh_config.lua" )
include( "cl_stats.lua" )
include( "cl_scoreboard.lua" )
include( "cl_deathnotice.lua" )

surface.CreateFont( "skyview_firstplayerfont", {
	font = "Droid Sans Mono",
	size = ScreenScale(50),
	shadow = true,
	bold = true
} )

surface.CreateFont( "skyview_firstplayerfont2", {
	font = "Droid Sans Mono",
	size = ScreenScale(15),
	shadow = true,
	bold = true
} )

surface.CreateFont( "skyview_noticefont", {
	font = "Impact",
	size = ScreenScale(16),
	shadow = true,
	bold = true
} )

surface.CreateFont( "skyview_scorefont", {
	font = "Impact",
	size = ScreenScale(30),
	shadow = true,
	bold = true
} )

surface.CreateFont( "skyview_chartfont", {
	font = "Impact",
	size = ScreenScale(8),
	shadow = false,
	bold = true
} )

local myView = 90
local LastDisplayedScore = 0
local ScoreShake = 0

local StatPieLerpTime = 0
local LastMusicStartTime = CurTime() + 100
MusicEnabled = false

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

function GM:InitPostEntity()
	-- Store on the player so that it doesn't fail on hot reload
	LocalPlayer().Sound_Music_Intro = CreateSound( LocalPlayer(), "skyview/music/intro.mp3" )
	LocalPlayer().Sound_Music_Loop = CreateSound( LocalPlayer(), "skyview/music/loop.mp3" )
	LocalPlayer().Sound_Music_Outro = CreateSound( LocalPlayer(), "skyview/music/outro.mp3" )
end

function GM:PlayMusic( message )
	message = string.lower( message )

	if ( MusicEnabled ) then
		-- Play intro
		if ( string.find( message, "begin" ) ) then
			if ( not LocalPlayer().Sound_Music_Intro:IsPlaying() ) then
				self:PlayMusicTrack( LocalPlayer().Sound_Music_Intro )
			end
		-- Play outro
		elseif ( string.find( message, "wins" ) ) then
			if ( not LocalPlayer().Sound_Music_Outro:IsPlaying() ) then
				self:PlayMusicTrack( LocalPlayer().Sound_Music_Outro )
			end
		-- Play loop
		else
			-- Isn't still playing the intro, and
			-- Isn't playing the loop effect
			-- OR Time for the loop to loop
			if (
				(
					( not LocalPlayer().Sound_Music_Intro:IsPlaying() ) and
					( not LocalPlayer().Sound_Music_Loop:IsPlaying() )
				) or
				( CurTime() >= ( LastMusicStartTime + self:GetCurrentMusicTrackLength() ) )
			) then
				self:PlayMusicTrack( LocalPlayer().Sound_Music_Loop )
			end
		end
	end
end

function GM:PlayMusicTrack( track )
	-- Stop all tracks
	LocalPlayer().Sound_Music_Intro:Stop()
	LocalPlayer().Sound_Music_Loop:Stop()
	LocalPlayer().Sound_Music_Outro:Stop()

	-- Play the required track, and store the time started for switching to the next track/looping
	track:Play()
	LastMusicStartTime = CurTime()
end

-- Professional
function GM:GetCurrentMusicTrackLength()
	-- Intro
	if ( LocalPlayer().Sound_Music_Intro:IsPlaying() ) then
		return 22
	-- Loop
	elseif ( LocalPlayer().Sound_Music_Loop:IsPlaying() ) then
		return 46.3
	-- Outro
	else
		return 15
	end
end

function GM:HUDShouldDraw( name )
	if ( name == "CHudHealth" ) then 
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
	self:PlayMusic( textround )

	-- Display the spectatee name text
	width, height = surface.GetTextSize( textspectatee )
	y = ScrH() / 12 * 10
	draw.TextRotated( textspectatee, x, y - ( height / 2 ), Color( 255, 255, 255 ), font, 0 )

	-- Draw stats on game end
	self:HUDPaint_Stats()
end

function GM:HUDPaint_Stats()
	-- Only display on round end
	local textround = LocalPlayer():GetNWString( "sky_round" )
	if ( not string.find( textround, "Wins!" ) ) then
		-- Reset lerp stat in timer
		StatPieLerpTime = 0
		return
	end

	-- Increment lerp time
	StatPieLerpTime = StatPieLerpTime + ( FrameTime() * 0.7 )

	-- Calculate once
	-- Count the number of stats to display, to find positioning of charts

	-- Display pie segments
	-- Find the total number of each stat
	-- Store the current segment rotation around the circle
	-- Divide the current stat by the max stat for segment size
	local chartoffx = ScrW() / ( #self.RoundEndStats + 1 )
	local chartoffy = 0
	local chartx = chartoffx --0
	local charty = ScrH() / 2 --0
	local chartradius = ScrH() / 4
	local chartthick = chartradius / 3
	local chartmargin = 0.1
	local chartdetail = 150
	for k, stat in pairs( self.RoundEndStats ) do
		local segmentoffset = 0
		local seg = 0
		local totalstat = 0
			for model, info in pairs( self.PropDescriptions ) do
				if ( info[stat] ) then
					totalstat = totalstat + info[stat]
				end
			end
		for model, info in pairs( self.PropDescriptions ) do
			if ( info[stat] and ( info[stat] ~= 0 ) ) then
				local statmargin = chartmargin
					-- Don't use a margin if there is only one prop with the stat
					if ( info[stat] == totalstat ) then
						statmargin = 0
					end
				local multiplier = info[stat] / totalstat
				local segsize = 100 * multiplier
					local timelerp = math.Clamp( StatPieLerpTime + ( 0.01 * seg ), 0, 0.5 )
					-- Calculate angle by the percentage of the circumference that has been travelled (-45 for offset of segments not starting at x0 ymax)
					local segmid = ( ( segmentoffset + ( segsize / 2 ) ) )
					local cirmid = segmid / 100 * 360
					local ang = cirmid
						-- Always upright
						if ( ( ang > 90 ) and ( ang < 270 ) ) then
							ang = ang - 180
						end
					local radius = chartradius * timelerp
					local thickness = chartthick * timelerp

					-- Calculate segments and store in shapes to draw after stenciling (text needs the position from this function first)
					local x, y, shapes = draw.CircleSegment( chartx, charty, radius, chartdetail, thickness, segmentoffset + ( statmargin / 2 ), segsize - statmargin, true )

					-- Draw circle segmentl
					render.SetStencilCompareFunction( STENCILCOMPARISONFUNCTION_EQUAL )
					render.SetStencilPassOperation( STENCILOPERATION_REPLACE )
					surface.SetDrawColor( Color( info[3].r, info[3].g, info[3].b, 255 * ( timelerp + 0.5 ) ) )
					for k, cir in pairs( shapes ) do
						surface.DrawPoly( cir )
					end

					-- Draw text
					local offset = segmentoffset + ( statmargin / 2 )
					local currentseg = segmid + segsize - ( statmargin / 2 )
					local seg = chartdetail
					local a = math.rad( ( ( currentseg / seg ) * -360 ) )
					x = chartx + math.sin( a ) * ( radius - thickness )
					y = charty + math.cos( a ) * ( radius - thickness )
					draw.TextRotatedNoShadow( info[2], x, y, Color( 255, 255, 255, 255 * ( timelerp + 0.5 ) ), "skyview_chartfont", ang )
				segmentoffset = segmentoffset + segsize
				seg = seg + 1
			end
		end
		chartx = chartx + chartoffx
	end
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
	DrawColorModify( tab )
end

-- From http://wiki.garrysmod.com/page/surface/DrawPoly
function draw.Circle( x, y, radius, seg )
	local cir = {}

	table.insert( cir, { x = x, y = y, u = 0.5, v = 0.5 } )
	for i = 0, seg do
		local a = math.rad( ( i / seg ) * -360 )
		table.insert( cir, { x = x + math.sin( a ) * radius, y = y + math.cos( a ) * radius, u = math.sin( a ) / 2 + 0.5, v = math.cos( a ) / 2 + 0.5 } )
	end

	local a = math.rad( 0 ) -- This is need for non absolute segment counts
	table.insert( cir, { x = x + math.sin( a ) * radius, y = y + math.cos( a ) * radius, u = math.sin( a ) / 2 + 0.5, v = math.cos( a ) / 2 + 0.5 } )

	surface.DrawPoly( cir )
end

function draw.CircleSegment( x, y, radius, seg, thickness, offset, percent, drawlater )
	if ( thickness == 0 ) then
		return draw.Circle( x, y, radius, seg )
	end

	local shapes = {}

	local minseg = seg * offset / 100
	local maxseg = seg * ( percent + offset ) / 100
	local numsegrow = maxseg - minseg + 1 -- Extra one each row

	local cirtotal, cirtotalx, cirtotaly = 0, 0, 0

	for currentseg = minseg, maxseg - 1 do
		local cir = {}
			-- 1
			local a = math.rad( ( ( currentseg / seg ) * -360 ) )
			table.insert( cir, {
				x = x + math.sin( a ) * ( radius - thickness ),
				y = y + math.cos( a ) * ( radius - thickness ),
				u = math.sin( a ) / 2 + 0.5,
				v = math.cos( a ) / 2 + 0.5
			} )
				cirtotalx = cirtotalx + cir[#cir].x
				cirtotaly = cirtotaly + cir[#cir].y
				cirtotal = cirtotal + 1
			-- 3
			local a = math.rad( ( ( currentseg / seg ) * -360 ) )
			table.insert( cir, {
				x = x + math.sin( a ) * ( radius ),
				y = y + math.cos( a ) * ( radius ),
				u = math.sin( a ) / 2 + 0.5,
				v = math.cos( a ) / 2 + 0.5
			} )
				cirtotalx = cirtotalx + cir[#cir].x
				cirtotaly = cirtotaly + cir[#cir].y
				cirtotal = cirtotal + 1
			-- 4
			local a = math.rad( ( ( ( currentseg + 1 ) / seg ) * -360 ) )
			table.insert( cir, {
				x = x + math.sin( a ) * ( radius ),
				y = y + math.cos( a ) * ( radius ),
				u = math.sin( a ) / 2 + 0.5,
				v = math.cos( a ) / 2 + 0.5
			} )
				cirtotalx = cirtotalx + cir[#cir].x
				cirtotaly = cirtotaly + cir[#cir].y
				cirtotal = cirtotal + 1

			-- 1
			local a = math.rad( ( ( currentseg / seg ) * -360 ) )
			table.insert( cir, {
				x = x + math.sin( a ) * ( radius - thickness ),
				y = y + math.cos( a ) * ( radius - thickness ),
				u = math.sin( a ) / 2 + 0.5,
				v = math.cos( a ) / 2 + 0.5
			} )
			-- 4
			local a = math.rad( ( ( ( currentseg + 1 ) / seg ) * -360 ) )
			table.insert( cir, {
				x = x + math.sin( a ) * ( radius ),
				y = y + math.cos( a ) * ( radius ),
				u = math.sin( a ) / 2 + 0.5,
				v = math.cos( a ) / 2 + 0.5
			} )
			-- 2
			local a = math.rad( ( ( ( currentseg + 1 ) / seg ) * -360 ) )
			table.insert( cir, {
				x = x + math.sin( a ) * ( radius - thickness ),
				y = y + math.cos( a ) * ( radius - thickness ),
				u = math.sin( a ) / 2 + 0.5,
				v = math.cos( a ) / 2 + 0.5
			} )
				cirtotalx = cirtotalx + cir[#cir].x
				cirtotaly = cirtotaly + cir[#cir].y
				cirtotal = cirtotal + 1
		if ( not drawlater ) then
			surface.DrawPoly( cir )
		else
			table.insert( shapes, cir )
		end
	end

	local centerx, centery
		centerx = cirtotalx / cirtotal
		centery = cirtotaly / cirtotal
	return centerx, centery, shapes
	-- local a = math.rad( ( ( minseg / seg ) * -360 ) )
	-- return ( x + math.sin( a ) * ( radius - thickness ) ), ( y + math.cos( a ) * ( radius - thickness ) )
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

-- From http://wiki.garrysmod.com/page/cam/PushModelMatrix
function draw.TextRotatedNoShadow( text, x, y, color, font, ang )
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
		draw.Text(
			{
				text = text,
				font = font,
				pos = { 0, 0 },
				xalign = 0,
				yalign = 4,
				color = color
			}
		)
	cam.PopModelMatrix()
	render.PopFilterMag()
	render.PopFilterMin()
end