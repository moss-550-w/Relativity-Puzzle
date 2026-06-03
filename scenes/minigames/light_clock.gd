extends Control
## 光钟工坊 — 爱因斯坦光钟思想实验
## 左：时钟自身参考系（光子垂直反弹）
## 右：实验室参考系（光子走斜边）
## ← → 调速  |  观察 ≥30s 解锁图鉴


const HudGauge = preload("res://scripts/ui/hud_gauge.gd")
const STC = preload("res://scripts/mechanics/speed_time_coupling.gd")

const C_CYAN := Color(0.2, 0.9, 1.0)
const C_GOLD := Color(1.0, 0.85, 0.3)
const C_RED := Color(1.0, 0.25, 0.2)

const MIRROR_LENGTH: float = 180.0
const MIRROR_GAP: float = 200.0
const PHOTON_RADIUS: float = 6.0
const OBSERVE_DURATION: float = 30.0

var _speed: float = 0.0           # 当前水平速度 (px/s)
var _gamma: float = 1.0           # 洛伦兹因子
var _rest_phase: float = 0.0      # 静止钟光子相位 [0, 1]
var _moving_phase: float = 0.0    # 运动钟光子相位 [0, 1]
var _rest_ticks: int = 0
var _moving_ticks: int = 0
var _t: float = 0.0
var _observe_timer: float = 0.0
var _unlocked: bool = false
var _paused: bool = false
var _speed_dir: float = 0.0       # 按住方向

# UI 节点
var _gauge: Control = null
var _gamma_label: Label = null
var _speed_label: Label = null
var _tick_rest_label: Label = null
var _tick_move_label: Label = null
var _rest_clock: Control = null
var _moving_clock: Control = null


func _ready() -> void:
	_build_background()
	_build_hud()
	_build_clocks()
	TransitionLayer.fade_in()


func _build_background() -> void:
	var bg := ColorRect.new()
	bg.set_anchors_preset(PRESET_FULL_RECT)
	bg.color = Color(0.02, 0.03, 0.08, 1.0)
	add_child(bg)

	# 星空粒子
	for i in 40:
		var dot := ColorRect.new()
		dot.size = Vector2(1.5, 1.5)
		dot.position = Vector2(randf_range(0, 1280), randf_range(0, 720))
		dot.color = Color(0.5, 0.7, 1.0, randf_range(0.08, 0.3))
		dot.mouse_filter = MOUSE_FILTER_IGNORE
		add_child(dot)


func _build_hud() -> void:
	# 顶部面板
	var panel := Panel.new()
	panel.name = "TopPanel"
	panel.position = Vector2(140, 12)
	panel.size = Vector2(1000, 56)
	var psb := StyleBoxFlat.new()
	psb.bg_color = Color(0.03, 0.07, 0.12, 0.82)
	psb.border_color = Color(0.2, 0.8, 1.0, 0.4)
	psb.set_border_width_all(2)
	psb.border_width_left = 4
	psb.set_corner_radius_all(6)
	panel.add_theme_stylebox_override("panel", psb)
	add_child(panel)

	var title := Label.new()
	title.text = "◆  光钟工坊"
	title.position = Vector2(14, 14)
	title.size = Vector2(180, 28)
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", C_CYAN)
	panel.add_child(title)

	# 速度百分比
	_speed_label = Label.new()
	_speed_label.text = "0% c"
	_speed_label.position = Vector2(200, 16)
	_speed_label.size = Vector2(120, 24)
	_speed_label.add_theme_font_size_override("font_size", 17)
	_speed_label.add_theme_color_override("font_color", C_CYAN)
	panel.add_child(_speed_label)

	# γ 因子
	_gamma_label = Label.new()
	_gamma_label.text = "γ = 1.00"
	_gamma_label.position = Vector2(320, 16)
	_gamma_label.size = Vector2(120, 24)
	_gamma_label.add_theme_font_size_override("font_size", 17)
	_gamma_label.add_theme_color_override("font_color", Color.WHITE)
	panel.add_child(_gamma_label)

	# 环形仪表
	_gauge = Control.new()
	_gauge.set_script(HudGauge)
	_gauge.position = Vector2(460, 3)
	_gauge.size = Vector2(50, 50)
	panel.add_child(_gauge)

	# 触发提示
	var hint := Label.new()
	hint.text = "观察 30 秒解锁图鉴"
	hint.position = Vector2(540, 16)
	hint.size = Vector2(200, 24)
	hint.add_theme_font_size_override("font_size", 13)
	hint.add_theme_color_override("font_color", Color(0.4, 0.6, 0.8, 0.5))
	panel.add_child(hint)

	# 进度条
	var prog_bg := ColorRect.new()
	prog_bg.position = Vector2(740, 22)
	prog_bg.size = Vector2(200, 10)
	prog_bg.color = Color(0.06, 0.1, 0.2, 0.9)
	panel.add_child(prog_bg)

	# 底部提示
	var ctrl_hint := Label.new()
	ctrl_hint.text = "← → 调速    空格 暂停    R 重置    返回选关 ESC"
	ctrl_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ctrl_hint.set_anchors_preset(PRESET_CENTER_BOTTOM)
	ctrl_hint.position = Vector2(-400, -36)
	ctrl_hint.size = Vector2(800, 24)
	ctrl_hint.add_theme_font_size_override("font_size", 12)
	ctrl_hint.add_theme_color_override("font_color", Color(0.3, 0.5, 0.7, 0.5))
	add_child(ctrl_hint)


