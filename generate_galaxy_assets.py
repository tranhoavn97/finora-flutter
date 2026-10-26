import os
import math
import random
from PIL import Image, ImageDraw, ImageFilter

OUTPUT_DIR = r"d:\FINORA-\flutter\assets\galaxies"
os.makedirs(OUTPUT_DIR, exist_ok=True)

WIDTH = 1200
HEIGHT = 600

GALAXIES = [
    {
        "name": "milky_way.png",
        "bg": [(3, 7, 18), (10, 25, 47), (25, 55, 110)],
        "core": (100, 180, 255),
        "nebula": (30, 100, 200),
        "dust": (180, 220, 255),
        "spiral_tilt": 0.42,
    },
    {
        "name": "andromeda.png",
        "bg": [(15, 5, 29), (46, 16, 101), (88, 28, 135)],
        "core": (220, 150, 255),
        "nebula": (140, 50, 210),
        "dust": (240, 200, 255),
        "spiral_tilt": -0.35,
    },
    {
        "name": "black_hole.png",
        "bg": [(18, 6, 2), (45, 16, 5), (85, 32, 10)],
        "core": (255, 180, 60),
        "nebula": (210, 80, 15),
        "dust": (255, 220, 120),
        "spiral_tilt": 0.15,
        "is_black_hole": True,
    },
    {
        "name": "butterfly_nebula.png",
        "bg": [(4, 21, 29), (8, 51, 68), (21, 94, 117)],
        "core": (60, 230, 240),
        "nebula": (10, 140, 170),
        "dust": (180, 250, 255),
        "spiral_tilt": 0.55,
    },
    {
        "name": "supernova.png",
        "bg": [(24, 16, 2), (60, 40, 5), (115, 75, 15)],
        "core": (255, 235, 120),
        "nebula": (210, 150, 20),
        "dust": (255, 250, 190),
        "spiral_tilt": 0.0,
    },
    {
        "name": "horsehead.png",
        "bg": [(28, 4, 10), (76, 5, 25), (136, 19, 55)],
        "core": (255, 100, 140),
        "nebula": (190, 20, 60),
        "dust": (255, 190, 210),
        "spiral_tilt": -0.45,
    },
    {
        "name": "triangulum.png",
        "bg": [(2, 24, 17), (6, 78, 59), (4, 120, 87)],
        "core": (80, 235, 170),
        "nebula": (16, 145, 100),
        "dust": (180, 255, 220),
        "spiral_tilt": 0.38,
    },
    {
        "name": "sombrero.png",
        "bg": [(26, 11, 4), (67, 20, 7), (124, 45, 18)],
        "core": (255, 170, 90),
        "nebula": (200, 90, 25),
        "dust": (255, 215, 160),
        "spiral_tilt": 0.12,
    },
    {
        "name": "cartwheel.png",
        "bg": [(5, 15, 38), (30, 58, 138), (29, 78, 216)],
        "core": (120, 190, 255),
        "nebula": (40, 100, 220),
        "dust": (210, 235, 255),
        "spiral_tilt": -0.28,
    },
    {
        "name": "sunflower.png",
        "bg": [(20, 16, 3), (54, 37, 3), (96, 70, 10)],
        "core": (245, 215, 90),
        "nebula": (180, 135, 20),
        "dust": (255, 240, 160),
        "spiral_tilt": 0.50,
    },
    {
        "name": "deep_space.png",
        "bg": [(9, 13, 20), (15, 23, 42), (30, 41, 59)],
        "core": (180, 205, 235),
        "nebula": (70, 95, 135),
        "dust": (225, 235, 250),
        "spiral_tilt": 0.25,
    },
    {
        "name": "solar_flare.png",
        "bg": [(31, 8, 0), (74, 18, 0), (138, 34, 0)],
        "core": (255, 140, 50),
        "nebula": (230, 60, 10),
        "dust": (255, 200, 140),
        "spiral_tilt": -0.32,
    },
]

def draw_diffraction_spike(draw, cx, cy, radius, color, alpha=255):
    for i in range(4):
        ang = i * (math.pi / 2)
        x1 = cx + math.cos(ang) * radius
        y1 = cy + math.sin(ang) * radius
        x2 = cx - math.cos(ang) * radius
        y2 = cy - math.sin(ang) * radius
        draw.line([(x2, y2), (x1, y1)], fill=color + (int(alpha * 0.65),), width=2)
    # Tiny diagonal accent
    for i in range(4):
        ang = i * (math.pi / 2) + math.pi / 4
        x1 = cx + math.cos(ang) * (radius * 0.45)
        y1 = cy + math.sin(ang) * (radius * 0.45)
        x2 = cx - math.cos(ang) * (radius * 0.45)
        y2 = cy - math.sin(ang) * (radius * 0.45)
        draw.line([(x2, y2), (x1, y1)], fill=color + (int(alpha * 0.35),), width=1)
    # Center core
    cr = max(2, int(radius * 0.16))
    draw.ellipse([cx - cr, cy - cr, cx + cr, cy + cr], fill=(255, 255, 255, alpha))

