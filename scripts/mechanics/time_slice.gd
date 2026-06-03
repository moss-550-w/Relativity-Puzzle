extends Node2D
## 时间切片 — World 4 底层核心视觉
## 同一物体在 5 个时间位置的静态副本平铺展示
## 过去(红)→现在(白)→未来(蓝)，透明度递减


@export_category("Slice")
@export var slice_count: int = 5
@export var slice_spacing: float = 80.0
@export var slice_size: Vector2 = Vector2(64, 24)

@export_category("Color")
@export var past_color: Color = Color(1.0, 0.35, 0.25)    # 红
@export var present_color: Color = Color(0.9, 0.9, 0.9)    # 白
@export var future_color: Color = Color(0.25, 0.4, 1.0)    # 蓝

var _slices: Array[Polygon2D] = []


func _ready() -> void:
	var mid: int = slice_count / 2  # 中间=现在
	for i in slice_count:
		var offset: int = i - mid  # -2, -1, 0, +1, +2
		var t: float = float(i) / float(slice_count - 1)  # 0(past)→1(future)
		var alpha: float = 1.0 - absf(offset) * 0.3  # 越远离现在越透明

		var slice := Polygon2D.new()
		slice.name = "Slice%d" % offset
		slice.color = _lerp_slice_color(t, alpha)
		slice.polygon = PackedVector2Array([
			Vector2(-slice_size.x / 2.0, -slice_size.y / 2.0),
			Vector2(slice_size.x / 2.0, -slice_size.y / 2.0),
			Vector2(slice_size.x / 2.0, slice_size.y / 2.0),
			Vector2(-slice_size.x / 2.0, slice_size.y / 2.0),
		])
		slice.position = Vector2(float(offset) * slice_spacing, 0.0)
		_slices.append(slice)
		add_child(slice)

	# 时间流向指示线
	var arrow := Polygon2D.new()
	arrow.name = "TimeArrow"
	arrow.color = Color(1.0, 1.0, 1.0, 0.2)
	var left: float = float(-mid) * slice_spacing - slice_size.x / 2.0 - 20
	var right: float = float(mid) * slice_spacing + slice_size.x / 2.0 + 20
	arrow.polygon = PackedVector2Array([
		Vector2(left, 20), Vector2(right, 20),
		Vector2(right, 18), Vector2(right + 12, 23), Vector2(right, 28),
		Vector2(right, 26), Vector2(left, 26),
	])
	add_child(arrow)

	# 标签
	var past_label := _make_label("← 过去", Vector2(left, 36), past_color)
	past_label.add_theme_color_override("font_color", past_color)
	add_child(past_label)
	var future_label := _make_label("未来 →", Vector2(right - 50, 36), future_color)
	future_label.add_theme_color_override("font_color", future_color)
	add_child(future_label)
	var now_label := _make_label("现在", Vector2(-15, -slice_size.y / 2.0 - 20), present_color)
	add_child(now_label)


func _lerp_slice_color(t: float, alpha: float) -> Color:
	var col: Color
	if t < 0.5:
		col = past_color.lerp(present_color, t * 2.0)
	else:
		col = present_color.lerp(future_color, (t - 0.5) * 2.0)
	col.a = alpha
	return col


func _make_label(text: String, pos: Vector2, _col: Color) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.position = pos
	lbl.add_theme_font_size_override("font_size", 10)
	lbl.add_theme_color_override("font_color", Color(1, 1, 1, 0.4))
	return lbl
