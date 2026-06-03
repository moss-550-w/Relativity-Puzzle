extends "res://scenes/world_1_lorentz/level_base.gd"
## M1-3 关卡控制器 — "光锥边界"
##
## 教学：未来光锥即因果可及区域，锥外无意义
## 机制：虚线边界 = 光锥安全区，走出 → 灰白冻结 → 3 秒后重置
## 中途有闸门需加速通过，但必须控制在锥区内


func _get_hints() -> Array:
	return [
		{"text": "虚线内 = 未来光锥范围，超出即冻结", "pos": Vector2(360, 470)},
		{"text": "冲刺让闸门快开 ← 但小心别冲出光锥", "pos": Vector2(800, 530)},
		{"text": "光锥之内即命运——没有捷径", "pos": Vector2(1350, 370)},
	]
