"""DriftLands procedural pixel-art generator.

Draws every sprite/tile from shape primitives, then auto-outlines in ink for a
clean hand-pixelled look. Animation frames are parametric (bob, flap, lunge),
so the art and the motion come from the same source. No external assets, no
PIL — a tiny built-in PNG writer keeps it dependency-free.

Run:  python tools/gen_assets.py
Out:  assets/sprites/*.png  + assets/sprites/sprites.json  + a review contact sheet
"""
import os
import json
import zlib
import struct

OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "sprites")
os.makedirs(OUT, exist_ok=True)

# ---- Ruined-keep palette (matches src/core/palette.gd) --------------------
PAL = {
    "ink": "16140f", "stone_d": "221f18", "stone": "3a3527", "stone_l": "574f3b",
    "bone": "d8c9a3", "bone_l": "efe4c8", "moss_d": "2c3f25", "moss": "5d7d3a",
    "leaf": "9bb24c", "rust_d": "5e2a1b", "rust": "9c4527", "ember": "d6743a",
    "gold": "e7b24c", "blood": "aa3a30", "teal": "2f6f6a", "frost": "8fb3ad",
}
INK = (0x16, 0x14, 0x0f, 255)


def hexc(h):
    if isinstance(h, tuple):
        return h if len(h) == 4 else (h[0], h[1], h[2], 255)
    h = PAL.get(h, h)
    return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16), 255)


# ---- minimal PNG writer ----------------------------------------------------
def write_png(path, w, h, px):
    def chunk(typ, data):
        return (struct.pack(">I", len(data)) + typ + data
                + struct.pack(">I", zlib.crc32(typ + data) & 0xffffffff))
    raw = bytearray()
    for y in range(h):
        raw.append(0)
        raw += px[y * w * 4:(y + 1) * w * 4]
    with open(path, "wb") as f:
        f.write(b"\x89PNG\r\n\x1a\n")
        f.write(chunk(b"IHDR", struct.pack(">IIBBBBB", w, h, 8, 6, 0, 0, 0)))
        f.write(chunk(b"IDAT", zlib.compress(bytes(raw), 9)))
        f.write(chunk(b"IEND", b""))


class Img:
    def __init__(self, w, h):
        self.w, self.h = w, h
        self.px = bytearray(w * h * 4)

    def set(self, x, y, c):
        x, y = int(x), int(y)
        if 0 <= x < self.w and 0 <= y < self.h:
            c = hexc(c)
            i = (y * self.w + x) * 4
            self.px[i:i + 4] = bytes(c)

    def get_a(self, x, y):
        if 0 <= x < self.w and 0 <= y < self.h:
            return self.px[(y * self.w + x) * 4 + 3]
        return 0

    def rect(self, x, y, w, h, c):
        for yy in range(int(y), int(y + h)):
            for xx in range(int(x), int(x + w)):
                self.set(xx, yy, c)

    def ellipse(self, cx, cy, rx, ry, c):
        if rx <= 0 or ry <= 0:
            return
        for y in range(self.h):
            for x in range(self.w):
                if ((x + 0.5 - cx) / rx) ** 2 + ((y + 0.5 - cy) / ry) ** 2 <= 1.0:
                    self.set(x, y, c)

    def vline(self, x, y0, y1, c):
        for y in range(int(y0), int(y1) + 1):
            self.set(x, y, c)

    def hline(self, x0, x1, y, c):
        for x in range(int(x0), int(x1) + 1):
            self.set(x, y, c)

    def outline(self, col=INK):
        src = bytes(self.px)
        for y in range(self.h):
            for x in range(self.w):
                if src[(y * self.w + x) * 4 + 3] != 0:
                    continue
                near = False
                for dy in (-1, 0, 1):
                    for dx in (-1, 0, 1):
                        if dx == 0 and dy == 0:
                            continue
                        nx, ny = x + dx, y + dy
                        if 0 <= nx < self.w and 0 <= ny < self.h:
                            if src[(ny * self.w + nx) * 4 + 3] != 0:
                                near = True
                if near:
                    self.set(x, y, col)

    def blit(self, src, dx, dy):
        for y in range(src.h):
            for x in range(src.w):
                i = (y * src.w + x) * 4
                if src.px[i + 3] != 0:
                    self.set(dx + x, dy + y, (src.px[i], src.px[i + 1], src.px[i + 2], src.px[i + 3]))

    def scaled(self, k):
        out = Img(self.w * k, self.h * k)
        for y in range(self.h):
            for x in range(self.w):
                i = (y * self.w + x) * 4
                c = (self.px[i], self.px[i + 1], self.px[i + 2], self.px[i + 3])
                if c[3]:
                    out.rect(x * k, y * k, k, k, c)
        return out

    def save(self, name):
        write_png(os.path.join(OUT, name), self.w, self.h, bytes(self.px))


