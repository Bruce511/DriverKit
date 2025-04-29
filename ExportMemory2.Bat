rem PreBuild commands start in the \clarion\bin folder, not the location of this file.
rem this command changes the "current directory" to be the location of the BAT file.
cd /d "%~dp0"
.\obdexport\obdexport.exe -i=.\Source\InMemory2DriverClass.Inc -e=.\Source\ClaMem2.Exp -l=CLAMEM2 -b=00A20000H -d=InMemory2
