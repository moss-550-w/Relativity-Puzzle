extends StaticBody2D
## CTC 联动门 — M2-2 核心障碍
## 读取 WormholePair 的状态，自动切换碰撞与视觉
## 现在态：门关闭（红色），阻挡玩家
## 过去态：门开启（绿色），允许通过
## 开关激活后：永久开启


@export_category("CTC Link")
## WormholePair 节点路径
@export var wormhole_pair_path: NodePath

@export_category("Visual")
@export var door_width: float = 40.0
@export var door_height: float = 220.0
@export var closed_color: Color = Color(0.9, 0.2, 0.15, 0.65)
@export var open_color: Color = Color(0.15, 0.8, 0.3, 0.35)

var _pair: Node2D = null
var _visual: ColorRect = null
var _col_shape: CollisionShape2D = null
var _label: Label = null
var _was_open: bool = false


func _ready() -> void:
	collision_layer = 1  # world 层（阻挡玩家）
	collision_mask = 0

	# 碰撞体
	_col_shape = CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(door_width, door_height)
	_col_shape.shape = rect
	add_child(_col_shape)

	# 视觉
	_visual = ColorRect.new()
	_visual.name = "DoorVisual"
	_visual.size = Vector2(door_width, door_height)
	_visual.position = Vector2(-door_width / 2.0, -door_height / 2.0)
	_visual.color = closed_color
	_visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_visual)

	# 标签
	_label = Label.new()
	_label.name = "DoorLabel"
	_label.position = Vector2(-24, -door_height / 2.0 - 22)
	_label.size = Vector2(48, 16)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.add_theme_font_size_override("font_size", 10)
	_label.add_theme_color_override("font_color", Color(1, 0.3, 0.2, 0.8))
	_label.text = "门关着"
	add_child(_label)


func _process(_delta: float) -> void:
	_resolve_pair()
	if not _pair:
		return

	var past: bool = _pair.get("ctc_past_active") if _pair else false
	var switched: bool = _pair.get("switch_activated") if _pair else false
	var is_open := past or switched

	if is_open == _was_open:
		return
	_was_open = is_open

	if is_open:
		_open_door()
	else:
		_close_door()


func _resolve_pair() -> void:
	if _pair:
		return
	if wormhole_pair_path and not wormhole_pair_path.is_empty():
		_pair = get_node_or_null(wormhole_pair_path)


func _open_door() -> void:
	# 碰撞禁用
	_col_shape.set_deferred("disabled", true)
	# 视觉变绿变透明
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(_visual, "color", open_color, 0.5)
	_label.text = "门开着"
	_label.add_theme_color_override("font_color", Color(0.2, 0.9, 0.3, 0.8))


func _close_door() -> void:
	_col_shape.set_deferred("disabled", false)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(_visual, "color", closed_color, 0.5)
	_label.text = "门关着"
	_label.add_theme_color_override("font_color", Color(1, 0.3, 0.2, 0.8))
