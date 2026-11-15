extends RefCounted
## A bounded 2D A* grid derived solely from authored physical geometry.
## The same room has separate paths for ground and FLY; painted backgrounds
## and game HUD never define navigation or passability.
##
## A* plans around static map solids. Dynamic actor collisions stay authoritative
## in CharacterBody2D.move_and_slide(), not in this planning approximation.

const CELL_SIZE := 24.0
const MAX_CELLS := 12000
const CLEARANCE := 12.0
const MAX_PATH_POINTS := 400

var last_error := ""
var bounds := Rect2()
var revision := 0
var _ground: AStarGrid2D
var _swimming: AStarGrid2D
var _flight: AStarGrid2D
var _dimension := Vector2i.ZERO


func configure(level_size: Vector2, solids: Array) -> bool:
	last_error = ""
	if not is_finite(level_size.x) or not is_finite(level_size.y):
		return _fail("Invalid level bounds")
	if level_size.x < CELL_SIZE or level_size.y < CELL_SIZE:
		return _fail("Level is too small")
	var cells := Vector2i(ceili(level_size.x / CELL_SIZE), ceili(level_size.y / CELL_SIZE))
	if cells.x <= 0 or cells.y <= 0 or cells.x * cells.y > MAX_CELLS:
		return _fail("Navigation grid exceeds safety budget")
	var candidate_solids: Array[Dictionary] = []
	if solids.size() > 256:
		return _fail("Too many solids")
	for entry in solids:
		if not (entry is Dictionary):
			return _fail("Invalid solid entry")
		if str(entry.get("kind", "")) not in ["WALL", "GROUND_ONLY", "SWIM_REQUIRED"]:
			return _fail("Unknown physical layer")
		var coords: Variant = entry.get("rect", null)
		if not (coords is Array) or coords.size() != 4:
			return _fail("Invalid obstacle rectangle")
		for value in coords:
			if typeof(value) not in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(value)):
				return _fail("Non-numeric obstacle coordinate")
		if float(coords[2]) <= 0.0 or float(coords[3]) <= 0.0:
			return _fail("Invalid obstacle size")
		candidate_solids.append({
			"kind": str(entry["kind"]),
			"rect": Rect2(float(coords[0]), float(coords[1]),
				float(coords[2]), float(coords[3]))
		})
	var ground := _new_grid(cells)
	var swimming := _new_grid(cells)
	var flight := _new_grid(cells)
	var next_bounds := Rect2(-level_size * 0.5, level_size)
	# A conservative radius covers the actor body and cell discretization:
	# no artificial "path" is opened through a too-narrow physical gap.
	var margin := CLEARANCE + CELL_SIZE * 0.5
	for y in range(cells.y):
		for x in range(cells.x):
			var center: Vector2 = next_bounds.position + Vector2(
				(float(x) + 0.5) * CELL_SIZE, (float(y) + 0.5) * CELL_SIZE)
			var blocked_ground := false
			var blocked_swimming := false
			var blocked_flight := false
			for obstacle in candidate_solids:
				if (obstacle["rect"] as Rect2).grow(margin).has_point(center):
					blocked_ground = true
					if str(obstacle["kind"]) != "SWIM_REQUIRED":
						blocked_swimming = true
					if str(obstacle["kind"]) == "WALL":
						blocked_flight = true
			var key := Vector2i(x, y)
			if blocked_ground:
				ground.set_point_solid(key)
			if blocked_swimming:
				swimming.set_point_solid(key)
			if blocked_flight:
				flight.set_point_solid(key)
	_ground = ground
	_swimming = swimming
	_flight = flight
	bounds = next_bounds
	_dimension = cells
	revision += 1
	return true


func get_path(start: Vector2, destination: Vector2, can_fly: bool = false,
		can_swim: bool = false) -> PackedVector2Array:
	var path := PackedVector2Array()
	if _ground == null or not _finite_point(start) or not _finite_point(destination):
		return path
	var source: Vector2i = _to_cell(start)
	var target: Vector2i = _to_cell(destination)
	var grid: AStarGrid2D = _flight if can_fly else (_swimming if can_swim else _ground)
	if not grid.is_in_boundsv(source) or not grid.is_in_boundsv(target):
		return path
	var original_source: Vector2i = source
	var original_target: Vector2i = target
	if grid.is_point_solid(source):
		source = _nearest_clear(grid, source)
	if grid.is_point_solid(target):
		target = _nearest_clear(grid, target)
	if not grid.is_in_boundsv(source) or not grid.is_in_boundsv(target):
		return path
	var cells: Array[Vector2i] = grid.get_id_path(source, target)
	if cells.is_empty() or cells.size() > MAX_PATH_POINTS:
		return path
	# Small clearance overlap at the actor's current position is recoverable
	# without teleportation: first walk toward the nearest navigable center.
	if source != original_source:
		path.append(_to_world(source))
	for i in range(1, cells.size()):
		path.append(_to_world(cells[i]))
	# Don't append the precise target if it is on a forbidden surface.
	if target == original_target:
		path.append(destination)
	return path


func is_walkable(point: Vector2, can_fly: bool = false, can_swim: bool = false) -> bool:
	if _ground == null or not _finite_point(point):
		return false
	var cell: Vector2i = _to_cell(point)
	var grid: AStarGrid2D = _flight if can_fly else (_swimming if can_swim else _ground)
	return grid.is_in_boundsv(cell) and not grid.is_point_solid(cell)


func _nearest_clear(grid: AStarGrid2D, cell: Vector2i) -> Vector2i:
	# Rescue real-world placements that overlap only the conservative A* cell
	# padding. A genuinely sealed room remains unreachable; no teleportation.
	for radius in range(1, 4):
		var closest := Vector2i(-1, -1)
		var best_distance := 999999
		for y in range(-radius, radius + 1):
			for x in range(-radius, radius + 1):
				var candidate: Vector2i = cell + Vector2i(x, y)
				if not grid.is_in_boundsv(candidate) or grid.is_point_solid(candidate):
					continue
				var distance_sq: int = x * x + y * y
				if distance_sq < best_distance:
					closest = candidate
					best_distance = distance_sq
		if best_distance < 999999:
			return closest
	return Vector2i(-1, -1)


func _new_grid(cells: Vector2i) -> AStarGrid2D:
	var grid := AStarGrid2D.new()
	grid.region = Rect2i(Vector2i.ZERO, cells)
	grid.cell_size = Vector2.ONE * CELL_SIZE
	grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	grid.update()
	return grid


func _to_cell(point: Vector2) -> Vector2i:
	var local: Vector2 = (point - bounds.position) / CELL_SIZE
	return Vector2i(floori(local.x), floori(local.y))


func _to_world(cell: Vector2i) -> Vector2:
	return bounds.position + (Vector2(cell) + Vector2(0.5, 0.5)) * CELL_SIZE


func _finite_point(point: Vector2) -> bool:
	return is_finite(point.x) and is_finite(point.y)


func _fail(reason: String) -> bool:
	last_error = reason
	return false
