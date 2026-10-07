"""Check the wow-professions.com Forever guides (tools/guides.txt) for changes.

    python tools/check_guides.py          fetch every guide, show what changed since the last snapshot
    python tools/check_guides.py --save   ...and make today's version the new snapshot

Snapshots are the guides' text, kept in tools/guides/ (gitignored - it's the site's content).
A change means the matching Data/*Route.lua needs re-checking against the guide: step ranges,
craft counts, choices, notes, and the plan totals against the guide's shopping list.
"""
import difflib, html, os, re, sys, urllib.request

HERE = os.path.dirname(os.path.abspath(__file__))
SNAP = os.path.join(HERE, 'guides')


def guides():
    for line in open(os.path.join(HERE, 'guides.txt'), encoding='utf8'):
        line = line.strip()
        if line and not line.startswith('#'):
            parts = line.split()
            yield parts[0], parts[1], parts[2] if len(parts) > 2 else ''


def to_text(page):
    s = re.sub(r'<(script|style)[^>]*>.*?</\1>', '', page, flags=re.S)
    s = re.sub(r'<br\s*/?>|</p>|</li>|</h\d>|</tr>|</div>', '\n', s)
    s = re.sub(r'<[^>]+>', ' ', s)
    s = html.unescape(s)
    s = re.sub(r'[ \t]+', ' ', s)
    s = re.sub(r'\n\s*\n+', '\n', s)
    i, j = s.find('Table of Contents'), s.find('(Return to Top)')
    return s[i if i >= 0 else 0:j if j > 0 else None]


def main():
    save = '--save' in sys.argv
    os.makedirs(SNAP, exist_ok=True)
    for name, url, routes in guides():
        req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
        try:
            text = to_text(urllib.request.urlopen(req, timeout=40).read().decode('utf8', 'replace'))
        except Exception as e:
            print(f'{name}: could not fetch ({e})')
            continue
        path = os.path.join(SNAP, name + '.txt')
        old = open(path, encoding='utf8').read() if os.path.exists(path) else None
        if old is None:
            print(f'{name}: no snapshot yet')
        elif old == text:
            print(f'{name}: unchanged')
        else:
            diff = [l for l in difflib.unified_diff(old.splitlines(), text.splitlines(), lineterm='', n=1)
                    if not l.startswith(('---', '+++'))]
            print(f'{name}: CHANGED -> re-check {routes}')
            for l in diff:
                print('    ' + l[:300])
        if save:
            open(path, 'w', encoding='utf8').write(text)


if __name__ == '__main__':
    main()
