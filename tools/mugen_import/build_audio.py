"""Lossless local SND extraction used by MUGEN source audits."""
import struct, io, wave

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