def generate_galaxy_image(g):
    img = Image.new("RGBA", (WIDTH, HEIGHT), (0, 0, 0, 255))
    draw = ImageDraw.Draw(img, "RGBA")

    # 1. Base gradient
    c0, c1, c2 = g["bg"]
    for y in range(HEIGHT):
        ratio = y / HEIGHT
        if ratio < 0.5:
            t = ratio * 2
            r = int(c0[0] * (1 - t) + c1[0] * t)
            g_val = int(c0[1] * (1 - t) + c1[1] * t)
            b = int(c0[2] * (1 - t) + c1[2] * t)
        else:
            t = (ratio - 0.5) * 2
            r = int(c1[0] * (1 - t) + c2[0] * t)
            g_val = int(c1[1] * (1 - t) + c2[1] * t)
            b = int(c1[2] * (1 - t) + c2[2] * t)
        draw.line([(0, y), (WIDTH, y)], fill=(r, g_val, b, 255))

    # 2. Nebula / Galactic Cloud Layer
    neb_layer = Image.new("RGBA", (WIDTH, HEIGHT), (0, 0, 0, 0))
    neb_draw = ImageDraw.Draw(neb_layer, "RGBA")
    random.seed(g["name"])

    # Galactic Center position (centered or slightly offset, natural)
    cx, cy = 600 + random.randint(-40, 80), 280 + random.randint(-30, 30)

    # Radiant Galactic Core
    core_c = g["core"]
    for r in range(280, 15, -12):
        alpha = int(35 * (1 - r / 280))
        neb_draw.ellipse([cx - r, cy - r, cx + r, cy + r], fill=core_c + (alpha,))

    # Spiral arms / Nebula filament flows sweeping across the canvas
    tilt = g["spiral_tilt"]
    neb_c = g["nebula"]
    dust_c = g["dust"]

    num_filaments = 35
    for f in range(num_filaments):
        ang_start = (f / num_filaments) * math.pi * 2
        arm_len = random.randint(220, 560)
        points = []
        for step in range(35):
            t = step / 35.0
            cur_ang = ang_start + t * math.pi * 1.8 + tilt * t * 2.5
            dist = 30 + t * arm_len
            x = cx + math.cos(cur_ang) * dist * 1.4
            y = cy + math.sin(cur_ang) * dist * 0.65 + t * tilt * 120
            points.append((x, y))

        # Draw glowing gas along filament
        cloud_color = neb_c if f % 2 == 0 else dust_c
        for idx in range(len(points) - 1):
            p1, p2 = points[idx], points[idx + 1]
            stroke_w = int(random.randint(18, 55) * (1 - idx / len(points)))
            if stroke_w > 0:
                neb_draw.line([p1, p2], fill=cloud_color + (random.randint(10, 28),), width=stroke_w)

    # Black hole shadow if applicable
    if g.get("is_black_hole"):
        # Central event horizon pure black circle surrounded by photon ring
        for pr in range(50, 42, -2):
            neb_draw.ellipse([cx - pr, cy - pr, cx + pr, cy + pr], fill=(255, 230, 150, 200))
        neb_draw.ellipse([cx - 42, cy - 42, cx + 42, cy + 42], fill=(0, 0, 0, 255))

    # Blur nebula for realistic soft cosmic gas look
    soft_nebula = neb_layer.filter(ImageFilter.GaussianBlur(18))
    img = Image.alpha_composite(img, soft_nebula)

    # 3. Fine Starfield Layer (Thousands of stars)
    star_layer = Image.new("RGBA", (WIDTH, HEIGHT), (0, 0, 0, 0))
    star_draw = ImageDraw.Draw(star_layer, "RGBA")

    # Background microscopic stars
    for _ in range(450):
        sx = random.randint(10, WIDTH - 10)
        sy = random.randint(10, HEIGHT - 10)
        alpha = random.randint(40, 160)
        star_draw.point((sx, sy), fill=(255, 255, 255, alpha))

    # Bright cluster stars
    for _ in range(120):
        sx = random.randint(20, WIDTH - 20)
        sy = random.randint(20, HEIGHT - 20)
        sr = random.choice([1, 1, 2, 2, 3])
        tint = random.choice([(255, 255, 255), dust_c, core_c])
        star_draw.ellipse([sx - sr, sy - sr, sx + sr, sy + sr], fill=tint + (random.randint(120, 250),))

    # Major hero stars with diffraction spikes distributed across the sky (NO artificial icon)
    major_stars = [
        (cx - 320, cy - 140, 26),
        (cx + 380, cy - 110, 32),
        (cx - 180, cy + 160, 24),
        (cx + 260, cy + 150, 28),
        (180, 240, 22),
        (1020, 340, 20),
        (450, 420, 18),
        (850, 120, 25),
        (cx, cy - 190, 20),
    ]
    for fx, fy, fr in major_stars:
        draw_diffraction_spike(star_draw, fx, fy, fr, dust_c, alpha=230)

    img = Image.alpha_composite(img, star_layer)

    # Save PNG
    out_path = os.path.join(OUTPUT_DIR, g["name"])
    img.convert("RGB").save(out_path, "PNG", quality=95, optimize=True)
    size_kb = os.path.getsize(out_path) // 1024
    print(f"Generated {g['name']} -> {size_kb} KB")

for g in GALAXIES:
    generate_galaxy_image(g)
print("ALL 12 GALAXY BACKGROUND ASSETS GENERATED!")
