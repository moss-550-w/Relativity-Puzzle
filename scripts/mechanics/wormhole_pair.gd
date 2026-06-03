extends Node2D
## 虫洞对 — World 2 CTC 核心机制
## 管理两个虫洞口（A 固定、B 可 F 拖拽）、连线、时间差检测
## 拖拽 B 入引力区 → 时间差激活 → 进 A 回到"过去"（CTC 过去回响态）


const Player = preload("res://scripts/player/player.gd")

# ---- 导出 ----

@export_category("Portals")
@export var portal_a_pos: Vector2 = Vector2(350, 590)
@export var portal_b_pos: Vector2 = Vector2(550, 590)
@export var portal_radius: float = 28.0
@export var portal_a_color: Color = Color(0.2, 0.6, 1.0, 0.85)
@export var portal_b_color: Color = Color(1.0, 0.5, 0.15, 0.85)
## 传送冷却（秒）
@export var cooldown: float = 1.5

@export_category("Grab")
@export var grab_range: float = 80.0
@export var grab_offset: Vector2 = Vector2(60, -40)

@export_category("CTC")
## 过去态视觉效果：画面叠加色
@export var past_tint: Color = Color(0.2, 0.15, 0.4, 0.25)
@export var switch_pos: Vector2 = Vector2(1020, 590)

# ---- 公开状态（供 ctc_door 等读取） ----

var time_diff_active: bool = false
var ctc_past_active: bool = false
var switch_activated: bool = false

# ---- 内部 ----

var _portal_a: Area2D = null
var _portal_b: Area2D = null
var _portal_b_spawn: Vector2 = Vector2.ZERO
var _dragging: bool = false
var _cooldown_remaining: float = 0.0
var _past_self_pos: Vector2 = Vector2.ZERO
var _has_past_self: bool = false
var _connection_line: Line2D = null
var _switch_area: Area2D = null
var _switch_sprite: Polygon2D = null
var _past_overlay: ColorRect = null
var _t: float = 0.0


func _ready() -> void:
	_create_portal_a()
	_create_portal_b()
	_create_connection_line()
	_create_switch()
	_create_past_overlay()


# ============================================================
# Portal A（固定，蓝色）
# ============================================================

func _create_portal_a() -> void:
	_portal_a = _make_portal(portal_a_color, false)
	_portal_a.name = "PortalA"
	_portal_a.position = portal_a_pos
	_portal_a.body_entered.connect(_on_portal_a_entered)
	add_child(_portal_a)


# ============================================================
# Portal B（可拖拽，橙色）
# ============================================================

func _create_portal_b() -> void:
	_portal_b = _make_portal(portal_b_color, true)
	_portal_b.name = "PortalB"
	_portal_b.position = portal_b_pos
	_portal_b_spawn = portal_b_pos
	_portal_b.body_entered.connect(_on_portal_b_entered)
	add_child(_portal_b)


func _make_portal(color: Color, draggable: bool) -> Area2D:
	var portal := Area2D.new()
	portal.collision_layer = 0
	portal.collision_mask = 2  # player 层

	var col := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = portal_radius
	col.shape = circle
	portal.add_child(col)

	# 光环绘制节点
	var ring := Node2D.new()
	ring.name = "RingVisual"
	ring.set_script(_make_ring_script(color, draggable))
	portal.add_child(ring)

	return portal


func _make_ring_script(c: Color, draggable: bool) -> GDScript:
	var s := GDScript.new()
	var drag_str := "true" if draggable else "false"
	s.source_code = """extends Node2D

var _base_color: Color = Color(""" + str(c.r) + "," + str(c.g) + "," + str(c.b) + "," + str(c.a) + """)
var _draggable: bool = """ + drag_str + """

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	var r := 28.0
	# 外层光环
	draw_arc(Vector2.ZERO, r, 0, TAU, 48, Color(_base_color.r, _base_color.g, _base_color.b, 0.25), 3.5)
	# 内层
	draw_arc(Vector2.ZERO, r - 5, 0, TAU, 48, _base_color, 2.0)
	# 旋转亮点
	var t := Time.get_ticks_msec() / 1000.0
	var speed := 2.5
	var angle := t * speed
	draw_circle(Vector2(cos(angle), sin(angle)) * (r - 3), 4.0, Color.WHITE)
	draw_circle(Vector2(cos(angle + PI), sin(angle + PI)) * (r - 3), 3.0, Color(_base_color.r, _base_color.g, _base_color.b, 0.6))
	# 拖拽提示
	if _draggable:
		draw_set_transform(Vector2(0, r + 12))
		draw_string(ThemeDB.fallback_font, Vector2(-18, 0), "[F 拖拽]")
"""
	s.reload()
	return s


