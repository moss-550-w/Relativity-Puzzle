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
var _pause_menu: Control = null


func _ready() -> void:
	_spawn_background()
	_spawn_player()
	_spawn_hud()
	_spawn_hints()
	_spawn_overlay()
	_spawn_killzone()
	_cache_resettables()
	GameState.puzzle_reset.connect(_on_puzzle_reset)
	GameState.level_completed.connect(_on_level_completed)
	_on_level_ready()
	TransitionLayer.fade_in()


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


func _spawn_background() -> void:
	var s: Script = load("res://scripts/ui/world_backdrop.gd")
	if s:
		var bg_layer := CanvasLayer.new()
		bg_layer.layer = -3  # 底色，在 time_warp(-1) 和关卡(0)之下；W4 昼夜(-2)叠加其上
		bg_layer.name = "WorldBackdropLayer"
		var bg := Node2D.new()
		bg.name = "WorldBackdrop"
		bg.set_script(s)
		bg_layer.add_child(bg)
		add_child(bg_layer)


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


var _complete_layer: CanvasLayer = null


func _on_level_completed(_name: String) -> void:
	if _level_done:
		return
	_level_done = true
	if _player and _player.has_method("set_frozen"):
		_player.set_frozen(true)

	var next_level: Dictionary = GameState.get_next_level(GameState.current_world, GameState.current_level)

	_complete_layer = CanvasLayer.new()
	_complete_layer.name = "CompleteLayer"
	_complete_layer.layer = 100
	_complete_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_complete_layer)

	# 半透明遮罩
	var overlay := ColorRect.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0.0, 0.0, 0.0, 0.6)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_complete_layer.add_child(overlay)

	# 面板
	var panel := Panel.new()
	panel.name = "CompletePanel"
	panel.position = Vector2(340, 160)
	panel.size = Vector2(600, 400)
	var psb := StyleBoxFlat.new()
	psb.bg_color = Color(0.03, 0.06, 0.14, 0.95)
	var accent: Color = Palette.world_accent(GameState.current_world)
	psb.border_color = Color(accent.r, accent.g, accent.b, 0.6)
	psb.set_border_width_all(2)
	psb.border_width_left = 4
	psb.set_corner_radius_all(10)
	psb.shadow_color = Color(accent.r, accent.g, accent.b, 0.25)
	psb.shadow_size = 20
	panel.add_theme_stylebox_override("panel", psb)
	_complete_layer.add_child(panel)

	# 标题
	var title := Label.new()
	title.text = "◆  关卡完成"
	title.position = Vector2(0, 30)
	title.size = Vector2(600, 40)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", Color(accent.r, accent.g, accent.b, 1.0))
	panel.add_child(title)

	# 完成文案
	var msg := Label.new()
	msg.text = complete_text
	msg.position = Vector2(40, 85)
	msg.size = Vector2(520, 40)
	msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	msg.add_theme_font_size_override("font_size", 20)
	msg.add_theme_color_override("font_color", Color.GOLD)
	panel.add_child(msg)

	# 按钮
	var btn_y := 160.0
	var btns: Array = []

	if not next_level.is_empty():
		btns.append({"text": "▶  下一关", "cb": func():
			GameState.current_world = next_level.get("world", GameState.current_world)
			GameState.current_level = next_level["id"]
			TransitionLayer.transition_to(next_level["scene"])
		})

	btns.append({"text": "↺  重新挑战", "cb": func():
		if _complete_layer:
			_complete_layer.queue_free()
			_complete_layer = null
		_level_done = false
		GameState.reset_current_puzzle()
	})

	btns.append({"text": "◆  返回选关", "cb": func():
		TransitionLayer.transition_to("res://scenes/ui/level_select.tscn")
	})

	for i in btns.size():
		var btn := Button.new()
		btn.text = btns[i]["text"]
		btn.position = Vector2(190, btn_y + i * 60)
		btn.size = Vector2(220, 44)
		btn.add_theme_font_size_override("font_size", 17)
		btn.pressed.connect(btns[i]["cb"])
		_pause_style_btn(btn)
		panel.add_child(btn)

	# 底部提示
	var hint := Label.new()
	if not next_level.is_empty():
		hint.text = "按 空格 进入下一关"
	else:
		hint.text = "恭喜！你已完成本世界全部关卡"
	hint.position = Vector2(0, 360)
	hint.size = Vector2(600, 20)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 11)
	hint.add_theme_color_override("font_color", Color(0.3, 0.5, 0.7, 0.5))
	panel.add_child(hint)


func _unhandled_input(event: InputEvent) -> void:
	# ESC 暂停菜单
	if event.is_action_pressed("ui_cancel"):
		_toggle_pause()
		return

	# 完成后按跳跃/空格进入下一关
	if _level_done and event.is_action_pressed("jump"):
		var next_level: Dictionary = GameState.get_next_level(GameState.current_world, GameState.current_level)
		if not next_level.is_empty():
			GameState.current_world = next_level.get("world", GameState.current_world)
			GameState.current_level = next_level["id"]
			TransitionLayer.transition_to(next_level["scene"])


