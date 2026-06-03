extends "res://scenes/world_1_lorentz/level_base.gd"
## M1-2 关卡控制器 — "光速红线"
##
## 教学：光速是宇宙硬上限，蛮力（高速冲撞）无法穿越红线壁垒
## 解法：下层主路被壁垒阻断 → 乘左侧速度耦合升降台到上层 → 从壁垒上方绕过
##
## 升降台受 scene_time_scale 驱动：玩家提速 → 升降台快速上行 → 缩短等待


func _get_hints() -> Array:
	return [
		{"text": "↑ 红线 = 光速壁垒，全速冲撞只会被弹回", "pos": Vector2(560, 360)},
		{"text": "← 站上升降台，提速让它快速升起，从上方绕过", "pos": Vector2(430, 520)},
	]
