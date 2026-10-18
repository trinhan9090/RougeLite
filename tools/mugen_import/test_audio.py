import unittest, struct
from build_audio import extract, SOURCE

class AudioTests(unittest.TestCase):
    def test_supplied_lossless(self):
        data=(SOURCE/'Ichigo_Bankai.snd').read_bytes()
        entries=extract(data)
        self.assertEqual(len(entries),134)
        self.assertIn('500_10_duplicate_112',entries)
        self.assertTrue(all(v[1]['frames']>0 for v in entries.values()))

    def test_invalid(self):
        data=(SOURCE/'Ichigo_Bankai.snd').read_bytes()
        for broken in [b'invalid',data[:100],data[:-100]]:
            with self.assertRaises((ValueError,struct.error)): extract(broken)
        cycle=bytearray(data);struct.pack_into('<I',cycle,512,512)
        with self.assertRaises(ValueError): extract(cycle)

if __name__=='__main__': unittest.main()
