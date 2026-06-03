class_name Player
extends CharacterBody2D
## Player — 时空观测员
## 铁律：输入处理在 _process（实时），物理计算在 _physics_process
## sprint 加速 → scene_time_scale ↑ → 场景物体加速


# ============================================================
# 导出参数
# ============================================================

@export_category("Movement")
@export var walk_speed: float = 200.0
@export var sprint_speed: float = 600.0
@export var acceleration: float = 800.0
@export var friction: float = 600.0

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


# ============================================================
# 生命周期
# ============================================================

func _ready() -> void:
	_visual_root = get_node_or_null("VisualRoot")
	_last_safe_position = global_position


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

	# 水平移动
	var target_speed: float = sprint_speed if _is_sprinting else walk_speed
	var input_dir: float = Input.get_axis("move_left", "move_right")

	if input_dir != 0.0:
		var target_vx: float = input_dir * target_speed
		# 加速
		velocity.x = move_toward(velocity.x, target_vx, acceleration * delta)
		# 检查光速红线
		if SpeedTimeCoupling.is_over_redline(absf(velocity.x)):
			_bounce_from_redline()
	else:
		velocity.x = move_toward(velocity.x, 0.0, friction * delta)

	# 跳跃（实时输入）
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity

	move_and_slide()


## 光速红线弹回
func _bounce_from_redline() -> void:
	# 弹回方向与速度
	velocity.x = -signf(velocity.x) * SpeedTimeCoupling.SPEED_REDLINE * 0.7
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


func get_last_safe_position() -> Vector2:
	return _last_safe_position


# ============================================================
# 信号
# ============================================================

signal redline_bounced()
