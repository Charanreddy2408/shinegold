import json
import re
from pathlib import Path

root = Path("lib")
files = []
patterns = [
    re.compile(r"Text\(\s*'([^']{2,120})'"),
    re.compile(r'Text\(\s*"([^"]{2,120})"'),
    re.compile(r"label:\s*'([^']+)'"),
    re.compile(r"title:\s*'([^']+)'"),
    re.compile(r"subtitle:\s*'([^']+)'"),
    re.compile(r"labelText:\s*'([^']+)'"),
    re.compile(r"hintText:\s*'([^']+)'"),
    re.compile(r"tooltip:\s*'([^']+)'"),
]

skip = {"l10n", "app_localizations"}

for p in root.rglob("*.dart"):
    s = str(p).replace("\\", "/")
    if any(x in s for x in skip):
        continue
    text = p.read_text(encoding="utf-8", errors="ignore")
    hits = []
    for pat in patterns:
        for m in pat.finditer(text):
            val = m.group(1)
            if re.search(r"[A-Za-z]", val):
                hits.append(val)
    if hits:
        # unique preserve order
        seen = set()
        uniq = []
        for h in hits:
            if h not in seen:
                seen.add(h)
                uniq.append(h)
        files.append((s, len(uniq), uniq))

files.sort(key=lambda x: -x[1])
print(f"files_with_english {len(files)}")
for path, n, hits in files:
    print(f"{n:3d} {path}")
    for h in hits[:12]:
        print(f"    - {h[:90]}")
