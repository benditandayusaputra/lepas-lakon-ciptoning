shader_type canvas_item;
// Efek layar: butiran film dan vignette. Tidak membaca layar, jadi aman untuk WebGL.

uniform float grain = 0.06;
uniform float vignette = 0.55;
uniform float darkness = 0.0;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	vec2 uv = UV;
	float t = floor(TIME * 18.0);
	float n = hash(uv * vec2(640.0, 360.0) + t) - 0.5;
	vec2 v = uv - 0.5;
	float vig = smoothstep(0.25, 0.85, length(v * vec2(1.0, 1.3))) * vignette;
	float a = clamp(vig + darkness, 0.0, 1.0);
	vec3 col = vec3(0.0);
	// Butiran: sedikit terang dan gelap bergantian.
	float g = n * grain;
	col += max(g, 0.0) * 6.0;
	a = clamp(a + abs(g), 0.0, 1.0);
	COLOR = vec4(col, a);
}
