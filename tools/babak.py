"""Pembangun peta babak LEPAS: Lakon Ciptoning.

Menulis scripts/core/babak_maps.gd dari definisi di bawah. Jalankan:
    python3 tools/babak.py

Legenda (1 sel = 16 px):
  #  tanah/dinding        -  pijakan satu arah     .  kosong
  P  awal                 K  pathok (checkpoint)   E  akhir babak
  S  sesaji               F  sesaji terakhir       H  harta (godaan terakhir)
  G  gerbang sesaji       g  gerbang keraton       R  prajurit keraton
  ^  duri kecil           X  duri besar            ~  papan rapuh
  W  angin                a  jebakan panah         D  dahan (ikat selendang)
  z  buta tidur           b  buta patroli          k  pemburu Kirata
  j  Kirata jarak dekat
  C  celeng mulai         c  celeng berhenti
  p  pelita  s  selendang  e  emas  t  tameng  o  terompah  m  mahkota
  J  joglo (hiasan)        T  pohon mati (hiasan)   Y  pohon (hiasan)
"""

import os


class Map:
    def __init__(self, w, h):
        self.W, self.H = w, h
        self.g = [["." for _ in range(w)] for _ in range(h)]

    def fill(self, x0, x1, y0, y1, ch):
        for y in range(max(0, y0), min(self.H, y1)):
            for x in range(max(0, x0), min(self.W, x1)):
                self.g[y][x] = ch

    def ground(self, x0, x1, h):
        """Tanah setinggi h sel dari dasar peta pada kolom x0..x1-1 (menimpa kolom itu)."""
        for x in range(x0, x1):
            for y in range(self.H):
                if self.g[y][x] == "#":
                    self.g[y][x] = "."
            self.fill(x, x + 1, self.H - h, self.H, "#")

    def pit(self, x0, x1):
        self.ground(x0, x1, 0)

    def ceil(self, x0, x1, rows):
        """Atap/dinding atas: baris 0..rows-1."""
        self.fill(x0, x1, 0, rows, "#")

    def row_on(self, h):
        """Baris sel tepat di atas tanah setinggi h."""
        return self.H - h - 1

    def on(self, x, h, ch, up=0):
        self.g[self.row_on(h) - up][x] = ch

    def put(self, x, y, ch):
        self.g[y][x] = ch

    def lines(self):
        return ["".join(r) for r in self.g]


def babak1():
    m = Map(152, 24)
    m.ground(0, 152, 4)
    m.ground(0, 1, 24)
    m.ground(151, 152, 24)
    m.on(3, 4, "P")
    m.on(9, 4, "J")
    m.on(14, 4, "Y")
    m.ground(18, 44, 6)
    # Prajurit dan gerbang keraton: hanya terbuka bagi pemakai mahkota.
    m.on(26, 6, "R")
    m.fill(29, 32, 0, m.row_on(6) - 3, "#")
    for up in range(4):
        m.on(30, 6, "g", up)
    m.on(36, 6, "K")
    # Tembok taman 4 sel: tameng dilepas dan dijadikan pijakan.
    m.ground(44, 47, 10)
    m.ground(47, 101, 6)
    m.on(52, 6, "T")
    # Gudang harta: emas di rak.
    r = m.row_on(6)
    m.fill(64, 67, r - 1, r, "-")
    m.put(65, r - 2, "e")
    m.fill(69, 72, r - 3, r - 2, "-")
    m.put(70, r - 4, "e")
    m.fill(74, 77, r - 2, r - 1, "-")
    m.put(75, r - 3, "e")
    m.on(79, 6, "e")
    m.on(82, 6, "K")
    # Gapura butulan: celah 3 sel, bayangan besar tidak muat.
    m.fill(86, 91, 0, m.row_on(6) - 2, "#")
    m.on(95, 6, "S")
    # Parit duri: lompat dari pijakan ke pijakan, emas menggoda di tengah.
    m.ground(101, 115, 1)
    for x in range(101, 115):
        m.on(x, 1, "X")
    for x0, row in ((103, 18), (107, 17), (111, 18)):
        m.fill(x0, x0 + 2, row, row + 1, "-")
    m.put(108, 15, "e")
    m.ground(115, 151, 6)
    m.on(117, 6, "K")
    # Lorong panah keraton: tunggu panah lewat di dalam ceruk.
    m.fill(120, 143, 0, m.row_on(6) - 4, "#")
    for x0 in (124, 130, 136):
        m.ground(x0, x0 + 2, 4)
    m.on(141, 6, "a")
    m.on(148, 6, "Y")
    m.on(146, 6, "E")
    return m


