extends Area2D
## 光锥边界检测（M1-3 机制）
## 挂载到 Area2D 节点，定义未来光锥安全区域
## 玩家超出区域 → 画面灰白冻结 → 3 秒后重置回锥内安全位置
## 自动绘制虚线边界可视化（可按需关闭）


const Player = preload("res://scripts/player/player.gd")

## 超出光锥后冻结时间（秒）
const FREEZE_DURATION: float = 3.0

# ---- 导出 ----

@export_category("Visual")
## 是否显示虚线边界
@export var show_boundary: bool = true
## 虚线颜色
@export var boundary_color: Color = Color(0.3, 0.9, 1.0, 0.55)
## 虚线宽度（像素）
@export var dash_length: float = 24.0
## 虚线间隔（像素）
@export var gap_length: float = 16.0
## 线宽（像素）
@export var line_width: float = 2.0

# ---- 内部 ----

var _frozen: bool = false
var _timer: float = 0.0
var _player: Player = null
var _reset_position: Vector2 = Vector2.ZERO


func _ready() -> void:
	body_exited.connect(_on_body_exited)
	body_entered.connect(_on_body_entered)
	if show_boundary:
		_create_boundary_visual()


# ============================================================
# 虚线边界可视化
# ============================================================

func _create_boundary_visual() -> void:
	var vis := Node2D.new()
	vis.name = "BoundaryVisual"
	vis.z_index = 10

	var shape_node := get_node_or_null("CollisionShape2D")
	if not shape_node or not shape_node.shape is RectangleShape2D:
		add_child(vis)
		return

	var rect: RectangleShape2D = shape_node.shape as RectangleShape2D
	var half: Vector2 = rect.size / 2.0
	var offset: Vector2 = shape_node.position

	var tl := offset - half
	var br := offset + half

	_draw_dashed_edge(vis, Vector2(tl.x, tl.y), Vector2(br.x, tl.y))  # top
	_draw_dashed_edge(vis, Vector2(br.x, tl.y), Vector2(br.x, br.y))  # right
	_draw_dashed_edge(vis, Vector2(br.x, br.y), Vector2(tl.x, br.y))  # bottom
	_draw_dashed_edge(vis, Vector2(tl.x, br.y), Vector2(tl.x, tl.y))  # left

	add_child(vis)


func _draw_dashed_edge(parent: Node2D, from: Vector2, to: Vector2) -> void:
	var dir := (to - from).normalized()
	var length := from.distance_to(to)
	var segment := dash_length + gap_length
	if segment <= 0.0:
		return

	var pos: float = 0.0
	while pos < length:
		var seg_end: float = minf(pos + dash_length, length)
		# 每个虚线段 = 一个 Line2D 节点（Node2D 子类，渲染正确）
		var line := Line2D.new()
		line.width = line_width
		line.default_color = boundary_color
		line.add_point(from + dir * pos)
		line.add_point(from + dir * seg_end)
		parent.add_child(line)
		pos += segment


# ============================================================
# 冻结 / 重置逻辑
# ============================================================

func _on_body_exited(body: Node2D) -> void:
	if _frozen or not body is Player:
		return
	_player = body as Player
	_reset_position = _player.get_last_safe_position()
	_frozen = true
	_timer = FREEZE_DURATION
	_player.set_frozen(true)


func _on_body_entered(body: Node2D) -> void:
	if body is Player and _frozen and body == _player:
		_reset_freeze()


func _process(delta: float) -> void:
	if not _frozen:
		return
	_timer -= delta
	if _timer <= 0.0:
		_reset_freeze()


func _reset_freeze() -> void:
	_frozen = false
	_timer = 0.0
	if _player:
		_player.set_frozen(false)
		_player.global_position = _reset_position
		_player = null


## 谜题重置时由 level_base 调用，清理冻结状态
func reset_state() -> void:
	if _frozen:
		if _player:
			_player.set_frozen(false)
		_frozen = false
		_timer = 0.0
		_player = null
