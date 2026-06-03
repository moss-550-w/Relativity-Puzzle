extends Node2D
## 物理学家小屋 — 世界 4 底层隐藏彩蛋
## 爱因斯坦与霍金在时空间隙中对话
## 按 E 键与附近 NPC 交谈，循环名言，首次对话解锁图鉴


# ---- 导出 ----

@export_category("Room")
@export var room_width: float = 520.0
@export var room_height: float = 240.0
@export var floor_y: float = 0.0  # 房间地板相对 y（0 = 节点原点）

@export_category("NPC")
@export var einstein_pos: Vector2 = Vector2(-140, -40)
@export var hawking_pos: Vector2 = Vector2(80, -40)

@export_category("Dialogue")
@export var talk_range: float = 110.0
@export var auto_close_time: float = 5.0
@export var codex_id: String = "physicists_cabin"

# ---- 颜色 ----

const COLOR_WALL := Color(0.18, 0.14, 0.1, 0.9)      # 深木色墙
const COLOR_FLOOR := Color(0.22, 0.16, 0.1, 1.0)     # 深木色地板
const COLOR_SHELF := Color(0.3, 0.2, 0.12, 0.9)       # 书架
const COLOR_WARM_LIGHT := Color(0.5, 0.42, 0.25, 0.15)  # 暖黄灯光
const COLOR_SUIT := Color(0.15, 0.18, 0.25, 1.0)      # 深色西装
const COLOR_SKIN := Color(0.85, 0.75, 0.6, 1.0)       # 肤色
const COLOR_WHITE_HAIR := Color(0.95, 0.93, 0.88, 1.0)
const COLOR_TIE := Color(0.15, 0.3, 0.6, 1.0)         # 领带蓝
const COLOR_WHEELCHAIR := Color(0.25, 0.28, 0.32, 1.0)
const COLOR_SCREEN := Color(0.2, 0.9, 0.3, 0.8)       # 屏幕绿
const COLOR_LENS := Color(0.2, 0.25, 0.35, 0.7)       # 眼镜片

# ---- 对话 ----

const EINSTEIN_LINES: Array[String] = [
	"引力不是力，是时空的弯曲。\n我的场方程 Rμν - ½gμνR = 8πGTμν 说的就是这个。",
	"想象力比知识更重要。\n知识有限，想象力环绕世界。",
	"关于量子理论，我可能错了。\n'上帝不掷骰子'——但也许祂确实掷。",
]

const HAWKING_LINES: Array[String] = [
	"我提出了时序保护猜想：\n物理定律禁止宏观时间旅行。大自然讨厌时间机器。",
	"记得仰望星空，而不是低头看脚下。\n试着理解你所看到的，思索宇宙为何存在。",
	"黑洞不是完全黑的——它们会辐射。\n这是我最骄傲的发现。",
]

# ---- 内部 ----

var _einstein_node: Node2D = null
var _hawking_node: Node2D = null
var _player_near_einstein: bool = false
var _player_near_hawking: bool = false
var _active_npc: String = ""           # "einstein" | "hawking" | ""
var _dialogue_index: int = -1          # -1 = 无活跃对话
var _dialogue_timer: float = 0.0
var _unlocked: bool = false

# UI
var _bubble_layer: CanvasLayer = null
var _bubble_panel: Panel = null
var _bubble_name: Label = null
var _bubble_text: Label = null
var _talk_hint: Label = null

var _t: float = 0.0


func _ready() -> void:
	_build_room()
	_build_einstein()
	_build_hawking()
	_build_dialogue_ui()
	_build_hint()


# ============================================================
# 房间
# ============================================================

