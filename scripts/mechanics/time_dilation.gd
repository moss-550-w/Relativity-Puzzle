class_name TimeAffectedBody
## 受时间效应影响的物体基类
## 所有平台、NPC 等需继承此类，通过 get_effective_time_scale() 获取缩放后时间

extends Node2D


## 局部时间缩放（相对于场景基准时间 1.0）
var local_time_scale: float = 1.0


## 获得最终有效时间缩放因子
## 世界1：仅叠加 scene_time_scale
## 后续世界可扩展引力/熵增因子
func get_effective_time_scale() -> float:
	return TimeManager.calculate_time_scale(self)


## 返回经时间膨胀后的帧 delta
## 场景物体在 _process/_physics_process 中调用此值
func dilated_delta(delta: float) -> float:
	return delta * get_effective_time_scale()
