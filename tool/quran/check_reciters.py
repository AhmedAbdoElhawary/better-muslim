#!/usr/bin/env python3
"""Checks every Reciter folder on EveryAyah holds all 6,236 ayahs, so run it after adding one.

    python3 tool/quran/check_reciters.py

Reads the folders from lib/core/settings/quran.dart and looks for each ayah's mp3 in the folder's
listing.
"""
import json
import re
import subprocess
import sys
from concurrent.futures import ThreadPoolExecutor

SETTINGS = "lib/core/settings/quran.dart"
DATA = "https://everyayah.com/data/"


# curl reads the system's certificates, python.org's python has none of its own
def fetch(url):
    return subprocess.run(["curl", "-sfL", url], capture_output=True, check=True, text=True).stdout


def folders():
    source = open(SETTINGS, encoding="utf-8").read()
    reciters = source[source.index("enum Reciter {") :]
    entries = re.findall(r"^  \w+\(\n    '([^']+)',\n((?:    .*\n)*?)  \)", reciters, re.MULTILINE)
    # the ones with a read are on mp3quran, check_surah_reciters.py checks them
    return [folder for folder, rest in entries if "read:" not in rest]


def ayahs():
    counts = json.loads(fetch(DATA + "recitations.js"))["ayahCount"]
    return {f"{surah:03}{ayah:03}.mp3" for surah, count in enumerate(counts, 1) for ayah in range(1, count + 1)}


def missing(folder, expected):
    return expected - set(re.findall(r"\b\d{6}\.mp3\b", fetch(f"{DATA}{folder}/")))


def main():
    expected = ayahs()
    names = folders()
    with ThreadPoolExecutor(8) as pool:
        gaps = dict(zip(names, pool.map(lambda folder: missing(folder, expected), names)))
    for folder, gap in gaps.items():
        print(f"{folder}: {len(expected) - len(gap)} of {len(expected)}")
    incomplete = [folder for folder, gap in gaps.items() if gap]
    if incomplete:
        print("incomplete:", ", ".join(incomplete))
        sys.exit(1)


if __name__ == "__main__":
    main()
