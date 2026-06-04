shader_type canvas_item;

// 时间膨胀色彩偏移 Shader（v2 — 半透明色洗，不遮挡底层世界背景）
// uniform 由 time_warp_overlay.gd 每帧更新：
//   time_dilation_factor > 1.0 → 蓝移色洗
//   time_dilation_factor < 1.0 → 红移色洗
//   等于 1.0 → 完全透明（透出世界背景）
//   偏差越大，色洗越浓

uniform float time_dilation_factor : hint_range(0.0, 50.0) = 1.0;
uniform float shift_strength : hint_range(0.0, 0.5) = 0.12;

void fragment() {
	float shift = (1.0 - time_dilation_factor) * shift_strength;
	float intensity = clamp(abs(shift) / 0.12, 0.0, 1.0);
	float alpha = intensity * 0.28;  // 最大不透明度 ≈ 0.28，保持轻薄

	vec4 col;
	if (time_dilation_factor > 1.005) {
		// 蓝移（场景加速）
		col = vec4(0.15, 0.25, 1.0, alpha);
	} else if (time_dilation_factor < 0.995) {
		// 红移（场景减速）
		col = vec4(1.0, 0.12, 0.05, alpha);
	} else {
		// ~1.0 → 完全透明
		col = vec4(0.0);
	}
	COLOR = col;
}