func _build_room() -> void:
	var hw := room_width / 2.0
	var top := floor_y - room_height
	var bot := floor_y

	# 地板
	_add_rect(Vector2(-hw, bot - 4), Vector2(room_width, 8), COLOR_FLOOR)
	# 左墙
	_add_rect(Vector2(-hw - 8, top), Vector2(8, room_height), COLOR_WALL)
	# 右墙
	_add_rect(Vector2(hw, top), Vector2(8, room_height), COLOR_WALL)
	# 天花板
	_add_rect(Vector2(-hw - 8, top - 8), Vector2(room_width + 16, 8), COLOR_WALL)

	# 书架（背景装饰）
	for i in 3:
		var sx: float = -hw + 60.0 + i * 160.0
		var shelf_h: float = room_height * 0.55
		_add_rect(Vector2(sx, top + room_height - shelf_h), Vector2(50, shelf_h), COLOR_SHELF)
		# 隔板
		for j in 4:
			_add_rect(Vector2(sx, top + room_height - shelf_h + j * (shelf_h / 4.0)), Vector2(50, 2), COLOR_FLOOR.lightened(0.1))

	# 暖黄灯光覆盖层
	var light := ColorRect.new()
	light.name = "WarmLight"
	light.position = Vector2(-hw, top)
	light.size = Vector2(room_width, room_height)
	light.color = COLOR_WARM_LIGHT
	light.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(light)

	# 地毯
	_add_rect(Vector2(-60, bot - 6), Vector2(120, 4), Color(0.4, 0.2, 0.08, 0.7))

	# 入口标记（左侧地面）
	var arrow := Polygon2D.new()
	arrow.name = "EntryArrow"
	arrow.color = Color(0.3, 0.8, 1.0, 0.35)
	arrow.polygon = PackedVector2Array([
		Vector2(-8, 0), Vector2(0, -6), Vector2(8, 0),
		Vector2(0, 6),
	])
	arrow.position = Vector2(-hw + 20, bot + 8)
	add_child(arrow)

	var entry_label := Label.new()
	entry_label.name = "EntryLabel"
	entry_label.text = "物理学家小屋"
	entry_label.position = Vector2(-hw + 34, bot + 4)
	entry_label.add_theme_font_size_override("font_size", 10)
	entry_label.add_theme_color_override("font_color", Color(0.3, 0.8, 1.0, 0.5))
	add_child(entry_label)


func _add_rect(pos: Vector2, size: Vector2, color: Color) -> void:
	var r := ColorRect.new()
	r.position = pos
	r.size = size
	r.color = color
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(r)


# ============================================================
# 爱因斯坦（左）
# ============================================================

func _build_einstein() -> void:
	_einstein_node = Node2D.new()
	_einstein_node.name = "Einstein"
	_einstein_node.position = einstein_pos
	add_child(_einstein_node)

	var base := _einstein_node

	# 身体/西装
	var body := Polygon2D.new()
	body.name = "Body"
	body.color = COLOR_SUIT
	body.polygon = PackedVector2Array([
		Vector2(-14, 0), Vector2(14, 0),
		Vector2(16, 30), Vector2(-16, 30),
	])
	body.position = Vector2(0, 8)
	base.add_child(body)

	# 领带
	var tie := Polygon2D.new()
	tie.name = "Tie"
	tie.color = COLOR_TIE
	tie.polygon = PackedVector2Array([
		Vector2(-3, 0), Vector2(3, 0),
		Vector2(1, 22), Vector2(-1, 22),
	])
	tie.position = Vector2(0, 10)
	base.add_child(tie)

	# 腿
	var legs := Polygon2D.new()
	legs.name = "Legs"
	legs.color = Color(0.2, 0.22, 0.28, 1.0)
	legs.polygon = PackedVector2Array([
		Vector2(-8, 0), Vector2(-2, 0), Vector2(-2, 26), Vector2(-8, 26),
		Vector2(2, 0), Vector2(8, 0), Vector2(8, 26), Vector2(2, 26),
	])
	legs.position = Vector2(0, 36)
	base.add_child(legs)

	# 鞋
	var shoes := Polygon2D.new()
	shoes.name = "Shoes"
	shoes.color = Color(0.1, 0.08, 0.06, 1.0)
	shoes.polygon = PackedVector2Array([
		Vector2(-10, 0), Vector2(-2, 0), Vector2(-1, 6), Vector2(-10, 6),
		Vector2(2, 0), Vector2(10, 0), Vector2(10, 6), Vector2(2, 6),
	])
	shoes.position = Vector2(0, 62)
	base.add_child(shoes)

	# 头
	var head := Polygon2D.new()
	head.name = "Head"
	head.color = COLOR_SKIN
	head.polygon = _make_oval(12, 14, 10)
	head.position = Vector2(0, -10)
	base.add_child(head)

	# 爆炸头发（多个三角形）
	var hair_positions: Array[Dictionary] = [
		{"angle": -150, "len": 16}, {"angle": -120, "len": 18}, {"angle": -90, "len": 20},
		{"angle": -60, "len": 18}, {"angle": -30, "len": 16}, {"angle": 0, "len": 14},
		{"angle": 30, "len": 16}, {"angle": 60, "len": 18}, {"angle": 90, "len": 17},
		{"angle": 120, "len": 14}, {"angle": 150, "len": 12},
	]
	for h in hair_positions:
		var hair := Polygon2D.new()
		hair.color = COLOR_WHITE_HAIR
		var a: float = deg_to_rad(h["angle"])
		var ln: float = h["len"]
		var cx: float = cos(a) * 6.0
		var cy: float = sin(a) * 4.0
		hair.polygon = PackedVector2Array([
			Vector2(cx - 3, cy), Vector2(cx + 3, cy),
			Vector2(cx + cos(a) * ln, cy + sin(a) * ln),
		])
		hair.position = Vector2(0, -12)
		base.add_child(hair)

	# 胡子
	var mustache := Polygon2D.new()
	mustache.name = "Mustache"
	mustache.color = COLOR_WHITE_HAIR
	mustache.polygon = PackedVector2Array([
		Vector2(-14, -2), Vector2(14, -2),
		Vector2(10, 4), Vector2(-10, 4),
	])
	mustache.position = Vector2(0, 2)
	base.add_child(mustache)


