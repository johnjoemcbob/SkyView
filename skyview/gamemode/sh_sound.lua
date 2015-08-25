-- Matthew Cormack (@johnjoemcbob)
-- 25/08/15
-- A list of sounds for use with stat events
--
-- The chance variable of each possible clip is added together to find the
-- division ratio

GM.Sounds = {}

GM.Sounds["round_begin"] =
{
	{
		File = "skyview/announcer/go.mp3",
		Chance = 50,
		MinIncrement = 0
	},
	{
		File = "skyview/announcer/start.mp3",
		Chance = 50,
		MinIncrement = 0
	}
}
GM.Sounds["round_end"] =
{
	{
		File = "skyview/announcer/game_over.mp3",
		Chance = 50,
		MinIncrement = 0
	},
	{
		File = "skyview/announcer/stop.mp3",
		Chance = 50,
		MinIncrement = 0
	}
}
GM.Sounds["near_miss"] =
{
	{
		File = "skyview/announcer/near_miss.mp3",
		Chance = 90,
		MinIncrement = 0
	},
	{
		File = "skyview/announcer/salty.mp3",
		Chance = 10,
		MinIncrement = 5
	}
}
GM.Sounds["grapple_hitsky"] =
{
	{
		File = "skyview/announcer/its_the_skybox.mp3",
		Chance = 1,
		MinIncrement = 0
	},
	{
		File = "skyview/announcer/its_not_real.mp3",
		Chance = 1,
		MinIncrement = 1
	},
	{
		File = "skyview/announcer/you_cant_grapple_air.mp3",
		Chance = 1,
		MinIncrement = 2
	},
	{
		File = "skyview/announcer/its_air.mp3",
		Chance = 1,
		MinIncrement = 3
	},
	{
		File = "skyview/announcer/just_air.mp3",
		Chance = 1,
		MinIncrement = 4
	}
}

-- Must be last, add all sounds declared here to the auto download
if ( SERVER ) then
	for k, soundid in pairs( GM.Sounds ) do
		for _, sound in pairs( soundid ) do
			resource.AddFile( sound.File )
		end
	end
end