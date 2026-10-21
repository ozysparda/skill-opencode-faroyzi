"""
Hunter: cari + probe halaman "free instagram likes" di internet.

1) Ambil URL kandidat dari DuckDuckGo (beberapa query varied)
2) Probe tiap URL: apakah ada form free-likes, field apa, sitekey apa, tombol submit apa
3) Tulis hasil ke tools_found.json

Jalankan:  python hunt.py --max 120
"""
import argparse
import json
import os
import re
import sys
import time
import urllib.parse
from concurrent.futures import ThreadPoolExecutor, as_completed

import requests

UA = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0 Safari/537.36"

QUERIES = [
    "free instagram likes tool no password no signup",
    "\"free instagram likes\" trial 100 likes instant",
    "\"free instagram likes\" paste post link email 2026",
    "\"free instagram likes\" demo order panel",
    "free instagram likes test service no survey site",
    "\"free instagram likes\" 50 likes daily tool",
    "\"get free instagram likes\" no card tool page",
    "sm panel free tools instagram likes trial",
    "\"free instagram likes\" 10 20 30 likes select",
    "\"free instagram likes\" every 24 hours tool",
    "free instagram likes generator real likes no password 2026",
    "\"free instagram likes\" site review panel free trial",
    "\"free instagram likes\" instant delivery signup free",
    "\"instagram free likes\" trial page no login",
    "\"free likes\" instagram smm tool free offer",
    "grow your instagram free likes tool trial page",
]

BLOCK = (
    "/login",
    "/register",
    "/signup",
    "/blog/",
    "/news/",
    "/review",
    "/tag/",
    "/category/",
    "/author/",
    "/privacy",
    "/terms",
    "/contact",
    "/faq",
    "/guide",
    "/how-to",
    "/what-is",
    "/check-likes",
    "/counter",
    "/hashtag",
    "/bio-",
    "/caption",
    "/calculator",
    "/viewer",
    "/analyzer",
)

OUT = "tools_found.json"


def ddg(query):
    """Ambil URL dari mesin pencari (Bing utama, DDG + Mojeek cadangan).

    Catatan: DDG HTML di environment ini_certificate kedaluwarsa,
    jadi Bing yang dipakai sebagai sumber utama.
    """
    urls = set()
    q = urllib.parse.quote_plus(query)

    def harvest_bing():
        try:
            r = requests.get(
                f"https://www.bing.com/search?q={q}&count=30",
                headers={"User-Agent": UA, "Accept-Language": "en-US,en;q=0.9"},
                timeout=25,
            )
            # hasil utama: <li class="b_algo"> <h2><a href="...">
            for m in re.finditer(r'<li class="b_algo".*?<h2><a href="(https?://[^"]+)"', r.text, re.S):
                urls.add(m.group(1))
            for m in re.finditer(r'<h2><a[^>]+href="(https?://[^"]+)"', r.text):
                urls.add(m.group(1))
        except Exception:
            pass

    def harvest_ddg():
        try:
            r = requests.post(
                "https://html.duckduckgo.com/html/",
                data={"q": query},
                headers={"User-Agent": UA},
                timeout=25,
            )
            for m in re.finditer(r'uddg=([^"&]+)', r.text):
                u = urllib.parse.unquote(m.group(1))
                if u.startswith("http"):
                    urls.add(u)
        except Exception:
            pass

    def harvest_mojeek():
        try:
            r = requests.get(
                f"https://www.mojeek.com/search?q={q}",
                headers={"User-Agent": UA},
                timeout=25,
            )
            for m in re.finditer(r'<a href="(https?://[^"]+)"', r.text):
                u = m.group(1)
                if "mojeek" not in u:
                    urls.add(u)
        except Exception:
            pass

    harvest_bing()
    if len(urls) < 5:
        harvest_ddg()
    if len(urls) < 5:
        harvest_mojeek()
    return urls


def normalize(u):
    p = urllib.parse.urlparse(u)
    if p.netloc.endswith("duckduckgo.com") or p.netloc.endswith("bing.com"):
        return None
    return f"{p.scheme}://{p.netloc}{p.path}"


