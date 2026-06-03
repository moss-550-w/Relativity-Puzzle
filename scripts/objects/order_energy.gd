extends Area2D
## 秩序能量 — World 4 上层可收集资源
## 金色旋转光点，收集后 +1 秩序干预次数


@export var pulse_color: Color = Color(1.0, 0.85, 0.3, 0.8)

var _collected: bool = false
var _visual: Polygon2D = null
var _glow: ColorRect = null


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2

	var col := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 18.0
	col.shape = circle
	add_child(col)

	_glow = ColorRect.new()
	_glow.name = "Glow"
	_glow.size = Vector2(30, 30)
	_glow.position = -_glow.size / 2.0
	_glow.color = Color(1.0, 0.85, 0.3, 0.2)
	_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_glow)

	_visual = Polygon2D.new()
	_visual.name = "Visual"
	_visual.color = pulse_color
	_visual.polygon = PackedVector2Array([
		Vector2(0, -14), Vector2(10, 0),
		Vector2(0, 14), Vector2(-10, 0),
	])
	add_child(_visual)

	body_entered.connect(_on_collect)


func _process(delta: float) -> void:
	if _collected:
		return
	_visual.rotation += delta * 2.5
	var pulse: float = 1.0 + sin(Time.get_ticks_msec() * 0.005) * 0.2
	_visual.scale = Vector2(pulse, pulse)
	_glow.color.a = 0.15 + sin(Time.get_ticks_msec() * 0.004) * 0.08


func _on_collect(body: Node2D) -> void:
	if _collected or not body.is_in_group("player"):
		return
	_collected = true
	EntropySystem.add_order_resource()
	AudioManager.play_sfx("fragment_collect")

	var tw := create_tween()
	tw.tween_property(_visual, "scale", Vector2(2.5, 2.5), 0.3)
	tw.parallel().tween_property(_visual, "color:a", 0.0, 0.3)
	tw.tween_callback(queue_free)

	_glow.queue_free()


func reset_state() -> void:
	if _collected:
		return
	# 已收集则保持消失
	pass
