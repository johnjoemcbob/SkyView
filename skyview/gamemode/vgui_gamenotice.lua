-- client cvars to control deathmsgs
local hud_deathnotice_time = CreateClientConVar( "hud_deathnotice_time", "6", true, false )
local hud_deathnotice_limit = CreateClientConVar( "hud_deathnotice_limit", "5", true, false )

local Material_BrushStroke = Material( "skyview/brushstroke" )

--[[
	This is the player death panel. This should be parented to a DeathMessage_Panel. The DeathMessage_Panel that
	it's parented to controls aspects such as the position on screen. All this panel's job is to print the
	specific death it's been given and fade out before its RetireTime.
]]

local PANEL = {}

Derma_Hook( PANEL, 	"Paint", 				"Paint", 	"GameNotice" )
Derma_Hook( PANEL, 	"ApplySchemeSettings", 	"Scheme", 	"GameNotice" )
Derma_Hook( PANEL, 	"PerformLayout", 		"Layout", 	"GameNotice" )

function PANEL:Init()
	self.m_bHighlight = false
	self.Padding = 32
	self.Spacing = 8
	self.Items = {}
end

function PANEL:AddEntityText( txt )

	if ( type( txt ) == "string" ) then return false end
	
	if ( type( txt ) == "Player" ) then 
	
		self:AddText( txt:Nick(), GAMEMODE:GetTeamColor( txt ) )
		if ( txt == LocalPlayer() ) then self.m_bHighlight = true end
		
		return true
		
	end

	if( txt:IsValid() ) then
		self:AddText( txt:GetClass(), GAMEMODE.DeathNoticeDefaultColor )	
	else
		self:AddText( tostring( txt ) )	
	end

end

function PANEL:AddItem( item )

	table.insert( self.Items, item )
	self:InvalidateLayout( true )
	
end

function PANEL:AddText( txt, color )

	if ( self:AddEntityText( txt ) ) then return end
	
	local txt = tostring( txt )
	
	local lbl = vgui.Create( "DLabel", self )
	
	Derma_Hook( lbl, 	"ApplySchemeSettings", 	"Scheme", 	"GameNoticeLabel" )
	lbl:ApplySchemeSettings()
	lbl:SetText( txt )
	lbl:SetFont( "CloseCaption_Bold" )
	
	if( string.Left( txt , 1 ) == "#" && !color ) then color = GAMEMODE.DeathNoticeDefaultColor end // localised ent death
	if( GAMEMODE.DeathNoticeTextColor && !color ) then color = GAMEMODE.DeathNoticeTextColor end // something else
	if ( !color ) then color = color_white end
	
	lbl:SetTextColor( color )
	
	self:AddItem( lbl )

end

function PANEL:AddIcon( txt )

	if ( killicon.Exists( txt ) ) then

		local icon = vgui.Create( "DKillIcon", self )
			icon:SetName( txt )
			icon:SizeToContents()

		self:AddItem( icon )

	elseif ( ( txt == "sky_physprop" ) or ( txt == "prop_physics" ) ) then

		local icon = vgui.Create( "SpawnIcon", self )
			icon:SetModel( txt )
			icon:SizeToContents()

		self:AddItem( icon )

	else

		self:AddText( "killed" )

	end

end

function PANEL:PerformLayout()

	local x = self.Padding
	local height = self.Padding * 0.5
	
	for k, v in pairs( self.Items ) do
	
		v:SetPos( x, self.Padding * 0.5 )
		v:SizeToContents()
		
		x = x + v:GetWide() + self.Spacing
		height = math.max( height, v:GetTall() + self.Padding )
	
	end
	
	self:SetSize( x + self.Padding, height )
	
end

function PANEL:Paint( w, h )
	self.Progress = math.Clamp( ( self.Progress or 0 ) + FrameTime() * w * 4, 0, 400 )

	-- Setup the stencil for drawing the paint stroke as it proceeds on the width variable
	render.ClearStencil()
	render.SetStencilEnable( true )
	render.SetStencilPassOperation( STENCIL_REPLACE )
	render.SetStencilFailOperation( STENCIL_KEEP )
	render.SetStencilZFailOperation( STENCIL_KEEP )
	render.SetStencilWriteMask( 1 )
	render.SetStencilTestMask( 1 )
	render.SetStencilReferenceValue( 1 )

	-- Render to mask
	render.SetStencilCompareFunction( STENCIL_ALWAYS )

	surface.SetDrawColor( Color( 255, 255, 255, 255 ) )
	surface.SetMaterial( Material_BrushStroke )
	surface.DrawTexturedRect( 0, 0, w / 100 * math.Clamp( self.Progress, 0, 100 ), h )

	-- Render to screen
	render.SetStencilCompareFunction( STENCIL_EQUAL )

	surface.SetDrawColor( 50, 155, 50, 255 )
	surface.SetMaterial( Material_BrushStroke )
	surface.DrawTexturedRect( 0, 0, w, h )
end

derma.DefineControl( "GameNotice", "", PANEL, "DPanel" )