extends Control
## 麦克斯韦妖 — 熵、信息与第二定律（World 4 趣味挑战）
## 鼠标 对准闸门高度 | 按住 空格/左键 开门分拣 | E/Shift 擦除记忆(全局熵↑) | R 重置 | ESC 返回
## 目标：把热(红)分子赶向右腔、冷(蓝)分子赶向左腔，局部有序度 ≥ 70% 解锁图鉴
## 科普核心：擦除记忆必然推高全局熵——局部可降熵，全局熵永不下降（兰道尔原理）
##
## 注意：本小游戏使用【局部】熵计量 _global_entropy，刻意不写入全局 EntropySystem，
## 以免污染世界4正式关卡的熵状态（向下兼容，互不干扰）。


const C_CYAN: Color = Palette.C_CYAN   # 冷 / 慢
const C_RED: Color = Palette.C_RED     # 热 / 快
const C_GOLD: Color = Palette.C_GOLD   # 成功
const C_DIM: Color = Palette.C_DIM

# 仿真箱（左=冷腔 / 右=热腔，中央隔墙在 WALL_X）
const BOX: Rect2 = Rect2(300, 124, 680, 468)   # left=300 right=980 top=124 bottom=592
const WALL_X: float = 640.0
const GATE_HALF: float = 44.0                  # 闸门口半高
const PARTICLE_RADIUS: float = 6.0
const PARTICLE_COUNT: int = 24
const HOT_SPEED_MIN: float = 175.0
const HOT_SPEED_MAX: float = 250.0
const COLD_SPEED_MIN: float = 60.0
const COLD_SPEED_MAX: float = 115.0

# 记忆缓冲 / 兰道尔擦除代价
const MEMORY_BITS: int = 8
const ERASE_ENTROPY_COST: float = 0.08
const GATE_COOLDOWN: float = 0.6
const TARGET_SEPARATION: float = 0.70          # 目标分离度（局部有序度）

# 每个分子：{ pos:Vector2, vel:Vector2, hot:bool, trail:Array[Vector2] }
var _particles: Array = []
var _gate_y: float = 358.0
var _gate_open: bool = false
var _gate_cooldown: float = 0.0
var _memory_used: int = 0
var _local_order: float = 0.5                  # [0,1] 处于正确腔室的分子比例
var _sorted_ok: int = 0                         # 有效分拣次数
var _passes: int = 0                            # 总放行次数
var _global_entropy: float = 0.0                # 局部全局熵计量（仅擦除时阶跃上升）
var _completed: bool = false
var _t: float = 0.0

var _stars: Array = []


func _ready() -> void:
	_init_stars()
	_spawn_particles()
	_build_hud()
	TransitionLayer.fade_in()
	_show_toast("把热分子(红)赶向右侧、冷分子(蓝)赶向左侧")


func _init_stars() -> void:
	_stars = Palette.make_stars(48, 1280.0, 720.0)


func _spawn_particles() -> void:
	_particles.clear()
	for i in PARTICLE_COUNT:
		var hot: bool = i % 2 == 0
		var speed: float = randf_range(HOT_SPEED_MIN, HOT_SPEED_MAX) if hot else randf_range(COLD_SPEED_MIN, COLD_SPEED_MAX)
		var ang: float = randf_range(0.0, TAU)
		# 初始故意"错位"：热分子多在冷腔(左)、冷分子多在热腔(右)，制造分拣需求
		var wrong_side: bool = randf() < 0.78
		var on_left: bool = wrong_side if hot else not wrong_side
		var x: float
		if on_left:
			x = randf_range(BOX.position.x + 24.0, WALL_X - 30.0)
		else:
			x = randf_range(WALL_X + 30.0, BOX.position.x + BOX.size.x - 24.0)
		var y: float = randf_range(BOX.position.y + 24.0, BOX.position.y + BOX.size.y - 24.0)
		_particles.append({
			"pos": Vector2(x, y),
			"vel": Vector2(cos(ang), sin(ang)) * speed,
			"hot": hot,
			"trail": [],
		})


