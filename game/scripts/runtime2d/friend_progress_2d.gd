extends RefCounted
## One completed ordinary episode per distinct friend; separate from gifts.
const FRIENDS := ["YUKI", "MIA", "ORI", "LEIA", "TOFFI", "ONI"]
const ONI_SITES := ["W1", "K6"]
var meetings: Array[String] = []
var oni_sites: Array[String] = []
var prism_owned := false


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


func can_gather() -> bool:
	return meetings.size() >= 3


func snapshot() -> Dictionary:
	return {"meetings": meetings.duplicate(), "oni_sites": oni_sites.duplicate(), "prism_owned": prism_owned}


func restore(data: Variant) -> bool:
	if not data is Dictionary or data.size() != 3:
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
	meetings.assign(checked_meetings)
	oni_sites.assign(checked_sites)
	prism_owned = owned
	return true
