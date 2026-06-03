extends Control
## 虫洞工程师 — 构建可穿越虫洞
## F 键拖拽虫洞口和卡西米尔板
## 推拢板产生负能量 → 稳定虫洞 → 信号粒子穿越


const PLATE_SIZE := Vector2(14, 70)
const PORTAL_RADIUS: float = 32.0
const PARTICLE_RADIUS: float = 5.0
const PARTICLE_SPEED: float = 160.0
const PARTICLE_INTERVAL: float = 3.0
const TARGET_TRANSPORT: int = 3
const PLATE_THRESHOLD: float = 80.0
const GRAB_RANGE: float = 100.0

const C_CYAN := Color(0.2, 0.9, 1.0)
const C_GOLD := Color(1.0, 0.85, 0.3)
const C_PURPLE := Color(0.6, 0.4, 1.0)

# 虫洞口位置
var _portal_a_pos: Vector2 = Vector2(460, 360)
var _portal_b_pos: Vector2 = Vector2(700, 360)
# 卡西米尔板 X 位置（只在 X 轴移动）
var _plate_a_x: float = 520.0
var _plate_b_x: float = 620.0
var _plate_y: float = 560.0

var _dragging: String = ""        # "portal_a" | "portal_b" | "plate_a" | "plate_b" | ""
var _drag_offset: Vector2 = Vector2.ZERO

var _neg_energy_active: bool = false
var _neg_zone_center: Vector2 = Vector2.ZERO
var _neg_zone_radius: float = 0.0
var _wormhole_stable: bool = false

# 信号粒子
var _particles: Array = []
var _particle_timer: float = 0.0
var _transported: int = 0
var _completed: bool = false

var _t: float = 0.0


func _ready() -> void:
	_build_background()
	TransitionLayer.fade_in()


func _build_background() -> void:
	var bg := ColorRect.new()
	bg.set_anchors_preset(PRESET_FULL_RECT)
	bg.color = Color(0.02, 0.03, 0.08, 1.0)
	add_child(bg)

	for i in 40:
		var dot := ColorRect.new()
		dot.size = Vector2(1.5, 1.5)
		dot.position = Vector2(randf_range(0, 1280), randf_range(0, 720))
		dot.color = Color(0.5, 0.7, 1.0, randf_range(0.08, 0.3))
		dot.mouse_filter = MOUSE_FILTER_IGNORE
		add_child(dot)

	# 标题
	var title := Label.new()
	title.text = "◆  虫洞工程师"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.position = Vector2(240, 12)
	title.size = Vector2(800, 36)
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", C_CYAN)
	add_child(title)

	# 传输计数
	var counter := Label.new()
	counter.name = "CounterLabel"
	counter.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	counter.position = Vector2(240, 46)
	counter.size = Vector2(800, 22)
	counter.add_theme_font_size_override("font_size", 14)
	counter.add_theme_color_override("font_color", Color(0.5, 0.7, 0.9, 0.6))
	counter.text = "已运输: 0 / %d" % TARGET_TRANSPORT
	add_child(counter)

	# 底部提示
	var hint := Label.new()
	hint.text = "F 拖拽虫洞口／金属板    推拢板产生负能量稳定虫洞    R 重置    ESC 返回"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.set_anchors_preset(PRESET_CENTER_BOTTOM)
	hint.position = Vector2(-500, -36)
	hint.size = Vector2(1000, 24)
	hint.add_theme_font_size_override("font_size", 12)
	hint.add_theme_color_override("font_color", Color(0.3, 0.5, 0.7, 0.5))
	add_child(hint)

	# 完成提示（初始隐藏）
	var done := Label.new()
	done.name = "DoneLabel"
	done.text = "✓  虫洞稳定！所有粒子已运输完成"
	done.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	done.position = Vector2(340, 650)
	done.size = Vector2(600, 30)
	done.add_theme_font_size_override("font_size", 16)
	done.add_theme_color_override("font_color", C_GOLD)
	done.visible = false
	add_child(done)


