extends Room


const TILE_MAP_LAYER := 0
const ROCK_SOURCE_ID := 0
const DESTRUCTIBLE_ROCK_TILE := Vector2i(4, 1)

@export var rock_chest_path: NodePath


func _ready() -> void:
	super._ready()
	call_deferred("_build_rock_box")


func _build_rock_box() -> void:
	var tilemap := $TileMap as TileMap
	var rock_chest := get_node_or_null(rock_chest_path) as Node2D
	if tilemap == null or rock_chest == null:
		return

	var center_cell := tilemap.local_to_map(tilemap.to_local(rock_chest.global_position))
	var rock_offsets := [
		Vector2i(-1, -1),
		Vector2i(0, -1),
		Vector2i(1, -1),
		Vector2i(-1, 0),
		Vector2i(1, 0),
		Vector2i(-1, 1),
		Vector2i(0, 1),
		Vector2i(1, 1),
	]

	for offset: Vector2i in rock_offsets:
		tilemap.set_cell(TILE_MAP_LAYER, center_cell + offset, ROCK_SOURCE_ID, DESTRUCTIBLE_ROCK_TILE)
