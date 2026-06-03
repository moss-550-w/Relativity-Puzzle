extends AnimatableBody2D
## 受时间膨胀影响的移动平台
## 两点间周期往返，位移使用 TimeManager.scaled_delta
## 玩家 sprint → scene_time_scale ↑ → 平台快进


@export_category("Motion")
## 终点（相对起点偏移）
@export var travel_offset: Vector2 = Vector2(0, -200)
## 单程时长（秒，基准时间流速下的周期）
@export var cycle_duration: float = 4.0
## 出发前停顿时间（秒）
@export var pause_time: float = 1.0
## 是否初始向上/向右
@export var start_forward: bool = true

@export_category("Visual")
@export var platform_color: Color = Color(0.4, 0.8, 0.4, 0.9)


var _start_position: Vector2
var _end_position: Vector2
var _elapsed: float = 0.0
var _going_forward: bool = true
var _pausing: bool = true
var _pause_elapsed: float = 0.0
var _body_sprite: ColorRect = null


func _ready() -> void:
	_start_position = global_position
	_end_position = _start_position + travel_offset
	if not start_forward:
		_going_forward = false

	# 创建视觉占位：绿色矩形
	_body_sprite = ColorRect.new()
	_body_sprite.size = Vector2(80, 16)
	_body_sprite.color = platform_color
	_body_sprite.position = -_body_sprite.size / 2
	add_child(_body_sprite)

	# 添加碰撞体（如果场景未附）
	var collision := get_node_or_null("CollisionShape2D")
	if not collision:
		var shape := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = Vector2(80, 16)
		shape.shape = rect
		collision_layer = 4  # platform layer
		add_child(shape)


func _physics_process(delta: float) -> void:
	# 使用时间膨胀后的 delta
	var eff_delta: float = TimeManager.scaled_delta(delta)

	if _pausing:
		_pause_elapsed += eff_delta
		if _pause_elapsed >= pause_time:
			_pausing = false
			_pause_elapsed = 0.0
		return

	_elapsed += eff_delta

	var progress: float = clampf(_elapsed / cycle_duration, 0.0, 1.0)
	if not _going_forward:
		progress = 1.0 - progress

	global_position = _start_position.lerp(_end_position, progress)

	if _elapsed >= cycle_duration:
		_elapsed = 0.0
		_going_forward = not _going_forward
		_pausing = true
		_pause_elapsed = 0.0
