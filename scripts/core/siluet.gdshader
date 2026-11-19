shader_type canvas_item;
// Siluet: setiap piksel yang tidak transparan diganti satu warna (bayangan di kelir).
// Lubang tatahan pada foto wayang tetap tembus cahaya. blur melunakkan tepi untuk bayangan
// yang dekat dengan blencong (makin berat bawaan, makin besar dan kabur bayangannya).
// rim: garis cahaya di LUAR tepi tokoh, seperti terkena blencong, supaya tokoh tidak
// menyatu dengan latar yang gelap. Tekstur tokoh diberi bingkai kosong agar garis ini muat.

uniform vec4 tint : source_color = vec4(0.025, 0.016, 0.01, 1.0);
uniform float blur = 0.0;
uniform vec4 rim_color : source_color = vec4(1.0, 0.78, 0.42, 0.0);
uniform float rim_width = 0.0;

void fragment() {
	float raw = texture(TEXTURE, UV).a;
	float a = raw;
	if (blur > 0.01) {
		vec2 px = TEXTURE_PIXEL_SIZE * blur;
		float s = texture(TEXTURE, UV + vec2(px.x, 0.0)).a + texture(TEXTURE, UV - vec2(px.x, 0.0)).a;
		s += texture(TEXTURE, UV + vec2(0.0, px.y)).a + texture(TEXTURE, UV - vec2(0.0, px.y)).a;
		float c = texture(TEXTURE, UV + px).a + texture(TEXTURE, UV - px).a;
		c += texture(TEXTURE, UV + vec2(px.x, -px.y)).a + texture(TEXTURE, UV + vec2(-px.x, px.y)).a;
		a = a * 0.2 + s * 0.1 + c * 0.1;
	}
	float sa = a * tint.a;
	if (rim_color.a > 0.01 && rim_width > 0.0) {
		vec2 r = TEXTURE_PIXEL_SIZE * rim_width;
		float m = 0.0;
		for (int i = 0; i < 12; i++) {
			float ang = 6.2831853 * float(i) / 12.0;
			vec2 d = vec2(cos(ang), sin(ang));
			m = max(m, texture(TEXTURE, UV + d * r).a);
			m = max(m, texture(TEXTURE, UV + d * r * 0.5).a);
		}
		float ol = clamp(m - raw, 0.0, 1.0) * rim_color.a;
		float oa = sa + ol * (1.0 - sa);
		vec3 col = mix(rim_color.rgb, tint.rgb, sa / max(oa, 0.0001));
		COLOR = vec4(col, oa * COLOR.a);
	} else {
		COLOR = vec4(tint.rgb, sa * COLOR.a);
	}
}
