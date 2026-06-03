extends Node
## PlayerMetrics — 玩家行为追踪（结局判定用）
## Phase 1：数据桩位，预建字段与接口，待后续世界填充


# ---- 行为统计 ----

## CTC 回溯次数（世界2+）
var wormhole_loop_count: int = 0

## 局部熵减干预次数（世界4）
var entropy_resist_count: int = 0

## 本源静止层停留时间（世界4底层）
var bottom_layer_idle_time: float = 0.0

## 修复时空碎片数量（全局）
var time_fragments_repaired: int = 0


# ---- 结局判定 ----

enum Ending {
	TOWARD_FUTURE,        # 奔赴未来
	CLOSED_LOOP_PRISON,   # 闭环囚笼
	SOURCE_INSIGHT,       # 本源顿悟
	NONE,                 # 尚未确定
}


## 基于行为统计判定结局
func determine_ending() -> Ending:
	if bottom_layer_idle_time > 60.0 and entropy_resist_count < 3:
		return Ending.SOURCE_INSIGHT
	elif wormhole_loop_count >= 3:
		return Ending.CLOSED_LOOP_PRISON
	elif time_fragments_repaired >= 3:
		return Ending.TOWARD_FUTURE
	return Ending.NONE


## 重置所有指标（新游戏）
func reset_all() -> void:
	wormhole_loop_count = 0
	entropy_resist_count = 0
	bottom_layer_idle_time = 0.0
	time_fragments_repaired = 0
