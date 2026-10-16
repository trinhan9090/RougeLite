import importlib.util
from pathlib import Path
import unittest
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[2]
spec = importlib.util.spec_from_file_location("cleanup",ROOT / "tools/clean_boros_sprites.py")
cleanup = importlib.util.module_from_spec(spec)
spec.loader.exec_module(cleanup)


class CleanupRegression(unittest.TestCase):
    def test_neighbor_fragments_removed_and_connected_weapon_retained(self):
        frame = Image.new("RGBA",(128,128))
        draw = ImageDraw.Draw(frame)
        draw.rectangle((40,10,90,100),fill=(140,20,20,255))
        draw.line((88,70,125,110),fill=(200,200,200,255),width=3)
        draw.rectangle((0,60,5,80),fill=(140,20,20,255))
        draw.rectangle((110,3,120,5),fill=(200,200,200,255))
        frame.putpixel((39,20),(140,20,20,64))
        clean, count, removed = cleanup.clean_frame(frame)
        self.assertEqual(count,2)
        self.assertGreater(removed,0)
        self.assertEqual(clean.getpixel((2,70))[3],0)
        self.assertEqual(clean.getpixel((115,4))[3],0)
        self.assertEqual(clean.getpixel((125,110)),frame.getpixel((125,110)))
        self.assertEqual(clean.getpixel((39,20)),frame.getpixel((39,20)))

    def test_transparent_frame_and_idempotence(self):
        image = Image.new("RGBA",(128,128))
        self.assertEqual(cleanup.clean_frame(image)[0].tobytes(),image.tobytes())
        ImageDraw.Draw(image).rectangle((30,20,80,100),fill="red")
        first = cleanup.clean_frame(image)[0]
        self.assertEqual(cleanup.clean_frame(first)[0].tobytes(),first.tobytes())

    def test_all_actual_derived_frames_have_no_disconnected_neighbor(self):
        files = sorted(cleanup.OUTPUT.glob("*.png"))
        self.assertEqual(len(files),96)
        source_had_artifacts = False
        for path in files:
            image = Image.open(path).convert("RGBA")
            source = Image.open(cleanup.SOURCE / path.name).convert("RGBA")
            self.assertEqual(image.size,source.size)
            for index in range(image.width // 128):
                box = (index*128,0,(index+1)*128,128)
                original = source.crop(box)
                original_groups = cleanup.components(original)
                source_had_artifacts |= len(original_groups)>1
                groups = cleanup.components(image.crop(box))
                self.assertLessEqual(len(groups),1,f"{path.name}/{index}")
                if original_groups:
                    self.assertEqual(len(groups[0]),len(original_groups[0]))
        self.assertTrue(source_had_artifacts)


if __name__ == "__main__":
    unittest.main(verbosity=2)
