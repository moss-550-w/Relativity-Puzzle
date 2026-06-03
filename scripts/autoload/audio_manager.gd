extends Node
## AudioManager — 音频管理器（Phase 1 桩）
## 提供音效播放接口，根据时间缩放调整音高


# ---- 方法 ----

## 播放音效（占位：暂不加载真实音频）
func play_sfx(sfx_id: String, pitch_scale: float = 1.0) -> void:
	var effective_pitch := pitch_scale * _pitch_from_time_scale()
	# TODO: Phase 2 — 加载真实音频资源播放
	if OS.is_debug_build():
		pass  # print("[AudioManager] SFX: %s pitch=%.2f" % [sfx_id, effective_pitch])


## 根据当前场景时间缩放返回音高倍率
## 时间快 → 音高上升；时间慢 → 音高下降
func _pitch_from_time_scale() -> float:
	return TimeManager.scene_time_scale
