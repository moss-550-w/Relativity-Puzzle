extends StaticBody2D
## 光速红线壁垒（M1-2 核心机制）
## 高速冲撞 → 弹回 + 红移闪光 + 低沉音效
## 教学：光速是宇宙硬上限，无法靠蛮力（速度）穿越，需绕路或借时间差
##
## 节点本体为实心墙（StaticBody2D，任何速度都无法穿过）；
## 子 Area2D 探测区比墙略宽，高速接近时提前触发强弹回与特效。


@export_category("Barrier")
## 壁垒高度（像素）
@export var bar_height: float = 340.0
## 壁垒宽度
@export var bar_width: float = 28.0
## 触发强弹回的速度阈值
@export var bounce_speed_threshold: float = 220.0
## 弹回水平冲量
@export var bounce_force: float = 540.0
## 解锁图鉴 id
@export var codex_id: String = "light_speed_barrier"

var _stripes: Array[ColorRect] = []
var _core: ColorRect = null
var _flash_layer: CanvasLayer = null
var _flash_rect: ColorRect = null
var _t: float = 0.0


func _ready() -> void:
	collision_layer = 1   # world 层，阻挡玩家
	collision_mask = 0

	_build_collision()
	_build_visual()
	_build_sensor()


# ============================================================
# 构建
# ============================================================

func _build_collision() -> void:
	var col := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(bar_width, bar_height)
	col.shape = rect
	add_child(col)


func _build_visual() -> void:
	# 半透红主体
	var body := ColorRect.new()
	body.size = Vector2(bar_width, bar_height)
	body.position = Vector2(-bar_width / 2.0, -bar_height / 2.0)
	body.color = Color(1.0, 0.15, 0.1, 0.4)
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(body)

	# 中心亮线（脉冲）
	_core = ColorRect.new()
	_core.size = Vector2(4, bar_height)
	_core.position = Vector2(-2, -bar_height / 2.0)
	_core.color = Color(1.0, 0.45, 0.35, 0.9)
	_core.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_core)

	# 流动警示条纹
	var count := int(bar_height / 56.0)
	for i in count:
		var s := ColorRect.new()
		s.size = Vector2(bar_width, 6)
		s.color = Color(1.0, 0.6, 0.2, 0.5)
		s.position = Vector2(-bar_width / 2.0, -bar_height / 2.0 + i * 56.0)
		s.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(s)
		_stripes.append(s)


func _build_sensor() -> void:
	var sensor := Area2D.new()
	sensor.name = "Sensor"
	sensor.collision_layer = 0
	sensor.collision_mask = 2  # 仅检测 player 层
	var scol := CollisionShape2D.new()
	var srect := RectangleShape2D.new()
	srect.size = Vector2(bar_width + 64.0, bar_height)
	scol.shape = srect
	sensor.add_child(scol)
	add_child(sensor)
	sensor.body_entered.connect(_on_sensor_body_entered)


# ============================================================
# 动画
# ============================================================

func _process(delta: float) -> void:
	_t += delta
	# 条纹向下流动
	for i in _stripes.size():
		var base := -bar_height / 2.0 + i * 56.0
		_stripes[i].position.y = base + fmod(_t * 45.0, 56.0)
	# 中心线脉冲
	if _core:
		_core.color.a = 0.6 + sin(_t * 6.0) * 0.3


# ============================================================
# 弹回逻辑
# ============================================================

func _on_sensor_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	# 首次接触壁垒即解锁图鉴（教学时机）
	CodexManager.unlock(codex_id)

	var speed: float = body.velocity.length()
	if speed >= bounce_speed_threshold:
		_bounce(body)


func _bounce(body: Node2D) -> void:
	# 朝远离壁垒方向弹回
	var dir := signf(body.global_position.x - global_position.x)
	if dir == 0.0:
		dir = -1.0
	body.velocity.x = dir * bounce_force
	body.velocity.y = minf(body.velocity.y, -160.0)  # 轻微上抛增强手感

	# 清空玩家累积速度（若有该接口）
	if body.has_method("reset_ramp"):
		body.reset_ramp()

	AudioManager.play_sfx("redline_bounce")
	_flash()


## 全屏红移闪光
func _flash() -> void:
	if not is_instance_valid(_flash_layer):
		_flash_layer = CanvasLayer.new()
		_flash_layer.layer = 50
		add_child(_flash_layer)
		_flash_rect = ColorRect.new()
		_flash_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
		_flash_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_flash_layer.add_child(_flash_rect)

	_flash_rect.color = Color(1.0, 0.1, 0.1, 0.0)
	var tw := create_tween()
	tw.tween_property(_flash_rect, "color:a", 0.45, 0.05)
	tw.tween_property(_flash_rect, "color:a", 0.0, 0.4)
