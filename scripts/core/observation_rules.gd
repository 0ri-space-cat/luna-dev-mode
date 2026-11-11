extends RefCounted
## Resolve an object's physical state independently from its appearance.
## Scene adapters supply sight and screen coverage from their own geometry.

enum SolidityLaw { ALWAYS, UNSEEN_BY_LUNA, UNSEEN_BY_PLAYER, EYES_OPEN }

static func resolve(base_visible: bool, base_solid: bool, law: SolidityLaw,
		luna_has_sight: bool, eyes_closed: bool, player_observes: bool) -> Dictionary:
	var luna_observes := luna_has_sight and not eyes_closed
	var solid := base_solid
	match law:
		SolidityLaw.UNSEEN_BY_LUNA:
			solid = solid and not luna_observes
		SolidityLaw.UNSEEN_BY_PLAYER:
			solid = solid and not player_observes
		SolidityLaw.EYES_OPEN:
			solid = solid and not eyes_closed
	return {"visible": base_visible, "solid": solid, "luna_observes": luna_observes,
		"player_observes": player_observes}


static func allows_transition(requires_unobserved: bool, player_observes: bool) -> bool:
	return not requires_unobserved or not player_observes
