@echo off
set "version=1.0.0"
title WebCTRL Add-on Development Utility
setlocal EnableDelayedExpansion

echo Initializing...

:: Global settings folder
call :normalizePath settings "%~dp0."
call :getFilename settingsFolderName "%settings%"

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

:: Collect runtime dependencies from the WebCTRL installation
setlocal
  set "depFolders[1]=%WebCTRL%\webserver\lib"
  set "depFiles[1]=tomcat-embed-core"
  set "depFolders[2]=%WebCTRL%\modules\addonsupport"
  set "depFiles[2]=addonsupport-api-addon"
  set "depFolders[3]=%WebCTRL%\modules\alarmmanager"
  set "depFiles[3]=alarmmanager-api-addon"
  set "depFolders[4]=%WebCTRL%\bin\lib"
  set "depFiles[4]=bacnet-api-addon"
  set "depFolders[5]=%WebCTRL%\modules\directaccess"
  set "depFiles[5]=directaccess-api-addon"
  set "depFolders[6]=%WebCTRL%\modules\webaccess"
  set "depFiles[6]=webaccess-api-addon"
  set "depFolders[7]=%WebCTRL%\modules\xdatabase"
  set "depFiles[7]=xdatabase-api-addon"
  set "msg=0"
  for /L %%i in (1,1,7) do (
    set "exists=0"
    for /F %%j in ('dir "%globalLib%" /B ^| findstr /C:"!depFiles[%%i]!"') do (
      set "exists=1"
    )
    if "!exists!" EQU "0" (
      set "msg=1"
      set "file="
      for /F %%j in ('dir "!depFolders[%%i]!" /B ^| findstr /C:"!depFiles[%%i]!"') do (
        set "file=%%j"
      )
      if "!file!" EQU "" (
        echo Failed to collect dependency: !depFiles[%%i]!
      ) else (
        copy /Y "!depFolders[%%i]!\!file!" "%globalLib%\!file!" >nul
        if %ErrorLevel%==0 (
          echo Collected dependency: !depFiles[%%i]!
        ) else (
          echo Failed to collect dependency: !depFiles[%%i]!
        )
      )
    )
  )
  if "%msg%" EQU "1" echo.
endlocal

:: Keystore used for signing the addon
set "keystore=%settings%\keystore.jks"

:: Keypair alias in the keystore
set "alias=addon_dev"

:: Certificate file
set "certFile=%settings%\Authenticator.cer"

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
set "commands[2]=clean"
set "commands[3]=build"
set "commands[4]=pack"
set "commands[5]=make"
set "commands[6]=sign"
set "commands[7]=forge"
set "commands=7"

:: Retrieve workspace root from parameter
if "%*" NEQ "" (
  call :normalizePath root "%*."
  goto :initWorkspace
)

:globalMenu
  cls
  echo.
  echo WebCTRL Add-on Project Initializer v%version%
  echo.
  echo Enter the folder name of the project to initialize.
  set /p "root=>"
  if "!root!" NEQ "" (
    call :normalizePath root "%settings%\..\!root!"
    goto :initWorkspace
  )
goto :globalMenu

:help
  echo.
  echo help   -  displays this message
  echo cls    -  clears the terminal
  echo new    -  create a new project
  echo clean  -  deletes all .class files
  echo build  -  calls clean and compiles .java files
  echo pack   -  packages files into .addon archive
  echo make   -  calls build and pack
  echo sign   -  signs the addon
  echo forge  -  calls make and sign
  echo.
  echo Commands starting with the phrase 'git' are executed literally.
  echo.
exit /b

:sign
  "%JDKBin%\jarsigner.exe" -keystore "%keystore%" -storepass "!pass!" "%addonFile%" %alias% >nul
exit /b

::parameteres passed to make
:forge
  call :make %*
  call :sign
exit /b

::parameters passed to build
:make
  call :build %*
  call :pack
exit /b

:pack
  "%JDKBin%\jar.exe" -c -M -f "%addonFile%" -C "%root%\." info.xml -C "%root%\." webapp
exit /b

:: optional parameter to clean a subdirectory tree
:clean
  if exist "%classes%\%*\*" (
    rmdir /Q /S "%classes%\%*" 2>nul
  )
exit /b

