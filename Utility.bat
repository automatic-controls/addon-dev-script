
:: Contributors:
::   Cameron Vogt (@cvogt729)

:: BSD 3-Clause License
:: 
:: Copyright (c) 2022, Automatic Controls Equipment Systems, Inc.
:: All rights reserved.
:: 
:: Redistribution and use in source and binary forms, with or without
:: modification, are permitted provided that the following conditions are met:
:: 
:: 1. Redistributions of source code must retain the above copyright notice, this
::    list of conditions and the following disclaimer.
:: 
:: 2. Redistributions in binary form must reproduce the above copyright notice,
::    this list of conditions and the following disclaimer in the documentation
::    and/or other materials provided with the distribution.
:: 
:: 3. Neither the name of the copyright holder nor the names of its
::    contributors may be used to endorse or promote products derived from
::    this software without specific prior written permission.
:: 
:: THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
:: AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
:: IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
:: DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
:: FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
:: DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
:: SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
:: CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
:: OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
:: OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

@echo off

:: Jump to a particular function
if "%1" EQU "--goto" (
  for /f "tokens=2,* delims= " %%i in ("%*") do (
    call :%%i %%j
    exit /b
  )
  exit /b
)

setlocal EnableDelayedExpansion

:: Version control
set "version=1.1.1"
if "%1" EQU "--version" (
  echo %version%
  exit /b
)

title Add-On Development Utility for WebCTRL
echo Initializing...

:: Whether to let extensions override commands of the same name
set "override=1"

:: This script's location for extension callback usage
set "callback=%~f0"

:: Default compilation arguments
set "compileArgs=--release 11"

:: Global settings folder
call :normalizePath settings "%~dp0."

:: License
set "license=%settings%\LICENSE"

:: External dependencies provided by WebCTRL at runtime (not packaged into the addon)
set "globalLib=%settings%\lib"
if not exist "%globalLib%" mkdir "%globalLib%"

:: JavaScript used to obfuscate the keystore password
set "obfuscate=%settings%\obfuscate.js"

:: Load the configuration file
set "config=%settings%\config.txt"
if exist "%config%" call :loadConfig

:: Determine location of JDK bin
:jdkFinder
  set "jdkFound=0"
  if "%JDKBin%" NEQ "" (
    "%JDKBin%\java.exe" --version >nul 2>nul
    if !ERRORLEVEL! EQU 0 (
      set "jdkFound=1"
    ) else (
      echo Invalid JDK location.
    )
  )
  if "%jdkFound%" EQU "0" (
    echo Enter the location of the JDK bin.
    set /p "JDKBin=>"
    echo.
    call :saveConfig
    goto :jdkFinder
  )

:: Determine location of WebCTRL installation
if "%WebCTRL%" EQU "" (
  for /f %%i in ('dir "%SystemDrive%\" /B /A:D ^| findstr /R /X "WebCTRL[0-9][0-9]*\.[0-9][0-9]*"') do (
    set "WebCTRL=%%i"
  )
  if "!WebCTRL!" NEQ "" (
    set "WebCTRL=%SystemDrive%\!WebCTRL!"
    if exist "!WebCTRL!\webserver\*" (
      echo Bound to installation !WebCTRL!
      echo.
    ) else (
      set "WebCTRL="
    )
  )
)
:webctrlFinder
  if "%WebCTRL%" EQU "" (
    echo Could not locate WebCTRL installation.
    echo Please enter the installation path ^(e.g, %SystemDrive%\WebCTRL8.0^).
    set /p "WebCTRL=>"
    echo.
    call :saveConfig
  )
  if not exist "%WebCTRL%\webserver\*" (
    set "WebCTRL="
    goto :webctrlFinder
  )

:: Collect dependencies
if exist "%settings%\DEPENDENCIES" call :collect "%settings%\DEPENDENCIES" "%globalLib%"

:: Keystore used for signing the addon
set "keystore=%settings%\keystore.jks"

