class_name SpeedTimeCoupling
## 速度-时间耦合静态工具类（世界1）
## 提供洛伦兹因子、红线判断等纯函数，供 TimeManager / Player 复用

# 游戏内光速值（单位：像素/秒）
const LIGHT_SPEED: float = 1000.0
# 光速红线：速度超过此值触发弹回
const SPEED_REDLINE: float = 0.99 * LIGHT_SPEED
# 避免除零的下限
const MIN_SPEED: float = 1.0


## 返回洛伦兹因子 γ = 1 / sqrt(1 - v²/c²)
## speed: 玩家当前速率（标量）
static func lorentz_factor(speed: float) -> float:
	if speed < MIN_SPEED:
		return 1.0
	var ratio: float = speed / LIGHT_SPEED
	if ratio >= 1.0:
		return INF
	return 1.0 / sqrt(1.0 - ratio * ratio)


## 检查是否超过光速红线
static func is_over_redline(speed: float) -> bool:
	return speed >= SPEED_REDLINE


## 返回红光强度的归一化值 [0, 1]，用于驱动红移特效
static func get_redline_ratio(speed: float) -> float:
	# 在 0.8c ~ 0.99c 之间渐变
	var threshold: float = 0.8 * LIGHT_SPEED
	if speed <= threshold:
		return 0.0
	return clampf((speed - threshold) / (SPEED_REDLINE - threshold), 0.0, 1.0)
