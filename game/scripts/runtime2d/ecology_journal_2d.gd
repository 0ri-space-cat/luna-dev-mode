extends RefCounted
## Only verified changes in living subjects enter this per-world record.

const DEATH := "death"
const VITAL_LOSS := "vital_loss"
const KINDS := [DEATH, VITAL_LOSS]
const WINDOW := 900.0
const BREADTH := 3
const EPISODES := 9
const MIN_SPAN := 90.0
const VITAL_DELAY := 6.0
const RESTRICTION_SECONDS := 360.0
const CAST_DELAY := 4.0

var episodes: Array[Dictionary] = []
var exposures: Dictionary = {}
var help: Dictionary = {}
var handled := 0
var restriction_until := 0.0
var frost_ready_at := 0.0
var notice_pending := false


func confirm(subject: String, kind: String, now: float) -> bool:
	if kind not in KINDS or _open_episode(subject, kind) >= 0:
		return false
	episodes.append({"subject": subject, "kind": kind, "time": now, "closed": false, "repaired": false})
	return true


func close(subject: String, kind: String, repaired: bool) -> bool:
	var index := _open_episode(subject, kind)
	if index < 0:
		return false
	episodes[index]["closed"] = true
	episodes[index]["repaired"] = repaired
	return true


func _open_episode(subject: String, kind: String) -> int:
	for index in range(episodes.size() - 1, -1, -1):
		var item := episodes[index]
		if item["subject"] == subject and item["kind"] == kind:
			return -1 if item["closed"] else index
	return -1


func arm_exposure(subject: String) -> bool:
	if exposures.has(subject) or _open_episode(subject, VITAL_LOSS) >= 0:
		return false
	exposures[subject] = 0.0
	return true


func observe_exposure(subject: String, actually_deprived: bool, delta: float, now: float) -> bool:
	if not exposures.has(subject):
		return false
	if not actually_deprived:
		return exposures.erase(subject)
	if not is_finite(delta) or delta <= 0.0:
		return false
	exposures[subject] = minf(VITAL_DELAY, float(exposures[subject]) + delta)
	if float(exposures[subject]) < VITAL_DELAY:
		return false
	exposures.erase(subject)
	return confirm(subject, VITAL_LOSS, now)


func record_help(outcome: String, subject: String, now: float) -> bool:
	if help.has(outcome):
		return false
	help[outcome] = {"subject": subject, "time": now}
	return true


func assess(now: float) -> bool:
	if restriction_remaining(now) > 0.0:
		return false
	var first := now
	var last := 0.0
	var harmed := {}
	var occurrences := 0
	for index in range(handled, episodes.size()):
		var item := episodes[index]
		var at: float = item["time"]
		if item["repaired"] or now - at > WINDOW:
			continue
		first = minf(first, at)
		last = maxf(last, at)
		harmed[item["subject"]] = true
		occurrences += 1
	if occurrences < EPISODES or harmed.size() < BREADTH or last - first < MIN_SPAN:
		return false
	handled = episodes.size()
	restriction_until = now + RESTRICTION_SECONDS
	frost_ready_at = 0.0
	notice_pending = true
	return true


func restriction_remaining(now: float) -> float:
	return maxf(0.0, restriction_until - now)


func allow_frost(now: float) -> bool:
	return restriction_remaining(now) <= 0.0 or now >= frost_ready_at


func record_frost(base_seconds: float, now: float) -> bool:
	if restriction_remaining(now) <= 0.0:
		return false
	frost_ready_at = minf(restriction_until, now + base_seconds + CAST_DELAY)
	return true


func snapshot() -> Dictionary:
	return {"episodes": episodes.duplicate(true), "exposures": exposures.duplicate(),
		"help": help.duplicate(true), "handled": handled, "restriction_until": restriction_until,
		"frost_ready_at": frost_ready_at, "notice_pending": notice_pending}


func restore(value: Variant, now: float) -> bool:
	if not value is Dictionary:
		return false
	if value.is_empty():
		return true # profiles before ecological observation
	var records: Variant = value.get("episodes")
	var waiting: Variant = value.get("exposures")
	var outcomes: Variant = value.get("help")
	if not records is Array or not waiting is Dictionary or not outcomes is Dictionary \
			or not _time(value.get("handled"), records.size()) \
			or float(value["handled"]) != floorf(value["handled"]) \
			or not _time(value.get("restriction_until"), now + RESTRICTION_SECONDS + 0.01) \
			or not _time(value.get("frost_ready_at"), value["restriction_until"]) \
			or not value.get("notice_pending") is bool or (value["notice_pending"] and value["handled"] == 0):
		return false
	var previous_time := 0.0
	var open := {}
	for item in records:
		if not item is Dictionary or not _id(item.get("subject")) or item.get("kind") not in KINDS \
				or not _time(item.get("time"), now + 0.01) or float(item["time"]) < previous_time \
				or not item.get("closed") is bool or not item.get("repaired") is bool \
				or (item["repaired"] and not item["closed"]):
			return false
		previous_time = item["time"]
		var key := "%s:%s" % [item["subject"], item["kind"]]
		if open.has(key):
			return false
		if not item["closed"]:
			open[key] = true
	for identity in waiting:
		if not _id(identity) or not _time(waiting[identity], VITAL_DELAY) or open.has("%s:%s" % [identity, VITAL_LOSS]):
			return false
	for outcome in outcomes:
		var result: Variant = outcomes[outcome]
		if not _id(outcome) or not result is Dictionary or not _id(result.get("subject")) \
				or not _time(result.get("time"), now + 0.01):
			return false
	episodes.assign(records.duplicate(true))
	exposures = waiting.duplicate()
	help = outcomes.duplicate(true)
	handled = int(value["handled"])
	restriction_until = value["restriction_until"]
	frost_ready_at = value["frost_ready_at"]
	notice_pending = value["notice_pending"]
	return true


func _id(value: Variant) -> bool:
	return value is String and value.length() <= 96 and value.is_valid_identifier()


func _time(value: Variant, maximum: float) -> bool:
	return typeof(value) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(value)) \
		and float(value) >= 0.0 and float(value) <= maximum
