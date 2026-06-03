extends Node
## AudioManager — 程序化音频合成器
## 使用 AudioStreamGenerator 实时生成音效
## 音高随 scene_time_scale 变化，红线接近时叠加谐波警告


const SAMPLE_RATE := 44100
const BUFFER_FRAMES := 256

# ---- 内部 ----

var _player: AudioStreamPlayer = null
var _playback: AudioStreamGeneratorPlayback = null
var _phase: float = 0.0
var _sfx_active: Array[Dictionary] = []


func _ready() -> void:
	_init_generator()


func _process(_delta: float) -> void:
	_fill_buffer()


# ============================================================
# 公开方法
# ============================================================

## 播放一次性音效
## sfx_id: "redline_bounce" | "fragment_collect" | "jump"
func play_sfx(sfx_id: String) -> void:
	match sfx_id:
		"redline_bounce":
			_sfx_active.append(_make_sfx_bounce())
		"fragment_collect":
			_sfx_active.append(_make_sfx_collect())
		"jump":
			_sfx_active.append(_make_sfx_jump())
		_:
			pass


# ============================================================
# 生成器初始化
# ============================================================

func _init_generator() -> void:
	var gen := AudioStreamGenerator.new()
	gen.mix_rate = SAMPLE_RATE
	gen.buffer_length = float(BUFFER_FRAMES * 2) / SAMPLE_RATE

	_player = AudioStreamPlayer.new()
	_player.stream = gen
	_player.bus = &"Master"
	add_child(_player)
	_player.play()

	_playback = _player.get_stream_playback()


# ============================================================
# 音频帧填充（每帧调用）
# ============================================================

func _fill_buffer() -> void:
	var available := _playback.get_frames_available()
	while available > 0:
		var n := mini(available, BUFFER_FRAMES)
		var buf := _generate_frames(n)
		_playback.push_buffer(buf)
		available -= n


func _generate_frames(count: int) -> PackedVector2Array:
	var buf := PackedVector2Array()
	buf.resize(count)

	var ts: float = TimeManager.scene_time_scale
	var rr: float = TimeManager.redline_ratio

	# 基频随场景时间缩放变化（80 Hz → 最高 800 Hz）
	var base_freq := clampf(80.0 * ts, 80.0, 800.0)
	var base_inc := base_freq / SAMPLE_RATE

	# 红线警告：叠加高频谐波
	var warn_freq := clampf(240.0 * ts, 240.0, 2400.0)
	var warn_inc := warn_freq / SAMPLE_RATE
	var warn_phase: float = fmod(_phase * 3.0, 1.0)

	# 处理一次性音效（提前结束的从列表移除）
	var expired: Array[int] = []

	for si in _sfx_active.size():
		var sfx: Dictionary = _sfx_active[si]
		if sfx["frame"] >= sfx["total"]:
			expired.append(si)

	# 从后往前删除过期 SFX
	for i in range(expired.size() - 1, -1, -1):
		_sfx_active.remove_at(expired[i])

	for i in count:
		# --- 环境底噪 ---
		var sample := sin(_phase * TAU) * 0.12

		# --- 红线警告谐波 ---
		if rr > 0.3:
			var w := sin(warn_phase * TAU) * (rr * 0.10)
			# 再加一个更尖锐的泛音（rr > 0.7 时出现）
			if rr > 0.7:
				w += sin(warn_phase * TAU * 2.3) * ((rr - 0.7) * 0.15)
			sample += w

		# --- 一次性音效叠加 ---
		for si in _sfx_active.size():
			var sfx: Dictionary = _sfx_active[si]
			var t: float = float(sfx["frame"]) / SAMPLE_RATE
			var duration: float = float(sfx["total"]) / SAMPLE_RATE
			var env := _sfx_envelope(t, duration, sfx.get("attack", 0.05), sfx.get("release", 0.1))
				var freq: float = 0.0
				if sfx["freq_func"] is Callable:
					freq = sfx["freq_func"].call(t)
				else:
					freq = sfx["freq"]
			var sfx_phase_val: float = sfx["phase"]
			sample += sin(sfx_phase_val * TAU) * env * sfx["amp"]
			sfx["phase"] = fmod(sfx_phase_val + freq / SAMPLE_RATE, 1.0)
			sfx["frame"] = sfx["frame"] + 1

		sample = clampf(sample, -1.0, 1.0)
		buf[i] = Vector2(sample, sample)

		_phase = fmod(_phase + base_inc, 1.0)
		warn_phase = fmod(warn_phase + warn_inc, 1.0)

	return buf


# ============================================================
# SFX 工厂
# ============================================================

func _make_sfx_bounce() -> Dictionary:
	# 红线弹回：频率从 300 Hz 扫到 60 Hz，持续 0.45 秒
	var total := int(SAMPLE_RATE * 0.45)
	return {
		"frame": 0,
		"total": total,
		"phase": 0.0,
		"amp": 0.25,
		"attack": 0.01,
		"release": 0.2,
		"freq_func": func(t: float) -> float:
			var progress := t / (float(total) / SAMPLE_RATE)
			return lerpf(300.0, 60.0, clampf(progress, 0.0, 1.0)),
	}


func _make_sfx_collect() -> Dictionary:
	# 碎片收集：频率从 440 Hz 升到 880 Hz，持续 0.35 秒
	var total := int(SAMPLE_RATE * 0.35)
	return {
		"frame": 0,
		"total": total,
		"phase": 0.0,
		"amp": 0.2,
		"attack": 0.02,
		"release": 0.15,
		"freq_func": func(t: float) -> float:
			var progress := t / (float(total) / SAMPLE_RATE)
			return lerpf(440.0, 880.0, clampf(progress, 0.0, 1.0)),
	}


func _make_sfx_jump() -> Dictionary:
	# 跳跃：短促上扬 220→330 Hz，持续 0.08 秒
	var total := int(SAMPLE_RATE * 0.08)
	return {
		"frame": 0,
		"total": total,
		"phase": 0.0,
		"amp": 0.12,
		"attack": 0.005,
		"release": 0.04,
		"freq_func": func(t: float) -> float:
			var progress := t / (float(total) / SAMPLE_RATE)
			return lerpf(220.0, 330.0, clampf(progress, 0.0, 1.0)),
	}


# ============================================================
# 工具
# ============================================================

## 简易 ADSR 包络（Attack → Sustain → Release）
func _sfx_envelope(t: float, duration: float, attack: float, release: float) -> float:
	if t < attack:
		return t / attack
	elif t > duration - release:
		return (duration - t) / release
	return 1.0
