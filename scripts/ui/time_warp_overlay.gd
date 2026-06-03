extends CanvasLayer
## 全屏时间膨胀色彩偏移 Shader 控制器
## 挂载到独立 CanvasLayer，包含 ColorRect + time_warp shader


var _material: ShaderMaterial = null
var _color_rect: ColorRect = null


func _ready() -> void:
	_load_shader()
	_color_rect = ColorRect.new()
	_color_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_color_rect.material = _material
	add_child(_color_rect)


func _process(_delta: float) -> void:
	if _material:
		_material.set_shader_parameter("time_dilation_factor", TimeManager.scene_time_scale)


func _load_shader() -> void:
	var shader: Shader = load("res://assets/shaders/time_warp.gdshader")
	if shader:
		_material = ShaderMaterial.new()
		_material.shader = shader
