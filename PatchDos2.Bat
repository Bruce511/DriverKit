cd /d "%~dp0"
.\obdpatch\obdPatch.exe -d=clados2.dll -c=.\source\Dos2Driver.Clw -w=1
copy .\clados2.dll ..\..\bin