:: Keypair alias in the keystore
set "alias=addon_dev"

:: Certificate file
set "certFileName=Authenticator.cer"
for /f "tokens=* delims=" %%i in ('dir /A-D /B "%settings%\*.cer"') do set "certFileName=%%i"
set "certFile=%settings%\%certFileName%"

:: Retrieve the keystore password
:passwordFinder
  if "!Password!" EQU "" (
    echo DO NOT USE SPECIAL CHARACTERS ^"^&^^!%%;^?
    echo Enter the keystore password.
    set /p "pass=>"
    cls
    call :obfuscate Password pass
    call :saveConfig
    if exist "%keystore%" (
      "%JDKBin%\keytool" -keystore %keystore% -storepass "!pass!" -list >nul 2>nul
      if !ERRORLEVEL! NEQ 0 (
        echo Incorrect password.
        set "Password="
        goto :passwordFinder
      )
    )
  ) else (
    call :obfuscate pass Password
  )

:: Create a new keystore and keypair if it doesn't already exist
set "exists=0"
if exist "%keystore%" (
  "%JDKBin%\keytool" -keystore %keystore% -storepass "!pass!" -list -alias %alias% >nul 2>nul
  if !ERRORLEVEL! EQU 0 (
    set "exists=1"
  ) else (
    echo Alias %alias% is not contained within the pre-existing keystore, so a new key-pair will be created.
  )
)
if "%exists%" EQU "0" (
  if exist "%certFile%" del /F "%certFile%" >nul 2>nul
  "%JDKBin%\keytool.exe" -keystore "%keystore%" -storepass "!pass!" -genkeypair -alias %alias% -keyalg RSA -keysize 2048 -sigalg SHA512withRSA -validity 36500
  echo.
)

if not exist "%certFile%" (
  "%JDKBin%\keytool.exe" -keystore "%keystore%" -storepass "!pass!" -export -alias %alias% -file "%certFile%"
  echo.
)

:: List of valid workspace commands
set "commands[1]=help"
set "commands[2]=depend"
set "commands[3]=build"
set "commands[4]=pack"
set "commands[5]=make"
set "commands[6]=sign"
set "commands[7]=forge"
set "commands[8]=deploy"
set "commands[9]=exec"
set "commands=9"

:: Retrieve workspace from parameter
if "%*" NEQ "" (
  call :normalizePath workspace "%*."
  goto :initWorkspace
)

:globalMenu
  cls
  echo.
  echo WebCTRL Add-On Project Initializer v%version%
  echo.
  echo Enter the project folder to initialize.
  set /p "workspace=>"
  if "!workspace!" NEQ "" (
    echo !workspace! | findstr /C:: >nul 2>nul
    if !ERRORLEVEL! EQU 1 call :normalizePath workspace "%settings%\..\!workspace!"
    goto :initWorkspace
  )
goto :globalMenu

:clsHelp
  echo CLS               Clears the terminal.
exit /b

:initHelp
  echo INIT [--new]      Reinitializes the current project if no parameters are given.
  echo                   Prompts you to initialize a new project if the '--new' flag is given.
exit /b

:help
  if "%override%" EQU "1" if exist "%ext%\help.bat" (
    call "%ext%\help.bat" %*
    exit /b
  )
  if /i "%*" EQU "--help" (
    echo HELP              Displays this message.
    exit /b
  )
  echo.
  echo Online documentation can be found at
  echo https://github.com/automatic-controls/addon-dev-script/blob/main/README.md
  echo.
  echo GIT [ARGS]        All Git commands are executed literally.
  call :initHelp
  call :clsHelp
  setlocal
    for /l %%i in (1,1,%commands%) do (
      set "cmd=!commands[%%i]!"
      if exist "%ext%\!cmd!.bat" (
        call "%ext%\!cmd!.bat" --help
      ) else (
        call :!cmd! --help
      )
    )
    for %%i in ("%ext%\*.bat") do (
      set prev=0
      for /l %%j in (1,1,%commands%) do (
        if "%%~ni" EQU "!commands[%%j]!" set prev=1
      )
      if !prev! EQU 0 call "%%~fi" --help
    )
  endlocal
  echo.
