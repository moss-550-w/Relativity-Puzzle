extends Node
## AudioManager — 程序化音频合成器
## 使用 AudioStreamGenerator 实时生成所有音效、背景音乐 & 环境音
## 背景音乐：三层程序化合成（主旋律音序器 + 低音 + 和声 Pad），
##           按 GameState.current_world 自动切换调式与情绪，
##           速度(scene_time_scale)调制节奏、引力(gravity_factor)减速、熵(entropy)崩解失谐
## 音效：UI 反馈、虫洞/裂隙/熵崩解专属音效、World 4 低频嗡鸣


const SAMPLE_RATE := 44100
const BUFFER_FRAMES := 256

const REST := -127  # 音序器休止符

## 各世界调式 / 旋律基底配置（key = GameState.World 枚举值）
## root: 根音 MIDI; scale: 音阶半音偏移; bpm: 基础速度;
## lead_wave: 主旋律波形("tri"|"sine"); pad_semis: 和声 Pad 三音半音偏移
const _MUSIC_MODES := {
	1: {  # 洛伦兹平原：A 大调五声，明亮轻快
		"root": 57, "scale": [0, 2, 4, 7, 9], "bpm": 104.0,
		"lead_wave": "tri", "pad_semis": [0, 4, 7],
	},
	2: {  # 引力深渊：A 小调五声，低沉迟缓
		"root": 45, "scale": [0, 3, 5, 7, 10], "bpm": 72.0,
		"lead_wave": "sine", "pad_semis": [0, 3, 7],
	},
	3: {  # 量子泡沫：C Lydian，飘忽迷离
		"root": 60, "scale": [0, 2, 4, 6, 7, 9, 11], "bpm": 92.0,
		"lead_wave": "tri", "pad_semis": [0, 4, 6],
	},
	4: {  # 熵之终焉：D 全音阶，悬浮崩解
		"root": 50, "scale": [0, 2, 4, 6, 8, 10], "bpm": 60.0,
		"lead_wave": "sine", "pad_semis": [0, 4, 8],
	},
}

## 各世界主旋律 pattern 库（一小节 = 16 个 16 分音符；数值为音阶级数，REST 为休止）
## 级数可超出音阶长度，自动按八度叠加（如五声音阶 deg=5 → 高八度根音）
## 每世界 4 段 = 4 小节乐句（陈述→应答→发展→收束），音序器按小节轮播
const _MUSIC_PATTERNS := {
	1: [  # 洛伦兹平原：明亮跳跃，整体上行后回落
		[0, REST, 2, 4, REST, 4, 5, REST, 7, REST, 5, 4, 2, REST, 0, REST],     # 陈述
		[4, REST, 5, 7, REST, 9, 7, REST, 5, 4, REST, 2, 4, REST, 2, 0],        # 应答（更高）
		[5, REST, 7, REST, 9, REST, 8, 7, REST, 5, 7, REST, 5, 4, REST, 2],     # 发展（切分上行）
		[7, 5, REST, 4, 2, REST, 0, REST, 2, REST, 0, REST, REST, 0, REST, REST], # 收束（下行归位）
	],
	2: [  # 引力深渊：稀疏低沉，渴望式上行后沉降
		[0, REST, REST, 2, REST, REST, 3, REST, 2, REST, REST, 0, REST, REST, REST, REST],
		[3, REST, REST, 4, REST, 3, REST, 2, REST, REST, 0, REST, REST, REST, REST, REST],
		[4, REST, REST, 5, REST, REST, 4, REST, REST, 3, REST, REST, 2, REST, REST, REST],
		[2, REST, REST, 1, REST, REST, 0, REST, REST, REST, 0, REST, REST, REST, REST, REST],
	],
	3: [  # 量子泡沫：流动闪烁，#4 色彩音营造迷离感
		[0, 2, REST, 4, 6, REST, 7, REST, 6, 4, REST, 2, REST, 4, REST, REST],
		[4, REST, 6, REST, 7, 9, REST, 7, REST, 6, REST, 4, 2, REST, 0, REST],
		[7, REST, 9, REST, 11, REST, 9, 7, REST, 9, REST, 7, 6, REST, 4, REST],   # 高区闪烁
		[6, REST, 4, REST, 3, REST, 2, REST, 4, REST, 2, REST, 0, REST, 2, REST], # 漂浮不解决
	],
	4: [  # 熵之终焉：极稀疏全音阶，悬浮飘移、永不解决
		[0, REST, REST, REST, 3, REST, REST, REST, 2, REST, REST, REST, 4, REST, REST, REST],
		[5, REST, REST, 4, REST, REST, 3, REST, REST, 2, REST, REST, REST, 0, REST, REST],
		[2, REST, REST, REST, 4, REST, REST, REST, 5, REST, REST, REST, 6, REST, REST, REST],
		[4, REST, REST, REST, 2, REST, REST, REST, 0, REST, REST, REST, REST, REST, REST, REST],
	],
}

# ---- 内部 ----

