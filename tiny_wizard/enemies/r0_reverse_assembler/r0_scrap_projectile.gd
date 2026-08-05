extends Area2D


const SCRAP_TEXTURE := preload("res://tiny_wizard/assets/art/enemies/chapter4/r0/r0_scrap_fragment_16x16_4f.png")

var _origin := Vector2.ZERO
var _direction := Vector2.RIGHT
var _distance := 220.0
var _elapsed := 0.0
var _hit_player := false
var _finished := false
var _damage := 2
var _sprite: Sprite2D


func setup(origin: Vector2, direction: Vector2, distance := 220.0, damage := 2) -> void:
	_origin = origin
	global_position = origin
	_direction = direction.normalized() if direction.length() > 0.01 else Vector2.RIGHT
	_distance = distance
	_damage = damage


func _ready() -> void:
	name = "R0ScrapProjectile"
	add_to_group("r0_scrap_projectiles")
	z_index = 10
	collision_layer = 4
	collision_mask = 2
	monitoring = true
	monitorable = true
	body_entered.connect(_on_body_entered)
	_sprite = Sprite2D.new()
	_sprite.texture = SCRAP_TEXTURE
	_sprite.hframes = 4
	_sprite.frame = 0
	_sprite.scale = Vector2(1.6, 1.6)
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(_sprite)

	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 7.0
	shape.shape = circle
	add_child(shape)


func _physics_process(delta: float) -> void:
	if _finished:
		return
	_elapsed += delta
	if _elapsed < 0.46:
		global_position = _origin + _direction * _distance * ease(_elapsed / 0.46, 0.72)
	elif _elapsed < 0.74:
		global_position = _origin + _direction * _distance
	else:
		var return_ratio := (_elapsed - 0.74) / 0.58
		if return_ratio >= 1.0:
			_finish()
			return
		global_position = _origin + _direction * _distance * (1.0 - ease(return_ratio, 0.68))
	if _sprite != null:
		_sprite.frame = int(_elapsed * 14.0) % 4


func _on_body_entered(body: Node) -> void:
	if _finished or _hit_player:
		return
	if body.has_method("hit"):
		_hit_player = true
		body.call("hit", _damage, _direction)


func _finish() -> void:
	if _finished:
		return
	_finished = true
	collision_layer = 0
	collision_mask = 0
	queue_free()
