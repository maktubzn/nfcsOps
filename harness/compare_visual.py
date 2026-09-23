"""Diagnostic comparison only; never changes source/reference images or auto-approves."""
import argparse
import json
from pathlib import Path
from PIL import Image, ImageChops, ImageStat


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--reference', required=True)
    parser.add_argument('--actual', required=True)
    parser.add_argument('--crop', nargs=4, type=int, required=True, metavar=('X', 'Y', 'W', 'H'))
    parser.add_argument('--out-dir', required=True)
    args = parser.parse_args()
    reference_path = Path(args.reference).resolve()
    actual_path = Path(args.actual).resolve()
    if reference_path == actual_path:
        parser.error('A captura deve vir da aplicação, não da própria referência.')
    reference = Image.open(reference_path).convert('RGB')
    actual = Image.open(actual_path).convert('RGB')
    x, y, width, height = args.crop
    if min(x, y) < 0 or min(width, height) <= 0 or x + width > reference.width or y + height > reference.height:
        parser.error('Recorte inválido ou fora da prancha.')
    if actual.size != (width, height):
        parser.error(f'Captura {actual.size} diferente do recorte {(width, height)}; recapture sem esticar.')
    crop = reference.crop((x, y, x + width, y + height))
    out = Path(args.out_dir).resolve()
    out.mkdir(parents=True, exist_ok=True)
    outputs = ['reference.png', 'actual.png', 'comparison.png', 'overlay.png', 'diff.png', 'metrics.json']
    if any((out / name).exists() for name in outputs):
        parser.error('Pasta já contém comparação. Use nova pasta para preservar evidências.')
    crop.save(out / 'reference.png')
    actual.save(out / 'actual.png')
    diff = ImageChops.difference(crop, actual)
    canvas = Image.new('RGB', (width * 2, height))
    canvas.paste(crop, (0, 0))
    canvas.paste(actual, (width, 0))
    canvas.save(out / 'comparison.png')
    Image.blend(crop, actual, .5).save(out / 'overlay.png')
    diff.point(lambda value: min(value * 4, 255)).save(out / 'diff.png')
    errors = list(diff.getdata())
    metrics = {'size': [width, height], 'crop': args.crop,
               'mean_absolute_channel_error': sum(ImageStat.Stat(diff).mean) / 3,
               'fraction_pixels_above_3': sum(max(pixel) > 3 for pixel in errors) / (width * height),
               'auto_approved': False,
               'note': 'Métricas auxiliares. Diferenças exigem revisão visual independente; SSIM não calculado.'}
    (out / 'metrics.json').write_text(json.dumps(metrics, indent=2, ensure_ascii=False), encoding='utf-8')
    print(json.dumps(metrics, ensure_ascii=False))


if __name__ == '__main__':
    main()
