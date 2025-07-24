!------------------------------------------------------------------------------------------------
!   CapeSoft Clarion File Driver Kit classes are copyright © 2025 by CapeSoft                   !
!   Docs online at : https://capesoft.com/docs/Driverkit/ClarionObjectBasedDrivers.htm
!   Released under MIT License
!------------------------------------------------------------------------------------------------
! Notice that DriverFields.Inc, DriverFields.Clw and DriverFields.Int stand alone. They do not include
! the Object-based class files, and the drivers do not compile any of these files.
!
! ---------------------------------------------------------------------------------------------
! This example includes 3 classes
!
!   DriverIP4Class - stores as a 4 byte long, displays as a 15 char string nnn.nnn.nnn.nnn or n.n.n.n
!   DriverIP6Class - stores as a 16 byte (binary) string, displays as a 39 char string hhhh:hhhh:hhhh:hhhh:hhhh:hhhh:hhhh:hhhh
!   DriverGuidClass - stores as a 16 byte (binary) string, displays as a 36 char string  XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX
! ---------------------------------------------------------------------------------------------
! Each class implements 6 interface methods;
!   FromRecordField    : Moves the data from the Clarion record structure to the "disk" buffer
!   ToRecordField      : Moves the data from the "disk" buffer into the Clarion record
!   ClearRecordField   : Sets the field to a "cleared" state. As called by CLEAR(file)
!   GetSourceSize      : Returns the "disk" size of the field (including arrays).
!   GetFieldType       : Return a unique text identifier for the field type
!   GetSQLType         : SQL Data type to use in CREATE statements

! ---------------------------------------------------------------------------------------------
  member()
cs  cstring(200)                                                 ! helpful for debugging
  map
    LoadApiFunctions()
    module('Windows')
      wc_LoadLibrary (*CString pszModuleFileName),long,pascal,raw,name('LoadLibraryA'),Dll(dll_mode)
      wc_GetModuleHandle (*Cstring pszModuleName),long,pascal,raw,name('GetModuleHandleA'),Dll(dll_mode)
      wc_GetProcAddress(long hModule, *CString pszProcName),Long,Pascal,Raw,Name('GetProcAddress'),Dll(Dll_mode)

      wc_dbg(*cstring msg), raw, pascal, name('OutputDebugStringA')  ! helpful for debugging

      wc_inet_ntop(Long pFamily,Long pAddr,*CString pAddress,Long pResultAddr),Long,raw,Pascal,dll(_fp_)
      wc_inet_pton(Long pFamily,*CString pAddress,Long pResultAddr),Long,Proc,raw,Pascal,dll(_fp_)
    end
    module('clarun')
       MemCpy(long dest, long src,  unsigned count), long, proc, name('_memcpy')
       MemSet(long dest, long char, unsigned count), long, proc, name('_memset')
    end
  end
os_inet_pton     long,name('wc_inet_pton')
os_inet_ntop     long,name('wc_inet_ntop')

  include('DriverFields.Inc'),Once

AF_INET                         equate(2)
AF_INET6                        equate(23)
ClaNull                         equate(0)
ClaLong                         equate(6)
ClaString                       equate(012h)

!!!todo Handle arrays in source and destination.

! ----------------------------------------------------------------------------------------------
! A helper function that loads Windows API calls at runtime. Bypasses the need to have a LIB file.
! Also allows the program to run on earlier versions of Windows (although of course the functionality will fail.)
LoadApiFunctions Procedure()
modulehandle      long
modulename        cstring(255)
procedurename     cstring(255)
  code

  moduleName = 'ws2_32.dll'
  modulehandle = wc_LoadLibrary(moduleName)
  If modulehandle
    procedurename = 'inet_pton'
    os_Inet_Pton = wc_GetProcAddress (modulehandle, procedurename)
    If os_Inet_Pton = 0 then cs = 'Unable to load ' & procedurename & ' in DLL ' & modulename ; wc_dbg(cs) .

    procedurename = 'inet_ntop'
    os_Inet_ntop = wc_GetProcAddress (modulehandle, procedurename)
    If os_Inet_ntop = 0 then cs = 'Unable to load ' & procedurename & ' in DLL ' & modulename ; wc_dbg(cs) .
  End

