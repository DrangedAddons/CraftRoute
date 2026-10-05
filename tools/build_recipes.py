"""Builds CraftRoute/Data/<Profession>Recipes.lua.

Sources:
  * endgametools.com recipe page (saved HTML) - reagents, colour thresholds, stats, category, crafted item.
  * TrainerSpells addon's Forever data (in-client datamined) - learn skill for trainer + pattern recipes, source text.
Usage: python build_recipes.py <endgametools.html> <TrainerSpells forever dir> <Profession> <out.lua> [ahledger.html]
"""
import re, html, sys, os

page, tsdir, prof, out = sys.argv[1:5]
s = open(page, encoding='utf8').read()

def lua_str(v):
    return '"' + v.replace(chr(92), chr(92) * 2).replace('"', chr(92) + '"') + '"'

def text(fragment):
    return html.unescape(re.sub(r'<[^>]+>', '', fragment)).strip()

# ---- TrainerSpells data: spellID -> learn skill / source
learn, source = {}, {}
# <Prof>.lua nests skill/spell keys at indent 4/8; <Prof>Recipes.lua at 8/12 with source at 16.
def parse_ts(path, indent, with_source):
    if not os.path.exists(path):
        return
    skill = None; spell = None
    for line in open(path, encoding='utf8'):
        m = re.match(r'^ {%d}\[(\d+)\] = \{' % indent, line)
        if m: skill = int(m.group(1)); continue
        m = re.match(r'^ {%d}\[(\d+)\] = \{' % (indent + 4), line)
        if m:
            spell = int(m.group(1)); learn.setdefault(spell, skill); continue
        m = re.match(r'^ {%d}source = "(.*)",?\s*$' % (indent + 8), line)
        if m and with_source and spell: source.setdefault(spell, m.group(1))
parse_ts(os.path.join(tsdir, prof.replace(' ', '') + '.lua'), 4, False)
for sp in list(learn): source[sp] = 'Trainer'
parse_ts(os.path.join(tsdir, prof.replace(' ', '') + 'Recipes.lua'), 8, True)

# Per-source faction from TrainerSpells' sourceLocations, so the addon can hide the other
# faction's vendors/quests. Output uses CraftRoute's {H:...}/{A:...} markup.
def parse_locations(path):
    locs = {}
    if not os.path.exists(path):
        return locs
    spell = None; cur = None
    for line in open(path, encoding='utf8'):
        m = re.match(r'^ {12}\[(\d+)\] = \{', line)
        if m: spell = int(m.group(1)); continue
        if re.match(r'^ {20}\{\s*$', line) and spell:
            cur = {}; locs.setdefault(spell, []).append(cur); continue
        m = re.match(r'^ {24}(\w+) = "?(.*?)"?,?\s*$', line)
        if m and cur is not None: cur[m.group(1)] = m.group(2)
    return locs

def faction_source(locs):
    vendors, quests = [], []
    for l in locs:
        if 'questName' in l:
            entry = l['questName']
            target = quests
        elif 'npcName' in l:
            entry = '%s (%s)' % (l['npcName'], l.get('zoneName', '?'))
            target = vendors
        else:
            continue
        f = l.get('faction')
        entry = '{%s:%s}' % ('H' if f == 'Horde' else 'A', entry) if f in ('Horde', 'Alliance') else entry
        if entry not in target: target.append(entry)
    parts = []
    if vendors: parts.append('Sold by ' + ', '.join(vendors))
    if quests: parts.append('Quest reward: ' + ', '.join(quests))
    return ' / '.join(parts)

for sp, locs in parse_locations(os.path.join(tsdir, prof.replace(' ', '') + 'Recipes.lua')).items():
    fs = faction_source(locs)
    if fs and any('{' in x for x in [fs]) and source.get(sp, '').startswith(('Sold by', 'Quest reward')):
        source[sp] = fs

# ---- ahledger profession table (optional 5th arg): spellID -> learn skill, yield.
# Preferred learn source: TrainerSpells carries some stale Classic Era skill values.
ahl_learn, ahl_yield = {}, {}
if len(sys.argv) > 5 and os.path.exists(sys.argv[5]):
    a = open(sys.argv[5], encoding='utf8').read()
    for row in re.findall(r'<tr class="border-b border-line align-top[^"]*">(.*?)</tr>', a, flags=re.S):
        row = row.replace('<!-- -->', '')
        m = re.search(r'href="/wow-forever/recipes/(\d+)-', row)
        tds = re.findall(r'<td[^>]*>(.*?)</td>', row, flags=re.S)
        if not m or len(tds) < 3: continue
        sp = int(m.group(1))
        sk = re.sub(r'<[^>]+>', '', tds[1]).strip()
        if sk.isdigit(): ahl_learn[sp] = int(sk)
        mk = re.match(r'(\d+)\s*\S', re.sub(r'<[^>]+>', '', tds[2]).strip())
        if mk and int(mk.group(1)) > 1: ahl_yield[sp] = int(mk.group(1))

