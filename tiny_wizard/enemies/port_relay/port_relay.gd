class_name Chapter5PortRelay
extends ProtomatterDropEnemy

const PROJECTILE_SCENE := preload("res://tiny_wizard/enemies/chapter5_linear_projectile.tscn")
const IDLE_TEXTURE := preload("res://tiny_wizard/assets/art/enemies/chapter5/port_relay/port_relay_idle_48x48.png")
const LINK_TEXTURE := preload("res://tiny_wizard/assets/art/enemies/chapter5/port_relay/port_relay_link_attack_48x48_8f.png")
const NODE_TEXTURE := preload("res://tiny_wizard/assets/art/enemies/chapter5/port_relay/port_relay_link_node_12x12_4f.png")
const PROJECTILE_TEXTURE := preload("res://tiny_wizard/assets/art/enemies/chapter5/port_relay/port_relay_echo_projectile_16x16_4f.png")

@export var relay_delay := 0.28
@export var relay_damage := 1
@export var relay_speed := 300.0

var _relay_active := false
var _relay_elapsed := 0.0
var _relay_origin := Vector2.ZERO
var _relay_direction := Vector2.RIGHT

@onready var body_sprite := $Visual/BodySprite as Sprite2D


func _ready() -> void:
	super._ready()
	add_to_group("chapter5_port_relays")
	set_meta("chapter5_enemy_id", "port_relay")
	for pursuer in get_tree().get_nodes_in_group("chapter5_index_pursuers"):
		_connect_pursuer(pursuer)
	get_tree().node_added.connect(_on_node_added)
	play_idle()


func _process(delta: float) -> void:
	if not _relay_active:
		return
	_relay_elapsed += delta
	if body_sprite != null:
		body_sprite.frame = mini(7, int(floor(_relay_elapsed / 0.92 * 8.0)))
	if _relay_elapsed >= relay_delay:
		_relay_active = false
		_fire_relay_shot()


func _on_node_added(node: Node) -> void:
	if is_instance_valid(node) and node.is_in_group("chapter5_index_pursuers"):
		_connect_pursuer(node)


func _connect_pursuer(pursuer: Node) -> void:
	if not pursuer.has_signal("index_shot"):
		return
	var callable := Callable(self, "_on_index_shot")
	if not pursuer.is_connected("index_shot", callable):
		pursuer.connect("index_shot", callable)


func _on_index_shot(source: Node, origin: Vector2, direction: Vector2, _target_position: Vector2) -> void:
	if source == self or _relay_active:
		return
	if global_position.distance_to(origin) > 250.0:
		return
	_relay_origin = global_position + Vector2(0.0, -24.0)
	_relay_direction = direction.normalized()
	_relay_active = true
	_relay_elapsed = 0.0
	if body_sprite != null:
		body_sprite.texture = LINK_TEXTURE
		body_sprite.hframes = 8
		body_sprite.frame = 0
	_spawn_link_visual(origin)


func _spawn_link_visual(target_origin: Vector2) -> void:
	var line := Line2D.new()
	line.name = "RelayLink"
	line.z_index = -1
	line.width = 2.0
	line.default_color = Color(0.24, 0.88, 0.9, 0.82)
	line.points = PackedVector2Array([Vector2(0.0, -24.0), to_local(target_origin)])
	add_child(line)
	var node_sprite := Sprite2D.new()
	node_sprite.texture = NODE_TEXTURE
	node_sprite.hframes = 4
	node_sprite.position = to_local(target_origin)
	node_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(node_sprite)
	var tween := line.create_tween()
	tween.tween_interval(relay_delay + 0.12)
	tween.tween_callback(line.queue_free)
	var node_tween := node_sprite.create_tween()
	node_tween.tween_interval(relay_delay + 0.12)
	node_tween.tween_callback(node_sprite.queue_free)


func _fire_relay_shot() -> void:
	var effect_parent := _get_drop_parent()
	if effect_parent == null:
		return
	var projectile := PROJECTILE_SCENE.instantiate() as Chapter5LinearProjectile
	if projectile == null:
		return
	var projectile_sprite := projectile.get_node_or_null("Sprite2D") as Sprite2D
	if projectile_sprite != null:
		projectile_sprite.texture = PROJECTILE_TEXTURE
		projectile_sprite.hframes = 4
	if effect_parent is Node2D:
		projectile.position = (effect_parent as Node2D).to_local(_relay_origin)
	else:
		projectile.global_position = _relay_origin
	projectile.call("setup", _relay_direction, relay_damage, relay_speed)
	effect_parent.call_deferred("add_child", projectile)
	play_idle()


func play_idle() -> void:
	if body_sprite == null:
		return
	body_sprite.texture = IDLE_TEXTURE
	body_sprite.hframes = 1
	body_sprite.frame = 0


func set_speed_multiplier(multiplier: float) -> void:
	if physics_stats != null:
		physics_stats.max_speed = 42.0 * multiplier
