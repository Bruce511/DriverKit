!------------------------------------------------------------------------------------------------
!   CapeSoft Clarion File Driver Kit classes are copyright © 2026 by CapeSoft                   !
!   Docs online at : https://capesoft.com/docs/Driverkit/ClarionObjectBasedDrivers.htm
!   Released under MIT License
!------------------------------------------------------------------------------------------------

! Interfaces don't have properties. So in simple cases all fields of this type can share the same
! global object. it doesn't even need to be threaded. So a singleton is declared here for that sort of usage.

  map
  end

  include('CWDriver.Int'),once                                                 ! declares the iDriverField Interface

! -- DriverIP4Class --
! store as a 4 byte binary long. In the program expose it as a a.b.c.d string
DriverIP4Class    Class,Implements(iDriverField), Type, MODULE('DriverFields.Clw'),LINK('DriverFields.Clw',DRVLM), DLL(DRVDM)
                  End

! -- DriverIP6Class --
! store as a 16 byte binary string. In the program expose as a 39 char string hhhh:hhhh:hhhh:hhhh:hhhh:hhhh:hhhh:hhhh
DriverIP6Class    Class,Implements(iDriverField), Type, MODULE('DriverFields.Clw'),LINK('DriverFields.Clw',DRVLM), DLL(DRVDM)
                  End

! -- DriverGUIDClass --
! store as a 16 byte binary string. In the program expose it as a 36 byte hex-encoded value, with hyphens
DriverGUIDClass                Class,Implements(iDriverField), Type, MODULE('DriverFields.Clw'),LINK('DriverFields.Clw',DRVLM), DLL(DRVDM)
                               End

! derived class for SQLite Blob type
DriverGUIDSqLiteClass          Class(DriverGUIDClass),Implements(iDriverField), Type, MODULE('DriverFields.Clw'),LINK('DriverFields.Clw',DRVLM), DLL(DRVDM)
                               End

! derived class for Postgres UUID type
DriverUUIDPostgresClass        Class(DriverGUIDClass),Implements(iDriverField), Type, MODULE('DriverFields.Clw'),LINK('DriverFields.Clw',DRVLM), DLL(DRVDM)
                               End

! derived class for MS SQL UNIQUEIDENTIFIER data type
DriverUniqueIdentifierMSClass  Class(DriverGUIDClass),Implements(iDriverField), Type, MODULE('DriverFields.Clw'),LINK('DriverFields.Clw',DRVLM), DLL(DRVDM)
                               End


! Because none of these classes contain properties, they're just stand-alone methods, it's possible to declare "singletons"
! here which can then be used for the various fields. There's no need to re-declare these in your app.
  Compile('***',DRVLM=1)
DriverIP4Object                 DriverIp4Class                    !EXPORT
DriverIP6Object                 DriverIp6Class                    !EXPORT
DriverGuidObject                DriverGuidClass                   !EXPORT
DriverGuidSQLiteObject          DriverGuidSQLiteClass             !EXPORT
DriverUuidPostgresObject        DriverUUIDPostgresClass           !EXPORT
DriverUniqueIdentifierMSObject  DriverUniqueIdentifierMSClass     !EXPORT
  !***
  Compile('***',DRVLM=0)
DriverIP4Object                 DriverIp4Class,EXTERNAL  , DLL(DRVDM)
DriverIP6Object                 DriverIp6Class,EXTERNAL  , DLL(DRVDM)
DriverGuidObject                DriverGuidClass,EXTERNAL , DLL(DRVDM)
DriverGuidSQLiteObject          DriverGuidSQLiteClass,EXTERNAL  , DLL(DRVDM)
DriverUuidPostgresObject        DriverUUIDPostgresClass,EXTERNAL , DLL(DRVDM)
DriverUniqueIdentifierMSObject  DriverUniqueIdentifierMSClass,EXTERNAL , DLL(DRVDM)
  !***
