extends Node2D
## 双生子小屋 — World 1 隐藏彩蛋
## 程序化构建整个房间、双 NPC、高速区、观察点
## 左侧 = 高速时间区（NPC 快速衰老），右侧 = 正常流速
## 同框对比 → 直观传达双生子佯谬


# ---- 导出 ----

@export_category("Room")
@export var room_width: float = 500.0
@export var room_height: float = 280.0
@export var floor_y: float = 0.0  # 房间地板相对 y（0 = 节点原点）

@export_category("Aging")
## 左 NPC（高速区）时间倍率
@export var left_time_scale: float = 15.0
## 完整衰老周期（正常流速下秒数）
@export var age_duration: float = 180.0

@export_category("Codex")
## 观察点需停留秒数
@export var observe_duration: float = 2.0
@export var codex_id: String = "twin_paradox"


# ---- 颜色常量 ----

const COLOR_YOUNG := Color(0.25, 0.6, 0.95)   # 年轻：亮蓝
const COLOR_OLD   := Color(0.55, 0.5, 0.45)   # 老年：灰褐
const COLOR_WALL  := Color(0.2, 0.22, 0.28, 0.9)
const COLOR_FLOOR := Color(0.3, 0.32, 0.38, 1.0)
const COLOR_DIVIDER := Color(0.4, 0.8, 1.0, 0.25)
const COLOR_SPEED_ZONE := Color(0.1, 0.4, 0.9, 0.12)
const COLOR_NORMAL_ZONE := Color(0.5, 0.4, 0.25, 0.08)

# ---- 内部 ----

var _left_npc: Node2D = null
var _right_npc: Node2D = null
var _left_age: float = 0.0
var _right_age: float = 0.0
var _observe_timer: float = 0.0
var _unlocked: bool = false
var _player_in_observe: bool = false


func _ready() -> void:
	_build_room()
	_build_npcs()
	_build_observe_zone()
	_build_hint()


# ============================================================
# 房间结构
# ============================================================

func _build_room() -> void:
	var hw := room_width / 2.0
	var top := floor_y - room_height
	var bot := floor_y

	# 地板（物理 + 视觉）
	_add_solid_rect(Vector2(-hw, bot), Vector2(room_width, 20), COLOR_FLOOR)

	# 左墙（物理阻挡 + 视觉）
	_add_solid_rect(Vector2(-hw - 10, top), Vector2(10, room_height + 20), COLOR_WALL)
	# 右墙留空 — 入口
	# 天花板（纯视觉）
	_add_rect(Vector2(-hw - 10, top - 10), Vector2(room_width + 20, 10), COLOR_WALL)
	# 右上方小段墙檐（视觉提示入口边界）
	_add_rect(Vector2(hw, top - 10), Vector2(6, 30), COLOR_WALL)

	# 中间分隔壁（半透明，分隔高速区和正常区，纯视觉）
	var div_x := 0.0
	_add_rect(Vector2(div_x - 1.5, top + 20), Vector2(3, room_height - 40), COLOR_DIVIDER)

	# 分隔壁底座（视觉支撑）
	_add_rect(Vector2(div_x - 15, bot - 18), Vector2(30, 18), COLOR_WALL.lerp(COLOR_FLOOR, 0.5))

	# 高速区蓝色调覆盖（左半）
	var zone_overlay := ColorRect.new()
	zone_overlay.name = "SpeedZoneOverlay"
	zone_overlay.color = COLOR_SPEED_ZONE
	zone_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	zone_overlay.position = Vector2(-hw, top + 20)
	zone_overlay.size = Vector2(hw, room_height - 20)
	add_child(zone_overlay)

	# 正常区暖色调覆盖（右半）
	var normal_overlay := ColorRect.new()
	normal_overlay.name = "NormalZoneOverlay"
	normal_overlay.color = COLOR_NORMAL_ZONE
	normal_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	normal_overlay.position = Vector2(3, top + 20)
	normal_overlay.size = Vector2(hw - 3, room_height - 20)
	add_child(normal_overlay)

	# 高速区粒子效果（小点向上飘动）
	_add_speed_particles(Vector2(-hw / 2.0, top + room_height / 2.0))


func _add_rect(pos: Vector2, size: Vector2, color: Color) -> ColorRect:
	var r := ColorRect.new()
	r.position = pos
	r.size = size
	r.color = color
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(r)
	return r


