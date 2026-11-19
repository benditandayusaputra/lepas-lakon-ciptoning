class_name Art
## Bantuan visual bersama: palet kelir per pathet, siluet, hook gambar wayang, font, tema UI.
##
## Semua benda di dunia tampil sebagai bayangan hitam di depan kelir. Satu-satunya warna adalah
## godaan (emas, mahkota, harta). Gambar wayang dari museum dipasang dengan menaruh PNG di
## assets/wayang/ (lihat README). Kalau file belum ada, dipakai siluet sementara dari Kenney.

const ONEBIT := preload("res://assets/tiles/onebit_pack.png")
const FONT_FILE := preload("res://assets/fonts/cormorant_garamond.ttf")
const LIGHT_TEX := preload("res://assets/particles/light_01.png")
const STAR_TEX := preload("res://assets/particles/star_06.png")
const SMOKE_TEX := preload("res://assets/particles/smoke_05.png")
const SPARK_TEX := preload("res://assets/particles/spark_05.png")
const KELIR_SHADER := preload("res://scripts/core/kelir.gdshader")
const SILUET_SHADER := preload("res://scripts/core/siluet.gdshader")
const WARNA_SHADER := preload("res://scripts/core/wayang_warna.gdshader")
const POST_SHADER := preload("res://scripts/core/post.gdshader")
const KABUT_SHADER := preload("res://scripts/core/kabut.gdshader")

const TILE := 16
const WAYANG_DIR := "res://assets/wayang/"

# Bayangan.
const HITAM := Color(0.025, 0.016, 0.01, 1.0)
const BAYANG := Color(0.05, 0.03, 0.018, 0.97)
const DEKOR := Color(0.09, 0.055, 0.03, 0.9)
# Godaan: satu-satunya warna di dunia.
const EMAS := Color(1.0, 0.76, 0.22)
const EMAS_TERANG := Color(1.0, 0.9, 0.55)
# Cahaya.
const API := Color(1.0, 0.7, 0.3)
# Kertas dan UI.
const PAPER := Color(0.96, 0.86, 0.64)
const PANEL := Color(0.08, 0.05, 0.03, 0.9)
const TEXT := Color(0.97, 0.91, 0.78)
const TEXT_DIM := Color(0.78, 0.68, 0.52)
const TEXT_INK := Color(0.12, 0.06, 0.03)
const BG := Color(0.08, 0.05, 0.03)

## Warna kelir per pathet: hot (pusat blencong), mid, edge (pinggir kelir).
const PATHET := {
	"nem": {"hot": Color(1.0, 0.88, 0.62), "mid": Color(0.88, 0.6, 0.3), "edge": Color(0.2, 0.09, 0.04)},
	"sanga": {"hot": Color(0.98, 0.62, 0.42), "mid": Color(0.62, 0.2, 0.12), "edge": Color(0.14, 0.03, 0.03)},
	"manyura": {"hot": Color(0.93, 0.95, 1.0), "mid": Color(0.52, 0.64, 0.82), "edge": Color(0.08, 0.1, 0.18)},
	"fajar": {"hot": Color(1.0, 0.98, 0.92), "mid": Color(0.95, 0.85, 0.7), "edge": Color(0.4, 0.32, 0.26)},
}

## Arah hadap asli gambar wayang (1 = menghadap kanan, -1 = menghadap kiri).
## Ubah di sini bila wayang yang dipasang menghadap ke arah sebaliknya.
const ARAH := {
	"arjuna": -1,
	"arjuna_tapa": -1,
	"semar": 1,
	"buta": 1,
	"celeng": 1,
	"kirata": 1,
	"prajurit": 1,
}

static var _cache := {}
static var _theme: Theme
static var _font: FontVariation
static var _glow_mat: CanvasItemMaterial
static var _white: ImageTexture


static func icon(c: int, r: int) -> AtlasTexture:
	var key := "%d:%d" % [c, r]
	if _cache.has(key):
		return _cache[key]
	var a := AtlasTexture.new()
	a.atlas = ONEBIT
	a.region = Rect2(c * TILE, r * TILE, TILE, TILE)
	_cache[key] = a
	return a


## Tekstur putih 4x4, dipakai untuk bidang hitam (tanah, dinding) yang diwarnai lewat modulate.
static func white() -> ImageTexture:
	if _white:
		return _white
	var img := Image.create(4, 4, false, Image.FORMAT_RGBA8)
	img.fill(Color.WHITE)
	_white = ImageTexture.create_from_image(img)
	return _white


static func tex(path: String) -> Texture2D:
	if _cache.has(path):
		return _cache[path]
	var t: Texture2D = null
	if ResourceLoader.exists(path):
		t = load(path)
	_cache[path] = t
	return t


