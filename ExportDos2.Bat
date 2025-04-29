rem PreBuild commands start in the \clarion\bin folder, not the location of this file.
rem this command changes the "current directory" to be the location of the BAT file.
cd /d "%~dp0"
.\obdexport\obdexport.exe -i=.\Source\Dos2DriverClass.Inc -e=.\Source\ClaDos2.Exp -l=CLADOS2 -b=00A00000H -d=DOS2
