extends Node2D
## 时序保护管理器 — M3-3 核心约束
## 追踪玩家 E 键观测干预次数。累积 ≥3 次触发高能粒子风暴
## 霍金时序保护猜想：宇宙禁止宏观时间旅行


# ---- 导出 ----

@export_category("Protection")
@export var max_interventions: int = 3
## 每次干预后计数衰减时间（秒）
@export var decay_time: float = 15.0
## 粒子风暴持续时间（秒）
@export var storm_duration: float = 2.0

@export_category("Visual")
@export var marker_positions: Array[Vector2] = [
	Vector2(20, 20), Vector2(50, 20), Vector2(80, 20)
]

# ---- 公开状态 ----

var intervention_count: int = 0:
	set(v):
		intervention_count = v
		_update_markers()
		if intervention_count >= max_interventions:
			_trigger_storm()

# ---- 内部 ----

var _markers: Array[Polygon2D] = []
var _decay_timer: float = 0.0
var _storming: bool = false


func _ready() -> void:
	_create_markers()
	add_to_group("chronology_protection")


# ============================================================
# HUD 标记
# ============================================================

func _create_markers() -> void:
	for i in max_interventions:
		var m := Polygon2D.new()
		m.name = "ChronoMarker%d" % i
		m.color = Color(0.3, 0.9, 1.0, 0.8)
		m.polygon = PackedVector2Array([
			Vector2(0, -8), Vector2(6, 0),
			Vector2(0, 8), Vector2(-6, 0),
		])
		if i < marker_positions.size():
			m.position = marker_positions[i]
		_markers.append(m)
		add_child(m)


func _update_markers() -> void:
	for i in max_interventions:
		if i < _markers.size():
			_markers[i].color.a = 0.15 if i < intervention_count else 0.8


# ============================================================
# 干预注册
# ============================================================

## 返回 true 表示安全，false 表示触发保护
func register_intervention() -> bool:
	if _storming:
		return false
	intervention_count += 1
	if intervention_count >= max_interventions:
		return false
	return true


# ============================================================
# 粒子风暴
# ============================================================

func _trigger_storm() -> void:
	if _storming:
		return
	_storming = true
	CodexManager.unlock("chronology_protection")

	# 全屏白色闪光
	var flash := ColorRect.new()
	flash.name = "ChronoFlash"
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash.color = Color(1.0, 1.0, 1.0, 0.0)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var cl := CanvasLayer.new()
	cl.layer = 100
	cl.add_child(flash)
	add_child(cl)

	var tw := create_tween()
	tw.tween_property(flash, "color", Color(1.0, 0.85, 0.3, 0.9), 0.3)
	tw.tween_property(flash, "color", Color(1.0, 0.3, 0.3, 0.6), 0.8)

	# 粒子风暴
	for i in 30:
		var dot := ColorRect.new()
		dot.size = Vector2(randf_range(2, 6), randf_range(2, 6))
		dot.color = Color(1.0, randf_range(0.2, 0.8), 0.1, 1.0)
		dot.position = Vector2(randf_range(0, 1280), randf_range(0, 720))
		dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cl.add_child(dot)
		var dt := create_tween()
		dt.tween_property(dot, "position", dot.position + Vector2(randf_range(-300, 300), randf_range(-300, 300)), storm_duration)
		dt.parallel().tween_property(dot, "color:a", 0.0, storm_duration)
		dt.tween_callback(dot.queue_free)

	AudioManager.play_sfx("redline_bounce")

	# 延迟重置
	await get_tree().create_timer(storm_duration).timeout
	flash.queue_free()
	cl.queue_free()
	_storming = false
	GameState.reset_current_puzzle()


# ============================================================
# 每帧衰减
# ============================================================

func _process(delta: float) -> void:
	if intervention_count <= 0 or _storming:
		return
	_decay_timer += delta
	if _decay_timer >= decay_time:
		_decay_timer = 0.0
		intervention_count = maxi(0, intervention_count - 1)


# ============================================================
# 重置
# ============================================================

func reset_state() -> void:
	intervention_count = 0
	_decay_timer = 0.0
	_storming = false
