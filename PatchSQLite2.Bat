cd /d "%~dp0"
.\obdpatch\obdPatch.exe -d=clalit2.dll -c=.\source\SQLite2Driver.Clw -w=1   
copy .\clalit2.dll ..\..\bin /y
