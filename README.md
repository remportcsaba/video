# Fantaztikusan mukodo YouTube/VOD/Live felvevo

Ez a projekt egy **stabil**, parancssoros felvevo program, amely a kert funkciokat keszitett sablonokkal es ellenorzott, attekintheto parancsokkal valositja meg. A program **kizarolag jogszeru, sajat vagy engedelyezett tartalmak** letoltesere/rogzitesere keszult.

## Fo funkciok (pont amit kertel)

- VOD legjobb minoseg (MP4) + kezdo ido
- VOD max 1080p (MP4)
- VOD max 720p (MP4)
- VOD csak hang (mp3 – ffmpeg kell)
- VOD fejezet-szures (szunet/felido)
- Elo rogzites elejetol (DVR)
- Elo rogzites elejetol idokorlattal
- M3U8 rogzites (elo vagy VOD)
- Elo rogzites mostantol (live edge)
- DVR visszahuzott ponttol (t=)

## Kovetelmenyek

- Python 3.9+
- `yt-dlp`
- `ffmpeg` (mp3 es M3U8 felvetelhez)

## Telepites

```bash
pip install yt-dlp
# ffmpeg telepitese a rendszeredhez igazodo modon
```

## Hasznalat

```bash
python src/fantastikus.py <URL> --vod-best --start-time 00:10:00
```

Tovabbi peldak:

```bash
# VOD max 1080p
python src/fantastikus.py <URL> --vod-1080

# VOD csak hang (mp3)
python src/fantastikus.py <URL> --vod-audio

# Fejezet-szures (szunet/felido)
python src/fantastikus.py <URL> --chapter-filter "!/szunet|felido/"

# Elo rogzites elejetol, 1 oraig
python src/fantastikus.py <URL> --live-from-start --live-limit 01:00:00

# M3U8 rogzites
python src/fantastikus.py <URL> --m3u8 "https://example.com/stream.m3u8"

# DVR visszahuzott ponttol
python src/fantastikus.py <URL> --dvr-from 00:30:00
```

## Megjegyzesek

- A program **yt-dlp** parancsokat epit es futtat.
- A `--dry-run` kapcsoloval csak kiirja a parancsokat, futtatas nelkul.
- A M3U8 rogzites alapbol `output.ts` fajlba ment.

## Jog

A projektet csak jogszeru tartalmakhoz hasznald.
