extends "res://scenes/world_1_lorentz/level_base.gd"
## M1-1 关卡控制器 — "三重时间考验"
## Zone 1: 闸门 — 提速让闸门周期加速 → 乘隙穿过
## Zone 2: 移动平台 — 提速让平台快进靠岸
## Zone 3: 终点碎片
##
## 隐藏彩蛋：向左走进入"双生子小屋"


const TwinRoom = preload("res://scripts/npc/twin_room.gd")


func _get_hints() -> Array:
	return [
		{"text": "长按方向键持续加速，Shift 急速冲刺 → 闸门加速 → 乘隙穿过", "pos": Vector2(360, 470)},
		{"text": "提速让平台快点过来 ←", "pos": Vector2(760, 460)},
	]


func _on_level_ready() -> void:
	_spawn_twin_room_passage()


# ============================================================
# 双生子小屋 — 隐藏通道 + 房间
# ============================================================

func _spawn_twin_room_passage() -> void:
	# 左侧通道地板（x=-300 ~ x=0，衔接出生平台左边）
	var passage := StaticBody2D.new()
	passage.name = "PassageFloor"
	passage.position = Vector2(-150, 620)
	passage.collision_mask = 0
	var pcol := CollisionShape2D.new()
	var prect := RectangleShape2D.new()
	prect.size = Vector2(300, 32)
	pcol.shape = prect
	passage.add_child(pcol)
	var pvis := ColorRect.new()
	pvis.name = "Visual"
	pvis.offset_left = -150.0
	pvis.offset_top = -16.0
	pvis.offset_right = 150.0
	pvis.offset_bottom = 16.0
	pvis.color = Color(0.28, 0.28, 0.38, 1)  # 略微更暗，暗示隐藏区域
	passage.add_child(pvis)
	add_child(passage)

	# 隐藏箭头提示
	var arrow := Label.new()
	arrow.name = "HintArrow"
	arrow.text = "←  ?"
	arrow.position = Vector2(-58, 580)
	arrow.add_theme_font_size_override("font_size", 16)
	arrow.add_theme_color_override("font_color", Color(0.3, 0.7, 1.0, 0.45))
	add_child(arrow)

	# 房间入口标记（地面两个光点）
	var marker_l := Polygon2D.new()
	marker_l.name = "DoorMarkerL"
	marker_l.color = Color(0.3, 0.8, 1.0, 0.35)
	marker_l.polygon = PackedVector2Array([
		Vector2(0, -6), Vector2(4, 0), Vector2(0, 6), Vector2(-4, 0),
	])
	marker_l.position = Vector2(-310, 610)
	add_child(marker_l)

	var marker_r := Polygon2D.new()
	marker_r.name = "DoorMarkerR"
	marker_r.color = Color(0.3, 0.8, 1.0, 0.35)
	marker_r.polygon = PackedVector2Array([
		Vector2(0, -6), Vector2(4, 0), Vector2(0, 6), Vector2(-4, 0),
	])
	marker_r.position = Vector2(-290, 610)
	add_child(marker_r)

	# 实例化双生子小屋（房间定位：右墙对齐通道末端 x≈-300）
	var room := Node2D.new()
	room.name = "TwinRoom"
	room.set_script(TwinRoom)
	room.position = Vector2(-550, 620)
	add_child(room)
