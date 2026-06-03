extends Node2D
## 克尔黑洞 — World 2 BOSS 关核心
## 管理奇环、双视界、能层视觉 + 三阶段推进 + 检查点系统
## 非战斗：极限环境下的时空穿越挑战


const Player = preload("res://scripts/player/player.gd")

# ---- 导出：几何参数 ----

@export_category("Geometry")
## 奇环半径
@export var ring_radius: float = 120.0
## 内视界半径
@export var inner_horizon_radius: float = 200.0
## 外视界半径
@export var outer_horizon_radius: float = 350.0
## 能层外缘半径
@export var ergosphere_radius: float = 550.0

# ---- 导出：物理参数 ----

@export_category("Physics")
## 能层拖拽力强度
@export var drag_force: float = 280.0
## 外视界内 gravity_factor
@export var outer_gravity: float = 0.15
## 内视界内 gravity_factor
@export var inner_gravity: float = 0.05

# ---- 导出：奇环 ----

@export_category("Ring Singularity")
## 间隙周期（秒）
@export var gap_period: float = 3.0
## 间隙持续比例 [0-1]
@export var gap_duration_ratio: float = 0.27
## 间隙弧段数（打开的弧段数）
@export var gap_segments: int = 2
## 总弧段数
@export var total_segments: int = 16

# ---- 导出：检查点 ----

@export_category("Checkpoints")
@export var checkpoint_1_pos: Vector2 = Vector2(400, 0)
@export var checkpoint_2_pos: Vector2 = Vector2(250, 0)
@export var core_pos: Vector2 = Vector2(0, 0)

# ---- 颜色 ----

const COLOR_RING    := Color(1.0, 0.92, 0.55, 1.0)
const COLOR_INNER   := Color(0.6, 0.15, 0.9, 0.5)
const COLOR_OUTER   := Color(0.2, 0.5, 1.0, 0.4)
const COLOR_ERGO    := Color(0.3, 0.08, 0.5, 0.2)
const COLOR_DEBRIS  := Color(0.5, 0.35, 0.2, 0.9)

# ---- 状态 ----

enum Phase { ONE_EROSPHERE, TWO_HORIZONS, THREE_RING, COMPLETE }
var current_phase: Phase = Phase.ONE_EROSPHERE
var active_checkpoint: Vector2 = Vector2.ZERO
var _checkpoints: Dictionary = {}
var _player_spawn: Vector2 = Vector2.ZERO
var _player: Node2D = null
var _t: float = 0.0
var _disintegrating: bool = false


func _ready() -> void:
	_player_spawn = Vector2(ergosphere_radius + 120, 0)
	active_checkpoint = _player_spawn
	_create_visuals()
	_create_zones()
	_create_checkpoints()
	set_physics_process(true)


# ============================================================
# 视觉效果
# ============================================================

func _create_visuals() -> void:
	_create_ergosphere_visual()
	_create_outer_horizon_visual()
	_create_inner_horizon_visual()
	_create_ring_visual()
	_create_particles()


func _create_ergosphere_visual() -> void:
	var v := Node2D.new(); v.name = "ErgosphereVis"
	v.set_script(_make_ring_shader(ergosphere_radius, COLOR_ERGO, 2.5, 0.3))
	add_child(v)


func _create_outer_horizon_visual() -> void:
	var v := Node2D.new(); v.name = "OuterHorizonVis"
	v.set_script(_make_ring_shader(outer_horizon_radius, COLOR_OUTER, 2.0, 0.8))
	add_child(v)


func _create_inner_horizon_visual() -> void:
	var v := Node2D.new(); v.name = "InnerHorizonVis"
	v.set_script(_make_pulsing_ring_shader(inner_horizon_radius, COLOR_INNER, 5.0))
	add_child(v)


