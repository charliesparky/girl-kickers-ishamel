# Development Tools

## AssetStudio

This directory contains `Asset Studio.zip` - a fork of AssetStudio by kenji1997 that is compatible with Girls' Frontline 2 assets.

### Setup

1. Extract the zip file:
```bash
cd tools
unzip "Asset Studio.zip"
```

2. Install .NET 8.0 Desktop Runtime:
```bash
wget https://builds.dotnet.microsoft.com/dotnet/WindowsDesktop/8.0.21/windowsdesktop-runtime-8.0.21-win-x64.exe
wine windowsdesktop-runtime-8.0.21-win-x64.exe
```

### Running AssetStudio

```bash
wine "tools/Asset Studio/AssetStudio.GUI.exe"
```

If using Windows 🤮, you can probably just run the `.exe` (I think).

## KHM Importer for 3DS Max

`KHM_Importer.ms` is a MAXScript plugin that imports Door Kickers 2 model files (.khm) into 3DS Max (only tested on version 2026).

### Setup

Copy `KHM_Importer.ms` to `C:\Program Files\Autodesk\3ds Max 2026\scripts\` (if you know how to run 3DS Max on Linux, PLEASE TELL ME I FUCKING HATE WINDOWS 🤮).

### Usage

1. Open 3DS Max 2026
2. Go to **Scripting > Run Script**
3. Select `KHM_Importer.ms`
4. Choose a `.khm` file to import

The script will import the model with all bones (as generic bones, I don't know how to make biped bones), meshes, skin weights, helpers, and collision objects. Depending on how complex the model is, this may take a while.
