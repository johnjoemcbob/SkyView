GM.Name = "SkyView"
GM.Author = "Tyguy"
GM.Email = "N/A"
GM.Website = "N/A"

function GM:Initialize()
end

function GM:ShouldCollide( ent1, ent2 )
	if (
		( ( ent1:GetClass() == "sky_grapple" ) and ( ent1.Owner == ent2 ) ) or
		( ( ent2:GetClass() == "sky_grapple" ) and ( ent2.Owner == ent1 ) )
	) then
		return false
	end

	return true
end