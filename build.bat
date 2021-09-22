@echo off
SPASM.exe -T -E src\main.asm main.bin
SPASM.exe -T -E src\program.asm TI81CE.8xp
copy /Y TI81CE.8xp "bin\TI81CE - TI-84 Plus CE (Native).8xp" >nul
copy /Y TI81CE.lst+main.lst "bin\TI81CE - TI-84 Plus CE (Native).lst" >nul
ECHO SPLITTING BINARIES...
setlocal
FOR /F "usebackq" %%A IN ('TI81CE.8xp') DO set /a FILESIZE=%%~zA
FOR /F "usebackq" %%A IN ('main.bin') DO set /a MAINSIZE=%%~zA
set /a SPLIT=%FILESIZE%-%MAINSIZE%-2
res\split.exe TI81CE.8xp %SPLIT%
res\split.exe TI81CE.8xp.002 32768
endlocal
copy /Y TI81CE.8xp.001 bin\release\"TI81CE - TI-84 Plus CE (Native).8xp.001"
copy /Y TI81CE.8xp.002.002 bin\release\"TI81CE - TI-84 Plus CE (Native).8xp.003"
del main.bin
del main.lst
del TI81CE.8xp
del TI81CE.lst
del TI81CE.8xp.001
del TI81CE.8xp.002
del TI81CE.8xp.002.001
del TI81CE.8xp.002.002
pause