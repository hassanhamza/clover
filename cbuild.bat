@echo off
rem windows batch script for building clover
rem 2012-09-06 apianti

rem setup current dir and edk2 if needed
pushd .
set CURRENTDIR=%CD%
if not defined WORKSPACE (
   echo Searching for EDK2
   goto searchforedk
)

rem have edk2 prepare to build
:foundedk
   echo Found EDK2. Generating %WORKSPACE%\Clover\Version.h
   cd %WORKSPACE%\Clover
   rem get svn revision number
   svnversion -n > vers.txt
   set /p s= < vers.txt
   del vers.txt
   set SVNREVISION=

   rem get the current revision number
   :fixrevision
      if x"%s%" == x"" goto generateversion
      set c=%s:~0,1%
      set s=%s:~1%
      if x"%c::=%" == x"" goto generateversion
      if x"%c:M=%" == x"" goto generateversion
      if x"%c:S=%" == x"" goto generateversion
      if x"%c:P=%" == x"" goto generateversion
      set SVNREVISION=%SVNREVISION%%c%
      goto fixrevision

   :generateversion
      rem check for revision number
      if x"%SVNREVISION%" == x"" goto noedk
      rem generate build date and time
      set BUILDDATE=
      echo Dim cdt, output, temp > buildtime.vbs
      rem output year
      echo cdt = Now >> buildtime.vbs
      echo output = Year(cdt) ^& "-" >> buildtime.vbs
      rem output month
      echo temp = Month(cdt) >> buildtime.vbs
      echo If temp ^< 10 Then >> buildtime.vbs
      echo    output = output ^& "0" >> buildtime.vbs
      echo End If >> buildtime.vbs
      echo output = output ^& temp ^& "-" >> buildtime.vbs
      rem output day
      echo temp = Day(cdt) >> buildtime.vbs
      echo If temp ^< 10 Then >> buildtime.vbs
      echo    output = output ^& "0" >> buildtime.vbs
      echo End If >> buildtime.vbs
      echo output = output ^& temp ^& " " >> buildtime.vbs
      rem output hours
      echo temp = Hour(cdt) >> buildtime.vbs
      echo If temp ^< 10 Then >> buildtime.vbs
      echo    output = output ^& "0" >> buildtime.vbs
      echo End If >> buildtime.vbs
      echo output = output ^& temp ^& ":" >> buildtime.vbs
      rem output minutes
      echo temp = Minute(cdt) >> buildtime.vbs
      echo If temp ^< 10 Then >> buildtime.vbs
      echo    output = output ^& "0" >> buildtime.vbs
      echo End If >> buildtime.vbs
      echo output = output ^& temp ^& ":" >> buildtime.vbs
      rem output seconds
      echo temp = Second(cdt) >> buildtime.vbs
      echo If temp ^< 10 Then >> buildtime.vbs
      echo    output = output ^& "0" >> buildtime.vbs
      echo End If >> buildtime.vbs
      echo output = output ^& temp >> buildtime.vbs
      echo Wscript.Echo output >> buildtime.vbs
      cscript //Nologo buildtime.vbs > buildtime.txt
      del buildtime.vbs
      set /p BUILDDATE= < buildtime.txt
      del buildtime.txt

      rem generate version.h
      echo // Autogenerated Version.h> Version.h
      echo #define FIRMWARE_VERSION "2.31">> Version.h
      echo #define FIRMWARE_BUILDDATE "%BUILDDATE%">> Version.h
      echo #define FIRMWARE_REVISION L"%SVNREVISION%">> Version.h
      echo #define REVISION_STR "Clover revision: %SVNREVISION%">> Version.h
      cd %CURRENTDIR%

      rem parse parameters for what we need
      set BUILD_ARCH=
      set TOOL_CHAIN_TAG=
      set TARGET=
      set DSCFILE=
      set CLEANING=
      set errorlevel=0
      call:parseArguments %*
      if not x"%errorlevel%" == x"0" goto:eof

      rem fix any parameters not set
      set CONFIG_FILE=%WORKSPACE%\Conf\target.txt
      set DEFAULT_TOOL_CHAIN_TAG=MYTOOLS
      set DEFAULT_TARGET=DEBUG
      for /f "tokens=1*" %%i in ('type %CONFIG_FILE% ^| find "TOOL_CHAIN_TAG" ^| find /V "#"') do set DEFAULT_TOOL_CHAIN_TAG%%j
      for /f "tokens=*" %%i in ("%DEFAULT_TOOL_CHAIN_TAG%") do set DEFAULT_TOOL_CHAIN_TAG=%%i
      for /f "tokens=1*" %%i in ('type %CONFIG_FILE% ^| find "TARGET" ^| find /V "#" ^| find /V "TARGET_ARCH"') do set DEFAULT_TARGET%%j
      for /f "tokens=*" %%i in ("%DEFAULT_TARGET%") do set DEFAULT_TARGET=%%i
      if x"%DEFAULT_TOOL_CHAIN_TAG%" == x"" set DEFAULT_TOOL_CHAIN_TAG=MYTOOLS
      if x"%DEFAULT_TARGET%" == x"" set DEFAULT_TARGET=DEBUG
      if x"%TOOL_CHAIN_TAG%" == x"" set TOOL_CHAIN_TAG=%DEFAULT_TOOL_CHAIN_TAG%
      if x"%TARGET%" == x"" set TARGET=%DEFAULT_TARGET%

      rem build clover
      if x"%DSCFILE%" == x"" goto buildall
      rem build specific dsc
      echo Building selected ...
      build %*
      if not x"%errorlevel%" == x"0" goto:eof
      if not x"%CLEANING%" == x"" goto:eof
      goto postbuild

      :buildall
         echo Building CloverEFI IA32 (boot) ...
         build -p %WORKSPACE%\Clover\CloverIa32.dsc -a IA32 %*
         if not x"%errorlevel%" == x"0" goto:eof
		 
         echo Building CloverIA32.efi ...
         build -p %WORKSPACE%\Clover\rEFIt_UEFI\rEFIt.dsc -a IA32 %*
         if not x"%errorlevel%" == x"0" goto:eof

         if x"%BUILD_ARCH%" == x"IA32" (
            if not x"%CLEANING%" == x"" goto:eof
            goto postbuild
         )

      :build64
         echo Building CloverEFI X64 (boot) ...
         build -p %WORKSPACE%\Clover\CloverX64.dsc -a X64 %*
         if not x"%errorlevel%" == x"0" goto:eof

         echo Building CloverX64.efi ...
         build -p %WORKSPACE%\Clover\rEFIt_UEFI\rEFIt64.dsc -a X64 %*
         if not x"%errorlevel%" == x"0" goto:eof
         if not x"%CLEANING%" == x"" goto:eof
         goto postbuild
   