func _create_ring_visual() -> void:
	var v := Node2D.new(); v.name = "RingSingularityVis"
	v.set_script(_make_ring_shader(ring_radius, COLOR_RING, 4.0, 1.5))
	add_child(v)
	# 内亮核
	var core := ColorRect.new()
	core.name = "Core"
	core.size = Vector2(20, 20); core.position = -core.size / 2.0
	core.color = Color(1.0, 0.95, 0.8, 0.9)
	core.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(core)


func _make_ring_shader(r: float, c: Color, w: float, pulse_amp: float) -> GDScript:
	var s := GDScript.new()
	s.source_code = """extends Node2D
var _t: float = 0.0
func _process(delta: float) -> void: _t += delta; queue_redraw()
func _draw() -> void:
	var r: float = """ + str(r) + """
	var c: Color = Color(""" + str(c.r) + "," + str(c.g) + "," + str(c.b) + "," + str(c.a) + """)
	var w: float = """ + str(w) + """
	var pa: float = """ + str(pulse_amp) + """
	var pulse := 1.0 + sin(_t * 1.3) * pa * 0.08
	draw_arc(Vector2.ZERO, r * pulse, 0, TAU, 80, c, w)
	draw_arc(Vector2.ZERO, r * pulse, 0, TAU, 80, Color(c.r, c.g, c.b, c.a * 0.2), w * 2.5)
"""
	s.reload(); return s


func _make_pulsing_ring_shader(r: float, c: Color, period: float) -> GDScript:
	var s := GDScript.new()
	s.source_code = """extends Node2D
var _t: float = 0.0
func _process(delta: float) -> void: _t += delta; queue_redraw()
func _draw() -> void:
	var r: float = """ + str(r) + """
	var c: Color = Color(""" + str(c.r) + "," + str(c.g) + "," + str(c.b) + "," + str(c.a) + """)
	var p: float = """ + str(period) + """
	# 椭圆化形变
	var phase := fmod(_t, p) / p
	var squash := 1.0 + sin(phase * TAU) * 0.25
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(squash, 2.0 - squash))
	draw_arc(Vector2.ZERO, r, 0, TAU, 80, c, 2.5)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
"""
	s.reload(); return s


func _create_particles() -> void:
	var container := Node2D.new(); container.name = "Particles"
	for i in 40:
		var dot := ColorRect.new()
		dot.size = Vector2(2, 2)
		var angle := randf() * TAU
		var dist := randf_range(ring_radius * 0.3, ergosphere_radius * 1.15)
		dot.position = Vector2(cos(angle), sin(angle)) * dist
		dot.color = Color(0.3, 0.5, 1.0, randf_range(0.15, 0.45))
		dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		dot.set_meta("angle", angle); dot.set_meta("dist", dist)
		dot.set_meta("speed", randf_range(0.4, 1.2))
		container.add_child(dot)
	add_child(container)


# ============================================================
# 引力区 + 碰撞区
# ============================================================

func _create_zones() -> void:
	_create_zone(ergosphere_radius, "ErgosphereZone", 0, _on_enter_ergosphere, _on_exit_zone)
	_create_zone(outer_horizon_radius, "OuterHorizonZone", outer_gravity, _on_enter_outer, _on_exit_zone)
	_create_zone(inner_horizon_radius, "InnerHorizonZone", inner_gravity, _on_enter_inner, _on_exit_zone)
	_create_ring_collider()


func _create_zone(radius: float, _name: String, gravity: float, enter_cb: Callable, exit_cb: Callable) -> Area2D:
	var zone := Area2D.new()
	zone.name = _name
	zone.collision_layer = 0; zone.collision_mask = 2
	var col := CollisionShape2D.new()
	var circle := CircleShape2D.new(); circle.radius = radius
	col.shape = circle; zone.add_child(col)
	zone.set_meta("gravity", gravity)
	if enter_cb.is_valid(): zone.body_entered.connect(enter_cb)
	if exit_cb.is_valid(): zone.body_exited.connect(exit_cb)
	add_child(zone)
	return zone


