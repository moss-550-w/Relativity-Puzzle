extends Node2D
## M1-1 关卡控制器
## 教学谜题：玩家 sprint 提速 → 场景时间加速 → 移动平台快进到合适位置
## 加载 Player、HUD、TimeWarpOverlay、坠崖 KillZone

const _Player = preload("res://scripts/player/player.gd")

## 玩家出生点
const PLAYER_SPAWN := Vector2(100, 500)
## 坠落线（低于此 y 坐标视为坠崖）
const FALL_THRESHOLD_Y: float = 750.0

var _player: Node2D = null
var _platform: AnimatableBody2D = null
var _platform_start: Vector2 = Vector2.ZERO
var _level_done: bool = false


func _ready() -> void:
	_spawn_player()
	_spawn_hud()
	_spawn_overlay()
	_spawn_killzone()
	# 缓存移动平台初始位置
	_platform = get_node_or_null("MovingPlatform") as AnimatableBody2D
	if _platform:
		_platform_start = _platform.global_position
	# 监听信号
	GameState.puzzle_reset.connect(_on_puzzle_reset)
	GameState.level_completed.connect(_on_level_completed)


func _spawn_player() -> void:
	var scene: PackedScene = load("res://scenes/player.tscn")
	if not scene:
		push_error("无法加载 player.tscn")
		return
	_player = scene.instantiate()
	_player.global_position = PLAYER_SPAWN
	add_child(_player)


func _spawn_hud() -> void:
	var script: Script = load("res://scripts/ui/relative_clock.gd")
	if not script:
		push_error("无法加载 relative_clock.gd")
		return

	var hud := CanvasLayer.new()
	hud.name = "HUD"
	hud.layer = 10
	hud.set_script(script)

	var vbox := VBoxContainer.new()
	vbox.name = "VBox"
	vbox.anchor_right = 1.0
	vbox.offset_left = 16.0
	vbox.offset_top = 16.0
	vbox.offset_right = -800.0
	vbox.offset_bottom = 86.0

	var scale_label := Label.new()
	scale_label.name = "ScaleLabel"
	scale_label.text = "场景时间: x1.00"
	scale_label.add_theme_font_size_override("font_size", 18)
	vbox.add_child(scale_label)

	var speed_label := Label.new()
	speed_label.name = "SpeedLabel"
	speed_label.text = "速度: 0.0% c"
	speed_label.add_theme_font_size_override("font_size", 14)
	vbox.add_child(speed_label)

	hud.add_child(vbox)

	var toast := Label.new()
	toast.name = "ToastLabel"
	toast.visible = false
	toast.anchor_bottom = 1.0
	toast.anchor_right = 1.0
	toast.offset_left = 40.0
	toast.offset_top = -120.0
	toast.offset_right = -40.0
	toast.offset_bottom = -80.0
	toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	toast.add_theme_font_size_override("font_size", 22)
	hud.add_child(toast)

	var toast_timer := Timer.new()
	toast_timer.name = "ToastTimer"
	toast_timer.one_shot = true
	toast_timer.wait_time = 3.0
	hud.add_child(toast_timer)

	if not toast_timer.timeout.is_connected(hud._on_toast_timer_timeout):
		toast_timer.timeout.connect(hud._on_toast_timer_timeout)

	add_child(hud)


func _spawn_overlay() -> void:
	var overlay_script: Script = load("res://scripts/ui/time_warp_overlay.gd")
	if not overlay_script:
		push_error("无法加载 time_warp_overlay.gd")
		return
	var overlay := CanvasLayer.new()
	overlay.set_script(overlay_script)
	overlay.layer = -1
	add_child(overlay)


## 坠崖检测区 — 平台下方宽大 Area2D，玩家进入即重置
func _spawn_killzone() -> void:
	var killzone := Area2D.new()
	killzone.name = "KillZone"
	killzone.collision_layer = 1
	killzone.collision_mask = 2
	killzone.position = Vector2(640, FALL_THRESHOLD_Y)

	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(2000, 200)
	shape.shape = rect
	killzone.add_child(shape)

	killzone.body_entered.connect(_on_fall)

	add_child(killzone)


# ============================================================
# 信号回调
# ============================================================

func _on_fall(body: Node2D) -> void:
	if _level_done:
		return
	if body == _player:
		_reset_level_positions()


func _on_puzzle_reset() -> void:
	_reset_level_positions()


func _on_level_completed(_level_name: String) -> void:
	if _level_done:
		return
	_level_done = true

	# 冻结玩家
	if _player and _player.has_method("set_frozen"):
		_player.set_frozen(true)

	# 通关提示
	var msg := Label.new()
	msg.name = "CompleteMsg"
	msg.text = "[ 关卡完成: 时间膨胀 ]\n你已理解速度如何弯曲时间"
	msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	msg.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	msg.add_theme_font_size_override("font_size", 36)
	msg.add_theme_color_override("font_color", Color.GOLD)
	msg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var layer := CanvasLayer.new()
	layer.name = "CompleteLayer"
	layer.layer = 100
	layer.add_child(msg)
	add_child(layer)


# ============================================================
# 重置
# ============================================================

func _reset_level_positions() -> void:
	TimeManager.reset()
	if _player:
		_player.velocity = Vector2.ZERO
		_player.global_position = PLAYER_SPAWN
	if _platform:
		_platform.global_position = _platform_start
		if _platform.has_method("reset_state"):
			_platform.reset_state()
