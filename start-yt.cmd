@echo off
chcp 65001 >nul
title yt-dlp STABIL MENU
cd /d "%~dp0"

:menu
cls
echo ===== MOD VALASZTASA =====
echo 1 = VOD legjobb minoseg (MP4) + KEZDO IDO
echo 2 = VOD max 1080p (MP4)
echo 3 = VOD max 720p (MP4)
echo 4 = VOD csak hang (mp3)
echo 5 = VOD fejezet-szuro (szunet/felido)
echo 6 = ELO rogzites A VIDEO ELEJETOL (DVR)  [CTRL+C = STOP]
echo 7 = ELO rogzites ELEJETOL idokorlattal (perc)
echo 8 = M3U8 rogzites (elo vagy VOD) [CTRL+C = STOP]
echo 9 = ELO rogzites MOSTTOL (live edge) [CTRL+C = STOP]
echo 10 = DVR visszahuzott ponttol (t=)
echo.
set /p M=Valassz (1-10): 

if "%M%"=="1" goto vod_best
if "%M%"=="2" goto vod_1080
if "%M%"=="3" goto vod_720
if "%M%"=="4" goto vod_mp3
if "%M%"=="5" goto vod_chapters
if "%M%"=="6" goto live_from_start
if "%M%"=="7" goto live_limit
if "%M%"=="8" goto m3u8
if "%M%"=="9" goto live_now
if "%M%"=="10" goto dvr_seek
goto menu

:askurl
set URL=
set /p URL=Add meg a video URL-jet: 
if "%URL%"=="" goto askurl
exit /b

:vod_best
call :askurl
set /p START=Kezdo ido (ENTER=teljes): 
yt-dlp.exe -f "bv*+ba/b" --merge-output-format mp4 --download-sections "*%START%" -o "letoltesek\%%(title)s.%%(ext)s" "%URL%"
pause
goto menu

:vod_1080
call :askurl
yt-dlp.exe -f "bv*[height<=1080]+ba/b[height<=1080]" --merge-output-format mp4 -o "letoltesek\%%(title)s.%%(ext)s" "%URL%"
pause
goto menu

:vod_720
call :askurl
yt-dlp.exe -f "bv*[height<=720]+ba/b[height<=720]" --merge-output-format mp4 -o "letoltesek\%%(title)s.%%(ext)s" "%URL%"
pause
goto menu

:vod_mp3
call :askurl
yt-dlp.exe -x --audio-format mp3 -o "letoltesek\%%(title)s.%%(ext)s" "%URL%"
pause
goto menu

:vod_chapters
call :askurl
yt-dlp.exe --download-sections "*szunet,*felido" -o "letoltesek\%%(title)s.%%(ext)s" "%URL%"
pause
goto menu

:live_from_start
call :askurl
yt-dlp.exe --live-from-start -o "letoltesek\%%(title)s.%%(ext)s" "%URL%"
pause
goto menu

:live_limit
call :askurl
set /p MIN=Perc: 
yt-dlp.exe --live-from-start --downloader ffmpeg --downloader-args ffmpeg:"-t %MIN%*60" -o "letoltesek\%%(title)s.%%(ext)s" "%URL%"
pause
goto menu

:m3u8
call :askurl
yt-dlp.exe "%URL%" -o "letoltesek\%%(title)s.%%(ext)s"
pause
goto menu

:live_now
call :askurl
yt-dlp.exe -o "letoltesek\%%(title)s.%%(ext)s" "%URL%"
pause
goto menu

:dvr_seek
call :askurl
yt-dlp.exe -o "letoltesek\%%(title)s.%%(ext)s" "%URL%"
pause
goto menu
