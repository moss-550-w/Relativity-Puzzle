extends CanvasLayer
## 科幻风格 HUD
## 左下：环形速度仪表（speed/c）+ 中心 γ 时间倍率读数
## 顶部：场景时间流速条
## 解锁 toast：辉光弹出


const Player = preload("res://scripts/player/player.gd")
const SpeedTimeCoupling = preload("res://scripts/mechanics/speed_time_coupling.gd")
const HudGauge = preload("res://scripts/ui/hud_gauge.gd")

# 配色（引用中央调色板）
const C_CYAN := Palette.C_CYAN
const C_BLUE := Palette.C_BLUE
const C_RED := Palette.C_RED
const C_PANEL_BG := Palette.C_PANEL_BG
const C_PANEL_EDGE := Palette.C_PANEL_EDGE

# 节点引用
var _gauge: Control
var _gamma_label: Label          # 仪表中心 γ 时间倍率
var _speed_value: Label          # 仪表下方 % c
var _scale_bar_fill: ColorRect   # 顶部时间流速条填充
var _scale_bar_label: Label
var _warn_panel: Panel           # 红线警告覆盖边框
var _toast_panel: Panel
var _toast_label: Label
var _toast_timer: Timer

var _warn_pulse: float = 0.0


func _ready() -> void:
	_build_ui()
	TimeManager.scene_time_scale_changed.connect(_on_scale_changed)
	CodexManager.entry_unlocked.connect(_on_entry_unlocked)
	_on_scale_changed(TimeManager.scene_time_scale)


# ============================================================
# UI 构建
# ============================================================

func _build_ui() -> void:
	var root := Control.new()
	root.name = "Root"
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	_build_top_bar(root)
	_build_gauge_panel(root)
	_build_warn_overlay(root)
	_build_toast(root)


## 顶部场景时间流速条
func _build_top_bar(root: Control) -> void:
	var panel := _make_panel(Vector2(360, 56))
	panel.position = Vector2(24, 20)
	root.add_child(panel)

	var title := Label.new()
	title.text = "▶ 场景时间流速 SCENE-TIME FLOW"
	title.position = Vector2(14, 6)
	title.add_theme_font_size_override("font_size", 11)
	title.add_theme_color_override("font_color", C_CYAN)
	panel.add_child(title)

	# 进度条背景
	var bar_bg := ColorRect.new()
	bar_bg.position = Vector2(14, 30)
	bar_bg.size = Vector2(280, 14)
	bar_bg.color = Color(0.08, 0.16, 0.24, 0.9)
	panel.add_child(bar_bg)

	_scale_bar_fill = ColorRect.new()
	_scale_bar_fill.position = Vector2(14, 30)
	_scale_bar_fill.size = Vector2(20, 14)
	_scale_bar_fill.color = C_CYAN
	panel.add_child(_scale_bar_fill)

	_scale_bar_label = Label.new()
	_scale_bar_label.text = "x1.00"
	_scale_bar_label.position = Vector2(304, 26)
	_scale_bar_label.add_theme_font_size_override("font_size", 18)
	_scale_bar_label.add_theme_color_override("font_color", Color.WHITE)
	panel.add_child(_scale_bar_label)


## 左下环形速度仪表
func _build_gauge_panel(root: Control) -> void:
	var panel := _make_panel(Vector2(180, 200))
	# 显式锚定左下角（避免 preset 重置 offset 导致塌缩）
	panel.anchor_left = 0.0
	panel.anchor_right = 0.0
	panel.anchor_top = 1.0
	panel.anchor_bottom = 1.0
	panel.offset_left = 24.0
	panel.offset_right = 204.0
	panel.offset_top = -224.0
	panel.offset_bottom = -24.0
	root.add_child(panel)

	_gauge = Control.new()
	_gauge.set_script(HudGauge)
	_gauge.position = Vector2(15, 24)
	_gauge.size = Vector2(150, 150)
	panel.add_child(_gauge)

	# 中心 γ 时间倍率
	_gamma_label = Label.new()
	_gamma_label.text = "1.00"
	_gamma_label.position = Vector2(15, 78)
	_gamma_label.size = Vector2(150, 30)
	_gamma_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_gamma_label.add_theme_font_size_override("font_size", 28)
	_gamma_label.add_theme_color_override("font_color", Color.WHITE)
	panel.add_child(_gamma_label)

	var gamma_tag := Label.new()
	gamma_tag.text = "γ FACTOR"
	gamma_tag.position = Vector2(15, 108)
	gamma_tag.size = Vector2(150, 16)
	gamma_tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	gamma_tag.add_theme_font_size_override("font_size", 10)
	gamma_tag.add_theme_color_override("font_color", C_CYAN)
	panel.add_child(gamma_tag)

	# 底部速度 %c
	_speed_value = Label.new()
	_speed_value.text = "0.0 %c"
	_speed_value.position = Vector2(15, 172)
	_speed_value.size = Vector2(150, 20)
	_speed_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_speed_value.add_theme_font_size_override("font_size", 14)
	_speed_value.add_theme_color_override("font_color", C_BLUE)
	panel.add_child(_speed_value)


## 红线警告全屏边框
func _build_warn_overlay(root: Control) -> void:
	_warn_panel = Panel.new()
	_warn_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_warn_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0, 0, 0, 0)
	sb.border_color = C_RED
	sb.set_border_width_all(0)
	sb.set_corner_radius_all(0)
	_warn_panel.add_theme_stylebox_override("panel", sb)
	_warn_panel.visible = false
	root.add_child(_warn_panel)


