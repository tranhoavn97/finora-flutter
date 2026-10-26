import os
import math
import random
from PIL import Image, ImageDraw, ImageFilter

OUTPUT_DIR = r"d:\FINORA-\flutter\assets\gems"
os.makedirs(OUTPUT_DIR, exist_ok=True)

WIDTH = 1200
HEIGHT = 600

# 12 Gem Theme Definitions:
# (filename, bg_colors, facet_color, flare_color, secondary_accent, gem_type)
GEMS = [
    {
        "name": "diamond.png",
        "bg": [(10, 20, 38), (18, 38, 68), (35, 75, 125)],
        "facets": (160, 225, 255),
        "flares": (240, 250, 255),
        "accent": (56, 189, 248),
        "style": "brilliant"
    },
    {
        "name": "ruby.png",
        "bg": [(35, 5, 15), (75, 10, 30), (145, 18, 55)],
        "facets": (255, 110, 150),
        "flares": (255, 220, 235),
        "accent": (225, 29, 72),
        "style": "oval"
    },
    {
        "name": "emerald.png",
        "bg": [(4, 25, 18), (8, 55, 40), (16, 95, 68)],
        "facets": (110, 245, 180),
        "flares": (220, 255, 235),
        "accent": (16, 185, 129),
        "style": "emerald_cut"
    },
    {
        "name": "sapphire.png",
        "bg": [(5, 18, 45), (10, 35, 85), (20, 65, 150)],
        "facets": (120, 190, 255),
        "flares": (225, 245, 255),
        "accent": (2, 132, 199),
        "style": "cushion"
    },
    {
        "name": "gold.png",
        "bg": [(45, 25, 5), (95, 55, 10), (170, 105, 20)],
        "facets": (255, 225, 120),
        "flares": (255, 250, 210),
        "accent": (245, 158, 11),
        "style": "bar"
    },
    {
        "name": "platinum.png",
        "bg": [(18, 22, 32), (35, 42, 58), (70, 82, 110)],
        "facets": (215, 228, 245),
        "flares": (250, 252, 255),
        "accent": (148, 163, 184),
        "style": "laser"
    },
    {
        "name": "jade.png",
        "bg": [(6, 28, 22), (12, 60, 48), (22, 105, 82)],
        "facets": (130, 230, 190),
        "flares": (230, 255, 245),
        "accent": (52, 211, 153),
        "style": "cabochon"
    },
    {
        "name": "amethyst.png",
        "bg": [(28, 10, 45), (60, 20, 95), (115, 38, 175)],
        "facets": (220, 150, 255),
        "flares": (250, 230, 255),
        "accent": (168, 85, 247),
        "style": "cluster"
    },
    {
        "name": "amber.png",
        "bg": [(40, 18, 5), (85, 38, 10), (160, 75, 20)],
        "facets": (255, 190, 90),
        "flares": (255, 240, 190),
        "accent": (234, 88, 12),
        "style": "teardrop"
    },
    {
        "name": "tiger_eye.png",
        "bg": [(32, 18, 8), (70, 40, 16), (135, 78, 28)],
        "facets": (240, 185, 95),
        "flares": (255, 235, 185),
        "accent": (180, 83, 9),
        "style": "silk_band"
    },
    {
        "name": "black_pearl.png",
        "bg": [(12, 16, 24), (24, 32, 46), (48, 62, 85)],
        "facets": (170, 190, 215),
        "flares": (235, 245, 255),
        "accent": (100, 116, 139),
        "style": "pearl"
    },
    {
        "name": "sunstone.png",
        "bg": [(48, 15, 5), (105, 32, 10), (195, 62, 18)],
        "facets": (255, 175, 100),
        "flares": (255, 245, 210),
        "accent": (255, 106, 0),
        "style": "solar_flare"
    },
]

def draw_star_flare(draw, cx, cy, radius, color, alpha=255):
    # Cross flare
    for i in range(4):
        angle = i * (math.pi / 2)
        x1 = cx + math.cos(angle) * radius
        y1 = cy + math.sin(angle) * radius
        x2 = cx - math.cos(angle) * radius
        y2 = cy - math.sin(angle) * radius
        draw.line([(x2, y2), (x1, y1)], fill=color + (int(alpha * 0.75),), width=2)
    # 45 deg smaller cross
    for i in range(4):
        angle = i * (math.pi / 2) + math.pi / 4
        x1 = cx + math.cos(angle) * (radius * 0.5)
        y1 = cy + math.sin(angle) * (radius * 0.5)
        x2 = cx - math.cos(angle) * (radius * 0.5)
        y2 = cy - math.sin(angle) * (radius * 0.5)
        draw.line([(x2, y2), (x1, y1)], fill=color + (int(alpha * 0.4),), width=1)
    # Core circle
    core_r = max(2, int(radius * 0.15))
    draw.ellipse([cx - core_r, cy - core_r, cx + core_r, cy + core_r], fill=(255, 255, 255, alpha))

