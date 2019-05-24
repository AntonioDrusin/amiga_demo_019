@rem Command Line Options are -dontrun -dontbuild -debug

@set MusicPlayer=2

@set UseMiniPacker=0
@set NoPack=1
@set DemoName=ExampleDemo
@set ShrinklerFlags=--flash dff180  --text "Example Demo. Be patient"
@set ShrinklerMiniFlags=
@set launcher=runa500

@echo off
@set _oldpath=%cd%
cd /d %~dp0
call ..\toolchain\toolchain\setpaths.bat

@set debug=0
@set dontrun=0
@set dontbuild=0

:ParseCommandLine
@if "%1" equ "" goto ParseCommandLineEnd
@if "%1" equ "-debug" set debug=1
@if "%1" equ "-debug" goto ParameterParsed
@if "%1" equ "-dontrun" set dontrun=1
@if "%1" equ "-dontrun" goto ParameterParsed
@if "%1" equ "-dontbuild" set dontbuild=1
@if "%1" equ "-dontbuild" goto ParameterParsed
@if "%1" equ "-aros" set launcher=runaros
@if "%1" equ "-aros" goto ParameterParsed

@echo Error: Unknown bat file parameter %1
@goto failed
:parameterParsed
@shift /1
@goto ParseCommandLine
:ParseCommandLineEnd

@if %debug% EQU 1 set NoPack=1

set DebugExt=
if %debug% NEQ 0 set DebugExt=_d
set OutDir=out%DebugExt%

@if %dontbuild% equ 1 goto dontBuild

if not exist %OutDir% md %OutDir%
if errorlevel 1 goto failed
del %OutDir%\* /s /q >NUL
if errorlevel 1 goto failed


if not exist ConvertedAssets md ConvertedAssets
if errorlevel 1 goto failed
del ConvertedAssets\* /s /q >NUL
if errorlevel 1 goto failed


if %MusicPlayer% EQU 1 (
	call ..\ConvertModToP61 dh1\modules\mod.blow_ya_nose_now ExampleDemo\ConvertedAssets TwoFiles_delta
	if errorlevel 1 goto failed
	cd /d %~dp0
)

kingcon @assetlist.txt
if errorlevel 1 goto failed


echo.
echo BUILDING %DemoName%

shallow -i %DemoName%.s -d
shallow -i DemoStartup.s -d

set BuildParm=
if %UseMiniPacker% NEQ 0 set BuildParm=-pic

vasmm68k_mot_win32.exe -m68000 -spaces -Fhunk %BuildParm% -x -o %OutDir%\%DemoName%Unpacked.o %DemoName%.s -DDebug=%Debug% -DUseMiniPacker=%UseMiniPacker% -DMUSICPLAYER=%MusicPlayer%
if errorlevel 1 goto failed
vc -O2 -notmpfile -nostdlib -DDebug=%Debug% -DUseMiniPacker=%UseMiniPacker% -o %OutDir%\%DemoName%Unpacked.exe %OutDir%\%DemoName%Unpacked.o ExampleCCode.c
if errorlevel 1 goto failed
if not exist %OutDir%\%DemoName%Unpacked.exe goto failed

@if %NoPack% NEQ 0 copy %OutDir%\%DemoName%Unpacked.exe %OutDir%\%DemoName%%DebugExt%.exe
@if %NoPack% NEQ 0 goto NoPack
echo.
echo.
echo PACKING %DemoName%
set PackerParm=--overlap %ShrinklerFlags%
if %UseMiniPacker% NEQ 0 set PackerParm=--mini %ShrinklerMiniFlags%
shrinkler %OutDir%\%DemoName%Unpacked.exe %OutDir%\%DemoName%%DebugExt%.exe %PackerParm% --no-progress
:NoPack
if not exist %OutDir%\%DemoName%%DebugExt%.exe goto failed

echo.
:dontBuild
if %dontrun% equ 1 goto DontRun
if not exist %~dp0%OutDir%\%DemoName%%DebugExt%.exe goto failed
call ..\toolchain\%launcher% %~dp0%OutDir%\%DemoName%%DebugExt%.exe
if errorlevel 1 goto failed
:DontRun

echo SUCCESS
cd /d %_oldpath%
exit /b 0

:failed
echo FAILED
cd /d %_oldpath%
exit /b 1