func _build_hud() -> void:
	var title: Label = Label.new()
	title.text = "◆  麦克斯韦妖"
	title.position = Vector2(28, 16)
	title.size = Vector2(220, 30)
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", C_CYAN)
	add_child(title)

	var subtitle: Label = Label.new()
	subtitle.text = "熵 · 信息 · 第二定律"
	subtitle.position = Vector2(200, 24)
	subtitle.size = Vector2(220, 20)
	subtitle.add_theme_font_size_override("font_size", 12)
	subtitle.add_theme_color_override("font_color", Color(C_CYAN.r, C_CYAN.g, C_CYAN.b, 0.4))
	add_child(subtitle)

	var hint: Label = Label.new()
	hint.text = "鼠标对准闸门高度    按住 空格/左键 开门分拣    E 擦除记忆(熵↑)    R 重置    ESC 返回"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.set_anchors_preset(PRESET_CENTER_BOTTOM)
	hint.position = Vector2(-480, -34)
	hint.size = Vector2(960, 24)
	hint.add_theme_font_size_override("font_size", 12)
	hint.add_theme_color_override("font_color", Color(0.3, 0.5, 0.7, 0.55))
	add_child(hint)

	var done: Label = Label.new()
	done.name = "DoneLabel"
	done.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	done.position = Vector2(300, 600)
	done.size = Vector2(680, 26)
	done.add_theme_font_size_override("font_size", 15)
	done.add_theme_color_override("font_color", C_GOLD)
	done.visible = false
	add_child(done)


# ============================================================
# 每帧
# ============================================================

func _process(delta: float) -> void:
	_t += delta
	if _completed:
		queue_redraw()
		return
	_gate_cooldown = maxf(0.0, _gate_cooldown - delta)
	_update_gate_state()
	_simulate(delta)
	_recompute_order()
	_check_state()
	queue_redraw()


func _update_gate_state() -> void:
	# 闸门高度跟随鼠标，限制在隔墙可开区间内
	var my: float = get_local_mouse_position().y
	_gate_y = clampf(my, BOX.position.y + GATE_HALF, BOX.position.y + BOX.size.y - GATE_HALF)
	# 开门条件：输入按住 + 记忆未满 + 非冷却
	var want_open: bool = Input.is_action_pressed("jump") or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	_gate_open = want_open and _memory_used < MEMORY_BITS and _gate_cooldown <= 0.0


func _simulate(delta: float) -> void:
	var left: float = BOX.position.x + PARTICLE_RADIUS
	var right: float = BOX.position.x + BOX.size.x - PARTICLE_RADIUS
	var top: float = BOX.position.y + PARTICLE_RADIUS
	var bottom: float = BOX.position.y + BOX.size.y - PARTICLE_RADIUS

	for m in _particles:
		var pos: Vector2 = m["pos"]
		var vel: Vector2 = m["vel"]
		var prev: Vector2 = pos
		pos += vel * delta

		# 中央墙横向穿越判定
		if (prev.x - WALL_X) * (pos.x - WALL_X) <= 0.0 and not is_equal_approx(prev.x, WALL_X):
			var denom: float = pos.x - prev.x
			var tcross: float = 0.0 if is_zero_approx(denom) else (WALL_X - prev.x) / denom
			var cross_y: float = prev.y + (pos.y - prev.y) * tcross
			var can_pass: bool = _gate_open and _memory_used < MEMORY_BITS and absf(cross_y - _gate_y) < GATE_HALF
			if can_pass:
				_register_pass(m, prev.x < WALL_X)
			else:
				# 撞墙反弹并退回原侧，避免穿墙
				vel.x = -vel.x
				pos.x = WALL_X - (PARTICLE_RADIUS + 1.0) if prev.x < WALL_X else WALL_X + (PARTICLE_RADIUS + 1.0)

		# 外框反弹
		if pos.x < left:
			pos.x = left
			vel.x = absf(vel.x)
		elif pos.x > right:
			pos.x = right
			vel.x = -absf(vel.x)
		if pos.y < top:
			pos.y = top
			vel.y = absf(vel.y)
		elif pos.y > bottom:
			pos.y = bottom
			vel.y = -absf(vel.y)

		m["pos"] = pos
		m["vel"] = vel

		var trail: Array = m["trail"]
		trail.push_front(pos)
		if trail.size() > 6:
			trail.pop_back()