!======================================================================================================================
! DriverIP4Class : Convert IPv4 type (long) into string (dot) format
!======================================================================================================================
! -------------------------------------------------------------------
! First up is a method to identify the field type. This should be unique for differnt field types.
DriverIP4Class.iDriverField.GetFieldType   Procedure()!,STRING ! return a unique text identifier for the field type
  code
  return 'IP4'

! -------------------------------------------------------------------
! This method converts the Clarion dictionary field, and writes the database raw value into pWriteAddress
!
! Takes in a string of the form nnn.nnn.nnn.nnn and writes a Long.
! nnn is a number from 0 to 255. can be 1,2 or 3 digits.
! Returns 4 (the number of bytes written to the address)
! Note: An incoming blank string equates to <0,0,0,0> which in turn equates back as 0.0.0.0
DriverIP4Class.iDriverField.FromRecordField     Procedure(Byte pFieldType, Long pFieldAddress, Long pFieldSize, Long pWriteAddress, Long pWriteSize)
str         string(16)
cstr        cstring(16)
blk         string(4)
Result      Long
  Code
  If os_Inet_Pton = 0 then LoadApiFunctions().
  Clear(blk,-1) ! clear to nulls
  If pFieldSize > 15 then pFieldSize = 15.
  MemCpy(address(str),pFieldAddress,pFieldSize)
  cstr = clip(str)

  If os_Inet_Pton <> 0 and wc_inet_pton(AF_INET,cstr,address(Result)) = 1
    MemCpy(pWriteAddress,address(Result), 4)
  Else
    MemCpy(pWriteAddress,address(blk), 4)
  End
  Return 4 ! The number of bytes written to the output

! -------------------------------------------------------------------
! Formats the source value (long) to a string of nnn.nnn.nnn.nnn where n is from 0 to 255.
! values are not 0 padded.
! The dictionary should declare a string of at least 15 chars to handle this.
!
! nnn is a number from 0 to 255. can be 1,2 or 3 digits.
! note: could use wc_inet_ntop here, but that seems like overkill.
DriverIP4Class.iDriverField.ToRecordField  Procedure(Byte pFieldType, Long pFieldAddress,Long pFieldSize,Long pSrcType, Long pSrcAddr, Long pSrcSize)
str   string(15)
ip    long
byt   byte,dim(4),over(ip)
  code
  If pSrcAddr
    Peek(pSrcAddr,ip)                                                       ! incoming ip address is 4 bytes, hence a long
  Else                                                                      ! Source field is a NULL
    ip = 0
  End
  str = byt[1] & '.' & byt[2] & '.' & byt[3] & '.' & byt[4]
  If pFieldSize <= size(str)
    memcpy(pFieldAddress,address(str),pFieldSize)
  Else
    memcpy(pFieldAddress,address(str),size(str))
    memset(pFieldAddress+size(str),32,pFieldSize-size(str))
  End
  return self.iDriverField.GetSourceSize()  ! pSrcSize may be unknown by caller, so pass actual Size back.

! -------------------------------------------------------------------
! For now the pValue parameter will always be blank. Included for future use.
DriverIP4Class.iDriverField.ClearRecordField  Procedure(Byte pFieldType, Long pFieldAddress,Long pFieldSize,String pValue)
  code
  Return self.iDriverField.ToRecordField(pFieldType,pFieldAddress,pFieldSize,ClaNULL,0,0)

! -------------------------------------------------------------------
! DriverIP4Class is an example of a field type where the source Size is fixed, and known.
DriverIP4Class.iDriverField.GetSourceSize  Procedure()
  code
  Return 4

! -------------------------------------------------------------------
DriverIP4Class.iDriverField.GetSQLType    Procedure() !,STRING
  code
  return 'INT'  ! all common databases use INT for 4 byte integer.

!======================================================================================================================
! DriverIP6Class : Convert IPv6 type (16 char binary) into hex format
!======================================================================================================================
! -------------------------------------------------------------------
! First up is a method to identify the field type. This should be unique for differnt field types.
DriverIP6Class.iDriverField.GetFieldType   Procedure()!,STRING ! return a unique text identifier for the field type
  code
  return 'IP6'

