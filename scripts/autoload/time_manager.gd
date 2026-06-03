extends Node
## TimeManager — 全局时间控制中枢
## 世界1：玩家速度驱动 scene_time_scale（洛伦兹因子）
## 后续世界扩展引力/熵减速因子
##
## 关键铁律：玩家操作绝对即时（使用原始delta），场景物体使用 scaled_delta


# 游戏内光速值（与 SpeedTimeCoupling 保持一致）
const LIGHT_SPEED: float = 1000.0
# 场景时间缩放最小/最大值
const MIN_SCALE: float = 1.0
const MAX_SCALE: float = 50.0

# ---- 核心状态 ----

## 场景基准时间缩放因子（1.0 = 正常流速）
## 世界1：等于玩家当前洛伦兹因子
var scene_time_scale: float = 1.0:
	set(v):
		var clamped = clampf(v, MIN_SCALE, MAX_SCALE)
		if not is_equal_approx(scene_time_scale, clamped):
			scene_time_scale = clamped
			scene_time_scale_changed.emit(scene_time_scale)

## 玩家洛伦兹因子（供视觉效果使用：尺缩、蓝移/红移）
var player_lorentz_factor: float = 1.0

# ---- 信号 ----

## 场景时间缩放发生变化
signal scene_time_scale_changed(new_scale: float)

# ---- 公开方法 ----

## 由玩家每帧调用，传入当前速度标量，更新场景时间
func update_from_player_speed(speed: float) -> void:
	var gamma: float = SpeedTimeCoupling.lorentz_factor(speed)
	player_lorentz_factor = gamma
	scene_time_scale = gamma  # 世界1：场景时间直接 = γ


## 供场景物体调用：返回经时间膨胀后的 delta
## 如 moving_platform.gd 在位移计算中调用
func scaled_delta(delta: float) -> float:
	return delta * scene_time_scale


## 供玩家调用：返回原始 delta（实时响应）
func player_delta(delta: float) -> float:
	return delta


## 供 TimeAffectedBody 调用：计算某物体的综合时间缩放
## 当前（世界1）仅叠加 scene_time_scale，后续扩展引力/熵因子
func calculate_time_scale(body: TimeAffectedBody) -> float:
	var scale: float = body.local_time_scale * scene_time_scale
	return clampf(scale, 0.0, MAX_SCALE)


## 重置时间缩放（谜题重置时调用）
func reset() -> void:
	scene_time_scale = 1.0
	player_lorentz_factor = 1.0