func _build_clocks() -> void:
	# 左面板 — 静止参考系
	var left_label := Label.new()
	left_label.text = "静止参考系（时钟自身）"
	left_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	left_label.position = Vector2(140, 90)
	left_label.size = Vector2(460, 24)
	left_label.add_theme_font_size_override("font_size", 14)
	left_label.add_theme_color_override("font_color", C_CYAN)
	add_child(left_label)

	_rest_clock = Control.new()
	_rest_clock.name = "RestClock"
	_rest_clock.position = Vector2(140, 120)
	_rest_clock.size = Vector2(460, 400)
	add_child(_rest_clock)

	# 滴答计数
	_tick_rest_label = Label.new()
	_tick_rest_label.text = "滴答: 0"
	_tick_rest_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_tick_rest_label.position = Vector2(140, 530)
	_tick_rest_label.size = Vector2(460, 24)
	_tick_rest_label.add_theme_font_size_override("font_size", 18)
	_tick_rest_label.add_theme_color_override("font_color", C_GOLD)
	add_child(_tick_rest_label)

	# 分隔线
	var divider := ColorRect.new()
	divider.position = Vector2(635, 100)
	divider.size = Vector2(2, 450)
	divider.color = Color(0.2, 0.3, 0.5, 0.3)
	add_child(divider)

	# 右面板 — 运动参考系
	var right_label := Label.new()
	right_label.text = "实验室参考系（观察者所见）"
	right_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	right_label.position = Vector2(680, 90)
	right_label.size = Vector2(460, 24)
	right_label.add_theme_font_size_override("font_size", 14)
	right_label.add_theme_color_override("font_color", Color(0.6, 0.4, 1.0))
	add_child(right_label)

	_moving_clock = Control.new()
	_moving_clock.name = "MovingClock"
	_moving_clock.position = Vector2(680, 120)
	_moving_clock.size = Vector2(460, 400)
	add_child(_moving_clock)

	# 滴答计数
	_tick_move_label = Label.new()
	_tick_move_label.text = "滴答: 0"
	_tick_move_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_tick_move_label.position = Vector2(680, 530)
	_tick_move_label.size = Vector2(460, 24)
	_tick_move_label.add_theme_font_size_override("font_size", 18)
	_tick_move_label.add_theme_color_override("font_color", Color(0.6, 0.4, 1.0))
	add_child(_tick_move_label)

	# 注入自定义 _draw() 到子 Control
	_inject_draw(_rest_clock, false)
	_inject_draw(_moving_clock, true)


# ============================================================
# 绘制时钟
# ============================================================