! -------------------------------------------------------------------
! This method converts the Clarion dictionary field, and writes the database raw value into pWriteAddress
!
! Takes in a string of the form hhhh:hhhh:hhhh:hhhh:hhhh:hhhh:hhhh:hhhh and writes a binary String(16)
! h is a hex digit
! Returns 16 (the number of bytes written to the address)
! Note: An incoming blank string equates to <0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0> which in turn equates back as ::
DriverIP6Class.iDriverField.FromRecordField     Procedure(Byte pFieldType, Long pFieldAddress, Long pFieldSize, Long pWriteAddress, Long pWriteSize)
str         string(39)
cstr        cstring(40)
blk         string(16)
Result      Long
  Code
  If os_Inet_Pton = 0 then LoadApiFunctions().
  Clear(blk,-1) ! clear to nulls
  If pFieldSize > 39 then pFieldSize = 39.
  MemCpy(address(str),pFieldAddress,pFieldSize)
  cstr = clip(str)
  If os_Inet_Pton <> 0 and wc_inet_pton(AF_INET6,cstr,address(Result)) = 1
    MemCpy(pWriteAddress,address(Result), 16)
  Else
    MemCpy(pWriteAddress,address(blk), 16)
  End
  Return 16 ! The number of bytes written to the output


! -------------------------------------------------------------------
! Formats the source value (string(16)) to a string of hhhh:hhhh:hhhh:hhhh:hhhh:hhhh:hhhh:hhhh where h is a lowercase hex digit.
! values are not 0 padded.
! The dictionary should declare a string of at least 46 chars to handle this.
!
! nnn is a number from 0 to 255. can be 1,2 or 3 digits.
DriverIP6Class.iDriverField.ToRecordField  Procedure(Byte pFieldType, Long pFieldAddress,Long pFieldSize,Long pSrcType, Long pSrcAddr, Long pSrcSize)
str    string(46)
cstr   cstring(46)
bin    string(16)  ! ip6, binary is 16 bytes
  code
  If os_Inet_ntop = 0 then LoadApiFunctions().
  If pSrcSize > size(bin) then pSrcSize = size(bin).
  If pSrcAddr = 0
    Clear(bin,-1)
  Else
    memcpy(address(bin),pSrcAddr,pSrcSize)
  End
  If os_Inet_ntop and wc_inet_ntop(AF_INET6,address(bin),cstr,size(cstr)) = 0
    cs = 'DriverIP6Class.iDriverField.ToRecord failed.' ; wc_dbg(cs)
  Else
    str = cstr
    If pFieldSize <= size(str)
      memcpy(pFieldAddress,address(str),pFieldSize)
    Else
      !!! todo this assumes the result is a STRING type, and so pads with spaces. If it's a CSTRING then could just terminate with a nul.
      memcpy(pFieldAddress,address(str),size(str))
      memset(pFieldAddress+size(str),32,pFieldSize-size(str))
    End
  End
  return self.iDriverField.GetSourceSize()

! -------------------------------------------------------------------
! For now the pValue parameter will always be blank. Included for future use.
DriverIP6Class.iDriverField.ClearRecordField  Procedure(Byte pFieldType, Long pFieldAddress,Long pFieldSize,String pValue)
  code
  Return self.iDriverField.ToRecordField(pFieldType,pFieldAddress,pFieldSize,ClaNULL,0,0)

! -------------------------------------------------------------------
! DriverIP6Class is an example of a field type where the source Size is fixed, and known.
DriverIP6Class.iDriverField.GetSourceSize  Procedure()
  Code
  Return 16
! -------------------------------------------------------------------
DriverIP6Class.iDriverField.GetSQLType    Procedure() !,STRING
  code
  return 'CHAR(16)'

!======================================================================================================================
! DriverGUIDClass : Convert RFC4122 Guid type (16 char binary) into hex format
!======================================================================================================================
! -------------------------------------------------------------------
! First up is a method to identify the field type. This should be unique for different field types.
DriverGUIDClass.iDriverField.GetFieldType   Procedure()!,STRING ! return a unique text identifier for the field type
  code
  return 'GUID'