# ============================================================
# 霍金（右）
# ============================================================

func _build_hawking() -> void:
	_hawking_node = Node2D.new()
	_hawking_node.name = "Hawking"
	_hawking_node.position = hawking_pos
	add_child(_hawking_node)

	var base := _hawking_node

	# 轮椅底座
	var wc_base := Polygon2D.new()
	wc_base.name = "ChairBase"
	wc_base.color = COLOR_WHEELCHAIR
	wc_base.polygon = PackedVector2Array([
		Vector2(-18, 0), Vector2(18, 0),
		Vector2(18, 10), Vector2(-18, 10),
	])
	wc_base.position = Vector2(0, 44)
	base.add_child(wc_base)

	# 轮椅靠背
	var wc_back := Polygon2D.new()
	wc_back.name = "ChairBack"
	wc_back.color = COLOR_WHEELCHAIR.lightened(0.1)
	wc_back.polygon = PackedVector2Array([
		Vector2(-16, 0), Vector2(16, 0),
		Vector2(16, -40), Vector2(-16, -40),
	])
	wc_back.position = Vector2(0, 44)
	base.add_child(wc_back)

	# 大轮（左）
	draw_circle_poly(Vector2(-16, 56), 14.0, COLOR_WHEELCHAIR.darkened(0.2), base)
	draw_circle_poly(Vector2(-16, 56), 6.0, COLOR_WHEELCHAIR.lightened(0.2), base)

	# 大轮（右）
	draw_circle_poly(Vector2(16, 56), 14.0, COLOR_WHEELCHAIR.darkened(0.2), base)
	draw_circle_poly(Vector2(16, 56), 6.0, COLOR_WHEELCHAIR.lightened(0.2), base)

	# 扶手 + 屏幕
	var arm := Polygon2D.new()
	arm.name = "ArmScreen"
	arm.color = COLOR_WHEELCHAIR.lightened(0.15)
	arm.polygon = PackedVector2Array([
		Vector2(-18, -2), Vector2(22, -2),
		Vector2(22, 8), Vector2(-18, 8),
	])
	arm.position = Vector2(0, 14)
	base.add_child(arm)

	var screen := Polygon2D.new()
	screen.name = "Screen"
	screen.color = COLOR_SCREEN
	screen.polygon = PackedVector2Array([
		Vector2(18, 0), Vector2(34, 0),
		Vector2(34, -16), Vector2(18, -16),
	])
	screen.position = Vector2(0, 4)
	base.add_child(screen)

	# 身体（坐姿，微斜）
	var body := Polygon2D.new()
	body.name = "Body"
	body.color = Color(0.2, 0.22, 0.28, 1.0)
	body.polygon = PackedVector2Array([
		Vector2(-10, 0), Vector2(8, -4),
		Vector2(8, 26), Vector2(-10, 30),
	])
	body.position = Vector2(0, -10)
	base.add_child(body)

	# 头
	var head := Polygon2D.new()
	head.name = "Head"
	head.color = COLOR_SKIN
	head.polygon = _make_oval(10, 11, 8)
	head.position = Vector2(0, -22)
	base.add_child(head)

	# 眼镜
	var lens_l := Polygon2D.new()
	lens_l.name = "LensL"
	lens_l.color = COLOR_LENS
	lens_l.polygon = _make_oval(5, 4, 6)
	lens_l.position = Vector2(-6, -23)
	base.add_child(lens_l)

	var lens_r := Polygon2D.new()
	lens_r.name = "LensR"
	lens_r.color = COLOR_LENS
	lens_r.polygon = _make_oval(5, 4, 6)
	lens_r.position = Vector2(6, -23)
	base.add_child(lens_r)

	# 微笑
	var smile := Polygon2D.new()
	smile.name = "Smile"
	smile.color = Color(0.5, 0.35, 0.25, 0.6)
	smile.polygon = PackedVector2Array([
		Vector2(-6, 0), Vector2(6, 0),
		Vector2(4, 3), Vector2(-4, 3),
	])
	smile.position = Vector2(0, -17)
	base.add_child(smile)


