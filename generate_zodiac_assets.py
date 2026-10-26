import os
import math
import random
from PIL import Image, ImageDraw, ImageFilter, ImageFont

output_dir = r"d:\FINORA-\flutter\assets\zodiac"
os.makedirs(output_dir, exist_ok=True)

# 12 Zodiac Constellations Data
# Format: id, name, en_name, symbol, element, primary_color, secondary_color, accent_color, star_coords (normalized 0-1)
zodiac_data = [
    {
        "id": "aries",
        "name": "Bạch Dương",
        "symbol": "♈",
        "bg_start": (20, 5, 5),
        "bg_end": (60, 15, 10),
        "nebula": (230, 57, 70),
        "accent": (255, 107, 107),
        # Aries constellation: curved horn line
        "stars": [(0.25, 0.65), (0.45, 0.45), (0.65, 0.35), (0.75, 0.42)],
        "lines": [(0, 1), (1, 2), (2, 3)],
    },
    {
        "id": "taurus",
        "name": "Kim Ngưu",
        "symbol": "♉",
        "bg_start": (5, 25, 15),
        "bg_end": (10, 50, 30),
        "nebula": (32, 201, 151),
        "accent": (52, 211, 153),
        # Taurus V-shape Hyades & Pleiades
        "stars": [(0.20, 0.30), (0.35, 0.50), (0.50, 0.55), (0.65, 0.45), (0.80, 0.25), (0.52, 0.68)],
        "lines": [(0, 1), (1, 2), (2, 3), (3, 4), (2, 5)],
    },
    {
        "id": "gemini",
        "name": "Song Tử",
        "symbol": "♊",
        "bg_start": (25, 18, 5),
        "bg_end": (60, 40, 10),
        "nebula": (245, 158, 11),
        "accent": (251, 191, 36),
        # Gemini twin lines: Castor and Pollux
        "stars": [(0.25, 0.25), (0.32, 0.45), (0.40, 0.68), (0.60, 0.22), (0.68, 0.42), (0.75, 0.65), (0.32, 0.45), (0.68, 0.42)],
        "lines": [(0, 1), (1, 2), (3, 4), (4, 5), (1, 4)],
    },
    {
        "id": "cancer",
        "name": "Cự Giải",
        "symbol": "♋",
        "bg_start": (10, 18, 35),
        "bg_end": (20, 40, 75),
        "nebula": (67, 121, 242),
        "accent": (96, 165, 250),
        # Cancer inverted Y shape
        "stars": [(0.50, 0.45), (0.35, 0.30), (0.65, 0.30), (0.50, 0.68), (0.42, 0.82)],
        "lines": [(0, 1), (0, 2), (0, 3), (3, 4)],
    },
    {
        "id": "leo",
        "name": "Sư Tử",
        "symbol": "♌",
        "bg_start": (35, 15, 0),
        "bg_end": (80, 35, 5),
        "nebula": (255, 125, 0),
        "accent": (255, 183, 3),
        # Leo sickle and triangle
        "stars": [(0.25, 0.50), (0.32, 0.35), (0.42, 0.30), (0.48, 0.42), (0.45, 0.58), (0.65, 0.58), (0.78, 0.45), (0.75, 0.70)],
        "lines": [(0, 1), (1, 2), (2, 3), (3, 4), (0, 4), (4, 5), (5, 6), (6, 7), (5, 7)],
    },
    {
        "id": "virgo",
        "name": "Xử Nữ",
        "symbol": "♍",
        "bg_start": (5, 20, 30),
        "bg_end": (10, 45, 65),
        "nebula": (5, 130, 202),
        "accent": (56, 189, 248),
        # Virgo branched star pattern with Spica
        "stars": [(0.22, 0.40), (0.35, 0.42), (0.48, 0.48), (0.60, 0.40), (0.72, 0.35), (0.55, 0.65), (0.70, 0.70)],
        "lines": [(0, 1), (1, 2), (2, 3), (3, 4), (2, 5), (5, 6)],
    },
    {
        "id": "libra",
        "name": "Thiên Bình",
        "symbol": "♎",
        "bg_start": (30, 10, 25),
        "bg_end": (65, 20, 50),
        "nebula": (236, 72, 153),
        "accent": (244, 114, 182),
        # Libra scale quadrangle
        "stars": [(0.30, 0.55), (0.45, 0.32), (0.68, 0.38), (0.55, 0.65), (0.75, 0.60)],
        "lines": [(0, 1), (1, 2), (2, 4), (4, 3), (3, 0), (1, 3)],
    },
    {
        "id": "scorpio",
        "name": "Bọ Cạp",
        "symbol": "♏",
        "bg_start": (20, 0, 30),
        "bg_end": (55, 0, 80),
        "nebula": (168, 85, 247),
        "accent": (192, 132, 252),
        # Scorpio J-hook tail with Antares
        "stars": [(0.20, 0.35), (0.28, 0.42), (0.38, 0.50), (0.50, 0.58), (0.62, 0.65), (0.72, 0.60), (0.78, 0.48), (0.72, 0.40)],
        "lines": [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 6), (6, 7)],
    },
    {
        "id": "sagittarius",
        "name": "Nhân Mã",
        "symbol": "♐",
        "bg_start": (15, 5, 40),
        "bg_end": (35, 10, 85),
        "nebula": (129, 140, 248),
        "accent": (165, 180, 252),
        # Sagittarius teapot asterism
        "stars": [(0.25, 0.55), (0.35, 0.35), (0.52, 0.35), (0.45, 0.60), (0.65, 0.42), (0.75, 0.60), (0.58, 0.68)],
        "lines": [(0, 1), (1, 2), (2, 3), (3, 0), (2, 4), (4, 5), (5, 6), (6, 3)],
    },
    {
        "id": "capricorn",
        "name": "Ma Kết",
        "symbol": "♑",
        "bg_start": (10, 15, 25),
        "bg_end": (25, 35, 60),
        "nebula": (56, 189, 248),
        "accent": (125, 211, 252),
        # Capricorn triangle & horns
        "stars": [(0.22, 0.35), (0.38, 0.32), (0.55, 0.42), (0.72, 0.52), (0.55, 0.70), (0.35, 0.62)],
        "lines": [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 0)],
    },
    {
        "id": "aquarius",
        "name": "Bảo Bình",
        "symbol": "♒",
        "bg_start": (0, 25, 35),
        "bg_end": (0, 60, 80),
        "nebula": (6, 182, 212),
        "accent": (34, 211, 238),
        # Aquarius wave streams
        "stars": [(0.25, 0.35), (0.38, 0.42), (0.52, 0.38), (0.68, 0.45), (0.30, 0.60), (0.45, 0.65), (0.60, 0.58), (0.75, 0.68)],
        "lines": [(0, 1), (1, 2), (2, 3), (4, 5), (5, 6), (6, 7), (1, 4)],
    },
    {
        "id": "pisces",
        "name": "Song Ngư",
        "symbol": "♓",
        "bg_start": (15, 10, 35),
        "bg_end": (40, 20, 75),
        "nebula": (167, 139, 250),
        "accent": (196, 181, 253),
        # Pisces V-connected fishes
        "stars": [(0.22, 0.28), (0.32, 0.40), (0.45, 0.58), (0.58, 0.68), (0.68, 0.55), (0.78, 0.42), (0.85, 0.30)],
        "lines": [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 6)],
    },
]

