#!/usr/bin/env python3
"""
generate_icon.py — 佛珠念經計數器 App Icon 生成腳本
生成琥珀蜜蠟佛珠環形排列的 App Icon（1024x1024）
包含 iOS（standard / dark / tinted）和 macOS 多尺寸版本
"""

import json
import math
import os

from PIL import Image, ImageDraw, ImageFilter, ImageEnhance

# === 常數 ===
SIZE = 1024
CENTER = SIZE // 2
NUM_BEADS = 14
RING_RADIUS = 280
BEAD_RADIUS = 52
GURU_SCALE = 1.3

# 琥珀蜜蠟色系
AMBER_BASE = (217, 153, 46)
AMBER_LIGHT = (250, 210, 110)
AMBER_DARK = (150, 90, 15)
AMBER_DEEP = (100, 55, 5)

# 背景色
BG_CENTER = (42, 42, 42)
BG_EDGE = (13, 13, 13)

OUTPUT_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..",
                          "beads", "Assets.xcassets", "AppIcon.appiconset")


def lerp_color(c1, c2, t):
    """線性插值兩個顏色"""
    return tuple(int(c1[i] + (c2[i] - c1[i]) * t) for i in range(len(c1)))


def radial_gradient_bg(size):
    """繪製深灰徑向漸層背景"""
    img = Image.new("RGBA", (size, size), BG_EDGE + (255,))
    draw = ImageDraw.Draw(img)
    cx, cy = size // 2, size // 2
    max_r = int(math.hypot(cx, cy))

    for r in range(max_r, 0, -1):
        t = r / max_r
        color = lerp_color(BG_CENTER, BG_EDGE, t)
        draw.ellipse([cx - r, cy - r, cx + r, cy + r], fill=color + (255,))

    return img


