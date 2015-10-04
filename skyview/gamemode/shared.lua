GM.Name = "SkyView"
GM.Author = "Tyguy"
GM.Email = "N/A"
GM.Website = "N/A"

include( "sh_stats.lua" )
include( "sh_sound.lua" )

-- Fire-able props
GM.PropDescriptions =
{
	["models/props_c17/FurnitureBathtub001a.mdl"] = { 1, "Bath" },
	["models/props_borealis/bluebarrel001.mdl"] = { 2, "Barrel" },
	["models/props_c17/furnitureStove001a.mdl"] = { 3, "Stove" },
	["models/props_c17/FurnitureFridge001a.mdl"] = { 4, "Fridge" },
	["models/props_c17/oildrum001.mdl"] = { 1, "Barrel" },
	["models/props_c17/oildrum001_explosive.mdl"] = { 1, "Barrel" },
	["models/props_junk/PlasticCrate01a.mdl"] = { 1, "Crate" },
	["models/props_c17/FurnitureSink001a.mdl"] = { 1, "Sink" },
	["models/props_c17/FurnitureCouch001a.mdl"] = { 1, "Couch" },
	["models/Combine_Helicopter/helicopter_bomb01.mdl"] = { 1, "Bomb" },
	["models/props_combine/breenglobe.mdl"] = { 1, "Globe" },
	["models/props_combine/breenchair.mdl"] = { 1, "Chair" },
	["models/props_docks/dock01_cleat01a.mdl"] = { 1, "Cleate" },
	["models/props_interiors/VendingMachineSoda01a.mdl"] = { 1, "Vending Machine" },
	["models/props_interiors/Furniture_Couch01a.mdl"] = { 1, "Couch" },
	["models/props_junk/plasticbucket001a.mdl"] = { 1, "Bucket" },
	["models/props_lab/filecabinet02.mdl"] = { 1, "File Cabinet" },
	["models/props_trainstation/trashcan_indoor001a.mdl"] = { 1, "Bin" },
	["models/props_vehicles/apc_tire001.mdl"] = { 1, "Tire" },
	["models/props_wasteland/light_spotlight01_lamp.mdl"] = { 1, "Spotlight" },
	["models/props_junk/TrafficCone001a.mdl"] = { 1, "Cone" }
}

-- Stats to display on round end
GM.RoundEndStats = {
	"kill"
}

-- Player model colours
GM.PlayerColours = {
	Color( 255, 0, 0 ),
	Color( 255, 255, 0 ),
	Color( 43, 235, 79 ),
	Color( 43, 158, 255 ),
	Color( 255, 148, 39 ),
	Color( 255, 148, 255 ),
	Color( 120, 133, 255 ),
	Color( 120, 158, 18 ),
	Color( 200, 200, 200 )
}

if ( CLIENT ) then
	CreateClientConVar( "cl_playercolor", "", true, true )
end


function GM:Initialize()
end

function GM:ShouldCollide( ent1, ent2 )
	-- Don't run collision between;
	-- -	Players with spawn invulnerability
	-- -	A grapple hook and it's owner
	-- -	Two grapple hooks
	-- -	Props JUST thrown by self (as they are still inside self)
	-- -	Active shields and anything other than grapple hooks or props
	if (
		( ( ent1:IsPlayer() ) and ( ent1:GetNWFloat( "sky_spawninvuln" ) >= CurTime() ) ) or
		( ( ent2:IsPlayer() ) and ( ent2:GetNWFloat( "sky_spawninvuln" ) >= CurTime() ) ) or
		( ( ent1:GetClass() == "sky_grapple" ) and ( ent1.Owner == ent2 ) ) or
		( ( ent2:GetClass() == "sky_grapple" ) and ( ent2.Owner == ent1 ) ) or
		( ( ent1:GetClass() == "sky_grapple" ) and ( ent2:GetClass() == "sky_grapple" ) ) or
		( ( ent1:GetClass() == "sky_physprop") and ( ent1.GetJustThrown ) and ( ent1:GetJustThrown() > 0) and (ent2 == ent1:GetThrownBy()) ) or
		( ( ent2:GetClass() == "sky_physprop") and ( ent2.GetJustThrown ) and ( ent2:GetJustThrown() > 0) and (ent1 == ent2:GetThrownBy()) ) or
		( ( ent1:GetClass() == "sky_physprop") and ( ent1.IsShield ) and ( ent1.IsActiveShield ) and ( ent2:GetClass() ~= "sky_grapple" ) and ( ent2:GetClass() ~= "sky_physprop" ) and ( not ent2:IsPlayer() ) ) or
		( ( ent2:GetClass() == "sky_physprop") and ( ent2.IsShield ) and ( ent2.IsActiveShield ) and ( ent1:GetClass() ~= "sky_grapple" ) and ( ent1:GetClass() ~= "sky_physprop" ) and ( not ent2:IsPlayer() ) )
	) then
		return false
	end
	return true
end
