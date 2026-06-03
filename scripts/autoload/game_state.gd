extends Node
## GameState — 游戏全局状态管理
## 当前世界/关卡索引、暂停、谜题重置信号


# ---- 枚举 ----

enum World {
	WORLD_1_LORENTZ = 1,
	WORLD_2_GRAVITY = 2,
	WORLD_3_QUANTUM = 3,
	WORLD_4_ENTROPY = 4,
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

# ---- 信号 ----

signal puzzle_reset
signal level_completed(level_name: String)

# ---- 方法 ----

## 重置当前谜题（无惩罚）
func reset_current_puzzle() -> void:
	TimeManager.reset()
	puzzle_reset.emit()


## 关卡完成
func complete_level() -> void:
	level_completed.emit("%s_L%d" % [World.keys()[current_world - 1], current_level])
