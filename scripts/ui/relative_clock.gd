extends CanvasLayer
## 相对时钟 HUD — 显示场景时间流速倍数与玩家当前速度百分比

const Player = preload("res://scripts/player/player.gd")
const SpeedTimeCoupling = preload("res://scripts/mechanics/speed_time_coupling.gd")


var _scale_label: Label
var _speed_label: Label
var _toast_label: Label
var _toast_timer: Timer


func _ready() -> void:
	_scale_label = get_node("VBox/ScaleLabel") as Label
	_speed_label = get_node("VBox/SpeedLabel") as Label
	_toast_label = get_node("ToastLabel") as Label
	_toast_timer = get_node("ToastTimer") as Timer

	TimeManager.scene_time_scale_changed.connect(_on_scale_changed)
	CodexManager.entry_unlocked.connect(_on_entry_unlocked)
	_update_display(TimeManager.scene_time_scale)
	_toast_label.hide()


func _process(_delta: float) -> void:
	var player := get_tree().get_first_node_in_group("player") as Player
	var speed: float = player.velocity.length() if player else 0.0
	var percent: float = (speed / SpeedTimeCoupling.LIGHT_SPEED) * 100.0
	_speed_label.text = "速度: %.1f%% c" % percent

	if SpeedTimeCoupling.get_redline_ratio(speed) > 0.5:
		_speed_label.add_theme_color_override("font_color", Color.RED)
	else:
		_speed_label.remove_theme_color_override("font_color")


func _on_scale_changed(new_scale: float) -> void:
	_update_display(new_scale)


func _on_entry_unlocked(_entry_id: String, entry_data: Dictionary) -> void:
	_show_toast("图鉴解锁: " + entry_data.get("name", _entry_id))


func _update_display(scale: float) -> void:
	_scale_label.text = "场景时间: x%.2f" % scale
	if scale > 2.0:
		_scale_label.add_theme_color_override("font_color", Color.CORNFLOWER_BLUE)
	elif scale > 1.05:
		_scale_label.add_theme_color_override("font_color", Color.CYAN)
	else:
		_scale_label.remove_theme_color_override("font_color")


func _show_toast(msg: String) -> void:
	_toast_label.text = msg
	_toast_label.show()
	_toast_timer.start()


func _on_toast_timer_timeout() -> void:
	_toast_label.hide()
