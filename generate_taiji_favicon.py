#!/usr/bin/env python3
"""Generate a liquid-metal yin-yang (taiji) favicon.

Approach:
- Draw a crisp taiji symbol at high resolution with smooth antialiasing.
- Apply a metallic "liquid mercury" treatment:
    * gradient fill per droplet (light -> dark chrome)
    * strong specular highlight along the S-curve and on the two eyes
    * subtle rim/ambient shading and a soft drop shadow
- Downscale with LANCZOS into an .ico containing multiple sizes.
"""

from PIL import Image, ImageDraw, ImageFilter
import math

OUT = "/Users/dragon/Code/knowledge-base/wisdomsword.github.io/assets/favicon.ico"
PREVIEW = "/Users/dragon/Code/knowledge-base/wisdomsword.github.io/assets/taiji_preview.png"

# ---- 1. Build a high-res taiji mask (unsigned 8-bit shape) ----
S = 512                         # supersampled size
cx = cy = S / 2
R = S * 0.42                    # outer radius
r = R / 2                       # half-droplet radius
eye = R * 0.16                  # eye radius

img = Image.new("L", (S, S), 0)
drw = ImageDraw.Draw(img)

def in_circle(px, py, xc, yc, rad):
    return (px - xc) ** 2 + (py - yc) ** 2 <= rad ** 2

# Sample at 4x4 per pixel for good antialiasing via supersampling
SS = 4
def sample_shape(px, py):
    """Return coverage in [0,1] that (px,py) lies inside the taiji shape."""
    hits = 0
    total = SS * SS
    for i in range(SS):
        for j in range(SS):
            x = px + (i + 0.5) / SS
            y = py + (j + 0.5) / SS
            # main circle
            if not in_circle(x, y, cx, cy, R):
                continue
            # droplet centers: upper (yang side left) at (cx, cy-r), lower at (cx, cy+r)
            up = in_circle(x, y, cx, cy - r, r)
            lo = in_circle(x, y, cx, cy + r, r)
            in_taiji = up or lo
            if in_taiji:
                # remove the eyes
                if in_circle(x, y, cx, cy - r, eye) or in_circle(x, y, cx, cy + r, eye):
                    continue
            hits += 1
    return hits / total

for py in range(S):
    for px in range(S):
        cov = sample_shape(px, py)
        if cov > 0:
            img.putpixel((px, py), int(255 * cov))

img = img.filter(ImageFilter.GaussianBlur(0.6))

# ---- 2. Build an RGBA canvas ---- 
canvas = Image.new("RGBA", (S, S), (0, 0, 0, 0))
mask = img

# ---- 3. Metallic fill: vertical chrome gradient (light top-left -> darker bottom-right) ----
metal = Image.new("RGBA", (S, S), (0, 0, 0, 0))
md = ImageDraw.Draw(metal)
for y in range(S):
    t = y / (S - 1)
    # chrome gradient: bright near top, a band of high reflection, dark lower
    # base luminance curve for a polished cylinder feel
    lum = 235 - 160 * t                      # overall darken downward
    # specular band ~ upper third
    band = 90 * math.exp(-((t - 0.22) ** 2) / (2 * 0.10 ** 2))
    # dark band at lower-middle (reflection of environment) then slight recover
    env = -60 * math.exp(-((t - 0.72) ** 2) / (2 * 0.12 ** 2))
    v = max(0, min(255, lum + band + env))
    md.line([(0, y), (S, y)], fill=(int(v), int(v), int(v + 6), 255))  # faint blue-tint

# Add a subtle horizontal sheen band
sheen = Image.new("RGBA", (S, S), (0, 0, 0, 0))
sd = ImageDraw.Draw(sheen)
for y in range(S):
    t = y / (S - 1)
    a = int(70 * math.exp(-((t - 0.38) ** 2) / (2 * 0.06 ** 2)))
    sd.line([(0, y), (S, y)], fill=(255, 255, 255, a))

# ---- 4. Specular highlight following the S-curve and droplets ----
highlight = Image.new("RGBA", (S, S), (0, 0, 0, 0))
hd = ImageDraw.Draw(highlight)

# highlight along the S separator curve: two arcs
def draw_arc_highlight():
    # upper droplet arc (left bulge)
    pts = []
    for ang_deg in range(-90, 91, 2):
        a = math.radians(ang_deg)
        x = cx + r * math.cos(a)
        y = (cy - r) + r * math.sin(a)
        pts.append((x, y))
    # lower droplet arc
    for ang_deg in range(90, 271, 2):
        a = math.radians(ang_deg)
        x = cx + r * math.cos(a)
        y = (cy + r) + r * math.sin(a)
        pts.append((x, y))
    return pts

