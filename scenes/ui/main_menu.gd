extends Control
## 主菜单 — 标题画面 + 开始/图鉴/退出 + 星空粒子背景
## 图鉴面板：侧栏分类筛选 + 卡片式词条列表 + 解锁进度


const ENTRY_ORDER: Array[String] = [
	"time_dilation", "light_speed_barrier", "light_clock", "light_cone", "twin_paradox",
	"gravitational_time_dilation", "wormhole", "traversable_wormhole", "ctc", "grandfather_paradox",
	"kerr_black_hole", "ergosphere", "ring_singularity",
	"casimir_effect", "quantum_vacuum", "chronology_protection",
	"entropy_arrow", "block_universe", "wheeler_dewitt", "time_illusion",
	"maxwell_demon", "landauer_principle",
	"physicists_cabin",
]

const CATEGORIES: Array[Dictionary] = [
	{ "id": "special_relativity", "name": "狭义相对论", "color": Color(0.3, 0.8, 1.0) },
	{ "id": "general_relativity", "name": "广义相对论", "color": Color(0.6, 0.4, 1.0) },
	{ "id": "quantum_gravity", "name": "量子引力", "color": Color(0.3, 1.0, 0.6) },
	{ "id": "entropy_cosmology", "name": "熵宇宙学", "color": Color(1.0, 0.7, 0.3) },
]

# 词条所属分类
const ENTRY_CATEGORY: Dictionary = {
	"time_dilation": 0, "light_speed_barrier": 0, "light_clock": 0, "light_cone": 0, "twin_paradox": 0,
	"gravitational_time_dilation": 1, "wormhole": 1, "traversable_wormhole": 1, "ctc": 1, "grandfather_paradox": 1,
	"kerr_black_hole": 1, "ergosphere": 1, "ring_singularity": 1,
	"casimir_effect": 2, "quantum_vacuum": 2, "chronology_protection": 2,
	"entropy_arrow": 3, "block_universe": 3, "wheeler_dewitt": 3, "time_illusion": 3,
	"maxwell_demon": 3, "landauer_principle": 3,
	"physicists_cabin": 3,
}

var _title_label: Label = null
var _codex_panel: Panel = null
var _codex_container: VBoxContainer = null
var _codex_stats: Label = null
var _codex_progress: ColorRect = null
var _category_buttons: Array[Button] = []
var _active_category: int = -1  # -1 = 全部
var _particles: Array[ColorRect] = []
var _t: float = 0.0


func _ready() -> void:
	_build_background()
	_build_title()
	_build_buttons()
	_build_codex_panel()
	_build_version()
	TransitionLayer.fade_in()


# ============================================================
# 星空粒子背景
# ============================================================

func _build_background() -> void:
	var bg := ColorRect.new()
	bg.name = "Background"
	bg.set_anchors_preset(PRESET_FULL_RECT)
	bg.color = Color(0.02, 0.03, 0.08, 1.0)
	add_child(bg)

	for i in 60:
		var dot := ColorRect.new()
		dot.size = Vector2(randf_range(1.5, 3.5), randf_range(1.5, 3.5))
		dot.position = Vector2(randf_range(0, 1280), randf_range(0, 720))
		dot.color = Color(0.5, 0.7, 1.0, randf_range(0.15, 0.6))
		dot.mouse_filter = MOUSE_FILTER_IGNORE
		dot.set_meta("speed", randf_range(8.0, 25.0))
		dot.set_meta("phase", randf() * TAU)
		_particles.append(dot)
		add_child(dot)


func _process(delta: float) -> void:
	_t += delta
	for dot in _particles:
		var speed: float = dot.get_meta("speed")
		var phase: float = dot.get_meta("phase")
		dot.position.y += speed * delta
		if dot.position.y > 730:
			dot.position.y = -10
		dot.modulate.a = 0.15 + absf(sin(_t * 2.0 + phase)) * 0.35


