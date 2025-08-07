!------------------------------------------------------------------------------------------------
!   CapeSoft Clarion File Driver Kit classes are copyright © 2025 by CapeSoft                   !
!   Docs online at : https://capesoft.com/docs/Driverkit/ClarionObjectBasedDrivers.htm
!   Released under MIT License
!------------------------------------------------------------------------------------------------

  include('Equates.Clw'),once  
  include('DriverClass.Inc'),once  
  include('DriverFields.Inc'),once    
  include('SQLite2DriverClass.Inc'),once    

!============================================================================================================  
  
!============================================================================================================  
DriverFileInMemory2Class  Class(DriverFileSQLite2Class), Type, MODULE('InMemory2DriverClass.Clw'),LINK('InMemory2DriverClass.Clw',DRVMEM2LM), DLL(DRVMEM2DM)
opt:ThreadedContent         Byte           ! /THREADEDCONTENT 

CONSTRUCT                   Procedure()

PushDatabase                Procedure(string pOwner),Virtual
ReplaceObject               Procedure(Long pOldObjectAddress),Derived

CONNECT                     Procedure(Long pOptions=0),Derived               
DISCONNECT                  Procedure(),Derived
STREAM                      Procedure(),Derived  

SetDriverOption             Procedure(String pOption, String pValue),STRING,Derived
_UpdateFileStrings          Procedure(),Derived    
GetProp:Driver              Procedure(),String,Derived
                          End          

!============================================================================================================  
DriverViewInMemory2Class  Class(DriverViewSQLite2Class), Type, MODULE('InMemory2DriverClass.Clw'),LINK('InMemory2DriverClass.Clw',DRVMEM2LM), DLL(DRVMEM2DM)
GetProp:Driver              Procedure(),String,Derived
                          End
!============================================================================================================  
DriverInMemoryThread      Class, Type, MODULE('InMemory2DriverClass.Clw'),LINK('InMemory2DriverClass.Clw',DRVMEM2LM), DLL(DRVMEM2DM)
Construct                   Procedure()
Destruct                    Procedure(),Virtual
Trace                       Procedure(String pStr),Virtual
                          End
!============================================================================================================  
                      