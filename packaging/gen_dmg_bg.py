#!/usr/bin/env python3
"""PKMonitor animated DMG background — dmgly contract.
Scene: dashed sparkline path app->Applications, bright trace, traveling mini
app icon that drops into the Applications folder, confirmation ring,
breathing glow + drifting specks. Loop 64 frames @ 70ms.
Fine-tuning: lire packaging/dmg-params.json (exporte par tuner.html) s'il existe."""
import json, math, os
from PIL import Image, ImageDraw, ImageFont, ImageFilter

# ---------- params (defauts = design valide ; dmg-params.json surcharge) ----------
P = {
    "canvas": {"w": 676, "h": 500},
    "app": {"x": 180, "y": 170},
    "folder": {"x": 480, "y": 170},
    "accent": "#b9ff31",
    "texts": {
        "title": "PKMonitor",
        "subtitle": "Glissez l'application vers le dossier Applications",
        "caption": "macOS 13+ · Gratuit · Open source",
    },
    "spark": {"dx": 8, "dy": -12},
    "caption_y": 362,
}
_params_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), "dmg-params.json")
if os.path.isfile(_params_path):
    try:
        _over = json.load(open(_params_path))
        for k, v in _over.items():
            if isinstance(v, dict) and isinstance(P.get(k), dict):
                P[k].update(v)
            else:
                P[k] = v
    except Exception as e:
        print("dmg-params.json illisible, defauts conserves:", e)

def _hex_rgb(s):
    s = s.lstrip("#")
    return tuple(int(s[i:i+2], 16) for i in (0, 2, 4))

W, H = P["canvas"]["w"], P["canvas"]["h"]
APP = (P["app"]["x"], P["app"]["y"])
FOLDER = (P["folder"]["x"], P["folder"]["y"])
LIME = _hex_rgb(P["accent"])
LIME_DIM = tuple(int(c * 0.78) for c in LIME)
TRACE_FAINT = tuple(int(c * 0.4) for c in LIME)
INK = (244, 245, 240)
MUTED = (155, 158, 151)
DIM = (111, 106, 97)

N = 64           # frames
DUR = 70         # ms per frame
TRACE_END = 24   # trace complete frame
ICON_START, ICON_END = 8, 34   # travel frames
DROP_END = 44    # drop complete frame
RING_END = 56    # ring complete frame

def font(size, index=1):
    try:
        return ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", size, index=index)
    except Exception:
        return ImageFont.load_default()

# ---------- bases (dark + full glow), blended per frame for breathing ----------
def make_base(glow_strength):
    img = Image.new("RGB", (W, H))
    px = img.load()
    for y in range(H):
        t = y / H
        base = (int(13 + (8 - 13) * t), int(15 + (9 - 15) * t), int(18 + (11 - 18) * t))
        for x in range(W):
            px[x, y] = base
    # soft masks: lime glow top, dim blue bottom-left, faint lime bottom-right
    lime_m = Image.new("L", (W, H), 0)
    blue_m = Image.new("L", (W, H), 0)
    ImageDraw.Draw(lime_m).ellipse([338 - 420, -300, 338 + 420, 140], fill=int(80 * glow_strength[0]))
    ImageDraw.Draw(blue_m).ellipse([-260, 240, 180, 560], fill=int(46 * glow_strength[1]))
    ImageDraw.Draw(lime_m).ellipse([508, 290, 868, 560], fill=int(34 * glow_strength[0]))
    lime_m = lime_m.filter(ImageFilter.GaussianBlur(70))
    blue_m = blue_m.filter(ImageFilter.GaussianBlur(70))
    out = Image.composite(Image.blend(img, Image.new("RGB", (W, H), (96, 138, 24)), 0.5), img, lime_m)
    out = Image.composite(Image.blend(out, Image.new("RGB", (W, H), (30, 52, 110)), 0.45), out, blue_m)
    d = ImageDraw.Draw(out)
    for gy in range(60, H, 44):
        for gx in range(30, W, 44):
            d.point((gx, gy), fill=(26, 28, 26))
    return out

BASE_LOW = make_base((0.55, 0.5))
BASE_HIGH = make_base((1.0, 0.9))

# ---------- overlay: title, subtitle, caption, dashed path, chevrons ----------
def bez(p0, p1, p2, p3, n):
    pts = []
    for i in range(n + 1):
        t = i / n
        mt = 1 - t
        x = mt**3*p0[0] + 3*mt**2*t*p1[0] + 3*mt*t**2*p2[0] + t**3*p3[0]
        y = mt**3*p0[1] + 3*mt**2*t*p1[1] + 3*mt*t**2*p2[1] + t**3*p3[1]
        pts.append((x, y))
    return pts