# ============================================================
# 标题
# ============================================================

func _build_title() -> void:
	_title_label = Label.new()
	_title_label.name = "Title"
	_title_label.text = "时空错位"
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.set_anchors_preset(PRESET_CENTER_TOP)
	_title_label.position = Vector2(-300, 100)
	_title_label.size = Vector2(600, 80)
	_title_label.add_theme_font_size_override("font_size", 52)
	_title_label.add_theme_color_override("font_color", Color(0.2, 0.8, 1.0, 1.0))
	add_child(_title_label)

	var subtitle := Label.new()
	subtitle.name = "Subtitle"
	subtitle.text = "相对论漫游"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.set_anchors_preset(PRESET_CENTER_TOP)
	subtitle.position = Vector2(-300, 160)
	subtitle.size = Vector2(600, 40)
	subtitle.add_theme_font_size_override("font_size", 28)
	subtitle.add_theme_color_override("font_color", Color(0.5, 0.7, 1.0, 0.7))
	add_child(subtitle)

	var desc := Label.new()
	desc.name = "Description"
	desc.text = "2D 横版相对论解谜游戏"
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.set_anchors_preset(PRESET_CENTER_TOP)
	desc.position = Vector2(-300, 215)
	desc.size = Vector2(600, 30)
	desc.add_theme_font_size_override("font_size", 14)
	desc.add_theme_color_override("font_color", Color(0.4, 0.5, 0.7, 0.5))
	add_child(desc)

	var glow_tween := create_tween()
	glow_tween.set_loops()
	glow_tween.tween_property(_title_label, "theme_override_colors/font_color", Color(0.4, 1.0, 1.0, 1.0), 2.0)
	glow_tween.tween_property(_title_label, "theme_override_colors/font_color", Color(0.2, 0.8, 1.0, 1.0), 2.0)


# ============================================================
# 按钮
# ============================================================

func _build_buttons() -> void:
	var btn_data := [
		{"text": "▶  开始游戏", "callback": _on_start},
		{"text": "◆  时空图鉴", "callback": _on_codex},
		{"text": "✕  退出游戏", "callback": _on_quit},
	]

	for i in btn_data.size():
		var btn := Button.new()
		btn.text = btn_data[i]["text"]
		btn.set_anchors_preset(PRESET_CENTER_TOP)
		btn.position = Vector2(-110, 290 + i * 60)
		btn.size = Vector2(220, 44)
		btn.add_theme_font_size_override("font_size", 18)
		btn.pressed.connect(btn_data[i]["callback"])
		_style_button(btn, Color(0.2, 0.6, 1.0))
		add_child(btn)


func _style_button(btn: Button, col: Color) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(col.r, col.g, col.b, 0.12)
	sb.border_color = Color(col.r, col.g, col.b, 0.5)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(6)
	sb.content_margin_left = 16
	sb.content_margin_right = 16
	btn.add_theme_stylebox_override("normal", sb)

	var sb_hover := StyleBoxFlat.new()
	sb_hover.bg_color = Color(col.r, col.g, col.b, 0.25)
	sb_hover.border_color = Color(col.r, col.g, col.b, 0.8)
	sb_hover.set_border_width_all(2)
	sb_hover.set_corner_radius_all(6)
	sb_hover.shadow_color = Color(col.r, col.g, col.b, 0.3)
	sb_hover.shadow_size = 12
	sb_hover.content_margin_left = 16
	sb_hover.content_margin_right = 16
	btn.add_theme_stylebox_override("hover", sb_hover)

	btn.add_theme_color_override("font_color", Color(col.r, col.g, col.b, 0.85))
	btn.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 1.0, 1.0))


# ============================================================
# 图鉴面板
# ============================================================