def sheet(frames):
    fw, fh = frames[0].w, frames[0].h
    s = Img(fw * len(frames), fh)
    for i, fr in enumerate(frames):
        s.blit(fr, i * fw, 0)
    return s


# ---- Actors ----------------------------------------------------------------
def player_frame(bob=0, step=0, attack=0, hurt=False):
    im = Img(16, 16)
    body = "blood" if hurt else "stone"
    y = 1 + bob
    # cloak body
    im.ellipse(8, 11 + bob, 4.2, 4.6, body)
    im.rect(4, 11 + bob, 8, 4, body)
    # lighter cloak front + trim
    im.ellipse(8, 12 + bob, 3.0, 3.4, "stone_l" if not hurt else "blood")
    im.hline(5, 10, 14 + bob, "moss_d")
    # hood
    im.ellipse(8, 5 + y, 3.4, 3.4, "stone_d")
    im.ellipse(8, 4 + y, 3.0, 2.6, "stone")
    # face
    im.rect(6, 5 + y, 4, 3, "bone")
    im.set(7, 6 + y, "ember")  # eye glow
    im.set(9, 6 + y, "ember")
    im.rect(6, 7 + y, 4, 1, "stone_d")  # hood shadow
    # feet (alternate by step)
    im.rect(5 + step, 15 + bob, 2, 1, "stone_d")
    im.rect(9 - step, 15 + bob, 2, 1, "stone_d")
    im.outline()
    # weapon (drawn after outline so blade stays bright)
    if attack:  # thrust to the right
        im.vline(13, 6 + y, 11 + bob, "bone_l")
        im.set(14, 6 + y, "bone_l")
        im.set(13, 5 + y, "frost")
    else:
        im.vline(12, 7 + y, 12 + bob, "bone")
        im.set(12, 6 + y, "bone_l")
    return im


def slime_frame(squash=0, hit=False):
    im = Img(16, 16)
    col = "blood" if hit else "moss"
    h = 4.5 - squash
    cy = 12 + squash
    im.ellipse(8, cy, 5.0 + squash * 0.6, h, "moss_d")
    im.ellipse(8, cy, 4.2 + squash * 0.6, h - 0.6, col)
    im.ellipse(8, cy - 1, 2.6, 1.8, "leaf")  # top sheen
    im.outline()
    im.set(6, cy, "ink")  # eyes
    im.set(10, cy, "ink")
    im.set(6, cy - 1, "bone_l")
    im.set(10, cy - 1, "bone_l")
    im.hline(6, 9, cy + 2, "moss_d")  # mouth
    return im


def bat_frame(flap=0):
    im = Img(16, 16)
    # wings (angle by flap)
    for s in (-1, 1):
        wx = 8 + s * 3
        im.ellipse(8 + s * 5, 7 - flap, 3.4, 1.6 + flap * 0.3, "stone_d")
        im.set(8 + s * 7, 7 - flap, "stone")
    im.ellipse(8, 8, 2.4, 2.6, "stone")        # body
    im.ellipse(8, 7, 1.8, 1.6, "stone_l")
    im.rect(6, 4, 2, 2, "stone_d")             # ears
    im.rect(8, 4, 2, 2, "stone_d")
    im.outline()
    im.set(7, 8, "blood")
    im.set(9, 8, "blood")
    return im


def skeleton_frame(step=0, attack=0):
    im = Img(16, 16)
    # legs
    im.rect(6 + step, 12, 2, 3, "bone")
    im.rect(9 - step, 12, 2, 3, "bone")
    # pelvis + ribs
    im.rect(5, 8, 6, 4, "bone")
    im.set(6, 9, "stone_d")
    im.set(8, 9, "stone_d")
    im.set(10, 9, "stone_d")
    im.set(6, 11, "stone_d")
    im.set(8, 11, "stone_d")
    im.set(10, 11, "stone_d")
    # skull
    im.ellipse(8, 5, 3, 3, "bone_l")
    im.outline()
    im.set(6, 5, "ink")  # eye sockets
    im.set(9, 5, "ink")
    im.set(6, 5, "ember")
    im.set(9, 5, "ember")
    im.hline(6, 9, 7, "ink")
    # bone weapon
    if attack:
        im.vline(13, 4, 9, "bone")
        im.set(12, 4, "bone_l")
    else:
        im.vline(12, 6, 11, "bone")
    return im


