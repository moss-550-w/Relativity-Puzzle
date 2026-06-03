extends "res://scenes/world_1_lorentz/level_base.gd"
## M1-1 关卡控制器 — "三重时间考验"
## Zone 1: 闸门 — 提速让闸门周期加速 → 乘隙穿过
## Zone 2: 移动平台 — 提速让平台快进靠岸
## Zone 3: 终点碎片


func _get_hints() -> Array:
	return [
		{"text": "长按方向键持续加速，Shift 急速冲刺 → 闸门加速 → 乘隙穿过", "pos": Vector2(360, 470)},
		{"text": "提速让平台快点过来 ←", "pos": Vector2(760, 460)},
	]
