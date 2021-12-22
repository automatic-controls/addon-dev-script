# WebCTRL Add-On Development

[This script](Utility.bat) may be used to automate certain aspects of *WebCTRL* add-on development on *Windows* operating systems. *WebCTRL SDK* dependencies are automatically collected from a local *WebCTRL* installation. Commands are provided for add-on compilation and packaging. Keystore management is automatic, so you don't have to worry about manually signing your *.addon* file.

## Setup Instructions

1. Install *WebCTRL7.0* or later.

1. Install [*JDK 16*](https://jdk.java.net/) or later.

1. Install [*Visual Studio Code*](https://code.visualstudio.com/) and the following extensions:

   - [Visual Studio IntelliCode](https://marketplace.visualstudio.com/items?itemName=VisualStudioExptTeam.vscodeintellicode)

   - [Project Manager for Java](https://marketplace.visualstudio.com/items?itemName=vscjava.vscode-java-dependency)

   - [Lanauge Support for Java(TM) by Red Hat](https://marketplace.visualstudio.com/items?itemName=redhat.java)
  
1. Clone this repository to your local machine.

   - Edit [*LICENSE*](LICENSE) to match your specifications. This license file is copied to the new projects created by the script.

1. Launch [Utility.bat](Utility.bat)

   - You will be prompted to enter the location of the *JDK* bin.

   - If the script cannot locate a *WebCTRL* installation folder under *%SystemDrive%*, you will be prompted to specify an installation path.

     - The script will automatically retrieve all [runtime dependencies](#dependency-collection) from this *WebCTRL* installation.

   - You will be prompted to enter a keystore password and a few other parameters for creating a new keystore. Refer to [Keystore Management](#keystore-management) for more details.

   - You will be prompted to enter a project folder for initialization.

     - It is recommended to use the naming convention *lowercase-with-hyphens* in accordance with common *GitHub* repository names.

     - Newly created project folders are placed alongside your local clone of this repository, but they can be moved anywhere after creation.

     - You may also enter the absolute path of a project folder. Any name which contains a colon is treated as an absolute path.

     - You can initialize preexisting project folders. For example, you could clone a remote repository to your local machine, and then initialize it with the script to generate missing files.

1. Review documentation at [*ALCshare*](http://alcshare.com/content/add-ons).

## Command Reference

The following commands may be used to automate add-on compilation and packaging.

| Command | Description |
| - | - |
| `help` | Displays a help message listing these commands with brief descriptions. |
| `cls` | Clears the terminal. |
| `new` | Exits the current context and prompts you to initialize a new project. |
| `build [args]` | Compiles source code. The last modified timestamp for each *.java* file is recorded to avoid unnecessary recompilation. Arguments are passed to the `javac` compilation command. Arguments are stored for future invokation, so you only have to type them once. The default compilation flag is `--release 11`. |
| `pack` | Packages all relevant files into a newly created *.addon* archive. |
| `make [args]` | Calls `build` and `pack`. Arguments are passed to `build`. |
| `sign` | Signs the *.addon* archive. |
| `forge [args]` | Calls `build`, `pack`, and `sign`. Arguments are passed to `build`. |
| `deploy` | Copies the *.addon* archive and authenticator certificate to the bound *WebCTRL* installation. |
| `run [args]` | Calls `build`, `pack`, `sign`, and `deploy`. Arguments are passed to `build`. |
| `git [args]` | All [*Git*](https://git-scm.com/) commands are executed literally. |

## Generated Project Structure

| File | Description |
| - | - |
| *./.vscode/settings.json* | Tells *Visual Studio Code* where dependencies are located. |
| *./.gitignore* | Tells *Git* what to ignore when committing files. |
| *./Utility.bat* | Script to automate builds. |
| *./README.md* | User-friendly information about the project. |
| *./DEPENDENCIES* | Record all compile-time dependencies. |
| *./LICENSE* | License file for the project. |
| *./config.txt* | Specifies additional compilation flags. |
| *./src* | Contains all source code. |
| *./classes* | Contains and indexes compiled *.class* files. |
| *./classes/index.txt* | Records last modified timestamps for source code to avoid unnecessary recompilation. |
| *./root* | Root directory packaged into the *.addon* archive. |
| *./root/info.xml* | Contains basic information. |
| *./root/webapp* | Static resources (e.g, files and folders including *html*, *css*, *js*, *jsp*, and *png*). |
| *./root/webapp/WEB-INF/web.xml* | Deployment descriptor (e.g, servlet, filter, and listener mappings). |
| *./root/webapp/WEB-INF/classes* | Contains compiled *.class* files. |
| *./root/webapp/WEB-INF/lib* | Dependencies not provided by *WebCTRL* at runtime. |

## Manual Deployment

1. Place the authentication certificate (look for a file with the *.cer* extension in your local clone of this repository) into the *./addons* directory of the target *WebCTRL* installation.

1. Use the *WebCTRL* interface to install the *.addon* archive of your project.

## Dependency Collection

Runtime dependencies are located in *./lib* relative to your local clone of this repository. These dependencies do not need to be packaged into your *.addon* file because they are provided by *WebCTRL* at runtime. Other external dependencies should be placed in *./root/webapp/WEB-INF/lib* relative to your project folder. The following runtime dependencies are collected from your *WebCTRL* installation:

| Dependency | Location Relative to *WebCTRL* |
| - | - |
| [*tomcat-embed-core*](https://mvnrepository.com/artifact/javax.servlet/javax.servlet-api) | *./webserver/lib* |
| [*addonsupport-api-addon*](http://repo.alcshare.com/com/controlj/green/addonsupport-api-addon/) | *./modules/addonsupport* |
| [*alarmmanager-api-addon*](http://repo.alcshare.com/com/controlj/green/alarmmanager-api-addon/) | *./modules/alarmmanager* |
| [*bacnet-api-addon*](http://repo.alcshare.com/com/controlj/green/bacnet-api-addon/) | *./bin/lib* |
| [*directaccess-api-addon*](http://repo.alcshare.com/com/controlj/green/directaccess-api-addon/) | *./modules/directaccess* |
| [*webaccess-api-addon*](http://repo.alcshare.com/com/controlj/green/webaccess-api-addon/) | *./modules/webaccess* |
| [*xdatabase-api-addon*](http://repo.alcshare.com/com/controlj/green/xdatabase-api-addon/) | *./modules/xdatabase* |

If you change the *WebCTRL* installation by manually editing *./config.txt* (relative to your local clone of this repository), then you should delete *./lib* to force dependency recollection.

## Keystore Management

The generated 2048-bit RSA key-pair is valid for 100 years, uses SHA512 as the signature algorithm, and is stored under the alias *addon_dev* in *./keystore.jks*. You can also use a preexisting key-pair under the same alias. An obfuscation of the keystore password is stored in *./config.txt*. The obfuscation algorithm reverses the ordering and XORs each character code with 4. **THE KEYSTORE PASSWORD IS NOT ENCRYPTED; IT IS ONLY OBFUSCATED**.

**Remark:** *WebCTRL* uses the same obfuscation algorithm in a few places I've found. Anyone can inspect the *JavaScript* in a *WebCTRL* login page to discover that operator passwords are obfuscated in this way before being sent to the server. The *webserver.keystorepassword* entry from *./resources/properties/settings.properties* (relative to *WebCTRL*) is also obfuscated using the same algorithm.

## Compatibility Notes

*WebCTRL* may complain if your add-on name includes spaces. You should use the build flag `--release 11` for *WebCTRL8.0* and `--release 8` for *WebCTRL7.0*. These flags indicate the *JVM* version to use for compilation. You can determine the appropriate *JVM* version by invoking `"[WebCTRL]\bin\java\jre\bin\java.exe" -version` from command prompt (after replacing `[WebCTRL]` with the path to your *WebCTRL* installation directory).