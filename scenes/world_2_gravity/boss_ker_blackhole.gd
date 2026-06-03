extends "res://scenes/world_1_lorentz/level_base.gd"
## BOSS 关 — 克尔黑洞
## 三阶段穿越挑战（非战斗）
## Phase 1: 穿越能层 + 碎片环 → 外视界
## Phase 2: 视界间通道 + 时间泡 → 内视界
## Phase 3: 奇环间隙穿越 → 核心 → 完成


func _get_hints() -> Array:
	return [
		{"text": "黑洞在旋转——时空本身在流动。逆流而上", "pos": Vector2(400, 530)},
		{"text": "不要冲刺！静止让时间减速，碎片间隙会变长", "pos": Vector2(600, 480)},
		{"text": "奇环有间隙——观察节奏，等待时机穿越", "pos": Vector2(250, 300)},
	]
