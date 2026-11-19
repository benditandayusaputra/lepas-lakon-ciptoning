shader_type canvas_item;
// Wayang berwarna (sisi dalang): warna asli foto, sedikit dihangatkan cahaya blencong.
// Tepi alfa dipersempit supaya sisa latar foto tidak terlihat sebagai pinggiran pucat.

uniform vec4 hangat : source_color = vec4(1.0, 0.93, 0.82, 1.0);

void fragment() {
	vec4 c = texture(TEXTURE, UV);
	float a = smoothstep(0.4, 0.95, c.a);
	COLOR = vec4(c.rgb * hangat.rgb, a * COLOR.a);
}
