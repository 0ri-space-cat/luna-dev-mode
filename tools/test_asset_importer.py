import json
import tempfile
import unittest
from pathlib import Path
from PIL import Image
from tools.asset_importer import assemble, edge_error

class AtlasImporterTest(unittest.TestCase):
    def test_valid_grid_export_and_checksums(self):
        with tempfile.TemporaryDirectory() as root:
            root = Path(root)
            img = Image.new("RGBA", (32, 16), (0, 0, 0, 0))
            for y in range(16):
                for x in range(16):
                    img.putpixel((x, y), (20, 160, 60, 255))
                    img.putpixel((x + 16, y), (230, 90, 150, 255))
            img.save(root / "atlas.png")
            data = {
                "source": "atlas.png", "cell_size": [16,16], "grid": [2,1],
                "sprites": [
                    {"name": "grass", "cell": [0,0], "seamless_tile": True},
                    {"name": "flower", "cell": [1,0], "pivot": [0.5,1]}
                ]
            }
            (root/"sheet.json").write_text(json.dumps(data))
            report = assemble(root/"sheet.json")
            self.assertEqual(report["count"], 2)
            self.assertEqual(report["sprites"][0]["seam_error"], 0)
            self.assertTrue((root/"export/grass.png").exists())
            self.assertEqual(len(report["sprites"][0]["sha256"]),64)

    def test_visible_seam_is_rejected_without_partial_export(self):
        with tempfile.TemporaryDirectory() as root:
            root = Path(root)
            img = Image.new("RGBA", (16,16), (20,160,60,255))
            for y in range(16):
                img.putpixel((15,y),(255,0,0,255))
            img.save(root/"atlas.png")
            data = {"source":"atlas.png","cell_size":[16,16],"grid":[1,1],
                    "sprites":[{"name":"bad_tile","cell":[0,0],"seamless_tile":True}]}
            (root/"sheet.json").write_text(json.dumps(data))
            with self.assertRaisesRegex(ValueError,"visible edge"):
                assemble(root/"sheet.json")
            self.assertFalse((root/"export").exists())

    def test_reject_path_traversal(self):
        with tempfile.TemporaryDirectory() as root:
            root = Path(root)
            (root/"sheet.json").write_text(json.dumps({"source":"../bad.png","cell_size":[16,16],"grid":[1,1],"sprites":[{"name":"bad","cell":[0,0]}]}))
            with self.assertRaises(ValueError):
                assemble(root/"sheet.json")

if __name__ == "__main__":
    unittest.main()