def boss_frame(bob=0, attack=0, hurt=False):
    im = Img(32, 32)
    base = "blood" if hurt else "rust_d"
    lit = "blood" if hurt else "rust"
    y = bob
    # hulking body
    im.ellipse(16, 20 + y, 9, 8, base)
    im.ellipse(16, 19 + y, 7.5, 6.5, lit)
    im.rect(7, 20 + y, 18, 7, base)
    # arms
    asw = 3 if attack else 0
    im.ellipse(6 - asw, 18 + y, 3, 4, base)
    im.ellipse(26 + asw, 18 + y, 3, 4, base)
    # cracked-stone shoulders
    im.ellipse(9, 13 + y, 4, 3.4, "stone")
    im.ellipse(23, 13 + y, 4, 3.4, "stone")
    # head/maw
    im.ellipse(16, 12 + y, 5, 4.5, "stone_d")
    im.ellipse(16, 11 + y, 4, 3.2, "stone")
    im.outline()
    # glowing eyes + molten cracks
    im.set(13, 11 + y, "ember")
    im.set(19, 11 + y, "ember")
    im.rect(14, 14 + y, 4, 1, "ember")  # maw
    im.set(16, 22 + y, "ember")
    im.set(13, 19 + y, "gold")
    im.set(20, 24 + y, "gold")
    return im


# ---- Items / pickups / projectiles / fx ------------------------------------
def coin_frame(t):
    im = Img(16, 16)
    rx = [4, 2.4, 0.8, 2.4][t]
    im.ellipse(8, 8, rx, 4.5, "gold")
    if rx > 1.5:
        im.ellipse(8, 7, rx * 0.6, 2.6, "bone_l")
        im.set(8, 8, "ember")
    im.outline()
    return im


def orb_frame(t):
    im = Img(8, 8)
    r = 2.6 + (t % 2) * 0.5
    im.ellipse(4, 4, r, r, "rust")
    im.ellipse(4, 4, r - 1, r - 1, "ember")
    im.set(3, 3, "gold")
    im.outline()
    return im


def icon(kind):
    im = Img(16, 16)
    if kind == "potion_hp" or kind == "potion_xp":
        liquid = "blood" if kind == "potion_hp" else "teal"
        im.rect(6, 3, 4, 2, "stone_l")          # cork
        im.ellipse(8, 10, 4, 4.4, "frost")      # glass
        im.ellipse(8, 11, 3, 3, liquid)
        im.rect(7, 5, 2, 2, "stone_l")          # neck
        im.set(6, 8, "bone_l")
    elif kind == "sword":
        im.vline(8, 2, 10, "bone")
        im.vline(9, 2, 10, "bone_l")
        im.set(8, 2, "frost")
        im.hline(5, 11, 11, "rust")             # guard
        im.vline(8, 12, 13, "stone_l")          # grip
        im.set(8, 14, "gold")                   # pommel
    elif kind == "shield":
        im.ellipse(8, 8, 5, 6, "stone")
        im.ellipse(8, 8, 3.6, 4.6, "stone_l")
        im.set(8, 8, "gold")
        im.vline(8, 4, 12, "moss_d")
    elif kind == "helm":
        im.ellipse(8, 8, 5, 4, "stone_l")
        im.rect(3, 8, 10, 4, "stone")
        im.rect(7, 8, 2, 4, "ink")              # visor slit
        im.rect(5, 8, 1, 4, "ink")
        im.rect(10, 8, 1, 4, "ink")
    elif kind == "ring":
        im.ellipse(8, 9, 4, 4, "gold")
        im.ellipse(8, 9, 2.2, 2.2, (0, 0, 0, 0))
        im.set(8, 5, "teal")
    elif kind == "boots":
        im.rect(5, 4, 4, 7, "rust_d")
        im.rect(5, 11, 8, 3, "rust")
        im.set(6, 5, "ember")
    elif kind == "scroll":
        im.rect(4, 4, 8, 9, "bone")
        im.rect(4, 4, 8, 1, "stone_l")
        im.rect(4, 12, 8, 1, "stone_l")
        im.hline(6, 10, 7, "rust")
        im.hline(6, 9, 9, "rust")
    elif kind == "heart":
        im.ellipse(6, 7, 2.4, 2.4, "blood")
        im.ellipse(10, 7, 2.4, 2.4, "blood")
        im.rect(4, 7, 8, 3, "blood")
        im.ellipse(8, 10, 3.6, 3.4, "blood")
        im.set(6, 6, "ember")
    im.outline()
    return im


