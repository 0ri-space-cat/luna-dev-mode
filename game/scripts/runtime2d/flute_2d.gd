extends RefCounted
## Author-approved literal notes. Matching does not depend on reading a clue.
const PHRASES := {
	"M01": "UUDDLRLR",
	"M02": "URULDR",
	"M03": "LDLURD",
	"M04": "RURDLU",
	"M05": "LLURD",
	"M06": "R D R U L",
	"M07": "DULRDU",
	"M08": "DDRLUR",
	"M09": "UDRDLU",
	"M10": "DLDRUL",
}
const IMPLEMENTED := ["M01", "M02", "M03", "M04", "M05", "M06", "M07", "M09", "M10"]
const GLYPHS := {"U": "↑", "D": "↓", "L": "←", "R": "→"}
const FREQUENCIES := {"U": 523.25, "D": 392.0, "L": 440.0, "R": 493.88}
const MAX_NOTES := 8
var phrase := ""


func note(value: String) -> bool:
	if value not in GLYPHS or phrase.length() >= MAX_NOTES:
		return false
	phrase += value
	return true


func clear() -> void:
	phrase = ""


static func resolve(value: String) -> String:
	for identity in PHRASES:
		if PHRASES[identity].replace(" ", "") == value:
			return identity
	return ""


static func arrows(value: String) -> String:
	var result := PackedStringArray()
	for letter in value.replace(" ", ""):
		if GLYPHS.has(letter):
			result.append(GLYPHS[letter])
	return " ".join(result)


static func tone(value: String) -> AudioStreamWAV:
	var sample := AudioStreamWAV.new()
	sample.format = AudioStreamWAV.FORMAT_16_BITS
	sample.mix_rate = 22050
	var frames := 3307
	var bytes := PackedByteArray()
	bytes.resize(frames * 2)
	var frequency: float = FREQUENCIES.get(value, 440.0)
	for index in range(frames):
		var seconds := float(index) / float(sample.mix_rate)
		var envelope := minf(1.0, float(index) / 180.0) * minf(1.0, float(frames - index) / 600.0)
		var wave := sin(TAU * frequency * seconds) * 0.8 + sin(TAU * frequency * 2.0 * seconds) * 0.2
		bytes.encode_s16(index * 2, roundi(wave * envelope * 7000.0))
	sample.data = bytes
	return sample