func _build_codex_panel() -> void:
	_codex_panel = Panel.new()
	_codex_panel.name = "CodexPanel"
	_codex_panel.set_anchors_preset(PRESET_FULL_RECT)
	_codex_panel.visible = false
	_codex_panel.mouse_filter = MOUSE_FILTER_STOP
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.03, 0.05, 0.12, 0.97)
	sb.set_corner_radius_all(0)
	_codex_panel.add_theme_stylebox_override("panel", sb)
	add_child(_codex_panel)

	# 顶部栏
	var top_bar := _make_panel_rect(Vector2(0, 0), Vector2(1280, 70), Color(0.04, 0.07, 0.16, 0.95))
	_codex_panel.add_child(top_bar)

	var title := Label.new()
	title.text = "◆  时空图鉴"
	title.position = Vector2(30, 16)
	title.size = Vector2(300, 38)
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3, 1.0))
	_codex_panel.add_child(title)

	# 总进度条
	var prog_bg := ColorRect.new()
	prog_bg.position = Vector2(340, 26)
	prog_bg.size = Vector2(580, 18)
	prog_bg.color = Color(0.06, 0.1, 0.2, 0.9)
	_codex_panel.add_child(prog_bg)

	_codex_progress = ColorRect.new()
	_codex_progress.name = "ProgressFill"
	_codex_progress.position = Vector2(340, 26)
	_codex_progress.size = Vector2(0, 18)
	_codex_progress.color = Color(0.2, 0.7, 1.0, 0.8)
	_codex_panel.add_child(_codex_progress)

	_codex_stats = Label.new()
	_codex_stats.name = "StatsLabel"
	_codex_stats.position = Vector2(930, 24)
	_codex_stats.size = Vector2(180, 22)
	_codex_stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_codex_stats.add_theme_font_size_override("font_size", 13)
	_codex_stats.add_theme_color_override("font_color", Color(0.5, 0.8, 1.0, 0.85))
	_codex_panel.add_child(_codex_stats)

	# 关闭按钮
	var close_btn := Button.new()
	close_btn.name = "CloseBtn"
	close_btn.text = "✕"
	close_btn.position = Vector2(1216, 18)
	close_btn.size = Vector2(44, 34)
	close_btn.add_theme_font_size_override("font_size", 18)
	close_btn.pressed.connect(_on_codex_close)
	_style_button(close_btn, Color(0.6, 0.4, 0.3))
	_codex_panel.add_child(close_btn)

	# 侧栏分类
	_build_category_sidebar()

	# 词条列表
	var scroll := ScrollContainer.new()
	scroll.name = "EntryScroll"
	scroll.position = Vector2(200, 80)
	scroll.size = Vector2(1050, 620)
	_codex_panel.add_child(scroll)

	_codex_container = VBoxContainer.new()
	_codex_container.name = "EntryContainer"
	_codex_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_codex_container.add_theme_constant_override("separation", 10)
	_codex_container.position = Vector2(0, 0)
	scroll.add_child(_codex_container)


func _build_category_sidebar() -> void:
	# 侧栏背景
	var side_bg := _make_panel_rect(Vector2(0, 70), Vector2(190, 650), Color(0.04, 0.06, 0.14, 0.9))
	_codex_panel.add_child(side_bg)

	# "全部" 按钮
	var all_btn := _make_category_btn("◆ 全部", -1, Color(0.7, 0.7, 0.8))
	all_btn.position = Vector2(14, 88)
	_category_buttons.append(all_btn)
	_codex_panel.add_child(all_btn)
	all_btn.pressed.connect(_on_category_pressed.bind(-1))

	# 各分类按钮 + 进度
	for i in CATEGORIES.size():
		var cat: Dictionary = CATEGORIES[i]
		var unlocked: int = _count_unlocked_in_category(cat["id"])
		var total: int = _count_total_in_category(cat["id"])
		var label: String = "%s  %d/%d" % [cat["name"], unlocked, total]
		var btn := _make_category_btn(label, i, cat["color"])
		btn.position = Vector2(14, 136 + i * 62)
		_category_buttons.append(btn)
		_codex_panel.add_child(btn)
		btn.pressed.connect(_on_category_pressed.bind(i))

		# 小进度条
		var bar_bg := ColorRect.new()
		bar_bg.position = Vector2(24, 170 + i * 62)
		bar_bg.size = Vector2(142, 4)
		bar_bg.color = Color(0.06, 0.1, 0.18, 0.8)
		_codex_panel.add_child(bar_bg)

		var bar: float = float(unlocked) / maxf(float(total), 1.0)
		var bar_fill := ColorRect.new()
		bar_fill.name = "CatBar%d" % i
		bar_fill.position = Vector2(24, 170 + i * 62)
		bar_fill.size = Vector2(142 * bar, 4)
		bar_fill.color = cat["color"]
		_codex_panel.add_child(bar_fill)

	_update_category_button_styles()