# elegant S-path: app -> up peak -> trough -> arrive folder (left edge)
# exprime en offsets relatifs a APP (fin ≈ FOLDER.x-38) pour rester draggable
_ax, _ay = APP
PATH = (
    bez((_ax+66, _ay+6), (_ax+108, _ay-50), (_ax+150, _ay-50), (_ax+172, _ay-12), 26) +
    bez((_ax+172, _ay-12), (_ax+192, _ay+20), (_ax+212, _ay+40), (_ax+232, _ay+20), 18) +
    bez((_ax+232, _ay+20), (_ax+244, _ay+8), (_ax+252, _ay+2), (_ax+262, _ay+1), 10)
)
PLEN = len(PATH)

def draw_dashed(d, pts, color, width, dash=11, gap=9, phase=0):
    dist = 0
    prev = pts[0]
    for p in pts[1:]:
        seg = math.hypot(p[0] - prev[0], p[1] - prev[1])
        steps = max(1, int(seg))
        for s in range(steps):
            t = s / steps
            x = prev[0] + (p[0] - prev[0]) * t
            y = prev[1] + (p[1] - prev[1]) * t
            dd = dist + seg * t
            if ((dd + phase) % (dash + gap)) < dash:
                d.point((x, y), fill=color)
                for w in range(1, width):
                    d.point((x, y - w), fill=color)
                    d.point((x, y + w - 1), fill=color)
            dist_local = dd
        dist += seg
        prev = p

def make_overlay():
    ov = Image.new("RGB", (W, H), (0, 0, 0))
    mask = Image.new("L", (W, H), 0)
    d = ImageDraw.Draw(ov)
    f_title = font(34, 1)
    t = P["texts"]["title"]
    tw = d.textlength(t, font=f_title)
    d.text(((W - tw) / 2, 26), t, font=f_title, fill=INK)
    f_sub = font(13.5, 0)
    t2 = P["texts"]["subtitle"]
    tw2 = d.textlength(t2, font=f_sub)
    d.text(((W - tw2) / 2, 68), t2, font=f_sub, fill=MUTED)
    f_cap = font(11, 0)
    cap = P["texts"]["caption"]
    cw = d.textlength(cap, font=f_cap)
    d.text((W - 68 - cw, P["caption_y"]), cap, font=f_cap, fill=DIM)
    # dashed path (faint, always visible) + chevrons near folder
    d2 = ImageDraw.Draw(ov)
    draw_dashed(d2, PATH, TRACE_FAINT, 3)
    ex, ey = PATH[-1]
    for k in range(2):
        ox = ex + 4 + k * 9
        d2.line([(ox, ey - 7), (ox + 6, ey), (ox, ey + 7)], fill=LIME_DIM, width=3)
    # reveal mask: everything except pure black
    mask = ov.convert("L").point(lambda v: 255 if v > 8 else 0)
    return ov, mask

OVERLAY, OVERLAY_MASK = make_overlay()

# ---------- mini app icon ----------
SRC = Image.open(__file__.rsplit("/", 2)[0] + "/packaging/icons/icon.png").convert("RGBA")
def mini_icon(size):
    ic = SRC.resize((size, size), Image.LANCZOS)
    r = int(size * 0.225)
    m = Image.new("L", (size, size), 0)
    ImageDraw.Draw(m).rounded_rectangle([0, 0, size, size], radius=r, fill=255)
    return ic, m

# ---------- bottom brand sparkline ----------
_SPARK_BASE = [
    (60, 340), (95, 340), (88, 302), (118, 304), (146, 338), (188, 338),
    (232, 344), (268, 344), (304, 350), (340, 350), (372, 338), (404, 338),
    (428, 296), (452, 300), (472, 336), (508, 338), (548, 338), (600, 340),
]
SPARK_RAW = [(x + P["spark"]["dx"], y + P["spark"]["dy"]) for x, y in _SPARK_BASE]
def spark_points():
    pts = []
    for i in range(len(SPARK_RAW) - 1):
        x0, y0 = SPARK_RAW[i]; x1, y1 = SPARK_RAW[i + 1]
        steps = max(2, int((x1 - x0) / 4))
        for s in range(steps):
            t = s / steps
            pts.append((x0 + (x1 - x0) * t, y0 + (y1 - y0) * t))
    pts.append(SPARK_RAW[-1])
    return pts
SPARK = spark_points()

# ---------- specks ----------
SPECKS = [(37 * i % W, 90 + (53 * i) % 300, 0.22 + (i % 5) * 0.11, (i % 7) - 3) for i in range(14)]

def path_at(t):
    i = min(PLEN - 1, max(0, int(t * (PLEN - 1))))
    return PATH[i]

def lerp(a, b, t):
    return a + (b - a) * t

def ease(t):
    return 0.5 - math.cos(math.pi * min(1, max(0, t))) / 2

