"""Lossless local SND extraction, CNS provenance and bounded gameplay cue manifest."""
from pathlib import Path
import struct, hashlib, io, wave, json, re, shutil

ROOT = Path(__file__).resolve().parents[2]
SOURCE = Path('D:/SelfProject/RougeLite/assets/characters/atyu/Yuta Manga v1')

def extract(data):
    if data[:12] != b'ElecbyteSnd\0': raise ValueError('invalid SND signature')
    count, offset = struct.unpack_from('<II', data, 16)
    seen = set(); result = {}
    for _ in range(count):
        if offset in seen or offset < 24 or offset + 16 > len(data): raise ValueError('invalid linked SND header')
        seen.add(offset)
        nxt, size, group, index = struct.unpack_from('<IIII', data, offset)
        if size < 12 or offset + 16 + size > len(data): raise ValueError('truncated SND data')
        blob = data[offset+16:offset+16+size]
        if blob[:4] != b'RIFF' or blob[8:12] != b'WAVE': raise ValueError('non-WAV SND entry')
        key = f'{group}_{index}'
        if key in result:
            key += f'_duplicate_{len(result)}' # preserve every occurrence; runtime explicitly uses first occurrence
        with wave.open(io.BytesIO(blob)) as w:
            details = dict(channels=w.getnchannels(), rate=w.getframerate(), width=w.getsampwidth(), frames=w.getnframes(), seconds=w.getnframes()/w.getframerate())
            if len(w.readframes(w.getnframes())) != details['frames']*details['channels']*details['width']: raise ValueError('truncated PCM')
        result[key] = (blob, details)
        offset = nxt
    if offset not in (0,len(data)): raise ValueError('SND count does not terminate chain')
    return result

def audit_cns():
    events = []
    for file in sorted(SOURCE.glob('*.cns')):
        parts = re.split(r'(?im)^\s*\[statedef\s+(-?\d+)\s*\]',file.read_text(errors='replace'))
        for i in range(1,len(parts),2):
            for block in re.split(r'(?im)(?=^\s*\[state\s)',parts[i+1]):
                fields = {}
                for line in block.splitlines():
                    line = line.split(';',1)[0].strip()
                    if '=' in line:
                        k,v=line.split('=',1);fields.setdefault(k.strip().lower(),[]).append(v.strip())
                kind=fields.get('type',[''])[0].lower()
                if kind not in ['playsnd','hitdef','superpause']: continue
                for key in ['value'] if kind=='playsnd' else ['hitsound','guardsound'] if kind=='hitdef' else ['sound']:
                    for value in fields.get(key,[]):
                        match=re.fullmatch(r'[sS]\s*(\d+)\s*,\s*(\d+)',value)
                        if match: events.append(dict(file=file.name,state=int(parts[i]),controller=kind,field=key,sound='_'.join(match.groups()),triggers={k:v for k,v in fields.items() if k.startswith('trigger')},source_volume=fields.get('volume',fields.get('volumescale'))))
    return events

def build():
    data=(SOURCE/'Ichigo_Bankai.snd').read_bytes(); entries=extract(data)
    archive=ROOT/'experiments/mugen_atyu/audio';archive.mkdir(parents=True,exist_ok=True)
    (archive/'.gdignore').write_text('')
    inventory=[]
    for key,(blob,details) in entries.items():
        (archive/f'{key}.wav').write_bytes(blob)
        inventory.append(dict(key=key,sha256=hashlib.sha256(blob).hexdigest(),**details))
    # No combat timings changed. Long MUGEN cinematic triggers intentionally omitted.
    cues={
      'basic':[('0_4',2/60,-14)],
      'combo_1':[('0_2',0,-14)],
      'combo_2':[('0_4',2/60,-14)],
      'cast_j':[('5_35',0,-17)], 'cone':[('0_2',0,-14)],
      'cast_k':[('5_38',0,-18)], 'control':[('500_12',0,-20)],
      'cast_l':[('500_11',2/60,-18)], 'companion':[('500_16',0,-20)],
      'companion_attack':[('500_13',0,-20)],
      'cast_i':[('0_4',0,-18)], 'charged_beam':[('5_21',0,-18)],
      'impact':[('1_23',0,-20)]}
    out=ROOT/'assets/private_atyu/audio';out.mkdir(parents=True,exist_ok=True)
    profile={}
    for cue,items in cues.items():
        profile[cue]=[]
        for key,delay,db in items:
            if key not in entries: raise ValueError('missing mapped sound '+key)
            shutil.copyfile(archive/f'{key}.wav',out/f'{key}.wav')
            profile[cue].append(dict(path=f'res://assets/private_atyu/audio/{key}.wav',delay=delay,db=db))
    (out/'cues.json').write_text(json.dumps(profile,indent=2))
    report=dict(source_sha256=hashlib.sha256(data).hexdigest(),count=len(entries),inventory=inventory,cns_events=[dict(e, exists=e['sound'] in entries) for e in audit_cns()],cues=profile,rights='Supplied third-party mod; private local testing only, redistribution rights unverified.')
    (ROOT/'docs/atyu_audit/audio_inventory.json').write_text(json.dumps(report,indent=2))
    print('AUDIO_EXTRACTED',len(entries),'runtime',len(list(out.glob('*.wav'))))

if __name__=='__main__': build()

