"""Mengubah foto wayang museum menjadi PNG transparan untuk assets/wayang/.

Cara pakai:
    python3 tools/siluet.py bahan/arjuna.jpg assets/wayang/arjuna.png
    python3 tools/siluet.py bahan/gunungan.jpg assets/wayang/gunungan.png --tinggi 700
    python3 tools/siluet.py bahan/semar2.jpg assets/wayang/semar.png --potong 0.70,0,1,1

Langkah:
1. Pita hitam di dasar foto (alas pemotretan) dibuang otomatis.
2. Warna latar dibaca dari sudut atas, lalu piksel yang dekat dengan warna latar dijadikan
   transparan. Lubang tatahan ikut tembus cahaya, seperti wayang asli di depan kelir.
3. Hasil dipotong rapat dan diperkecil.

Ini pengolahan gambar biasa (ambang warna), bukan AI generatif. Periksa hasilnya, dan rapikan
dengan GIMP atau Krita bila ada sisa latar.
"""

import argparse
from PIL import Image, ImageFilter


def avg(im, box):
    c = im.crop(box)
    px = [c.getpixel((x, y)) for y in range(c.height) for x in range(c.width)]
    n = len(px)
    return tuple(sum(p[i] for p in px) / n for i in range(3))


def strip_dark_band(im, dark=60, frac=0.6):
    """Buang baris bawah yang sebagian besar hitam (alas)."""
    w, h = im.size
    px = im.load()
    y = h - 1
    while y > h // 3:
        cnt = 0
        for x in range(0, w, 4):
            r, g, b = px[x, y]
            if r + g + b < dark * 3:
                cnt += 1
        if cnt < frac * (w / 4):
            break
        y -= 1
    return im.crop((0, 0, w, y + 1)) if y < h - 1 else im


def trim_rods(mask, frac=0.06):
    """Buang batang kendali (gapit, tuding) yang menjuntai di bawah kaki."""
    w, h = mask.size
    m = mask.load()
    y = h - 1
    while y > h // 2:
        cnt = 0
        for x in range(w):
            if m[x, y] > 0:
                cnt += 1
        if cnt >= max(3, frac * w):
            break
        y -= 1
    return y + 1


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("src")
    ap.add_argument("dst")
    ap.add_argument("--ambang", type=float, default=40.0, help="jarak warna dari latar yang dianggap latar")
    ap.add_argument("--tinggi", type=int, default=512, help="tinggi maksimum hasil")
    ap.add_argument("--potong", default="", help="potong dulu: x0,y0,x1,y1 dalam pecahan 0..1")
    ap.add_argument("--latar", default="", help="paksa warna latar r,g,b")
    ap.add_argument("--tanpa-pita", action="store_true", help="jangan buang pita hitam di dasar")
    ap.add_argument("--dengan-gapit", action="store_true", help="biarkan batang kendali di bawah kaki")
    args = ap.parse_args()

    im = Image.open(args.src).convert("RGB")
    if not args.tanpa_pita:
        im = strip_dark_band(im)
    if args.potong:
        x0, y0, x1, y1 = [float(v) for v in args.potong.split(",")]
        w, h = im.size
        im = im.crop((int(x0 * w), int(y0 * h), int(x1 * w), int(y1 * h)))
    w, h = im.size
    if args.latar:
        bg = tuple(float(v) for v in args.latar.split(","))
    else:
        s = max(4, min(w, h) // 30)
        a = avg(im, (0, 0, s, s))
        b = avg(im, (w - s, 0, w, s))
        bg = tuple((a[i] + b[i]) / 2 for i in range(3))
    src = im.load()
    mask = Image.new("L", (w, h), 0)
    m = mask.load()
    t2 = args.ambang * args.ambang
    for y in range(h):
        for x in range(w):
            r, g, bb = src[x, y]
            d = (r - bg[0]) ** 2 + (g - bg[1]) ** 2 + (bb - bg[2]) ** 2
            if d > t2:
                m[x, y] = 255
    mask = mask.filter(ImageFilter.MedianFilter(3))
    bbox = mask.getbbox()
    if bbox and not args.dengan_gapit:
        sub = mask.crop(bbox)
        bottom = trim_rods(sub)
        bbox = (bbox[0], bbox[1], bbox[2], bbox[1] + bottom)
        mask2 = Image.new("L", mask.size, 0)
        mask2.paste(mask.crop(bbox), (bbox[0], bbox[1]))
        mask = mask2
        bbox = mask.getbbox()
    if bbox is None:
        raise SystemExit("Tidak ada bentuk yang terdeteksi. Coba turunkan --ambang.")
    rgba = im.convert("RGBA")
    rgba.putalpha(mask)
    rgba = rgba.crop(bbox)
    if rgba.height > args.tinggi:
        k = args.tinggi / rgba.height
        rgba = rgba.resize((max(1, int(rgba.width * k)), args.tinggi), Image.LANCZOS)
    rgba.save(args.dst)
    print("%s -> %s (%dx%d), latar %s" % (args.src, args.dst, rgba.width, rgba.height, tuple(int(c) for c in bg)))


if __name__ == "__main__":
    main()
