extends Control
## 关卡选择界面 — 四大世界 · 十一关卡
## 程序化构建：星空背景、世界面板、关卡按钮、进度标记


const C_CYAN := Color(0.2, 0.9, 1.0)
const C_GOLD := Color(1.0, 0.85, 0.3)
const C_DIM := Color(0.25, 0.28, 0.35, 0.5)
const C_PANEL_BG := Color(0.03, 0.07, 0.12, 0.82)
const C_PANEL_EDGE := Color(0.2, 0.8, 1.0, 0.4)

var _particles: Array = []
var _t: float = 0.0


func _ready() -> void:
	_build_background()
	_build_title()
	_build_world_panels()
	_build_back_button()
	TransitionLayer.fade_in()


func _process(delta: float) -> void:
	_t += delta
	for dot in _particles:
		var speed: float = dot.get_meta("speed", 15.0)
		var phase: float = dot.get_meta("phase", 0.0)
		dot.position.y += speed * delta
		if dot.position.y > 730:
			dot.position.y = -10
		dot.modulate.a = 0.12 + absf(sin(_t * 1.8 + phase)) * 0.3


# ============================================================
# 星空背景
# ============================================================

func _build_background() -> void:
	var bg := ColorRect.new()
	bg.name = "Background"
	bg.set_anchors_preset(PRESET_FULL_RECT)
	bg.color = Color(0.02, 0.03, 0.08, 1.0)
	add_child(bg)

	for i in 50:
		var dot := ColorRect.new()
		dot.size = Vector2(randf_range(1.5, 3.5), randf_range(1.5, 3.5))
		dot.position = Vector2(randf_range(0, 1280), randf_range(0, 720))
		dot.color = Color(0.5, 0.7, 1.0, randf_range(0.1, 0.5))
		dot.mouse_filter = MOUSE_FILTER_IGNORE
		dot.set_meta("speed", randf_range(6.0, 20.0))
		dot.set_meta("phase", randf() * TAU)
		_particles.append(dot)
		add_child(dot)


# ============================================================
# 标题
# ============================================================

func _build_title() -> void:
	var title := Label.new()
	title.name = "Title"
	title.text = "◆  时空图 — 选择关卡"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.set_anchors_preset(PRESET_CENTER_TOP)
	title.position = Vector2(-350, 16)
	title.size = Vector2(700, 48)
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", C_CYAN)
	add_child(title)

	var subtitle := Label.new()
	subtitle.name = "Subtitle"
	subtitle.text = "四大世界 · 十一关卡"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.set_anchors_preset(PRESET_CENTER_TOP)
	subtitle.position = Vector2(-350, 60)
	subtitle.size = Vector2(700, 24)
	subtitle.add_theme_font_size_override("font_size", 13)
	subtitle.add_theme_color_override("font_color", Color(0.4, 0.6, 0.8, 0.5))
	add_child(subtitle)

	# 标题呼吸脉冲
	var glow_tween := create_tween()
	glow_tween.set_loops()
	glow_tween.tween_property(title, "theme_override_colors/font_color", Color(0.4, 1.0, 1.0, 1.0), 2.0)
	glow_tween.tween_property(title, "theme_override_colors/font_color", C_CYAN, 2.0)


# ============================================================
# 世界面板
# ============================================================

func _build_world_panels() -> void:
	var worlds: Array = GameState.LEVEL_REGISTRY.keys()
	worlds.sort()

	for wi in worlds.size():
		var world: int = worlds[wi] as int
		var data: Dictionary = GameState.LEVEL_REGISTRY[world]
		var unlocked: bool = GameState.is_world_unlocked(world)
		var y: float = 100.0 + wi * 140.0
		_build_world_panel(world, data, unlocked, y)


