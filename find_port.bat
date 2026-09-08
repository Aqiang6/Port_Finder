@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

if not "%~1"=="" (
    call :query %~1
)

:input_loop
echo.
set "PORT="
set /p PORT=请输入要查询的端口号（退出请直接关闭窗口）: || goto :eof
if not defined PORT goto :input_loop
call :query !PORT!
goto :input_loop

:query
set "SHOWN=,"
set /a COUNT=0
echo.
echo ================ 端口 %1 占用情况 ================
for /f "tokens=1,2,3,4,5" %%a in ('netstat -ano ^| findstr /c:":%1 "') do (
    if "%%e"=="" (
        call :detail %%a %%b UDP %%d
    ) else (
        call :detail %%a %%b %%d %%e
    )
)
if !COUNT! EQU 0 (
    echo.
    echo 端口 %1 当前没有被任何程序占用。
)
goto :eof

:detail
set /a COUNT+=1
set "NAME="
for /f "tokens=1,3,5* delims=," %%i in ('tasklist /fi "PID eq %4" /fo csv /nh 2^>nul') do (
    set "NAME=%%~i"
    set "SESS=%%~j"
    set "MEM=%%~k"
    set "MEM2=%%~l"
)
set "MEMFULL=!MEM!"
if defined MEM2 set "MEMFULL=!MEM!,!MEM2!"
set "MEMFULL=!MEMFULL:"=!"
if not defined NAME (
    set "NAME=未知（可能已退出或需管理员权限）"
    set "SESS=N/A"
    set "MEM=N/A"
)
if "%3"=="UDP" (
    echo [%1] %2  PID: %4  进程: !NAME!
) else (
    echo [%1] %2  %3  PID: %4  进程: !NAME!
)
if "!SHOWN:,%4,=!"=="!SHOWN!" (
    set "SHOWN=!SHOWN!%4,"
    echo 会话: !SESS!    内存: !MEMFULL!
    for /f "tokens=1* delims=:" %%i in ('tasklist /fi "PID eq %4" /v /fo list 2^>nul ^| findstr /c:"Window Title:" /c:"窗口标题:" ^| findstr /v /c:"N/A"') do (
        echo 窗口标题:%%j
    )
    set "KILL="
    set /p KILL=结束该进程？y结束 / n跳过: || set "KILL=n"
    if /i "!KILL!"=="y" (
        taskkill /f /pid %4
        if errorlevel 1 echo [提示] 结束失败，可能需要以管理员身份运行
    )
)
goto :eof