# ============================================================
# 每帧
# ============================================================

func _process(delta: float) -> void:
	_t += delta
	_update_neg_energy()
	_update_wormhole()
	_handle_drag()
	_update_particles(delta)
	_spawn_particles(delta)
	queue_redraw()


# ============================================================
# 负能量检测
# ============================================================

func _update_neg_energy() -> void:
	var gap: float = absf(_plate_a_x - _plate_b_x)
	_neg_energy_active = gap < PLATE_THRESHOLD
	if _neg_energy_active:
		var mid: float = (_plate_a_x + _plate_b_x) / 2.0
		_neg_zone_center = Vector2(mid, _plate_y)
		_neg_zone_radius = gap / 2.0 + PLATE_SIZE.x / 2.0


func _update_wormhole() -> void:
	var was_stable := _wormhole_stable
	_wormhole_stable = false
	if _neg_energy_active:
		for portal_pos in [_portal_a_pos, _portal_b_pos]:
			if portal_pos.distance_to(_neg_zone_center) < _neg_zone_radius + PORTAL_RADIUS:
				_wormhole_stable = true
	if _wormhole_stable and not was_stable:
		AudioManager.play_sfx("fragment_collect")


# ============================================================
# 拖拽
# ============================================================

func _handle_drag() -> void:
	if _completed:
		return
	var mouse_pos := get_global_mouse_position()

	if Input.is_action_just_pressed("grab"):
		# 检测拖哪个
		if mouse_pos.distance_to(_portal_a_pos) < GRAB_RANGE:
			_dragging = "portal_a"
			_drag_offset = _portal_a_pos - mouse_pos
		elif mouse_pos.distance_to(_portal_b_pos) < GRAB_RANGE:
			_dragging = "portal_b"
			_drag_offset = _portal_b_pos - mouse_pos
		elif absf(mouse_pos.x - _plate_a_x) < GRAB_RANGE and absf(mouse_pos.y - _plate_y) < 40.0:
			_dragging = "plate_a"
		elif absf(mouse_pos.x - _plate_b_x) < GRAB_RANGE and absf(mouse_pos.y - _plate_y) < 40.0:
			_dragging = "plate_b"

	if Input.is_action_just_released("grab"):
		_dragging = ""

	if _dragging == "portal_a":
		_portal_a_pos = mouse_pos + _drag_offset
	elif _dragging == "portal_b":
		_portal_b_pos = mouse_pos + _drag_offset
	elif _dragging == "plate_a":
		_plate_a_x = clampf(mouse_pos.x, 180.0, _plate_b_x - 20.0)
	elif _dragging == "plate_b":
		_plate_b_x = clampf(mouse_pos.x, _plate_a_x + 20.0, 1100.0)


# ============================================================
# 信号粒子
# ============================================================

func _spawn_particles(delta: float) -> void:
	if _completed:
		return
	_particle_timer += delta
	if _particle_timer >= PARTICLE_INTERVAL:
		_particle_timer = 0.0
		_particles.append({"x": 80.0, "y": 360.0, "active": true, "trail": []})


func _update_particles(delta: float) -> void:
	for p in _particles:
		if not p["active"]:
			continue
		# 移动
		p["x"] += PARTICLE_SPEED * delta
		# 拖尾
		var trail: Array = p["trail"]
		trail.push_front(Vector2(p["x"], p["y"]))
		if trail.size() > 12:
			trail.pop_back()
		# 碰到虫洞入口？
		if _wormhole_stable and absf(p["x"] - _portal_a_pos.x) < PORTAL_RADIUS + PARTICLE_RADIUS and absf(p["y"] - _portal_a_pos.y) < PORTAL_RADIUS + PARTICLE_RADIUS:
			p["x"] = _portal_b_pos.x + PORTAL_RADIUS
			p["y"] = _portal_b_pos.y
			p["trail"].clear()
			AudioManager.play_sfx("jump")
		# 到达目标区？
		if p["x"] > 1150.0 and absf(p["y"] - 360.0) < 50.0:
			p["active"] = false
			_transported += 1
			_update_counter_label()
			AudioManager.play_sfx("fragment_collect")
			if _transported >= TARGET_TRANSPORT and not _completed:
				_complete()
		# 跑出屏幕
		if p["x"] > 1320.0:
			p["active"] = false

	# 清理非活跃粒子
	var active_only: Array = []
	for p in _particles:
		if p["active"]:
			active_only.append(p)
	_particles = active_only