## Hook gambar wayang: assets/wayang/<nama>.png bila ada, selain itu null.
static func wayang(file_name: String) -> Texture2D:
	return tex(WAYANG_DIR + file_name + ".png")


## Tekstur wayang dengan bingkai kosong di sekelilingnya, supaya garis luar tidak terpotong.
const BINGKAI := 28


static func berbingkai(file_name: String, t: Texture2D) -> Texture2D:
	var key := "bingkai:" + file_name
	if _cache.has(key):
		return _cache[key]
	var img := t.get_image()
	if img == null:
		return t
	if img.is_compressed():
		img.decompress()
	img.convert(Image.FORMAT_RGBA8)
	var out := Image.create(img.get_width() + BINGKAI * 2, img.get_height() + BINGKAI * 2, false, Image.FORMAT_RGBA8)
	out.fill(Color(0, 0, 0, 0))
	out.blit_rect(img, Rect2i(Vector2i.ZERO, img.get_size()), Vector2i(BINGKAI, BINGKAI))
	var nt := ImageTexture.create_from_image(out)
	_cache[key] = nt
	return nt


static func siluet_material(tint: Color, blur := 0.0) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = SILUET_SHADER
	m.set_shader_parameter("tint", tint)
	m.set_shader_parameter("blur", blur)
	return m


## Sprite tokoh: gambar wayang bila tersedia, kalau tidak ikon Kenney yang diperbesar.
## Berdiri di kakinya (y = 0), tingginya fit_height piksel.
static func figure(file_name: String, fallback: Vector2i, fit_height: float, tint := HITAM) -> Sprite2D:
	var s := Sprite2D.new()
	var t := wayang(file_name)
	if t:
		var k := fit_height / float(t.get_height())
		s.texture = berbingkai(file_name, t)
		s.scale = Vector2(k, k)
		s.position = Vector2(0, -fit_height / 2.0)
	else:
		s.texture = icon(fallback.x, fallback.y)
		s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		var k2 := fit_height / 16.0
		s.scale = Vector2(k2, k2)
		s.position = Vector2(0, -fit_height / 2.0)
	s.material = siluet_material(tint)
	# Garis cahaya di luar tepi tokoh, kira-kira 1,5 piksel layar (hanya untuk gambar wayang).
	if t:
		(s.material as ShaderMaterial).set_shader_parameter("rim_color", Color(1.0, 0.8, 0.45, 0.9))
		(s.material as ShaderMaterial).set_shader_parameter("rim_width", minf(1.5 / maxf(s.scale.x, 0.001), float(BINGKAI) - 2.0))
	return s


static func arah(file_name: String) -> int:
	return int(ARAH.get(file_name, 1))


static func is_wayang(file_name: String) -> bool:
	return wayang(file_name) != null


## Gunungan (kayon): gambar wayang bila ada, kalau tidak bentuk daun sederhana.
## Titik asal di dasar gunungan.
## Tampilkan wayang dengan warna aslinya (sisi dalang), untuk judul, pembukaan, dan ending.
## Hanya berlaku untuk gambar wayang; bentuk cadangan tetap berupa siluet.
static func warnai(node: Node) -> void:
	var list: Array = [node]
	list.append_array(node.get_children())
	for n in list:
		var s := n as Sprite2D
		if s == null or s.texture == null or s.texture.get_width() <= 16:
			continue
		var m := ShaderMaterial.new()
		m.shader = WARNA_SHADER
		s.material = m


static func gunungan(height: float, tint := HITAM) -> Node2D:
	var holder := Node2D.new()
	var t := wayang("gunungan")
	if t:
		var s := Sprite2D.new()
		s.texture = t
		var k := height / float(t.get_height())
		s.scale = Vector2(k, k)
		s.position = Vector2(0, -height / 2.0)
		s.material = siluet_material(tint)
		holder.add_child(s)
		return holder
	var w := height * 0.56
	var pts := PackedVector2Array()
	var n := 24
	for i in n + 1:
		var a := float(i) / float(n)
		var half := w * 0.5 * (1.0 - pow(a, 1.7)) * (0.72 + 0.28 * sin(a * PI))
		pts.append(Vector2(half, -height * 0.12 - height * 0.88 * a))
	for i in range(n, -1, -1):
		var a := float(i) / float(n)
		var half := w * 0.5 * (1.0 - pow(a, 1.7)) * (0.72 + 0.28 * sin(a * PI))
		pts.append(Vector2(-half, -height * 0.12 - height * 0.88 * a))
	var poly := Polygon2D.new()
	poly.polygon = pts
	poly.color = tint
	holder.add_child(poly)
	var stem := rect(Vector2(height * 0.03, height * 0.14), tint)
	stem.position = Vector2(-height * 0.015, -height * 0.14)
	holder.add_child(stem)
	return holder


