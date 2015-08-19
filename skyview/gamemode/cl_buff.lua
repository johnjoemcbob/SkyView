-- Matthew Cormack (@johnjoemcbob)
-- 06/08/15
-- Buff/debuff clientside hud visuals
-- Including icon/progress bar for each buff with hover-over descriptions

local Buffs = {}

-- Initialization of this message is contained within sv_buff.lua
net.Receive( "DC_Client_Buff", function( len )
	local id = net.ReadFloat()
	Buffs[id] = net.ReadFloat()

	-- If the buff still exists on the player, use clientside CurTime for visual progress decrease
	if ( Buffs[id] > 0 ) then
		Buffs[id] = Buffs[id] + CurTime()
	end
end )

function GM:Initialize_Buffs()
	-- Create a material cache for each icon
	for k, v in pairs( self.Buffs ) do
		v.Material = Material( v.Icon )
	end
end

function GM:HUDPaint_Buffs()
	if ( LocalPlayer().Ghost ) then return end

	local x = 0
	local y = ScrH() / 4
	local size = ScrH() / 20
	for k, v in pairs( Buffs ) do
		if ( v and ( v > 0 ) ) then
			local activetime = v - CurTime()
				-- Flag set in some buffs to never visually decrease progress
				if ( self.Buffs[k].Time == 0.5 ) then
					activetime = self.Buffs[k].Time
				end
			if ( activetime > 0 ) then
				-- Backdrop
				surface.SetDrawColor( 181, 140, 50, 200 )
				surface.DrawRect( x, y, size, size )

				-- Progress green/red bar
				surface.SetDrawColor( 0, 255, 0, 150 )
					if ( self.Buffs[k].Debuff ) then
						surface.SetDrawColor( 255, 0, 0, 150 )
					end
				surface.DrawRect( x, y, size / self.Buffs[k].Time * activetime, size )

				-- Icon
				surface.SetDrawColor( 255, 255, 255, 255 )
				surface.SetMaterial( self.Buffs[k].Material	)
				surface.DrawTexturedRect( x, y, size, size )

				-- Display description if the context menu is open and the player is hovering over this buff
				if (
					vgui.CursorVisible() and
					( ( gui.MouseX() >= x ) and ( gui.MouseX() <= ( x + size ) ) ) and
					( ( gui.MouseY() >= y ) and ( gui.MouseY() <= ( y + size ) ) )
				) then
					-- Start position of the description box
					local dx = gui.MouseX() + ( size / 4 )
					local dy = gui.MouseY() + ( size / 4 )

					-- Backdrop
					surface.SetDrawColor( 181, 140, 50, 200 )
					surface.DrawRect( dx, dy, size * 6, size * 2 )

					-- Start the text display a little in from the top left border
					dx = dx + ( size / 5 )
					dy = dy + ( size / 5 )

					-- Name of this buff
					local textcolour = Color( 100, 200, 255, 255 )
						if ( self.Buffs[k].Debuff ) then
							textcolour = Color( 255, 100, 100, 255 )
						end
					draw.DrawText( self.Buffs[k].Name, "TargetID", dx, dy, textcolour, TEXT_ALIGN_LEFT )

					-- Progress of this buff
					local textcolour = Color( 200, 255, 20, 255 )
					local progress = activetime
						if ( progress == 0.5 ) then
							progress = "Recurring"
						else
							progress = math.Round( progress ) .. "s"
						end
					draw.DrawText( progress, "TargetID", dx + ( size * 6 ) - ( size * 4 / 10 ), dy, textcolour, TEXT_ALIGN_RIGHT )

					-- Move down a line for description
					dy = dy + ( size / 2 )

					-- Description of this buff
					local textcolour = Color( 255, 255, 255, 255 )
					draw.DrawText( self.Buffs[k].Description, "TargetID", dx, dy, textcolour, TEXT_ALIGN_LEFT )
				end

				-- Move next buff visual downward
				y = y + ScrH() / 16
			end
		end
	end
end