func _update_counter_label() -> void:
	var lbl := get_node_or_null("CounterLabel") as Label
	if lbl:
		lbl.text = "已运输: %d / %d" % [_transported, TARGET_TRANSPORT]


func _complete() -> void:
	_completed = true
	GameState.mark_minigame_completed("wormhole_engineer")
	CodexManager.unlock("traversable_wormhole")

	var done := get_node_or_null("DoneLabel") as Label
	if done:
		done.visible = true
		var tw := create_tween()
		tw.tween_property(done, "modulate", Color(1, 1, 1, 0), 0.0)
		tw.tween_property(done, "modulate", Color.WHITE, 0.5)

	_show_toast("图鉴解锁：可穿越虫洞")


# ============================================================
# 绘制
# ============================================================

func _draw() -> void:
	_draw_game_area()
	_draw_portals()
	_draw_casimir_plates()
	_draw_neg_energy_zone()
	_draw_particles()
	_draw_labels()


func _draw_game_area() -> void:
	# 发射区
	draw_rect(Rect2(40, 300, 80, 120), Color(0.04, 0.06, 0.14, 0.5), true)
	draw_line(Vector2(120, 360), Vector2(120, 360), Color(0.3, 0.6, 1.0, 0.3), 2.0)
	var emit_label_pos := Vector2(60, 430)
	draw_string(ThemeDB.fallback_font, emit_label_pos, "发射区", HORIZONTAL_ALIGNMENT_CENTER, -1, 10, Color(0.4, 0.7, 1.0, 0.4))

	# 目标区
	draw_rect(Rect2(1140, 300, 100, 120), Color(0.06, 0.04, 0.14, 0.5), true)
	# 虚线边框
	for i in range(0, 100, 12):
		draw_rect(Rect2(1140 + i, 300, 8, 2), C_GOLD * Color(1, 1, 1, 0.3), true)
		draw_rect(Rect2(1140 + i, 418, 8, 2), C_GOLD * Color(1, 1, 1, 0.3), true)
	for i in range(0, 118, 12):
		draw_rect(Rect2(1140, 300 + i, 2, 8), C_GOLD * Color(1, 1, 1, 0.3), true)
		draw_rect(Rect2(1238, 300 + i, 2, 8), C_GOLD * Color(1, 1, 1, 0.3), true)

	var target_label_pos := Vector2(1190, 430)
	draw_string(ThemeDB.fallback_font, target_label_pos, "目标区", HORIZONTAL_ALIGNMENT_CENTER, -1, 10, Color(1.0, 0.85, 0.3, 0.5))


