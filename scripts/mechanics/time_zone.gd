extends Area2D
## 时区 — World 4 中层核心机制
## 玩家进入后 TimeManager.gravity_factor 变为 zone 的时间倍率
## 不同时区有不同视觉颜色和粒子速度，直观对比时间流速差异


@export_category("Time")
## 时间倍率（<1=减速, 1=正常, >1=加速, 0=冻结）
@export var time_scale: float = 1.0
## 过渡时长
@export var transition_time: float = 0.6

@export_category("Visual")
@export var zone_color: Color = Color(1.0, 1.0, 1.0, 0.2)
@export var zone_radius: float = 200.0
@export var label_text: String = ""

var _player_inside: bool = false
var _tween: Tween = null


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2

	var col := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = zone_radius
	col.shape = circle
	add_child(col)

	body_entered.connect(_on_enter)
	body_exited.connect(_on_exit)

	_build_visual()
	add_to_group("time_zone")


func _build_visual() -> void:
	# 半透明圆形底色
	var bg := ColorRect.new()
	bg.name = "ZoneBg"
	bg.size = Vector2(zone_radius * 2, zone_radius * 2)
	bg.position = -bg.size / 2.0
	bg.color = zone_color
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	# 边框光环
	var ring := Node2D.new()
	ring.name = "Ring"
	var ring_script := GDScript.new()
	var col_str: String = "Color(%f,%f,%f,%f)" % [zone_color.r, zone_color.g, zone_color.b, zone_color.a]
	ring_script.source_code = """extends Node2D
func _process(_delta: float) -> void: queue_redraw()
func _draw() -> void:
	var r: float = """ + str(zone_radius) + """
	var col: Color = """ + col_str + """
	draw_arc(Vector2.ZERO, r, 0, TAU, 48, Color(col.r, col.g, col.b, col.a * 0.6), 3.0)
	draw_arc(Vector2.ZERO, r - 6, 0, TAU, 48, col, 1.5)
"""
	ring_script.reload()
	ring.set_script(ring_script)
	add_child(ring)

	# 标签
	if label_text != "":
		var label := Label.new()
		label.text = label_text
		label.position = Vector2(-40, -zone_radius - 20)
		label.size = Vector2(80, 16)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 11)
		label.add_theme_color_override("font_color", zone_color)
		add_child(label)


func _on_enter(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	_player_inside = true
	_tween_to(time_scale)


func _on_exit(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	_player_inside = false
	_tween_to(1.0)


func _tween_to(target: float) -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	_tween.set_ease(Tween.EASE_IN_OUT)
	_tween.set_trans(Tween.TRANS_SINE)
	_tween.tween_method(_set_factor, TimeManager.gravity_factor, target, transition_time)


func _set_factor(v: float) -> void:
	TimeManager.gravity_factor = v


func reset_state() -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
	_player_inside = false
	TimeManager.gravity_factor = 1.0
