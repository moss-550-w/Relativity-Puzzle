extends Node
## AudioManager — 程序化音频合成器
## 使用 AudioStreamGenerator 实时生成所有音效 & 环境音
## 音高随 scene_time_scale、熵值变化
## 新增：UI 反馈、虫洞/裂隙/熵崩解专属音效、World 4 低频嗡鸣


const SAMPLE_RATE := 44100
const BUFFER_FRAMES := 256

# ---- 内部 ----

var _player: AudioStreamPlayer = null
var _playback: AudioStreamGeneratorPlayback = null
var _phase: float = 0.0
var _sfx_active: Array[Dictionary] = []
var _paused: bool = false
## 环境嗡鸣相位（独立于 SFX）
var _drone_phase: float = 0.0


func _ready() -> void:
	_init_generator()


func _process(_delta: float) -> void:
	if _paused and _sfx_active.is_empty():
		return
	_fill_buffer()


# ============================================================
# 公开方法
# ============================================================

## 播放一次性音效
## sfx_id 支持:
##   "redline_bounce" | "fragment_collect" | "jump"
##   "ui_tick" | "ui_confirm" | "wormhole_stabilize"
##   "platform_crumble" | "fissure_warning" | "photon_tick"
##   "order_collect"
func play_sfx(sfx_id: String) -> void:
	match sfx_id:
		"redline_bounce":
			_sfx_active.append(_make_sfx_redline_bounce())
		"fragment_collect":
			_sfx_active.append(_make_sfx_fragment_collect())
		"jump":
			_sfx_active.append(_make_sfx_jump())
		"ui_tick":
			_sfx_active.append(_make_sfx_ui_tick())
		"ui_confirm":
			_sfx_active.append(_make_sfx_ui_confirm())
		"wormhole_stabilize":
			_sfx_active.append(_make_sfx_wormhole_stabilize())
		"platform_crumble":
			_sfx_active.append(_make_sfx_platform_crumble())
		"fissure_warning":
			_sfx_active.append(_make_sfx_fissure_warning())
		"photon_tick":
			_sfx_active.append(_make_sfx_photon_tick())
		"order_collect":
			_sfx_active.append(_make_sfx_order_collect())
		_:
			push_warning("AudioManager: 未知音效 '%s'" % sfx_id)