func _draw_portals() -> void:
	for portal_pos in [_portal_a_pos, _portal_b_pos]:
		var is_entry := (portal_pos == _portal_a_pos)
		var label_text := "入口 A" if is_entry else "出口 B"
		var col: Color
		var alpha: float

		if _wormhole_stable:
			col = C_CYAN
			alpha = 0.9
		else:
			col = Color(1.0, 0.4, 0.15)
			alpha = 0.25 + sin(_t * 8.0) * 0.3

		# 外层光晕
		draw_circle(portal_pos, PORTAL_RADIUS + 8, Color(col.r, col.g, col.b, alpha * 0.2))
		draw_arc(portal_pos, PORTAL_RADIUS + 4, 0, TAU, 48, Color(col.r, col.g, col.b, alpha * 0.4), 4.0)
		draw_arc(portal_pos, PORTAL_RADIUS, 0, TAU, 48, col, 2.5)

		if _wormhole_stable:
			draw_circle(portal_pos, 8.0, Color(1.0, 1.0, 1.0, 0.6))
			# 旋转亮点
			var angle := _t * 2.5
			draw_circle(portal_pos + Vector2(cos(angle), sin(angle)) * (PORTAL_RADIUS - 3), 4.0, Color.WHITE)
			draw_circle(portal_pos + Vector2(cos(angle + PI), sin(angle + PI)) * (PORTAL_RADIUS - 3), 3.0, Color(col.r, col.g, col.b, 0.6))

		# 标签
		var lbl_pos := portal_pos + Vector2(-18, PORTAL_RADIUS + 16)
		draw_string(ThemeDB.fallback_font, lbl_pos, label_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, col)

		# [F] 指示
		var f_pos := portal_pos + Vector2(-10, PORTAL_RADIUS + 30)
		draw_string(ThemeDB.fallback_font, f_pos, "[F]", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(0.4, 0.7, 1.0, 0.5))

	# 虫洞连线
	if _wormhole_stable:
		var mid := (_portal_a_pos + _portal_b_pos) / 2.0
		var perp := (_portal_b_pos - _portal_a_pos).orthogonal().normalized() * 40.0
		var ctrl := mid + perp
		var prev_pt := _portal_a_pos
		for i in range(1, 21):
			var t_param: float = i / 20.0
			var pt := _portal_a_pos.bezier_interpolate(ctrl, ctrl, _portal_b_pos, t_param)
			draw_line(prev_pt, pt, Color(C_CYAN.r, C_CYAN.g, C_CYAN.b, 0.3 + sin(_t * 3.0 + t_param) * 0.15), 2.0, true)
			prev_pt = pt


func _draw_casimir_plates() -> void:
	var plates := [{"x": _plate_a_x, "label": "板 A"}, {"x": _plate_b_x, "label": "板 B"}]
	for p in plates:
		var px: float = p["x"]
		var rect := Rect2(px - PLATE_SIZE.x / 2.0, _plate_y - PLATE_SIZE.y / 2.0, PLATE_SIZE.x, PLATE_SIZE.y)
		draw_rect(rect, Color(0.35, 0.35, 0.45, 0.95), true)
		# 边框辉光
		var border_alpha: float = 0.6 if _neg_energy_active else 0.0
		draw_rect(Rect2(px - PLATE_SIZE.x / 2.0 - 2, _plate_y - PLATE_SIZE.y / 2.0 - 2, PLATE_SIZE.x + 4, 2), Color(0.2, 0.5, 1.0, border_alpha), true)
		draw_rect(Rect2(px - PLATE_SIZE.x / 2.0 - 2, _plate_y + PLATE_SIZE.y / 2.0, PLATE_SIZE.x + 4, 2), Color(0.2, 0.5, 1.0, border_alpha), true)

		var label_pos := Vector2(px - 12, _plate_y + PLATE_SIZE.y / 2.0 + 4)
		draw_string(ThemeDB.fallback_font, label_pos, p["label"], HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(0.4, 0.7, 1.0, 0.6))

		var f_pos := Vector2(px - 10, _plate_y + PLATE_SIZE.y / 2.0 + 18)
		draw_string(ThemeDB.fallback_font, f_pos, "[F]", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(0.4, 0.7, 1.0, 0.45))

	# 板间距离指示
	var gap: float = absf(_plate_a_x - _plate_b_x)
	var mid_x: float = (_plate_a_x + _plate_b_x) / 2.0
	draw_line(Vector2(_plate_a_x + PLATE_SIZE.x / 2.0, _plate_y - PLATE_SIZE.y / 2.0 - 10),
			  Vector2(_plate_b_x - PLATE_SIZE.x / 2.0, _plate_y - PLATE_SIZE.y / 2.0 - 10),
			  Color(0.3, 0.5, 0.7, 0.4), 1.0, true)

	var gap_color := C_GOLD if _neg_energy_active else Color(0.4, 0.5, 0.7, 0.5)
	var gap_text := "%.0f px" % gap
	var gap_pos := Vector2(mid_x - 20, _plate_y - PLATE_SIZE.y / 2.0 - 24)
	draw_string(ThemeDB.fallback_font, gap_pos, gap_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, gap_color)

	if _neg_energy_active:
		var ok_pos := Vector2(mid_x - 40, _plate_y - PLATE_SIZE.y / 2.0 - 38)
		draw_string(ThemeDB.fallback_font, ok_pos, "✓ 负能量", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, C_GOLD)