func _register_pass(m: Dictionary, going_right: bool) -> void:
	# 每放行一个分子消耗 1 bit 记忆；判定分拣方向是否正确
	_memory_used += 1
	_passes += 1
	var correct: bool = (going_right and m["hot"]) or (not going_right and not m["hot"])
	if correct:
		_sorted_ok += 1
		AudioManager.play_sfx("order_collect")
	else:
		AudioManager.play_sfx("redline_bounce")


func _recompute_order() -> void:
	# 局部有序度 = 处于"正确"腔室的分子比例（热在右 / 冷在左）
	var correct_count: int = 0
	for m in _particles:
		var on_right: bool = m["pos"].x >= WALL_X
		if (on_right and m["hot"]) or (not on_right and not m["hot"]):
			correct_count += 1
	_local_order = float(correct_count) / float(_particles.size())


func _check_state() -> void:
	if _local_order >= TARGET_SEPARATION:
		_complete()
	elif _global_entropy >= 1.0:
		# 全局熵触顶：裂隙崩解，区段重置（图鉴不回退）
		AudioManager.play_sfx("fissure_warning")
		_reset_segment()


# ============================================================
# 擦除 / 完成 / 重置
# ============================================================

func _erase_memory() -> void:
	if _completed or _memory_used == 0:
		return
	# 兰道尔原理：擦除信息必然耗散热量 → 全局熵阶跃上升，第二定律不可违背
	_memory_used = 0
	_gate_cooldown = GATE_COOLDOWN
	_gate_open = false
	_global_entropy = minf(1.0, _global_entropy + ERASE_ENTROPY_COST)
	AudioManager.play_sfx("platform_crumble")


func _complete() -> void:
	if _completed:
		return
	_completed = true
	_gate_open = false
	GameState.mark_minigame_completed("maxwell_demon")
	CodexManager.unlock("maxwell_demon")
	CodexManager.unlock("landauer_principle")
	AudioManager.play_sfx("ui_confirm")
	AudioManager.play_sfx("fragment_collect")

	var done: Label = get_node_or_null("DoneLabel") as Label
	if done:
		done.text = "✓ 局部秩序达成！但全局熵从未下降——这正是时间箭头的方向。ESC 返回"
		done.visible = true
		done.modulate = Color(1, 1, 1, 0)
		var tw: Tween = create_tween()
		tw.tween_property(done, "modulate", Color.WHITE, 0.5)

	_show_toast("图鉴解锁：麦克斯韦妖 与 兰道尔原理")


func _reset_segment() -> void:
	_spawn_particles()
	_memory_used = 0
	_gate_cooldown = 0.0
	_global_entropy = 0.0
	_sorted_ok = 0
	_passes = 0
	_local_order = 0.5
	_completed = false
	_gate_open = false
	var done: Label = get_node_or_null("DoneLabel") as Label
	if done:
		done.visible = false


# ============================================================
# 绘制
# ============================================================

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.02, 0.03, 0.08, 1.0), true)
	_draw_starfield()
	_draw_chambers()
	_draw_box_and_wall()
	_draw_particles()
	_draw_hud_panel()


func _draw_starfield() -> void:
	Palette.draw_starfield(self, _stars)


func _draw_chambers() -> void:
	var l_cold: int = 0
	var l_tot: int = 0
	var r_hot: int = 0
	var r_tot: int = 0
	for m in _particles:
		if m["pos"].x < WALL_X:
			l_tot += 1
			if not m["hot"]:
				l_cold += 1
		else:
			r_tot += 1
			if m["hot"]:
				r_hot += 1
	var l_ratio: float = float(l_cold) / l_tot if l_tot > 0 else 0.0
	var r_ratio: float = float(r_hot) / r_tot if r_tot > 0 else 0.0

	var lrect: Rect2 = Rect2(BOX.position.x, BOX.position.y, WALL_X - BOX.position.x, BOX.size.y)
	var rrect: Rect2 = Rect2(WALL_X, BOX.position.y, BOX.position.x + BOX.size.x - WALL_X, BOX.size.y)
	draw_rect(lrect, Color(0.04, 0.06, 0.14, 0.5), true)
	draw_rect(lrect, Color(C_CYAN.r, C_CYAN.g, C_CYAN.b, 0.04 + 0.16 * l_ratio), true)
	draw_rect(rrect, Color(0.12, 0.05, 0.06, 0.5), true)
	draw_rect(rrect, Color(C_RED.r, C_RED.g, C_RED.b, 0.04 + 0.16 * r_ratio), true)

	var font: Font = ThemeDB.fallback_font
	draw_string(font, Vector2(BOX.position.x + 16.0, BOX.position.y + 26.0), "冷腔（慢分子）", 0, -1, 13, Color(C_CYAN.r, C_CYAN.g, C_CYAN.b, 0.65))
	draw_string(font, Vector2(WALL_X + 16.0, BOX.position.y + 26.0), "热腔（快分子）", 0, -1, 13, Color(C_RED.r, C_RED.g, C_RED.b, 0.75))