func pause_audio(p: bool) -> void:
	_paused = p


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
	var entropy: float = EntropySystem.global_entropy

	# 基频随场景时间缩放变化（80 Hz → 最高 800 Hz）
	var base_freq := clampf(80.0 * ts, 80.0, 800.0)
	var base_inc := base_freq / SAMPLE_RATE

	# 红线警告：叠加高频谐波
	var warn_freq := clampf(240.0 * ts, 240.0, 2400.0)
	var warn_inc := warn_freq / SAMPLE_RATE
	var warn_phase: float = fmod(_phase * 3.0, 1.0)

	# World 4 底层嗡鸣（极低频，纯正弦）
	var drone_freq := 36.0
	var drone_inc := drone_freq / SAMPLE_RATE

	# 熵噪音种子
	var noise_seed: float = fmod(_phase * 997.3, 1.0)

	# 处理一次性音效过期
	var expired: Array[int] = []
	for si in _sfx_active.size():
		var sfx: Dictionary = _sfx_active[si]
		if sfx["frame"] >= sfx["total"]:
			expired.append(si)
	for i in range(expired.size() - 1, -1, -1):
		_sfx_active.remove_at(expired[i])

	for i in count:
		var sample: float = 0.0

		# --- 环境底噪 ---
		# 正常时：纯净正弦；熵高时：加入粉噪成分
		var env_clean := sin(_phase * TAU) * 0.12
		var env_noise := _pseudo_random(noise_seed + float(i) * 0.137) * entropy * 0.10
		sample += env_clean * (1.0 - entropy) + env_noise

		# --- World 4 底层嗡鸣（仅在熵暂停且无速度时明显） ---
		if EntropySystem.global_entropy < 0.05 and ts < 1.05:
			var drone_amp: float = 0.08 + sin(_drone_phase * TAU * 0.23) * 0.03
			sample += sin(_drone_phase * TAU) * drone_amp
			# 第二个泛音增加厚重感
			sample += sin(_drone_phase * TAU * 0.5) * drone_amp * 0.6
			_drone_phase = fmod(_drone_phase + drone_inc, 1.0)

		# --- 红线警告谐波 ---
		if rr > 0.3:
			var w := sin(warn_phase * TAU) * (rr * 0.10)
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
			if sfx.get("freq_func") is Callable:
				freq = sfx["freq_func"].call(t)
			else:
				freq = sfx.get("freq", 0.0)
			var sfx_phase_val: float = sfx["phase"]
			var wave: float
			if sfx.get("wave_type", "sine") == "noise":
				wave = _pseudo_random(sfx_phase_val + float(sfx["frame"]) * 0.01) * 2.0 - 1.0
			else:
				wave = sin(sfx_phase_val * TAU)
			sample += wave * env * sfx["amp"]
			sfx["phase"] = fmod(sfx_phase_val + freq / SAMPLE_RATE, 1.0)
			sfx["frame"] = sfx["frame"] + 1

		# 最终钳制 + 软限幅防削波
		sample = clampf(sample, -1.0, 1.0)
		# 当多个 SFX 同时激活时轻微压缩
		if _sfx_active.size() > 3:
			sample *= 0.85

		buf[i] = Vector2(sample, sample)

		_phase = fmod(_phase + base_inc, 1.0)
		warn_phase = fmod(warn_phase + warn_inc, 1.0)
		noise_seed = fmod(noise_seed * 1.037 + 0.003, 1.0)

	return buf


# ============================================================
# SFX 工厂 — 原有
# ============================================================

func _make_sfx_redline_bounce() -> Dictionary:
	var total := int(SAMPLE_RATE * 0.45)
	return {
		"frame": 0, "total": total, "phase": 0.0, "amp": 0.25,
		"attack": 0.01, "release": 0.2, "wave_type": "sine",
		"freq_func": func(t: float) -> float:
			var progress := t / (float(total) / SAMPLE_RATE)
			return lerpf(300.0, 60.0, clampf(progress, 0.0, 1.0)),
	}


func _make_sfx_fragment_collect() -> Dictionary:
	var total := int(SAMPLE_RATE * 0.35)
	return {
		"frame": 0, "total": total, "phase": 0.0, "amp": 0.2,
		"attack": 0.02, "release": 0.15, "wave_type": "sine",
		"freq_func": func(t: float) -> float:
			var progress := t / (float(total) / SAMPLE_RATE)
			return lerpf(440.0, 880.0, clampf(progress, 0.0, 1.0)),
	}


func _make_sfx_jump() -> Dictionary:
	var total := int(SAMPLE_RATE * 0.08)
	return {
		"frame": 0, "total": total, "phase": 0.0, "amp": 0.12,
		"attack": 0.005, "release": 0.04, "wave_type": "sine",
		"freq_func": func(t: float) -> float:
			var progress := t / (float(total) / SAMPLE_RATE)
			return lerpf(220.0, 330.0, clampf(progress, 0.0, 1.0)),
	}


# ============================================================
# SFX 工厂 — 新增 UI 音效
# ============================================================

func _make_sfx_ui_tick() -> Dictionary:
	# 菜单悬停/切换：极短高音叮咚 (800 Hz, 0.04s)
	var total := int(SAMPLE_RATE * 0.04)
	return {
		"frame": 0, "total": total, "phase": 0.0, "amp": 0.06,
		"attack": 0.002, "release": 0.02, "wave_type": "sine",
		"freq": 800.0,
	}


