shader_type canvas_item;
// Kabut tipis di antara lapisan latar dan lapisan main. Koordinat dunia membuat kabut
// tetap di tempat saat kamera bergerak, lalu bergeser pelan oleh angin.

uniform vec4 fog_color : source_color = vec4(1.0, 0.9, 0.75, 0.22);
uniform vec2 world_offset = vec2(0.0);
uniform vec2 rect_size = vec2(760.0, 460.0);
uniform float drift = 8.0;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = hash(i);
	float b = hash(i + vec2(1.0, 0.0));
	float c = hash(i + vec2(0.0, 1.0));
	float d = hash(i + vec2(1.0, 1.0));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

void fragment() {
	vec2 w = world_offset + UV * rect_size + vec2(TIME * drift, 0.0);
	float n = vnoise(w / 120.0) * 0.6 + vnoise(w / 45.0) * 0.3 + vnoise(w / 18.0) * 0.1;
	float band = smoothstep(0.15, 0.9, UV.y);
	float a = smoothstep(0.35, 0.85, n) * band;
	COLOR = vec4(fog_color.rgb, fog_color.a * a);
}
