extends Node2D
## WorldBackdrop — 关卡底层背景（CanvasLayer 挂载）
## 根据 GameState.current_world 绘制：纵向渐变 + 统一星空 + 坐标参考网格
## 在 level_base._spawn_background() 中实例化于 time_warp 覆盖层之下


const GRID_SIZE: float = 64.0
const GRID_COLS: int = 22   # 覆盖 ~1400px 宽
const GRID_ROWS: int = 14   # 覆盖 ~896px 高

var _stars: Array = []
var _world: int = 0
var _t: float = 0.0


func _ready() -> void:
	_world = GameState.current_world
	_stars = Palette.make_stars(50, 1280.0, 720.0)
	set_process(true)


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, Vector2(1280, 720)),
		Palette.world_bg_top(_world), true)

	# 纵向渐变（下半屏向 bg_bottom 过渡）
	var top: Color = Palette.world_bg_top(_world)
	var bot: Color = Palette.world_bg_bottom(_world)
	for i in range(1, 361):
		var t_param: float = i / 360.0
		var y: float = i * 2.0  # 0..720
		draw_line(Vector2(0, y), Vector2(1280, y), top.lerp(bot, t_param), 1.0)

	Palette.draw_starfield(self, _stars)
	_draw_grid()


# ============================================================
# 坐标参考网格
# ============================================================

func _draw_grid() -> void:
	var grid_col: Color = Palette.world_grid(_world)
	match _world:
		1:
			_draw_grid_flat(grid_col)
		2:
			_draw_grid_curved(grid_col)
		3:
			_draw_grid_fractured(grid_col)
		4:
			_draw_grid_decaying(grid_col)
		_:
			_draw_grid_flat(grid_col)


## W1 — 平直正方网格（惯性参考系坐标系）
func _draw_grid_flat(col: Color) -> void:
	for xi in GRID_COLS:
		var x: float = xi * GRID_SIZE - 64.0
		draw_line(Vector2(x, 0), Vector2(x, 720), col, 0.8)
	for yi in GRID_ROWS:
		var y: float = yi * GRID_SIZE - 48.0
		draw_line(Vector2(0, y), Vector2(1280, y), col, 0.8)


## W2 — 弯曲时空网格（向屏幕中心下凹的弧形，直观表现时空弯曲）
func _draw_grid_curved(col: Color) -> void:
	var center: Vector2 = Vector2(640, 360)
	for xi in GRID_COLS:
		var x: float = xi * GRID_SIZE - 64.0
		for yi in GRID_ROWS - 1:
			var y0: float = yi * GRID_SIZE - 48.0
			var y1: float = (yi + 1) * GRID_SIZE - 48.0
			var dx: float = x - center.x
			var dist: float = absf(dx) / 640.0
			var warp: float = dist * dist * 28.0  # 越远越弯（二阶）
			draw_line(Vector2(x, y0 + warp), Vector2(x, y1 + warp), col, 0.8)
	for yi in GRID_ROWS:
		var y: float = yi * GRID_SIZE - 48.0
		var prev: Vector2 = Vector2.ZERO
		for xi in GRID_COLS:
			var x: float = xi * GRID_SIZE - 64.0
			var dx: float = x - center.x
			var dist: float = absf(dx) / 640.0
			var warp: float = dist * dist * 28.0
			var pt: Vector2 = Vector2(x, y + warp * 0.6)
			if xi > 0:
				draw_line(prev, pt, col, 0.8)
			prev = pt


## W3 — 破碎/错断不规则网格段 + 轻微闪烁（量子真空涨落）
func _draw_grid_fractured(col: Color) -> void:
	var flicker: float = 0.8 + 0.2 * sin(_t * 3.7 + 1.1)
	var frag_col: Color = Color(col.r, col.g, col.b, col.a * flicker)
	for xi in GRID_COLS:
		var x: float = xi * GRID_SIZE - 64.0
		var seg_start: float = -48.0
		while seg_start < 672.0:
			var seg_len: float = GRID_SIZE * randf_range(0.6, 2.5)
			var seg_end: float = minf(seg_start + seg_len, 672.0)
			var x_jitter: float = randf_range(-2.5, 2.5)  # 轻微横向错断
			draw_line(Vector2(x + x_jitter, seg_start), Vector2(x + randf_range(-2.0, 2.0), seg_end), frag_col, 0.8)
			seg_start = seg_end + GRID_SIZE * randf_range(0.3, 1.2)  # 缺口
	for yi in GRID_ROWS:
		var y: float = yi * GRID_SIZE - 48.0
		var seg_start: float = -64.0
		while seg_start < 1216.0:
			var seg_len: float = GRID_SIZE * randf_range(0.6, 2.5)
			var seg_end: float = minf(seg_start + seg_len, 1216.0)
			var y_jitter: float = randf_range(-2.5, 2.5)
			draw_line(Vector2(seg_start, y + y_jitter), Vector2(seg_end, y + randf_range(-2.0, 2.0)), frag_col, 0.8)
			seg_start = seg_end + GRID_SIZE * randf_range(0.3, 1.2)


## W4 — 暖色网格 + 随机缺口/淡出（熵增衰败）
func _draw_grid_decaying(col: Color) -> void:
	# 随机种子固定（每帧稳定），缺口位置基于 xi/yi 的伪随机
	for xi in GRID_COLS:
		var x: float = xi * GRID_SIZE - 64.0
		for yi in GRID_ROWS - 1:
			var y0: float = yi * GRID_SIZE - 48.0
			var y1: float = (yi + 1) * GRID_SIZE - 48.0
			if _decay_gap(xi, yi):
				continue
			draw_line(Vector2(x, y0), Vector2(x, y1), col, 0.8)
	for yi in GRID_ROWS:
		var y: float = yi * GRID_SIZE - 48.0
		for xi in GRID_COLS - 1:
			var x0: float = xi * GRID_SIZE - 64.0
			var x1: float = (xi + 1) * GRID_SIZE - 64.0
			if _decay_gap(xi, yi):
				continue
			draw_line(Vector2(x0, y), Vector2(x1, y), col, 0.8)


## 伪随机决定该格是否缺口（基于行列号做确定性哈希）
func _decay_gap(xi: int, yi: int) -> bool:
	var h: int = (xi * 31 + yi * 97) % 100
	return h < 18  # ~18% 的网格线段缺失（熵增崩解）