func _make_category_btn(text: String, _idx: int, col: Color) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.size = Vector2(162, 34)
	btn.add_theme_font_size_override("font_size", 13)
	_style_category_btn(btn, col, false)
	return btn


func _style_category_btn(btn: Button, col: Color, active: bool) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(col.r, col.g, col.b, 0.2) if active else Color(0, 0, 0, 0)
	sb.border_color = col if active else Color(col.r, col.g, col.b, 0.25)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(4)
	btn.add_theme_stylebox_override("normal", sb)

	var sb_h := StyleBoxFlat.new()
	sb_h.bg_color = Color(col.r, col.g, col.b, 0.25)
	sb_h.border_color = Color(col.r, col.g, col.b, 0.7)
	sb_h.set_border_width_all(1)
	sb_h.set_corner_radius_all(4)
	btn.add_theme_stylebox_override("hover", sb_h)

	btn.add_theme_color_override("font_color", col if active else Color(col.r, col.g, col.b, 0.6))
	btn.add_theme_color_override("font_hover_color", Color(1, 1, 1, 1))


func _on_category_pressed(cat_idx: int) -> void:
	_active_category = cat_idx
	_update_category_button_styles()
	_refresh_codex()


func _update_category_button_styles() -> void:
	for i in _category_buttons.size():
		var btn: Button = _category_buttons[i]
		var cat_idx: int = i - 1  # 0=全部, 1=狭义, ...
		var is_active: bool = (_active_category == cat_idx)
		var col: Color
		if i == 0:
			col = Color(0.7, 0.7, 0.8)
		else:
			col = CATEGORIES[cat_idx]["color"]
		_style_category_btn(btn, col, is_active)


# ============================================================
# 图鉴切换
# ============================================================

func _on_codex() -> void:
	_active_category = -1
	_update_category_button_styles()
	_refresh_codex()
	_codex_panel.visible = true
	_codex_panel.modulate = Color(1, 1, 1, 0)
	var tw := create_tween()
	tw.tween_property(_codex_panel, "modulate", Color(1, 1, 1, 1), 0.25)


func _on_codex_close() -> void:
	var tw := create_tween()
	tw.tween_property(_codex_panel, "modulate", Color(1, 1, 1, 0), 0.2)
	tw.tween_callback(func(): _codex_panel.visible = false)


# ============================================================
# 词条列表刷新
# ============================================================

