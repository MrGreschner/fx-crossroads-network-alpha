"""Generate the classroom prototype's original, editable 2D pixel art."""
from pathlib import Path
from PIL import Image, ImageDraw

OUT = Path(__file__).resolve().parents[1] / "assets"
OUT.mkdir(exist_ok=True)

def canvas(name, size, painter):
    im = Image.new("RGBA", size, (0, 0, 0, 0))
    painter(ImageDraw.Draw(im))
    im.save(OUT / (name + ".png"))

def ground(name, base, specks):
    def paint(d):
        d.rectangle((0, 0, 31, 31), fill=base)
        for i in range(15):
            x = (i * 19 + 7) % 31
            y = (i * 11 + 3) % 31
            d.rectangle((x, y, x + 1, y + 2), fill=specks[i % len(specks)])
    canvas(name, (32, 32), paint)

ground("grass", "#547a51", ["#71945e", "#476f4a", "#93a965"])
ground("forest", "#42644e", ["#668554", "#385645", "#829a62"])
ground("path", "#ad9267", ["#c1a678", "#927c5d", "#d0b284"])
ground("ash", "#5b555a", ["#786c69", "#47444e", "#a1846d"])

def tree(d):
    d.ellipse((4, 34, 28, 41), fill="#283f3c")
    d.rectangle((13, 25, 18, 36), fill="#76523d")
    d.rectangle((12, 26, 14, 34), fill="#a7794f")
    d.polygon([(4, 27), (11, 5), (22, 5), (29, 27)], fill="#234c46")
    d.polygon([(6, 24), (12, 5), (22, 5), (27, 24)], fill="#39745a")
    d.rectangle((10, 15, 22, 17), fill="#508b63")
    d.rectangle((12, 10, 19, 12), fill="#6ea070")
canvas("tree", (32, 42), tree)

def flower(d):
    d.rectangle((15, 15, 16, 28), fill="#34583e")
    d.rectangle((10, 8, 21, 19), fill="#f1d382")
    d.rectangle((13, 5, 18, 22), fill="#f7e4aa")
    d.rectangle((13, 11, 18, 16), fill="#e78382")
canvas("flower", (32, 32), flower)

def crystal(d):
    d.ellipse((2, 35, 35, 42), fill="#3b3945")
    d.polygon([(4, 36), (9, 10), (16, 5), (20, 35)], fill="#a1748d")
    d.polygon([(16, 37), (22, 4), (31, 12), (34, 37)], fill="#d29b76")
    d.polygon([(23, 13), (27, 10), (28, 32), (20, 33)], fill="#f0c490")
canvas("crystal", (38, 44), crystal)

def merchant(d):
    d.rectangle((4, 20, 43, 38), fill="#65524b")
    d.rectangle((7, 19, 40, 34), fill="#ae8b64")
    d.polygon([(1, 21), (9, 5), (38, 5), (46, 21)], fill="#a65d64")
    d.rectangle((5, 17, 42, 22), fill="#e2af7c")
    d.rectangle((18, 23, 28, 33), fill="#4c4149")
    d.rectangle((21, 25, 26, 31), fill="#e6d19a")
canvas("merchant", (48, 40), merchant)

def house(d):
    d.ellipse((4, 55, 74, 71), fill="#355246")
    d.rectangle((12, 31, 67, 63), fill="#564e47")
    d.rectangle((15, 32, 63, 61), fill="#d5b985")
    d.polygon([(4, 34), (19, 13), (61, 13), (76, 34)], fill="#493d48")
    d.polygon([(9, 32), (21, 17), (58, 17), (70, 32)], fill="#a65855")
    for x in range(17, 67, 14):
        d.line((x, 20, x + 7, 29), fill="#c87865", width=2)
    d.rectangle((32, 40, 47, 62), fill="#654a42")
    d.rectangle((35, 42, 44, 60), fill="#84604b")
    d.rectangle((52, 41, 60, 50), fill="#567d81")
    d.rectangle((53, 42, 59, 46), fill="#a6c6b6")
canvas("house", (80, 72), house)

def warden(d, step=0):
    # Original silhouette: cyan cloak, brass clasp, dark boots, pale face.
    d.ellipse((4, 27, 21, 31), fill="#263f40")
    d.rectangle((6, 23 + step, 10, 28), fill="#343d47")
    d.rectangle((15, 23 - step, 19, 28), fill="#343d47")
    d.polygon([(5, 12), (19, 12), (22, 24), (3, 24)], fill="#284c63")
    d.rectangle((7, 13, 17, 23), fill="#55a5aa")
    d.rectangle((8, 13, 9, 21), fill="#80c3b4")
    d.rectangle((4, 14, 7, 21), fill="#cfab79")
    d.rectangle((18, 14, 21, 21), fill="#cfab79")
    d.rectangle((8, 5, 17, 13), fill="#e3bd8a")
    d.rectangle((7, 3, 18, 8), fill="#344756")
    d.rectangle((9, 8, 10, 9), fill="#283440")
    d.rectangle((15, 8, 16, 9), fill="#283440")
    d.rectangle((12, 15, 13, 17), fill="#efd68b")