def generate_gem_image(gem):
    img = Image.new("RGBA", (WIDTH, HEIGHT), (0, 0, 0, 255))
    draw = ImageDraw.Draw(img, "RGBA")

    # 1. Base gradient
    c0, c1, c2 = gem["bg"]
    for y in range(HEIGHT):
        ratio = y / HEIGHT
        if ratio < 0.5:
            t = ratio * 2
            r = int(c0[0] * (1 - t) + c1[0] * t)
            g = int(c0[1] * (1 - t) + c1[1] * t)
            b = int(c0[2] * (1 - t) + c1[2] * t)
        else:
            t = (ratio - 0.5) * 2
            r = int(c1[0] * (1 - t) + c2[0] * t)
            g = int(c1[1] * (1 - t) + c2[1] * t)
            b = int(c1[2] * (1 - t) + c2[2] * t)
        draw.line([(0, y), (WIDTH, y)], fill=(r, g, b, 255))

    # 2. Glowing atmospheric orbs
    glow_layer = Image.new("RGBA", (WIDTH, HEIGHT), (0, 0, 0, 0))
    glow_draw = ImageDraw.Draw(glow_layer, "RGBA")
    ac = gem["accent"]
    # Large right orb (focus area for card)
    rx, ry = 950, 240
    for r in range(260, 20, -15):
        alpha = int(45 * (1 - r / 260))
        glow_draw.ellipse([rx - r, ry - r, rx + r, ry + r], fill=ac + (alpha,))

    # Small top-left accent orb
    lx, ly = 220, 160
    for r in range(180, 20, -12):
        alpha = int(35 * (1 - r / 180))
        glow_draw.ellipse([lx - r, ly - r, lx + r, ly + r], fill=gem["facets"] + (alpha,))

    # Caustic diagonal sweep
    for i in range(12):
        x_start = 650 + i * 25
        glow_draw.line([(x_start, -50), (x_start + 450, HEIGHT + 50)], fill=gem["flares"] + (14,), width=16)

    img = Image.alpha_composite(img, glow_layer)

    # 3. Facet Geometry Layer
    geom_layer = Image.new("RGBA", (WIDTH, HEIGHT), (0, 0, 0, 0))
    geom_draw = ImageDraw.Draw(geom_layer, "RGBA")
    fc = gem["facets"]
    gx, gy = 930, 250  # Center for gemstone art

    random.seed(gem["name"])

    # Draw specific gemstone facet styles
    style = gem["style"]
    if style == "brilliant":
        # Classic Round Brilliant Diamond facets
        radii = [170, 120, 60]
        points_outer = []
        for i in range(16):
            ang = i * (math.pi * 2 / 16)
            points_outer.append((gx + math.cos(ang) * radii[0], gy + math.sin(ang) * (radii[0] * 0.72)))
        points_mid = []
        for i in range(16):
            ang = (i + 0.5) * (math.pi * 2 / 16)
            points_mid.append((gx + math.cos(ang) * radii[1], gy + math.sin(ang) * (radii[1] * 0.72)))
        points_table = []
        for i in range(8):
            ang = i * (math.pi * 2 / 8)
            points_table.append((gx + math.cos(ang) * radii[2], gy + math.sin(ang) * (radii[2] * 0.72)))

        # Fill table facet
        geom_draw.polygon(points_table, fill=fc + (70,), outline=gem["flares"] + (180,))
        # Facet connections
        for i in range(16):
            geom_draw.polygon([points_outer[i], points_outer[(i + 1) % 16], points_mid[i]], fill=fc + (35 if i % 2 == 0 else 55,), outline=gem["flares"] + (120,))
            if i % 2 == 0:
                t_idx = (i // 2) % 8
                geom_draw.polygon([points_mid[i], points_mid[(i + 1) % 16], points_table[t_idx]], fill=fc + (45,), outline=gem["flares"] + (110,))

    elif style == "emerald_cut":
        # Stepped Rectangle Octagon
        w, h = 240, 170
        cut = 45
        for s, al in [(1.0, 75), (0.78, 55), (0.55, 90), (0.32, 120)]:
            sw, sh, sc = int(w * s), int(h * s), int(cut * s)
            poly = [
                (gx - sw + sc, gy - sh), (gx + sw - sc, gy - sh),
                (gx + sw, gy - sh + sc), (gx + sw, gy + sh - sc),
                (gx + sw - sc, gy + sh), (gx - sw + sc, gy + sh),
                (gx - sw, gy + sh - sc), (gx - sw, gy - sh + sc)
            ]
            geom_draw.polygon(poly, fill=fc + (int(al * 0.45),), outline=gem["flares"] + (al + 60,))
        # Corner bevel lines
        geom_draw.line([(gx - w + cut, gy - h), (gx - int(w * 0.32) + int(cut * 0.32), gy - int(h * 0.32))], fill=gem["flares"] + (180,), width=2)
        geom_draw.line([(gx + w - cut, gy - h), (gx + int(w * 0.32) - int(cut * 0.32), gy - int(h * 0.32))], fill=gem["flares"] + (180,), width=2)
        geom_draw.line([(gx + w - cut, gy + h), (gx + int(w * 0.32) - int(cut * 0.32), gy + int(h * 0.32))], fill=gem["flares"] + (180,), width=2)
        geom_draw.line([(gx - w + cut, gy + h), (gx - int(w * 0.32) + int(cut * 0.32), gy + int(h * 0.32))], fill=gem["flares"] + (180,), width=2)

    elif style == "bar":
        # 24K Gold Bars isometric 3D ingots
        for offset_x, offset_y, scale in [(-70, 40, 0.9), (40, -10, 1.05)]:
            bx, by = gx + offset_x, gy + offset_y
            bw, bh = int(140 * scale), int(65 * scale)
            # Top face
            top_face = [(bx - bw, by), (bx - bw + 45, by - 38), (bx + bw + 20, by - 38), (bx + bw - 25, by)]
            geom_draw.polygon(top_face, fill=gem["flares"] + (160,), outline=(255, 255, 255, 220))
            # Front face
            front_face = [(bx - bw, by), (bx + bw - 25, by), (bx + bw - 45, by + bh), (bx - bw + 20, by + bh)]
            geom_draw.polygon(front_face, fill=fc + (120,), outline=(255, 235, 150, 180))
            # Side face
            side_face = [(bx + bw - 25, by), (bx + bw + 20, by - 38), (bx + bw, by - 38 + bh), (bx + bw - 45, by + bh)]
            geom_draw.polygon(side_face, fill=fc + (80,), outline=(255, 235, 150, 160))

    else:
        # Luxury Crystal Facet Polyhedra (Cushion, Oval, Cluster, Cabochon, Silk, Pearl, Solar)
        points = []
        n_sides = 12
        rw, rh = 180, 130
        for i in range(n_sides):
            ang = i * (math.pi * 2 / n_sides)
            jitter = random.uniform(0.92, 1.08)
            px = gx + math.cos(ang) * rw * jitter
            py = gy + math.sin(ang) * rh * jitter
            points.append((px, py))
        
        # Center inner ring
        inner_points = []
        for i in range(n_sides):
            ang = i * (math.pi * 2 / n_sides) + (math.pi / n_sides)
            px = gx + math.cos(ang) * (rw * 0.55)
            py = gy + math.sin(ang) * (rh * 0.55)
            inner_points.append((px, py))

        # Center table
        table_points = []
        for i in range(6):
            ang = i * (math.pi * 2 / 6)
            table_points.append((gx + math.cos(ang) * (rw * 0.28), gy + math.sin(ang) * (rh * 0.28)))

        geom_draw.polygon(table_points, fill=fc + (80,), outline=gem["flares"] + (210,))
        for i in range(n_sides):
            p1 = points[i]
            p2 = points[(i + 1) % n_sides]
            p_in = inner_points[i]
            geom_draw.polygon([p1, p2, p_in], fill=fc + (35 if i % 2 == 0 else 60,), outline=gem["flares"] + (130,))
            geom_draw.line([p_in, table_points[i % 6]], fill=gem["flares"] + (110,), width=1)

    # 4. Light Flares & Sparkles
    flare_coords = [
        (gx - 110, gy - 80, 36),
        (gx + 130, gy - 50, 48),
        (gx + 40, gy + 90, 30),
        (gx - 70, gy + 75, 25),
        (gx + 160, gy + 45, 22),
        (gx - 170, gy - 15, 26),
        (350, 180, 28),
        (480, 380, 20),
        (200, 420, 18),
        (150, 140, 22),
    ]
    for fx, fy, fr in flare_coords:
        draw_star_flare(geom_draw, fx, fy, fr, gem["flares"], alpha=220)

    # 5. Fine stardust / crystal dust points
    for _ in range(70):
        sx = random.randint(80, WIDTH - 80)
        sy = random.randint(40, HEIGHT - 40)
        sr = random.choice([1, 1, 2, 2, 3])
        geom_draw.ellipse([sx - sr, sy - sr, sx + sr, sy + sr], fill=(255, 255, 255, random.randint(120, 240)))

    # Composite & slight soft blur glow
    glow_geom = geom_layer.filter(ImageFilter.GaussianBlur(3))
    img = Image.alpha_composite(img, glow_geom)
    img = Image.alpha_composite(img, geom_layer)

    # Save PNG
    out_path = os.path.join(OUTPUT_DIR, gem["name"])
    img.convert("RGB").save(out_path, "PNG", quality=95, optimize=True)
    size_kb = os.path.getsize(out_path) // 1024
    print(f"Generated {gem['name']} -> {size_kb} KB")

for g in GEMS:
    generate_gem_image(g)
print("ALL 12 GEM IMAGES GENERATED SUCCESSFULLY!")
