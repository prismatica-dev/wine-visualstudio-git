# wine-visualstudio-git
Script to install wine-git AUR package with patches to run Visual Studio 2019

### Requirements
This script will patch, build and install wine-git, and as such has the same dependencies: https://aur.archlinux.org/packages/wine-git?all_deps=1#pkgdeps

Additionally, it requires winetricks and wine-mono.

### Running Script
```
git clone https://github.com/prismatica-dev/wine-visualstudio-git
cd wine-visualstudio-git
sh vswine.sh
```

# Installing and Running Visual Studio 2019 on Linux
Despite [numerous](https://stackoverflow.com/questions/60414147/visual-studio-2019-on-linux) [forums](https://askubuntu.com/questions/195144/how-can-i-install-visual-studio) [online](https://stackoverflow.com/questions/76061336/how-do-i-install-visual-studio-on-pop-os-linux-with-wine) concluding that it is impossible to run VS on linux, [this is not true.](https://bugs.winehq.org/show_bug.cgi?id=48023#c29)

### Installation
Modified from https://forum.winehq.org/viewtopic.php?t=36926 and https://bugs.winehq.org/show_bug.cgi?id=48023
### Creating Prefix
```
rm -rf ~/.cache/wine*
mkdir ~/VS2019
cd ~/VS2019
WINEPREFIX="$HOME/VS2019/" wineboot
```
**IMPORTANT:** If not installed, wine may ask to install wine-mono here. Decline and install the wine-mono AUR package instead.

### Installing Visual Studio 2019 Dependencies
```
WINEPREFIX="$HOME/VS2019/" winetricks -q arial d3dcompiler_47 gdiplus
WINEPREFIX="$HOME/VS2019/" winetricks msxml6
WINEPREFIX="$HOME/VS2019/" winetricks dotnet48 dotnet7 dotnetdesktop7 # Replace these with the versions of .NET you wish to install.
WINEPREFIX="$HOME/VS2019/" winetricks vstools2019
```
**IMPORTANT:** You will now see the Visual Studio Installer GUI. The current prompt will install Visual Studio 2019 Build Tools, select the components you want and install. This may produce errors, but they should not prevent you from running VS2019.

### Installing Visual Studio 2019
This method is used to run the old installer gui as the current no longer lists VS2019 releases.
```
wget https://aka.ms/vs/16/release/installer -O vs_installer.opc
mkdir -p opc
unzip -d opc vs_installer.opc
WINEPREFIX="$HOME/VS2019/" wine opc/Contents/vs_installer.exe install --channelId VisualStudio.16.Release --channelUri "https://aka.ms/vs/16/release/channel" --productId Microsoft.VisualStudio.Product.Community
```
**IMPORTANT:** Once again using the GUI select your desired components and install, this may produce errors but it will not stop you from running VS2019.

#### Library Overrides
```
WINEPREFIX="$HOME/VS2019/" winecfg
```
Go to the "Libraries" menu and add 'native' overrides for the following DLLs:
- d3dcompiler_47\*
- gdiplus\*
- mscoree\*
- msxml6\*
- ieframe
- ieproxy
- msimtf
- url (optional, for github login later on)

\* These should already be present from winetricks installations

### Fixing Visual Studio 2019
You have now successfully installed VS2019, but the UI will be a flickering mess and fonts will look horrible. 
#### Fonts
Installing the remaining Windows 10 fonts helps:
```
WINEPREFIX="$HOME/VS2019/" winetricks corefonts allfonts
yay -S ttf-ms-win10-auto
```
Other fixes can be found on the [Arch Linux Wiki](https://wiki.archlinux.org/title/Wine#Fonts), personally I used the `FREETYPE_PROPERTIES="truetype:interpreter-version=35"` environment variable for starting devenv.exe, and enabled fontsmoothing.

#### Disabling Hardware Acceleration
This can be done in VS2019 itself, under "Tools" -> "Options" -> ”Environment” -> ”General” -> Disable "Automatically adjust visual experience based on client performance", "Use hardware graphics acceleration if available". From testing, "Enable rich client visual experience" does not have any negative impact and can be left enabled.

However, due to Hardware Acceleration the options menu ***may not render at all***, preventing itself from being disabled. 
In this case, running with the environment variable `LIBGL_ALWAYS_SOFTWARE=1` should change it to Software Acceleration.

Alternatively, you can change the renderer with winetricks, which in my case did not change the renderer and instead switched VS2019 to using Software Acceleration automatically.
```
WINEPREFIX="$HOME/VS2019/" winetricks
```
Select the default wineprefix -> Change settings -> Enable `Renderer=vulkan`

### Running Visual Studio 2019
Visual Studio's devenv.exe should now run using wine under the new prefix, `WINEPREFIX="$HOME/VS2019/" wine ~/VS2019/drive_c/Program\ Files\ \(x86\)/Microsoft\ Visual\ Studio/2019/Community/Common7/IDE/devenv.exe`.
Alternatively, if it does not open, or closes immediately, appending `/resetsettings` or `/setup` to the end of the command can allow it to run.

## Troubleshooting
#### UI Flickering
Try disabling Hardware Acceleration as specified above. If it still occurs, there may be an issue with your installation of wine.
Installing gdiplus if you chose not to earlier can help, `WINEPREFIX="$HOME/VS2019/" winetricks gdiplus`, but issues not solved by this or native dll overrides are likely distro or user-specific and should be solved on a per-user basis.

#### Visual Studio 2019 will not start even with /resetsettings or /setup
Run `WINEPREFIX="$HOME/VS2019/" winetricks vstools2019`, close out of the Build Tools installer prompt and in the main UI select VS2019, and click "repair". This may once again result in errors, however it should now allow VS to start properly (worked in my case). 

If VS still will not start, try deleting the prefix and repeating the installation and repair process. If that doesn't work, you likely did not patch wine correctly or are experiencing a different problem covered in https://bugs.winehq.org/show_bug.cgi?id=48023.

#### License expired notification
Refer to [this comment](https://bugs.winehq.org/show_bug.cgi?id=48023#c30) for a fix.

#### Cannot sign into Github
**IMPORTANT:** You will still not be able to pull/push repositories once signed in due to a Cygwin issue, this is here purely if someone more knowledgeable than me wants to try and get it working.

Due to an issue with url.dll, the sign-in link will not open in either an embedded browser or the system web browser. You will have to get the github sign-in URL using `WINEDEBUG=+relay` environment variable. 
Go to "Tools" -> "Options" -> "Environment" -> "Accounts" and change "Embedded Browser" to "System Web Browser". Additionally enable the Github Enterprise sign-in option (even if you don't have an Enterprise account, this makes it easier to figure out if the OpenUrl request has been triggered).

To prevent VS2019 from refusing to start with the `WINEDEBUG=+relay` environment value, increase the amount of DLLs ignored by the relay flag.
Using `WINEPREFIX="$HOME/VS2019" wine regedit` set the key `HKEY_CURRENT_USER/Software/Wine/Debug/RelayExclude` to `ntdll.RtlEnterCriticalSection;ntdll.RtlTryEnterCriticalSection;ntdll.RtlLeaveCriticalSection;kernel32.48;kernel32.49;kernel32.94;kernel32.95;kernel32.96;kernel32.97;kernel32.98;kernel32.TlsGetValue;kernel32.TlsSetValue;kernel32.FlsGetValue;kernel32.FlsSetValue;kernel32.SetLastError;kernel32.*;ntdll.*;ucrtbase.*;user32.*;combase.*;oleaut32.*;kernelbase.*;msvcrt.*;shlwapi.*;msvcp140.*;`


Now run `WINEDEBUG=+relay WINEPREFIX="$HOME/VS2019/" wine ~/VS2019/drive_c/Program\ Files\ \(x86\)/Microsoft\ Visual\ Studio/2019/Community/Common7/IDE/devenv.exe &>vs.log` and try to sign in to your Github account. 

After clicking sign in, open `vs.log` and search for any instance of `url.dll` or `url` being listed, one of these should contain the Github sign in link that you can then use to sign in!

Congratulations, you should now be signed in. You can view your repositories (public and private), but cannot clone them due to an authorisation issue caused by Cygwin. Manual authorisation also does not work as password authentication was disabled in 2021. Therefore, you also cannot pull, push or fetch. But, with the amount of warnings and disclaimers on the [Wine Cygwin and More page](https://wiki.winehq.org/Cygwin_and_More), I figure that this is probably a fix best left to someone else.