func _refresh_codex() -> void:
	for child in _codex_container.get_children():
		child.queue_free()

	var total_unlocked: int = 0
	var total_all: int = ENTRY_ORDER.size()

	for entry_id in ENTRY_ORDER:
		var cat_idx: int = ENTRY_CATEGORY.get(entry_id, 0)
		if _active_category >= 0 and cat_idx != _active_category:
			continue

		var unlocked: bool = CodexManager.is_unlocked(entry_id)
		if unlocked:
			total_unlocked += 1

		var data: Dictionary = _get_entry_data(entry_id)
		var card := _make_entry_card(entry_id, data, unlocked)
		_codex_container.add_child(card)

		var spacer := ColorRect.new()
		spacer.size = Vector2(10, 1)
		spacer.color = Color(0, 0, 0, 0)
		_codex_container.add_child(spacer)

	# 更新进度
	_codex_stats.text = "已解锁 %d / %d" % [CodexManager.get_unlocked_count(), total_all]
	var ratio: float = float(CodexManager.get_unlocked_count()) / float(total_all)
	_codex_progress.size.x = 580.0 * ratio

	# 更新侧栏分类进度
	for i in CATEGORIES.size():
		var cat: Dictionary = CATEGORIES[i]
		var u: int = _count_unlocked_in_category(cat["id"])
		var t: int = _count_total_in_category(cat["id"])
		var b: float = float(u) / maxf(float(t), 1.0)
		var bar_fill := _codex_panel.get_node_or_null("CatBar%d" % i) as ColorRect
		if bar_fill:
			bar_fill.size.x = 142.0 * b

		# 更新按钮文字
		if i + 1 < _category_buttons.size():
			_category_buttons[i + 1].text = "%s  %d/%d" % [cat["name"], u, t]


func _make_entry_card(entry_id: String, data: Dictionary, unlocked: bool) -> VBoxContainer:
	var card := VBoxContainer.new()
	card.add_theme_constant_override("separation", 4)

	# 标题行
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 12)

	var icon := Label.new()
	if unlocked:
		icon.text = "◆"
		icon.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3, 0.9))
	else:
		icon.text = "◇"
		icon.add_theme_color_override("font_color", Color(0.25, 0.28, 0.35, 0.5))
	icon.add_theme_font_size_override("font_size", 18)
	header.add_child(icon)

	var name_label := Label.new()
	name_label.text = data.get("name", entry_id) if unlocked else "？？？"
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.add_theme_font_size_override("font_size", 16)
	if unlocked:
		name_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.9))
	else:
		name_label.add_theme_color_override("font_color", Color(0.3, 0.32, 0.4, 0.6))
	header.add_child(name_label)

	# 分类标签
	var cat_idx: int = ENTRY_CATEGORY.get(entry_id, 0)
	var cat_color: Color = CATEGORIES[cat_idx]["color"]
	var tag := Label.new()
	tag.text = CATEGORIES[cat_idx]["name"]
	tag.add_theme_font_size_override("font_size", 10)
	tag.add_theme_color_override("font_color", Color(cat_color.r, cat_color.g, cat_color.b, 0.7))
	header.add_child(tag)

	card.add_child(header)

	# 描述
	if unlocked:
		var desc := Label.new()
		desc.text = data.get("desc", "")
		desc.add_theme_font_size_override("font_size", 13)
		desc.add_theme_color_override("font_color", Color(0.45, 0.55, 0.75, 0.75))
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc.custom_minimum_size = Vector2(800, 0)
		card.add_child(desc)
	else:
		var hint := Label.new()
		hint.text = "继续探索以解锁此词条"
		hint.add_theme_font_size_override("font_size", 11)
		hint.add_theme_color_override("font_color", Color(0.2, 0.22, 0.3, 0.5))
		card.add_child(hint)

	return card


# ============================================================
# 工具
# ============================================================

func _count_unlocked_in_category(cat_id: String) -> int:
	var count: int = 0
	for entry_id in ENTRY_ORDER:
		var cat_idx: int = ENTRY_CATEGORY.get(entry_id, 0)
		if CATEGORIES[cat_idx]["id"] == cat_id and CodexManager.is_unlocked(entry_id):
			count += 1
	return count


func _count_total_in_category(cat_id: String) -> int:
	var count: int = 0
	for entry_id in ENTRY_ORDER:
		var cat_idx: int = ENTRY_CATEGORY.get(entry_id, 0)
		if CATEGORIES[cat_idx]["id"] == cat_id:
			count += 1
	return count