# ============================================================
# 暂停菜单
# ============================================================

var _pause_layer: CanvasLayer = null


func _toggle_pause() -> void:
	if _level_done:
		return
	if not _pause_menu:
		_build_pause_menu()
	var paused: bool = not get_tree().paused
	get_tree().paused = paused
	if _pause_layer:
		_pause_layer.visible = paused


func _build_pause_menu() -> void:
	_pause_layer = CanvasLayer.new()
	_pause_layer.name = "PauseLayer"
	_pause_layer.layer = 200
	_pause_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	_pause_layer.visible = false
	add_child(_pause_layer)

	# 半透明遮罩
	var overlay := ColorRect.new()
	overlay.name = "PauseOverlay"
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0.0, 0.0, 0.0, 0.55)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_pause_layer.add_child(overlay)

	_pause_menu = Control.new()
	_pause_menu.name = "PauseMenu"
	_pause_menu.set_anchors_preset(Control.PRESET_FULL_RECT)
	_pause_menu.mouse_filter = Control.MOUSE_FILTER_STOP
	# 挂载 _input 脚本以响应 ESC（暂停后 _unhandled_input 不再触发）
	_pause_menu.set_script(_make_pause_input_script())
	_pause_layer.add_child(_pause_menu)

	# 面板背景
	var panel := Panel.new()
	panel.name = "PausePanel"
	panel.position = Vector2(440, 180)
	panel.size = Vector2(400, 340)
	var psb := StyleBoxFlat.new()
	psb.bg_color = Color(0.03, 0.06, 0.14, 0.95)
	var paccent: Color = Palette.world_accent(GameState.current_world)
	psb.border_color = Color(paccent.r, paccent.g, paccent.b, 0.5)
	psb.set_border_width_all(2)
	psb.set_corner_radius_all(10)
	psb.shadow_color = Color(paccent.r, paccent.g, paccent.b, 0.3)
	psb.shadow_size = 20
	panel.add_theme_stylebox_override("panel", psb)
	_pause_menu.add_child(panel)

	# 标题
	var title := Label.new()
	title.text = "◆  暂停"
	title.position = Vector2(0, 24)
	title.size = Vector2(400, 36)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", Color(paccent.r, paccent.g, paccent.b, 1.0))
	panel.add_child(title)

	# 按钮
	var btns := [
		{"text": "▶  继续游戏", "cb": func(): _toggle_pause()},
		{"text": "↺  重新开始", "cb": func(): _toggle_pause(); GameState.reset_current_puzzle()},
		{"text": "🏠  返回选关", "cb": func(): _toggle_pause(); TransitionLayer.transition_to("res://scenes/ui/level_select.tscn")},
	]
	for i in btns.size():
		var btn := Button.new()
		btn.text = btns[i]["text"]
		btn.position = Vector2(90, 100 + i * 60)
		btn.size = Vector2(220, 44)
		btn.add_theme_font_size_override("font_size", 17)
		btn.pressed.connect(btns[i]["cb"])
		_pause_style_btn(btn)
		panel.add_child(btn)

	# 底部提示
	var hint := Label.new()
	hint.text = "按 ESC 继续"
	hint.position = Vector2(0, 300)
	hint.size = Vector2(400, 20)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 11)
	hint.add_theme_color_override("font_color", Color(0.3, 0.5, 0.7, 0.5))
	panel.add_child(hint)


func _make_pause_input_script() -> GDScript:
	var s := GDScript.new()
	s.source_code = """extends Control

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_parent().get_parent()._toggle_pause()
		accept_event()
"""
	s.reload()
	return s


func _pause_style_btn(btn: Button) -> void:
	var col := Color(0.2, 0.6, 1.0)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(col.r, col.g, col.b, 0.1)
	sb.border_color = Color(col.r, col.g, col.b, 0.4)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(6)
	btn.add_theme_stylebox_override("normal", sb)

	var sb_h := StyleBoxFlat.new()
	sb_h.bg_color = Color(col.r, col.g, col.b, 0.22)
	sb_h.border_color = Color(col.r, col.g, col.b, 0.75)
	sb_h.set_border_width_all(2)
	sb_h.set_corner_radius_all(6)
	sb_h.shadow_color = Color(col.r, col.g, col.b, 0.35)
	sb_h.shadow_size = 14
	btn.add_theme_stylebox_override("hover", sb_h)

	btn.add_theme_color_override("font_color", Color(col.r, col.g, col.b, 0.8))
	btn.add_theme_color_override("font_hover_color", Color(1, 1, 1, 1))


# ============================================================
# 重置
# ============================================================

func _reset_level() -> void:
	TimeManager.reset()
	# 清理完成面板
	if _complete_layer:
		_complete_layer.queue_free()
		_complete_layer = null
	_level_done = false
	if _player:
		_player.velocity = Vector2.ZERO
		_player.global_position = player_spawn
		if _player.has_method("set_frozen"):
			_player.set_frozen(false)
	for node in _resettables:
		if is_instance_valid(node) and node.has_method("reset_state"):
			node.reset_state()
