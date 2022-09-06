# Add-On Development Script for WebCTRL

WebCTRL is a trademark of Automated Logic Corporation.  Any other trademarks mentioned herein are the property of their respective owners.

- [Add-On Development Script for WebCTRL](#add-on-development-script-for-webctrl)
  - [About](#about)
  - [Setup Instructions](#setup-instructions)
  - [Command Reference](#command-reference)
  - [Extensions](#extensions)
  - [Generated Project Structure](#generated-project-structure)
  - [Manual Deployment](#manual-deployment)
  - [Dependencies](#dependencies)
    - [Automated Collection](#automated-collection)
  - [Keystore Management](#keystore-management)
  - [Compatibility Notes](#compatibility-notes)
  - [Known Issues](#known-issues)
    - [Recursive Dependency Collection](#recursive-dependency-collection)
    - [Lazy Inline Constants](#lazy-inline-constants)

## About

[This script](Utility.bat) may be used to automate certain aspects of *WebCTRL* add-on development on *Windows* operating systems. *Windows* version 10 or greater is required. *WebCTRL SDK* dependencies are automatically collected from a local *WebCTRL* installation. Other dependencies may be automatically downloaded from URLs. Commands are provided for add-on compilation and packaging. Keystore management is automatic, so you don't have to worry about manually signing your *.addon* file. Newly created projects are scaffolded by the script to contain all required files.

## Setup Instructions

1. Install *WebCTRL8.0* or later.

1. Install the most recent [*JDK*](https://jdk.java.net/) release.

1. Install [*Visual Studio Code*](https://code.visualstudio.com/) and the following extensions:

   - [Visual Studio IntelliCode](https://marketplace.visualstudio.com/items?itemName=VisualStudioExptTeam.vscodeintellicode)

   - [Project Manager for Java](https://marketplace.visualstudio.com/items?itemName=vscjava.vscode-java-dependency)

   - [Lanauge Support for Java(TM) by Red Hat](https://marketplace.visualstudio.com/items?itemName=redhat.java)
  
1. Clone this repository to your local machine.

   - Edit [*LICENSE*](LICENSE) to match your specifications. This license file is copied to the new projects created by the script.

1. Launch [Utility.bat](Utility.bat)

   - You will be prompted to enter the location of the *JDK* bin.

   - If the script cannot locate a *WebCTRL* installation folder under *%SystemDrive%*, you will be prompted to specify an installation path.

     - The script will automatically retrieve all [runtime dependencies](#dependencies) from this *WebCTRL* installation.

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
| `depend [--all]` | Attempts to collect missing dependencies. Recollects all dependencies if the `--all` flag is given. |
| `init [--new]` | Reinitializes the current project if no parameters are given. Prompts you to initialize a new project if the `--new` flag is given. |
| `build [args]` | Compiles source code. The last modified timestamp for each *.java* file is recorded to avoid unnecessary recompilation. Arguments are passed to the `javac` compilation command. Arguments are stored for future invokation, so you only have to type them once. The default compilation flag is `--release 11`. |
| `pack` | Packages all relevant files into a newly created *.addon* archive. |
| `make [args]` | Calls `build` and `pack`. Arguments are passed to `build`. |
| `sign` | Signs the *.addon* archive. |
| `forge [args]` | Calls `build`, `pack`, and `sign`. Arguments are passed to `build`. |
| `deploy` | Copies the *.addon* archive and authenticator certificate to the bound *WebCTRL* installation. |
| `exec [args]` | Calls `build`, `pack`, `sign`, and `deploy`. Arguments are passed to `build`. |
| `git [args]` | All [*Git*](https://git-scm.com/) commands are executed literally. |

## Extensions

Custom project-specific commands can be created to extend the functionality of this script. For examples, refer to <https://github.com/automatic-controls/centralizer-for-webctrl/tree/main/ext>. Any batch file placed in *./ext* is treated as an extension. The name of each batch file is used as the command name (case-insensitive). It is expected that each extension prints help information to the terminal when passed the `--help` parameter. Help information is appended to the help menu shown in the terminal.

The default commands shown in the previous section can be overridden by extensions. For instance, <https://github.com/automatic-controls/commissioning-scripts/blob/main/ext/pack.bat> overrides the default `pack` command. This example also shows how to invoke the overridden packing command (akin to the `super` keyword in Java). For an improved `deploy` command, see <https://github.com/automatic-controls/addon-dev-refresh>.

An optional script, `./startup.bat`, is invoked whenever a project folder is loaded. This may be used for any additional setup required for project files after cloning a remote repository to your local device.

## Generated Project Structure

| File | Description |
| - | - |
| *./.vscode/settings.json* | Tells *Visual Studio Code* where dependencies are located. |
| *./.gitignore* | Tells *Git* what to ignore when committing files. |
| *./Utility.bat* | Script to automate builds. |
| *./README.md* | User-friendly information about the project. |
| *./LICENSE* | License file for the project. |
| *./config* | Contains various configuration files for this script. |
| *./config/BUILD_DETAILS* | Record basic information about the latest build. |
| *./config/COMPILE_FLAGS* | Specifies additional compilation flags. |
| *./config/EXTERNAL_DEPS* | File specifying external dependencies for [automatic collection](#automated-collection). |
| *./config/RUNTIME_DEPS* | File specifying runtime dependencies for [automatic collection](#automated-collection). |
| *./src* | Contains all source code. |
| *./classes* | Contains and indexes compiled *.class* files. |
| *./classes/index.txt* | Records last modified timestamps for source code to avoid unnecessary recompilation. |
| *./root* | Root directory packaged into the *.addon* archive. |
| *./root/info.xml* | Contains basic information about the add-on. |
| *./root/webapp* | Static resources (e.g, files and folders including *html*, *css*, *js*, *jsp*, and *png*). |
| *./root/webapp/WEB-INF/web.xml* | Deployment descriptor (e.g, servlet, filter, and listener mappings). |
| *./root/webapp/WEB-INF/classes* | Contains compiled *.class* files. |
| *./root/webapp/WEB-INF/lib* | Contains dependencies **not** provided by *WebCTRL* at runtime. |
| *./lib* | Contains project-specific dependencies provided by *WebCTRL* at runtime. |
| *./ext* | Contains [extensions](#extensions) that provide additional commands. |
| *./startup.bat* | Batch script which is executed whenever the project folder is loaded. |

## Manual Deployment

1. Place the authentication certificate (look for a file with the *.cer* extension in your local clone of this repository) into the *./addons* directory of the target *WebCTRL* installation.

1. Use the *WebCTRL* interface to install the *.addon* archive of your project.

## Dependencies

Runtime dependencies are located in *./lib* relative to your local clone of this repository. These dependencies do not need to be packaged into your *.addon* file because they are provided by *WebCTRL* at runtime. Other external dependencies should be placed in *./root/webapp/WEB-INF/lib* relative to your project folder. The following runtime dependencies are collected from your *WebCTRL* installation:

| Dependency | Location Relative to *WebCTRL8.0* |
| - | - |
| [*tomcat-embed-core*](https://mvnrepository.com/artifact/javax.servlet/javax.servlet-api) | *./webserver/lib* |
| [*addonsupport-api-addon*](http://repo.alcshare.com/com/controlj/green/addonsupport-api-addon/) | *./modules/addonsupport* |
| [*alarmmanager-api-addon*](http://repo.alcshare.com/com/controlj/green/alarmmanager-api-addon/) | *./modules/alarmmanager* |
| [*bacnet-api-addon*](http://repo.alcshare.com/com/controlj/green/bacnet-api-addon/) | *./bin/lib* |
| [*directaccess-api-addon*](http://repo.alcshare.com/com/controlj/green/directaccess-api-addon/) | *./modules/directaccess* |
| [*webaccess-api-addon*](http://repo.alcshare.com/com/controlj/green/webaccess-api-addon/) | *./modules/webaccess* |
| [*xdatabase-api-addon*](http://repo.alcshare.com/com/controlj/green/xdatabase-api-addon/) | *./modules/xdatabase* |

Feel free to browse your *WebCTRL* installation for dependencies that give access to other internal APIs if these defaults are insufficient. If you would like to add a *WebCTRL* API to one project folder without affecting any other projects, the *.jar* file should be placed in *./lib* relative to your project folder.

[VSCode](https://code.visualstudio.com/) can provide additional features like hover-text documentation for dependencies when source jars are available. Each source jar (*name-sources.jar*) should be placed alongside the corresponding binary jar (*name.jar*). Source jars are ignored when packing the *.addon* archive in an attempt to minimize file size.

### Automated Collection

There are three files which define automatic dependency collection. The first is [*./DEPENDENCIES*](./DEPENDENCIES) relative to your local clone of this repository. This file defines global runtime dependencies used by every project (e.g, the *WebCTRL SDK*). The other two files are [*./config/EXTERNAL_DEPS*](https://github.com/automatic-controls/commissioning-scripts/blob/main/config/EXTERNAL_DEPS) and [*./config/RUNTIME_DEPS*](https://github.com/automatic-controls/commissioning-scripts/blob/main/config/RUNTIME_DEPS) relative to each project folder (click the links for an example).

Dependencies specified by *EXTERNAL_DEPS* are placed in *./root/webapp/WEB-INF/lib*. Dependencies specified by *RUNTIME_DEPS* are placed in *./lib*. Dependency collection automatically occurs whenever a project folder is loaded, or it can be manually triggered with the [`depend`](#command-reference) command.

Each dependency list adheres to the same file format. Two schemes currently exist for collecting dependencies. The `file` scheme searches for a dependency located in your *WebCTRL* installation. The `url` scheme downloads a dependency from a website (using [`curl`](https://curl.se/windows/microsoft.html)). See the example:

```
url:janino:https://repo1.maven.org/maven2/org/codehaus/janino/janino/3.1.7/janino-3.1.7-sources.jar
url:commons-compiler:https://repo1.maven.org/maven2/org/codehaus/janino/commons-compiler/3.1.7/commons-compiler-3.1.7-sources.jar
file:spring-context:bin\lib
file:javax.activation:bin\lib
file:core-api:modules\core
url:CommissioningScripts-0.1.1.jar:https://github.com/automatic-controls/commissioning-scripts/releases/download/v0.1.1-beta/CommissioningScripts-0.1.1.jar
url:CommissioningScripts-0.1.1-sources.jar:https://github.com/automatic-controls/commissioning-scripts/releases/download/v0.1.1-beta/CommissioningScripts-0.1.1-sources.jar
```

The general format is `scheme:identifier:location`. For files, the location is a relative path to the folder in your *WebCTRL* installation which contains the dependency. For urls, the location is a direct download link. The identifier should be the first part of the dependency's filename (excluding the version). Dependency filenames are generally expected to match the regular expression `^identifier-\d.*\.jar$`. Alternatively, the identifier may be an exact match to the filename (including the *.jar* extension).

## Keystore Management

The generated 2048-bit RSA key-pair is valid for 100 years, uses SHA512 as the signature algorithm, and is stored under the alias *addon_dev* in *./keystore.jks*. You can also use a preexisting key-pair under the same alias. An obfuscation of the keystore password is stored in *./config.txt*. The obfuscation algorithm reverses the ordering and XORs each character code with 4. **THE KEYSTORE PASSWORD IS NOT ENCRYPTED; IT IS ONLY OBFUSCATED**.

**Remark:** *WebCTRL* uses the same obfuscation algorithm in a few places I've found. Anyone can inspect the *JavaScript* in a *WebCTRL* login page to discover that operator passwords are obfuscated in this way before being sent to the server (of course, this is **not** a substitute for encrypting traffic with *HTTPS*). The *webserver.keystorepassword* entry from *./resources/properties/settings.properties* (relative to *WebCTRL*) is also obfuscated using the same algorithm.

## Compatibility Notes

*WebCTRL* may complain if your add-on name includes spaces. You should use the build flag `--release 11` for *WebCTRL8.0* and `--release 8` for *WebCTRL7.0*. These flags indicate the *JVM* version to use for compilation. You can determine the appropriate *JVM* version by invoking `"[WebCTRL]\bin\java\jre\bin\java.exe" -version` from command prompt (after replacing `[WebCTRL]` with the path to your *WebCTRL* installation directory).

## Known Issues

### Recursive Dependency Collection

Recursive dependency collection from *Maven* repositories is not supported. *POM* files are commonly used by other compilation scripts for such purposes. For this development tool, you must manually specify the URL to download each required dependency individually.

### Lazy Inline Constants

The *Java* compiler inlines certain constants. This optimization has the potential to cause problems given that this build script only compiles source code files when it detects changes to the last-modified timestamp. For example, suppose *Constants.java* has the following contents.
```java
public class Constants {
   public final static String VERSION = "1.0.0";
}
```
Suppose another class, *Main.java*, contains a reference to `Constants.VERSION`. When *Main.java* is compiled into *Main.class*, the version constant is inlined. Since the constant is evaluated at compilation instead of runtime, *Main.class* will not detect changes to `Constants.VERSION` as one would expect when *Constants.java* is recompiled. In order for changes to inlined constants to fully propagate, all classes which reference the constants must also be recompiled.

Therefore, it is recommended to delete the *./classes* directory and recompile everything after altering inlined constants.