func _draw_box_and_wall() -> void:
	# 外框
	draw_rect(BOX, Color(0.3, 0.55, 0.8, 0.55), false, 2.0)

	# 中央墙（闸门口上下两段）
	var gate_top: float = _gate_y - GATE_HALF
	var gate_bot: float = _gate_y + GATE_HALF
	var wall_col: Color = Color(0.45, 0.55, 0.7, 0.9)
	draw_line(Vector2(WALL_X, BOX.position.y), Vector2(WALL_X, gate_top), wall_col, 4.0)
	draw_line(Vector2(WALL_X, gate_bot), Vector2(WALL_X, BOX.position.y + BOX.size.y), wall_col, 4.0)

	# 闸门口状态色
	var openable: bool = _memory_used < MEMORY_BITS and _gate_cooldown <= 0.0
	var gate_col: Color
	if _gate_open:
		gate_col = C_GOLD
	elif not openable:
		gate_col = Color(0.55, 0.5, 0.55, 0.6)   # 记忆满 / 冷却中
	else:
		gate_col = C_CYAN

	# 门框横标
	draw_line(Vector2(WALL_X - 9.0, gate_top), Vector2(WALL_X + 9.0, gate_top), gate_col, 2.0)
	draw_line(Vector2(WALL_X - 9.0, gate_bot), Vector2(WALL_X + 9.0, gate_bot), gate_col, 2.0)
	if _gate_open:
		var glow: float = 0.35 + 0.2 * sin(_t * 10.0)
		draw_line(Vector2(WALL_X, gate_top), Vector2(WALL_X, gate_bot), Color(gate_col.r, gate_col.g, gate_col.b, glow), 10.0)
	else:
		draw_line(Vector2(WALL_X, gate_top), Vector2(WALL_X, gate_bot), Color(gate_col.r, gate_col.g, gate_col.b, 0.22), 3.0)


func _draw_particles() -> void:
	for m in _particles:
		var base: Color = C_RED if m["hot"] else C_CYAN
		var trail: Array = m["trail"]
		for ti in trail.size():
			var ta: float = 0.3 * (1.0 - float(ti) / trail.size())
			draw_circle(trail[ti], PARTICLE_RADIUS * 0.5, Color(base.r, base.g, base.b, ta))
		var pos: Vector2 = m["pos"]
		draw_circle(pos, PARTICLE_RADIUS + 3.0, Color(base.r, base.g, base.b, 0.25))
		draw_circle(pos, PARTICLE_RADIUS, base)


