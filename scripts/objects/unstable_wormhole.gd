extends Area2D
## 不稳定虫洞 — M3-1 穿越机制
## 默认高速闪烁（0.3s 开/关），无法稳定通过
## 与卡西米尔负能量区重叠 → 稳定保持打开 → 可传送


const Player = preload("res://scripts/player/player.gd")

# ---- 导出 ----

@export_category("Flicker")
@export var flicker_on_time: float = 0.3
@export var flicker_off_time: float = 0.3
@export var wormhole_radius: float = 32.0

@export_category("Teleport")
## 传送目标（封闭空间内部出口）
@export var exit_pos: Vector2 = Vector2.ZERO

@export_category("Visual")
@export var stable_color: Color = Color(0.2, 0.7, 1.0, 0.9)
@export var unstable_color: Color = Color(1.0, 0.4, 0.15, 0.5)

# ---- 公开状态 ----

var is_open: bool = false
var is_stable: bool = false

# ---- 内部 ----

var _flicker_timer: float = 0.0
var _t: float = 0.0
var _ring_vis: Node2D = null


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2

	var col := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = wormhole_radius
	col.shape = circle
	add_child(col)

	_ring_vis = Node2D.new()
	_ring_vis.name = "RingVisual"
	_ring_vis.set_script(_make_ring_script())
	add_child(_ring_vis)

	body_entered.connect(_on_body_entered)


func _make_ring_script() -> GDScript:
	var s := GDScript.new()
	s.source_code = """extends Node2D
var _t: float = 0.0
func _process(delta: float) -> void: _t += delta; queue_redraw()
func _draw() -> void:
	var parent := get_parent()
	if not parent: return
	var open: bool = parent.get("is_open") if parent else false
	var stable: bool = parent.get("is_stable") if parent else false
	var r: float = 32.0
	var alpha: float = 0.85 if stable else (0.25 + sin(_t * 8.0) * 0.3 if open else 0.08)
	var col: Color
	if stable:
		col = Color(0.2, 0.7, 1.0, alpha)
	else:
		col = Color(1.0, 0.4, 0.15, alpha)
	# 双层光环
	draw_arc(Vector2.ZERO, r, 0, TAU, 48, Color(col.r, col.g, col.b, col.a * 0.3), 4.0)
	draw_arc(Vector2.ZERO, r - 4, 0, TAU, 48, col, 2.0)
	# 稳定时的内亮核
	if stable:
		draw_circle(Vector2.ZERO, 8.0, Color(1.0, 1.0, 1.0, 0.5))
"""
	s.reload(); return s


# ============================================================
# 每帧
# ============================================================

func _process(delta: float) -> void:
	_t += delta
	_check_neg_energy_stabilize()

	if is_stable:
		is_open = true
	else:
		_flicker_timer += delta
		var threshold := flicker_on_time if is_open else flicker_off_time
		if _flicker_timer >= threshold:
			_flicker_timer = 0.0
			is_open = not is_open

	# 碰撞跟随开关状态
	monitoring = is_open
	monitorable = is_open


func _check_neg_energy_stabilize() -> void:
	# 检测是否与任何负能量区重叠（通过 casimir_plates group）
	var was_stable := is_stable
	is_stable = false
	for plates in get_tree().get_nodes_in_group("casimir_plates"):
		if plates.get("neg_energy_active") != true:
			continue
		var center: Vector2 = plates.get("neg_zone_center")
		var radius: float = plates.get("neg_zone_radius")
		if global_position.distance_to(center) < radius + wormhole_radius:
			is_stable = true
			break
	if is_stable and not was_stable:
		AudioManager.play_sfx("fragment_collect")


# ============================================================
# 传送
# ============================================================

func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"): return
	if not is_open: return
	body.global_position = exit_pos
	body.velocity = Vector2.ZERO
	AudioManager.play_sfx("jump")


# ============================================================
# 重置
# ============================================================

func reset_state() -> void:
	_flicker_timer = 0.0
	is_open = false
	is_stable = false
