# Vbox4Pwsh

This repository contains a PowerShell wrapper implementation of the `VBoxManage` binary that ships with `VirtualBox`.

It was developed in the course of my master thesis but can actually be used independently.

Both Windows and Ubuntu can be used to run the tool, given that you have PowerShell Core and VirtualBox installed.

Development is still ongoing and Documentation will come!

Until then, just refer to the `Get-Help` options of the commandlets, like:

`Get-Help Get-VboxVMs -Full`

## Installation

At the moment this module is neither published in the PSGallery nor available as a NuGet package, but this is on the roadmap. Until then you have to perform a good old manual installation

### Linux (Ubuntu)

- Clone the repository
- Copy the folder `VBox4Pwsh` to the respective configured paths in your `PSModulePath` environment variable.

```powershell
# Copy module to all paths
$env:PSModulePath.Split(":") | % { Copy-Item "VBox4Pwsh" -Destination $_ -Recurse -Force -Verbose }

# Import module and test
Import-Module VBox4Pwsh

Get-Command -Module VBox4Pwsh
```

### Windows

- Clone the repository
- Copy the folder `VBox4Pwsh` to the respective configured paths in your `PSModulePath` environment variable.

```powershell
# Copy module to all paths
$env:PSModulePath.Split(";") | % { Copy-Item "VBox4Pwsh" -Destination $_ -Recurse -Force -Verbose }

# Import module and test
Import-Module VBox4Pwsh

Get-Command -Module VBox4Pwsh
```