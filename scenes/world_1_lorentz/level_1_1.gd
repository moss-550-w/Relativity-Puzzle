extends Node2D
## M1-1 关卡控制器
## 教学谜题：玩家 sprint 提速 → 场景时间加速 → 移动平台快进到合适位置
## 加载 Player、HUD、TimeWarpOverlay

const _Player = preload("res://scripts/player/player.gd")


func _ready() -> void:
	_spawn_player()
	_spawn_hud()
	_spawn_overlay()


func _spawn_player() -> void:
	var scene: PackedScene = load("res://scenes/player.tscn")
	if not scene:
		push_error("无法加载 player.tscn")
		return
	var player: Node2D = scene.instantiate()
	player.global_position = Vector2(100, 500)
	add_child(player)


func _spawn_hud() -> void:
	# 程序化构建 HUD，避免 tscn 加载的节点查找问题
	var script: Script = load("res://scripts/ui/relative_clock.gd")
	if not script:
		push_error("无法加载 relative_clock.gd")
		return

	var hud := CanvasLayer.new()
	hud.name = "HUD"
	hud.layer = 10
	hud.set_script(script)

	# --- VBox ---
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

	# --- Toast ---
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

	# 连接信号
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
	overlay.layer = -1  # 渲染在所有内容下方/背景
	add_child(overlay)
