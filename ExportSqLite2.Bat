rem PreBuild commands start in the \clarion\bin folder, not the location of this file.
rem this command changes the "current directory" to be the location of the BAT file.
cd /d "%~dp0"
.\obdexport\obdexport.exe -i=.\Source\Sqlite2DriverClass.Inc -e=.\Source\ClaLit2.Exp -l=CLALIT2 -b=00A30000H -d=SQLite2