def build_frames():
    raw = []
    for f in range(N):
        breath = 0.5 + 0.5 * math.sin(2 * math.pi * f / N)
        img = Image.blend(BASE_LOW, BASE_HIGH, breath)
        # specks
        d = ImageDraw.Draw(img)
        for (sx, sy, sp, br) in SPECKS:
            x = (sx + f * sp * 2) % W
            alpha = 0.5 + 0.5 * math.sin(2 * math.pi * (f / N) * 2 + sx)
            c = int(38 + 52 * alpha * (br + 1) / 2)
            d.point((x, sy), fill=(c, int(c * 1.25), int(c * 0.35)))
        # static overlay
        img.paste(OVERLAY, (0, 0), OVERLAY_MASK)
        d = ImageDraw.Draw(img)
        # bright trace on path, then afterglow that fades before loop reset
        p = ease(min(1, f / TRACE_END))
        cnt = max(2, int(PLEN * p))
        seg = PATH[:cnt]
        d.line(seg, fill=(70, 100, 16), width=10, joint="curve")
        if f <= TRACE_END:
            line_col = LIME
        else:
            fade = max(0, (f - (N - 9)) / 8)
            line_col = tuple(int(lerp(a, b, fade)) for a, b in zip(LIME_DIM, TRACE_FAINT))
        d.line(seg, fill=line_col, width=4, joint="curve")
        if f <= TRACE_END and p < 1:
            tx, ty = seg[-1]
            d.ellipse([tx - 4, ty - 4, tx + 4, ty + 4], fill=LIME)
        # traveling icon
        if ICON_START <= f < ICON_END:
            t = ease((f - ICON_START) / (ICON_END - ICON_START))
            x, y = path_at(t)
            size = 52
            ic, m = mini_icon(size)
            bob = math.sin(f * 0.8) * 2
            img.paste(ic, (int(x - size / 2), int(y - size / 2 + bob)), m)
            d = ImageDraw.Draw(img)
            # small trail
            tx, ty = path_at(max(0, t - 0.07))
            d.ellipse([tx - 3, ty - 3, tx + 3, ty + 3], fill=LIME_DIM)
        # drop into folder
        elif ICON_END <= f < DROP_END:
            t = ease((f - ICON_END) / (DROP_END - ICON_END))
            x0, y0 = PATH[-1]
            x = lerp(x0, FOLDER[0], t)
            y = lerp(y0, FOLDER[1], t) + math.sin(t * math.pi) * -14  # slight arc up then in
            size = int(lerp(52, 30, t))
            ic, m = mini_icon(size)
            img.paste(ic, (int(x - size / 2), int(y - size / 2)), m)
        # confirmation ring
        if DROP_END <= f < RING_END:
            t = (f - DROP_END) / (RING_END - DROP_END)
            r = lerp(66, 92, t)
            fade = 1 - t
            col = (int(lerp(60, 185, fade)), int(lerp(90, 255, fade)), int(lerp(14, 49, fade)))
            d.ellipse([FOLDER[0] - r, FOLDER[1] - r, FOLDER[0] + r, FOLDER[1] + r], outline=col, width=3)
            # second smaller ring offset
            r2 = lerp(58, 78, t)
            d.ellipse([FOLDER[0] - r2, FOLDER[1] - r2, FOLDER[0] + r2, FOLDER[1] + r2], outline=TRACE_FAINT, width=2)
        # bottom sparkline traces with the icon travel
        sp_end = ICON_END
        sp = ease(min(1, f / sp_end))
        cnt = max(2, int(len(SPARK) * sp))
        seg = SPARK[:cnt]
        d.line(seg, fill=(60, 90, 14), width=11, joint="curve")
        d.line(seg, fill=INK, width=5, joint="curve")
        if sp < 1:
            tx, ty = seg[-1]
            d.ellipse([tx - 5, ty - 5, tx + 5, ty + 5], fill=LIME)
        raw.append(img)
    # shared palette built from the scene itself -> key colors stay exact
    sample = Image.new("RGB", (W, H * 3))
    for i, pick in enumerate((8, 30, 50)):
        sample.paste(raw[pick], (0, i * H))
    pal = sample.quantize(colors=255, method=Image.MEDIANCUT)
    return [fr.quantize(palette=pal, dither=Image.Dither.NONE) for fr in raw]

if __name__ == "__main__":
    frames = build_frames()
    frames[0].save(
        "/tmp/pkmonitor/dmg-background-final.gif",
        save_all=True, append_images=frames[1:],
        duration=DUR, loop=0, optimize=True,
    )
    import os
    print("GIF", os.path.getsize("/tmp/pkmonitor/dmg-background-final.gif") // 1024, "KB,", len(frames), "frames")
    # previews for probing
    for probe in (0, 16, 30, 38, 48):
        frames[probe].convert("RGB").save(f"/tmp/pkmonitor/v2-frame-{probe}.png")
