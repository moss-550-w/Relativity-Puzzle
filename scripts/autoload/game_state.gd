extends Node
## GameState — 游戏全局状态管理
## 当前世界/关卡索引、暂停、谜题重置信号、进度追踪、关卡注册表


# ---- 枚举 ----

enum World {
	WORLD_1_LORENTZ = 1,
	WORLD_2_GRAVITY = 2,
	WORLD_3_QUANTUM = 3,
	WORLD_4_ENTROPY = 4,
}


# ---- 关卡注册表 ----

const LEVEL_REGISTRY: Dictionary = {
	World.WORLD_1_LORENTZ: {
		"name": "洛伦兹平原",
		"subtitle": "狭义相对论",
		"color": Color(0.3, 0.8, 1.0),
		"levels": [
			{"id": 1, "name": "M1-1 三重时间考验", "scene": "res://scenes/world_1_lorentz/level_1_1.tscn"},
			{"id": 2, "name": "M1-2 光速红线", "scene": "res://scenes/world_1_lorentz/level_1_2.tscn"},
			{"id": 3, "name": "M1-3 光锥边界", "scene": "res://scenes/world_1_lorentz/level_1_3.tscn"},
		],
	},
	World.WORLD_2_GRAVITY: {
		"name": "引力深渊",
		"subtitle": "广义相对论",
		"color": Color(0.6, 0.4, 1.0),
		"levels": [
			{"id": 1, "name": "M2-1 引力时间膨胀", "scene": "res://scenes/world_2_gravity/level_2_1.tscn"},
			{"id": 2, "name": "M2-2 闭合类时曲线", "scene": "res://scenes/world_2_gravity/level_2_2.tscn"},
			{"id": 3, "name": "BOSS 克尔黑洞", "scene": "res://scenes/world_2_gravity/boss_ker_blackhole.tscn"},
		],
	},
	World.WORLD_3_QUANTUM: {
		"name": "量子泡沫秘境",
		"subtitle": "量子引力",
		"color": Color(0.3, 1.0, 0.6),
		"levels": [
			{"id": 1, "name": "M3-1 卡西米尔效应", "scene": "res://scenes/world_3_quantum/level_3_1.tscn"},
			{"id": 2, "name": "M3-2 量子裂隙网络", "scene": "res://scenes/world_3_quantum/level_3_2.tscn"},
			{"id": 3, "name": "M3-3 时序保护", "scene": "res://scenes/world_3_quantum/level_3_3.tscn"},
		],
	},
	World.WORLD_4_ENTROPY: {
		"name": "熵之终焉",
		"subtitle": "熵与时间本质",
		"color": Color(1.0, 0.7, 0.3),
		"levels": [
			{"id": 1, "name": "上层 熵之斜坡", "scene": "res://scenes/world_4_entropy/level_4_upper.tscn"},
			{"id": 2, "name": "中层 时间的碎片", "scene": "res://scenes/world_4_entropy/level_4_middle.tscn"},
			{"id": 3, "name": "底层 本源静止空间", "scene": "res://scenes/world_4_entropy/level_4_bottom.tscn"},
		],
	},
}


# ---- 状态 ----

var current_world: World = World.WORLD_1_LORENTZ
var current_level: int = 1
var is_paused: bool = false:
	set(v):
		is_paused = v
		get_tree().paused = v
## 是否已获得二段跳能力（克尔黑洞 BOSS 关解锁，持久生效）
var double_jump_unlocked: bool = false

## 已完成关卡：{ World: [level_id, ...] }
var completed_levels: Dictionary = {}


# ---- 信号 ----

signal puzzle_reset
signal level_completed(level_name: String)


# ---- 进度查询 ----

## 某关是否已解锁（前关已完成 或 为第一关且世界已解锁）
func is_level_unlocked(world: World, level: int) -> bool:
	if not is_world_unlocked(world):
		return false
	if level == 1:
		return true
	return is_level_completed(world, level - 1)


## 某世界是否已解锁
func is_world_unlocked(world: World) -> bool:
	if world == World.WORLD_1_LORENTZ:
		return true
	var prev_world: int = world - 1
	var prev_data: Dictionary = LEVEL_REGISTRY.get(prev_world, {})
	var prev_levels: Array = prev_data.get("levels", [])
	if prev_levels.is_empty():
		return false
	var last_level: int = prev_levels[-1]["id"]
	return is_level_completed(prev_world, last_level)


## 某关是否已完成
func is_level_completed(world: World, level: int) -> bool:
	return (completed_levels.get(world, []) as Array).has(level)


## 获取下一关数据（含 world 字段），无则返回空 {}
func get_next_level(world: World, level: int) -> Dictionary:
	var world_data: Dictionary = LEVEL_REGISTRY.get(world, {})
	var levels: Array = world_data.get("levels", [])
	var next_id: int = level + 1
	for lv in levels:
		if lv["id"] == next_id:
			var result: Dictionary = lv.duplicate()
			result["world"] = world
			return result
	# 跨世界：当前世界最后关 → 下一世界第一关
	var next_world: int = world + 1
	var next_data: Dictionary = LEVEL_REGISTRY.get(next_world, {})
	var next_levels: Array = next_data.get("levels", [])
	if next_levels.is_empty():
		return {}
	var result: Dictionary = (next_levels[0] as Dictionary).duplicate()
	result["world"] = next_world
	return result


## 查某关元数据
func get_level_data(world: World, level: int) -> Dictionary:
	var world_data: Dictionary = LEVEL_REGISTRY.get(world, {})
	for lv in world_data.get("levels", []):
		if lv["id"] == level:
			return lv
	return {}


# ---- 进度变更 ----

## 标记关卡完成 + 自动解锁下一关
func mark_level_completed(world: World, level: int) -> void:
	if not completed_levels.has(world):
		completed_levels[world] = []
	var arr: Array = completed_levels[world] as Array
	if not arr.has(level):
		arr.append(level)


## 是否有任何进度
func has_any_progress() -> bool:
	return not completed_levels.is_empty()


## 重置所有进度（新游戏）
func reset_progress() -> void:
	completed_levels.clear()
	current_world = World.WORLD_1_LORENTZ
	current_level = 1
	double_jump_unlocked = false


# ---- 谜题 / 关卡操作 ----

## 重置当前谜题（无惩罚）
func reset_current_puzzle() -> void:
	TimeManager.reset()
	puzzle_reset.emit()


## 关卡完成
func complete_level() -> void:
	mark_level_completed(current_world, current_level)
	level_completed.emit("%s_L%d" % [World.keys()[current_world - 1], current_level])