def create_bead_image(radius):
    """建立一顆佛珠的獨立圖像（含陰影），返回 (image, offset_x, offset_y)"""
    # 加大 canvas 容納陰影
    padding = int(radius * 0.6)
    bead_size = (radius + padding) * 2
    bead_img = Image.new("RGBA", (bead_size, bead_size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(bead_img)
    bcx = bead_size // 2
    bcy = bead_size // 2

    # --- 陰影層（在珠子後面偏下） ---
    shadow_layer = Image.new("RGBA", (bead_size, bead_size), (0, 0, 0, 0))
    sd = ImageDraw.Draw(shadow_layer)
    shadow_off = int(radius * 0.12)
    shadow_r = int(radius * 1.05)
    for sr in range(shadow_r, 0, -1):
        t = sr / shadow_r
        a = int(60 * (1 - t ** 0.8))
        sd.ellipse([bcx - sr + shadow_off, bcy - sr + shadow_off,
                     bcx + sr + shadow_off, bcy + sr + shadow_off],
                    fill=(0, 0, 0, a))
    shadow_layer = shadow_layer.filter(ImageFilter.GaussianBlur(radius=6))
    bead_img = Image.alpha_composite(bead_img, shadow_layer)

    # --- 珠子主體（球體漸層）---
    # 使用偏移光源（左上方）的球體著色
    light_dx, light_dy = -0.35, -0.40  # 光源方向

    body = Image.new("RGBA", (bead_size, bead_size), (0, 0, 0, 0))
    body_pixels = body.load()

    for py in range(bead_size):
        for px in range(bead_size):
            dx = (px - bcx) / radius
            dy = (py - bcy) / radius
            dist2 = dx * dx + dy * dy
            if dist2 > 1.0:
                continue

            # 球面法線
            nz = math.sqrt(1.0 - dist2)
            # 光照強度（dot product with light direction）
            light_intensity = max(0, -(dx * light_dx + dy * light_dy) * 0.5 + nz * 0.7)
            light_intensity = min(1.0, light_intensity)

            # 基底顏色：從邊緣深色到中心亮色
            edge_factor = dist2 ** 0.5  # 0=中心, 1=邊緣
            base_color = lerp_color(AMBER_BASE, AMBER_DEEP, edge_factor * 0.8)

            # 應用光照
            lit_color = lerp_color(AMBER_DARK, AMBER_LIGHT, light_intensity)
            final_color = lerp_color(base_color, lit_color, 0.7)

            # 邊緣漸淡（模擬半透明琥珀）
            edge_alpha = 255
            if dist2 > 0.85:
                edge_t = (dist2 - 0.85) / 0.15
                edge_alpha = int(255 * (1 - edge_t * 0.3))

            body_pixels[px, py] = (
                max(0, min(255, final_color[0])),
                max(0, min(255, final_color[1])),
                max(0, min(255, final_color[2])),
                edge_alpha
            )

    bead_img = Image.alpha_composite(bead_img, body)

    # --- 高光（Specular highlight）---
    spec = Image.new("RGBA", (bead_size, bead_size), (0, 0, 0, 0))
    spec_pixels = spec.load()

    # 主高光：左上方，寬廣柔和
    hl_cx = bcx + light_dx * radius * 0.45
    hl_cy = bcy + light_dy * radius * 0.45
    hl_radius = radius * 0.38

    for py in range(bead_size):
        for px in range(bead_size):
            # 只在珠子範圍內
            dx = (px - bcx) / radius
            dy = (py - bcy) / radius
            if dx * dx + dy * dy > 1.0:
                continue

            hdx = (px - hl_cx) / hl_radius
            hdy = (py - hl_cy) / hl_radius
            hd2 = hdx * hdx + hdy * hdy
            if hd2 < 1.0:
                t = 1 - hd2
                a = int(160 * t ** 2.5)
                spec_pixels[px, py] = (255, 250, 230, a)

    spec = spec.filter(ImageFilter.GaussianBlur(radius=4))
    bead_img = Image.alpha_composite(bead_img, spec)

    # --- 環境反光（底部微弱暖光）---
    ref = Image.new("RGBA", (bead_size, bead_size), (0, 0, 0, 0))
    ref_pixels = ref.load()
    ref_cx = bcx + radius * 0.1
    ref_cy = bcy + radius * 0.38
    ref_radius = radius * 0.25

    for py in range(bead_size):
        for px in range(bead_size):
            dx = (px - bcx) / radius
            dy = (py - bcy) / radius
            if dx * dx + dy * dy > 1.0:
                continue
            rdx = (px - ref_cx) / ref_radius
            rdy = (py - ref_cy) / ref_radius
            rd2 = rdx * rdx + rdy * rdy
            if rd2 < 1.0:
                t = 1 - rd2
                a = int(35 * t ** 2)
                ref_pixels[px, py] = (255, 220, 170, a)

    ref = ref.filter(ImageFilter.GaussianBlur(radius=3))
    bead_img = Image.alpha_composite(bead_img, ref)

    # --- 邊緣微光（琥珀透光感）---
    rim = Image.new("RGBA", (bead_size, bead_size), (0, 0, 0, 0))
    rim_draw = ImageDraw.Draw(rim)
    # 右下側邊緣光
    for angle_deg in range(90, 270):
        angle = math.radians(angle_deg)
        for dr in range(-3, 4):
            rx = bcx + (radius + dr) * math.cos(angle)
            ry = bcy + (radius + dr) * math.sin(angle)
            a = int(18 * (1 - abs(dr) / 4))
            rim_draw.point((int(rx), int(ry)), fill=(255, 200, 80, max(0, a)))

    rim = rim.filter(ImageFilter.GaussianBlur(radius=3))
    bead_img = Image.alpha_composite(bead_img, rim)

    return bead_img, padding


def draw_ring_glow(img, cx, cy, ring_radius, bead_radius):
    """繪製環形金色 glow"""
    glow = Image.new("RGBA", img.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(glow)

    glow_width = bead_radius * 2.2
    for angle_deg in range(360):
        angle = math.radians(angle_deg)
        gx = cx + ring_radius * math.cos(angle)
        gy = cy + ring_radius * math.sin(angle)
        r = int(glow_width)
        draw.ellipse([gx - r, gy - r, gx + r, gy + r],
                      fill=(255, 190, 70, 3))

    glow = glow.filter(ImageFilter.GaussianBlur(radius=35))
    return Image.alpha_composite(img, glow)


def draw_string(img, bead_positions):
    """繪製佛珠之間的穿繩"""
    overlay = Image.new("RGBA", img.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay)

    for i in range(len(bead_positions)):
        x1, y1 = bead_positions[i]
        x2, y2 = bead_positions[(i + 1) % len(bead_positions)]
        draw.line([(x1, y1), (x2, y2)], fill=(70, 45, 15, 120), width=4)

    overlay = overlay.filter(ImageFilter.GaussianBlur(radius=1))
    return Image.alpha_composite(img, overlay)


def draw_tassel(img, x, y, length):
    """繪製主珠下方的流蘇"""
    overlay = Image.new("RGBA", img.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay)

    # 繩結
    knot_r = 10
    for r in range(knot_r, 0, -1):
        t = 1 - r / knot_r
        c = lerp_color(AMBER_DARK, AMBER_BASE, t)
        draw.ellipse([x - r, y - r, x + r, y + r], fill=c + (220,))

    # 三條流蘇線
    for ox in [-7, 0, 7]:
        for dy in range(0, length):
            t = dy / length
            width = max(1, int(3 * (1 - t * 0.6)))
            alpha = int(200 * (1 - t ** 1.3))
            wave = math.sin(dy * 0.07 + ox * 0.4) * (2 + t * 6)
            px = int(x + ox + wave)
            py = y + dy
            color = lerp_color(AMBER_BASE, AMBER_DARK, t * 0.5)
            draw.ellipse([px - width, py - width, px + width, py + width],
                          fill=color + (alpha,))

    # 尾端小珠
    for ox in [-5, 0, 5]:
        wave = math.sin(length * 0.07 + ox * 0.4) * 8
        bx = int(x + ox + wave)
        by = y + length - 3
        for r in range(6, 0, -1):
            t = 1 - r / 6
            c = lerp_color(AMBER_DARK, AMBER_BASE, t)
            draw.ellipse([bx - r, by - r, bx + r, by + r], fill=c + (160,))

    return Image.alpha_composite(img, overlay)


def generate_standard_icon():
    """生成標準版 App Icon"""
    img = radial_gradient_bg(SIZE)

    # 計算佛珠位置
    bead_positions = []
    for i in range(NUM_BEADS):
        angle = math.radians(-90 + (360 / NUM_BEADS) * i)
        bx = CENTER + RING_RADIUS * math.cos(angle)
        by = CENTER + RING_RADIUS * math.sin(angle)
        bead_positions.append((bx, by))

    # 環形 glow
    img = draw_ring_glow(img, CENTER, CENTER, RING_RADIUS, BEAD_RADIUS)

    # 穿繩
    img = draw_string(img, bead_positions)

    # 預先生成珠子圖像（避免重複計算）
    bead_img, bead_pad = create_bead_image(BEAD_RADIUS)
    guru_radius = int(BEAD_RADIUS * GURU_SCALE)
    guru_img, guru_pad = create_bead_image(guru_radius)

    # 繪製一般佛珠
    for i in range(1, NUM_BEADS):
        bx, by = bead_positions[i]
        paste_x = int(bx) - bead_img.width // 2
        paste_y = int(by) - bead_img.height // 2
        img = Image.alpha_composite(
            img,
            _paste_on_canvas(bead_img, paste_x, paste_y, SIZE)
        )

    # 主珠
    guru_bx, guru_by = bead_positions[0]
    paste_x = int(guru_bx) - guru_img.width // 2
    paste_y = int(guru_by) - guru_img.height // 2
    img = Image.alpha_composite(
        img,
        _paste_on_canvas(guru_img, paste_x, paste_y, SIZE)
    )

    # 流蘇
    tassel_y = int(guru_by + guru_radius + 8)
    img = draw_tassel(img, int(guru_bx), tassel_y, 85)

    return img


def _paste_on_canvas(src, x, y, canvas_size):
    """將小圖貼到大 canvas 上的指定位置"""
    canvas = Image.new("RGBA", (canvas_size, canvas_size), (0, 0, 0, 0))
    canvas.paste(src, (x, y))
    return canvas


def generate_dark_variant(standard_img):
    """Dark 變體"""
    dark = standard_img.copy()
    dark = ImageEnhance.Brightness(dark).enhance(0.75)
    dark = ImageEnhance.Color(dark).enhance(0.8)
    return dark


def generate_tinted_variant(standard_img):
    """Tinted 變體 — 金色剪影"""
    img = standard_img.copy().convert("RGBA")
    tinted = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))

    src = img.load()
    dst = tinted.load()

    # 先建立背景遮罩：只有佛珠區域才轉為金色剪影
    bg_only = radial_gradient_bg(SIZE)
    bg_pixels = bg_only.load()

    for y in range(SIZE):
        for x in range(SIZE):
            r, g, b, a = src[x, y]
            bg_r, bg_g, bg_b, _ = bg_pixels[x, y]
            # 計算與背景的差異來判斷是否為前景物件
            diff = abs(r - bg_r) + abs(g - bg_g) + abs(b - bg_b)
            if diff > 30:
                lum = (r * 0.299 + g * 0.587 + b * 0.114) / 255
                gold_alpha = int(min(255, lum * 380))
                dst[x, y] = (217, 165, 50, gold_alpha)
            else:
                dst[x, y] = (r, g, b, a)

    return tinted


def save_mac_sizes(img, output_dir):
    """從 1024 縮放生成 macOS 所需尺寸"""
    mac_sizes = [
        ("icon_mac_16x16@1x.png", 16),
        ("icon_mac_16x16@2x.png", 32),
        ("icon_mac_32x32@1x.png", 32),
        ("icon_mac_32x32@2x.png", 64),
        ("icon_mac_128x128@1x.png", 128),
        ("icon_mac_128x128@2x.png", 256),
        ("icon_mac_256x256@1x.png", 256),
        ("icon_mac_256x256@2x.png", 512),
        ("icon_mac_512x512@1x.png", 512),
        ("icon_mac_512x512@2x.png", 1024),
    ]
    for filename, px in mac_sizes:
        resized = img.resize((px, px), Image.LANCZOS)
        resized.save(os.path.join(output_dir, filename), "PNG")
        print(f"  {filename} ({px}x{px})")


def generate_contents_json():
    """生成 Contents.json"""
    contents = {
        "images": [
            {"filename": "icon_1024.png", "idiom": "universal", "platform": "ios", "size": "1024x1024"},
            {"appearances": [{"appearance": "luminosity", "value": "dark"}],
             "filename": "icon_1024_dark.png", "idiom": "universal", "platform": "ios", "size": "1024x1024"},
            {"appearances": [{"appearance": "luminosity", "value": "tinted"}],
             "filename": "icon_1024_tinted.png", "idiom": "universal", "platform": "ios", "size": "1024x1024"},
            {"filename": "icon_mac_16x16@1x.png", "idiom": "mac", "scale": "1x", "size": "16x16"},
            {"filename": "icon_mac_16x16@2x.png", "idiom": "mac", "scale": "2x", "size": "16x16"},
            {"filename": "icon_mac_32x32@1x.png", "idiom": "mac", "scale": "1x", "size": "32x32"},
            {"filename": "icon_mac_32x32@2x.png", "idiom": "mac", "scale": "2x", "size": "32x32"},
            {"filename": "icon_mac_128x128@1x.png", "idiom": "mac", "scale": "1x", "size": "128x128"},
            {"filename": "icon_mac_128x128@2x.png", "idiom": "mac", "scale": "2x", "size": "128x128"},
            {"filename": "icon_mac_256x256@1x.png", "idiom": "mac", "scale": "1x", "size": "256x256"},
            {"filename": "icon_mac_256x256@2x.png", "idiom": "mac", "scale": "2x", "size": "256x256"},
            {"filename": "icon_mac_512x512@1x.png", "idiom": "mac", "scale": "1x", "size": "512x512"},
            {"filename": "icon_mac_512x512@2x.png", "idiom": "mac", "scale": "2x", "size": "512x512"},
        ],
        "info": {"author": "xcode", "version": 1}
    }
    return json.dumps(contents, indent=2, ensure_ascii=False)


def main():
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    print("=== 佛珠 App Icon 生成器 ===\n")

    print("[1/5] 生成標準版 icon...")
    standard = generate_standard_icon()
    standard.save(os.path.join(OUTPUT_DIR, "icon_1024.png"), "PNG")
    print("  已儲存: icon_1024.png (1024x1024)")

    print("[2/5] 生成 Dark 變體...")
    dark = generate_dark_variant(standard)
    dark.save(os.path.join(OUTPUT_DIR, "icon_1024_dark.png"), "PNG")
    print("  已儲存: icon_1024_dark.png")

    print("[3/5] 生成 Tinted 變體...")
    tinted = generate_tinted_variant(standard)
    tinted.save(os.path.join(OUTPUT_DIR, "icon_1024_tinted.png"), "PNG")
    print("  已儲存: icon_1024_tinted.png")

    print("[4/5] 生成 macOS 多尺寸...")
    save_mac_sizes(standard, OUTPUT_DIR)

    print("[5/5] 更新 Contents.json...")
    with open(os.path.join(OUTPUT_DIR, "Contents.json"), "w", encoding="utf-8") as f:
        f.write(generate_contents_json())
    print("  已更新: Contents.json")

    print(f"\n完成！所有圖檔已輸出至:\n  {OUTPUT_DIR}")


if __name__ == "__main__":
    main()
