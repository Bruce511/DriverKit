rem PreBuild commands start in the \clarion\bin folder, not the location of this file.
rem this command changes the "current directory" to be the location of the BAT file.
cd /d "%~dp0"
.\obdexport\obdexport.exe -i=.\Source\DriverClass.Inc -e=.\Source\ClaObd.Exp -l=CLAOBD -b=650000H
.\obdexport\obdexport.exe -a=1 -i=.\Source\CwDriver.Inc -e=.\Source\ClaObd.Exp -l=CLAOBD