# ---- recipe page
recipes = []; names = {}
for sec in re.finditer(r"<section id='c-\d+' class='recipe-category'.*?</section>", s, flags=re.S):
    sect = sec.group(0)
    cat = text(re.search(r"<span class='type-title[^']*'>(.*?)</span>", sect).group(1))
    for li in re.finditer(r"<li id='r(\d+)' class='recipe' data-y='(\d+)' data-g='(\d+)' data-x='(\d+)'>(.*?)</li>", sect, flags=re.S):
        spell, y, g, x, body = int(li.group(1)), int(li.group(2)), int(li.group(3)), int(li.group(4)), li.group(5)
        t = re.search(r"<p class='recipe-title'><a href='/en/wow-forever/items/(\d+)' class='text-q(\d)'>(.*?)</a>", body)
        if t:
            item, q, name = int(t.group(1)), int(t.group(2)), text(t.group(3))
        else:  # unreleased/unlinked crafted item - keep the recipe, no item ID
            item, q = 0, 1
            name = text(re.search(r"<p class='recipe-title'><span>(.*?)</span>", body).group(1))
        title_yield = 1
        m = re.match(r'(\d+)\s*\S\s*(.+)', name)  # "2 × Cured Rugged Hide"
        if m: title_yield, name = int(m.group(1)), m.group(2)
        sub = re.search(r"<span class='recipe-sub'>(.*?)</span>", body)
        if sub: name += ' (' + text(sub.group(1)) + ')'
        if item: names[item] = name
        paras = re.findall(r"<p>(.*?)</p>", body, flags=re.S)
        stats = ''; reagents = []; pattern = None; pskill = None
        for p in paras:
            if p.startswith('Reagents:'):
                for a in re.finditer(r"<a href='/en/wow-forever/items/(\d+)'[^>]*>(.*?)</a>", p):
                    rt = text(a.group(2))
                    m = re.match(r'(\d+)\s*\S\s*(.*)', rt)
                    n, rn = (int(m.group(1)), m.group(2)) if m else (1, rt)
                    reagents.append((int(a.group(1)), n)); names[int(a.group(1))] = rn.strip()
            elif p.startswith('Learnt from'):
                m = re.search(r"<a [^>]*>(.*?)</a>\s*\(skill (\d+)\)", p)
                if m: pattern, pskill = text(m.group(1)), int(m.group(2))
            else:
                stats = (stats + ' · ' if stats else '') + text(p)
        # A pattern can demand more skill to read than the recipe's orange point - take the higher.
        known = [v for v in (ahl_learn.get(spell), pskill) if v is not None]
        ls = max(known) if known else learn.get(spell)
        src = source.get(spell) or (pattern and 'Pattern') or 'Unknown'
        recipes.append(dict(spell=spell, item=item, q=q, name=name, cat=cat, stats=stats, reagents=reagents,
                            learn=ls, y=y, g=g, x=x, src=src, pattern=pattern, makes=ahl_yield.get(spell, title_yield)))

# Hand fixes for gaps in the sources (verified against the wow-professions guides).
OVERRIDES = {
    'Cooking': {
        'Mithril Headed Trout': {'item': 8364},           # endgametools has no item link
        'Charred Wolf Meat': {'learn': 1, 'src': 'Trainer'},
        'Roasted Boar Meat': {'learn': 1, 'src': 'Trainer'},
        'Herb Baked Egg': {'learn': 1, 'src': 'Trainer'},
    },
    # Smelting recipes have no item link on endgametools; bar IDs taken from the other professions' reagents.
    'Mining': {
        'Smelt Copper': {'item': 2840}, 'Smelt Tin': {'item': 3576}, 'Smelt Bronze': {'item': 2841},
        'Smelt Silver': {'item': 2842}, 'Smelt Iron': {'item': 3575}, 'Smelt Steel': {'item': 3859},
        'Smelt Gold': {'item': 3577}, 'Smelt Mithril': {'item': 3860}, 'Smelt Dark Iron': {'item': 11371},
        'Smelt Truesilver': {'item': 6037}, 'Smelt Thorium': {'item': 12359},
        'Smelt Azerothium': {'item': 249726}, 'Smelt Heavy Thorium': {'item': 251291},
    },
}
for r in recipes:
    r.update(OVERRIDES.get(prof, {}).get(r['name'], {}))
    if r['item'] and r['name'] and r['item'] not in names: names[r['item']] = r['name']
missing = [r['name'] for r in recipes if r['learn'] is None]
# No learn skill anywhere: estimate from the yellow point (orange is usually ~40 below).
for r in recipes:
    if r['learn'] is None:
        r['learn'] = max(1, r['y'] - 40) if r['y'] > 0 else 1
with open(out, 'w', encoding='utf8', newline='\n') as f:
    f.write('-- Generated by CraftRoute-tools/build_recipes.py - do not edit by hand.\n')
    f.write('-- learn = skill needed to learn/craft (orange); y/g/x = yellow/green/grey thresholds.\n')
    f.write('local _, CR = ...\nCR.RegisterRecipes(%s, {\n' % lua_str(prof))
    for r in sorted(recipes, key=lambda r: ((r['learn'] if r['learn'] is not None else r['y']), r['name'])):
        reag = ', '.join('{%d, %d}' % rg for rg in r['reagents'])
        learn_v = r['learn'] if r['learn'] is not None else 'nil'
        f.write('  [%d] = { name = %s, item = %d, q = %d, cat = %s, learn = %s, y = %d, g = %d, x = %d, src = %s,%s%s%s reagents = { %s } },\n' % (
            r['spell'], lua_str(r['name']), r['item'], r['q'], lua_str(r['cat']), learn_v, r['y'], r['g'], r['x'], lua_str(r['src']),
            (' makes = %d,' % r['makes']) if r['makes'] > 1 else '',
            (' pattern = %s,' % lua_str(r['pattern'])) if r['pattern'] else '',
            (' stats = %s,' % lua_str(r['stats'])) if r['stats'] else '', reag))
    f.write('}, {\n')
    for iid in sorted(names):
        f.write('  [%d] = %s,\n' % (iid, lua_str(names[iid])))
    f.write('})\n')
print(len(recipes), 'recipes;', len(missing), 'without learn skill:', missing[:30])
