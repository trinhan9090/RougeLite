"""Read-only structural audit; does not decode sprites or execute MUGEN code."""
from pathlib import Path
import argparse,hashlib,json,re,collections,zipfile,xml.etree.ElementTree as ET
p=argparse.ArgumentParser();p.add_argument('--source',type=Path,required=True);p.add_argument('--out',type=Path,required=True);a=p.parse_args()
root=a.source.resolve();out=a.out.resolve();out.mkdir(parents=True,exist_ok=True)
def read(path):return path.read_text(encoding='utf-8-sig',errors='replace')
files=[dict(path=f.relative_to(root).as_posix(),bytes=f.stat().st_size,sha256=hashlib.sha256(f.read_bytes()).hexdigest()) for f in sorted(root.rglob('*')) if f.is_file()]
primary=root/'Yuta Manga v1.def';section='';dependencies=[]
for line in read(primary).splitlines():
 line=line.split(';',1)[0].strip()
 if line.startswith('['):section=line.lower()
 elif section=='[files]' and '=' in line:
  key,value=line.split('=',1);value=value.strip().strip('"')
  dependencies.append(dict(key=key.strip(),path=value,exists=(root/value).is_file()))
air=read(root/'Ichigo_Bankai.air');blocks=re.split(r'(?im)^\s*\[begin\s+action\s+(-?\d+)\s*\]',air);actions=[]
for i in range(1,len(blocks),2):
 rows=[]
 for line in blocks[i+1].splitlines():
  value=line.split(';',1)[0].strip()
  if re.match(r'^-?\d+\s*,\s*-?\d+\s*,',value):
   tokens=[x.strip() for x in value.split(',')]
   if len(tokens)>=5:rows.append(dict(raw=value,group=tokens[0],index=tokens[1],x=tokens[2],y=tokens[3],ticks=tokens[4],extra=tokens[5:]))
 actions.append(dict(id=int(blocks[i]),rows=rows))
counts=collections.Counter(x['id'] for x in actions);states=[]
for f in sorted(root.glob('*.cns')):
 parts=re.split(r'(?im)^\s*\[statedef\s+(-?\d+)\s*\]',read(f))
 for i in range(1,len(parts),2):
  body=parts[i+1];state_header=re.split(r'(?im)^\s*\[',body,maxsplit=1)[0]
  m=re.search(r'(?im)^\s*anim\s*=\s*([^;\r\n]+)',state_header);expr=m.group(1).strip() if m else None
  literal=int(expr) if expr and re.fullmatch(r'-?\d+',expr) else None
  states.append(dict(file=f.name,state=int(parts[i]),anim_expression=expr,literal_anim=literal,air_occurrences=counts.get(literal,0) if literal is not None else None))
sff=root/'Ichigo_Bankai.sff'
with sff.open('rb') as f:header=f.read(32)
spec=root.parent/'ATYU_CHARACTER_AND_IMPORT_SPEC.docx'
with zipfile.ZipFile(spec) as z:
 tree=ET.fromstring(z.read('word/document.xml'));paragraphs=[''.join(x.itertext()) for x in tree.iter('{http://schemas.openxmlformats.org/wordprocessingml/2006/main}t')]
(out/'docx_text.txt').write_text('\n'.join(paragraphs),encoding='utf-8')
report=dict(source=str(root),scope='read-only structural audit; images NOT DECODED; gameplay NOT IMPLEMENTED',files=files,dependencies=dependencies,sff_magic=header[:12].decode('ascii',errors='replace'),sff_version_bytes=list(header[12:16]),air_declarations=len(actions),air_unique_ids=len(counts),duplicate_ids={str(k):v for k,v in counts.items() if v>1},air_frame_rows=sum(len(x['rows']) for x in actions),negative_duration_rows=sum(r['ticks']=='-1' for x in actions for r in x['rows']),states=states,actions=actions,docx_text_characters=sum(map(len,paragraphs)))
assert all(x['exists'] for x in dependencies),'missing DEF dependency'
assert header[:12]==b'ElecbyteSpr\x00','unexpected SFF signature'
assert len(actions)>0 and len(states)>0,'no actions/states parsed'
for name in ('0','20','200','1150','8065','8067','2044'):
 report.setdefault('candidate_action_occurrences',{})[name]=counts.get(int(name),0)
(out/'inventory.json').write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding='utf-8')
print(json.dumps({k:report[k] for k in ('air_declarations','air_unique_ids','duplicate_ids','air_frame_rows','sff_version_bytes','candidate_action_occurrences','docx_text_characters')},ensure_ascii=False))
print(f'INSPECTION_OK files={len(files)} dependencies={len(dependencies)} states={len(states)}; sprites NOT DECODED')
