GM.Name = "SkyView"
GM.Author = "Tyguy"
GM.Email = "N/A"
GM.Website = "N/A"

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
	-- -	A grapple hook and it's owner
	-- -	Two grapple hooks
	-- -	Props JUST thrown by self (as they are still inside self)
	-- -	Active shields and anything other than grapple hooks or props
	if (
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