"""Original bounded SFF2 decoder: raw/RLE8/LZ5 and linked palettes/sprites.
References: Elecbyte format.
No MUGEN state code is executed. Generated PNGs are private runtime textures.
"""
import struct,json,hashlib,argparse,io
from pathlib import Path
from PIL import Image

def unpack_pixels(data,fmt,size):
 if fmt==0:
  if len(data)!=size:raise ValueError('raw length')
  return data
 if len(data)<4 or struct.unpack_from('<I',data)[0]!=size:raise ValueError('decoded size header')
 out=bytearray();i=4;control=0;bits=0;recycle=0;recycled=0
 def byte():
  nonlocal i
  if i>=len(data):raise ValueError('truncated packet')
  v=data[i];i+=1;return v
 def run(c,n):
  if n<=0 or len(out)+n>size:raise ValueError('run exceeds image')
  out.extend(bytes([c])*n)
 while len(out)<size:
  if fmt==2:
   b=byte()
   if b&192==64:run(byte(),b&63)
   else:run(b,1)
  elif fmt==4:
   if bits==0:control=byte();bits=8
   lz=control&1;control>>=1;bits-=1;b=byte()
   if not lz:
    run(b&31,b>>5) if b&224 else run(b,byte()+8)
   else:
    n=b&63
    if n==0:distance=((b&192)<<2)|byte();n=byte()+3
    else:
     n+=1;recycle=(recycle<<2)|(b>>6);recycled+=1
     if recycled==4:distance=recycle;recycle=0;recycled=0
     else:distance=byte()
    distance+=1
    if distance>len(out) or len(out)+n>size:raise ValueError('invalid backreference')
    for _ in range(n):out.append(out[-distance])
  else:raise ValueError('unsupported encoding '+str(fmt))
 return bytes(out)

class Archive:
 def __init__(self,path):
  self.data=Path(path).read_bytes();b=self.data
  if b[:12]!=b'ElecbyteSpr\0' or b[15]!=2:raise ValueError('SFF2 required')
  so,sn,po,pn,self.lo,ll,self.to,tl=struct.unpack_from('<8I',b,36)
  self.sprites=[struct.unpack_from('<HHHHhhHBBIIHH',b,so+i*28) for i in range(sn)]
  self.palettes=[struct.unpack_from('<HHHHII',b,po+i*16) for i in range(pn)]
  self.cache={};self.pcache={}
 def block(self,offset,length):
  if offset<0 or offset+length>len(self.data):raise ValueError('block out of bounds')
  return self.data[offset:offset+length]
 def palette(self,i,seen=()):
  if i in seen:raise ValueError('palette cycle')
  if i in self.pcache:return self.pcache[i]
  g,n,c,link,off,length=self.palettes[i]
  if length==0:p=self.palette(link,seen+(i,))
  else:
   raw=self.block(self.lo+off,length)
   if len(raw)<c*4:raise ValueError('palette length')
   p=[tuple(raw[k*4:k*4+3])+(0 if k==0 else 255,) for k in range(c)]
  self.pcache[i]=p;return p
 def pixels(self,i,seen=()):
  if i in seen:raise ValueError('sprite cycle')
  s=self.sprites[i]
  if s[2]*s[3]>16000000:raise ValueError('oversize sprite')
  if s[10]==0:return self.pixels(s[6],seen+(i,))
  raw=self.block((self.to if s[12]&1 else self.lo)+s[9],s[10])
  if s[7]==10:
   if len(raw)<12 or struct.unpack_from('<I',raw)[0]!=s[2]*s[3] or raw[4:12]!=b'\x89PNG\r\n\x1a\n':raise ValueError('invalid indexed PNG header')
   im=Image.open(io.BytesIO(raw[4:]));im.load()
   if im.mode!='P' or im.size!=(s[2],s[3]):raise ValueError('indexed PNG dimensions/mode')
   return im.tobytes(),s[2],s[3]
  return unpack_pixels(raw,s[7],s[2]*s[3]),s[2],s[3]

def convert(source,out):
 out=Path(out);(out/'sprites').mkdir(parents=True,exist_ok=True);(out/'.gdignore').touch();a=Archive(source);rows={};entries=[];failures=[];keys={}
 for i,s in enumerate(a.sprites):
  key=f'{s[0]}_{s[1]}'
  try:
   pixels,w,h=a.pixels(i);palette=a.palette(s[11])
   if w*h>16000000:raise ValueError('oversize')
   if max(pixels,default=0)>=len(palette):raise ValueError('palette index out of bounds')
   im=Image.frombytes('P',(w,h),pixels);im.putpalette([c for row in palette for c in row[:3]])
   im.info['transparency']=0;im=im.convert('RGBA');rgba=im.tobytes()
   name=f'sprites/{i:05d}.png';im.save(out/name,compress_level=1)
   row=dict(key=key,path=name,width=w,height=h,axis=[s[4],s[5]],table_index=i,palette=s[11],encoding=s[7],sha256=hashlib.sha256(rgba).hexdigest())
   entries.append(row);rows.setdefault(key,row);keys.setdefault(key,[]).append(i)
  except (ValueError,IndexError,struct.error) as e:failures.append(dict(index=i,key=key,error=str(e)))
  if i%250==0:print('decoded',i,'failed',len(failures),flush=True)
 report=dict(source_sha256=hashlib.sha256(a.data).hexdigest(),sprite_count=len(a.sprites),decoded=len(entries),failures=failures,sprites=rows,entries=entries,duplicate_keys={k:v for k,v in keys.items() if len(v)>1})
 (out/'sprites.json').write_text(json.dumps(report,indent=2))
 print('SFF_RESULT',len(entries),'/',len(a.sprites),'failed',len(failures));print(failures[:5])
 return report
if __name__=='__main__':
 p=argparse.ArgumentParser();p.add_argument('--source',required=True);p.add_argument('--out',required=True);x=p.parse_args();r=convert(x.source,x.out)
 raise SystemExit(1 if r['failures'] else 0)