func draw_circle_poly(pos: Vector2, radius: float, color: Color, parent: Node2D) -> void:
	var p := Polygon2D.new()
	p.color = color
	var pts := PackedVector2Array()
	for i in 12:
		var a: float = float(i) / 12.0 * TAU
		pts.append(Vector2(cos(a), sin(a)) * radius)
	p.polygon = pts
	p.position = pos
	parent.add_child(p)


func _make_oval(rx: float, ry: float, segs: int) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in segs:
		var a: float = float(i) / segs * TAU
		pts.append(Vector2(cos(a) * rx, sin(a) * ry))
	return pts


# ============================================================
# 对话 UI
# ============================================================

func _build_dialogue_ui() -> void:
	_bubble_layer = CanvasLayer.new()
	_bubble_layer.name = "DialogueLayer"
	_bubble_layer.layer = 50
	add_child(_bubble_layer)

	_bubble_panel = Panel.new()
	_bubble_panel.name = "BubblePanel"
	_bubble_panel.size = Vector2(420, 100)
	_bubble_panel.visible = false
	var psb := StyleBoxFlat.new()
	psb.bg_color = Color(0.03, 0.07, 0.12, 0.92)
	psb.border_color = Color(0.2, 0.8, 1.0, 0.6)
	psb.set_border_width_all(2)
	psb.border_width_left = 4
	psb.set_corner_radius_all(6)
	psb.shadow_color = Color(0.1, 0.6, 1.0, 0.25)
	psb.shadow_size = 12
	_bubble_panel.add_theme_stylebox_override("panel", psb)
	_bubble_layer.add_child(_bubble_panel)

	_bubble_name = Label.new()
	_bubble_name.name = "NameLabel"
	_bubble_name.position = Vector2(14, 8)
	_bubble_name.size = Vector2(392, 22)
	_bubble_name.add_theme_font_size_override("font_size", 15)
	_bubble_name.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3, 1.0))
	_bubble_panel.add_child(_bubble_name)

	_bubble_text = Label.new()
	_bubble_text.name = "TextLabel"
	_bubble_text.position = Vector2(14, 34)
	_bubble_text.size = Vector2(392, 58)
	_bubble_text.add_theme_font_size_override("font_size", 13)
	_bubble_text.add_theme_color_override("font_color", Color(0.85, 0.9, 1.0, 0.9))
	_bubble_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_bubble_panel.add_child(_bubble_text)

	# [E] 交谈提示
	_talk_hint = Label.new()
	_talk_hint.name = "TalkHint"
	_talk_hint.text = "[E] 交谈"
	_talk_hint.add_theme_font_size_override("font_size", 12)
	_talk_hint.add_theme_color_override("font_color", Color(0.3, 0.9, 1.0, 0.7))
	_talk_hint.visible = false
	add_child(_talk_hint)


func _build_hint() -> void:
	var label := Label.new()
	label.name = "RoomTitle"
	label.text = "时空的尽头，他们仍在争论"
	label.position = Vector2(-room_width / 2.0 + 10, floor_y - room_height + 5)
	label.size = Vector2(220, 20)
	label.add_theme_font_size_override("font_size", 10)
	label.add_theme_color_override("font_color", Color(0.3, 0.8, 1.0, 0.45))
	add_child(label)