def slash_frame(t):
    im = Img(20, 20)
    col = ["bone", "bone_l", "frost"][t]
    import math
    for a in range(-60, 61, 6):
        rad = math.radians(a)
        r = 8 + t
        x = 10 + math.cos(rad) * r
        yy = 10 + math.sin(rad) * r * 0.9
        im.set(x, yy, col)
        im.set(x, yy - 1, col)
    return im


def hit_frame(t):
    im = Img(16, 16)
    import math
    n = 4 + t * 2
    for k in range(n):
        a = math.radians(k * 360 / n + t * 18)
        r = 2 + t * 2.5
        im.set(8 + math.cos(a) * r, 8 + math.sin(a) * r, ["bone_l", "ember", "rust"][t])
    im.set(8, 8, "bone_l")
    return im


def poof_frame(t):
    im = Img(16, 16)
    r = 2 + t * 2
    im.ellipse(8, 9 - t, r, r, ["bone", "stone_l", "stone"][t])
    return im


# ---- Tiles -----------------------------------------------------------------
def tiles_atlas():
    # 7 tiles across, 16px: floor x4, wall, wall_top, stairs
    fr = []
    for v in range(4):
        im = Img(16, 16)
        im.rect(0, 0, 16, 16, "stone_d")
        seed = (v * 2654435761) & 0xffff
        for k in range(7):
            x = (seed >> (k * 2)) % 16
            yy = (seed >> (k * 2 + 1)) % 16
            im.set(x, yy, "stone" if k % 2 else "ink")
        if v == 3:
            im.rect(5, 6, 3, 3, "moss_d")
            im.set(6, 7, "moss")
        fr.append(im)
    wall = Img(16, 16)
    wall.rect(0, 0, 16, 16, "stone")
    wall.rect(0, 0, 16, 3, "stone_l")
    wall.rect(0, 13, 16, 3, "stone_d")
    for k in range(5):
        wall.set((k * 5) % 16, 5 + (k * 3) % 8, "stone_d")
    walltop = Img(16, 16)
    walltop.rect(0, 0, 16, 16, "stone_l")
    walltop.rect(0, 12, 16, 4, "stone")
    stairs = Img(16, 16)
    stairs.rect(0, 0, 16, 16, "stone_d")
    for s in range(4):
        stairs.rect(2, 3 + s * 3, 12 - s, 2, "stone_l")
        stairs.rect(2, 5 + s * 3, 12 - s, 1, "ink")
    stairs.set(8, 2, "gold")
    return sheet(fr + [wall, walltop, stairs])


