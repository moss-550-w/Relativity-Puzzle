extends Node
## TimeManager — 全局时间控制中枢
## 世界1：玩家速度驱动 scene_time_scale（洛伦兹因子）
## 世界2：追加引力时间膨胀（gravity_factor）
## 后续世界扩展熵减速因子
##
## 关键铁律：玩家操作绝对即时（使用原始delta），场景物体使用 scaled_delta


# 预加载类依赖（autoload 先于 class_name 脚本编译，必须 preload）
const _SpeedTimeCoupling = preload("res://scripts/mechanics/speed_time_coupling.gd")
const _TimeAffectedBody = preload("res://scripts/mechanics/time_dilation.gd")

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

## 引力时间膨胀因子（World 2+，1.0 = 无引力影响，< 1.0 = 场景减速）
## 由 GravityZone 在玩家进入/离开时平滑 tween
var gravity_factor: float = 1.0:
	set(v):
		var clamped = clampf(v, 0.05, 1.0)
		if not is_equal_approx(gravity_factor, clamped):
			gravity_factor = clamped
			gravity_factor_changed.emit(gravity_factor)

## 玩家洛伦兹因子（供视觉效果使用：尺缩、蓝移/红移）
var player_lorentz_factor: float = 1.0
## 玩家当前速率（供音频合成器使用）
var player_speed: float = 0.0
## 红线接近度 [0, 1]（供音频合成器使用）
var redline_ratio: float = 0.0

# ---- 信号 ----

## 场景时间缩放发生变化
signal scene_time_scale_changed(new_scale: float)
## 引力因子发生变化
signal gravity_factor_changed(new_factor: float)

# ---- 公开方法 ----

## 由玩家每帧调用，传入当前速度标量，更新场景时间
func update_from_player_speed(speed: float) -> void:
	var gamma: float = _SpeedTimeCoupling.lorentz_factor(speed)
	player_lorentz_factor = gamma
	player_speed = speed
	redline_ratio = _SpeedTimeCoupling.get_redline_ratio(speed)
	scene_time_scale = gamma  # 世界1：场景时间直接 = γ


## 供场景物体调用：返回经时间膨胀后的 delta
## 综合速度膨胀 + 引力膨胀
func scaled_delta(delta: float) -> float:
	return delta * scene_time_scale * gravity_factor


## 供玩家调用：返回原始 delta（实时响应）
func player_delta(delta: float) -> float:
	return delta


## 供 TimeAffectedBody 调用：计算某物体的综合时间缩放
## 叠加 local_time_scale × scene_time_scale × gravity_factor
func calculate_time_scale(body: Node2D) -> float:
	var local_ts: float = body.get("local_time_scale") if body else 1.0
	var scale: float = local_ts * scene_time_scale * gravity_factor
	return clampf(scale, 0.0, MAX_SCALE)


## 重置时间缩放（谜题重置时调用）
func reset() -> void:
	scene_time_scale = 1.0
	gravity_factor = 1.0
	player_lorentz_factor = 1.0
	player_speed = 0.0
	redline_ratio = 0.0
