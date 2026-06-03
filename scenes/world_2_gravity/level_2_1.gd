extends "res://scenes/world_1_lorentz/level_base.gd"
## M2-1 关卡控制器 — "引力时间膨胀"
##
## 教学：靠近大质量天体 → 场景时间减慢
## 谜题：悬浮平台周期极短（0.8s），正常速度无法通过
##       → 进入引力区让场景减速（×0.25）→ 平台变慢 → 从容通过


func _get_hints() -> Array:
	return [
		{"text": "平台太快？进入紫色引力区让时间减速", "pos": Vector2(360, 470)},
		{"text": "引力越强，时间越慢 — 爱因斯坦的洞见", "pos": Vector2(700, 360)},
	]