func _make_sfx_ui_confirm() -> Dictionary:
	# 确认/选择：双音上扫 (440→660 Hz, 0.15s)
	var total := int(SAMPLE_RATE * 0.15)
	return {
		"frame": 0, "total": total, "phase": 0.0, "amp": 0.10,
		"attack": 0.01, "release": 0.08, "wave_type": "sine",
		"freq_func": func(t: float) -> float:
			var progress := t / (float(total) / SAMPLE_RATE)
			return lerpf(440.0, 660.0, clampf(progress, 0.0, 1.0)),
	}


# ============================================================
# SFX 工厂 — 新增游戏机制音效
# ============================================================

func _make_sfx_wormhole_stabilize() -> Dictionary:
	# 虫洞稳定化：低频嗡鸣上升 (60→180 Hz, 0.5s) + 谐波
	var total := int(SAMPLE_RATE * 0.5)
	return {
		"frame": 0, "total": total, "phase": 0.0, "amp": 0.18,
		"attack": 0.03, "release": 0.25, "wave_type": "sine",
		"freq_func": func(t: float) -> float:
			var progress := t / (float(total) / SAMPLE_RATE)
			return lerpf(60.0, 180.0, clampf(progress, 0.0, 1.0)),
	}


func _make_sfx_platform_crumble() -> Dictionary:
	# 熵增平台崩解：噪音爆发 + 频率下降 (200→40 Hz, 0.4s)
	var total := int(SAMPLE_RATE * 0.4)
	return {
		"frame": 0, "total": total, "phase": 0.0, "amp": 0.15,
		"attack": 0.005, "release": 0.25, "wave_type": "noise",
		"freq_func": func(t: float) -> float:
			var progress := t / (float(total) / SAMPLE_RATE)
			return lerpf(200.0, 40.0, clampf(progress, 0.0, 1.0)),
	}


func _make_sfx_fissure_warning() -> Dictionary:
	# 量子裂隙预兆：闪烁上升音 (300→600 Hz, 0.5s 脉冲)
	var total := int(SAMPLE_RATE * 0.5)
	return {
		"frame": 0, "total": total, "phase": 0.0, "amp": 0.12,
		"attack": 0.05, "release": 0.3, "wave_type": "sine",
		"freq_func": func(t: float) -> float:
			var progress := t / (float(total) / SAMPLE_RATE)
			var pulse := sin(progress * TAU * 4.0) * 0.5 + 0.5
			return lerpf(300.0, 600.0, clampf(progress, 0.0, 1.0)) * (0.6 + pulse * 0.4),
	}


func _make_sfx_photon_tick() -> Dictionary:
	# 光钟滴答：极短清脆敲击 (1200 Hz, 0.03s)
	var total := int(SAMPLE_RATE * 0.03)
	return {
		"frame": 0, "total": total, "phase": 0.0, "amp": 0.08,
		"attack": 0.001, "release": 0.015, "wave_type": "sine",
		"freq": 1200.0,
	}


func _make_sfx_order_collect() -> Dictionary:
	# 秩序能量收集：三音上琶音 (523→659→784 Hz, 0.35s)
	var total := int(SAMPLE_RATE * 0.35)
	return {
		"frame": 0, "total": total, "phase": 0.0, "amp": 0.14,
		"attack": 0.02, "release": 0.2, "wave_type": "sine",
		"freq_func": func(t: float) -> float:
			var progress := t / (float(total) / SAMPLE_RATE)
			var p := clampf(progress, 0.0, 1.0)
			if p < 0.33:
				return lerpf(523.0, 659.0, p / 0.33)
			elif p < 0.66:
				return lerpf(659.0, 784.0, (p - 0.33) / 0.33)
			else:
				return 784.0,
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


## 简易伪随机数（确定性，用于噪音合成）
func _pseudo_random(seed: float) -> float:
	var s := seed * 43758.5453
	return s - floor(s)