:searchforedk
   if exist edksetup.bat (
      call edksetup.bat
      @echo off
      goto foundedk
   )
   if x"%CD%" == x"%~d0%\" (
      cd %CURRENTDIR%
      echo No EDK found!
      goto failscript
   )
   cd ..
   goto searchforedk

:postbuild
   echo Performing post build operations ...
   set BUILD_DIR=%WORKSPACE%\Build\Clover\%TARGET%_%TOOL_CHAIN_TAG%
   set DEST_DIR=%WORKSPACE%\Clover\CloverPackage\CloverV2
   set BASETOOLS_DIR=%WORKSPACE_TOOLS_PATH%\Bin\Win32
   set BOOTSECTOR_BIN_DIR=%WORKSPACE%\Clover\BootSector\bin

   if x"%BUILD_ARCH%" == x"X64" goto postbuild64

   echo Compressing DUETEFIMainFv.FV (IA32) ...
   %BASETOOLS_DIR%\LzmaCompress -e -o %BUILD_DIR%\FV\DUETEFIMAINFVIA32.z %BUILD_DIR%\FV\DUETEFIMAINFVIA32.Fv

   echo Compressing DxeMain.efi (IA32) ...
   %BASETOOLS_DIR%\LzmaCompress -e -o %BUILD_DIR%\FV\DxeMainIA32.z %BUILD_DIR%\IA32\DxeCore.efi

   echo Compressing DxeIpl.efi (IA32) ...
   %BASETOOLS_DIR%\LzmaCompress -e -o %BUILD_DIR%\FV\DxeIplIA32.z %BUILD_DIR%\IA32\DxeIpl.efi

   echo Generating Loader Image (IA32) ...
   %BASETOOLS_DIR%\EfiLdrImage.exe -o %BUILD_DIR%\FV\Efildr32 %BUILD_DIR%\IA32\EfiLoader.efi %BUILD_DIR%\FV\DxeIplIA32.z %BUILD_DIR%\FV\DxeMainIA32.z %BUILD_DIR%\FV\DUETEFIMAINFVIA32.z
   rem copy /b %BOOTSECTOR_BIN_DIR%\Start.com+%BOOTSECTOR_BIN_DIR%\Efi32.com2+%BUILD_DIR%\FV\Efildr32 %BUILD_DIR%\FV\Efildr
   rem copy /b %BOOTSECTOR_BIN_DIR%\Start16.com+%BOOTSECTOR_BIN_DIR%\Efi32.com2+%BUILD_DIR%\FV\Efildr32 %BUILD_DIR%\FV\Efildr16
   rem copy /b %BOOTSECTOR_BIN_DIR%\Start32.com+%BOOTSECTOR_BIN_DIR%\Efi32.com3+%BUILD_DIR%\FV\Efildr32 %BUILD_DIR%\FV\Efildr20
   copy /b %BOOTSECTOR_BIN_DIR%\start32H.com2+%BOOTSECTOR_BIN_DIR%\efi32.com3+%BUILD_DIR%\FV\Efildr32 %BUILD_DIR%\FV\boot32

   xcopy /d /y %BUILD_DIR%\FV\boot32 %DEST_DIR%\Bootloaders\ia32\boot
   xcopy /d /y %BUILD_DIR%\IA32\FSInject.efi %DEST_DIR%\EFI\drivers32\FSInject-32.efi
   xcopy /d /y %BUILD_DIR%\IA32\VBoxIso9600.efi %DEST_DIR%\drivers-Off\drivers32\VBoxIso9600-32.efi
   xcopy /d /y %BUILD_DIR%\IA32\VBoxExt2.efi %DEST_DIR%\drivers-Off\drivers32\VBoxExt2-32.efi
   xcopy /d /y %BUILD_DIR%\IA32\Ps2KeyboardDxe.efi %DEST_DIR%\drivers-Off\drivers32\Ps2KeyboardDxe-32.efi
   xcopy /d /y %BUILD_DIR%\IA32\Ps2MouseAbsolutePointerDxe.efi %DEST_DIR%\drivers-Off\drivers32\Ps2MouseAbsolutePointerDxe-32.efi
   xcopy /d /y %BUILD_DIR%\IA32\Ps2MouseDxe.efi %DEST_DIR%\drivers-Off\drivers32\Ps2MouseDxe-32.efi
   xcopy /d /y %BUILD_DIR%\IA32\UsbMouseDxe.efi %DEST_DIR%\drivers-Off\drivers32\UsbMouseDxe-32.efi
   xcopy /d /y %BUILD_DIR%\IA32\XhciDxe.efi %DEST_DIR%\drivers-Off\drivers32\XhciDxe-32.efi
   xcopy /d /y %BUILD_DIR%\IA32\OsxFatBinaryDrv.efi %DEST_DIR%\drivers-Off\drivers32UEFI\OsxFatBinaryDrv-32.efi
   xcopy /d /y %WORKSPACE%\Build\rEFIt\%TARGET%_%TOOL_CHAIN_TAG%\IA32\CLOVERIA32.efi %DEST_DIR%\EFI\BOOT\CLOVERIA32.efi

   if x"%BUILD_ARCH%" == x"IA32" goto:eof