var _player: AudioStreamPlayer = null
var _playback: AudioStreamGeneratorPlayback = null
var _phase: float = 0.0
var _sfx_active: Array[Dictionary] = []
var _paused: bool = false
## 环境嗡鸣相位（独立于 SFX）
var _drone_phase: float = 0.0

# ---- 背景音乐：旋律 / 和声层状态 ----
var _lead_phase: float = 0.0
var _bass_phase: float = 0.0
var _pad_phase_a: float = 0.0
var _pad_phase_b: float = 0.0
var _pad_phase_c: float = 0.0
var _pad_lfo: float = 0.0            # Pad 颤音慢速 LFO
var _seq_step: int = -1             # 当前 16 分音符步（-1 = 尚未开始）
var _seq_bar: int = 0               # 小节计数（切换 pattern / 低音根音）
var _seq_samples_left: float = 0.0  # 距下一步剩余采样数
var _lead_freq: float = 0.0         # 当前主旋律频率（0 = 休止）
var _lead_note_t: float = 0.0       # 当前主旋律音符已发声时长（秒）
var _lead_note_dur: float = 0.0     # 当前主旋律音符总时长（秒）
var _bass_freq: float = 0.0
var _bass_note_t: float = 0.0
var _bass_note_dur: float = 0.0


func _ready() -> void:
	# 暂停时仍持续填充缓冲，避免生成器欠载产生爆音/卡顿
	process_mode = Node.PROCESS_MODE_ALWAYS
	_init_generator()


func _process(_delta: float) -> void:
	# 始终填充以喂饱生成器；_paused 时在 _generate_frames 内静音音乐层，仅保留 SFX
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
	var grav: float = TimeManager.gravity_factor
	var rr: float = TimeManager.redline_ratio
	var entropy: float = EntropySystem.global_entropy
	var world: int = GameState.current_world

	# 当前世界调式 / 旋律配置（未知世界回退到 W1）
	var mode: Dictionary = _MUSIC_MODES.get(world, _MUSIC_MODES[1])
	var scale: Array = mode["scale"]
	var patterns: Array = _MUSIC_PATTERNS.get(world, _MUSIC_PATTERNS[1])
	var lead_wave: String = mode["lead_wave"]
	var pad_semis: Array = mode["pad_semis"]
	var root: int = mode["root"]

	# 速度 / 引力 → 节奏调制：速度越快越急促，引力越强越迟缓
	var speed_mul: float = pow(clampf(ts, 1.0, 50.0), 0.35)
	var tempo_mul: float = clampf(speed_mul * clampf(grav, 0.35, 1.0), 0.45, 4.0)
	var bpm: float = float(mode["bpm"]) * tempo_mul
	var samples_per_step: float = SAMPLE_RATE * 60.0 / (bpm * 4.0)  # 16 分音符时长（采样）
	var step_seconds: float = samples_per_step / SAMPLE_RATE

	# 和声 Pad 三音频率
	var pad_fa: float = _midi_to_freq(float(root + int(pad_semis[0])))
	var pad_fb: float = _midi_to_freq(float(root + int(pad_semis[1])))
	var pad_fc: float = _midi_to_freq(float(root + int(pad_semis[2])))

	# 红线警告谐波 + 噪声种子 LFO（沿用旧逻辑）
	var base_freq := clampf(80.0 * ts, 80.0, 800.0)
	var base_inc := base_freq / SAMPLE_RATE
	var warn_freq := clampf(240.0 * ts, 240.0, 2400.0)
	var warn_inc := warn_freq / SAMPLE_RATE
	var warn_phase: float = fmod(_phase * 3.0, 1.0)
	var drone_inc := 36.0 / SAMPLE_RATE
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

		# ============ 背景音乐 + 环境层（暂停时静音） ============
		if not _paused:
			# --- 音序器推进（采样级精确，节奏随 tempo 实时变化） ---
			_seq_samples_left -= 1.0
			if _seq_samples_left <= 0.0:
				_seq_samples_left += samples_per_step
				_advance_sequencer(scale, patterns, root, step_seconds, entropy)

			# 熵失谐：随熵升高轻微失谐，制造"崩坏走音"感
			var det: float = 1.0
			if entropy > 0.0:
				det = 1.0 + entropy * 0.02 * sin(_pad_lfo * TAU)

			# --- 主旋律 voice（拨奏式包络：快起音 + 衰减） ---
			if _lead_freq > 0.0 and _lead_note_t < _lead_note_dur:
				var atk := 0.006
				var env_l: float
				if _lead_note_t < atk:
					env_l = _lead_note_t / atk
				else:
					env_l = pow(1.0 - (_lead_note_t - atk) / maxf(_lead_note_dur - atk, 0.001), 1.4)
				sample += _wave(lead_wave, _lead_phase) * clampf(env_l, 0.0, 1.0) * 0.13
				_lead_phase = fmod(_lead_phase + _lead_freq * det / SAMPLE_RATE, 1.0)
				_lead_note_t += 1.0 / SAMPLE_RATE

			# --- 低音 bass（每小节根音/五度，缓慢衰减铺底） ---
			if _bass_freq > 0.0 and _bass_note_t < _bass_note_dur:
				var env_b := pow(1.0 - _bass_note_t / _bass_note_dur, 1.2)
				sample += sin(_bass_phase * TAU) * env_b * 0.11
				_bass_phase = fmod(_bass_phase + _bass_freq * det / SAMPLE_RATE, 1.0)
				_bass_note_t += 1.0 / SAMPLE_RATE

			# --- 和声 Pad（持续柔和正弦三音，取代旧的单频嗡鸣作为音乐铺底） ---
			var pad_amp := 0.045 * (0.78 + 0.22 * sin(_pad_lfo * TAU)) * (1.0 - entropy * 0.4)
			sample += sin(_pad_phase_a * TAU) * pad_amp
			sample += sin(_pad_phase_b * TAU) * pad_amp * 0.8
			sample += sin(_pad_phase_c * TAU) * pad_amp * 0.7
			_pad_phase_a = fmod(_pad_phase_a + pad_fa * det / SAMPLE_RATE, 1.0)
			_pad_phase_b = fmod(_pad_phase_b + pad_fb * det / SAMPLE_RATE, 1.0)
			_pad_phase_c = fmod(_pad_phase_c + pad_fc * det / SAMPLE_RATE, 1.0)
			_pad_lfo = fmod(_pad_lfo + 0.12 / SAMPLE_RATE, 1.0)

			# --- World 4 底层嗡鸣（仅熵之终焉） ---
			if world == GameState.World.WORLD_4_ENTROPY:
				var drone_amp: float = 0.06 + sin(_drone_phase * TAU * 0.23) * 0.02
				sample += sin(_drone_phase * TAU) * drone_amp
				_drone_phase = fmod(_drone_phase + drone_inc, 1.0)

			# --- 熵噪声（高熵时混入粉噪，强化崩坏感） ---
			if entropy > 0.0:
				sample += (_pseudo_random(noise_seed + float(i) * 0.137) * 2.0 - 1.0) * entropy * 0.08

			# --- 红线警告谐波 ---
			if rr > 0.3:
				var w := sin(warn_phase * TAU) * (rr * 0.10)
				if rr > 0.7:
					w += sin(warn_phase * TAU * 2.3) * ((rr - 0.7) * 0.15)
				sample += w

		# ============ 一次性音效（暂停时仍可播放，如 UI 确认音） ============
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

		# 主输出增益 + 软限幅防削波
		sample = clampf(sample * 0.92, -1.0, 1.0)
		# 当多个 SFX 同时激活时轻微压缩
		if _sfx_active.size() > 3:
			sample *= 0.85

		buf[i] = Vector2(sample, sample)

		_phase = fmod(_phase + base_inc, 1.0)
		warn_phase = fmod(warn_phase + warn_inc, 1.0)
		noise_seed = fmod(noise_seed * 1.037 + 0.003, 1.0)

	return buf