func _create_ring_collider() -> void:
	# 奇环碰撞：N 段弧形碰撞体围绕环
	for i in total_segments:
		var seg := Area2D.new()
		seg.name = "RingSeg%d" % i
		seg.collision_layer = 0; seg.collision_mask = 2
		seg.set_meta("seg_index", i)
		var col := CollisionShape2D.new()
		var circle := CircleShape2D.new(); circle.radius = 18.0
		col.shape = circle
		var angle := float(i) / total_segments * TAU
		col.position = Vector2(cos(angle), sin(angle)) * ring_radius
		seg.add_child(col)
		seg.body_entered.connect(_on_ring_touch)
		add_child(seg)


# ============================================================
# 检查点
# ============================================================

func _create_checkpoints() -> void:
	_make_checkpoint("cp1", checkpoint_1_pos)
	_make_checkpoint("cp2", checkpoint_2_pos)
	_make_checkpoint("core", core_pos)


func _make_checkpoint(id: String, pos: Vector2) -> void:
	var cp := Area2D.new(); cp.name = "CP_" + id
	cp.collision_layer = 0; cp.collision_mask = 2; cp.position = pos
	var col := CollisionShape2D.new()
	var circle := CircleShape2D.new(); circle.radius = 24.0
	col.shape = circle; cp.add_child(col)
	cp.body_entered.connect(func(_b): _on_checkpoint(id, pos))
	add_child(cp)
	_checkpoints[id] = false
	# 视觉
	var m := Polygon2D.new(); m.name = "Marker"
	m.color = Color(0.3, 0.9, 1.0, 0.5)
	m.polygon = PackedVector2Array([Vector2(0,-10),Vector2(8,0),Vector2(0,10),Vector2(-8,0)])
	cp.add_child(m)


func _on_checkpoint(id: String, pos: Vector2) -> void:
	if _checkpoints.get(id, false):
		return
	_checkpoints[id] = true
	active_checkpoint = pos
	var marker := get_node_or_null("CP_" + id + "/Marker") as Polygon2D
	if marker: marker.color = Color(1.0, 0.85, 0.3, 0.9)
	AudioManager.play_sfx("fragment_collect")
	# 阶段推进
	match id:
		"cp1": current_phase = Phase.TWO_HORIZONS
		"cp2": current_phase = Phase.THREE_RING
		"core": _complete()


# ============================================================
# 区域进入/离开回调
# ============================================================

func _on_enter_ergosphere(_b: Node2D) -> void:
	pass  # 拖拽由 ergosphere_drag.gd 处理


func _on_enter_outer(body: Node2D) -> void:
	if body.is_in_group("player"): _apply_gravity(outer_gravity)


func _on_enter_inner(body: Node2D) -> void:
	if body.is_in_group("player"):
		_apply_gravity(inner_gravity)
		CodexManager.unlock("kerr_black_hole")


func _on_exit_zone(body: Node2D) -> void:
	if body.is_in_group("player"): _apply_gravity(1.0)


func _apply_gravity(v: float) -> void:
	var tw := create_tween()
	tw.set_ease(Tween.EASE_IN_OUT)
	tw.set_trans(Tween.TRANS_SINE)
	tw.tween_method(func(x): TimeManager.gravity_factor = x, TimeManager.gravity_factor, v, 0.6)


# ============================================================
# 奇环接触 → 解体
# ============================================================

func _on_ring_touch(body: Node2D) -> void:
	if not body.is_in_group("player") or _disintegrating:
		return
	if not _is_gap_open():
		_disintegrate(body)
	else:
		# 间隙打开，安全通过 → 推进到核心
		if current_phase == Phase.THREE_RING:
			_on_checkpoint("core", core_pos)


func _is_gap_open() -> bool:
	var phase := fmod(_t, gap_period) / gap_period
	return phase > (1.0 - gap_duration_ratio)