exit /b

:depend
  if "%override%" EQU "1" if exist "%ext%\depend.bat" (
    call "%ext%\depend.bat" %*
    exit /b
  )
  if /i "%*" EQU "--help" (
    echo DEPEND [--all]    Attempts to collect missing dependencies.
    echo                   Recollects all dependencies if the '--all' flag is given.
    exit /b
  ) else if /i "%*" EQU "--all" (
    rmdir /S /Q "%globalLib%" >nul 2>nul
    rmdir /S /Q "%lib%" >nul 2>nul
    rmdir /S /Q "%localLib%" >nul 2>nul
    mkdir "%globalLib%" >nul 2>nul
    mkdir "%lib%" >nul 2>nul
    mkdir "%localLib%" >nul 2>nul
  )
  setlocal
    set "err=0"
    if exist "%settings%\DEPENDENCIES" (
      call :collect "%settings%\DEPENDENCIES" "%globalLib%"
      if !ErrorLevel! NEQ 0 set "err=1"
    ) else (
      echo No global dependencies detected: "%settings%\DEPENDENCIES"
      echo.
    )
    if exist "%libCollector%" (
      call :collect "%libCollector%" "%lib%"
      if !ErrorLevel! NEQ 0 set "err=1"
    ) else (
      echo No external dependencies detected: "%libCollector%"
      echo.
    )
    if exist "%localLibCollector%" (
      call :collect "%localLibCollector%" "%localLib%"
      if !ErrorLevel! NEQ 0 set "err=1"
    ) else (
      echo No runtime dependencies detected: "%localLibCollector%"
      echo.
    )
  endlocal & exit /b %err%

:exec
  if "%override%" EQU "1" if exist "%ext%\exec.bat" (
    call "%ext%\exec.bat" %*
    exit /b
  )
  if /i "%*" EQU "--help" (
    echo EXEC [ARGS]       Calls BUILD, PACK, SIGN, and DEPLOY. Arguments are passed to BUILD.
    exit /b
  )
  ( call :build %* ) && ( call :pack ) && ( call :sign ) && ( call :deploy )
exit /b

:forge
  if "%override%" EQU "1" if exist "%ext%\forge.bat" (
    call "%ext%\forge.bat" %*
    exit /b
  )
  if /i "%*" EQU "--help" (
    echo FORGE [ARGS]      Calls BUILD, PACK, and SIGN. Arguments are passed to BUILD.
    exit /b
  )
  ( call :build %* ) && ( call :pack ) && ( call :sign )
exit /b

:make
  if "%override%" EQU "1" if exist "%ext%\make.bat" (
    call "%ext%\make.bat" %*
    exit /b
  )
  if /i "%*" EQU "--help" (
    echo MAKE [ARGS]       Calls BUILD and PACK. Arguments are passed to BUILD.
    exit /b
  )
  ( call :build %* ) && ( call :pack )
exit /b

:deploy
  if "%override%" EQU "1" if exist "%ext%\deploy.bat" (
    call "%ext%\deploy.bat" %*
    exit /b
  )
  if /i "%*" EQU "--help" (
    echo DEPLOY            Copies the .addon archive and certificate file to the bound WebCTRL installation.
    exit /b
  )
  if "%*" NEQ "" (
    echo Unexpected parameter.
    exit /b 1
  )
  if exist "%addonFile%" (
    echo Deploying...
    if not exist "%WebCTRL%\addons" mkdir "%WebCTRL%\addons" >nul 2>nul
    if exist "%WebCTRL%\addons\!name!.addon" del /F "%WebCTRL%\addons\!name!.addon" >nul 2>nul
    if !ERRORLEVEL! NEQ 0 (
      echo Failed to overwrite !name!.addon. Please deactivate the addon in WebCTRL before attempting to redeploy.
      exit /b 1
    )
    copy /y "%certFile%" "%WebCTRL%\addons\%certFileName%" >nul
    copy /y "%addonFile%" "%WebCTRL%\addons\!name!.addon" >nul
    if !ERRORLEVEL! EQU 0 (
      echo Deployment successful.
      exit /b 0
    ) else (
      echo Deployment unsuccessful.
      exit /b 1
    )
  ) else (
    echo Cannot deploy because !name!.addon does not exist.
    exit /b 1
  )

