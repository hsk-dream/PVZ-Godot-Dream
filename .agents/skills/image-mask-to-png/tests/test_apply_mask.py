"""Run unittest discovery against this directory using the selected Python environment."""

import importlib.util
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

from PIL import Image

SCRIPT = Path(__file__).resolve().parents[1] / "scripts" / "apply_mask.py"
SPEC = importlib.util.spec_from_file_location("image_mask_to_png", SCRIPT)
assert SPEC is not None and SPEC.loader is not None
MODULE = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(MODULE)
apply_mask = MODULE.apply_mask


class ApplyMaskTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.directory = Path(self.temporary.name) / "中文 图片"
        self.directory.mkdir()
        self.source = self.directory / "source.png"
        self.mask = self.directory / "mask.png"
        self.output = self.directory / "output.png"
        Image.new("RGB", (3, 1), (20, 80, 160)).save(self.source)
        mask = Image.new("L", (3, 1))
        mask.putdata([0, 128, 255])
        mask.save(self.mask)

    def test_black_gray_white_mask_preserves_rgb_and_sets_alpha(self) -> None:
        result = apply_mask(self.source, self.mask, self.output)
        self.assertEqual(result, self.output.resolve())
        with Image.open(result) as image:
            self.assertEqual((image.format, image.mode, image.size), ("PNG", "RGBA", (3, 1)))
            self.assertEqual(
                [image.getpixel((x, 0)) for x in range(3)],
                [(20, 80, 160, 0), (20, 80, 160, 128), (20, 80, 160, 255)],
            )

    def test_existing_transparency_is_multiplied_not_replaced(self) -> None:
        source = Image.new("RGBA", (3, 1))
        source.putdata([(1, 2, 3, 128), (4, 5, 6, 128), (7, 8, 9, 0)])
        source.save(self.source)
        apply_mask(self.source, self.mask, self.output)
        with Image.open(self.output) as image:
            self.assertEqual([image.getpixel((x, 0))[3] for x in range(3)], [0, 64, 0])

    def test_invalid_dimensions_or_extension_do_not_create_output(self) -> None:
        with self.assertRaises(ValueError):
            apply_mask(self.source, self.mask, self.directory / "output.jpg")
        Image.new("L", (1, 1), 255).save(self.mask)
        with self.assertRaises(ValueError):
            apply_mask(self.source, self.mask, self.output)
        self.assertFalse(self.output.exists())
        self.assertFalse((self.directory / "output.jpg").exists())

    def test_existing_output_requires_force(self) -> None:
        self.output.write_bytes(b"keep this file")
        with self.assertRaises(FileExistsError):
            apply_mask(self.source, self.mask, self.output)
        self.assertEqual(self.output.read_bytes(), b"keep this file")
        apply_mask(self.source, self.mask, self.output, force=True)
        with Image.open(self.output) as image:
            self.assertEqual(image.mode, "RGBA")

    def test_force_cannot_overwrite_either_input(self) -> None:
        for target in (self.source, self.mask):
            with self.subTest(target=target.name):
                original = target.read_bytes()
                with self.assertRaises(ValueError):
                    apply_mask(self.source, self.mask, target, force=True)
                self.assertEqual(target.read_bytes(), original)

    def test_cli_handles_unicode_paths_and_reports_invalid_input(self) -> None:
        script = SCRIPT
        command = [
            sys.executable, "-X", "utf8", str(script), "--image", str(self.source),
            "--mask", str(self.mask), "--output", str(self.output), "--allow-other-formats",
        ]
        success = subprocess.run(command, capture_output=True, cwd=self.directory)
        self.assertEqual(success.returncode, 0, success.stderr)
        self.assertTrue(self.output.exists())
        self.assertIn(str(self.output.resolve()), success.stdout.decode("utf-8"))
        self.source.write_text("not an image", encoding="utf-8")
        failure = subprocess.run(command + ["--force"], capture_output=True, cwd=self.directory)
        self.assertNotEqual(failure.returncode, 0)
        self.assertNotIn(b"Traceback", failure.stderr)
        with Image.open(self.output) as image:
            self.assertEqual(image.format, "PNG")


if __name__ == "__main__":
    unittest.main()
