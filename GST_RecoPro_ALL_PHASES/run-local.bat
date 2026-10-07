@echo off
cd /d "%~dp0"
echo Starting GST RecoPro local server...
python -m http.server 5501
pause