W, H = 1200, 600

def create_zodiac_image(data):
    # 1. Base gradient background
    base = Image.new("RGBA", (W, H), (0, 0, 0, 255))
    draw = ImageDraw.Draw(base)
    
    bg_start = data["bg_start"]
    bg_end = data["bg_end"]
    
    for y in range(H):
        t = y / H
        r = int(bg_start[0] * (1 - t) + bg_end[0] * t)
        g = int(bg_start[1] * (1 - t) + bg_end[1] * t)
        b = int(bg_start[2] * (1 - t) + bg_end[2] * t)
        draw.line([(0, y), (W, y)], fill=(r, g, b, 255))
        
    # 2. Cosmic Nebula glow
    nebula_layer = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    neb_draw = ImageDraw.Draw(nebula_layer)
    nr, ng, nb = data["nebula"]
    
    # 2-3 radiant cosmic clouds
    clouds = [
        (int(W * 0.75), int(H * 0.35), 260, 0.45),
        (int(W * 0.40), int(H * 0.60), 220, 0.30),
        (int(W * 0.85), int(H * 0.70), 180, 0.25),
    ]
    for cx, cy, rad, intensity in clouds:
        for r_step in range(rad, 0, -8):
            alpha = int(255 * intensity * (1 - (r_step / rad) ** 1.8))
            neb_draw.ellipse(
                [cx - r_step, cy - r_step, cx + r_step, cy + r_step],
                fill=(nr, ng, nb, alpha)
            )
            
    nebula_layer = nebula_layer.filter(ImageFilter.GaussianBlur(radius=35))
    base = Image.alpha_composite(base, nebula_layer)
    
    # 3. Random background starfield (twinkling star dust)
    star_layer = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    star_draw = ImageDraw.Draw(star_layer)
    
    random.seed(hash(data["id"]))
    for _ in range(160):
        sx = random.randint(10, W - 10)
        sy = random.randint(10, H - 10)
        s_size = random.choice([1, 1, 1, 2, 2, 3])
        s_bright = random.randint(120, 255)
        star_draw.ellipse([sx, sy, sx + s_size, sy + s_size], fill=(255, 255, 255, s_bright))
        
    base = Image.alpha_composite(base, star_layer)
    
    # 4. Constellation Lines & Major Star Nodes
    const_layer = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    const_draw = ImageDraw.Draw(const_layer)
    
    coords = [(int(x * W), int(y * H)) for x, y in data["stars"]]
    lines = data["lines"]
    ar, ag, ab = data["accent"]
    
    # Draw constellation lines (glow line + crisp line)
    for i1, i2 in lines:
        p1 = coords[i1]
        p2 = coords[i2]
        # Glow
        const_draw.line([p1, p2], fill=(ar, ag, ab, 80), width=6)
        # Core line
        const_draw.line([p1, p2], fill=(255, 255, 255, 190), width=2)
        
    # Draw major star nodes
    for idx, (px, py) in enumerate(coords):
        # Outer radiant halo
        const_draw.ellipse([px - 14, py - 14, px + 14, py + 14], fill=(ar, ag, ab, 60))
        const_draw.ellipse([px - 8, py - 8, px + 8, py + 8], fill=(ar, ag, ab, 140))
        # Bright star core
        const_draw.ellipse([px - 3, py - 3, px + 3, py + 3], fill=(255, 255, 255, 255))
        
    const_layer = const_layer.filter(ImageFilter.GaussianBlur(radius=1.2))
    base = Image.alpha_composite(base, const_layer)
    
    # 5. Large Watermark Zodiac Symbol
    watermark_layer = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    wm_draw = ImageDraw.Draw(watermark_layer)
    symbol = data["symbol"]
    
    try:
        font = ImageFont.truetype("seguiemj.ttf", 220)
    except Exception:
        try:
            font = ImageFont.truetype("arial.ttf", 200)
        except Exception:
            font = ImageFont.load_default()
            
    wm_draw.text((int(W * 0.72), int(H * 0.15)), symbol, font=font, fill=(ar, ag, ab, 38))
    base = Image.alpha_composite(base, watermark_layer)

    # Save PNG
    out_path = os.path.join(output_dir, f"{data['id']}.png")
    base.save(out_path, "PNG", optimize=True)
    print(f"Generated: {out_path} ({os.path.getsize(out_path)} bytes)")

for z in zodiac_data:
    create_zodiac_image(z)

print("All 12 Zodiac images generated successfully!")
