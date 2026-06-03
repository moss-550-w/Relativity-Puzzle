extends Area2D
## 引力区 — World 2 核心机制
## 玩家进入后 TimeManager.gravity_factor 平滑降低 → 场景减速
## 视觉：暗紫色同心椭圆光环 + 中心暗核 + 旋转粒子


@export_category("Gravity")
## 目标引力因子（< 1.0 = 场景减速，默认 0.25 = 减速至 1/4）
@export var gravity_scale: float = 0.25
## 平滑过渡时长（秒）
@export var transition_time: float = 0.8

@export_category("Visual")
## 光环颜色
@export var ring_color: Color = Color(0.45, 0.2, 0.7, 0.3)
## 光环宽度（半径，像素）
@export var ring_radius: float = 180.0


# ---- 内部 ----

var _player_inside: bool = false
var _tween: Tween = null
var _particles: Array[Node2D] = []
var _ring_phase: float = 0.0


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2  # player 层

	# 圆形碰撞体（覆盖光环半径）
	var col := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = ring_radius
	col.shape = circle
	add_child(col)

	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

	_build_visual()
	_build_particles()


# ============================================================
# 视觉构建
# ============================================================

func _build_visual() -> void:
	# 暗色圆形底（模拟大质量天体在背景中的"暗影"）
	var core := ColorRect.new()
	core.name = "GravityCore"
	core.size = Vector2(60, 60)
	core.position = -core.size / 2.0
	core.color = Color(0.08, 0.02, 0.15, 0.7)
	core.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(core)

	# 光环用 _draw()
	var ring_draw := Node2D.new()
	ring_draw.name = "RingDraw"
	ring_draw.set_script(_make_ring_script())
	add_child(ring_draw)

	# 标签
	var label := Label.new()
	label.name = "GravityLabel"
	label.text = "引力区"
	label.position = Vector2(-24, -ring_radius - 20)
	label.size = Vector2(48, 16)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 10)
	label.add_theme_color_override("font_color", Color(0.55, 0.35, 0.8, 0.6))
	add_child(label)


func _make_ring_script() -> GDScript:
	var s := GDScript.new()
	s.source_code = """extends Node2D

var _phase: float = 0.0

func _process(delta: float) -> void:
	_phase += delta * 0.6
	queue_redraw()

func _draw() -> void:
	var parent := get_parent()
	var rr: float = parent.get("ring_radius") if parent else 180.0
	var col: Color = parent.get("ring_color") if parent else Color(0.45, 0.2, 0.7, 0.3)

	# 三层同心椭圆环，由内向外渐淡
	for layer in range(3, 0, -1):
		var r: float = rr * (0.45 + float(layer) * 0.22)
		var a: float = col.a * (0.35 + float(layer) * 0.2)
		var pulse: float = 1.0 + sin(_phase * 1.8 + float(layer)) * 0.06
		draw_arc(Vector2.ZERO, r * pulse, 0, TAU, 64, Color(col.r, col.g, col.b, a), 2.0)

	# 中心向外的渐变短线（引力方向暗示）
	for i in 6:
		var angle: float = float(i) / 6.0 * TAU + _phase * 0.3
		var inner: float = rr * 0.12
		var outer: float = rr * 0.35 + sin(_phase * 1.2 + float(i)) * rr * 0.08
		draw_line(Vector2(cos(angle), sin(angle)) * inner,
				  Vector2(cos(angle), sin(angle)) * outer,
				  Color(col.r, col.g, col.b, col.a * 0.6), 1.5)
"""
	s.reload()
	return s


func _build_particles() -> void:
	var container := Node2D.new()
	container.name = "Particles"
	for i in 10:
		var dot := ColorRect.new()
		dot.name = "P%d" % i
		dot.size = Vector2(3, 3)
		var angle := randf() * TAU
		var dist := randf_range(20.0, ring_radius * 0.9)
		dot.position = Vector2(cos(angle), sin(angle)) * dist
		dot.color = Color(0.5, 0.25, 0.75, 0.35 + randf() * 0.3)
		dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		dot.set_meta("angle", angle)
		dot.set_meta("dist", dist)
		dot.set_meta("speed", randf_range(0.12, 0.35))
		container.add_child(dot)
	add_child(container)


# ============================================================
# 引力因子控制
# ============================================================

func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	_player_inside = true
	_tween_to(gravity_scale)


func _on_body_exited(body: Node2D) -> void:
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
	_tween.tween_method(_set_gravity_factor, TimeManager.gravity_factor, target, transition_time)


func _set_gravity_factor(v: float) -> void:
	TimeManager.gravity_factor = v


# ============================================================
# 每帧
# ============================================================

func _process(delta: float) -> void:
	_update_particles(delta)


func _update_particles(_delta: float) -> void:
	var container := get_node_or_null("Particles")
	if not container:
		return
	for child in container.get_children():
		var angle: float = child.get_meta("angle")
		var dist: float = child.get_meta("dist")
		var speed: float = child.get_meta("speed")
		# 粒子缓慢向中心旋转
		var new_angle := angle + speed * 0.01
		child.set_meta("angle", new_angle)
		child.position = Vector2(cos(new_angle), sin(new_angle)) * dist
		# 靠近中心时略暗
		child.modulate.a = 0.25 + (dist / ring_radius) * 0.4


# ============================================================
# 重置
# ============================================================

func reset_state() -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
	_player_inside = false
	TimeManager.gravity_factor = 1.0
