"""Inspect image/mask inputs and safely produce a transparent PNG."""

import argparse
import json
import os
import sys
import tempfile
from pathlib import Path

from PIL import Image, ImageChops


def _paths(image_path, mask_path, output_path):
    source = Path(image_path).expanduser().resolve()
    mask = Path(mask_path).expanduser().resolve()
    output = (Path(output_path).expanduser().resolve()
              if output_path is not None else source.with_suffix(".png"))
    if output.suffix.lower() != ".png":
        raise ValueError("输出文件必须使用 .png 扩展名。")
    for path in (source, mask):
        if not path.is_file():
            raise FileNotFoundError(f"找不到输入文件：{path}")
    return source, mask, output


def _is_input(output, inputs):
    return any(output == path or (output.exists() and output.samefile(path))
               for path in inputs)


def _available_output(base):
    candidate = base
    number = 1
    while candidate.exists():
        candidate = base.with_name(f"{base.stem}_{number}.png")
        number += 1
    return candidate


def inspect_request(image_path, mask_path, output_path=None):
    """Return a read-only JSON-compatible plan; input conflicts take priority."""
    source, mask, output = _paths(image_path, mask_path, output_path)
    metadata = []
    warnings = []
    for role, path, expected, suffixes in (
        ("原图", source, "JPEG", {".jpg", ".jpeg"}),
        ("遮罩", mask, "PNG", {".png"}),
    ):
        with Image.open(path) as image:
            image.load()
            metadata.append({"path": str(path), "format": image.format,
                             "mode": image.mode, "size": list(image.size)})
            if image.format != expected or path.suffix.lower() not in suffixes:
                warnings.append(
                    f"{role} {path}：实际格式 {image.format}，扩展名 {path.suffix}；预期 {expected}。"
                )
    if metadata[0]["size"] != metadata[1]["size"]:
        raise ValueError(f"尺寸不一致：原图 {metadata[0]['size']}，遮罩 {metadata[1]['size']}。")
    conflict = ("input" if _is_input(output, (source, mask))
                else "existing" if output.exists() else "none")
    return {"source": metadata[0], "mask": metadata[1], "format_warnings": warnings,
            "output": str(output), "conflict": conflict,
            "numbered_output": str(_available_output(output))}


def apply_mask(
    image_path: str | Path,
    mask_path: str | Path,
    output_path: str | Path | None = None,
    *,
    force: bool = False,
    auto_number: bool = False,
) -> Path:
    """Preserve RGB and multiply source alpha by mask luminance (floor / 255).

    The Python API accepts any Pillow-readable input. The CLI enforces the
    skill's JPG/PNG convention unless the caller confirms other formats.
    Never overwrite inputs. Publish only after a temporary PNG is validated.
    """
    if force and auto_number:
        raise ValueError("覆盖与自动编号不能同时使用。")
    source, mask, base = _paths(image_path, mask_path, output_path)
    destination = _available_output(base) if auto_number else base
    if _is_input(destination, (source, mask)):
        raise ValueError(f"输出路径不能覆盖输入文件：{destination}")
    if destination.exists() and not force:
        raise FileExistsError(f"输出文件已存在：{destination}；确认覆盖后用 --force，否则用 --auto-number。")

    with Image.open(source) as original, Image.open(mask) as grayscale:
        if original.size != grayscale.size:
            raise ValueError(f"尺寸不一致：原图 {original.size}，遮罩 {grayscale.size}。")
        result = original.convert("RGBA")
        result.putalpha(ImageChops.multiply(result.getchannel("A"), grayscale.convert("L")))

    destination.parent.mkdir(parents=True, exist_ok=True)
    temporary_path = None
    try:
        with tempfile.NamedTemporaryFile(
            dir=destination.parent, prefix=f".{base.stem}.", suffix=".tmp", delete=False,
        ) as temporary:
            temporary_path = Path(temporary.name)
            result.save(temporary, format="PNG")
            temporary.flush()
            os.fsync(temporary.fileno())
        with Image.open(temporary_path) as verified:
            verified.load()
            if verified.format != "PNG" or verified.mode != "RGBA" or verified.size != result.size:
                raise ValueError("临时 PNG 校验失败。")
        while True:
            if _is_input(destination, (source, mask)):
                if auto_number:
                    destination = _available_output(base)
                    continue
                raise ValueError(f"输出路径不能覆盖输入文件：{destination}")
            if force:
                os.replace(temporary_path, destination)
                break
            try:
                # Linking the complete file refuses an existing destination atomically.
                os.link(temporary_path, destination)
                break
            except FileExistsError:
                if not auto_number:
                    raise FileExistsError(f"输出文件已存在：{destination}") from None
                destination = _available_output(base)
        return destination
    finally:
        if temporary_path is not None:
            temporary_path.unlink(missing_ok=True)


def main() -> int:
    parser = argparse.ArgumentParser(
        description="使用灰度遮罩生成 RGBA PNG：白色保留、黑色透明、灰色半透明。",
        epilog=(
            "默认 JPG/JPEG 原图、PNG 遮罩；默认输出为原图同目录同名 .png。\n"
            "先运行 --check 查看格式、路径和覆盖冲突，再根据用户确认执行。\n"
            f'示例（PowerShell）：& "{sys.executable}" -X utf8 '
            f'"{Path(__file__).resolve()}" --image "source.jpg" --mask "mask.png" --check'
        ),
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    parser.add_argument("--image", required=True, type=Path, help="原图路径，默认 JPG/JPEG")
    parser.add_argument("--mask", required=True, type=Path, help="遮罩路径，默认 PNG，尺寸必须一致")
    parser.add_argument("--output", type=Path, help="输出 PNG 路径；默认原图同目录同名 .png")
    parser.add_argument("--check", action="store_true", help="仅输出 JSON 检查报告，不生成文件")
    parser.add_argument("--allow-other-formats", action="store_true", help="用户确认后允许非默认输入格式")
    collision = parser.add_mutually_exclusive_group()
    collision.add_argument("--force", action="store_true", help="用户确认后覆盖已有输出，仍禁止覆盖输入")
    collision.add_argument("--auto-number", action="store_true", help="冲突时追加 _1、_2 等编号另存")
    args = parser.parse_args()
    try:
        report = inspect_request(args.image, args.mask, args.output)
        if args.check:
            print(json.dumps(report, ensure_ascii=False, indent=2))
            return 0
        if report["format_warnings"] and not args.allow_other_formats:
            raise ValueError("\n".join(report["format_warnings"]) +
                             "\n请先向用户确认，确认后使用 --allow-other-formats。")
        destination = apply_mask(args.image, args.mask, args.output,
                                 force=args.force, auto_number=args.auto_number)
        with Image.open(destination) as result:
            result.load()
            print(f"已生成：{destination}\n格式：{result.format} / {result.mode} / {result.width} × {result.height}")
    except (OSError, ValueError, Image.DecompressionBombError) as error:
        parser.exit(1, f"错误：{error}\n")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
