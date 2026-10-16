"""Validator for exactly the keywords used by the supplied handoff schemas.
Unsupported keywords fail explicitly rather than silently weakening validation.
"""
import re, math
def check(value,schema,where='$'):
    errors=[]
    supported={'$schema','title','description','type','required','properties','additionalProperties','const','enum','prefixItems','items','minItems','maxItems','uniqueItems','pattern','minimum','exclusiveMinimum'}
    for keyword in schema:
        if keyword not in supported: errors.append(f'{where}: unsupported schema keyword {keyword}')
    types={'object':dict,'array':list,'string':str,'integer':int,'number':(int,float),'boolean':bool}
    expected=schema.get('type')
    if expected and (not isinstance(value,types[expected]) or expected in ('integer','number') and isinstance(value,bool)):
        return [f'{where}: type {expected}']
    if 'const' in schema and value!=schema['const']: errors.append(f'{where}: const')
    if 'enum' in schema and value not in schema['enum']: errors.append(f'{where}: enum')
    if isinstance(value,dict):
        for key in schema.get('required',[]):
            if key not in value: errors.append(f'{where}: required {key}')
        props=schema.get('properties',{})
        for key,item in value.items():
            child=props.get(key,schema.get('additionalProperties',{}))
            if isinstance(child,dict): errors.extend(check(item,child,f'{where}.{key}'))
            elif child is False: errors.append(f'{where}: unknown {key}')
    if isinstance(value,list):
        if len(value)<schema.get('minItems',0) or len(value)>schema.get('maxItems',float('inf')): errors.append(f'{where}: length')
        if schema.get('uniqueItems') and len({repr(x) for x in value})!=len(value): errors.append(f'{where}: unique')
        for index,item in enumerate(value):
            prefix=schema.get('prefixItems',[])
            errors.extend(check(item,prefix[index] if index<len(prefix) else schema.get('items',{}),f'{where}[{index}]'))
    if isinstance(value,str) and 'pattern' in schema and not re.search(schema['pattern'],value): errors.append(f'{where}: pattern')
    if type(value) in (int,float):
        if not math.isfinite(value): errors.append(f'{where}: nonfinite')
        if value<schema.get('minimum',-float('inf')): errors.append(f'{where}: minimum')
        if value<=schema.get('exclusiveMinimum',-float('inf')): errors.append(f'{where}: exclusiveMinimum')
    return errors
