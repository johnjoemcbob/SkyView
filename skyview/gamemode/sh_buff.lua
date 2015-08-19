-- Matthew Cormack (@johnjoemcbob)
-- 06/08/15
-- Buff/debuff shared information, contains the description of every buff
--
-- {
	-- Name = "Sheltered", -- Name for the tooltip
	-- Description = "Under shelter, protected from the elements.", -- Description for the tooltip
	-- Icon = "icon16/house.png", -- Icon to display as the buff's main visuals
	-- Time = 0, -- Times here are in seconds; NOTE - exactly 0.5 flags the client to display a quickly recurring buff (e.g. shelter)
	-- Team = TEAM_BOTH, -- Which team this buff/debuff should affect (TEAM_MONSTER,TEAM_HERO,TEAM_BOTH)
	-- Debuff = false, -- Whether or not this buff should be displayed as a negative buff (debuff)
	-- ThinkActivate = function( self, ply ) -- Run every frame to run logic on adding the buff to the player under certain conditions
		-- return true/false -- Whether or not the buff should be activated
	-- end,
	-- Init = function( self, ply ) -- Run when the buff is first added to the player
		
	-- end,
	-- Think = function( self, ply ) -- Run every frame the buff exists on the player
		
	-- end,
	-- Remove = function( self, ply ) -- Run when the buff is removed from the player
		
	-- end
-- }
--
-- If you want to continue using silk icons, a full list can be found in this image;
-- http://www.famfamfam.com/lab/icons/silk/previews/index_abc.png

GM.Buffs = {}

table.insert(
	GM.Buffs,
	{
		Name = "Hyperspeed",
		Description = "Travelling at super speed!",
		Icon = "icon16/lightning.png",
		Time = 15,
		Debuff = false,
		
		ThinkActivate = function( self, ply )
			
		end,
		Init = function( self, ply )
			GAMEMODE:SetPlayerSpeed(ply, 1800, 1700)
			print( ply:Name() .. " IS GOING VERY FASTER ")
			-- Play speedup noise
			ply:EmitSound("weapons/physcannon/physcannon_charge.wav", 75, 160, 1, CHAN_AUTO)
			ply.HasPowerup = true
		end,
		Think = function( self, ply )
		
		end,
		Remove = function( self, ply )
			GAMEMODE:SetPlayerSpeed(ply, 700, 600)
			print( ply:Name() .. " has calmed down.")
			-- Play slowdown noise
			ply:EmitSound("npc/manhack/bat_away.wav", 75, 75, 1, CHAN_AUTO)
			ply.HasPowerup = false
		end
	}
)
