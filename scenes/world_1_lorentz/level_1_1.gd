extends Node2D
## M1-1 关卡控制器 — "三重时间考验"
##
## Zone 0: 起点 — 玩家自由行走，感受正常时间流速
## Zone 1: 闸门 — 冲刺 → 闸门周期加速 → 乘隙穿过（教学核心）
## Zone 2: 移动平台 — 冲刺 → 平台加速靠岸（强化理解）
## Zone 3: 终点碎片

const _Player = preload("res://scripts/player/player.gd")

const PLAYER_SPAWN := Vector2(100, 520)
const FALL_Y: float = 800.0
const LEVEL_WIDTH: float = 2800.0

var _player: Node2D = null
var _resettables: Array[Node] = []
var _level_done: bool = false


func _ready() -> void:
	_spawn_player()
	_spawn_hud()
	_spawn_hints()
	_spawn_overlay()
	_spawn_killzone()
	_cache_resettables()
	GameState.puzzle_reset.connect(_on_puzzle_reset)
	GameState.level_completed.connect(_on_level_completed)


# ============================================================
# 生成
# ============================================================

func _spawn_player() -> void:
	var scene: PackedScene = load("res://scenes/player.tscn")
	if not scene:
		return
	_player = scene.instantiate()
	_player.global_position = PLAYER_SPAWN
	add_child(_player)


func _spawn_hud() -> void:
	var script: Script = load("res://scripts/ui/relative_clock.gd")
	if not script:
		return
	var hud := CanvasLayer.new()
	hud.name = "HUD"
	hud.layer = 10
	hud.set_script(script)
	add_child(hud)


func _spawn_overlay() -> void:
	var s: Script = load("res://scripts/ui/time_warp_overlay.gd")
	if s:
		var o := CanvasLayer.new()
		o.set_script(s)
		o.layer = -1
		add_child(o)


func _spawn_killzone() -> void:
	var kz := Area2D.new()
	kz.name = "KillZone"
	kz.collision_layer = 1
	kz.collision_mask = 2
	kz.position = Vector2(LEVEL_WIDTH / 2.0, FALL_Y)
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(LEVEL_WIDTH, 200)
	shape.shape = rect
	kz.add_child(shape)
	kz.body_entered.connect(_on_fall)
	add_child(kz)



func _spawn_hints() -> void:
	_create_hint("按住 Shift 冲刺 → 闸门加速周期 → 乘隙穿过", Vector2(380, 480))
	_create_hint("冲刺让平台快点过来 ←", Vector2(750, 470))

func _create_hint(text: String, pos: Vector2) -> void:
	var label := Label.new()
	label.text = text
	label.position = pos
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", Color(1, 0.8, 0.3, 0.8))
	add_child(label)
func _cache_resettables() -> void:
	for child in get_children():
		if child is Node and child.has_method("reset_state"):
			_resettables.append(child as Node)

# ============================================================
# 信号
# ============================================================

func _on_fall(body: Node2D) -> void:
	if _level_done:
		return
	if body == _player:
		_reset_level()


func _on_puzzle_reset() -> void:
	_reset_level()


func _on_level_completed(_name: String) -> void:
	if _level_done:
		return
	_level_done = true
	if _player and _player.has_method("set_frozen"):
		_player.set_frozen(true)

	var msg := Label.new()
	msg.text = "[ 关卡完成: 时间膨胀 ]\n冲刺即时间，静止即永恒"
	msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	msg.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	msg.add_theme_font_size_override("font_size", 36)
	msg.add_theme_color_override("font_color", Color.GOLD)
	msg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var layer := CanvasLayer.new()
	layer.layer = 100
	layer.add_child(msg)
	add_child(layer)


# ============================================================
# 重置
# ============================================================

func _reset_level() -> void:
	TimeManager.reset()
	if _player:
		_player.velocity = Vector2.ZERO
		_player.global_position = PLAYER_SPAWN
	for node in _resettables:
		if node.has_method("reset_state"):
			node.reset_state()
