extends Node2D
## 卡西米尔板对 — M3-1 核心机制
## 两块金属板可 F 键拖拽推动，靠近到阈值内产生负能量区
## 负能量区可被不稳定虫洞检测以稳定其开启


const PLATE_SIZE := Vector2(16, 80)

# ---- 导出 ----

@export_category("Plates")
@export var plate_a_pos: Vector2 = Vector2(300, 590)
@export var plate_b_pos: Vector2 = Vector2(500, 590)
## 产生负能量的距离阈值（两板间距 < 此值 → 负能量激活）
@export var threshold: float = 80.0

@export_category("Visual")
@export var plate_color: Color = Color(0.35, 0.35, 0.45, 0.95)
@export var neg_energy_color: Color = Color(0.2, 0.5, 1.0, 0.35)

@export_category("Grab")
@export var grab_range: float = 80.0

# ---- 公开状态 ----

var neg_energy_active: bool = false
var neg_zone_center: Vector2 = Vector2.ZERO
var neg_zone_radius: float = 0.0

# ---- 内部 ----

var _plate_a: Area2D = null
var _plate_b: Area2D = null
var _plate_a_spawn: Vector2 = Vector2.ZERO
var _plate_b_spawn: Vector2 = Vector2.ZERO
var _dragging_a: bool = false
var _dragging_b: bool = false
var _neg_vis: ColorRect = null
var _t: float = 0.0


func _ready() -> void:
	_plate_a_spawn = plate_a_pos
	_plate_b_spawn = plate_b_pos
	_create_plate_a()
	_create_plate_b()
	_create_neg_energy_visual()
	add_to_group("casimir_plates")


# ============================================================
# 金属板创建
# ============================================================

func _create_plate_a() -> void:
	_plate_a = _make_plate("PlateA", plate_a_pos)
	_plate_a.body_entered.connect(func(_b): pass)
	add_child(_plate_a)


func _create_plate_b() -> void:
	_plate_b = _make_plate("PlateB", plate_b_pos)
	add_child(_plate_b)


func _make_plate(pname: String, pos: Vector2) -> Area2D:
	var plate := Area2D.new()
	plate.name = pname
	plate.position = pos
	plate.collision_layer = 0
	plate.collision_mask = 2

	var col := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = PLATE_SIZE
	col.shape = rect
	plate.add_child(col)

	var vis := ColorRect.new()
	vis.name = "Visual"
	vis.size = PLATE_SIZE
	vis.position = -PLATE_SIZE / 2.0
	vis.color = plate_color
	vis.mouse_filter = Control.MOUSE_FILTER_IGNORE
	plate.add_child(vis)

	var border := ColorRect.new()
	border.name = "Border"
	border.size = PLATE_SIZE + Vector2(4, 4)
	border.position = -PLATE_SIZE / 2.0 - Vector2(2, 2)
	border.color = Color(0.2, 0.5, 1.0, 0.0)
	border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	plate.add_child(border)

	var label := Label.new()
	label.text = "[F]"
	label.position = Vector2(-10, PLATE_SIZE.y / 2.0 + 6.0)
	label.add_theme_font_size_override("font_size", 9)
	label.add_theme_color_override("font_color", Color(0.4, 0.7, 1.0, 0.5))
	plate.add_child(label)

	return plate


# ============================================================
# 负能量视觉区
# ============================================================

func _create_neg_energy_visual() -> void:
	_neg_vis = ColorRect.new()
	_neg_vis.name = "NegEnergyVis"
	_neg_vis.color = Color(0.0, 0.0, 0.0, 0.0)
	_neg_vis.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_neg_vis.z_index = -1
	add_child(_neg_vis)


# ============================================================
# 每帧
# ============================================================

func _process(delta: float) -> void:
	_t += delta
	_handle_drag()
	_update_neg_energy()
	_update_border_glow()


func _handle_drag() -> void:
	var player: Node2D = get_tree().get_first_node_in_group("player") as Node2D
	if not player:
		return

	# 板 A 拖拽
	var dist_a: float = player.global_position.distance_to(_plate_a.global_position)
	if Input.is_action_just_pressed("grab") and dist_a < grab_range and not _dragging_b:
		_dragging_a = true
	if Input.is_action_just_released("grab") and _dragging_a:
		_dragging_a = false
	if _dragging_a:
		var target: Vector2 = player.global_position + Vector2(0.0, -50.0)
		_plate_a.global_position = _plate_a.global_position.lerp(target, 0.3)

	# 板 B 拖拽
	var dist_b: float = player.global_position.distance_to(_plate_b.global_position)
	if Input.is_action_just_pressed("grab") and dist_b < grab_range and not _dragging_a:
		_dragging_b = true
	if Input.is_action_just_released("grab") and _dragging_b:
		_dragging_b = false
	if _dragging_b:
		var target: Vector2 = player.global_position + Vector2(0.0, -50.0)
		_plate_b.global_position = _plate_b.global_position.lerp(target, 0.3)


func _update_neg_energy() -> void:
	var dist: float = _plate_a.global_position.distance_to(_plate_b.global_position)
	var was_active: bool = neg_energy_active
	neg_energy_active = dist < threshold

	if neg_energy_active:
		var pa: Vector2 = _plate_a.global_position
		var pb: Vector2 = _plate_b.global_position
		var mid: Vector2 = (pa + pb) / 2.0
		neg_zone_center = mid
		neg_zone_radius = dist / 2.0 + PLATE_SIZE.x / 2.0

		var dir: Vector2 = (pb - pa).normalized()
		var half: float = dist / 2.0
		var horizontal: bool = absf(dir.x) > absf(dir.y)
		var px: float = half if horizontal else 3.0
		var py: float = 3.0 if horizontal else half
		_neg_vis.position = mid - Vector2(px, py)
		if horizontal:
			_neg_vis.size = Vector2(dist + 8.0, 14.0)
		else:
			_neg_vis.size = Vector2(14.0, dist + 8.0)
		_neg_vis.color = Color(neg_energy_color.r, neg_energy_color.g, neg_energy_color.b, 0.25 + sin(_t * 3.0) * 0.08)
	else:
		_neg_vis.color = _neg_vis.color.lerp(Color(0.0, 0.0, 0.0, 0.0), 0.15)

	if neg_energy_active and not was_active:
		AudioManager.play_sfx("fragment_collect")


func _update_border_glow() -> void:
	var plates: Array[Area2D] = [_plate_a, _plate_b]
	for plate in plates:
		if not plate:
			continue
		var border: ColorRect = plate.get_node_or_null("Border") as ColorRect
		if not border:
			continue
		var target_a: float = 0.6 if neg_energy_active else 0.0
		border.color = Color(0.2, 0.5, 1.0, lerpf(border.color.a, target_a, 0.1))


# ============================================================
# 重置
# ============================================================

func reset_state() -> void:
	_dragging_a = false
	_dragging_b = false
	neg_energy_active = false
	_plate_a.global_position = global_position + _plate_a_spawn
	_plate_b.global_position = global_position + _plate_b_spawn
