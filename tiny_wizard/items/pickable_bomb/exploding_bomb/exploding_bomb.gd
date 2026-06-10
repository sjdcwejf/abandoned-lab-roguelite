extends Node2D

const TILE_MAP_LAYER := 0
const DESTRUCTIBLE_ROCK_TILE := Vector2i(4, 1)
const DESTROYED_ROCK_TILE := Vector2i(4, 2)
const TILE_BLAST_RADIUS := 145.0

var active = true

var stone_rids = []

func _ready():
	tree_exiting.connect(_on_tree_exiting)

func explode():
	
	play_anim()
	
	var exploding_area : Area2D = $RigidBody2D/ExplodingArea
	
	var explode_position = $RigidBody2D.global_position
	
	for thing in exploding_area.get_overlapping_bodies():
		if thing != $RigidBody2D:
			if thing is TileMap:
				update_tilemap(thing, explode_position)

			if thing.has_method("hit"):
				thing.hit(2, explode_position.direction_to(thing.global_position))
			elif thing.has_method("apply_impulse"):
				thing.apply_impulse(explode_position.direction_to(thing.global_position)*20000/explode_position.distance_to(thing.global_position))

func update_tilemap(tilemap: TileMap, explode_position: Vector2):
	var destroyed_cells := {}
	for stone_rid in stone_rids:
		var coords := tilemap.get_coords_for_body_rid(stone_rid)
		if _destroy_tilemap_rock(tilemap, coords):
			destroyed_cells[coords] = true

	var center_cell := tilemap.local_to_map(tilemap.to_local(explode_position))
	var tile_range := int(ceil(TILE_BLAST_RADIUS / float(tilemap.tile_set.tile_size.x))) + 1
	for x in range(center_cell.x - tile_range, center_cell.x + tile_range + 1):
		for y in range(center_cell.y - tile_range, center_cell.y + tile_range + 1):
			var coords := Vector2i(x, y)
			if destroyed_cells.has(coords):
				continue
			var cell_center := tilemap.to_global(tilemap.map_to_local(coords))
			if cell_center.distance_to(explode_position) <= TILE_BLAST_RADIUS:
				_destroy_tilemap_rock(tilemap, coords)


func _destroy_tilemap_rock(tilemap: TileMap, coords: Vector2i) -> bool:
	var source_id := tilemap.get_cell_source_id(TILE_MAP_LAYER, coords)
	if source_id < 0:
		return false
	if tilemap.get_cell_atlas_coords(TILE_MAP_LAYER, coords) != DESTRUCTIBLE_ROCK_TILE:
		return false

	tilemap.set_cell(TILE_MAP_LAYER, coords, source_id, DESTROYED_ROCK_TILE)
	return true

func play_anim():
	($RigidBody2D/AnimatedSprite2D as AnimatedSprite2D).play("explosion")

func _on_tree_exiting():
	var target_parent := get_parent()
	var ground_trace = $RigidBody2D/GroundBombTrace
	var trace_parent = ground_trace.get_parent()
	if target_parent == null or trace_parent == null:
		return

	var pos = ground_trace.global_position
	trace_parent.remove_child(ground_trace)
	target_parent.call_deferred("add_child", ground_trace)
	ground_trace.set_deferred("global_position", pos)

func _on_exploding_area_body_shape_entered(body_rid, body, body_shape_index, local_shape_index):
	if body is TileMap:
		stone_rids.append(body_rid)

func _on_exploding_area_body_shape_exited(body_rid, body, body_shape_index, local_shape_index):
	if body is TileMap:
		var index = stone_rids.find(body_rid)
		if index >= 0:
			stone_rids.remove_at(index)