spts = draw_arc_highlight()
if len(spts) > 1:
    tmp = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    td = ImageDraw.Draw(tmp)
    td.line(spts, fill=(255, 255, 255, 255), width=int(R * 0.10), joint="curve")
    tmp = tmp.filter(ImageFilter.GaussianBlur(R * 0.05))
    highlight = Image.alpha_composite(highlight, tmp)

# highlight blobs on droplet crowns (upper-left of upper droplet, upper-right of lower droplet)
def blob(xc, yc, rad, alpha):
    tmp = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    td = ImageDraw.Draw(tmp)
    td.ellipse([xc - rad, yc - rad, xc + rad, yc + rad], fill=(255, 255, 255, alpha))
    tmp = tmp.filter(ImageFilter.GaussianBlur(rad * 0.6))
    return tmp

highlight = Image.alpha_composite(highlight, blob(cx - r * 0.45, cy - r * 1.15, r * 0.62, 160))
highlight = Image.alpha_composite(highlight, blob(cx + r * 0.45, cy + r * 1.15, r * 0.62, 140))

# ---- 5. Eyes: metallic balls with own highlight ----
def metallic_eye(xc, yc, rad):
    base = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    bd = ImageDraw.Draw(base)
    bd.ellipse([xc - rad, yc - rad, xc + rad, yc + rad], fill=(20, 20, 26, 255))
    # radial-ish highlight
    hl = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    hd2 = ImageDraw.Draw(hl)
    hdr = rad * 0.5
    hd2.ellipse([xc - hdr, yc - hdr - rad * 0.3, xc + hdr, yc + hdr - rad * 0.3],
                fill=(235, 240, 255, 220))
    hl = hl.filter(ImageFilter.GaussianBlur(rad * 0.35))
    base = Image.alpha_composite(base, hl)
    return base

eye_up = metallic_eye(cx, cy - r, eye)
eye_lo = metallic_eye(cx, cy + r, eye)

# ---- 6. Compose ----
base_layer = metal
base_layer = Image.alpha_composite(base_layer, sheen)
base_layer = Image.alpha_composite(base_layer, highlight)

droplets = Image.new("RGBA", (S, S), (0, 0, 0, 0))
droplets = Image.alpha_composite(droplets, base_layer)
droplets = Image.alpha_composite(droplets, eye_up)
droplets = Image.alpha_composite(droplets, eye_lo)

# apply taiji silhouette mask (alpha) 
final = Image.new("RGBA", (S, S), (0, 0, 0, 0))
final.paste(droplets, (0, 0), mask)

# ---- 7. Soft drop shadow ----
shadow = Image.new("RGBA", (S, S), (0, 0, 0, 0))
sh = ImageDraw.Draw(shadow)
sh.ellipse([cx - R, cy - R, cx + R, cy + R], fill=(0, 0, 0, 255))
shadow = shadow.filter(ImageFilter.GaussianBlur(R * 0.12))
shadow = Image.new("RGBA", (S, S), (0, 0, 0, 0))
sh = ImageDraw.Draw(shadow)
sh.ellipse([cx - R * 0.98, cy - R * 0.98, cx + R * 0.98, cy + R * 0.98], fill=(0, 0, 0, 90))
shadow = shadow.filter(ImageFilter.GaussianBlur(R * 0.10))
shadow = shadow.crop((0, 0, S, S))
# offset shadow down-right
shadow_off = Image.new("RGBA", (S, S), (0, 0, 0, 0))
shadow_off.alpha_composite(shadow, (int(R*0.06), int(R*0.08)))

# composite
result = Image.new("RGBA", (S, S), (0, 0, 0, 0))
result = Image.alpha_composite(result, shadow_off)
result = Image.alpha_composite(result, final)

# resize to 256 preview
preview = result.resize((256, 256), Image.Resampling.LANCZOS)
preview.save(PREVIEW)
print("preview saved", PREVIEW)

# ---- 8. Save .ico with multiple sizes ----
favicon_sizes = [(16, 16), (32, 32), (48, 48), (64, 64), (128, 128), (256, 256)]
icon_sizes = [result.resize(s, Image.Resampling.LANCZOS) for s in favicon_sizes]
icon_sizes[0].save(
    OUT,
    format="ICO",
    append_images=icon_sizes[1:],
    sizes=favicon_sizes,
)
print("favicon saved", OUT)