func _draw_hud_panel() -> void:
	var font: Font = ThemeDB.fallback_font

	# 面板背景
	var panel: Rect2 = Rect2(12, 12, 1256, 96)
	draw_rect(panel, Color(0.03, 0.07, 0.12, 0.82), true)
	draw_rect(panel, Palette.C_PANEL_EDGE, false, 1.0)
	draw_rect(Rect2(12, 12, 4, 96), Palette.C_PANEL_EDGE, true)

	# 记忆缓冲
	draw_string(font, Vector2(28, 74), "记忆缓冲", 0, -1, 13, C_DIM)
	for i in MEMORY_BITS:
		var r: Rect2 = Rect2(120.0 + i * 22.0, 60.0, 18.0, 18.0)
		if i < _memory_used:
			var lit: Color = C_GOLD if _memory_used < MEMORY_BITS else C_RED
			draw_rect(r, Color(lit.r, lit.g, lit.b, 0.85), true)
		else:
			draw_rect(r, Color(0.1, 0.15, 0.25, 0.8), true)
		draw_rect(r, Color(0.3, 0.45, 0.6, 0.5), false, 1.0)
	if _memory_used >= MEMORY_BITS:
		draw_string(font, Vector2(120, 100), "记忆已满！按 E 擦除（全局熵↑）", 0, -1, 11, C_RED)

	# 局部有序度
	var m1x: float = 360.0
	draw_string(font, Vector2(m1x, 44), "局部有序度", 0, -1, 12, C_CYAN)
	_draw_meter(Vector2(m1x, 52), 230.0, _local_order, C_CYAN, C_GOLD)
	var tx: float = m1x + 230.0 * TARGET_SEPARATION
	draw_line(Vector2(tx, 50), Vector2(tx, 68), C_GOLD, 1.5)   # 目标刻度
	var order_col: Color = C_GOLD if _local_order >= TARGET_SEPARATION else Color.WHITE
	draw_string(font, Vector2(m1x, 92), "%d%%  (目标 %d%%)" % [int(_local_order * 100.0), int(TARGET_SEPARATION * 100.0)], 0, -1, 12, order_col)

	# 全局熵
	var m2x: float = 720.0
	draw_string(font, Vector2(m2x, 44), "全局熵（永不下降）", 0, -1, 12, C_RED)
	_draw_meter(Vector2(m2x, 52), 230.0, _global_entropy, Color(1.0, 0.5, 0.2), C_RED)
	draw_string(font, Vector2(m2x, 92), "%d%%" % int(_global_entropy * 100.0), 0, -1, 12, C_RED)

	# 分拣效率
	var eff: float = float(_sorted_ok) / _passes if _passes > 0 else 0.0
	draw_string(font, Vector2(1070, 50), "分拣效率", 0, -1, 12, C_DIM)
	draw_string(font, Vector2(1070, 76), "%d%%  (%d/%d)" % [int(eff * 100.0), _sorted_ok, _passes], 0, -1, 13, C_GOLD)


func _draw_meter(pos: Vector2, width: float, value: float, c_low: Color, c_high: Color) -> void:
	var h: float = 12.0
	draw_rect(Rect2(pos, Vector2(width, h)), Color(0.06, 0.1, 0.2, 0.9), true)
	var v: float = clampf(value, 0.0, 1.0)
	draw_rect(Rect2(pos, Vector2(width * v, h)), c_low.lerp(c_high, v), true)
	draw_rect(Rect2(pos, Vector2(width, h)), Color(0.3, 0.45, 0.6, 0.4), false, 1.0)


# ============================================================
# 输入
# ============================================================

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		TransitionLayer.transition_to("res://scenes/ui/level_select.tscn")
	elif event.is_action_pressed("reset_puzzle"):
		_reset_segment()
	elif event.is_action_pressed("observe") or event.is_action_pressed("sprint"):
		_erase_memory()


# ============================================================
# Toast
# ============================================================

func _show_toast(msg: String) -> void:
	var toast: Panel = Panel.new()
	toast.name = "Toast"
	toast.set_anchors_preset(PRESET_CENTER_BOTTOM)
	toast.position = Vector2(-260, -160)
	toast.size = Vector2(520, 56)
	toast.modulate = Color(1, 1, 1, 0)
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = Color(0.03, 0.07, 0.12, 0.9)
	sb.border_color = C_GOLD
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(6)
	toast.add_theme_stylebox_override("panel", sb)
	add_child(toast)

	var label: Label = Label.new()
	label.text = "◆  " + msg
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.set_anchors_preset(PRESET_FULL_RECT)
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", C_GOLD)
	toast.add_child(label)

	var tw: Tween = create_tween()
	tw.tween_property(toast, "modulate", Color.WHITE, 0.3)
	tw.tween_interval(3.0)
	tw.tween_property(toast, "modulate", Color(1, 1, 1, 0), 0.5)
	tw.tween_callback(toast.queue_free)
