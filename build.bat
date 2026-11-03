@echo off

if not exist bin mkdir bin

echo Compiling RemLang for Windows...
zig build-exe compiler\main.zig -O ReleaseFast -femit-bin=bin\rem.exe %*

if %ERRORLEVEL% EQU 0 (
    echo.
    if exist compiler\cli\rem_art.txt type compiler\cli\rem_art.txt
    echo.
    echo ================================================================================
    echo 💙 Kon'nichiwa minna at RemLang! (bin\rem.exe)
    echo ================================================================================
    echo.
    echo RemLang is a programming language born out of love for Rem from Re:Zero.
    echo Dedicated to her unwavering loyalty, gentle smile, and devotion, RemLang is
    echo crafted from scratch to deliver blazing systems-level performance with
    echo clean, modern ergonomics—seamlessly uniting both Procedure-Oriented Programming (POP)
    echo and Object-Oriented Programming (OOP).
    echo.
    echo Quotes: "Starting from zero, let's build the ultimate language." 💙
    echo.
    echo Location : bin\rem.exe
    echo ================================================================================
) else (
    echo Build failed!
)
