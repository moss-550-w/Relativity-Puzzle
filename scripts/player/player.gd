extends CharacterBody2D
## Player — 时空观测员
## 铁律：输入处理在 _process（实时），物理计算在 _physics_process
## 长按方向键 → 速度随时长持续累积；Shift → 累积速率倍增，迅速冲高
## 速度越高 → scene_time_scale ↑ → 场景物体加速
## 二段跳：克尔黑洞 BOSS 关解锁，GameState.double_jump_unlocked 持久生效

const _STC = preload("res://scripts/mechanics/speed_time_coupling.gd")


# ============================================================
# 导出参数
# ============================================================

@export_category("Movement")
## 起步速度（刚按下方向键时）
@export var base_speed: float = 150.0
## 长按可达的最高速度（接近光速红线）
@export var max_speed: float = 980.0
## 长按时速度累积速率（像素/秒²的目标提升）
@export var ramp_rate: float = 260.0
## Shift 冲刺时累积速率倍数
@export var sprint_multiplier: float = 3.5
## 实际速度趋近目标的加速度
@export var acceleration: float = 1200.0
## 松开方向键后的减速
@export var friction: float = 900.0

@export_category("Jump")
@export var jump_velocity: float = -400.0
@export var gravity: float = 980.0

@export_category("Visual")
@export var enable_length_contraction: bool = true
## 尺缩最小缩放比例（1/γ 下限）
@export var contraction_min_scale: float = 0.1


# ============================================================
# 内部状态
# ============================================================

var _is_sprinting: bool = false
var _is_frozen: bool = false
var _last_safe_position: Vector2 = Vector2.ZERO
var _visual_root: Node2D = null
## 当前方向（-1/0/1），用于检测换向重置累积
var _hold_dir: float = 0.0
## 长按累积出的目标速度（随按住时长增长）
var _ramped_speed: float = 0.0
## 剩余跳跃次数（1 = 单跳，2 = 二段跳，由 GameState.double_jump_unlocked 控制）
var _jumps_remaining: int = 1


# ============================================================
# 生命周期
# ============================================================

func _ready() -> void:
	_visual_root = get_node_or_null("VisualRoot")
	_last_safe_position = global_position
	_jumps_remaining = 2 if GameState.double_jump_unlocked else 1


func _process(_delta: float) -> void:
	if _is_frozen:
		return
	_handle_input()


func _physics_process(delta: float) -> void:
	if _is_frozen:
		move_and_slide()
		return

	# 铁律：玩家物理使用实时 delta（绝不受时间膨胀影响）
	_apply_movement(delta)
	# 上报速度给全局时间系统
	TimeManager.update_from_player_speed(velocity.length())
	# 运动方向尺缩
	_update_length_contraction()
	# 更新安全位置（在地上的位置为安全点）
	if is_on_floor():
		_last_safe_position = global_position


# ============================================================
# 输入（_process）
# ============================================================

func _handle_input() -> void:
	# sprint
	_is_sprinting = Input.is_action_pressed("sprint")

	# 谜题重置
	if Input.is_action_just_pressed("reset_puzzle"):
		GameState.reset_current_puzzle()


# ============================================================
# 物理
# ============================================================

func _apply_movement(delta: float) -> void:
	# 重力（实时）
	if not is_on_floor():
		velocity.y += gravity * delta

	var input_dir: float = Input.get_axis("move_left", "move_right")

	if input_dir != 0.0:
		# 换向：重置累积，从起步速度重新积累
		if input_dir != _hold_dir:
			_hold_dir = input_dir
			_ramped_speed = base_speed

		# 长按持续累积目标速度；Shift 让累积速率倍增
		var rate := ramp_rate * (sprint_multiplier if _is_sprinting else 1.0)
		_ramped_speed = minf(_ramped_speed + rate * delta, max_speed)

		# 实际速度趋近累积目标
		var target_vx := input_dir * _ramped_speed
		velocity.x = move_toward(velocity.x, target_vx, acceleration * delta)

		# 光速红线
		if _STC.is_over_redline(absf(velocity.x)):
			_bounce_from_redline()
	else:
		# 松开方向键：累积清零，速度回落
		_hold_dir = 0.0
		_ramped_speed = 0.0
		velocity.x = move_toward(velocity.x, 0.0, friction * delta)

	# 跳跃 — 支持二段跳（GameState.double_jump_unlocked 控制）
	if Input.is_action_just_pressed("jump"):
		if is_on_floor():
			# 着地：重置跳跃次数
			_jumps_remaining = 2 if GameState.double_jump_unlocked else 1
			velocity.y = jump_velocity
			_jumps_remaining -= 1
			AudioManager.play_sfx("jump")
		elif _jumps_remaining > 0:
			# 空中二段跳：略小的上推力
			velocity.y = jump_velocity * 0.85
			_jumps_remaining -= 1
			AudioManager.play_sfx("jump")

	move_and_slide()


## 光速红线弹回
func _bounce_from_redline() -> void:
	# 清空累积速度，避免立即再次触发
	_ramped_speed = base_speed
	# 弹回方向与速度
	velocity.x = -signf(velocity.x) * _STC.SPEED_REDLINE * 0.7
	# 触发红移信号（M1-2机制就位，视觉效果由Shader层响应）
	redline_bounced.emit()
	AudioManager.play_sfx("redline_bounce")


# ============================================================
# 视觉
# ============================================================

## 根据洛伦兹因子做运动方向尺缩
## 碰撞体不受影响，仅视觉根节点变形
func _update_length_contraction() -> void:
	if not _visual_root or not enable_length_contraction:
		return
	var gamma: float = TimeManager.player_lorentz_factor
	if gamma <= 1.0:
		_visual_root.scale = Vector2.ONE
		return
	var squeeze: float = clampf(1.0 / gamma, contraction_min_scale, 1.0)
	# 横向压缩（运动方向），纵向不变
	_visual_root.scale.x = squeeze
	_visual_root.scale.y = 1.0


# ============================================================
# 外部接口
# ============================================================

func set_frozen(frozen: bool) -> void:
	_is_frozen = frozen
	if frozen:
		velocity = Vector2.ZERO
		_ramped_speed = 0.0
		_hold_dir = 0.0


func get_last_safe_position() -> Vector2:
	return _last_safe_position


## 清空速度累积（光速壁垒弹回时由外部调用）
func reset_ramp() -> void:
	_ramped_speed = 0.0
	_hold_dir = 0.0


# ============================================================
# 信号
# ============================================================

signal redline_bounced()
