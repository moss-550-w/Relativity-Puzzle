shader_type canvas_item;

// 时间膨胀色彩偏移 Shader
// uniform 由脚本每帧更新：
//   time_dilation_factor > 1.0 → 蓝移（场景加速）
//   time_dilation_factor < 1.0 → 红移（场景减速）
//   等于 1.0 → 无色偏

uniform float time_dilation_factor : hint_range(0.0, 50.0) = 1.0;
// 色偏强度（可调）
uniform float shift_strength : hint_range(0.0, 0.5) = 0.08;

void fragment() {
	vec4 col = texture(TEXTURE, UV);
	// factor > 1 时 shift 为负 → col.b += shift(负值=减蓝) → 画面偏蓝（蓝移）
	// factor < 1 时 shift 为正 → col.r += → 画面偏红（红移）
	float shift = (1.0 - time_dilation_factor) * shift_strength;
	col.r += shift;
	col.b -= shift;
	// 保持亮度大致不变
	col.r = clamp(col.r, 0.0, 1.0);
	col.b = clamp(col.b, 0.0, 1.0);
	COLOR = col;
}