:sign
  if "%override%" EQU "1" if exist "%ext%\sign.bat" (
    call "%ext%\sign.bat" %*
    exit /b
  )
  if /i "%*" EQU "--help" (
    echo SIGN              Signs the .addon archive.
    exit /b
  )
  if "%*" NEQ "" (
    echo Unexpected parameter.
    exit /b 1
  )
  if exist "%addonFile%" (
    echo Signing...
    "%JDKBin%\jarsigner.exe" -keystore "%keystore%" -storepass "!pass!" "%addonFile%" %alias% >nul
    if !ERRORLEVEL! EQU 0 (
      echo Signing successful.
      exit /b 0
    ) else (
      echo Signing unsuccessful.
      exit /b 1
    )
  ) else (
    echo Cannot sign because !name!.addon does not exist.
    exit /b 1
  )

:pack
  if "%override%" EQU "1" if exist "%ext%\pack.bat" (
    call "%ext%\pack.bat" %*
    exit /b
  )
  if /i "%*" EQU "--help" (
    echo PACK              Packages all relevant files into a newly created .addon archive.
    exit /b
  )
  if "%*" NEQ "" (
    echo Unexpected parameter.
    exit /b 1
  )
  echo Packing...
  rmdir /Q /S "%classes%" >nul 2>nul
  for /D %%i in ("%trackingClasses%\*") do robocopy /E "%%~fi" "%classes%" >nul 2>nul
  robocopy /E "%src%" "%classes%" /XF "*.java" >nul 2>nul
  copy /Y "%workspace%\LICENSE" "%root%\LICENSE" >nul 2>nul
  "%JDKBin%\jar.exe" -c -M -f "%addonFile%" -C "%root%" .
  if %ERRORLEVEL% EQU 0 (
    echo Packing successful.
    exit /b 0
  ) else (
    echo Packing unsuccessful.
    exit /b 1
  )