func _get_entry_data(entry_id: String) -> Dictionary:
	if CodexManager.unlocked.has(entry_id):
		return CodexManager.unlocked[entry_id]
	return _entry_fallback(entry_id)


func _entry_fallback(entry_id: String) -> Dictionary:
	var fallbacks: Dictionary = {
		"time_dilation": {"name": "时间膨胀", "desc": "", "category": "special_relativity"},
		"light_speed_barrier": {"name": "光速不变与光速壁垒", "desc": "", "category": "special_relativity"},
		"light_cone": {"name": "光锥与因果结构", "desc": "", "category": "special_relativity"},
		"twin_paradox": {"name": "双生子佯谬", "desc": "", "category": "special_relativity"},
		"gravitational_time_dilation": {"name": "引力时间膨胀", "desc": "", "category": "general_relativity"},
		"wormhole": {"name": "虫洞与爱因斯坦-罗森桥", "desc": "", "category": "general_relativity"},
		"ctc": {"name": "闭合类时曲线", "desc": "", "category": "general_relativity"},
		"grandfather_paradox": {"name": "祖父悖论", "desc": "", "category": "general_relativity"},
		"kerr_black_hole": {"name": "克尔黑洞", "desc": "", "category": "general_relativity"},
		"ergosphere": {"name": "能层与帧拖拽", "desc": "", "category": "general_relativity"},
		"ring_singularity": {"name": "奇环与裸奇点", "desc": "", "category": "general_relativity"},
		"casimir_effect": {"name": "卡西米尔效应与负能量", "desc": "", "category": "quantum_gravity"},
		"quantum_vacuum": {"name": "量子真空涨落", "desc": "", "category": "quantum_gravity"},
		"chronology_protection": {"name": "时序保护猜想", "desc": "", "category": "quantum_gravity"},
		"entropy_arrow": {"name": "熵增定律与时间箭头", "desc": "", "category": "entropy_cosmology"},
		"block_universe": {"name": "块状宇宙", "desc": "", "category": "entropy_cosmology"},
		"wheeler_dewitt": {"name": "惠勒-德维特方程", "desc": "", "category": "entropy_cosmology"},
		"time_illusion": {"name": "时间的主观性错觉", "desc": "", "category": "entropy_cosmology"},
		"maxwell_demon": {"name": "麦克斯韦妖", "desc": "", "category": "entropy_cosmology"},
		"landauer_principle": {"name": "兰道尔原理", "desc": "", "category": "entropy_cosmology"},
		"light_clock": {"name": "光钟与时间膨胀", "desc": "", "category": "special_relativity"},
		"traversable_wormhole": {"name": "可穿越虫洞", "desc": "", "category": "general_relativity"},
		"physicists_cabin": {"name": "物理学家的午后", "desc": "", "category": "entropy_cosmology"},
	}
	return fallbacks.get(entry_id, {"name": entry_id, "desc": "", "category": "unknown"})


func _make_panel_rect(pos: Vector2, sz: Vector2, col: Color) -> ColorRect:
	var r := ColorRect.new()
	r.position = pos
	r.size = sz
	r.color = col
	r.mouse_filter = MOUSE_FILTER_IGNORE
	return r


# ============================================================
# 按钮回调
# ============================================================

func _on_start() -> void:
	TransitionLayer.transition_to("res://scenes/ui/level_select.tscn")


func _on_quit() -> void:
	get_tree().quit()


# ============================================================
# 版本号
# ============================================================

func _build_version() -> void:
	var ver := Label.new()
	ver.name = "Version"
	ver.text = "v0.9 — Pre-Production"
	ver.position = Vector2(12, 696)
	ver.size = Vector2(200, 20)
	ver.add_theme_font_size_override("font_size", 10)
	ver.add_theme_color_override("font_color", Color(0.3, 0.4, 0.6, 0.5))
	add_child(ver)