## 创建带物理碰撞的矩形（视觉 ColorRect + StaticBody2D）
func _add_solid_rect(pos: Vector2, size: Vector2, color: Color) -> void:
	# 视觉层
	_add_rect(pos, size, color)
	# 物理碰撞层（collision_layer = 1 = world，阻挡玩家）
	var body := StaticBody2D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	body.position = pos + size / 2.0  # StaticBody2D 定位到矩形中心
	var col := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = size
	col.shape = rect
	body.add_child(col)
	add_child(body)


func _add_speed_particles(center: Vector2) -> void:
	var particles := Node2D.new()
	particles.name = "SpeedParticles"
	particles.position = center
	# 创建 8 个静态粒子点（周期性上下浮动模拟时间流动）
	for i in 8:
		var dot := ColorRect.new()
		dot.name = "Particle%d" % i
		dot.size = Vector2(3, 3)
		dot.color = Color(0.4, 0.75, 1.0, 0.5 + randf() * 0.4)
		dot.position = Vector2(randf_range(-200, 200), randf_range(-120, 120))
		dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		dot.set_meta("base_y", dot.position.y)
		dot.set_meta("speed", randf_range(20.0, 50.0))
		dot.set_meta("phase", randf() * TAU)
		particles.add_child(dot)
	add_child(particles)


# ============================================================
# 双 NPC 构建
# ============================================================

func _build_npcs() -> void:
	var hw := room_width / 2.0
	var ground := floor_y - 10  # NPC 脚底

	# 左 NPC（高速区）
	_left_npc = _create_npc(Vector2(-hw / 2.0, ground), true)
	add_child(_left_npc)

	# 右 NPC（正常区）
	_right_npc = _create_npc(Vector2(hw / 2.0, ground), false)
	add_child(_right_npc)

	# 标签
	_add_label("高速区", Vector2(-hw / 2.0, floor_y - room_height + 10), Color(0.3, 0.7, 1.0))
	_add_label("正常区", Vector2(hw / 2.0, floor_y - room_height + 10), Color(0.8, 0.7, 0.5))


func _create_npc(pos: Vector2, _is_left: bool) -> Node2D:
	var npc := Node2D.new()
	npc.position = pos
	npc.name = "LeftNPC" if _is_left else "RightNPC"

	# 头
	var head := Polygon2D.new()
	head.name = "Head"
	head.color = COLOR_YOUNG
	head.polygon = _make_circle_polygon(10, 8)
	head.position = Vector2(0, -28)
	npc.add_child(head)

	# 身体
	var body := Polygon2D.new()
	body.name = "Body"
	body.color = COLOR_YOUNG
	body.polygon = PackedVector2Array([
		Vector2(-8, 0), Vector2(8, 0),
		Vector2(6, 22), Vector2(-6, 22),
	])
	body.position = Vector2(0, -18)
	npc.add_child(body)

	# 腿
	var legs := Polygon2D.new()
	legs.name = "Legs"
	legs.color = COLOR_YOUNG.darkened(0.15)
	legs.polygon = PackedVector2Array([
		Vector2(-5, 0), Vector2(-1, 0),
		Vector2(-1, 14), Vector2(-5, 14),
		Vector2(1, 0), Vector2(5, 0),
		Vector2(5, 14), Vector2(1, 14),
	])
	legs.position = Vector2(0, 4)
	npc.add_child(legs)

	# 存储引用
	npc.set_meta("head", head)
	npc.set_meta("body", body)
	npc.set_meta("legs", legs)
	npc.set_meta("is_left", _is_left)

	return npc


func _make_circle_polygon(radius: float, segments: int) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in segments:
		var angle := float(i) / segments * TAU
		pts.append(Vector2(cos(angle), sin(angle)) * radius)
	return pts


func _add_label(text: String, pos: Vector2, color: Color) -> void:
	var label := Label.new()
	label.text = text
	label.position = pos - Vector2(40, 0)
	label.size = Vector2(80, 20)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 11)
	label.add_theme_color_override("font_color", color)
	add_child(label)


# ============================================================
# 观察点（图鉴解锁）
# ============================================================

