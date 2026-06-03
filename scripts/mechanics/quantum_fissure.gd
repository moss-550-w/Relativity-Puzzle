extends Node2D
## 量子裂隙 — M3-2 核心机制
## 一对入口/出口：预兆(0.5s) → 打开(2s) → 坍缩消失，周期性循环
## 玩家触碰入口 → 传送到出口。E 键延长打开状态 +2s


const Player = preload("res://scripts/player/player.gd")

enum State { DORMANT, WARNING, OPEN }

# ---- 导出 ----

@export_category("Fissure")
@export var entry_pos: Vector2 = Vector2.ZERO
@export var exit_pos: Vector2 = Vector2.ZERO
## 初始延迟（首次打开前的等待秒数）
@export var initial_delay: float = 0.0
## 预兆阶段时长
@export var warning_time: float = 0.5
## 打开阶段时长
@export var open_time: float = 2.0
## 完整周期（DORMANT→WARNING→OPEN→DORMANT 的间隔）
@export var cycle_period: float = 8.0

@export_category("Visual")
@export var radius: float = 28.0
@export var entry_color: Color = Color(0.35, 0.3, 0.95, 0.85)
@export var exit_color: Color = Color(1.0, 0.7, 0.2, 0.85)

@export_category("Observe")
@export var observe_extend: float = 2.0
@export var observe_cooldown: float = 3.0
@export var observe_range: float = 120.0

# ---- 公开状态 ----

var current_state: State = State.DORMANT
var _state_timer: float = 0.0
var _cycle_timer: float = 0.0
var _cooldown_remaining: float = 0.0
var _entry_area: Area2D = null
var _entry_ring: Node2D = null
var _exit_marker: Polygon2D = null
var _particles: Array[ColorRect] = []
var _t: float = 0.0


func _ready() -> void:
	_cycle_timer = initial_delay
	_create_entry()
	_create_exit_marker()
	_create_particles()
	add_to_group("quantum_fissure")


# ============================================================
# 入口创建
# ============================================================

func _create_entry() -> void:
	_entry_area = Area2D.new()
	_entry_area.name = "Entry"
	_entry_area.position = entry_pos
	_entry_area.collision_layer = 0
	_entry_area.collision_mask = 2
	_entry_area.monitoring = false
	_entry_area.monitorable = false
	_entry_area.body_entered.connect(_on_entry_touch)

	var col := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = radius
	col.shape = circle
	_entry_area.add_child(col)

	_entry_ring = Node2D.new()
	_entry_ring.name = "RingVisual"
	_entry_ring.set_script(_make_ring_script(true))
	_entry_area.add_child(_entry_ring)

	add_child(_entry_area)


# ============================================================
# 出口标记
# ============================================================

func _create_exit_marker() -> void:
	_exit_marker = Polygon2D.new()
	_exit_marker.name = "ExitMarker"
	_exit_marker.position = exit_pos
	_exit_marker.color = Color(0.0, 0.0, 0.0, 0.0)  # 默认不可见
	_exit_marker.polygon = PackedVector2Array([
		Vector2(0, -10), Vector2(7, 0),
		Vector2(0, 10), Vector2(-7, 0),
	])
	add_child(_exit_marker)


# ============================================================
# 粒子
# ============================================================

func _create_particles() -> void:
	for i in 10:
		var dot := ColorRect.new()
		dot.size = Vector2(3, 3)
		dot.color = Color(0.0, 0.0, 0.0, 0.0)
		dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		dot.set_meta("angle", randf() * TAU)
		dot.set_meta("dist", randf_range(radius * 0.5, radius * 1.8))
		dot.set_meta("phase", randf() * TAU)
		_particles.append(dot)
		add_child(dot)


# ============================================================
# 光环绘制脚本
# ============================================================

func _make_ring_script(is_entry: bool) -> GDScript:
	var s := GDScript.new()
	var base_color: String = "Color(%f,%f,%f,%f)" % [entry_color.r, entry_color.g, entry_color.b, entry_color.a]
	s.source_code = """extends Node2D
var _t: float = 0.0
func _process(delta: float) -> void: _t += delta; queue_redraw()
func _draw() -> void:
	var parent_area := get_parent()
	if not parent_area: return
	var gp := parent_area.get_parent()
	if not gp: return
	var state: int = gp.get("current_state") if gp else 0
	var r: float = """ + str(radius) + """
	var base: Color = """ + base_color + """
	var alpha: float
	match state:
		0: alpha = 0.0   # DORMANT
		1:                 # WARNING — 粒子汇聚中
			var wp: float = gp.get("warning_time") if gp else 0.5
			var wt: float = gp.get("_state_timer") if gp else 0.0
			alpha = minf(wt / maxf(wp, 0.01), 1.0) * 0.5
		2: alpha = 0.85   # OPEN
		_: alpha = 0.0
	if alpha < 0.01: return
	draw_arc(Vector2.ZERO, r, 0, TAU, 48, Color(base.r, base.g, base.b, alpha * 0.25), 3.5)
	draw_arc(Vector2.ZERO, r - 4, 0, TAU, 48, Color(base.r, base.g, base.b, alpha), 2.0)
"""
	s.reload()
	return s