::optional parameter to build only a specified file or subdirectory tree
::omit file extensions
:build
  call :clean %*
  setlocal
    if exist "%src%\%*\*" (
      set "param=%src%\%*"
      set "match=*.java"
    ) else if exist "%src%\%*.java" (
      set "param=%src%\%*.java"
      set "match=."
    )
    for /r "%param%" %%i in (%match%) do (
      "%JDKBin%\javac.exe" --release 8 -implicit:none -d "%classes%" -cp "%globalLib%\*;%lib%\*" "%%~fi"
    )
  endlocal
exit /b

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

:: Gets the filename and extension from a path
:getFilename
  set "%~1=%~nx2"
exit /b

:initWorkspace
  echo.
  if not exist "%root%" mkdir "%root%"
  cd "%root%"

  :: Create local launcher within workspace
  setlocal
    set "batch=%root%\Utility.bat"
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
      echo "%%~dp0..\%settingsFolderName%\Utility.bat" %%~dp0
    ) > "%batch%"
  endlocal

  :: Source code
  set "src=%root%\src"
  if not exist "%src%" mkdir "%src%"

  :: Compiled classes
  set "classes=%root%\webapp\WEB-INF\classes"
  if not exist "%classes%" mkdir "%classes%"

  :: External dependencies (packaged into the addon)
  set "lib=%root%\webapp\WEB-INF\lib"
  if not exist "%lib%" mkdir "%lib%"

  :: Visual Studio Code Settings
  set "vscode=%root%\.vscode"
  if not exist "%vscode%" mkdir "%vscode%"
  set "vscodeSettings=%vscode%\settings.json"
  if not exist "%vscodeSettings%" (
    echo {
    echo   "java.project.referencedLibraries": [
    echo     "%globalLib:\=\\%\\*.jar",
    echo     "%lib:\=\\%\\*.jar"
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
  )
  if "%name%" EQU "" (
    echo Enter basic information about your add-on.
    set /p "name=Name: "
    setlocal
      set /p "description=Description: "
      set /p "version=Version: "
      set /p "vendor=Vendor: "
      (
        echo ^<extension^>
        echo   ^<name^>!name!^</name^>
        echo   ^<description^>!description!^</description^>
        echo   ^<version^>!version!^</version^>
        echo   ^<vendor^>!vendor!^</vendor^>
        echo ^</extension^>
      ) > "%infoXML%"
    endlocal
  )

  :: The resulting .addon file
  set "addonFile=%root%\!name!.addon"

  :: Deployment descriptor
  set "webXML=%root%\webapp\WEB-INF\web.xml"
  if not exist "%webXML%" (
    echo ^<?xml version="1.0" encoding="UTF-8"?^>
    echo.
    echo ^<web-app^>
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
    echo       ^<http-method^>GET^</http-method^>
    echo       ^<http-method^>POST^</http-method^>
    echo     ^</web-resource-collection^>
    echo     ^<auth-constraint^>
    echo       ^<role-name^>login^</role-name^>
    echo     ^</auth-constraint^>
    echo   ^</security-constraint^>
    echo.
    echo   ^<login-config^>
    echo     ^<auth-method^>STANDARD^</auth-method^>
    echo   ^</login-config^>
    echo.
    echo ^</web-app^>
  ) > "%webXML%"
  
  :: Git ignore
  if not exist "%root%\.gitignore" (
    echo .vscode
    echo Utility.bat
    echo webapp/WEB-INF/classes
    echo webapp/WEB-INF/lib
    echo **/*.addon
  ) > "%root%\.gitignore"

  :: License
  if not exist "%root%\LICENSE" (
    copy /Y "%license%" "%root%\LICENSE" >nul
  )

  :: README
  if not exist "%root%\README.md" (
    echo # !name!
  ) > "%root%\README.md"

  :: Main workspace command processing loop
  :main
    cls
    echo.
    echo WebCTRL Add-on Development Utility
    echo Project: !name!
    echo.
    echo Type 'help' for a list of commands.
    echo.
    :loop
      set "cmd="
      set /p "cmd=>"
      if /i "!cmd!" EQU "cls" (
        goto main
      ) else if /i "!cmd!" EQU "new" (
        goto :globalMenu
      )
      for /f "tokens=1,* delims= " %%a in ("!cmd!") do (
        if "%%a" EQU "git" (
          call !cmd!
        ) else (
          set "exists=0"
          for /l %%i in (1,1,%commands%) do (
            if "!commands[%%i]!" EQU "%%a" set "exists=1"
          )
          if "!exists!" EQU "1" (
            call :!cmd!
          ) else (
            echo Unknown command.
          )
        )
      )
      goto loop