func _get_open_segments() -> Array[int]:
	if not _is_gap_open():
		return []
	var segs: Array[int] = []
	var base := int(fmod(_t / gap_period, total_segments))
	for i in gap_segments:
		segs.append((base + i) % total_segments)
	return segs


func _disintegrate(player: Node2D) -> void:
	_disintegrating = true
	player.set_frozen(true)
	# 像素化解体粒子
	_spawn_disintegration_particles(player.global_position)
	AudioManager.play_sfx("redline_bounce")
	# 重生
	await get_tree().create_timer(0.6).timeout
	player.global_position = active_checkpoint
	player.velocity = Vector2.ZERO
	player.set_frozen(false)
	_disintegrating = false


func _spawn_disintegration_particles(pos: Vector2) -> void:
	for i in 18:
		var p := ColorRect.new()
		p.size = Vector2(randf_range(3, 8), randf_range(3, 8))
		p.color = Color(randf_range(0.5, 1.0), randf_range(0.3, 0.9), randf_range(0.1, 0.5), 1.0)
		p.position = pos - p.size / 2.0
		p.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(p)
		var tw := create_tween()
		tw.tween_property(p, "position", pos + Vector2(randf_range(-80, 80), randf_range(-80, 80)), 0.5)
		tw.parallel().tween_property(p, "color:a", 0.0, 0.5)
		tw.tween_callback(p.queue_free)


func _complete() -> void:
	current_phase = Phase.COMPLETE
	CodexManager.unlock("ring_singularity")
	GameState.complete_level()


# ============================================================
# 每帧
# ============================================================

func _physics_process(delta: float) -> void:
	_t += delta
	_update_ring_gaps()
	_update_particles(delta)
	_apply_ergosphere_drag(delta)


func _update_ring_gaps() -> void:
	var open_segs := _get_open_segments()
	for child in get_children():
		if child.name.begins_with("RingSeg"):
			var idx: int = child.get_meta("seg_index", -1)
			var open := idx in open_segs
			child.set_deferred("monitoring", not open)
			child.set_deferred("monitorable", not open)
			# 视觉：间隙段变暗
			for gc in child.get_children():
				if gc is CollisionShape2D:
					var seg_color := Color(1, 1, 1, 0.15) if open else Color(1, 1, 1, 0.0)
					# 通过 modulate 变暗
					child.modulate = Color(0.3, 0.3, 0.3, 1.0) if open else Color.WHITE


func _update_particles(_delta: float) -> void:
	var container := get_node_or_null("Particles")
	if not container: return
	for child in container.get_children():
		var a: float = child.get_meta("angle"); var d: float = child.get_meta("dist")
		var s: float = child.get_meta("speed")
		child.set_meta("angle", a + s * 0.015)
		child.position = Vector2(cos(a), sin(a)) * d


func _apply_ergosphere_drag(_delta: float) -> void:
	if current_phase != Phase.ONE_EROSPHERE: return
	var p := _get_player()
	if not p: return
	var dist := p.global_position.distance_to(global_position)
	if dist >= ergosphere_radius or dist <= outer_horizon_radius: return
	# 切线方向力
	var to_center := (global_position - p.global_position).normalized()
	var tangent := Vector2(-to_center.y, to_center.x)
	var strength := (dist - outer_horizon_radius) / (ergosphere_radius - outer_horizon_radius)
	strength = 1.0 - strength  # 越靠近黑洞越强
	p.velocity += tangent * drag_force * strength * _delta


func _get_player() -> Node2D:
	return get_tree().get_first_node_in_group("player")


# ============================================================
# 重置
# ============================================================

func reset_state() -> void:
	current_phase = Phase.ONE_EROSPHERE
	active_checkpoint = _player_spawn
	_disintegrating = false
	_checkpoints.clear()
	for id in ["cp1", "cp2", "core"]:
		var marker := get_node_or_null("CP_" + id + "/Marker") as Polygon2D
		if marker: marker.color = Color(0.3, 0.9, 1.0, 0.5)
	TimeManager.gravity_factor = 1.0
