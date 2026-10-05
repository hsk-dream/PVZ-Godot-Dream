"""Exercise the skill CLI, output selection and failed-write recovery."""

import json
import os
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

from PIL import Image
from test_apply_mask import MODULE, SCRIPT


class WorkflowTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.directory = Path(self.temporary.name).resolve() / "中文 图片"
        self.directory.mkdir()
        self.source = self.directory / "boss.jpg"
        self.mask = self.directory / "boss_.png"
        self.output = self.directory / "boss.png"
        Image.new("RGB", (3, 1), (20, 80, 160)).save(self.source)
        mask = Image.new("P", (3, 1))
        mask.putpalette([v for gray in range(256) for v in (gray, gray, gray)])
        mask.putdata([0, 128, 255])
        mask.save(self.mask)

    def cli(self, *args):
        return subprocess.run(
            [sys.executable, "-B", "-X", "utf8", str(SCRIPT),
             "--image", str(self.source), "--mask", str(self.mask), *args],
            cwd=self.directory, capture_output=True, text=True, encoding="utf-8",
        )

    def test_check_reports_default_path_formats_and_conflict_without_writing(self):
        self.output.write_bytes(b"existing output")
        result = self.cli("--check")
        self.assertEqual(result.returncode, 0, result.stderr)
        report = json.loads(result.stdout)
        self.assertEqual(report["source"]["format"], "JPEG")
        self.assertEqual(report["mask"]["format"], "PNG")
        self.assertEqual(report["format_warnings"], [])
        self.assertEqual(report["output"], str(self.output))
        self.assertEqual(report["conflict"], "existing")
        self.assertEqual(report["numbered_output"], str(self.directory / "boss_1.png"))
        self.assertEqual(self.output.read_bytes(), b"existing output")
        self.assertEqual(len(list(self.directory.iterdir())), 3)

    def test_jpeg_and_palette_mask_use_default_output_and_preserve_pixels(self):
        result = self.cli()
        self.assertEqual(result.returncode, 0, result.stderr)
        with Image.open(self.output) as out, Image.open(self.source) as src:
            self.assertEqual((out.format, out.mode, out.size), ("PNG", "RGBA", (3, 1)))
            self.assertEqual(out.convert("RGB").tobytes(), src.convert("RGB").tobytes())
            self.assertEqual([out.getpixel((x, 0))[3] for x in range(3)], [0, 128, 255])

    def test_nondefault_format_requires_explicit_confirmation_flag(self):
        Image.new("RGB", (3, 1), "red").save(self.source, format="PNG")
        checked = self.cli("--check")
        self.assertEqual(checked.returncode, 0, checked.stderr)
        self.assertTrue(json.loads(checked.stdout)["format_warnings"])
        refused = self.cli()
        self.assertNotEqual(refused.returncode, 0)
        self.assertFalse(self.output.exists())
        accepted = self.cli("--allow-other-formats")
        self.assertEqual(accepted.returncode, 0, accepted.stderr)
        self.assertTrue(self.output.exists())

    def test_numbering_uses_first_available_name_and_keeps_all_existing_files(self):
        self.output.write_bytes(b"original")
        (self.directory / "boss_1.png").write_bytes(b"one")
        (self.directory / "boss_3.png").write_bytes(b"three")
        result = self.cli("--auto-number")
        self.assertEqual(result.returncode, 0, result.stderr)
        with Image.open(self.directory / "boss_2.png") as out:
            self.assertEqual(out.mode, "RGBA")
        self.assertEqual(self.output.read_bytes(), b"original")
        self.assertEqual((self.directory / "boss_1.png").read_bytes(), b"one")
        self.assertEqual((self.directory / "boss_3.png").read_bytes(), b"three")

    def test_input_conflict_is_reported_first_and_can_only_be_numbered(self):
        original = self.mask.read_bytes()
        checked = self.cli("--check", "--output", str(self.mask))
        self.assertEqual(checked.returncode, 0, checked.stderr)
        self.assertEqual(json.loads(checked.stdout)["conflict"], "input")
        refused = self.cli("--output", str(self.mask), "--force")
        self.assertNotEqual(refused.returncode, 0)
        accepted = self.cli("--output", str(self.mask), "--auto-number")
        self.assertEqual(accepted.returncode, 0, accepted.stderr)
        self.assertEqual(self.mask.read_bytes(), original)
        self.assertTrue((self.directory / "boss__1.png").is_file())

    def test_force_and_numbering_cannot_be_combined(self):
        result = self.cli("--force", "--auto-number")
        self.assertEqual(result.returncode, 2)
        self.assertFalse(self.output.exists())

    def test_write_failure_preserves_old_output_and_removes_temporary_file(self):
        self.output.write_bytes(b"keep old image")
        before = set(self.directory.iterdir())
        with patch("os.fsync", side_effect=OSError("simulated disk failure")):
            with self.assertRaises(OSError):
                MODULE.apply_mask(self.source, self.mask, self.output, force=True)
        self.assertEqual(self.output.read_bytes(), b"keep old image")
        self.assertEqual(set(self.directory.iterdir()), before)

    def test_replace_failure_preserves_old_output_and_removes_temporary_file(self):
        self.output.write_bytes(b"keep old image")
        before = set(self.directory.iterdir())
        with patch("os.replace", side_effect=PermissionError("target is locked")):
            with self.assertRaises(PermissionError):
                MODULE.apply_mask(self.source, self.mask, self.output, force=True)
        self.assertEqual(self.output.read_bytes(), b"keep old image")
        self.assertEqual(set(self.directory.iterdir()), before)

    def test_numbering_handles_file_appearing_during_publish(self):
        real_link = os.link
        raced = False

        def competing_writer(source, destination):
            nonlocal raced
            if not raced:
                raced = True
                Path(destination).write_bytes(b"other writer")
            return real_link(source, destination)

        with patch("os.link", side_effect=competing_writer):
            result = MODULE.apply_mask(self.source, self.mask, self.output, auto_number=True)
        self.assertEqual(result, self.directory / "boss_1.png")
        self.assertEqual(self.output.read_bytes(), b"other writer")
        with Image.open(result) as out:
            self.assertEqual(out.mode, "RGBA")
        self.assertFalse(list(self.directory.glob("*.tmp")))

    def test_new_output_write_failure_leaves_no_partial_file(self):
        before = set(self.directory.iterdir())
        with patch("os.fsync", side_effect=OSError("simulated disk failure")):
            with self.assertRaises(OSError):
                MODULE.apply_mask(self.source, self.mask, self.output)
        self.assertFalse(self.output.exists())
        self.assertEqual(set(self.directory.iterdir()), before)


    def test_mask_disguised_as_png_is_reported_and_not_processed(self):
        Image.new("RGB", (3, 1), "white").save(self.mask, format="JPEG")
        checked = self.cli("--check")
        self.assertEqual(checked.returncode, 0, checked.stderr)
        report = json.loads(checked.stdout)
        self.assertEqual(report["mask"]["format"], "JPEG")
        self.assertTrue(report["format_warnings"])
        result = self.cli()
        self.assertNotEqual(result.returncode, 0)
        self.assertFalse(self.output.exists())

    def test_numbering_preserves_digits_in_custom_output_name(self):
        target = self.directory / "boss_7.png"
        target.write_bytes(b"keep")
        result = self.cli("--output", str(target), "--auto-number")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertTrue((self.directory / "boss_7_1.png").is_file())
        self.assertEqual(target.read_bytes(), b"keep")

    def test_no_force_preserves_file_appearing_during_publish(self):
        real_link = os.link

        def competing_writer(source, destination):
            Path(destination).write_bytes(b"other writer")
            return real_link(source, destination)

        with patch("os.link", side_effect=competing_writer):
            with self.assertRaises(FileExistsError):
                MODULE.apply_mask(self.source, self.mask, self.output)
        self.assertEqual(self.output.read_bytes(), b"other writer")
        self.assertFalse(list(self.directory.glob("*.tmp")))

    def test_invalid_temporary_png_does_not_replace_existing_output(self):
        self.output.write_bytes(b"keep old image")
        before = set(self.directory.iterdir())

        def corrupted_save(image, file, **kwargs):
            file.write(b"invalid PNG")

        with patch.object(Image.Image, "save", new=corrupted_save):
            with self.assertRaises(OSError):
                MODULE.apply_mask(self.source, self.mask, self.output, force=True)
        self.assertEqual(self.output.read_bytes(), b"keep old image")
        self.assertEqual(set(self.directory.iterdir()), before)

if __name__ == "__main__":
    unittest.main()