:build
  if "%override%" EQU "1" if exist "%ext%\build.bat" (
    call "%ext%\build.bat" %*
    exit /b
  )
  if /i "%*" EQU "--help" (
    echo BUILD [ARGS]      Compiles source code. Arguments are passed to the JAVAC compilation command.
    echo                   Current build flags: !compileArgs!
    exit /b
  )
  echo Indexing...
  if "%*" NEQ "" (
    set "compileArgs=%*"
    (
      echo !compileArgs!
    ) > "%workspaceConfig%"
    rmdir /S /Q "%trackingClasses%" >nul 2>nul
  )
  (
    echo JDK Version:
    "%JDKBin%\java.exe" --version
    echo.
    echo Compilation Flags:
    echo !compileArgs!
    echo.
    echo Runtime Dependencies:
    for /r "%globalLib%" %%i in (*.jar) do echo %%~ni
    for /r "%localLib%" %%i in (*.jar) do echo %%~ni
    echo.
    echo Packaged Dependencies:
    for /r "%lib%" %%i in (*.jar) do echo %%~ni
  ) > "%buildDetails%"
  setlocal
    set err=0
    set "changes=0"
    set /a index=0
    for /f "tokens=1,* delims==" %%i in ('echo foreach ^($a in ^(Get-ChildItem -Path "%src%" -Recurse -Include *.java^)^){Echo ^($a.LastWriteTime.toString^(^)+"="+$a.FullName^)} ^| PowerShell -Command -') do (
      set /a index+=1
      set "time[!index!]=%%i"
      set "file[!index!]=%%j"
      set "process[!index!]=0"
    )
    set /a newIndex=0
    if exist "%trackingRecord%" (
      for /f "usebackq tokens=1,2,* delims==" %%i in ("%trackingRecord%") do (
        set exists=0
        for /l %%a in (1,1,%index%) do (
          if !exists! EQU 0 if "!file[%%a]!" EQU "%%k" (
            set exists=1
            set /a newIndex+=1
            set "process[%%a]=1"
            set "newFile[!newIndex!]=%%k"
            if !err! EQU 0 (
              set "newTime[!newIndex!]=!time[%%a]!"
              if "%%j" EQU "!time[%%a]!" (
                if "%%i" NEQ "!newIndex!" rename "%trackingClasses%\%%i" !newIndex!
              ) else (
                echo Compiling: %%k
                set "changes=1"
                rmdir /S /Q "%trackingClasses%\%%i" >nul 2>nul
                mkdir "%trackingClasses%\!newIndex!"
                "%JDKBin%\javac.exe" !compileArgs! -implicit:none -d "%trackingClasses%\!newIndex!" -cp "%src%;%globalLib%\*;%lib%\*;%localLib%\*" "%%k"
                if !ERRORLEVEL! NEQ 0 (
                  rmdir /S /Q "%trackingClasses%\!newIndex!" >nul 2>nul
                  set /a newIndex-=1
                  set err=1
                )
              )
            ) else (
              set "newTime[!newIndex!]=%%j"
              if "%%i" NEQ "!newIndex!" rename "%trackingClasses%\%%i" !newIndex!
            )
          )
        )
        if !exists! EQU 0 (
          set "changes=1"
          echo Removing: %%k
          rmdir /S /Q "%trackingClasses%\%%i" >nul 2>nul
        )
      )
    ) else (
      rmdir /S /Q "%trackingClasses%" >nul 2>nul
      mkdir "%trackingClasses%"
    )
    if %err% EQU 0 (
      for /l %%i in (1,1,%index%) do (
        if !err! EQU 0 if "!process[%%i]!" EQU "0" (
          echo Compiling: !file[%%i]!
          set "changes=1"
          set /a newIndex+=1
          set "newTime[!newIndex!]=!time[%%i]!"
          set "newFile[!newIndex!]=!file[%%i]!"
          if exist "%trackingClasses%\!newIndex!" rmdir /S /Q "%trackingClasses%\!newIndex!" >nul 2>nul
          mkdir "%trackingClasses%\!newIndex!"
          "%JDKBin%\javac.exe" !compileArgs! -implicit:none -d "%trackingClasses%\!newIndex!" -cp "%src%;%globalLib%\*;%lib%\*;%localLib%\*" "!file[%%i]!"
          if !ERRORLEVEL! NEQ 0 (
            rmdir /S /Q "%trackingClasses%\!newIndex!" >nul 2>nul
            set /a newIndex-=1
            set err=1
          )
        )
      )
    )
    (
      for /L %%i in (1,1,!newIndex!) do echo %%i=!newTime[%%i]!=!newFile[%%i]!
    ) > "%trackingRecord%"
    if %err% EQU 1 (
      echo Compilation unsuccessful.
    ) else if "!changes!" EQU "0" (
      echo Compilation skipped.
    ) else (
      echo Compilation successful.
    )
  endlocal & exit /b %err%

:: Obfuscates text
:: First parameter - name of variable to store result
:: Second parameter - name of variable which has text to obfuscate
:obfuscate
  if not exist "%obfuscate%" (
    echo var x = WScript.Arguments^(0^)
    echo var y = ^"^"
    echo for ^(var i=x.length-1;i^>=0;--i^){
    echo     y+=String.fromCharCode^(x.charCodeAt^(i^)^^4^)
    echo }
    echo WScript.Echo^(y^)
  ) > "%obfuscate%"
  for /f "tokens=* delims=" %%i in ('cscript //nologo //E:jscript "%obfuscate%" "!%~2!"') do (
    setlocal DisableDelayedExpansion
    set "tmpVar=%%i"
  )
  (
    endlocal
    set "%~1=%tmpVar%"
  )
  del /F "%obfuscate%" >nul 2>nul