func _build_world_panel(world: int, data: Dictionary, unlocked: bool, y_pos: float) -> void:
	var col: Color = data.get("color", C_CYAN)
	if not unlocked:
		col = C_DIM

	# 面板背景
	var panel := Panel.new()
	panel.name = "WorldPanel_%d" % world
	panel.position = Vector2(40, y_pos)
	panel.size = Vector2(1200, 128)
	var psb := StyleBoxFlat.new()
	psb.bg_color = C_PANEL_BG
	psb.border_color = Color(col.r, col.g, col.b, 0.3)
	psb.set_border_width_all(1)
	psb.border_width_left = 3
	psb.set_corner_radius_all(6)
	psb.shadow_color = Color(col.r, col.g, col.b, 0.1)
	psb.shadow_size = 8
	panel.add_theme_stylebox_override("panel", psb)
	add_child(panel)

	# 世界名称 + 副标题
	var name_label := Label.new()
	name_label.text = "世界 %d — %s" % [world, data.get("name", "???")]
	name_label.position = Vector2(16, 10)
	name_label.size = Vector2(400, 22)
	name_label.add_theme_font_size_override("font_size", 16)
	if unlocked:
		name_label.add_theme_color_override("font_color", col)
	else:
		name_label.add_theme_color_override("font_color", C_DIM)
	panel.add_child(name_label)

	var sub_label := Label.new()
	sub_label.text = data.get("subtitle", "")
	sub_label.position = Vector2(16, 30)
	sub_label.size = Vector2(300, 16)
	sub_label.add_theme_font_size_override("font_size", 11)
	sub_label.add_theme_color_override("font_color", Color(col.r, col.g, col.b, 0.45))
	panel.add_child(sub_label)

	# 进度统计（右上角）
	var completed_count := _count_completed_in_world(world)
	var total_count: int = (data.get("levels", []) as Array).size()
	var stats := Label.new()
	stats.text = "%d / %d" % [completed_count, total_count]
	stats.position = Vector2(1120, 12)
	stats.size = Vector2(64, 18)
	stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	stats.add_theme_font_size_override("font_size", 12)
	stats.add_theme_color_override("font_color", col if completed_count == total_count else Color(col.r, col.g, col.b, 0.4))
	panel.add_child(stats)

	# 关卡按钮
	var levels: Array = data.get("levels", [])
	if levels.is_empty():
		return

	var btn_width: float = 160.0
	var btn_height: float = 44.0
	var total_btn_width: float = levels.size() * btn_width + (levels.size() - 1) * 60.0
	var start_x: float = (1200.0 - total_btn_width) / 2.0

	for li in levels.size():
		var lv: Dictionary = levels[li]
		var lv_id: int = lv["id"]
		var lv_completed: bool = GameState.is_level_completed(world, lv_id)
		var lv_unlocked: bool = GameState.is_level_unlocked(world, lv_id)
		var bx: float = start_x + li * (btn_width + 60.0)
		var by: float = 60.0

		_build_level_button(panel, world, lv, lv_completed, lv_unlocked, col, bx, by, btn_width, btn_height)

		# 连接线（非最后一个）
		if li < levels.size() - 1:
			var line := ColorRect.new()
			line.name = "Line_%d" % li
			line.position = Vector2(bx + btn_width, by + btn_height / 2.0 - 1.0)
			line.size = Vector2(60.0, 2.0)
			line.color = Color(col.r, col.g, col.b, 0.3) if lv_completed else Color(0.2, 0.24, 0.3, 0.3)
			line.mouse_filter = MOUSE_FILTER_IGNORE
			panel.add_child(line)