:postbuild64
   echo Compressing DUETEFIMainFv.FV (X64) ...
   %BASETOOLS_DIR%\LzmaCompress -e -o %BUILD_DIR%\FV\DUETEFIMAINFVX64.z %BUILD_DIR%\FV\DUETEFIMAINFVX64.Fv

   echo Compressing DxeMain.efi (X64) ...
   %BASETOOLS_DIR%\LzmaCompress -e -o %BUILD_DIR%\FV\DxeMainX64.z %BUILD_DIR%\X64\DxeCore.efi

   echo Compressing DxeIpl.efi (X64) ...
   %BASETOOLS_DIR%\LzmaCompress -e -o %BUILD_DIR%\FV\DxeIplX64.z %BUILD_DIR%\X64\DxeIpl.efi

   echo Generating Loader Image (X64) ...
   %BASETOOLS_DIR%\EfiLdrImage.exe -o %BUILD_DIR%\FV\Efildr64 %BUILD_DIR%\X64\EfiLoader.efi %BUILD_DIR%\FV\DxeIplX64.z %BUILD_DIR%\FV\DxeMainX64.z %BUILD_DIR%\FV\DUETEFIMAINFVX64.z
   rem copy /b %BOOTSECTOR_BIN_DIR%\Start64.com+%BOOTSECTOR_BIN_DIR%\Efi64.com2+%BUILD_DIR%\FV\Efildr64 %BUILD_DIR%\FV\EfildrPure
   rem %BASETOOLS_DIR%\GenPage.exe %BUILD_DIR%\FV\EfildrPure -o %BUILD_DIR%\FV\Efildr
   rem copy /b %BOOTSECTOR_BIN_DIR%\St16_64.com+%BOOTSECTOR_BIN_DIR%\Efi64.com2+%BUILD_DIR%\FV\Efildr64 %BUILD_DIR%\FV\Efildr16Pure
   rem %BASETOOLS_DIR%\GenPage.exe %BUILD_DIR%\FV\Efildr16Pure -o %BUILD_DIR%\FV\Efildr16
   copy /b %BOOTSECTOR_BIN_DIR%\Start64H.com+%BOOTSECTOR_BIN_DIR%\efi64.com3+%BUILD_DIR%\FV\Efildr64 %BUILD_DIR%\FV\Efildr20Pure
   %BASETOOLS_DIR%\GenPage.exe %BUILD_DIR%\FV\Efildr20Pure -o %BUILD_DIR%\FV\Efildr20
   %BASETOOLS_DIR%\Split.exe -f %BUILD_DIR%\FV\Efildr20 -p %BUILD_DIR%\FV\ -o Efildr20.1 -t boot64 -s 512
   del %BUILD_DIR%\FV\Efildr20.1

   xcopy /d /y %BUILD_DIR%\FV\boot64 %DEST_DIR%\Bootloaders\x64\boot
   xcopy /d /y %BUILD_DIR%\X64\FSInject.efi %DEST_DIR%\EFI\drivers64\FSInject-64.efi
   xcopy /d /y %BUILD_DIR%\X64\FSInject.efi %DEST_DIR%\EFI\drivers64UEFI\FSInject-64.efi
   rem xcopy /d /y %BUILD_DIR%\X64\VBoxIso9600.efi %DEST_DIR%\drivers-Off\drivers64\VBoxIso9600-64.efi
   xcopy /d /y %BUILD_DIR%\X64\VBoxExt2.efi %DEST_DIR%\drivers-Off\drivers64\VBoxExt2-64.efi
   xcopy /d /y %BUILD_DIR%\X64\PartitionDxe.efi %DEST_DIR%\drivers-Off\drivers64UEFI\PartitionDxe-64.efi
   xcopy /d /y %BUILD_DIR%\X64\DataHubDxe.efi %DEST_DIR%\drivers-Off\drivers64UEFI\DataHubDxe-64.efi

   rem xcopy /d /y %BUILD_DIR%\X64\Ps2KeyboardDxe.efi %DEST_DIR%\drivers-Off\drivers64\Ps2KeyboardDxe-64.efi
   rem xcopy /d /y %BUILD_DIR%\X64\Ps2MouseAbsolutePointerDxe.efi %DEST_DIR%\drivers-Off\drivers64\Ps2MouseAbsolutePointerDxe-64.efi
   xcopy /d /y %BUILD_DIR%\X64\Ps2MouseDxe.efi %DEST_DIR%\drivers-Off\drivers64\Ps2MouseDxe-64.efi
   xcopy /d /y %BUILD_DIR%\X64\UsbMouseDxe.efi %DEST_DIR%\drivers-Off\drivers64\UsbMouseDxe-64.efi
   xcopy /d /y %BUILD_DIR%\X64\XhciDxe.efi %DEST_DIR%\drivers-Off\drivers64\XhciDxe-64.efi
   xcopy /d /y %BUILD_DIR%\X64\OsxFatBinaryDrv.efi %DEST_DIR%\drivers-Off\drivers64UEFI\OsxFatBinaryDrv-64.efi
   xcopy /d /y %BUILD_DIR%\X64\OsxAptioFixDrv.efi %DEST_DIR%\drivers-Off\drivers64UEFI\OsxAptioFixDrv-64.efi
   xcopy /d /y %BUILD_DIR%\X64\OsxLowMemFixDrv.efi %DEST_DIR%\drivers-Off\drivers64UEFI\OsxLowMemFixDrv-64.efi
   xcopy /d /y %WORKSPACE%\Build\rEFIt\%TARGET%_%TOOL_CHAIN_TAG%\X64\CLOVERX64.efi %DEST_DIR%\EFI\BOOT\CLOVERX64.efi
   goto:eof

:parseArguments
   if x"%1" == x"" goto:eof
   if x"%1" == x"-t" (
      set TOOL_CHAIN_TAG=%2
   )
   if x"%1" == x"--tagname" (
      set TOOL_CHAIN_TAG=%2
   )
   if x"%1" == x"-b" (
      set TARGET=%2
   )
   if x"%1" == x"--buildtarget" (
      set TARGET=%2
   )
   if x"%1" == x"-a" (
      set BUILD_ARCH=%2
   )
   if x"%1" == x"--arch" (
      set BUILD_ARCH=%2
   )
   if x"%1" == x"-p" (
      set DSCFILE=%2
   )
   if x"%1" == x"--platform" (
      set DSCFILE=%2
   )
   if x"%1" == x"-h" (
      build --help
      set errorlevel=1
      goto:eof
   )
   if x"%1" == x"--help" (
      build --help
      set errorlevel=1
      goto:eof
   )
   if x"%1" == x"--version" (
      build --version
      set errorlevel=1
      goto:eof
   )
   if x"%1" == x"clean" (
      set CLEANING=clean
   )
   if x"%1" == x"cleanall" (
      set CLEANING=cleanall
   )
   shift
   goto parseArguments

:failscript
   echo Build failed!