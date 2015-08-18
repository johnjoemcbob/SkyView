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
		( ( ent1:GetClass() == "sky_physprop") and ( ent1.JustThrown > 0) and (!ent2:IsWorld() ) and (ent2 != ent1.ThrownBy) ) or
		( ( ent2:GetClass() == "sky_physprop") and ( ent2.JustThrown > 0) and (!ent2:IsWorld() ) and (ent1 != ent2.ThrownBy) )
	) then
		return false
	end

	return true
end