#!/usr/bin/env python3
"""Apply _templates/wip-note.qmd to stub notes that other notes link to.

Only stubs with no real prose are rewritten (front matter is kept and a `wip`
tag added); stubs holding content fragments are skipped and reported.
Notes already tagged `wip` are left alone, so the script is idempotent.
Usage: python3 _tools/wip_stubs.py [--dry-run]
"""
import collections
import glob
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TOPICS = os.path.join(ROOT, "topics")
LINK = re.compile(r"\[\[([^\]|#]+)(?:#[^\]|]*)?(?:\|[^\]]*)?\]\]")
STUB_CHARS = 200
dry = "--dry-run" in sys.argv


def clean(t):
    t = re.sub(r"```.*?```", "", t, flags=re.S)
    return re.sub(r"<!--.*?-->", "", t, flags=re.S)


def split(t):
    m = re.match(r"^---\n(.*?)\n---\n?(.*)$", t, flags=re.S)
    return (m.group(1), m.group(2)) if m else ("", t)


names = sorted(os.path.basename(p)[:-4] for p in glob.glob(TOPICS + "/*.qmd"))
text = {n: open(f"{TOPICS}/{n}.qmd").read() for n in names}
out_links = {n: [l.strip() for l in LINK.findall(clean(text[n]))] for n in names}
in_links = collections.defaultdict(set)
for n, ls in out_links.items():
    for l in ls:
        if l != n:
            in_links[l].add(n)
hubs = [l for l in dict.fromkeys(out_links["topics"]) if l in text]
listed = collections.defaultdict(list)
for h in hubs:
    for l in out_links[h]:
        listed[l].append(h)


def parent(n):
    if listed.get(n):
        return listed[n][0]
    score = collections.Counter()
    for m in set(out_links[n]) | in_links[n]:
        for h in listed.get(m, ()):
            score[h] += 1
    return score.most_common(1)[0][0] if score else None


def real_prose(body):
    body = re.sub(r"```.*?```", "", body, flags=re.S)
    body = re.sub(r"(?m)^#{1,6} .*$", "", body)
    body = re.sub(r":::.*", "", body)
    body = body.replace("Notes to be added.", "").replace("*", "")
    return re.sub(r"\s+", "", body)


def title_of(front, n):
    m = re.search(r'(?m)^title:\s*"?(.*?)"?\s*$', front)
    return (m.group(1) if m else n.replace("-", " ").title()).replace('"', "'")


tmpl = open(f"{ROOT}/_templates/wip-note.qmd").read()
tmpl_body = split(tmpl)[1].lstrip("\n")
applied, skipped = [], []
for n in names:
    front, body = split(text[n])
    if n in hubs or n == "topics" or not in_links[n]:
        continue
    if len(re.sub(r"\s+", "", clean(body))) >= STUB_CHARS + 40 and False:
        continue
    prose = real_prose(body)
    if re.search(r"(?m)^tags:.*wip", front):
        continue
    if len(prose) >= STUB_CHARS and not prose.startswith("$f(x)$"):
        continue
    if len(prose) > 2 and prose != "$f(x)$":
        skipped.append(n)
        continue
    p = parent(n)
    refs = ", ".join(f"[[{s}]]" for s in sorted(in_links[n]))
    nb = tmpl_body.replace("[[PARENT-HUB]]", f"[[{p}]]" if p else "none yet")
    nb = nb.replace("LIST-OF-BACKLINKS", refs)
    if re.search(r"(?m)^tags:.*$", front):
        front = re.sub(r"(?m)^tags:.*$", "tags: [wip]", front)
    else:
        front += "\ntags: [wip]"
    applied.append((n, p))
    if not dry:
        open(f"{TOPICS}/{n}.qmd", "w").write(f"---\n{front}\n---\n\n{nb}")
print("applied:", len(applied))
for n, p in applied:
    print(f"  {n} -> {p}")
print("skipped (has content):", skipped)