# ============================================================
# 连线（Portal A ↔ Portal B）
# ============================================================

func _create_connection_line() -> void:
	_connection_line = Line2D.new()
	_connection_line.name = "ConnectionLine"
	_connection_line.width = 2.5
	_connection_line.default_color = portal_a_color
	_connection_line.z_index = -1
	add_child(_connection_line)


func _update_connection_line() -> void:
	if not _connection_line:
		return
	var pa := _portal_a.global_position
	var pb := _portal_b.global_position
	var mid := (pa + pb) / 2.0
	# 弧形偏移
	var perp := (pb - pa).orthogonal().normalized() * (pa.distance_to(pb) * 0.18)
	var ctrl := mid + perp

	_connection_line.clear_points()
	var steps := 20
	for i in steps + 1:
		var t_param := float(i) / steps
		var pt := pa.bezier_interpolate(ctrl, ctrl, pb, t_param)
		_connection_line.add_point(pt)

	# 颜色切换
	if time_diff_active:
		var purple := Color(0.7, 0.25, 0.95, 0.7)
		_connection_line.default_color = purple.lerp(Color(1.0, 0.35, 0.5, 0.8), absf(sin(_t * 2.5)) * 0.4)
	else:
		_connection_line.default_color = portal_a_color


# ============================================================
# 过去回响覆盖层
# ============================================================

func _create_past_overlay() -> void:
	_past_overlay = ColorRect.new()
	_past_overlay.name = "PastOverlay"
	_past_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_past_overlay.color = Color(0, 0, 0, 0)
	_past_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# 挂到最顶层 CanvasLayer
	var cl := CanvasLayer.new()
	cl.layer = 5
	cl.add_child(_past_overlay)
	add_child(cl)


# ============================================================
# CTC 开关（仅过去态可见）
# ============================================================

func _create_switch() -> void:
	_switch_area = Area2D.new()
	_switch_area.name = "CTCSwitch"
	_switch_area.position = switch_pos
	_switch_area.collision_layer = 0
	_switch_area.collision_mask = 2
	_switch_area.monitoring = false
	_switch_area.monitorable = false

	var col := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(40, 40)
	col.shape = rect
	_switch_area.add_child(col)

	_switch_area.body_entered.connect(_on_switch_entered)

	# 视觉
	_switch_sprite = Polygon2D.new()
	_switch_sprite.name = "SwitchSprite"
	_switch_sprite.color = Color(1.0, 0.85, 0.3, 0.0)
	_switch_sprite.polygon = PackedVector2Array([
		Vector2(0, -14), Vector2(10, 0),
		Vector2(0, 14), Vector2(-10, 0),
	])
	_switch_area.add_child(_switch_sprite)

	add_child(_switch_area)


func _on_switch_entered(body: Node2D) -> void:
	if not body.is_in_group("player") or not ctc_past_active or switch_activated:
		return
	switch_activated = true
	# 视觉反馈
	_switch_sprite.color = Color(1.0, 0.85, 0.3, 0.95)
	_switch_sprite.scale = Vector2(1.8, 1.8)
	var tw := create_tween()
	tw.tween_property(_switch_sprite, "scale", Vector2(1.3, 1.3), 0.3)
	# 解锁 CTC 图鉴
	CodexManager.unlock("ctc")
	AudioManager.play_sfx("fragment_collect")


# ============================================================
# 拖拽逻辑
# ============================================================

func _process(delta: float) -> void:
	_t += delta
	_cooldown_remaining = maxf(0.0, _cooldown_remaining - delta)
	_update_connection_line()
	_update_past_overlay()
	_update_switch_visual()
	_handle_drag()
	_check_gravity_overlap()
	_check_paradox()