## 音序器步进：确定本步主旋律音；小节首拍触发低音
func _advance_sequencer(scale: Array, patterns: Array, root: int, step_seconds: float, entropy: float) -> void:
	_seq_step += 1
	if _seq_step >= 16:
		_seq_step = 0
		_seq_bar += 1

	var pattern: Array = patterns[_seq_bar % patterns.size()]
	var deg: int = int(pattern[_seq_step])

	# 熵崩解：高熵随机丢音，旋律逐渐瓦解为零散音符
	if entropy > 0.0:
		var rnd := _pseudo_random(float(_seq_step) * 1.71 + float(_seq_bar) * 3.13 + 0.5)
		if rnd < entropy * 0.5:
			deg = REST

	if deg == REST:
		_lead_freq = 0.0
	else:
		# 级数超出音阶长度时自动按八度叠加（整除取八度数，取模取音阶内序号）
		@warning_ignore("integer_division")
		var oct: int = deg / scale.size()
		var idx: int = deg % scale.size()
		var midi: int = root + 12 * oct + int(scale[idx]) + 12  # +12：主旋律置于低音之上
		_lead_freq = _midi_to_freq(float(midi))
		_lead_phase = 0.0
		_lead_note_t = 0.0
		_lead_note_dur = step_seconds * 0.85

	# 小节首拍触发低音（偶数小节根音，奇数小节五度，形成进行感）
	if _seq_step == 0:
		var fifth: int = 0 if (_seq_bar % 2 == 0) else 7
		_bass_freq = _midi_to_freq(float(root - 12 + fifth))
		_bass_phase = 0.0
		_bass_note_t = 0.0
		_bass_note_dur = step_seconds * 16.0 * 0.95


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


## MIDI 音高 → 频率（A4=69=440Hz）
func _midi_to_freq(midi: float) -> float:
	return 440.0 * pow(2.0, (midi - 69.0) / 12.0)


## 旋律波形：三角波(柔和、奇次谐波) 或 正弦波
func _wave(type: String, phase: float) -> float:
	if type == "tri":
		return 2.0 * absf(2.0 * (phase - floor(phase + 0.5))) - 1.0
	return sin(phase * TAU)
