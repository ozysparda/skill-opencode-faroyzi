"""Probe daftar kandidat (file argumen) -> tools_found2.json"""
import json
import sys
from concurrent.futures import ThreadPoolExecutor, as_completed

from hunt import probe

src = sys.argv[1] if len(sys.argv) > 1 else "candidates.txt"
out_file = sys.argv[2] if len(sys.argv) > 2 else "tools_found.json"

with open(src, encoding="utf-8") as f:
    urls = [l.strip() for l in f if l.strip() and not l.startswith("#")]

print(f"[probe] {len(urls)} URL dari {src}", flush=True)
results = []
with ThreadPoolExecutor(max_workers=10) as ex:
    futs = {ex.submit(probe, u): u for u in urls}
    for i, f in enumerate(as_completed(futs), 1):
        r = f.result()
        results.append(r)
        if r.get("verdict") == "kandidat":
            print(
                f"[{i}/{len(urls)}] {r['url'][:58]:60s} cap={r.get('captcha','?'):9s} "
                f"likes={r.get('like_mentions'):2d} un={int(r.get('username_based',False))} "
                f"mail={int(r.get('needs_email',False))} f={len(r.get('fields',[]))}",
                flush=True,
            )

with open(out_file, "w", encoding="utf-8") as f:
    json.dump(results, f, indent=2, ensure_ascii=False)

good = [r for r in results if r.get("verdict") == "kandidat"]
print(f"\n[probe] kandidat: {len(good)}/{len(results)} -> {out_file}")
with open(out_file, encoding="utf-8") as f:
    data = json.load(f)
for g in good:
    fields = [(x.get("name") or x.get("id"), (x.get("ph") or "")[:26]) for x in (g.get("fields") or [])[:6]]
    print(f"  {g['url']}")
    print(f"     cap={g.get('captcha')} {g.get('sitekeys', [])[:1]} un={g.get('username_based')} fields={fields}")
    print(f"     btns={g.get('buttons', [])[:5]}")
