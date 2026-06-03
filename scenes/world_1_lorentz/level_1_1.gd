extends Node2D
## M1-1 关卡控制器
## 教学谜题：玩家 sprint 提速 → 场景时间加速 → 移动平台快进到合适位置
## 加载 Player、HUD、TimeWarpOverlay


func _ready() -> void:
	_spawn_player()
	_spawn_hud()
	_spawn_overlay()


func _spawn_player() -> void:
	var scene: PackedScene = load("res://scenes/player.tscn")
	if not scene:
		push_error("无法加载 player.tscn")
		return
	var player: Player = scene.instantiate()
	player.global_position = Vector2(100, 500)
	add_child(player)


func _spawn_hud() -> void:
	var scene: PackedScene = load("res://scenes/ui/hud.tscn")
	if not scene:
		push_error("无法加载 hud.tscn")
		return
	var hud: CanvasLayer = scene.instantiate()
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
