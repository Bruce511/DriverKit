!------------------------------------------------------------------------------------------------
!   CapeSoft Clarion File Driver Kit classes are copyright © 2025 by CapeSoft                   !
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
DriverIP4Class    Class,Implements(iDriverField), Type, MODULE('DriverFields.Clw'),LINK('DriverFields.Clw',1), DLL(0)
                  End

! -- DriverIP6Class --
! store as a 16 byte binary string. In the program expose as a 39 char string hhhh:hhhh:hhhh:hhhh:hhhh:hhhh:hhhh:hhhh
DriverIP6Class    Class,Implements(iDriverField), Type, MODULE('DriverFields.Clw'),LINK('DriverFields.Clw',1), DLL(0)
                  End

! -- DriverGUIDClass --
! store as a 16 byte binary string. In the program expose it as a 37 byte hex-encoded value, with hyphens
DriverGUIDClass  Class,Implements(iDriverField), Type, MODULE('DriverFields.Clw'),LINK('DriverFields.Clw',1), DLL(0)
                 End

! -- DriverGUIDClass --
! MS SQL UNIQUEIDENTIFIER data type
DriverUniqueIdentifierClass  Class,Implements(iDriverField), Type, MODULE('DriverFields.Clw'),LINK('DriverFields.Clw',1), DLL(0)
                 End

! Because none of these classes contain properties, they're just stand-alone methods, it's possible to declare "singletons"
! here which can then be used for the various fields. There's no need to re-declare these in your app.
DriverIP4                 DriverIp4Class
DriverIP6                 DriverIp6Class
DriverGuid                DriverGuidClass
DriverUniqueIdentifier    DriverUniqueIdentifierClass
