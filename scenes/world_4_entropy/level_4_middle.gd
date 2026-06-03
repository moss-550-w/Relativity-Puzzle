extends "res://scenes/world_1_lorentz/level_base.gd"
## 世界 4 中层 — "时间的碎片"
##
## 多个时区拼接，每个时区独立时间流速
## 收集 3 个时间碎片穿越时区，感受时间相对性


func _get_hints() -> Array:
	return [
		{"text": "每个色区的时间流速不同——进入体验", "pos": Vector2(180, 500)},
		{"text": "红区极慢 ×0.05 ← 等待是唯一的策略", "pos": Vector2(400, 460)},
		{"text": "蓝区极快 ×5 ← 反应必须精准", "pos": Vector2(750, 460)},
		{"text": "灰区时间冻结 ×0 ← 利用惯性冲过去", "pos": Vector2(1200, 480)},
	]


func _on_level_ready() -> void:
	GameState.double_jump_unlocked = true
	EntropySystem.pause_entropy(true)  # 中层暂停全局熵增