def babak2():
    m = Map(140, 24)
    m.ground(0, 140, 4)
    m.ground(0, 1, 24)
    m.ground(139, 140, 24)
    m.on(3, 4, "P")
    m.on(7, 4, "p")
    m.on(12, 4, "T")
    m.on(20, 4, "T")
    m.on(23, 4, "K")
    # Lubang umpan: pelita dilempar ke sini, buta mengikuti cahayanya.
    m.ground(28, 31, 1)
    # Jembatan akar di atas jurang, buta tidur di tengahnya.
    m.pit(34, 47)
    m.fill(34, 47, m.H - 4, m.H - 3, "#")
    m.on(37, 4, "z")
    m.on(49, 4, "K")
    # Lorong panah dengan ceruk untuk berlindung.
    for x0 in (57, 63, 69):
        m.ground(x0, x0 + 2, 2)
    m.fill(52, 74, 0, m.row_on(4) - 4, "#")
    m.on(73, 4, "a")
    m.on(77, 4, "K")
    # Papan rapuh: patah bila Bobot 4 ke atas.
    m.pit(80, 87)
    m.fill(80, 87, m.H - 4, m.H - 3, "~")
    m.on(91, 4, "S")
    m.fill(95, 98, 0, m.row_on(4) - 3, "#")
    for up in range(4):
        m.on(96, 4, "G", up)
    m.on(99, 4, "K")
    # Lorong panah kedua: lantai di antara ceruk berupa papan rapuh di atas duri.
    m.fill(103, 126, 0, m.row_on(4) - 4, "#")
    for x0 in (107, 113, 119):
        m.ground(x0, x0 + 2, 2)
    for x0 in (110, 116):
        m.ground(x0, x0 + 2, 1)
        m.on(x0, 1, "X")
        m.on(x0 + 1, 1, "X")
        m.fill(x0, x0 + 2, m.H - 4, m.H - 3, "~")
    m.on(114, 2, "e")
    m.on(123, 4, "a")
    m.on(129, 4, "K")
    m.on(133, 4, "T")
    m.on(136, 4, "E")
    return m


def babak3():
    m = Map(110, 26)
    m.ground(0, 110, 4)
    m.ground(0, 1, 26)
    m.ground(109, 110, 26)
    m.on(3, 4, "P")
    m.on(6, 4, "T")
    m.on(9, 4, "s")
    for x in list(range(14, 17)) + list(range(18, 21)):
        m.on(x, 4, "^")
    m.on(23, 4, "K")
    # Jurang lebar dengan angin badai yang bertiup ke kanan.
    m.pit(26, 36)
    m.fill(24, 38, m.row_on(4) - 9, m.row_on(4) + 1, "W")
    m.on(40, 4, "T")
    # Tebing 7 sel: selendang diikat di dahan lalu dipanjat.
    m.ground(47, 109, 11)
    m.on(47, 11, "D")
    m.on(50, 11, "K")
    m.on(56, 11, "S")
    m.on(60, 11, "T")
    # Puncak badai: jurang duri yang hanya terlompati saat angin bertiup.
    for x0 in (68, 78, 88):
        m.ground(x0, x0 + 4, 5)
        for x in range(x0, x0 + 4):
            m.on(x, 5, "X")
    m.fill(64, 94, m.row_on(11) - 8, m.row_on(11) + 1, "W")
    m.on(64, 11, "K")
    m.on(84, 11, "K")
    m.on(98, 11, "T")
    m.on(104, 11, "E")
    return m


def babak4():
    m = Map(170, 24)
    m.ground(0, 170, 4)
    m.ground(0, 1, 24)
    m.ground(169, 170, 24)
    m.on(3, 4, "P")
    m.on(8, 4, "Y")
    m.on(14, 4, "K")
    m.on(22, 4, "C")
    m.ground(26, 28, 5)
    m.pit(34, 36)
    m.ground(42, 52, 6)
    m.on(46, 6, "T")
    m.pit(58, 67)
    m.fill(58, 67, m.H - 4, m.H - 3, "~")
    m.pit(70, 72)
    m.on(75, 4, "K")
    m.ground(80, 84, 5)
    m.ground(90, 96, 6)
    # Lorong rendah: hanya bayangan tipis yang muat, celeng tertahan di mulutnya.
    m.fill(98, 113, 0, m.row_on(4) - 1, "#")
    m.on(114, 4, "c")
    m.on(116, 4, "K")
    m.on(120, 4, "S")
    # Lereng Mamangmurka: duri, tanjakan, dan titian papan rapuh dengan emas.
    for x in (124, 125):
        m.on(x, 4, "^")
    m.ground(128, 131, 6)
    m.ground(131, 134, 8)
    m.ground(134, 143, 1)
    for x in range(134, 143):
        m.on(x, 1, "X")
    m.fill(134, 143, m.H - 8, m.H - 7, "~")
    m.on(138, 8, "e")
    m.ground(143, 150, 8)
    m.on(145, 8, "K")
    for x in (153, 154, 158, 159):
        m.on(x, 4, "^")
    m.on(162, 4, "T")
    m.on(165, 4, "E")
    return m