exit /b

:: Loads the configuration file
:loadConfig
  setlocal DisableDelayedExpansion
  for /f "usebackq tokens=* delims=" %%i in ("%config%") do (
    set "%%i"
  )
  (
    endlocal
    set "JDKBin=%JDKBin%"
    set "WebCTRL=%WebCTRL%"
    set "Password=%Password%"
  )
exit /b

:: Saves global configuration properties
:saveConfig
  (
    echo JDKBin=!JDKBin!
    echo WebCTRL=!WebCTRL!
    echo Password=!Password!
  ) > "%config%"
exit /b

:: Resolves relative paths to fully qualified path names.
:normalizePath
  set "%~1=%~f2"
exit /b

:: Collect dependencies from the WebCTRL installation or from external websites
:: Parameters: <dependency-file> <output-folder>
:collect
  setlocal
    set "tmp1=%~dp0tmp1"
    set "tmp2=%~dp0tmp2"
    set "err=0"
    set "msg=0"
    dir "%~f2\*.jar" /B /A-D 2>nul >"%tmp1%"
    for /F "usebackq tokens=1,2,* delims=:" %%i in ("%~f1") do (
      set "findString=%%j"
      if "!findString:~-4!" NEQ ".jar" set "findString=%%j-[0-9].*"
      set "exists=0"
      for /F %%a in ('findstr /R /X "!findString!" "%tmp1%"') do (
        set "exists=1"
      )
      if "!exists!" EQU "0" (
        set "msg=1"
        if /I "%%i" EQU "url" (
          curl --location --fail --silent --output-dir "%~f2" --remote-name %%k
          if !ErrorLevel! EQU 0 (
            echo Collected: %%j
          ) else (
            set "err=1"
            echo Failed to collect: %%j
          )
        ) else if /I "%%i" EQU "file" (
          set "file="
          dir "%WebCTRL%\%%k\*.jar" /B /A-D 2>nul >"%tmp2%"
          for /F %%a in ('findstr /R /X "!findString!" "%tmp2%"') do (
            set "file=%%a"
          )
          if "!file!" EQU "" (
            set "err=1"
            echo Failed to collect: %%j
          ) else (
            copy /Y "%WebCTRL%\%%k\!file!" "%~f2\!file!" >nul
            if !ErrorLevel!==0 (
              echo Collected: %%j
            ) else (
              set "err=1"
              echo Failed to collect: %%j
            )
          )
        ) else (
          set "err=1"
          echo Failed to collect: %%j
        )
      )
    )
    if "%msg%" EQU "1" echo.
    if exist "%tmp1%" del /F "%tmp1%" >nul 2>nul
    if exist "%tmp2%" del /F "%tmp2%" >nul 2>nul
  endlocal & exit /b %err%