func _draw_clock(ci: Control, moving: bool) -> void:
	var cx: float = ci.size.x / 2.0
	var top_y: float = 40.0
	var bot_y: float = top_y + MIRROR_GAP
	var phase: float
	var photon_pos: Vector2

	if moving:
		phase = _moving_phase
		# 光子水平位移随速度和相位变化
		var offset: float = (_speed / STC.LIGHT_SPEED) * MIRROR_GAP * phase
		photon_pos = Vector2(cx + offset, lerpf(top_y, bot_y, fmod(phase * 2.0, 1.0) if fmod(phase * 2.0, 2.0) < 1.0 else 2.0 - fmod(phase * 2.0, 2.0)))
	else:
		phase = _rest_phase
		photon_pos = Vector2(cx, lerpf(top_y, bot_y, fmod(phase * 2.0, 1.0) if fmod(phase * 2.0, 2.0) < 1.0 else 2.0 - fmod(phase * 2.0, 2.0)))

	ci.draw_rect(Rect2(Vector2.ZERO, ci.size), Color(0.02, 0.03, 0.1, 0.3), true)

	# 镜面
	var mirror_col := Color(0.5, 0.6, 0.7, 0.9)
	ci.draw_rect(Rect2(cx - MIRROR_LENGTH / 2.0, top_y - 4, MIRROR_LENGTH, 8), mirror_col, true)
	ci.draw_rect(Rect2(cx - MIRROR_LENGTH / 2.0, bot_y - 4, MIRROR_LENGTH, 8), mirror_col, true)
	# 镜面辉光
	ci.draw_rect(Rect2(cx - MIRROR_LENGTH / 2.0, top_y - 6, MIRROR_LENGTH, 2), C_CYAN, true)
	ci.draw_rect(Rect2(cx - MIRROR_LENGTH / 2.0, bot_y + 4, MIRROR_LENGTH, 2), C_CYAN, true)

	if moving and _speed > 50.0:
		# 虚线直角三角形辅助线
		var offset: float = (_speed / STC.LIGHT_SPEED) * MIRROR_GAP * phase
		var px: float = cx + offset
		var h_leg_top: float = top_y + (bot_y - top_y) * (1.0 - fmod(phase, 0.5) * 2.0) if phase < 0.5 else top_y + (bot_y - top_y) * (fmod(phase, 0.5) * 2.0)
		# 水平位移
		ci.draw_line(Vector2(cx, h_leg_top), Vector2(px, h_leg_top), Color(0.4, 0.5, 0.7, 0.3), 1.0, true)
		# 垂直路径
		ci.draw_line(Vector2(cx, top_y), Vector2(cx, h_leg_top), Color(0.4, 0.5, 0.7, 0.3), 1.0, true)

	# 光子
	var photon_glow := Color(1.0, 0.9, 0.3, 0.25)
	ci.draw_circle(photon_pos, PHOTON_RADIUS + 6.0, photon_glow)
	ci.draw_circle(photon_pos, PHOTON_RADIUS, C_GOLD)

	# 拖尾
	for i in range(1, 4):
		var trail_alpha: float = 0.35 - i * 0.1
		var trail_offset := Vector2.ZERO
		if moving:
			var speed_dir: float = signf(_speed) if _speed != 0 else 1.0
			trail_offset = Vector2(-speed_dir * i * 12.0, 0)
		else:
			trail_offset = Vector2(0, signf(photon_pos.y - (top_y + bot_y) / 2.0) * i * 10.0 * (-1.0 if phase > 0.5 else 1.0))
		ci.draw_circle(photon_pos + trail_offset, PHOTON_RADIUS * 0.6, Color(1.0, 0.85, 0.3, trail_alpha))

	# 速度箭头（运动钟）
	if moving and absf(_speed) > 10.0:
		var arrow_x := cx + signf(_speed) * 80.0
		var arrow_y := bot_y + 40.0
		ci.draw_line(Vector2(cx + 60, arrow_y), Vector2(cx + 160, arrow_y), Color(0.4, 0.7, 1.0, 0.5), 1.5)
		var tip_dir := signf(_speed)
		ci.draw_line(Vector2(cx + 160, arrow_y), Vector2(cx + 152, arrow_y - 5), Color(0.4, 0.7, 1.0, 0.5), 1.5)
		ci.draw_line(Vector2(cx + 160, arrow_y), Vector2(cx + 152, arrow_y + 5), Color(0.4, 0.7, 1.0, 0.5), 1.5)