func _draw_neg_energy_zone() -> void:
	if not _neg_energy_active:
		return
	var cz: Vector2 = _neg_zone_center
	var cr: float = _neg_zone_radius
	var alpha: float = 0.18 + sin(_t * 3.0) * 0.06
	draw_circle(cz, cr, Color(0.2, 0.5, 1.0, alpha))
	draw_arc(cz, cr, 0, TAU, 48, Color(0.3, 0.6, 1.0, alpha * 1.5), 1.5)


func _draw_particles() -> void:
	for p in _particles:
		if not p["active"]:
			continue
		var pos := Vector2(p["x"], p["y"])
		# 拖尾
		var trail: Array = p["trail"]
		for ti in trail.size():
			var tp: Vector2 = trail[ti]
			var ta: float = 0.4 * (1.0 - float(ti) / trail.size())
			draw_circle(tp, PARTICLE_RADIUS * 0.5, Color(1.0, 0.85, 0.3, ta))
		# 主体
		draw_circle(pos, PARTICLE_RADIUS + 4, Color(1.0, 0.9, 0.3, 0.3))
		draw_circle(pos, PARTICLE_RADIUS, C_GOLD)


func _draw_labels() -> void:
	# 虫洞状态
	var status_text: String
	var status_col: Color
	if _wormhole_stable:
		status_text = "虫洞状态: 稳定 ◆"
		status_col = C_CYAN
	else:
		status_text = "虫洞状态: 不稳定 ◇"
		status_col = Color(1.0, 0.4, 0.15, 0.8)
	var sp := Vector2(520, 636)
	draw_string(ThemeDB.fallback_font, sp, status_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, status_col)

	if _completed:
		var cp := Vector2(520, 660)
		draw_string(ThemeDB.fallback_font, cp, "任务完成！按 ESC 返回", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, C_GOLD)


# ============================================================
# 输入
# ============================================================

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		TransitionLayer.transition_to("res://scenes/ui/level_select.tscn")
	elif event.is_action_pressed("reset_puzzle"):
		_reset()


func _reset() -> void:
	_portal_a_pos = Vector2(460, 360)
	_portal_b_pos = Vector2(700, 360)
	_plate_a_x = 520.0
	_plate_b_x = 620.0
	_dragging = ""
	_particles.clear()
	_particle_timer = 0.0
	_transported = 0
	_completed = false
	_wormhole_stable = false
	_update_counter_label()
	var done := get_node_or_null("DoneLabel") as Label
	if done:
		done.visible = false


func _show_toast(msg: String) -> void:
	var toast := Panel.new()
	toast.name = "Toast"
	toast.set_anchors_preset(PRESET_CENTER_BOTTOM)
	toast.position = Vector2(-260, -160)
	toast.size = Vector2(520, 56)
	toast.modulate = Color(1, 1, 1, 0)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.03, 0.07, 0.12, 0.9)
	sb.border_color = C_GOLD
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(6)
	toast.add_theme_stylebox_override("panel", sb)
	add_child(toast)

	var label := Label.new()
	label.text = "◆  " + msg
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.set_anchors_preset(PRESET_FULL_RECT)
	label.add_theme_font_size_override("font_size", 17)
	label.add_theme_color_override("font_color", C_GOLD)
	toast.add_child(label)

	var tw := create_tween()
	tw.tween_property(toast, "modulate", Color.WHITE, 0.3)
	tw.tween_interval(3.0)
	tw.tween_property(toast, "modulate", Color(1, 1, 1, 0), 0.5)
	tw.tween_callback(toast.queue_free)