# ---- Build everything ------------------------------------------------------
def build():
    manifest = {}

    def emit(name, frames, fw, fh, anims):
        sheet(frames).save(name + ".png")
        manifest[name] = {"file": name + ".png", "fw": fw, "fh": fh, "anims": anims}

    emit("player",
         [player_frame(0), player_frame(-1),
          player_frame(0, 1), player_frame(-1, -1),
          player_frame(0, 0, 1), player_frame(-1, 0, 1),
          player_frame(0, 0, 0, True)],
         16, 16,
         {"idle": {"frames": [0, 1], "fps": 3}, "walk": {"frames": [2, 3], "fps": 9},
          "attack": {"frames": [4, 5], "fps": 16}, "hurt": {"frames": [6], "fps": 1}})

    emit("slime",
         [slime_frame(0), slime_frame(1), slime_frame(0), slime_frame(1, True)],
         16, 16,
         {"idle": {"frames": [0, 1], "fps": 3}, "move": {"frames": [0, 1], "fps": 6},
          "hurt": {"frames": [3], "fps": 1}})

    emit("bat",
         [bat_frame(0), bat_frame(2), bat_frame(3), bat_frame(2)],
         16, 16,
         {"fly": {"frames": [0, 1, 2, 3], "fps": 12}, "hurt": {"frames": [1], "fps": 1}})

    emit("skeleton",
         [skeleton_frame(0), skeleton_frame(0, 0), skeleton_frame(1), skeleton_frame(-1),
          skeleton_frame(0, 1), skeleton_frame(1, 1)],
         16, 16,
         {"idle": {"frames": [0, 1], "fps": 2}, "walk": {"frames": [2, 3], "fps": 8},
          "attack": {"frames": [4, 5], "fps": 12}})

    emit("boss",
         [boss_frame(0), boss_frame(-1), boss_frame(0, 1), boss_frame(-1, 1),
          boss_frame(0, 0, True)],
         32, 32,
         {"idle": {"frames": [0, 1], "fps": 2}, "attack": {"frames": [2, 3], "fps": 6},
          "hurt": {"frames": [4], "fps": 1}})

    emit("coin", [coin_frame(i) for i in range(4)], 16, 16,
         {"spin": {"frames": [0, 1, 2, 3], "fps": 10}})
    emit("orb", [orb_frame(0), orb_frame(1)], 8, 8,
         {"spin": {"frames": [0, 1], "fps": 10}})
    emit("slash", [slash_frame(i) for i in range(3)], 20, 20,
         {"play": {"frames": [0, 1, 2], "fps": 22}})
    emit("hit", [hit_frame(i) for i in range(3)], 16, 16,
         {"play": {"frames": [0, 1, 2], "fps": 20}})
    emit("poof", [poof_frame(i) for i in range(3)], 16, 16,
         {"play": {"frames": [0, 1, 2], "fps": 16}})

    items = ["potion_hp", "potion_xp", "sword", "shield", "helm", "ring", "boots", "scroll", "heart"]
    sheet([icon(k) for k in items]).save("items.png")
    manifest["items"] = {"file": "items.png", "fw": 16, "fh": 16,
                         "index": {k: i for i, k in enumerate(items)}}

    tiles_atlas().save("tiles.png")
    manifest["tiles"] = {"file": "tiles.png", "fw": 16, "fh": 16,
                         "index": {"floor0": 0, "floor1": 1, "floor2": 2, "floor3": 3,
                                   "wall": 4, "wall_top": 5, "stairs": 6}}

    with open(os.path.join(OUT, "sprites.json"), "w") as f:
        json.dump(manifest, f, indent=2)

    # review contact sheet (scaled), stacked
    review_names = ["player", "slime", "bat", "skeleton", "boss", "coin",
                    "items", "tiles", "slash", "hit"]
    loaded = []
    for n in review_names:
        # rebuild quickly from saved sheets isn't trivial; re-emit known sheets
        pass
    sheets = {
        "player": sheet([player_frame(0), player_frame(-1), player_frame(0, 1),
                         player_frame(-1, -1), player_frame(0, 0, 1), player_frame(-1, 0, 1),
                         player_frame(0, 0, 0, True)]),
        "slime": sheet([slime_frame(0), slime_frame(1), slime_frame(0), slime_frame(1, True)]),
        "bat": sheet([bat_frame(0), bat_frame(2), bat_frame(3), bat_frame(2)]),
        "skeleton": sheet([skeleton_frame(0), skeleton_frame(0, 0), skeleton_frame(1),
                           skeleton_frame(-1), skeleton_frame(0, 1), skeleton_frame(1, 1)]),
        "boss": sheet([boss_frame(0), boss_frame(-1), boss_frame(0, 1), boss_frame(-1, 1),
                       boss_frame(0, 0, True)]),
        "coin": sheet([coin_frame(i) for i in range(4)]),
        "items": sheet([icon(k) for k in items]),
        "tiles": tiles_atlas(),
        "slash": sheet([slash_frame(i) for i in range(3)]),
        "hit": sheet([hit_frame(i) for i in range(3)]),
    }
    k = 5
    gap = 6
    cw = max(s.w for s in sheets.values()) * k + 8
    ch = sum(s.h * k + gap for s in sheets.values()) + gap
    contact = Img(cw, ch)
    contact.rect(0, 0, cw, ch, "16140f")
    yy = gap
    for name in ["player", "slime", "bat", "skeleton", "boss", "coin", "items", "tiles", "slash", "hit"]:
        sc = sheets[name].scaled(k)
        contact.blit(sc, 4, yy)
        yy += sc.h + gap
    write_png(os.path.join(OUT, "_contact.png"), contact.w, contact.h, bytes(contact.px))

    print("generated", len(manifest), "sheets ->", OUT)
    print("sheets:", ", ".join(sorted(manifest.keys())))


if __name__ == "__main__":
    build()
