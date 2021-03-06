**POSZ**

An implementation of [z](https://github.com/rupa/z/ "z") for Powershell

**Getting started**

You can source the script in your Powershell profile.

If you don't already have one, create a profile like below:

`New-item –type file –force $profile`

Source the posz.ps1 script in your profile:

`. c:\path\to\posz.ps1`

Note: To execute scripts, like your profile, you must run the following from an admin powershell console:

`Set-ExecutionPolicy unrestricted`

By default zscores.csv file location is in the same folder as posz.ps1 script.
But you can provide custom file name by setting `$zscoreFile` variable prior to sourcing posz.ps1. For example:

`New-Variable zscoreFile -Value "c:\path\to\myzscorefile.csv" -Force`


**How to use**

Now you can just do 

`cd c:\projects`

`cd c:\projects\oss`

etc and change directories like you normally do.

To jump to directories, just do

`z oss`

and it will cd to c:\projects\oss

To get list of directories and their scores:

`z -list`



