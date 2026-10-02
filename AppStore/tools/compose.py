"""Imágenes de App Store: titular + captura asomando por abajo, en el tamaño exacto del dispositivo."""
import sys
from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter, ImageFont

def bold_font(size):
    ttc = '/System/Library/Fonts/Avenir Next.ttc'
    for i in range(12):
        try:
            f = ImageFont.truetype(ttc, size, index=i)
            if f.getname()[1].lower() in ('bold', 'demi bold'): return f
        except Exception: break
    return ImageFont.truetype('/System/Library/Fonts/Supplemental/Arial Bold.ttf', size)

def gradient(w, h, top, bottom):
    img = Image.new('RGB', (w, h)); px = img.load()
    for y in range(h):
        t = y / (h - 1)
        c = tuple(int(top[i] + (bottom[i] - top[i]) * t) for i in range(3))
        for x in range(w): px[x, y] = c
    return img

def wrap(draw, text, font, max_w):
    lines, cur = [], ''
    for word in text.split():
        trial = (cur + ' ' + word).strip()
        if draw.textlength(trial, font=font) <= max_w: cur = trial
        else: lines.append(cur); cur = word
    return lines + [cur]

def compose(shot, caption, out, W, H, phone=True):
    bg = gradient(W, H, (79, 70, 229), (124, 58, 237))          # indigo → violet (acento de la app)
    d = ImageDraw.Draw(bg)
    size = int(W * (0.078 if phone else 0.062))
    font = bold_font(size)
    lines = wrap(d, caption, font, W * 0.86)
    y = int(H * 0.055)
    for ln in lines:
        d.text(((W - d.textlength(ln, font=font)) / 2, y), ln, font=font, fill='white')
        y += int(size * 1.18)
    scr = Image.open(shot).convert('RGB')
    if not phone: scr = scr.crop((0, 56, scr.width, scr.height))   # iPad: sin la franja de la barra de estado (la esquina redondeada la cortaría)
    sw = int(W * (0.84 if phone else 0.80)); sh = int(scr.height * sw / scr.width)
    scr = scr.resize((sw, sh), Image.LANCZOS)
    r = int(sw * 0.075)
    mask = Image.new('L', scr.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, sw, sh), radius=r, fill=255)
    x = (W - sw) // 2; top = max(y + int(H * 0.025), int(H * 0.19))
    shadow = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    ImageDraw.Draw(shadow).rounded_rectangle((x, top + 18, x + sw, top + sh + 18), radius=r, fill=(0, 0, 0, 120))
    bg = Image.alpha_composite(bg.convert('RGBA'), shadow.filter(ImageFilter.GaussianBlur(28)))
    bg.paste(scr, (x, top), mask)
    bg.convert('RGB').save(out, 'PNG', optimize=True)

if __name__ == '__main__':
    base = Path(sys.argv[1]); outdir = Path(sys.argv[2])
    iphone = [('iphone_en_01_library', 'Books, series and games in one place'),
              ('iphone_en_08_search', 'Find any title in seconds'),
              ('iphone_en_02_detail_progress', 'Track your progress, page by page'),
              ('iphone_en_05_series', 'Follow every season and episode'),
              ('iphone_en_03_completed_ratings', 'Rate from 0 to 5 in quarter steps'),
              ('iphone_en_06_games', 'Log your hours and beat the backlog'),
              ('iphone_en_04_detail_rating_review', 'Keep dates, ratings and notes'),
              ('iphone_en_07_stats', 'Your hobbies at a glance')]
    ipad = [('ipad_en_01_library', 'Books, series and games in one place'),
            ('ipad_en_02_detail_progress', 'Track your progress, page by page'),
            ('ipad_en_03_series', 'Follow every season and episode'),
            ('ipad_en_04_games', 'Log your hours and beat the backlog'),
            ('ipad_en_05_stats', 'Your hobbies at a glance')]
    (outdir / 'iphone_6.9').mkdir(parents=True, exist_ok=True); (outdir / 'ipad_13').mkdir(exist_ok=True)
    for i, (n, c) in enumerate(iphone, 1): compose(base / f'{n}.png', c, outdir / 'iphone_6.9' / f'{i:02d}_{n.split("_",3)[3]}.png', 1320, 2868, True)
    for i, (n, c) in enumerate(ipad, 1): compose(base / f'{n}.png', c, outdir / 'ipad_13' / f'{i:02d}_{n.split("_",3)[3]}.png', 2064, 2752, False)
    print('ok')