func _build_level_button(panel: Panel, world: int, lv: Dictionary, completed: bool, unlocked: bool, world_col: Color, x: float, y: float, w: float, h: float) -> void:
	var btn := Button.new()
	btn.name = "LevelBtn_%d_%d" % [world, lv["id"]]
	btn.position = Vector2(x, y)
	btn.size = Vector2(w, h)
	btn.add_theme_font_size_override("font_size", 13)

	var icon: String
	var label_col: Color
	if completed:
		icon = "◆"
		label_col = C_GOLD
	elif unlocked:
		icon = "◇"
		label_col = Color(0.5, 0.9, 1.0, 0.85)
	else:
		icon = "◇"
		label_col = C_DIM

	btn.text = "%s  %s" % [icon, lv.get("name", "???")]

	# 样式
	var sb := StyleBoxFlat.new()
	if completed:
		sb.bg_color = Color(world_col.r, world_col.g, world_col.b, 0.08)
		sb.border_color = C_GOLD
	elif unlocked:
		sb.bg_color = Color(world_col.r, world_col.g, world_col.b, 0.06)
		sb.border_color = Color(world_col.r, world_col.g, world_col.b, 0.45)
	else:
		sb.bg_color = Color(0.04, 0.05, 0.08, 0.5)
		sb.border_color = Color(0.15, 0.18, 0.22, 0.3)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(4)
	btn.add_theme_stylebox_override("normal", sb)

	var sb_h := StyleBoxFlat.new()
	if completed:
		sb_h.bg_color = Color(world_col.r, world_col.g, world_col.b, 0.18)
		sb_h.border_color = C_GOLD
	elif unlocked:
		sb_h.bg_color = Color(world_col.r, world_col.g, world_col.b, 0.15)
		sb_h.border_color = Color(world_col.r, world_col.g, world_col.b, 0.75)
	else:
		sb_h.bg_color = Color(0.04, 0.05, 0.08, 0.5)
		sb_h.border_color = Color(0.15, 0.18, 0.22, 0.3)
	sb_h.set_border_width_all(1)
	sb_h.set_corner_radius_all(4)
	sb_h.shadow_color = Color(world_col.r, world_col.g, world_col.b, 0.25)
	sb_h.shadow_size = 10
	btn.add_theme_stylebox_override("hover", sb_h)

	btn.add_theme_color_override("font_color", label_col)
	btn.add_theme_color_override("font_hover_color", Color(1, 1, 1, 1))

	if unlocked:
		btn.pressed.connect(_on_level_pressed.bind(lv["scene"], world, lv["id"]))
	else:
		btn.disabled = true

	panel.add_child(btn)


func _on_level_pressed(scene_path: String, world: int, level: int) -> void:
	GameState.current_world = world
	GameState.current_level = level
	TransitionLayer.transition_to(scene_path)


# ============================================================
# 返回按钮
# ============================================================

func _build_back_button() -> void:
	var btn := Button.new()
	btn.text = "←  返回主菜单"
	btn.set_anchors_preset(PRESET_CENTER_BOTTOM)
	btn.position = Vector2(-110, -50)
	btn.size = Vector2(220, 44)
	btn.add_theme_font_size_override("font_size", 16)

	var col := Color(0.5, 0.5, 0.6)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(col.r, col.g, col.b, 0.08)
	sb.border_color = Color(col.r, col.g, col.b, 0.3)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(6)
	btn.add_theme_stylebox_override("normal", sb)

	var sb_h := StyleBoxFlat.new()
	sb_h.bg_color = Color(col.r, col.g, col.b, 0.2)
	sb_h.border_color = Color(col.r, col.g, col.b, 0.6)
	sb_h.set_border_width_all(2)
	sb_h.set_corner_radius_all(6)
	sb_h.shadow_color = Color(col.r, col.g, col.b, 0.2)
	sb_h.shadow_size = 10
	btn.add_theme_stylebox_override("hover", sb_h)

	btn.add_theme_color_override("font_color", Color(0.5, 0.6, 0.7, 0.7))
	btn.add_theme_color_override("font_hover_color", Color(1, 1, 1, 1))

	btn.pressed.connect(func(): TransitionLayer.transition_to("res://scenes/ui/main_menu.tscn"))
	add_child(btn)


# ============================================================
# 输入
# ============================================================

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		TransitionLayer.transition_to("res://scenes/ui/main_menu.tscn")


# ============================================================
# 工具
# ============================================================

func _count_completed_in_world(world: int) -> int:
	var arr: Array = GameState.completed_levels.get(world, []) as Array
	return arr.size()
