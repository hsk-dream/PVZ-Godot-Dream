// 角色身体与蹦极绳子共用的水平裁切；默认保留原有隐藏下方的屏幕坐标行为。
shader_type canvas_item;

// 裁切边界的 Y，单位由 use_world_coordinates 决定，必须与调用方传入的坐标一致。
uniform float cutoff_y = 0.0;
// false 隐藏边界下方，用于出土或出水；true 隐藏上方，用于手部以上的绳子。
uniform bool clip_above = false;
// false 使用片元的视口屏幕坐标，兼容原调用；true 使用世界坐标，接收连接点 global_position.y。
uniform bool use_world_coordinates = false;
// 可见侧的渐变宽度，单位与 cutoff_y 相同；0 为硬裁切，绳子可设置为 1～2。
uniform float fade_width : hint_range(0.0, 32.0, 0.1) = 0.0;

// 顶点的世界 Y，插值到各片元后可在换父节点、缩放和移动时保持裁切边界一致。
varying float world_y;

// 仅记录世界位置，不修改顶点，让引擎继续处理原有的画布和相机变换。
void vertex() {
	world_y = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).y;
}

// 将裁切透明度乘到已有颜色上，保留纹理透明度及受击、冰冻、魅惑等 modulate 效果。
void fragment() {
	// fragment 中的 VERTEX 是屏幕坐标，不是节点局部坐标。
	float pixel_y = use_world_coordinates ? world_y : VERTEX.y;
	// 距离为正表示位于可见侧；两种裁切方向共用同一套边缘处理。
	float visible_distance = clip_above ? pixel_y - cutoff_y : cutoff_y - pixel_y;
	// 默认硬裁切保留边界本身；仅正宽度调用 smoothstep，避免两端相等的未定义结果。
	float mask_alpha = step(0.0, visible_distance);
	if (fade_width > 0.0) {
		mask_alpha = smoothstep(0.0, fade_width, visible_distance);
	}
	COLOR.a *= mask_alpha;
}
