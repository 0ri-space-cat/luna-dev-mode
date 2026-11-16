extends RefCounted
## A bounded 2D A* grid derived solely from authored physical geometry.
## The same room has separate paths per movement capability; painted backgrounds
## and game HUD never define navigation or passability.
##
## A* plans around static map solids. Dynamic actor collisions stay authoritative
## in CharacterBody2D.move_and_slide(), not in this planning approximation.

const CELL_SIZE := 24.0
const MAX_CELLS := 12000
const CLEARANCE := 12.0
const MAX_PATH_POINTS := 400
const MAX_DYNAMIC_WALLS := 32

var last_error := ""
var bounds := Rect2()
var revision := 0
var _ground: AStarGrid2D
var _swimming: AStarGrid2D
var _climbing: AStarGrid2D
var _swim_climb: AStarGrid2D
var _flight: AStarGrid2D
var _dimension := Vector2i.ZERO
var _source_size := Vector2.ZERO
var _authored_solids: Array = []
var _dynamic_walls: Dictionary = {}


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
		if str(entry.get("kind", "")) not in ["WALL", "GROUND_ONLY", "SWIM_REQUIRED", "CLIMB_REQUIRED"]:
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
	for wall_rect in _dynamic_walls.values():
		candidate_solids.append({"kind": "WALL", "rect": wall_rect})
	var ground := _new_grid(cells)
	var swimming := _new_grid(cells)
	var climbing := _new_grid(cells)
	var swim_climb := _new_grid(cells)
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
			var blocked_climbing := false
			var blocked_swim_climb := false
			var blocked_flight := false
			for obstacle in candidate_solids:
				if (obstacle["rect"] as Rect2).grow(margin).has_point(center):
					var kind: String = str(obstacle["kind"])
					blocked_ground = true
					if kind != "SWIM_REQUIRED":
						blocked_swimming = true
					if kind != "CLIMB_REQUIRED":
						blocked_climbing = true
					if kind in ["WALL", "GROUND_ONLY"]:
						blocked_swim_climb = true
					if kind == "WALL":
						blocked_flight = true
			var key := Vector2i(x, y)
			if blocked_ground:
				ground.set_point_solid(key)
			if blocked_swimming:
				swimming.set_point_solid(key)
			if blocked_climbing:
				climbing.set_point_solid(key)
			if blocked_swim_climb:
				swim_climb.set_point_solid(key)
			if blocked_flight:
				flight.set_point_solid(key)
	_ground = ground
	_swimming = swimming
	_climbing = climbing
	_swim_climb = swim_climb
	_flight = flight
	bounds = next_bounds
	_dimension = cells
	_source_size = level_size
	_authored_solids = solids.duplicate(true)
	revision += 1
	return true


## Rebuild all mobility grids only when a physical law changes solidity.
## Passing the entire current set removes stale obstacles when a room unloads.
## This remains a static A* planner plus a bounded dynamic overlay, not a
## global crowd pathfinder. Every dynamic obstacle behaves as a true WALL.
func set_dynamic_walls(walls: Dictionary) -> bool:
	if walls.size() > MAX_DYNAMIC_WALLS:
		return _fail("Too many observation-dependent physical walls")
	for id in walls:
		if str(id).is_empty() or str(id).length() > 128:
			return _fail("Invalid dynamic obstacle identity")
		if not (walls[id] is Rect2):
			return _fail("Dynamic obstacle must be a Rect2")
		var footprint: Rect2 = walls[id]
		if not is_finite(footprint.position.x) or not is_finite(footprint.position.y) \
				or not is_finite(footprint.size.x) or not is_finite(footprint.size.y):
			return _fail("Non-finite dynamic obstacle")
		if footprint.size.x < 1.0 or footprint.size.y < 1.0 \
				or footprint.size.x > 20000.0 or footprint.size.y > 20000.0:
			return _fail("Invalid dynamic obstacle size")
	if walls == _dynamic_walls:
		return true
	if _ground == null:
		return walls.is_empty()
	var previous: Dictionary = _dynamic_walls.duplicate(true)
	_dynamic_walls = walls.duplicate(true)
	if not configure(_source_size, _authored_solids):
		_dynamic_walls = previous
		return false
	return true


func dynamic_wall_count() -> int:
	return _dynamic_walls.size()


func get_path(start: Vector2, destination: Vector2, can_fly: bool = false,
		can_swim: bool = false, can_climb: bool = false) -> PackedVector2Array:
	var path := PackedVector2Array()
	if _ground == null or not _finite_point(start) or not _finite_point(destination):
		return path
	var source: Vector2i = _to_cell(start)
	var target: Vector2i = _to_cell(destination)
	var grid: AStarGrid2D = _grid_for(can_fly, can_swim, can_climb)
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


func is_walkable(point: Vector2, can_fly: bool = false, can_swim: bool = false,
		can_climb: bool = false) -> bool:
	if _ground == null or not _finite_point(point):
		return false
	var cell: Vector2i = _to_cell(point)
	var grid: AStarGrid2D = _grid_for(can_fly, can_swim, can_climb)
	return grid.is_in_boundsv(cell) and not grid.is_point_solid(cell)


func _grid_for(can_fly: bool, can_swim: bool, can_climb: bool) -> AStarGrid2D:
	if can_fly:
		return _flight
	if can_swim and can_climb:
		return _swim_climb
	if can_swim:
		return _swimming
	if can_climb:
		return _climbing
	return _ground


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
	grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
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
