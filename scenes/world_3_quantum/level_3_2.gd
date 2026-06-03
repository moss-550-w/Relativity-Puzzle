extends "res://scenes/world_1_lorentz/level_base.gd"
## M3-2 关卡控制器 — "量子裂隙网络"
##
## 三房间隔离，只能通过短暂出现的量子裂隙穿越墙壁
## 按 E（观测键）延长裂隙存续，在裂隙网络崩溃前连续穿越


func _get_hints() -> Array:
	return [
		{"text": "裂隙短暂涌现——量子真空的泡沫", "pos": Vector2(150, 500)},
		{"text": "靠近裂隙按 [E] 观测 → 延长存续 2 秒", "pos": Vector2(450, 500)},
		{"text": "裂隙成对连接：蓝紫=入口  金橙=出口", "pos": Vector2(650, 450)},
	]
