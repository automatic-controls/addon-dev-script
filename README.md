# WebCTRL Add-On Development

[This script](Utility.bat) may be used to automate certain aspects of *WebCTRL* add-on development on *Windows* operating systems. *WebCTRL SDK* dependencies are automatically collected from a local *WebCTRL* installation. Commands are provided for add-on compilation and packaging. Keystore management is automatic, so you don't have to worry about manually signing your *.addon* file.

## Setup Installation

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

   - You will be prompted to enter a folder name for initialization of a new project.

     - It is recommended to use the naming convention *lowercase-with-hyphens* in accordance with common *GitHub* repository names.

     - Newly created project folders are placed alongside your local clone of this repository, but they can be moved anywhere after creation.

## Generated Project Structure

<!-- explain the purpose of each file in a generated project -->

## Command Reference

The following commands may be used to automate add-on compilation and packaging. Notably, the *forge* command executes every step at once.

| Command | Description |
| - | - |
| ** |  |
<!-- TODO -->

## Deployment Instructions

1. 
<!-- use WebCTRL interface to install the addon after placing Authenticator.cer (renamed) into the addons directory -->

## Dependency Collection

Runtime dependencies are located in *./lib* relative to your local clone of this repository. These dependencies do not need to be packaged into your *.addon* file because they are provided by *WebCTRL* at runtime. Other external dependencies should be placed in *./webapp/WEB-INF/lib* relative to your project folder. The following runtime dependencies are collected from your *WebCTRL* installation:

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

<!-- explain how one could use a pre-existing keystore if needed, also explain how the keystore password is stored -->