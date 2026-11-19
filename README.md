# LEPAS: Lakon Ciptoning

Puzzle-platformer bayangan wayang kulit tentang melepaskan. Dibuat untuk Game Development Dinamik-21 dengan tema **Less is More, More is Worse**.

Main di browser: https://benday.itch.io/lepas-lakon-ciptoning

## Cerita

Arjuna meninggalkan keraton untuk bertapa di puncak Indrakila. Ia berangkat membawa mahkota, tameng, dan terompah. Di jalan, semua bawaan itu justru menjadi beban. Tujuannya: sampai di sesaji puncak dengan tangan kosong.

## Mekanik inti

Setiap barang yang dibawa menambah Bobot. Bobot menurunkan lompatan, memperlambat langkah, membesarkan bayangan, dan mengeraskan suara langkah. Barang yang dilepas berubah menjadi alat:

| Barang | Bobot | Saat dibawa | Saat dilepas atau dilempar |
| --- | --- | --- | --- |
| Mahkota | 2 | Membuka gerbang keraton | Umpan bagi pemburu Kirata |
| Tameng | 2 | Menahan satu serangan | Pijakan |
| Pelita | 1 | Menerangi hutan, membangunkan buta | Umpan cahaya bagi buta |
| Selendang | 1 | Melayang saat jatuh | Tali panjat bila diikat di dahan |
| Terompah | 1 | Aman di atas duri kecil | Pengalih perhatian celeng |
| Emas | 1 | Godaan | Umpan bagi pemburu Kirata |

Lima babak: Jejer Amarta, Alas Wingit, Goro-goro, Celeng Mamangmurka, Gunung Indrakila. Tiga akhir cerita: Tancep Kayon, Kantong Bolong, Kelir Peteng.

Tingkat kesulitan: Mudah (7 nyawa), Sedang (5), Sulit (3), dan Pati Geni (1 nyawa, mati berarti mengulang dari babak 1).

## Kontrol

| Tombol | Aksi |
| --- | --- |
| A / D atau panah | Jalan |
| Spasi atau W | Lompat, tahan saat jatuh untuk melayang (dengan selendang) |
| E atau J | Ambil barang |
| Q atau K | Lepas barang teratas (diam = taruh, berjalan = lempar), persembahkan di sesaji |
| W / S | Panjat tali |
| Esc atau P | Jeda |
| F atau F11 | Layar penuh |

## Menjalankan proyek

1. Pasang Godot 4.7 (versi Standard).
2. Buka Godot, pilih Import, lalu pilih `project.godot` di folder ini.
3. Tekan F5 untuk bermain.

Ekspor memakai preset di `export_presets.cfg`: Web (tanpa thread, untuk itch.io) dan Windows Desktop.

## Struktur

- `scripts/autoload/`: Game (alur, simpanan, tingkat kesulitan, nyawa), Bobot, Music, Sfx.
- `scripts/game/`: Arjuna, barang, level, dan objek (buta, celeng, Kirata, panah, papan, sesaji, gerbang).
- `scripts/core/`: data babak, peta hasil generator, gaya visual, shader kelir dan siluet.
- `scripts/ui/`: layar judul, pembukaan lakon, kredit.
- `tools/babak.py`: generator peta lima babak (menulis `scripts/core/babak_maps.gd`).
- `tools/siluet.py`: memotong foto wayang museum menjadi gambar bertransparansi.
- `scripts/uji/bot.gd`: bot uji otomatis (`godot --headless --path . -- --babak=N --bot --keluar=170`).

## Tim (BINUS University)

- Zahra Illiyin (Ketua)
- Jessica Anabella
- Made Kevin Darmawan
- Bendi Tandayu Saputra
- Rivaldi Gunawan Yusuf

## Kredit aset

- Wayang: Yale University Art Gallery, The Dr. Walter Angst and Sir Henry Angest Collection, domain publik (CC0). Set Kyai Nugroho (Yogyakarta, 1913), set Kyai Drajat (Surakarta, abad ke-19), dan Wek atau Babi (Bali).
- Musik: "Javanese Court Gamelan 1 - Indonesia" oleh RTB45 (Freesound, CC-BY 4.0). "Gender Wayang" (1928), rekaman tradisional domain publik (Wikimedia Commons). Kenney Music Loops (CC0).
- Gambar dan suara: Kenney (CC0). Font Cormorant Garamond (SIL Open Font License).
- Rujukan cerita: lakon Begawan Ciptoning (Mintaraga) dari kakawin Arjunawiwaha karya Empu Kanwa. Petuah R.M.P. Sosrokartono.

Tidak ada aset gambar atau suara buatan AI generatif. Kode dikembangkan dengan bantuan AI (Claude).
