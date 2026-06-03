extends Node2D
## 关卡基类 — 承载所有世界1关卡的共用逻辑
## 子类通过覆写 _get_hints() / 导出变量定制内容
##
## 共用：spawn player/hud/overlay/killzone、坠崖与手动重置、完成演出


const _Player = preload("res://scripts/player/player.gd")

@export_category("Level Config")
## 玩家出生点
@export var player_spawn: Vector2 = Vector2(100, 520)
## 坠崖线 y 坐标
@export var fall_y: float = 800.0
## 坠崖检测区中心 x 与宽度
@export var level_center_x: float = 1400.0
@export var level_width: float = 2800.0
## 完成文案
@export_multiline var complete_text: String = "[ 关卡完成 ]"
## 下一关场景路径（留空则停在完成画面）
@export_file("*.tscn") var next_level_path: String = ""

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
	_on_level_ready()


## 子类钩子：所有基础设施就绪后调用
func _on_level_ready() -> void:
	pass


## 子类覆写：返回提示列表 [{text, pos}]
func _get_hints() -> Array:
	return []


# ============================================================
# 生成
# ============================================================

func _spawn_player() -> void:
	var scene: PackedScene = load("res://scenes/player.tscn")
	if not scene:
		return
	_player = scene.instantiate()
	_player.global_position = player_spawn
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
	kz.position = Vector2(level_center_x, fall_y)
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(level_width, 200)
	shape.shape = rect
	kz.add_child(shape)
	kz.body_entered.connect(_on_fall)
	add_child(kz)


func _spawn_hints() -> void:
	for hint in _get_hints():
		_create_hint(hint.get("text", ""), hint.get("pos", Vector2.ZERO))


func _create_hint(text: String, pos: Vector2) -> void:
	var label := Label.new()
	label.text = text
	label.position = pos
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", Color(1, 0.8, 0.3, 0.85))
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
	msg.text = complete_text
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
		_player.global_position = player_spawn
	for node in _resettables:
		if node.has_method("reset_state"):
			node.reset_state()
