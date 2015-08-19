GM.Name = "SkyView"
GM.Author = "Tyguy"
GM.Email = "N/A"
GM.Website = "N/A"

function GM:Initialize()
end

function GM:ShouldCollide( ent1, ent2 )
	if (
		( ( ent1:GetClass() == "sky_grapple" ) and ( ent1.Owner == ent2 ) ) or
		( ( ent2:GetClass() == "sky_grapple" ) and ( ent2.Owner == ent1 ) ) or
		( ( ent1:GetClass() == "sky_grapple" ) and ( ent2:GetClass() == "sky_grapple" ) ) or
		( ( ent1:GetClass() == "sky_physprop") and ( ent1.GetJustThrown ) and ( ent1:GetJustThrown() > 0) and (ent2 == ent1:GetThrownBy()) ) or
		( ( ent2:GetClass() == "sky_physprop") and ( ent2.GetJustThrown ) and ( ent2:GetJustThrown() > 0) and (ent1 == ent2:GetThrownBy()) )
	) then	
		return false
	end
	return true
end