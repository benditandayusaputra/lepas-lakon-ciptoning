extends Node
## Bobot: semua yang dibawa Arjuna dan semua akibatnya.
##
## Satu sumber kebenaran. Pemain, musik, bayangan, dan musuh membaca nilai dari sini.
## Barang disimpan sebagai tumpukan: yang terakhir diambil adalah yang pertama dilepas.

signal berubah(total: int)

const DATA := {
	"mahkota": {"nama": "Mahkota", "bobot": 2, "icon": Vector2i(43, 2), "emas": true},
	"tameng": {"nama": "Tameng", "bobot": 2, "icon": Vector2i(39, 4), "emas": false},
	"pelita": {"nama": "Pelita", "bobot": 1, "icon": Vector2i(31, 11), "emas": false},
	"selendang": {"nama": "Selendang", "bobot": 1, "icon": Vector2i(29, 11), "emas": false},
	"terompah": {"nama": "Terompah", "bobot": 1, "icon": Vector2i(40, 1), "emas": false},
	"emas": {"nama": "Emas", "bobot": 1, "icon": Vector2i(41, 3), "emas": true},
}

const TIPIS := 0
const SEDANG := 1
const BESAR := 2

var bawaan: Array[String] = []
## Pernah mengambil emas sepanjang permainan (menentukan ending Kantong Bolong).
var emas_pernah := false


func total() -> int:
	var t := 0
	for id in bawaan:
		t += int(DATA[id]["bobot"])
	return t


func tingkat() -> int:
	var t := total()
	if t <= 2:
		return TIPIS
	if t <= 5:
		return SEDANG
	return BESAR


func punya(id: String) -> bool:
	return bawaan.has(id)


func kosong() -> bool:
	return bawaan.is_empty()


func atas() -> String:
	if bawaan.is_empty():
		return ""
	return bawaan[bawaan.size() - 1]


func ambil(id: String) -> void:
	bawaan.append(id)
	if id == "emas":
		emas_pernah = true
	berubah.emit(total())


func lepas_atas() -> String:
	if bawaan.is_empty():
		return ""
	var id: String = bawaan.pop_back()
	berubah.emit(total())
	return id


## Menghapus satu barang tertentu (tameng pecah, persembahan). true bila ada.
func hapus(id: String) -> bool:
	var i := bawaan.rfind(id)
	if i == -1:
		return false
	bawaan.remove_at(i)
	berubah.emit(total())
	return true


func setel(list: Array) -> void:
	bawaan.clear()
	for id in list:
		bawaan.append(str(id))
	berubah.emit(total())


func salin() -> Array[String]:
	return bawaan.duplicate()


# --- akibat Bobot -------------------------------------------------------------

## Tinggi lompatan relatif: turun 8% per Bobot, paling rendah 40%.
func lompat_mult() -> float:
	return maxf(0.4, 1.0 - 0.08 * total())


## Kecepatan relatif: turun 5% per Bobot.
func lari_mult() -> float:
	return maxf(0.5, 1.0 - 0.05 * total())


## Batas jatuh aman dalam piksel, diukur dari pijakan terakhir.
func jatuh_aman() -> float:
	return (6.0 - 0.5 * total()) * 16.0 + 6.0


## Radius suara langkah dalam piksel. Terompah membuatnya jauh lebih bising.
func suara() -> float:
	var r := (1.0 + total()) * 16.0
	if punya("terompah"):
		r *= 1.6
	return r


## Skala bayangan Arjuna di kelir.
func skala_bayangan() -> float:
	return 1.0 + 0.08 * total()


func nama(id: String) -> String:
	return str(DATA[id]["nama"])


func icon(id: String) -> Texture2D:
	var team := Art.wayang("barang_" + id)
	if team:
		return team
	var c: Vector2i = DATA[id]["icon"]
	return Art.icon(c.x, c.y)


func berwarna(id: String) -> bool:
	return bool(DATA[id]["emas"])
