rem PreBuild commands start in the \clarion\bin folder, not the location of this file.
rem this command changes the "current directory" to be the location of the BAT file.
cd /d "%~dp0"
.\obdexport\obdexport.exe -i=..\Libsrc\win\StringTheory.Inc -e=.\Source\ClaStr.Exp -l=CLASTR -b=600000H 