# ============================================================
# 生命周期
# ============================================================

func _process(delta: float) -> void:
	_t += delta
	_cooldown_remaining = maxf(0.0, _cooldown_remaining - delta)

	match current_state:
		State.DORMANT:
			_cycle_timer += delta
			if _cycle_timer >= cycle_period:
				_cycle_timer = 0.0
				_enter_warning()
		State.WARNING:
			_state_timer += delta
			if _state_timer >= warning_time:
				_state_timer = 0.0
				_enter_open()
		State.OPEN:
			_state_timer += delta
			if _state_timer >= open_time:
				_state_timer = 0.0
				_enter_dormant()

	_update_particles()


func _enter_warning() -> void:
	current_state = State.WARNING
	_state_timer = 0.0
	# 粒子开始向入口汇聚
	for dot in _particles:
		dot.set_meta("converging", true)


func _enter_open() -> void:
	current_state = State.OPEN
	_state_timer = 0.0
	_entry_area.monitoring = true
	_entry_area.monitorable = true
	# 出口标记亮起
	_exit_marker.color = exit_color


func _enter_dormant() -> void:
	current_state = State.DORMANT
	_state_timer = 0.0
	_entry_area.monitoring = false
	_entry_area.monitorable = false
	_exit_marker.color = Color(0.0, 0.0, 0.0, 0.0)


# ============================================================
# 观测延长
# ============================================================

## 由玩家 E 键调用，延长打开阶段 +observe_extend 秒
func try_extend(from_pos: Vector2) -> bool:
	if current_state != State.OPEN:
		return false
	if _cooldown_remaining > 0.0:
		return false
	if from_pos.distance_to(global_position + entry_pos) > observe_range:
		return false
	_state_timer = maxf(0.0, _state_timer - observe_extend)
	_cooldown_remaining = observe_cooldown
	# 视觉反馈：光环闪亮
	AudioManager.play_sfx("fragment_collect")
	return true


# ============================================================
# 传送
# ============================================================

func _on_entry_touch(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	if current_state != State.OPEN:
		return
	body.global_position = global_position + exit_pos
	body.velocity = Vector2.ZERO
	AudioManager.play_sfx("jump")


# ============================================================
# 粒子更新
# ============================================================

func _update_particles() -> void:
	var center: Vector2 = global_position + entry_pos
	for dot in _particles:
		var angle: float = dot.get_meta("angle")
		var dist: float = dot.get_meta("dist")
		var target_alpha: float

		match current_state:
			State.DORMANT:
				target_alpha = 0.0
			State.WARNING:
				# 粒子汇聚
				var progress: float = _state_timer / maxf(warning_time, 0.01)
				dot.position = center.lerp(center + Vector2(cos(angle), sin(angle)) * dist, 1.0 - progress)
				target_alpha = 0.3 + progress * 0.4
			State.OPEN:
				# 粒子在环附近飘浮
				var wobble: float = sin(_t * 4.0 + angle) * 8.0
				dot.position = center + Vector2(cos(angle), sin(angle)) * (dist + wobble)
				target_alpha = 0.25 + absf(sin(_t * 3.0 + angle)) * 0.3

		dot.color.a = lerpf(dot.color.a, target_alpha, 0.1)
		if current_state == State.DORMANT:
			dot.position = center + Vector2(cos(angle), sin(angle)) * dist * 0.3
		dot.color = Color(entry_color.r, entry_color.g, entry_color.b, dot.color.a)


# ============================================================
# 重置
# ============================================================

func reset_state() -> void:
	current_state = State.DORMANT
	_state_timer = 0.0
	_cycle_timer = initial_delay
	_cooldown_remaining = 0.0
	_entry_area.monitoring = false
	_entry_area.monitorable = false
	_exit_marker.color = Color(0.0, 0.0, 0.0, 0.0)