func _build_observe_zone() -> void:
	var sensor := Area2D.new()
	sensor.name = "ObserveZone"
	sensor.collision_layer = 0
	sensor.collision_mask = 2  # player 层
	sensor.position = Vector2(0, floor_y - 30)

	var col := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(80, 40)
	col.shape = rect
	sensor.add_child(col)
	add_child(sensor)

	sensor.body_entered.connect(_on_observe_entered)
	sensor.body_exited.connect(_on_observe_exited)

	# 地面观察标记（发光菱形轮廓）
	var marker := Polygon2D.new()
	marker.name = "ObserveMarker"
	marker.color = Color(1.0, 0.85, 0.3, 0.4)
	marker.polygon = PackedVector2Array([
		Vector2(0, -10), Vector2(8, 0),
		Vector2(0, 10), Vector2(-8, 0),
	])
	marker.position = Vector2(0, floor_y - 20)
	add_child(marker)

	# 提示文字
	var hint := Label.new()
	hint.name = "ObserveHint"
	hint.text = "站在此处观察"
	hint.position = Vector2(-50, floor_y - room_height + 30)
	hint.size = Vector2(100, 20)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 9)
	hint.add_theme_color_override("font_color", Color(1, 0.85, 0.3, 0.6))
	add_child(hint)


func _on_observe_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	_player_in_observe = true


func _on_observe_exited(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	_player_in_observe = false
	_observe_timer = 0.0


# ============================================================
# 房间入口提示
# ============================================================

func _build_hint() -> void:
	var label := Label.new()
	label.name = "RoomTitle"
	label.text = "双生子小屋"
	label.position = Vector2(-room_width / 2.0 + 10, floor_y - room_height + 5)
	label.size = Vector2(120, 20)
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", Color(0.3, 0.8, 1.0, 0.7))
	add_child(label)


# ============================================================
# 每帧更新
# ============================================================

func _process(delta: float) -> void:
	_update_npc_aging(delta)
	_update_particles(delta)
	_update_observe(delta)


func _update_npc_aging(delta: float) -> void:
	if _left_npc:
		_left_age += delta * left_time_scale / age_duration
		_left_age = minf(_left_age, 1.0)
		_apply_aging(_left_npc, _left_age)

	if _right_npc:
		_right_age += delta * 1.0 / age_duration
		_right_age = minf(_right_age, 1.0)
		_apply_aging(_right_npc, _right_age)


func _apply_aging(npc: Node2D, age: float) -> void:
	var head: Polygon2D = npc.get_meta("head")
	var body: Polygon2D = npc.get_meta("body")
	var legs: Polygon2D = npc.get_meta("legs")

	if not head or not body or not legs:
		return

	# 颜色渐变：亮蓝 → 灰褐
	var col := COLOR_YOUNG.lerp(COLOR_OLD, age)
	head.color = col
	body.color = col
	legs.color = col.darkened(0.1)

	# 身高微缩（老年驼背）
	var s := lerpf(1.0, 0.82, age)
	npc.scale = Vector2(s, s)

	# 头位置略微下沉（缩脖）
	head.position.y = lerpf(-28.0, -24.0, age)


func _update_particles(_delta: float) -> void:
	var particles := get_node_or_null("SpeedParticles")
	if not particles:
		return
	var t := Time.get_ticks_msec() / 1000.0
	for child in particles.get_children():
		var base_y: float = child.get_meta("base_y", 0.0)
		var speed: float = child.get_meta("speed", 30.0)
		var phase: float = child.get_meta("phase", 0.0)
		child.position.y = base_y + sin(t * speed + phase) * 30.0
		child.modulate.a = 0.2 + absf(sin(t * speed * 1.5 + phase)) * 0.5


func _update_observe(delta: float) -> void:
	if _unlocked or not _player_in_observe:
		return
	_observe_timer += delta
	if _observe_timer >= observe_duration:
		_unlocked = true
		CodexManager.unlock(codex_id)
		# 观察标记变色表示已解锁
		var marker := get_node_or_null("ObserveMarker") as Polygon2D
		if marker:
			marker.color = Color(1.0, 0.85, 0.3, 0.9)


# ============================================================
# 重置
# ============================================================

func reset_state() -> void:
	_left_age = 0.0
	_right_age = 0.0
	_observe_timer = 0.0
	_player_in_observe = false

	if _left_npc:
		_apply_aging(_left_npc, 0.0)
	if _right_npc:
		_apply_aging(_right_npc, 0.0)
