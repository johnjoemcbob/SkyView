GM.Name = "SkyView"
GM.Author = "Tyguy"
GM.Email = "N/A"
GM.Website = "N/A"

include( "sh_stats.lua" )
include( "sh_sound.lua" )

-- Fire-able props
GM.PropDescriptions =
{
	["models/props_c17/FurnitureBathtub001a.mdl"] = { 1, "Bath", Color( 39, 174, 96 ) },
	["models/props_borealis/bluebarrel001.mdl"] = { 2, "Barrel", Color( 155, 89, 182 ) },
	["models/props_c17/furnitureStove001a.mdl"] = { 3, "Stove", Color( 41, 128, 185 ) },
	["models/props_c17/FurnitureFridge001a.mdl"] = { 4, "Fridge", Color( 52, 73, 94 ) },
	["models/props_c17/oildrum001.mdl"] = { 1, "Oil Drum", Color( 22, 160, 133 ) },
	["models/props_c17/oildrum001_explosive.mdl"] = { 1, "Explosive Drum", Color( 230, 126, 34 ) },
	["models/props_junk/PlasticCrate01a.mdl"] = { 1, "Crate", Color( 231, 76, 60 ) },
	["models/props_c17/FurnitureSink001a.mdl"] = { 1, "Sink", Color( 26, 188, 156 ) },
	["models/props_c17/FurnitureCouch001a.mdl"] = { 1, "Couch", Color( 46, 204, 113 ) },
	["models/Combine_Helicopter/helicopter_bomb01.mdl"] = { 1, "Bomb", Color( 52, 152, 219 ) },
	["models/props_combine/breenglobe.mdl"] = { 1, "Globe", Color( 142, 68, 173 ) },
	["models/props_combine/breenchair.mdl"] = { 1, "Chair", Color( 44, 62, 80 ) },
	["models/props_docks/dock01_cleat01a.mdl"] = { 1, "Cleate", Color( 241, 196, 15 ) },
	["models/props_interiors/VendingMachineSoda01a.mdl"] = { 1, "Vending Machine", Color( 243, 156, 18 ) },
	["models/props_interiors/Furniture_Couch01a.mdl"] = { 1, "Couch", Color( 211, 84, 0 ) },
	["models/props_junk/plasticbucket001a.mdl"] = { 1, "Bucket", Color( 192, 57, 43 ) },
	["models/props_lab/filecabinet02.mdl"] = { 1, "File Cabinet", Color( 189, 195, 199 ) },
	["models/props_trainstation/trashcan_indoor001a.mdl"] = { 1, "Bin", Color( 149, 165, 166 ) },
	["models/props_vehicles/apc_tire001.mdl"] = { 1, "Tire", Color( 127, 140, 141 ) },
	["models/props_wasteland/light_spotlight01_lamp.mdl"] = { 1, "Spotlight", Color( 210, 82, 127 ) },
	["models/props_junk/TrafficCone001a.mdl"] = { 1, "Cone", Color( 144, 198, 149 ) }
}

-- Stats to display on round end
GM.RoundEndStats = {
	"thrown",
	"kill"
}

-- Player model colours
GM.PlayerColours = {
	Color( 39, 174, 96 ),
	Color( 155, 89, 182 ),
	Color( 41, 128, 185 ),
	Color( 52, 73, 94 ),
	Color( 22, 160, 133 ),
	Color( 230, 126, 34 ),
	Color( 231, 76, 60 )
}

if ( CLIENT ) then
	CreateClientConVar( "cl_playercolor", "", true, true )
end


function GM:Initialize()
end

-- function GM:ShouldCollide( ent1, ent2 )
	-- Don't run collision between;
	-- -	Players with spawn invulnerability
	-- -	A grapple hook and it's owner
	-- -	Two grapple hooks
	-- -	Props JUST thrown by self (as they are still inside self)
	-- -	Active shields and anything other than grapple hooks or props
	-- if (
		-- ( ( ent1:IsPlayer() ) and ( ent1:GetNWFloat( "sky_spawninvuln" ) >= CurTime() ) ) or
		-- ( ( ent2:IsPlayer() ) and ( ent2:GetNWFloat( "sky_spawninvuln" ) >= CurTime() ) ) or
		-- ( ( ent1:GetClass() == "sky_grapple" ) and ( ent1.Owner == ent2 ) ) or
		-- ( ( ent2:GetClass() == "sky_grapple" ) and ( ent2.Owner == ent1 ) ) or
		-- ( ( ent1:GetClass() == "sky_grapple" ) and ( ent2:GetClass() == "sky_grapple" ) ) or
		-- ( ( ent1:GetClass() == "sky_physprop") and ( ent1.GetJustThrown ) and ( ent1:GetJustThrown() > 0) and (ent2 == ent1:GetThrownBy()) ) or
		-- ( ( ent2:GetClass() == "sky_physprop") and ( ent2.GetJustThrown ) and ( ent2:GetJustThrown() > 0) and (ent1 == ent2:GetThrownBy()) ) or
		-- ( ( ent1:GetClass() == "sky_physprop") and ( ent1.IsShield ) and ( ent1.IsActiveShield ) and ( ent2:GetClass() ~= "sky_grapple" ) and ( ent2:GetClass() ~= "sky_physprop" ) and ( not ent2:IsPlayer() ) ) or
		-- ( ( ent2:GetClass() == "sky_physprop") and ( ent2.IsShield ) and ( ent2.IsActiveShield ) and ( ent1:GetClass() ~= "sky_grapple" ) and ( ent1:GetClass() ~= "sky_physprop" ) and ( not ent2:IsPlayer() ) )
	-- ) then
		-- return false
	-- end
	-- return true
-- end
