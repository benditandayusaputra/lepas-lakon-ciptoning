import re, os, sys, glob
root = sys.argv[1] if len(sys.argv) > 1 else '.'
files = glob.glob(os.path.join(root, 'scripts', '**', '*.gd'), recursive=True)
src = {f: open(f).read() for f in files}
def defs(text):
    names = set(re.findall(r'^(?:static\s+)?func\s+(\w+)', text, re.M))
    names |= set(re.findall(r'^(?:static\s+)?(?:const|var)\s+(\w+)', text, re.M))
    names |= set(re.findall(r'^signal\s+(\w+)', text, re.M))
    names |= set(re.findall(r'^enum\s+(\w+)', text, re.M))
    return names
by_class = {}
for f, t in src.items():
    m = re.search(r'^class_name\s+(\w+)', t, re.M)
    if m: by_class[m.group(1)] = defs(t)
autoload = {'Bobot': 'scripts/autoload/bobot.gd', 'Game': 'scripts/autoload/game.gd', 'Music': 'scripts/autoload/music.gd', 'Sfx': 'scripts/autoload/sfx.gd'}
for k, v in autoload.items():
    by_class[k] = defs(src[os.path.join(root, v)])
errors = 0
builtin_ok = {'new'}
for f, t in src.items():
    code = re.sub(r'"[^"\n]*"', '""', t)
    code = re.sub(r'#.*', '', code)
    for cls, mem in re.findall(r'\b([A-Z]\w+)\.(\w+)', code):
        if cls in by_class and mem not in by_class[cls] and mem not in builtin_ok:
            print(f'{f}: {cls}.{mem} undefined'); errors += 1
    for cls in set(re.findall(r'\b([A-Z][a-z]\w*)\.new\(', code)):
        pass
# Sfx keys
sfx = src[os.path.join(root, 'scripts/autoload/sfx.gd')]
keys = set(re.findall(r'^\t"(\w+)":', sfx, re.M))
for f, t in src.items():
    for k in re.findall(r'Sfx\.play\("(\w+)"', t):
        if k not in keys: print(f'{f}: Sfx key {k} missing'); errors += 1
# level.call names
lvl = src[os.path.join(root, 'scripts/game/level.gd')]
lvl_defs = defs(lvl)
for f, t in src.items():
    for k in re.findall(r'level\.(?:call|get)\("(\w+)"', t):
        if k not in lvl_defs: print(f'{f}: level.{k} missing'); errors += 1
# player./p. method calls vs Arjuna
arj = by_class['Arjuna'] | {'global_position','position','is_on_floor','get_slide_collision_count','get_slide_collision','visible','velocity','get_rid','z_index','scale'}
for f, t in src.items():
    for k in re.findall(r'\b(?:player|p)\.(\w+)', t):
        if k not in arj: print(f'{f}: Arjuna.{k} ?'); errors += 1
# preload/load paths
for f, t in src.items():
    for pth in re.findall(r'(?:preload|load)\("res://([^"]+)"\)', t):
        if '%' in pth: continue
        if not os.path.exists(os.path.join(root, pth)): print(f'{f}: missing {pth}'); errors += 1
print('errors:', errors)