def babak5():
    """Pendakian Indrakila: ujian terakhir, panjang dan menegangkan.

    Lima bagian: lorong rendah, lereng Kirata, jurang angin dan tebing, titian papan
    di bawah bidikan Kirata, lalu puncak dengan harta sebagai godaan terakhir.
    Setiap Kirata membidik Arjuna; batu menjadi perlindungan dan barang berkilau
    yang dilempar menjadi umpan.
    """
    m = Map(200, 40)
    m.ground(0, 200, 4)
    m.ground(0, 1, 40)
    m.ground(199, 200, 40)
    m.on(3, 4, "P")
    # 1. Kaki gunung: anak tangga, emas penggoda, lorong rendah.
    m.ground(10, 16, 7)
    m.ground(16, 22, 10)
    m.on(18, 10, "T")
    m.on(20, 10, "e")
    m.ground(22, 76, 13)
    m.fill(26, 34, 0, m.row_on(13) - 1, "#")
    # 2. Lereng terbuka di bawah bidikan Kirata pertama, batu sebagai perlindungan.
    for x0 in (39, 46, 53, 60, 67):
        m.ground(x0, x0 + 2, 15)
    m.on(37, 13, "K")
    m.on(58, 13, "K")
    m.ground(73, 76, 16)
    m.ground(76, 90, 19)
    m.on(81, 19, "k")
    # 3. Jurang angin, lalu tebing yang dipanjat dengan selendang.
    m.on(85, 19, "K")
    m.on(87, 19, "s")
    m.pit(90, 100)
    m.fill(88, 102, m.row_on(19) - 9, m.row_on(19) + 1, "W")
    m.ground(100, 106, 19)
    m.ground(106, 129, 27)
    m.on(106, 27, "D")
    # Bibir tebing terbuka: naik saat Kirata kedua selesai melepas panah.
    m.ground(113, 115, 29)
    m.ground(117, 119, 29)
    m.ground(119, 123, 31)
    m.on(120, 31, "j")
    m.on(124, 27, "K")
    m.ground(126, 128, 29)
    # 4. Titian papan rapuh di atas jurang duri, Kirata ketiga di tebing seberang.
    m.ground(128, 159, 18)
    for x in range(128, 159):
        m.on(x, 18, "X")
    m.fill(128, 159, m.H - 27, m.H - 26, "~")
    for x0 in (134, 142, 150):
        m.ground(x0, x0 + 2, 29)
    m.on(139, 27, "e")
    m.on(147, 27, "e")
    m.ground(159, 166, 27)
    m.ground(161, 163, 29)
    m.on(165, 27, "K")
    m.ground(166, 170, 30)
    m.ground(170, 199, 33)
    m.on(175, 33, "k")
    # 5. Puncak: harta sebagai godaan terakhir, lalu sesaji.
    m.on(178, 33, "K")
    m.on(182, 33, "T")
    m.on(186, 33, "H")
    m.on(193, 33, "F")
    return m


BABAK = [babak1, babak2, babak3, babak4, babak5]


def main():
    here = os.path.dirname(os.path.abspath(__file__))
    out = os.path.join(here, "..", "scripts", "core", "babak_maps.gd")
    parts = [
        "class_name BabakMaps",
        "## Dibuat otomatis oleh tools/babak.py. Jangan diedit langsung; ubah skripnya lalu jalankan lagi.",
        "",
        "const MAPS := [",
    ]
    for fn in BABAK:
        m = fn()
        parts.append("\t[")
        for line in m.lines():
            parts.append('\t\t"%s",' % line)
        parts.append("\t],")
    parts.append("]")
    parts.append("")
    with open(out, "w") as f:
        f.write("\n".join(parts))
    for i, fn in enumerate(BABAK):
        m = fn()
        print("babak %d: %dx%d" % (i + 1, m.W, m.H))


if __name__ == "__main__":
    main()
