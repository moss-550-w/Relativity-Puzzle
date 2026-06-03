extends "res://scenes/world_1_lorentz/level_base.gd"
## M3-1 关卡控制器 — "卡西米尔效应"
##
## 谜题：封闭空间只能通过不稳定虫洞进入
## 将两块金属板推拢 → 产生负能量 → 稳定虫洞 → 穿越


func _get_hints() -> Array:
	return [
		{"text": "[F] 推动金属板，让它们靠近彼此", "pos": Vector2(380, 500)},
		{"text": "卡西米尔效应：真空中的板靠近 → 负能量", "pos": Vector2(480, 450)},
		{"text": "负能量稳定虫洞 ← 穿过去", "pos": Vector2(680, 500)},
	]
