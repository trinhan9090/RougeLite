import unittest,struct
from decode_sff import unpack_pixels,Archive
from parse_air import parse
def packet(n,p):return struct.pack('<I',n)+bytes(p)
class DecoderTests(unittest.TestCase):
 def test_rle8(self):self.assertEqual(unpack_pixels(packet(5,[0x43,2,3,4]),2,5),bytes([2,2,2,3,4]))
 def test_rle_literal_high(self):self.assertEqual(unpack_pixels(packet(2,[192,255]),2,2),bytes([192,255]))
 def test_lz_overlap(self):self.assertEqual(unpack_pixels(packet(6,[2,103,2,0]),4,6),bytes([7]*6))
 def test_lz_long_rle(self):self.assertEqual(unpack_pixels(packet(8,[0,5,0]),4,8),bytes([5]*8))
 def test_bad_packets(self):
  for data,fmt,n in [(packet(2,[0x43,2]),2,2),(packet(5,[1,2,255]),4,5),(b'bad',2,2)]:
   with self.assertRaises(ValueError):unpack_pixels(data,fmt,n)
 def test_palette_cycle(self):
  a=Archive.__new__(Archive);a.pcache={};a.palettes=[(1,1,256,0,0,0)]
  with self.assertRaises(ValueError):a.palette(0)
 def test_air_duplicates_offsets_hold(self):
  x=parse('[Begin Action 0]\nClsn2Default:1\nClsn2[0]=-2,-8,2,0\n0,1,11,0,10,H,A\nLoopstart\n-1,0,0,0,-1\n[Begin Action 0]\n0,2,3,-4,0')
  self.assertEqual([a['occurrence'] for a in x],[1,2]);self.assertEqual(x[0]['loop_start'],1)
  self.assertEqual(x[0]['frames'][0]['offset'],[11,0]);self.assertEqual(x[0]['frames'][1]['ticks'],-1)
  self.assertEqual(x[0]['frames'][1]['boxes']['2'],[[-2,-8,2,0]])
 def test_temporary_boxes_reset(self):
  x=parse('[Begin Action 1]\nClsn1:1\nClsn1[0]=0,0,5,5\n1,1,0,0,1\n1,2,0,0,1')
  self.assertEqual(len(x[0]['frames'][0]['boxes']['1']),1);self.assertEqual(x[0]['frames'][1]['boxes']['1'],[])
if __name__=='__main__':unittest.main()
