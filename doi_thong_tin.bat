@echo off
rem Bấm đúp để đổi thông tin người nộp bài (hỏi từng trường).
rem chcp 65001 để gõ được tiếng Việt có dấu trong cửa sổ này.
chcp 65001 >nul
cd /d "%~dp0"
dart run tool/doi_thong_tin.dart %*
echo.
pause
