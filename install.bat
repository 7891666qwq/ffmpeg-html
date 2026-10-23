@echo off
setlocal enabledelayedexpansion
title Node.js 自动安装脚本 (Win7 / Win10)

echo ============================================
echo   Node.js 自动安装脚本
echo   支持系统: Windows 7 / Windows 10
echo ============================================
echo.

:: ---------- 1. 检测系统版本 ----------
:: Win7 的版本号是 6.1，Win10 是 10.0
for /f "tokens=4-5 delims=. " %%i in ('ver') do set "WIN_VER=%%i.%%j"

echo [检测] 当前系统版本: %WIN_VER%
echo.

if "%WIN_VER%"=="6.1" (
    echo [识别] 检测到 Windows 7，将使用 ZIP 免安装方案。
    goto :INSTALL_WIN7
) else if "%WIN_VER%"=="10.0" (
    echo [识别] 检测到 Windows 10，将使用 winget 自动安装。
    goto :INSTALL_WIN10
) else (
    echo [错误] 不支持的系统版本: %WIN_VER%
    echo        本脚本仅适用于 Windows 7 和 Windows 10。
    goto :END
)

:: ============================================
:: Windows 10 安装分支 (使用 winget)
:: ============================================
:INSTALL_WIN10
echo.
echo [步骤] 正在使用 winget 安装 Node.js LTS...
echo        如果弹出用户账户控制，请点击“是”。

:: 检查 winget 是否存在
winget --version >nul 2>&1
if %errorlevel% neq 0 (
    echo [错误] 未找到 winget。请确保系统已更新，或手动从 Microsoft Store 安装“应用安装程序”。
    goto :END
)

:: 执行静默安装，自动接受协议
winget install -e --id OpenJS.NodeJS.LTS --silent --accept-package-agreements --accept-source-agreements

if %errorlevel% equ 0 (
    echo.
    echo [成功] Node.js 安装完成！
    echo        请关闭并重新打开命令提示符，然后输入 node -v 验证。
) else (
    echo.
    echo [失败] winget 安装失败，错误码: %errorlevel%
    echo        请尝试手动访问 https://nodejs.org 下载安装。
)
goto :END

:: ============================================
:: Windows 7 安装分支 (ZIP 免安装)
:: ============================================
:INSTALL_WIN7
echo.
echo [说明] Windows 7 官方最高仅支持 Node.js v13.14。
echo        为了获得更好的兼容性，本脚本将下载 v14 的 Win7 适配版 ZIP 包。
echo.

set "NODE_DIR=C:\nodejs"
set "NODE_VERSION=v14.21.3"
set "ZIP_NAME=node-%NODE_VERSION%-win-x64.zip"
set "DOWNLOAD_URL=https://nodejs.org/dist/%NODE_VERSION%/%ZIP_NAME%"
set "TEMP_ZIP=%TEMP%\%ZIP_NAME%"

:: 检查目标目录是否已存在 Node
if exist "%NODE_DIR%\node.exe" (
    echo [提示] 检测到 %NODE_DIR% 已存在 Node.js。
    set /p "OVERWRITE=是否覆盖安装？(Y/N): "
    if /i not "!OVERWRITE!"=="Y" goto :END
    rmdir /s /q "%NODE_DIR%" 2>nul
)

:: 下载 ZIP 包
echo [步骤 1/3] 正在下载 Node.js %NODE_VERSION% (约 30MB)...
powershell -Command "& {[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri '%DOWNLOAD_URL%' -OutFile '%TEMP_ZIP%'}"
if %errorlevel% neq 0 (
    echo [错误] 下载失败。请检查网络连接，或手动访问 nodejs.org 下载。
    goto :END
)

:: 解压 ZIP
echo [步骤 2/3] 正在解压到 %NODE_DIR%...
if not exist "%NODE_DIR%" mkdir "%NODE_DIR%"
powershell -Command "& {Expand-Archive -Path '%TEMP_ZIP%' -DestinationPath '%NODE_DIR%' -Force}"
if %errorlevel% neq 0 (
    echo [错误] 解压失败。
    goto :END
)

:: ZIP 解压后通常会多一层文件夹，需要把里面的内容移动到根目录
for /d %%d in ("%NODE_DIR%\node-%NODE_VERSION%-win-x64") do (
    if exist "%%d\node.exe" (
        echo [提示] 正在整理目录结构...
        xcopy "%%d\*" "%NODE_DIR%\" /E /H /Y >nul
        rmdir /s /q "%%d"
    )
)

:: 设置环境变量
echo [步骤 3/3] 正在配置环境变量...

:: 添加 Node 目录到 Path
echo %PATH% | find /i "%NODE_DIR%" >nul
if %errorlevel% neq 0 (
    setx PATH "%PATH%;%NODE_DIR%" /M >nul 2>&1
    if !errorlevel! equ 0 (
        echo [成功] 已添加 %NODE_DIR% 到系统 Path。
    ) else (
        echo [警告] 无法写入系统环境变量，请手动将 %NODE_DIR% 添加到 Path。
    )
) else (
    echo [提示] Path 中已包含 %NODE_DIR%。
)

:: Win7 上运行高版本 Node 需要设置此变量以跳过平台检查
setx NODE_SKIP_PLATFORM_CHECK 1 /M >nul 2>&1
if !errorlevel! equ 0 (
    echo [成功] 已设置 NODE_SKIP_PLATFORM_CHECK=1 (Win7 兼容性必需)。
) else (
    echo [警告] 无法设置 NODE_SKIP_PLATFORM_CHECK，高版本 Node 可能无法运行。
)

:: 清理临时文件
if exist "%TEMP_ZIP%" del /f /q "%TEMP_ZIP%"

echo.
echo [完成] Node.js 安装与配置完毕！
echo        请关闭并重新打开命令提示符，然后输入 node -v 验证。
echo        如果提示找不到命令，请注销或重启电脑使环境变量生效。
goto :END

:: ============================================
:END
echo.
echo 安装完成，请使用start运行
pause
endlocal