# ============================================================
# 每帧
# ============================================================

func _process(delta: float) -> void:
	if _paused:
		return
	_t += delta

	# 速度输入
	var input_dir := Input.get_axis("move_left", "move_right")
	if input_dir != 0.0:
		_speed = clampf(_speed + input_dir * 200.0 * delta, -STC.SPEED_REDLINE, STC.SPEED_REDLINE)
		_speed_dir = input_dir
	elif _speed_dir != 0.0:
		# 惯性减速
		_speed = move_toward(_speed, 0.0, 150.0 * delta)
		if absf(_speed) < 5.0:
			_speed = 0.0
			_speed_dir = 0.0

	_gamma = STC.lorentz_factor(absf(_speed))

	# 光子相位更新
	# 静止钟：滴答周期 = MIRROR_GAP / c（往返）
	var rest_period: float = MIRROR_GAP / STC.LIGHT_SPEED
	_rest_phase += delta / rest_period
	if _rest_phase >= 1.0:
		_rest_phase -= 1.0
		_rest_ticks += 1
		AudioManager.play_sfx("jump")

	# 运动钟：滴答周期 = rest_period * γ（时间膨胀）
	var moving_period: float = rest_period * _gamma
	_moving_phase += delta / moving_period
	if _moving_phase >= 1.0:
		_moving_phase -= 1.0
		_moving_ticks += 1

	# 观察计时
	_observe_timer += delta
	if _observe_timer >= OBSERVE_DURATION and not _unlocked:
		_unlocked = true
		GameState.mark_minigame_completed("light_clock")
		CodexManager.unlock("light_clock")
		_show_toast("图鉴解锁：光钟与时间膨胀")

	_update_hud()
	_rest_clock.queue_redraw()
	_moving_clock.queue_redraw()


func _update_hud() -> void:
	var c_ratio: float = absf(_speed) / STC.LIGHT_SPEED
	var rr: float = STC.get_redline_ratio(absf(_speed))

	_speed_label.text = "%.0f%% c" % (c_ratio * 100.0)
	_speed_label.add_theme_color_override("font_color", C_CYAN.lerp(C_RED, rr))

	_gamma_label.text = "γ = %.2f" % _gamma
	_gamma_label.add_theme_color_override("font_color", Color.WHITE.lerp(C_RED, rr))

	if _gauge and _gauge.has_method("set_values"):
		_gauge.set_values(c_ratio, C_CYAN.lerp(C_RED, rr))

	_tick_rest_label.text = "滴答: %d" % _rest_ticks
	_tick_move_label.text = "滴答: %d" % _moving_ticks


# ============================================================
# 绘制连接
# ============================================================

func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAW:
		if _rest_clock:
			_rest_clock.queue_redraw()
		if _moving_clock:
			_moving_clock.queue_redraw()


func _inject_draw(ci: Control, moving: bool) -> void:
	var s := GDScript.new()
	var moving_str: String = "true" if moving else "false"
	s.source_code = """extends Control

func _draw() -> void:
	var parent := get_parent()
	if parent and parent.has_method("_draw_clock"):
		parent._draw_clock(self, """ + moving_str + """)
"""
	s.reload()
	ci.set_script(s)


# ============================================================
# 输入
# ============================================================

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		TransitionLayer.transition_to("res://scenes/ui/level_select.tscn")
	elif event.is_action_pressed("reset_puzzle"):
		_reset()
	elif event.is_action_pressed("jump"):
		_paused = not _paused


func _reset() -> void:
	_speed = 0.0
	_speed_dir = 0.0
	_gamma = 1.0
	_rest_phase = 0.0
	_moving_phase = 0.0
	_rest_ticks = 0
	_moving_ticks = 0
	_observe_timer = 0.0


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
