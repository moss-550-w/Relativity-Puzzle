extends Node2D
## 周期性升降闸门 — 受 scene_time_scale 影响
## 冲刺加速 → 闸门快速升降 → 玩家可把握时机穿过


@export_category("Motion")
## 闸门升降范围（相对起始位置）
@export var travel_range: float = 200.0
## 一个完整升降周期时间（基准流速下秒数）
@export var cycle_duration: float = 6.0
## 初始相位 [0,1]（0=升起/关闭, 0.5=降下/打开）
@export var initial_phase: float = 0.0
## 闸门宽度
@export var gate_width: float = 80.0

@export_category("Visual")
@export var gate_color: Color = Color(0.9, 0.3, 0.15, 0.85)


var _start_y: float
var _elapsed: float
var _body: ColorRect = null
var _area: Area2D = null


func _ready() -> void:
	_start_y = global_position.y
	_elapsed = initial_phase * cycle_duration

	# 视觉
	_body = ColorRect.new()
	_body.name = "Visual"
	_body.size = Vector2(gate_width, travel_range * 0.35)
	_body.color = gate_color
	_body.position = Vector2(-gate_width / 2.0, -travel_range * 0.35 / 2.0)
	add_child(_body)

	# 碰撞体
	var collision := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(gate_width, travel_range * 0.35)
	collision.shape = rect
	collision.position = Vector2(0, -travel_range * 0.35 / 2.0)

	_area = Area2D.new()
	_area.name = "GateBlocker"
	_area.collision_layer = 4
	_area.collision_mask = 0
	_area.add_child(collision)
	add_child(_area)

	# 装饰性警示条纹
	var stripe := ColorRect.new()
	stripe.name = "Stripe"
	stripe.size = Vector2(gate_width, 8)
	stripe.color = Color.YELLOW
	stripe.position = Vector2(-gate_width / 2.0, 0)
	add_child(stripe)


func _physics_process(delta: float) -> void:
	var eff_delta := TimeManager.scaled_delta(delta)
	_elapsed = fmod(_elapsed + eff_delta, cycle_duration)

	var phase := _elapsed / cycle_duration
	# 用正弦波模拟升降：phase 0=升起(顶), 0.5=降下(底)
	var offset := sin(phase * TAU) * travel_range * 0.5
	_body.position.y = -travel_range * 0.35 / 2.0 + offset
	_area.position.y = offset

	# 根据闸门位置决定是否阻挡（顶部时阻挡，底部时可通过）
	# area 在 y 偏移 < -30 时挡住玩家（闸门升起）
	var blocking := offset < -30.0
	_area.set_deferred("monitoring", blocking)
	_area.set_deferred("monitorable", blocking)


func reset_state() -> void:
	_elapsed = initial_phase * cycle_duration