## 解锁 toast
func _build_toast(root: Control) -> void:
	_toast_panel = _make_panel(Vector2(520, 64))
	# 显式锚定底部居中
	_toast_panel.anchor_left = 0.5
	_toast_panel.anchor_right = 0.5
	_toast_panel.anchor_top = 1.0
	_toast_panel.anchor_bottom = 1.0
	_toast_panel.offset_left = -260.0
	_toast_panel.offset_right = 260.0
	_toast_panel.offset_top = -224.0
	_toast_panel.offset_bottom = -160.0
	_toast_panel.visible = false
	root.add_child(_toast_panel)

	var icon := Label.new()
	icon.text = "◆"
	icon.position = Vector2(18, 16)
	icon.add_theme_font_size_override("font_size", 28)
	icon.add_theme_color_override("font_color", Color(1, 0.85, 0.3))
	_toast_panel.add_child(icon)

	_toast_label = Label.new()
	_toast_label.text = ""
	_toast_label.position = Vector2(56, 8)
	_toast_label.size = Vector2(450, 48)
	_toast_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_toast_label.add_theme_font_size_override("font_size", 20)
	_toast_label.add_theme_color_override("font_color", Color(1, 0.95, 0.7))
	_toast_panel.add_child(_toast_label)

	_toast_timer = Timer.new()
	_toast_timer.one_shot = true
	_toast_timer.wait_time = 3.5
	_toast_timer.timeout.connect(_on_toast_timer_timeout)
	add_child(_toast_timer)


## 通用辉光面板工厂
func _make_panel(panel_size: Vector2) -> Panel:
	var p := Panel.new()
	p.size = panel_size
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := StyleBoxFlat.new()
	sb.bg_color = C_PANEL_BG
	sb.border_color = C_PANEL_EDGE
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(6)
	# 左上角强调
	sb.border_width_left = 4
	sb.shadow_color = Color(0.1, 0.6, 1.0, 0.25)
	sb.shadow_size = 8
	p.add_theme_stylebox_override("panel", sb)
	return p


# ============================================================
# 每帧更新
# ============================================================

func _process(delta: float) -> void:
	var player := get_tree().get_first_node_in_group("player") as Player
	var speed: float = player.velocity.length() if player else 0.0
	var c_ratio: float = speed / SpeedTimeCoupling.LIGHT_SPEED
	var rr: float = SpeedTimeCoupling.get_redline_ratio(speed)

	# 仪表颜色：常态青，临红线渐变红
	var gauge_col := C_CYAN.lerp(C_RED, rr)
	if _gauge and _gauge.has_method("set_values"):
		_gauge.set_values(c_ratio, gauge_col)

	_speed_value.text = "%.1f %%c" % (c_ratio * 100.0)
	_speed_value.add_theme_color_override("font_color", C_BLUE.lerp(C_RED, rr))

	# γ 因子
	var gamma := TimeManager.player_lorentz_factor
	_gamma_label.text = "%.2f" % gamma
	_gamma_label.add_theme_color_override("font_color", Color.WHITE.lerp(C_RED, rr))

	# 红线警告边框脉冲
	if rr > 0.3:
		_warn_panel.visible = true
		_warn_pulse += delta * 8.0
		var alpha := (sin(_warn_pulse) * 0.5 + 0.5) * rr
		var sb := _warn_panel.get_theme_stylebox("panel") as StyleBoxFlat
		if sb:
			sb.set_border_width_all(int(lerpf(2.0, 10.0, rr)))
			sb.border_color = Color(C_RED.r, C_RED.g, C_RED.b, alpha)
	else:
		_warn_panel.visible = false
		_warn_pulse = 0.0


# ============================================================
# 信号回调
# ============================================================

func _on_scale_changed(new_scale: float) -> void:
	# 顶部时间流速条：x1 → x10 映射满条 280px
	var t := clampf((new_scale - 1.0) / 9.0, 0.0, 1.0)
	_scale_bar_fill.size.x = lerpf(20.0, 280.0, t)
	_scale_bar_label.text = "x%.2f" % new_scale

	var col := C_CYAN
	if new_scale > 3.0:
		col = C_BLUE
	elif new_scale > 1.5:
		col = C_CYAN.lerp(C_BLUE, 0.5)
	_scale_bar_fill.color = col
	_scale_bar_label.add_theme_color_override("font_color", col.lerp(Color.WHITE, 0.5))


func _on_entry_unlocked(entry_id: String, entry_data: Dictionary) -> void:
	_show_toast("图鉴解锁  " + entry_data.get("name", entry_id))


func _show_toast(msg: String) -> void:
	_toast_label.text = msg
	_toast_panel.visible = true
	_toast_panel.modulate = Color(1, 1, 1, 0)
	# 淡入
	var tw := create_tween()
	tw.tween_property(_toast_panel, "modulate", Color.WHITE, 0.3)
	_toast_timer.start()


func _on_toast_timer_timeout() -> void:
	var tw := create_tween()
	tw.tween_property(_toast_panel, "modulate", Color(1, 1, 1, 0), 0.5)
	tw.tween_callback(func(): _toast_panel.visible = false)