## Bidang persegi berwarna (tanah, dinding, gerbang).
static func rect(size: Vector2, color: Color, centered := false) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = white()
	s.centered = centered
	s.scale = size / 4.0
	s.modulate = color
	return s


static func font() -> FontVariation:
	if _font:
		return _font
	_font = FontVariation.new()
	_font.base_font = FONT_FILE
	var ts := TextServerManager.get_primary_interface()
	_font.variation_opentype = {ts.name_to_tag("wght"): 600}
	return _font


static func theme() -> Theme:
	if _theme:
		return _theme
	var t := Theme.new()
	t.default_font = font()
	t.default_font_size = 18
	t.set_color("font_color", "Label", TEXT)
	t.set_color("font_color", "Button", TEXT_INK)
	t.set_color("font_hover_color", "Button", Color(0.55, 0.12, 0.06))
	t.set_color("font_focus_color", "Button", Color(0.55, 0.12, 0.06))
	t.set_color("font_pressed_color", "Button", Color(0.55, 0.12, 0.06))
	t.set_color("font_disabled_color", "Button", Color(TEXT_INK, 0.4))
	var flat := StyleBoxFlat.new()
	flat.bg_color = Color(0, 0, 0, 0)
	flat.content_margin_left = 10
	flat.content_margin_right = 10
	flat.content_margin_top = 2
	flat.content_margin_bottom = 2
	var focus := flat.duplicate() as StyleBoxFlat
	focus.border_color = Color(0.55, 0.12, 0.06)
	focus.border_width_bottom = 1
	for s in ["normal", "pressed", "hover", "disabled"]:
		t.set_stylebox(s, "Button", flat)
	t.set_stylebox("focus", "Button", focus)
	var panel := StyleBoxFlat.new()
	panel.bg_color = PANEL
	panel.border_color = Color(API, 0.6)
	panel.set_border_width_all(1)
	panel.set_corner_radius_all(3)
	panel.content_margin_left = 14
	panel.content_margin_right = 14
	panel.content_margin_top = 8
	panel.content_margin_bottom = 8
	t.set_stylebox("panel", "PanelContainer", panel)
	_theme = t
	return t


static func label(text: String, font_size := 18, color := TEXT) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	return l


## Tulisan di atas kelir: tinta gelap dengan garis tepi kertas.
static func ink_label(text: String, font_size := 18) -> Label:
	var l := label(text, font_size, TEXT_INK)
	l.add_theme_color_override("font_outline_color", Color(PAPER, 0.75))
	l.add_theme_constant_override("outline_size", 5)
	return l


static func place(c: Control, preset: Control.LayoutPreset, r: Rect2) -> void:
	c.set_anchors_preset(preset, false)
	c.offset_left = r.position.x
	c.offset_top = r.position.y
	c.offset_right = r.end.x
	c.offset_bottom = r.end.y


## Sprite cahaya aditif: api pelita, kilau emas, sinar anugerah.
static func glow(color: Color, size: float) -> Sprite2D:
	if _glow_mat == null:
		_glow_mat = CanvasItemMaterial.new()
		_glow_mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	var s := Sprite2D.new()
	s.texture = LIGHT_TEX
	s.material = _glow_mat
	s.modulate = color
	s.scale = Vector2.ONE * (size / float(LIGHT_TEX.get_width()))
	return s


static func burst(parent: Node, pos: Vector2, color: Color, amount := 14, texture: Texture2D = STAR_TEX, speed := 60.0) -> void:
	var p := CPUParticles2D.new()
	p.texture = texture
	p.amount = amount
	p.one_shot = true
	p.explosiveness = 0.95
	p.lifetime = 0.8
	p.direction = Vector2.UP
	p.spread = 180.0
	p.gravity = Vector2(0, 60)
	p.initial_velocity_min = speed * 0.4
	p.initial_velocity_max = speed
	p.scale_amount_min = 0.015
	p.scale_amount_max = 0.035
	p.color = color
	var ramp := Gradient.new()
	ramp.set_color(0, Color(1, 1, 1, 1))
	ramp.set_color(1, Color(1, 1, 1, 0))
	p.color_ramp = ramp
	p.global_position = pos
	parent.add_child(p)
	p.emitting = true
	parent.get_tree().create_timer(p.lifetime + 0.3).timeout.connect(p.queue_free)
