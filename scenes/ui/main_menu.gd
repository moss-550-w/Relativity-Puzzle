extends Control
## 主菜单 — 标题画面 + 开始/图鉴/退出 + 星空粒子背景


const ENTRY_ORDER: Array[String] = [
	"time_dilation", "light_speed_barrier", "light_cone", "twin_paradox",
	"gravitational_time_dilation", "wormhole", "ctc", "grandfather_paradox",
	"kerr_black_hole", "ergosphere", "ring_singularity",
	"casimir_effect", "quantum_vacuum", "chronology_protection",
	"entropy_arrow", "block_universe", "wheeler_dewitt", "time_illusion",
]

const CATEGORY_NAMES: Dictionary = {
	"special_relativity": "狭义相对论",
	"general_relativity": "广义相对论",
	"quantum_gravity": "量子引力",
	"entropy_cosmology": "熵宇宙学",
}

var _title_label: Label = null
var _codex_panel: Panel = null
var _codex_container: VBoxContainer = null
var _particles: Array[ColorRect] = []
var _t: float = 0.0


func _ready() -> void:
	_build_background()
	_build_title()
	_build_buttons()
	_build_codex_panel()
	_build_version()


# ============================================================
# 星空粒子背景
# ============================================================

func _build_background() -> void:
	var bg := ColorRect.new()
	bg.name = "Background"
	bg.set_anchors_preset(PRESET_FULL_RECT)
	bg.color = Color(0.02, 0.03, 0.08, 1.0)
	add_child(bg)

	# 随机星点
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

	# 标题辉光脉冲
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
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.03, 0.05, 0.12, 0.95)
	sb.set_corner_radius_all(12)
	_codex_panel.add_theme_stylebox_override("panel", sb)
	add_child(_codex_panel)

	# 关闭按钮
	var close_btn := Button.new()
	close_btn.name = "CloseBtn"
	close_btn.text = "✕ 关闭"
	close_btn.position = Vector2(540, 24)
	close_btn.size = Vector2(100, 36)
	close_btn.add_theme_font_size_override("font_size", 14)
	close_btn.pressed.connect(_on_codex_close)
	_style_button(close_btn, Color(0.6, 0.4, 0.3))
	_codex_panel.add_child(close_btn)

	# 标题
	var title := Label.new()
	title.text = "◆ 时空图鉴"
	title.position = Vector2(24, 24)
	title.size = Vector2(400, 36)
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3, 1.0))
	_codex_panel.add_child(title)

	# 统计
	var stats := Label.new()
	stats.name = "StatsLabel"
	stats.position = Vector2(24, 66)
	stats.size = Vector2(400, 24)
	stats.add_theme_font_size_override("font_size", 13)
	stats.add_theme_color_override("font_color", Color(0.5, 0.7, 0.9, 0.7))
	_codex_panel.add_child(stats)

	# 滚动词条列表
	var scroll := ScrollContainer.new()
	scroll.name = "EntryScroll"
	scroll.position = Vector2(24, 100)
	scroll.size = Vector2(600, 560)
	_codex_panel.add_child(scroll)

	_codex_container = VBoxContainer.new()
	_codex_container.name = "EntryContainer"
	_codex_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_codex_container.add_theme_constant_override("separation", 8)
	scroll.add_child(_codex_container)


func _on_codex() -> void:
	_refresh_codex()
	_codex_panel.visible = true


func _on_codex_close() -> void:
	_codex_panel.visible = false


func _refresh_codex() -> void:
	# 清空旧词条
	for child in _codex_container.get_children():
		child.queue_free()

	var unlocked_count: int = CodexManager.get_unlocked_count()
	var stats := _codex_panel.get_node_or_null("StatsLabel") as Label
	if stats:
		stats.text = "已解锁 %d / %d" % [unlocked_count, ENTRY_ORDER.size()]

	var current_category: String = ""
	for entry_id in ENTRY_ORDER:
		var data: Dictionary = {}
		if CodexManager.unlocked.has(entry_id):
			data = CodexManager.unlocked[entry_id]
		else:
			data = _get_entry_fallback(entry_id)

		var cat: String = data.get("category", "")
		if cat != current_category:
			current_category = cat
			var cat_label := Label.new()
			cat_label.text = "— " + CATEGORY_NAMES.get(cat, cat) + " —"
			cat_label.add_theme_font_size_override("font_size", 15)
			cat_label.add_theme_color_override("font_color", Color(0.3, 0.8, 1.0, 0.7))
			_codex_container.add_child(cat_label)

		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 14)

		var icon := Label.new()
		icon.text = "◆" if CodexManager.is_unlocked(entry_id) else "◇"
		icon.add_theme_font_size_override("font_size", 16)
		icon.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3, 0.9) if CodexManager.is_unlocked(entry_id) else Color(0.3, 0.3, 0.4, 0.5))

		var name_label := Label.new()
		name_label.text = data.get("name", entry_id) if CodexManager.is_unlocked(entry_id) else "？？？"
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_label.add_theme_font_size_override("font_size", 14)
		name_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.85) if CodexManager.is_unlocked(entry_id) else Color(0.3, 0.3, 0.4, 0.6))

		var desc_label := Label.new()
		desc_label.text = data.get("desc", "")
		desc_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		desc_label.add_theme_font_size_override("font_size", 12)
		desc_label.add_theme_color_override("font_color", Color(0.5, 0.6, 0.8, 0.7))
		desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc_label.custom_minimum_size = Vector2(300, 0)

		row.add_child(icon)
		row.add_child(name_label)

		var entry_vbox := VBoxContainer.new()
		entry_vbox.add_child(row)
		if CodexManager.is_unlocked(entry_id):
			entry_vbox.add_child(desc_label)
		_codex_container.add_child(entry_vbox)


func _get_entry_fallback(entry_id: String) -> Dictionary:
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
	}
	return fallbacks.get(entry_id, {"name": entry_id, "desc": "", "category": "unknown"})


# ============================================================
# 按钮回调
# ============================================================

func _on_start() -> void:
	get_tree().change_scene_to_file("res://scenes/world_1_lorentz/level_1_1.tscn")


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