for frame in (0, 1):
    canvas("warden_%s" % frame, (24, 32), lambda d, f=frame: warden(d, f))

def ram(d, step=0, elder=False):
    d.ellipse((4, 27, 24, 32), fill="#273e3d")
    d.rectangle((6, 21 + step, 10, 29), fill="#564442")
    d.rectangle((18, 21 - step, 22, 29), fill="#564442")
    d.rectangle((5, 11, 23, 24), fill="#e8d8b2" if elder else "#e9e3cf")
    d.rectangle((7, 12, 19, 23), fill="#f6e8cf" if elder else "#faf0d9")
    d.rectangle((3, 6, 7, 17), fill="#b49a70")
    d.rectangle((21, 6, 25, 17), fill="#b49a70")
    d.rectangle((5, 3, 10, 10), fill="#d4bc89")
    d.rectangle((18, 3, 23, 10), fill="#d4bc89")
    d.rectangle((9, 5, 19, 17), fill="#f8eddb")
    d.rectangle((11, 11, 12, 13), fill="#423c43")
    d.rectangle((17, 11, 18, 13), fill="#423c43")
    d.rectangle((13, 15, 16, 17), fill="#9e7871")
    if elder:
        d.rectangle((8, 18, 20, 24), fill="#e7e8d7")
        d.rectangle((12, 25, 17, 31), fill="#765b43")
        d.rectangle((20, 14, 22, 22), fill="#815e79")
    else:
        d.rectangle((11, 21, 18, 23), fill="#75aa9b")

for frame in (0, 1):
    canvas("ram_%s" % frame, (28, 32), lambda d, f=frame: ram(d, f))
canvas("elder_ram", (28, 32), lambda d: ram(d, elder=True))

def cat(d, step=0):
    d.ellipse((3, 26, 25, 31), fill="#293e43")
    d.arc((17, 11, 34, 28), 260, 90, fill="#c5b5aa", width=3)
    d.rectangle((7, 19 + step, 10, 29), fill="#655868")
    d.rectangle((19, 19 - step, 22, 29), fill="#655868")
    d.ellipse((5, 11, 25, 25), fill="#b5a7a0")
    d.polygon([(5, 13), (7, 3), (13, 10)], fill="#897787")
    d.polygon([(18, 10), (25, 3), (26, 14)], fill="#897787")
    d.polygon([(7, 8), (8, 5), (11, 10)], fill="#e0afa8")
    d.polygon([(21, 10), (24, 5), (24, 12)], fill="#e0afa8")
    d.ellipse((8, 11, 23, 20), fill="#d3c6b7")
    d.rectangle((10, 13, 11, 15), fill="#30464c")
    d.rectangle((19, 13, 20, 15), fill="#30464c")
    d.polygon([(14, 17), (17, 17), (16, 19)], fill="#be7f84")
    d.line((4, 18, 12, 18), fill="#e4d9c7")
    d.line((19, 18, 27, 18), fill="#e4d9c7")
    d.rectangle((10, 21, 19, 23), fill="#519694")
for frame in (0, 1):
    canvas("cat_%s" % frame, (30, 32), lambda d, f=frame: cat(d, f))

def boss(d):
    d.ellipse((3, 34, 46, 47), fill="#273d3a")
    d.rectangle((4, 14, 45, 38), fill="#6d3852")
    d.polygon([(5, 19), (0, 3), (17, 14)], fill="#c77c73")
    d.polygon([(45, 19), (49, 3), (32, 14)], fill="#c77c73")
    d.rectangle((10, 12, 39, 32), fill="#a65b65")
    d.rectangle((12, 16, 19, 21), fill="#fbe4af")
    d.rectangle((30, 16, 37, 21), fill="#fbe4af")
    d.rectangle((15, 18, 18, 20), fill="#41344b")
    d.rectangle((32, 18, 35, 20), fill="#41344b")
    d.rectangle((20, 27, 29, 30), fill="#e9b8a2")
canvas("bramble_boss", (50, 50), boss)

def bottle(d):
    d.rectangle((12, 3, 19, 8), fill="#d7d3bd")
    d.rectangle((10, 8, 21, 27), fill="#8fbec0")
    d.rectangle((12, 12, 19, 25), fill="#d85f78")
    d.rectangle((13, 11, 15, 21), fill="#f0a9a5")
canvas("potion", (32, 32), bottle)

