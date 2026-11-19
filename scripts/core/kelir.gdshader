shader_type canvas_item;
// Kelir: layar putih wayang kulit yang diterangi blencong (lampu minyak).
// Titik terang di tengah atas, berkedip pelan, makin gelap ke tepi bingkai.
// spot_* menambah cahaya kecil yang mengikuti pelita (dibawa atau ditaruh).

uniform float brightness = 1.0;
uniform float aspect = 1.7778;
uniform float flicker_amount = 1.0;
uniform vec2 lamp_uv = vec2(0.5, 0.28);
uniform vec2 spot_uv = vec2(0.5, 0.6);
uniform float spot_strength = 0.0;
uniform float spot_radius = 0.16;
uniform float flash = 0.0;
uniform vec3 hot : source_color = vec3(1.0, 0.88, 0.62);
uniform vec3 mid : source_color = vec3(0.88, 0.6, 0.3);
uniform vec3 edge : source_color = vec3(0.2, 0.09, 0.04);

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
	vec2 uv = UV;
	float wobble = 0.03 * sin(TIME * 7.3) + 0.02 * sin(TIME * 17.1 + 1.3) + 0.04 * (vnoise(vec2(TIME * 2.5, 0.0)) - 0.5);
	float flick = 0.95 + wobble * flicker_amount;

	vec2 d = (uv - lamp_uv) * vec2(aspect, 1.0);
	float lamp = exp(-dot(d, d) * 1.1) * brightness;

	vec2 ds = (uv - spot_uv) * vec2(aspect, 1.0);
	float spot = exp(-dot(ds, ds) / (spot_radius * spot_radius)) * spot_strength;

	float light = clamp((lamp + spot) * flick + flash, 0.0, 1.4);
	vec3 col = mix(edge, mid, smoothstep(0.0, 0.55, light));
	col = mix(col, hot, smoothstep(0.5, 1.05, light));

	// Serat kain.
	float fibre = vnoise(uv * vec2(380.0, 6.0)) * 0.05 + vnoise(uv * vec2(90.0, 52.0)) * 0.05;
	col *= 0.94 + fibre;

	// Bingkai kayu makin gelap ke tepi.
	vec2 v = uv - 0.5;
	float frame = 1.0 - smoothstep(0.36, 0.8, length(v * vec2(1.0, 1.25)));
	col *= mix(0.3, 1.0, frame);

	COLOR = vec4(col, 1.0);
}
