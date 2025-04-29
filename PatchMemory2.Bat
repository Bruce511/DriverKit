cd /d "%~dp0"
.\obdpatch\obdPatch.exe -d=clamem2.dll -c=.\source\InMemory2Driver.Clw -w=1
copy .\clamem2.dll ..\..\bin