func _handle_drag() -> void:
	var player := _get_player()
	if not player:
		return

	var dist := player.global_position.distance_to(_portal_b.global_position)

	if Input.is_action_just_pressed("grab") and dist < grab_range and not _dragging:
		_dragging = true

	if Input.is_action_just_released("grab") and _dragging:
		_dragging = false

	if _dragging:
		# Portal B 跟随玩家
		var target := player.global_position + grab_offset
		_portal_b.global_position = _portal_b.global_position.lerp(target, 0.3)


func _check_gravity_overlap() -> void:
	# 检测 Portal B 是否与任何 GravityZone 重叠
	var was_active := time_diff_active
	time_diff_active = false
	for area in _portal_b.get_overlapping_areas():
		if area.has_method("_tween_to") or area.get("gravity_scale") != null:
			time_diff_active = true
			break
	if time_diff_active != was_active:
		if time_diff_active:
			CodexManager.unlock("wormhole")


func _check_paradox() -> void:
	if not ctc_past_active or not _has_past_self:
		return
	var player := _get_player()
	if not player:
		return
	if player.global_position.distance_to(_past_self_pos) < 80.0:
		_trigger_paradox()


func _trigger_paradox() -> void:
	# 全屏白色闪光
	_past_overlay.color = Color(1, 1, 1, 0.9)
	var tw := create_tween()
	tw.tween_property(_past_overlay, "color", Color(1, 0.3, 0.3, 0.0), 1.2)
	# 解锁祖父悖论图鉴
	CodexManager.unlock("grandfather_paradox")
	# 谜题重置
	await get_tree().create_timer(0.8).timeout
	GameState.reset_current_puzzle()


# ============================================================
# 传送逻辑
# ============================================================

func _on_portal_a_entered(body: Node2D) -> void:
	if not body.is_in_group("player") or _cooldown_remaining > 0.0:
		return
	if not time_diff_active:
		return  # 无时间差，普通传送不可用
	if ctc_past_active:
		return  # 已在过去态

	# 进入过去回响
	_teleport(body, _portal_a, _portal_b)
	ctc_past_active = true
	PlayerMetrics.wormhole_loop_count += 1


func _on_portal_b_entered(body: Node2D) -> void:
	if not body.is_in_group("player") or _cooldown_remaining > 0.0:
		return
	if not ctc_past_active:
		return  # 现在态下 B 不通向 A

	# 返回现在
	_teleport(body, _portal_b, _portal_a)
	ctc_past_active = false


func _teleport(player: Node2D, from_portal: Area2D, to_portal: Area2D) -> void:
	# 记录过去自己位置（悖论检测用）
	if ctc_past_active:
		# 从过去返回现在，清除
		_has_past_self = false
	else:
		# 从现在进入过去，记录位置
		_past_self_pos = player.global_position
		_has_past_self = true

	_cooldown_remaining = cooldown
	player.global_position = to_portal.global_position + Vector2(40, -40)
	player.velocity = Vector2.ZERO
	AudioManager.play_sfx("fragment_collect")


# ============================================================
# 视觉更新
# ============================================================

func _update_past_overlay() -> void:
	if ctc_past_active:
		var pulse := 0.18 + sin(_t * 1.5) * 0.06
		_past_overlay.color = Color(past_tint.r, past_tint.g, past_tint.b, pulse)
	else:
		_past_overlay.color = _past_overlay.color.lerp(Color(0, 0, 0, 0), 0.1)


func _update_switch_visual() -> void:
	if not _switch_sprite or not _switch_area:
		return
	var active := ctc_past_active and not switch_activated
	_switch_area.monitoring = active
	_switch_area.monitorable = active
	if not switch_activated:
		_switch_sprite.color.a = 0.7 if active else 0.0
		_switch_sprite.rotation += 0.03 if active else 0.0


func _get_player() -> Node2D:
	return get_tree().get_first_node_in_group("player")


# ============================================================
# 重置
# ============================================================

func reset_state() -> void:
	_dragging = false
	_cooldown_remaining = 0.0
	time_diff_active = false
	ctc_past_active = false
	switch_activated = false
	_has_past_self = false
	_portal_b.position = _portal_b_spawn
	_past_overlay.color = Color(0, 0, 0, 0)
	if _switch_sprite:
		_switch_sprite.color.a = 0.0
		_switch_sprite.scale = Vector2(1.0, 1.0)