def enemy(d, step=0):
    d.ellipse((2, 18, 25, 26), fill="#28413e")
    d.rectangle((3, 8 + step, 24, 21), fill="#793f50")
    d.rectangle((5, 5 + step, 21, 18), fill="#d67b70")
    d.rectangle((8, 3 + step, 19, 8), fill="#e49b7d")
    d.rectangle((7, 11 + step, 10, 13 + step), fill="#fff1c9")
    d.rectangle((17, 11 + step, 20, 13 + step), fill="#fff1c9")
    d.rectangle((9, 11 + step, 10, 12 + step), fill="#453849")
    d.rectangle((18, 11 + step, 19, 12 + step), fill="#453849")
    d.rectangle((8, 21, 11, 25), fill="#793f50")
    d.rectangle((17, 21, 20, 25), fill="#793f50")
for frame in (0, 1):
    canvas("bramble_%s" % frame, (28, 28), lambda d, f=frame: enemy(d, f))

def archer(d, step=0):
    d.ellipse((3, 20, 25, 27), fill="#2b403f")
    d.rectangle((4, 9 + step, 23, 23), fill="#4f6670")
    d.rectangle((8, 5 + step, 19, 17), fill="#b4b6a0")
    d.rectangle((7, 10 + step, 10, 12 + step), fill="#f7d78e")
    d.rectangle((17, 10 + step, 20, 12 + step), fill="#f7d78e")
    d.line((24, 3, 25, 22), fill="#e1bc8a", width=2)
    d.line((25, 3, 19, 13), fill="#d99e75", width=1)
for frame in (0, 1):
    canvas("archer_%s" % frame, (28, 28), lambda d, f=frame: archer(d, f))

def portal(d):
    d.ellipse((1, 1, 30, 45), fill="#31565b")
    d.ellipse((4, 2, 27, 40), fill="#b5e7b2")
    d.ellipse((7, 5, 24, 36), fill="#508f9b")
    d.ellipse((10, 10, 22, 32), fill="#72c1b6")
    d.rectangle((0, 39, 31, 47), fill="#766758")
    d.rectangle((3, 40, 28, 43), fill="#b8aa80")
canvas("portal", (32, 48), portal)

print("Generated original pixel art in", OUT)

# New classroom characters and enemies.
def basketball(d, step=0):
    d.ellipse((2, 27, 30, 32), fill="#35424a")
    d.rectangle((7, 23 + step, 10, 29), fill="#795345")
    d.rectangle((22, 23 - step, 25, 29), fill="#795345")
    d.ellipse((3, 3 + step, 29, 28 + step), fill="#da884b", outline="#8c4f3c", width=2)
    d.arc((4, 4 + step, 28, 27 + step), 55, 125, fill="#704238", width=2)
    d.arc((4, 4 + step, 28, 27 + step), 235, 305, fill="#704238", width=2)
    d.line((16, 4 + step, 16, 27 + step), fill="#704238", width=2)
    d.line((4, 16 + step, 28, 16 + step), fill="#704238", width=2)
    d.rectangle((10, 11 + step, 11, 13 + step), fill="#fff0c6")
    d.rectangle((21, 11 + step, 22, 13 + step), fill="#fff0c6")
for frame in (0,1):
    canvas('basketball_%s' % frame,(32,32),lambda d,f=frame:basketball(d,f))
canvas('mini_basketball',(20,20),lambda d:(d.ellipse((1,1,18,18),fill='#ed9c52',outline='#713f36',width=2),d.line((10,2,10,17),fill='#713f36',width=1),d.line((2,10,17,10),fill='#713f36',width=1)))

def warlock(d,step=0):
    d.ellipse((2,24,28,31),fill='#323245')
    d.polygon([(3,27),(9,9+step),(22,9+step),(28,27)],fill='#69517b')
    d.polygon([(5,12+step),(14,2+step),(21,4+step),(27,14+step)],fill='#433956')
    d.rectangle((9,11+step,22,19+step),fill='#b5a5a3')
    d.rectangle((10,13+step,13,15+step),fill='#a3daec')
    d.rectangle((19,13+step,22,15+step),fill='#a3daec')
    d.line((26,5,27,24),fill='#bba075',width=2)
    d.ellipse((23,2,29,8),fill='#bca3ea')
for frame in (0,1):
    canvas('warlock_%s' % frame,(32,32),lambda d,f=frame:warlock(d,f))

def imp(d,step=0):
    d.ellipse((3,18,25,27),fill='#413448')
    d.polygon([(2,19),(7,5+step),(15,10+step),(22,4+step),(28,21)],fill='#9b718c')
    d.rectangle((8,15+step,11,17+step),fill='#f6d397')
    d.rectangle((18,15+step,21,17+step),fill='#f6d397')
for frame in (0,1):
    canvas('imp_%s' % frame,(28,28),lambda d,f=frame:imp(d,f))
