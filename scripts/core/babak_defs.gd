class_name BabakDefs
## Data lima babak: petuah Sosrokartono, pathet, bawaan awal, aturan sesaji, petunjuk tombol.
## Peta ASCII ada di babak_maps.gd (dibuat oleh tools/babak.py).

const DEFS := [
	{
		"nama": "Jejer Amarta",
		"tujuan": "Keluar dari keraton lewat gapura belakang.",
		"langkah": [[0, "Temui prajurit di gerbang keraton"], [31, "Panjat tembok taman"], [47, "Cari jalan ke gapura belakang"], [84, "Lewati gapura butulan yang sempit"], [91, "Persembahkan yang tidak perlu di sesaji"], [99, "Lompati parit duri"], [118, "Lewati lorong panah keraton"]],
		"petuah": "Sugih tanpa bandha",
		"arti": "Kaya tanpa harta",
		"pathet": "nem",
		"terang": 1.0,
		"gelap": false,
		"musik": "babak",
		"latar": "keraton",
		"bawaan": ["mahkota", "terompah", "tameng"],
		"terima": ["emas", "tameng"],
		"syarat": [],
		"panah_arah": -1,
		"angin": 0,
		"petunjuk": [
			[3, "A / D  jalan      Spasi  lompat"],
			[40, "Q  lepas barang teratas"],
			[63, "E  ambil"],
			[92, "Q di depan sesaji  persembahkan"],
			[100, "Parit duri: lompat dari pijakan ke pijakan"],
			[121, "Berlindung di ceruk saat panah melesat"],
		],
	},
	{
		"nama": "Alas Wingit",
		"tujuan": "Seberangi Alas Wingit tanpa tertangkap buta.",
		"langkah": [[0, "Ambil pelita"], [10, "Seberangi jembatan akar tanpa membangunkan buta"], [48, "Lewati lorong panah"], [76, "Seberangi papan rapuh"], [88, "Buka gerbang hutan"], [98, "Lewati lorong panah kedua"], [126, "Keluar dari Alas Wingit"]],
		"petuah": "Digdaya tanpa aji",
		"arti": "Sakti tanpa jimat",
		"pathet": "nem",
		"terang": 0.3,
		"gelap": true,
		"musik": "babak",
		"latar": "hutan",
		"bawaan": ["mahkota", "terompah"],
		"terima": ["tameng", "pelita", "emas"],
		"syarat": ["tameng", "pelita"],
		"panah_arah": -1,
		"angin": 0,
		"petunjuk": [
			[6, "E  ambil pelita"],
			[24, "Q diam  taruh      Q sambil berjalan  lempar"],
			[52, "Berlindung di ceruk saat panah melesat"],
			[77, "Papan rapuh patah bila Bobot 3 ke atas  lepas terompah dulu"],
			[104, "Papan rapuh di lorong patah bila Bobot 3 ke atas"],
		],
	},
	{
		"nama": "Goro-goro",
		"tujuan": "Seberangi jurang badai dan naiki tebing.",
		"langkah": [[0, "Ambil selendang"], [12, "Lewati duri"], [22, "Melayang menyeberangi jurang bersama angin"], [38, "Ikat selendang di dahan, lalu panjat"], [48, "Beristirahat di sesaji"], [62, "Lompati jurang puncak bersama angin"], [93, "Turun dari puncak badai"]],
		"petuah": "Trima mawi pasrah",
		"arti": "Menerima dengan pasrah",
		"pathet": "sanga",
		"terang": 0.85,
		"gelap": false,
		"musik": "badai",
		"latar": "badai",
		"bawaan": ["mahkota", "terompah"],
		"terima": ["selendang", "emas"],
		"syarat": [],
		"panah_arah": -1,
		"angin": 1,
		"petunjuk": [
			[8, "E  ambil selendang"],
			[23, "Tahan Spasi saat jatuh  melayang"],
			[44, "Q di bawah dahan  ikat selendang"],
			[46, "W / S  panjat"],
			[65, "Lompat saat angin bertiup  terlalu berat? lepas terompah"],
		],
	},
	{
		"nama": "Celeng Mamangmurka",
		"tujuan": "Lolos dari kejaran celeng.",
		"langkah": [[0, "Lanjutkan perjalanan"], [22, "Lari, celeng mengejar"], [90, "Masuk lorong rendah"], [114, "Lanjutkan ke sesaji"], [122, "Daki lereng Mamangmurka"], [133, "Seberangi titian papan rapuh"], [146, "Lompati duri terakhir"]],
		"petuah": "Nglurug tanpa bala",
		"arti": "Menyerbu tanpa pasukan",
		"pathet": "sanga",
		"terang": 0.9,
		"gelap": false,
		"musik": "babak",
		"latar": "lereng",
		"bawaan": ["mahkota", "terompah"],
		"terima": ["terompah", "emas"],
		"syarat": [],
		"panah_arah": -1,
		"angin": 0,
		"petunjuk": [
			[44, "Lempar terompah: celeng berhenti mengendus, papan pun tetap kuat"],
			[132, "Papan rapuh patah bila Bobot 3 ke atas"],
		],
	},
	{
		"nama": "Gunung Indrakila",
		"tujuan": "Capai sesaji di puncak Indrakila dengan tangan kosong.",
		"langkah": [[0, "Daki kaki Indrakila"], [35, "Lewati lereng di bawah bidikan Kirata"], [80, "Ambil selendang dan seberangi jurang angin"], [101, "Ikat selendang di dahan, panjat tebing"], [124, "Seberangi titian papan rapuh"], [164, "Naik ke puncak"], [180, "Bertapa di sesaji puncak"]],
		"petuah": "Menang tanpa ngasorake",
		"arti": "Menang tanpa merendahkan",
		"pathet": "manyura",
		"terang": 1.0,
		"gelap": false,
		"musik": "kejar",
		"latar": "gunung",
		"bawaan": ["mahkota"],
		"terima": ["mahkota", "tameng", "pelita", "selendang", "terompah", "emas"],
		"syarat": [],
		"panah_arah": -1,
		"angin": 1,
		"petunjuk": [
			[21, "Lorong rendah hanya muat bila Bobot ringan"],
			[37, "Garis bidik Kirata muncul: berlindung di balik batu"],
			[44, "Q sambil berjalan  lempar barang berkilau sebagai umpan"],
			[90, "Tahan Spasi saat jatuh  melayang bersama angin"],
			[87, "E  ambil selendang"],
			[104, "Q di bawah dahan  ikat selendang      W  panjat"],
			[127, "Papan rapuh patah bila Bobot 3 ke atas"],
		],
	},
]


static func count() -> int:
	return DEFS.size()


static func get_def(index: int) -> Dictionary:
	var d: Dictionary = DEFS[clampi(index, 0, DEFS.size() - 1)]
	return d


static func get_map(index: int) -> Array:
	var m: Array = BabakMaps.MAPS[clampi(index, 0, BabakMaps.MAPS.size() - 1)]
	return m


static func start_bawaan(index: int) -> Array:
	var b: Array = get_def(index)["bawaan"]
	return b.duplicate()