def probe(url):
    """Ambil info form dari halaman."""
    out = {"url": url}
    try:
        r = requests.get(
            url,
            headers={"User-Agent": UA, "Accept-Language": "en-US,en;q=0.9"},
            timeout=25,
            allow_redirects=True,
        )
        html = r.text
        out["status"] = r.status_code
        out["final"] = r.url
        low = html.lower()

        if r.status_code >= 400 or "404" in low[:3000] and "instagram" not in low:
            out["verdict"] = "dead"
            return out

        # judul
        t = re.search(r"<title[^>]*>(.*?)</title>", html, re.S | re.I)
        out["title"] = re.sub(r"\s+", " ", t.group(1)).strip()[:110] if t else ""

        # apakah halaman free instagram likes?
        like_words = len(re.findall(r"free instagram likes", low))
        out["like_mentions"] = like_words
        if like_words == 0 and "free ig likes" not in low:
            out["verdict"] = "bukan-halaman-likes"
            return out

        # ada input non-hidden?
        inputs = re.findall(
            r"<input\b[^>]*>", html, re.I
        )
        fields = []
        for tag in inputs:
            if "hidden" in tag.lower():
                continue
            nm = re.search(r'name=["\']([^"\']+)', tag, re.I)
            ph = re.search(r'placeholder=["\']([^"\']+)', tag, re.I)
            it = re.search(r'type=["\']([^"\']+)', tag, re.I)
            tid = re.search(r'id=["\']([^"\']+)', tag, re.I)
            fields.append(
                {
                    "type": (it.group(1) if it else "text").lower(),
                    "name": nm.group(1) if nm else "",
                    "id": tid.group(1) if tid else "",
                    "ph": (ph.group(1) if ph else "")[:40],
                }
            )
        out["fields"] = fields[:12]

        # sitekey
        keys = set(re.findall(r"0x[0-9A-Za-z]{20,}", html))
        keys |= set(re.findall(r"6L[A-Za-z0-9_-]{30,}", html))
        out["sitekeys"] = [k for k in keys if len(k) < 80][:4]
        out["captcha"] = "turnstile" if any(k.startswith("0x") for k in out["sitekeys"]) else (
            "recaptcha" if any(k.startswith("6L") for k in out["sitekeys"]) else "none"
        )

        # tombol submit
        btns = re.findall(r"<button[^>]*>(.*?)</button>", html, re.S | re.I)
        texts = []
        for b in btns:
            tt = re.sub(r"<[^>]+>", " ", b)
            tt = re.sub(r"\s+", " ", tt).strip()
            if tt:
                texts.append(tt[:48])
        out["buttons"] = texts[:10]

        # form action / api endpoint
        eps = set(re.findall(r"['\"](/api/[a-zA-Z0-9_\-/]{3,50})['\"]", html))
        eps |= set(re.findall(r"['\"](/[a-zA-Z0-9_\-/]*(?:free[_-]?likes|free[_-]?tool|free[_-]?trial)[a-zA-Z0-9_\-/]*)['\"]", html, re.I))
        out["endpoints"] = list(eps)[:6]

        # apakah butuh username (backend fetch IG)?
        out["username_based"] = bool(
            re.search(r"(enter your instagram username|username.*select.*post|load your posts)", low)
        )
        out["needs_email"] = bool(re.search(r"email address|your email|verify your email", low))
        out["verdict"] = "kandidat"
        return out
    except Exception as e:
        out["verdict"] = "error"
        out["error"] = str(e)[:120]
        return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--max", type=int, default=120)
    ap.add_argument("--out", default=OUT)
    args = ap.parse_args()

    cands = set()
    for q in QUERIES:
        for u in ddg(q):
            n = normalize(u)
            if not n:
                continue
            low = n.lower()
            if any(b in low for b in BLOCK):
                continue
            if "instagram" in low or "smm" in low or "likes" in low or "followers" in low:
                cands.add(n)
        time.sleep(0.6)

    cands = sorted(cands)
    print(f"[hunt] {len(cands)} URL kandidat dari {len(QUERIES)} query", flush=True)
    cands = cands[: args.max]

    results = []
    with ThreadPoolExecutor(max_workers=12) as ex:
        futs = {ex.submit(probe, u): u for u in cands}
        for i, f in enumerate(as_completed(futs), 1):
            r = f.result()
            results.append(r)
            v = r.get("verdict")
            if v == "kandidat":
                print(
                    f"[{i}/{len(cands)}] {v:20s} {r['url'][:78]} | {r.get('captcha','?'):9s} "
                    f"likes={r.get('like_mentions')} un={int(r.get('username_based',False))} "
                    f"mail={int(r.get('needs_email',False))} fields={len(r.get('fields',[]))}",
                    flush=True,
                )

    with open(args.out, "w", encoding="utf-8") as f:
        json.dump(results, f, indent=2, ensure_ascii=False)

    good = [r for r in results if r.get("verdict") == "kandidat"]
    print(f"\n[hunt] selesai. kandidat: {len(good)}/{len(results)} -> {args.out}")
    print(f"[hunt] saldo captcha: {os.environ.get('CAPTCHA_NO_KEY','?')[:6]}...")


if __name__ == "__main__":
    main()