! -------------------------------------------------------------------
! This method converts the Clarion dictionary field, and writes the database raw value into pWriteAddress
!
! Takes in a string of the form xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx and writes 16 char binary string.    [8-4-4-4-12]
! x is an uppercase hexadecimal digit
! Returns 16 (the number of bytes written to the address)
DriverGUIDClass.iDriverField.FromRecordField  Procedure(Byte pFieldType, Long pFieldAddress, Long pFieldSize, Long pWriteAddress, Long pWriteSize)
str     string(36)
result  string(16)
pos     long
char    byte
x       long
  Code
  If pFieldSize > size(str) then pFieldSize = size(str).
  MemCpy(address(str),pFieldAddress,pFieldSize)
  str = sub(str,1,8) & sub(str,10,4) & sub(str,15,4) & sub(str,20,4) & sub(str,25,12)
  loop x = 1 to 32 by 2
    char = 0
    case upper(str[x])
    of '0' to '9'
      char = (val(str[x])-48) * 16
    of 'A' to 'F'
      char = (val(str[x])-55) * 16
    end
    case upper(str[x+1])
    of '0' to '9'
      char += str[x+1]
    of 'A' to 'F'
      char += val(str[x+1])-55
    end
    pos += 1
    result[pos] = chr(char)
  End
  If pWriteAddress
    MemCpy(pWriteAddress,address(Result), 16)
  End
  Return 16
! -------------------------------------------------------------------
! Formats the source value (string(16)) to a string of xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx where x is a upper case hex digit
! The dictionary should declare a string of at least 36 chars to handle this.                             [8-4-4-4-12]
!
DriverGUIDClass.iDriverField.ToRecordField   Procedure(Byte pFieldType, Long pFieldAddress,Long pFieldSize,Long pSrcType, Long pSrcAddr, Long pSrcSize)
str  string(36)
bin    string(16)  ! guid, binary is 16 bytes
pos    long
x      long
char   byte
  Code
  If pSrcSize > size(bin) then pSrcSize = size(bin).
  If pSrcAddr = 0
    Clear(bin,-1)
  Else
    memcpy(address(bin),pSrcAddr,pSrcSize)
  End
  pos = 1
  loop x = 1 to 16
    char = bshift(val(bin[x]),-4)
    do OneChar
    char = band(val(bin[x]),0fh)
    do OneChar
    case x
    of 4 orof 6 orof 8 orof 10
      str[pos] = '-'
      pos += 1
    End
  End

  If pFieldSize <= size(str)
    memcpy(pFieldAddress,address(str),pFieldSize)
  Else
    !!! todo this assumes the result is a STRING type, and so pads with spaces. If it's a CSTRING then could just terminate with a nul.
    memcpy(pFieldAddress,address(str),size(str))
    memset(pFieldAddress+size(str),32,pFieldSize-size(str))
  End

  return self.iDriverField.GetSourceSize()

onechar  routine
  case char
  of 0 to 9
    str[pos] = chr(char+48)
  of 10 to 15
    str[pos] = chr(char+55)
  end
  pos += 1
! -------------------------------------------------------------------
! For now the pValue parameter will always be blank. Included for future use.
DriverGUIDClass.iDriverField.ClearRecordField  Procedure(Byte pFieldType, Long pFieldAddress,Long pFieldSize,String pValue)
  code
  Return self.iDriverField.ToRecordField(pFieldType,pFieldAddress,pFieldSize,ClaNULL,0,0)

! -------------------------------------------------------------------
! DriverGUIDClass is an example of a field type where the source Size is fixed, and known.
DriverGUIDClass.iDriverField.GetSourceSize  Procedure()
  code
  Return 16
! -------------------------------------------------------------------
DriverGUIDClass.iDriverField.GetSQLType    Procedure() !,STRING
  code
  return 'CHAR(16)'

!======================================================================================================================

!======================================================================================================================
! DriverUniqueIdentifierClass : MSSQL UNIQUEIDENTIFIER field type
!======================================================================================================================
! -------------------------------------------------------------------
! First up is a method to identify the field type. This should be unique for different field types.
DriverUniqueIdentifierClass.iDriverField.GetFieldType   Procedure()!,STRING ! return a unique text identifier for the field type
  code
  return 'UNIQUEIDENTIFIER'

