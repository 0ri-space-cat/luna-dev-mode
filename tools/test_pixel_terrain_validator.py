"""Synthetic fixtures for the 32px pixel-art grass seam gate."""
from pathlib import Path
from tempfile import TemporaryDirectory
import unittest
from PIL import Image, ImageDraw
from ci.check_pixel_terrain import validate_atlas


class TestPixelTerrainValidator(unittest.TestCase):
    def setUp(self):
        self.tmp = TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.path = Path(self.tmp.name) / "grass_32_atlas.png"
        self.image = Image.new("RGBA", (128, 96), (124, 176, 114, 255))
        draw = ImageDraw.Draw(self.image)
        # Vary interiors while keeping every tile boundary identical.
        for i in range(12):
            x, y = (i % 4) * 32, (i // 4) * 32
            draw.rectangle((x + 6, y + 6, x + 22, y + 19),
                           fill=(100 + i * 4, 130 + i * 3, 112, 255))

    def check_bad(self, phrase):
        self.image.save(self.path)
        with self.assertRaisesRegex(ValueError, phrase):
            validate_atlas(self.path)

    def test_accepts_variants_with_matching_edges(self):
        self.image.save(self.path)
        self.assertEqual(validate_atlas(self.path), 12)

    def test_rejects_horizontal_seam(self):
        self.image.putpixel((31, 12), (255, 0, 0, 255))
        self.check_bad("Horizontal seam")

    def test_rejects_vertical_seam(self):
        self.image.putpixel((12, 31), (0, 0, 255, 255))
        self.check_bad("Vertical seam")

    def test_rejects_transparency(self):
        self.image.putpixel((12, 13), (124, 176, 114, 0))
        self.check_bad("transparency")

    def test_rejects_wrong_dimensions(self):
        self.image.crop((0, 0, 96, 96)).save(self.path)
        with self.assertRaisesRegex(ValueError, "Expected"):
            validate_atlas(self.path)


if __name__ == "__main__":
    unittest.main()
