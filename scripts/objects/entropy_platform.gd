extends StaticBody2D
## 熵增平台 — World 4 上层核心物件
## 随 EntropySystem.global_entropy 渐进崩解
## 视觉用 offset_* 定位 ColorRect（Control 在 Node2D 下的可靠方式）


@export_category("Visual")
@export var platform_width: float = 200.0
@export var platform_height: float = 24.0
@export var intact_color: Color = Color(0.4, 0.45, 0.55, 1.0)
@export var cracked_color: Color = Color(0.45, 0.38, 0.3, 0.9)
@export var crumbled_color: Color = Color(0.5, 0.3, 0.2, 0.6)

var _full_width: float
var _col_shape: CollisionShape2D = null
var _vis: ColorRect = null
var _cracks: Array[ColorRect] = []


func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	_full_width = platform_width

	# 碰撞体
	_col_shape = CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(platform_width, platform_height)
	_col_shape.shape = rect
	add_child(_col_shape)

	# 视觉：用 offset_* 定位（Control 在 Node2D 下的可靠方式）
	_vis = ColorRect.new()
	_vis.name = "Visual"
	var hw: float = platform_width / 2.0
	var hh: float = platform_height / 2.0
	_vis.offset_left = -hw
	_vis.offset_top = -hh
	_vis.offset_right = hw
	_vis.offset_bottom = hh
	_vis.color = intact_color
	_vis.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_vis)

	# 裂缝线
	for i in 4:
		var crack := ColorRect.new()
		crack.name = "Crack%d" % i
		var cx: float = randf_range(-hw + 15, hw - 50)
		crack.offset_left = cx
		crack.offset_top = randf_range(-hh + 2, hh - 8)
		crack.offset_right = cx + randf_range(15, 40)
		crack.offset_bottom = crack.offset_top + 2
		crack.color = Color(0.1, 0.08, 0.05, 0.0)
		crack.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_cracks.append(crack)
		add_child(crack)


func _process(_delta: float) -> void:
	var e: float = EntropySystem.global_entropy
	_update_visual(e)
	_update_collision(e)


func _update_visual(e: float) -> void:
	var col: Color
	var hw: float = _full_width / 2.0
	var hh: float = platform_height / 2.0

	if e < 0.25:
		col = intact_color
	elif e < 0.5:
		var t: float = (e - 0.25) / 0.25
		col = intact_color.lerp(cracked_color, t)
	elif e < 0.75:
		var t: float = (e - 0.5) / 0.25
		col = cracked_color.lerp(crumbled_color, t)
	else:
		col = crumbled_color
		col.a = lerpf(0.6, 0.2, (e - 0.75) / 0.25)

	_vis.color = col
	# 崩解时视觉缩小
	var vis_scale: float = 1.0
	if e > 0.5:
		vis_scale = lerpf(1.0, 0.35, (e - 0.5) / 0.5)
	_vis.offset_left = -hw * vis_scale
	_vis.offset_right = hw * vis_scale

	# 裂缝可见度
	var crack_alpha: float = 0.0
	if e > 0.2:
		crack_alpha = clampf((e - 0.2) / 0.5, 0.0, 0.85)
	for crack in _cracks:
		crack.color.a = crack_alpha


func _update_collision(e: float) -> void:
	var scale: float = 1.0
	if e > 0.5:
		scale = lerpf(1.0, 0.35, (e - 0.5) / 0.5)
	if _col_shape and _col_shape.shape is RectangleShape2D:
		(_col_shape.shape as RectangleShape2D).size.x = _full_width * scale
	_col_shape.disabled = e >= 1.0


func reset_state() -> void:
	pass