! -------------------------------------------------------------------
! This method converts the Clarion dictionary field, and writes the database raw value into pWriteAddress
!
! Takes in a string of the form xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx and writes 16 char binary string.    [8-4-4-4-12]
! x is an uppercase hexadecimal digit
! Returns 16 (the number of bytes written to the address)
DriverUniqueIdentifierClass.iDriverField.FromRecordField  Procedure(Byte pFieldType, Long pFieldAddress, Long pFieldSize, Long pWriteAddress, Long pWriteSize)
str     string(36)
result  string(16)
pos     long
char    byte
x       long
  Code
  If pFieldSize > size(str) then pFieldSize = size(str).
  If pWriteAddress and pFieldSize = 16
    MemCpy(pWriteAddress,pFieldAddress, 16)
    Return 16
  End
  MemCpy(address(str),pFieldAddress,pFieldSize)
  str = sub(str,1,8) & sub(str,10,4) & sub(str,15,4) & sub(str,20,4) & sub(str,25,12)
  Loop x = 1 to 32 by 2
    char = 0
    case upper(str[x])
    of '0' to '9'
      char = (val(str[x])-48) * 16
    of 'A' to 'F'
      char = (val(str[x])-55) * 16
    end
    case upper(str[x+1])
    of '0' to '9'
      char += str[x+1]
    of 'A' to 'F'
      char += val(str[x+1])-55
    end
    pos += 1
    result[pos] = chr(char)
  End
  If pWriteAddress
    MemCpy(pWriteAddress,address(Result), 16)
  End
  Return 16
! -------------------------------------------------------------------
! Formats the source value (string(16)) to a string of xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx where x is a upper case hex digit
! The dictionary should declare a string of at least 36 chars to handle this.                             [8-4-4-4-12]
!
DriverUniqueIdentifierClass.iDriverField.ToRecordField   Procedure(Byte pFieldType, Long pFieldAddress,Long pFieldSize,Long pSrcType, Long pSrcAddr, Long pSrcSize)
str  string(36)
bin    string(16)  ! guid, binary is 16 bytes
pos    long
x      long
char   byte
  Code
  If pSrcSize > size(bin) then pSrcSize = size(bin).
  If pSrcAddr = 0
    Clear(bin,-1)
  ElsIf pFieldSize = 16
    memcpy(pFieldAddress,pSrcAddr,pFieldSize)
    return self.iDriverField.GetSourceSize()
  Else
    memcpy(address(bin),pSrcAddr,pSrcSize)
  End
  pos = 1
  loop x = 1 to 16
    char = bshift(val(bin[x]),-4)
    do OneChar
    char = band(val(bin[x]),0fh)
    do OneChar
    case x
    of 4 orof 6 orof 8 orof 10
      str[pos] = '-'
      pos += 1
    End
  End

  If pFieldSize <= size(str)
    memcpy(pFieldAddress,address(str),pFieldSize)
  Else
    !!! todo this assumes the result is a STRING type, and so pads with spaces. If it's a CSTRING then could just terminate with a nul.
    memcpy(pFieldAddress,address(str),size(str))
    memset(pFieldAddress+size(str),32,pFieldSize-size(str))
  End

  return self.iDriverField.GetSourceSize()

onechar  routine
  case char
  of 0 to 9
    str[pos] = chr(char+48)
  of 10 to 15
    str[pos] = chr(char+55)
  end
  pos += 1
! -------------------------------------------------------------------
! For now the pValue parameter will always be blank. Included for future use.
DriverUniqueIdentifierClass.iDriverField.ClearRecordField  Procedure(Byte pFieldType, Long pFieldAddress,Long pFieldSize,String pValue)
  code
  Return self.iDriverField.ToRecordField(pFieldType,pFieldAddress,pFieldSize,ClaNULL,0,0)

! -------------------------------------------------------------------
DriverUniqueIdentifierClass.iDriverField.GetSourceSize  Procedure()
  code
  Return 16
! -------------------------------------------------------------------
DriverUniqueIdentifierClass.iDriverField.GetSQLType    Procedure() !,STRING
  code
  return 'UNIQUEIDENTIFIER'

!======================================================================================================================

