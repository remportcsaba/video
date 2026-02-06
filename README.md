 (cd "$(git rev-parse --show-toplevel)" && git apply --3way <<'EOF' 
diff --git a/README.md b/README.md
index b99d8575dd519a650e97e5fd878c78937eef8c89..9c9f907371f91e466a9313cf890c497cb04574c3 100644
--- a/README.md
+++ b/README.md
@@ -12,50 +12,58 @@ Ez a projekt egy **stabil**, parancssoros felvevo program, amely a kert funkciok
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
 
+### Interaktiv menu (ajanlott, ha nem akarsz kapcsolokat irni)
+
+```bash
+python src/fantastikus.py --interactive
+```
+
+Ezutan a program magyar nyelvu kerdesekkel vegigvezet es osszeallitja a szukseges muveleteket.
+
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
 
EOF
)# video
video handball