:initWorkspace
  echo.
  if not exist "%workspace%" mkdir "%workspace%"
  cd "%workspace%"
  set "root=%workspace%\root"
  if not exist "%root%" mkdir "%root%"

  :: Folder containing custom batch file command extensions for this utility.
  set "ext=%workspace%\ext"

  :: Create local launcher within workspace
  setlocal
    set "batch=%workspace%\Utility.bat"
    set "create=1"
    if exist "%batch%" (
      for /f "tokens=* delims=" %%i in ('call "%batch%" --version') do (
        if "%%i" EQU "%version%" (
          set "create=0"
        )
      )
    )
    if "%create%" EQU "1" (
      echo @echo off
      echo if "%%1" EQU "--version" ^(
      echo   echo %version%
      echo   exit /b
      echo ^)
      echo %0 %%~dp0
    ) > "%batch%"
  endlocal

  :: Source code
  set "src=%workspace%\src"
  if not exist "%src%" mkdir "%src%"

  :: Compiled classes
  set "trackingClasses=%workspace%\classes"
  set "trackingRecord=%trackingClasses%\index.txt"
  set "classes=%root%\webapp\WEB-INF\classes"
  if not exist "%classes%" mkdir "%classes%"

  :: Configuration file folder
  set "configFolder=%workspace%\config"
  if not exist "%configFolder%" mkdir "%configFolder%"

  :: External dependencies (packaged into the addon)
  set "lib=%root%\webapp\WEB-INF\lib"
  if not exist "%lib%" mkdir "%lib%"
  set "libCollector=%configFolder%\EXTERNAL_DEPS"
  if exist "%libCollector%" call :collect "%libCollector%" "%lib%"

  :: Local runtime dependencies (not packaged into the addon)
  set "localLib=%workspace%\lib"
  if not exist "%localLib%" mkdir "%localLib%"
  set "localLibCollector=%configFolder%\RUNTIME_DEPS"
  if exist "%localLibCollector%" call :collect "%localLibCollector%" "%localLib%"

  :: Recent build details
  set "buildDetails=%configFolder%\BUILD_DETAILS"

  :: Visual Studio Code Settings
  set "vscode=%workspace%\.vscode"
  if not exist "%vscode%" mkdir "%vscode%"
  set "vscodeSettings=%vscode%\settings.json"
  if not exist "%vscodeSettings%" (
    echo {
    echo   "java.project.referencedLibraries": [
    echo     "%globalLib:\=\\%\\**\\*.jar",
    echo     "root\\webapp\\WEB-INF\\lib\\**\\*.jar",
    echo     "lib\\**\\*.jar"
    echo   ]
    echo }
  ) > "%vscodeSettings%"

  :: Retrieve basic add-on information
  set "infoXML=%root%\info.xml"
  set "name="
  if exist "%infoXML%" (
    for /f "tokens=* delims=" %%i in ('type "%infoXML%" ^| findstr /C:"<name>"') do (
      for /f "tokens=* delims=" %%j in ('echo echo^([Regex]::Match^("%%i"^, " *<name>(.*)</name> *"^).groups[1].Value^) ^| PowerShell -Command -') do (
        set "name=%%j"
      )
    )
    for /f "tokens=* delims=" %%i in ('type "%infoXML%" ^| findstr /C:"<version>"') do (
      for /f "tokens=* delims=" %%j in ('echo echo^([Regex]::Match^("%%i"^, " *<version>(.*)</version> *"^).groups[1].Value^) ^| PowerShell -Command -') do (
        set "projectVersion=%%j"
      )
    )
  )
  if "%name%" EQU "" (
    echo Enter basic information about your add-on.
    set /p "name=Name: "
    set /p "description=Description: "
    set /p "projectVersion=Version: "
    set /p "vendor=Vendor: "
    (
      echo ^<extension version="1"^>
      echo   ^<name^>!name!^</name^>
      echo   ^<description^>!description!^</description^>
      echo   ^<version^>!projectVersion!^</version^>
      echo   ^<vendor^>!vendor!^</vendor^>
      echo ^</extension^>
    ) > "%infoXML%"
  )

  :: The resulting .addon file
  set "addonFile=%workspace%\!name!.addon"

  :: Deployment descriptor
  set "webXML=%root%\webapp\WEB-INF\web.xml"
  if not exist "%webXML%" (
    echo ^<?xml version="1.0" encoding="UTF-8"?^>
    echo.
    echo ^<web-app^>
    echo.
    echo   ^<listener^>
    echo     ^<listener-class^>^</listener-class^>
    echo   ^</listener^>
    echo.
    echo   ^<welcome-file-list^>
    echo     ^<welcome-file^>^</welcome-file^>
    echo   ^</welcome-file-list^>
    echo.
    echo   ^<servlet^>
    echo     ^<servlet-name^>^</servlet-name^>
    echo     ^<servlet-class^>^</servlet-class^>
    echo   ^</servlet^>
    echo   ^<servlet-mapping^>
    echo     ^<servlet-name^>^</servlet-name^>
    echo     ^<url-pattern^>^</url-pattern^>
    echo   ^</servlet-mapping^>
    echo.
    echo   ^<security-constraint^>
    echo     ^<web-resource-collection^>
    echo       ^<web-resource-name^>WEB^</web-resource-name^>
    echo       ^<url-pattern^>/*^</url-pattern^>
    echo     ^</web-resource-collection^>
    echo   ^</security-constraint^>
    echo.
    echo   ^<filter^>
    echo     ^<filter-name^>RoleFilterAJAX^</filter-name^>
    echo     ^<filter-class^>com.controlj.green.addonsupport.web.RoleFilter^</filter-class^>
    echo     ^<init-param^>
    echo       ^<param-name^>roles^</param-name^>
    echo       ^<param-value^>view_administrator_only^</param-value^>
    echo     ^</init-param^>
    echo   ^</filter^>
    echo   ^<filter-mapping^>
    echo     ^<filter-name^>RoleFilterAJAX^</filter-name^>
    echo     ^<url-pattern^>/*^</url-pattern^>
    echo   ^</filter-mapping^>
    echo.
    echo ^</web-app^>
  ) > "%webXML%"
  
  :: Git ignore
  if not exist "%workspace%\.gitignore" (
    echo .gitignore
    echo .vscode
    echo Utility.bat
    echo classes
    echo root/LICENSE
    echo root/webapp/WEB-INF/classes
    echo root/webapp/WEB-INF/lib
    echo lib
    echo **/*.jar
    echo **/*.addon
  ) > "%workspace%\.gitignore"

  :: License
  if not exist "%workspace%\LICENSE" (
    copy /Y "%license%" "%workspace%\LICENSE" >nul
  )

  :: README
  if not exist "%workspace%\README.md" (
    echo # !name!
  ) > "%workspace%\README.md"

  :: Workspace configuration properties
  set "workspaceConfig=%configFolder%\COMPILE_FLAGS"
  if exist "%workspaceConfig%" (
    for /f "usebackq tokens=* delims=" %%i in ("%workspaceConfig%") do set "compileArgs=%%i"
  )
  (
    echo !compileArgs!
  ) > "%workspaceConfig%"

  :: Execute an optional startup script
  if exist "%workspace%\startup.bat" call "%workspace%\startup.bat"

  :: Main workspace command processing loop
  :main
    cls
    echo.
    echo Add-On Development Utility for WebCTRL
    echo Project: !name!
    echo.
    echo Type 'help' for a list of commands.
    echo.
    :loop
      set "cmd="
      set /p "cmd=>"
      for /f "tokens=1,* delims= " %%a in ("!cmd!") do (
        if /i "%%a" EQU "git" (
          call !cmd!
        ) else if /i "%%a" EQU "cls" (
          if "%%b" EQU "" (
            goto :main
          ) else if /i "%%b" EQU "--help" (
            call :clsHelp
          ) else (
            echo Unexpected parameter.
          )
        ) else if /i "%%a" EQU "init" (
          if "%%b" EQU "" (
            goto :initWorkspace
          ) else if /i "%%b" EQU "--new" (
            goto :globalMenu
          ) else if /i "%%b" EQU "--help" (
            call :initHelp
          ) else (
            echo Unexpected parameter.
          )
        ) else if exist "%ext%\%%a.bat" (
          call "%ext%\%%a.bat" %%b
        ) else (
          set "exists=0"
          for /l %%i in (1,1,%commands%) do (
            if /i "!commands[%%i]!" EQU "%%a" set "exists=1"
          )
          if "!exists!" EQU "1" (
            call :!cmd!
          ) else (
            echo Unknown command.
          )
        )
      )
      goto loop