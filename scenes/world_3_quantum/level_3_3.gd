extends "res://scenes/world_1_lorentz/level_base.gd"
## M3-3 关卡控制器 — "时序保护"
##
## 综合关：负能量板稳定裂隙 + 观测键延长窗口 + 时序保护上限
## 霍金：宇宙禁止宏观时间旅行。观测干预 ≤2 次，第 3 次触发粒子风暴重置


func _get_hints() -> Array:
	return [
		{"text": "推拢金属板 → 负能量稳定裂隙 → 存续延长", "pos": Vector2(200, 500)},
		{"text": "按 [E] 观测延长时间 ← 但每次干预会计数", "pos": Vector2(500, 500)},
		{"text": "左上角 3 个标记 = 时序保护余量。用完即风暴", "pos": Vector2(350, 400)},
	]
