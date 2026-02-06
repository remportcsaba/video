#!/usr/bin/env python3
"""
Fantaztikusan mukodo YouTube/VOD/Live felvevo CLI.

A program jogszeru, sajat vagy engedelyezett tartalmakra keszult.
"""

import argparse
import shlex
import shutil
import subprocess
from dataclasses import dataclass
from typing import Iterable, List, Optional


@dataclass(frozen=True)
class CommandSpec:
    title: str
    cmd: List[str]

    def as_shell(self) -> str:
        return " ".join(shlex.quote(part) for part in self.cmd)


def ensure_binary(name: str) -> bool:
    return shutil.which(name) is not None


def run_command(cmd: List[str], dry_run: bool) -> int:
    if dry_run:
        print("DRY RUN:")
        print(" ".join(shlex.quote(part) for part in cmd))
        return 0
    result = subprocess.run(cmd, check=False)
    return result.returncode


def base_cmd(url: str) -> List[str]:
    return ["yt-dlp", url]


def vod_best(url: str, start_time: Optional[str]) -> CommandSpec:
    cmd = base_cmd(url) + ["-f", "bv*+ba/b"]
    if start_time:
        cmd += ["--download-sections", f"*{start_time}-"]
    return CommandSpec("VOD legjobb minoseg (MP4)", cmd)


def vod_max_height(url: str, height: int) -> CommandSpec:
    fmt = f"bv*[height<={height}][ext=mp4]+ba[ext=m4a]/b[height<={height}]"
    cmd = base_cmd(url) + ["-f", fmt]
    return CommandSpec(f"VOD max {height}p (MP4)", cmd)


def vod_audio(url: str) -> CommandSpec:
    cmd = base_cmd(url) + ["-x", "--audio-format", "mp3"]
    return CommandSpec("VOD csak hang (mp3)", cmd)


def vod_chapter_filter(url: str, chapter_regex: str) -> CommandSpec:
    cmd = base_cmd(url) + ["--chapter-filter", chapter_regex, "--split-chapters"]
    return CommandSpec("VOD fejezet-szures", cmd)


def live_from_start(url: str, limit: Optional[str]) -> CommandSpec:
    cmd = base_cmd(url) + ["--live-from-start"]
    if limit:
        cmd += ["--download-sections", f"*00:00:00-{limit}"]
    return CommandSpec("Elo rogzites elejetol", cmd)


def live_edge(url: str) -> CommandSpec:
    cmd = base_cmd(url)
    return CommandSpec("Elo rogzites mostantol (live edge)", cmd)


def record_m3u8(url: str) -> CommandSpec:
    cmd = ["ffmpeg", "-i", url, "-c", "copy", "output.ts"]
    return CommandSpec("M3U8 rogzites (elo vagy VOD)", cmd)


def dvr_from(url: str, start_time: str) -> CommandSpec:
    cmd = base_cmd(url) + ["--download-sections", f"*{start_time}-"]
    return CommandSpec("DVR visszahuzott ponttol", cmd)


def validate_dependencies(specs: Iterable[CommandSpec]) -> List[str]:
    missing = []
    for spec in specs:
        if spec.cmd[0] == "yt-dlp" and not ensure_binary("yt-dlp"):
            missing.append("yt-dlp")
            break
    for spec in specs:
        if spec.cmd[0] == "ffmpeg" and not ensure_binary("ffmpeg"):
            missing.append("ffmpeg")
            break
    return sorted(set(missing))


def build_specs(args: argparse.Namespace) -> List[CommandSpec]:
    specs: List[CommandSpec] = []
    if args.vod_best:
        specs.append(vod_best(args.url, args.start_time))
    if args.vod_1080:
        specs.append(vod_max_height(args.url, 1080))
    if args.vod_720:
        specs.append(vod_max_height(args.url, 720))
    if args.vod_audio:
        specs.append(vod_audio(args.url))
    if args.chapter_filter:
        specs.append(vod_chapter_filter(args.url, args.chapter_filter))
    if args.live_from_start:
        specs.append(live_from_start(args.url, args.live_limit))
    if args.live_edge:
        specs.append(live_edge(args.url))
    if args.m3u8:
        specs.append(record_m3u8(args.m3u8))
    if args.dvr_from:
        specs.append(dvr_from(args.url, args.dvr_from))
    return specs


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description=(
            "Fantaztikusan mukodo YouTube/VOD/Live felvevo CLI "
            "(jogszeru tartalmakhoz)."
        )
    )
    parser.add_argument("url", help="YouTube/VOD/Live URL")
    parser.add_argument("--start-time", help="Kezdo ido (HH:MM:SS)")
    parser.add_argument("--vod-best", action="store_true", help="VOD legjobb minoseg (MP4)")
    parser.add_argument("--vod-1080", action="store_true", help="VOD max 1080p (MP4)")
    parser.add_argument("--vod-720", action="store_true", help="VOD max 720p (MP4)")
    parser.add_argument("--vod-audio", action="store_true", help="VOD csak hang (mp3)")
    parser.add_argument("--chapter-filter", help="Fejezet-szures regex (pl. !/szunet/")
    parser.add_argument("--live-from-start", action="store_true", help="Elo rogzites elejetol (DVR)")
    parser.add_argument("--live-limit", help="Elo rogzites idokorlattal (HH:MM:SS)")
    parser.add_argument("--m3u8", help="M3U8 URL (elo vagy VOD)")
    parser.add_argument("--live-edge", action="store_true", help="Elo rogzites mostantol")
    parser.add_argument("--dvr-from", help="DVR visszahuzott ponttol (HH:MM:SS)")
    parser.add_argument("--dry-run", action="store_true", help="Csak parancsok kiirasa")
    return parser


def main() -> int:
    parser = build_parser()
    args = parser.parse_args()

    specs = build_specs(args)
    if not specs:
        parser.error("Nincs kivalasztott funkcio. Adj meg legalabb egy kapcsolot.")

    missing = validate_dependencies(specs)
    if missing:
        missing_list = ", ".join(missing)
        print(f"Hianyzo fuggosegek: {missing_list}")
        return 1

    exit_code = 0
    for spec in specs:
        print(f"\n== {spec.title} ==")
        print(spec.as_shell())
        code = run_command(spec.cmd, args.dry_run)
        if code != 0:
            exit_code = code
    return exit_code


if __name__ == "__main__":
    raise SystemExit(main())
