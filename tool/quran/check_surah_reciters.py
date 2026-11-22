#!/usr/bin/env python3
"""Checks every mp3quran Reciter surah by surah, so run it after adding one (needs ffmpeg).

    python3 tool/quran/check_surah_reciters.py

Reads the reciters with a `read:` from lib/core/settings/quran.dart. Each surah file is streamed
through ffmpeg, nothing is kept. A surah is missing when:

- its timings don't list every ayah in order,
- an ayah lasts under 0.1 s a letter, a voice reads about 0.3, so the labels slipped,
- the timings end after the file, or more than 2 minutes before it (a short tail is a closing dua),
- the file is not constant bitrate, android seeks by its first frame and the clips land wrong,
- 10 or more ayah boundaries and fewer than half of them sit in a quiet dip of the voice.

Prints each reciter's `missing:` set to paste into the enum.
"""
import glob
import json
import re
import statistics
import subprocess
import sys
from concurrent.futures import ThreadPoolExecutor

SETTINGS = "lib/core/settings/quran.dart"
PAGES = "assets/quran/pages/*.json"
AUDIO = "https://cdn.mp3quran.net/audio/"
TIMINGS = "https://www.mp3quran.net/api/v3/ayat_timing?surah={surah}&read={read}"

WINDOW = 0.05
FAST = 0.1
TAIL = 120
QUIET = 0.25
NEAR = 6


# curl reads the system's certificates, python.org's python has none of its own
def fetch(url):
    return subprocess.run(["curl", "-sfL", url], capture_output=True, check=True, text=True).stdout


def reciters():
    source = open(SETTINGS, encoding="utf-8").read()
    reciters = source[source.index("enum Reciter {") :]
    return re.findall(r"^  (\w+)\(\n    '([^']+)',\n(?:    .*\n)*?    read: (\d+),", reciters, re.MULTILINE)


# each ayah's letters from the app's own pages, the ayah markers left out
def letters():
    counts = {}
    for page in glob.glob(PAGES):
        for line in json.load(open(page, encoding="utf-8"))["lines"]:
            if line.get("t") != "a":
                continue
            for word in line["w"]:
                if len(word) > 3:
                    continue
                surah, ayah, text = word[:3]
                found = sum(1 for c in text if "\u0621" <= c <= "\u064a" or c == "\u0671")
                counts[(surah, ayah)] = counts.get((surah, ayah), 0) + found
    return counts


def header_length(url):
    out = subprocess.run(
        ["ffprobe", "-v", "error", "-show_entries", "format=duration", "-of", "csv=p=0", url],
        capture_output=True,
        text=True,
    ).stdout
    return float(out.strip().splitlines()[0])


# the voice's loudness every 50 ms over the whole file, decoded by ffmpeg
def loudness(url):
    out = subprocess.run(
        [
            "ffmpeg", "-v", "error", "-i", url, "-vn", "-ac", "1", "-af",
            "aresample=8000,asetnsamples=n=400:p=0,astats=metadata=1:reset=1,"
            "ametadata=mode=print:key=lavfi.astats.Overall.RMS_level:file=-",
            "-f", "null", "-",
        ],
        capture_output=True,
        text=True,
    ).stdout
    levels = []
    for line in out.splitlines():
        if line.startswith("lavfi.astats.Overall.RMS_level="):
            value = line.split("=", 1)[1]
            levels.append(0.0 if value in ("-inf", "nan") else 10 ** (float(value) / 20))
    return levels


def problem(folder, read, surah, letters):
    ayahs = max(ayah for (each, ayah) in letters if each == surah)
    try:
        timings = json.loads(fetch(TIMINGS.format(surah=surah, read=read)))
    except (subprocess.CalledProcessError, json.JSONDecodeError):
        return "no timings"
    if [entry["ayah"] for entry in timings] != list(range(1, ayahs + 1)):
        return f"{len(timings)} timings for {ayahs} ayahs"
    for entry in timings:
        length = (entry["end_time"] - entry["start_time"]) / 1000
        if length < FAST * letters[(surah, entry["ayah"])]:
            return f"ayah {entry['ayah']} is {length:.2f} s"
    url = f"{AUDIO}{folder}/{surah:03}.mp3"
    levels = loudness(url)
    if not levels:
        return "no audio"
    length = len(levels) * WINDOW
    end = timings[-1]["end_time"] / 1000
    if end > length + 1.5:
        return f"timings end at {end:.0f} s, the file at {length:.0f} s"
    if length - end > TAIL:
        return f"{length - end:.0f} s after the last ayah"
    header = header_length(url)
    if abs(header - length) > 1:
        return f"not constant bitrate, {header:.0f} s by the header, {length:.0f} s decoded"
    bounds = [entry["end_time"] / 1000 for entry in timings[:-1]]
    if len(bounds) >= 10:
        middle = statistics.median(levels) or 1
        quiet = 0
        for bound in bounds:
            index = int(bound / WINDOW)
            near = levels[max(0, index - NEAR) : index + NEAR + 1]
            if near and min(near) / middle < QUIET:
                quiet += 1
        if quiet < len(bounds) / 2:
            return f"{quiet} of {len(bounds)} boundaries in a pause"
    return None


def main():
    counts = letters()
    found = reciters()
    if not found:
        sys.exit(f"no reciter with a read in {SETTINGS}")
    for name, folder, read in found:
        surahs = list(range(1, 115))
        with ThreadPoolExecutor(6) as pool:
            problems = list(pool.map(lambda surah: problem(folder, read, surah, counts), surahs))
        missing = [surah for surah, reason in zip(surahs, problems) if reason]
        print(f"{name}: {114 - len(missing)} of 114")
        for surah in missing:
            print(f"  {surah}: {problems[surah - 1]}")
        print(f"  missing: {{{', '.join(map(str, missing))}}},")


if __name__ == "__main__":
    main()
