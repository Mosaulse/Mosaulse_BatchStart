@echo off

:: BatchStart 配置编辑器启动脚本
:: 直接打开 HTML 文件,无需 HTTP 服务器

cd /d "%~dp0"

:: 检查必要文件
if not exist "config-editor.html" (
    echo Error: config-editor.html not found!
    echo Please run this script from the correct directory.
    pause
    exit /b 1
)

:: 直接打开 HTML 文件
start "" "%~dp0config-editor.html"
