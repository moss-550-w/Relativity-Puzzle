extends Node
## EntropySystem — 全局熵增系统（World 4 核心）
## global_entropy [0,1] 线性递增，驱动平台崩解、视觉噪声、音频失真
## local_order_resources 供玩家消耗以暂缓局部崩解


# ---- 常量 ----

const ENTROPY_RATE: float = 0.008  # 每秒熵增速（~125s 到 1.0）

# ---- 状态 ----

var global_entropy: float = 0.0:
	set(v):
		var clamped: float = clampf(v, 0.0, 1.0)
		if not is_equal_approx(global_entropy, clamped):
			global_entropy = clamped
			entropy_changed.emit(global_entropy)
			# 里程碑检测
			var prev_milestone: int = _last_milestone
			_last_milestone = int(global_entropy * 4.0)  # 0,1,2,3,4
			if _last_milestone > prev_milestone:
				entropy_milestone.emit(global_entropy)

var local_order_resources: int = 3:
	set(v):
		local_order_resources = maxi(0, v)
		order_changed.emit(local_order_resources)

var _last_milestone: int = 0
var _paused: bool = false

# ---- 信号 ----

signal entropy_changed(value: float)
signal entropy_milestone(value: float)
signal order_changed(remaining: int)

# ---- 方法 ----

func _process(delta: float) -> void:
	if _paused:
		return
	global_entropy = minf(1.0, global_entropy + ENTROPY_RATE * delta)


## 消耗一次秩序能量，暂缓目标区域崩解 30s
func use_order_resource() -> bool:
	if local_order_resources <= 0:
		return false
	local_order_resources -= 1
	PlayerMetrics.entropy_resist_count += 1
	# 暂缓：熵值小幅度回退
	global_entropy = maxf(0.0, global_entropy - 0.12)
	return true


## 收集秩序能量光点
func add_order_resource() -> void:
	local_order_resources += 1


func pause_entropy(p: bool) -> void:
	_paused = p


func reset() -> void:
	global_entropy = 0.0
	local_order_resources = 3
	_paused = false
	_last_milestone = 0