# ============================================================
# 每帧
# ============================================================

func _process(delta: float) -> void:
	_t += delta
	_check_proximity()
	_update_dialogue(delta)
	_update_hint()


func _check_proximity() -> void:
	var player := _get_player()
	if not player:
		return

	var pp: Vector2 = player.global_position
	_player_near_einstein = pp.distance_to(global_position + einstein_pos) < talk_range
	_player_near_hawking = pp.distance_to(global_position + hawking_pos) < talk_range

	# E 键交谈
	if Input.is_action_just_pressed("observe"):
		if _active_npc != "":
			# 推进当前对话
			_advance_dialogue()
		elif _player_near_einstein:
			_start_dialogue("einstein")
		elif _player_near_hawking:
			_start_dialogue("hawking")


func _start_dialogue(npc: String) -> void:
	_active_npc = npc
	_dialogue_index = 0
	_dialogue_timer = 0.0
	_show_current_line()

	if not _unlocked:
		_unlocked = true
		CodexManager.unlock(codex_id)


func _advance_dialogue() -> void:
	var lines: Array = EINSTEIN_LINES if _active_npc == "einstein" else HAWKING_LINES
	_dialogue_index = (_dialogue_index + 1) % lines.size()
	_dialogue_timer = 0.0
	_show_current_line()


func _show_current_line() -> void:
	var lines: Array = EINSTEIN_LINES if _active_npc == "einstein" else HAWKING_LINES
	var name_text: String = "阿尔伯特·爱因斯坦" if _active_npc == "einstein" else "斯蒂芬·霍金"

	_bubble_name.text = name_text
	_bubble_text.text = lines[_dialogue_index]

	# 定位气泡在 NPC 头顶
	# 气泡在 CanvasLayer（屏幕空间），NPC 在世界空间，需做坐标转换
	var npc_node: Node2D = _einstein_node if _active_npc == "einstein" else _hawking_node
	var npc_screen_pos: Vector2 = npc_node.get_global_transform_with_canvas().origin
	_bubble_panel.position = npc_screen_pos + Vector2(-210, -120)

	_bubble_panel.visible = true
	_bubble_panel.modulate = Color(1, 1, 1, 0)
	var tw := create_tween()
	tw.tween_property(_bubble_panel, "modulate", Color.WHITE, 0.25)


func _update_dialogue(delta: float) -> void:
	if _active_npc == "":
		return
	# 气泡每帧跟随 NPC 屏幕位置（相机移动时不漂移）
	if _bubble_panel and _bubble_panel.visible:
		var npc_node: Node2D = _einstein_node if _active_npc == "einstein" else _hawking_node
		var npc_screen_pos: Vector2 = npc_node.get_global_transform_with_canvas().origin
		_bubble_panel.position = npc_screen_pos + Vector2(-210, -120)
	_dialogue_timer += delta
	if _dialogue_timer >= auto_close_time:
		_close_dialogue()


func _close_dialogue() -> void:
	_active_npc = ""
	_dialogue_index = -1
	_dialogue_timer = 0.0
	if _bubble_panel:
		var tw := create_tween()
		tw.tween_property(_bubble_panel, "modulate", Color(1, 1, 1, 0), 0.2)
		tw.tween_callback(func(): _bubble_panel.visible = false)


func _update_hint() -> void:
	var near: bool = _player_near_einstein or _player_near_hawking
	var show_hint := near and _active_npc == ""

	if show_hint:
		var npc_node: Node2D = _einstein_node if _player_near_einstein else _hawking_node
		var hint_pos: Vector2 = global_position + npc_node.position + Vector2(-20, -80)
		_talk_hint.position = hint_pos
		_talk_hint.visible = true
		_talk_hint.modulate.a = 0.5 + sin(_t * 3.0) * 0.2
	else:
		_talk_hint.visible = false


func _get_player() -> Node2D:
	return get_tree().get_first_node_in_group("player")


# ============================================================
# 重置
# ============================================================

func reset_state() -> void:
	_close_dialogue()
	_bubble_panel.visible = false
	_talk_hint.visible = false
