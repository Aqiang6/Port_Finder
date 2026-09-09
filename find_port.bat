@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

if not "%~1"=="" (
    call :query %~1
)

:input_loop
echo.
set "PORT="
set /p PORT=请输入要查询的端口号: || goto :eof
if not defined PORT goto :input_loop
call :query !PORT!
goto :input_loop

:query
set "SHOWN=,"
set /a COUNT=0
echo.
echo ================ 端口 %1 占用情况 ================
for /f "tokens=1,2,3,4,5" %%a in ('netstat -ano ^| findstr /c:":%1 "') do (
    echo %%b| findstr /r ":%1$" >nul && (
        if "%%e"=="" (
            call :detail %%a %%b UDP %%d
        ) else (
            call :detail %%a %%b %%d %%e
        )
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
if not "%4"=="0" if "!SHOWN:,%4,=!"=="!SHOWN!" (
    set "SHOWN=!SHOWN!%4,"
    echo 会话: !SESS!    内存: !MEMFULL!
    powershell -NoProfile -Command "[Console]::OutputEncoding=[Text.Encoding]::UTF8; $m=@{}; Get-CimInstance Win32_Process | ForEach-Object { $m[$_.ProcessId.ToString()]=$_ }; $p=$m['%4']; if($p){ $g=Get-Process -Id %4 -ErrorAction SilentlyContinue; if($g -and $g.MainWindowTitle){ Write-Output ('窗口标题: '+$g.MainWindowTitle) }; if($p.CommandLine){ Write-Output ('命令行: '+$p.CommandLine) } elseif($p.ExecutablePath){ Write-Output ('程序路径: '+$p.ExecutablePath) }; $d=0; while($d -lt 5){ $pp=$m[$p.ParentProcessId.ToString()]; if(-not $pp -or $pp.ProcessId -eq $p.ProcessId){ break }; Write-Output ('父进程: '+$pp.Name+' (PID '+$pp.ProcessId+')'); $p=$pp; $d++ } }"
    set "KILL="
    set /p KILL=结束该进程？y结束此进程 / n查下一个端口: || set "KILL=n"
    if /i "!KILL!"=="y" (
        taskkill /f /pid %4
        if errorlevel 1 echo [提示] 结束失败，可能需要以管理员身份运行
    )
)
goto :eof
