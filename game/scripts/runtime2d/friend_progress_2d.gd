extends RefCounted
## One completed ordinary episode per distinct friend; separate from gifts.
const FRIENDS := ["YUKI", "MIA", "ORI", "LEIA", "TOFFI", "ONI"]
const ONI_SITES := ["W1", "K6"]
var meetings: Array[String] = []
var invitations: Array[String] = []
# Only an already-started evening from the old three-meeting contract.
var legacy_evening := false
var oni_sites: Array[String] = []
var prism_owned := false
# Q21b is independent of the two ordinary observations and their gift.
var oni_deep_met := false


func complete(friend: String) -> bool:
	if friend not in FRIENDS or friend in meetings:
		return false
	meetings.append(friend)
	return true


func observe_with_oni(site: String) -> bool:
	if site not in ONI_SITES or site in oni_sites:
		return false
	oni_sites.append(site)
	complete("ONI")
	return true


func complete_oni_deep() -> bool:
	if oni_deep_met:
		return false
	oni_deep_met = true
	return true


func oni_profile_unlocked() -> bool:
	return oni_deep_met


func can_invite(friend: String) -> bool:
	return friend in FRIENDS and friend in meetings and friend not in invitations


func invite(friend: String) -> bool:
	if not can_invite(friend):
		return false
	invitations.append(friend)
	return true


func can_gather() -> bool:
	return invitations.size() == FRIENDS.size()


func can_restore_evening() -> bool:
	return can_gather() or (legacy_evening and meetings.size() >= 3)


func snapshot() -> Dictionary:
	return {"meetings": meetings.duplicate(), "oni_sites": oni_sites.duplicate(), "prism_owned": prism_owned,
		"invitations": invitations.duplicate(), "legacy_evening": legacy_evening, "oni_deep_met": oni_deep_met}


func restore(data: Variant, evening_started: bool = false) -> bool:
	if not data is Dictionary or data.size() not in [3, 5, 6]:
		return false
	var old_format: bool = data.size() == 3 and not data.has("invitations") and not data.has("legacy_evening")
	if not old_format and (not data.has("invitations") or not data.has("legacy_evening")):
		return false
	if data.has("oni_deep_met") != (data.size() == 6) or not data.get("oni_deep_met", false) is bool:
		return false
	var raw_invites: Variant = data.get("invitations", [])
	var carried_evening: Variant = data.get("legacy_evening", old_format and evening_started)
	if not raw_invites is Array or not carried_evening is bool or (carried_evening and not evening_started):
		return false
	var next_meetings: Variant = data.get("meetings")
	var next_sites: Variant = data.get("oni_sites")
	var owned: Variant = data.get("prism_owned")
	if not next_meetings is Array or not next_sites is Array or not owned is bool:
		return false
	var checked_meetings: Array[String] = []
	var checked_sites: Array[String] = []
	for friend in next_meetings:
		if not friend is String or friend not in FRIENDS or friend in checked_meetings:
			return false
		checked_meetings.append(friend)
	for site in next_sites:
		if not site is String or site not in ONI_SITES or site in checked_sites:
			return false
		checked_sites.append(site)
	if (not checked_sites.is_empty()) != ("ONI" in checked_meetings) or (owned and checked_sites.size() != 2):
		return false
	var checked_invites: Array[String] = []
	for friend in raw_invites:
		if not friend is String or friend not in checked_meetings or friend in checked_invites:
			return false
		checked_invites.append(friend)
	if carried_evening and checked_meetings.size() < 3:
		return false
	meetings.assign(checked_meetings)
	invitations.assign(checked_invites)
	legacy_evening = carried_evening
	oni_sites.assign(checked_sites)
	prism_owned = owned
	oni_deep_met = data.get("oni_deep_met", false)
	return true
