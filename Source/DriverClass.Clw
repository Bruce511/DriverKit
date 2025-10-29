!------------------------------------------------------------------------------------------------
!   CapeSoft Clarion File Driver Kit classes are copyright © 2025 by CapeSoft                   !
!   Docs online at : https://capesoft.com/docs/Driverkit/ClarionObjectBasedDrivers.htm
!   Released under MIT License
!------------------------------------------------------------------------------------------------
! -- postgres 9.2 win server 2012

!!!todo setkeyprop:Unique ! allows keys to be "made unique" even if they're not unique in the backend.
!!!todo /EXPLAIN driver string
!!!todo Make ADDRelation global in template

!!!todo View prop:Sql
!!!todo Thread Safety on Unthreaded files and Views

!!!todo allow for result set to be stolen, and used as a separate object?
!!!todo use of memos and blobs in OrderBy and Filter?
!!!todo Alter table  Alter(file), Alter(key), Alter(file,field), Alter(file,blob)
!!!todo Server side math, like Records, Average etc.
!!!todo VIEW prop:NotDistinct
!!!todo Auto-Generate GROUP BY from PROJECT LIST when either prop:GroupBy is set, or PROJECT contains an aggregate function.

!!! for more powerful database engines;
!!!todo prop:hint                                  ! MSSQL possibly ORACLE?
!!!todo stored procedures CALL , NORESULTCALL

!!!todo add test :: view filter can be set BEFORE the view is opened.

  member()

  include('Errors.Clw'),once
  include('AbFile.Equ'),once
  include('Driver.Inc'),once
  include('DriverClass.Inc'),once
  include('StringTheory.Inc'),once

osSYSTEMTIME          group, type
wYear                   ushort
wMonth                  ushort
wDayOfWeek              ushort
wDay                    ushort
wHour                   ushort
wMinute                 ushort
wSecond                 ushort
wMilliseconds           ushort
                      end

! These are very unusual. "global" threaded variables which contains the object that did the most recent SET
! Only one is active - either the File one OR the View one, not both.
FileSETObject         &DriverFileClass,THREAD
ViewSETObject         &DriverViewClass,THREAD

LogCriticalSection    DriverCriticalSection ! not threaded. All drivers. Files and Views.
_ProcessId            Long ! ID of this process in windows.
_WorkStation          Cstring(255)
_User                 Cstring(255)

  map
    module('Windows')
      osOutputDebugString(*cstring msg), raw, pascal, name('OutputDebugStringA'), dll(1)
      osGlobalSize(Long pHandle),Long,raw,pascal,name('GlobalSize'), dll(1)
      osGlobalAlloc(Long pFlags,Long pSize),Long,raw,pascal,name('GlobalAlloc'), dll(1)
      osGlobalFree(Long pHandle),Long,Proc,raw,pascal,name('GlobalFree'), dll(1)
      osGlobalLock(Long pHandle),Long,Proc,raw,pascal,name('GlobalLock'), dll(1)
      osGlobalUnLock(Long pHandle),Long,Proc,raw,pascal,name('GlobalUnLock') , dll(1)
      osGlobalReAlloc(Long pHandle, Long pSize, Long pFlags),Long,raw,pascal,name('GlobalReAlloc'), dll(1)
      osGlobalFlags(Long pHandle),Long,Proc,raw,pascal,name('GlobalFlags'), dll(1)
      osGetLastError(), ulong, raw, pascal, name('GetLastError'), dll(1)
      osFormatMessage(long pFlags,long lpSource,long pMessageId,long pLanguageId,*cstring pBuffer,long pSize,long pVaList),long,Pascal,raw,name('FormatMessageA'), dll(1)

      osCreateFile(*cstring lpFileName, long dwDesiredAccess, long dwSharedMode, long lpSecurityAttributes, |
                    long dwCreationDisposition, long dwFlagsAndAttributes, long hTemplateFile), long, raw, pascal, name('CreateFileA'), dll(1)
      osSetEndOfFile(long hFile),long, proc, raw, pascal, name('SetEndOfFile'), dll(1)
      osWriteFile(long hFile, long lpBuffer, long nNumberOfBytesToWrite, *long lpNumberOfBytesWritten, |
                  long lpOverlapped), long, proc, raw, pascal, name('WriteFile'), dll(1)
      osFlushFileBuffers(long hFile), long, pascal, name('FlushFileBuffers'), dll(1)
      osCloseHandle(long hObject),long, proc, pascal, name('CloseHandle'), dll(1)
      osSHGetFolderPath(long pHandle, long pCSIDL, long hToken, long pFlags, *CSTRING szPath),long, raw, pascal, name('SHGetFolderPathA'), dll(1)
      osGetCurrentProcessId(),ulong,Pascal,raw,name('GetCurrentProcessId') , dll(1)
      osGetSystemTime(*osSYSTEMTIME lpSystemTime), pascal, raw, name('GetSystemTime'), dll(1)
      osWNetGetUser( <*CSTRING lpName>, *CSTRING lpUserName, *ULONG lpnLength  ),ulong,proc,raw,pascal,name('WNetGetUserA')
    end
    module('rtl')
      _MemCpy(long dest, long src,  unsigned count), long, proc, name('_memcpy'),dll(DLL_Mode)
      MemSet(long dest, long char, unsigned count), long, proc, name('_memset'),dll(DLL_Mode)
      _MemCmp(long buf1, long buf2, unsigned count), long, name('_memcmp'),dll(DLL_Mode)
      ClaPopTemp(Long pStr),name('Cla$PopTemp')
      ClaPopString(Long pStrAdr,Long pStrLen),name('Cla$PopString')
      ClaPushString(Long pStrAdr,Long pStrLen),name('Cla$PushString')
      ClaStackHeap(),name('Cla$StackHeap')
      ClaSetError(Long pError),name('Cla$seterror')
      ClaSetFileError(Long pError),name('Cla$setfileerror')
      ClaSetFileError(*CSTRING pErrorCode, *CSTRING pErrorMessage),Raw,NAME('Cla$SetFileError')
      ClaClearError(),NAME('Cla$ClearError')
      ClaSetErrorFile(FILE pFile),NAME('Cla$SetErrorFile')
      ClaActivateDriver(Long pFcb, Long pAccessMode, Long pSupportsLogout, Long pSupportsRollback, Long pSupportsCommit, Long pSupportsLock, Long pSupportsUnlock),name('Cla$activate_drv')
      ClaDeactivateDriver(Long pFcb),name('Cla$deactivate_drv')
      ClaCrc32(Long pBuffer, ULong Bytes, Long crc), Long, Raw,Name('Cla$CRC32')
      SeedRandom(Long pSeed),name('_srand')
      NewCriticalSection(),*ICriticalSection,C,NAME('NewCriticalSection')
    end
    MemCpy(long dest, long src,  unsigned count), long, proc, name('memcpy')

  end

!MaxStringParmLen  Equate(1024)

GMEM_FIXED    Equate(0)
GMEM_MOVEABLE Equate(2)
GMEM_ZEROINIT Equate(40h)

nullkey                &key         ! not set or used, just allows null to be passed to KEY parameters.
!=============================================================================
!  DriverBaseClass
!=============================================================================
!-----------------------------------------------------------------
! helper methods that are shared between the FILE class and the VIEW class
!-----------------------------------------------------------------
DriverBaseClass.Construct  Procedure()
  code
  self.SeedRandom()
  self.rid = random(1000,9999)
  self._result &= New DriverResultSetClass
  self._result.obj &= self
  self.Result  &= self._result.iResultSet
  self.OrderQueue &= New OrderQueueType
  self.ProjectList &= New StringTheory
  self.SqlCode &= New StringTheory
  self.tempstr &= New StringTheory
  self.TokenStr &= New StringTheory
  self.QuoteString    = '"'           ! this is the default value. May be overiden by a derived driver.
  Return

!-----------------------------------------------------------------
DriverBaseClass.Destruct  Procedure()
  code
  !self.trace('[DriverBaseClass DESTRUCT] ' & self.FullPathName)
  self._destructing = true
  Dispose(self.ProjectList)
  Dispose(self.Filter)                 ! prop:filter is the Clarion statement
  Dispose(self.SQLFilter)              ! prop:SqlFilter is a SQL add-on to the clarion statement
  Dispose(self.Where)                  ! prop:where is the calculated SQL WHERE clause.
  Dispose(self.WherePage)

  Dispose(self.Order)                  ! prop:order is the Clarion statement
  Dispose(self.SQLOrder)               ! prop:SqlOrder is a SQL add-on to the clarion statement
  Dispose(self.OrderBy)                ! prop:OrderBy is the calculated SQL ORDER BY clause. An amalgamtion of the above 2, and additional fields to make it unique.
  Dispose(self.tempstr)

  !dispose(self.SQL)
  Dispose(self.SqlCode)
  Dispose(self.GroupBy)
  Dispose(self.Having)

  Dispose(self.ConditionQueue)
  Dispose(self.ValueQueue)
  Dispose(self.LabelQueue)
  Dispose(self.FunctionQueue)
  Dispose(self.ExpressionQueue)
  Dispose(self.TokenStr)
  Dispose(self.OrderQueue)
  Dispose(self.BindQueue)
  self._FreeParameterQueue()
  Dispose(self.ParameterQueue)
  self._FreeSubSet()

  self.Result &= null
  Dispose(self._result)
  If FileSETObject &= self
    FileSETObject &= NULL
  End
  If ViewSETObject &= self
    ViewSETObject &= NULL
  End

!-----------------------------------------------------------------
DriverBaseClass.Trace            PROCEDURE(String pStr)
cstr  Cstring(size(pStr)+101)
  Code
  cstr = '[' & thread() & '][' & self._structure & '][' & self.GetProp:Driver() &'][' & self.GetProp:Label(0) & '][' & self.rid & '] ' & clip(pStr)
  osOutputDebugString(cstr)
  Return

!-----------------------------------------------------------------
DriverBaseClass.BugAlert         PROCEDURE(String pStr)
  code
  self.Trace('[ERROR][BUGALERT] ' & pStr)
  !MESSAGE(pStr,'ERROR')
  return

!-----------------------------------------------------------------
DriverBaseClass.LoadLogging  procedure
  code

!-----------------------------------------------------------------
DriverBaseClass.SETERROR            PROCEDURE(Long pError)
  Code
  If pError = NoError
    ClaClearError()
  Else
    ClaSetError(pError)
    If self._logClarion or self._logSQL then self.Log('[CLAR]SETERROR :' & errorcode() & ' ' & error()  ).
  End
  Return

!-----------------------------------------------------------------
DriverBaseClass.SetFileError        PROCEDURE(String pError, String pMessage)
cError  cstring(size(pError)+1)
cMsg    cstring(size(pMessage)+1)
  Code
  case pError        !!!todo remove this, it's just for debugging sqlite.
  of '0' orof '101'
  else
    self.trace('SetFileError: ' & '[' & clip(pError) & '] :: ' & pMessage & '')
  End
  If pError = '0' then pError = ''.
  cError = pError
  cMsg = pMessage
  ClaSetFileError(cError, cMsg)
  If cError <> '' and (self._logClarion or self._logSQL) then self.Log('[CLAR]SETFILEERROR :' & fileErrorcode() & ' ' & FileError() ).
  Return

!-----------------------------------------------------------------
DriverBaseClass._memchk    PROCEDURE(long pSrc, byte pchar, Long pCount)
x  long,auto
b  byte,auto
  code
  loop x = 1 to pCount
    Peek(pSrc,b)
    If b <> pChar then return false.
    pSrc += 1
  end
  Return true

!!-----------------------------------------------------------------
DriverBaseClass._WinError  PROCEDURE()
FORMAT_MESSAGE_FROM_SYSTEM  equate(1000h)
result                      long,auto
ErrCode                     long,auto
ErrMess                     cstring(1024),auto
  code
  ErrCode = osGetLastError()
  result = osFormatMessage(FORMAT_MESSAGE_FROM_SYSTEM,0,ErrCode,0,ErrMess,size(ErrMess),0)
  self.SetFileError(ErrCode,ErrMess)
  self.trace('[WINDOWS ERROR] ' & ErrCode & ' ' & ErrMess)
  Return

!--------------------------------------------------------------------------------
! thanks to Jeff Slarve for the inspiration for this method.
! https://clarionhub.com/t/enumerating-fields-in-a-group-or-queue-how-do-you-know-youve-reached-the-end/2340
DriverBaseClass.GetAnyType     Procedure(*? pField)
ufo         &driver:iUFO
  code
  ufo &= address(pField)
  If not ufo &= NULL
    return ufo._type(address(pField))
  End
  Return -1

!--------------------------------------------------------------------------------
DriverBaseClass.GetAnySize     Procedure(*? pField)
ufo         &driver:iUFO
  Code
  ufo &= address(pField)
  If not ufo &= NULL
    Return ufo._size(address(pField))
  End
  Return 0

!--------------------------------------------------------------------------------
DriverBaseClass.GetAnyAddress   Procedure(*? pField)
ufo         &driver:iUFO
  code
  ufo &= address(pField)
  if not ufo &= NULL
    return ufo._Address(address(pField))
  end
  return 0

!------------------------------------------------------------------------------
DriverBaseClass.FormatDate    Procedure(Date pDate)
dt  Long,Auto
  code
  dt = pDate
  If dt = 0 then return '0000-00-00'.
  Return Format(pDate,'@d010-')

!----------------------------------------------------------------------------------
DriverBaseClass.FormatTime    Procedure(Time pTime)
tm  Long,auto
  code
  tm = pTime
  If tm = 0 then return '00:00:00.000'.
  Return Format(tm,'@t04') & '.' & Format((tm-1) % 100,'@n02') & '0'

!-----------------------------------------------------------------
DriverBaseClass.FormatTimeStamp            Procedure(String pStr)
gr  group,auto
dt    date
tm    time
    End
  code
  gr = pStr
  Return self.FormatDate(gr.dt) & self.DateTimeSeparator & self.FormatTime(gr.tm)

!-----------------------------------------------------------------
DriverBaseClass._FreeSubset         Procedure()
x  Long,auto
  code
  Self.HasSubset = false
  If not self.SubsetQueue &= null
    Loop x = 1 to records(self.SubsetQueue)
      Get(self.SubsetQueue,x)
      Dispose(self.SubsetQueue.Filter)
    End
    Dispose(self.SubsetQueue)
  End
  self.SubsetInFields       = ''
  self.SubSetFields         = ''
  Return

!-----------------------------------------------------------------
! checks to see if the file is closed. Returns False if the file is open,
DriverBaseClass._CheckClosed  PROCEDURE()
  Code
  If self._opened = true
    self.SetError(IsOpenErr)
  End
  Return choose(self._opened = true, false, true)

!-----------------------------------------------------------------
DriverBaseClass._CheckOpen  PROCEDURE()
  Code
  If self._opened = false
    self.SetError(NotOpenErr)
  !Else
    !self.SetError(NoError)    ! Checkopen must not clear the error code
  End
  Return self._opened

!-----------------------------------------------------------------
DriverBaseClass.NewResultSet       PROCEDURE(Long pOptions)!,VIRTUAL
  code
  self.result.NewResultSet(pOptions)
  self.ResultRow = 0
  self._ResultRow = 0
  Return

!-----------------------------------------------------------------
! Parsing VAList Parameter Methods
!-----------------------------------------------------------------
DriverBaseClass._GetParmAsLong    Procedure(uLong pAddr,Long pParmNumber)
adr ulong,auto
l   long,auto
  code
  adr = pAddr + ((pParmNumber -1) * 4)
  peek(Adr,l)
  Return l

!-----------------------------------------------------------------
DriverBaseClass._GetParmAsUShort    Procedure(uLong pAddr,Long pParmNumber)
adr   ulong,auto
ush   ushort,auto
  code
  adr = pAddr + ((pParmNumber -1) * 4)
  peek(Adr,ush)
  Return ush

!-----------------------------------------------------------------
DriverBaseClass._GetParmAsByte    Procedure(uLong pAddr,Long pParmNumber)
adr  ulong,auto
b    byte,auto
  code
  adr = pAddr + ((pParmNumber -1) * 4)
  Peek(Adr,b)
  Return b

!-----------------------------------------------------------------
DriverBaseClass._PushString    Procedure(String pStr)
  Code
  ClaPushString(address(pStr), size(pStr))
  ClaStackHeap()
  Return

!-----------------------------------------------------------------
DriverBaseClass._PopString    Procedure()
sTmp          like(Cla_StrDesc),auto
  code
  ClaPopTemp(Address(sTmp))
  Return self._GetString(sTmp)

!-----------------------------------------------------------------
DriverBaseClass._GetString    Procedure(*Cla_StrDesc pStr)
str     &string,auto
a       long,auto
b       byte,auto
  code
  If pStr.len = 0 then return ''.
  If pStr.len = -1
    Loop a = pStr.str to pStr.str + 255
      Peek(a,b)
      If b = 0
        Break
      End
    End
    pStr.len = a - pStr.str
  End
  If pStr.len = 0 then return ''.
  str &= pStr.str & ':' & pStr.len
  Return str

!-----------------------------------------------------------------
DriverBaseClass._LongToHex    Procedure(Long pX)
chars  string('0123456789ABCDEF')
  code
  If px <= 0FFFFh
    Return chars[band(bshift(pX,-12),0fh)+1] & chars[band(bshift(pX,-8),0fh)+1] & chars[band(bshift(pX,-4),0fh)+1] & chars[band(bshift(pX,-0),0fh)+1]
  End
  Return chars[band(bshift(pX,-28),0fh)+1] & chars[band(bshift(pX,-24),0fh)+1] & chars[band(bshift(pX,-20),0fh)+1] & chars[band(bshift(pX,-16),0fh)+1] & |
         chars[band(bshift(pX,-12),0fh)+1] & chars[band(bshift(pX,-8),0fh)+1] & chars[band(bshift(pX,-4),0fh)+1] & chars[band(bshift(pX,-0),0fh)+1]

!-----------------------------------------------------------------
DriverBaseClass._HexToLong         Procedure(String pHex)
Ans   Long
ln    Byte,auto
x     Long,auto
  Code
  ln =  len(clip(pHex))
  pHex = upper(pHex)
  If ln > 8 then ln = 8.
  Loop x = 1 to ln
    Case pHex[x]
    Of '0' to '9'
      ans = (ans * 16) + (val(pHex[x])- 48)
    Of 'A' to 'F'
      ans = (ans * 16) + (val(pHex[x])- 55)
    Of 'H'
      break
    End
  End
  Return Ans

!-----------------------------------------------------------------
DriverBaseClass._BinToLong         Procedure(String pBin)
Ans   Long
ln    Byte
x     Long
  Code
  ln =  len(clip(pBin))
  pBin = upper(pBin)
  If ln > 32 then ln = 32.
  Loop x = 1 to ln
    Case pBin[x]
    Of '0'
      ans = ans * 2
    Of '1'
      ans = (ans * 2) + 1
    Of 'B'
      break
    End
  End
  Return Ans

!---------------------------------------------------------------------------------------------
DriverBaseClass._i64ToCString         Procedure(String pI64,*CString pClaString)
bigi    group,over(pI64)
lo        ulong
hi        long
        end
neg     Byte
bigd    Decimal(20) ! 19 digits plus sign
  code
  If band(bigi.hi,10000000h) then neg = true.
  If Neg
    ! convert the number to positive, by inverting all the bits, and adding 1
    BigI.hi = BXOR(BigI.hi,0FFFFFFFFh)
    BigI.lo = BXOR(BigI.lo,0FFFFFFFFh)
    If BigI.lo = 0FFFFFFFFh
      BigI.lo = 0
      BigI.hi += 1
    else
      BigI.lo += 1
    End
  End
  bigd = (bigi.hi * 0FFFFFFFFh) + bigi.lo
  If neg then Bigd = BigD * -1.
  pClaString = bigd
  Return Len(pClaString)

!---------------------------------------------------------------------------------------------
DriverBaseClass._i64Fit              Procedure(String pI64,Byte pClaType,Long pLength)
bigi    group,over(pI64)
lo        ulong
hi        long
        end
neg     Byte
  Code
  If band(bigi.hi,10000000h) then neg = true.
  !self.trace('_i64Fit neg=' & neg)
  Case pClaType
  Of ClaByte
  orOf ClaUShort
  OrOf ClaULong
    If neg then return driver:notok.  ! negative number
  End
  If Neg
    ! convert the number to positive, by inverting all the bits, and adding 1
    BigI.hi = BXOR(BigI.hi,0FFFFFFFFh)
    BigI.lo = BXOR(BigI.lo,0FFFFFFFFh)
    If BigI.lo = 0FFFFFFFFh
      BigI.lo = 0
      BigI.hi += 1
    else
      BigI.lo += 1
    End
  End
  ! at this point BigI is the ABS(BigI) so only need to test positive values.
  Case pClaType
  of ClaBYTE
    If BigI.hi <> 0 or BigI.lo > 255 then Return driver:NotOk.
  of ClaSHORT
    If BigI.hi <> 0 or BigI.lo > 32767 + neg then Return driver:NotOk.
  of ClaUSHORT
    If BigI.hi <> 0 or BigI.lo > 65535 then Return driver:NotOk.
  of ClaLONG
    If BigI.hi <> 0 or bigI.lo > 2147483647 + neg then Return driver:NotOk.
  of ClaULONG
    If BigI.hi <> 0 then Return driver:NotOk.
  of ClaSREAL
    If BigI.hi <> 0 or BigI.lo > 16777216 + neg then Return driver:NotOk.
  of ClaREAL
    If band(BigI.hi , 0FFE00000h ) then Return driver:NotOk.
  of ClaSTRING
  orof ClaPSTRING
    if pLength < 20 then return driver:notok.
  of ClaCSTRING
    if pLength < 21 then return driver:notok.
  of ClaDECIMAL
  orof ClaPDECIMAL
    if pLength < 20 then return driver:notok.
  End
  Return driver:Ok

!---------------------------------------------------------------------------------------------
DriverBaseClass._DecToString         Procedure(Long pStrAddr, Long pLength, Long pDecSize, Long pDecPlaces, Byte pClaType, *String rString)
DDec       Decimal(pDecSize,pDecPlaces),AUTO
PDec       Pdecimal(pDecSize,pDecPlaces),AUTO
  code
  Case pClaType
  Of ClaDECIMAL
    MemCpy(address(DDec),pStrAddr,pLength)
    rString = DDec
  Of ClaPDECIMAL
    MemCpy(address(PDec),pStrAddr,pLength)
    rString = PDec
  End
  Return

!-----------------------------------------------------------------
! string is of form +cccc.dddd
DriverBaseClass._StringToDec         Procedure(*String pStr, Byte pClaType, Long rDecimalAddress, Long rDecSize, Long rDecPlaces)
DDec       Decimal(rDecSize,rDecPlaces),AUTO
PDec       Pdecimal(rDecSize,rDecPlaces),AUTO
  code
  Case pClaType
  Of ClaDECIMAL
    DDec = pStr
    MemCpy(rDecimalAddress,address(DDec),Size(DDec))
  Of ClaPDECIMAL
    PDec = pStr
    MemCpy(rDecimalAddress,address(PDec),Size(PDec))
  End
  Return

!-----------------------------------------------------------------
!!! DERIVE
DriverBaseClass._Morph      Procedure(String pFieldLabel,Byte pClarionType, Long pClarionAddress, Long pClarionLength, Long pCellType, Long pCellAddress, Long pCellLength, Long pSqlTimeStamp, Byte pSetFieldNull, *Long rTextLength)
  code

!-----------------------------------------------------------------
DriverBaseClass._ParseOrderByField       Procedure(String pClause,*Byte pDescending,*Byte pNoCase)
clause  cstring(100),Auto
x       long,Auto
len     long,Auto
  Code
  clause = Clip(Left(Upper(pClause)))
  len = Len(clause)
  pNoCase = false
  Case Sub(clause,1,6)
  of 'UPPER(' orof 'LOWER('
    pNoCase = true
    x = Instring(')',clause,-1,len)
    If x
      clause = clause[7 : x-1] & clause [x+1 : len]
    End
  End
  pDescending = false
  If Right(clause,5) = ' DESC'
    pDescending = true
  End
  x = Instring(' ',clause,1,1)
  If x
    Return Sub(clause,1,x-1)
  End
  Return Clip(clause)

!-----------------------------------------------------------------
DriverBaseClass._reparm   Procedure(StringTheory pOrc, *Long pCount)
neworc  StringTheory
x       cstring(10)
strt    long
einde   long
p       long
  code
  !self.trace('DriverBaseClass._reparm ' & pOrc.GetValue() & ' err=' & errorcode() & ' pCount=' & pCount)
  newOrc.setValue(pOrc)
  loop
    strt = 0
    einde = 0
    x = newOrc.FindBetween('@<<{{','}>@',strt,einde,false,true)
    if strt = 0 or einde = 0 then break.
    pCount += 1
    self._DuplicateParameter(pCount,x)  ! duplicate parameter x into self._ParameterCount
    newOrc.ReplaceSlice(strt-3,einde+3, self._genparm(pCount))
  end
  return newOrc.GetValue()

!-----------------------------------------------------------------
DriverBaseClass._GetColumnNameFromOrder   Procedure(String pClause)
x  Long,Auto
y  Long
  code
  Loop x = 1 to len(clip(pClause))
    Case pClause[x]
    Of ' '
      If y = 0 then y = x.
      Cycle
    of '(' orof '+' orof '-' orof '*' orof '/'
      Return ''
    End
  End
  If y then x = y-1.
  Return Sub(pClause,1,x)

!-----------------------------------------------------------------
!!! derive
DriverBaseClass._GenParm                PROCEDURE(Long pCount)
  code
  return ''

!-----------------------------------------------------------------
DriverBaseClass.InterpretProperty  Procedure(long pProperty)
  code
  case pProperty
  of PROP:AddOnly
    return 'PROP:AddOnly'
  of PROP:Affected
    return 'PROP:Affected'
  of PROP:Alias
    return 'PROP:Alias'
  of Prop:AlwaysQuote
    return 'PROP:AlwaysQuote'
  of PROP:AlwaysRebind
    return 'PROP:AlwaysRebind'
  of PROP:Arrays
    return 'PROP:Arrays'
  of Prop:Attributes
    return 'Prop:Attributes'
  of PROP:Ascending
    return 'PROP:Ascending'
  of Prop:AutoProject
    return 'PROP:AutoProject'
  of PROP:Binary
    return 'PROP:Binary'
  of PROP:Blob
    return 'PROP:Blob'
  of PROP:Blobs
    return 'PROP:Blobs'
  of Prop:Bytes
    return 'PROP:Bytes'
  of PROP:ChildrenAffected
    return 'PROP:ChildrenAffected'
  of Prop:ClearProps
    return 'PROP:ClearProps'
  of PROP:Column
    return 'PROP:Column'
  of PROP:Completed
    return 'PROP:Completed'
  of PROP:Connect
    return 'PROP:Connect'
  of PROP:ConnectString
    return 'PROP:ConnectString'
  of PROP:Create
    return 'PROP:Create'
  of PROP:CreateDB
    return 'PROP:CreateDB'
  of PROP:CurrentKey
    return 'PROP:CurrentKey'
  of Prop:Database
    return 'PROP:Database'
  of Prop:DatabaseName
    return 'PROP:DatabaseName'
  of Prop:DateTimeSeparator
    return 'PROP:DateTimeSeparator'
  of Prop:DbVersionMajor
    return 'PROP:DbVersionMajor'
  of Prop:DbVersionMinor
    return 'PROP:DbVersionMinor'
  of Prop:DbVersionBuild
    return 'PROP:DbVersionBuild'
  of PROP:DBMSVer
    return 'PROP:DBMSVer'
  of PROP:DefaultExtension
    return 'PROP:DefaultExtension'
  of PROP:Details
    return 'PROP:Details'
  of PROP:Dim
    return 'PROP:Dim'
  of PROP:Distinct
    return 'PROP:Distinct'
  of PROP:Disconnect
    return 'PROP:Disconnect'
  of PROP:Driver
    return 'PROP:Driver'
  of PROP:DriverLogsoutAlias
    return 'PROP:DriverLogsoutAlias'
  of PROP:DriverString
    return 'PROP:DriverString'
  of Prop:DriverVersion
    return 'PROP:DriverVersion'
  of prop:OBD
    return 'PROP:OBD'
  of Prop:NotDistinct
    return 'PROP:NotDistinct'
  of PROP:DuplicateKey
    return 'PROP:DuplicateKey'
  of PROP:DynamicFile
    return 'PROP:DynamicFile'
  of PROP:Encrypt
    return 'PROP:Encrypt'
  of PROP:Exists
    return 'PROP:Exists'
  of PROP:Explain
    return 'PROP:Explain'
  of PROP:FastWrite
    return 'PROP:FastWrite'
  of PROP:FetchSize
    return 'PROP:FetchSize'
  of PROP:Field
    return 'PROP:Field'
  of PROP:Fields
    return 'PROP:Fields'
  of PROP:FieldsFile
    return 'PROP:FieldsFile'
  of PROP:FileDriver
    return 'PROP:FileDriver'
  of PROP:File
    return 'PROP:File'
  of PROP:Files
    return 'PROP:Files'
  of PROP:FileSize
    return 'PROP:FileSize'
  of PROP:Filter
    return 'PROP:Filter'
  of PROP:FlushLog
    return 'PROP:FlushLog'
  of PROP:GroupBy
    return 'PROP:GroupBy'
  of PROP:Handle
    return 'PROP:Handle'
  of PROP:Having
    return 'PROP:Having'
  of PROP:Hdbc
    return 'PROP:Hdbc'
  of PROP:Held
    return 'PROP:Held'
  of PROP:Henv
    return 'PROP:Henv'
  of PROP:Hint
    return 'PROP:Hint'
  of PROP:Hstmt
    return 'PROP:Hstmt'
  of PROP:IgnoreTruncation
    return ' PROP:IgnoreTruncation'
  of PROP:ImageAsString
    return 'PROP:ImageAsString'
  of PROP:Inner
    return 'PROP:Inner'
  of PROP:Interface
    return 'PROP:Interface'
  of PROP:IPRequestCount
    return 'PROP:IPRequestCount'
  of PROP:JoinExpression
    return 'PROP:JoinExpression'
  of PROP:Json
    return 'PROP:Json'
  of PROP:Key
    return 'PROP:Key'
  of PROP:Keys
    return 'PROP:Keys'
  of PROP:Label
    return 'PROP:Label'
  of PROP:Limit
    return 'PROP:Limit'
  of Prop:LineEndings
    return 'PROP:LineEndings'
  of PROP:Log
    return 'PROP:Log'
  of PROP:LogFile
    return 'PROP:LogFile'
  of PROP:LoginTimeout
    return 'PROP:LoginTimeout'
  of PROP:LogonScreen
    return 'PROP:LogonScreen'
  of PROP:Logout
    return 'PROP:Logout'
  of PROP:LogoutIsolationLevel
    return 'PROP:LogoutIsolationLevel'
  of Prop:LogBind
    return 'PROP:LogBind'
  of Prop:LogClarion
    return 'PROP:LogClarion'
  of Prop:LogConnections
    return 'PROP:LogConnections'
  of Prop:LogData
    return 'PROP:LogData'
  of Prop:LogExplain
    return 'PROP:LogExplain'
  of PROP:LogOptions
    return 'PROP:LogOptions'
  of PROP:LogSQL
    return 'PROP:LogSQL'
  of PROP:MaxStatements
    return 'PROP:MaxStatements'
  of PROP:Memo
    return 'PROP:Memo'
  of PROP:Memos
    return 'PROP:Memos'
  of PROP:Merge
    return 'PROP:Merge'
  of PROP:MergeName
    return 'PROP:MergeName'
  of PROP:Name
    return 'PROP:Name'
  of PROP:NoKeyProject
    return 'PROP:NoKeyProject'
  of Prop:NoMemo
    return 'PROP:NoMemo'
  of Prop:NoPrevious
    return 'PROP:NoPrevious'
  of Prop:NotDistinct
    return 'PROP:NotDistinct'
  of 'Prop:NullString'
    return('PROP:NullString')
  of PROP:Obd
    return 'PROP:Obd'
  of PROP:Object
    return 'PROP:Object'
  of PROP:OEM
    return 'PROP:OEM'
  of PROP:Offset
    return 'PROP:Offset'
  of PROP:Order
    return 'PROP:Order'
  of PROP:OrderAllTables
    return 'PROP:OrderAllTables'
  of PROP:OrderBy
    return 'PROP:OrderBy'
  of PROP:OrderInSelect
    return 'PROP:OrderInSelect'
  of PROP:Owner
    return 'PROP:Owner'
  of PROP:Over
    return 'PROP:Over'
  of Prop:PageSize
    return 'PROP:PageSize'
  of Prop:Paging
    return 'PROP:Paging'
  of Prop:Pointer
    return 'Prop:Pointer'
  of PROP:Places
    return 'PROP:Places'
  of Prop:Pointer
    return 'PROP:Pointer'
  of Prop:Pool
    return 'PROP:Pool'
  of PROP:Pre
    return 'PROP:Pre'
  of PROP:Prefix
    return 'PROP:Prefix'
  of PROP:Profile
    return 'PROP:Profile'
  of PROP:ProfileIntoFiles
    return 'PROP:ProfileIntoFiles'
  of PROP:ProgressEvents
    return 'PROP:ProgressEvents'
  of Prop:Project
    return 'PROP:Project'
  of PROP:QuoteString
    return 'PROP:QuoteString'
  of PROP:ReadOnly
    return 'PROP:ReadOnly'
  of PROP:Reclaim
    return 'PROP:Reclaim'
  of PROP:Record
    return 'PROP:Record'
  of Prop:Records
    return 'PROP:Records'
  of PROP:RelationsOff
    return 'PROP:RelationsOff'
  of Prop:Reopen
    return 'PROP:Reopen'
  of Prop:ResultGet
    return 'PROP:ResultGet'
  of Prop:ResultNext
    return 'PROP:ResultNext'
  of Prop:ResultPrevious
    return 'PROP:ResultPrevious'
  of Prop:ResultRow
    return 'PROP:ResultRow'
  of Prop:ResultRecords
    return 'PROP:ResultRecords'
  of Prop:Search
    return 'PROP:Search'
  of Prop:SearchRank
    return 'PROP:SearchRank'
  of Prop:Separator
    return 'PROP:Separator'
  of PROP:Server
    return 'PROP:Server'
  of PROP:ServerAutoInc
    return 'PROP:ServerAutoInc'
  of PROP:ServerCaseInsensitive
    return 'PROP:ServerCaseInsensitive'
  of Prop:Size
    return 'Prop:Size'
  of PROP:StmtAttr
    return 'PROP:StmtAttr'
  of PROP:SQLDriver
    return 'PROP:SQLDriver'
  of PROP:SQL
    return 'PROP:SQL'
  of PROP:SQLFilter
    return 'PROP:SQLFilter'
  of PROP:SQLJoinExpression
    return 'PROP:SQLJoinExpression'
  of PROP:SQLOrder
    return 'PROP:SQLOrder'
  of PROP:SQLRowSet
    return 'PROP:SQLRowSet'
  of PROP:SupportsOp
    return 'PROP:SupportsOp'
  of PROP:SupportsType
    return 'PROP:SupportsType'
  of PROP:Text
    return 'PROP:Text'
  of PROP:TextAsString
    return 'PROP:TextAsString'
  of PROP:Thread
    return 'PROP:Thread'
  of PROP:Touched
    return 'PROP:Touched'
  of PROP:Type
    return 'PROP:Type'
  of PROP:User
    return 'PROP:User'
  of PROP:Uuid
    return 'PROP:Uuid'
  of PROP:Uuid4
    return 'PROP:Uuid4'
  of PROP:Uuid7
    return 'PROP:Uuid7'
  of PROP:Uuid8
    return 'PROP:Uuid8'
  of PROP:Value
    return 'PROP:Value'
  of PROP:Watched
    return 'PROP:Watched'
  of PROP:Where
    return 'PROP:Where'
  of PROP:WherePage
    return 'PROP:WherePage'
  end
  Return self._LongToHex(pProperty) & 'h'

!---------------------------------------------------------------------------------
DriverBaseClass.InterpretOpCode  Procedure(long pOpCode)
  code
  case pOpCode
  of Opcode:ADD
    return 'ADD()'
  of Opcode:ADDfilelen
    return 'ADD(length)'
  of Opcode:APPEND
    return 'APPEND()'
  of Opcode:APPENDlen
    return 'APPEND(length)'
  of Opcode:BINDFIELD
    return('BINDFIELD')
  of Opcode:BOF
    return 'BOF()'
  of Opcode:BUFFER
    return 'BUFFER()'
  of Opcode:BUILDdyn
    return 'BUILD(dyn)'
  of Opcode:BUILDdynfilter
    return 'BUILD(dyn,filter)'
  of Opcode:BUILDfile
    return 'BUILD(file)'
  of Opcode:BUILDkey
    return 'BUILD(key)'
  of Opcode:BYTES
    return 'BYTES()'
  of Opcode:BYTES64
    return 'BYTES64()'
  of Opcode:CLOSE
    return 'CLOSE()'
  of Opcode:COMMITdrv
    return 'COMMIT(drv)'
  of Opcode:OPEN
    return 'OPEN()'
  of Opcode:Connect
    return 'CONNECT()'
  of Opcode:COPY
    return 'COPY()'
  of Opcode:CREATE
    return 'CREATE()'
  of Opcode:DELETE
    return 'DELETE()'
  of Opcode:Disconnect
    return 'DISCONNECT()'
  of Opcode:DUPLICATE
    return 'DUPLICATE()'
  of Opcode:DUPLICATEkey
    return 'DUPLICATE(key)'
  of Opcode:EMPTY
    return 'EMPTY()'
  of Opcode:EOF
    return 'EOF()'
  of Opcode:Exists
    return 'EXISTS()'
  of Opcode:FLUSH
    return 'FLUSH()'
  of Opcode:GETfilekey
    return 'GET(file,key)'
  of Opcode:GETfileptrlen
    return 'GET(file,ptr,length)'
  of Opcode:GETfileptr
    return 'GET(file,ptr)'
  of Opcode:GETkeyptr
    return 'GET(key,ptr)'
  of Opcode:HOLDfile
    return 'HOLD(file)'
  of Opcode:HOLDfilesec
    return 'HOLD(file,seconds)'
  of Opcode:LOCKfile
    return 'LOCK(file)'
  of Opcode:LOCKfilesec
    return 'LOCK(file,seconds)'
  of Opcode:LOGOUTdrv
    return 'LOGOUT(driver)'
  of Opcode:MERGE
    return 'MERGE()'
  of Opcode:NAME
    return 'NAME()'
  of Opcode:NEXT
    return 'NEXT()'
  of Opcode:PACK
    return 'PACK()'
  of Opcode:POINTERfile
    return 'POINTER(file)'
  of Opcode:POINTER64
    return 'POINTER64()'
  of Opcode:POINTERkey
    return 'POINTER(key)'
  of Opcode:POSITIONfile
    return 'POSITION'
  of Opcode:POSITIONkey
    return 'POSITION(key)'
  of Opcode:PREVIOUS
    return 'PREVIOUS()'
  of Opcode:PUT
    return 'PUT()'
  of Opcode:PUTfileptr
    return 'PUT(file,pointer)'
  of Opcode:PUTfileptrlen
    return 'PUT(file,pointer,length)'
  of Opcode:RECORDSfile
    return 'RECORDS(file)'
  of Opcode:RECORDSkey
    return 'RECORDS(key)'
  of Opcode:RECORDS64
    return 'RECORDS64()'
  of Opcode:RELEASE
    return 'RELEASE()'
  of Opcode:REMOVE
    return 'REMOVE()'
  of Opcode:RENAME
    return 'RENAME()'
  of Opcode:REOPEN
    return 'REOPEN()'
  of Opcode:RESETfile
    return 'RESET(file/view,position)'
  of Opcode:RESETkey
    return 'RESET(key)'
  of Opcode:ROLLBACKdrv
    return 'ROLLBACK(driver)'
  of Opcode:SEND
    return 'SEND()'
  of Opcode:SETCustomType
    return 'SETCUSTOMTYPE()'
  of Opcode:SET64
    return 'SET64()'
  of Opcode:SETfile
    return 'SET(file)'
  of Opcode:SETfilekey
    return 'SET(file,key)'
  of Opcode:SETfileptr
    return 'SET(file,pointer)'
  of Opcode:SETkey
    return 'SET(key)'
  of Opcode:SETkeykeyptr
    return 'SET(key,key,pointer)'
  of Opcode:SETkeykey
    return 'SET(key,key)'
  of Opcode:SETkeyptr
    return 'SET(key,ptr)'
  of Opcode:SHARE
    return 'SHARE()'
  of Opcode:SKIP
    return 'SKIP()'
  of Opcode:STREAM
    return 'STREAM()'
  of Opcode:UNLOCK
    return 'UNLOCK()'
  of Opcode:WATCH
    return 'WATCH()'
  of Opcode:NOMEMO
    return 'NOMEMO()'
  of Opcode:REGETfile
    return 'REGET(file)'
  of Opcode:REGETkey
    return 'REGET(key)'
  of Opcode:NULL
    return 'NULL()'
  of Opcode:SETNULL
    return 'SETNULL()'
  of Opcode:SETNONNULL
    return 'SETNONNULL()'
  of Opcode:SET_PROPERTY
    return 'SETPROPERTY()'
  of Opcode:GET_PROPERTY
    return 'GetProperty()'
  of Opcode:QUERY_KEY
    return 'QUERY_KEY()'
  of Opcode:QUERY_VIEW
    return 'QUERY_VIEW()'
  of Opcode:_BLOB_YIELD
    return 'BLOB_YIELD()'
  of Opcode:_BLOB_TAKE
    return 'BLOB_TAKE()'
  of Opcode:_BLOB_SIZE
    return 'BLOB_SIZE()'
  of Opcode:_BLOB_SETPROPERTY
    return 'BLOB_SETPROPERTY()'
  of Opcode:_BLOB_GetProperty
    return 'BLOB_GetProperty()'
  of Opcode:SETviewfields
    return 'SET(viewfields)'
  of Opcode:CLEARfile
    return 'CLEAR(file)'
  of Opcode:RESETviewf
    return 'RESET(view,file)'
  of Opcode:START_BUILD
    return 'START_BUILD()'
  of Opcode:KEY_SETPROPERTY
    return 'KEY_SETPROPERTY()'
  of Opcode:KEY_GetProperty
    return 'KEY_GetProperty'
  of Opcode:REGISTER
    return 'REGISTER()'
  of Opcode:DO_PROPERTY
    return 'DO_PROPERTY()'
  of Opcode:KEY_DOPROPERTY
    return 'KEY_DOPROPERTY()'
  of Opcode:BLOB_DOPROPERTY
    return 'BLOB_DOPROPERTY()'
  of Opcode:WHO_ARE_YOU
    return 'WHOAREYOU()'
  of Opcode:BULK_READ_ON
    return 'BULK_READ_ON()'
  of Opcode:BULK_READ_OFF
    return 'BULK_READ_OFF()'
  of Opcode:CONNECT
    return 'CONNECT()'
  of Opcode:EXCEEDS_RECS
    return 'EXCEEDS_RECS()'
  of Opcode:GETNULLS
    return 'GETNULLS()'
  of Opcode:SETNULLS
    return 'SETNULLS()'
  of Opcode:GETSTATE
    return 'GETSTATE()'
  of Opcode:RESTORESTATE
    return 'RESTORESTATE()'
  of Opcode:CALLBACK
    return 'CALLBACK()'
  of Opcode:FREESTATE
    return 'FREESTATE()'
  of Opcode:SQLCALLBACK
    return 'SQLCALLBACK()'
  of Opcode:DESTROYf
    return 'DESTROY(file)'
  of Opcode:STARTTRAN
    return 'STARTTRAN()'
  of Opcode:ENDTRAN
    return 'ENDTRAN()'
  of Opcode:FIXFORMAT
    return 'FIXFORMAT()'
  of Opcode:UNFIXFORMAT
    return 'UNFIXFORMAT()'
  of Opcode:SQL
    return 'SQL()'
  of Opcode:UPSERT
    return 'UPSERT()'
  of Opcode:VALIDATE
    return 'VALIDATE()'
  of Opcode:SET_DOTNET_PROPERTY
    return 'SET_DOTNET_PROPERTY()'
  of Opcode:GET_DOTNET_PROPERTY
    return 'GET_DOTNET_PROPERTY()'
  of Opcode:SET_DOTNET_KEY_PROPERTY
    return 'SET_DOTNET_KEY_PROPERTY()'
  of Opcode:GET_DOTNET_KEY_PROPERTY
    return 'GET_DOTNET_KEY_PROPERTY()'

  of Opcode:TOTFOPCODES
    return 'TOTFOPCODES()'
  else
    return 'unknown opcode'
  end

!---------------------------------------------------------------------------------
DriverBaseClass.InterpretType  Procedure(Byte pType)
  code
  case pType
  of ClaBYTE          !Equate(1) !                      /* 0x01 Signed 1 Byte Binary      */  x
    return 'BYTE'
  of ClaSHORT         !Equate(2) !                      /* 0x02 Signed 2 Byte Binary      */  x
    return 'SHORT'
  of ClaUSHORT        !Equate(3) !                      /* 0x03 Unsigned 2 Byte Binary    */
    return 'USHORT'
  of ClaDATE          !Equate(4) !                      /* 0x04 4 Byte Binary YYMD        */
    return 'DATE'
  of ClaTIME          !Equate(5) !                      /* 0x05 4 Byte Binary HMSH        */
    return 'TIME'
  of ClaLONG          !Equate(6) !                      /* 0x06 Signed 4 Byte Binary      */  x
    return 'LONG'
  of ClaULONG         !Equate(7) !                      /* 0x07 Unsigned 4 Byte Binary    */
    return 'ULONG'
  of ClaSREAL         !Equate(8) !                      /* 0x08 Signed 4 Byte Float       */
    return 'SREAL'
  of ClaREAL          !Equate(9) !                      /* 0x09 Signed 8 Byte Float       */ x
    return 'REAL'
  of ClaDECIMAL       !Equate(00Ah) !                   /* 0x0A Clarion Packed Decimal    */ x
    return 'DECIMAL'
  of ClaPDECIMAL      !Equate(00Bh) !                   /* 0x0B IBM Packed Decimal        */
    return 'PDECIMAL'
  of ClaSBYTE         !Equate(00Ch) !
    return 'SBYTE'
  of ClaBFLOAT4       !Equate(00Dh) !                   /* 0x0D Basic FLOAT 4 bytes       */
    return 'BFLOAT4'
  of ClaBFLOAT8       !Equate(00Eh) !                   /* 0x0E Basic FLOAT 8 bytes       */
    return 'BFLOAT8'
  of ClaANY           !Equate(00Fh)
    return 'ANY'
  of ClaSIGNED        !Equate(010h)
    return 'SIGNED'
  of ClaUNSIGNED      !Equate(011h)
    return 'UNSIGNED'
  of ClaSTRING        !Equate(012h) !                   /* 0x12 ASCII character sequence  */  x
    return 'STRING'
  of ClaCSTRING       !Equate(013h) !                   /* 0x13 C string (trailing null)  */
    return 'CSTRING'
  of ClaPSTRING       !Equate(014h) !                   /* 0x14 Pascal string (len byte)  */
    return 'PSTRING'
  of ClaMEMO          !Equate(015h) !                   /* 0x15 Memo                      */  x      ?
    return 'MEMO'
  of ClaGROUP         !Equate(016h) !                   /* 0x16 Clarion Group structure   */  x
    return 'GROUP'
  of ClaCLASS         !Equate(017h) !                   /* 0x17 Class type descriptor     */
    return 'CLASS'
  of ClaNOTHING       !Equate(018h) !                   Nothing                               x
    return 'NOTHING'
  of ClaQUEUE         !Equate(01Ah) !                   /* 0x1A Queue          */        ?
    return 'QUEUE'
  of ClaBLOB          !Equate(01Bh) !                   /* 0x1B Blob and TempStr          */        ?
    return 'BLOB'
  end
  Return pType

!-----------------------------------------------------------------------------------
! Returns a REAL containing the milliseconds elapsed since 1 January 1970 00:00:00 UTC up until now
DriverBaseClass.GetElapsedTimeUTC     PROCEDURE ()
UnixBaseDay         Equate(61730) ! = 1 jan 1970
msPerDay            real(24 * 60 * 60 * 1000)    ! don't make this an equate, needs to force the calc below to be real.
msPerHour           equate   (60 * 60 * 1000)
msPerMinute         equate        (60 * 1000)
msPerSecond         equate             (1000)
ans                 Real,Auto
tim                 Group(osSYSTEMTIME),Auto.

  code
  osGetSystemTime(tim)   ! returned time is for UTC not local time
  ans = (( date(tim.wMonth,tim.wDay,tim.wYear) - UnixBaseDay ) * msPerDay ) + (tim.wHour * msPerHour) + (tim.wMinute * msPerMinute) + (tim.wSecond * msPerSecond) + tim.wMilliseconds
  Return ans

!-----------------------------------------------------------------------------------
DriverBaseClass.SeedRandom Procedure()
seeded   byte,static
  code
  If seeded then return.
  seeded = true
  SeedRandom(bor(clock(),bshift(osGetCurrentProcessId(),24)))  ! process Id's are 16 bit, so we only get the low part of the process ID here
  Return

!-----------------------------------------------------------------
! https://en.wikipedia.org/wiki/Universally_unique_identifier#Version_4_(random)
! the biggest space, 122 bits of randomness. But binary, so may want to hex-encode for display
DriverBaseClass.GenerateUUIDv4  procedure()
x   long,Auto
ans string(16),Auto
  Code
  Loop x = 1 to size(ans)
    ans[x] = chr(random(0,255))
  End
  ans[7] = chr(40h + band(val(ans[7]),0Fh) )
  ans[9] = chr( 10000000b + band(val(ans[9]),111111b) )
  Return ans

!-----------------------------------------------------------------
! https://en.wikipedia.org/wiki/Universally_unique_identifier#Version_7_(timestamp,_counter_and_random)
! 56 bits of randomness, plus 18 bits of sequential randomness
! Binary, so may want to hex-encode for display. Will sort "sequentially" (as high bytes are time based.)
!
DriverBaseClass.GenerateUUIDv7  procedure()
inc   Long,static

x     Long,Auto
ms    Real,Auto
ms48  String(6),over(ms) ! only taking 48 bits
ans   String(16),Auto
  Code
  ms = self.GetElapsedTimeUTC()
  ans[1] = ms48[6]
  ans[2] = ms48[5]
  ans[3] = ms48[4]
  ans[4] = ms48[3]
  ans[5] = ms48[2]
  ans[6] = ms48[1]

  !next 2.2 bytes, 18 bits, are incrementing numbers, incrementing by random amounts
  inc += random(1,128)                             ! allows for at least 127 records per millisecond, with incrementing timestamp, in the same process.
  If inc > 3FFFFh then inc = random(1,128).
  ans[7] = chr(70h + band(bshift(inc,-14),0Fh ))   ! the version nibble (7) plus high 4 bits of the inc value
  ans[8] = chr(band(bshift(inc,-6),0FFh))          ! 8 bits of the inc value
  ans[9] = chr(10000000b + band(inc,111111b))      ! 2 variant bits (10) plus low 6 bits of the inc

  ! the remainder (56 bits) are purely random
  Loop x = 10 to size(ans)
    ans[x] = chr(random(0,255))
  End
  Return ans

!-----------------------------------------------------------------
! https://en.wikipedia.org/wiki/Universally_unique_identifier#Version_8_(custom)
! ~80 bits of randomness, but text based, not binary
DriverBaseClass.GenerateUUIDv8  procedure()
alphabet    String('0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ')
ans         string(16),Auto
x           long,Auto
  code
  loop x = 1 to size(ans)
    ans[x] = alphabet[Random(1,36)]
  end
  ! strictly speaking the 7th byte should have the high nibble set to 1000, (aka 8) but this breaks the Text nature of this UUID.
  !self.value[7] = chr(80h + band(val(self.value[7]),0Fh) )
  !self.value[9] = chr(10000000b + band(val(self.value[9]),111111b) )
  Return ans

!-----------------------------------------------------------------
! takes in a string of the form a.b.c and parses it into   DBVersionMajor . DBVersionMinor .  DBVersionBuild
DriverBaseClass._ParseVersionDb        PROCEDURE(String pVersion)
i  Long,Auto
  code
  self.DBVersionMajor = pVersion  ! will cunningly take digits from before the first .
  i = Instring('.',pVersion,1,1)
  self.DBVersionMinor = sub(pVersion,i+1,20)
  i = Instring('.',pVersion,1,i+1)
  self.DBVersionBuild = sub(pVersion,i+1,20)
  Return

!-----------------------------------------------------------------
! takes in a string of the form a.b.c and parses it into   ClientVersionMajor . ClientVersionMinor .  ClientVersionBuild
DriverBaseClass._ParseVersionClient        PROCEDURE(String pVersion)
i  Long,Auto
  code
  self.ClientVersionMajor = pVersion  ! will cunningly take digits from before the first .
  i = Instring('.',pVersion,1,1)
  self.ClientVersionMinor = sub(pVersion,i+1,20)
  i = Instring('.',pVersion,1,i+1)
  self.ClientVersionBuild = sub(pVersion,i+1,20)
  Return

!-----------------------------------------------------------------
! given a required minimum version number, check to see if the backend is better than this version.
! returns driver:ok or driver:notok
DriverBaseClass.CheckVersion        PROCEDURE(Long pMajorRqd, Long pMinorRqd, Long pBuildRqd)
  code
  If self.DBVersionMajor < pMajorRqd or |
    self.DBVersionMajor = pMajorRqd and self.DBVersionMinor < pMinorRqd or |
    self.DBVersionMajor = pMajorRqd and self.DBVersionMinor = pMinorRqd and self.DBVersionBuild < pBuildRqd
      self.SetError(FileSystemErr)
      self.SetFileError(OldDatabaseErr,'Old Database Version ' & self.DBVersionMajor & '.' & self.DBVersionMinor & '.' & self.DBVersionBuild & '. Needs ' & pMajorRqd & '.' & pMinorRqd & '.' & pBuildRqd & ' or later.')
      return driver:notOk
  End
  Return driver:ok

!-----------------------------------------------------------------
! The following methods are used to convert Clarion properties, + Clarion SQLProperties to SQL SELECT Clauses.
!-----------------------------------------------------------------
DriverBaseClass.BuildGroupBy              Procedure()
  code
  If self.groupBy &= null then Return.
  If self.ParseProperty(self.groupBy,driver:groupby,self.TokenStr) = driver:ok
    self.SetProp:GroupBy(self._ExpandExpression(self.TokenStr.GetValue()))
  End
  Return

!-----------------------------------------------------------------
DriverBaseClass.BuildHaving              Procedure()
  code
  If self.having &= null then Return.
  If self.groupBy &= null or self.groupBy = ''
    self.setProp:Having('')
    Return
  End
  If self.ParseProperty(self.having,driver:having,self.TokenStr) = driver:ok
    self.SetProp:Having(self._ExpandExpression(self.TokenStr.GetValue()))
  End
  Return

!-----------------------------------------------------------------
! starts the process by freeing the queue. This method is derived in the DriverClass and DriverViewClass
! to cater for the different approaches between FILE and VIEW.
DriverBaseClass.BuildOrderBy    Procedure()
  code
  Free(self.OrderQueue)
  self._OrderHasCalc = false
  Return

!-----------------------------------------------------------------
! The OrderBy property is an amalgamation of the prop:order and the prop:SqlOrder
DriverBaseClass.BuildOrderByProps    Procedure()
  code
  !self.trace('DriverBaseClass.BuildOrderByProps self.order=' & self.order)
  If not self.SqlOrder &= NULL and self.SqlOrder <> '' and Sub(self.SqlOrder,1,1) <> '+'     ! overrides prop:order
    If self.ParseProperty(self.sqlorder,driver:sqlorder,self.TokenStr) = driver:ok
      self.AddTokensToOrderBy(self.TokenStr)
    End
  ElsIf self.ParseProperty(self.order,driver:order,self.TokenStr) = driver:ok
    self.AddTokensToOrderBy(self.TokenStr)
    If self.ParseProperty(self.sqlorder,driver:sqlorder + driver:append,self.TokenStr) = driver:ok
      self.AddTokensToOrderBy(self.TokenStr)
    End
  End
  Return

!-----------------------------------------------------------------
! takes the subset and builds a CTE (WITH AS)
! Then the SET statement can compare the primary key fields against the CTE, thus generating a subset
DriverBaseClass.BuildSubsetCTE       PROCEDURE(StringTheory pCTE)
PrimaryFileSubSetDone     Byte
PrimarySelectDone         Byte
FoundSubsetOnPrimaryTable Byte
donefirst                 Byte
donecmd                   Byte
Distinct                  Cstring(12)
cmd                       Cstring(12)
obj                       &DriverFileClass
filter                    StringTheory
x                         Long,Auto
i                         Long,Auto
  Code
  Self.HasSubset = false
  If self.SubsetQueue &= NULL or Records(self.SubsetQueue) = 0
    Return
  End

  ! set the default SubSetFields to be the primary key fields.
  self.SubSetFields = ''
  Self.PrimeSubset()

  ! the goal of this loop is to build the CTE query.
  Loop i = 1 to Records(self.SubsetQueue)
    Get(self.SubsetQueue,i)
    obj &= self.SubsetQueue.File{prop:object}
    Case self.subsetqueue.Operation
    of Opcode:Subset
      obj.SubSetFields = self.SubsetQueue.Name[1]
      Loop x = 2 to 10
        If self.SubsetQueue.Name[x] = '' then break.
        obj.SubSetFields = obj.SubSetFields & ',' & self.SubsetQueue.Name[x]
      End
      If self.SubSetQueue.File &= self.SubsetPrimaryFile
        If self.SubsetInFields = '' then self.SubsetInFields = self.SubSetFields.
        FoundSubsetOnPrimaryTable = true
      End

    of Opcode:Except
      cmd = ' EXCEPT'
      do First
    of Opcode:Intersect
      If donefirst = false
        cmd = ' UNION'
      else
        cmd = ' INTERSECT'
      END
      do First
    of Opcode:Union
      cmd = Choose(donefirst = true,' UNION','')
      do First
    of Opcode:UnionAll
      cmd = Choose(donefirst = true,' UNION ALL','')
      do First
    End

    Case self.subsetqueue.Operation
    of  Opcode:Except orof Opcode:Intersect orof Opcode:Union orof Opcode:UnionAll
      If self.SubsetInFields = '' then self.SubsetInFields = self.SubSetFields.  ! this is the field list for the IN statement
      pCTE.Append(cmd & ' SELECT ' & obj.SubSetFields & ' FROM ' & self._sanitize(obj.FullPathName,driver:sqlTable))
      donecmd = true
      If not self.SubsetQueue.Filter  &= null
        obj._noAlias = true
        If obj.ParseProperty(self.SubsetQueue.Filter,driver:filter,obj.TokenStr) = driver:notok
          self.SetError(BadFilterErr)
          Return
        End
        filter.SetValue(obj._ExpandExpression(obj.TokenStr.GetValue()))
        obj._noAlias = false
        pCTE.Append(' WHERE ' & filter.GetValue())
      End
    End
  End
  If donecmd
    pCTE.Append(') ')
    Self.HasSubset = true
  End
  Return

first  routine
  If donefirst = false
    pCTE.SetValue('WITH subset(' & self.SubSetFields & ') AS (')
    If self.subsetqueue.Operation = Opcode:Except
      If FoundSubsetOnPrimaryTable = false then Distinct = 'DISTINCT '.
      pCTE.Append(' SELECT ' & Distinct & self.SubSetFields & ' FROM ' & self._sanitize(self.FullPathName,driver:sqlTable))
    End
  End
  donefirst = true

!-----------------------------------------------------------------
DriverBaseClass.BuildSubsetWhere       PROCEDURE(StringTheory pWhere, String pAlias)
matchlist   StringTheory
x           Long,Auto
  code
  If self.SubsetQueue &= NULL or Records(self.SubsetQueue) = 0 or Self.HasSubset = false
    Return
  End
  Matchlist.SetValue(self.SubsetInFields)
  Matchlist.split(',')
  MatchList.SetValue('')
  Loop x = 1 to Matchlist.Records()
    Matchlist.append(pAlias & Matchlist.Getline(x) & '=  ss.' & Matchlist.Getline(x),,' AND ')
  End
  If pWhere.Length()
    pWhere.SetValue('(' & pWhere.GetValue() & ') AND')
  end
  pWhere.Append(' EXISTS( SELECT 1 FROM subset ss WHERE ' & matchlist.GetValue() & ')')
  Return

!-----------------------------------------------------------------
! the prop has been tokenised, but that needs to now be expanded, and added to the OrderByQueue
! the context is already set, by the call to ParseProperty
DriverBaseClass.AddTokensToOrderBy  Procedure(StringTheory pTokenString)
token        string(6),Auto
nexttoken    string(6),Auto
tn           long
x            long,Auto
i            long
label        string(5)
ln           long
already      long
cansimplify  byte,Auto
  code
  If pTokenString.Length() = 0 then return.

  !self.trace('AddTokensToOrderBy tokenString=' & pTokenString.GetValue())
  ! there are some special cases to take care of.
  ! UPPER and LOWER are removed, and OrderBy.NoCase is set instead.
  x = 1
  Loop
    Clear(self.OrderQueue)
    token = pTokenString.Sub(x,5)
    If x+11 <= pTokenString.Length()
      nexttoken = pTokenString.Sub(x+6,6)
    else
      nexttoken = ''
    end
    cansimplify = false
    case nexttoken
    of ''
      cansimplify = true
    of token:desc
      self.OrderQueue.Direction = driver:Descending
      x += 6
      cansimplify = true
    of token:asc
      self.OrderQueue.Direction = driver:Ascending
      x += 6
      cansimplify = true
    of token:comma
      cansimplify = true
    of token:plus
    orof token:minus
    orof token:divide
    orof token:multiply
    orof token:mod
    orof token:power
    orof token:concat
      cansimplify = false
    end
    If token = token:comma
      x += 6
      cycle
    End
    tn = token[2 : 5]
    If cansimplify
      Case token[1]
      of token:label
        Get(self.LabelQueue,tn)
        If errorcode() = 0
          already = self._FillOrderFromLabel(self.LabelQueue.Label,false)
        End

      of token:function
        Get(self.FunctionQueue,tn)
        If Errorcode() = 0
          Case upper(self.FunctionQueue.Func)
          of 'UPPER' orof 'LOWER'
            If self.FunctionQueue.Parms[1] = token:label and len(self.FunctionQueue.Parms) = 6
              ln = self.FunctionQueue.Parms[2 : 5]
              Get(self.LabelQueue,ln)
              If errorcode() = 0
                already = self._FillOrderFromLabel(self.LabelQueue.Label,true)
              End
            End
          End
        End
      End
    End
    If self.OrderQueue.Clause = ''
      i = pTokenString.Instring(token:comma,1,x)
      if i = 0
        self.OrderQueue.Clause = self._ExpandExpression(pTokenString.slice(x))
        x = pTokenString.Length()
      else
        self.OrderQueue.Clause = self._ExpandExpression(pTokenString.slice(x,i-1))
        x = i + 6
      end
      self.OrderQueue.IsCalc = true
    End
    If already = 0
      If self.OrderQueue.Clause <> ''
        If self.OrderQueue.IsCalc then self._OrderHasCalc = true.
        Add(self.OrderQueue)
      End
    End
    x += 6
    if x >= pTokenString.length() then break.
  End
  Return

!-----------------------------------------------------------------
DriverBaseClass._FillOrderFromLabel              Procedure(String pLabel, Byte pCase)
  code
  return 0

!-----------------------------------------------------------------
! The Where property is an amalgamation of the prop:filter and the prop:SqlFilter
! After calling this The File class prepends the Key fields to the where, and the paging after it.
! The View class adds the Fixed values (as determined by the SET call) before this, and the paging after.
DriverBaseClass.BuildWhere              Procedure()
where   StringTheory
 code
  If self.SearchFilter
    If self.ParseProperty(self.SearchFilter,driver:searchfilter,self.TokenStr) = driver:ok
      where.SetValue(self._ExpandExpression(self.TokenStr.GetValue()))
    End
  End

  If (self.SqlFilter &= NULL or self.SqlFilter = '') and (self.Filter &= NULL or self.Filter = '')
    ! No filters in play, nothing to do.
    self.SetProp:Where(where.GetValue())
    Return
  End

  ! If prop:SQLFilter exists, and if it overrides prop:filter.
  If not self.SqlFilter &= NULL and self.SqlFilter <> ''
    If (sub(self.SQLFilter,1,1) <> '+') or (self.Filter &= NULL or self.Filter = '')
      ! yep. just handle prop:SqlFilter and get out.
      where.Append(self.sqlFilter,,' AND ')
      self.SetProp:Where(where.GetValue())
      Return
    End
  End

  ! Check for no prop:SqlFilter, but only prop:filter
  If (not self.Filter &= NULL and self.Filter <> '') and (self.SqlFilter &= NULL or self.SqlFilter = '')
    If self.ParseProperty(self.filter,driver:filter,self.TokenStr) = driver:ok
      where.Append(self._ExpandExpression(self.TokenStr.GetValue()),,' AND ')
    End
    self.SetProp:Where(where.GetValue())
    Return
  End

  ! so now we have both sqlfilter and filter, and they both need to be used
  If self.ParseProperty(self.filter,driver:filter,self.TokenStr) = driver:ok
    where.Append('(' & self._ExpandExpression(self.TokenStr.GetValue()) & ') AND (' & self.sqlfilter & ')')
  End
  self.SetProp:Where(where.GetValue())
  Return

!------------------------------------------------------------------------------------------------------------
! the prop:filter contains Claron code, Field names and Static values.
! This needs to be parsed so it can be handled or translated by the driver.
DriverBaseClass.ParseProperty             Procedure(String pProperty, Long pContext,StringTheory rTokenString)
cstr   cstring(size(pProperty)+1),Auto
  code
  If pProperty = '' then return driver:ok.
  cstr = pProperty
  Return self.ParseProperty(cstr,pContext,rTokenString)

!------------------------------------------------------------------------------------------------------------
! the (for example) prop:Filter contains Clarion code, Field names and Static values.
! This needs to be parsed so it can be handled or translated by the driver.
DriverBaseClass.ParseProperty             Procedure(*Cstring pProperty, Long pContext,StringTheory rTokenString)
x            Long,Auto
  code
  rTokenString.SetValue('')
  !self.trace('DriverBaseClass.ParseProperty ' & pProperty)
  self._ParseContext = pContext
  If pProperty = '' then Return driver:ok.
  self.SetError(NoError)
  If self.ConditionQueue &= null
    self.ConditionQueue &= New ConditionQueueType
    self.ValueQueue &= New ValueQueueType
    self.LabelQueue &= New LabelQueueType
    self.FunctionQueue &= New FunctionQueueType
    self.ExpressionQueue &= New ExpressionQueueType
  ElsIf band(pContext,driver:append) = 0
    Free(self.ConditionQueue)
    Free(self.ValueQueue)
    Free(self.LabelQueue)
    Free(self.FunctionQueue)
    Free(self.ExpressionQueue)
  End

  rTokenString.SetValue(self._Tokenize(pProperty,pContext))

  If ErrorCode() then Return driver:notok.

  Loop x = 1 to Records(self.ExpressionQueue)
    get(self.ExpressionQueue,x)
    self.tempstr.SetValue(self.ExpressionQueue.Expression)
    If self.OperatorsToFunction(self.tempstr)
      Get(self.ExpressionQueue,x)
      self.ExpressionQueue.Expression = self.tempstr.GetValue()
      Put(self.ExpressionQueue)
    Else
      If Errorcode() then Return driver:notok.
    End
  End

  ! operator translations work directly on the token string.
  self.OperatorsToFunction(rTokenString)
  If Errorcode() then Return driver:notok.

  If pContext = driver:order or pContext = driver:order + driver:append
     ! clarion order is + field , -field
     ! sql order is Field ASC, Field DESC
     self.TranslateOrder(rTokenString)
  End
  !self._ViewTokens()
  Return driver:ok

!-----------------------------------------------------------------
DriverBaseClass._ViewTokens  Procedure()
x  long,Auto
  code
  self.trace('VIEW TOKENS:')
  Loop x = 1 to records(self.ConditionQueue)
    get(self.ConditionQueue,x)
    self.trace('  Condition : ' & x & ' ' & self.ConditionQueue.Condition)
  End

  Loop x = 1 to records(self.ValueQueue)
    get(self.ValueQueue,x)
    self.trace('  Value     : ' & x & '[parm=' & self.ValueQueue.parm &  ']' & ' ' & self.ValueQueue.Value)
  End

  Loop x = 1 to records(self.LabelQueue)
    get(self.LabelQueue,x)
    self.trace('  Label     : ' & x & ' ' & self.LabelQueue.Label & choose(self.LabelQueue.as = 0 , '' , '  [AS]'))
  End

  Loop x = 1 to records(self.FunctionQueue)
    get(self.FunctionQueue,x)
    self.trace('  Function  : ' & x & ' ' & self.FunctionQueue.Func & ' (' & self.FunctionQueue.Parms & ')')
  End

  Loop x = 1 to records(self.ExpressionQueue)
    get(self.ExpressionQueue,x)
    If self.ExpressionQueue.brackets
      self.trace('  Expression:' & x & ' (' & self.ExpressionQueue.Expression & ')')
    Else
      self.trace('  Expression:' & x & ' ' & self.ExpressionQueue.Expression)
    End
  End
  Return

!-----------------------------------------------------------------
! need to take in a string, and split that string into it's various parts.
! all "text" parts are replaced with a token.
! the tokens are placed in the various token queues.
! the tokenized string is returned.
! ----
!  extract tokens, and place in token queue.
!  ?1 = ?2 and ?3 = ?4 and (?5 = ?6 or ?7 = ?8)
!  conditional operators are > < = <= =< >= => <> ~= and or not ~ xor ~> not > not <
!  logical operators are  + - / * ^ ( ) %
!  single quotes must match.

! extract every quoted part, and replace with an    token:value & 0000. Push that into the quote queue
! extract expressions and replace with              token:expression & 0000. Push that to expression queue
! extract conditional operators and replace with    token:condition & 0000. Push that to condition queue
! extract each label and replace that with          token:label & 0000. Push that into the variable queue
! extract numbers and replace with                  token:value & 0000. Push that to value queue
! extract function calls and replace with           token:function & 0000. Push that to function queue
! extract math and string operators and replace with token:operator & 0000. Push that to Operator queue
DriverBaseClass._Tokenize   Procedure(String pStr, Long pContext)
x            long,Auto
y            long,Auto
z            long
a            long
p            long
as           long
len          long,Auto
inquote      byte
tokenString  cString(4096)
tempstring   cstring(4096)
  code
  !self.trace('  Tokenize ' & pStr)
  x = 1
  len = len(pStr)
  loop while x <= len
    ! at this point find the start of the next thing
    Case pStr[x]
    of ''''                                                                   ! next block is a quoted section.
      do PushQuote
      If ErrorCode() then Return ''.
      Cycle

    of '('
      do PushExpression
      If ErrorCode() then Return ''.
      Cycle

    of '+'
      !If Band(self._ParseContext,driver:append) and x = 1    ! ignore first + if the context is set to append
      If Band(pContext,driver:append) and x = 1    ! ignore first + if the context is set to append
        x += 1
        Cycle
      Else
        do PushOperator
        Cycle
      End
    of ','
      do PushOperator
      Cycle
    of '-' orof '/' orof '*' orof '%' orof '^' orof '&'     ! term separators
      do PushOperator
      Cycle

    of '=' orof '<' orof '>' orof '~' orof '!'                                ! next block is conditional operators
      do PushConditionOperator
      Cycle

    of '0' to '9'                                                             ! next block is a number.
      do PushValue
      If ErrorCode() then Return ''.
      Cycle

    of 'a' orof 'A'
      If len < x + 1

      ElsIf len = x + 1
        case upper(pStr[x : x + 2])
        of 'AS'
          do PushOperatorAs
          Cycle
        End

      ElsIf len = x + 2
        case upper(pStr[x : x + 2])
        of 'AS '
          do PushOperatorAs
          Cycle
        of 'ASC'
          do PushOperatorAsc
          Cycle
        End
      Else
        case upper(pStr[x : x + 2])
        of 'AS '
          do PushOperatorAs
          Cycle
        End
        case upper(pStr[x : x + 3])
        of 'AND ' orof 'AND('
          do PushConditionAnd
          Cycle
        of 'ASC ' orof 'ASC,'
          do PushOperatorAsc
          Cycle
        end
      End
    of 'o' orof 'O'
      If len >= x + 2
        Case upper(pStr[x : x + 2])
        Of 'OR ' orof 'OR('
          do PushConditionOr
          Cycle
        End
      End
    of 'n' orof 'N'
      If len >= x + 3
        case upper(pStr[x : x + 3])
        of 'NOT ' orof 'NOT(' orof 'NOT=' orof  'NOT<' orof 'NOT>'
          do PushConditionNot
          Cycle
        end
      End
    of 'x' orof 'X'
      If len >= x + 3
        case upper(pStr[x : x + 3])
        of 'XOR ' orof 'XOR('
          do PushConditionXor
          Cycle
        end
      End
    of 'd' orof 'D'
      If len < x+3
      ElsIf len = x+3
        case upper(pStr[x : x + 3])
        of 'DESC'
          do PushOperatorDesc
          Cycle
        end
      Else
        case upper(pStr[x : x + 4])
        of 'DESC ' orof 'DESC,'
          do PushOperatorDesc
          Cycle
        end
      End
    End
    case pStr[x]
    of 'A' to 'Z' orof 'a' to 'z' orof '_'
      If x > as+3 then as = 0.
      do PushLabel
      If ErrorCode() then Return ''.
      Cycle
    of ' '
      x += 1
      Cycle
    end
    x += 1
  end
  Return tokenString

PushQuote routine
  y = self._FindMatching(pStr,x)
  If y
    self.ValueQueue.Value = pStr[x : y] & '<0>'
    If pContext = driver:searchfilter
      self.ValueQueue.Parm = 1
    Else
      self.ValueQueue.Parm = 0
    End
    Add(self.ValueQueue)
    tokenString = tokenString & token:value & format(records(self.ValueQueue),@n04) & ' '
    x = y + 1  ! move to first char after the closing quote
  else
    self.SetError(FileSystemErr)
    self.SetFileError(BadFilterErr,'BadFilterErr: No closing quote to position ' & x)
    x = len(pStr) + 1
  end

PushExpression  Routine
  y = self._FindMatching(pStr,x)
  If y
    tempString = pStr[x+1 : y-1] & '<0>'
    self.ExpressionQueue.Expression = self._Tokenize(tempstring,pContext)
    If Errorcode() then exit.
    self.ExpressionQueue.brackets = true
    Add(self.ExpressionQueue)
    tokenString = tokenString & token:expression & format(records(self.ExpressionQueue),@n04) & ' '
    x = y + 1  ! move to first char after the closing )
  Else
    self.SetError(FileSystemErr)
    self.SetFileError(BadFilterErr,'BadFilterErr: No closing ) to position ' & x)
    x = len(pStr) + 1
  End

PushOperator   routine
  case pStr[x]
  of '+'
    tokenString = tokenString & token:plus
  of '-'
    tokenString = tokenString & token:minus
  of '/'
    tokenString = tokenString & token:divide
  of '*'
    tokenString = tokenString & token:multiply
  of '%'
    tokenString = tokenString & token:mod
  of ','
    tokenString = tokenString & token:comma
  of '^'
    tokenString = tokenString & token:power
  of '&'
    tokenString = tokenString & token:concat
  end
  x += 1

PushOperatorAsc    routine
  tokenString = tokenString & token:asc
  x += 3

PushOperatorAs    routine
  tokenString = tokenString & token:as
  x += 2

PushOperatorDesc   routine
  tokenString = tokenString & token:desc
  x += 4

PushConditionOperator  routine
  y = x + 1
  self.ConditionQueue.Condition =  pStr[x]
  Loop
    Case pStr[y]
    of ' '
      y += 1 ! whitespace doesn't terminate a condition. < = is as legal as <=
      cycle
    of '=' orof '<' orof '>'
      self.ConditionQueue.Condition = self.ConditionQueue.Condition & pStr[y]
      y += 1
      break
    else
      break
    End
  End
  do PushCondition
  x = y

PushValue  routine
  self.ValueQueue.Value = ''
  y = x
  loop
    If y > len(pStr) then break.
    Case pStr[y]
    Of '0' to '9' orof '.' orof 'e' orof 'E'
      self.ValueQueue.Value = self.ValueQueue.Value & pStr[y]
      y += 1
      Cycle
    Of 'h' orof 'H'
      self.ValueQueue.Value = self._HexToLong(self.ValueQueue.Value)
      y += 1
      Break
    Of 'b' orof 'B'
      self.ValueQueue.Value = self._BinToLong(self.ValueQueue.Value)
      y += 1
      Break
    of 'a' to 'z' OROF 'A' to 'Z'
      self.SetError(FileSystemErr)
      self.SetFileError(BadFilterErr,'BadFilterErr: Invalid number at ' & x)
      Exit
    Else
      Break
    End
  End
  self.ValueQueue.Parm = 0
  Add(self.ValueQueue)
  tokenString = tokenString & token:value & format(records(self.ValueQueue),@n04) & ' '
  x = y

PushCondition  routine
  ! Clarion allows some forms of conditional operators that are not SQL standard. For simplicity
  ! this is as good a time as any to translate them into their standard form
  case self.ConditionQueue.Condition
  of '~'
  orof '!'
    self.ConditionQueue.Condition = 'NOT'
  of '~='
  orof '!='
  orof '=~'
  orof '=!'
    self.ConditionQueue.Condition = '<>'
  of '=<'
  orof '~>'
  orof '!>'
    self.ConditionQueue.Condition = '<='
  of '=>'
  orof '~<'
  orof '!<'
    self.ConditionQueue.Condition = '>='
  End
  Add(self.ConditionQueue)
  tokenString = tokenString & token:condition & format(records(self.ConditionQueue),@n04) & ' '

PushConditionAnd  routine
  self.ConditionQueue.Condition =  'AND'
  do PushCondition
  x += 3

PushConditionOr  routine
  self.ConditionQueue.Condition =  'OR'
  do PushCondition
  x += 2

PushConditionNot  routine
  self.ConditionQueue.Condition =  'NOT'
  y = x + 3
  ! Clarion allows some forms of conditional operators that are not SQL standard. For simplicity
  ! this is as good a time as any to translate them into their standard form
  loop
    Case pStr[y]
    of ' ' ! whitespace doesn't terminate a NOT. NOT =  is legal
      y += 1
      cycle
    of '<'                                                 !NOT<
      self.ConditionQueue.Condition = '>='
      y += 1
      break
    of '='
      self.ConditionQueue.Condition = '<>'                 !NOT=
      y += 1
      break
    of '>'                                                 !NOT>
      self.ConditionQueue.Condition = '<='
      y += 1
      break
    else
      break
    end
  End
  do PushCondition
  x = y ! y is the first character not part of the NOT statement

PushConditionXor  routine
 !!!todo Condition XOR maybe?
 ! there's no matching clause in SQL, so it would have to be expanded into [ x OR y and not (x AND y) ]

PushLabel  routine
! might be a simple Label, which terminates with a space and not a (
! or a function, which contains a parameter list surrounded by ( )
  self.LabelQueue.Label = ''
  y = x
  Loop
    If y > len(pStr) then break.
    Case pStr[y]
    Of '('                              ! name has ended this is a function call.
      do PushFunction                   ! takes ExpressionQueue.Expression so far, and carries on.
      exit
    Of ' ' ! name has ended, if next non-white-space is a ( then this is a function call.
      loop z = y+1 to len(pStr)
        If pStr[z] = ' ' then cycle.
        If pStr[z] ='('                 ! name has ended this is a function call.
          y = z
          do PushFunction               ! takes ExpressionQueue.Expression so far, and carries on.
          exit
        End
        break                           ! y is the char after the Label name
      End
      Break
      ! it is legal to end the expresion with a name, so carry on from here if the loop ended either way
    Of '+' orof '-' orof '/' orof '*' orof '%' orof ')' orof '>' orof '<<' orof '=' orof '~' orof ','
      break                             ! y is the char after the Label name

    Else                                !of 'A' to 'Z' orof 'a' to 'z' orof '0' to '9' orof '_' orof ':' orof '.' also any non latin alphabets
      self.LabelQueue.Label = self.LabelQueue.Label &  pStr[y]
      y += 1
      Cycle
    End
  End
  Add(self.LabelQueue)
  tokenString = tokenString & token:label & format(records(self.LabelQueue),@n04) & ' '
  x = y

PushFunction  routine
! take over from PushLabel
  self.FunctionQueue.Func = self.LabelQueue.Label
  self.FunctionQueue.Parms = ''
  !y points to the opening bracket. Find the matching, closing, bracket.
  z = self._FindMatching(pStr,y)
  If z
    add(self.FunctionQueue) ! need to write the Function name away
    p = Pointer(self.FunctionQueue)
    tempstring = self._Tokenize(pStr[ y+1 : z-1],pContext)
    If Errorcode() then Exit.
    Get(self.FunctionQueue,p)
    self.FunctionQueue.Parms = tempstring
    Put(self.FunctionQueue)
    tokenString = tokenString & token:function & format(p,@n04) & ' '
    x = z + 1
  else
    self.SetError(FileSystemErr)
    self.SetFileError(BadFilterErr,'BadFilterErr: No matching bracket at position ' & y & ' in expression ' & pStr)
  End

!-----------------------------------------------------------------
! works on the incoming pStr, and alters it.
! if it finds the passed token, then a new expression is created and the pStr is updated to that expression.
DriverBaseClass._Functionize             Procedure(StringTheory pStr,String pToken, String pFunction)
i      long,Auto
j      long,Auto
chain  long,Auto
ans    long
  code
  case pFunction  ! varadic functions can take multiple parameters
  of 'CONCAT'
    ! so to start we have the operator in pToken. The previous token is the first parameter. i points to the operator token
    ! first thing to see if if there's a "chain" of concatenated parameters.
    loop
      i = pStr.Instring(pToken,1,1)
      If i = 0 then break.
      chain = 0
      j = i
      Loop
        If j + 12 > pStr.Length() then break.
        If pStr.Sub(j+12,5) = pToken
          chain += 1
          j += 12
          Cycle
        End
        Break
      End
      j = i

      ! turn the two sides of the chain of operators into a parameter list
      self.ExpressionQueue.Expression = pStr.Sub(j-6,6) & token:comma & pStr.Sub(j+6,6)
      j += 6
      loop chain times
        j += 12
        self.ExpressionQueue.Expression = self.ExpressionQueue.Expression & token:comma & pStr.Sub(j,6)
      end
      self.ExpressionQueue.brackets = false
      Add(self.ExpressionQueue)

      ! now add a function which takes that expression list
      self.FunctionQueue.Func = clip(pFunction)
      self.FunctionQueue.Parms = token:expression & format(records(self.ExpressionQueue),'@n04')
      Add(self.FunctionQueue)

      ! now replace the whole chain into a call to the function
      pStr.ReplaceSlice(i-6, i+10 + chain * 12, token:function & format(records(self.FunctionQueue),'@n04'))
      ans = true
    end
  Else
    Loop
      i = pStr.Instring(pToken,1,1)
      If i = 0 then break.
      ! turn the two sides of the operator into a parameter list
      self.ExpressionQueue.Expression = pStr.Sub(i-6,6) & token:comma & pStr.Sub(i+6,6)  ! token before , token after
      self.ExpressionQueue.brackets = false
      Add(self.ExpressionQueue)
      ! now add a function which takes that expression list
      self.FunctionQueue.Func = clip(pFunction)
      self.FunctionQueue.Parms = token:expression & format(records(self.ExpressionQueue),'@n04')
      Add(self.FunctionQueue)
      ! now replace the original operator, and two sides into a call to the function
      pStr.ReplaceSlice(i-6, i+10, token:function & format(records(self.FunctionQueue),'@n04'))
      ans = true
    End
  End
  Return ans

!-----------------------------------------------------------------
! The Start points to a start char.
! The method returns the position of the matching end char.
! works for ( and for '
DriverBaseClass._FindMatching  Procedure(*String pStr, Long pStart)
closingchar string(1),Auto
inquote     byte
y           long,Auto
nest        long
  Code
  y = pStart
  case pStr[pStart]
  of ''''
    closingchar = ''''
    inquote = true
  of '('
    closingchar = ')'
  End
  y += 1
  Loop
    If y > len(pStr) then return 0. ! error, no closing char
    If inquote
      Case pStr[y]
      Of ''''
        if len(pStr) > y and pStr[y+1] = '''' ! this is just a inline quote char, not the end of the quote, so keep going.
          y += 2
          cycle
        else
          If closingchar = '''' then return y.
          inquote = false
          y += 1
          cycle
        end
      Else
        y += 1
        cycle
      End
    Else
      Case pStr[y]
      of ''''
        y += 1
        inquote = true
        cycle
      of pStr[pStart]
        nest += 1
      of closingchar
        if nest = 0 then break.
        nest -= 1
      End
      y += 1
    End
  End
  Return y

!-----------------------------------------------------------------
! _ExpandExpression can read any records from any of the queues. So if incoming pTokenString
! is a value from one of the queues, then it needs to be preserved and restored before calling this method.
DriverBaseClass._ExpandExpression      Procedure(String pTokenString, <String pPrefix>,<String pSuffix>)
x      long,auto
i      long,auto
ans    cstring(4096)
ts     cstring(4096),auto
  code
  ts = pTokenString
  If pTokenString = '' then return ''.
  x = 1
  Loop
    If x >= len(pTokenString)
      If not omitted(pSuffix)
        i = len(ans)
        If ans[i] = ''''
          ans = Sub(ans,1,len(ans)-1) & clip(pSuffix) & ''''
        Elsif Numeric(ans)
          ans = '''' & ans & clip(pSuffix) & ''''
        End
      End
      Break
    End
    ans = ans & self._ExpandToken(pTokenString,x)
    If x = 1 and not omitted(pPrefix) and pPrefix <> ''
      If ans[1] = ''''
        ans = '''' & clip(pPrefix) & sub(ans,2,len(ans))
      Elsif Numeric(ans)
        ans = '''' & clip(pPrefix) & ans & ''''
      End
    End
    x += 6
  End
  Return Ans

!-----------------------------------------------------------------
! pTokenPos does not have to be incremented, unless multiple tokens are processed.
! This will alter the current record for any of the token queues, so the caller needs to assume the queue values have changed.
DriverBaseClass._ExpandToken           Procedure(String pTokenString,*Long pTokenPos)
t          Long ,Auto
token      String(6)
fc         Like(self.FunctionQueue.Func)
fp         Like(self.FunctionQueue.Parms)
LabelType  Byte
Label      Cstring(4096)
  code
  token = sub(pTokenString,pTokenpos,6)
  t = sub(token,2,4)
  case Token[1]
  of token:value
    Get(self.ValueQueue,t)
    If self.ValueQueue.Parm
      self._ParameterCount += 1
      If sub(self.ValueQueue.Value,1,1) = ''''
        self._SetParameterString(self._ParameterCount,sub(self.ValueQueue.Value,2,len(clip(self.ValueQueue.Value))-2))
      else
        self._SetParameterString(self._ParameterCount,self.ValueQueue.Value)
      end
      Return self._genparm(self._ParameterCount)
    End
    Return self.ValueQueue.Value

  of token:expression
    Get(self.ExpressionQueue,t)
    If self.ExpressionQueue.brackets
      Return '(' & self._ExpandExpression(self.ExpressionQueue.Expression) & ')'
    Else
      Return self._ExpandExpression(self.ExpressionQueue.Expression)
    End

  of token:condition
    Get(self.ConditionQueue,t)
    Return ' ' & self.TranslateCondition(self.ConditionQueue.Condition) & ' ' ! dont remove ' ' - neceessary for OR AND etc

  of token:label
    Get(self.LabelQueue,t)
    Label = self.TranslateLabel(self.LabelQueue.Label,LabelType)
    Return Label

  of token:function
    Get(self.FunctionQueue,t)
    fc = self.FunctionQueue.Func                      ! cannot pass self.FunctionQueue.Func into _ExpandExpression because it is passed by pointer,
    fp = self.FunctionQueue.Parms                     ! and the string in self.FunctionQueue.Expression could be changed along the way.
    Return self.TranslateFunction(fc,fp,pTokenString,pTokenPos)

  of token:operator
    case token
    of token:plus
      return ' + '
    of token:minus
      return ' - '
    of token:divide
      return ' / '
    of token:multiply
      return ' * '
    of token:mod
      return self.TranslateOperatorMod()
    of token:comma
      return ','
    of token:power
      return self.TranslateOperatorPower()
    of token:concat
      return self.TranslateOperatorConcat()
    of token:asc
      return ' ASC'
    of token:desc
      return ' DESC'
    of token:as
      return ' AS '
    end
  End
  self.trace('ERROR: Token Not Found. ' & token)
  !self._viewtokens()
  Return ''

!-----------------------------------------------------------------
!!!todo - optimize filter expression Date(DateTime) = n where only the Date part of the DateTime is being considered. This could be changed to avoid an in-row function.
DriverBaseClass._Optimize                Procedure(String pFunction,String pExpression)
  code
  !self.trace('_Optimize ' & pFunction & ' eval=' &  Evaluate(pExpression) & ' expr=' & pExpression)
  case upper(pFunction)
  of 'UPPER'
    If ''''& Evaluate(pExpression) & '''' = pExpression
      pExpression = Upper(pExpression)
      return pExpression
    End
  of 'LOWER'
    If ''''& Evaluate(pExpression) & '''' = pExpression
      pExpression = lower(pExpression)
      return pExpression
    End
  End
  Return clip(pFunction) & '(' & clip(pExpression) & ')'

!-----------------------------------------------------------------
! clarion order is: + field , -field
! sql order is    : Field ASC, Field DESC
DriverBaseClass.TranslateOrder  Procedure(StringTheory pStr)
newstr     cstring(1024)
t1         cString(7),Auto
t2         cString(7),Auto
x          long ,Auto
start      long ,Auto
Clause     cstring(255),Auto
  code
  x = 1
  start = 1
  Loop                                      ! loop through each clause
    x = pStr.Instring(token:comma,1,x)
    If x
      clause = pStr.Sub(start,x-1)
      start = x + 6
    Else
      clause = pStr.Slice(start)
    End
    Case len(clause)
    of 0
      break
    of 1 to 12                   ! only single tokens, or in some case double tokens need to be handled.
      t1 = sub(clause,1,6)
      t2 = sub(clause,7,6)
      If (t1 = token:minus or t1 = token:plus) and (t2[1] = token:label or t2[1] = token:function or t2[1] = token:expression)    ! if t1 is + or -, and t2 is a label
        Case t1
        of token:minus
          clause = t2 & token:desc
        of token:plus
          clause = t2 & token:asc
        End
      ElsIf t1[1] = token:label
        If t2 <> token:desc and t2 <> token:asc
          clause = t1 !& token:asc & t2           ! t2 is either blank, or this order is likely invalid. Not aware of anything that can legally follow a label in a 2 token clause.
        End
      Else
        ! leave Clause as is
      End
    Else
      ! leave Clause as is
    End
    If newstr
      newstr = newStr & token:comma & clause
    Else
      newstr = clause
    End
    If x = 0 then break.
    x += 6
  End
  pStr.SetValue(newStr)
  Return

!-----------------------------------------------------------------
! The syntax for EXPLAINing varies a lot between different servers.
! must include a trailing space
!!! DERIVE if necessary
DriverBaseClass.ExplainStart      Procedure()
  Code
  Return 'EXPLAIN '

!-----------------------------------------------------------------
! Some servers treat EXPLAIN as a command, turned on and off. If your database is one of these
! then include the turn-off part here.
!!! DERIVE if necessary
DriverBaseClass.ExplainEnd        Procedure()
  Code
  Return ''

!-----------------------------------------------------------------
!!! DERIVE if necessary
DriverBaseClass.TranslateCondition Procedure(*cstring pCondition)
  code
  Return pCondition

!-----------------------------------------------------------------
!!! DERIVE
! This implementation will likely work, but will likely be slow. See specific database syntax for more performant case insensitive matching.
DriverBaseClass.TranslateNoCase    Procedure(*CString pExpr,*CString pColumn)
  code
  return ' UPPER( ' & self._ExpandExpression(pColumn) & ') LIKE UPPER(' & '''%' & self._ExpandExpression(pExpr) & '%'')'

!-----------------------------------------------------------------
! potentially converts a operator token (^, &, %) into a function.
! Derived classes should  decide which of these are in play, and which to ignore.
! For example many databases ignore CONCAT and use || instead.
! Most databases ignore MOD and use % instead. (Some support both).
! pToken is one of the token:equates
! pFunction is the name of the function (which can get translated later on)
! return true if a translation occured
!!! DERIVE if necessary
DriverBaseClass.OperatorsToFunction  Procedure(StringTheory pStr)
ans  long
  code
  ans += self._Functionize(pStr,token:power,'POWER')     ! pretty much all use POWER
  ans += self._Functionize(pStr,token:concat,'CONCAT')   ! CONCAT widly supported. Treats null as blank string
  !ans += self._Functionize(pStr,token:mod,'MOD')        ! Most dont need MOD
  Return ans

!-----------------------------------------------------------------
! commands translated include INSTRING, SUB, UPPER, LOWER, MATCH, CLIP, CHOOSE, INLIST, NULL, SQRT
!-----------------------------------------------------------------
! pTokenPos does not need to be incremented here, unless other tokens are consumed
!!! DERIVE if necessary
DriverBaseClass.TranslateFunction  Procedure(*Cstring pFunc, *CString pParms,String pTokenString,*Long pTokenPos)
ExParms   cstring(256),dim(25)
Parms     like(self.ExpressionQueue.Expression)
x         Long
ex        Long
numParms  Long

  code
  do ExpandParms
  case lower(self.FunctionQueue.func)
  of 'beginswith'   ! BeginsWith(substring,string)                               => string LIKE 'substring%'
    return self.TranslateBeginsWith(pFunc,pParms,pTokenString,pTokenPos,ExParms,NumParms)

  of 'chr'     ! CHR(expression)
    return self.TranslateChr(pFunc,pParms,pTokenString,pTokenPos,ExParms,NumParms)

  of 'clip'     ! CLIP(expression)                                              => RTRIM(expression)
    return self.TranslateClip(pFunc,pParms,pTokenString,pTokenPos,ExParms,NumParms)

  of 'date'     !
    return self.TranslateDate(pFunc,pParms,pTokenString,pTokenPos,ExParms,NumParms)

  of 'day'      ! DAY(date)                                                     => DAY(date)
    return self.TranslateDay(pFunc,pParms,pTokenString,pTokenPos,ExParms,NumParms)

  of 'endswith'   ! EndsWith(substring,string)                                  => string LIKE '%substring'
    return self.TranslateEndsWith(pFunc,pParms,pTokenString,pTokenPos,ExParms,NumParms)

  of 'inlist'   ! INLIST(searchstring,liststring,liststring [,liststring...])   => searchstring IN (liststring1,...)
    return self.TranslateInList(pFunc,pParms,pTokenString,pTokenPos,ExParms,NumParms)

  of 'inrange'  ! INRANGE(expression,low,high)                                  => expression BETWEEN low AND high
    return self.TranslateInRange(pFunc,pParms,pTokenString,pTokenPos,ExParms,NumParms)

  of 'instring' ! INSTRING(substring,string [,step] [,start])                   => string LIKE '%substring%'
    return self.TranslateInstring(pFunc,pParms,pTokenString,pTokenPos,ExParms,NumParms)

  of 'int'      ! INT(expression)                                               => FLOOR(expression)
    return self.TranslateInt(pFunc,pParms,pTokenString,pTokenPos,ExParms,NumParms)

  of 'match'    ! MATCH( first, second [, mode ] )                              => LIKE '%a%' ; SOUNDEX
    return self.TranslateMatch(pFunc,pParms,pTokenString,pTokenPos,ExParms,NumParms)

  of 'month'    ! MONTH(date)                                                   => MONTH(date)
    return self.TranslateMonth(pFunc,pParms,pTokenString,pTokenPos,ExParms,NumParms)

  of 'null'     ! NULL(field) = 1                                               => field IS NULL
    return self.TranslateNull(pFunc,pParms,pTokenString,pTokenPos,ExParms,NumParms)

  of 'search'    ! SEARCH(expression)                                         => MATCH expr
    return self.TranslateSearchX(pFunc,pParms,pTokenString,pTokenPos,ExParms,NumParms)

  of 'sqrt'     ! SQRT(n)
    return self.TranslateSqrt(pFunc,pParms,pTokenString,pTokenPos,ExParms,NumParms)

  of 'sub'      ! SUB(string,position,length)                                   => SUBSTRING(string,start,length)
    return self.TranslateSub(pFunc,pParms,pTokenString,pTokenPos,ExParms,NumParms)

  of 'sql'
    !!!todo add support for SQL function in filters etc.

  of 'year'     ! YEAR(date)                                                    => YEAR(date)
    return self.TranslateYear(pFunc,pParms,pTokenString,pTokenPos,ExParms,NumParms)

  End
  ! Everything else is assumed to be a legal SQL function an is passed through.
  ! Clarion=SQL:  ABS, SQRT, UPPER, LOWER, ROUND
  ! SQL only   :  POWER, CONCAT, TRIM
  Return pFunc & '(' & self._ExpandExpression(pParms) & ')'

ExpandParms  routine
  If len(pParms) < 1 then exit.
  If pParms[1] = 'E'
    ex = sub(pParms,2,4)
    get(self.ExpressionQueue,ex)
    Parms = self.ExpressionQueue.Expression
  Else
    Parms = pParms
  End
  x = 1
  NumParms = 0
  Loop
    If x >= len(Parms) then break.
    If NumParms > maximum(ExParms,1) then break.
    ex = instring(token:comma,parms,1,x)
    If ex = 0
      NumParms += 1
      ExParms[NumParms] = sub(Parms,x,len(Parms))
      break
    End
    NumParms += 1
    ExParms[NumParms] = Parms[x : ex-1]
    x = ex + 6
  End

!-----------------------------------------------------------------
DriverBaseClass.TranslateBeginsWith  Procedure(*Cstring pFunc, *CString pParms,string pTokenString,*Long pTokenPos,*Cstring[] pExParm,Long pNumParms)
  Code
  Return self._ExpandExpression(pExParm[2]) & ' LIKE ' & self._ExpandExpression(pExParm[1],'','%')

!-----------------------------------------------------------------
! !!!Derive for some databases. CHR (Postgres/Oracle) , ASCII_CHAR (Firebird)
DriverBaseClass.TranslateChr        Procedure(*Cstring pFunc, *CString pParms,string pTokenString,*Long pTokenPos,*Cstring[] pExParm,Long pNumParms)
  Code
  Return 'CHAR(' & self._ExpandExpression(pParms) & ')'

!-----------------------------------------------------------------
DriverBaseClass.TranslateClip        Procedure(*Cstring pFunc, *CString pParms,string pTokenString,*Long pTokenPos,*Cstring[] pExParm,Long pNumParms)
  Code
  Return 'RTRIM(' & self._ExpandExpression(pParms) & ')'

!-----------------------------------------------------------------
! The DATE function is handled differently in different databases
! the DATE function takes 3 parameters, the month, day and year.
!!!todo handle expressions for month, day, year, not just labels and values.
DriverBaseClass.TranslateDate        Procedure(*Cstring pFunc, *CString pParms,string pTokenString,*Long pTokenPos,*Cstring[] pExParm,Long pNumParms)
t          Long ,Auto
LabelType  Byte
FieldType  Long
cond       Cstring(5)
fld        Cstring(128)
dy         Cstring(128) ,Auto
mth        Cstring(128) ,Auto
yr         Cstring(128) ,Auto
  Code
  ! if the function is being used in a comparison, then the type of the comparing field is important.
  ! so look for a comparison, and see if the thing being compared is a label of type driver:field
  If pTokenPos > 12
    If sub(pTokenString,pTokenPos - 6,1) = token:condition
      t = sub(pTokenString,pTokenPos - 5,4)
      get(self.ConditionQueue,t)
      Cond = self.ConditionQueue.Condition
    End
    If sub(pTokenString,pTokenPos - 6,1) = token:condition and sub(pTokenString,pTokenPos - 12,1) = token:label
      t = sub(pTokenString,pTokenPos - 11,4)
      get(self.LabelQueue,t)
      fld = self.TranslateLabel(self.LabelQueue.Label,LabelType)   ! gets the specific self.fields node.
    end
  ElsIf pTokenPos + 17 < len(clip(pTokenString))
    If sub(pTokenString,pTokenPos + 6,1) = token:condition
      t = sub(pTokenString,pTokenPos +7,4)
      get(self.ConditionQueue,t)
      Cond = self.ConditionQueue.Condition
    End
    If sub(pTokenString,pTokenPos + 6,1) = token:condition and sub(pTokenString,pTokenPos + 12,1) = token:label
      t = sub(pTokenString,pTokenPos + 13,4)
      get(self.LabelQueue,t)
      fld = self.TranslateLabel(self.LabelQueue.Label,LabelType)   ! gets the specific self.fields node.
    end
  End

  !-- month
  If pExParm[1,1] = token:value                           ! the parameter is a value, not a label.
    t = sub(pExParm[1],2,4)                       ! Get Value Queue Index number
    get(self.ValueQueue,t)                        ! Load value from Queue
    mth = format(self.ValueQueue.Value,@n02)      ! Format the number as a 2 digit month number
  ElsIf pExParm[1,1] = token:label
    t = sub(pExParm[1],2,4)
    get(self.LabelQueue,t)
    mth = self.LabelQueue.Label
  End
  !-- day
  If pExParm[2,1] = token:value
    t = sub(pExParm[2],2,4)
    get(self.ValueQueue,t)
    dy = format(self.ValueQueue.Value,@n02)
  ElsIf pExParm[2,1] = token:label
    t = sub(pExParm[2],2,4)
    get(self.LabelQueue,t)
    dy = self.LabelQueue.Label
  End
  !-- year
  If pExParm[3,1] = token:value
    t = sub(pExParm[3],2,4)
    get(self.ValueQueue,t)
    yr = self.ValueQueue.Value
    If yr < 100
      If yr > year(today()) + 20 then yr += 1900 else yr += 2000.
    End
  ElsIf pExParm[3,1] = token:label
    t = sub(pExParm[3],2,4)
    get(self.LabelQueue,t)
    yr = self.LabelQueue.Label
  End
  Return self._TranslateDateSql(fld,mth,dy,yr,LabelType,Cond)

!-----------------------------------------------------------------
!!!DERIVE
DriverBaseClass._TranslateDateSql          Procedure(*CString pField, String pMonth, String pDay, String pYear, Byte pLabelType,*Cstring pCond)
  code
  Return ''

!-----------------------------------------------------------------
DriverBaseClass.TranslateDay         Procedure(*Cstring pFunc, *CString pParms,string pTokenString,*Long pTokenPos,*Cstring[] pExParm,Long pNumParms)
t          Long,Auto
dy         Cstring(128)
LabelType  Byte
  Code
  If pExParm[1,1] = token:value                                 ! if its a value
    t = sub(pExParm[1],2,4)                                     ! get the value index
    get(self.ValueQueue,t)                                      ! get the actual value from the value queue. Expecting 1-31 or yyyy-mm-dd string or 100-100000
    do ParseValue
  ElsIf pExParm[1,1] = token:label                              ! if it's a label, it could be a DATE column, a LONG column or a binded value
    t = sub(pExParm[1],2,4)
    Get(self.LabelQueue,t)
    dy = self.TranslateLabel(self.LabelQueue.Label,LabelType)   ! gets the specific self.fields node. Needed for call to _TranslateDaySQL below
    Case LabelType
    Of driver:constant
    Orof driver:bound
      self.ValueQueue.Value = dy                                ! safe to just use because ParseValue will force it to be a number
      do ParseValue
    Of driver:field
    orof driver:unknown
      dy = self._TranslateDaySQL(dy)
    End
  End
  Return dy

ParseValue  routine
  If self.ValueQueue.Value > 0 and self.ValueQueue.Value <= 31
    dy = Int(self.ValueQueue.Value)
  ElsIf self.ValueQueue.Value < 100000  ! clarion long number
    dy = Day(self.ValueQueue.Value)
  Else ! assume string of yyyy-mm-dd format
    dy = Int(Sub(self.ValueQueue.Value,9,2))
  End

!-----------------------------------------------------------------
!!!DERIVE
DriverBaseClass._TranslateDaySQL   Procedure(*CString pField)
  code
  Return ''

!-----------------------------------------------------------------
DriverBaseClass.TranslateEndsWith    Procedure(*Cstring pFunc, *CString pParms,string pTokenString,*Long pTokenPos,*Cstring[] pExParm,Long pNumParms)
  Code
  Return self._ExpandExpression(pExParm[2]) & ' LIKE ' & self._ExpandExpression(pExParm[1],'%','')

!-----------------------------------------------------------------
DriverBaseClass.TranslateInList      Procedure(*Cstring pFunc, *CString pParms,string pTokenString,*Long pTokenPos,*Cstring[] pExParm,Long pNumParms)
x     long
c     long
ans   cstring(4096)
pc    long,Auto
  Code
  If pNumParms < 2                                                      ! INLIST(searchstring,option1...) so must be at least 2 parameters
    Return 'false'
  End
  pc = self._ParameterCount                                             !  number of parameters bound so far
  Loop x = 2 to pNumParms                                               !  work our way through the parameters.
    If x = 2
      ans = self._ExpandExpression(pExParm[x])
    Else
      ans = ans & ',' & self._ExpandExpression(pExParm[x])
    End
  End
  If ans = ''
    return 'false'
  End
  loop x = 1 to len(ans)
    if ans[x] = ',' then c += 1.
  End
  If c or pc <> self._ParameterCount                                   ! If one of the terms is a parameter then assume it's a list.
    Return self._ExpandExpression(pExParm[1]) & ' IN (' & ans & ')'
  else
    Return self._ExpandExpression(pExParm[1]) & ' = ' & ans
  End

!-----------------------------------------------------------------
! handles number or string parameters
! if lowerbound is more than higher bound then swaps the parameters around.
DriverBaseClass.TranslateInRange     Procedure(*Cstring pFunc, *CString pParms,string pTokenString,*Long pTokenPos,*Cstring[] pExParm,Long pNumParms)
low   cstring(255)
high  cstring(255)
lowr   real
highr  real
lown   byte
highn  byte
  Code
  If pNumParms <> 3
    self.SetError(FileSystemErr)
    self.SetFileError(BadFilterErr,'BadFilterErr: INRANGE called with the wrong number of parameters.')
    return ''
  End
  low = self._ExpandExpression(pExParm[2])
  if numeric(low) then lowr = low ; lown = true.
  high = self._ExpandExpression(pExParm[3])
  if numeric(high) then highr = high ; highn = true.
  if lown and highn  ! both arguments are numeric, so do numeric comparisons
    if lowr = highr
      Return self._ExpandExpression(pExParm[1]) & ' = ' & lowr
    elsif lowr < highr
      Return self._ExpandExpression(pExParm[1]) & ' BETWEEN ' & lowr & ' AND ' & highr
    else
      Return self._ExpandExpression(pExParm[1]) & ' BETWEEN ' & highr & ' AND ' & lowr
    end
  End
  ! one of the arguments is a string, so do a string comparison
  If low = high
    Return self._ExpandExpression(pExParm[1]) & ' = ' & low
  Elsif low < high
    Return self._ExpandExpression(pExParm[1]) & ' BETWEEN ' & low & ' AND ' & high
  Else
    Return self._ExpandExpression(pExParm[1]) & ' BETWEEN ' & high & ' AND ' & low
  End

!-----------------------------------------------------------------
! Note: Not all SQL engines support INSTR, some use POSITION, CHARINDEX etc
DriverBaseClass.TranslateInString    Procedure(*Cstring pFunc, *CString pParms,string pTokenString,*Long pTokenPos,*Cstring[] pExParm,Long pNumParms)
tokenplus1  cstring(6)
tokenplus2  cstring(6)
vx  long
cx  long
  Code
  tokenplus1 = sub(pTokenString,pTokenPos+6,6)
  tokenplus2 = sub(pTokenString,pTokenPos+12,6)
  If pNumParms = 2 and len(self._ExpandExpression(pExParm[1])) > 1
    self.BugAlert('STEP parameter defaulting to 1 in filter.')
  ElsIf pNumParms <> 4 or self._ExpandExpression(pExParm[3]) <> 1 or self._ExpandExpression(pExParm[4]) <>  1
    self.BugAlert('Use of STEP and START parameters to INSTRING in filter will be ignored. ' & pNumParms & ' ' & self._ExpandExpression(pExParm[3]) & ' ' & self._ExpandExpression(pExParm[4]) )
  End
  If tokenplus1[1] = 'C'
    ! so the instring part is then being compared to something so use INSTR not LIKE.
    If tokenplus2[1] = 'V'
      vx = sub(tokenplus2,2,4)
      get(self.ValueQueue,vx)
    End
    cx = sub(tokenplus1,2,4)
    get(self.ConditionQueue,cx)
    case self.ConditionQueue.Condition
    of '='
      If self.ValueQueue.Value = '0'
        ! special case, if condition = 0 then use NOT LIKE
        pTokenPos += 12
        return self._ExpandExpression(pExParm[2]) & ' NOT LIKE ' & self._ExpandExpression(pExParm[1],'%','%')
      ElsIf self.ValueQueue.Value = '1'
        ! special case, if condition = 1 then use BeginsWith
        pTokenPos += 12
        return self._ExpandExpression(pExParm[2]) & ' LIKE ' & self._ExpandExpression(pExParm[1],'','%')
      End
    of '<='
      If self.ValueQueue.Value = '0'
        ! special case, if condition = 0 then use NOT LIKE
        pTokenPos += 12
        return self._ExpandExpression(pExParm[2]) & ' NOT LIKE ' & self._ExpandExpression(pExParm[1],'%','%')
      End
    of '<>'
    orof '>'
      ! special case, if conditon <> 0 then use LIKE
      If self.ValueQueue.Value = '0'
        pTokenPos += 12
        return self._ExpandExpression(pExParm[2]) & ' LIKE ' & self._ExpandExpression(pExParm[1],'%','%')
      End

    of '>='
      ! special case, if conditon >= 1 then use LIKE
      If self.ValueQueue.Value = '1'
        pTokenPos += 12
        return self._ExpandExpression(pExParm[2]) & ' LIKE ' & self._ExpandExpression(pExParm[1],'%','%')
      End
    End
    return self.TranslateInStr(pFunc,pParms,pTokenString,pTokenPos,pExParm,pNumParms)
  End
  Return self._ExpandExpression(pExParm[2]) & ' LIKE ' & self._ExpandExpression(pExParm[1],'%','%')

!-----------------------------------------------------------------
! Note: Not all SQL engines support INSTR, some use POSITION, CHARINDEX, LOCATE etc
DriverBaseClass.TranslateInStr       Procedure(*Cstring pFunc, *CString pParms,String pTokenString,*Long pTokenPos,*Cstring[] pExParm,Long pNumParms)
  code
  return 'INSTR(' & self._ExpandExpression(pExParm[2]) & ',' & self._ExpandExpression(pExParm[1]) & ')'

!-----------------------------------------------------------------
! Hint: MySql uses AS SIGNED, Oracle uses AS NUMBER(10), Firebird uses AS INTEGER.
! Don't use FLOOR here as that goes the wrong way for negative numbers.
DriverBaseClass.TranslateInt         Procedure(*Cstring pFunc, *CString pParms,string pTokenString,*Long pTokenPos,*Cstring[] pExParm,Long pNumParms)
  Code
  Return 'CAST(' & self._ExpandExpression(pParms) & ' AS INT)'

!-----------------------------------------------------------------
! MATCH( first, second [, mode ] )
DriverBaseClass.TranslateMatch       Procedure(*Cstring pFunc, *CString pParms,string pTokenString,*Long pTokenPos,*Cstring[] pExParm,Long pNumParms)
v1        Cstring(100)
x         Long
nocase    byte
mode      byte
r         long
  Code
  If pNumParms = 2
    mode = Match:Wild
  else
    mode = Evaluate(self._ExpandExpression(pExParm[3]))
    If band(mode,Match:NoCase)
      nocase = true
      mode = band(mode,0Fh)
    End
  End
  If mode = match:wild
    v1 = self._ExpandExpression(pExParm[1])
    do replaces
    if r = 0 then mode = match:simple.
  End
  Case mode
  Of Match:Simple ! literally 'x' = 'y', potentially with NOCASE
    If nocase
      Return self._optimize('UPPER',self._ExpandExpression(pExParm[2])) & ' = ' & self._optimize('UPPER',self._ExpandExpression(pExParm[1]))
    Else
      Return self._ExpandExpression(pExParm[2]) & ' = ' & self._ExpandExpression(pExParm[1])
    End

  of Match:Wild
    If nocase
      Return self._optimize('UPPER', self._ExpandExpression(pExParm[2])) & ' LIKE ' & self._optimize('UPPER',v1)
    Else
      Return self._ExpandExpression(pExParm[2]) & ' LIKE ' & v1
    End

  of Match:Regular
    return self.TranslateRegularExpression(pExParm[1],pExParm[2]) ! Different SQLs have different syntax for this.

  of Match:Soundex
    return 'SOUNDEX(' & self._ExpandExpression(pExParm[2]) & ') = SOUNDEX(' & self._ExpandExpression(pExParm[1]) & ')'
  End

replaces  routine
  Loop x = 1 to len(v1)
    Case v1[x]
    Of '?'
      v1[x] = '_'   ! one single character
      r += 1
    Of '*'
      v1[x] = '%'   ! represents zero, one, or multiple characters
      r += 1
    End
  End

!-----------------------------------------------------------------
DriverBaseClass.TranslateMonth         Procedure(*Cstring pFunc, *CString pParms,string pTokenString,*Long pTokenPos,*Cstring[] pExParm,Long pNumParms)
t          Long
mth        Cstring(128)
LabelType  Byte
  Code
  If pExParm[1,1] = token:value                                ! if its a value
    t = sub(pExParm[1],2,4)                                    ! get the value index
    get(self.ValueQueue,t)                                     ! get the actual value from the value queue. Expecting 1-12 or yyyy-mm-dd string or 100-100000
    do ParseValue
  ElsIf pExParm[1,1] = token:label                             ! if it's a label, it could be a DATE column, a LONG column or a binded value
    t = sub(pExParm[1],2,4)
    get(self.LabelQueue,t)
    mth = self.TranslateLabel(self.LabelQueue.Label,LabelType)
    case LabelType
    of driver:constant
    orof driver:bound                                          ! safe to just use because ParseValue will force it to be a number
      self.ValueQueue.Value = mth
      do ParseValue
    of driver:field
    orof driver:unknown
      mth = self._TranslateMonthSQL(mth)
    End
  End
  Return mth

ParseValue  routine
  If self.ValueQueue.Value > 0 and self.ValueQueue.Value <= 12
    mth = int(self.ValueQueue.Value)
  ElsIf self.ValueQueue.Value < 100000  ! clarion long number
    mth = Month(self.ValueQueue.Value)
  Else ! assume string of yyyy-mm-dd format
    mth = int(sub(self.ValueQueue.Value,6,2))
  End

!-----------------------------------------------------------------
!!!DERIVE
DriverBaseClass._TranslateMonthSQL   Procedure(*CString pField)
  code
  Return ''

!-----------------------------------------------------------------
DriverBaseClass.TranslateNull        Procedure(*Cstring pFunc, *CString pParms,string pTokenString,*Long pTokenPos,*Cstring[] pExParm,Long pNumParms)
  Code
  return self._ExpandExpression(pParms) & ' IS NULL'

!-----------------------------------------------------------------
DriverBaseClass.TranslateSearchX        Procedure(*Cstring pFunc, *CString pParms,string pTokenString,*Long pTokenPos,*Cstring[] pExParm,Long pNumParms)
  Code
  Return ' MATCH ' & self._ExpandExpression(pParms)

!-----------------------------------------------------------------
DriverBaseClass.TranslateSqrt         Procedure(*Cstring pFunc, *CString pParms,string pTokenString,*Long pTokenPos,*Cstring[] pExParm,Long pNumParms)
  Code
  !self.trace('DriverBaseClass.TranslateSqrt pTokenPos=' & pTokenPos & ' pTokenString=' & pTokenString)
  !self._ViewTokens()
  !If previous token is CAST or previous token is INT
    Return 'SQRT(' & self._ExpandExpression(pParms) & ')'
  !End
  !If next token is % operator
  !  Return  self._ExpandExpression(pParms) & ' AND CAST(SQRT(' & self._ExpandExpression(pParms) & ') AS INT)'
  !End
  !Return  self._ExpandExpression(pParms) & ' AND SQRT(' & self._ExpandExpression(pParms) & ')'
!-----------------------------------------------------------------
DriverBaseClass.TranslateSub         Procedure(*Cstring pFunc, *CString pParms,string pTokenString,*Long pTokenPos,*Cstring[] pExParm,Long pNumParms)
  Code
  return 'SUBSTRING(' & self._ExpandExpression(pParms) & ')'

!-----------------------------------------------------------------
DriverBaseClass.TranslateYear         Procedure(*Cstring pFunc, *CString pParms,string pTokenString,*Long pTokenPos,*Cstring[] pExParm,Long pNumParms)
t          Long
yr         Cstring(128)
LabelType  Byte
  Code
  If pExParm[1,1] = token:value                       ! if its a value
    t = sub(pExParm[1],2,4)                           ! get the value index
    get(self.ValueQueue,t)                            ! get the actual value from the value queue. Expecting 1000-3000 or yyyy-mm-dd string or 3000-100000
    do ParseValue
  ElsIf pExParm[1,1] = token:label                    ! if it's a label, it could be a DATE column, a LONG column or a binded value
    t = sub(pExParm[1],2,4)
    get(self.LabelQueue,t)
    yr = self.TranslateLabel(self.LabelQueue.Label,LabelType)
    Case LabelType
    of driver:constant
    orof driver:bound                                 ! safe to just use because ParseValue will force it to be a number
      self.ValueQueue.Value = yr
      do ParseValue
    Else
      yr = self._TranslateYearSQL(yr)
    End
  End
  Return yr

ParseValue  routine
  If self.ValueQueue.Value > 0 and self.ValueQueue.Value <= 3000
    yr = int(self.ValueQueue.Value)
  ElsIf self.ValueQueue.Value < 100000  ! clarion long number
    yr = Year(self.ValueQueue.Value)
  Else ! assume string of yyyy-mm-dd format
    yr = int(sub(self.ValueQueue.Value,1,4))
  End

!-----------------------------------------------------------------
!!!DERIVE
DriverBaseClass._TranslateYearSQL   Procedure(*CString pField)
  code
  self.trace('DriverBaseClass._TranslateYearSQL Not Expected here')
  Return ''

!-----------------------------------------------------------------
DriverBaseClass._GetFreeParameter         Procedure()
x  long,auto
y  long,auto
p  long,auto
  code
  If self.ParameterQueue &= null
    self.ParameterQueue &= new ParameterQueueType
  End
  If Records(self.ParameterQueue) = 0
    Clear(self.ParameterQueue)
    Clear(self.ParameterQueue.ParameterArray)
    Add(self.ParameterQueue)
    Return 1
  End
  ! first try and find a place on this page
  do OnePage
  p = Pointer(self.ParameterQueue)
  ! next try and find a place on any page
  Loop y = 1 to Records(self.ParameterQueue)
    If y = p then cycle.
    do OnePage
  End
  ! lastly, add a page and add to that;
  Clear(self.ParameterQueue)
  Clear(self.ParameterQueue.ParameterArray)
  Add(self.ParameterQueue)
  Return 1

OnePage  routine
  Loop x = 1 to Driver:ParametersPerPage
    If self.ParameterQueue.ParameterArray[x].OpCode = Opcode:NONE
      Return x
    End
  End

!-----------------------------------------------------------------
DriverBaseClass._SetParameterString         Procedure(Long pCount, String pValue)
x   long,auto
  code
  x = self._GetFreeParameter()
  if x > self.ParameterQueue.ParameterArrayIndex then self.ParameterQueue.ParameterArrayIndex = x.
  Clear(self.ParameterQueue.ParameterArray[x])
  self.ParameterQueue.ParameterArray[x].OpCode = self._ParameterOpcode
  self.ParameterQueue.ParameterArray[x].Count = pCount
  self._ResetParameterValue(x,pValue, size(pValue) )
  Return

!-----------------------------------------------------------------
DriverBaseClass._SetParameterBlob          Procedure(Long pCount, Long pIndex)
x   long,auto
  code
  !self.trace('DriverBaseClass._SetParameterBlob pCount=' & pCount & ' index=' & pIndex)
  x = self._GetFreeParameter()
  if x > self.ParameterQueue.ParameterArrayIndex then self.ParameterQueue.ParameterArrayIndex = x.
  clear(self.ParameterQueue.ParameterArray[x])
  self.ParameterQueue.ParameterArray[x].OpCode = self._ParameterOpcode
  self.ParameterQueue.ParameterArray[x].Count = pCount
  self.ParameterQueue.ParameterArray[x].BlobIndex = pIndex
  Put(self.ParameterQueue)
  Return

!-----------------------------------------------------------------
DriverBaseClass._SetParameterNode          Procedure(Long pCount, *FieldGroupType pNode, Byte pSource, Long pOffset)
x   long,auto
  code
  x = self._GetFreeParameter()
  if x > self.ParameterQueue.ParameterArrayIndex then self.ParameterQueue.ParameterArrayIndex = x.
  clear(self.ParameterQueue.ParameterArray[x])
  self.ParameterQueue.ParameterArray[x].OpCode = self._ParameterOpcode
  self.ParameterQueue.ParameterArray[x].Count = pCount
  self.ParameterQueue.ParameterArray[x].FieldNode &= pNode
  self.ParameterQueue.ParameterArray[x].Source = pSource
  self.ParameterQueue.ParameterArray[x].Offset = pOffset
  Put(self.ParameterQueue)
  Return

!-----------------------------------------------------------------
! for most cases this simply calls _SetParameterNode. However for some Clarion Type / SQL Type combinations
! some automatica translation occurs
DriverBaseClass._SetParameterField          Procedure(Long pCount, *FieldGroupType pNode, Byte pSource, Long pOffset)
x   long,auto
tx  string(10)
  code
  self._SetParameterNode(pCount,pNode,pSource,pOffset)
  Return

!-----------------------------------------------------------------
DriverBaseClass._DuplicateParameter         Procedure(Long pCount, Long pFrom)
node     &FieldGroupType,Auto
Source   Byte,Auto
Offset   Long,Auto
x        Long,Auto
y        Long,Auto
  code
  If self.ParameterQueue &= NULL
    self.trace('DriverBaseClass._DuplicateParameter : self.ParameterQueue is null')
  End
  !self.trace('DriverBaseClass._DuplicateParameter 0 recs=' & records(self.ParameterQueue) & ' err=' & errorcode())
  Loop y = 1 to records(self.ParameterQueue)
    Get(self.ParameterQueue,y)
    Loop x = 1 to Maximum(self.ParameterQueue.ParameterArray,1)
      If self.ParameterQueue.ParameterArray[x].OpCode = self._ParameterOpcode and self.ParameterQueue.ParameterArray[x].Count = pFrom
        ! got it
        node &= self.ParameterQueue.ParameterArray[x].FieldNode
        source = self.ParameterQueue.ParameterArray[x].Source
        offset = self.ParameterQueue.ParameterArray[x].Offset
        self._SetParameterNode(pCount,node,source,offset)
        Return
      End
    End
  End

!-----------------------------------------------------------------
! assumes the correct self.ParameterQueue record has been loaded.
DriverBaseClass._ResetParameterValue         Procedure(Long pIndex, String pValue, Long pLength)
  code
  !self.trace('DriverBaseClass._ResetParameterValue  pIndex=' & pIndex & '  pValue=' & pValue)
  If pLength = 0 and self.ParameterQueue.ParameterArray[pIndex].Value &= null
    self.ParameterQueue.ParameterArray[pIndex].Value &= new string(1)
  Else
    If size(self.ParameterQueue.ParameterArray[pIndex].Value) < pLength
      Dispose(self.ParameterQueue.ParameterArray[pIndex].Value)
      self.ParameterQueue.ParameterArray[pIndex].Value &= new string(pLength)
    End
  End
  If pLength = 0
    self.ParameterQueue.ParameterArray[pIndex].Value = ''
  Else
    self.ParameterQueue.ParameterArray[pIndex].Value = pValue[1 : pLength]
  End
  Put(self.ParameterQueue)
  Return
!-----------------------------------------------------------------
DriverBaseClass._ClearParameterQueue        Procedure(Long pOpcode)
x  long,auto
y  long,auto
  code
  self._ParameterCount = 0
  If self.ParameterQueue &= null then return.
  PushErrors()
  Loop y = 1 to Records(self.ParameterQueue)
    Get(self.ParameterQueue,y)
    If pOpcode = 0
      Clear(self.ParameterQueue.ParameterArray)
      self.ParameterQueue.ParameterArrayIndex = 0
    Else
      Loop x = 1 to self.ParameterQueue.ParameterArrayIndex
        If self.ParameterQueue.ParameterArray[x].OpCode = pOpcode
          self.ParameterQueue.ParameterArray[x].OpCode = Opcode:NONE
        End
      End
    End
    Put(self.ParameterQueue)
  End
  PopErrors()
  Return

!-----------------------------------------------------------------
DriverBaseClass._FreeParameterQueue        Procedure()
x  long,auto
y  long,auto
  code
  self._ParameterCount = 0
  If self.ParameterQueue &= null then return.
  PushErrors()
  Loop y = 1 to records(self.ParameterQueue)
    Get(self.ParameterQueue,y)
    Loop x = 1 to self.ParameterQueue.ParameterArrayIndex
      If self.ParameterQueue.ParameterArray[x].Value &= null then cycle.
      Dispose(self.ParameterQueue.ParameterArray[x].Value)
    End
  End
  PopErrors()
  Free(self.ParameterQueue)

!-----------------------------------------------------------------
!!! DERIVE
DriverBaseClass.TranslateLabel     Procedure(*cstring pValue,*byte pReturnType)
  code
  return pValue

!-----------------------------------------------------------------
DriverBaseClass.TranslateConstant Procedure(*cstring pValue,*long pConstant)
  Code
  Case lower(pValue)
  Of 'match:simple'
    pConstant = match:simple
  Of 'match:wild'
    pConstant =  match:wild
  Of 'match:regular'
    pConstant =  match:regular
  Of 'match:soundex'
    pConstant =  match:soundex
  Of 'match:nocase'
    pConstant =  match:nocase
  else
    Return driver:NotOk
  End
  Return driver:ok

!-----------------------------------------------------------------
!!! DERIVE if necessary
DriverBaseClass.TranslateOperatorPower             Procedure()
  code
  Return ' ^ '

!-----------------------------------------------------------------
!!! DERIVE if necessary
DriverBaseClass.TranslateOperatorMod               Procedure()
  code
  return ' % '

!-----------------------------------------------------------------
!!! DERIVE if necessary
DriverBaseClass.TranslateOperatorConcat            Procedure()
  code
  Return ' || '

!-----------------------------------------------------------------
!!! DERIVE
DriverBaseClass.TranslateRegularExpression    Procedure(*CString pExpr,*CString pColumn)
  code
  self.SetFileError(BadFilterErr,'BadFilterErr: Use of match:regular in Filter not supported')
  Return ' '

!-----------------------------------------------------------------
DriverBaseClass.TranslateVariable  Procedure(*cstring pValue)
v   cstring(4096)
  code
  !self.trace('TranslateVariable ' & pValue)
  v = clip(Evaluate(pValue))
  If Errorcode()
    ! ERROR BAD FILTER, VARIABLE NAME
    !self.SetError(FileSystemErr)
    !self.SetFileError(BadFilterErr,'BadFilterErr: Unable to Evaluate ' & pValue)
    Return pValue
  End
  If Numeric(v)
    Return v
  else
    Return '''' & v & ''''
  End

!-----------------------------------------------------------------
DriverBaseClass.DOPROPERTY                         Procedure(String pProperty,Long pIndex=0)
  Code
  !self.trace('DriverBaseClass.DOPROPERTY (' & pProperty & ' [' & self.InterpretProperty(pProperty) & '],' & pIndex & ')')
  Case pProperty
  Of Prop:ClearProps
    self.ClearProps()
  of PROP:Explain
    self.SetPROP:Explain(true)
  End
  Return

!-----------------------------------------------------------------
DriverBaseClass.GETPROPERTY                        Procedure(String pProperty,Long pIndex=0)
  Code
  !self.trace('DriverBaseClass.GETPROPERTY ' & pProperty & ' ' & self.InterpretProperty(pProperty))
  Case pProperty
  of Prop:Affected
    return self.GetProp:Affected()
  of Prop:AlwaysQuote
    return self.GetProp:AlwaysQuote()
  of Prop:ChildrenAffected
    return self.GetProp:ChildrenAffected()
  of PROP:Codepage
    return self.GetProp:CodePage()
  of Prop:ClientVersionMajor
    return self.GetPROP:ClientVersionMajor()
  of Prop:ClientVersionMinor
    return self.GetPROP:ClientVersionMinor()
  of Prop:ClientVersionBuild
    return self.GetPROP:ClientVersionBuild()
  of PROP:ClientVer
    return self.GetProp:ClientVer()
  of Prop:DateTimeSeparator
    return self.GetProp:DateTimeSeparator()
  of Prop:DbVersionMajor
    return self.GetPROP:DbVersionMajor()
  of Prop:DbVersionMinor
    return self.GetPROP:DbVersionMinor()
  of Prop:DbVersionBuild
    return self.GetPROP:DbVersionBuild()
  of PROP:DBMSVer
    return self.GetProp:DBMSVer()

  of PROP:Distinct
    Return self.GetPROP:Distinct()
  of PROP:Driver
    Return self.GetPROP:Driver()
  of PROP:DriverVersion
    Return self.GetProp:DriverVersion()
  of PROP:Database
    Return self.GetPROP:Database()
  of PROP:DatabaseName
    Return self.GetPROP:DatabaseName()
  of Prop:OBD
    Return self.GetProp:Obd()
  of Prop:NotDistinct
    Return self.GetPROP:NotDistinct()
  of PROP:Explain
    return self.GetProp:Explain()
  of PROP:FetchSize
    Return self.GetPROP:FetchSize()
  of PROP:Fields             !  ! Get number of fields in file (group)
    return self.GetProp:Fields(pIndex)
  of PROP:Filter
    Return self.GetPROP:Filter()
  of Prop:GroupBy
    Return self.GetProp:GroupBy()
  of Prop:Having
    Return self.GetProp:Having()
  of PROP:IgnoreTruncation
    Return self.GetProp:IgnoreTruncation()
  of Prop:IPrequestCount
    Return self.GetProp:IPrequestCount()
  of PROP:Label
    Return self.GetPROP:Label(pIndex)
  of PROP:Limit
    Return self.GetPROP:Limit()
  of Prop:LineEndings
    Return self.GetProp:LineEndings()
  of Prop:LogBind
    Return self.GetProp:LogBind()
  of Prop:LogClarion
    Return self.GetProp:LogClarion()
  of Prop:LogConnections
    Return self.GetProp:LogConnections()
  of Prop:LogData
    Return self.GetProp:LogData()
  of Prop:LogExplain
    Return self.GetProp:LogExplain()
  of Prop:LogOptions
    Return self.GetProp:LogOptions()
  of Prop:LogSQL
    Return self.GetProp:LogSQL()
  of PROP:NoPrevious
    Return self.GetPROP:NoPrevious()
  of Prop:NullString
    Return self.GetProp:NullString()
  of PROP:Offset
    Return self.GetPROP:Offset()
  of Prop:Order
    Return self.GetProp:Order()
  of Prop:OrderBy
    Return self.GetProp:OrderBy()
  of PROP:Paging
    Return self.GetPROP:Paging()
  of PROP:Profile
  orof PROP:Logfile
    return self.GetProp:Profile()
  of PROP:QuoteString
    Return self.GetPROP:QuoteString()
  of PROP:ReadOnly
    Return self.GetPROP:ReadOnly()
  of Prop:ResultRecords
    return self.GETPROP:ResultRecords()
  of Prop:ResultRow
    return self.GETPROP:ResultRow()
  of Prop:Search
    return self.GetProp:Search()
  of Prop:SearchRank
    return self.GetProp:SearchRank()
  of Prop:Separator
    return self.GetProp:Separator()
  of PROP:Server
    Return self.GetPROP:Server()
  of PROP:SQL
    Return self.GetPROP:SQL()
  of PROP:SQLFilter
    Return self.GetPROP:SQLFilter()
  of Prop:SQLOrder
    Return self.GetProp:SqlOrder()
  of PROP:User
    Return self.GetPROP:User()
  of Prop:Where
    Return self.GetProp:Where()
  of Prop:WherePage
    Return self.GetProp:WherePage()
  Else
    Return self.GetCustomProperty(pProperty,pIndex)
  End
  Return ''

!-----------------------------------------------------------------
DriverBaseClass.GetCustomProperty       Procedure(String pProperty,Long pIndex)
  code
  If self.PropertyQueue &= NULL
    Return ''
  End
  PushErrors()
  self.PropertyQueue.property = lower(clip(pProperty))
  self.PropertyQueue.index = pIndex
  Get(self.PropertyQueue,self.PropertyQueue.property,self.PropertyQueue.index)
  If Errorcode()
    PopErrors()
    Return ''
  End
  PopErrors()
  Return self.PropertyQueue.Value

!-----------------------------------------------------------------
DriverBaseClass.OPEN               Procedure()
  code
  If self._CheckClosed() = false then Return.
  self.SetError(noError)
  self.ClearProps()
  Self._HasBeenSet = false
  !self.IPRequestCount  = 0
  !self._Limit          = 0
  Return

!-----------------------------------------------------------------
! deliberatly does not clear prop:sql
DriverBaseClass.ClearProps            PROCEDURE()
  Code
  self.SetError(NoError)
  self.SetProp:Distinct(false)
  self.SetProp:NotDistinct(false)
  !self.SetProp:Explain(false)
  self.SetProp:Filter('')
  self.SetProp:GroupBy('')
  self.SetProp:Having('')
  self.SetProp:Limit(0)
  self.SetProp:Paging(true)
  self.SetProp:Offset(0)
  self.SetProp:Order('')
  self.SetProp:OrderBy('')
  self.SetProp:ReadOnly(false)
  self.SetProp:Search('')
  self.SetProp:SQLFilter('')
  self.SetProp:SQLOrder('')
  self.SetProp:Where('')
  self.SetProp:WherePage('')
  self.ProjectList.SetValue('')
  !self._HasBeenSet = False
  self._FreeSubset()

  self.SetProp:Separator(',')
  self.SetProp:LineEndings('<13,10>')
  self.SetProp:AlwaysQuote(false)
  self.SetProp:NullString('\N')  ! null:null
  self.SetProp:DateTimeSeparator(' ')

  self.SearchFilter         = ''
  self._SearchOrderClause   = ''
  self.SearchRank           = 0
  self._SearchParameter     = 0
  self.fetchsize = 30                 ! a somewhat arbitary value, but is more-or-less the size of a browse list page. Can be set using BUFFER. or prop:FetchSize

  Free(self.BindQueue)
  Return

!-----------------------------------------------------------------
! called at the start of the derived method.
DriverBaseClass.CLOSE               Procedure()
  code
  If self._opened
    Self.SetError(NoError)
  Else
    Self.SetError(NotOpenErr)
    Return
  End
  self.ClearProps()
  !Self.FetchSize       = 0      ! prop:FetchSize survives a CLOSE and OPEN of a FILE or VIEW
  self.IPRequestCount  = 0
  self._Limit          = 0

  PushErrors()
  Self.Flush()  ! tells the server that resources are not longer required. Frees result set in derived classes etc.
  PopErrors()

  Dispose(self.Filter)
  Dispose(self.SQLFilter)
  Dispose(self.Order)
  Dispose(self.SQLOrder)
  !Dispose(self.SqlCode)
  Dispose(self.Where)
  Dispose(self.WherePage)
  Dispose(self.OrderBy)
  Dispose(self.GroupBy)
  Dispose(self.Having)
  self._opened = false
  Return

!-----------------------------------------------------------------
DriverBaseClass.FLUSH               Procedure()
  code
  self.SetError(NoError)
  self.result.Free()
  Return

!-----------------------------------------------------------------
DriverBaseClass.LOG            PROCEDURE(String pLog)
SHARE_ALL              Equate(3)
GENERIC_WRITE          Equate(40000000h)
OPEN_ALWAYS            Equate(4)
FILE_ATTRIBUTE_NORMAL  Equate(080h)
INVALID_HANDLE_VALUE   Equate(-1)
written                Long
cLog                   Cstring(size(pLog)+400)
UserLen                Ulong,Auto
  code
  !self.trace('log ' & self._LogFile)
  If _ProcessId = 0 then _ProcessId = osGetCurrentProcessId().
  If _WorkStation = '' then _WorkStation = GetReg(REG_LOCAL_MACHINE,'SYSTEM\CurrentControlSet\Control\ComputerName\ComputerName\','ComputerName').
  UserLen = size(_User)
  If _User = '' then osWNetGetUser(,_User,UserLen).
  !Clog = '[' & self.GetProp:Driver() & '][' & self._structure & '][' & self.rid & '][' & _WorkStation & '][' & _User & '][' & _ProcessId & '][' & thread() & '][' & format(today(),'@d1')& '][' & format(clock(),'@t4') & '][' & self.GetProp:Server() & '][' & self.GetProp:Database() & '][' & self.FullPathName & '][' & self.status() & ']' & clip(pLog) & '<13,10>'
  !Clog = '[' & self.GetProp:Driver() & '][' & self._structure & '][' & self.rid & '][' & _WorkStation & '][' & _User & '][' & _ProcessId & '][' & '][' & self.GetProp:Server() & '][' & self.GetProp:Database() & '][' & self.FullPathName & '][' & ']' & clip(pLog) & '<13,10>'
  If self._LogFile = ''
    Clog = '[' & self.GetProp:Driver() & '][' & self._structure & '][' & self.rid & '][PID=' & _ProcessId & '][THD=' & thread() & '][' & self.GetProp:Server() & '][' & self.GetProp:Database() & '][' & self.FullPathName & '][' & self.status() & ']' & clip(pLog)
    osOutputDebugString(Clog)
  Elsif self._LogFile
    Clog = '[' & self.GetProp:Driver() & '][' & self._structure & '][' & self.rid & '][' & _WorkStation & '][USR=' & _User & '][PID=' & _ProcessId & '][THD=' & thread() & '][' & format(today(),'@d1')& '][' & format(clock(),'@t4') & '][' & self.GetProp:Server() & '][' & self.GetProp:Database() & '][' & self.FullPathName & '][' & self.status() & ']' & clip(pLog) & '<13,10>'
    If self._logHandle = 0
      ! open log file, in append mode
      self._logHandle = osCreateFile(self._LogFile, GENERIC_WRITE, SHARE_ALL , 0, OPEN_ALWAYS, FILE_ATTRIBUTE_NORMAL, 0)
      If self._logHandle = INVALID_HANDLE_VALUE
        self.SetError(FileSystemErr)
        self._WinError()
      End
    End
    If self._logHandle >= 0
      ! set to end of file
      LogCriticalSection.Wait()
      If osSetEndOfFile(self._logHandle) = 0
        self.SetError(FileSystemErr)
        self._WinError()
      Else
        ! write string
        If osWriteFile(self._logHandle, address(cLog), len(clip(cLog)), written, 0) = 0
          self.SetError(FileSystemErr)
          self._WinError()
        Else
          ! flush log, but don't close it.
          If osFlushFileBuffers(self._logHandle) = 0
            self.SetError(FileSystemErr)
            self._WinError()
          End
        End
      End
      LogCriticalSection.Release()
    End
  End
  Return

!-----------------------------------------------------------------
DriverBaseClass.LOGGINGON                  Procedure(<String pFileName>,Long pOptions=0)
  Code
  self.trace('=========================== LOGGING ON ' & self.FullPathName & ' ==============================================')
  If Omitted(pFileName)
    self._LogFile = ''
  Else
    If Numeric(pFileName)
      pOptions = pFileName
      self._LogFile = ''
    Else
      self._LogFile = pFileName  ! the log file is not opened here, it'll be opened by the first call to add to the file.
    End
  End
  If pOptions < 0
    pOptions = 65535 + pOptions
  End
  If pOptions = 0
    self._logClarion = true
    self._logSQL     = true
    self._logBind    = true
    self._logData    = true
    self._logOptions = true
    self._logExplain = false
    self._logConnections = true
  Else
    If band(pOptions,driver:LogClarion) then self._logClarion = true else self._logClarion = false.
    If band(pOptions,driver:LogSQL) then self._logSQL = true else self._logSQL = false.
    If band(pOptions,driver:LogBind) then self._logBind = true else self._logBind = false.
    If band(pOptions,driver:LogDetails) then self._logData = true else self._logData = false.
    If band(pOptions,driver:LogExplain) then self._logExplain = true else self._logExplain = false.
    If band(pOptions,driver:LogOptions) then self._logOptions = true else self._logOptions = false.
    If band(pOptions,driver:LogConnections) then self._logConnections = true else self._logConnections = false.
  End
  self.log('=========================== LOGGING ON ' & self.FullPathName & ' ==============================================')
  !self.trace('=========================== LOGGING ON ' & self.FullPathName & ' ==============================================')
  Return

!-----------------------------------------------------------------
DriverBaseClass.LOGGINGOFF                 Procedure()
  Code
  If self._LogFile
    osCloseHandle(self._LogFile)
  End
  self._logClarion = false
  self._logSQL     = false
  self._logBind    = false
  self._logData    = false
  self._logExplain = false
  self._logOptions = false
  self._logConnections = false
  self.log('=========================== LOGGING OFF ' & self.FullPathName & ' ==============================================')
  Return

!-----------------------------------------------------------------
!!! derived for FILE and VIEW
DriverBaseClass.RESULTGET       PROCEDURE(BIGINT pRow)
  code

!-----------------------------------------------------------------
DriverBaseClass.RESULTNEXT       PROCEDURE()
  code
  self.ResultGet(self._ResultRow+1)

!-----------------------------------------------------------------
DriverBaseClass.RESULTPREVIOUS   PROCEDURE()
  code
  self.ResultGet(self._ResultRow-1)

!-----------------------------------------------------------------
DriverBaseClass.RESULTROW        PROCEDURE()
  code
  Return self._ResultRow

!-----------------------------------------------------------------
DriverBaseClass.RESULTRECORDS    PROCEDURE()
  code
  Return self.Result.Rows()

!-----------------------------------------------------------------
!!! Derive
DriverBaseClass.ResultToExplain  Procedure(iResultSet pResult)
  Code
  Return

!-----------------------------------------------------------------
! Send commands are in the form /a=b /c=d
! ie, a space separated list, sql commands start with / (isam might not),
!  and are of the form name=value
! value can be anything, including TRUE or FALSE
DriverBaseClass.SEND             PROCEDURE(STRING pMessage)
str  StringTheory
lne  StringTheory
x    Long
ans  String(255)
  Code
  If pMessage = '' then Return ''.
  !self.trace('DriverBaseClass.SEND ' & pMessage)
  str.SetValue(pMessage,st:clip)
  str.Split(' ','"','"')
  Loop x = 1 to str.Records()
    lne.SetValue(str.GetLine(x))
    If lne.Instring('=') = 0
      ans = self.SetDriverOption(lne.GetValue(),'')
    Else
      ans = self.SetDriverOption(lne.Before('='),lne.After('='))
    End
  End
  Return ans

!-----------------------------------------------------------------
! SetDriverOption is called in reverse order. ie Driver, then generic class, then base class.
! The LOG statement may appear multiple times as it flows through this call tree, however that cannot be helped.
! Note that these Base class options apply to FILE and VIEW structures.
DriverBaseClass.SetDriverOption  Procedure(String pOption, String pValue)
  Code
  !self.trace('SetDriverOption ' & pOption & ' = ' & pValue)
  If self._logOptions then self.Log('[OPTN]' & clip(pOption) & ' =[' & clip(pValue & ']')).

  Case upper(pOption)
  of '/DUMMY'
    If pValue = ''
      self.opt:dummy = True
    Else
      self.opt:dummy = pValue
    End
    Return self.opt:dummy
  of '/EXPLAIN'
    If pValue = ''
      self.opt:explain = false
    Else
      self.opt:explain = pValue
    End
    Return self.opt:explain
  of '/IGNORETRUNCATION'
    Case upper(pValue)
    Of 'TRUE' orof '1'
      self.SetProp:IgnoreTruncation(1)
    Else
      self.SetProp:IgnoreTruncation(0)
    End
    Return self.opt:IgnoreTruncation ! unlike GetProp returns 0 for 0, not blank for 0.
  of '/UNSAFE'
    case upper(pValue)
    of 'TRUE' orof '1'
      self.opt:unsafe = 1
    of 'FALSE' orof '0'
      self.opt:unsafe = 0
    of 'STOP'
      self.opt:unsafe = 2
    of 'GPF'
      self.opt:unsafe = 3
    else
      self.opt:unsafe = pValue
    End
    Return self.opt:unsafe
  End
  Return 'Unknown Driver String'

!-----------------------------------------------------------------
DriverBaseClass.SQL            Procedure(String pSql,<? pParm1>,<? pParm2>,<? pParm3>,<? pParm4>,<? pParm5>,<? pParm6>,<? pParm7>,<? pParm8>,<? pParm9>,<? pParm10>,<? pParm11>,<? pParm12>,<? pParm13>,<? pParm14>,<? pParm15>,<? pParm16>,<? pParm17>,<? pParm18>,<? pParm19>,<? pParm20>)
  Code
  self.SetError(NoDriverSupport)
  Return

!-----------------------------------------------------------------
DriverBaseClass.STATUS           PROCEDURE()
  Code
  Return 0

!-----------------------------------------------------------------
DriverBaseClass.SETPROPERTY              Procedure(String pProperty,Long pIndex,STRING pValue)
  Code
  case pProperty
  of Prop:AlwaysQuote
    Self.SetProp:AlwaysQuote(pValue)
  of Prop:ClearProps
    self.ClearProps()
  of Prop:Codepage
    self.SetProp:Codepage(pValue)
  of Prop:DateTimeSeparator
    self.SetProp:DateTimeSeparator(pValue)
  of PROP:Distinct
    self.SetPROP:Distinct(pValue)
  of PROP:NotDistinct
    self.SetPROP:NotDistinct(pValue)
  of PROP:Explain
    self.SetPROP:Explain(pValue)
  of PROP:FetchSize
    self.SetPROP:FetchSize(pValue)
  of PROP:Filter
    self.SetPROP:Filter(pValue)
  of Prop:GroupBy
    self.SetProp:GroupBy(pValue)
  of Prop:Having
    self.SetProp:Having(pValue)
  of PROP:IgnoreTruncation
    self.SetProp:IgnoreTruncation(pValue)
  of Prop:IPrequestCount
    self.SetProp:IPrequestCount(pValue)
  of PROP:Limit
    self.SetPROP:Limit(pValue)
  of Prop:LineEndings
    Self.SetProp:LineEndings(pValue)
  of PROP:Log
    self.Log(pValue)
  of Prop:LogBind
    self.SetProp:LogBind(pValue)
  of Prop:LogClarion
    self.SetProp:LogClarion(pValue)
  of Prop:LogConnections
    self.SetProp:LogConnections(pValue)
  of Prop:LogData
  orof PROP:Details
    self.SetProp:LogData(pValue)
  of PROP:LogExplain
    self.SetProp:LogExplain(pValue)
  of PROP:LogOptions
    self.SetProp:LogOptions(pValue)
  of PROP:LogSQL
    self.SetProp:LogSQL(pValue)
  of PROP:Paging
    self.SetPROP:Paging(pValue)
  of PROP:Profile
  orof PROP:Logfile
    self.SetProp:Profile(pValue)
  of PROP:NoPrevious
    self.SetPROP:NoPrevious(pValue)
  of Prop:NullString
    Self.SetProp:NullString(pValue)
  of PROP:Offset
    self.SetPROP:Offset(pValue)
  of Prop:Order
    self.SetProp:Order(pValue)
  of Prop:OrderBy
    self.SetProp:OrderBy(pValue)
  of PROP:QuoteString
    self.SetPROP:QuoteString(pValue)
  of PROP:ReadOnly
    self.SetPROP:ReadOnly(pValue)
  of PROP:Search
    self.SetPROP:Search(pValue)
  of Prop:Separator
    Self.SetProp:Separator(pValue)
  of PROP:SQL
  orof PROP:SQLRowSet
    self.SetPROP:SQL(pValue)
  of PROP:SQLFilter
    self.SetPROP:SQLFilter(pValue)
  of Prop:SQLOrder
    self.SetProp:SQLOrder(pValue)
  of PROP:Where
    self.SetPROP:Where(pValue)
  of PROP:WherePage
    self.SetPROP:WherePage(pValue)
  else
    !self.trace('DriverBaseClass.SetProperty (' & self.InterpretProperty(pProperty) & ',' & pIndex & ',' & pValue & ') [' & self.FullPathName & ']')
    self.SetCustomProperty(pProperty,pIndex,pValue)
  end
  Return

!-----------------------------------------------------------------
DriverBaseClass.SetCustomProperty       Procedure(String pProperty,Long pIndex,STRING pValue)
  code
  PushErrors()
  If self.PropertyQueue &= NULL
    self.PropertyQueue &= NEW PropertyQueueType
  End
  self.PropertyQueue.property = lower(clip(pProperty))
  self.PropertyQueue.index = pIndex
  Get(self.PropertyQueue,self.PropertyQueue.property,self.PropertyQueue.index)
  If Errorcode()
    self.PropertyQueue.Value = clip(pValue)
    Add(self.PropertyQueue,self.PropertyQueue.property,self.PropertyQueue.index)
  Else
    self.PropertyQueue.Value = clip(pValue)
    Put(self.PropertyQueue,self.PropertyQueue.property,self.PropertyQueue.index)
  End
  PopErrors()
  Return

!-----------------------------------------------------------------
DriverBaseClass.GetPROP:Affected            PROCEDURE()
  code
  Return self.Affected

!-----------------------------------------------------------
DriverBaseClass.GetProp:AlwaysQuote  Procedure()
  Code
  If self.AlwaysQuote = 0 then return ''.
  Return self.AlwaysQuote

!-----------------------------------------------------------
DriverBaseClass.SetProp:AlwaysQuote  Procedure(Byte pValue)
  Code
  self.AlwaysQuote = pValue
  Return

!-----------------------------------------------------------------
DriverBaseClass.GetPROP:ChildrenAffected            PROCEDURE()
  code
  Return self.ChildrenAffected

!-----------------------------------------------------------
DriverBaseClass.GetProp:CodePage  Procedure()
  Code
  Return self.codePage

!-----------------------------------------------------------
DriverBaseClass.SetProp:CodePage  Procedure(Long pCodePage)
  Code
  self.codePage = pCodePage
  Return

!-----------------------------------------------------------------
! unlike some other GetProps this returns 0 when set to 0
DriverBaseClass.GetProp:ClientVersionMajor            PROCEDURE()
  code
  Return self.ClientVersionMajor

!-----------------------------------------------------------------
! unlike some other GetProps this returns 0 when set to 0
DriverBaseClass.GetProp:ClientVersionMinor            PROCEDURE()
  code
  Return self.ClientVersionMinor

!-----------------------------------------------------------------
! unlike some other GetProps this returns 0 when set to 0
DriverBaseClass.GetProp:ClientVersionBuild            PROCEDURE()
  code
  Return self.ClientVersionBuild

!-----------------------------------------------------------------
! DbVersionMajor et al are set with a call to _ParseVersion when the Connection is made to the database.
! In other words inside the CONNECT method in the derived class.
DriverBaseClass.GetProp:ClientVer            PROCEDURE()
  code
  If self.ClientVersionMajor = 0 then return ''.
  Return self.ClientVersionMajor & '.' & self.ClientVersionMinor & '.' & self.ClientVersionBuild

!-----------------------------------------------------------------
! unlike some other GetProps this returns 0 when set to 0
DriverBaseClass.GetProp:DbVersionMajor            PROCEDURE()
  code
  Return self.DbVersionMajor

!-----------------------------------------------------------------
! unlike some other GetProps this returns 0 when set to 0
DriverBaseClass.GetProp:DbVersionMinor            PROCEDURE()
  code
  Return self.DbVersionMinor

!-----------------------------------------------------------------
! unlike some other GetProps this returns 0 when set to 0
DriverBaseClass.GetProp:DbVersionBuild            PROCEDURE()
  code
  Return self.DbVersionBuild

!-----------------------------------------------------------------
DriverBaseClass.GetProp:DateTimeSeparator         PROCEDURE()
  code
  Return self.DateTimeSeparator

!-----------------------------------------------------------------
DriverBaseClass.SetProp:DateTimeSeparator         PROCEDURE(String pValue)
  code
  self.DateTimeSeparator = pValue

!-----------------------------------------------------------------
! DbVersionMajor et al are set with a call to _ParseVersion when the Connection is made to the database.
! In other words inside the CONNECT method in the derived class.
DriverBaseClass.GetProp:DBMSVer            PROCEDURE()
  code
  If self.DbVersionMajor = 0 then return ''.
  Return self.DbVersionMajor & '.' & self.DbVersionMinor & '.' & self.DbVersionBuild

!-----------------------------------------------------------------
DriverBaseClass.GetProp:Distinct           PROCEDURE()
  Code
  If self.Distinct then Return '1' Else Return ''.

!-----------------------------------------------------------------
DriverBaseClass.SetPROP:Distinct           PROCEDURE(BYTE pDistinct)
  Code
  If self.distinct <> pDistinct
    self.distinct = pDistinct
    self._PropsCache += 1
  End
  Return

!-----------------------------------------------------------------
!!! DERIVE
DriverBaseClass.GetProp:Driver             PROCEDURE()!,STRING,VIRTUAL ! Get name of file driver
  code
  Return ''

!-----------------------------------------------------------------
! This seems like it should be set here, but that would only version the CLAOBD file.
! Since we want to version the actual driver file, this is derived in the drivers.
DriverBaseClass.GetProp:DriverVersion      PROCEDURE()
  code
  Return ''

!-----------------------------------------------------------------
!!! DERIVE
DriverBaseClass.GetProp:Database       PROCEDURE()   ! get the database name out of the connection string
  code
  Return ''

!-----------------------------------------------------------------
!!! DERIVE
DriverBaseClass.GetProp:DatabaseName        PROCEDURE()!,STRING,VIRTUAL ! Get name of database, like SQLITE or PostgreSQL or whatever
  code
  Return ''

!-----------------------------------------------------------------
DriverBaseClass.GetProp:OBD           PROCEDURE()    ! Is this an Object Based Driver?
  Code
  Return '1'

!-----------------------------------------------------------------
DriverBaseClass.GetProp:Profile            PROCEDURE()!,STRING,VIRTUAL
  code
  Return self._LogFile

!-----------------------------------------------------------------
DriverBaseClass.SetPROP:Profile            PROCEDURE(String pLogFile)
  code
  If self._LogFile and pLogFile <> self._LogFile
    self.LoggingOff()
  ElsIf pLogFile = '' and self._LogFile
    self.LoggingOff()
  End
  self._LogFile = pLogFile  ! the log file is not opened here, it'll be opened by the first call to add to the file.
  Return

!-----------------------------------------------------------------
DriverBaseClass.GetProp:NotDistinct           PROCEDURE()
  Code
  If self.NotDistinct then Return '1' Else Return ''.

!-----------------------------------------------------------------
DriverBaseClass.SetPROP:NotDistinct          PROCEDURE(Long pNotDistinct)
  Code
  If pNotDistinct = 1 then pNotDistinct = 2.   ! used in a count(*) >= pNotDistinct way, so 1 has no meaning. To turn off use 0.
  If self.NotDistinct <> pNotDistinct
    self.NotDistinct = pNotDistinct
    self._PropsCache += 1
  End
  Return

!-----------------------------------------------------------------
DriverBaseClass.GetProp:Explain           Procedure()
  Code
  If self.explain then Return self.explain else Return ''.

!-----------------------------------------------------------------
DriverBaseClass.SetProp:Explain           Procedure(Byte pValue)
  Code
  If self.explain <> pValue
    self.explain = pValue
    self._PropsCache += 1
  End
  Return

!-----------------------------------------------------------------
DriverBaseClass.GetProp:FetchSize           PROCEDURE()  ! Get the gets the pagesize parameter for the last BUFFER statement executed
  code
  Return self.fetchsize

!-----------------------------------------------------------------
DriverBaseClass.SETPROP:FetchSize           PROCEDURE(Long pValue)
  code
  If self.fetchsize <> pValue
    self.fetchsize = pValue
    self._PropsCache += 1
  End
  Return

!-----------------------------------------------------------------
DriverBaseClass.GetProp:Fields             PROCEDURE(Long pIndex)
  code
  Return 0

!-----------------------------------------------------------------
DriverBaseClass.GetProp:Filter             Procedure()
  Code
  If self.Filter &= NULL
    Return ''
  End
  Return self.Filter

!-----------------------------------------------------------------
DriverBaseClass.SetProp:Filter             Procedure(String pValue)
  Code
  self._PropFilterCalled  = True
  If self.Filter &= null and pValue = '' then return.
  If self.Filter &= null or size(self.Filter) < size(pValue) + 1
    Dispose(self.Filter)
    self.Filter &= new Cstring(size(pValue)+1)
  End
  If self.Filter <> clip(pValue)
    self.Filter = clip(pValue)
    self._PropsCache += 1
  End
  Return

!-----------------------------------------------------------------
DriverBaseClass.GetProp:GroupBy           Procedure()
  Code
  If self.GroupBy &= NULL
    Return ''
  End
  Return self.GroupBy

!-----------------------------------------------------------------
! The developer can set this property to whatever. The SET will change it into the parsed SQL statement
! GroupBy cannot contain parameters. If it contains a local BIND variable then that will be evaluated as a constant.
! The ONLY characters allowed in constants are A-Z, a-z, 0-9, . and :
DriverBaseClass.SetProp:GroupBy           Procedure(String pValue)
  Code
  If self.GroupBy &= null and pValue = '' then return.
  If self.GroupBy &= null or size(self.GroupBy) < size(pValue) + 1
    Dispose(self.GroupBy)
    self.GroupBy &= new Cstring(size(pValue)+2)
  End
  If self.GroupBy <> clip(pValue)
    self.GroupBy = clip(pValue)
    self._PropsCache += 1
  End
  If self.GroupBy <> ''
    self.noKeyProject = Driver:ProjectNoKeys
  End
  Return

!-----------------------------------------------------------------
DriverBaseClass.GetProp:Having            Procedure()
  Code
  If self.Having &= NULL
    Return ''
  End
  Return self.Having

!-----------------------------------------------------------------
DriverBaseClass.SetProp:Having            Procedure(String pValue)
  Code
  If self.Having &= null and pValue = '' then return.
  If self.Having &= null or size(self.Having) < size(pValue) + 1
    Dispose(self.Having)
    self.Having &= new Cstring(size(pValue)+1)
  End
  If self.Having <> clip(pValue)
    self.Having = clip(pValue) & ' '
    self._PropsCache += 1
  End
  Return

!-----------------------------------------------------------------
DriverBaseClass.GetProp:IgnoreTruncation   Procedure()
  Code
  If self.opt:ignoretruncation then Return self.opt:ignoretruncation.
  Return ''

!-----------------------------------------------------------------
DriverBaseClass.SetProp:IgnoreTruncation            Procedure(Long pValue)
  Code
  self.opt:ignoretruncation = pValue
  Return

!-----------------------------------------------------------------
DriverBaseClass.GetProp:IPrequestCount    Procedure()
  Code
  If self.IpRequestCount then return self.IpRequestCount.
  Return ''

!-----------------------------------------------------------------
DriverBaseClass.SetProp:IPrequestCount    Procedure(Long pValue)
  Code
  self.IpRequestCount = pValue
  Return
!-----------------------------------------------------------------
! Derived in DriverClass
DriverBaseClass.GetProp:Label            PROCEDURE(Long pIndex)!,STRING,VIRTUAL  ! Get file label
  code
  Return ''

!-----------------------------------------------------------------
DriverBaseClass.GetProp:Limit           PROCEDURE()
  Code
  If self.Limit then Return self.Limit Else Return ''.

!-----------------------------------------------------------------
DriverBaseClass.SetPROP:Limit           PROCEDURE(BIGINT pLimit)
  Code
  self.limit = pLimit
  Return

!-----------------------------------------------------------
DriverBaseClass.GetProp:LineEndings  Procedure()
  Code
  Return self.LineEndings

!-----------------------------------------------------------
DriverBaseClass.SetProp:LineEndings  Procedure(String pValue)
  Code
  self.LineEndings = pValue
  Return

!-----------------------------------------------------------
DriverBaseClass.GetProp:LogBind  Procedure()
  Code
  If self._LogBind then Return '1' Else Return ''.

!-----------------------------------------------------------
DriverBaseClass.SetProp:LogBind  Procedure(String pValue)
  Code
  self._LogBind = pValue
  Return

!-----------------------------------------------------------
DriverBaseClass.GetProp:LogClarion  Procedure()
  Code
  If self._LogClarion then Return '1' Else Return ''.

!-----------------------------------------------------------
DriverBaseClass.SetProp:LogClarion  Procedure(String pValue)
  Code
  self._LogClarion = pValue
  Return

!-----------------------------------------------------------
DriverBaseClass.GetProp:LogConnections  Procedure()
  Code
  If self._LogConnections then Return '1' Else Return ''.

!-----------------------------------------------------------
DriverBaseClass.SetProp:LogConnections  Procedure(String pValue)
  Code
  self._LogConnections = pValue
  Return

!-----------------------------------------------------------
DriverBaseClass.GetProp:LogData  Procedure()
  Code
  If self._LogData then Return '1' Else Return ''.

!-----------------------------------------------------------
DriverBaseClass.SetProp:LogData  Procedure(String pValue)
  Code
  self._LogData = pValue
  Return

!-----------------------------------------------------------
DriverBaseClass.GetProp:LogExplain  Procedure()
  Code
  If self._LogExplain then Return '1' Else Return ''.

!-----------------------------------------------------------
DriverBaseClass.SetProp:LogExplain  Procedure(String pValue)
  Code
  self._LogExplain = pValue
  Return

!-----------------------------------------------------------
DriverBaseClass.GetProp:LogOptions  Procedure()
  Code
  If self._LogOptions then Return '1' Else Return ''.

!-----------------------------------------------------------
DriverBaseClass.SetProp:LogOptions  Procedure(String pValue)
  Code
  self._LogOptions = pValue
  Return

!-----------------------------------------------------------
DriverBaseClass.GetProp:LogSQL  Procedure()
  Code
  If self._LogSQL then Return '1' Else Return ''.

!-----------------------------------------------------------
DriverBaseClass.SetProp:LogSQL  Procedure(String pValue)
  Code
  self._LogSQL = pValue
  Return

!-----------------------------------------------------------------
DriverBaseClass.GetPROP:Paging           Procedure()
  Code
  If self.Paging then Return '1' Else Return ''.

!-----------------------------------------------------------------
DriverBaseClass.SetPROP:Paging          Procedure(Byte pValue)
  Code
  self.Paging = pValue
  Return

!-----------------------------------------------------------------
DriverBaseClass.GetPROP:NoPrevious       Procedure()
  Code
  If self.NoPrevious then Return '1' Else Return ''.

!-----------------------------------------------------------------
DriverBaseClass.SetPROP:NoPrevious       Procedure(Byte pValue)
  Code
  self.NoPrevious = pValue
  Return

!-----------------------------------------------------------
DriverBaseClass.GetProp:NullString  Procedure()
  Code
  Return self.NullString

!-----------------------------------------------------------
DriverBaseClass.SetProp:NullString  Procedure(String pValue)
  Code
  self.NullString = pValue
  Return

!-----------------------------------------------------------------
DriverBaseClass.GetProp:Offset           PROCEDURE()
  Code
  If self.Offset then Return self.Offset Else Return ''.

!-----------------------------------------------------------------
DriverBaseClass.SetPROP:Offset           PROCEDURE(BIGINT pOffset)
  Code
  self.Offset = pOffset
  Return

!-----------------------------------------------------------------
DriverBaseClass.GetProp:Order             Procedure()
  Code
  If self.Order &= NULL
    Return ''
  End
  Return self.Order

!-----------------------------------------------------------------
DriverBaseClass.SetProp:Order             Procedure(String pValue)
  Code
  self._PropOrderCalled  = True
  If self.Order &= null and pValue = '' then return.
  If self.Order &= null or size(self.Order) < size(pValue) + 1
    Dispose(self.Order)
    self.Order &= new Cstring(size(pValue)+1)
  End
  If self.Order <> clip(pValue)
    self.Order = clip(pValue)
    self._PropsCache += 1
  End
  !self.trace('DriverBaseClass.SetProp:Order self._PropsCache=' & self._PropsCache)
  Return

!-----------------------------------------------------------------
DriverBaseClass.GetProp:OrderBy           Procedure()
  Code
  If self.OrderBy &= NULL
    Return ''
  End
  Return self.OrderBy

!-----------------------------------------------------------------
DriverBaseClass.SetProp:OrderBy          Procedure(String pValue)
  Code
  If self.OrderBy &= null and pValue = '' then return.
  If self.OrderBy &= null or size(self.OrderBy) < size(pValue)  + 1
    Dispose(self.OrderBy)
    self.OrderBy &= new Cstring(size(pValue)+500)
  End
  If self.OrderBy <> clip(pValue)
    self.OrderBy = clip(pValue)
    self._PropsCache += 1
  End
  Return

!-----------------------------------------------------------------
DriverBaseClass.GetProp:QuoteString     PROCEDURE()
  code
  Return self.QuoteString

!-----------------------------------------------------------------
DriverBaseClass.SetProp:QuoteString     PROCEDURE(String pValue)
  code
  self.QuoteString = clip(pValue)
  Return

!-----------------------------------------------------------------
DriverBaseClass.GetPROP:ReadOnly       Procedure()
  Code
  If self.ReadOnly then Return '1' Else Return ''.

!-----------------------------------------------------------------
! if the file is opened in read-only mode, then setting prop:readonly to false will fail. Suggest ReOpen in that case.
DriverBaseClass.SetPROP:ReadOnly       Procedure(Byte pValue)
  Code
  self.ReadOnly = pValue
  Return

!-----------------------------------------------------------------
DriverBaseClass.GETPROP:ResultRecords     Procedure()
  code
  return self.ResultRecords()

!-----------------------------------------------------------------
DriverBaseClass.GETPROP:ResultRow         Procedure()
  code
  Return self.ResultRow()

!-----------------------------------------------------------------
DriverBaseClass.GetProp:Search             Procedure()
  Code
  If self.Search &= NULL
    Return ''
  End
  Return self.Search

!-----------------------------------------------------------------
DriverBaseClass.SetProp:Search             Procedure(String pValue)
  Code
  If self.Search &= null and pValue = '' then return.
  If self.Search &= null or size(self.Search) < size(pValue) + 1
    Dispose(self.Search)
    self.Search &= new Cstring(size(pValue)+1)
  End
  If self.Search <> clip(pValue)
    self.Search = clip(pValue)
  End
  Return

!-----------------------------------------------------------------
DriverBaseClass.GetProp:SearchRank             Procedure()
  Code
  Return self.SearchRank

!-----------------------------------------------------------
DriverBaseClass.GetProp:Separator  Procedure()
  Code
  Return self.Separator

!-----------------------------------------------------------
DriverBaseClass.SetProp:Separator  Procedure(String pValue)
  Code
  self.Separator = pValue
  Return

!-----------------------------------------------------------------
!!! DERIVE
DriverBaseClass.GetProp:Server         Procedure()   ! get the server name out of the connection string
  code
  Return ''

!-----------------------------------------------------------------
DriverBaseClass.GetProp:Sql             Procedure()
  code
  Return self.SqlCode.GetValue()

!-----------------------------------------------------------------
DriverBaseClass.SetProp:Sql            Procedure(String pValue)
  code
  If self.opt:Unsafe
    self.SqlCode.SetValue(pValue)
    self.DoProp:Sql()
  Else
    Self.SetError(FileSystemErr)
    Self.SetFileError(UnsafeSQLErr,'2. Unsafe use of the prop:Sql command. Driver[' & self.GetPROP:Driver() & '] table[' & self.fullpathname & ']')
  End
  Return

!-----------------------------------------------------------------
DriverBaseClass.DoProp:Sql            PROCEDURE()
  Code
  Case self.opt:Unsafe
  of 1 ! allow unsafe commands
    Self.SetError(NoError)
    do ExecuteSql

  of 2 ! post a STOP then continue with the command
    Stop('Unsafe use of the prop:Sql command. Driver[' & self.GetPROP:Driver() & '] table[' & self.fullpathname & ']')
    do ExecuteSql

  Else
    Self.SetError(FileSystemErr)
    Self.SetFileError(UnsafeSQLErr,'Unsafe use of the prop:Sql command. Driver[' & self.GetPROP:Driver() & '] table[' & self.fullpathname & ']')
  End
  Return

ExecuteSql  routine
  ! There may or may not have been a SET. If not there's some housekeeping to do
  If self._HasBeenSet = false
  End
  !
  self._justSet = false
  self.Paging = false
  self._ResultSetDirection = Opcode:NEXT
  self._SetDirection = Opcode:NEXT
  self._HasBeenPropSql = true

  If self._ExecuteSql() = driver:ok
  End

!-----------------------------------------------------------------
!!!Derive
DriverBaseClass._ExecuteSql            PROCEDURE(StringTheory pSQL, <? pParm1>,<? pParm2>,<? pParm3>,<? pParm4>,<? pParm5>,<? pParm6>,<? pParm7>,<? pParm8>,<? pParm9>,<? pParm10>,<? pParm11>,<? pParm12>,<? pParm13>,<? pParm14>,<? pParm15>,<? pParm16>,<? pParm17>,<? pParm18>,<? pParm19>,<? pParm20>)
  Code
  Return Driver:NotOk

!-----------------------------------------------------------------
!!!Derive
DriverBaseClass._ExecuteSql            PROCEDURE()
  Code
  Return Driver:NotOk

!-----------------------------------------------------------------
DriverBaseClass.GetProp:SqlFilter     PROCEDURE()
  code
  If self.sqlFilter &= NULL
    Return ''
  End
  Return self.sqlFilter

!-----------------------------------------------------------------
DriverBaseClass.SetProp:SqlFilter    PROCEDURE(String pValue)
  code
  If self.SqlFilter &= null and pValue = '' then return.
  If self.SqlFilter &= null or size(self.SqlFilter) > size(pValue)
    Dispose(self.SqlFilter)
    self.SqlFilter &= new Cstring(size(pValue)+1)
  End
  If self.SqlFilter <> clip(pValue)
    self.SqlFilter = clip(pValue)
    self._PropsCache += 1
  End
  Return

!-----------------------------------------------------------------
DriverBaseClass.GetProp:SqlOrder     PROCEDURE()
  code
  If self.SqlOrder &= NULL
    Return ''
  End
  Return self.SqlOrder

!-----------------------------------------------------------------
DriverBaseClass.SetProp:SqlOrder    PROCEDURE(String pValue)
  code
  If self.SqlOrder &= null and pValue = '' then return.
  If self.SqlOrder &= null or size(self.SqlOrder) > size(pValue)
    Dispose(self.SqlOrder)
    self.SqlOrder &= new Cstring(size(pValue)+1)
  End
  If self.SqlOrder <> clip(pValue)
    self.SqlOrder = clip(pValue)
    self._PropsCache += 1
  End
  Return

!-----------------------------------------------------------------
!!! DERIVE
DriverBaseClass.GetProp:User         Procedure()   ! get the user name out of the connection string
  code
  return ''

!-----------------------------------------------------------------
DriverBaseClass.GetProp:Where           Procedure()
  Code
  If self.Where &= NULL
    Return ''
  End
  Return self.Where

!-----------------------------------------------------------------
DriverBaseClass.SetProp:Where          Procedure(String pValue)
  Code
  If self.Where &= null and pValue = '' then return.
  If self.Where &= null or size(self.Where) < size(pValue) + 1
    Dispose(self.Where)
    self.Where &= new Cstring(size(pValue)+500)
  End
  If self.Where <> clip(pValue)
    self.Where = clip(pValue)
    self._PropsCache += 1
  End
  Return

!-----------------------------------------------------------------
DriverBaseClass.GetProp:WherePage      Procedure()
  Code
  If self.WherePage &= NULL
    Return ''
  End
  Return self.WherePage

!-----------------------------------------------------------------
DriverBaseClass.SetProp:WherePage     Procedure(String pValue)
  Code
  If self.WherePage &= null and pValue = '' then return.
  If self.WherePage &= null or size(self.WherePage) < size(pValue) + 1
    Dispose(self.WherePage)
    self.WherePage &= new Cstring(size(pValue)+500)
  End
  If self.WherePage <> clip(pValue)
    self.WherePage = clip(pValue)
    self._PropsCache += 1
  End
  Return

!=============================================================================
!  DriverClass
!=============================================================================
!-----------------------------------------------------------------
! Setup Methods
!-----------------------------------------------------------------
DriverFileClass.CONSTRUCT        PROCEDURE()
  Code
  self.keys &= new KeysQueueType
  self.blobs &= new BlobsQueueType
  self.relations &= new RelationsQueueType
  self.state &= new StateQueueType
  self._structure = 'F'
  Return

!-----------------------------------------------------------------
! FileClass Destructs before the base class, and so on.
DriverFileClass.DESTRUCT         PROCEDURE()
  Code
  Self.Close()
  Dispose(self.WatchBuffer)
  Dispose(self.Project)
  Dispose(self._ProjectClauses)
  Dispose(self.ShadowBuffer)
  self.FreeState(0)
  self._FreeKeys()
  self._FreeBlobs()
  Dispose(self.keys)
  Dispose(self.blobs)
  Dispose(self.relations)
  Dispose(self._nullstr)
  If self._logHandle
    osCloseHandle(self._logHandle)
  End
  ! we could dispose the FieldTree here, but only when thread 1 ends. so it's irrelevant.
  ClaDeactivateDriver(address(self.ClaFCB))
  Return

!-----------------------------------------------------------------
DriverFileClass.SETERROR            PROCEDURE(Long pError)
f &File
  Code
  parent.SetError(pError)
  If pError <> NoError
    f &= (self.ClaFCB)
    ClaSetErrorFile(f)
  End
  Return

!-----------------------------------------------------------------
DriverFileClass.SetFileError        PROCEDURE(String pError, String pMessage)
  Code
  if pMessage
    parent.SetFileError(pError, clip(pMessage) & '[' & self.FullPathName & ']')
  else
    parent.SetFileError(pError, '')
  End
  Return

!-----------------------------------------------------------------
! This can be called from inside the thunk (the first time a file is accessed) or
! from program code. If called from program code then it pre-emptivly "binds" that
! file structure to this object.
! If called from the thunk, then an object has already been created, and this is just a courtesy call.
DriverFileClass.INIT             PROCEDURE(File pFile, Long pForce=false)
lFile      long
FileOne    &FILE
FileOneObj &DriverFileClass
Driver     String(32)
Threaded   Byte
Doparse    byte
r          byte
  Code
! Point FILE and object at one another
  If self._Inited = true and pForce = false then return.
  self.LoadLogging()
  self.file &= pFile
  lFile = address(pFile)
  self.ClaFCB  &= (lfile)
  If self.ClaFCB.rblock = 0             ! this is the first object assigned to this file
    self.ClaFCB.rblock = address(self)
  Elsif self.ClaFCB.rblock <> address(self)
    Self.ReplaceObject(self.ClaFCB.rblock)  ! this is replacing the object assigned to the file
  End
  self.recbuf &= (self.ClaFCB.rec_buf) &':' & self.ClaFCB.rec_len
  self.reclen = self.ClaFCB.rec_len

  ! shadow buffer
  self.ShadowBuffer &= New String(self.ClaFCB.rec_len)

  ! if this is the first time the object has been encountered then create unthreaded shared property space
  threaded = choose(band(self.ClaFCB.fil_attr,FILTHRD) > 0, true, false)
  If threaded = false or |                     ! if the file is not threaded, then just make the list if necessary
                 Thread() = 1                       ! this is threaded, but this is thread 1, so just make the list if necessary
    do checkShared
  Else   ! file is threaded, this is not on thread 1
    FileOne &= Instance(self.File,1)
    FileOneObj &= FileOne{prop:object}               ! this triggers the Instance on thread 1 to get INITialised if it hasn't been already.
    do checkShared                                   ! but even then it comes through here, because we're not on thread 1 now
    self.SharedProperties &= FileOneObj.SharedProperties
  End
  ASSERT(not self.SharedProperties &= null,'In DriverFileClass.Init, SharedProperties is null. Thread ' & thread())

! Prime object properties from pFILE
  self._UpdateFileStrings()

  ! first apply System-wide driver string for all files of this driver
  compile('!***',_C100_=1)
  self.Send(System{'Driver:' & self.GetPROP:Driver()})       ! available from Clarion 10.11975 --- October 27, 2015
  !***
  ! Then apply the driver string for this table
  self.Send(self.DriverStr)

  ! this next line is problematic if the full path name is a variable, and it's set before the first table is initialised.
  !     Recommend Calling SetProp:Label instead
  !self.setProp:Label(0,self.FullPathName) ! UPPER of first 8 chars if no FullPathName set.

  self._FreeBlobs()
  self._FreeKeys()

  self._parseBlobs(self.ClaFCB.num_memos)
  self._parseKeys(self.ClaFCB.num_keys)

  If DoParse
    self._parseFields(self.ClaFCB.t_desc)
    self._nullstr &= New String(self.SharedProperties.FieldList.nodes)
    self._nullstr = all('+',size(self._nullstr))
  End
! file attributes
  self.SharedProperties.hasowner = choose(band(self.ClaFCB.fil_attr,FILOWN) > 0, true, false)
  self.SharedProperties.encrypt  = choose(band(self.ClaFCB.fil_attr,FILCRYP) > 0, true, false)
  self.SharedProperties.reclaim  = choose(band(self.ClaFCB.fil_attr,FILRECL) > 0, true, false)
  self.SharedProperties.create   = choose(band(self.ClaFCB.fil_attr,FILCREA) > 0, true, false)
  self.SharedProperties.threaded = choose(band(self.ClaFCB.fil_attr,FILTHRD) > 0, true, false)
  self.SharedProperties.oem      = choose(band(self.ClaFCB.fil_attr,FILOEM) > 0, true, false)
  self.SharedProperties.cdrom    = choose(band(self.ClaFCB.fil_attr,FILCD) > 0, true, false)

  self._optimize()
  self._inited = true
  Return

checkShared  routine
  If self.SharedProperties &= Null
    self.SharedProperties &= new(FilePropertiesType)
    self.SharedProperties.FieldList &= New ListType
    doParse = true
  End

!-----------------------------------------------------------------
! to avoid calling WithField and WithKey excessivly, some properties in those queues are cached in arrays
DriverFileClass._Optimize   Procedure()
x          long,Auto
  code
  If self._WithPrimaryKey() = Driver:ok
    self.SharedProperties._PKcomponents = self.keys.components
    Loop x = 1 to self.keys.components
      If self._WithField(self.keys.component[x]) = Driver:ok
        self.SharedProperties._PKcomponentOffset[x] = self.Fields.Offset
        self.SharedProperties._PKcomponentLength[x] = self.Fields.Length
      End
      If x = Maximum(self.SharedProperties._PKcomponentOffset,1) then break.
    End
  End
  Return

!-----------------------------------------------------------------
! In derived classes derive this method with this exact same code, but
! replace the declaration of old with your class name. DO NOT call the parent class.
DriverFileClass.ReplaceObject          PROCEDURE(Long pOldObjectAddress)
old    &DriverFileClass,Auto
  Code
  If pOldObjectAddress <> 0
    old &= (pOldObjectAddress)
    self :=: old
    dispose(old)
  End
  self.ClaFCB.rblock = address(self)
  Return

!-----------------------------------------------------------------
DriverFileClass._CallFunctionCalled PROCEDURE()!,LONG,VIRTUAL
  Code
  Return true

!-----------------------------------------------------------------
DriverFileClass._CallFunctionDone   PROCEDURE()!,LONG,VIRTUAL
  Code
  Return true

!-----------------------------------------------------------------
DriverFileClass._CallExecutingCode PROCEDURE()!,LONG,VIRTUAL
  Code
  Return true

!-----------------------------------------------------------------
DriverFileClass._WithFieldLabeled  Procedure(String pLabel)
cs cString(size(pLabel)+1),auto
  code
  cs = clip(pLabel)
  Return self._WithFieldLabeled(cs)

!-----------------------------------------------------------------
DriverFileClass._WithFieldLabeled  Procedure(*cString pLabel)
node  &FieldGroupType,auto
x     Long,auto
  code
  Loop x = 1 to self.SharedProperties.FieldList.nodes
    node &= self._withFieldNode(x)
    If upper(node.Label) = upper(pLabel)
      self.Fields &= node
      Return driver:ok
    End
  End
  Return Driver:notok

!-----------------------------------------------------------------
DriverFileClass._WithFieldNamed  Procedure(String pName)
cs cString(size(pName)+1),auto
  code
  cs = clip(pName)
  Return self._WithFieldNamed(cs)

!-----------------------------------------------------------------
DriverFileClass._WithFieldNamed  Procedure(*cString pName)
node  &FieldGroupType,auto
cstr  cstring(size(pName)),auto
x     long
  code
  If size(pName) = 0 then return Driver:Notok.
  cstr = upper(pName)
  Loop x = 1 to self.SharedProperties.FieldList.nodes
    node &= self._withFieldNode(x)
    If node.UpperColumn = cstr
      self.Fields &= node
      Return driver:ok
    End
  End
  Return Driver:notok

!-----------------------------------------------------------------
! Checks the fieldsqueue to see if there's a field with that offset.
! if there is then that field is loaded.
DriverFileClass._WithFieldOffset  Procedure(Long pOffset,Long pSize)
x     long,auto
node  &FieldGroupType ,auto
  code
  Loop x = 1 to self.SharedProperties.FieldList.nodes
    node &= self._withFieldNode(x)
    If node.Type = ClaGroup then cycle.
    If node.Offset = pOffset
      self.Fields &= node
      Return driver:ok
    End
  End
  Return Driver:notok

!-----------------------------------------------------------------
DriverFileClass._WithField   Procedure(Long pIndex)
  Code
  self.Fields &= self._WithFieldNode(pIndex)
  If self.Fields &= null
    Return Driver:notok
  End
  Return Driver:ok

!-----------------------------------------------------------------
DriverFileClass._WithFieldPtr            Procedure(*? pField)
ptr     Long
offset  Long
  Code
  Peek(address(pField)+4,ptr)
  If ptr >= self.ClaFCB.rec_buf and ptr <= self.ClaFCB.rec_buf + self.ClaFCB.rec_len
    offset = ptr - self.ClaFCB.rec_buf
    If self._WithFieldOffset(offset,0) = driver:ok
      Return driver:ok
    else
      self.SetError(BadFieldErr)
    End
  Else
    self.SetError(BadFieldErr)
  End
  Return Driver:NotOk

!-----------------------------------------------------------------
! Fields queue record already loaded
DriverFileClass._FieldIsBlank      Procedure()
  code
  Case self.Fields.Type
  of ClaSTRING
    Return self._memchk(self.ClaFCB.rec_buf + self.Fields.Offset,32,self.Fields.Length)
  of ClaCSTRING
  orof ClaPSTRING
    Return self._memchk(self.ClaFCB.rec_buf + self.Fields.Offset,0,1)
  End
  Return self._memchk(self.ClaFCB.rec_buf + self.Fields.Offset,0,self.Fields.Length)

!-----------------------------------------------------------------
! loads an entry from the Keys queue, based on the KeyPtr
DriverFileClass._withKey  Procedure(*Key pKey)
  code
  If self.keys.keyptr = address(pKey) then Return driver:ok.
  self.keys.keyptr = address(pKey)
  Get(self.keys,self.keys.keyptr)
  If errorcode() = 0 then return driver:ok.
  Return errorcode()

!-----------------------------------------------------------------
! loads an entry from the Keys queue, based on the index
DriverFileClass._withKey  Procedure(Long pIndex)
  code
  self.keys.index = pIndex
  Get(self.keys,self.keys.index)
  If errorcode() = 0 then return driver:ok.
  Return errorcode()

!-----------------------------------------------------------------
! Primary keys are defined as having the ,PRIMARY set to true.
! However in the absence of that, the first Unique key will do.
DriverFileClass._withPrimaryKey  Procedure()
  code
  If self.keys.primary Then Return driver:ok.
  self.keys.primary = true
  Get(self.keys,self.keys.primary)
  If errorcode() = 0 Then Return driver:ok.
  self.keys.dup = false
  Get(self.keys,self.keys.dup)
  If errorcode() = 0 Then Return driver:ok.
  self.keys.primary = false
  Return driver:notok

!-----------------------------------------------------------------
DriverFileClass._WithBlobLabel  Procedure(*cString pLabel)
e  long,auto
  code
  e = ErrorCode()
  self.blobs.label = upper(pLabel)
  Get(self.blobs,self.blobs.label)
  If Errorcode()
    self.SetError(e)
    Return Driver:notok
  End
  self.SetError(e)
  Return Driver:ok

!-----------------------------------------------------------------
DriverFileClass._WithBlobNamed  Procedure(String pName)
cs cString(size(pName)+1),auto
  code
  cs = clip(pName)
  Return self._WithBlobNamed(cs)

!-----------------------------------------------------------------
DriverFileClass._WithBlobNamed  Procedure(*cString pName)
e  long,auto
  code
  e = ErrorCode()
  self.blobs.UpperColumn = upper(pName)
  Get(self.blobs,self.blobs.UpperColumn)
  If Errorcode()
    self.SetError(e)
    Return Driver:notok
  End
  self.SetError(e)
  Return Driver:ok

!-----------------------------------------------------------------
! can take pIndex as either a positive or negative value.
! gets the record for a blob or memo from the self.blobs queue
DriverFileClass._WithBlob  Procedure(Long pIndex)
e  Long,auto
  Code
  e = ErrorCode()
  if pIndex = 0 then return driver:notok.
  If self.blobs.index = abs(pIndex) then return Driver:ok.
  self.blobs.index = abs(pIndex)
  Get(self.blobs,self.blobs.index)
  If Errorcode()
    self.trace('Blob index not found ' & pIndex)
    self.blobs.index = 0
    self.SetError(e)
    Return Driver:notok
  End
  self.SetError(e)
  Return Driver:ok

!-----------------------------------------------------------------
! need to write this address back into the FCB
DriverFileClass._writeHandle  Procedure()
addr         &long,auto
addrNew      long,auto
addrF        long,auto
  code
  addr &= (self.ClaFCB.m_desc)
  AddrNew = self.blobs.handle                            ! for GMEM_FIXED objects the handle doubles as a pointer.
  AddrF = addr + (self.blobs.index-1) * size(Cla_MEMODESC) + 16
  Poke(addrF,AddrNew)
  Return

!-----------------------------------------------------------------
! assumes a (self.blobs) blob queue record is loaded. Assume the caller will ADD or PUT the self.blobs queue.
! called from INIT
DriverFileClass._newMemoMemory  Procedure(Long pNewSize)
addr         &long,auto
addrNew      long,auto
addrF        long,auto
  code
  addr &= (self.ClaFCB.m_desc)
  dispose(self.blobs.memostring)
  self.blobs.memostring &= NEW String(pNewSize)
  ! need to write this address back into the FCB
  AddrNew = address(self.blobs.memostring)
  AddrF = addr + (self.blobs.index-1) * size(Cla_MEMODESC) + 16
  Poke(addrF,AddrNew)

!-----------------------------------------------------------------
! Parsing FCBLK Parameter Methods
!-----------------------------------------------------------------
DriverFileClass._parseBlobs    Procedure(Byte pIndex)
addr         &long,auto
DescRam      Group(Cla_MEMODESC),dim(255),Auto
             End
Desc         like(Cla_MEMODESC),Auto
x            long,Auto
column       cstring(254),Auto
p            long,Auto

  code
  self._NumMemos = 0
  self._NumBlobs = 0
  addr &= (self.ClaFCB.m_desc)
  MemCpy(address(descram),addr,size(Cla_MEMODESC)*pIndex) ! ideally we'd read addr directly, but it's not so easy to create a &group,dim(x)
  Loop x = 1 to pIndex
    desc =  descram[x]
    clear(self.blobs)
    self.blobs.index = x   ! self.blobs.index is a positive number
    self.blobs.name  = self._GetString(desc.memo_name)  ! Contents of the MEMOs NAME() attribute, or '' if there is no NAME() attribute.
    self.blobs.label = self._GetString(desc.memo_label)
    if self.blobs.name
      p = Instring('|',self.blobs.Name,1,1)
      If p = 0
        column = self.blobs.Name
      Else
        column = clip(sub(self.blobs.Name,1,p-1))
      End
    Else
      column = self.blobs.Label
      p = instring(':',column,1,1)
      If p
        column = clip(sub(column,p+1,254))
      End
    End
    self.blobs.column = self.TranslateReserved(column)
    self.blobs.upperColumn = upper(self.UnwrapReserved(column))
    self.blobs.memo  = Choose(band(desc.memo_attr,Cla_Blob)=Cla_Memo,true,false)   ! looks weird, but is correct here
    self.blobs.binary = Choose(band(desc.memo_attr,Cla_Binary)=Cla_Binary,true,false)
    self.blobs.memosize   = desc.memo_size
    if self.blobs.memo
      self._NumMemos += 1
    else
      self._NumBlobs += 1
    end
    If desc.memo_data = 0
      If self.blobs.memo and self.blobs.memosize
        self._newMemoMemory(self.blobs.memosize)
      End
    Else
      self.blobs.handle = desc.memo_data
      self.blobs.handlesize = osGlobalSize(self.blobs.handle)
    End
    ! extended name attributes
    self._parseBlobNameAttributes()
    Add(self.blobs)
  End
  Return

!-----------------------------------------------------------------
DriverFileClass._parseKeys    Procedure(Byte pIndex)
addr         &long
DescRam      Group(Cla_KEYDESC),dim(255)
             End
Desc         like(Cla_KEYDESC)
x            long
y            long
p            long
dbName       pString(254)  ! the name, as it is in the database. If from the label then prefix is included with _

  code
  addr &= (self.ClaFCB.k_desc)
  MemCpy(address(descram),addr,size(Cla_KEYDESC)*pIndex)
  Loop x = 1 to pIndex
    clear(self.keys)
    self.keys.index = x
    self.keys.keyptr = addr + (x-1) * size(Cla_KEYDESC)
    desc =  descram[x]
    dbname = ''
    self.keys.name  = self._GetString(desc.pname)  ! Contents of the KEYs NAME() attribute, or '' if there is no NAME() attribute.
    self.keys.label = self._GetString(desc.lname)
    If self.keys.name
      p = Instring('|',self.keys.Name,1,1)
      If p = 0
        dbName = self.keys.Name
      Else
        self._parseKeyNameAttributes()
        dbName = clip(sub(self.keys.Name,1,p-1))
      End
    end
    If dbname = ''
      dbName = self.keys.Label
      p = instring(':',dbName,1,1)
      If p
        dbName = sub(dbname,p+1,255)
      End
    End
    self.keys.dbName = dbName

    self.keys.dup = Choose(band(desc.key_attr,Cla_Dup)=Cla_Dup,true,false)
    self.keys.opt = Choose(band(desc.key_attr,Cla_Opt)=Cla_Opt,true,false)
    self.keys.nocase = Choose(band(desc.key_attr,Cla_NoCase)=Cla_NoCase,true,false)
    If band(desc.key_attr,Cla_Primary) = Cla_Primary
      self.primarykey &= (self.keys.keyptr)
      self.keys.primary = true
    End
    self.keys.components = desc.num_comps
    If band(desc.key_attr, Cla_DynIndex) or self.keys.components = 0
      self.keys.type = Cla_DynIndex
    Elsif band(desc.key_attr, Cla_Index)
      self.keys.type = Cla_Index
    Else
      self.keys.type = Cla_Key
    End
    If self.keys.type = Cla_Key and self.keys.primary then self.SharedProperties._PrimaryKeyIndex = x.

    MemCpy(address(self.keys.component),desc.comps,self.keys.components * 4)
    loop y = 1 to self.keys.components
      if self.keys.component[y] < 0
        self.keys.descending[y] = 1
        self.keys.component[y] = abs(self.keys.component[y])
      end
    end
    !self.trace('KEY: ' & self.keys.index & ' label=[' & self.keys.label & '] Name=' & self.keys.name & ' dup=' & self.keys.dup & ' opt=' & self.keys.opt & ' nocase=' & self.keys.nocase  & ' primary=' & self.keys.primary & ' components=' & self.keys.components & '(' & self.keys.component[1] & ','  & self.keys.component[2] & ',' & self.keys.component[3] & ',' & self.keys.component[4] & ',' & self.keys.component[5] &') type=' & self.keys.type & ' ptr=' & self.keys.keyptr)
    Add(Self.Keys)
  End
  Return

!-----------------------------------------------------------------
! the prop:order has been tokenised, but that needs to now be expanded, and added to the OrderByQueue
! This method is called by AddTokensToOrderBy for tokens that are marked as labels.
! if the field is already in the order, then the index of the already field is returned.
! If the field is added to the order, then it returns 0.
DriverFileClass._FillOrderFromLabel              Procedure(String pLabel, Byte pCase)
column     cstring(255)
LabelType  byte
  code
  column = clip(pLabel)
  self._NoAlias = true
  column = self.TranslateLabel(column,LabelType)
  self._NoAlias = false
  case LabelType
  of driver:field
    If self._WithFieldNamed(column) = driver:ok   ! Ordering by a table field
      self.OrderQueue.FieldIndex = self.Fields.index
      Get(self.OrderQueue,self.OrderQueue.FieldIndex)
      If Errorcode() = 0
        Return Pointer(self.OrderQueue)
      End
      If not self._ProjectClauses &= null and self._ProjectClauses.InString(' AS ' & self.Fields.Column) > 0
        self.OrderQueue.Clause = self.Fields.Column
      Else
        self.OrderQueue.Clause = self._GetAlias(driver:withdot) & self.Fields.Column
      End
      Case self.Fields.type
      of ClaCSTRING orof ClaPSTRING orof ClaSTRING
        If self.Fields.Binary
          self.OrderQueue.Nocase = false
        Else
          self.OrderQueue.Nocase = pCase
        End
      Else
        self.OrderQueue.Nocase = false
      End
      self.OrderQueue.IsCalc     = false
      self.OrderQueue.FileIndex  = 1
      self.OrderQueue.FieldIndex = self.Fields.index
    End
  of driver:bindfield                                                       ! Ordering by a calculated field called BindQueue.Name
    self.OrderQueue.FieldIndex = -Pointer(self.BindQueue)
    Get(self.OrderQueue,self.OrderQueue.FieldIndex)
    If Errorcode() = 0
      Return Pointer(self.OrderQueue)
    End
    self.OrderQueue.Clause     = column
    self.OrderQueue.Nocase = pCase
    self.OrderQueue.IsCalc     = false
    self.OrderQueue.FileIndex  = -1
    self.OrderQueue.FieldIndex = -Pointer(self.BindQueue)
  Else
    ! Invalid label in OrderBy clause
  End
  Return 0

!-----------------------------------------------------------------
! Numbers are stored in the field descriptor as variable length using 1, 2, 3 or 4 bytes
DriverFileClass._GetVariableLengthNumber  Procedure(*Long pAddr,*byte pHighbit)
b        byte
lg       long
ush      ushort
  code
  peek(pAddr,b)                                                ! not incrementing pAddr here.
  !self.trace('     gvln start pAddr=' & pAddr & ' b=' & b)
  If band(b,128) > 0
    pHighbit = true
    b = band(b,127)
  else
    pHighbit = false
  End
  lg = b
  If band(b,64+32) = 64+32                                     ! both bits are set, so next 3 bytes are used
    peek(pAddr,lg)                                             !4,194,304 is the max the compiler will allow
    pAddr += 4
    lg = band(lg,0FFFFFFh)                                     ! low 3 bytes of the long - ie remove the high byte
  Elsif band(b,64) > 0                                         ! 64 bit is set, so read next 2 bytes as a short
    pAddr += 1                                                 ! add the 1 for the peek at the top of this procedure
    peek(pAddr,ush)
    pAddr += 2
    lg = (band(lg,31) * 65536) + ush                           ! max 2,031,616 + sh
  Elsif band(b,32) > 0                                         ! 32 bit is set, so read next 1 byte and use low 5 bits of the first byte
    pAddr += 1                                                 ! add the 1 for the peek at the top of this procedure
    peek(pAddr,b)
    pAddr += 1
    lg = band(lg,31) * 256 + b                                 ! max 7936 + b
  Else
    pAddr += 1                                                 ! add the 1 for the peek at the top of this procedure
  End
  !self.trace('     gvln end pAddr=' & pAddr)
  Return lg

!-----------------------------------------------------------------
! Strings in the Field Descriptor are stored as null terminated strings inline, with no fixed length.
DriverFileClass._GetVariableLengthString  Procedure(*Long pAddr)
b  byte
s  string(255)
x  long
  code
  Loop
    Peek(pAddr,b)
    pAddr += 1
    If b = 0 then break.
    x += 1
    s[x] = chr(b)
  End
  If x = 0 then return ''.
  Return s[1:x]

!-----------------------------------------------------------------
DriverFileClass._withFieldNode  Procedure(Long pIndex)
nodeptr  long,auto
node     &FieldGroupType!,Auto
  code
  pIndex = abs(pIndex)
  If pIndex < 1 or pIndex > self.SharedProperties.FieldList.nodes
    return Node
  End
  Peek(address(self.SharedProperties.FieldList.nodelist) + ((pIndex-1) * 4),NodePtr)  ! nodelist is a dynamic array of longs
  If NodePtr = 0
    node &= new(FieldGroupType)
    nodeptr = address(node)
    poke(address(self.SharedProperties.FieldList.nodelist) + ((pIndex-1) * 4),NodePtr)
  Else
    node &= (NodePtr)
  End
  Return Node

!-----------------------------------------------------------------
! pAddr is the address of tdesc in the ClaFCB.
DriverFileClass._parseFields    Procedure(Long pAddr)
index           Long
node            &FieldGroupType
type            Byte
attribute       Byte
lgSize          Long
lgGroupFields   Long
lgGroupDef      Long
  Code
  self.SharedProperties.FieldList  &= new(ListType)
  peek(pAddr + 6 , self.SharedProperties.FieldList.Nodes)
  self.SharedProperties.FieldList.nodelist &= new String(self.SharedProperties.FieldList.Nodes*4)
  memset(address(self.SharedProperties.FieldList.nodelist),0,self.SharedProperties.FieldList.Nodes*4)

  ! read the outer group setting (aka the RECORD). Don't want to add this as a node.
  peek(pAddr,type)
  pAddr += 1
  peek(pAddr,Attribute)
  pAddr += 1
  Case type
  of ClaGROUP
     peek(pAddr,lgSize)
     pAddr += 4
     peek(pAddr,lgGroupFields)  ! number of fields in the group, including child groups and all their fields.
     pAddr += 4
     peek(pAddr,lgGroupDef)
     pAddr += 4
  End
  self._parseFieldsWalker(pAddr,lgGroupFields,index,0,0,0,1) ! The number of fields is 1, cause this is the group record, which is just 1 field.

  Loop index = 1 to self.SharedProperties.FieldList.nodes - 3
    node &= self._withFieldNode(index)
    !node.SqlTimeStamp = false
    ! check for magic Clarion OVER DateTime
    If node.Type <> ClaSTRING or node.Length <> 8 or node.Over then cycle.
    node &= self._withFieldNode(index+1)
    If node.Type <> ClaGROUP or node.Length <> 8 or node.Over <> index then cycle.
    node &= self._withFieldNode(index+2)
    If node.Type <> ClaDATE then cycle.
    node &= self._withFieldNode(index+3)
    If node.Type <> ClaTIME then cycle.
    node &= self._withFieldNode(index)
    node.SqlTimeStamp = driver:GroupOverTimeStamp
  End
  self._AfterParseFields()
  Return

!-----------------------------------------------------------------
DriverFileClass._AfterParseFields        Procedure()
  code
  Return

!-----------------------------------------------------------------
DriverFileClass._parseFieldsWalker    Procedure(*Long pAddr,Long pFields,*Long pIndex,Long pLastRealOffSet, Long pLastRealLength,Long pInOveredGroup,Long pLevel)
b               Byte
HighBit         Byte
HighBit2        Byte
c               Long
maybeTimeStamp  Long
pNode           &FieldGroupType
EarlierNode     &FieldGroupType
FieldsCounter   Long
InOveredGroup   Long
  code
  !self.trace(' _parseFieldsWalker ' & pFields & ' index=' & pIndex & ' pLastRealOffSet=' & pLastRealOffSet & ' pLastRealLength=' & pLastRealLength)
  Loop
    FieldsCounter += 1
    if FieldsCounter > pFields then break.
    pIndex += 1
    pNode &= self._withFieldNode(pIndex)
    !self.trace('index = ' & pIndex)
    pNode.Index = pIndex
    pNode.Level = pLevel
    pNode.InOverGroup = pInOveredGroup
    pNode.SqlTimeStamp = false
    peek(pAddr,pNode.type)
    pAddr += 1
    peek(pAddr,pNode.Attribute)
    pAddr += 1
    !str.trace('index=' & pIndex & ' type=' &  pNode.type & ' attr=' & pNode.Attribute)
    Case pNode.type
    of ClaGROUP
       peek(pAddr,pNode.Size)
       pAddr += 4
       peek(pAddr,pNode.GroupFields)  ! number of fields in the group, including child groups and all their fields.
       pAddr += 4
       peek(pAddr,pNode.GroupDef)
       pAddr += 4
       !pNode.Children &= new String(pnode.GroupFields * 4)  ! assign space for an array of &nodes
    of ClaBYTE
      pNode.Size = 1
    of ClaSHORT orof ClaUSHORT
      pNode.Size = 2
    of ClaDATE orof ClaTIME orof ClaLONG orof ClaULONG orof ClaSREAL orof ClaBFLOAT4
      pNode.Size = 4
    of ClaREAL orof ClaBFLOAT8
      pNode.Size = 8
    of ClaDECIMAL orof ClaPDECIMAL
      peek(pAddr,b)
      pAddr += 1
      pNode.Size = b
      pNode.DecimalSize = pNode.Size * 2 - 1 ! digits
      peek(pAddr,pNode.DecimalPlaces)
      pAddr += 1
    of ClaSTRING orof ClaPSTRING orof ClaCSTRING
      pNode.Size = self._GetVariableLengthNumber(pAddr,HighBit)
    of CLAReference
      pNode.ref = true
      !peek(pAddr,pNode.Type)
      !pAddr += 1
      pNode.Size = 4
    End
    pNode.Picture = ''
    If Band(pNode.Attribute,ClaAttrPic)
      pNode.Picture = '@'  & self._GetVariableLengthString(pAddr)
    End
    pNode.Label = ''
    If Band(pNode.Attribute,ClaAttrLabel)
      pNode.Label = self._GetVariableLengthString(pAddr)  ! label inline in the structure at this point
    End
    pNode.Name = ''
    If Band(pNode.Attribute,ClaAttrName)
      pNode.Name = self._GetVariableLengthString(pAddr)
    End

    pNode.Over = 0
    HighBit = 0
    If Band(pNode.Attribute,ClaAttrOver)
      pNode.Over = self._GetVariableLengthNumber(pAddr,HighBit)   ! over is a relative number of bytes backwards in the record
    End

    ! Array Support
    pNode.Dims = 0                                  ! assume not an array
    pNode.DimProduct = 1
    pNode.Length = pNode.Size
    Clear(pNode.Dim)
    If band(pNode.Attribute,ClaAttrDim)             ! it is an array
      Peek(pAddr,pNode.Dims)                        ! number of dimensions
      pAddr += 1
      !self.trace('pNode.Dims=' & pNode.Dims & ' max=' & maximum(pNode.dim,1) & ' attr=' & pNode.Attribute)
      Loop c = 1 to pNode.Dims
        If c <= maximum(pNode.dim,1)
          pNode.Dim[c] = self._GetVariableLengthNumber(pAddr,HighBit2)
          pNode.Length *= pNode.Dim[c]              ! working out the memory used by the field, allowing for all array space
          pNode.DimProduct *= pNode.Dim[c]          ! working out the product of all the dimensions
        End
      End
    End
    If Band(pNode.Attribute,ClaAttrOver) = 0 or HighBit = 0   ! this is a real field.
      pNode.Offset = pLastRealOffSet + pLastRealLength
      pLastRealOffSet = pNode.Offset
      pLastRealLength = pNode.Length
      pNode.Over = 0
    ElsIf HighBit                                                    ! this is an overed field, and over holds a relative
      pNode.Offset = pLastRealOffSet + pLastRealLength - pNode.Over  ! position, so calculate the field number, and set the offset.
      pNode.Over = -1
      Loop c = pIndex - 1 to 1 by -1
        EarlierNode &= self._withFieldNode(c)
        If EarlierNode.Level < pNode.Level then break.
        If EarlierNode.Over then cycle.
        If earlierNode.Offset = pNode.Offset
          pNode.Over = earlierNode.Index
          break
        End
      End
    End
    self._parseFieldsB(pNode)

    Case pNode.type
    Of ClaGROUP
      If pInOveredGroup
        InOveredGroup = pInOveredGroup
      ElsIf pNode.Over
        InOveredGroup = pNode.Index
      End
      self._parseFieldsWalker(pAddr,pNode.GroupFields,pIndex,pLastRealOffSet,0,InOveredGroup,pLevel+1)
      FieldsCounter += pNode.GroupFields
    End
    InOveredGroup = pInOveredGroup
  End
  Return

!-----------------------------------------------------------------
! there are additional things we can deduce from the field descriptor, and cache these
! for use later on.
DriverFileClass._parseFieldsB    Procedure(FieldGroupType pNode)
p         long
column    cstring(254)
  code
  ! set the file prefix from the label
  If self.SharedProperties.Prefix = ''
    p = instring(':',pNode.label,1,1)
    If p > 1
      self.SharedProperties.prefix = sub(pNode.label,1,p-1)
    End
  End

  ! Set Column from name
  If band(pNode.Attribute,ClaAttrName)
    p = Instring('|',pNode.Name,1,1)
    If p <= 1
      column = pNode.Name
    Else
      column = clip(sub(pNode.Name,1,p-1))
      If column = ''
        column = pNode.Name
      End
    End
    pNode.column = self.TranslateReserved(column)
  Else
    column = clip(pNode.Label)
    p = instring(':',column,1,1)
    If p
      column = clip(sub(column,p+1,254))
    End
    pNode.column = self.TranslateReserved(column)
    pNode.name = upper(column)
  End
  pNode.upperColumn = upper(self.UnwrapReserved(column))

  ! Extended Name Attributes
  self._parseFieldNameAttributes(pNode)

  ! Is this field in the primary key?
  If self._FieldInPrimaryKey(pNode.Index)
    pNode.Primary = true
  Else
    pNode.Primary = false
  End

  ! Is this field a string type, and also in any nocase key?
  pNode.InCase = 255
  case pNode.Type
  of ClaSTRING
  orof ClaPSTRING
  orof ClaCSTRING
    If self._FieldInCaseKey(pNode.Index)
      pNode.InCase = 1
    ElsIf self._FieldInNoCaseKey(pNode.Index)
      pNode.InCase = 0
    End
  End
  Return

!-----------------------------------------------------------------
DriverFileClass._parseKeyNameAttributes    Procedure()
str  StringTheory
x    Long
  Code
  str.setvalue(self.keys.name,st:clip)
  str.Split('|')
  Loop x = 2 to str.records()
    !str.trace('[' & str.GetLine(x) & ']')
    Case upper(clip(left(str.GetLine(x))))
    Of 'CLUSTER'
    Orof 'CLUSTERED'
      self.keys.cluster = true
    End
  End
  Return

!-----------------------------------------------------------------
DriverFileClass._parseBlobNameAttributes    Procedure()
c            long,auto
d            long,auto
e            long,auto
attribute    pstring(25),Auto
val          pstring(250),Auto
ThisTypeSet  Byte,Auto
  Code
  If instring('|',self.blobs.name,1,1)
    c = 0
    loop
      c = instring('|',self.blobs.name,1,c+1)
      if c = 0 then break.
      d = instring('|',self.blobs.name,1,c)
      if d = 0 then d = len(clip(self.blobs.name))+1.
      attribute = left(clip(sub(self.blobs.name,c+1,d-c-1)))
      e =  instring('=',attribute,1,1)
      if e = 0 then e = instring('(',attribute,1,1).
      val = ''
      if e
        val = sub(attribute,e+1,len(clip(attribute)))
        if right(val,1) = ')' then val = sub(val,1,len(clip(val))-1).
        attribute = sub(attribute,1,e-1)
      end
      case upper(attribute)
      of 'BINARY'
        self.blobs.Binary = true
      of 'CHECKFORNULL'
      orof 'CHECK FOR NULL'
        self.blobs.CheckForNull = true
      of 'COLLATE'
        self.blobs.collate = val
      of 'DEFAULT'
        self.blobs.HasDefault = true
        self.blobs.DefaultValue = val
      of 'NOTNULL'
      orof 'NOT NULL'
        self.blobs.NotNull = true
      of 'NOWHERE'
      orof 'NO WHERE'
        self.blobs.NoWhere = true
      of 'READONLY'
      orof 'READ ONLY'
        self.blobs.ReadOnly = true
      of 'SELECTNAME'
        self.blobs.selectname = val
      of 'UPDATENAME'
        self.blobs.updatename = val
      of 'INSERTNAME'
        self.blobs.insertname = val
      of 'SQLTYPE'
        If ThisTypeSet = false
          self.blobs.SqlType = val
        End
      of self._ThisSqlType
        ThisTypeSet = true
        self.blobs.SqlType = val
      of 'WATCH'
        self.SharedProperties._haswatch = true
        self.blobs.Watch = true
      End
    End
  End

!-----------------------------------------------------------------
DriverFileClass._parseFieldNameAttributes    Procedure(FieldGroupType pNode)
c            long,auto
d            long,auto
e            long,auto
f            long,auto
attribute    pstring(250),auto
val          pstring(250),auto
ThisTypeSet  Byte
str          StringTheory

  Code
  ! extended name attributes
  If instring('|',pNode.name,1,1)
    c = 0
    loop
      c = instring('|',pNode.name,1,c+1)
      if c = 0 then break.
      d = instring('|',pNode.name,1,c+1)
      if d = 0 then d = len(clip(pNode.name))+1.
      attribute = clip(left(sub(pNode.name,c+1,d-c-1)))
      case sub(attribute,1,1)
      of '<'
        If sub(attribute,2,1) = '>'
          ! defer processing to next case statement
        Else
          Dispose(pNode.LessThan)
          pNode.LessThan &= new String(len(attribute))
          pNode.LessThan = attribute
          cycle
        End
      of '>'
        Dispose(pNode.GreaterThan)
        pNode.GreaterThan &= new String(len(attribute))
        pNode.GreaterThan = attribute
        cycle
      end
      Case sub(attribute,1,2)
      of '<<>'
      orof '~='
      orof '!='
        Dispose(pNode.NotEqual)
        If sub(attribute,3,10) = ''
          case pNode.Type
          of ClaSTRING
          orof ClaPSTRING
          orof ClaCSTRING
            pNode.NotEqual &= new String(5)
            pNode.NotEqual = '<<> '''''
          Else
            pNode.NotEqual &= new String(4)
            pNode.NotEqual = '<<> 0'
          End
        Else
          pNode.NotEqual &= new String(len(attribute))
          attribute[1:2] = '<<>'
          pNode.NotEqual = attribute
        End
        Cycle
      End
      e = instring('=',attribute,1,1)
      f = instring('(',attribute,1,1)
      If e and (e < f or f=0)
        val = sub(attribute,e+1,len(clip(attribute)))
        attribute = clip(left(sub(attribute,1,e-1)))
      elsif f
        val = sub(attribute,f+1,len(clip(attribute)))
        if right(val,1) = ')' then val = sub(val,1,len(clip(val))-1).
        attribute = clip(left(sub(attribute,1,f-1)))
      end
      case upper(attribute)
      of 'BINARY'
        pNode.Binary = true
      of 'BOOLEAN'
        pNode.Boolean = true
      of 'CHECKFORNULL'
        pNode.CheckForNull = true   !!!todo support checkfornull
      of 'DEFAULT'
        pNode.HasDefault = true
        pNode.DefaultValue = val
      of 'INLIST'
        Dispose(pNode.InList)
        case pNode.Type
        of ClaSTRING
        orof ClaPSTRING
        orof ClaCSTRING
          str.setvalue(val)
          str.split(',')
          str.Join(',','''','''',true)
          val = str.GetValue()
        end
        pNode.InList &= new String(len(val))
        pNode.InList = val
      of 'ISIDENTITY'
        self.SharedProperties.HasIdentity = pNode.index
        pNode.IsIdentity = true
      of 'NOTNULL'
      orof 'NOT NULL'
        pNode.NotNull = true
      of 'NOWHERE'                       !!!todo support nowhere
        pNode.NoWhere = true
      of 'READONLY'
        pNode.ReadOnly = true
      of 'REQ'
        pNode.NotNull = true
        Dispose(pNode.NotEqual)
          case pNode.Type
          of ClaSTRING
          orof ClaPSTRING
          orof ClaCSTRING
            pNode.NotEqual &= new String(5)
            pNode.NotEqual = '<<> '''''
          Else
            pNode.NotEqual &= new String(4)
            pNode.NotEqual = '<<> 0'
          End
      of 'SELECTNAME'
        pNode.selectname = val
      of 'UPDATENAME'
        pNode.updatename = val
      of 'INSERTNAME'
        pNode.insertname = val
      of 'SQLTYPE'
        If ThisTypeSet = false
          pNode.SqlType = val
          self._ParseFieldSQLType(pNode)
        End
      of self._ThisSqlType
        ThisTypeSet = true
        pNode.SqlType = val
        self._ParseFieldSQLType(pNode)
      of 'COLLATE'
        pNode.collate = val
      of 'UUID4'
        If (pNode.Type = ClaSTRING and pNode.length >= 16) or |
           (pNode.Type = ClaPSTRING and pNode.length >= 17)
          pNode.uuid = 4
          self.SharedProperties.hasUUID = pNode.index
          self.SharedProperties.HasUUIDs += 1
          pNode.Binary = true
        Else
          self.trace('ERROR: Field type not compatible with UUID4. Use STRING(16) or PSTRING(17). ' & pNode.Name)
        End
      of 'UUID7'
        If (pNode.Type = ClaSTRING and pNode.length >= 16) or |
           (pNode.Type = ClaPSTRING and pNode.length >= 17)
          pNode.uuid = 7
          self.SharedProperties.hasUUID = pNode.index
          self.SharedProperties.HasUUIDs += 1
          pNode.Binary = true
        Else
          self.trace('ERROR: Field type not compatible with UUID7. Use STRING(16) or PSTRING(17). ' & pNode.Name)
        End
      of 'UUID8'
      orof 'UUID'
        Case pNode.Type
        Of ClaSTRING
        Orof ClaPSTRING
        Orof ClaCSTRING
          pNode.uuid = 8
          self.SharedProperties.hasUUID = pNode.index
          self.SharedProperties.HasUUIDs += 1
        Else
          self.trace('ERROR: Field type not compatible with UUID8. Use CSTRING, STRING or PSTRING. ' & pNode.Name)
        End
      of 'VALIDATE'
      orof 'CHECK'
        Dispose(pNode.Validate)
        pNode.Validate &= new String(len(val))
        pNode.Validate = val

      of 'WATCH'
        self.SharedProperties._haswatch = true
        pNode.Watch = true
      End
    End
  End
  Return

!-----------------------------------------------------------------
DriverFileClass._ParseFieldSQLType   Procedure(FieldGroupType pNode)
  Code

!-----------------------------------------------------------------
! find common mistakes in table declarations and provide warnings of same.
DriverFileClass.ValidateStructure   PROCEDURE()
  Code
  return driver:ok

!-----------------------------------------------------------------
DriverFileClass._SetSourceSize            PROCEDURE()
x  long
  code
  If self.SharedProperties &= null then
    self.trace('DriverFileClass._SetSourceSize: shared is null')
  End
  If self.SharedProperties.HasCustomFields
    self._SourceSize = 0
    Loop x = 1 to self.SharedProperties.FieldList.nodes
      self.Fields &= self._withFieldNode(x)
      If self.Fields.Interface &= null
        self._SourceSize += self.Fields.Size
      Else
        self._SourceSize += self.Fields.SourceSize
      End
    End
  Else
    self._SourceSize = self.ClaFCB.rec_len
  End
!-----------------------------------------------------------------
DriverFileClass._SourceSize  Procedure()
  code
  If self._SourceSize
    Return self._SourceSize
  Else
    Return self.ClaFCB.rec_len
  End

!-----------------------------------------------------------------
DriverFileClass._FreeKeys         PROCEDURE()
x  long
  code
  !loop x = 1 to records(self.keys)
  !  get(self.keys,x)
  !end
  free(self.keys)

!-----------------------------------------------------------------
DriverFileClass._FreeBlobs         PROCEDURE()
x       long
  code
  self._clearBlobs()
  Free(self.blobs)

!-----------------------------------------------------------------
! clears the blob memory, but leaves memos alone
DriverFileClass._ClearBlobs        PROCEDURE()
x       long
  code
  Loop x = 1 to Records(self.blobs)
    Get(self.blobs,x)
    self.SetBlobProp:Size(x,0)
    !Dispose(self.blobs.memostring)
  End
  Return

!-----------------------------------------------------------------
DriverFileClass._FreeFields         PROCEDURE()
  code

!-----------------------------------------------------------------
DriverFileClass.FreeBuffer  PROCEDURE()
  Code

!-----------------------------------------------------------------
DriverFileClass._UpdateFileStrings  Procedure()
  code
  If self._locknames = false
    If self._FullPathNameSetFromPropName = false
      self.FullPathName = clip(self._GetString(self.ClaFCB.phyname))
    End
    If self._OwnerSetFromPropOwner = false
      self.Owner        = clip(self._GetString(self.ClaFCB.oname))
    End
    self.DriverStr    = clip(self._GetString(self.ClaFCB.drvstr))
  End
  Return

!-----------------------------------------------------------------
DriverFileClass._FieldInPrimaryKey  Procedure(Long pIndex)
y  long,Auto
  code
  If self.SharedProperties._PrimaryKeyIndex
    Get(self.keys,self.SharedProperties._PrimaryKeyIndex)
    Loop y = 1 to self.keys.components
      If self.keys.component[y] = pIndex then return self.SharedProperties._PrimaryKeyIndex.
    End
  End
  Return 0

!-----------------------------------------------------------------
DriverFileClass._FieldInCaseKey  Procedure(Long pIndex)
x  long,Auto
y  long,Auto
  code
  Loop x = 1 to Records(self.keys)
    Get(self.keys,x)
    If self.keys.nocase = true then cycle.
    Loop y = 1 to self.keys.components
      If self.keys.component[y] = pIndex then return true .
    End
  End
  Return false

!-----------------------------------------------------------------
DriverFileClass._FieldInNoCaseKey  Procedure(Long pIndex)
x  long,Auto
y  long,Auto
  code
  Loop x = 1 to Records(self.keys)
    Get(self.keys,x)
    If self.keys.nocase = false then cycle.
    Loop y = 1 to self.keys.components
      If self.keys.component[y] = pIndex then return true .
    End
  End
  Return false


!-----------------------------------------------------------------
DriverFileClass._FieldAloneInUniqueKey   Procedure(Long pIndex)
x  long,Auto
!y  long
  code
  Loop x = 1 to records(self.keys)
    Get(self.keys,x)
    If self.keys.dup then cycle.
    If self.keys.type <> Cla_Key then cycle.
    If self.keys.components = 1 and self.keys.component[1] = pIndex then Return x.
  End
  Return 0

!-----------------------------------------------------------------
DriverFileClass._GetAlias               Procedure(Byte pWithDot)
  code
  If self._NoAlias then return ''.
  If self.Alias
    If pWithDot = driver:withdot
      Return self.Alias & '.'
    Else
      Return self.Alias
    End
  End
  If pWithDot = driver:withdot
    Return 'A.'
  Else
    Return 'A'
  End

!-----------------------------------------------------------------
! This is a list of common reserved words. Each database has their own suplementary list - derive as necessary
DriverFileClass.TranslateReserved       PROCEDURE(*cstring pColumn)
  code
  Return pColumn

!-----------------------------------------------------------------
! Postgres, SQLite, Oracle and Firebird use double quotes.
! Sql Server uses [ ], MySQL uses `. Derive as appropriate
DriverFileClass.WrapReserved       PROCEDURE(*cstring pColumn)
  code
  Return '"' & pColumn & '"'

!-----------------------------------------------------------------
DriverFileClass.UnwrapReserved    Procedure(*cstring pColumn)
  code
  if Left(pColumn,1) = '"' and Right(pColumn,1) = '"'
    Return sub(pColumn,2,Len(pColumn)-2)
  end
  Return pColumn

!-----------------------------------------------------------------
! In the "FILE" context, labels are translated into the column name
DriverFileClass.TranslateLabel       Procedure(*cstring pValue,*byte pReturnType)
i         Long
column    Cstring(128)
node      &FieldGroupType
v         Cstring(4096)
e         Cstring(4096)
  code
  ! lookup variable name in table, and replace if necessary.
  ! If the variable is not in a table, then EVALUATE it and turn it into a fixed value.

  ! the incoming value is of the form
  ! a) Clarion Label (cus:address)          ! translate this to columnname (with the alias)
  ! b) SQL table.column (customer.address)  ! translate this to columnname (with the alias)
  ! c) a.address                            ! translate this to columnname (with the alias)

  ! first: known equates which can be used in filters

  If self.TranslateConstant(pValue,i) = Driver:Ok
    pReturnType = driver:constant
    Return i
  End

  pReturnType = driver:field
  ! look for clarion fields.
  i = instring(':',pValue,1,1)
  If i
    ! Clarion Label.
    If self._WithFieldLabeled(pValue) = driver:ok
      do ModColumn
      Return self._GetAlias(driver:withdot) & self.fields.Column
    End
  Else
    i = instring('.',pValue,1,1)
    If i
      If self._WithFieldNamed(sub(pValue,i+1,len(pValue))) = driver:ok
        do ModColumn
        Return self._GetAlias(driver:withdot) & self.fields.Column
      End
    Else  ! no colon or period - it's just a word.
      If self._WithFieldNamed(sub(pValue,i+1,len(pValue))) = driver:ok
        do ModColumn
        Return self._GetAlias(driver:withdot) & self.fields.Column
      Else
        column = self.SharedProperties.prefix & ':' & pValue
        If self._WithFieldLabeled(column) = Driver:ok
          do ModColumn
          Return self._GetAlias(driver:withdot) & self.fields.Column
        End
      End
    End
  End
  If not self.BindQueue &= null
    self.BindQueue.Name = upper(clip(pValue))
    Get(self.BindQueue,self.BindQueue.name)
    If Errorcode() = 0
      pReturnType = driver:BindField
      Return self.BindQueue.Name
    End
  end

  pReturnType = driver:bound
  ! not a column name, try evaluating it

  v = clip(Evaluate(pValue))
  If Errorcode() = NoError
    Case band(self._ParseContext, 01111111b)
    Of driver:Order
    Orof driver:SQLOrder
    Orof driver:GroupBy
      pReturnType = driver:constant
      Return self._Sanitize(v,self._ParseContext)
    Of driver:filter
    orOf driver:searchfilter
    OrOf driver:having
    OrOf driver:expression
      If Numeric(v)
        pReturnType = driver:constant
        Return v
      Else
        pReturnType = driver:parameter
        self._ParameterCount += 1
        self._SetParameterString(self._ParameterCount,v)
        Return self._genparm(self._ParameterCount)
      End
    End
    pReturnType = driver:constant
    Return v
  End
  self.SetError(NoError)
  pReturnType = driver:unknown
  Return self._Sanitize(pValue,self._ParseContext)   ! assume the user knows what they're doing....but there are limits...

ModColumn  routine
  Case self.fields.type
  Of ClaDATE
    If self.fields.InOverGroup
      node &= self._WithFieldNode(self.fields.InOverGroup)
      node &= self._WithFieldNode(node.Over)
      If node.Type = ClaSTRING
        Return self._TranslateLabelOverDateSQL(node)
      End
    End
  Of ClaTIME
    If self.fields.InOverGroup
      node &= self._WithFieldNode(self.fields.InOverGroup)
      node &= self._WithFieldNode(node.Over)
      If node.Type = ClaSTRING
        Return self._TranslateLabelOverTimeSQL(node)
      End
    End
  End

!-----------------------------------------------------------------
DriverFileClass.TranslateSearch  Procedure(String pSearchString)
  code
  Return pSearchString

!-----------------------------------------------------------------
DriverFileClass._TranslateLabelOverDateSQL  Procedure(FieldGroupType pNode)
!!!DERIVE
  code
  Return ''

!-----------------------------------------------------------------
!!!DERIVE
DriverFileClass._TranslateLabelOverTimeSQL  Procedure(FieldGroupType pNode)
  code
  Return ''

!-----------------------------------------------------------------
!After an Add, Append,Put, Get, Reget, Next, Previous the position needs to be recorded because of a possible DELETE or PUT
!   This takes some time, and so can (should) be be disabled by setting prop:readonly (if reading) or prop:AddOnly
!   when only Inserting where possible.
DriverFileClass.SetPrimaryKeyPosition     PROCEDURE()
x     long,auto
pos   long
  code
  If Self.ReadOnly or self.AddOnly or Records(self.keys) = 0
    self.ClearPrimaryKeyPosition()
    Return
  End

  If self._WithPrimaryKey() <> driver:ok
    self.ClearPrimaryKeyPosition()
    Return
  End
  Loop x = 1 to self.keys.components
    memcpy(address(self.PrimaryKeyPosition) + pos, self.ClaFCB.rec_buf + self.SharedProperties._PKcomponentOffset[x] , self.SharedProperties._PKcomponentLength[x])
    pos +=  self.SharedProperties._PKcomponentLength[x]
    !self.PrimaryKeyPosition[self.SharedProperties._PKcomponentPos[x] : self.SharedProperties._PKcomponentPosEnd[x]] = self.GetProp:Value(self.keys.component[x])
    !!!todo - getprop:value returns the record buffer, not the db value, so doesn't support custom types yet
  End
  Return

!-----------------------------------------------------------------
!After a Delete, or Get(0), the Primary Key Position needs to be cleared.
DriverFileClass.ClearPrimaryKeyPosition     PROCEDURE()
  code
  self.PrimaryKeyPosition = ''
  Return

!-----------------------------------------------------------------
! a method that is called after every ADD, APPEND, PUT, DELETE, UPSERT
DriverFileClass._AfterWrite            Procedure(Long pOpCode)
  code
  !self.trace('AfterWrite ' & pOpCode & ' err=' & errorcode())
  Case pOpCode
  Of Opcode:DELETE
    self.ClearPrimaryKeyPosition()
    self._watchBufferState = watch:off
  Else
    If Errorcode()
      self.ClearPrimaryKeyPosition()
    Else
      self.SetPrimaryKeyPosition()
    End
    self._WatchBuffLoad()  ! set the _watchBufferState
    If self._logData then self.LogBuffer().
  End
  self._WatchCmdOff()   ! clear the _watchCmdState
  Return

!-----------------------------------------------------------------
! a method that is called at the start of every GET, REGET, NEXT, PREVIOUS, GETRANDOM
! this is done by the derived class, not the driverclass or DriverFileSQLClass
! The default flow for REGET flows through GET, so if the derived class does not derive REGET then it'll flow through GET ok.
DriverFileClass._BeforeRead            Procedure(Long pOpCode)
  code
  Self.SetError(NoError)
  If self._CheckOpen() = false then Return.
  self._SetAllNoNull()
  case pOpCode
  of Opcode:GET
    self.SubsetInFields       = ''
    self.SubSetFields         = ''
    self.SearchFilter         = ''
    self._SearchOrderClause   = ''
    self.SearchRank           = 0
    self._SearchParameter     = 0

  of Opcode:NEXT
  orof Opcode:PREVIOUS
    If self._HasBeenSet = False and self._HasBeenPropSql = false
      Self.SetError(BadRecErr)
    End
  End
  Return

!-----------------------------------------------------------------
DriverFileClass._AfterRead            Procedure(Long pOpCode)
  code
  If self._doingWatchCheck = false
    self._WatchCmdArm()      ! checks if watch cmd state is watch on, and if it is moves it to watch:armed. Else sets it to watch:off
    self._WatchBuffLoad()    ! moves the current record buffer into the WatchBuffer (if file is not readonly)
  End
  If self._logData then self.LogBuffer().
  Return

!-----------------------------------------------------------------
! parses prop:project, and populates the _ProjectField array with true and false
! will put additional clauses into the _ProjectClauses list
! If a GROUP field is in prop:project, then all the contents of the group are included.
! If an OVER field is in prop:project, then the "real" field is included.
DriverFileClass.ParseProject  Procedure()
x      long
y      long
col    cstring(255)
precol cstring(255)
abort  byte
  code
  Clear(self._ProjectField,1)                                ! default to all projected
  Clear(self._ProjectBlobField,1)                            ! default to all projected
  self._ProjectedPrimary = true
  If self.Project &= null or self.Project = '' then Return.
  Clear(self._ProjectField,0)                                ! a list exists, so default to none projected
  Clear(self._ProjectBlobField,0)                            ! a list exists, so default to none projected
  x = 1
  y = 1
  Loop
    If abort then Return.
    x = Instring(',',self.Project,1,y)
    If x = 0
      col = upper(clip(left(self.Project[y : len(self.Project)])))
      do NextCol
      Break
    End
    col = upper(clip(left(self.project[y : x-1])))
    do NextCol
    y = x + 1
  End
  ! check to see if the primary key fields are projected
  ! this does NOT project the primary key fields.
  If self._WithPrimaryKey() = Driver:ok
    Loop x = 1 to self.keys.components
      If self._ProjectField[self.keys.component[x]] = 0
        self._ProjectedPrimary = false
        Break
      End
    End
  End

  Return

NextCol  routine
  If self._WithFieldLabeled(col) = Driver:ok
    self._ProjectField()
  elsif self._WithFieldNamed(col) = Driver:ok
    self._ProjectField()
  elsif self._WithBlobLabel(col) = Driver:ok
    self._ProjectBlob()
  elsif self._WithBlobNamed(col) = Driver:ok
    self._ProjectBlob()
  else
    precol = self.SharedProperties.Prefix & ':' & col
    If self._WithFieldLabeled(precol) = Driver:ok
      self._ProjectField()
    Else
      If self._ProjectClauses &= null
        self._ProjectClauses &= new StringTheory
      End
      self._ProjectClauses.append(col,,',')
      !self.trace('column in prop:project not found in table, added to Clauses' & col)
      !self.SetError(BadProjectErr)
      !abort = true
    End
  End

!-----------------------------------------------------------------
! set _ProjectField array for the current field.
! If the field is over, then project the over'd field.
! If the field is a group then project everything in the group
DriverFileClass._ProjectField   Procedure()
x       Long
node    &FieldGroupType
  code
  If self.fields.over
    self._ProjectField[self.fields.over] = 255
  ElsIf self.fields.type = ClaGroup
    Loop x = self.fields.index to self.fields.index + self.fields.GroupFields
      self._ProjectField[x] = 255
    End
  ElsIf self.fields.InOverGroup
    node &= self._WithFieldNode(self.fields.InOverGroup)
    self._ProjectField[node.over] = 255
  Else
    self._ProjectField[self.Fields.Index] = 255
  End
  Return

!-----------------------------------------------------------------
DriverFileClass._ProjectBlob   Procedure()
  code
  self._ProjectBlobField[self.blobs.Index] = 255

!-----------------------------------------------------------------
! parses prop:project and adds a list of the fields to self.ProjectList
! does not add the custom clauses, those are only added for reads, not writes.
DriverFileClass.BuildProjectList    Procedure()
x  long,Auto
y  long,Auto
  code
  self.ParseProject()                                     ! parses the prop:project, and populates the _ProjectField array
  self.ProjectList.SetValue('')
  Loop x = 1 to self.SharedProperties.FieldList.nodes
    self.Fields &= self._withFieldNode(x)
    If self.Fields.Over or self.Fields.InOverGroup or self.Fields.Type = ClaGroup then Cycle.
    If self._ProjectField[x] = false then cycle.          ! importantly, 255, not 1, if included.
    self.ProjectList.append(self._GetAlias(driver:withdot) & self.Fields.Column,st:NoClip,',')
  End

  If self._noMemo = false
    Loop x = 1 to Records(self.blobs)
      Get(self.blobs,x)
      If self._ProjectBlobField[x] = false then cycle.          ! importantly, 255, not 1, if included.
      self.ProjectList.append(self._GetAlias(driver:withdot) & self.blobs.Column,st:NoClip,',')
    End
  End
  Return

!-----------------------------------------------------------------
DriverFileClass.BuildProjectListAppendClauses    Procedure()
  code
  If not self._ProjectClauses &= null and self._ProjectClauses.Length() > 0
    self.ProjectList.Append(self._ProjectClauses,,',')
  End
  Return

!-----------------------------------------------------------------
! this is called at the end of a SET, and also inside NextPrevious if the direction changes
!!! DERIVE
DriverFileClass._GenerateSelect            Procedure(Long pOpcode)
  code
  self._ResultSetDirection = pOpcode
  Return

!-----------------------------------------------------------------
DriverFileClass.BuildGroupBy              Procedure()
  code
  ! If fields are projected, then check for prop:distinct, prop:notdistinct
  If not self.Project &= null and self.Project <> '' and self._ProjectedPrimary = false
    self.ReadOnly = true
    If self.NotDistinct > 0
      self.Distinct = false
      self.SetProp:GroupBy(self.ProjectList.GetValue())
      self.SetProp:Having('COUNT(*) >= ' & self.notdistinct)
    End
  End
  parent.BuildGroupBy()
  Return

!-----------------------------------------------------------------
! It's really tempting to move the Pipe code into the thunking CLW, for performance reasons.
! However this base class is derived by all the other object-based classes, whereas the thunk is
! cloned per driver. So fixing bugs here applies to all drivers.
! For perfomance reasons there's only one opcode case statement in here. Parameter code is duplicated.
!-----------------------------------------------------------------
! Pipe Methods
!-----------------------------------------------------------------
DriverFileClass.Pipe            Procedure(Long pOpCode, Long pClaFCB, long pVarList)
ushparm1  UShort ,auto
lparm1    Long   ,auto
lparm2    Long   ,auto
lparm3    Long   ,auto
lparm4    Long   ,auto
kparm1    &key   ,auto
sparm1    string(1024),auto
sparm2    string(1024),auto

lReturn1  long,auto
ulReturn1 Ulong,over(lReturn1)

  Code
  !self.trace('DriverFileClass.Pipe :  err=[' & errorcode() & '] opcode:' & pOpcode & ' ' & self.InterpretOpCode(pOpcode) & ' pVarList='& pVarList)
!----- call object methods
  case pOpCode
  of Opcode:GET_PROPERTY                              ! comes first for performance reasons
    lparm1 = self._GetParmAsLong(pVarList,1)
    sParm1 = self._PopString()
    If self._logClarion then self.Log('[CLAR]GETPROPERTY(' & clip(sParm1) & ' ' & self.InterpretProperty(sParm1) & ',' & lparm1 & ')').
    self._PushString(self.GetProperty(sParm1,lparm1))

  of Opcode:ADD
    If self._logClarion then self.Log('[CLAR]ADD()').
    self.Add()

  of Opcode:ADDfilelen
    lparm1 = self._GetParmAsLong(pVarList,1)
    If self._logClarion then self.Log('[CLAR]ADD(' & lparm1 & ')').
    self.Add(lparm1)

  of Opcode:APPEND
    If self._logClarion then self.Log('[CLAR]APPEND()').
    self.Append()

  of Opcode:APPENDlen
    lparm1 = self._GetParmAsLong(pVarList,1)
    If self._logClarion then self.Log('[CLAR]APPEND(' & lparm1 & ')').
    self.Append(lparm1)

  of Opcode:_BLOB_YIELD                              ! called when a part of the blob is fetched. As in s = blob[0:10]
    ushparm1 = self._GetParmAsUShort(pVarList,1)
    lparm1 = self._GetParmAsLong(pVarList,2)
    lparm2 = self._GetParmAsLong(pVarList,3)
    self.BlobYield(ushparm1,lparm1,lparm2)

  of Opcode:_BLOB_TAKE                               ! called by the compiler when an assignment into the blob is done. As in  cus:aBlob[0:10] = 'abcdefghijk'
    ushparm1 = self._GetParmAsUShort(pVarList,1)
    lparm1 = self._GetParmAsLong(pVarList,2)
    lparm2 = self._GetParmAsLong(pVarList,3)
    self.BlobTake(ushparm1,lparm1,lparm2) ! does a self._PopString() later to avoid passing it as a parameter

  of Opcode:_BLOB_SIZE
    ushparm1 = self._GetParmAsUShort(pVarList,1)
    Return self.BlobSize(ushparm1)       ! pipe limits value to 2 gigs, Call method directly for larger

  of Opcode:_BLOB_SETPROPERTY
    ushparm1 = self._GetParmAsUShort(pVarList,1)
    self.SetBlobProperty(self._PopString(), ushparm1, self._PopString())

  of Opcode:BLOB_DOPROPERTY
    ushparm1 = self._GetParmAsUShort(pVarList,1)
    return self.DoBlobProperty(self._PopString(), ushparm1)

  of Opcode:_BLOB_GetProperty
    ushparm1 = self._GetParmAsUShort(pVarList,1)
    self._PushString(self.GetBlobProperty(self._PopString(), ushparm1))

  of Opcode:BOF
    If self._logClarion then self.Log('[CLAR]BOF()').
    return self.Bof()

  of Opcode:BUFFER
    lparm1 = self._GetParmAsLong(pVarList,1)
    lparm2 = self._GetParmAsLong(pVarList,2)
    lparm3 = self._GetParmAsLong(pVarList,3)
    lparm4 = self._GetParmAsLong(pVarList,4)
    If self._logClarion then self.Log('[CLAR]BUFFER(' & lparm1 & ',' & lparm1 & ',' & lparm3 & ',' & lparm4 & ')').
    self.buffer(lparm1,lparm2,lparm3,lparm4)

  of Opcode:BUILDdyn
    lparm1 = self._GetParmAsLong(pVarList,1)  ! effectivly the &key
    kparm1 &= (lparm1)
    If self._logClarion then self.Log('[CLAR]BUILD(key,string)').
    self.Build(kparm1,self._PopString())

  of Opcode:BUILDdynfilter
    sparm1 = self._PopString()
    sparm2 = self._PopString()
    lparm1 = self._GetParmAsLong(pVarList,1)  ! effectivly the &key
    kparm1 &= (lparm1)
    If self._logClarion then self.Log('[CLAR]BUILD(key,' & clip(sParm1) & ',' & clip(sparm2) & ')').
    self.Build(kparm1,clip(sParm1),clip(sParm2))  !!!todo check the interim Pops first to get the order of parameters right

  of Opcode:BUILDfile
    If self._logClarion then self.Log('[CLAR]BUILD()').
    self.Build()

  of Opcode:BUILDkey
    lparm1 = self._GetParmAsLong(pVarList,1)  ! effectivly the &key
    kparm1 &= (lparm1)
    If self._logClarion then self.Log('[CLAR]BUILD(key)').
    self.Build(kparm1)

  of Opcode:BULK_READ_ON
    self._bulkread = true

  of Opcode:BULK_READ_OFF
    self._bulkread = false

  of Opcode:BYTES
    If self._logClarion then self.Log('[CLAR]BYTES()').
    ulReturn1 = self.Bytes()
    return lReturn1

  !of Opcode:CALLBACK          ! doesn't come in here, handled by RTL

  of Opcode:CLEARfile
    lparm1 = self._GetParmAsLong(pVarList,1)
    If self._logClarion then self.Log('[CLAR]CLEAR(' & lparm1 & ')').
    self.ClearFile(lparm1)

  of Opcode:CLOSE
    If self._logClarion then self.Log('[CLAR]CLOSE()').
    self.Close()

  of Opcode:COMMITdrv
    If self._logClarion then self.Log('[CLAR]COMMIT()').
    self.Commit()

  of Opcode:CONNECT

  of Opcode:COPY
    sparm1 = self._PopString()
    If self._logClarion then self.Log('[CLAR]COPY(' & sparm1 & ')').
    self.Copy(sparm1,0)

  of Opcode:CREATE
    If self._logClarion then self.Log('[CLAR]CREATE()').
    self.CreateTable()

  of Opcode:DELETE
    If self._logClarion then self.Log('[CLAR]DELETE()').
    self.Delete()

  of Opcode:DESTROYf
    self.Destruct()

  of Opcode:DO_PROPERTY
    lparm1 = self._GetParmAsLong(pVarList,1)
    self.DoProperty(self._PopString(),lparm1)

  of Opcode:DUPLICATE
    If self._logClarion then self.Log('[CLAR]DUPLICATE()').
    return self.Duplicate()

  of Opcode:DUPLICATEkey
    lparm1 = self._GetParmAsLong(pVarList,1)  ! effectivly the &key
    kparm1 &= (lparm1)
    If self._logClarion then self.Log('[CLAR]DUPLICATE(key)').
    return self.Duplicate(kparm1)

  of Opcode:EMPTY
    If self._logClarion then self.Log('[CLAR]EMPTY()').
    self.Empty()

  of Opcode:EOF
    If self._logClarion then self.Log('[CLAR]EOF()').
    return self.Eof()

  of Opcode:EXCEEDS_RECS

  of Opcode:FIXFORMAT

  of Opcode:FLUSH
    If self._logClarion then self.Log('[CLAR]FLUSH()').
    self.Flush()

  of Opcode:FREESTATE
    lparm1 = self._GetParmAsLong(pVarList,1)
    If self._logClarion then self.Log('[CLAR]FREESTATE(' & lParm1 & ')').
    self.FreeState(lparm1)

  of Opcode:GETfilekey
    lparm1 = self._GetParmAsLong(pVarList,1)  ! effectivly the &key
    kparm1 &= (lparm1)
    If self._logClarion then self.Log('[CLAR]GET(key)').
    self.Get(kparm1)

  of Opcode:GETfileptrlen
    lparm1 = self._GetParmAsLong(pVarList,1)
    lparm2 = self._GetParmAsLong(pVarList,2)
    If self._logClarion then self.Log('[CLAR]GET(' & lParm1 & ',' & lParm2& ')').
    self.Get(lparm1,lparm2)                    ! limited to 2 gigs, use direct call for larger numbers

  of Opcode:GETfileptr
    lparm1 = self._GetParmAsLong(pVarList,1)
    If self._logClarion then self.Log('[CLAR]GET(' & lParm1 & ')').
    self.Get(lparm1)

  of Opcode:GETkeyptr
    lparm1 = self._GetParmAsLong(pVarList,1)  ! effectivly the &key
    kparm1 &= (lparm1)
    lparm2 = self._GetParmAsLong(pVarList,2)
    If self._logClarion then self.Log('[CLAR]GET(key,' & lParm2& ')').
    self.Get(kparm1,lparm2)

  of Opcode:GETNULLS
    If self._logClarion then self.Log('[CLAR]GETNULLS()').
    self._PushString(self.GetNulls())

  ! GetProperty is at the top of the CASE

  of Opcode:GETSTATE
    lparm1 = self._GetParmAsByte(pVarList,1)
    If self._logClarion then self.Log('[CLAR]GETSTATE(' & lParm1 & ')').
    Return self.GetState(lparm1)

  of Opcode:HOLDfile
    If self._logClarion then self.Log('[CLAR]HOLD()').
    self.Hold()

  of Opcode:HOLDfilesec
    lparm1 = self._GetParmAsLong(pVarList,1)  ! seconds
    If self._logClarion then self.Log('[CLAR]HOLD(' & lParm1 & ')').
    self.Hold(lparm1)

  of Opcode:KEY_DOPROPERTY
    !sparm1 = self._PopString()
    !lparm1 = self._GetParmAsLong(pVarList,1)  ! effectivly the &key

  of Opcode:KEY_SETPROPERTY
    lparm1 = self._GetParmAsLong(pVarList,1)  ! effectivly the &key
    kparm1 &= (lparm1)
    lparm2 = self._GetParmAsLong(pVarList,2)  ! effectivly the &key
    self.SetKeyProperty(self._PopString(),kparm1,lparm2,self._PopString())

  of Opcode:KEY_GetProperty
    lparm1 = self._GetParmAsLong(pVarList,1)  ! effectivly the &key
    kparm1 &= (lparm1)
    lparm2 = self._GetParmAsLong(pVarList,2)  ! the field index
    self._PushString(self.GetKeyProperty(self._PopString(),kparm1,lparm2))

  of Opcode:LOCKfile
  If self._logClarion then self.Log('[CLAR]LOCK()').
    self.Lock()

  of Opcode:LOCKfilesec   !21
    lparm1 = self._GetParmAsLong(pVarList,1)
    If self._logClarion then self.Log('[CLAR]LOCK(' & lParm1 & ')').
    self.Lock(lparm1)

  of Opcode:LOGOUTdrv     ! 22
    !self.trace('PIPE: Opcode:LOGOUTdrv=' & Opcode:LOGOUTdrv)
    If self._logClarion then self.Log('[CLAR]LOGOUT()').
    self.LogoutConnection()

  of Opcode:NAME
    If self._logClarion then self.Log('[CLAR]NAME()').
    self._PushString(self.Name())

  of Opcode:NEXT
    If self._logClarion then self.Log('[CLAR]NEXT()').
    self.Next()

  of Opcode:NOMEMO
    If self._logClarion then self.Log('[CLAR]NOMEMO()').
    self.NoMemo()

  of Opcode:NULL
    ! first parameter is pointer to field in recbuf. Second is length of the field.
    lparm1 = self._GetParmAsLong(pVarList,1)
    lparm2 = self._GetParmAsLong(pVarList,2)
    If self._logClarion then self.Log('[CLAR]NULL(' & lparm1 & ',' & lparm2 & ')').
    return self.null_(lparm1,lparm2)

  of Opcode:OPEN
    lparm1 = self._GetParmAsLong(pVarList,1)
    If self._logClarion then self.Log('[CLAR]OPEN(' & lparm1 & ')').
    self.Open(lparm1)

  of Opcode:PACK
    If self._logClarion then self.Log('[CLAR]PACK()').
    self.Pack()

  of Opcode:POINTERfile
    If self._logClarion then self.Log('[CLAR]POINTER()').
    return self.Pointer()

  of Opcode:POINTERkey
    lparm1 = self._GetParmAsLong(pVarList,1)  ! effectivly the &key
    kparm1 &= (lparm1)
    If self._logClarion then self.Log('[CLAR]POINTER(key)').
    Return self.Pointer(kparm1)

  of Opcode:POSITIONfile
    If self._logClarion then self.Log('[CLAR]POSITION()').
    self._PushString(self.Position())

  of Opcode:POSITIONkey
    lparm1 = self._GetParmAsLong(pVarList,1)  ! effectivly the &key
    kparm1 &= (lparm1)
    If self._logClarion then self.Log('[CLAR]POSITION(key)').
    self._PushString(self.Position(kparm1))

  of Opcode:PREVIOUS
    If self._logClarion then self.Log('[CLAR]PREVIOUS()').
    self.Previous()

  of Opcode:PUT
    If self._logClarion then self.Log('[CLAR]PUT()').
    self.Put()

  of Opcode:PUTfileptr
    lparm1 = self._GetParmAsLong(pVarList,1)
    If self._logClarion then self.Log('[CLAR]PUT(' & lParm1 & ')').
    self.Put(lparm1)

  of Opcode:PUTfileptrlen
    lparm1 = self._GetParmAsLong(pVarList,1)
    lparm2 = self._GetParmAsLong(pVarList,2)
    If self._logClarion then self.Log('[CLAR]PUT(' & lParm1 & ',' & lParm2 & ')').
    self.Put(lparm1,lparm2)

  of Opcode:QUERY_KEY

  of Opcode:QUERY_VIEW
    ! this is a special case, handled in the thunk layer, because the value is in scope there, but not here.

  of Opcode:RECORDSfile
    If self._logClarion then self.Log('[CLAR]RECORDS()').
    return self.Records()

  of Opcode:RECORDSkey
    lparm1 = self._GetParmAsLong(pVarList,1)  ! effectivly the &key
    kparm1 &= (lparm1)
    If self._logClarion then self.Log('[CLAR]RECORDS(key)').
    return self.Records()

  of Opcode:REGETfile
    If self._logClarion then self.Log('[CLAR]REGET(string)').
    self.Reget(self._PopString())

  of Opcode:REGETkey
    lparm1 = self._GetParmAsLong(pVarList,1)  ! effectivly the &key
    kparm1 &= (lparm1)
    If self._logClarion then self.Log('[CLAR]REGET(key,string)').
    self.Reget(kparm1,self._PopString())

  of Opcode:REGISTER          !!!todo
    !self.trace('xxx OPCODE:Register')

  of Opcode:RELEASE
    If self._logClarion then self.Log('[CLAR]RELEASE()').
    self.Release()

  of Opcode:REMOVE
    If self._logClarion then self.Log('[CLAR]REMOVE()').
    self.Remove()

  of Opcode:RENAME
    sParm1 = self._PopString()
    If self._logClarion then self.Log('[CLAR]RENAME(' & clip(sParm1) & ')').
    self.Rename(clip(sParm1))

  of Opcode:RESETfile
    If self._logClarion then self.Log('[CLAR]RESET(string)').
    self.Reset(self._PopString())

  of Opcode:RESETkey
    lparm1 = self._GetParmAsLong(pVarList,1)  ! effectivly the &key
    kparm1 &= (lparm1)
    If self._logClarion then self.Log('[CLAR]RESET(key,string)').
    self.reset(kparm1,self._PopString())

  of Opcode:RESTORESTATE
    lparm1 = self._GetParmAsLong(pVarList,1)
    lparm2 = self._GetParmAsByte(pVarList,2)
    If self._logClarion then self.Log('[CLAR]RESTORESTATE('&lparm1& ',' & lParm2 & ')').
    self.RestoreState(lparm1,lparm2)

  of Opcode:ROLLBACKdrv
    If self._logClarion then self.Log('[CLAR]ROLLBACK()').
    self.Rollback()

  of Opcode:SEND
    If self._logClarion then self.Log('[CLAR]SEND(string)').
    self._PushString(self.Send(self._PopString()))

  of Opcode:SETfile
    If self._logClarion then self.Log('[CLAR]SET(file)').
    self.Set()

  of Opcode:SETfilekey
    lparm1 = self._GetParmAsLong(pVarList,1)  ! effectivly the &key
    kparm1 &= (lparm1)
    If self._logClarion then self.Log('[CLAR]SET(file,key)').
    self.Set(0,kparm1)

  of Opcode:SETfileptr
    lparm1 = self._GetParmAsLong(pVarList,1)
    If self._logClarion then self.Log('[CLAR]SET(fileptr) where ptr=(' & lParm1 & ')').
    self.Set(lparm1)

  of Opcode:SETkey
    lparm1 = self._GetParmAsLong(pVarList,1)  ! effectivly the &key
    kparm1 &= (lparm1)
    If self._logClarion then self.Log('[CLAR]SET(key)').
    self.Set(kparm1)

  of Opcode:SETkeykeyptr
    lparm1 = self._GetParmAsLong(pVarList,1)  ! effectivly the &key
    kparm1 &= (lparm1)
    lparm2 = self._GetParmAsLong(pVarList,2)
    If self._logClarion then self.Log('[CLAR]SET(key,key,' & lParm2 & ')').
    self.Set(kparm1,kparm1,lparm2) ! interestingly the first key is forced to both parameters
    If self._logData then self.LogBuffer().

  of Opcode:SETkeykey
    lparm1 = self._GetParmAsLong(pVarList,1)  ! effectivly the &key
    kparm1 &= (lparm1)
    If self._logClarion then self.Log('[CLAR]SET(key,key)').
    self.Set(kparm1,kparm1) ! interestingly the first key is forced to both parameters
    If self._logData then self.LogBuffer().

  of Opcode:SETkeyptr
    lparm1 = self._GetParmAsLong(pVarList,1)  ! effectivly the &key
    kparm1 &= (lparm1)
    lparm2 = self._GetParmAsLong(pVarList,2)
    If self._logClarion then self.Log('[CLAR]SET(key,'& lParm1 &')').
    self.Set(kparm1,lparm2)

  of Opcode:SETNULL
    lparm1 = self._GetParmAsLong(pVarList,1)
    lparm2 = self._GetParmAsLong(pVarList,2)
    If self._logClarion then self.Log('[CLAR]SETNULL('&lParm1 & ',' & lParm2&')').
    self.SetNull_(lparm1,lparm2)

  of Opcode:SETNULLS
    If self._logClarion then self.Log('[CLAR]SETNULLS(string)').
    self.SetNulls(self._PopString())

  of Opcode:SETNONNULL
    lparm1 = self._GetParmAsLong(pVarList,1)
    lparm2 = self._GetParmAsLong(pVarList,2)
    If self._logClarion then self.Log('[CLAR]SETNONNULL('&lParm1 & ',' & lParm2&')').
    self.SetNonNull(lparm1,lparm2)

  of Opcode:SET_PROPERTY
    lparm2 = self._GetParmAsLong(pVarList,1)
    !sParm1 = self._PopString()
    !sParm2 = self._PopString()
    !If self._logClarion then self.Log('[CLAR]SETPROPERTY(' & self.InterpretProperty(sParm1) & ',' & lParm2 & ')=' & sparm2).
    !self.trace('DriverFileClass.SETPROPERTY (' & self.InterpretProperty(pProperty) & ',' & pIndex & ',' & pValue & ')')
    self.SetProperty(self._PopString(),lparm2,self._PopString())

  of Opcode:SETviewfields

  of Opcode:SHARE
    lparm1 = self._GetParmAsLong(pVarList,1)
    If self._logClarion then self.Log('[CLAR]SHARE(' & lParm1 &')').
    self.Share(lparm1)

  of Opcode:SKIP
    lparm1 = self._GetParmAsLong(pVarList,1)
    If self._logClarion then self.Log('[CLAR]SKIP(' & lParm1 &')').
    self.Skip(lparm1)

  of Opcode:STREAM
    If self._logClarion then self.Log('[CLAR]STREAM(' & lParm1 &')').
    self.Stream()

  of Opcode:START_BUILD
    self.Build()

  of Opcode:STARTTRAN                                     ! transtate can be HAVEFILE, STARTTRAN,ENDTRAN
    !self.trace('PIPE : Opcode:STARTTRAN=' & Opcode:STARTTRAN)
    lparm1 = self._GetParmAsLong(pVarList,1)
    self.StartTran(lparm1)

  of Opcode:ENDTRAN
    !self.trace('PIPE : Opcode:ENDTRAN=' & Opcode:ENDTRAN)
    lparm1 = self._GetParmAsLong(pVarList,1)
    self.EndTran(lparm1)

  of Opcode:SQL              !equate(107)  !    DRV(code, fcb, const char *sql, char textAsStr, char imageAsStr) Internally used by DynFile.cpp

  of Opcode:SQLCALLBACK

  of Opcode:UNFIXFORMAT

  of Opcode:UNLOCK
    If self._logClarion then self.Log('[CLAR]UNLOCK(' & lParm1 &')').
    self.Unlock()

  of Opcode:VALIDATE

  of Opcode:WATCH
    If self._logClarion then self.Log('[CLAR]WATCH()').
    self.Watch()

  !of Opcode:WHO_ARE_YOU      !     Internal used in buffering code
    !This one is called by the pipe procedure, it doesn't come to the class.
  Else

  End
  !self.trace('pipedone')
  Return 0

!-----------------------------------------------------------------
DriverFileClass._FindBindQueue             Procedure(Long pAddress)
x  Long,Auto
  Code
  If pAddress = 0 then Return Driver:notok.
  Loop x = 1 to Records(self.BindQueue)
    Get(self.BindQueue,x)
    If self.BindQueue.cst &= (pAddress) then return driver:ok.
    If self.BindQueue.st &= (pAddress) then return driver:ok.
    If self.BindQueue.rl &= (pAddress) then return driver:ok.
    If self.BindQueue.lg &= (pAddress) then return driver:ok.
  End
  Return Driver:notok

!-----------------------------------------------------------------
! File Methods
!-----------------------------------------------------------------
!-----------------------------------------------------------------
! BindField allows local variables to be added to the Prop:Project, and to Prop:Order.
! They are not available in prop:filter
DriverFileClass.BINDFIELD                     Procedure(String pName,*Long pLong)
  Code
  If self.BindQueue &= Null
    self.BindQueue &= new BindQueueType
  End
  self.BindQueue.Name = upper(clip(pName))
  Get(self.BindQueue,self.BindQueue.Name)
  If Errorcode()
    clear(self.BindQueue)
    self.BindQueue.Name = upper(clip(pName))
    self.BindQueue.lg &= pLong
    Add(self.BindQueue)
  Else
    self.BindQueue.rl &= null
    self.BindQueue.st &= null
    self.BindQueue.cst &= null
    self.BindQueue.lg &= pLong
    Put(self.BindQueue)
  End
  Return

!-----------------------------------------------------------------
DriverFileClass.BINDFIELD                     Procedure(String pName,*Real pReal)
  Code
  If self.BindQueue &= Null
    self.BindQueue &= new BindQueueType
  End
  self.BindQueue.Name = upper(clip(pName))
  Get(self.BindQueue,self.BindQueue.Name)
  If Errorcode()
    clear(self.BindQueue)
    self.BindQueue.Name = upper(clip(pName))
    self.BindQueue.rl &= pReal
    Add(self.BindQueue)
  Else
    self.BindQueue.lg &= null
    self.BindQueue.st &= null
    self.BindQueue.cst &= null
    self.BindQueue.rl &= pReal
    Put(self.BindQueue)
  End
  Return

!-----------------------------------------------------------------
DriverFileClass.BINDFIELD                     Procedure(String pName,*String pString)
  Code
  If self.BindQueue &= Null
    self.BindQueue &= new BindQueueType
  End
  self.BindQueue.Name = upper(clip(pName))
  Get(self.BindQueue,self.BindQueue.Name)
  If Errorcode()
    clear(self.BindQueue)
    self.BindQueue.Name = upper(clip(pName))
    self.BindQueue.st &= pString
    Add(self.BindQueue)
  Else
    self.BindQueue.lg &= null
    self.BindQueue.rl &= null
    self.BindQueue.cst &= null
    self.BindQueue.st &= pString
    Put(self.BindQueue)
  End
  Return

!-----------------------------------------------------------------
DriverFileClass.BINDFIELD                     Procedure(String pName,*Cstring pCstring)
  Code
    If self.BindQueue &= Null
    self.BindQueue &= new BindQueueType
  End
  self.BindQueue.Name = upper(clip(pName))
  Get(self.BindQueue,self.BindQueue.Name)
  If Errorcode()
    clear(self.BindQueue)
    self.BindQueue.Name = upper(clip(pName))
    self.BindQueue.cst &= pCstring
    Add(self.BindQueue)
  Else
    self.BindQueue.lg &= null
    self.BindQueue.rl &= null
    self.BindQueue.st &= null
    self.BindQueue.cst &= pCstring
    Put(self.BindQueue)
  End
  Return

!-----------------------------------------------------------------
DriverFileClass.BOF              PROCEDURE()
  Code
  self.SetError(NoDriverSupport)
  Return false

!-----------------------------------------------------------------
! called by the compiler when an assignment into the blob is done. As in  cus:aBlob[0:10] = 'abcdefghijk'
! Not called for MEMO's, only actual blobs. Memos are a simple assignment, they don't flow through the driver.
! Do not call this method directly. If you want to set the blob directly using a method then use SetBlob.
! This method will automatically resize the blob if it is too small.
DriverFileClass.BLOBTAKE       PROCEDURE(Long pIndex,BIGINT pStartPos, BIGINT pEndPos)
addr  long
len   long
  Code
  !self.trace('DriverFileClass.BlobTake pIndex=' & pIndex & ' pstartpos=' & pStartPos & ' pendpos=' & pEndPos)
  If pEndPos >= pStartPos
    If self._WithBlob(pIndex) = driver:ok
      If pEndPos >= self.blobs.handlesize            ! EndPos is 0 based
        self.SetBlobProp:Size(pIndex,pEndPos+1)
      End
      addr = self.blobs.handle + pStartPos  ! pStartPos is 0 based
      len = pEndPos - pStartPos + 1
      ClaPopString(addr,len)
      !self.trace('DriverFileClass.BlobTake handle=' & self.blobs.handle & ' handlesize=' & self.blobs.handlesize)
    End
  End
  Return

!-----------------------------------------------------------------
! not called from Pipe when doing a BlobTake (ie array assignment),
! this is for direct object access to set the blob.
DriverFileClass.SetBlob          PROCEDURE(Long pIndex,Blob pValue)
iParm  BIGINT
  code
  iParm = pValue{prop:handle}
  self.SetBlobProp:Handle(pIndex,iParm)
  Return
!-----------------------------------------------------------------
! not called from Pipe when doing a BlobTake (ie array assignment),
! this is for direct object access to set the blob.
! But is called from the SetProp:Value method, which can be from Pipe.
! Note that the pStartPos is 0 based. Blob will automatically resize bigger if necessary.
!-----------------------------------------------------------------
DriverFileClass.SetBlob          PROCEDURE(Long pIndex,String pValue)
  code
  Self.SetBlob(pIndex,0,pValue,true)
  Return

!-----------------------------------------------------------------
! assumes the correct Blobs queue record is loaded.
DriverFileClass.CheckBlobCrc    PROCEDURE()
lCrc32  Long
  Code
  If self.blobs.Memo  ! MEMO field
    lCrc32 = ClaCrc32(address(self.blobs.memostring), self.blobs.memosize ,0)
  Else
    lCrc32 = ClaCrc32(self.blobs.handle, self.blobs.handlesize ,0)
  End
  !self.trace('DriverFileClass.CheckBlobCrc ' & self.blobs.Column & ' ' & self.Blobs.Crc32 & '  lCrc32=' & lCrc32)

  If lCrc32 = self.blobs.crc32 Then Return True.

  Return False

!-----------------------------------------------------------------
DriverFileClass.SetBlobsCrc    PROCEDURE()
x  long
  Code
  Loop x = 1 to Records(self.blobs)
    Get(self.blobs,x)
    self.SetBlobCrc()
    Put(self.blobs)
  End

!-----------------------------------------------------------------
! assumes the correct Blobs queue record is loaded.
! sets the crc32 field, but does not do a PUT on the Blobs queue.
DriverFileClass.SetBlobCrc    PROCEDURE()
  Code

  If self.blobs.Memo  ! MEMO field
    self.Blobs.Crc32 = ClaCrc32(address(self.blobs.memostring), self.blobs.memosize ,0)
  Else
    self.Blobs.Crc32 = ClaCrc32(self.blobs.handle, self.blobs.handlesize ,0)
  End
  !self.trace('DriverFileClass.SetBlobCrc ' & self.blobs.Column & ' ' & self.Blobs.Crc32)
  Return

!-----------------------------------------------------------------
DriverFileClass.SetBlob       PROCEDURE(Long pIndex,BIGINT pStartPos, String pValue, Long pSetSize)
len  BIGINT
addr long
  code
  If self._WithBlob(pIndex) = driver:ok
    If self.blobs.Memo  ! set MEMO field
      If self.blobs.Binary
        len = len(pValue)
      Else
        len = len(clip(pValue))
      End
      If len > self.blobs.memosize
        self._newMemoMemory(pStartPos + len)
        Put(self.blobs)
      End
      if pStartPos
        self.blobs.memostring = sub(self.blobs.memostring,1,pStartPos-1) & pValue
      else
        self.blobs.memostring = pValue
      End
      !self.trace('DriverFileClass.SetBlob MEMO #' & pIndex & ' startpos=' & pStartpos & ' pSetSize=' & pSetSize & ' val=[' & pValue & ']')
    Else ! Set BLOB field
      len = size(pValue)
      If pSetSize = false and self.blobs.handle <> 0 and self.blobs.handlesize >= pStartPos + len
        ! fits into existing size
        if len > 0 then memcpy(self.blobs.handle + pStartPos,address(pValue),len).    ! not BigInt compatible
      Else
        ! need to resize
        self.SetBlobProp:Size(pIndex,pStartPos + len)
        if len > 0 then memcpy(self.blobs.handle + pStartPos,address(pValue),len ).   ! not BigInt compatible
      End
      !self.trace('DriverFileClass.SetBlob BLOB #' & pIndex & ' startpos=' & pStartpos & ' pSetSize=' & pSetSize & ' val=[' & pValue & '] handlesize=' & self.blobs.handlesize  )
    End
  End
  Return

!-----------------------------------------------------------------
! If pIndex = 0 then the blob record is already loaded.
DriverFileClass.SetBlobFromAddr  PROCEDURE(Long pIndex,BIGINT pStartPos, BIGINT pAddress, BIGINT pSize)
str  &string
  Code
  If self._WithBlob(pIndex) = driver:ok
    If self.blobs.Memo  ! set MEMO field
      str &= pAddress & ':' & pSize
      self.blobs.memostring = str
    else ! Set BLOB field
      self.SetBlobProp:Size(pIndex,pStartPos + pSize)
      If pSize
        memcpy(self.blobs.handle + pStartPos,pAddress,pSize )   ! not BigInt compatible
      End
    End
  End
  Return

!-----------------------------------------------------------------
! called when a part of the blob is fetched. As in s = blob[0:10]
! Do not call this method directly. If you want to get the blob directly using a method then use GetBlob.
DriverFileClass.BLOBYIELD       PROCEDURE(Long pIndex,BIGINT pStartPos, BIGINT pEndPos)
addr  long
len   long
strg  string(1)
  Code
  !self.trace('DriverFileClass.BlobYield')
  If self._WithBlob(pIndex) = driver:ok and not self.blobs.handle = 0 and pEndPos >= pStartPos and pStartPos >= 0
    If pEndPos > self.blobs.handlesize then pEndPos = self.blobs.handlesize - 1.
    addr = self.blobs.handle + pStartPos
    len = pEndPos - pStartPos + 1
    ClaPushString(addr,len)
  Else
    ClaPushString(address(strg),0)
  End
  Return

!-----------------------------------------------------------------
! useful for debuggin. Sends contents of blob to debugview.
DriverFileClass.ViewBlob       PROCEDURE(Long pIndex)
str  &string
  code
  If self._WithBlob(pIndex) = Driver:ok and not self.blobs.handle = 0 and self.blobs.handlesize > 0
    str &= self.blobs.handle & ':' & self.blobs.handlesize
    self.trace('ViewBlob(' & pIndex & ') handle= ' & self.blobs.handle & ' handlesize=' & self.blobs.handlesize & ' value = [' & str & ']')
  else
    self.trace('ViewBlob(' & pIndex & ') handle= ' & self.blobs.handle & ' handlesize=' & self.blobs.handlesize)
  end

!-----------------------------------------------------------------
DriverFileClass.GetBlob       PROCEDURE(Long pIndex)
str  &string
  Code
  !self.trace('GetBlob(i) ' & pIndex)
  If self._WithBlob(pIndex) = Driver:ok and not self.blobs.handle = 0 and self.blobs.handlesize > 0
    str &= self.blobs.handle & ':' & self.blobs.handlesize
    Return str
  End
  Return ''
!-----------------------------------------------------------------
DriverFileClass.GetBlob       PROCEDURE(Long pIndex,BIGINT pStartPos)  ! pStartPos is 0 based.
str  &string
  Code
  If self._WithBlob(pIndex) = Driver:ok and not self.blobs.handle = 0 and self.blobs.handlesize > 0 and pStartPos <= self.blobs.handlesize
    If pStartPos < 0 then pStartPos = 0.
    str &= self.blobs.handle + pStartPos & ' : ' & self.blobs.handlesize - pStartPos
    Return str
  End
  Return ''

!-----------------------------------------------------------------
DriverFileClass.GetBlob       PROCEDURE(Long pIndex,BIGINT pStartPos, BIGINT pEndPos)  ! pStartPos, pEndPos are 0 based.
str  &string
  Code
  If self._WithBlob(pIndex) = Driver:ok and not self.blobs.handle = 0  and pStartPos >= 0 and self.blobs.handlesize > 0 and pStartPos <= self.blobs.handlesize and pEndPos >= pStartPos
    If pEndPos > self.blobs.handlesize then pEndPos = self.blobs.handlesize - 1.
    str &= self.blobs.handle + pStartPos & ' : ' & pEndPos - pStartPos + 1
    Return str
  End
  Return ''


!-----------------------------------------------------------------
DriverFileClass.BLOBSIZE       PROCEDURE(Long pIndex)
  Code
  Return self.GetProp:Size(-pIndex)

!-----------------------------------------------------------------
DriverFileClass.BUFFER           PROCEDURE(UNSIGNED pPageSize, UNSIGNED pBehind=0, UNSIGNED pAhead=0, UNSIGNED pTimeout=0)
  Code
  If self._CheckOpen() = false then Return.
  self.SetError(NoError)
  If pAhead
    self.FetchSize = pPageSize * pAhead
  Else
    self.FetchSize = pPageSize
  End
  Return

!-----------------------------------------------------------------
! Build the OrderBy for the FILE case.
DriverFileClass.BuildOrderBy  Procedure()
  code
  parent.BuildOrderBy()                                                                             ! Clear the Queue
  If self._SearchOrderClause
    Clear(self.OrderQueue)
    self.OrderQueue.Clause = self._SearchOrderClause
    Add(self.OrderQueue)
  End
  self._SupplementalOrderFields = 0
  If (self.SetMethod = driver:SetFile or self.SetMethod = driver:SetFilePos) and self.SetKey &= Null   ! Set(file) form used, so just use Prop:OrderBy
    self.BuildOrderByProps()
  Else
    self.BuildOrderByKey(self.SetKey)                                                               ! Do the SetKey part first
    self.BuildOrderByProps()
  End
  If self.Paging = true and self.Distinct = false and self.NotDistinct = 0
    self.BuildOrderByUnique()                                                                       ! Make sure Order contains unique fields for each file
  End
  self.SetOrderByFromQueue()                                                                        ! sets prop:OrderBy based on SetDirection
  Return

!-----------------------------------------------------------------
! The syntax for this part is dependent on the SQL engine being used.
! This takes the OrderBy queue as input, and generates the prop:OrderBy as output
! makes use of self._setDirection to determine the OpCode
!!! derive
DriverFileClass.SetOrderByFromQueue            Procedure()
  code

!-----------------------------------------------------------------
! The OrderBy property is an amalgamation of the prop:order and the prop:SqlOrder
DriverFileClass.BuildOrderByKey          Procedure(Key pKey)
x long
  code
  !If a Key is used to set the order, then it preceeds the prop:order and prop:SqlOrder
  If self._WithKey(pKey) = Driver:ok
    Loop x = 1 to self.keys.components
      self.OrderQueue.FieldIndex = self.keys.component[x]
      Get(self.OrderQueue,self.OrderQueue.FieldIndex)
      If errorcode() = NoError then cycle.                    ! already exists
      Clear(self.OrderQueue)
      If self._WithField(self.keys.component[x]) = Driver:ok
        self.OrderQueue.Clause     = self._GetAlias(driver:withdot) & self.Fields.Column
        case self.Fields.Type
        of ClaSTRING
        orof ClaCSTRING
        orof ClaPSTRING
          self.OrderQueue.Nocase     = self.keys.Nocase
        End
        self.OrderQueue.IsCalc     = false
        self.OrderQueue.FileIndex  = 1
        self.OrderQueue.FieldIndex = self.keys.component[x]
        If self.keys.descending[x]
          self.OrderQueue.Direction   = driver:Descending
        End
        Add(self.OrderQueue)
      End
    End
  End
  Return


!-----------------------------------------------------------------
! Buid a prop:order string based on the fields in the key.
DriverFileClass.BuildPropOrderByKey          Procedure(Key pKey)
x   long,auto
ans StringTheory
  code
  If self._WithKey(pKey) = Driver:ok
    Loop x = 1 to self.keys.components
      If self._WithField(self.keys.component[x]) = Driver:ok
        If self.keys.descending[x]
          ans.append('-',,',')
        Else
          ans.append('+',,',')
        End
        case self.Fields.Type
        of ClaSTRING
        orof ClaCSTRING
        orof ClaPSTRING
          If self.keys.Nocase
            ans.append('UPPER(' & self.FullPathName & '.' & self.Fields.Column & ')')
          else
            ans.append(self.FullPathName & '.' & self.Fields.Column)
          end
        else
          ans.append(self.FullPathName & '.' & self.Fields.Column)
        End
      End
    End
  End
  !self.trace('ans=' & ans.GetValue())
  Return ans.GetValue()

!-----------------------------------------------------------------
!Need to make the OrderBy unique. In the FILE case this means potentially adding any primary key fields that don't exist in the order.
DriverFileClass.BuildOrderByUnique      Procedure()
key     &key
y       long
x       long
thiskey byte
  Code
  Loop x = 1 to records(self.keys)
    Get(self.keys,x)
    If self.keys.dup then cycle.
    thiskey = true
    Loop y = 1 to self.keys.components
      self.OrderQueue.FieldIndex = self.keys.component[y]
      Get(self.OrderQueue,self.OrderQueue.FieldIndex)
      If errorcode()
        thiskey = false
        break
      End
    End
    If thiskey then return.
  End
  ! add the primary key fields if they're not already part of the order
  x = Records(self.OrderQueue)
  If self._WithPrimaryKey() = Driver:ok
    key &= (self.keys.keyptr)
    self.BuildOrderByKey(key)
  End
  if x < records(self.OrderQueue)
    self._SupplementalOrderFields = x + 1
  End
  Return

!-----------------------------------------------------------------
DriverFileClass.HASRELATION    PROCEDURE(File pParentFile)
x  Long
  code
  Loop x = 1 to Records(self.relations)
    Get(self.relations,x)
    If self.relations.ParentFile &= pParentFile
      Return true
    End
  End
  Return false

!-----------------------------------------------------------------
DriverFileClass.ADDRELATION    PROCEDURE(File pParentFile, Long pOnUpdate, Long pOnDelete, *? pChildField1, *? pParentField1, <*? pChildField2>, <*? pParentField2>, <*? pChildField3>, <*? pParentField3>, <*? pChildField4>, <*? pParentField4>, <*? pChildField5>, <*? pParentField5>, <*? pChildField6>, <*? pParentField6>, <*? pChildField7>, <*? pParentField7>, <*? pChildField8>, <*? pParentField8>, <*? pChildField9>, <*? pParentField9>, <*? pChildField10>, <*? pParentField10>)
obj    &DriverFileClass ,auto
x      long             ,auto
found  long
  code
  self.SetError(NoError)
  obj &= pParentFile{prop:object}
  If obj &= NULL
    self.SetError(NoDriverSupport)
    Return
  End
  Loop x = 1 to records(self.relations)
    Get(self.relations,x)
    If self.relations.ParentFile &= pParentFile
      found = 1
    End
  End
  If found = 0
    Clear(self.relations)
    self.relations.ParentFile &= pParentFile
    Add(self.relations)
  end

  self.relations.OnUpdate = pOnUpdate
  self.relations.OnDelete = pOnDelete
  if obj &= NULL
    self.trace('DriverFileClass.ADDRELATION  obj is null')
  end

  self._AddRelationField(1,obj,pChildField1,pParentField1)
  If not omitted(pChildField2) and not omitted(pParentField2) then self._AddRelationField(2,obj,pChildField2,pParentField2).
  If not omitted(pChildField3) and not omitted(pParentField3) then self._AddRelationField(3,obj,pChildField3,pParentField3).
  If not omitted(pChildField4) and not omitted(pParentField4) then self._AddRelationField(4,obj,pChildField4,pParentField4).
  If not omitted(pChildField5) and not omitted(pParentField5) then self._AddRelationField(5,obj,pChildField5,pParentField5).
  If not omitted(pChildField6) and not omitted(pParentField6) then self._AddRelationField(6,obj,pChildField6,pParentField6).
  If not omitted(pChildField7) and not omitted(pParentField7) then self._AddRelationField(7,obj,pChildField7,pParentField7).
  If not omitted(pChildField8) and not omitted(pParentField8) then self._AddRelationField(8,obj,pChildField8,pParentField8).
  If not omitted(pChildField9) and not omitted(pParentField9) then self._AddRelationField(9,obj,pChildField9,pParentField9).
  If not omitted(pChildField10) and not omitted(pParentField10) then self._AddRelationField(10,obj,pChildField10,pParentField10).
  Put(self.Relations)
  Return

!-----------------------------------------------------------------
DriverFileClass._AddRelationField Procedure(Long pIndex,DriverFileClass pParent, *? pChildField, *? pParentField)
  code
  If self._WithFieldPtr(pChildField) = driver:ok
    self.relations.ChildIndex[pIndex] = self.fields.Index
  Else
    self.SetError(BadFieldErr)
  End
  If pParent._WithFieldPtr(pParentField) = driver:ok
    self.relations.ParentIndex[pIndex] = pParent.fields.Index
  Else
    self.SetError(BadFieldErr)
  End
  Return

!-----------------------------------------------------------------
DriverFileClass.BUILD            PROCEDURE()
  Code
  !self.trace('build file')
  self.SetError(NoDriverSupport)
  Return

!-----------------------------------------------------------------
DriverFileClass.BUILD            PROCEDURE(KEY pKey)
  Code
  !self.trace('build key ')
  self.SetError(NoDriverSupport)
  Return

!-----------------------------------------------------------------
DriverFileClass.BUILD            PROCEDURE(KEY pKey, <STRING pComponents>,STRING pFilter)
  Code
  !if omitted(pComponents)
    !self.trace('build key, , filter: '  & ' filter=' & pFilter)
  !else
    !self.trace('build key, comp, filter: comp=' & pComponents & '  filter=' & pFilter)
  !end
  self.SetError(NoDriverSupport)
  Return

!-----------------------------------------------------------------
DriverFileClass.BUILD            PROCEDURE(KEY pKey, STRING pComponents)
  Code
  !self.trace('build key, comp: pComponents= ' & pComponents)
  If self._CheckOpen() = false then Return.
  self.SetError(NoDriverSupport)
  Return

!-----------------------------------------------------------------
DriverFileClass.BYTES            PROCEDURE()
  Code
  self.SetError(NoError)
  Return self._Bytes
!
!-----------------------------------------------------------------
DriverFileClass.CALL             Procedure(String pStoredProcedure,<? pParm1>,<? pParm2>,<? pParm3>,<? pParm4>,<? pParm5>,<? pParm6>,<? pParm7>,<? pParm8>,<? pParm9>,<? pParm10>,<? pParm11>,<? pParm12>,<? pParm13>,<? pParm14>,<? pParm15>,<? pParm16>,<? pParm17>,<? pParm18>,<? pParm19>,<? pParm20>)
  code
  self.SetError(NoDriverSupport)
  Return

!-----------------------------------------------------------------
! clear fields based on type. If memos and blobs clear those too.
! also calls ClearProps
DriverFileClass.CLEARFILE        PROCEDURE(Long pWhat)
x  long
  Code
  If self._opened = 0 then self._UpdateFileStrings().
  Loop x = 1 to self.SharedProperties.FieldList.nodes
    self.Fields &= self._withFieldNode(x)
    If not self.Fields.Interface &= null
      self.Fields.Interface.ClearRecordField(self.Fields.Type, self.ClaFCB.rec_buf + self.Fields.offset ,self.Fields.Size,'')
    Else
      Case self.Fields.Type
      of ClaSTRING
        MemSet(self.ClaFCB.rec_buf + self.Fields.Offset,32, self.Fields.Size * self.Fields.DimProduct)
      of ClaCSTRING
        MemSet(self.ClaFCB.rec_buf + self.Fields.Offset,0, self.Fields.Size * self.Fields.DimProduct)
      of ClaPSTRING
        MemSet(self.ClaFCB.rec_buf + self.Fields.Offset,0, self.Fields.Size * self.Fields.DimProduct)
      of ClaGROUP
        If self.Fields.Dims
          !!!todo clear Group Arrays
        End
      Else
        MemSet(self.ClaFCB.rec_buf + self.Fields.Offset,0, self.Fields.Size * self.Fields.DimProduct)
      End
    End
  End
  Loop x = 1 to Records(self.Blobs)
    Get(self.Blobs,x)
    self.SetBlob(x,'')
  End
  self.ClearProps()
  Return

!-----------------------------------------------------------------
! derived class must call parent AFTER loading the record
DriverFileClass.CLOSE            PROCEDURE()
  Code
  If self._inTransaction = True and self._transactionPrimary = true
    self.SetError(LogActiveErr)
    Return
  End
  ! anything touching the database needs to happen before it starts closing.
  !self.ResumeRelations()

  parent.Close() ! will call FLUSH to empty buffers
  self.pool = 0
  self._transactionPrimary = false
  If Errorcode() then Return.
  Self._WatchCmdOff()
  self._watchBufferState = watch:off
  Dispose(self.WatchBuffer)
  Dispose(self.Project)
  !self.trace('DriverFileClass.CLOSE : In closing, the blobs are disposed here')
  self._ClearBlobs()
  self._opened = false
  self._Bytes = 0
  self.SetError(NoError)
  self.SetStatus(0)
  Self.SetMethod = driver:NotSet
  If self._FullPathNameSetFromPropName = false
    self.FullPathName = clip(self._GetString(self.ClaFCB.phyname))
  End
  self._FullPathNameSetFromPropName = false
  If self._OwnerSetFromPropOwner = false
    self.Owner = clip(self._GetString(self.ClaFCB.oname))
  End
  self._OwnerSetFromPropOwner = false
  self.SetKey &= Null
  self.SetKeyKey &= Null
  Return

!-----------------------------------------------------------------
DriverFileClass.CONNECT            PROCEDURE(Long pOptions=0)
  Code
  self.SetError(NoDriverSupport)
  Return

!-----------------------------------------------------------------
DriverFileClass.DECLARATION               Procedure(Long pOptions)
  Code
  self.SetError(NoDriverSupport)
  Return ''

!-----------------------------------------------------------------
DriverFileClass.DECLARATION               Procedure(Key pKey,Long pOptions)
  Code
  self.SetError(NoDriverSupport)
  Return ''

!-----------------------------------------------------------------
DriverFileClass.DISCONNECT         PROCEDURE()
  Code
  self.SetError(NoDriverSupport)
  Return

!-----------------------------------------------------------------
DriverFileClass.COPY             PROCEDURE(STRING pNewFileName, Long pOptions)
  Code
  self.SetError(NoDriverSupport)
  Return

!-----------------------------------------------------------------
DriverFileClass.CreateDB      PROCEDURE(String pDatabaseName)
  code
  self.SetError(NoDriverSupport)
  Return

!-----------------------------------------------------------------
DriverFileClass.CREATETABLE      PROCEDURE()
  Code
  !self.trace('DriverFileClass.CREATETABLE ' & self.FullPathName)
  If  self.SharedProperties &= NULL
    self.trace('DriverFileClass.CREATETABLE Shared Properties is NULL')
  End

  If self.SharedProperties.Create = false
    self.SetError(NoCreateErr)
    return
  End
  If self._CheckClosed() = false
    Return
  End
  self.SetError(NoError)
  self._UpdateFileStrings()
  self._CreateTable()
  Return

!-----------------------------------------------------------------
DriverFileClass.CLONE            Procedure(String pNewTableName,Long pOptions)
  code

!-----------------------------------------------------------------
! assumes self.fields is loaded. Called from CreateTable, so self.SqlCode updated.
DriverFileClass._CreateValidation      PROCEDURE()
check  StringTheory
  Code
  If self.Fields.Boolean
    case self.fields.Type
    of ClaBYTE
    orof ClaSHORT
    orof ClaUSHORT
    orof ClaLONG
    orof ClaULONG
    orof ClaREAL
    orof ClaSREAL
    orof ClaDECIMAL
    orof ClaPDECIMAL
      If self.fields.NotNull
        self.SqlCode.append(' NOT NULL CONSTRAINT check_' & self.FullPathName & '_' & self.Fields.Column & ' CHECK (' & self.Fields.column & ' IN (0, 1))')
      Else
        self.SqlCode.append(' CONSTRAINT check_' & self.FullPathName & '_' & self.Fields.Column & ' CHECK (' & self.Fields.column & ' IN (0, 1) OR ' & self.Fields.column & ' IS NULL)')
      End
      Return
    of ClaString
    orof ClaCString
    orof ClaPString
      If self.fields.NotNull
        self.SqlCode.append(' NOT NULL CONSTRAINT check_' & self.FullPathName & '_' & self.Fields.Column & ' CHECK (' & self.Fields.column & ' IN (''0'', ''1''))')
      Else
        self.SqlCode.append(' CONSTRAINT check_' & self.FullPathName & '_' & self.Fields.Column & ' CHECK (' & self.Fields.column & ' IN (''0'', ''1'') OR ' & self.Fields.column & ' IS NULL)')
      End
      Return
    End
  End
  check.SetValue('')
  If not self.Fields.GreaterThan &= null
    check.append( self.Fields.column & ' ' & self.Fields.GreaterThan,,' AND ')
  end
  If not self.Fields.LessThan &= null
    check.append( self.Fields.column & ' ' & self.Fields.LessThan,,' AND ')
  end
  If not self.Fields.NotEqual &= null
    check.append( self.Fields.column & ' ' & self.Fields.NotEqual,,' AND ')
  end
  If not self.Fields.Inlist &= null
    check.append( self.Fields.column & ' IN (' & self.Fields.InList &')',,' AND ')
  end
  if not self.fields.Validate &= NULL
    check.Append(self.fields.validate,,' AND ')
  End
  If Check.Length()
    If self.fields.NotNull
      self.SqlCode.append(' NOT NULL CONSTRAINT check_' & self.FullPathName & '_' & self.Fields.Column & ' CHECK (' & check.getvalue() & ')' )
    Else
      self.SqlCode.append(' CONSTRAINT check_' & self.FullPathName & '_' & self.Fields.Column & ' CHECK ((' & check.getvalue() & ') OR ' & self.Fields.column & ' IS NULL)')
    End
  ElsIf self.fields.NotNull
    self.SqlCode.append(' NOT NULL')
  End
  Return

!-----------------------------------------------------------------
!Called from CreateTable, so self.SqlCode updated.
DriverFileClass._CreateDefault   Procedure(Long pHasDefault, Long pType, String pDefault)
  Code
  If pHasDefault
    Case pType
    of ClaCSTRING
    orof ClaSTRING
    orof ClaPSTRING
    orof ClaMEMO
    orof ClaBLOB
      If Sub(pDefault,1,1) = ''''
        self.SqlCode.Append(' DEFAULT ' & pDefault)
      Else
        self.SqlCode.Append(' DEFAULT ''' & pDefault & '''')
      End
    Else
      If Numeric(pDefault)                     ! important for date etc
        self.SqlCode.Append(' DEFAULT ' & pDefault)
      Else
        self.SqlCode.Append(' DEFAULT ''' & pDefault & '''')
      End
    End
  End
  Return

!-----------------------------------------------------------------
DriverFileClass._CreateForeignKeys      PROCEDURE()
x             Long,auto
i             Long,auto
obj           &DriverFileClass
childlist     StringTheory
parentlist    StringTheory
  Code
  ! foreign keys, based on relationships
  Loop x = 1 to Records(self.relations)
    Get(self.relations,x)
    If self.relations.ParentFile &= null then cycle.
    obj &= self.relations.ParentFile{prop:object}
    If obj &= null then cycle.
    childlist.SetValue('')
    parentlist.SetValue('')
    Loop i = 1 to maximum(self.relations.ChildIndex,1)
      If self.relations.ChildIndex[i] = 0 then break.
      If self._withField(self.relations.ChildIndex[i]) = driver:ok and obj._withField(self.relations.ParentIndex[i]) = driver:ok
        ChildList.Append(self.fields.Column,,',')
        ParentList.Append(obj.fields.Column,,',')
      End
    End
    !self.trace('creating FOREIGN KEY (' & childlist.GetValue() & ') REFERENCES ' & obj.FullPathName & '(' & parentlist.GetValue() & ') ' & self.relations.OnUpdate & ' ' & self.relations.OnDelete)
    self.SqlCode.Append(',<13,10>FOREIGN KEY (' & childlist.GetValue() & ') REFERENCES ' & obj.FullPathName & '(' & parentlist.GetValue() & ')')
    Case self.relations.OnUpdate
    Of driver:NoAction
      self.SqlCode.Append(' ON UPDATE NO ACTION')
    Of driver:CascadeUpdate
      self.SqlCode.Append(' ON UPDATE CASCADE')
    Of driver:ClearUpdate
      self.SqlCode.Append(' ON UPDATE SET NULL')
    Of driver:RestrictUpdate
      self.SqlCode.Append(' ON UPDATE RESTRICT')
    End
    Case self.relations.OnDelete
    Of driver:NoAction
      self.SqlCode.Append(' ON DELETE NO ACTION')
    Of driver:CascadeDelete
      self.SqlCode.Append(' ON DELETE CASCADE')
    Of driver:ClearDelete
      self.SqlCode.Append(' ON DELETE SET NULL')
    Of driver:RestrictDelete
      self.SqlCode.Append(' ON DELETE RESTRICT')
    End
  End

!-----------------------------------------------------------------
DriverFileClass._CREATETABLE      PROCEDURE()
  Code
  Return


!-----------------------------------------------------------------
DriverFileClass.CREATEFIELD       PROCEDURE(*? pField1)
  Code
  self.SetError(NoDriverSupport)
  Return

!-----------------------------------------------------------------
DriverFileClass.CREATEFIELD      PROCEDURE(String pName, String pType, String pConstraint)
  Code
  self.SetError(NoDriverSupport)
  Return

!-----------------------------------------------------------------
DriverFileClass.CREATEKEY         PROCEDURE(KEY pKey)
  Code
  self.SetError(NoDriverSupport)
  Return

!-----------------------------------------------------------------
DriverFileClass.CREATEKEY         PROCEDURE(String pName, Long pOptions, *? pField1, *? pField2, <*? pField3>, <*? pField4>, <*? pField5>, <*? pField6>, <*? pField7>, <*? pField8>, <*? pField9>, <*? pField10>)
  Code
  self.SetError(NoDriverSupport)
  Return


!-----------------------------------------------------------------
DriverFileClass.CREATERELATIONS   PROCEDURE()
  code
  self.SetError(NoDriverSupport)
  Return

!-----------------------------------------------------------------
DriverFileClass.DUPLICATE         PROCEDURE()
x  long
k  &key
  Code
  Loop x = 1 to records(self.keys)
    Get(self.keys,x)
    If self.keys.dup then cycle.
    k &= (self.keys.keyptr)
    If self.Duplicate(k) then return true. ! will / should change opcode to Opcode:DUPLICATEKey
  End
  Return false

!-----------------------------------------------------------------
DriverFileClass.DUPLICATE        PROCEDURE(KEY pKey)
  Code
  self.SetError(NoDriverSupport)
  Return 0

!-----------------------------------------------------------------
DriverFileClass.EMPTY            PROCEDURE()
  Code
  If self._CheckOpen() = false then Return.
  self.SetError(NoError)
  Return

!-----------------------------------------------------------------
DriverFileClass.EOF              PROCEDURE()
  Code
  self.SetError(NoDriverSupport)
  Return false

!-----------------------------------------------------------------
DriverFileClass.EXISTS           PROCEDURE(String pTablename)     ! new command
  Code
  self.SetError(NoDriverSupport)
  Return false

!-----------------------------------------------------------------
DriverFileClass.EXISTS           PROCEDURE(Long pWhat,String pName)     ! new command
  Code
  self.SetError(NoDriverSupport)
  Return false

!-----------------------------------------------------------------
DriverFileClass.EXISTSDB         PROCEDURE(String pTablename)     ! new command
  Code
  self.SetError(NoDriverSupport)
  Return false

!-----------------------------------------------------------------
DriverFileClass.EXPORT           PROCEDURE(String pDosFileName, Long pOptions=0,Long pFormat=0)
  Code
  If self._CheckOpen() = false then Return driver:notok.
  If self._justset = false
    self.SetError(BadRecErr)
    Return driver:notok
  End
  self.SetError(NoError)
  Case pFormat
  of driver:json
  of driver:xml
  of driver:csv
    Return self.EXPORTCSV(pDosFileName,pOptions)
  Else
    Return self.EXPORTCSV(pDosFileName,pOptions)
  End

!-----------------------------------------------------------------
DriverFileClass.EXPORTCSV        PROCEDURE(String pDosFileName, Long pOptions=0)
  Code
  self.SetError(NoDriverSupport)
  Return driver:notok

!-----------------------------------------------------------------
DriverFileClass.FREESTATE        PROCEDURE(Long pState)
x  Long,Auto
y  Long,Auto
  code
  If pState = 0
    Loop x = 1 to records(self.state)
      Get(self.state,x)
      do FreeOneState
    End
    Free(self.state)
  Else
    self.state.id = pState
    Get(self.state,self.state.id)
    If ErrorCode() = NoError
      do FreeOneState
      Delete(self.state)
    Else
      self.SetError(FileSystemErr)  ! Traditional drivers may GPF here (freeing memory that isn't valid).
    End
  End

FreeOneState  routine
  Dispose(self.State.Record)
  Dispose(self.State._Buffer)
  Dispose(self.State.Level1)
  Dispose(self.State.Level2)
  Dispose(self.State.Level3)
  Dispose(self.State.Level4)
  Dispose(self.State.Level5)
  Dispose(self.State.Level6)
  Dispose(self.State.PropertyQueue)
  Dispose(self.State.OrderQueue)
  Dispose(self.State.BindQueue)
  Dispose(self.state.ShadowBuffer)
  Dispose(self.state.WatchBuffer)
  Dispose(self.state.Project)
  Dispose(self.state._ProjectClauses)
  Dispose(self.State.ProjectList)
  Dispose(self.State.SqlCode)
  Dispose(self.State.Filter)
  Dispose(self.State.SQLFilter)
  Dispose(self.State.Where)
  Dispose(self.State.WherePage)
  Dispose(self.State.Order)
  Dispose(self.State.SQLOrder)
  Dispose(self.State.OrderBy)
  Dispose(self.State.GroupBy)
  Dispose(self.State.Having)
  Dispose(self.State.Search)

  If not self.state.BlobPointers &= null
    Loop y = 1 to Records(self.state.BlobPointers)
      Get(self.state.BlobPointers,y)
      Dispose(self.state.BlobPointers.memory)
    End
    Free(self.state.BlobPointers)
    Dispose(self.state.BlobPointers)
  End

!-----------------------------------------------------------------
! GetState - aka SaveState
! Stores the file's current state including the record buffer and memos, file pointer, fullpathname, owner name,
!   open/close status and access mode, file sequencing order, and the error state of the system.
!   Optionally stores Blobs as well.
! Returns an id which identifies this state.
! Derived Classes call this parent first, which adds the queue record. They then add supplemental information, and do a PUT
!!!todo - review properties saved to see if any new ones have been added.
DriverFileClass.GETSTATE         PROCEDURE(Long pSaveBlob)!,LONG,VIRTUAL
x    Long,Auto
e    Long,Auto
len  Long,Auto
  code
  e = ErrorCode()
  self._nextstate += 1
  clear(self.state)

  self.state.id            = self._nextstate
  self.state.RecordPointer = self.RecordPointer
  self.state.RecordLength  = self.RecordLength
  self.state.SetPointer    = self.SetPointer
  self.state.Errorcode     = ErrorCode()
  self.state.Error         = Error()
  self.state.FileErrorCode = FileErrorCode()
  self.state.FileError     = FileError()
  self.state.FullPathName  = self.FullPathName
  self.state.owner         = self.owner
  self.state.status        = self.Status()
  self.state.Record       &= new string(self.ClaFCB.rec_len)
  MemCpy(address(self.state.Record),self.ClaFCB.rec_buf,self.ClaFCB.rec_len)

  If Records(self.blobs)
    self.state.BlobPointers &= new BlobPointersQueueType
    Loop x = 1 to records(self.blobs)
      Get(self.blobs,x)
      If self.blobs.Memo ! memos are saved even if blobs aren't
        self.state.BlobPointers.index = x
        len = len(clip(self.file{prop:value,-x}))
        self.state.BlobPointers.memory &= new String(len)
        self.state.BlobPointers.memory = clip(self.file{prop:value,-x})
        add(self.state.BlobPointers)
      ElsIf pSaveBlob
        self.state.BlobPointers.index = x
        len = self.file{prop:size,-x}
        if len
          self.state.BlobPointers.memory &= new String(len)
          self.state.BlobPointers.memory = self.file{prop:value,-x}
          add(self.state.BlobPointers)
        End
      End
    End
  End
  ! this code is not in the Base object, because SaveState does not apply to VIEWS.  So it's done here instead
  ! BASE object properties
  len = address(self.__BASESTATEEND) - address(self.__BASESTATESTART)
  self.State.Level1 &= new String(len)
  MemCpy(address(self.State.Level1),address(self.__BASESTATESTART),len)

  ! Base Object Pointers
  If not self.PropertyQueue &= null
    self.state.PropertyQueue &= new PropertyQueueType  ! custom properties
    Loop x = 1 to Records(self.PropertyQueue)
      Get(self.PropertyQueue,x)
      self.state.PropertyQueue = self.PropertyQueue
      Add(self.State.PropertyQueue)
    End
  End
  If not self.OrderQueue &= null
    self.state.OrderQueue &= new OrderQueueType  ! custom properties
    Loop x = 1 to Records(self.OrderQueue)
      Get(self.OrderQueue,x)
      self.state.OrderQueue = self.OrderQueue
      Add(self.State.OrderQueue)
    End
  End
  If not self.BindQueue  &= null
    self.state.BindQueue &= new BindQueueType  ! custom properties
    Loop x = 1 to Records(self.BindQueue)
      Get(self.BindQueue,x)
      self.state.BindQueue = self.BindQueue
      Add(self.State.BindQueue)
    End
  End

  ! FILE object properties
  len = address(self.__FILESTATEEND)- address(self.__FILESTATESTART)
  self.State.Level2 &= new String(len)
  MemCpy(address(self.State.Level2),address(self.__FILESTATESTART),len)

  ! File Object Pointers
  If not self._ProjectClauses &= null
    self.State._ProjectClauses &= new StringTheory
    self.State._ProjectClauses.SetValue(self._ProjectClauses)
  End

  If Not self.Project &= null
    self.State.Project &=  new Cstring(size(self.Project))
    self.State.Project = self.Project
  End

  If Not self.ShadowBuffer &= null
    self.State.ShadowBuffer &=  new String(size(self.ShadowBuffer))
    self.State.ShadowBuffer = self.ShadowBuffer
  End

  If Not self.WatchBuffer &= null
    self.State.WatchBuffer &=  new String(size(self.WatchBuffer))
    self.State.WatchBuffer = self.WatchBuffer
  End
  Add(self.state)
  self.SetError(e)      ! GetState should not alter errorcode.
  Return self.state.id

!-----------------------------------------------------------------
DriverFileClass.IMPORT           PROCEDURE(String pDosFileName, Long pOptions=0,Long pFormat=0)
  Code
  !self.trace('DriverFileClass.IMPORT  pFormat=' & pFormat)
  If self._CheckOpen() = false then Return driver:notok.
  self.SetError(NoError)
  Case pFormat
  of driver:json
  of driver:xml
  of driver:csv
    Return self.IMPORTCSV(pDosFileName,pOptions)
  Else
    Return self.IMPORTCSV(pDosFileName,pOptions)
  End

!-----------------------------------------------------------------
DriverFileClass.IMPORTCSV        PROCEDURE(String pDosFileName, Long pOptions=0)
  Code
  self.SetError(NoDriverSupport)
  Return driver:notok

!-----------------------------------------------------------------
DriverFileClass.LOCK             PROCEDURE()
  Code
  self.Lock(-1)
  Return

!-----------------------------------------------------------------
! Clarion calls LOCK as part of the transaction process, so requires that it returns errors free.
DriverFileClass.LOCK             PROCEDURE(LONG Seconds)
  Code
  self.SetError(NoError)
  Return

!-----------------------------------------------------------------
DriverFileClass.LOGBUFFER                  Procedure()
x  Long,Auto
  code
  PushErrors()
  Loop x = 1 to self.SharedProperties.FieldList.nodes
    self.Fields &= self._withFieldNode(x)
    self.Log('[DATA]  ' & self.fields.Label & ' | ' & self.GetPROP:Text(x))
  End
  If self._opened
    Loop x = 1 to Records(self.blobs)
      get(self.blobs,x)
      self.Log('[DATA]  ' & self.blobs.Label & ' | ' & self.GetPROP:Text(-x))
    End
  End
  PopErrors()
  Return

!-----------------------------------------------------------------
DriverFileClass.NAME             PROCEDURE()
  Code
  self.SetError(NoError)
  return self.GetProp:name()

!-----------------------------------------------------------------
! This is called BEFORE the derived class. So this has no access to the actual file or database table.
!!! DERIVE
DriverFileClass.OPEN             PROCEDURE(LONG pAccessMode=022h)
x  long
  Code
  parent.Open()                        ! base class clears all settings.
  If Errorcode() then return.
  self._SetSourceSize()                ! calculates the size of the record on the database side. Custom Fields allows the database to have a different size to the file record.
  Self.SetMethod = driver:NotSet
  self.SetPointer = driver:SetBoundary
  self._recordloaded   = false
  self.SetError(NoError)
  If self._opened
    self.SetError(IsOpenErr)
    Return
  End
  Loop x = 1 to Records(self.blobs)
    Get(self.blobs,x)
    If self.blobs.memo and self.blobs.memosize
      self._newMemoMemory(self.blobs.memosize)
      Put(self.blobs)
    End
  End
  self._UpdateFileStrings()
  If self.FullPathName = ''
    self.SetError(BadNameErr)
    Return
  End

  ! first apply System-wide driver string for all files of this driver
  compile('!***',_C100_=1)
  self.Send(System{'Driver:' & self.GetPROP:Driver()})       ! available from Clarion 10.11975 --- October 27, 2015
  !***
  ! Then apply the driver string for this table
  ClaActivateDriver(address(self.ClaFCB), 0, self.GetPROP:SupportsOp(Opcode:LOGOUTdrv), self.GetPROP:SupportsOp(Opcode:ROLLBACKdrv), |
                  self.GetPROP:SupportsOp(Opcode:COMMITdrv), self.GetPROP:SupportsOp(Opcode:LOCKfile), self.GetPROP:SupportsOp(Opcode:UNLOCK))
                  ! although ClaActivateDriver sets the access mode, that's done manually by AFTEROPEN and CLOSE so not done here.
                  ! this call is primarily here to NEW the FBlock.

  ! derived class must call .AfterOpen at the end, regardless of success or fail.
  self.WatchBuffer &= new String(self.ClaFCB.rec_len)
  Return

!-----------------------------------------------------------------
DriverFileClass.AfterOPEN             PROCEDURE(LONG pAccessMode=022h,Byte pOpened)
  code
  !self.trace('DriverFileClass.AfterOPEN ' & pAccessmode & ' ' & pOpened)
  self._opened = pOpened
  If pAccessMode = 0 then pAccessMode = ReadOnly + DenyNone.
  If self._opened
    self.Send(self.DriverStr)
    self.SetStatus(pAccessMode)
    If band(pAccessMode,11b) = 0
      self.ReadOnly = true
    Else
      self.ReadOnly = false
    End
  Else
    self.SetStatus(0)
  End
  Return

!-----------------------------------------------------------------
DriverFileClass.PACK             PROCEDURE()
  Code
  self.SetError(NoDriverSupport)
  Return

!-----------------------------------------------------------------
DriverFileClass.POINTER          PROCEDURE()
  Code
  self.SetError(NoDriverSupport)
  Return 0

!-----------------------------------------------------------------
DriverFileClass.POINTER          PROCEDURE(KEY pKey)
  Code
  self.SetError(NoDriverSupport)
  Return 0

!-----------------------------------------------------------------
! This is sufficient for files that have record pointers
! Aside: In SQL, POSITION returns the primary key values
DriverFileClass.POSITION         PROCEDURE()
rp     string(8),over(self.RecordPointer)  ! RecordPointer and RecordLength are declared as BigInt.
rl     string(8),over(self.RecordLength)   !
  Code
  If self._CheckOpen() = 0 then Return ''.
  self._poslen = 16
  self.SetError(NoError)
  Return rp & rl                             ! so position is just a record number, and length.

!-----------------------------------------------------------------
! returns a unique string that identifies the position in the file via the primary key
! This allows REGET to work on just the primary key part.
DriverFileClass.POSITION         PROCEDURE(KEY pKey)
x  long,auto
  Code
  If self._CheckOpen() = 0 then Return ''.
  If self._recordloaded = false
    self.SetError(BadRecErr)
    Return ''
  End
  If self._ProjectedPrimary = false
    self.SetError(BadProjectErr)
    Return ''
  End
  Return self._GetPrimaryKeyPosition(x)

!-----------------------------------------------------------------
! Takes in a POSITION string, and moves the contents of the primary key fields into the nominated buffer
DriverFileClass._SetPrimaryKeyPosition       PROCEDURE(String pPosition,Long pBuffer,*Long rLen)
x           Long,Auto
Pos         Long
Addr        Long
  Code
  Case pBuffer
  Of driver:shadow
    addr = address(self.ShadowBuffer)
  Else
    addr = self.ClaFCB.rec_buf
  End
  rLen = 0
  Loop x = 1 to self.SharedProperties._PKComponents
    If len(pPosition) <  pos + self.SharedProperties._PKcomponentLength[x]
      self.SetError(NoRecErr)
      Return
    End
    memcpy(addr + self.SharedProperties._PKcomponentOffset[x], address(pPosition)+ pos , self.SharedProperties._PKcomponentLength[x])
    pos += self.SharedProperties._PKcomponentLength[x]
    rLen += self.SharedProperties._PKcomponentLength[x]
  End
  Return

!-----------------------------------------------------------------
! gets the contents of the primary key of the record, and puts it into a POSITION string, which is then returned.
DriverFileClass._GetPrimaryKeyPosition       PROCEDURE(*Long rLength)
PosStr      String(DRIVER:MAX_PRIMARY_KEY_SIZE)
x           Long,Auto
  Code
  rLength = 0
  Loop x = 1 to self.SharedProperties._PKComponents
    memcpy(address(PosStr)+ rLength, self.ClaFCB.rec_buf + self.SharedProperties._PKcomponentOffset[x] , self.SharedProperties._PKcomponentLength[x])
    rLength +=  self.SharedProperties._PKcomponentLength[x]
  End
  If rLength = 0 then return ''.
  Return PosStr[1 : rLength]

!!-----------------------------------------------------------------
!! pStr must be a POSITION string returned from calling POSITION(pKey) on the same key as is here.
!! populate that position string into the shadow buffer
DriverFileClass._FillShadowBufferFromPosition  Procedure(KEY pKey, STRING pStr)
ans     string(50000) ! arbitrarily large
strpos  long(1)
x       long,auto
  code
  If self._WithPrimaryKey() = Driver:ok ! first add on the primary key fields to ensure uniqueness.
    do ProcessKey
    If pKey &= (self.keys.keyptr) or pKey &= null then Return.
  End
  If self._WithKey(pKey) = Driver:ok
    do ProcessKey
  End
  Return

ProcessKey  routine
  Loop x = 1 to self.keys.components
    If self._WithField(self.keys.component[x]) = driver:ok
      self.ShadowBuffer[self.Fields.Offset + 1 : self.Fields.Offset + self.Fields.Length]  = pStr[strpos : strpos + self.Fields.Length -1]
      strpos += self.Fields.Length
    End
  End
  self._PosLen = strpos

!-----------------------------------------------------------------
! derived class must call parent AFTER successfully loading the record, or setError(NoDriverSupport)
DriverFileClass.GETRANDOM          PROCEDURE(String pFilter)
  Code
  self._ParameterOpcode = Opcode:GETRANDOM
  self._AfterRead(Opcode:GETRANDOM)
  self._nomemo = self.NoMemoArmed
  self.NoMemoArmed = false
  self.AddOnly = false
  Return

!-----------------------------------------------------------------
DriverFileClass.RECORDS          PROCEDURE()
  Code
  self.SetError(NoDriverSupport)
  Return 0

!-----------------------------------------------------------------
DriverFileClass.RECORDSFILTER    PROCEDURE(String pFilter)
  Code
  self.SetError(NoDriverSupport)
  Return 0

!-----------------------------------------------------------------
DriverFileClass.RECORDS          PROCEDURE(*? pField1, <*? pField2>, <*? pField3>, <*? pField4>, <*? pField5>,<*? pField6>, <*? pField7>, <*? pField8>, <*? pField9>, <*? pField10>,<*? pField11>, <*? pField12>, <*? pField13>, <*? pField14>, <*? pField15>)
  Code
  self.SetError(NoDriverSupport)
  Return 0

!-----------------------------------------------------------------
DriverFileClass.RECORDS          PROCEDURE(KEY pkey)
  Code
  self.SetError(NoDriverSupport)
  Return 0

!-----------------------------------------------------------------
DriverFileClass.REMOVE           PROCEDURE()
  Code
  self.SetError(NoDriverSupport)
  Return

!-----------------------------------------------------------------
DriverFileClass.REMOVEFIELD           PROCEDURE(String pName)
  Code
  self.SetError(NoDriverSupport)
  Return

!-----------------------------------------------------------------
DriverFileClass.REMOVEKEY           PROCEDURE(String pName)
  Code
  self.SetError(NoDriverSupport)
  Return

!-----------------------------------------------------------------
DriverFileClass.REMOVEKEY           PROCEDURE(Key pKey)
  Code
  self.SetError(NoDriverSupport)
  Return

!-----------------------------------------------------------------
DriverFileClass.RENAME           PROCEDURE(STRING pNewFileName)
  Code
  self.SetError(NoDriverSupport)
  Return

!-----------------------------------------------------------------
! This is a new function, not in traditional drivers. It's called from RESTORESTATE.
! It's keeping everything the same, including the buffers, it just needs to change the
! AccessMode of the file that is currently open.
! Can also be called as file{prop:reopen,newmode} or file{'reopen',newmode}
!!! DERIVE
DriverFileClass.REOPEN           PROCEDURE(Long pAccessMode)
  code
  If pAccessMode = 0 then pAccessMode = ReadOnly + DenyNone.
  case self.Status()
  of pAccessMode
    Return
  Else
    self._locknames = true  ! name is set in Property, don't refresh from ClaFCB
    self.Open(pAccessMode)
    self._locknames = false
    Return
  End
  If Band(pAccessMode,11b) = 0
    self.ReadOnly = true
  Else
    self.ReadOnly = false
  End
  self.SetStatus(pAccessMode)
  Return

!-----------------------------------------------------------------
DriverFileClass.SHARE            PROCEDURE(LONG pAccessMode=042h)
  Code
  self.Open(pAccessMode)
  Return

!-----------------------------------------------------------------
! STATUS is not a FILE Driver function (there is no opcode for it).
! The RTL reads the value straight out of the FCB.fblock.openmode, which is effectivly self.fblock.openmode.
! The code is duplicated here so that the syntax object.Status() and self.status() will return the same value.
DriverFileClass.STATUS           PROCEDURE()!,LONG
  Code
  If self._opened
    Return self.ClaFcb.fblock.acc_mode
  End
  Return 0

!-----------------------------------------------------------------
DriverFileClass.SETSTATUS        PROCEDURE(Long pAccessMode)
  Code
  self.ClaFcb.fblock.acc_mode = pAccessMode
  ClaActivateDriver(address(self.ClaFCB), pAccessMode, 0,0,0,0,0)
  Return

!-----------------------------------------------------------------
DriverFileClass.STREAM           PROCEDURE()
  Code
  !self.SetError(NoDriverSupport)
  self.SetError(NoError)
  Return

!-----------------------------------------------------------------
DriverFileClass.TOQUEUE           PROCEDURE(Queue pQueue)
Len     Long,auto
nomemo  byte,auto
  Code
  !self.trace('DriverFileClass.TOQUEUE')
  If self._CheckOpen() = false then Return.
  If Size(pQueue) < self.ClaFCB.rec_len then len = Size(pQueue) else len = self.ClaFCB.rec_len.
  If Len = 0 then Return.
  nomemo = self.NoMemoArmed
  Self.NoMemo()
  If Self._HasBeenSet = false
    self.Set()
  End
  If Errorcode() then Return.
  Loop
    self.Next()
    If Errorcode() then break.
    MemCpy(address(pQueue),self.ClaFCB.rec_buf,len)
    Add(pQueue)
  End
  If Errorcode() = BadRecErr
    self.SetError(NoError)
  End
  self.NoMemoArmed = nomemo
  Return

!-----------------------------------------------------------------
DriverFileClass.FROMQUEUE           PROCEDURE(Queue pQueue)
x       Long,auto
Len     Long,auto
stream  byte ! definitly not ,auto
nomemo  byte,auto
  Code
  If self._CheckOpen() = false then Return.
  If Size(pQueue) < self.ClaFCB.rec_len then len = Size(pQueue) else len = self.ClaFCB.rec_len.
  If Len = 0 then Return.

  nomemo = self._nomemo
  self._nomemo = true
  If self._inTransaction = false and self._InStream   = false
    self.Stream()
    stream = true
  End
  Loop x = 1 to Records(pQueue)
    Get(pQueue,x)
    MemCpy(self.ClaFCB.rec_buf,address(pQueue),Len)
    self.Upsert()
  End
  If stream
    self.Flush()
  End
  self._nomemo = nomemo
  self.SetError(NoError)
  Return

!-----------------------------------------------------------------
! Clarion calls UNLOCK as part of the transaction process, so requires that it returns errors free.
DriverFileClass.UNLOCK           PROCEDURE()
  Code
  self.SetError(NoError)
  Return

!-----------------------------------------------------------------
DriverFileClass._PopulateUuidFields  Procedure()
uuid    string(16)
x       long
len     long
  code
  If self.SharedProperties.HasUUIDs = 1
    If self.SharedProperties.HasUUID and self._WithField(self.SharedProperties.HasUUID) = driver:ok
      do GenerateUUid
    End
  ElsIf self.SharedProperties.HasUUIDs > 1
    loop x = 1 to self.SharedProperties.FieldList.nodes
      self.Fields &= self._withFieldNode(x)
      If self.Fields.uuid
        do GenerateUUid
      End
    End
  End
  Return

GenerateUUid  routine
  If self.GetProp:Value(self.Fields.index) = ''
    case self.Fields.uuid
    of 4
      uuid = self.GenerateUUIDv4()
    of 7
      uuid = self.GenerateUUIDv7()
    else
      uuid = self.GenerateUUIDv8()
    end
    !self._ToRecordField(self.Fields.Type,self.ClaFCB.rec_buf + self.Fields.Offset,self.Fields.length,ClaString,address(uuid),size(uuid))
    If not self.Fields.interface &= null
      self.Fields.interface.ToRecordField(self.Fields.Type,self.ClaFCB.rec_buf + self.Fields.Offset,self.Fields.length,ClaString,address(uuid),size(uuid))
    Else
      len = size(uuid)
      If len > self.fields.Length then len = self.fields.length.
      memcpy(self.ClaFCB.rec_buf + self.Fields.Offset,address(uuid),len)
    End
  End

!-----------------------------------------------------------------
! Record Access Methods
!-----------------------------------------------------------------
! this parent is run before derived code
DriverFileClass._BeforeWrite      PROCEDURE(Long pOpCode)
  Code
  If self._CheckOpen() = false then Return.
  If Self.ReadOnly
    self.SetError(NoAccessErr)
    Return
  End
  self.SetError(NoError)
  Return

!-----------------------------------------------------------------
DriverFileClass.ADD              PROCEDURE()
  Code
  self._ParameterOpcode = Opcode:ADD
  self._WatchCmdOff()
  self._BeforeWrite(Opcode:ADD)
  If Errorcode() then Return.
  self._PopulateUuidFields()
  Return

!-----------------------------------------------------------------
DriverFileClass.ADD              PROCEDURE(LONG pLength)
  Code
  self._ParameterOpcode = Opcode:ADD
  self._WatchCmdOff()
  self._BeforeWrite(Opcode:ADDfilelen)
  If Errorcode() then Return.
  self._PopulateUuidFields()
  Return

!-----------------------------------------------------------------
DriverFileClass.APPEND           PROCEDURE()
  Code
  self._ParameterOpcode = Opcode:APPEND
  self._WatchCmdOff()
  self._BeforeWrite(Opcode:APPEND)
  If Errorcode() then Return.
  self._PopulateUuidFields()
  Return

!-----------------------------------------------------------------
! this parent is run before derived code
DriverFileClass.APPEND          PROCEDURE(LONG pLength)
  Code
  self._ParameterOpcode = Opcode:APPEND
  self._WatchCmdOff()
  self._BeforeWrite(Opcode:APPENDLen)
  If Errorcode() then Return.
  self._PopulateUuidFields()
  Return

!-----------------------------------------------------------------
DriverFileClass.DELETE           PROCEDURE()
  Code
  self._ParameterOpcode = Opcode:DELETE
  self._WatchCmdOff()
  self._BeforeWrite(Opcode:Delete)
  If Errorcode() then Return.
  If self._recordLoaded = false
    self.SetError(BadRecErr)
  ElsIf self.PrimaryKeyPosition = ''
    Self.SetError(BadRecErr)
  End
  Return

!-----------------------------------------------------------------
DriverFileClass.DELETE           PROCEDURE(String pFilter)
  Code
  self._ParameterOpcode = Opcode:DELETE
  self._WatchCmdOff()
  self._BeforeWrite(Opcode:Delete)
  If Errorcode() then Return.
  Return

!-----------------------------------------------------------------
! derived class must call parent AFTER loading the record
!!!todo, investigate GET, change fields GET(,0) DUPLICATE, PUT sequence. for ISAM case
DriverFileClass.GET              PROCEDURE(BIGINT pFilePointer)
  Code
  self._ParameterOpcode = Opcode:GET
  If pFilePointer = 0                 ! get(file,0) is a special case which doesn't invalidate the current record pointers
    Return
  ElsIf pFilePointer < 0
    self.RecordPointer = 0
    self._recordLoaded = false
    self._WatchCmdOff()
  Else
    self._AfterRead(Opcode:GET)
  End
  self.RecordLength = self.ClaFCB.rec_len
  self._nomemo = self.NoMemoArmed
  self.NoMemoArmed = false
  self.AddOnly = false
  Return

!-----------------------------------------------------------------
! derived class must call parent AFTER loading the record
DriverFileClass.GET              PROCEDURE(BIGINT pFilePointer, LONG pLength)
  Code
  self._ParameterOpcode = Opcode:GET
  if pFilePointer <= 0
    self.RecordPointer = 0
    self._recordLoaded = false
    self._WatchCmdOff()
  Else
    self._AfterRead(Opcode:GET)
  End
  self.RecordLength = pLength
  self._nomemo = self.NoMemoArmed
  self.NoMemoArmed = false
  self.AddOnly = false
  Return

!-----------------------------------------------------------------
! derived class must call parent AFTER successfully loading the record, or setError(NoDriverSupport)
DriverFileClass.GET              PROCEDURE(KEY pKey)
  Code
  self._ParameterOpcode = Opcode:GET
  self._AfterRead(Opcode:GET)
  self.RecordLength = self.ClaFCB.rec_len
  self._nomemo = self.NoMemoArmed
  self.NoMemoArmed = false
  self.AddOnly = false
  Return

!-----------------------------------------------------------------
! derived class must call parent AFTER loading the record
DriverFileClass.GET              PROCEDURE(KEY pKey, BIGINT pKeyPointer)
  Code
  self._ParameterOpcode = Opcode:GET
  self._AfterRead(Opcode:GET)
  self.RecordLength = self.ClaFCB.rec_len
  self._nomemo = self.NoMemoArmed
  self.NoMemoArmed = false
  self.AddOnly = false
  Return

!-----------------------------------------------------------------
DriverFileClass.HOLD             PROCEDURE()
  Code
  self.SetError(NoDriverSupport)
  Return

!-----------------------------------------------------------------
DriverFileClass.HOLD             PROCEDURE(LONG pSeconds)
  Code
  self.SetError(NoDriverSupport)
  Return

!-----------------------------------------------------------------
! Merge behaves like an COPY, but copies records into a destination file.
! This parent is called before the derived code
DriverFileClass.MERGE             PROCEDURE(File pDestination, LONG pOptions=0)
  Code
  self.SetError(NoDriverSupport)
  Return

!-----------------------------------------------------------------
DriverFileClass.MERGE             PROCEDURE(String pDestination, LONG pOptions=0)
  code
  self.SetError(NoDriverSupport)
  Return

!-----------------------------------------------------------------
! Derived class must call parent (ie this) AFTER loading the record
!!! DERIVE
DriverFileClass.NEXT             PROCEDURE()
  Code
  self._justset = false
  self._AfterRead(Opcode:NEXT)
  self._nomemo = self._nomemoset
  self.NoMemoArmed = false      ! for backwards compatibility this is turned off here, in case the developer did their NOMEMO between the SET and NEXT
  self.AddOnly = false
  Return

!-----------------------------------------------------------------
DriverFileClass.NOMEMO           PROCEDURE()
  Code
  self.NoMemoArmed = true
  Return

!-----------------------------------------------------------------
! derived class must call parent AFTER loading the record
DriverFileClass.PREVIOUS         PROCEDURE()
  Code
  self._justset = false
  self._AfterRead(Opcode:PREVIOUS)
  self._nomemo = self._nomemoset
  self.NoMemoArmed = false      ! for backwards compatibility this is turned off here, in case the developer did their NOMEMO between the SET and PREVIOUS
  self.AddOnly = false
  Return

!-----------------------------------------------------------------
! derived class must call parent BEFORE writing the record
DriverFileClass.PUT              PROCEDURE()
  Code
  self._ParameterOpcode = Opcode:PUT
  self._BeforeWrite(Opcode:PUT)
  If Errorcode() then Return.
  If self._recordLoaded = false
    self.SetError(BadRecErr)
    Return
  End
  self.SetError(NoError)
  self._WatchCheck()   ! if self._watchCmdState = watch:armed, then do the test before the write. Possibly sets Errorcode.
  Return

!-----------------------------------------------------------------
! derived class must call parent BEFORE writing the record
DriverFileClass.PUT              PROCEDURE(BIGINT pFilePointer)
  Code
  self._ParameterOpcode = Opcode:PUT
  self._BeforeWrite(Opcode:PUTfileptr)
  If Errorcode() then Return.
  !If self._recordLoaded = false !  ! This test is not done here, because PUT(pointer) is including the place to PUT, so a record does not need to be loaded.
  If pFilePointer < 0
    self.SetError(NoAccessErr)
    Return
  End
  self.SetError(NoError)
  self._WatchCheck()   ! if self._watchCmdState = watch:armed, then do the test before the write. Possibly sets Errorcode.
  Return

!-----------------------------------------------------------------
! derived class must call parent BEFORE saving the record
DriverFileClass.PUT              PROCEDURE(BIGINT pFilePointer, LONG pLength)
  Code
  self._ParameterOpcode = Opcode:PUT
  self._BeforeWrite(Opcode:PUTfileptrlen)
  If Errorcode() then Return.

  If self._CheckOpen() = false then Return.
  !If self._recordLoaded = false !  ! This test is not done here, because PUT(pointer) is including the place to PUT, so a record does not need to be loaded.
  If pFilePointer < 0 or pLength < 0
    self.SetError(NoAccessErr)
    Return
  End
  self.SetError(NoError)
  self._WatchCheck()   ! if self._watchCmdState = watch:armed, then do the test before the write. Possibly sets Errorcode.
  Return

!-----------------------------------------------------------------
DriverFileClass.RELEASE          PROCEDURE()
  Code
  self.SetError(NoDriverSupport)
  Return

!-----------------------------------------------------------------
! bear in mind that a completely blank string is still a valid "position".
DriverFileClass.REGET            PROCEDURE(STRING pPosition)
k       &key,auto
minlen  long(0)
x       long,auto
  Code
  If self._CheckOpen() = 0 then Return.
  self.SetError(NoError)
  self.SetProp:Project('')
  self._SetPrimaryKeyPosition(pPosition,driver:buffer,x)  ! x is a return value
  If Errorcode() then Return.
  If self._WithPrimaryKey() = Driver:ok
    k &= (self.keys.keyptr)
    self.Get(k)
  End
  Return

!-----------------------------------------------------------------
DriverFileClass.REGET            PROCEDURE(KEY pkey, STRING pPosition)
  Code
  self.Reget(pPosition)
  Return

!-----------------------------------------------------------------
! Defaults to using Primary key when "file order" is specified.
DriverFileClass.RESET            PROCEDURE(STRING pPosition)
  Code
  If self.primarykey &= null
    self._Set(driver:SetFilePos,driver:SetBoundary,nullkey,nullkey)
    If Errorcode() then return.
    self.ShadowBuffer  = pPosition
  Else
    self.Reset(self.primarykey,pPosition)
  End
  Return

!-----------------------------------------------------------------
! the RESET key determines the key used by the SET command.
DriverFileClass.RESET            PROCEDURE(KEY pKey, STRING pPosition)
x  Long,Auto
  Code
  self.Reget(pPosition)   ! reads in the whole record for the position.
  ! it's possible the REGET will fail if the row has since been deleted. RESET might continue to work though, as long as the pKey is the Primary Key.
  self._Set(driver:SetKeyPos,driver:SetBoundary,pKey,nullkey)
  If Errorcode() then return.
  self._SetPrimaryKeyPosition(pPosition,driver:shadow,x)
  Return

!-----------------------------------------------------------------
DriverFileClass.RESTORESTATE     PROCEDURE(Long pState, Byte pBuffer)
status    Long,Auto
x         Long,Auto
changed   Byte
Len       Long,Auto
  code
  !self.trace('DriverFileClass.RESTORESTATE ' & pState & ' buffer=' & pBuffer)
  self.state.id = pState
  Get(self.state,self.State.id)
  ! check if pState number valid
  If Errorcode()
    self.SetError(FileSystemErr) ! DOS Driver sets Error 90, via GPF, so mimic that here for now.
    self.SetFileError(NoRecErr,'Call to RestoreState : State ID not valid. [' & pState & ']')
    self.state.id = 0
    Return
  End
  ! is Valid

  ! Deal with table being open or closed, and if fullpathname or owner has changed.
  status = self.Status()
  If self.FullPathName <> self.state.FullPathName
    self.FullPathName = self.state.FullPathName
    changed = true
  End
  If self.Owner <> self.state.owner
    self.Owner = self.state.owner
    changed = true
  End
  If status = 0
    If Self.state.status
      self.Reopen(self.state.status)
      If Errorcode()
        !self.trace('1. RESTORESTATE After Reopen ' & Errorcode() & ' ' & Error() & ' name=' & self.FullPathName & ' state.name=' & self.state.FullPathName)
      End
    End
  Elsif self.state.status = 0
    self.Close()
  ElsIf changed
    self.Close()   ! filename has changed, so flushing buffers etc
    self.Reopen(self.state.status)
  ElsIf status <> self.state.status
    self.Reopen(self.state.status)  ! just change the access mode
    If Errorcode()
      !self.trace('2. RESTORESTATE After Reopen: ' & Errorcode() & ' ' & Error())
    End
  End
  !
  self.RecordPointer  = self.state.RecordPointer
  self.RecordLength = self.state.RecordLength
  self.SetPointer = self.state.SetPointer
  ! If pBuffer is set then the Record Buffer, and possibly blobs, needs to be restored
  If pBuffer
    MemCpy(self.ClaFCB.rec_buf,address(self.state.Record),self.ClaFCB.rec_len)
    If not self.state.BlobPointers &= NULL
      Loop x = 1 to records(self.state.BlobPointers)
        Get(self.state.BlobPointers,x)
        If self.state.BlobPointers.memory &= NULL
        End
        If self._WithBlob(self.state.BlobPointers.index) = driver:ok
          If not self.state.BlobPointers.memory &= null
            If self.blobs.Memo = true
              self.blobs.memostring = self.state.BlobPointers.memory
            Else
              self.file{prop:value,-self.blobs.index} = self.state.BlobPointers.memory ! self.blobs.index is a positive number, so add the -
            End
          End
        End
      End
    End
  End
  ! base object pointers
  If self.PropertyQueue &= null and self.state.propertyQueue &= null
  Else
    Free(self.PropertyQueue)
    Loop x = 1 to Records(self.state.PropertyQueue)
      Get(self.state.PropertyQueue,x)
      self.PropertyQueue = self.state.PropertyQueue
      Add(self.PropertyQueue)
    End
  End

  If self.OrderQueue &= null and self.state.OrderQueue &= null
  Else
    Free(self.OrderQueue)
    Loop x = 1 to Records(self.state.OrderQueue)
      Get(self.state.OrderQueue,x)
      self.OrderQueue = self.state.OrderQueue
      Add(self.OrderQueue)
    End
  End

  If self.BindQueue &= null and self.state.BindQueue &= null
  Else
    Free(self.BindQueue)
    Loop x = 1 to Records(self.state.BindQueue)
      Get(self.state.BindQueue,x)
      self.BindQueue = self.state.BindQueue
      Add(self.BindQueue)
    End
  End

  ! File Object Pointers
  If self._ProjectClauses &= null and self.state._ProjectClauses &= null
  ElsIf self.state._ProjectClauses &= null
    self._ProjectClauses.SetValue('')
  Else
    self._ProjectClauses.SetValue(self.state._ProjectClauses)
  End

  If self.Project &= null and self.state.Project &= null
  ElsIf self.state.Project &= null
    Dispose(self.Project)
  Else
    Dispose(self.Project)
    self.project &=  new Cstring(size(self.State.Project))
    self.Project = self.state.Project
  End

  If not (self.ShadowBuffer &= null and self.state.ShadowBuffer &= null)
    self.ShadowBuffer = self.state.ShadowBuffer
  End

  If self.WatchBuffer &= null and self.state.WatchBuffer &= null
  elsif self.WatchBuffer &= null
    self.WatchBuffer &= new String(self.ClaFCB.rec_len)
    self.WatchBuffer = self.state.WatchBuffer
  elsif self.state.WatchBuffer &= null
  else
    self.WatchBuffer = self.state.WatchBuffer
  End

  ! Base Object Properties
  len = address(self.__BASESTATEEND) - address(self.__BASESTATESTART)
  MemCpy(address(self.__BASESTATESTART),address(self.State.Level1),len)

  ! File Object Properties
  len = address(self.__FILESTATEEND) - address(self.__FILESTATESTART)
  MemCpy(address(self.__FILESTATESTART),address(self.State.Level2),len)

  ! do this last ! repeat in any derived methods
  Self.SetError(self.state.Errorcode)
  Self.SetFileError(self.state.FileErrorCode,self.state.FileError)

  Return

!-----------------------------------------------------------------
DriverFileClass.RESUMERELATIONS     PROCEDURE()
  code
  self.SetError(NoDriverSupport)
  Return

!-----------------------------------------------------------------
DriverFileClass.RESULTGET        PROCEDURE(BIGINT pRow)!,VIRTUAL
  code
  If pRow < 1 or pRow > self.Result.Rows()
    self.SetError(BadRecErr)
    Return
  End
  self._ResultRow = pRow
  self.ResultToRecord(self._ResultRow, self.ClaFcb.rec_buf ,true)
  self._AfterRead(Opcode:ResultGet)
  Return

!-----------------------------------------------------------------
! Get a row from the result set, and move it into the record.
! called from NEXT and PREVIOUS. Also from the returning part of ADD and APPEND.
! not called from GET or REGET because those bypass the result set and write straight to the record.
! This function could set the error to DataTruncatedError(132)  "Data retrieved from the database could not fit in the Clarion field"
DriverFileClass.ResultToRecord  Procedure(Long pRow, Long pAddressRecord, Byte pBlobs)
colname    cstring(255),auto
col        long,auto
index      long,auto
result     &iresultSet,auto
  Code
  result &= self.result
  Loop col = 1 to Result.Columns()
    colname = Result.GetColumnName(col)
    index = Result.GetColumnIndex(col)
    If self._WithField(index) = driver:ok
      self.ResultToField(result,pRow,col,pAddressRecord)
      if errorcode() then break.
    ElsIf index = 0 and self._WithFieldNamed(colname) = driver:ok
      self.ResultToField(self.result,pRow,col,pAddressRecord)
      if errorcode() then break.
    ElsIf pBlobs = Driver:Blobs and self._WithBlobNamed(colname) = driver:ok
      self.ResultToBlob(self.result,pRow,col)
      if errorcode() then break.
    elsIf not self.BindQueue &= null
      self.ResultToBind(pRow,col,colname)
      !if errorcode() then break.           ! Result To bind deliberately unsets errors
    End
  End
  !self.trace('result to record done err=' & errorcode())
  Return

!------------------------------------------------------
!  called from ResultToRecord, Blobs record is already loaded.
DriverFileClass.ResultToBlob  Procedure(iResultSet pResult, Long pRow, Long pColumn)
CellType      long
CellLen       BIGINT,auto
CellAddr      BIGINT,auto
rTextLen      Long ! do not ,Auto
  code
  self.result.GetCell(pRow,pColumn,CellType,CellAddr,CellLen)
  If self.blobs.Memo
    self._Morph(self.blobs.label,ClaMEMO,address(self.blobs.memostring),self.blobs.memosize,CellType,CellAddr,CellLen,0,false,rTextLen)
  else
    self._Morph(self.blobs.label,ClaBLOB,self.blobs.index,self.blobs.handlesize,CellType,CellAddr,CellLen,0,false,rTextLen)
  End
  Return

!------------------------------------------------------
DriverFileClass.ResultToBind  Procedure(Long pRow, Long pCol, *cstring pColName)
  code
  self.BindQueue.Name = upper(pColName)
  PushErrors()
  Get(self.BindQueue,self.BindQueue.Name)
  If Errorcode() = NoError
    self.ResultToBindField(pRow,pCol)
  End
  PopErrors()
  Return

!-----------------------------------------------------------------
! Fields that are included in prop:project, which are not part of the table structure, are resolved here.
DriverBaseClass.ResultToBindField   Procedure(Long pRow, Long pCol)
CellAddr   BIGINT,auto
CellLen    BIGINT,auto
CellType   Long,auto
rTextLen   Long
  code
  self.result.GetCell(pRow,pCol,CellType,CellAddr,CellLen)
  If not self.BindQueue.lg &= null
    self.bindqueue.lg = 0
    self._Morph(self.bindqueue.Name,ClaLONG,address(self.bindqueue.lg),4,CellType,CellAddr,CellLen,0,false,rTextLen)
  ElsIf not self.bindqueue.rl &= null
    self.bindqueue.rl = 0
    self._Morph(self.bindqueue.Name,ClaREAL,address(self.bindqueue.rl),8,CellType,CellAddr,CellLen,0,false,rTextLen)
  Elsif not self.bindqueue.st &= null
    self.bindqueue.st = ''
    self._Morph(self.bindqueue.Name,ClaSTRING,address(self.bindqueue.st),size(self.bindqueue.st),CellType,CellAddr,CellLen,0,false,rTextLen)
  Elsif not self.bindqueue.cst &= null
    self.bindqueue.cst = ''
    self._Morph(self.bindqueue.Name,ClaCSTRING,address(self.bindqueue.cst),size(self.bindqueue.cst),CellType,CellAddr,CellLen,0,false,rTextLen)
  End
  Return

!------------------------------------------------------
! This is called from the View. The number might be a field, or a blob
! if the index is a field then the field node is already loaded.
DriverFileClass.ResultToFieldNumber  Procedure(iResultSet pResult, Long pRow, Long pColumn, Long pFieldNumber,Long pOptions)
rType      Long
rLen       BIGINT,auto
rAddr      BIGINT,auto
  code
  !self.trace('ResultToFieldNumber ' & self.FullPathName & ' row=' & pRow & ' col=' & pColumn & ' fieldnum=' & pFieldNumber & ' field=' & self.fields.Column)
  If pFieldNumber > 0
    If Band(pOptions,driver:buffer)
      self.ResultToField(pResult,pRow,pColumn,self.ClaFCB.rec_buf)
    Else
      self.ResultToField(pResult,pRow,pColumn,address(self.ShadowBuffer))
    End
  ElsIf pFieldNumber < 0
    If self._WithBlob(pFieldNumber) = driver:ok
      self.ResultToBlob(pResult,pRow,pColumn )
    End
  End
  Return

!------------------------------------------------------
! self.fields queue already loaded
! pAddr is the location of the record buffer to move the field into.
DriverFileClass.ResultToField  Procedure(iResultSet pResult,Long pRow, Long pColumn, Long pAddr)
str          &String,auto
CellAddress  BIGINT,auto
CellLen      BIGINT,auto
Celltype     Long,Auto
rTextLen     Long
  code
  pResult.GetCell(pRow,pColumn,CellType,CellAddress,CellLen)
  If not self.Fields.Interface &= NULL
    self.Fields.interface.ToRecordField(self.Fields.Type,pAddr + self.Fields.Offset,self.Fields.length,CellType,CellAddress,CellLen)
  ElsIf self.Fields.DimProduct > 1                     ! field matching this column is an array. In SQLite this means a TEXT field, in JSON form. ! Parse the JSON and move the values into the record buffer
    str &= CellAddress & ':' & CellLen
    self._LoadArray(str,self.Fields.index)
  Else
    self._Morph(self.fields.Label,self.Fields.type,pAddr + self.Fields.Offset,self.Fields.Length,CellType,CellAddress,CellLen,self.fields.SqlTimeStamp,true,rTextLen)
  End
  Return

!-----------------------------------------------------------------
!!! Derive
! Some field types are stored in the database as "text" (or other raw value). Use this method
! to deformat that text. Specifically for DATETIME, DATE, TIME, DECIMAL, PDECIMAL types.
DriverFileClass.DeformatText           Procedure(String pText)
  Code
  Return pText

!-----------------------------------------------------------------
DriverFileClass.SEARCH                     Procedure(String pSearchString,<*? pField1>, <*? pField2>, <*? pField3>, <*? pField4>, <*? pField5>, <*? pField6>, <*? pField7>, <*? pField8>, <*? pField9>, <*? pField10>,<*? pField11>, <*? pField12>, <*? pField13>, <*? pField14>, <*? pField15>)
  code
  self.SetError(NoDriverSupport)
  Return

!-----------------------------------------------------------------
! This is the actual SET where all of the forms of SET end up.
! Classes that need to derive SET should therefor just derive this one method.
DriverFileClass._SET             PROCEDURE(Byte pSetMethod, BigInt pPointer,Key pSetKey, Key pSetKeyKey)
  Code
  !self.trace('_set')
  If self._CheckOpen() = false then Return.
  If pPointer < -1
    self.SetError(BadRecErr)
    self.SetMethod = driver:NotSet
    Return
  End
  self.SetError(NoError)
  self._justset = true
  Self._HasBeenSet = true
  self._HasBeenPropSql = false

  Self.SetMethod = pSetMethod
  self.SetPointer = pPointer
  self.NoMemoArmed = false
  self.SetKey &= pSetKey
  self.SetKeyKey &= pSetKeyKey
  If pPointer > 0
    self._SetOffset = pPointer - 1
  else
    self._SetOffset = 0
  End
  !self.trace('DriverFileClass._SET done pPointer= ' & pPointer & ' pSetMethod=' & pSetMethod)
  Return

!-----------------------------------------------------------------
DriverFileClass.SET              PROCEDURE()
  Code
  self._Set(driver:SetFile,driver:SetBoundary,nullkey,nullkey)
  Return

!-----------------------------------------------------------------
DriverFileClass.SET              PROCEDURE(Byte pSpacer=0,KEY pKey)
  Code
  self._Set(driver:SetFile,driver:SetBoundary,pKey,nullkey)
  Return

!-----------------------------------------------------------------
DriverFileClass.SET              PROCEDURE(BIGINT pSetPointer)
  Code
  self._Set(driver:SetFile,pSetPointer,nullkey,nullkey)
  Return

!-----------------------------------------------------------------
DriverFileClass.SET              PROCEDURE(KEY pKey)
  Code
  self._Set(driver:SetKey,0,pKey,nullkey)
  Return

!-----------------------------------------------------------------
DriverFileClass.SET              PROCEDURE(KEY pKey, KEY pStart)
  Code
  self._Set(driver:SetKeyKey,0,pKey,pStart)
  Return

!-----------------------------------------------------------------
DriverFileClass.SET              PROCEDURE(KEY pKey, BIGINT pSetPointer)
  Code
  self._Set(driver:SetKey,pSetPointer,pKey,nullkey)
  Return

!-----------------------------------------------------------------
DriverFileClass.SET              PROCEDURE(KEY pKey, KEY pStart, BIGINT pSetPointer)
  Code
  self._Set(driver:SetKeyKey,pSetPointer,pKey,pStart)
  Return


!-----------------------------------------------------------------
! Union, Except and Intersect are interesting because they're sent to the wrong object. So when it comes in here
! it's redirected to the correct object. The correct object is in a MODULE (threaded) variable, and is set by the SET
! command. So UNION, EXCEPT and INTERSECT all apply to the "file used by the last call to SET".
!-----------------------------------------------------------------
!-----------------------------------------------------------------
! so, this is the case direct from cwdriver, which does NOT include the actual SET file. So this call needs
! to be redirected to the correct object
DriverFileClass.SUBSET                     Procedure(*? pParm1,<*? pParm2>,<*? pParm3>,<*? pParm4>,<*? pParm5>,<*? pParm6>,<*? pParm7>,<*? pParm8>,<*? pParm9>,<*? pParm10>,<*? pParm11>,<*? pParm12>,<*? pParm13>,<*? pParm14>,<*? pParm15>,<*? pParm16>,<*? pParm17>,<*? pParm18>,<*? pParm19>,<*? pParm20>)
  Code
  If not FileSETObject &= null
    FileSETObject.Subset(self.file,pParm1,pParm2,pParm3,pParm4,pParm5,pParm6,pParm7,pParm8,pParm9,pParm10,pParm11,pParm12,pParm13,pParm14,pParm15,pParm16,pParm17,pParm18,pParm19,pParm20)
  ElsIf not ViewSETObject &= null
    ViewSETObject.Subset(self.file,pParm1,pParm2,pParm3,pParm4,pParm5,pParm6,pParm7,pParm8,pParm9,pParm10,pParm11,pParm12,pParm13,pParm14,pParm15,pParm16,pParm17,pParm18,pParm19,pParm20)
  Else
    ! call to SUBSET with no SET active
  End
  Return

!-----------------------------------------------------------------
! This is the object version
DriverBaseClass.SUBSET                     Procedure(FILE pFile,*? pParm1,<*? pParm2>,<*? pParm3>,<*? pParm4>,<*? pParm5>,<*? pParm6>,<*? pParm7>,<*? pParm8>,<*? pParm9>,<*? pParm10>,<*? pParm11>,<*? pParm12>,<*? pParm13>,<*? pParm14>,<*? pParm15>,<*? pParm16>,<*? pParm17>,<*? pParm18>,<*? pParm19>,<*? pParm20>)
ptr     Long,Auto
offset  Long,Auto
x       Long,Auto
obj     &DriverFileClass
  Code
  If self.SubsetQueue &= NULL
    self.SubsetQueue &= new SubsetQueueType
  End
  Clear(self.SubsetQueue)
  self.SubsetQueue.Operation = Opcode:Subset
  self.SubsetQueue.File &= pFile
  obj &= pFile{prop:object}
  If obj &= NULL
    self.SetError(NoDriverSupport)
    Return
  End
  Loop x = 1 To 20
    Execute x
       If Omitted(pParm1) Then Break Else Peek(address(pParm1) + 4,ptr).
       If Omitted(pParm2) Then Break Else Peek(address(pParm2) + 4,ptr).
       If Omitted(pParm3) Then Break Else Peek(address(pParm3) + 4,ptr).
       If Omitted(pParm4) Then Break Else Peek(address(pParm4) + 4,ptr).
       If Omitted(pParm5) Then Break Else Peek(address(pParm5) + 4,ptr).
       If Omitted(pParm6) Then Break Else Peek(address(pParm6) + 4,ptr).
       If Omitted(pParm7) Then Break Else Peek(address(pParm7) + 4,ptr).
       If Omitted(pParm8) Then Break Else Peek(address(pParm8) + 4,ptr).
       If Omitted(pParm9) Then Break Else Peek(address(pParm9) + 4,ptr).
       If Omitted(pParm10) Then Break Else Peek(address(pParm10) + 4,ptr).
       If Omitted(pParm11) Then Break Else Peek(address(pParm11) + 4,ptr).
       If Omitted(pParm12) Then Break Else Peek(address(pParm12) + 4,ptr).
       If Omitted(pParm13) Then Break Else Peek(address(pParm13) + 4,ptr).
       If Omitted(pParm14) Then Break Else Peek(address(pParm14) + 4,ptr).
       If Omitted(pParm15) Then Break Else Peek(address(pParm15) + 4,ptr).
       If Omitted(pParm16) Then Break Else Peek(address(pParm16) + 4,ptr).
       If Omitted(pParm17) Then Break Else Peek(address(pParm17) + 4,ptr).
       If Omitted(pParm18) Then Break Else Peek(address(pParm18) + 4,ptr).
       If Omitted(pParm19) Then Break Else Peek(address(pParm19) + 4,ptr).
       If Omitted(pParm20) Then Break Else Peek(address(pParm20) + 4,ptr).
    End
    Do GetField
    If ErrorCode() Then Break.
  End
  If ErrorCode() = NoError
    Add(self.SubsetQueue)
  End
  Return

GetField  routine
  If ptr >= obj.ClaFCB.rec_buf and ptr <= obj.ClaFCB.rec_buf + obj.ClaFCB.rec_len
    offset = ptr - obj.ClaFCB.rec_buf
    If obj._WithFieldOffset(offset,0) = driver:ok
      self.SubsetQueue.Name[x] = obj.fields.column
    else
      self.SetError(BadFieldErr)
    End
  else
    self.SetError(BadFieldErr)
  End

!-----------------------------------------------------------------
DriverFileClass.SUSPENDRELATIONS     PROCEDURE()
  code
  self.SetError(NoDriverSupport)
  Return

!-----------------------------------------------------------------
! so, this is the case direct from cwdriver, which does NOT include the actual SET file. So this call needs
! to be redirected to the correct object
DriverFileClass.UNION                      Procedure(<String pFilter>)
  Code
  If not FileSETObject &= null
    FileSETObject._AddSubsetCommand(Opcode:Union,self.file,pFilter)
  ElsIf not ViewSETObject &= null
    ViewSETObject._AddSubsetCommand(Opcode:Union,self.file,pFilter)
  End
  Return

!-----------------------------------------------------------------
DriverFileClass.UNIONALL                   Procedure(<String pFilter>)
  Code
  If not FileSETObject &= null
    FileSETObject._AddSubsetCommand(Opcode:UnionAll,self.file,pFilter)
  ElsIf not ViewSETObject &= null
    ViewSETObject._AddSubsetCommand(Opcode:UnionAll,self.file,pFilter)
  End
  Return

!-----------------------------------------------------------------
DriverFileClass.EXCEPT                     Procedure(<String pFilter>)
  Code
  If not FileSETObject &= null
    FileSETObject._AddSubsetCommand(Opcode:Except,self.file,pFilter)
  ElsIf not ViewSETObject &= null
    ViewSETObject._AddSubsetCommand(Opcode:Except,self.file,pFilter)
  End
  Return

!-----------------------------------------------------------------
DriverFileClass.INTERSECT                  Procedure(<String pFilter>)
  Code
  If not FileSETObject &= null
    FileSETObject._AddSubsetCommand(Opcode:Intersect,self.file,pFilter)
  ElsIf not ViewSETObject &= null
    ViewSETObject._AddSubsetCommand(Opcode:Intersect,self.file,pFilter)
  End
  Return

!-----------------------------------------------------------------
! this one is called into the correct file object, the object that did the SET. So the call gets added to the queue here.
DriverBaseClass._AddSubsetCommand                 Procedure(Byte pOperation, File pFile,<String pFilter>)
obj   &DriverFileClass
  Code
  If self.SubsetQueue &= NULL
    self.SubsetQueue &= new SubsetQueueType
  End
  obj &= pFile{prop:object}
  If obj &= NULL
    self.SetError(NoDriverSupport)
    Return
  End
  Clear(self.SubsetQueue)
  self.SubsetQueue.Operation = pOperation
  self.SubsetQueue.From = obj.FullPathName
  self.SubsetQueue.File &= pFile
  If not omitted(pFilter)
    self.SubsetQueue.Filter &= New String(size(pFilter))
    self.SubsetQueue.Filter = pFilter
  End
  Add(self.SubsetQueue)
  Return

!-----------------------------------------------------------------
DriverBaseClass.PrimeSubset                  Procedure()
  Code
  Return

!-----------------------------------------------------------------
DriverFileClass.PrimeSubset                  Procedure()
x  Long,Auto
  Code
  self.SubsetPrimaryFile &= self.file
  If self._WithPrimaryKey() = Driver:ok
    Loop x = 1 to self.keys.components
      If self._WithField(self.keys.component[x]) = Driver:ok
        If self.SubSetFields = ''
          self.SubSetFields = self._GetAlias(driver:withdot) & self.Fields.column
        Else
          self.SubSetFields = self.SubSetFields & ',' & self._GetAlias(driver:withdot) & self.Fields.column
        End
      End
    End
  End
  Return


!-----------------------------------------------------------------
DriverFileClass.SKIP               PROCEDURE(BIGINT pCount)
  Code
  If self._CheckOpen() = false then Return.
  If Self.SetMethod = driver:NotSet
    self.SetError(BadRecErr)
  Else
    self.SetError(NoError)
  End
  Return

!-----------------------------------------------------------------
DriverFileClass.UPDATE             PROCEDURE(String pFilter,*? pField1,String pValue1,<*? pField2>,<String pValue2>,<*? pField3>,<String pValue3>,<*? pField4>,<String pValue4>,<*? pField5>,<String pValue5>,<*? pField6>,<String pValue6>,<*? pField7>,<String pValue7>,<*? pField8>,<String pValue8>,<*? pField9>,<String pValue9>,<*? pField10>,<String pValue10>)
  Code
  self.SetError(NoDriverSupport)
  Return

!-----------------------------------------------------------------
DriverFileClass.UPDATE             PROCEDURE(Key pKey,*? pField1,String pValue1,<*? pField2>,<String pValue2>,<*? pField3>,<String pValue3>,<*? pField4>,<String pValue4>,<*? pField5>,<String pValue5>,<*? pField6>,<String pValue6>,<*? pField7>,<String pValue7>,<*? pField8>,<String pValue8>,<*? pField9>,<String pValue9>,<*? pField10>,<String pValue10>)
  Code
  self.SetError(NoDriverSupport)
  Return

!-----------------------------------------------------------------
! Upsert behaves like an ADD, but if a DUPLICATE error occurs then the record is PUT instead.
! This parent is called before the derived code
DriverFileClass.UPSERT             PROCEDURE()
  Code
  If self._CheckOpen() = false then Return.
  self._ParameterOpcode = Opcode:UPSERT
  self._WatchCmdOff()
  self._BeforeWrite(Opcode:Upsert)
  If Errorcode() then Return.
  self._PopulateUuidFields()
  Return

!-----------------------------------------------------------------
! called by the program to "arm" the WATCH function for the next GET, REGET, NEXT or PREVIOUS
DriverFileClass.WATCH              PROCEDURE()
  Code
  If self._CheckOpen() = false then Return.
  self._watchCmdState = Watch:on
  !self.trace('DriverFileClass._WatchCmdArm self._watchCmdState = watch:on')
  self.SetError(NoError)
  Return

!-----------------------------------------------------------------
! called by the driver if a PUT or CLOSE is done, or if another GET, REGET, NEXT, PREVIOUS occurs
DriverFileClass._WatchCmdOff      PROCEDURE()
  code
  self._watchCmdState = Watch:off
  !self.trace('DriverFileClass._WatchCmdArm self._watchCmdState = watch:off')
  Return

!-----------------------------------------------------------------
! if WATCH has been primed then this checks if this is the fist read. If it is, then fine.
! If it's more than the first read then the watch is disabled.
DriverFileClass._WatchCmdArm          PROCEDURE()
  code
  case self._watchCmdState
  of Watch:on
    self._watchCmdState = watch:armed
    !self.trace('DriverFileClass._WatchCmdArm self._watchCmdState = watch:armed')
  of watch:armed
    self._watchCmdState = watch:off
  End
  Return

!-----------------------------------------------------------------
! called for all GET, REGET, NEXT and PREVIOUS  . Also by ADD, APPEND, UPSERT, PUT, via ._AfterWrite
DriverFileClass._WatchBuffLoad         PROCEDURE()   !!!todo check that all paths here require the file to be open
  code
  If Errorcode()
    self._watchBufferState = watch:off
    Return
  End
  If self.ReadOnly
    self._watchBufferState = watch:off
    self._recordLoaded = false
    Return
  End
  self._recordLoaded = true ! used for general PUT case
  self._watchBufferState = watch:loaded
  !self.trace('DriverFileClass._WatchBuffLoad self._watchBufferState = watch:loaded')
  memcpy(Address(self.WatchBuffer),self.ClaFCB.rec_buf,self.ClaFCB.rec_len)
  self.SetBlobsCrc()

!  case self._watchstate
!  of Watch:off
!    Return
!  of Watch:on
!    !If self.WatchBuffer &= NULL
!    !  self.WatchBuffer &= new String(self.ClaFCB.rec_len)
!    !End
!    memcpy(Address(self.WatchBuffer),self.ClaFCB.rec_buf,self.ClaFCB.rec_len)
!    self._watchstate = Watch:loaded
!  of Watch:put           ! always populating the watch buffer after a read, means partial SQL PUT's are possible.
!    memcpy(Address(self.WatchBuffer),self.ClaFCB.rec_buf,self.ClaFCB.rec_len)
!    self._watchstate = Watch:CanPut
!  of Watch:disabled
!    ! do nothing
!  Else
!    self.WatchOff()
!  End
  Return

!-----------------------------------------------------------------
! called before doing a PUT
! Generates a RecordChangedErr if a REGET of the record fails a buffer comparison test
DriverFileClass._WatchCheck         PROCEDURE()
x   long,auto
o1  long,auto
o2  long,auto
str   cstring(1024),auto
  code
  case self._watchCmdState
  of Watch:Armed
    self._watchCmdState = watch:on  ! An attempt to write disarms the Watch

    ! if the WatchBuffer is the same as the current record buffer, then there's no need to do a put, so no need to do the REGET check.
    If self.WatchBuffer[1: self.RecordLength] = self.recbuf[1: self.RecordLength]
      Return    !!!todo watch on BLOBs
    End

    ! copy record buffer to shadow buffer
    memcpy(Address(self.ShadowBuffer),self.ClaFCB.rec_buf,self.ClaFCB.rec_len)
    ! re-load record based on Primary Key Position. But this loads the WHOLE RECORD. So if the WATCH was done after a partial READ
    ! then only the fields partially READ should be checked.
    self._doingWatchCheck = true
    self.Reget(self.PrimaryKeyPosition)
    self._doingWatchCheck = false
    self._ParameterOpcode = Opcode:PUT
    If self.WatchBuffer[1: self.RecordLength] <> self.recbuf[1: self.RecordLength]
      self.SetError(RecordChangedErr)
      str = ''
      Loop x = 1 to self.SharedProperties.FieldList.nodes
        If self._withField(x) = driver:ok
          o1 = self.fields.Offset + 1
          o2 = self.fields.offset + self.fields.length
          If self.WatchBuffer[o1 : o2] <> self.recbuf[o1 : o2]
            str = str & ' ' & self.fields.Column
          End
        End
      End
      self.SetFileError('Fields Changed', str)
      !self.trace('fields Changed: ' & str)
    End
    memcpy(self.ClaFCB.rec_buf,Address(self.ShadowBuffer),self.ClaFCB.rec_len)    ! the user-altered record is restored in either case
  End
  Return

!-----------------------------------------------------------------

! Transaction Processing
!-----------------------------------------------------------------
! StartTran is called from LOGOUT, ROLLBACK and COMMIT. The Opcode parameter indicates which one.
! This is only called for the first table in the list
DriverFileClass.StartTran      PROCEDURE(Long pOpcode)
  Code
  self.SetError(NoError)
  !self.trace('StartTran Table ' & self.FullPathName & ' pOpcode=' & pOpcode & ' ' & self.InterpretOPCode(pOpcode))
  self._transactionPrimary = true
  case pOpcode
  of Opcode:LOGOUTdrv
    !self.trace('***BEGIN TRANSACTION***')
  of Opcode:ROLLBACKdrv
    !self.trace('***ROLLBACK TRANSACTION***')
  of Opcode:COMMITdrv
    !self.trace('***COMMIT TRANSACTION***')
  End
  !self.trace('end of starttran')
  Return

DriverFileClass.EndTran      PROCEDURE(Long pOpcode)  !LONG pTimeout,<FILE file1>,<FILE file2>,<FILE file3>,<FILE file4>,<FILE file5>,<FILE file6>,<FILE file7>,<FILE file8>,<FILE file9>,<FILE file10>
  Code
  self.SetError(NoError)
  !self.trace('EndTran Table ' & self.FullPathName & ' pOpcode=' & pOpcode & ' ' & self.InterpretOPCode(pOpcode))
  case pOpcode
  of Opcode:LOGOUTdrv
    !self.trace('***END LOGOUT ***')
  of Opcode:ROLLBACKdrv
    !self.trace('***END ROLLBACK ***')
  of Opcode:COMMITdrv
    !self.trace('***END COMMIT ***')
  End
  !self.trace('end of EndTran')
  Return

!-----------------------------------------------------------------
DriverFileClass.LOGOUTCONNECTION      PROCEDURE()  !LONG pTimeout,<FILE file1>,<FILE file2>,<FILE file3>,<FILE file4>,<FILE file5>,<FILE file6>,<FILE file7>,<FILE file8>,<FILE file9>,<FILE file10>
  Code
  !self.trace('DriverFileClass.LOGOUTCONNECTION for : ' & self.name() & ' _transactionPrimary=' & self._transactionPrimary & ' _inTransaction=' & self._inTransaction)
  If self._transactionPrimary = true and self._inTransaction
    self.SetError(LogActiveErr)
  Else
    self.SetError(NoError)
  End
  Return

!-----------------------------------------------------------------
! COMMIT and ROLLBACK are called for all the tables in the list. But if the transaction is connection based it should only be
! done for the primary table. The primary table is set by the call to StartTran and EndTran because those are only called for the
! first table in the list.
DriverFileClass.COMMIT           PROCEDURE()
  Code
  !self.trace('committing ' & self.name())
  If self._transactionPrimary = true and self._inTransaction = False
    Self.SetError(NoLogoutErr)
  Else
    self.SetError(NoError)
  End
  Return

!-----------------------------------------------------------------
DriverFileClass.ROLLBACK         PROCEDURE()
  Code
  !self.trace('rollbacking ' & self.name())
  If self._transactionPrimary = true and self._inTransaction = False
    Self.SetError(NoLogoutErr)
  Else
    self.SetError(NoError)
  End
  Return

!-----------------------------------------------------------------
DriverFileClass.ROLLBACK         PROCEDURE(String pSavePoint)
  Code
  If self._inTransaction = FALSE
    Self.SetError(NoLogoutErr)
  ElsIf pSavePoint = ''
    self.SetError(InvalidSavePointErr)
  Else
    self.SetError(NoError)
  End
  Return

!-----------------------------------------------------------------
DriverFileClass.SAVEPOINT        PROCEDURE(String pSavePoint)
  Code
  If self._inTransaction = FALSE
    Self.SetError(NoLogoutErr)
  ElsIf pSavePoint = ''
    self.SetError(InvalidSavePointErr)
  Else
    self.SetError(NoError)
  End
  Return

!-----------------------------------------------------------------

! Null Data Processing
!-----------------------------------------------------------------
! first parameter is pointer to field in recbuf. Second is length of the field.
! aka GETNULL
DriverFileClass.NULL_          PROCEDURE(Long pAddr, Long pSize)!,LONG
x    long
  Code
  self.SetError(NoError)
  If self._WithFieldOffset(pAddr - self.ClaFCB.rec_buf,pSize) = Driver:ok
    Return self.null_(self.fields.index)
  End
  Return False

!-----------------------------------------------------------------
DriverFileClass.NULL_          PROCEDURE(Long pIndex)
x    long
  Code
  self.SetError(NoError)
  If self._WithField(pIndex) = Driver:ok
    If self.Fields.Type = ClaGROUP   ! to see if a group is null, the contents of each field in the group is tested
      Loop x = self.Fields.index + 1 to self.Fields.index + self.Fields.GroupFields
        If self.null_(x) = false                                                       ! recurse down groups
          Return false
        End
      End
      Return True
    Else
      If self._nullstr[self.Fields.index] <> '.' then Return False.
    End
    ! so, at this point the field has been _set_ to null. But check and see if the value in the field is still blank.
    !self.trace('field is set null and self._FieldIsBlank()=' & self._FieldIsBlank())
    Return self._FieldIsBlank()
  End
  Return False

!-----------------------------------------------------------------
! given the ADDRESS of the field, and the size
! set the _nullstr byte, and also clear the field
! only works on the record buffer not the shadow buffer.
! This is the one called by the compiler when the code says NULL(field) or NULL(file,field)
DriverFileClass.SETNULL_         PROCEDURE(Long pAddr, Long pSize)
  Code
  self.SetError(NoError)
  If self._WithFieldOffset(pAddr - self.ClaFCB.rec_buf,pSize) = Driver:ok
    self._SetFieldNull()
  End
  Return

!-----------------------------------------------------------------
! given the field index number
! set the _nullstr byte, and also clear the field
! only works on the record buffer not the shadow buffer.
DriverFileClass.SETNULL_         PROCEDURE(*Long pIndex)
  Code
  self.SetError(NoError)
  If self._WithField(pIndex) = Driver:ok
    self._SetFieldNull()
  End
  Return

!-----------------------------------------------------------------
! given the column name (ie external name of the column in the database)
! set the _nullstr byte, and also clear the field
! only works on the record buffer not the shadow buffer.
DriverFileClass.SETNULL_         PROCEDURE(*Cstring pColumn)
  Code
  self.SetError(NoError)
  If self._WithFieldNamed(pColumn) = driver:ok
    self._SetFieldNull()
  End
  Return

!-----------------------------------------------------------------
! called from one of the SetNull_ methods.
! Assumes the correct entry in the Fields Queue is loaded
! Works on the Record Buffer, not the Shadow buffer
DriverFileClass._SetFieldNull     PROCEDURE()
  code
  If self.Fields.index = 0 then return.
  self._nullstr[self.Fields.index] = '.'
  self._ClearField()

!-----------------------------------------------------------------
! clear the specific field. Works on Arrays as well.
DriverFileClass._ClearField     PROCEDURE()
  code
  !self.trace('DriverFileClass._ClearField type=' & self.Fields.Type)
  Case self.Fields.Type
  of ClaSTRING
    memset(self.ClaFCB.rec_buf + self.Fields.offset,32,self.Fields.Length)
  of ClaPSTRING
    memset(self.ClaFCB.rec_buf + self.Fields.offset,32,self.Fields.Length)
    memset(self.ClaFCB.rec_buf + self.Fields.offset,0,1)
  of ClaCSTRING
    memset(self.ClaFCB.rec_buf + self.Fields.offset,0,self.Fields.Length)
  Else
    memset(self.ClaFCB.rec_buf + self.Fields.offset,0,self.Fields.Length)
  End
  Return

!-----------------------------------------------------------------
DriverFileClass._SetAllNoNull     PROCEDURE()
  code
  self._nullstr = all('+',self.SharedProperties.FieldList.nodes)
  Return

!-----------------------------------------------------------------
DriverFileClass.SETNONNULL      PROCEDURE(Long pAddr, Long pSize)
  Code
  self.SetError(NoError)
  If self._WithFieldOffset(pAddr - self.ClaFCB.rec_buf,pSize) = Driver:ok
    self._nullstr[self.Fields.index] = '+'
  End
  Return

!-----------------------------------------------------------------
DriverFileClass.GETNULLS         PROCEDURE()
x  long
  Code
  Loop x = 1 to self.SharedProperties.FieldList.nodes
    !self.trace('x=' & x & ' ns=' & size(self._nullstr))
    self.Fields &= self._withFieldNode(x)
    If self._nullstr[x] = '.' and self._FieldIsBlank() = false
      self._nullstr[x] = '+'
    End
  End
  Return self._nullstr

!-----------------------------------------------------------------
DriverFileClass.SETNULLS        PROCEDURE(String pNulls)
  Code
  self._nullstr = pNulls
  Return

!-----------------------------------------------------------------
DriverFileClass.DOKEYPROPERTY   PROCEDURE(Long pProperty,KEY pKeyPtr,Long pIndex=0)!,String,VIRTUAL
  code
  self.SetError(NoDriverSupport)
  Return

!-----------------------------------------------------------------
! code can be of the form
! file{prop:something}
! with neither a return value, nor an assignment. In this case this DOPROPERTY method is called.
DriverFileClass.DOPROPERTY      PROCEDURE(String pProperty,Long pIndex=0)
f   &File
  Code
  !self.trace('DriverFileClass.DOPROPERTY (' & self.InterpretProperty(pProperty) & ',' & pIndex & ')')
  case lower(pProperty)
  of Prop:Exists                            ! new to Object Based Drivers
  orof 'exists'
    self._exists = self.Exists('')

  of OpCode:Reopen                          ! new to Object Based Drivers
  orof 'reopen'
    self.reopen(pIndex)

  of OpCode:Upsert
  orof 'upsert'                             ! new to Object Based Drivers
    self.Upsert()

  else
    parent.DoProperty(pProperty,pIndex)
  End
  return

!-----------------------------------------------------------------
DriverFileClass.DOBLOBPROPERTY  PROCEDURE(Long pProperty,Long pIndex)
  Code
  return ''

! key properties
!-----------------------------------------------------------------
DriverFileClass.GETKEYPROPERTY   PROCEDURE(Long pProperty,KEY pKeyPtr,Long pIndex=0)!,String,VIRTUAL
  code
  !self.trace('DriverFileClass.GETKEYPROPERTY ' & pProperty & ' =' & self.InterpretProperty(pProperty))
  case pProperty
  of PROP:Ascending
    return self.GETKEYPROP:Ascending(pKeyPtr,pIndex)
  of PROP:Components        ! EQUATE (731AH)  ! Get number of key components
  orof PROP:Fields
    return self.GETKEYPROP:Components(pKeyPtr)
  of PROP:Dup               ! EQUATE (731BH)  ! Get DUP attribute
    return self.GETKEYPROP:Dup(pKeyPtr)
  of prop:Field
    return self.GETKEYPROP:Field(pKeyPtr,pIndex)
  of prop:File
    return self.GETPROP:File()
  of Prop:Label
    return self.GETKEYPROP:Label(pKeyPtr)
  of PROP:Name
    return self.GETKEYPROP:Name(pKeyPtr)
  of PROP:NoCase            ! EQUATE (731DH)  ! Get NOCASE attribute
    return self.GETKEYPROP:NoCase (pKeyPtr)
  of PROP:Object               !
    return self.GetProp:Object()
  of PROP:Opt               ! EQUATE (731CH)  ! Get OPT attribute
    return self.GETKEYPROP:Opt(pKeyPtr)
  of PROP:Primary           ! EQUATE (731EH)  ! Get PRIMARY attribute
    return self.GETKEYPROP:Primary(pKeyPtr)
  of PROP:Type
    return self.GETKEYPROP:Type(pKeyPtr)
  end
  return ''

!-----------------------------------------------------------------
DriverFileClass.SetKeyProperty   PROCEDURE(Long pProperty,KEY pKeyPtr,Long pIndex=0,STRING pValue)!,STRING,VIRTUAL
  code
  !self.trace('DriverFileClass.SetKeyProperty pProperty=' & pProperty & ' ' & self.InterpretProperty(pProperty) & ' pIndex=' & pIndex & ' pValue=' & pValue)
  return

! properties
!-----------------------------------------------------------------
DriverFileClass.GetProperty      PROCEDURE(String pProperty,Long pIndex=0)
  Code
  !self.trace('DriverFileClass.GetProperty (' & self.InterpretProperty(pProperty) & ',' & pIndex & ') [' & self.FullPathName & ']')
  case pProperty
  of PROP:AddOnly
   return self.GetPROP:AddOnly()
  of Prop:Arrays
    return self.GetProp:Arrays()
  of PROP:Alias              !  ! the alias the SQL Accelerator driver uses when generating SELECT statements for a view.
    return self.GetProp:Alias()
  of PROP:AlwaysRebind       !  ! the toggle that controls whether the SQL Accelerator rebinds memory locations when a NULL state changes.
    return self.GetProp:AlwaysRebind()
  of Prop:Attributes
    return self.GetProp:Attributes(pIndex)
  of PROP:Binary
    return self.GetProp:Binary(pIndex)
  of PROP:Blob               !PROCEDURE(Long pIndex),LONG,VIRTUAL ! Get reference to blob data
    return self.GetProp:Blob(pIndex)
  of PROP:Blobs              ! ! Get number of blobs in file
    return self.GetProp:Blobs()
  of Prop:Bytes
    return self.Bytes()
  of PROP:Column              ! the external name, as it is in the database, no prefix or attributes
    return self.GetProp:Column(pIndex)
  of PROP:Completed          !  ! Get BUILD completed status
    return self.GetProp:Completed()
  of PROP:ConnectString      !  ! returns an SQL database's connection information.
    return self.GetProp:ConnectString()
  of PROP:Create             !  ! Get create status
    return self.GetProp:Create()
  of PROP:CurrentKey         !  ! Get current sequential or build key
    return self.GetProp:CurrentKey()
  of PROP:DefaultExtension   !  ! (read only) The extension, including the dot, added to a file if no extension is supplied.
    return self.GetProp:DefaultExtension()
  of PROP:Dim
     return self.GetProp:Dim(pIndex)
  of PROP:DriverLogsoutAlias !  ! Get the capacity of LOGOUT
    return self.GetProp:DriverLogsoutAlias()
  of PROP:DriverString       ! ! Get driver string
    return self.GetProp:DriverString()
  of PROP:DuplicateKey       !  ! (read only) The key that cause error code 40
    return self.GetProp:DuplicateKey()
  of PROP:DynamicFile        !  ! (read only) Returns '1' if the file was created by NEW(File)
    return self.GetProp:DynamicFile()
  of PROP:Encrypt            !  ! Get encrypt status
    return self.GetProp:Encrypt()
  of Prop:Exists                            ! new to Object Based Drivers
    If self.Exists('').
    Return self.GetProp:Exists()
  of prop:FastWrite
    return self.GetProp:FastWrite()
  of PROP:Hdbc               !  ! returns the current hdbc used by the ODBC driver
    return self.GetProp:Hdbc()
  of PROP:Henv               !  ! returns the current henv (environment handle) used by the SQL driver
    return self.GetProp:Henv()
  of PROP:Hstmt              !  ! returns the current hstmt used by the SQL driver.
    return self.GetProp:Hstmt()
  of PROP:Interface              !  ! See P  of PROP:Interface
    return self.GetProp:Interface(pIndex)
  of PROP:FileDriver         !  ! Get the file driver
    return self.GetProp:FileDriver()
  of PROP:FileSize           !  ! Get the size of the file
    return self.GetProp:FileSize()
  of PROP:Held               !  ! Get record hold status
    return self.GetProp:Held()
  of Prop:Json
    return self.GetProp:Json(pIndex)
  of PROP:Key                !PROCEDURE(Long pIndex),STRING,VIRTUAL
    return self.GetProp:Key(pIndex)
  of PROP:Keys               !  ! Get number of keys in file
    return self.GetProp:Keys()
  of PROP:Locked
    return self.GetProp:Locked()
  of PROP:LoginTimeout       !  ! sets a time limit in seconds for an SQL database's login screen
    return self.GetProp:LoginTimeout()
  of PROP:LogonScreen        !  ! Drive3r automatically prompts for logon information
    return self.GetProp:LogonScreen()
  of PROP:Logout             !  ! Get/Set files logout status
    return self.GetProp:Logout()
  of PROP:LogoutIsolationLevel !  ! controls what isolation level is used within a transaction frame. SQL only.
    return self.GetProp:LogoutIsolationLevel()
  of PROP:LogSQL             !  ! turns on or off logging of calls to the backend for SQL drivers
    return self.GetProp:LogSQL()
  of PROP:MaxStatements      !  ! find out how many statements can be active before a new connection to the database is raised. SQL only
    return self.GetProp:MaxStatements()
  of PROP:Memo               !  ! Remove memo from file definition (dynamic file support required)
    return self.GetProp:Memo()
  of PROP:Memos              !  ! Get number of memos in file
    return self.GetProp:Memos()
  of PROP:Name               !  ! Get file/key/memo/blob/field's name
    return self.GetProp:Name(pIndex)
  of PROP:Object               !
    return self.GetProp:Object()
  of PROP:OEM                !  ! Get OEM attribute
    return self.GetProp:OEM()
  of PROP:Owner              !  ! Get Owner
    return self.GetProp:Owner()
  of PROP:Over
    return self.GetProp:Over(pIndex)
  of Prop:Pointer
    return self.Pointer()
  of Prop:Pool
    return self.GetProp:Pool()
  of PROP:Places
    return self.GetProp:Places(pIndex)
  of PROP:Pre                !  ! (write only) Set the prefix of the file
    return self.GetProp:Prefix()
  of PROP:ProgressEvents     !  ! Set amount of events for BUILD
    return self.GetProp:ProgressEvents()
  of Prop:Project
    return self.GetProp:Project()
  of PROP:Reclaim            !  ! Get Reclaim attribute
    return self.GetProp:Reclaim()
  of PROP:Record             !  ! Get the file's record buffer
    return self.GetProp:Record()
  of Prop:Records
    return self.Records()
  of prop:RelationsOff
    return self.GetProp:RelationsOff()
  of Prop:Size
    return self.GetProp:Size(pIndex)
  of PROP:StmtAttr           !  ! read or set the ODBC Statement Attribute
    return self.GetProp:StmtAttr()
  of PROP:SQLDriver          !  ! '1' = Driver is SQL aware
    return self.GetProp:SQLDriver()
  of PROP:SupportsOp         !PROCEDURE(Byte pOpCode),STRING,VIRTUAL  ! Get which functions are supported
    return self.GetProp:SupportsOp(pIndex)
  of PROP:SupportsType       !PROCEDURE(Byte pType),STRING,VIRTUAL  ! Get which data types are supported
    return self.GetProp:SupportsType(pIndex)
  of PROP:Text               !PROCEDURE(Long pIndex),STRING,VIRTUAL ! sets or returns the specified MEMO or BLOB field's data
    return self.GetProp:Text(pIndex)
  of PROP:Thread       !PROCEDURE(Byte pType),STRING,VIRTUAL  ! Get which data types are supported
    return self.GetProp:Thread()
  of PROP:Touched
    return self.GetProp:Touched(pIndex)
  of PROP:TryConnectedAs
    return self.GetProp:TryConnectedAs()
  of PROP:Type
    return self.GetProp:Type(pIndex)
  of Prop:Uuid
    return self.GetProp:Uuid(pIndex)
  of Prop:Uuid4
    return self.GetProp:Uuid4(pIndex)
  of Prop:Uuid7
    return self.GetProp:Uuid7(pIndex)
  of Prop:Uuid8
    return self.GetProp:Uuid8(pIndex)
  of PROP:Value              !PROCEDURE(Long pIndex),STRING,VIRTUAL ! sets or returns the specified MEMO or BLOB field's data
    return self.GetProp:Value(pIndex)
  of PROP:Watched            !  ! Get record watch status
    return self.GetProp:Watched()
  else
    Return parent.GetProperty(pProperty,pIndex)
  end
  return ''

!-----------------------------------------------------------------
DriverFileClass.SETPROPERTY      PROCEDURE(String pProperty,Long pIndex,String pValue)
F  &File
  Code
  !self.trace('DriverFileClass.SETPROPERTY (' & self.InterpretProperty(pProperty) & ',' & pIndex & ',' & pValue & ')')
  If self._logClarion then self.Log('[CLAR]SETPROPERTY(' & self.InterpretProperty(pProperty) & ',' & pIndex & ')=' & pValue).  !!!todo This is in the wrong place
  case pProperty
  of PROP:AddOnly
    self.SetPROP:AddOnly(pValue)
  of PROP:Alias              !  ! the alias the SQL Accelerator driver uses when generating SELECT statements for a view.
    self.SetProp:Alias(pValue)
  of PROP:Column              ! the external name, as it is in the database, no prefix or attributes
    self.SetProp:Column(pIndex,pValue)
  of PROP:Create                            ! *not usually writable
    self.SetProp:Create(pValue)
  of PROP:DefaultExtension
    self.SetProp:DefaultExtension(pValue)   ! *
  of PROP:DriverString
    self.SetProp:DriverString(pValue)
  of PROP:Encrypt
    self.SetProp:Encrypt(pValue)
  of Prop:Exists                            ! new to Object Based Drivers
    self._exists = self.Exists(pValue)
  of Prop:FastWrite
    self.SetProp:FastWrite(pValue)
  of PROP:Interface                         ! new to Object Based Drivers
    self.SetPROP:Interface(pIndex,pValue)
  of prop:Json
    !self.SetPROP:Json(pIndex,pValue)
  of prop:Label                             ! *
    self.SetPROP:Label(pIndex,pValue)
  of prop:LoginTimeout
    self.SetPROP:LoginTimeout(pValue)
  of PROP:Logout
    ! used to add a file to a transaction. But Transactions in SQL are really connection based.
    self.SetProp:Logout(pValue)
  of prop:LogSQL
    self.SetPROP:LogSQL(pValue)
  of Prop:Merge                              ! new to Object Based Drivers
    F &= (pValue)
    self.Merge(F,0)
  of Prop:MergeName                         ! new to Object Based Drivers
    self.Merge(pValue,0)
  of PROP:Name
    self.SetProp:Name(pIndex,pValue)
  of PROP:Object                           ! new to Object Based Drivers
    self.SetPROP:Object(pValue)
  of PROP:OEM
    self.SetProp:OEM(pValue)
  of PROP:Owner
    self.SetProp:Owner(pValue)
  of PROP:Pool
    self.SetProp:Pool(pValue)
  of PROP:Project
    self.SetPROP:Project(pValue)
  of prop:Reopen
    self.Reopen(pValue)
  of PROP:ServerAutoInc
    self.SetProp:ServerAutoInc(pIndex,pValue)
  of PROP:Size
    self.SetProp:Size(pIndex,pValue)
  of PROP:Text
    self.SetProp:Text(pIndex,pValue)
  of PROP:Value
    self.SetProp:Value(pIndex,pValue)
  else
    parent.SetProperty(pProperty,pIndex,pValue)
  end
  Return

! Blob Properties
!-----------------------------------------------------------------
! the docs on prop:size for a blob are conflictory.
! on the one hand;
! Prop:Size
! Returns or sets the size of a BLOB field. Before assigning data to the BLOB using the string slicing technique,
! if the BLOB does not yet contain any data you must set its size using PROP:Size. Before assigning additional
! data that will increase the amount of data in the BLOB (using the string slicing technique), you must reset its size using PROP:Size.
!
! However this is not true for TPS or SQlite. Neither driver appears to need prop:size to be set before assigning the Blob.
! Neither driver ever returns anything for table{prop:size,-x}.
! However setting, and getting blbptr{prop:size} does work.
!
! OBD's behave as follows;
! - setting prop:size to zero free's the Blob buffer.
! - assigning something into the blob extends the blob buffer size as required
! - reading from beyond the buffer treats the beyond part as blank string.
! - memsize and size are treated separately, where memsize is always >= size
! - memsize only gets bigger, unless prop:size is set to 0.
! - other than 0, prop:size deals with the blob size, not memsize
! - setting prop:size can be used to "truncate" the blob.
! - the value written to disk is .size long.


DriverFileClass.GETBLOBPROPERTY  PROCEDURE(Long pProperty,Long pIndex)
nullstr  &string
  Code
  !self.trace('Getting blob property: ' & self.InterpretProperty(pProperty) & ' for field ' & pIndex)
  If pIndex > 0 then pIndex = -pIndex.
  case pProperty
  of PROP:Size
    return self.GetProp:Size(pIndex)
  of PROP:Handle
    return self.GetProp:Handle(pIndex)
  of PROP:Object               !
    return self.GetProp:Object()
  of PROP:Value
  orof PROP:Text
    return self.GetProp:Value(pIndex)
  End
  return nullstr

!-----------------------------------------------------------------
DriverFileClass.SETBLOBPROPERTY  PROCEDURE(Long pProperty,Long pIndex,String pValue)
iParm  BIGINT
  Code
  !self.trace('Setting blob property: ' &  self.InterpretProperty(pProperty) & ' for field ' & pIndex & ' to [' & pValue & ']')
  case pProperty
  of PROP:Handle
    iParm = int(pValue)
    self.SetBlobProp:Handle(pIndex,iParm)
  of PROP:Size
    iParm = int(pValue)
    self.SetBlobProp:Size(pIndex,iParm)
  of PROP:Value
  orof PROP:Text
    self.SetBlobProp:Value(pIndex,pValue)
  End
!=================================================================
! Blob Properties
! ----------------------------------------------------------------
! This method does not actually set the Handle value. Rather the incoming value
! is assigned to the blob. The incoming value is also a handle.
! Since this incoming handle _may_ have been allocated using movable memory, we'll lock it before using it.
! when copying a blob in this way ALL the memory is copied. And SIZE is then set to the MEM SIZE of the src blob
DriverFileClass.SetBlobProp:Handle  Procedure(Long pIndex, BIGINT pValue)
ptr     long
srcSize long
handle  long
addr    long
  code
  !self.trace('yyy SetBlobProp:Handle desc=' & pIndex & ' ,  src handle=' & pValue)
  if self._WithBlob(pIndex) = driver:ok
    handle = pValue
    srcSize = osGlobalSize(handle)
    If self.blobs.handle = 0 or self.blobs.handlesize <> srcSize
      self.SetBlobProp:Size(pIndex,srcSize)
    End
    addr = osGlobalLock(handle)
    if addr
      MemCpy(self.blobs.handle,addr,srcSize)
    else
      MemCpy(self.blobs.handle,handle,srcSize)
    End
    addr = osGlobalUnLock(handle)
    put(self.blobs)
  End
  Return

!-----------------------------------------------------------------
! setting prop:size to 0 frees the memory associated with the blob
! setting prop:size > memsize increases memsize
! setting prop:size < memsize decreases memsize
!
DriverFileClass.SetBlobProp:Size   Procedure(Long pIndex, BIGINT pValue)
newHandle  Long
newsize    Long
  code
  newsize = pValue
  !self.trace('DriverFileClass.SetBlobProp:Size for ' & pIndex & ' to ' & newsize)
  If self._WithBlob(pIndex) = driver:ok
    If self.blobs.memo
      If newsize > self.blobs.memosize
        self._newMemoMemory(newsize)
        Put(self.blobs)
      End
    Else
      !self.trace('SetBlobProp:Size = ' & newsize)
      If newsize <= 0
        !self.trace('freeing blob memory ' & self.blobs.handle)
        If self.blobs.handle
          osGlobalFree(self.blobs.handle)
          self.blobs.handlesize = 0
          self.blobs.handle = 0
          Put(self.blobs)
        Elsif self.blobs.handlesize
          self.blobs.handlesize = 0
          Put(self.blobs)
        End
      Else
        If self.blobs.handle = 0
          !self.trace('need NEW memory of ' & newsize)
          self.blobs.handle = osGlobalAlloc(GMEM_FIXED + GMEM_ZEROINIT , newsize)
          self.blobs.handlesize = osGlobalSize(self.blobs.handle)
          Put(self.blobs)
          self._writeHandle()
        elsif newsize = self.blobs.handlesize
          ! nothing to do.  ! this does not clear the blob memory.
          !self.trace('nothing to do, size is already big enough')
        Else
          !self.trace('need DIFFERENT memory of ' & newsize)
          ! need to change the size of the block.
          ! At first glance GlobalReAlloc seems useful, but that only works on Movable memory.
          ! Instead use GlobalAlloc, and copy memory contents.
          !self.trace('need to resize memory to ' & newsize & ' from ' & self.blobs.handle & ' ' & self.blobs.handlesize)
          newHandle = osGlobalAlloc(GMEM_FIXED + GMEM_ZEROINIT , newsize)
          If NewHandle
            If newsize > self.blobs.handlesize
              MemCpy(newhandle,self.blobs.handle,self.blobs.handlesize)
            Else
              MemCpy(newhandle,self.blobs.handle,newsize)
            End
            self.blobs.handle = newHandle
            self.blobs.handlesize = osGlobalSize(self.blobs.handle)
            !self.trace('self.blobs.handlesize=' & self.blobs.handlesize & ' newsize = ' & newsize)
            Put(self.blobs)
            self._writeHandle()
          End
        End
      End
    End
  End
  Return
!-----------------------------------------------------------------
DriverFileClass.SETBLOBPROP:Value   Procedure(Long pIndex, String pValue)
  code
  Self.SetBlob(pIndex,0,pValue,true)
  Return

!=================================================================
! FILE Properties
! The above GetProperty method calls into these methods, one for each specific property.
! Most of these methods do not need to be derived by a specific driver. Ones that are, are marked with !!! DERIVE
!-----------------------------------------------------------------
DriverFileClass.GetPROP:AddOnly            PROCEDURE()
  code
  If self.AddOnly then Return '1' else Return ''.

!-----------------------------------------------------------------
!DERIVE
DriverFileClass.GetPROP:Arrays            PROCEDURE()
  code
  return ''

!-----------------------------------------------------------------
DriverFileClass.SetPROP:AddOnly            PROCEDURE(Byte pValue)
  code
  self.AddOnly = pValue
  Return

!-----------------------------------------------------------------
DriverFileClass.GetProp:Alias              PROCEDURE()!,STRING,VIRTUAL
  code
  Return Self.Alias

!-----------------------------------------------------------------
DriverFileClass.SETPROP:Alias              PROCEDURE(String pAlias)!,STRING,VIRTUAL
  code
  Self.Alias = clip(pAlias)
  Return

!-----------------------------------------------------------------
DriverFileClass.GetProp:AlwaysRebind       PROCEDURE()
  code
  return ''
!-----------------------------------------------------------------
DriverFileClass.GetProp:Binary             PROCEDURE(Long pIndex)
  code
  If self._WithBlob(pIndex) = Driver:ok
    If self.blobs.Binary then Return '1'.
  End
  Return ''
!-----------------------------------------------------------------
DriverFileClass.GetProp:Blobs              PROCEDURE()!,LONG,VIRTUAL ! Get number of blobs in file
  code
  return self._numBlobs
!-----------------------------------------------------------------
DriverFileClass.GetProp:Blob               PROCEDURE(Long pIndex)!,LONG,VIRTUAL ! Get reference to blob data
  code
  !self.trace('DriverFileClass.GetProp:Blob ')
  If self._WithBlob(pIndex) = driver:ok
    If self.blobs.memo = false
      Return address(self.ClaFCB) & ':' & self.blobs.index  ! +index
    End
  End
  self.SetError(NoError)
  Return 0

!-----------------------------------------------------------------
! the external name, as it is in the database, no prefix or attributes
! Supports -ve numbers for blobs and memos
! This is the ColName, so includes the reserved-word-wrapping and is "case sensitive".
! Does not include the SQL Alias
DriverFileClass.GetProp:Column               PROCEDURE(Long pIndex=0)
  code
  If pIndex = 0
    Return ''
  Elsif pIndex > 0
    If self._WithField(pIndex) = driver:ok
      return self.Fields.Column
    End
  ElsIf self._WithBlob(pIndex) = driver:ok
    Return self.blobs.Column
  End
  Return ''

!-----------------------------------------------------------------
DriverFileClass.ClearProps              PROCEDURE()
  Code
  self.SetProp:AddOnly(0)
  self.SetProp:Project('')
  self.NoMemoArmed = false
  self._fastwrite = false
  self._nomemo = false
  If not self._ProjectClauses &= NULL
    self._ProjectClauses.SetValue('')
  End
  parent.ClearProps()
  Return

!-----------------------------------------------------------------
! the external name, as it is in the database, no prefix or attributes
! Supports -ve numbers for blobs and memos
! if the pColumn is a reserved word then it is wrapped.
! NOTE: This affects ALL instances of this stucture, on all threads, for the life of the program
DriverFileClass.SETPROP:Column               PROCEDURE(Long pIndex,String pColumn)
column  cstring(size(pColumn)+1),auto
  code
  column = clip(pColumn)
  If pIndex = 0
    Return
  Elsif pIndex > 0
    If self._WithField(pIndex) = driver:ok
      self.Fields.Column = self.TranslateReserved(Column)
      self.Fields.UpperColumn = upper(self.UnwrapReserved(Column))
    End
  ElsIf self._WithBlob(pIndex) = driver:ok
     self.blobs.Column = self.TranslateReserved(Column)
     self.blobs.UpperColumn = upper(self.UnwrapReserved(Column))
  End
  Return

!-----------------------------------------------------------------
DriverFileClass.GetProp:Completed          PROCEDURE()!,STRING,VIRTUAL  ! Get BUILD completed status
  code
  return ''
!-----------------------------------------------------------------
DriverFileClass.GetProp:ConnectString      PROCEDURE()!,STRING,VIRTUAL
  code
  return ''
!-----------------------------------------------------------------
DriverFileClass.GetProp:Create             PROCEDURE()!,BYTE,VIRTUAL  ! Get create attribute
  code
  If self.SharedProperties &= NULL
    self.trace('DriverFileClass.GetProp:Create SharedProperties=null')
  End
  return choose(self.SharedProperties.create = true,'1','')
!-----------------------------------------------------------------
! NOTE: This affects ALL instances of this stucture, on all threads, for the life of the program
DriverFileClass.SetPROP:Create             PROCEDURE(Byte pValue)
  code
  self.SharedProperties.create = pValue
  return
!-----------------------------------------------------------------
DriverFileClass.GetProp:CurrentKey         PROCEDURE()!,STRING,VIRTUAL  ! Get current sequential or build key
  code
  return ''

!-----------------------------------------------------------------
!!! DERIVE ISAM / FLATFILE
DriverFileClass.GetProp:DefaultExtension   PROCEDURE()!,STRING,VIRTUAL ! The extension, including the dot, added to a file if no extension is supplied.
  code
  Return ''
!-----------------------------------------------------------------
!!! DERIVE ISAM / FLATFILE
DriverFileClass.SETPROP:DefaultExtension   PROCEDURE(String pValue)!VIRTUAL  !The extension, including the dot, added to a file if no extension is supplied.
  code
  Return
!-----------------------------------------------------------------
DriverFileClass.GetProp:Dim                PROCEDURE(Long pIndex)
  code
  If pIndex <= 0 then return ''.
  If self._WithField(pIndex) = driver:ok
    If self.Fields.Dims
      Return self.Fields.DimProduct
    Else
      Return 0 ! not ''
    End
  End
  Return ''

!-----------------------------------------------------------------
!!! DERIVE
DriverFileClass.GetProp:DriverLogsoutAlias PROCEDURE()!,STRING,VIRTUAL  ! Get the capacity of LOGOUT
  code
  return ''
!-----------------------------------------------------------------
DriverFileClass.GetProp:DriverString       PROCEDURE()!,STRING,VIRTUAL ! Get driver string
  code
  self.DriverStr = self._GetString(self.ClaFCB.drvstr)
  return self.DriverStr
!-----------------------------------------------------------------
DriverFileClass.SETPROP:DriverString       PROCEDURE(String pDriverString)
  code
  !self._SetString(self.ClaFCB.drvstr,clip(pDriverString))
  self.DriverStr = clip(pDriverString)
  return
!-----------------------------------------------------------------
DriverFileClass.GetProp:DuplicateKey       PROCEDURE()!,STRING,VIRTUAL  ! (read only) The key that cause error code 40
  code
  Return ''

!-----------------------------------------------------------------
DriverFileClass.GetProp:DynamicFile        PROCEDURE()!,STRING,VIRTUAL  ! (read only) Returns '1' if the file was created by NEW(File)
  code
  Return ''

!-----------------------------------------------------------------
DriverFileClass.GetProp:Encrypt            PROCEDURE()!,BYTE,VIRTUAL  ! Get encrypt status
  code
  Return Choose(self.SharedProperties.encrypt = true,'1','')

!-----------------------------------------------------------------
DriverFileClass.SETPROP:Encrypt            PROCEDURE(Byte pEncrypt)  ! Set encrypt status
  code
  self.SharedProperties.encrypt = pEncrypt
  Return

!-----------------------------------------------------------------
DriverFileClass.GetProp:Exists            PROCEDURE()  ! gets the result of the last call to EXISTS
  code
  return self._exists

!-----------------------------------------------------------------
DriverFileClass.GetPROP:FastWrite            Procedure()
  code
  Return Choose(self._fastwrite <> false,self._fastwrite,'')

!-----------------------------------------------------------------
DriverFileClass.SetPROP:FastWrite           Procedure(STRING pValue)
  code
  self._PropsCache += 1
  self._fastwrite = pValue
  Return

!-----------------------------------------------------------------
DriverFileClass.GetProp:Fields             PROCEDURE(Long pIndex)!,LONG,VIRTUAL  ! Get number of fields in file
  code
  If pIndex = 0 then return self.SharedProperties.FieldList.nodes.
  If pIndex < 0 then return ''.
  If self._WithField(pIndex) = driver:ok
    If self.Fields.Type = ClaGROUP
      Return self.Fields.GroupFields
    else
      Return 1   ! not ''
    End
  End
  Return ''
!-----------------------------------------------------------------
DriverFileClass.GetPROP:File               PROCEDURE()
  code
  return address(self.File)

!-----------------------------------------------------------------
!!! DERIVE
DriverFileClass.GetProp:FileDriver         PROCEDURE()!,STRING,VIRTUAL  ! Set the file driver (dynamic file support required)
  code
  return ''

!-----------------------------------------------------------------
!!! DERIVE
DriverFileClass.GetProp:FileSize           PROCEDURE()!,BIGINT,VIRTUAL  ! Get the size of the file
  code
  return 0

!-----------------------------------------------------------------
DriverFileClass.GetProp:Handle             PROCEDURE(Long pIndex)!,STRING,VIRTUAL
str  &string
  code
  If self._WithBlob(pIndex) = driver:ok and self.blobs.Memo = false and not self.blobs.handle = 0
    Return self.blobs.handle
  End
  Return ''

!-----------------------------------------------------------------
DriverFileClass.GetProp:Hdbc               PROCEDURE()!,STRING,VIRTUAL
  code
  return ''

!-----------------------------------------------------------------
DriverFileClass.GetProp:Henv               PROCEDURE()!,STRING,VIRTUAL
  code
  return ''

!-----------------------------------------------------------------
DriverFileClass.GetProp:Held               PROCEDURE()!,BYTE,VIRTUAL  ! Get record hold status
  code
  return self.held

!-----------------------------------------------------------------
DriverFileClass.GetProp:Hstmt              PROCEDURE()!,STRING,VIRTUAL
  code
  return ''

!-----------------------------------------------------------------
DriverFileClass.GetProp:Json               PROCEDURE(Long pIndex)!,STRING,VIRTUAL
  code
  If pIndex < 0
    Return self.GetProp:Value(pIndex)
    !!!todo GetBlobAsJson
  else
    Return Self._GetFieldAsJson(pIndex)
  End
  return ''
!-----------------------------------------------------------------
!DriverFileClass.SETPROP:Json               PROCEDURE(Long pIndex,String pValue)
!  code
!  If pIndex < 0
!    self.SetProp:Value(pIndex,pValue)
!  End
!  Return

!-----------------------------------------------------------------
DriverFileClass.GetProp:Keys               PROCEDURE()!,Long,VIRTUAL  ! Get number of keys in file
  code
  return records(self.keys)
!-----------------------------------------------------------------
DriverFileClass.GetProp:Key               PROCEDURE(Long pIndex)!,STRING,VIRTUAL  ! Get a pointer to a specific key
  code
  self.keys.index = pIndex
  get(self.keys,self.keys.index)
  if errorcode() = 0
    return self.keys.keyptr
  end
  return 0
!-----------------------------------------------------------------
DriverFileClass.GetProp:Label              PROCEDURE(Long pIndex)!,STRING,VIRTUAL  ! Get file/key/memo/blob/field's label
  code
  If self.SharedProperties &= null then return ''.
  If pIndex = 0
    Return self.SharedProperties.label
  elsif pIndex > 0
    If self._WithField(pIndex) = driver:ok
      Return self.Fields.Label
    End
  else
    If self._WithBlob(pIndex) = driver:ok
      Return self.blobs.label
    End
  End
  Return ''
!-----------------------------------------------------------------
! LABEL is always UPPERCASE. When FullPathname is not set, label will default to first 8 chars.
! NOTE: This affects ALL instances of this structure, on all threads, for the life of the program
DriverFileClass.SETPROP:Label              PROCEDURE(Long pIndex,String pValue)
  code
  If pIndex = 0
    self.SharedProperties.label = Upper(pValue)
  End
  Return

!-----------------------------------------------------------------
DriverFileClass.GetProp:Locked       PROCEDURE()
  code
  Return self._locked

!-----------------------------------------------------------------
DriverFileClass.GetProp:LoginTimeout       PROCEDURE()!,LONG,VIRTUAL
  code
  Return self.LoginTimeout

!-----------------------------------------------------------------
DriverFileClass.SETPROP:LoginTimeout       PROCEDURE(Long pSeconds)
  code
  self.LoginTimeout = pSeconds
  Return

!-----------------------------------------------------------------
DriverFileClass.GetProp:LogonScreen       PROCEDURE()!,STRING,VIRTUAL
  code
  Return ''

!-----------------------------------------------------------------
DriverFileClass.GetProp:Logout             PROCEDURE()!,STRING,VIRTUAL  ! Get/Set files logout status
  code
  Return ''

!-----------------------------------------------------------------
DriverFileClass.SetProp:Logout             PROCEDURE(Long pValue)
  code
  Return

!-----------------------------------------------------------------
DriverFileClass.GetProp:LogoutIsolationLevel PROCEDURE()!,BYTE,VIRTUAL
  code
  Return ''

!-----------------------------------------------------------------
DriverFileClass.GetProp:LogSQL             PROCEDURE()!,BYTE,VIRTUAL
  code
  If self.LogSql
    return '1'
  End
  Return ''

!-----------------------------------------------------------------
DriverFileClass.SETPROP:LogSQL             PROCEDURE(Byte pLogSql)
  code
  self.LogSql = pLogSql
  Return

!-----------------------------------------------------------------
DriverFileClass.GetProp:MaxStatements      PROCEDURE()!,LONG,VIRTUAL
  code
  Return ''

!-----------------------------------------------------------------
DriverFileClass.GetProp:Memos              PROCEDURE()!,STRING,VIRTUAL  ! Get number of memos in file
  code
  Return self._NumMemos

!-----------------------------------------------------------------
DriverFileClass.GetProp:Memo               PROCEDURE()!,STRING,VIRTUAL  ! Remove memo from file definition (dynamic file support required)
  code
  Return ''

!-----------------------------------------------------------------
DriverFileClass.GetProp:Attributes      PROCEDURE(Long pIndex=0)
p  long
  code
  If pIndex = 0
    Return ''
  Elsif pIndex > 0
    If self._WithField(pIndex) = driver:ok
      p = instring('|',self.Fields.Name,1,1)
      If p
        Return clip(left(sub(self.Fields.Name,p+1,len(self.Fields.Name))))
      End
    End
  ElsIf self._WithBlob(pIndex) = driver:ok
    p = instring('|',self.blobs.Name,1,1)
    If p
      Return clip(left(sub(self.blobs.Name,p+1,len(self.blobs.Name))))
    End
  End
  Return ''

!-----------------------------------------------------------------
DriverFileClass.GetProp:Name               PROCEDURE(Long pIndex=0)
  code
  If pIndex = 0
    If self.status() = 0
      If self.FullPathName = ''
        self.FullPathName = self._GetString(self.ClaFCB.phyname)  ! only update if file is closed.
      End
    End
    Return clip(self.FullPathName)
  Elsif pIndex > 0
    If self._WithField(pIndex) = driver:ok
      If self.Fields.name = '' then return ''.
      Return self.Fields.column
    End
  ElsIf self._WithBlob(pIndex) = driver:ok
    If self.blobs.name = '' then return ''.
    Return self.blobs.column
  End
  Return ''

!-----------------------------------------------------------------
DriverFileClass.SetProp:Name               PROCEDURE(Long pIndex,String pName)
p  long
  code
  If pIndex = 0
    self.FullPathName = clip(pName)
    If self.FullPathName
      self._FullPathNameSetFromPropName = true
    Else
      self._FullPathNameSetFromPropName = false
    End
    Return
  Elsif pIndex > 0
    ! NOTE: This affects ALL instances of this stucture, on all threads, for the life of the program
    If self._WithField(pIndex) = driver:ok
      self.Fields.Name = pName
      p = Instring('|',self.Fields.Name,1,1)
      If p <= 1
        self.Fields.column = self.Fields.Name
      Else
        self.Fields.column = clip(sub(self.Fields.Name,1,p-1))
        If self.Fields.column = ''
          self.Fields.column = self.Fields.Name
        End
      End
      self.Fields.UpperColumn = upper(self.Fields.column)
    End
  ElsIf self._WithBlob(pIndex) = driver:ok
     self.blobs.name = pName
  End
  Return

!-----------------------------------------------------------------
DriverFileClass.GetProp:Object                PROCEDURE()
  code
  !self.trace('DriverFileClass.GetProp:Object=' & address(self))
  return address(self)

!-----------------------------------------------------------------
DriverFileClass.SetPROP:Object             PROCEDURE(Long pAddress)
newObj &DriverFileClass
table  &File
  code
  newObj &= (pAddress)
  table &= (self.ClaFCB)
  newObj.Init(table)

!-----------------------------------------------------------------
DriverFileClass.GetProp:Interface            PROCEDURE(LONG pIndex)
  code
  If pIndex
    If self._WithField(pIndex) = driver:ok
      return address(self.Fields.Interface)
    end
  end
  Return 0

!-----------------------------------------------------------------
! NOTE: This affects ALL instances of this stucture, on all threads, for the life of the program
DriverFileClass.SetCustomType              PROCEDURE(String pFieldLabel,iDriverField pInterface)
x    long
  code
  If self._WithFieldLabeled(pFieldLabel) = driver:ok
    self.SetPROP:Interface(self.Fields.Index,address(pInterface))
    Return Driver:ok
  End
  Return Driver:Notok

!-----------------------------------------------------------------
! NOTE: This affects ALL instances of this stucture, on all threads, for the life of the program
DriverFileClass.SetPROP:Interface         PROCEDURE(LONG pIndex,Long pAddress)
newObj &DriverFileClass
table  &File
  code
  If pIndex
    self.Fields &= self._withFieldNode(pIndex)
    If not self.Fields &= null
      self.Fields.Interface &= (pAddress)
      self.Fields.SourceSize = self.Fields.Interface.GetSourceSize()
      self.SharedProperties.HasCustomFields = true
    End
  End

!-----------------------------------------------------------------
DriverFileClass.GetProp:OEM                PROCEDURE()  ! Get OEM attribute
  code
  return Choose(self.SharedProperties.oem = true,'1','')
!-----------------------------------------------------------------
DriverFileClass.SETPROP:OEM                PROCEDURE(Byte pOEM)!VIRTUAL  ! Set OEM attribute
  code
  self.SharedProperties.oem = pOEM
  Return
!-----------------------------------------------------------------
DriverFileClass.GetProp:Owner              PROCEDURE()!,STRING,VIRTUAL ! Get Owner
  code
  If self._OwnerSetFromPropOwner = false
    self.Owner = self._GetString(self.ClaFCB.oname)
  End
  Return self.Owner
!-----------------------------------------------------------------
DriverFileClass.SETPROP:Owner              PROCEDURE(STRING pOwner)!,STRING,VIRTUAL ! Get Owner
  code
  self.Owner = clip(pOwner)
  If self.Owner
    self._OwnerSetFromPropOwner = true
  Else
    self._OwnerSetFromPropOwner = false
  End
  Return

!-----------------------------------------------------------------
DriverFileClass.GetProp:Over              PROCEDURE(Long pIndex)
  code
  If pIndex <= 0 then return ''.
  If self._WithField(pIndex) = driver:ok
    If self.Fields.Over
      return self.Fields.Over
    Else
      return 0 ! not ''
    End
  End
  Return ''

!-----------------------------------------------------------------
DriverFileClass.GetProp:Pool              PROCEDURE()
  code
  if self.pool = 0 then return '' else return self.pool.

!-----------------------------------------------------------------
DriverFileClass.SetProp:Pool              PROCEDURE(Long pValue)
  code
  self.pool = pValue

!-----------------------------------------------------------------
DriverFileClass.GetProp:Places             PROCEDURE(Long pIndex)!,STRING,VIRTUAL
  code
  If self._WithField(pIndex) = driver:ok
    case self.Fields.Type
    of ClaDECIMAL
    orof ClaPDECIMAL
      return self.Fields.DecimalPlaces
    end
  End
  Return ''
!-----------------------------------------------------------------
DriverFileClass.GetProp:Prefix             PROCEDURE()!,STRING,VIRTUAL
  code
  Return self.SharedProperties.prefix

!-----------------------------------------------------------------
DriverFileClass.GetProp:ProgressEvents     PROCEDURE()!,STRING,VIRTUAL  ! Set amount of events for BUILD
  code
  return ''
!-----------------------------------------------------------------
DriverFileClass.GetProp:Project            PROCEDURE()
  Code
  If self.Project &= null then return ''.
  Return self.Project

!-----------------------------------------------------------------
! the existance of primary key fields is not enforced here, because that would break prop:Distinct
! however the PaseProject method will set self._ProjectedPrimary to false if the primary key fields are not included.
DriverFileClass.SetProp:Project            PROCEDURE(String pValue)
  Code
  If self.Project &= null and pValue = '' then return.
  If self.Project &= null or size(self.Project) < size(pValue) + 1
    Dispose(self.Project)
    self.Project &= new Cstring(size(pValue)+1)
  End
  If self.Project <> clip(pValue)
    self.Project = clip(pValue)
    self._PropsCache += 1
  End
  Return

!-----------------------------------------------------------------
! if the file is opened in read-only mode, then setting prop:readonly to false will fail. Suggest ReOpen in that case.
DriverFileClass.SetPROP:ReadOnly       Procedure(Byte pValue)
  Code
  If pValue = false                             ! trying to unset read-only
    If band(self.Status(),11b) = 0    ! file is opened as read only, so
      self.ReadOnly = true
      Return
    end
  end
  self.ReadOnly = pValue
  Return

!-----------------------------------------------------------------
DriverFileClass.GetProp:Reclaim            PROCEDURE()!,STRING,VIRTUAL  ! Get Reclaim attribute
  code
  Return Choose(self.SharedProperties.reclaim = true,'1','')

!-----------------------------------------------------------------
DriverFileClass.GetProp:Record             PROCEDURE()!,STRING,VIRTUAL  ! Get the file's record buffer
  code
  Return self.ClaFCB.rec_buf & ':' & self.ClaFCB.rec_len & ':' & self.ClaFCB.t_desc

!-----------------------------------------------------------------
DriverFileClass.GetProp:RelationsOff       PROCEDURE()
  code
  Return Choose(self._relationsOff = true,'1','')

!-----------------------------------------------------------------
DriverFileClass.GetProp:Size               PROCEDURE(Long pIndex)
  code
  !self.trace('GetProp:Size ' & pIndex)
  If pIndex > 0 and self._WithField(pIndex) = driver:ok
    Case self.Fields.Type
    Of ClaDECIMAL
    Orof ClaPDECIMAL
      Return self.Fields.DecimalSize
    Else
      Return self.Fields.Size
    End
  ElsIf pIndex < 0 and self._WithBlob(pIndex) = driver:ok
    If self.blobs.Memo = true
      Return self.blobs.memosize
    Else
      Return self.blobs.handlesize
    End
  End
  Return 0

!-----------------------------------------------------------------
DriverFileClass.SetPROP:ServerAutoInc      PROCEDURE(Long pIndex,BIGINT pValue)
  code
  If pIndex = 0
    !if self.HasIdentity = false then self.HasIdentity = true.
  Else
    If self._WithField(pIndex) = Driver:ok and self.Fields.IsIdentity = false
      self.Fields.IsIdentity = true
      !Put(self.Fields)
      !!!todo
    End
  End
  Return

!-----------------------------------------------------------------
DriverFileClass.SetPROP:Size               Procedure(Long pIndex,BIGINT pValue)
  code
  If pIndex < 0
    self.SetBlobProp:Size(pIndex,pValue)
  End
  Return

!-----------------------------------------------------------------
DriverFileClass.GetProp:StmtAttr           Procedure()!,STRING,VIRTUAL
  code
  return ''
!-----------------------------------------------------------------
DriverFileClass.GetProp:SQLDriver          Procedure()!,STRING,VIRTUAL  ! '1' = Driver is SQL aware
  code
  return ''
!-----------------------------------------------------------------
DriverFileClass.GetProp:SupportsOp         Procedure(Byte pOpCode)!,STRING,VIRTUAL  ! Get which functions are supported
tdesc  String(255)
ops    byte
  code
  peek(self.TypeDescriptorAddress,ops)
  MemCpy(address(tdesc),self.TypeDescriptorAddress,ops+1)
  if instring(chr(pOpCode),tdesc[ 2 : ops + 1],1,1)
    return '1'
  end
  return ''
!-----------------------------------------------------------------
DriverFileClass.GetProp:SupportsType       Procedure(Byte pType)!,STRING,VIRTUAL  ! Get which data types are supported
tdesc  String(255)
ops    byte
typs   byte
  code
  peek(self.TypeDescriptorAddress,ops)
  peek(self.TypeDescriptorAddress+ops+1,typs)
  MemCpy(address(tdesc),self.TypeDescriptorAddress,ops + 2 + typs + 1)
  if instring(chr(pType),tdesc[ ops+2 : ops + 2 + typs + 1],1,1)
    return '1'
  end
  Return ''

!-----------------------------------------------------------------
! Pure virtual, filled in by the actual driver
DriverFileClass._LoadArray             Procedure(*String pStr, Long pIndex)
  code

!-----------------------------------------------------------------
! a string containing a JSON array is being moved into a Clarion Array
! This splits the Json into separate values, then moves each value into an element in the array.
DriverFileClass._PutJsonAsField        Procedure(*String pStr, Long pIndex)
str  StringTheory
lne  StringTheory
x    long
  Code
  !self.trace('_PutJsonAsField ' & self.fields.Column & ' pIndex=' & pIndex & ' pStr=' & pStr)
  self._ClearField()
  str.SetValue(clip(pStr))
  str.removeChars('[]')
  str.split(',','"','"',true)
  loop x = 1 to str.records()
    lne.SetValue(str.GetLine(x))
    lne.JsonDecode()
    self._PutJsonAsFieldWorker(lne,pIndex,x)
  End
  Return

!-----------------------------------------------------------------
DriverFileClass._PutJsonAsFieldWorker        Procedure(StringTheory pStr, Long pIndex, Long pArrayIndex)
addr    long,auto    ! address to write into record buffer
offset  long,auto    ! the memory offset into the array
b       byte,auto
sh      short,auto
ush     short,auto
lg      long,auto
ulg     ulong,auto
rl      real,auto
srl     sreal,auto
dt      date,auto
tm      time ,auto
strdf   string(16),auto
  code
  offset = (pArrayIndex-1) * self.Fields.Size
  if Offset +  self.Fields.Size > self.Fields.Length then Return.
  addr = self.ClaFCB.rec_buf + self.Fields.Offset + offset
  !self.trace('_PutJsonAsField: [' & pStr.GetValue() & '] pArrayIndex=' & pArrayIndex & ' offset=' & offset & ' self.Fields.Offset= ' & self.Fields.Offset & ' self.ClaFCB.rec_buf=' & self.ClaFCB.rec_buf & ' addr=' & addr)
  Case self.Fields.Type
  of ClaBYTE
    b = pStr.GetValue()
    memcpy(Addr,address(b),1)
  of ClaShort
    sh = pStr.GetValue()
    memcpy(Addr,address(sh),2)
  of ClaUShort
    ush = pStr.GetValue()
    memcpy(Addr,address(ush),2)
  of ClaLong
    lg = pStr.GetValue()
    memcpy(Addr,address(lg),4)
  of ClaULong
    ulg = pStr.GetValue()
    memcpy(Addr,address(lg),4)
  of ClaReal
    rl = pStr.GetValue()
    memcpy(Addr,address(rl),8)
  of ClaSReal
    srl = pStr.GetValue()
    memcpy(Addr,address(srl),4)
  of ClaString
    If self.fields.SqlTimeStamp
      pStr.SetValue(self.DeformatText(pStr.GetValue()))
    End
    If pStr.Length() <> self.Fields.size then pStr.SetLength(self.Fields.size).
    memcpy(Addr,pStr.GetAddress(),pStr.Length())

  of ClaCString
    If pStr.Length() < self.Fields.size-1
      pStr.Append(all('<0>',self.Fields.size - pStr.Length()))
    End
    pStr.SetSlice(self.Fields.size,self.Fields.size,'<0>')
    memcpy(Addr,pStr.GetAddress(),self.Fields.size)
  of ClaPString
    If pStr.Length() > self.Fields.size-1 then pStr.SetLength(self.Fields.size-1).
    lg = pStr.Length()
    If pStr.Length() < self.Fields.size-1
      pStr.Append(all('<32>',self.Fields.size - pStr.Length()))
    End
    memset(Addr,lg,1)
    memcpy(Addr+1,pStr.GetAddress(),self.Fields.size-1)
  of ClaDate
  orof ClaTime
  orof ClaDecimal
  orof ClapDecimal
    strdf = self.DeformatText(pStr.GetValue())
    memcpy(Addr,address(strdf),self.Fields.size)
  End
  Return

!-----------------------------------------------------------------
DriverFileClass._GetFieldAsJson           Procedure(Long pIndex)
str  StringTheory
  code
  If self._WithField(pIndex) = driver:ok
    If self.Fields.DimProduct = 1
      case self.Fields.Type
      of ClaSTRING
      orof ClaCSTRING
      orof ClaPSTRING
        str.SetValue(self._GetFieldAsText(pIndex,1))
        If self.fields.SqlTimeStamp
          str.SetValue(self.FormatTimeStamp(str.GetValue()))
        end
        str.JsonEncode()
        Return '["' & str.GetValue() & '"]'
      of ClaDATE
        str.SetValue(self.FormatDate(self._GetFieldAsText(pIndex,1)))
        str.JsonEncode()
        Return '["' & str.GetValue() & '"]'
      of ClaTIME
        str.SetValue(self.FormatTime(self._GetFieldAsText(pIndex,1)))
        str.JsonEncode()
        Return '["' & str.GetValue() & '"]'
      Else
        Return '[' & self._GetFieldAsText(pIndex,1) & ']'
      End
    Else
      self._GetArrayAsJson(str,pIndex)
      Return str.GetValue()
    End
  End
  Return ''

!-----------------------------------------------------------------
! multi-dimensional array, but in memory is a 1D array. So convert the multiple indicies into a single value
DriverFileClass._CalcIndex  Procedure()
ans     Long
x       Long
mx      Long
  Code
  ans = self._indicies[self.Fields.dims]  ! Start with last dimension
  mx = 1
  ! Work backwards through dimensions, accumulating the index
  Loop x = self.Fields.dims-1 TO 1 BY -1
    mx *= self.Fields.dim[x+1]        ! Calculate mx for this dimension. Is the max of all lower dimensions multiplied together
    ans += (self._indicies[x] - 1) * mx
  End
  Return ans

!-----------------------------------------------------------------
! Fields Queue is already loaded.
DriverFileClass._GetArrayAsJson             PROCEDURE(StringTheory pStr,Long pIndex)
x  long
  code
  pStr.SetValue('')
  !self.trace('Dims=' & self.Fields.Dims & ' dim[1]=' &self.Fields.Dim[1]  & ' dim[2]=' &self.Fields.Dim[2]  & ' dim[3]=' &self.Fields.Dim[3] )
  loop x = 1 to self.Fields.Dims
    self._indicies[x] = 1
  End
  self._GetArrayAsJsonWalker(pStr,pIndex, 1)
  Return

!-----------------------------------------------------------------
DriverFileClass._GetArrayAsJsonWalker Procedure(StringTheory pStr,Long pIndex,Long pDim)
x           Long
ArrayIndex  Long
str         StringTheory
  Code
  If pDim = self.Fields.Dims
    pStr.Append('[')
    Loop x = 1 to self.Fields.dim[pDim]
      self._indicies[pDim] = x
      If x > 1
        pStr.Append(',')
      End
      ArrayIndex = self._calcIndex()
      case self.Fields.Type
      of ClaSTRING
      orof ClaCSTRING
      orof ClaPSTRING
        str.SetValue(self._GetFieldAsText(pIndex,ArrayIndex))
        If self.fields.SqlTimeStamp
          str.SetValue(self.FormatTimeStamp(str.GetValue()))
        end
        str.JsonEncode()
        pStr.Append('"' & str.GetValue() & '"')
      of ClaDATE
        str.SetValue(self.FormatDate(self._GetFieldAsText(pIndex,ArrayIndex)))
        str.JsonEncode()
        pStr.Append('"' & str.GetValue() & '"')
      of ClaTIME
        str.SetValue(self.FormatTime(self._GetFieldAsText(pIndex,ArrayIndex)))
        str.JsonEncode()
        pStr.Append('"' & str.GetValue() & '"')
      Else
        pStr.Append(self._GetFieldAsText(pIndex,ArrayIndex))
      End
    End
    pStr.Append(']')
    Return
  End

  pStr.Append('[')
  Loop x = 1 to self.Fields.dim[pDim]
    self._indicies[pDim] = x
    If x > 1
      pStr.Append(',')
    End
    self._GetArrayAsJsonWalker(pStr,pIndex,pDim+1)
  END
  pStr.Append(']')
  Return

!-----------------------------------------------------------------
DriverFileClass._GetFieldAsText             PROCEDURE(Long pIndex)
  code
  If self._WithField(pIndex) = driver:ok
    If self.Fields.DimProduct = 1
      Return self._GetFieldAsText(pIndex,1)
    Else
      Return self._GetArrayAsText(pIndex)
    End
  End
  Return ''

!-----------------------------------------------------------------
! Fields Queue is already loaded.
DriverFileClass._GetArrayAsText             PROCEDURE(Long pIndex)
str  stringtheory
txt  stringtheory
x    long
  code
  Loop x = 1 to self.Fields.DimProduct
    txt.SetValue(self._GetFieldAsText(pIndex,x))
    If txt.instring('"') or txt.instring(',')
      txt.replace('"','""')
      str.append('"' & txt.getvalue() & '"',,',')
    Else
      str.append(txt.getvalue(),,',')
    End
  End
  Return str.getvalue()

!-----------------------------------------------------------------
! Fields Queue is already loaded.
DriverFileClass._GetFieldAsText           PROCEDURE(Long pIndex, Long pArrayIndex)
addr  long
b     &byte
sh    &short
ush   &ushort
lg    &long
ulg   &ulong
rl    &real
srl   &sreal
st    &string
cst   &cstring
pst   &pstring
dt    &date
tm    &time
str   string(36)
  code
  If pArrayIndex < 1 then pArrayIndex = 1.
  addr = self.ClaFCB.rec_buf + self.Fields.Offset + ((pArrayIndex -1) * self.Fields.Size)
  case self.Fields.Type
  of ClaBYTE
    b &= (addr)
    Return b
  of ClaSHORT
    sh &= (addr)
    Return sh
  of ClaUSHORT
    ush &= (addr)
    Return ush
  of ClaLONG
    lg &= (addr)
    Return lg
  of ClaULONG
    ulg &= (addr)
    Return ulg
  of ClaREAL
    rl &= (addr)
    Return rl
  of ClaSREAL
    srl &= (addr)
    Return srl
  of ClaSTRING
    st &= (addr) & ':' &  self.Fields.Size
    return clip(st)
  of ClaCSTRING
    cst &= (addr) & ':' &  self.Fields.Size
    return cst
  of ClaPSTRING
    pst &= (addr) & ':' &  self.Fields.Size
    return pst
  of ClaDATE
    dt &= (addr)
    str = dt            ! clarion standard date, not formatted
    return clip(str)
  of ClaTIME
    tm &= (addr)
    str = tm            ! clarion standard time, not formatted
    return clip(str)
  of ClaDECIMAL
  orof ClaPDECIMAL
    self._DecToString(addr,self.Fields.Size,self.Fields.DecimalSize,self.Fields.DecimalPlaces,self.Fields.Type, str)
    return clip(str)
  End
  Return ''

!-----------------------------------------------------------------
DriverFileClass.GetProp:Text               PROCEDURE(Long pIndex)!,STRING,VIRTUAL
  code
  If pIndex < 0
    Return self.GetProp:Value(pIndex)
  Else
    Return Self._GetFieldAsText(pIndex)
  End
  Return ''

!-----------------------------------------------------------------
DriverFileClass.SETPROP:Text               PROCEDURE(Long pIndex,String pValue)
  code
  If pIndex < 0
    self.SetProp:Value(pIndex,pValue)
  End
  Return

!-----------------------------------------------------------------
DriverFileClass.GetProp:Thread               PROCEDURE()
  code
  return Choose(self.SharedProperties.threaded = true,'1','')
!-----------------------------------------------------------------
DriverFileClass.GetProp:Touched             PROCEDURE(Long pIndex)
  code
  return ''
!-----------------------------------------------------------------
DriverFileClass.GETPROP:TryConnectedAs     Procedure()
  code
  return self._TryConnectedAs
!-----------------------------------------------------------------
DriverFileClass.GetProp:Type                PROCEDURE(Long pIndex)!,STRING,VIRTUAL
  code
  If pIndex = 0
    return ''
  ElsIf pIndex < 0
    If self._WithBlob(pIndex) = driver:ok
      If self.blobs.Memo = 1 then return 'MEMO'.
      Return 'BLOB'
    End
  Else
    self.Fields &= self._withFieldNode(pIndex)
    If not self.Fields &= null
      Return self.InterpretType(self.Fields.Type)
    End
  End
  Return ''
!-----------------------------------------------------------------
! For Memos and Blobs this method returns the value as always.
! For memos the whole memo space is returned (ie includes space padding where applicable.)
! For fields, this property now also works. It returns the raw memory from the record, assigned to this field.
! If the field is an array then the "whole" block is returned. (ie all array values).
! If the field is a string, Cstring, or PString then the whole allocated space is returned.
! This operates directly on the record buffer, so custom fields do not matter, the representation in the record buffer is returned.
!
DriverFileClass.GetProp:Value              PROCEDURE(Long pIndex)
str  &string
  code
  If pIndex > 0 and self._WithField(pIndex) = driver:ok
    !self.Trace('GetProp:Value ' & pIndex & ' ' & self.Fields.index & ' self.Fields.Offset=' & self.Fields.Offset & ' self.Fields.Length=' & self.Fields.Length)
    str &= self.ClaFCB.rec_buf & ':' & self.ClaFCB.rec_len
    Return str[self.Fields.Offset + 1 : self.Fields.Offset + self.Fields.Length]
  Elsif pIndex < 0 and self._WithBlob(pIndex) = driver:ok
    If self.blobs.memo
      return self.blobs.memostring
    else
      return self.GetBlob(pIndex)
    End
  End
  Return ''
!-----------------------------------------------------------------
! For Memos and Blobs this method sets the value as always.
! For fields it sets the value in the record buffer.
DriverFileClass.SETPROP:Value              PROCEDURE(Long pIndex,String pValue)
str  &string
  code
  If pIndex > 0 and self._WithField(pIndex) = driver:ok
  Elsif pIndex < 0
    Self.SetBlob(pIndex,0,pValue,true)
  end
  Return

!-----------------------------------------------------------------
DriverFileClass.GetProp:Uuid               PROCEDURE(Long pIndex)!,STRING,VIRTUAL
  Code
  return self.GenerateUUIDv8()

!-----------------------------------------------------------------
DriverFileClass.GetProp:Uuid4              PROCEDURE(Long pIndex)!,STRING,VIRTUAL
  Code
  return self.GenerateUUIDv4()

!-----------------------------------------------------------------
DriverFileClass.GetProp:Uuid7              PROCEDURE(Long pIndex)!,STRING,VIRTUAL
  Code
  return self.GenerateUUIDv7()

!-----------------------------------------------------------------
DriverFileClass.GetProp:Uuid8              PROCEDURE(Long pIndex)!,STRING,VIRTUAL
  Code
  return self.GenerateUUIDv8()

!-----------------------------------------------------------------
DriverFileClass.GetProp:Watched            PROCEDURE()!,STRING,VIRTUAL  ! Get record watch status
  code
  return self.watching
!=================================================================
!-----------------------------------------------------------------
! KEY Properties
! The above GETKEYPROPERTY method calls into these methods, one for each specific property.
! Most of these methods do not need to be derived by a specific driver. Ones that are are marked with !!! DERIVE
!-----------------------------------------------------------------
!-----------------------------------------------------------------
DriverFileClass.GETKEYPROP:Ascending       PROCEDURE(KEY pKey, Long pField)
  code
  If self._withKey(pKey) = driver:ok
    If pField > 0 and pField < maximum(self.keys.component,1) and pField <= self.keys.components
      Return Choose(self.keys.descending[pField] = true , '' , '1')
    End
  End
  Return ''

!-----------------------------------------------------------------
!DriverFileClass.GETKEYPROP:Fields     PROCEDURE(KEY pKey)     ! prop:Fields and prop:Components return the same value
DriverFileClass.GETKEYPROP:Components     PROCEDURE(KEY pKey)
  code
  if self._withKey(pKey) = driver:ok
    return self.keys.components
  end
  return ''
!-----------------------------------------------------------------
DriverFileClass.GETKEYPROP:Dup             PROCEDURE(KEY pKey)
  code
  If self._withKey(pKey) = driver:ok
    Return Choose(self.keys.dup = true, '1','')
  End
  Return ''
!-----------------------------------------------------------------
DriverFileClass.GETKEYPROP:Field       PROCEDURE(KEY pKey, Long pField)
  code
  !self.trace('DriverFileClass.GETKEYPROP:Field pField=' & pField)
  If self._withKey(pKey) = driver:ok
    !self.trace('found key ' & self.keys.label & ' ' & self.keys.components & '  ' & self.keys.component[1])
    If pField > 0 and pField <= maximum(self.keys.component,1)
      If self.keys.component[pField] = 0 then return ''.
      Return self.keys.component[pField]
    End
  End
  Return ''
!-----------------------------------------------------------------
DriverFileClass.GETKEYPROP:Label           PROCEDURE(KEY pKey)
  code
  if self._withKey(pKey) = driver:ok
    return self.keys.label
  end
  return ''
!-----------------------------------------------------------------
DriverFileClass.GETKEYPROP:Name           PROCEDURE(KEY pKey)
  code
  if self._withKey(pKey) = driver:ok
    return self.keys.name
  end
  return ''
!-----------------------------------------------------------------
DriverFileClass.GETKEYPROP:NoCase           PROCEDURE(KEY pKey)
  code
  if self._withKey(pKey) = driver:ok
    return choose(self.keys.nocase = true, '1','')
  end
  return ''
!-----------------------------------------------------------------
DriverFileClass.GETKEYPROP:Opt             PROCEDURE(KEY pKey)
  code
  if self._withKey(pKey) = driver:ok
    return choose(self.keys.opt = true, '1','')
  end
  return ''
!-----------------------------------------------------------------
DriverFileClass.GETKEYPROP:Primary          PROCEDURE(KEY pKey)
  code
  if self._withKey(pKey) = driver:ok
    return choose(self.keys.primary = true, '1','')
  end
  return ''
!-----------------------------------------------------------------
DriverFileClass.GETKEYPROP:Type      PROCEDURE(KEY pKey)
  code
  if self._withKey(pKey) = driver:ok
    case self.keys.type
    of Cla_Key
      return 'KEY'
    of Cla_Index
      return 'INDEX'
    of Cla_DynIndex
      return 'INDEX'  !
    end
  end
  return ''
!!-----------------------------------------------------------------
!! move one field from the source into the file record.
!! fieldsqueue is already loaded.
!DriverFileClass._ToRecordField   Procedure(Byte pFieldType, Long pFieldAddress, Long pFieldSize, Long pSrcType, Long pSrcAddr, Long pSrcSize)
!!b byte
!  code
!  If not self.Fields.Interface &= null
!    self.Fields.interface.ToRecordField(pFieldType,pFieldAddress,pFieldSize,pSrcType,pSrcAddr,pSrcSize)
!  Else
!    If pFieldSize < pSrcSize then pSrcSize = pFieldSize.
!    If pFieldType = ClaPSTRING                          ! SQL databases don't have pStrings, just strings, so we can do a generic conversion here
!      If pSrcSize > pFieldSize - 1
!        self.SetError(DataTruncatedError)
!      else
!        memset(pFieldAddress,pSrcSize,1)
!        memcpy(pFieldAddress+1,pSrcAddr,pSrcSize)
!      end
!    Else
!      memcpy(pFieldAddress,pSrcAddr,pSrcSize)
!    End
!    If pFieldSize > pSrcSize
!      Case pFieldType
!      Of ClaSTRING
!        memset(pFieldAddress + pSrcSize,32, pFieldSize - pSrcSize)               ! pad with spaces
!      Of ClaPSTRING
!        If pFieldSize-1 > pSrcSize
!          memset(pFieldAddress + pSrcSize + 1,32, pFieldSize - pSrcSize - 1)     ! pad with spaces
!        End
!      Else
!        memset(pFieldAddress + pSrcSize,0, pFieldSize - pSrcSize)                ! pad with nulls
!      End
!    End
!  End
!  Return

!-----------------------------------------------------------------
   !!!todo - update this for unicode ; see GetStringTypeW
DriverBaseClass._Sanitize      Procedure(String pStr, Long pContext)
x               Long
  Code
  self.tempstr.SetValue(pStr,st:clip)
  case band(pContext, 01111111b)
  of driver:DosFile
    self.tempstr.CleanFileName( , ,st:allowpath)
  of driver:SqlTable
    self.tempstr.KeepChars('._[$#@]"','_',st:AllAlphaNum)
  of driver:order
  orof driver:groupby
    self.tempstr.KeepChars('_ ,()+-*/''|<<>=','_',st:AllAlphaNum)
  of driver:filter
  orof driver:searchfilter
  orof driver:expression
    self.tempstr.RemoveChars(';')
  of driver:SqlSavepoint
    self.tempstr.KeepCharRanges('A-Z0-9a-z')
  end
  return self.tempstr.GetValue()



!=============================================================================
!  DriverFileSQLClass
!=============================================================================
!-----------------------------------------------------------------
DriverFileSQLClass.CONSTRUCT                 PROCEDURE()
  Code
  self.LoginTimeout = 10      ! could probably be less.
  self.opt:BusyTimeout = 60   ! might need to be more? perhaps a lot more?
  self.opt:zerodate = -1      ! null

!-----------------------------------------------------------------
DriverFileSQLClass.DESTRUCT                  PROCEDURE()
  Code

!-----------------------------------------------------------------
DriverFileSQLClass.INIT            PROCEDURE(FILE pFile, Long pForce=false)!,DERIVED
  code
  parent.Init(pFile,pForce)
  Return

!-----------------------------------------------------------------
DriverFileSQLClass.SetDriverOption            Procedure(String pOption, String pValue)
  Code
  Case upper(pOption)
  of '/ALLOWDETAILS'
    If pValue <> ''
      do checkBoolean
      self.opt:AllowDetails = pValue
    End
    Return self.opt:AllowDetails
  of '/LOGFILENAME'
    If pValue <> ''
      if self.opt:LogFileName &= null then self.opt:LogFileName &= new Cstring(255).
      self.opt:LogFileName = clip(pValue)
    End
    If self.opt:LogFileName &= null then return '' else return self.opt:LogFileName.
  of '/LOGMESSAGE'
    If pValue <> ''
      if self.opt:LogMessage &= null then self.opt:LogMessage &= new Cstring(255).
      self.opt:LogMessage = clip(pValue)
    End
    Return ''
  of '/MASTER'
    case upper(pValue)
    of 'DATABASE'
      self.opt:master = driver:database
    of 'DICT'
      self.opt:master = driver:dict
    of 'DICTFIELD'
      self.opt:master = driver:dictfield
    of 'DICTKEY'
      self.opt:master = driver:dictkey
    of 'STRICTDICT'
      self.opt:master = driver:strictdict
    end
  of '/TURBOSQL'
    if pValue <> '' then
      do checkBoolean
      self.opt:TurboSQL = pValue
    End
    Return self.opt:TurboSQL
  of '/ZERODATE'
    case upper(pValue)
    of 'NULL'
      self.opt:zerodate = -1
    of 'TRUE' orof '1'
      self.opt:zerodate = 1
    of 'FALSE' orof '0'
      self.opt:zerodate = 0
    else
      self.opt:zerodate = pValue
    End
  End
  Return parent.SetDriverOption(pOption,pValue)

CheckBoolean  routine
  case upper(pValue)
  of 'TRUE'
    pValue = 1
  of 'FALSE'
    pValue = 0
  End

!-----------------------------------------------------------------
DriverFileSQLClass.CheckConnect    PROCEDURE()
  Code
  Return Driver:NotOk

!-----------------------------------------------------------------
DriverFileSQLClass.ADD             PROCEDURE(LONG pLength)
  Code
  parent.Add(pLength)
  If Errorcode() then Return.
  self.SetError(NoDriverSupport)
  Return

!-----------------------------------------------------------------
DriverFileSQLClass.APPEND           PROCEDURE(LONG pLength)
  Code
  parent.Append(pLength)
  If Errorcode() then Return.
  self.SetError(NoDriverSupport)
  Return

!-----------------------------------------------------------------
! In SQL tables, if BYTES(file) is used before the file is opened, then it returns the number of rows in the table.
! If it is used after the file is open it returns the number of bytes in the record buffer.
DriverFileSQLClass.BYTES            PROCEDURE()
x  Long,Auto
  Code
  x = Parent.Bytes()
  if self._opened = false
    Return self.Records()
  else
    Return self.ClaFCB.rec_len
  End

!-----------------------------------------------------------------
DriverFileSQLClass.CreateDB      PROCEDURE(String pDatabaseName)
  code
  !self.trace('DriverFileSQLClass.CreateDB')
  If self._CheckClosed() = false then Return.
  Return

!-----------------------------------------------------------------
DriverFileSQLClass.CONNECT     PROCEDURE(Long pOptions=0)
  Code
  If self.dbHandle <> 0
    Self.Disconnect()
  End
  self._UpdateFileStrings()
  If self.Owner = ''
    self.SetError(FileSystemErr)
    Self.SetFileError(BadOwnerErr,'BadOwnerErr: No OWNER attribute specified')
    Return
  End
  self.SetError(NoError)
  Return

!-----------------------------------------------------------------
! although mostly common SQL syntax, use of ON CONFLICT and RETURNING are database specific.
!!! DERIVE
DriverFileSQLClass._AddSQL       Procedure(Long pOpcode)
  code
  return driver:notok

!-----------------------------------------------------------------
! The SQL for a DELETE is pretty standard. However this method may need to be derived in a specific driver
! if the SQL syntax is different.
! In some SQL engines, SQL Aliases are not allowed in DELETE commands. (SQLite and MySQL)
DriverFileSQLClass._DeleteSQL          PROCEDURE()
x      Long,Auto
Where  StringTheory
Offset Long
  code
  self._ClearParameterQueue(self._ParameterOpcode)
  If self._WithPrimaryKey() = Driver:ok
    Loop x = 1 to self.keys.components
      If self._WithField(self.keys.component[x]) = Driver:ok
        self._ParameterCount += 1
        self._SetParameterNode(self._ParameterCount,self.fields,driver:FromPrimaryKeyPosition,Offset)
        Offset += self.fields.Length
        where.Append(self.Fields.Column & '= ' & self._genparm(self._ParameterCount) ,st:NoClip,' AND ')
      End
    End
    self.SqlCode.SetValue('DELETE FROM ' & self._sanitize(self.FullPathName,driver:sqlTable) & ' WHERE ' & where.GetValue() & ';')
    Return driver:ok
  End
  Return driver:notok

!-----------------------------------------------------------------
! The SQL for a DELETE is pretty standard. However this method may need to be derived in a specific driver
! if the SQL syntax is different.
! In some SQL engines, SQL Aliases are not allowed in DELETE commands. (SQLite and MySQL)
DriverFileSQLClass._DeleteSQL           PROCEDURE(String pFilter)
filter  StringTheory
!count   long
  code
  self._ClearParameterQueue(self._ParameterOpcode)
  If self.ParseProperty(pFilter,driver:filter,self.TokenStr) = driver:notok
    self.SetError(BadFilterErr)
    return driver:notok
  End
  self._NoAlias = true
  filter.SetValue(self._ExpandExpression(self.TokenStr.GetValue()))
  self._NoAlias = false
  self.SqlCode.SetValue('DELETE FROM ' & self._sanitize(self.FullPathName,driver:sqlTable) & ' WHERE ' & filter.GetValue() & ';')
  Return driver:ok

!-----------------------------------------------------------------
DriverFileSQLClass._DuplicateSQL          PROCEDURE(KEY pKey)
x        long
where    StringTheory
  Code
  self._ClearParameterQueue(self._ParameterOpcode)
  If self._withkey(pKey) = Driver:ok
    Loop x = 1 to self.keys.components
      If self._withField(self.keys.component[x]) = driver:ok
        self._ParameterCount += 1
        self._SetParameterNode(self._ParameterCount,self.fields,driver:FromBuffer,0)
        where.append(self.Fields.Column & '= ' & self._genparm(self._ParameterCount) ,st:NoClip, ' AND ')
      End
    End
    self.SqlCode.SetValue('SELECT COUNT (1) FROM ' & self._sanitize(self.FullPathName,driver:sqlTable) & ' WHERE ' & where.GetValue() & ';')
    Return Driver:ok
  End
  Return driver:NotOk

!-----------------------------------------------------------------
!!!DERIVE
DriverFileSQLClass.DISCONNECT     PROCEDURE()
  Code
  If self._closing = false and self._CheckOpen() = true
    self.Close()
  End
  self.SetError(NoError)
  self._ConnectedAs = ''
  self._ConnectedPool = 0
  Return

!-----------------------------------------------------------------
! The SQL for a GET is pretty standard. However this method may need to be derived in a specific driver
! if the SQL syntax is different.
DriverFileSQLClass._GetSQL  Procedure(KEY pKey)
count       Long
x           Long,Auto
stmt        Long
FieldsList  StringTheory
Where       StringTheory
  Code
  self._ClearParameterQueue(self._ParameterOpcode)
  If self._WithKey(pKey) = Driver:ok
    self.BuildProjectList()                   ! calling this can reset the key loaded
  End
  If self._WithKey(pKey) = Driver:ok
    self.BuildProjectListAppendClauses()      ! calling this can reset the key loaded
  end
  If self._WithKey(pKey) = Driver:ok
    Loop x = 1 to self.keys.components
      If self._WithField(self.keys.component[x]) = Driver:ok
        self._ParameterCount += 1
        self._SetParameterNode(self._ParameterCount,self.fields,driver:FromBuffer,0)
        where.Append(self._GetAlias(driver:withdot) & self.Fields.Column & '= ' & self._genparm(self._ParameterCount) ,st:NoClip,' AND ')
      End
    End
    self.SqlCode.SetValue('SELECT ' & self.ProjectList.GetValue() & ' FROM ' & self._sanitize(self.FullPathName,driver:sqlTable) & ' ' & self._GetAlias(driver:nodot) & ' WHERE ' & where.GetValue() & ';')
    Return driver:ok
  End
  Return Driver:NotOk

!-------------------------------------------------------------------------------------------------
! set minimum filter from the orderBy field values based on the values in the shadow buffer.
! If the setkeykey form is used the the shadow buffer is primed .
! If the setkey form was used then the shadow buffer is clear for the first page, but may be primed for future pages.
! This method doesn't use the shadow buffer value - that's plugged in later via parameters
DriverFileSQLClass._AddOrderToWhere   Procedure(StringTheory pWhere,Byte pOpCode)
x              long
con            cstring(3)
RecsOrderBy    long
orc            StringTheory
  code
  pWhere.SetValue('')
  If self.SetMethod = driver:SetKeyKey or (self.Paging = true and self.Limit = 0)
    RecsOrderBy = records(self.OrderQueue)
    Loop x = 1 to RecsOrderBy
      Get(self.OrderQueue,x)
      If (self.OrderQueue.Direction = driver:Descending and pOpcode = Opcode:NEXT) or |
         (self.OrderQueue.Direction = driver:Ascending and pOpcode = Opcode:PREVIOUS)
        con = '<'
      Else
        con = '>'
      end
      If x = RecsOrderBy
        con = clip(con) & '='
      end
      If self.OrderQueue.FieldIndex = 0
        self._ParameterCount += 1
        self._SearchParameter = self._ParameterCount   !!!todo currently the only order queue clause supported here is rank_fts
        If x = 1
          ! first term in the prop:order is the search rank parameter
          pWhere.append('(' & self.OrderQueue.Clause & ' ' & con & ' ' & self._genparm(self._ParameterCount) & ')')
        Else
          ! some other term in the order is the rank parameter
          self._ParameterCount += 1
          If self.AllowParameterRepeats
            pWhere.append(' OR (' & orc.getvalue())
          Else
            pWhere.append(' OR (' & self._reparm(orc,self._ParameterCount))
          End
          pWhere.append(' AND ' &  self.OrderQueue.Clause & ' ' & con & ' ' & self._genparm(self._ParameterCount) & ')')
        End
        If self.AllowParameterRepeats
          orc.append(self.OrderQueue.Clause & ' = '& self._genparm(self._ParameterCount) ,st:noclip,' AND ')
        Else
          orc.append(self.OrderQueue.Clause & ' = @<<{{' & self._ParameterCount & '}>@' ,st:noclip,' AND ')
        End

      ElsIf self._WithField(self.OrderQueue.FieldIndex) = driver:ok
        If x = 1 !or fp = false
          !fp = true
          self._ParameterCount += 1
          self._SetParameterNode(self._ParameterCount,self.fields,driver:FromShadow,0)
          pWhere.append('(' & self._GetAlias(driver:withdot) & self.Fields.Column & ' ' & con & ' ' & self._genparm(self._ParameterCount) & ')')
        Else
          If self.AllowParameterRepeats
            pWhere.append(' OR (' & orc.getvalue())
          Else
            pWhere.append(' OR (' & self._reparm(orc,self._ParameterCount))
          End
          self._ParameterCount += 1
          self._SetParameterNode(self._ParameterCount,self.fields,driver:FromShadow,0)
          pWhere.append(' AND ' &  self._GetAlias(driver:withdot) & self.Fields.Column & ' ' & con & ' ' & self._genparm(self._ParameterCount) & ')')
        End
        If self.AllowParameterRepeats
          orc.append(self._GetAlias(driver:withdot) & self.Fields.Column & ' = ' & self._genparm(self._ParameterCount) ,st:noclip,' AND ')
        Else
          orc.append(self._GetAlias(driver:withdot) & self.Fields.Column & ' = @<<{{' & self._ParameterCount & '}>@',st:noclip,' AND ')
        End
      End
    End
  End
  Return

!-----------------------------------------------------------------
! note that this is the FILE set, not the VIEW set, however prop:order and prop:filter are in play
! SET _Always_ prepares a new stmt.
! This code is reasonably generic between databases, however specific drivers may want, or need, to override this method.
DriverFileSQLClass._SelectSQL  Procedure(Long pOpcode)
offset              Long
where               StringTheory
cte                 StringTheory
from                Cstring(255)
tok                 StringTheory

  Code
  !self.trace('DriverFileSQLClass._SelectSQL pOpcode=' & pOpcode)
  self._ClearParameterQueue(Opcode:Set)
  self._WhereParmNumber = 1
  self._setdirection = pOpcode
  !self._ParameterOpcode = Opcode:SET
  !!!todo is _setDirection the same as _ResultSetDirection ?
  self.BuildProjectList()
  self.BuildGroupBy()
  self.BuildHaving()
  self.BuildProjectListAppendClauses()

  ! ORDER BY Clause
  self.BuildOrderBy()               ! Builds the self.OrderQueue. Sets the Prop:OrderBy based on the SetDirection

  ! WHERE
  self._AddOrderToWhere(where,pOpCode)      ! count is returned

  ! so the order is based on the "key,key" and the filter so far is based on the key,key or (if paging) the order.

  self.BuildSubsetCTE(cte)
  If Errorcode() then Return Driver:notok.

  self.BuildSubsetWhere(where,self._GetAlias(driver:withdot))

  ! next append any prop:filter or prop:sqlFilter
  self.BuildWhere()                                                              ! this populates *self.where* from self.filter and self.sqlfilter and self.searchfilter
  If Errorcode() then Return Driver:notok.

  If not self.Where &= Null and self.Where <> ''                                 ! self.filter and self.sqlfilter
    If where.Length()                                                            ! order fields constructed above
      where.SetValue('(' & where.GetValue() & ') AND (' & self.Where & ')')      ! AND the two parts together.
    Else
      where.SetValue(self.Where)                                                 ! or just move the filter into where
    End                                                                          ! which is then used below.
  End

  If self.Offset
    offset = self.Offset
  ElsIf self._SetOffset
    offset = self._SetOffset
  End

  self.SqlCode.SetValue(  Choose(self._explain  = true,' ' & self.ExplainStart(),'') &|
                        CHOOSE(cte.length() > 0 ,cte.GetValue(),'') &|
                        'SELECT ' &|
                        | !self.TranslateLimitAbove(self.Limit,Offset) & ' ' & |
                        CHOOSE(self.distinct = true,'DISTINCT ','') &|
                        self.ProjectList.GetValue())

  self.SqlCode.Append( |
                        ' FROM ' & self._sanitize(self.FullPathName,driver:sqlTable) & ' ' & self._GetAlias(driver:nodot) & |
                        Choose(self._SearchJoin <> '', self._SearchJoin , '') & |
                        Choose(where.Length() > 0,' WHERE ' & where.GetValue(),'') & |
                        Choose(not self.GroupBy &= null and not self.GroupBy = '', ' GROUP BY ' & self.GroupBy, '') &|
                        Choose(not self.Having &= null and not self.Having = '', ' HAVING ' & self.Having, '') &|
                        Choose(self.OrderBy <> '', ' ORDER BY ' & self.OrderBy,'') ) !& |
                        !self.TranslateLimitBelow(self.Limit,Offset))
                        ! not the end yet, more below...

  If self.Limit <> 0
    ! If prop:limit is set then whole result set is loaded. No paging here.
    If self.Offset
      self.SqlCode.Append(self.TranslateLimitBelow(self.Limit,self.Offset))
    ElsIf self._SetOffset
      self.SqlCode.Append(self.TranslateLimitBelow(self.Limit,self._SetOffset))
    Else
      self.SqlCode.Append(self.TranslateLimitBelow(self.Limit,0))
    End

    ! If prop:limit is set then whole result set is loaded. No paging here.
    self._OffsetParmNumber = 0
  ElsIf self.Paging = false or self.distinct = true !or self.notdistinct > 0
    self._OffsetParmNumber = 0
  ElsIf self.fetchsize
    ! developer not setting boundaries, so using buffer page settings
    ! note that setOFFSET is only actually used for the initial SET, where the developer can set the Offset, (and by SKIP).
    ! It is not used for "paging". Paging is accomplished using a sophisticated WHERE clause on the ORDER BY fields.
    self._ParameterCount += 1
    self._OffsetParmNumber = self._ParameterCount
    self.SqlCode.Append(self.TranslateLimitBelow(self.fetchsize,self._genparm(self._ParameterCount)))
  Else
    self._ParameterCount += 1
    self._OffsetParmNumber = self._ParameterCount
    self.SqlCode.Append(self.TranslateLimitBelow(0,self._genparm(self._ParameterCount)))
  End
  self.SqlCode.Append(';' & Choose(self._explain = true,' ' & self.ExplainEnd(),'') )
  self.SetProp:Where(where.GetValue())
  Return driver:ok

!-----------------------------------------------------------------
DriverFileSQLClass.TranslateLimitAbove           PROCEDURE(Long pLimit, String pOffset)
  Code
  return ''

!-----------------------------------------------------------------
DriverFileSQLClass.TranslateLimitBelow           PROCEDURE(Long pLimit, String pOffset)
  Code
  If pLimit = 0 and (pOffset = '' or pOffset ='0')
    Return ''
  End
  If pLimit = 0 then pLimit = -1.
  If pOffset and pOffset <> '0'
    Return ' LIMIT ' & pLimit & ' OFFSET ' & clip(pOffset)
  Else
    Return ' LIMIT ' & pLimit
  End

!-----------------------------------------------------------------
DriverFileSQLClass.GET              PROCEDURE(KEY pKey)
  Code
  If Errorcode() = NoError
    self.SetPrimaryKeyPosition()
  else
    self.ClearPrimaryKeyPosition()
  End
  Parent.Get(pKey)
  Return

!-----------------------------------------------------------------
! While this method is usually marked as "not supported", calling GET(File,0) has a special meaning.
DriverFileSQLClass.GET              PROCEDURE(BIGINT pFilePointer)
  Code
  If pFilePointer <= 0
    Parent.Get(pFilePointer) ! Parent MUST be called after reading the record.
    self.ClearPrimaryKeyPosition()
    Self.SetError(NoError)
    Return
  End
  Self.SetError(NoDriverSupport)
  Parent.Get(pFilePointer) ! Parent MUST be called after reading the record.
  Return

!-----------------------------------------------------------------
DriverFileSQLClass.GET              PROCEDURE(BIGINT pFilePointer, LONG pLength)
  Code
  Self.SetError(NoDriverSupport)
  Parent.Get(pFilePointer,pLength) ! Parent MUST be called after reading the record.
  Return

!-----------------------------------------------------------------
DriverFileSQLClass.GET              PROCEDURE(KEY pKey, BIGINT pKeyPointer)
  Code
  Self.SetError(NoDriverSupport)
  Parent.Get(pKey,pKeyPointer) ! Parent MUST be called after reading the record.
  Return

!-----------------------------------------------------------------
!!! Derive
DriverFileSQLClass._ExecuteSelect   Procedure()
  Code

!-----------------------------------------------------------------
!!! Derive
DriverFileSQLClass._BindOffset      Procedure()
  Code

!-----------------------------------------------------------------
DriverFileSQLClass._ClearOrderFieldsInShadowBuffer  Procedure(Long pOpCode, Long pFromField)
x  long
  Code
  Loop x = pFromField to Records(self.OrderQueue)
    Get(self.OrderQueue,x)
    self._ClearOrderFieldInShadowBuffer(pOpCode,self.OrderQueue.Direction,self.Orderqueue.FieldIndex)
  End
  Return

!-----------------------------------------------------------------
! Clears a single field in the shadow buffer, either high or low.
DriverFileSQLClass._ClearOrderFieldInShadowBuffer  Procedure(Long pOpCode, Long pDirection, Long pIndex)
  Code
  Case pOpCode
  Of opcode:NEXT
    If pDirection = driver:Descending
      self._ClearField(pIndex ,driver:high, address(self.ShadowBuffer))  ! clear field high
    Else
      self._ClearField(pIndex ,driver:low, address(self.ShadowBuffer))  ! clear field low
    End
  Of Opcode:PREVIOUS
    If pDirection = driver:Descending
      self._ClearField(pIndex ,driver:low, address(self.ShadowBuffer))  ! clear field low
    Else
      self._ClearField(pIndex ,driver:high, address(self.ShadowBuffer))  ! clear field high
    End
  End
  Return

!-----------------------------------------------------------------
DriverFileSQLClass._ClearField  Procedure(Long pIndex, Byte pHighLow, Long pAddr)
sh   short
lg   long
srl  sreal
rl   real
bf4  bfloat4
bf8  bfloat8
dt   Date
tm   Time
decString  string(36)
  code
  If self._WithField(pIndex) = Driver:ok
    If not self.Fields.Interface &= null
      ! clear custom field here
    Else
      Case self.Fields.Type
      of ClaBYTE
      orof ClaUSHORT
      orof ClaULONG
      orof ClaUNSIGNED
        If pHighLow = driver:high
          Memset(pAddr + self.Fields.Offset,255,self.Fields.length)
        Else
          Memset(pAddr + self.Fields.Offset,0,self.Fields.length)
        End
      of ClaSHORT
        if pHighLow = driver:high then sh = 32767 else sh = -32768.
        memcpy(pAddr + self.Fields.Offset,address(sh),2)

      of ClaLONG
      orof ClaSIGNED
        if pHighLow = driver:high then lg = 2147483647 else lg = -2147483648.
        memcpy(pAddr + self.Fields.Offset,address(lg),4)

      of ClaSREAL
        If pHighLow = driver:high then clear(srl,1) else clear(srl,-1).
        memcpy(pAddr + self.Fields.Offset,address(srl),4)
      of ClaREAL
        If pHighLow = driver:high then clear(rl,1) else clear(rl,-1).
        memcpy(pAddr + self.Fields.Offset,address(rl),8)
      of ClaBFLOAT4
        If pHighLow = driver:high then clear(bf4,1) else clear(bf4,-1).
        memcpy(pAddr + self.Fields.Offset,address(bf4),4)
      of ClaBFLOAT8
        If pHighLow = driver:high then clear(bf8,1) else clear(bf8,-1).
        memcpy(pAddr + self.Fields.Offset,address(bf8),8)
      of ClaDATE
        If pHighLow = driver:high then  clear(dt,1) else clear(dt,-1).
        memcpy(pAddr + self.Fields.Offset,address(dt),4)
      of ClaTIME
        If pHighLow = driver:high then clear(tm,1) else clear(tm,-1).
        memcpy(pAddr + self.Fields.Offset,address(tm),4)
      of ClaDECIMAL
      orof ClaPDECIMAL
        decstring = all(9,self.Fields.DecimalSize-self.Fields.DecimalPlaces ) & '.' & all(9,self.Fields.DecimalPlaces )
        If pHighLow = driver:low
          decstring = '-' & decstring
        End
        self._StringToDec(decString,self.Fields.Type,address(decstring),self.Fields.DecimalSize,self.Fields.DecimalPlaces)
        memcpy(pAddr + self.Fields.Offset,address(Decstring),self.Fields.Size)
      of ClaSTRING
        If pHighLow = driver:high
          memset(pAddr + self.Fields.Offset,255,self.Fields.Length)
        Else
          memset(pAddr + self.Fields.Offset,0,self.Fields.Length)
        End
      of ClaCSTRING
        If pHighLow = driver:high
          memset(pAddr + self.Fields.Offset,255,self.Fields.Length-1)
          memset(pAddr + self.Fields.Offset + self.Fields.Length-1,0,1)
        Else
          memset(pAddr + self.Fields.Offset,0,self.Fields.Length)
        End
      of ClaPSTRING
        If pHighLow = driver:high
          memset(pAddr + self.Fields.Offset,255,self.Fields.Length)
          memset(pAddr + self.Fields.Offset,self.Fields.Length,1)
        Else
          memset(pAddr + self.Fields.Offset,0,self.Fields.Length)
        End
      End
    End
  End
  Return

!-----------------------------------------------------------------
!DriverFileClass.CloneCStringPtr   Procedure(Long ppSource,Long ppDest)
!cstr  &cstring!,over(ppDest)
!  Code
!  If ppSource <> 0
!    cstr &= new Cstring(size(pSource))
!    cstr = pSource
!  End

!-----------------------------------------------------------------
DriverFileSQLClass.GETSTATE               Procedure(Long pSaveBlob)
len  Long,Auto
i    Long,Auto
e    Long,Auto
  Code
  !self.trace('DriverFileSQLClass.GETSTATE start ' & errorcode())
  e = errorcode()

  ! object memory
  i = parent.GetState(pSaveBlob)
  len = address(self.__SQLSTATEEND) - address(self.__SQLSTATESTART)
  Dispose(self.State.Level3)
  self.State.Level3 &= new String(len)
  MemCpy(address(self.State.Level3),address(self.__SQLSTATESTART),len)

  ! object pointers
  If not self.ProjectList &= null
    self.State.ProjectList &= new StringTheory
    self.State.ProjectList.SetValue(self.ProjectList)
  End
  If not self.SqlCode &= null
    self.State.SqlCode &= new StringTheory
    self.State.SqlCode.SetValue(self.SqlCode)
  End

  If Not self.Filter &= null
    self.State.Filter &=  new Cstring(size(self.Filter))
    self.State.Filter = self.Filter
  End
  If not self.SQLFilter &= null
    self.State.SQLFilter &=  new Cstring(size(self.SQLFilter))
    self.State.SQLFilter = self.SQLFilter
  End
  If not self.Where &= null
    self.State.Where &=  new Cstring(size(self.Where))
    self.State.Where = self.Where
  End
  If not self.WherePage &= null
    self.State.WherePage &= new Cstring(size(self.WherePage))
    self.State.WherePage = self.WherePage
  End
  If not self.Order &= null
    self.State.Order &= new Cstring(size(self.Order))
    self.State.Order = self.Order
  End
  If not self.SQLOrder &= null
    self.State.SQLOrder &= new Cstring(size(self.SQLOrder))
    self.State.SQLOrder = self.SQLOrder
  End
  If not self.OrderBy &= null
    self.State.OrderBy &= new Cstring(size(self.OrderBy))
    self.State.OrderBy = self.OrderBy
  End
  If not self.GroupBy &= null
    self.State.GroupBy &= new Cstring(size(self.GroupBy))
    self.State.GroupBy = self.GroupBy
  End
  If not self.Having &= null
    self.State.Having &= new Cstring(size(self.Having))
    self.State.Having = self.Having
  End
  If not self.Search &= null
    self.State.Search &=  new Cstring(size(self.Search))
    self.State.Search = self.Search
  End

  self.Result.GetState(self.state.id)

  Put(self.State)
  self.SetError(e)      ! GetState should not alter errorcode.
  !self.trace('DriverFileSQLClass.GETSTATE end ' & errorcode())
  Return i

!-----------------------------------------------------------------
DriverFileSQLClass.RESTORESTATE           Procedure(Long pState, Byte pBuffer)
len  long
  Code
  Parent.RestoreState(pState,pBuffer)
  If self.state.id = 0 then return.

  len = address(self.__SQLSTATEEND) - address(self.__SQLSTATESTART)
  MemCpy(address(self.__SQLSTATESTART),address(self.State.Level3),len)

  ! object pointers
  If self.State.ProjectList &= null
    self.ProjectList.SetValue('')
  Else
    self.ProjectList.SetValue(self.State.ProjectList)
  End
  If self.State.SqlCode &= null
    self.SqlCode.SetValue('')
  Else
    self.SqlCode.SetValue(self.SqlCode)
  End

  If not (self.Filter &= Null and self.state.filter &= NULL) or (self.Filter = self.State.Filter)
    Dispose(self.Filter)
    If not self.State.Filter &= null
      self.Filter &= new Cstring(size(self.state.Filter))
      self.Filter = self.State.Filter
    End
  End

  If not (self.SQLFilter &= Null and self.state.SQLFilter &= NULL) or (self.SQLFilter = self.State.SQLFilter)
    Dispose(self.SQLFilter)
    If not self.State.SQLFilter &= null
      self.SQLFilter &= new Cstring(size(self.state.SQLFilter))
      self.SQLFilter = self.State.SQLFilter
    End
  End

  If not (self.Where &= Null and self.state.Where &= NULL) or (self.Where = self.State.Where)
    Dispose(self.Where)
    If not self.State.Where &= null
      self.Where &= new Cstring(size(self.state.Where))
      self.Where = self.State.Where
    End
  End

  If not (self.WherePage &= Null and self.state.WherePage &= NULL) or (self.WherePage = self.State.WherePage)
    Dispose(self.WherePage)
    If not self.State.WherePage &= null
      self.WherePage &= new Cstring(size(self.state.WherePage))
      self.WherePage = self.State.WherePage
    End
  End

  If not (self.Order &= Null and self.state.Order &= NULL) or (self.Order = self.State.Order)
    Dispose(self.Order)
    If not self.State.Order &= null
      self.Order &= new Cstring(size(self.state.Order))
      self.Order = self.State.Order
    End
  End

  If not (self.SQLOrder &= Null and self.state.SQLOrder &= NULL) or (self.SQLOrder = self.State.SQLOrder)
    Dispose(self.SQLOrder)
    If not self.State.SQLOrder &= null
      self.SQLOrder &= new Cstring(size(self.state.SQLOrder))
      self.SQLOrder = self.State.SQLOrder
    End
  End

  If not (self.OrderBy &= Null and self.state.SQLOrder &= NULL) or (self.OrderBy = self.State.OrderBy)
    Dispose(self.OrderBy)
    If not self.State.OrderBy &= null
      self.OrderBy &= new Cstring(size(self.state.OrderBy))
      self.OrderBy = self.State.OrderBy
    End
  End

  If not (self.GroupBy &= Null and self.state.GroupBy &= NULL) or (self.GroupBy = self.State.GroupBy)
    Dispose(self.GroupBy)
    If not self.State.GroupBy &= null
      self.GroupBy &= new Cstring(size(self.state.GroupBy))
      self.GroupBy = self.State.GroupBy
    End
  End

  If not (self.Having &= Null and self.state.Having &= NULL) or (self.Having = self.State.Having)
    Dispose(self.Having)
    If not self.State.Having &= null
      self.Having &= new Cstring(size(self.state.Having))
      self.Having = self.State.Having
    End
  End

  If not (self.Search &= Null and self.state.Search &= NULL) or (self.Search = self.State.Search)
    Dispose(self.Search)
    If not self.State.Search &= null
      self.Search &= new Cstring(size(self.state.Search))
      self.Search = self.State.Search
    End
  End

  self.Result.RestoreState(self.state.id)

  ! do this last ! repeat in any derived methods
  Self.SetError(self.state.Errorcode)
  Self.SetFileError(self.state.FileErrorCode,self.state.FileError)

  Return

!-----------------------------------------------------------------
DriverFileSQLClass.MERGE             PROCEDURE(FILE pDestination, LONG pOptions)
obj   &DriverFileSQLClass
  Code
  !self.trace('DriverFileSQLClass.MERGE')
  If self._CheckOpen() = 0
    self.ClearProps()
    Return
  End
  ! determine if the destination database is the same driver, and same server.
  obj &= pDestination{prop:object}
  If obj &= null
    self.SetError(FileSystemErr)
    self.SetFileError(NoDriverSupport,'Failure to Merge. Destination Driver is not an Object Based Driver')
    self.ClearProps()
    Return
  End
  If self.GetPROP:Driver() = obj.GetProp:Driver() and lower(self.GetProp:Server()) = lower(obj.GetProp:server())
    If obj.Exists('') = False
      obj._CreateTable()   ! bypass the open checks
    End
    self.MergeFast(pDestination,pOptions)
  Else
    self.MergeSlow(pDestination,pOptions)
  End
  self.ClearProps()
  Return

!-----------------------------------------------------------------
DriverFileSQLClass.MERGE             PROCEDURE(String pDestination, LONG pOptions)
SavedFileName  like(self.FullPathName)
  Code
  If self._CheckOpen() = 0
    self.ClearProps()
    Return
  End
  If self.Exists(pDestination) = False
    SavedFileName = self.FullPathName
    self.FullPathName = clip(pDestination)
    self._CreateTable()   ! bypass the open checks
    self.FullPathName = SavedFileName
  End
  self.MergeFast(pDestination,pOptions)
  self.ClearProps()
  Return

!-----------------------------------------------------------------
!!!DERIVE
DriverFileSQLClass.MERGEFast         PROCEDURE(FILE pDestination, LONG pOptions)
  Code

!-----------------------------------------------------------------
!!!DERIVE
DriverFileSQLClass.MERGEFast         PROCEDURE(String pDestination, LONG pOptions)
  Code

!-----------------------------------------------------------------
!!!DERIVE
DriverFileSQLClass.MERGESlow         PROCEDURE(FILE pDestination, LONG pOptions)
  Code

!-----------------------------------------------------------------
DriverFileSQLClass.NEXT         PROCEDURE()
  Code
  If self._JustSetSearch
    Clear(self.SearchRank,-1)
    self._JustSetSearch = false
  End
  self._NextPrevious(Opcode:NEXT)
  Parent.Next()
  Return

!-----------------------------------------------------------------
! Previous is still walking through the result set "forwards", it just has a different sort order.
! changing direction inside the current result set is cheap.
DriverFileSQLClass._NextPrevious             Procedure(Long pOpcode)
rows    long,Auto
dbg     stringtheory
  Code
  !self.trace('DriverFileSQLClass._NextPrevious self._justset=' & self._justset & ' self.ResultRow=' & self.ResultRow & ' self._ResultSetDirection=' & self._ResultSetDirection & ' pOpcode=' & pOpcode & ' self.fetchsize=' & self.fetchsize & ' errorcode=' & errorcode())
  Loop 2 times
    ! first check results to see if a row is waiting there.
    If self._justset = false
      rows = self.Result.Rows()
      If self._ResultSetDirection = Opcode:Next and pOpcode = Opcode:Next or |
        self._ResultSetDirection = Opcode:Previous and pOpcode = Opcode:Previous
        ! fetched the records, now looping through them. very straight-forward, just get the next one from the set.
        If self.ResultRow < rows
          self.ResultRow += 1
          self.ResultToRecord(self.ResultRow,self.ClaFCB.rec_buf, Choose(self._nomemoset=true,Driver:NoBlobs,Driver:Blobs))
          Break
        Elsif rows And (self.Limit or self._limit or self.Paging = false)
          ! limit is set, so whole result is here, so trigger an end-of-file
          Self.SetError(BadRecErr)
          Break
        ElsIf rows and rows < self.fetchsize
          ! page is not full, so whole result is here, so trigger an end-of-file
          Self.SetError(BadRecErr)
          Break
        End
      Else
        ! the opcode doesn't match the set direction. First see if there's a simple row behind the current pointer
        If self.ResultRow > 1
          self.ResultRow -= 1
          self.ResultToRecord(self.ResultRow,self.ClaFCB.rec_buf, Choose(self._nomemoset=true,Driver:NoBlobs,Driver:Blobs))
          Break
        Elsif rows And self.Paging = false
          ! whole result is here, so trigger an end-of-file
          Self.SetError(BadRecErr)
          Break
        End
      End
      ! ok, so the row we want is not in the current result set.
      ! If the direction does not = the request direction, then the SET needs to be reversed.
      If rows
        If self._ResultSetDirection = Opcode:Next and pOpcode = Opcode:Previous      ! want whatever's "before" row number 1
          ! reset the shadow buffer to record #1 in the result set, and then
          self.ResultToRecord(1,address(self.shadowbuffer),Driver:NoBlobs) ! no need to populate the blobs, this is for an OrderBy clause
          ! build a new SELECT statement based on OpCode:Previous
        ElsIf self._ResultSetDirection = Opcode:Previous and pOpcode = Opcode:Next   ! want whatever's "before" row number 1
          ! reset the shadow buffer to record #1 in the result set, and then
          self.ResultToRecord(1,address(self.shadowbuffer),Driver:NoBlobs) ! no need to populate the blobs, this is for an OrderBy clause
          ! build a new SELECT statement based on OpCode:Next
          self._GenerateSelect(pOpcode)
        Else
        ! we just need the next page, so leave the SELECT alone, prime the shadow buffer to the last row, and get the next set
          self.ResultToRecord(rows,address(self.shadowbuffer),Driver:NoBlobs) ! no need to populate the blobs, this is for an OrderBy clause
        End
      End
    ElsIf self._justset = true ! first time in. Might need to clear the shadow buffer high or low
      ! -- put it all together
      self._GenerateSelect(pOpcode)
      If Errorcode() <> NoError then Return.

      Case Self.SetMethod
      Of driver:SetFilePos
      Orof driver:SetKeyPos
      Of driver:SetKeyKey
        ! all the supplemental fields in the order need to be cleared appropriately
        If self._SupplementalOrderFields
          self._ClearOrderFieldsInShadowBuffer(pOpcode,self._SupplementalOrderFields)
        End
      Else
        self._ClearOrderFieldsInShadowBuffer(pOpcode,1)
      End
      self._justset = false
    End
    self._ExecuteSelect()
    ! if there are results loop back
    If self.Result.Rows()
      self.ResultRow = 0
      cycle
    End
    ! if not trigger an end-of-file
    If Errorcode() = 0
      Self.SetError(BadRecErr)
    End
    Break
  End
  If Errorcode() = NoError
    self.SetPrimaryKeyPosition()
  Else
    self.ClearPrimaryKeyPosition()
  End
  !self.trace('NextPrevious done ' & errorcode())
  Return

!-----------------------------------------------------------------
DriverFileSQLClass.PREVIOUS         PROCEDURE()
  Code
  If self._JustSetSearch
    clear(self.SearchRank,1)
    self._JustSetSearch = false
  End
  self._NextPrevious(Opcode:PREVIOUS)
  Parent.Previous()
  Return

!-----------------------------------------------------------------
DriverFileSQLClass.POSITION                  PROCEDURE()
  code
  Return Self.Position(self.primarykey)

!-----------------------------------------------------------------
! The SQL for a UPDATE is pretty standard. However this method may need to be derived in a specific driver
! if the SQL syntax is different. MSSql for example does not use RETURNING to return values, but OUTPUT
DriverFileSQLClass._PutSql Procedure()
x              Long
stmt           Long
Offset         Long
FieldsList     StringTheory
where          StringTheory
returning      StringTheory
  Code
  self.BuildProjectList()                     ! ProjectClauses are not included here

  self._ClearParameterQueue(self._ParameterOpcode)

  Loop x = 1 to self.SharedProperties.FieldList.nodes
    self.Fields &= self._withFieldNode(x)
    If self.Fields.Over or self.Fields.InOverGroup or self.Fields.Type = ClaGroup then Cycle.

    ! readonly fields are reset by a PUT. They are not written to.
    If (self.Fields.ReadOnly or self.Fields.IsIdentity) and self._fastwrite = false
      returning.Append(self.Fields.Column,st:noclip,',')
      Cycle
    End

    ! if the field was not read, then don't PUT it.
    If self._ProjectField[x] = false then Cycle.    ! importantly, 255, not 1, if included.

    ! if the field hasn't changed, don't PUT it
    If _MemCmp(self.ClaFCB.rec_buf+self.fields.Offset,address(self.WatchBuffer)+self.fields.offset,self.fields.Length) = 0
      Cycle
    End
    self._ParameterCount += 1
    self._SetParameterNode(self._ParameterCount,self.fields,driver:FromBuffer,0)
    FieldsList.append(self.Fields.Column & ' = ' & self._genparm(self._ParameterCount),st:NoClip,',')
  End
  If self._nomemo = false
    Loop x = 1 to Records(self.blobs)
      Get(self.blobs,x)
      If self.blobs.ReadOnly then cycle.
      If self._ProjectBlobField[x] = false then Cycle.    ! importantly, 255, not 1, if included.
      If self.CheckBlobCrc() = true then cycle.
      self._ParameterCount += 1
      self._SetParameterBlob(self._ParameterCount,self.blobs.index)
      FieldsList.append(self.blobs.Column & ' = ' & self._genparm(self._ParameterCount),st:NoClip,',')
    End
  End
  If self._nomemo = false
    self._PutCols = self._ParameterCount
  Else
    self._PutNoMemoCols = self._ParameterCount
  End
  If self._WithPrimaryKey() = Driver:ok
    where.SetValue('')
    Loop x = 1 to self.keys.components
      If self._WithField(self.keys.component[x]) = Driver:ok
        self._ParameterCount += 1
        self._SetParameterNode(self._ParameterCount,self.fields,driver:FromPrimaryKeyPosition, offset)
        offset += self.Fields.Length
        where.append(self.Fields.Column & '= ' & self._genparm(self._ParameterCount) ,st:NoClip,' AND ')
      End
    End
    If FieldsList.Length() = 0
      If returning.length() = 0
        self.SqlCode.SetValue('')
      Else
        !self.SqlCode.SetValue('')
        ! Readonly fields are restored with a PUT. Since there's nothing to write, but the RETURNING fields have been altered, these need to be reset.
        self.SqlCode.SetValue('SELECT ' & returning.GetValue() & ' FROM ' & self._sanitize(self.FullPathName,driver:sqlTable) & ' WHERE ' & where.GetValue() )
      End
    Else
      self.SqlCode.SetValue('UPDATE ' & self._sanitize(self.FullPathName,driver:sqlTable) & ' SET ' & FieldsList.GetValue() & ' WHERE ' & where.GetValue() )
      If returning.length()
        self.SqlCode.append(' RETURNING ' & returning.GetValue())
      End
    End
    If self.SqlCode.Length()
      self.SqlCode.append(';')
    End
    Return driver:ok
  End
  Return Driver:notok

!-----------------------------------------------------------------
! Put with FilePointer is not supported in SQL
DriverFileSQLClass.PUT              PROCEDURE(BIGINT pFilePointer)
  Code
  Parent.Put(pFilePointer) ! Parent MUST be called before writing the record. Abort if Errorcode set.
  If Errorcode() then Return.
  Self.SetError(NoDriverSupport)
  Return

!-----------------------------------------------------------------
! Put with FilePointer is not supported in SQL
DriverFileSQLClass.PUT              PROCEDURE(BIGINT pFilePointer, LONG pLength)
  Code
  Parent.Put(pFilePointer,pLength) ! Parent MUST be called before writing the record. Abort if Errorcode set.
  If Errorcode() then return.
  Self.SetError(NoDriverSupport)
  Return

!-----------------------------------------------------------------
! The SQL for a GETRANDOM is pretty standard. However this method may need to be derived in a specific driver
! if the SQL syntax is different.
DriverFileSQLClass._RandomSQL  Procedure(String pFilter, BIGINT pOffset)
x           Long,Auto
stmt        Long
FieldsList  StringTheory
Filter      StringTheory
Order       StringTheory
  Code
  self._ClearParameterQueue(self._ParameterOpcode)
  self.BuildProjectList()
  self.BuildProjectListAppendClauses()

  If self._WithPrimaryKey() = Driver:ok
    Loop x = 1 to self.keys.components
      If self._WithField(self.keys.component[x]) = Driver:ok
        order.Append(self._GetAlias(driver:withdot) & self.Fields.Column ,st:NoClip,', ')
      End
    End
  End

  self.SqlCode.SetValue('SELECT ' & self.ProjectList.GetValue() & ' FROM ' & self._sanitize(self.FullPathName,driver:sqlTable) & ' ' & self._GetAlias(driver:nodot))
  If pFilter
    If self.ParseProperty(pFilter,driver:filter,self.TokenStr) = driver:notok
      self.SetError(BadFilterErr)
      Return driver:notok
    End
    filter.SetValue(self._ExpandExpression(self.TokenStr.GetValue()))
    self.SqlCode.Append(' WHERE ' & filter.GetValue())
  End
  self.SqlCode.Append(' ORDER BY ' & order.GetValue())
  self.SqlCode.Append(self.TranslateLimitBelow(1,pOffset))
  Return driver:ok

!-----------------------------------------------------------------
DriverFileSQLClass.GETRANDOM         PROCEDURE(String pFilter)
  Code
  If Errorcode() = NoError
    self.SetPrimaryKeyPosition()
  else
    self.ClearPrimaryKeyPosition()
  End
  Parent.GetRandom(pFilter)
  Return

!-----------------------------------------------------------------
DriverFileSQLClass.RECORDSFILTER     PROCEDURE(String pFilter)
filter   StringTheory
  Code
  self._ParameterOpcode = Opcode:RECORDS
  self._ClearParameterQueue(self._ParameterOpcode)
  If self.CheckConnect() = Driver:notok then Return 0.      ! File can be OPEN. If closed a new connection may be established.
  Self.SetError(NoError)
  self.SqlCode.setvalue('SELECT COUNT(1) FROM ' & self._sanitize(self.FullPathName,driver:sqlTable))
  If pFilter
    self.SqlCode.Append(' ' & self._GetAlias(driver:nodot))
    If self.ParseProperty(pFilter,driver:filter,self.TokenStr) = driver:notok
      self.SetError(BadFilterErr)
      Return 0
    End
    filter.SetValue(self._ExpandExpression(self.TokenStr.GetValue()))
    self.SqlCode.Append(' WHERE ' & filter.GetValue())
  End
  self.SqlCode.Append(';')
  If self._executeSql() = driver:ok
    Return self.Result.GetCell(1,1)
  End
  Return 0

!-----------------------------------------------------------------
DriverFileSQLClass.RECORDS          PROCEDURE(*? pField1, <*? pField2>, <*? pField3>, <*? pField4>, <*? pField5>,<*? pField6>, <*? pField7>, <*? pField8>, <*? pField9>, <*? pField10>,<*? pField11>, <*? pField12>, <*? pField13>, <*? pField14>, <*? pField15>)
filter   StringTheory
ptr      Long
offset   Long
  code
  !If self._CheckOpen() = false then Return 0.
  If self._opened = 0 then self._UpdateFileStrings().
  Self.SetError(NoError)
  Peek(address(pfield1)+4,ptr)
  do AppendField
  If not omitted(pField2)
    Peek(address(pfield2)+4,ptr)
    do AppendField
  End
  If not omitted(pField3)
    Peek(address(pfield3)+4,ptr)
    do AppendField
  End
  If not omitted(pField4)
    Peek(address(pfield4)+4,ptr)
    do AppendField
  End
  If not omitted(pField5)
    Peek(address(pfield5)+4,ptr)
    do AppendField
  End
  If not omitted(pField6)
    Peek(address(pfield6)+4,ptr)
    do AppendField
  End
  If not omitted(pField7)
    Peek(address(pfield7)+4,ptr)
    do AppendField
  End
  If not omitted(pField8)
    Peek(address(pfield8)+4,ptr)
    do AppendField
  End
  If not omitted(pField9)
    Peek(address(pfield9)+4,ptr)
    do AppendField
  End
  If not omitted(pField10)
    Peek(address(pfield10)+4,ptr)
    do AppendField
  End
  If not omitted(pField11)
    Peek(address(pfield11)+4,ptr)
    do AppendField
  End
  If not omitted(pField12)
    Peek(address(pfield12)+4,ptr)
    do AppendField
  End
  If not omitted(pField13)
    Peek(address(pfield13)+4,ptr)
    do AppendField
  End
  If not omitted(pField14)
    Peek(address(pfield14)+4,ptr)
    do AppendField
  End
  If not omitted(pField15)
    Peek(address(pfield15)+4,ptr)
    do AppendField
  End

  self.SqlCode.setvalue('SELECT COUNT(1) FROM ' & self._sanitize(self.FullPathName,driver:sqlTable)  & ' ' & self._GetAlias(driver:nodot))
  If Filter.length()
    self.SqlCode.Append(' WHERE ' & filter.GetValue())
  End
  self.SqlCode.Append(';')
  If self._executeSql() = Driver:ok
    Return self.Result.GetCell(1,1)
  end
  Return 0

AppendField  routine
  If ptr >= self.ClaFCB.rec_buf and ptr <= self.ClaFCB.rec_buf + self.ClaFCB.rec_len
    offset = ptr - self.ClaFCB.rec_buf
    If self._WithFieldOffset(offset,0) = driver:ok
      self._ParameterCount += 1
      self._SetParameterNode(self._ParameterCount,self.fields,driver:FromBuffer,0)
      filter.append(self.fields.Column & '= ' & self._genparm(self._ParameterCount),,' AND ')
    End
  else
    self.trace('Bad Field Error')
    self.SetError(BadFieldErr)
  End

!-----------------------------------------------------------------
DriverFileSQLClass.RECORDS          PROCEDURE()
  Code
  Return self.RecordsFilter('')

!-----------------------------------------------------------------
! since the driver does not support "exclude" keys, the key value is the same as the table value.
!!!todo  Records(key) should count the records in the key, but exclude items where the keyvalues are null.
DriverFileSQLClass.RECORDS          PROCEDURE(KEY keyLabel)
  Code
  Return self.Records()

!-----------------------------------------------------------------
DriverFileSQLClass.REMOVE           PROCEDURE()
  Code
  self._ParameterOpcode = 0
  If self._CheckClosed() = false then Return.                   ! FILE must be CLOSED to REMOVE
  If self.CheckConnect() = Driver:notok then Return.
  Self.SetError(NoError)
  self.SqlCode.SetValue('DROP TABLE ' & self._sanitize(self.FullPathName,driver:sqlTable) & ';')
  If self._ExecuteSql() = driver:ok
  End
  Return

!-----------------------------------------------------------------
DriverFileSQLClass._SET             PROCEDURE(Byte pSetMethod, BigInt pPointer,Key pSetKey, Key pSetKeyKey)
  code
  self._ParameterOpcode = Opcode:SET
  self._ClearParameterQueue(self._ParameterOpcode)
  self._FreeSubset()
  If not self._ProjectClauses &= null
    self._ProjectClauses.SetValue('')
  End
  self._SearchJoin = ''
  self.SearchFilter = ''
  self._SearchOrderClause = ''
  self._SearchParameter = 0
  self.SetProp:Where('')

  FileSETObject &= self  ! FileSetObject is a module level, threaded parameter. It notes the most recent object to do a SET. This is used by EXCEPT, UNION and INTERSECT
  ViewSETObject &= null  ! ViewSetObject is a module level, threaded parameter. It notes the most recent object to do a SET. This is used by EXCEPT, UNION and INTERSECT
  parent._Set(pSetMethod,pPointer,pSetKey,pSetKeyKey)
  self._nomemoset = self.NoMemoArmed
  self._nomemo    = self.NoMemoArmed
  self._paging = Self.Paging
  self._limit = Self.Limit

  self.NewResultSet(driver:DontFreeRam)
  memCpy(address(self.ShadowBuffer),self.ClaFCB.rec_buf,self.ClaFCB.rec_len)
  Return

!-----------------------------------------------------------------
DriverFileSQLClass.SKIP                       PROCEDURE(BIGINT pCount)
rows      Long
rowsleft  Long
  code
  parent.Skip(pCount)
  If Errorcode() then Return.
  rows = self.Result.Rows()   ! number of rows in the current result set.
  if rows
    rowsleft = rows - self.ResultRow
    if pCount <= rowsleft
      self.ResultRow += pCount
      return
    end
    self.resultrow = rows
    pCount -= rowsleft
  end
  self._SetOffset += pCount
  Return

!-----------------------------------------------------------------
! parameterized SQL call, designed to be a safer prop:sql
DriverFileSQLClass.SQL            PROCEDURE(String pSql,<? pParm1>,<? pParm2>,<? pParm3>,<? pParm4>,<? pParm5>,<? pParm6>,<? pParm7>,<? pParm8>,<? pParm9>,<? pParm10>,<? pParm11>,<? pParm12>,<? pParm13>,<? pParm14>,<? pParm15>,<? pParm16>,<? pParm17>,<? pParm18>,<? pParm19>,<? pParm20>)
stmt  Long
  Code
  Self.SetError(NoError)
  If self.CheckConnect() = driver:notok then return.
  If pSql = ''
    Self.SetError(FileSystemErr)
    self.SetFileError(SQLErr,'Sql Statement Empty')
    Return
  End
  self.SqlCode.SetValue(clip(pSql))
  If self._executeSql(self.SqlCode,pParm1,pParm2,pParm3,pParm4,pParm5,pParm6,pParm7,pParm8,pParm9,pParm10,pParm11,pParm12,pParm13,pParm14,pParm15,pParm16,pParm17,pParm18,pParm19,pParm20) = Driver:ok
  End
  self._justSet = false
  self.Paging = false
  self._ResultSetDirection = Opcode:NEXT
  self._HasBeenPropSql = true
  Return

!-----------------------------------------------------------------
DriverFileSQLClass._UpdateSql         PROCEDURE(String pFilter,*? pField1,String pValue1,<*? pField2>,<String pValue2>,<*? pField3>,<String pValue3>,<*? pField4>,<String pValue4>,<*? pField5>,<String pValue5>,<*? pField6>,<String pValue6>,<*? pField7>,<String pValue7>,<*? pField8>,<String pValue8>,<*? pField9>,<String pValue9>,<*? pField10>,<String pValue10>)
str      StringTheory
count    long
fldnum   long
ptr      long
offset   long
  Code
  self.SqlCode.SetValue('UPDATE ' & self._sanitize(self.FullPathName,driver:sqlTable) & ' SET ')
  do Fields
  If pFilter
    self.SqlCode.Append(' WHERE ' & pFilter)
  End
  self.SqlCode.Append(';')
  Return

Fields  routine
  Peek(address(pfield1)+4,ptr)
  fldnum = 1
  str.SetValue(pValue1,st:clip)
  do AppendField
  If Errorcode() then return.

  If not omitted(pField2) and not omitted(pValue2)
    Peek(address(pfield2)+4,ptr)
    fldnum += 1
    str.SetValue(pValue2,st:clip)
    do AppendField
    If Errorcode() then return.
  End

  If not omitted(pField3) and not omitted(pValue3)
    Peek(address(pfield3)+4,ptr)
    fldnum += 1
    str.SetValue(pValue1,st:clip)
    do AppendField
    If Errorcode() then return.
  End
  If not omitted(pField4) and not omitted(pValue4)
    Peek(address(pfield4)+4,ptr)
    fldnum += 1
    str.SetValue(pValue1,st:clip)
    do AppendField
    If Errorcode() then return.
  End
  If not omitted(pField5) and not omitted(pValue5)
    Peek(address(pfield5)+4,ptr)
    fldnum += 1
    str.SetValue(pValue1,st:clip)
    do AppendField
    If Errorcode() then return.
  End
  If not omitted(pField6) and not omitted(pValue6)
    Peek(address(pfield6)+4,ptr)
    fldnum += 1
    str.SetValue(pValue1,st:clip)
    do AppendField
    If Errorcode() then return.
  End
  If not omitted(pField7) and not omitted(pValue7)
    Peek(address(pfield7)+4,ptr)
    fldnum += 1
    str.SetValue(pValue1,st:clip)
    do AppendField
    If Errorcode() then return.
  End
  If not omitted(pField8) and not omitted(pValue8)
    Peek(address(pfield8)+4,ptr)
    fldnum += 1
    str.SetValue(pValue1,st:clip)
    do AppendField
    If Errorcode() then return.
  End
  If not omitted(pField9) and not omitted(pValue9)
    Peek(address(pfield9)+4,ptr)
    fldnum += 1
    str.SetValue(pValue1,st:clip)
    do AppendField
    If Errorcode() then return.
  End
  If not omitted(pField10) and not omitted(pValue10)
    Peek(address(pfield10)+4,ptr)
    fldnum += 1
    str.SetValue(pValue1,st:clip)
    do AppendField
    If Errorcode() then return.
  End

AppendField  routine
  If ptr >= self.ClaFCB.rec_buf and ptr <= self.ClaFCB.rec_buf + self.ClaFCB.rec_len
    offset = ptr - self.ClaFCB.rec_buf
    If self._WithFieldOffset(offset,0) = driver:ok
      str.Prepend(self.fields.Column & ' = ')
      If self.ParseProperty(str.GetValue(),driver:expression,self.TokenStr) = driver:notok
        self.SetError(BadExpressionErr)
        Return
      End

      str.SetValue(self._ExpandExpression(self.TokenStr.GetValue()))
      If fldnum > 1 then self.SqlCode.Append(', ').
      !self._ParameterCount += 1
      !self._SetParameterString(self._ParameterCount,str.GetValue())
      !self.SqlCode.append(self.fields.Column & '= ' & self._genparm(self._ParameterCount))
      !self.SqlCode.append(self.fields.Column & ' = ' & str.GetValue())
      !str.trace('ax1 ' & str.getvalue())
      self.SqlCode.append(str)
    End
  else
    self.SetError(BadFieldErr)
  End

!-----------------------------------------------------------------
DriverFileSQLClass.UPDATE             PROCEDURE(String pFilter,*? pField1,String pValue1,<*? pField2>,<String pValue2>,<*? pField3>,<String pValue3>,<*? pField4>,<String pValue4>,<*? pField5>,<String pValue5>,<*? pField6>,<String pValue6>,<*? pField7>,<String pValue7>,<*? pField8>,<String pValue8>,<*? pField9>,<String pValue9>,<*? pField10>,<String pValue10>)
filter   StringTheory
NoAlias  Byte,Auto
  Code
  If self._CheckOpen() = false then Return.
  If pFilter = ''
    self.SetError(MissingFilterErr)
    Return
  End
  self._ParameterOpcode = Opcode:UPDATE
  self._ClearParameterQueue(self._ParameterOpcode)
  Self.SetError(NoError)
  NoAlias = self._NoAlias
  self._NoAlias = true
  if pFilter <> driver:all
    If self.ParseProperty(pFilter,driver:filter,self.TokenStr) = driver:notok
      self.SetError(BadFilterErr)
      Return
    End
    filter.SetValue(self._ExpandExpression(self.TokenStr.GetValue()))
  End
  Self._UpdateSql(filter.GetValue(),pField1,pValue1,pField2,pValue2,pField3,pValue3,pField4,pValue4,pField5,pValue5,pField6,pValue6,pField7,pValue7,pField8,pValue8,pField9,pValue9,pField10,pValue10)
  self._NoAlias = NoAlias
  If Errorcode() then return.
  If self._executeSql() = driver:ok
  End
  Return

!-----------------------------------------------------------------
DriverFileSQLClass.UPDATE             PROCEDURE(Key pKey,*? pField1,String pValue1,<*? pField2>,<String pValue2>,<*? pField3>,<String pValue3>,<*? pField4>,<String pValue4>,<*? pField5>,<String pValue5>,<*? pField6>,<String pValue6>,<*? pField7>,<String pValue7>,<*? pField8>,<String pValue8>,<*? pField9>,<String pValue9>,<*? pField10>,<String pValue10>)
x        Long,Auto
filter   StringTheory
NoAlias  Byte ,Auto
  Code
  If self._CheckOpen() = false then Return.
  self._ParameterOpcode = Opcode:UPDATE
  self._ClearParameterQueue(self._ParameterOpcode)
  Self.SetError(NoError)

  If self._WithKey(pKey) = driver:ok
    NoAlias = self._NoAlias
    self._NoAlias = true
    Loop x = 1 to self.keys.components
      If self._WithField(self.keys.component[x]) = Driver:ok
        self._ParameterCount += 1
        self._SetParameterNode(self._ParameterCount,self.fields,driver:FromBuffer,0)
        filter.Append(self.Fields.Column & '= ' & self._genparm(self._ParameterCount) ,st:NoClip,' AND ')
      End
    End
    Self._UpdateSql(filter.getvalue(),pField1,pValue1,pField2,pValue2,pField3,pValue3,pField4,pValue4,pField5,pValue5,pField6,pValue6,pField7,pValue7,pField8,pValue8,pField9,pValue9,pField10,pValue10)
    self._NoAlias = NoAlias
    If Errorcode() then return.
    !self.trace('es3')
    If self._executeSql() = driver:ok
    End
    !self.trace('es4 ' & errorcode())

  Else
    Self.SetError(InvKeyErr) !!!todo - not sure about this error code. Should never get here though.
  End
  Return

!-----------------------------------------------------------------
DriverFileSQLClass.SETPROPERTY               Procedure(String pProperty,Long pIndex,STRING pValue)
  Code
  !self.trace('DriverFileClass.SETPROPERTY (' & self.InterpretProperty(pProperty) & ',' & pIndex & ',' & pValue & ')')
  case pProperty
  of PROP:Connect
    Self.Connect(pValue)

  of PROP:CreateDB
    self.CreateDB('')

  of PROP:Disconnect
    ! this property has been explicitly removed for Object Based Drivers.

  of Prop:ResultGet
    self.ResultGet(pValue)

  else
    parent.SetProperty(pProperty,pIndex,pValue)
  end
  Return

!-----------------------------------------------------------------
DriverFileSQLClass.DOPROPERTY                Procedure(String pProperty,Long pIndex=0)
  Code
  !self.trace('DriverBaseClass.DOPROPERTY (' & pProperty & ' [' & self.InterpretProperty(pProperty) & '],' & pIndex & ')')
  Case pProperty
  of PROP:Connect
    Self.Connect()

  of PROP:CreateDB
    self.CreateDB('')

  of PROP:Disconnect
    ! this property has been explicitly removed for Object Based Drivers.

  of Prop:ResultNext
    self.ResultNext()

  of Prop:ResultPrevious
    self.ResultPrevious()

  of PROP:ServerAutoInc
  else
    parent.DoProperty(pProperty,pIndex)
  End
  Return

!-----------------------------------------------------------------
! assumes the connection string to be of the form server,database,uid,pwd
DriverFileSQLClass.GetProp:Database         Procedure()   ! get the server name out of the connection string
  code
  return self._connect[2]

!-----------------------------------------------------------------
! assumes the connection string to be of the form server,database,uid,pwd
DriverFileSQLClass.GetProp:Server         Procedure()   ! get the server name out of the connection string
  code
  return self._connect[1]

!-----------------------------------------------------------------
! assumes the connection string to be of the form server,database,uid,pwd
DriverFileSQLClass.GetProp:User         Procedure()   ! get the user name out of the connection string
  code
  return self._connect[3]

!-----------------------------------------------------------------
DriverFileSQLClass.GetProp:SQLDriver          PROCEDURE()!,STRING,VIRTUAL  ! '1' = Driver is SQL aware
  code
  Return '1'

!=============================================================================
!  DriverViewClass
!=============================================================================
!-----------------------------------------------------------------

DriverViewClass.Construct  Procedure()
  Code
  self.Tree &= new(ViewTreeType)
  self.ConditionQueue &= new(ConditionQueueType)
  self.ValueQueue &= new(ValueQueueType)
  self.LabelQueue &= new(LabelQueueType)
  self.FunctionQueue &= new(FunctionQueueType)
  self.ExpressionQueue &= new(ExpressionQueueType)
  self._structure = 'V'
  Return

!-----------------------------------------------------------------
DriverViewClass.Destruct  Procedure()
  Code
  self.Close()
  self._FreeTree(self.Tree)
  Dispose(self.Tree)
  Dispose(self.ConditionQueue)
  Dispose(self.ValueQueue)
  Dispose(self.LabelQueue)
  Dispose(self.FunctionQueue)
  Dispose(self.ExpressionQueue)
  Return

!-----------------------------------------------------------------
DriverViewClass.LOGGINGON                  Procedure(<String pFileName>,Long pOptions=0)
obj  &DriverFileClass,Auto
x    Long,Auto
  code
  parent.LoggingOn(pFileName,pOptions)
  Loop x = 1 to self.Files
    Obj &= (self.FileObject[x])
    If obj &= null then cycle.
    obj.LoggingOn(pFileName,pOptions)
  end
  Return

!-----------------------------------------------------------------
DriverViewClass.LOGGINGOFF                Procedure()
obj  &DriverFileClass,Auto
x    Long,Auto
  code
  Loop x = 1 to self.Files
    Obj &= (self.FileObject[x])
    If obj &= null then cycle.
    obj.LoggingOff()
  end
  Parent.LoggingOff()
  Return

!-----------------------------------------------------------------
DriverViewClass.ClearProps    Procedure()
  code
  parent.ClearProps()
  self.OrderAllTables  = False
  self.OrderInSelect   = False
  self.NoKeyProject    = False
  self._PropFilterCalled = False
  self._PropOrderCalled  = False
  self._PropSQLCalled = False
  self._ClearPropsWalker(self.tree)
  Return

!-----------------------------------------------------------------
DriverViewClass._ClearPropsWalker  Procedure(ViewTreeType pNode)
x  long
  Code
  loop x = 1 to records(pNode)
    Get(pNode,x)
    If pNode.children &= null then cycle.
    pNode.AutoProject = driver:projectfields
    Put(pNode)
    self._ClearPropsWalker(pNode.children)
  End
  Return

!-----------------------------------------------------------------
DriverViewClass._FreeTree  Procedure(ViewTreeType pNode)
x  long
  Code
  Loop x = 1 to Records(pNode)
    Get(pNode,x)
    If pNode.children &= null then cycle.
    self._FreeTree(pNode.children)
    Dispose(pNode.children)
    Dispose(pNode.LinkingExpr)
    Dispose(pNode.SQLJoinExpression)
  End
  Free(pNode)
  Return

!-----------------------------------------------------------------
DriverViewClass.Init                     Procedure(VIEW pView, Long pForce=false)
lView   Long
  Code
! Point VIEW and object at one another
  If self._Inited = true and pForce = false then return.
  self.view &= pView
  lView = address(pView)
  self.ClaVCB  &= (lView)
  If self.ClaVCB.rblock = 0             ! this is the first object assigned to this view
    self.ClaVCB.rblock = address(self)
  else
    !Self.ReplaceObject(self.ClaVCB.rblock)  ! this is replacing the object assigned to the file
  End
  self._BuildTree()
  Return

!-----------------------------------------------------------------
DriverViewClass.Pipe          Procedure(Long pOpCode, Long pClaVCB, long pVarList)
lparm1  long
lparm2  long
  code
  !self.trace('DriverViewClass Pipe: [' & pOpCode & '] ' & self.InterpretOpCode(pOpcode) & ' pClaVCB=' & pClaVCB & ' pVarList = ' & pVarList & ' self._logClarion=' & self._logClarion)
  Case pOpCode

  ! ordered for frequency / performance
  of Opcode:NEXT                                                   ! reports are very heavy on NEXT
    If self._logClarion then self.Log('[CLAR]NEXT(view)').
    self.Next()

  of Opcode:GET_PROPERTY                                           ! browses use GET Property, POSITION and RESET a lot
    lparm1 = self._GetParmAsLong(pVarList,1)
    self._PushString(self.GetProperty(self._PopString(),lparm1))

  of Opcode:POSITIONview
    If self._logClarion then self.Log('[CLAR]POSITION(view,string)').
    self._PushString(self.Position())

  of Opcode:RESETfile   ! This is called for a RESET(view,position)
    If self._logClarion then self.Log('[CLAR]RESET(view,string)').
    self.Reset(self._PopString())

  of Opcode:PREVIOUS
    If self._logClarion then self.Log('[CLAR]PREVIOUS(view)').
    self.Previous()

  ! unordered
  of Opcode:BUFFER
   !!! todo view Opcode:BUFFER

  of Opcode:CLOSE
    If self._logClarion then self.Log('[CLAR]CLOSE(view)').
    self.Close()

  of Opcode:DELETE
    If self._logClarion then self.Log('[CLAR]DELETE(view)').
    self.Delete()

  of Opcode:FLUSH
    If self._logClarion then self.Log('[CLAR]FLUSH(view)').
    self.Flush()

  of Opcode:HOLD                   !(Hold not supported by Traditional SQL drivers)
    !!!todo View Opcode:Hold

  of Opcode:DO_PROPERTY    ! equate(88)
    lparm1 = self._GetParmAsLong(pVarList,1)
    self.DoProperty(self._PopString(),lparm1)

  of Opcode:PUT
    If self._logClarion then self.Log('[CLAR]PUT(view)').
    self.Put()

  of Opcode:OPEN
    If self._logClarion then self.Log('[CLAR]OPEN(view)').
    self.Open()


  of Opcode:RECORDS
    If self._logClarion then self.Log('[CLAR]RECORDS(view)').
    Return self.Records()

  of Opcode:REGETfile
    If self._logClarion then self.Log('[CLAR]REGET(view)').
    self.Reget(self._PopString())

  of Opcode:RELEASE
    !!!todo View Opcode:Release  (Release not supported by Traditional SQL drivers)

  of Opcode:RESETviewf
    If self._logClarion then self.Log('[CLAR]RESET(view,file)').
    self.Reset()

  of Opcode:SEND
    If self._logClarion then self.Log('[CLAR]SEND(view,driveroption)').
    self._PushString(self.Send(self._PopString()))

  of Opcode:SETviewfields
    lparm1 = self._GetParmAsLong(pVarList,1)
    If self._logClarion then self.Log('[CLAR]SET(view,' & lParm1 & ')').
    self.Set(lParm1)
    If self._logData then self.LogBuffer().

  of Opcode:SET_PROPERTY
    lparm2 = self._GetParmAsLong(pVarList,1)
    self.SetProperty(self._PopString() ,lparm2,self._PopString() )

  of Opcode:SKIP
    self.trace('xxx SKIP(view) - TODO Not Implemented yet')
    !!!todo View Opcode:Skip

  of Opcode:WATCH
    self.trace('xxx WATCH(view) - TODO Not Implemented yet;')
    !!!todo View Opcode:Watch

  else
    self.trace('Driver View Pipe: Unhandled Command [' & pOpCode & '] ' & self.InterpretOpCode(pOpcode) & ' pClaVCB=' & pClaVCB & ' pVarList = ' & pVarList & ' ERROR')
  End
  Return 0


!-----------------------------------------------------------------
! parse self.ClaVCB.Descriptor
DriverViewClass._BuildTree         Procedure()
addr       long
FileIndex  long
f          &file
cstr       &cstring
  code
  self._FreeTree(self.Tree)
  clear(self.Tree)
  self.Files = 0

  addr = self.ClaVCB.ViewDescriptor + 1                  ! skip first byte
  FileIndex = self.ClaVCB.FileIndex                      ! pointer to an array of (FCB / File) pointers
  self._parseDescriptor(addr , FileIndex ,self.Tree,f)   ! f is null
  self.ViewDriver = self.tree.File{prop:driver}
  cstr &= (self.ClaVCB.filter)
  self.SetProp:Filter(cstr)
  cstr &= (self.ClaVCB.order)
  self.SetProp:Order(cstr)
  self._CountFields()
  Return

!-----------------------------------------------------------------
DriverViewClass._parseDescriptor         Procedure(*Long pAddr, *Long pFileIndex, ViewTreeType pNode, FILE pParentFile)
b     byte
sh    short
x     long
y     long
lg    long
obj   &DriverFileClass
fil   &file
cstr  &cstring
  code
  self.Files += 1
  clear(pNode)
  pNode.parentFile &= pParentFile
  peek(pAddr,b)                                                                       ! Number of Linking Fields
  pAddr += 1
  pNode.numLinkingFields = b
  If pNode.numLinkingFields = 0FFh                                                    ! Custom expression
    cstr &= (pAddr)
    pNode.LinkingExpr &= new Cstring(len(cStr)+1)
    pNode.LinkingExpr = cstr
    Peek(pFileIndex,lg)
    pFileIndex += 4
    pNode.File &= (lg)
    self.FilePtr[self.files] = lg
    Loop 10000 times                        !!!todo check  ! limit custom expression to 10000 chars?
      Peek(pAddr,b)
      pAddr += 1
      If b = 0 then Break.
    End
    Peek(pAddr,b)
    pAddr += 1
    pNode.jointype = b
    do SetRelation
  ElsIf pNode.numLinkingFields > 0                                                    ! join fields
    peek(pFileIndex,lg)
    pFileIndex += 4
    pNode.Key &= (lg)
    peek(lg+29,lg)
    pNode.File &= (lg)
    self.FilePtr[self.files] = lg
    loop x = 1 to pNode.numLinkingFields
      peek(pAddr,sh)
      pAddr += 2
      pNode.LinkingField[x] = sh
    End
    peek(pAddr,b)
    pAddr += 1
    pNode.jointype = b
    do SetRelation
  Else                                                                                ! this is the first node, so just pop the pFileIndex into File
    peek(pFileIndex,lg)
    pFileIndex += 4
    pNode.File &= (lg)
    self.FilePtr[self.files] = lg
    pNode.Relation = driver:root
  End
  ! cache the file object for later direct use
  fil &= (self.FilePtr[self.files])
  obj &= fil{prop:object}
  self.FileObject[self.files] = address(obj)
  pNode.Driver = fil{prop:driver}
  pNode.Index = self.Files
  !
  peek(pAddr,sh)                         ! Number of fields in this level of the View.
  pAddr += 2
  pNode.NumFields = sh
  If pNode.NumFields = -1 !0FFFFh        ! When set to -1 then no fields are PROJECTED into the view. This typically means that ALL fields should be projected.
    pNode.NumFields = 0
  Else
    Loop x = 1 to pNode.NumFields
      peek(pAddr,sh)
      pAddr += 2
      If sh = -1                         ! the field is a memo or blob. Next short is the blob/memo number
        peek(pAddr,sh)
        pAddr += 2
        pNode.Field[x] = -sh
      Else
        pNode.Field[x] = sh
      End
    End
  End
  peek(pAddr,b)
  pAddr += 1
  pNode.NumChildren = b                  ! JOINS
  pNode.Alias = self.GetProp:Alias(self.files)
  If pNode.NumChildren
    pNode.Children &= new ViewTreeType
    loop pNode.NumChildren times
      self._parseDescriptor(pAddr, pFileIndex, pNode.Children,pNode.File)   ! increases pAddr, because passed by reference.
    End
  End
  pNode.AutoProject = driver:projectfields
  Add(pNode)
  Return

SetRelation  routine
  fil &= (self.FilePtr[self.files])
  obj &= fil{prop:object}
  if obj.HasRelation(pNode.parentFile)
    pNode.Relation = driver:many
    exit
  end
  obj &= pNode.parentFile{prop:object}
  if obj.HasRelation(fil)
    pNode.Relation = driver:one
    exit
  end
  pNode.Relation = driver:unknown

!-----------------------------------------------------------------
DriverViewClass.Walk   procedure()
  code
  self._walk(self.Tree,1)
  Return

!-----------------------------------------------------------------
DriverViewClass._Walk   procedure(ViewTreeType pNode,Long pLevel)
x         long
y         long
linklist  cstring(540)
inner     cstring(7)
  code
  loop x = 1 to records(pNode)
    Get(pNode,x)
    If pLevel = 1
      linklist = ''
      If not self.Filter &= Null then linklist = ',FILTER(''' & self.filter & ''')'.
      If not self.Order &= Null then linklist = linklist &  ',ORDER(''' & self.Order & ''')'.
      linklist = linklist & '[' & pNode.Driver & ']'
      If not pNode.File &= Null
        self.trace(all(' ',pLevel * 2) & 'VIEW(' & name(pNode.File) & ')' & linklist)
      Else
        self.trace(all(' ',pLevel * 2) & 'VIEW()' & linklist)
      End
    Else
      If pNode.jointype = driver:innerjoin then inner = ',INNER' else inner = ''.
      If not pNode.key &= Null
        linklist = ''
        If not pNode.ParentFile &= null
          Loop y = 1 to pNode.numLinkingFields
            linklist = linklist & ',' & pNode.ParentFile{prop:label,pNode.LinkingField[y]}
          End
        End
        linklist = linklist & '[' & pNode.Driver & ']'
        self.trace(all(' ',pLevel * 2) & 'JOIN(' & pNode.key{prop:label} & linklist & ')' & inner)
      ElsIf not pNode.File &= Null
        If not pNode.LinkingExpr &= null and pNode.LinkingExpr <> ''
          self.trace(all(' ',pLevel * 2) & 'JOIN(' & name(pNode.File) & ',''' & pNode.LinkingExpr & ''')' & inner & ' [' & pNode.Driver & ']')
        Else
          self.trace(all(' ',pLevel * 2) & 'JOIN(' & name(pNode.File) & ')' & inner & ' [' & pNode.Driver & ']')
        End
      Elsif pNode.TableName <> ''
        self.trace(all(' ',pLevel * 2) & 'JOIN(''' &  pNode.TableName & ''')')
      Else
        self.trace(all(' ',pLevel * 2) & 'JOIN()')
      End
    End
    Loop y = 1 to pNode.NumFields
      If pNode.Name[y]
        self.trace( all(' ',pLevel * 2) & '  PROJECT(' & pNode.Name[y] & ')')
      Else
        self.trace( all(' ',pLevel * 2) & '  PROJECT(' & pNode.File{prop:label,pNode.Field[y]} & ')')
      End
    End
    If not pNode.children &= null
      self._Walk(pNode.children,pLevel+1)
    End
    self.trace(all(' ',pLevel * 2) & 'END')
  End

!-----------------------------------------------------------------
! we need a _morph method here so that result.GetCell can call it.
! However the actual morph is likely to depend on node.fields, so this method can't be used for all data types
! or data type conversions. It's limited to paths that don't make use of fields.
DriverViewClass._Morph                        Procedure(String pFieldLabel,Byte pClarionType, Long pClarionAddress, Long pClarionLength, Long pCellType, Long pCellAddress, Long pCellLength, Long pSqlTimeStamp, Byte pSetFieldNull, *Long rTextLength)
obj  &DriverFileClass
  code
  obj &= (self.FileObject[1])
  obj._Morph(pFieldLabel,pClarionType,pClarionAddress,pClarionLength,pCellType,pCellAddress,pCellLength,pSqlTimeStamp,pSetFieldNull,rTextLength)
  Return

!-----------------------------------------------------------------
DriverViewClass._ClearParameterQueue           Procedure(Long pOpcode)
x    long
obj  &DriverFileClass
  code
  Loop x = 1 to self.Files
    obj &= (self.FileObject[x])
    If obj &= null then cycle.
    obj._ClearParameterQueue(pOpcode)
  End
  self._ParameterCount = 0
  Return

!-----------------------------------------------------------------
DriverViewClass._CountFields                  Procedure()
ans   Long
x     Long,Auto
  code
  Loop x = 1 to self.files
    If self._withNodeFileIndex(x) = driver:ok
      If self.node.NumFields = 0
        If not self.node.File &= NULL
          ans += self.node.File{prop:fields}
        End
      Else
        ans += self.node.NumFields
      End
    End
  End
  self.Fields = Ans
  Return

!-----------------------------------------------------------------
DriverViewClass.BINDFIELD                     Procedure(String pName,*Long pLong)
  Code
  If self.BindQueue &= Null
    self.BindQueue &= new BindQueueType
  End
  self.BindQueue.Name = upper(clip(pName))
  Get(self.BindQueue,self.BindQueue.Name)
  If Errorcode()
    Clear(self.BindQueue)
    self.BindQueue.Name = upper(clip(pName))
    self.BindQueue.lg &= pLong
    Add(self.BindQueue)
  Else
    self.BindQueue.lg &= pLong
    Put(self.BindQueue)
  End
  Return

!-----------------------------------------------------------------
DriverViewClass.BINDFIELD                     Procedure(String pName,*Real pReal)
  Code
  If self.BindQueue &= Null
    self.BindQueue &= new BindQueueType
  End
  self.BindQueue.Name = upper(clip(pName))
  Get(self.BindQueue,self.BindQueue.Name)
  If Errorcode()
    Clear(self.BindQueue)
    self.BindQueue.Name = upper(clip(pName))
    self.BindQueue.rl &= pReal
    Add(self.BindQueue)
  Else
    self.BindQueue.rl &= pReal
    Put(self.BindQueue)
  End
  Return

!-----------------------------------------------------------------
DriverViewClass.BINDFIELD                     Procedure(String pName,*String pString)
  Code
  If self.BindQueue &= Null
    self.BindQueue &= new BindQueueType
  End
  self.BindQueue.Name = upper(clip(pName))
  Get(self.BindQueue,self.BindQueue.Name)
  If Errorcode()
    Clear(self.BindQueue)
    self.BindQueue.Name = upper(clip(pName))
    self.BindQueue.st &= pString
    Add(self.BindQueue)
  Else
    self.BindQueue.st &= pString
    Put(self.BindQueue)
  End
  Return

!-----------------------------------------------------------------
DriverViewClass.BINDFIELD                     Procedure(String pName,*Cstring pCstring)
  Code
  If self.BindQueue &= Null
    self.BindQueue &= new BindQueueType
  End
  self.BindQueue.Name = upper(clip(pName))
  Get(self.BindQueue,self.BindQueue.Name)
  If Errorcode()
    Clear(self.BindQueue)
    self.BindQueue.Name = upper(clip(pName))
    self.BindQueue.cst &= pCstring
    Add(self.BindQueue)
  Else
    self.BindQueue.cst &= pCstring
    Put(self.BindQueue)
  End
  Return

!-----------------------------------------------------------------
DriverViewClass.BUFFER                   PROCEDURE(UNSIGNED pPageSize, UNSIGNED pBehind=0, UNSIGNED pAhead=0, UNSIGNED pTimeout=0)
  Code
  self.SetError(NoError)
  If pAhead
    self.FetchSize = pPageSize * pAhead
  Else
    self.FetchSize = pPageSize
  End
  Return

!-----------------------------------------------------------------
DriverViewClass.CLOSE                     Procedure()
  code
  Self.SetError(NoError)
  parent.Close()                             ! will flush the buffers
  self._BuildTree()                          ! returns the view tree to the compiled program state.
  self._FreeParameterQueue()
  Return

!-----------------------------------------------------------------
DriverViewClass.GetProperty               Procedure(String pProperty,Long pIndex=0)
  code
  !self.trace('DriverViewClass.GetProperty (' & self.InterpretProperty(pProperty) & ',' & pIndex & ')')
  If self._logClarion then self.Log('[CLAR]GETPROPERTY('& clip(pProperty) & ' ' & self.InterpretProperty(pProperty) & ',' & pIndex & ')' ).
  case pProperty
  of PROP:Alias
    return self.GetProp:Alias(pIndex)
  of Prop:AutoProject
    return self.GetProp:AutoProject(pIndex)
  of PROP:Field
    return self.GetProp:Field(pIndex)
  of PROP:Fields
    return self.GetProp:Fields(pIndex)
  !of PROP:JoinExpression    ! EQUATE (7212H)  ! Set the join expression
    !return self.GetProp:JoinExpression()
  of PROP:Files                               ! Get number of files in view
    return self.GetProp:Files(pIndex)
  of PROP:File                                ! Get reference to n'th File
    return self.GetProp:File(pIndex)
  of PROP:FieldsFile                          ! Get reference to the File that the n'th field is in
    return self.GetProp:FieldsFile(pIndex)
  of PROP:Hint
    return self.GetProp:Hint(pIndex)
  of PROP:Inner
    return self.GetProp:Inner(pIndex)
  of PROP:Name
    return self.GetProp:Name(pIndex)
  of Prop:NoKeyProject
    return self.GetProp:NoKeyProject (pIndex)
  of PROP:Object
    return self.GetProp:Object()
  of PROP:OrderAllTables     !  ! use linking fields and secondary files' key component fields, as well as the primary file's key component fields, in the ORDER BY clause it sends to the server.
    return self.GetProp:OrderAllTables()
  of PROP:OrderInSelect      !  ! Some SQL backends require that any fields used in the ORDER BY clause also appear in the SELECT statement.
    return self.GetProp:OrderInSelect()
  of Prop:Project
    return self.GetProp:Project(pIndex)
  of PROP:Records
    return self.Records()
  of PROP:SQLJoinExpression
    return self.GetProp:SQLJoinExpression(pIndex)
  else
    Return parent.GetProperty(pProperty,pIndex)
  end
  Return ''
!-----------------------------------------------------------------
DriverViewClass.CreateView                  Procedure(FILE pMainFile)
  code
  !!!todo create a new VCB and assign it to a &view
  Return 0

!-----------------------------------------------------------------
!!! Derived in DriverViewSqlClass
DriverViewClass.Delete              Procedure()
PrimaryFile  &File
  code
  ! FilePtr1.Position needs to be set to current row buffer
  PrimaryFile &= (self.FilePtr[1])
  Delete(PrimaryFile)
  self.sqlcode.SetValue(PrimaryFile{prop:sql})
  self.Affected = PrimaryFile{prop:Affected}
  self.ChildrenAffected = PrimaryFile{prop:ChildrenAffected}
  Return

!-----------------------------------------------------------------
DriverViewClass.JoinTable                  Procedure(FILE pParentFile,FILE pJoinFile,Byte pJoinType,String pExpression)
  code
  ! find the parent node
  if pJoinFile &= null then Return.
  if self._withNodeFile(pParentFile) = Driver:ok
    ! add a child to the parent node
    self.Files += 1
    self.FilePtr[self.Files] = address(pJoinFile)
    self.FileObject[self.Files] = (pJoinFile{prop:object})

    Clear(self.node)
    self.node.ParentFile  &= pParentFile
    self.node.File        &= pJoinFile
    self.node.Driver      = pJoinFile{prop:Driver}
    self.node.Alias       = self.GetProp:Alias(self.Files)
    !                     join
    self.node.Key         &= null
    !!!todo support expressions; needs to be parsed
    !self.node.LinkingExpr &= new CString(len(clip(pExpression))+1)
    !self.node.LinkingExpr  = clip(pExpression)
    self.node.JoinType    = pJoinType
    self.node.index = self.Files
    Add(self.node)
  End
  self._CountFields()
  Return

!-----------------------------------------------------------------
DriverViewClass.JoinTable                  Procedure(FILE pParentFile, KEY pKey, Byte pJoinType, <*? pField1>)
obj              &DriverFileClass
Offset                   long
ptr   long
  code
  ! find the parent node
  if pKey &= null then Return.
  if self._withNodeFile(pParentFile) = Driver:ok
    ! add a child to the parent node
    If self.node.children &= NULL
      self.node.children &= new(ViewTreeType)
      put(self.node)
    End

    Clear(self.node.Children)
    self.node.Children.ParentFile  &= pParentFile
    self.node.Children.File        &= pKey{prop:file}
    self.Files += 1
    self.FilePtr[self.Files]       = address(self.node.Children.File)
    self.FileObject[self.Files]    = (self.node.Children.File{prop:object})
    self.node.Children.Driver      = self.node.File{prop:driver}
    self.node.Children.Alias       = self.GetProp:Alias(self.Files)
    !                     join
    self.node.Children.Key         &= pKey
    obj &= self.node.Children.ParentFile{prop:object}     ! obj is PARENT object
    self.node.Children.JoinType    = pJoinType
    self.node.Children.LinkingExpr &= null
    self.node.Children.SQLJoinExpression &= null
    If not omitted(pField1) and not pField1 &= NULL
      peek(address(pfield1)+4,ptr)
      offset = ptr - obj.ClaFCB.rec_buf
      If obj._WithFieldOffset(offset,0) = driver:ok
        self.node.Children.NumLinkingFields += 1
        self.node.Children.LinkingField[self.node.Children.NumLinkingFields] = obj.Fields.index
      End
    End
    self.node.Children.index = self.Files
    Add(self.node.Children)
  End
  self._CountFields()
  Return

!-----------------------------------------------------------------
DriverViewClass.LogBuffer                 Procedure()
LogFile &file
x       long,Auto
p       long,Auto
obj      &DriverFileClass
  code
  p = self.GetProp:Files(0)
  Loop x = 1 to p
    LogFile &= self.GetProp:File(x)
    If LogFile &= null then cycle.
    obj &= LogFile{prop:object}
    If not obj &= null
      obj.LogBuffer()
    End
  End
  Return

!-----------------------------------------------------------------
DriverViewClass.Next                      Procedure()
  code
  If self._JustSetSearch
    clear(self.SearchRank,-1)
    self._JustSetSearch = false
  End
  If self._HasBeenSet = False
    If self._PropSqlCalled

    ElsIf self._PropOrderCalled
      Self.SetError(BadRecErr)
    ElsIf self._SetFromFile() = driver:ok
    Else
      Self.SetError(BadRecErr)
    End
  End
  Return

!-----------------------------------------------------------------
DriverViewClass.Open                      Procedure()
f       &File,Auto
x       Long,Auto
obj     &DriverFileClass,Auto
  code
  parent.Open()
  If errorcode() then return.
  Loop x = 1 to self.GetProp:Files(0)
    f &= self.GetProp:File(x)
    If f &= null then break.
    If Status(f) = 0
      self.SetError(NotOpenErr)
      Return
    End
  End

  self._DeclaredFilter &= (self.ClaVCB.filter)
  obj &= (self.FileObject[1])
  If not obj &= null
    self.opt:explain = obj.opt:explain
    self.Explain = obj.Explain
  End
  self._DeclaredOrder &= (self.ClaVCB.order)
  self.TokenStr.SetValue('')
  self._opened = true
  self._HasBeenSet = false
  self._HasBeenSetFromFile = false
  Return

!-----------------------------------------------------------------
! Position(View) returns a string containing the values of all the primary fields
!   it's possible, indeed likely, that
!     If the order is not unique then the value returned is of little use
!     If the Primary Key values are not included in the order, or the Primary Key values are not PROJECTed then REGET cannot be used.
! The first 4 bytes are the row number of the row
DriverViewClass.Position                  Procedure()
PosStr  String(DRIVER:MAX_PRIMARY_KEY_SIZE)
Obj     &DriverFileClass  ,Auto
x       Long              ,Auto
y       Long              ,Auto
PosLen  Long              ,Auto
RowStr  String(4)     ,Auto
RowNum  Long,Over(RowStr)
SizPos  Long,Auto
srStr   String(8),over(self.searchrank)
hash    string(16),Auto
  code
  SizPos = Size(self.Position)
  RowNum = 0
  self.Position[1 : 4] = RowStr
  self._PosLen = 4
  Loop x = 1 to self.Files
    Obj &= (self.FileObject[x])
    If obj &= null then cycle.
    PosStr = obj._GetPrimaryKeyPosition(PosLen)  ! PosLen is passed by reference, filled, and returned
    If self._PosLen + PosLen > sizPos then break.
    self.Position[self._PosLen+1 : self._PosLen + PosLen] = PosStr[1 : PosLen]
    self._PosLen += PosLen
  End
  self.Position[self._PosLen+1 : self._PosLen + 8] = srStr
  self._PosLen += 8
  hash = self.TempStr.MD5(st:EncNone, self.Position, self._PosLen)
  self.Result.SetRowPosition(self.ResultRow,hash)
  If self._PosLen < 1 then return ''.
  Return self.Position[1 : self._PosLen]

!-----------------------------------------------------------------
DriverViewClass.Previous                  Procedure()
  code
  If self._JustSetSearch
    clear(self.SearchRank,1)
    self._JustSetSearch = false
  End
  If self._HasBeenSet = False
    If self._PropSQLCalled

    ElsIf self._PropOrderCalled
      Self.SetError(BadRecErr)
    ElsIf self._SetFromFile() = driver:ok
    Else
      Self.SetError(BadRecErr)
    End
  End
  Return

!-----------------------------------------------------------------
DriverViewClass.PrimeSubset                  Procedure()
x    Long,Auto
obj  &DriverFileClass
  Code
  obj &= (self.FileObject[1])
  self.SubsetPrimaryFile &= obj.File
  If obj._WithPrimaryKey() = Driver:ok
    Loop x = 1 to obj.keys.components
      If obj._WithField(obj.keys.component[x]) = Driver:ok
        If self.SubSetFields = ''
          self.SubSetFields = obj.Fields.column
        Else
          self.SubSetFields = self.SubSetFields & ',' & obj.Fields.column
        End
      End
    End
  End
  Return

!-----------------------------------------------------------------
!!! Derived in DriverViewSqlClass
DriverViewClass.ProjectField              Procedure(String pExpression,String pAs)
  code
  self.SetError(NoDriverSupport)
  Return

!-----------------------------------------------------------------
!!! Derived in DriverViewSqlClass
DriverViewClass.ProjectField              Procedure(File pFile, Long pIndex)
  code
  self.SetError(NoDriverSupport)
  Return

!-----------------------------------------------------------------
!!! Derived in DriverViewSqlClass
DriverViewClass.ProjectField              Procedure(*? pField)
  code
  self.SetError(NoDriverSupport)
  Return

!-----------------------------------------------------------------
!!! Derived in DriverViewSqlClass
DriverViewClass.PUT              Procedure()
  code
  Return

!-----------------------------------------------------------------
DriverViewClass.RECORDS                   Procedure()
  Code
  self.SetError(NoDriverSupport)
  Return 0

!-----------------------------------------------------------------
DriverViewClass.RECORDS                   Procedure(Long pIndex)
  Code
  self.SetError(NoDriverSupport)
  Return 0

!-----------------------------------------------------------------
!  REGET reads the VIEW record identified by the string returned by the POSITION(view) procedure.
!  If the VIEW contains JOIN structures, REGET retrieves the appropriate set of related records.
!  **** REGET re-loads all the  files' record buffers with complete records.  It does not perform the relational "Project" operation. ****
! This only works if the POSITION contains the Primary Key values. Which means they need to have been PROJECTed.

DriverViewClass.REGET                     Procedure(String pPosition)
x         Long,Auto
offset    Long,Auto
obj       &DriverFileClass
pk        &key,Auto
srStr     string(8),over(self.SearchRank)
  code
  If self._CheckOpen() = false then Return.
  offset = self._FillBuffersFromPosition(pPosition, 5 , driver:buffer)
  srStr = sub(pPosition,offset,8)
  ! for each file in the View, do a GET on the file
  Loop x = 1 to self.Files
    obj &= (self.FileObject[x])
    if obj &= Null then cycle.
    If obj._WithPrimaryKey() = driver:ok
      pk &= (obj.keys.keyptr)
      obj.setProp:Project('')
      obj.Get(pk)
    End
  End

  Return
!-----------------------------------------------------------------
!-----------------------------------------------------------------
! pStr must be a POSITION string returned from calling POSITION(view)
! populate that position string into the desired buffer
DriverViewClass._FillBuffersFromPosition  Procedure(STRING pPosition, Long pOffset, Long pWhichBuffer)
Obj     &DriverFileClass,Auto
x       Long,Auto
kLen    Long,Auto
Len     Long,Auto
  code
  Len = len(pPosition)
  Loop x = 1 to self.Files
    Obj &= (self.FileObject[x])
    If obj &= null then cycle.
    Obj._SetPrimaryKeyPosition(pPosition[ pOffset : len],pWhichBuffer,kLen)
    pOffset += kLen
  End
  Return pOffset

!-----------------------------------------------------------------
DriverViewClass.RESET                     Procedure(String pPosition)
offset   Long
srStr    String(8),over(self.SearchRank)
  code
  self._SetOffset = 0
  offset = self._FillBuffersFromPosition(pPosition, 5, driver:buffer)     ! Reset is going to do a REGET, so may as well put it in the BUFFER for the GET to work on
  self._FillBuffersFromPosition(pPosition, 5, driver:shadow)
  srStr = Sub(pPosition,offset,8)
  Return

!-----------------------------------------------------------------
DriverViewClass.RESET                     Procedure()
  Code

!-----------------------------------------------------------------
DriverViewClass.ResultGet        PROCEDURE(BIGINT pRow)
  code
  If pRow < 1 or pRow > self.Result.Rows()
    self.SetError(BadRecErr)
    Return
  End
  self._ResultRow = pRow
  self.ResultToRecords(self._ResultRow, driver:buffer)
  Return

!-----------------------------------------------------------------
DriverViewClass.DoPROP:SQL                Procedure()
  Code
  If self._HasBeenSet = False
    Self.Paging = false
    Self.Set(0)
  End
  parent.DoProp:SQL()
  Return

!-----------------------------------------------------------------
DriverViewClass.BuildMap  Procedure()
index  Long,Auto
  code
  PushErrors()
  index = 0
  self._BuildMapWalker(self.Tree,index)
  self._RecordsViewMap = index
  PopErrors()
  Return

!-----------------------------------------------------------------
! The index represents the field in the VIEW. Which maps to a column in the result set.
! ViewMapObj[pIndex] is the file object for this field in the view
! ViewMapFieldNumber[pIndex] is the field index, into that file object
! ViewMapFieldNode[pIndex] is the field node in that file object
! ViewMapIsPrimary[pIndex] is set if the field is a primary key value in the file
DriverViewClass._BuildMapWalker  Procedure(ViewTreeType pNode,*Long pIndex)
x            Long,Auto
y            Long,Auto
obj          &DriverFileClass
  code
  If pNode &= null then Return.
  If pNode.File &= null then Return.
  Loop x = 1 to Records(pNode)
    Get(pNode,x)
    If pNode.NumFields
      Loop y = 1 to pNode.NumFields
        pIndex += 1
        self.ViewMapObj[pIndex] = (pNode.File{prop:object})
        self.ViewMapFieldNumber[pIndex] = pNode.Field[y]
        obj &= (self.ViewMapObj[pIndex])
        self.ViewMapFieldNode[pIndex] = address(obj._WithFieldNode(pNode.Field[y]))
        if obj._WithField(pNode.Field[y]) = driver:ok
          self.ViewMapIsPrimary[pIndex] = obj.fields.Primary
        else
          self.ViewMapIsPrimary[pIndex] = false
        end
      End
    End
    If not pNode.children &= NULL
      self._BuildMapWalker(pNode.Children,pIndex)
    End
  End
  Return

!-----------------------------------------------------------------
! take a row from the result set, and copy it into the various record buffers that belong to the view
! pOptions is one of driver:buffer or driver:shadowbuffer
DriverViewClass.ResultToRecords  Procedure(Long pRow,Long pOptions)
index        long,Auto
obj          &DriverFileClass,Auto
cols         Long,Auto
colname      Cstring(255)
F            &File
  Code
  PushErrors()
  !For each field move it from the results into the appropriate record
  If self._RecordsViewMap = 0
    cols = self.Result.Columns()
    Loop index = 1 to cols
      If index > self.fields then break. ! because of prop:sql the result set may contain more fields than are in the view.
      colName = self.Result.GetColumnName(index)
      F &= self.GetProp:FieldsFile(index)
      obj &= F{prop:object}
      If obj &= null then cycle.
      If obj._WithFieldNamed(colname) = Driver:ok
        obj.ResultToFieldNumber(self.Result,pRow,index,index, pOptions)
      End
    End
  Else
    Loop index = 1 to self._RecordsViewMap
      obj &= (self.ViewMapObj[Index])
      obj.fields &= (self.ViewMapFieldNode[Index])
      obj.ResultToFieldNumber(self.Result,pRow,index , self.ViewMapFieldNumber[Index], pOptions)
    End
  End

  If self.readonly = false
    Loop index = 1 to self.Files
      obj &= (self.FileObject[index])
      If obj &= null then cycle.
      obj._WatchBuffLoad()
      obj.SetPrimaryKeyPosition()  ! allows row to be DELETED or PUT
    End
  End
  If not self.BindQueue &= null
    self.ResultToBind(pRow)
  End
  PopErrors()
  Return

!-----------------------------------------------------------------
DriverViewClass.ResultToBind  Procedure(Long pRow)
x      Long,auto
col    long,auto
  Code
  If self.BindQueue &= null then Return.
  If Records(self.BindQueue) = 0 then Return.
  PushErrors()
  Loop x = 1 to Records(self.BindQueue)
    Get(self.BindQueue,x)
    col = self.Result.GetColumnNamed(self.bindqueue.name)
    If col
      self.ResultToBindField(pRow,Col)
    End
  End
  PopErrors()
  Return

!-----------------------------------------------------------------
DriverViewClass.ResultToExplain  Procedure(iResultSet pResult)
Obj   &DriverFileClass
  Code
  obj &= (self.FileObject[1])
  obj.ResultToExplain(pResult)
  Return

!-----------------------------------------------------------------
DriverViewClass.Search                    Procedure(String pSearchString,<*? pField1>, <*? pField2>, <*? pField3>, <*? pField4>, <*? pField5>, <*? pField6>, <*? pField7>, <*? pField8>, <*? pField9>, <*? pField10>,<*? pField11>, <*? pField12>, <*? pField13>, <*? pField14>, <*? pField15>)
  Code

!-----------------------------------------------------------------
! This is called if the SET(file) / Open(VIEW) / Next(View) pattern is used
! Self._HasBeenSet = false
DriverViewClass._SetFromFile                Procedure()
obj  &DriverFileClass
  code
  obj &= (self.FileObject[1])
  If obj &= Null then Return Driver:notok .
  If not self._DeclaredOrder &= NULL
    self.SetProp:Order(self._DeclaredOrder)
  ElsIf obj.SetKey &= null
    Return Driver:notok
  Else
    self.SetProp:Order(obj.BuildPropOrderByKey(obj.SetKey))
  End

  self._HasBeenSetFromFile = 1
  If not self._DeclaredFilter &= NULL and self.GetProp:Order() = ''
    self.SetProp:Filter(self._DeclaredFilter)
  ElsIf not obj.SetKeyKey &= null
    ! prime shadow buffers from file record
    memcpy(address(obj.ShadowBuffer),obj.ClaFCB.rec_buf,obj.ClaFCB.rec_len)
    self._HasBeenSetFromFile = driver:ShadowBufferPrimed
  End

  self.Set(0)
  Return driver:ok

!-----------------------------------------------------------------
DriverViewClass.Set                       Procedure(Long pIndex)
obj  &DriverFileClass
  code
  Self._HasBeenSet = true
  If self._HasBeenSetFromFile = false
    If self._PropOrderCalled  = false
      If not self._DeclaredOrder &= NULL
        self.SetProp:Order(self._DeclaredOrder)
      Else
        obj &= (self.FileObject[1])
        If not obj &= Null and not obj.SetKey &= null
          self.SetProp:Order(obj.BuildPropOrderByKey(obj.SetKey))
        End
      End
    End
    If self._PropFilterCalled  = False  and not self._DeclaredFilter &= NULL
      self.SetProp:Filter(self._DeclaredFilter)
    End
  End
  self.setError(NoError)
  self._ParameterOpcode = opcode:SET
  self.NewResultSet(driver:DontFreeRam)
  self._FreeSubset()
  self._paging = Self.Paging
  self._SetOffset = 0
  FileSETObject &= null  ! FileSetObject is a module level, threaded parameter. It notes the most recent object to do a SET. This is used by EXCEPT, UNION and INTERSECT
  ViewSETObject &= self  ! ViewSetObject is a module level, threaded parameter. It notes the most recent object to do a SET. This is used by EXCEPT, UNION and INTERSECT
  self._SearchOrderClause = ''
  Return

!-----------------------------------------------------------------
DriverViewClass.STATUS           PROCEDURE()
  Code
  If self._opened
    Return 1
  End
  Return 0

!-----------------------------------------------------------------
DriverViewClass.SetProperty               Procedure(String pProperty,Long pIndex,STRING pValue)
  code
  !self.trace('DriverViewClass.SETPROPERTY (' & pProperty & ' >> ' & self.InterpretProperty(pProperty) & ',' & pIndex & ',' & pValue & ')')
  If self._logClarion then self.Log('[CLAR]SETPROPERTY('& clip(pProperty) & ' ' & self.InterpretProperty(pProperty) & ',' & pIndex & ') =' & pValue )  .
  case pProperty
  of Prop:AutoProject
    self.SetProp:AutoProject(pIndex,pValue)
  of PROP:Distinct
    self.SetPROP:Distinct(pValue)
  of PROP:NotDistinct
    self.SetPROP:NotDistinct(pValue)
  of PROP:FetchSize
    self.SetPROP:FetchSize(pValue)
  of PROP:Filter
    self.SetPROP:Filter(pValue)
  of PROP:Hint
    self.SetPROP:Hint(pIndex,pValue)
  of PROP:IPRequestCount
    self.SetPROP:IPRequestCount(pValue)
  of PROP:Inner
    self.SetPROP:Inner(pIndex,pValue)
  of PROP:Limit
    self.SetPROP:Limit(pValue)
  of PROP:Name
    self.SetPROP:Name(pIndex,pValue)
  of Prop:NoKeyProject
    self.SetProp:NoKeyProject (pIndex,pValue)
  of PROP:Object
    self.SetPROP:Object(pValue)
  of PROP:Offset
    self.SetPROP:Offset(pValue)
  of PROP:Order
    self.SetPROP:Order(pValue)
  of Prop:OrderAllTables
    self.SetProp:OrderAllTables(pValue)
  of PROP:OrderInSelect      !  ! Some SQL backends require that any fields used in the ORDER BY clause also appear in the SELECT statement.
    self.SetProp:OrderInSelect(pValue)
  of PROP:QuoteString
    self.SetProp:QuoteString(pValue)
  of PROP:SQL
    self.SetProp:SQL(pValue)
  of PROP:SQLFilter
    self.SetProp:SQLFilter(pValue)
  of PROP:SQLJoinExpression
    self.SetProp:SQLJoinExpression(pIndex,pValue)
  of PROP:SQLOrder
    self.SetProp:SQLOrder(pValue)
  else
    If Instring(':',pProperty) and pIndex = prop:name  ! view{'field_label',PROP:Name} = string
      self._SetViewFieldColumn(pProperty,pValue)
    Else
      parent.SetProperty(pProperty,pIndex,pValue)
    End
    !self.trace('DriverViewClass.SETPROPERTY (' & self.InterpretProperty(pProperty) & ',' & pIndex & ',' & pValue & ')')
  End

!-----------------------------------------------------------------
! SQL drivers support the following syntax
! view{'field_label',PROP:Name} = string
! This method finds the node with that field, then sets the pnode.name
DriverViewClass._SetViewFieldColumn          procedure(String pLabel, String pValue)
result  long
  code
  result = self._SetViewFieldWalker(self.Tree,pLabel,pValue,0)
  Return

!-----------------------------------------------------------------
DriverViewClass._SetViewFieldWalker          procedure(ViewTreeType pNode,String pLabel, String pValue,Long pFileNumber)
x    long
i    long
obj  &DriverFileClass
  code
  Loop x = 1 to Records(pNode)
    Get(pNode,x)
    If pNode.File &= null then cycle.
    obj &= pNode.File{PROP:Object}
    pFileNumber += 1
    If not obj &= null and obj._WithFieldLabeled(pLabel) = Driver:ok
      i = obj.Fields.Index
      If pNode.NumFields = 0
        self._ForceAutoProjectNow(pNode) ! developer has called prop:name, but there are no fields in view. So forced to populate them all in now.
      End
      Loop x = 1 to pNode.NumFields
        If pNode.field[x] = i
          pNode.Name[x] = clip(pValue)
          Put(pnode)
          Return driver:ok
        End
      End
    End
    If not pNode.children &= null
      If self._SetViewFieldWalker(pNode.children,pLabel,pValue,pFileNumber) = driver:ok
        Return Driver:ok
      End
    End
  End
  Return driver:notok

!-----------------------------------------------------------------
! makes sure the pNode.NumFields is set, and the pNode.field[n]
DriverViewClass._ForceAutoProjectNow  Procedure(ViewTreeType pNode)
obj   &DriverFileClass
y     long
  code
  If pNode.File &= null then Return.
  obj &= pNode.File{prop:object}
  If obj &= null then return.
  If Band(pNode.AutoProject,driver:ProjectFields) > 0
    pNode.Dynamic = 1
    Loop y = 1 to obj.SharedProperties.FieldList.nodes
      If obj._withField(y) = driver:ok
        If obj.Fields.Type = ClaGROUP or obj.Fields.Over or obj.Fields.InOverGroup then Cycle.
        pNode.NumFields += 1
        pNode.field[pNode.NumFields] = obj.Fields.Index
      End
    End
  End
  If Band(pNode.AutoProject,driver:ProjectBlobs)
    pNode.Dynamic = 1
    Loop y = 1 to Records(obj.Blobs)
      If obj._WithBlob(y)
        pNode.NumFields += 1
        pNode.field[pNode.NumFields] = obj.blobs.Index
      End
    End
  End
  Put(pNode)
  Return

!-----------------------------------------------------------------
DriverViewClass._withNodeFileIndex               Procedure(Long pIndex)
  code
  self.node &= null
  If pIndex < 1 then pIndex = 1.
  If pIndex = 1                  ! optimization
    self.node &= self.tree
    Return Driver:ok
  End
  If self._withNodeFileIndexWalker(self.tree,pIndex,0) = Driver:ok
    Return Driver:ok
  End
  Return driver:notok

!-----------------------------------------------------------------
DriverViewClass._withNodeFileIndexWalker           Procedure(ViewTreeType pNode, Long pIndex,Long pCounter)
x  long
  code
  Loop x = 1 to Records(pNode)
    Get(pNode,x)
    pCounter += 1
    If pCounter = pIndex
      self.node &= pNode
      Return driver:ok
    End
    If not pNode.children &= null
      If self._withNodeFileIndexWalker(pNode.children,pIndex,pCounter) = driver:ok
        Return Driver:ok
      End
    End
  End
  Return driver:notok

!-----------------------------------------------------------------
! Given a fixed table name, find that table in the view tree
DriverViewClass._withNodeTableName              Procedure(String pTableName)
  code
  pTableName = lower(pTableName)
  self.node &= null
  If self._withNodeTableNameWalker(self.tree,pTableName) = Driver:ok
    Return Driver:ok
  End
  Return driver:notok

!-----------------------------------------------------------------
DriverViewClass._withNodeTableNameWalker           Procedure(ViewTreeType pNode, String pTableName)
x  long
  code
  Loop x = 1 to Records(pNode)
    Get(pNode,x)
    If pNode.TableName = pTableName
      self.node &= pNode
      Return driver:ok
    End
    If not pNode.children &= null
      If self._withNodeTableNameWalker(pNode.children,pTableName) = driver:ok
        Return Driver:ok
      End
    End
  End
  Return driver:notok

!-----------------------------------------------------------------
DriverViewClass._withNodeFieldLabel               Procedure(String pLabel)
cstr  cString(size(pLabel)+1)
  code
  cstr = clip(pLabel)
  If self._withNodeFieldLabelWalker(self.tree,cstr) = Driver:ok
    return Driver:ok
  End
  Return driver:notok

!-----------------------------------------------------------------
! Given a field label, find the node that contains that field label.
DriverViewClass._withNodeFieldLabelWalker           Procedure(ViewTreeType pNode, *CString pLabel)
x    long
obj  &DriverFileClass
  code
  Loop x = 1 to Records(pNode)
    Get(pNode,x)
    If pNode.File &= null then cycle.
    obj &= pNode.File{prop:object}
    If obj &= null then cycle.
    If obj._WithFieldLabeled(plabel) = driver:ok
      self.node &= pNode
      Return driver:ok
    End
    If not pNode.children &= null
      If self._withNodeFieldLabelWalker(pNode.children,pLabel) = driver:ok
        Return Driver:ok
      End
    End
  End
  Return driver:notok

!-----------------------------------------------------------------
! takes a label of the form alias.label
! sets pNode to the node of the file
DriverViewClass._withNodeFieldLabelAlias            Procedure(String pAliasDotLabel)
lbl    cString(size(pAliasDotLabel)+1)
alias  cString(DRIVER:MAXALIASLENGTH)
x      Long
  code
  x = instring('.',pAliasDotLabel,1,1)
  self.trace('DriverViewClass._withNodeFieldLabelAlias x=' & x)
  If x = 0 then Return Driver:notok.
  alias = sub(pAliasDotLabel,1,x-1)
  lbl = sub(pAliasDotLabel,x+1,len(pAliasDotLabel))
  self.trace('alias=' & alias & ' lbl=' & lbl)
  If self._withNodeFieldLabelAliasWalker(self.tree,alias,lbl) = Driver:ok
    return Driver:ok
  End
  self.trace('wnfla 9')
  Return Driver:notok

!-----------------------------------------------------------------
! Given a field label, find the node that contains that field label.
DriverViewClass._withNodeFieldLabelAliasWalker    Procedure(ViewTreeType pNode, *CString pAlias, *Cstring pLabel)
x    long
obj  &DriverFileClass
  code
  Loop x = 1 to Records(pNode)
    Get(pNode,x)
    If pNode.File &= null then cycle.
    obj &= pNode.File{prop:object}
    If obj &= null then cycle.
    self.trace('pNode.Alias=' & pNode.Alias & ' pAlias=' & pAlias & ' plabel=' & plabel)
    If pNode.Alias = pAlias and obj._WithFieldNamed(plabel) = driver:ok
      self.node &= pNode
      Return driver:ok
    End
    If not pNode.children &= null
      If self._withNodeFieldLabelAliasWalker(pNode.children,pAlias,pLabel) = driver:ok
        Return Driver:ok
      End
    End
  End
  Return Driver:notok

!-----------------------------------------------------------------
! given a view field number pIndex, find the node that contains that number.
! self._FieldsOffset will be the number of fields in the nodes that preceed this node.
! self.FieldsFile will be set to the FILE handle of this node.
! returns driver:ok if the node is found, driver:not ok if not.
DriverViewClass._withNodeField            Procedure(Long pIndex)
  code
  self.FieldsFile &= null
  self._FieldsOffset = 0
  If pIndex < 0 then return driver:notok.
  If self._withNodeFieldWalker(self.tree,pIndex,0) = Driver:ok
    return Driver:ok
  End
  Return Driver:notok

!-----------------------------------------------------------------
DriverViewClass._withNodeFieldWalker    Procedure(ViewTreeType pNode, Long pIndex,Long pCounter)
x   long,Auto
nf  long
  code
  Loop x = 1 to Records(pNode)
    Get(pNode,x)
    If pNode.NumFields = 0 then self._ForceAutoProjectNow(pNode).
    If pCounter + pNode.NumFields < pIndex
      pCounter += pNode.NumFields
      If not pNode.children &= null
        If self._withNodeFieldWalker(pNode.children,pIndex,pCounter) = driver:ok
          Return Driver:ok
        End
      End
    Else
      self.node &= pNode
      self.FieldsFile &= pNode.File
      self._FieldsOffset = pCounter
      Return Driver:ok
    End
  End
  Return Driver:notok

!-----------------------------------------------------------------
! given a view field number pIndex, find the node that contains that number.
! self._FieldsOffset will be the number of fields in the nodes that preceed this node.
! self.FieldsFile will be set to the FILE handle of this node.
! returns driver:ok if the node is found, driver:not ok if not.
DriverViewClass._withNodeFile            Procedure(File pFile)
  code
  return self._withNodeFileWalker(self.tree,pFile)

!-----------------------------------------------------------------
DriverViewClass._withNodeFileWalker    Procedure(ViewTreeType pNode,File pFile)
x     long
  Code
  Loop x = 1 to Records(pNode)
    Get(pNode,x)
    If pNode.file &= pFile
      self.node &= pNode
      Return driver:ok
    End
    If not pNode.children &= null
      If self._withNodeFileWalker(pNode.children,pFile) = driver:ok
        Return driver:ok
      End
    End
  End
  Return Driver:notok

!-----------------------------------------------------------------
DriverViewClass._countNodes  Procedure(ViewTreeType pNode)
ans  long
x    long
  code
  if pNode &= null then return 0.
  Loop x = 1 to records(pNode)
    get(pNode,x)
    ans += self._countNodes(pNode.children)
  End
  Return Ans

!-----------------------------------------------------------------
DriverViewClass._TranslateYearSQL       Procedure(*CString pField)
obj   &DriverFileSQLClass
cstr  Cstring(DRIVER:MAXFIELDNAMELEN)
  code
  !self.trace('DriverViewClass._TranslateYearSQL pField=' & pField)
  If self._withNodeFieldLabelAlias(pField) = Driver:ok
    obj &= self.node.File{prop:object}
    If obj &= Null then Return ''.
    cstr = obj.fields.Column
    Return obj._TranslateYearSQL(cstr)
  End
  Return ''

!-----------------------------------------------------------------
DriverViewClass._TranslateMonthSQL       Procedure(*CString pField)
obj   &DriverFileSQLClass
cstr  Cstring(DRIVER:MAXFIELDNAMELEN)
  code
  self.trace('DriverViewClass._TranslateMonthSQL ' & pField )
  If self._withNodeFieldLabelAlias(pField) = Driver:ok
    self.trace('m1')
    obj &= self.node.File{prop:object}
    self.trace('m12')
    If obj &= Null then Return ''.
    cstr = obj.fields.Column
    self.trace('m3 ' & cstr & ' ' & obj._TranslateMonthSQL(cstr))
    Return obj._TranslateMonthSQL(cstr)
  End
  Return ''

!-----------------------------------------------------------------
DriverViewClass._TranslateDaySQL       Procedure(*CString pField)
obj   &DriverFileSQLClass
cstr  Cstring(DRIVER:MAXFIELDNAMELEN)
  code
  If self._withNodeFieldLabelAlias(pField) = Driver:ok
    obj &= self.node.File{prop:object}
    If obj &= Null then Return ''.
    cstr = obj.fields.Column
    Return obj._TranslateDaySQL(cstr)
  End
  Return ''

!-----------------------------------------------------------------
DriverViewClass._TranslateDateSQL       Procedure(*CString pField,String pMonth, String pDay, String pYear, Byte pLabelType,*Cstring pCond)
obj   &DriverFileSQLClass
cstr  Cstring(DRIVER:MAXFIELDNAMELEN)
  code
  If self._withNodeFieldLabelAlias(pField) = Driver:ok
    obj &= self.node.File{prop:object}
    If obj &= Null then Return ''.
    cstr = obj.fields.Column
    Return obj._TranslateDateSQL(pField,pMonth,pDay,pYear,pLabelType,pCond)
  End
  Return ''

!-----------------------------------------------------------------
DriverViewClass.GetProp:Alias  procedure(Long pFileNumber)
alias   cstring(DRIVER:MAXALIASLENGTH)
obj     &DriverFileClass,Auto
  code
  obj &= (self.FileObject[pFileNumber])
  If not obj &= null
    Alias = obj.GetPROP:Alias()
  End
  If Alias = '' then Alias = chr(pFileNumber+64).
  Return Alias

!-----------------------------------------------------------------
DriverViewClass.GetProp:AutoProject     Procedure(Long pIndex)
  Code
  If self._withNodeFileIndex(pIndex) = driver:ok
    If self.node.AutoProject then Return self.node.AutoProject.
  End
  Return ''

!-----------------------------------------------------------------
DriverViewClass.SetProp:AutoProject     Procedure(Long pIndex, Byte pValue)
x  Long
  Code
  If pIndex = 0
    Loop x = 1 to self.Files
      do SetNode
    End
  Else
    x = pIndex
    do SetNode
  End
  Return

SetNode  routine
  If self._withNodeFileIndex(pIndex) = driver:ok
    self.node.AutoProject = pValue
    Put(self.node)
  End

!-----------------------------------------------------------------
! returns the field number in a file for the specified field number in a VIEW.
! interestingly returns 0, not '' for bad values of pIndex.
DriverViewClass.GetProp:Field             Procedure(Long pIndex)
adj  long,Auto
  Code
  If pIndex <= 0 then return 0.
  If self._withNodeField(pIndex) = driver:ok
    adj = pIndex - self._FieldsOffset
    If self.node.NumFields = 0
      self._ForceAutoProjectNow(self.node) ! developer has called prop:field, but there are no fields in view. So forced to populate them all in now.
    End
    Return self.node.Field[adj]
  End
  Return 0

!-----------------------------------------------------------------
DriverViewClass.GetProp:Fields            Procedure(Long pIndex)
nf  Long,Auto
  Code
  self._CountFields()
  If pIndex = 0
    If self.fields then return self.fields else return ''.
  End
  If pIndex >= 1 and pIndex <= self.files and pIndex <= Maximum(self.FilePtr,1)
    If self._withNodeFileIndex(pIndex) = driver:ok
      If self.node.NumFields
        Return self.node.NumFields
      Else
        nf = self.node.File{prop:fields}
        If nf
          Return nf
        Else
          Return ''
        End
      End
    End
  End
  Return ''

!-----------------------------------------------------------------
DriverViewClass.GetProp:File              Procedure(Long pIndex)
  Code
  If pIndex >= 1 and pIndex <= self.files and pIndex <= Maximum(self.FilePtr,1)
    Return self.FilePtr[pIndex]
  End
  Return ''

!-----------------------------------------------------------------
DriverViewClass.GetProp:Files             Procedure(Long pIndex)
  Code
  If pIndex = 0
    If self.files then Return self.Files.
    Return ''
  End
  If self._withNodeField(pIndex) = driver:ok
    ! count number of joins down the tree from there.
    Return self._countNodes(self.Node)
  End
  Return ''

!-----------------------------------------------------------------
! interestingly returns 0, not '' for bad values of pIndex.
DriverViewClass.GetProp:FieldsFile        Procedure(Long pIndex)
  Code
  If self._withNodeField(pIndex) = driver:ok
    Return Address(self.FieldsFile)
  End
  Return 0

!-----------------------------------------------------------------
DriverViewClass.GetProp:Hint            Procedure(Long pIndex)
  Code
  If self._withNodeFileIndex(pIndex) = driver:ok
    If self.Node.hint then return self.Node.hint.
  End
  Return ''

!-----------------------------------------------------------------
DriverViewClass.SetProp:Hint            Procedure(Long pIndex, String pValue)
  Code
  If self._withNodeFileIndex(pIndex) = driver:ok
    self.Node.hint = pValue
    put(self.Node)
  End
  Return

!-----------------------------------------------------------------
DriverViewClass.GetProp:Inner            Procedure(Long pIndex)
  Code
  If self._withNodeFileIndex(pIndex) = driver:ok
    If self.Node.jointype then return self.Node.jointype.
  End
  Return ''

!-----------------------------------------------------------------
DriverViewClass.SetProp:Inner            Procedure(Long pIndex, Byte pValue)
  Code
  If self._withNodeFileIndex(pIndex) = driver:ok
    self.Node.jointype = pValue
    put(self.Node)
  End
  Return

!-----------------------------------------------------------------
DriverViewClass.GetProp:Name            Procedure(Long pIndex)
adj   long
  Code
  If self._withNodeField(pIndex) = driver:ok
    adj = pIndex - self._FieldsOffset
    if adj <= 0
      return ''
    End
    If self.Node.name[adj] then return self.Node.name[adj].
    If not self.node.File &= null
      Return self.node.File{prop:name,self.node.Field[adj]}
    End
  End
  Return ''

!-----------------------------------------------------------------
DriverViewClass.SetProp:Name            Procedure(Long pIndex,String pValue)
adj   long
  Code
  If self._withNodeField(pIndex) = driver:ok
    adj = pIndex - self._FieldsOffset
    self.Node.name[adj] = pValue
    put(self.Node)
  End
  Return

!-----------------------------------------------------------------
DriverViewClass.GetProp:NoKeyProject      Procedure(Long pIndex)
  Code
  If self.NoKeyProject then Return self.NoKeyProject.
  Return ''

!-----------------------------------------------------------------
DriverViewClass.SetProp:NoKeyProject      Procedure(Long pIndex, Byte pValue)
  Code
  self.NoKeyProject = pValue
  Return

!-----------------------------------------------------------------
DriverViewClass.GetProp:Object             Procedure()
  Code
  Return address(self)

!-----------------------------------------------------------------
DriverViewClass.SetProp:Object             Procedure(Long pAddress)
newObj &DriverViewClass
v      &view
  Code
  newObj &= (pAddress)
  v &= (self.ClaVCB)
  newObj.Init(v)
  Return

!-----------------------------------------------------------------
DriverViewClass.GetProp:OrderAllTables     PROCEDURE()
  code
  If self.OrderAllTables then return 1.
  return ''

!-----------------------------------------------------------------
DriverViewClass.SetProp:OrderAllTables     PROCEDURE(Byte pValue)
  code
  self.OrderAllTables = pValue
  return

!-----------------------------------------------------------------
DriverViewClass.GetProp:OrderInSelect     PROCEDURE()
  code
  If self.OrderInSelect then return self.OrderInSelect.
  Return ''

!-----------------------------------------------------------------
DriverViewClass.SetProp:OrderInSelect     PROCEDURE(Byte pValue)
  code
  self.OrderInSelect = pValue
  Return

!-----------------------------------------------------------------
DriverViewClass.GetProp:Project          PROCEDURE(Long pIndex)
  Code
  Return ''

!-----------------------------------------------------------------
DriverViewClass.GetProp:SQLJoinExpression           PROCEDURE(Long pIndex)
  Code
  If self._withNodeFileIndex(pIndex) = driver:ok
    If not self.Node.SqlJoinExpression &= null
      Return self.Node.SqlJoinExpression
    End
  End
  Return ''

!-----------------------------------------------------------------
DriverViewClass.SetPROP:SQLJoinExpression           PROCEDURE(Long pIndex,String pValue)
  Code
  If self._withNodeFileIndex(pIndex) = driver:ok
    If not self.Node.SqlJoinExpression &= null and size(self.Node.SqlJoinExpression) < len(clip(pValue))
      self.Node.SqlJoinExpression = pValue
    Else
      Dispose(self.Node.SqlJoinExpression)
      self.Node.SqlJoinExpression &= new Cstring(len(clip(pValue))+1)
      self.Node.SqlJoinExpression = pValue
    End
  End
  Return

!-----------------------------------------------------------------
DriverViewClass._FillOrderFromLabel              Procedure(String pLabel, Byte pCase)
column  cstring(255)
obj     &DriverFileClass
x       Long
i       Long
already Long
  code
  i = instring('.',pLabel,1,1)
  Loop x = 1 to self.Files
    obj &= (self.FileObject[x])
    If obj &= null then cycle.
    If obj._WithFieldLabeled(pLabel) = Driver:ok
      do FillFields
      Break
    ElsIf obj._WithFieldNamed(pLabel) = Driver:ok
      do FillFields
      Break
    elsif i > 1 and upper(pLabel[1:i-1]) = upper(self.GetProp:Alias(x))
      If obj._WithFieldNamed(sub(pLabel,i+1,255)) = Driver:ok
        do FillFields
        Break
      End
    elsif i > 1 and upper(pLabel[1:i-1]) = upper(obj.FullPathName)
      If obj._WithFieldNamed(sub(pLabel,i+1,255)) = Driver:ok
        do FillFields
        Break
      End
    End
  End
  Return already

FillFields  routine
  self.OrderQueue.FileIndex = x
  self.OrderQueue.FieldIndex = obj.Fields.index

  Get(self.OrderQueue,self.OrderQueue.FileIndex,self.OrderQueue.FieldIndex)
  If errorcode() = 0
    already = pointer(self.OrderQueue)
    exit
  End

  self.OrderQueue.Clause     = self.GetProp:Alias(x) & '.' & obj.Fields.Column
  Case obj.Fields.type
  of ClaCSTRING orof ClaPSTRING orof ClaSTRING
    If obj.fields.Binary
      self.OrderQueue.Nocase = false
    Else
      self.OrderQueue.Nocase = pCase
    End
  Else
    self.OrderQueue.Nocase = false
  End
  self.OrderQueue.IsCalc     = false

!-----------------------------------------------------------------
!-----------------------------------------------------------------

!=============================================================================
!  DriverViewSQLClass
!=============================================================================
DriverViewSQLClass.Construct          Procedure()
  Code
  self.JoinList &= new StringTheory
  Return

!-----------------------------------------------------------------
DriverViewSQLClass.Destruct           Procedure()
  Code
  Dispose(self.JoinList)
  Dispose(self._ProjectClauses)
  Return

!-----------------------------------------------------------------
DriverViewSQLClass.CheckConnect    PROCEDURE()
  Code
  Return False

!-----------------------------------------------------------------
DriverViewSQLClass.ClearProps  Procedure()
  code
  self._ClearDynamicProjects()
  self.JoinList.SetValue('')
  self.from = ''
  if not self._ProjectClauses &= null then self._ProjectClauses.SetValue('').
  parent.ClearProps()
  self._FreeParameterQueue()
  Return

!-----------------------------------------------------------------
DriverViewSQLClass.BuildProjectList          Procedure()
  code
  self._fieldcounter = 0
  self.ProjectList.SetValue('')
  self._BuildProjectListWalker(self.tree)
  ! all the fields have been done, now add the _ProjectClauses if there are any
  If not self._ProjectClauses &= NULL and self._ProjectClauses.length() > 0
    self.ProjectList.append(self._ProjectClauses.GetValue(),,',')
  End
  Return

!-----------------------------------------------------------------
DriverViewSQLClass._BuildProjectListWalker    Procedure(ViewTreeType pNode)
x         long
y         long
z         long
obj       &DriverFileSQLClass,auto
usename   cstring(256)
expr      cstring(256)
i         long
as        byte
count     long
OneFileProjectList  StringTheory
AllFields  byte
PutNode    byte
  code
  If pNode &= null then Return.
  Loop x = 1 to Records(pNode)
    Get(pNode,x)
    PutNode = false
    If pNode.File &= null
      obj &= null
    Else
      obj &= pNode.File{prop:object}
      Clear(obj._ProjectField,0)
      Clear(obj._ProjectBlobField,0)
    End
    OneFileProjectList.SetValue('')
    If pNode.NumFields = 0
      If Band(pNode.AutoProject,driver:ProjectFields) > 0
        ! auto-project all the fields in the record
        If Band(pNode.AutoProject,driver:ProjectFields) > 0
          allFields = true
          pNode.Dynamic = 1
          Loop y = 1 to obj.SharedProperties.FieldList.nodes
            If obj._withField(y) = driver:ok
              if obj.Fields.Type = ClaGROUP or obj.Fields.Over or obj.Fields.InOverGroup
                Cycle
              End
              useName = pNode.Alias & '.' & obj.Fields.Column
              self.ProjectList.append(usename,,',')
              pNode.NumFields += 1
              pNode.field[pNode.NumFields] = obj.Fields.Index
              obj._ProjectField()
            End
          End
        End
      End
      If Band(pNode.AutoProject,driver:ProjectBlobs)
        pNode.Dynamic = 1
        Loop y = 1 to Records(obj.Blobs)
          If obj._WithBlob(y)
            useName = pNode.Alias & '.' & obj.blobs.Column
            self.ProjectList.append(usename,,',')
            pNode.NumFields += 1
            pNode.field[pNode.NumFields] = obj.blobs.Index
            obj._ProjectBlob()
          End
        End
      End
      PutNode = true
    Else
      ! projected fields listed in the view structure, or added via ProjectField.
      Loop y = 1 to pNode.NumFields
        self._fieldcounter += 1
        as = false
        If pNode.name[y]
          i = Instring('|',pNode.name[y],1,1)
          If i
            usename = Clip(Left(Sub(pNode.Name[y],1,i-1)))
          Else
            usename = Clip(Left(pNode.name[y]))
          End
          i = Instring(' AS ',upper(usename),1,1)
          If i
            expr = Sub(usename,1,i-1)
            as = true
          Else
            expr = usename
          End
          self._ParseContext = driver:project
          OneFileProjectList.Append(usename,,',')  ! before alias added
          expr = self._tokenize(expr,driver:project)
          expr = self._ExpandExpression(expr) !,driver:project,count)
          If i
            usename = expr & Sub(usename,i,len(usename))
          Else
            usename = expr
          End
        Else
          useName = pNode.Alias & '.' & pNode.File{prop:column,pNode.Field[y]}
          OneFileProjectList.Append(pNode.File{prop:column,pNode.Field[y]},,',')
        End
        If (pNode.Driver = self.tree.driver or as = true) and usename <> ''
          self.ProjectList.append(usename,,',')
        End
      End
      If not obj &= null
        obj.SetProp:Project(OneFileProjectList.GetValue())
        obj.ParseProject()
      End
    End
    ! key fields are now added
    If self.Distinct or self.NotDistinct
      ! use of distinct or not distinct means no key fields are added
    Elsif allFields
      ! all fields are already included, so can skip this part
    Elsif obj &= null
      ! not an object, so skip this part
    Else
      self.ProjectList.split(',')
      case self.NoKeyProject
      of driver:ProjectAllKeys
        Loop z = 1 to records(obj.keys)
          If obj._WithKey(z) = Driver:ok
            do ProjectKey
          End
        End
      of driver:ProjectPrimaryKeys
        If obj._WithPrimaryKey() = Driver:ok
          do ProjectKey
        End
      End
    End
    If putnode
      Put(pNode)
    End
    If not pNode.children &= null
      self._BuildProjectListWalker(pNode.Children)
    End
  End
  Return

ProjectKey  Routine
  Loop y = 1 to obj.keys.components
    If obj._WithField(obj.keys.component[y]) = driver:ok
      usename = pNode.Alias & '.' & obj.Fields.Column
      If self.ProjectList.Inline(usename,1,1,0,st:noCase,st:wholeLine) = 0
        self.ProjectList.append(usename,,',')
        self.ProjectList.AddLine(usename)
        pNode.NumFields += 1
        pNode.Field[pNode.NumFields] = obj.keys.component[y]
        PutNode = true
      End
    End
  End

!-----------------------------------------------------------------
DriverViewClass._IsProjected     Procedure(ViewTreeType pNode,Long pIndex)
i  long
  code
  loop i = 1 to pNode.NumFields
    if pNode.Field[i] = pIndex then Return i.
  end
  Return 0

!-----------------------------------------------------------------
DriverViewClass._ProjectField     Procedure(ViewTreeType pNode,Long pIndex,String pExpression)
obj    &DriverFileClass
i      Long
  code
  If not self.node.File &= null
    obj &= self.node.file{prop:object}
    i = self._IsProjected(self.node,pIndex)
  End
  If i = 0
    self.node.NumFields += 1
    i = self.node.NumFields
    self.node.field[self.node.NumFields] = pIndex
    If pExpression <> ''
      self.Node.name[self.node.NumFields] = clip(pExpression)
    End
    If self.node.Dynamic = 0 then self.node.Dynamic = self.node.NumFields .
    Put(self.node)
  ElsIf pExpression <> ''
    self.Node.name[self.node.NumFields] = clip(pExpression)
    Put(self.node)
  End
  self._CountFields()
  Return i

!-----------------------------------------------------------------
DriverViewSQLClass.ProjectField              Procedure(String pExpression,String pAs)
obj    &DriverFileClass
expr   StringTheory
i      Long
count  Long
  Code
  If pAs = ''
    ! check to see if the pExpression is really just a single field name.
    If self._withNodeFieldLabel(pExpression) = Driver:ok
      obj &= self.node.file{prop:object}
      self._ProjectField(self.node,obj.Fields.index,'')
      Return
    End
  Else
    ! check to see if AS is a field label. If so make sure that's projected, and set the name to the expression
    If self._withNodeFieldLabel(pAs) = Driver:ok
      obj &= self.node.file{prop:object}
      i = self._ProjectField(self.node,obj.Fields.index,pExpression)
      If i
        !self.Node.name[i] = pExpression    !!!todo set expression
        !Put(self.node)
      End
      Return
    End
  End
  If self._ProjectClauses &= null
    self._ProjectClauses &= new StringTheory
  end
  If pAs
    self.ParseProperty(clip(pExpression) & ' AS ' & upper(clip(pAs)), driver:project,self.TokenStr)
    Expr.SetValue(self._ExpandExpression(self.TokenStr.GetValue()))
    If self._ProjectClauses.Instring(Expr.GetValue()) = 0
      self._ProjectClauses.Append(Expr.GetValue(),,',')
    End
  End
  self._CountFields()
  Return

!-----------------------------------------------------------------
DriverViewSQLClass.ProjectField              Procedure(File pFile,Long pIndex)
  Code
  If self._withNodeFile(pFile) = Driver:ok
    self.node.NumFields += 1
    If self.node.Dynamic = 0 then self.node.Dynamic = self.node.NumFields .
    self.node.Field[self.node.NumFields] = pIndex
    Put(self.node)
  End
  self._CountFields()
  Return

!-----------------------------------------------------------------
DriverViewSQLClass.ProjectField              Procedure(*? pField)
  code
  If self._ProjectFieldWalker(self.Tree,pfield).
  self._CountFields()
  Return

!-----------------------------------------------------------------
DriverViewSQLClass._ProjectFieldWalker        Procedure(ViewTreeType pNode,*? pField)
x       long
obj     &DriverFileClass
ptr     long
offset  long
  code
  peek(address(pfield)+4,ptr)
  Loop x = 1 to Records(pNode)
    Get(pNode,x)
    If pNode.File &= null then Cycle.
    obj &= pNode.File{prop:object}
    If ptr >= obj.ClaFCB.rec_buf and ptr <= obj.ClaFCB.rec_buf + obj.ClaFCB.rec_len
      offset = ptr - obj.ClaFCB.rec_buf
      If obj._WithFieldOffset(offset,0) = driver:ok
        pNode.NumFields += 1
        If pNode.Dynamic = 0 then pNode.Dynamic = pNode.NumFields .
        pnode.Field[pNode.NumFields] = obj.Fields.Index
        Put(pNode)
        Return driver:ok
      End
    End
    If Not pNode.Children &= null
      If self._ProjectFieldWalker(pNode.children,pField) = driver:ok
        Return Driver:ok
      End
    End
  End
  Return Driver:notok

!-----------------------------------------------------------------
! removes all dynamic PROJECT fields from a View Tree. ie returns it to "compiled" state.
DriverViewSQLClass._ClearDynamicProjects  Procedure()
  code
  self._ClearDynamicProjectsWalker(self.Tree)
  self._CountFields()
  Return

!-----------------------------------------------------------------
DriverViewSQLClass._ClearDynamicProjectsWalker  Procedure(ViewTreeType pNode)
x  long
  code
  Loop x = 1 to Records(pNode)
    Get(pNode,x)
    if pNode.Dynamic
      pNode.NumFields = pNode.Dynamic -1
      pNode.Dynamic = 0
      Put(pNode)
    End
    If Not pNode.Children &= null
      self._ClearDynamicProjectsWalker(pNode.children)
    End
  End
  Return

!-----------------------------------------------------------------
DriverViewSQLClass.BuildFrom            Procedure()
  code
  self.from = name(self.tree.File) & ' ' & self.tree.Alias
  Return

!-----------------------------------------------------------------
DriverViewSQLClass.BuildJoinList          Procedure()
  code
  self.joinlist.setvalue('')
  self._BuildJoinListWalker(self.Tree.children, self.tree.alias)
  Return

!-----------------------------------------------------------------
DriverViewSQLClass._BuildJoinListWalker    Procedure(ViewTreeType pNode, String pParentAlias)
x     long
y     long
f     long
  Code
  If pNode &= null then return.
  Loop x = 1 to Records(pNode)
    Get(pNode,x)
    If pNode.Driver <> self.tree.driver and pNode.Driver <> '' then cycle.
    Case pNode.jointype
    Of driver:innerjoin     !  Equate(1)
      self.joinlist.append('INNER JOIN ')
    Of driver:rightjoin     !  Equate(2)
      self.joinlist.append('RIGHT JOIN ')
    Of driver:fulljoin      !  Equate(3)
      self.joinlist.append('FULL JOIN ')
    Of driver:crossjoin     !  Equate(4)
      self.joinlist.append('CROSS JOIN ')
    Of driver:selfjoin      !  Equate(5)
      self.joinlist.append('SELF JOIN ')
    Else !of driver:leftjoin      !  Equate(0)
      self.joinlist.append('LEFT JOIN ')
    End
    If not pNode.file &= null
      self.joinlist.append(name(pNode.file) & ' ' & self.TranslateJoinHint(pnode.hint) & pnode.alias & ' ON ')
    Elsif not pNode.tablename = ''
      self.joinlist.append(pNode.tablename & ' ' & self.TranslateJoinHint(pnode.hint) & pnode.alias & ' ON ')
    Else
      self.SetError(BadJoinFileError)
      Return
    End

    If not pNode.SqlJoinExpression &= null and pNode.SqlJoinExpression <> '' and sub(pNode.SqlJoinExpression,1,1) <> '+'
      self.joinlist.Append(pNode.SqlJoinExpression & ' ')
    Else
      If not pNode.key &= Null
        ! loop through key fields and match up to linking fields
        Loop y = 1 to pnode.numLinkingFields
          f = pNode.key{prop:field,y}
          if y > 1 then self.joinlist.append(' AND ').
          self.joinlist.Append(pNode.alias & '.' & pNode.file{prop:column,f} & '=' & pParentAlias & '.' & pNode.parentFile{prop:column,pNode.LinkingField[y]} & ' ')
        End
      ElsIf not pNode.LinkingExpr &= null and not pNode.LinkingExpr = ''
        If self.ParseProperty(pNode.LinkingExpr,driver:join,self.TokenStr) = driver:ok
          self.joinlist.Append(self._ExpandExpression(self.TokenStr.GetValue()) & ' ')
        End
      End
      If not pNode.SqlJoinExpression &= null and pNode.SqlJoinExpression <> '' and sub(pNode.SqlJoinExpression,1,1) = '+'
        self.joinlist.Append(sub(pNode.SqlJoinExpression,2,len(pNode.SqlJoinExpression)) & ' ' )
      End
    End
    If not pNode.children &= null
      self._BuildJoinListWalker(pNode.Children,pNode.Alias)
    End
  End
  Return

!-----------------------------------------------------------------
! Some databases support a hint statement (like USE INDEX or WITH INDEX or whatever
! Some databases do their hinting after the select; use the .TranslateSelectHint method for those.
! If deriving, and the hint exists, must have a trailing space
!!! DERIVE if supporting JOIN statement hints
DriverViewSQLClass.TranslateJoinHint       Procedure(String pHint)
  code
  return ''

!-----------------------------------------------------------------
! Some databases support a hint statement as a comment after SELECT
! Some databases do their hinting after the Join; use the .TranslateJoinHint method for those.
! If deriving, and the hint exists, must have a trailing space
!!! DERIVE if supporting SELECT statement hints
DriverViewSQLClass.TranslateSelectHint     Procedure(String pHint)
  code
  return ''

!-----------------------------------------------------------------
DriverViewSQLClass.TranslateLimitAbove     Procedure(Long pLimit, String pOffset)
  code
  return ''
!-----------------------------------------------------------------
DriverViewSQLClass.TranslateLimitBelow     Procedure(Long pLimit, String pOffset)
  code
  !self.trace('DriverViewSQLClass.TranslateLimitBelow pLimit=' & pLimit & ' pOffset=' & pOffset)
  If pLimit = 0 and (pOffset = '' or pOffset ='0')
    Return ''
  End
  If pLimit = 0 then pLimit = -1.
  If pOffset and pOffset <> '0'
    Return 'LIMIT ' & pLimit & ' OFFSET ' & clip(pOffset) & ' '
  Else
    Return 'LIMIT ' & pLimit & ' '
  End

!-----------------------------------------------------------------
DriverViewSQLClass.BuildOrderBy            Procedure()
  code
  parent.BuildOrderBy()                                    ! Clear the Queue
  If self._SearchOrderClause
    Clear(self.OrderQueue)
    self.OrderQueue.Clause = self._SearchOrderClause
    Add(self.OrderQueue)
  End
  self.BuildOrderByProps()                                 ! prop:order and prop:SqlOrder
  If self.GroupBy &= null or self.groupBy = ''
    If self.NoKeyProject <> driver:ProjectNoKeys
      self.BuildOrderByUnique()                            ! As long as the primary keys are being projected, they can be added in here
    End
  End
  self.SetOrderByFromQueue()                               ! This takes the OrderBy queue as input, and generates the prop:OrderBy as output
  Return

!-----------------------------------------------------------------
!!! derive
DriverViewSQLClass.SetOrderByFromQueue            Procedure()
  code
! Need to make the OrderBy unique. In the VIEW case this means always adding any primary key fields that don't exist in the order.
! This is desired, even in cases where it's readonly or paging is false, because the same code should always generate the records
! in the same order. You don't want the same report coming out in different orders, just because the Order clause is not
! exhaustive enough.
! Only many:1 relations need to be added here, so if ADDRELATION has been used this can improve performance.
!-----------------------------------------------------------------


!-----------------------------------------------------------------
DriverViewSQLClass.BuildOrderByUnique          Procedure()
  code
  self._BuildOrderByUniqueWalker(self.Tree)
  Return

!-----------------------------------------------------------------
! make sure each many to one child file in the view has sufficient fields in the order to make it unique.
DriverViewSQLClass._BuildOrderByUniqueWalker    Procedure(ViewTreeType pNode)
k       long,Auto
x       long,Auto
y       long,Auto
obj     &DriverFileClass
CheckCase    Byte,Auto
UniqueFound  Byte,Auto
Suggest      Long,Auto
Missing      Long,Auto
  Code
  If pNode &= null then return.
  Loop x = 1 to Records(pNode)
    Get(pNode,x)
    If pNode.Driver <> self.tree.driver and pNode.Driver <> '' then cycle.

    ! if it's a one-to-many relationship then cycle. It's a lookup, not a set of child records.
    case pNode.Relation
    of driver:one
      cycle  ! this is a one-to-many relation to the parent, so doesn't need to be in the order.
    End
    ! if it's not a FILE then cycle.
    obj &= pNode.File{prop:object}
    If obj &= null then cycle.

    ! loop through the unique keys and see if all the fields are already there.
    suggest = 0
    Loop k = 1 to Records(obj.keys)
      Get(obj.keys,k)
      If obj.keys.dup = true then cycle.                   ! only looking through unique keys here
      If obj.keys.opt = true then cycle.                   ! avoid exclude null keys
      UniqueFound = true
      Missing = 1
      Loop y = 1 to obj.keys.components
        checkcase = false
        If obj._WithField(obj.keys.component[y]) = Driver:ok
          case obj.Fields.Type
          of ClaString orof ClaCSTRING orof ClaPSTRING
            checkcase = true
          End
        End
        self.OrderQueue.FileIndex = pNode.Index
        self.OrderQueue.FieldIndex = obj.keys.component[y]
        Get(self.OrderQueue,self.OrderQueue.FileIndex,self.OrderQueue.FieldIndex)
        If ErrorCode() or (checkcase = true and  obj.keys.nocase <> self.OrderQueue.Nocase)
          UniqueFound = false
          If y > 1 and errorcode()
            suggest = k
            missing = y
          End
          break
        End
      End
      If UniqueFound = true then break.
    End
    If not UniqueFound
      If Suggest
        If obj._withKey(Suggest) = Driver:ok
          Loop y = missing to obj.keys.components
            self.OrderQueue.FileIndex = pNode.Index
            self.OrderQueue.FieldIndex = obj.keys.component[y]
            Get(self.OrderQueue,self.OrderQueue.FileIndex,self.OrderQueue.FieldIndex)
            If ErrorCode()
              do addToOrderQueue
            End
          End
        End
      Else
        If obj._withPrimaryKey() = Driver:ok
          Loop y = 1 to obj.keys.components
            self.OrderQueue.FileIndex = pNode.Index
            self.OrderQueue.FieldIndex = obj.keys.component[y]
            Get(self.OrderQueue,self.OrderQueue.FileIndex,self.OrderQueue.FieldIndex)
            If ErrorCode()
              do AddToOrderQueue
            End
          End
        End
      End
    End
    If not pNode.children &= null
      self._BuildOrderByUniqueWalker(pNode.Children)
    End
  End
  Return

addToOrderQueue  routine
  Clear(self.OrderQueue)
  If obj._WithField(obj.keys.component[y]) = Driver:ok
    self.OrderQueue.Clause = self.GetProp:Alias(pNode.Index) & '.' & obj.Fields.Column
    Case obj.Fields.Type
    of ClaSTRING
    orof ClaCSTRING
    orof ClaPSTRING
      If obj.fields.binary
        self.OrderQueue.Nocase     = false
      Else
        self.OrderQueue.Nocase     = obj.keys.Nocase
      End
    End
    self.OrderQueue.IsCalc     = false
    self.OrderQueue.FileIndex  = pNode.Index
    self.OrderQueue.FieldIndex = obj.keys.component[y]
    If obj.keys.descending[y]
      self.OrderQueue.Direction   = driver:Descending
    End
    Add(self.OrderQueue)
  End
  Exit

DriverViewSQLClass.BuildOrderByUniqueXX      Procedure()
key     &key
y       long
x       long
fil     long
obj     &DriverFileClass

  Code
  Loop fil = 1 to self.Files
    obj &= (self.FileObject[fil])
    if obj &= null then cycle.
    If obj._withPrimaryKey() = Driver:ok
      Loop y = 1 to obj.keys.components
        self.OrderQueue.FileIndex = fil
        self.OrderQueue.FieldIndex = obj.keys.component[y]
        Get(self.OrderQueue,self.OrderQueue.FileIndex,self.OrderQueue.FieldIndex)
        If errorcode()
          do addToOrderQueue
        End
      End
    End
  End
  Return

addToOrderQueue  routine
  Clear(self.OrderQueue)
  If obj._WithField(obj.keys.component[y]) = Driver:ok
    self.OrderQueue.Clause     = self.GetProp:Alias(fil) & '.' & obj.Fields.Column
    Case obj.Fields.Type
    of ClaSTRING
    orof ClaCSTRING
    orof ClaPSTRING
      If obj.fields.binary
        self.OrderQueue.Nocase     = false
      Else
        self.OrderQueue.Nocase     = obj.keys.Nocase
      End
    End
    self.OrderQueue.IsCalc     = false
    self.OrderQueue.FileIndex  = fil
    self.OrderQueue.FieldIndex = obj.keys.component[y]
    If obj.keys.descending[y]
      self.OrderQueue.Direction   = driver:Descending
    End
    Add(self.OrderQueue)
  End
  Exit

!-----------------------------------------------------------------
!!!todo need to turn BINDed variables into parameters.
DriverViewSQLClass.TranslateLabel       Procedure(*cstring pValue,*byte pReturnType)
i      long
ans    long
  code
  ! lookup variable name in view tables, and replace. Note that it's not necessarily PROJECTed.
  ! If the variable is not in a table, then EVALUATE it and turn it into a fixed value.

  ! the incoming value is of the form
  ! a) Clarion Label (cus:address)          ! translate this to alias.columnname
  ! b) SQL table.column (customer.address)  ! translate this to alias.columnname
  ! c) a.address                            ! leave this as is

  If self.TranslateConstant(pValue,i) = Driver:Ok
    pReturnType = driver:constant
    Return i
  End
  i = instring(':',pValue,1,1)
  If i
    ! Clarion Label.
    Return self.TranslateFieldClarion(pValue)
  else
    i = instring('.',pValue,1,1)
    If i = 0  ! no colon or . - it's just a word, assume this is a bounded local variable?
      Return self.TranslateVariable(pValue)
    ElsIf i <= 3 ! assume tablename.columnname
      Return self.TranslateFieldSQL(pValue)
    else
      ! Assume it's already an alias and leave it alone.
    End
  End
  Return pValue

!-----------------------------------------------------------------
! this is expected to be a file field, however if it's not one of the files in the view
! then it's passed onto TranslateVariableLocal
DriverViewSQLClass.TranslateFieldClarion   Procedure(*cstring pValue)
obj   &DriverFileClass
x     Long
  code
  Loop x = 1 to self.Files
    obj &= (self.FileObject[x])
    If obj &= null then cycle.
    If obj._WithFieldLabeled(pValue) = Driver:ok
      Return self.GetProp:Alias(x) & '.' & obj.Fields.Column
    End
  End
  Return self.TranslateVariable(pValue)

!-----------------------------------------------------------------
! this may have the form table.column. It has to be translated to alias.column
DriverViewSQLClass.TranslateFieldSQL       Procedure(*cstring pValue)
obj   &DriverFileClass
x     Long
i     Long
j     Long
n     cstring(100)
fpn   cstring(100)
  code
  i = instring('.',pValue,1,1)
  If i < 2 then return false.
  n = upper(sub(pValue,1,i-1))

  Loop x = 1 to self.Files
    obj &= (self.FileObject[x])
    If obj &= null then cycle.
    fpn = upper(obj.FullPathName)
    Loop
      j = instring('.',fpn,1,1)
      if j = 0 then break.
      fpn = sub(fpn,j+1,100)
    End
    If n = fpn
      Return self.GetProp:Alias(x) & '.' & sub(pValue,i+1,255)
    End
  End
  Return pValue

!-----------------------------------------------------------------
DriverViewSQLClass._ClearOrderFieldsInShadowBuffer  Procedure(Long pOpcode)
x       Long
obj     &DriverFileSQLClass
  code
  Loop x = 1 to Records(self.OrderQueue)
    Get(self.OrderQueue,x)
    If self.OrderQueue.FileIndex
      obj &= (self.FileObject[self.OrderQueue.FileIndex])
      obj._ClearOrderFieldInShadowBuffer(pOpCode, self.OrderQueue.Direction,self.Orderqueue.FieldIndex)
    End
  End
  Return

!-----------------------------------------------------------------
DriverViewSQLClass.NEXT             PROCEDURE()
  Code
  self.SetError(NoError)
  Parent.Next()
  If Errorcode() then Return.
  self._NextPrevious(Opcode:NEXT)
  If self._logData then self.LogBuffer().
  Return

!-----------------------------------------------------------------
!!! Derive
DriverViewSQLClass._BindOffset      Procedure()
  Code

!-----------------------------------------------------------------
!!! Derive
DriverViewSQLClass._ExecuteSelect     PROCEDURE()
  Code

!-----------------------------------------------------------------
DriverViewSQLClass.PREVIOUS             PROCEDURE()
  code
  self.SetError(NoError)
  Parent.Previous()
  If Errorcode() then Return.
  self._NextPrevious(Opcode:PREVIOUS)
  If self._logData then self.LogBuffer().
  Return

!-----------------------------------------------------------------
DriverViewSQLClass._NextPrevious        Procedure(Long pOpcode)
x                   Long,Auto
rows                Long,Auto
savResultRow        Long,Auto
reverse             Byte
ShadowBufferPrimed  Byte

  Code
  !self.trace('DriverViewSQLClass._NextPrevious pOpcode=' & pOpcode & ' _setdirection=' &  self._setdirection & ' _justset=' & self._justset & ' _JustReset=' & self._JustReset & ' ResultRow=' & self.ResultRow & ' explain=' & self.explain )

  self.SetError(NoError)
  self._ParameterOpcode = Opcode:SET

  ! if the current row is in the result set, and the next or previous row is in the result set, then we can just return that row.
  ! no need to do anything hasty, like doing a _set, yet.

  ! If just reset to a row in the result set, then the next PREVIOUS or NEXT simply returns that row.
  If self._justReset = driver:ResetToBufferRow
    self.ResultToRecords(self.ResultRow,driver:buffer)  ! Reset has pointed us to a current row in the result set, and the OPCode should return that row.
    self._JustReset = false
    !self.trace('-=-= nextprev done - Quick reread of result row after RESET - ' & self.ResultRow)
    Return
  End
  Loop x = 1 to 2 ! the second pass through here is if a new page of records was loaded.
    rows = self.Result.Rows()
    ! If doing a PREVIOUS or NEXT, and the next row is in the result set, then just read it from there.
    savResultRow = self.ResultRow
    !self.trace('top of loop pOpcode=' & pOpcode & ' self._setdirection=' & self._setdirection & ' self.ResultRow=' & self.ResultRow  & ' rows=' & rows)
    Case pOpcode
    Of Opcode:NEXT
      If self._setdirection = Opcode:NEXT then self.ResultRow += 1 Else self.ResultRow -= 1 .
      If self.ResultRow >= 1 and self.ResultRow <= rows
        self.ResultToRecords(self.ResultRow,driver:buffer)
        !self.trace('-=-= nextprev done - Quick read of next row in result set ' & self.ResultRow)
        Return
      End
    Of Opcode:PREVIOUS
      If self._setdirection = Opcode:PREVIOUS then self.ResultRow += 1 Else self.ResultRow -= 1 .
      If self.ResultRow >= 1 and self.ResultRow <= rows
        self.ResultToRecords(self.ResultRow,driver:buffer)
        !self.trace('-=-= nextprev done - Quick read of previous row in result set ' & self.ResultRow)
        Return
      End
    End
    self.ResultRow = savResultRow
    ! Only expecting this block to be possible on the first pass through the loop.
    If self._setdirection <> pOpcode   ! The direction may have changed, or this may be the first call after the SET.
      ASSERT(x=1,'_SetDirection Unexpected on second pass through loop')
      !self.trace('Doing a _set here because direction has changed')
      !self.trace('was rows = ' & rows & ' limit=' & self.limit & ' self.ResultRow=' & self.ResultRow & ' self._JustReset=' & self._JustReset)
      ! about to do a _set, which will clear the result set. But if we're paging we need the last record to work from
      If rows and self._justSet = false
        case pOpcode
        of Opcode:PREVIOUS                                    ! were going forward, now going backward
          self.ResultToRecords(1,driver:shadow)               ! Prime the Shadow buffer with the first record in the last result
          ShadowBufferPrimed = true
          self._SetOffset = 1
        of Opcode:NEXT                                        ! was going backward, now going forward.
          self.ResultToRecords(1,driver:shadow)            ! Prime the Shadow buffer with the last result ???
          ShadowBufferPrimed = true
          self._SetOffset = 1
        End
      End
      self._Set(pOpcode)
    End
    ! first check results to see if a row is waiting there.
    rows = self.Result.Rows()
    !self.trace('nextprevious: rows = ' & rows & ' limit=' & self.limit & ' self.ResultRow=' & self.ResultRow & ' self._JustReset=' & self._JustReset & ' ShadowBufferPrimed=' & ShadowBufferPrimed & ' self._HasBeenSetFromFile=' & self._HasBeenSetFromFile)
    If self._JustReset = driver:ResetToBufferRow
      self.ResultToRecords(self.ResultRow,driver:buffer)  ! Reset has pointed us to a current row in the result set, and the OPCode should return that row.
      self._JustReset = false
      Break
    ElsIf self._justset
      rows = 0
      If self.Explain or self.opt:explain or self._logExplain
        self._Explain = true
        self._Set(pOpcode)
        self._executeSelect()
        self.ResultToExplain(self.result)
        self._Explain = false
        self._Set(pOpcode)
      End
    ElsIf rows > self.ResultRow and self.ResultRow > 0
      ! next record is already in the result set, so just get it from there. Need this here in case this is the 2nd pass through the loop.
      self.ResultRow += 1
      self.ResultToRecords(self.ResultRow,driver:buffer)
      Break
    Elsif rows and (self.Limit or self.Paging = false or self._Paging = false or self._OrderHasCalc = true)
      ! limit is set, so whole result is here, so trigger a end-of-file
      self.ResultRow = 0
      Self.SetError(BadRecErr)
      Break
    End
    ! If not trigger the stmt to get the next set of rows.
    ! prime the record with the last row in the last result set, or clear the record
    !self.trace('rows=' & rows)
    If rows
      !self.trace('prime shadow buffer with last row in result set rows=' & rows & ' opcode=' & pOpcode)
      self.ResultToRecords(rows,driver:shadow)            ! Prime the Shadow buffer with the last result
      self._SetOffset = 1
    !ElsIf self._JustReset = driver:ShadowBufferPrimed     ! The Shadow buffers are already primed from the Reset command.
    ElsIf self._HasBeenSetFromFile = driver:ShadowBufferPrimed
      self._HasBeenSetFromFile = 0
    ElsIf ShadowBufferPrimed
    ElsIf self._JustReset = driver:BufferPrimed     ! The buffers are already primed from the Reset command.
    Else ! first time in.
      self._ClearOrderFieldsInShadowBuffer(pOpcode)
    End
    self._justSet = false
    self._justReset = false
    !self.trace('DriverViewSQLClass Getting next page self._SetOffset=' & self._SetOffset & ' err=' & errorcode())
    self._executeSelect()                            ! will prepareSelect based on the shadow buffer
    self._SetPropsCache = self._PropsCache
    ! if there are results loop back
    !self.trace('Loaded rows = ' & self.Result.Rows())
    !self.SqlCode.Trace()
    If self.Result.Rows()
      self.ResultRow  = 0
      cycle
    End
    ! if not trigger an end-of-file
    Self.SetError(BadRecErr)
    Break
  End
  !self.trace('-=-= nextprev done with error set to ' & errorcode())
  Return

!-----------------------------------------------------------------
DriverViewSqlClass.Put           Procedure()
obj       &File
x         Long
  code
  self.sqlcode.SetValue('')
  Loop x = 1 to self.Files
    obj &= (self.FilePtr[x])
    If obj &= null then cycle.
    obj{prop:FastWrite} = true
    !obj{prop:project} = self.GetProp:Project(x)
    Put(obj)
    obj{prop:FastWrite} = false
    self.sqlcode.append(obj{prop:Sql})
    self.Affected = obj{prop:Affected}
    self.ChildrenAffected = obj{prop:ChildrenAffected}
  End
  If self._logData then self.LogBuffer().
  Return

!-----------------------------------------------------------------
DriverViewSQLClass.RECORDS                   Procedure()
  Code
  Return self.Records(0)

!-----------------------------------------------------------------
DriverViewSQLClass.RECORDS                   Procedure(Long pIndex)
Ans  BIGINT
Opn  Long
Sd   Long
p    Byte
  Code
  If self._CheckOpen() = false then Return 0.
  self.SetError(NoError)
  p = self.Paging
  self.Paging = false
  self._ParameterOpcode = Opcode:RECORDS
  self._ClearParameterQueue(Opcode:RECORDS)
  self._ParameterCount = 0
  If self.Distinct or self.Limit or self.Offset or pIndex
    !!! todo, could optimize this list a bit - only need one field from every table to do the count.
    self.BuildProjectList()
  End
  If Errorcode() then Return Ans.
  self.BuildFrom()
  If Errorcode() then Return Ans.
  self.BuildJoinList()                     ! parameters in here
  If Errorcode() then Return Ans.

  ! this is a count, at first glance orderBy has no meaning.
  ! But it is necessary because OFFSET and LIMIT are in play, and these require a unique sort order.
  ! It's also in play if the index is set. Since the Index is based on the Order.
  !-- OrderBy                          ! this is a count, orderBy has no meaning. But it is necessary because OFFSET and LIMIT are in play, and these require a unique sort order.
  If pIndex or self.Limit or self.Offset
    Self.BuildOrderBy()                  ! set self.orderby
    If Errorcode() then Return Ans.
  else
    Free(self.OrderQueue)
    self._OrderHasCalc = false
    If not self.OrderBy &= null then self.OrderBy = ''.
  End
  ! -- where
  self.SetProp:Where('')
  Self.BuildWhere()                    ! WherePage is dependent on OrderBy, so must come after that. Sets prop:Where   ! parameters in here
  If Errorcode() then Return Ans.
  If pIndex
    sd = self._setdirection
    self._setdirection = Opcode:Next
    Self._PrependFixedToWhere(pIndex)   ! Add fixed fields to front of Where if SET(View,Number) form is used.
    self._setdirection = sd
  End

  If Errorcode() then Return Ans.
  ! -- GroupBy
  Self.BuildGroupBy()
  If Errorcode() then Return Ans.

  ! -- Having
  Self.BuildHaving()
  If Errorcode() then Return Ans.
  opn = self._OffsetParmNumber
  self.SqlCode.SetValue(self._GenerateRecordsSelect(pIndex))
  !self.SqlCode.trace()
  If self._executeSql() = driver:ok
    Ans = self.Result.GetCell(1,1)
  End
  self._OffsetParmNumber = opn
  self.Paging = p
  Return Ans

!-----------------------------------------------------------------
! Resets to the record identified by the string that was returned by the POSITION procedure.
! Once RESET has restored the record pointer, either NEXT or PREVIOUS will read that record.
DriverViewSQLClass.RESET                     Procedure(String pPosition)
hash  String(16),Auto
  code
  ! resetting on position. But possibly resetting into current result set. If so can avoid a request to the backend.
  parent.Reset(pPosition)                         ! populates pPosition primary key fields into buffers for all tables
  If self._SetPropsCache = self._PropsCache
    self._justReset = driver:ResetToBufferRow
    hash = self.TempStr.MD5(st:EncNone,pPosition,self._PosLen )
    self.ResultRow = self.Result.GetRowWithPosition(hash)
    If self.ResultRow then Return.
  End
  Self.Reset()
  Return

!-----------------------------------------------------------------
! Resets to the current file record buffer
! Once RESET has restored the record pointer, either NEXT or PREVIOUS will read that record.
DriverViewSQLClass.RESET                     Procedure()
obj     &DriverFileClass,auto
x       Long,Auto
  code
  Self.NewResultSet(driver:DontFreeRam)           ! This will force the next or previous to get the next page.
  self._setdirection = 0                          ! force generation of a new SELECT statement, because things like Prop:Order and Prop:Filter may have changed
  self._justReset = driver:BufferPrimed
  self._SetOffset = 0
  ! do a GET on each file, but into the shadow buffer
  Loop x = 1 to self.Files
    obj &= (self.FileObject[x])
    If obj &= null then cycle.
    obj._GetBuffer = driver:shadow
    obj.Get(obj.primarykey)
    obj._GetBuffer = driver:buffer
  End
  Return

!-----------------------------------------------------------------
DriverViewSQLClass.SET                       Procedure(Long pIndex)
  code
  self._ParameterOpcode = Opcode:SET
  self._ClearParameterQueue(self._ParameterOpcode)
  parent.Set(pIndex)
  self._SetOffset = 0
  If Errorcode() <> NoError then Return.
  self._ViewFixedFields = pIndex
  self._setdirection = 0
  self._justset = true
  Return

!-----------------------------------------------------------------
DriverViewSQLClass.AddFixedToOrderBy          Procedure()
vff long
  code
!-----------------------------------------------------------------
DriverViewSQLClass._SET                       Procedure(Long pOpcode)
  code
  self._setdirection = pOpcode
  self._ParameterOpcode = Opcode:SET
  self._ClearParameterQueue(Opcode:Set)
  self.NewResultSet(driver:DontFreeRam)
  !!!todo make a list of the fields in the group by. Only these fields can be projected UNLESS the field has been aggregated in prop:name or prop:project
  If self._justset
    ! all non-aggregated selected columns to be included in the GROUP BY clause. In other words fields that are not aggregated
    ! and not in the GroupBy cannot be projected.
    self.BuildProjectList()
    If Errorcode()  then Return.
    self.BuildFrom()
    If Errorcode()  then Return.
  End
  ! join list can contain parameters
  !!!todo maybe figure out an optimize for this if it doesn't, so then it can be called in the SET above.
  self.BuildJoinList()                     ! parameters in here
  If Errorcode()  then Return.
  self.BuildMap()

  If self._ViewFixedFields
    self.AddFixedToOrderBy()
  End

  !-- OrderBy
  Self.BuildOrderBy()                  ! set self.orderby
  If Errorcode()  then Return.
  ! -- where
  self.SetProp:Where('')
  Self.BuildWhere()                    ! WherePage is dependent on OrderBy, so must come after that. Sets prop:Where   ! parameters in here
  If Errorcode()  then Return.
  If self._ViewFixedFields
    Self._PrependFixedToWhere(self._ViewFixedFields)   ! Add fixed fields to front of Where if SET(View,Number) form is used.
  End
  If Errorcode() <> NoError then Return.
  self._pagingfieldsadded = false
  If self.Limit = 0 and self.Paging = true and self._OrderHasCalc = false
    self._OrderParmNumber = self._ParameterCount
    self._AppendOrderQueueToWhere(self._ParameterCount)     ! Add the OrderBy fields to the where clause to create WherePage  ! parameters in here
  else
    self.setProp:WherePage('')
  End
  If Errorcode() then Return.

  ! -- GroupBy
  Self.BuildGroupBy()
  If Errorcode() then Return.

  ! -- Having
  Self.BuildHaving()
  If Errorcode() then Return.
!  ! -- put it all together
  self.SqlCode.SetValue(self._GenerateSelect())
  !self.SqlCode.trace()
  Return

!-----------------------------------------------------------------
! There's a chance this will suffice, however you will likely need to derive it
! for a driver if the SQL syntax varies from the one below
!!! DERIVE if necessary
DriverViewSQLClass._GenerateSelect              Procedure()
limit   long
offset  long
cte     StringTheory
where   StringTheory
  code

  !!!todo implement prop:NotDistinct here

  self._CalcLimitAndOffset(limit,offset)
  self.BuildSubsetCTE(cte)
  If Errorcode() then Return ''.
  If self.WherePage <> ''
    where.SetValue(self.wherePage)
  Elsif Self.Where <> ''
    where.SetValue(self.where)
  End
  self.BuildSubsetWhere(where,self.GetProp:Alias(1) & '.')

  Return (Choose(self._explain = true,self.ExplainStart(),'')                   & |
         Choose(cte.length() > 0,cte.GetValue(),'')                            & |
         'SELECT '                                                             & |
         | ! self.TranslateLimitAbove (Limit,Offset)                     & |
         self.TranslateSelectHint(self.tree.hint)                              & |
         Choose(self.distinct = true, 'DISTINCT ','')                          & |
                self.ProjectList.GetValue()                                    & |
         ' FROM '  & self.from & ' '                                           & |
         Choose(self.tree.Hint <> '',self.tree.hint & ' ','')                  & |
                self.joinlist.GetValue()                                       & |  ! the JOIN keyword is part of the list
         Choose(Where.Length() > 0 ,'WHERE ' & where.GetValue() & ' ','')      & |
         Choose(self.GroupBy <> '','GROUP BY ' & self.GroupBy & ' ','')        & |
         Choose(self.Having  <> '','HAVING '   & self.Having  & ' ','')        & |
         Choose(self.OrderBy <> '','ORDER BY ' & self.orderby  & ' ' ,'')        & |
         self.TranslateLimitBelow(Limit,Choose(Offset <> 0 ,self._genparm(self._OffsetParmNumber),'')) & |   ! '?'  & self._OffsetParmNumber
         ';' &|
         Choose(self._explain = true,' ' & self.ExplainEnd(),''))

!-----------------------------------------------------------------
! There's a chance this will suffice, however you will likely need to derive it
! for a driver if the SQL syntax varies from the one below
!!! DERIVE if necessary
DriverViewSQLClass._GenerateRecordsSelect              Procedure(Long pIndex)
  code
  !!!todo implement prop:NotDistinct here
  self._OffsetParmNumber = 0
  If self.distinct = true or self.limit or self.offset or pIndex <> 0
    Return ('SELECT Count(*) From ( SELECT '                                   & |
         | ! self.TranslateLimitAbove (self.Limit,self.Offset)                     & |
         self.TranslateSelectHint(self.tree.hint)                              & |
         Choose(self.distinct = true, 'DISTINCT ','')                          & |
                self.ProjectList.GetValue()                                    & |
         ' FROM '  & self.from & ' '                                           & |
         Choose(self.tree.Hint <> '',self.tree.hint & ' ','')                  & |
                self.joinlist.GetValue()                                       & |  ! the JOIN keyword is part of the list
           Choose(self.Where <> '','WHERE '    & self.where   & ' ','')        & |
         Choose(self.GroupBy <> '','GROUP BY ' & self.GroupBy & ' ','')        & |
         Choose(self.Having  <> '','HAVING '   & self.Having  & ' ','')        & |
         Choose(self.OrderBy <> '' and (self.limit <> 0 or self.Offset <> 0) ,'ORDER BY ' & self.orderby & ' ','')        & |
         self.TranslateLimitBelow (self.Limit,self.Offset)                     & |
         ') AS Rows;' )
  Else
    Return ('SELECT Count(*) '                                                 & |
         ' FROM '  & self.from & ' '                                           & |
                self.joinlist.GetValue()                                       & |  ! the JOIN keyword is part of the list
         Choose(self.Where <> '','WHERE '    & self.where   & ' ','')          & |
         Choose(self.GroupBy <> '','GROUP BY ' & self.GroupBy & ' ','')        & |
         Choose(self.Having  <> '','HAVING '   & self.Having  & ' ','')        & |
         Choose(self.OrderBy <> '','ORDER BY ' & self.orderby & ' ','')      & |   ! no ORDER when RECORDS, because answer is just a single number
         ';')
  End
  Return ''

!-----------------------------------------------------------------
DriverViewSQLClass._CalcLimitAndOffset     Procedure(*Long rLimit, *Long rOffset)
isCalc  byte
  Code
  self.OrderQueue.IsCalc = true
  Get(self.OrderQueue,self.OrderQueue.IsCalc)
  If Errorcode() = NoError then isCalc = true.
  self.SetError(NoError)
  self._OffsetParmNumber = 0
  rOffSet = FALSE
  rLimit = 0
  If self._OrderHasCalc
    rLimit = 0
    rOffset = false
  ElsIf self.Limit <> 0
    ! If prop:limit is set then whole result set is loaded. No paging here.
    rLimit = self.Limit
    If self.Offset then rOffset =  self.Offset.
  ElsIf self.Paging = false
    ! developer has turned paging off for this view
  ElsIf isCalc = true
    ! if calculations in prop:SqlOrder are used then paging via the WHERE clause is not possible, so return the whole result set
  ElsIf self.fetchsize
    ! developer not setting boundaries, so using buffer page settings
     self._ParameterCount += 1
     self._OffsetParmNumber = self._ParameterCount
     rLimit = self.fetchsize
     rOffset = true
  End
  Return

!-----------------------------------------------------------------
! The SET was called with a ,n parameter. This implies that the first n fields of the order must be pinned
! to their current values in the buffer(s).
DriverViewSQLClass._PrependFixedToWhere                       Procedure(Long pIndex)
x      long
obj    &DriverFileClass
ans    StringTheory
vff    long
v      cString(255)
  code
  If pIndex = 0 then return.
  vff = abs(pIndex)
  Loop x = 1 to vff
    Get(self.OrderQueue,x)
    If self.OrderQueue.IsCalc then cycle.
    If self.OrderQueue.FileIndex < 1 or self.OrderQueue.FileIndex > self.Files then cycle.
    obj &= (self.FileObject[self.OrderQueue.FileIndex])
    If obj._withField(self.OrderQueue.FieldIndex) = Driver:ok
      self._ParameterCount += 1
      obj._ParameterOpcode = self._ParameterOpcode
      v = clip(obj.GetProp:Value(obj.fields.index))
      obj._SetParameterString(self._ParameterCount,v)  ! fixing the parameter to a value as it is at the SET, not based on the shadow buffer.
      If pIndex < 0
        ans.append(obj.Fields.Column & ' = ' & obj._genparm(self._ParameterCount),,' AND ')
        self.OrderQueue.Fixed = true
        put(self.OrderQueue)
      Else
        Case self._setdirection
        Of Opcode:Next
          ans.append(obj.Fields.Column & ' >= ' & obj._genparm(self._ParameterCount),,' AND ')
        Of Opcode:Previous
          ans.append(obj.Fields.Column & ' <= ' & obj._genparm(self._ParameterCount),,' AND ')
        End
      End
    End
  End
  If Self.GetProp:Where() = ''
    self.SetProp:Where(ans.GetValue())
  Else
    self.SetProp:Where('(' & ans.GetValue() & ') AND ' & Self.GetProp:Where())
  End
  Return

!---------------------------------------------------------------------------------
!!! derive
! This one is derived because the SQL code is backend dependent.
! making the *filter* case sensitive varies a lot between databases.
DriverViewSQLClass._AppendOrderQueueToWhere  Procedure(*Long pCount)
  code


!=============================================================================
!  DriverMetaData Interface
!=============================================================================
!---------------------------------------------------------------------------------
!DriverMetaData.IDrvMetaWindow.Link PROCEDURE()
!  Code
!  self.Count += 1
!  Return self.Count + 1
!!---------------------------------------------------------------------------------
!DriverMetaData.IDrvMetaWindow.Release PROCEDURE()
!  Code
!  If self.Count <> 0
!    self.Count -= 1
!    Return self.Count + 1
!  Else
!    Dispose(self)
!    Return 0
!  End
!!---------------------------------------------------------------------------------
!DriverMetaData.IDrvMetaWindow.GetUsage PROCEDURE()
!  Code
!  Return self.Count + 1
!
!!---------------------------------------------------------------------------------
!DriverMetaData.IDrvMetaWindow.HasOperation      PROCEDURE(SIGNED opCode)!,BYTE
!  Code
!  return false
!!---------------------------------------------------------------------------------
!DriverMetaData.IDrvMetaWindow.BuildDriverString PROCEDURE(*CSTRING inStr, LONG info = 0)!,BYTE,PROC !Returns FALSE if the user cancels
!  Code
!  return false
!!---------------------------------------------------------------------------------
!DriverMetaData.IDrvMetaWindow.Extensions        PROCEDURE()!,*CSTRING
!  Code
!  return 0
!!---------------------------------------------------------------------------------
!DriverMetaData.IDrvMetaWindow.ExtensionName     PROCEDURE()!,*CSTRING
!  Code
!  return 0
!!---------------------------------------------------------------------------------
!DriverMetaData.AddOption                 Procedure(*? pOption, String pName, String pDefault)
!  Code
!  If self.Options &= null
!    self.Options &= new OptionsQueueType
!  End
!  self.Options.option &= pOption
!  self.Options.name    = pName
!  self.Options.default = pDefault
!  Add(Self.Options)
!  Return
!!---------------------------------------------------------------------------------
!DriverMetaData.Parse                     Procedure(*Cstring pDriverString)
!  Code
!  Return
!!---------------------------------------------------------------------------------
!DriverMetaData.CreateString              Procedure(*Cstring rResult)
!  Code
!  Return

!=============================================================================
!  DriverResultSetClass Class
!=============================================================================
DriverResultSetClass.Construct  Procedure()
  Code
  self.CellPages &= New CellPageQueueType
  self.Columns &= New ColumnNamesQueueType
  self.state &= New DriverResultSetStateQueueType
  Return

!-----------------------------------------------------------------
DriverResultSetClass.Destruct  Procedure()
  Code
  self.iResultSet.Free()
  self._FreeStateQueue()
  Dispose(self.Columns)
  Dispose(self.cellPages)
  Dispose(self.state)
  Dispose(self.strmem)
  Return

!-----------------------------------------------------------------
DriverResultSetClass.Trace            PROCEDURE(String pStr)
cstr  Cstring(size(pStr)+101),Auto
  Code
  cstr = '[result] ' & clip(pStr)
  osOutputDebugString(cstr)
  Return

!-----------------------------------------------------------------
DriverResultSetClass._FreeStateQueue  Procedure()
x  Long,Auto
  code
  Loop x = Records(self.state) to 1 by -1
    get(self.state,x)
    self.iResultSet.FreeState(self.state.id)
  End
  Return

!-----------------------------------------------------------------
DriverResultSetClass._CheckString  Procedure(Long pLength)
  code
  If self.strmem &= null
    self.strmem &= new String(pLength)
  Elsif Len(self.StrMem) >= pLength
    Return
  Else
    Dispose(self.strmem)
    self.strmem &= new String(pLength)
  End
  Return

!-----------------------------------------------------------------
DriverResultSetClass._WithCell  Procedure(Long pRow, Long pColumn)
cellnumber  Long,auto
pagenumber  Long,auto
  Code
  cellnumber = (pRow-1) * self.NumColumns + pColumn - 1
  self._CellInPage = band(cellnumber,1023) + 1
  pageNumber = bshift(cellnumber,-10) + 1                ! 2^10 is 1024, which is the number of cells per page. Want the number to be 1 based.
  Return self._WithPage(PageNumber)

!-----------------------------------------------------------------
DriverResultSetClass._WithPage  Procedure(Long pPageNumber)
  code
  If self.CellPages.PageNumber = pPageNumber             ! if this page is already loaded then leave
    return Driver:ok
  End
  self.CellPages.PageNumber = pPageNumber
  Get(self.CellPages,self.CellPages.PageNumber)
  If Errorcode()
    self.CellPages.Cells &= new CellsPageClass
    Clear(self.CellPages.Cells.Addr)
    Add(self.CellPages,self.CellPages.PageNumber)
  End
  If Errorcode()
    Return Driver:notok
  End
  Return Driver:ok

!-----------------------------------------------------------------
! Free must not call FreeState
DriverResultSetClass.iResultSet.Free     Procedure()
x        Long,Auto
y        long,Auto
strmem   &string,Auto
  Code
  Loop x = 1 to records(self.CellPages)
    Get(self.CellPages,x)
    If self.CellPages.Cells &= NULL then cycle.
    Loop y = 1 to Maximum(self.CellPages.Cells.Addr,1)
      If self.CellPages.Cells.Addr[y]
        strmem &= self.CellPages.Cells.Addr[y] & ':' & self.CellPages.Cells.Size[y]
        Dispose(strmem)
        self.CellPages.Cells.Addr[y] = 0
        self.CellPages.Cells.Size[y] = 0
        self.CellPages.Cells.Len[y] = 0
      End
    End
    Dispose(self.CellPages.Cells)
  End
  Free(self.CellPages)
  Clear(self.CellPages)
  Free(Self.Columns)
  clear(self.ColumnsIndex)
  clear(self.ColumnsName)
  self.NumRows = 0
  self.NumColumns = 0
  self._CellInPage = 0
  self.ColumnsIndexMax = 0
  self.ColumnsNameMax = 0
  Return

!-----------------------------------------------------------------
DriverResultSetClass.iResultSet.NewResultSet          Procedure(Long pOptions)
  code
  If Band(pOptions,driver:FreeRam)
    self.iResultSet.Free()
    Return
  End
  self.NumColumns = 0
  self.NumRows = 0
  self.ColumnsIndexMax = 0
  self.ColumnsNameMax = 0
  !clear(self.ColumnsIndex)
  !Clear(self.ColumnsArray)
  Return

!-----------------------------------------------------------------
DriverResultSetClass.iResultSet.SetColumnName         Procedure(Long pColumn,String pName)
  code
  If pColumn <= FASTCOLUMNS
    self.ColumnsName[pcolumn] = pName
    If pColumn > self.ColumnsNameMax then self.ColumnsNameMax = pColumn.
    Return
  End
  self.Columns.Column = pColumn
  Get(self.Columns,self.Columns.Column)
  If errorcode()
    self.Columns.Name = pName
    Add(self.Columns)
  Else
    self.Columns.Name = pName
    Put(self.Columns)
  End
  Return

!-----------------------------------------------------------------
DriverResultSetClass.iResultSet.SetColumnIndex        Procedure(Long pColumn,Long pIndex)
  code
  If pColumn <= maximum(self.ColumnsIndex,1)
    self.ColumnsIndex[pcolumn] = pIndex
    If pColumn > self.ColumnsIndexMax then self.ColumnsIndexMax = pColumn.
  End
  Return

!-----------------------------------------------------------------
DriverResultSetClass.iResultSet.GetColumnIndex        Procedure(Long pColumn)
  code
  If pColumn <= self.ColumnsIndexMax
    Return self.ColumnsIndex[pcolumn]
  End
  Return 0

!-----------------------------------------------------------------
DriverResultSetClass.iResultSet.SetColumnType        Procedure(Long pColumn,Long pType)
  code
  If pColumn <= maximum(self.ColumnsIndex,1)
    self.ColumnsType[pcolumn] = pType
  End
  Return

!-----------------------------------------------------------------
DriverResultSetClass.iResultSet.GetColumnType        Procedure(Long pColumn)
  code
  If pColumn <= maximum(self.ColumnsIndex,1)
    Return self.ColumnsType[pcolumn]
  End
  Return 0

!-----------------------------------------------------------------
DriverResultSetClass.iResultSet.GetColumnName         Procedure(Long pColumn)
  code
  If pColumn <= FASTCOLUMNS
    If pColumn <= self.ColumnsNameMax
      Return self.ColumnsName[pColumn]
    End
  End
  self.Columns.Column = pColumn
  Get(self.Columns,self.Columns.Column)
  If errorcode()
    Return ''
  End
  Return self.Columns.Name

!-----------------------------------------------------------------
DriverResultSetClass.iResultSet.GetColumnNamed        Procedure(String pName)
x   long,auto
l   long,auto
  Code
  l = len(clip(pName))
  if l < 1 then return 0.
  Loop x = 1 to self.NumColumns
    If self.ColumnsName[x]= pName[1 : l] then Return x.
  End
  self.Columns.Name = pName[1 : l]
  Get(self.Columns,self.Columns.Name)
  If Errorcode() = 0
    Return self.Columns.Column
  End
  Return 0

!-----------------------------------------------------------------
DriverResultSetClass.iResultSet.SetRowPosition        Procedure(Long pRow, *String pPosition)
  Code
  If pRow <= 0 or pRow > Maximum(self.RowPositionHash,1) then Return.
  self.RowPositionHash[pRow] = pPosition
  Return

!-----------------------------------------------------------------
DriverResultSetClass.iResultSet.GetRowWithPosition    Procedure(*String pPosition)
nr   Long,Auto
x    Long,Auto
  code
  If pPosition = '' then Return 0.
  nr = self.NumRows
  If nr > Maximum(self.RowPositionHash,1) then nr = Maximum(self.RowPositionHash,1).
  Loop x = 1 to nr
    If self.RowPositionHash[x] = pPosition then Return x.
  End
  Return 0

!-----------------------------------------------------------------
! data is stored in the Results memory. It is stored as the native result, as from the database. SQL Type is stored in pType
! The incoming data is pointed to by rAddress and rLength.
! The data is *copied* into the result set
! Despite being passed by pointer, rAddress and rLength are not changed.
!
DriverResultSetClass.iResultSet.SetCell               Procedure(Long pRow, Long pColumn, Long pType, *BigInt rAddress, *BigInt rLength)
strmem      &string!,auto
  code
  !self.trace('1 DriverResultSetClass.iResultSet.SetCell pType=' & pType & ' row=' & pRow & ' col=' & pColumn & ' addr=' & rAddress & ' len=' & rLength)
  If pColumn > self.NumColumns then self.NumColumns = pColumn.
  If self._WithCell(pRow,pColumn) = driver:ok
    self.CellPages.Cells.Type[self._CellInPage] = pType
    If pType = ClaNull or rLength = 0
      self.CellPages.Cells.Len[self._CellInPage] = rLength
      Return
    End
    If self.CellPages.Cells.Addr[self._CellInPage] = 0
      strmem &= new String(rLength)
      self.CellPages.Cells.Addr[self._CellInPage] = address(strmem)
      self.CellPages.Cells.Size[self._CellInPage] = rLength
    Elsif rLength > self.CellPages.Cells.Len[self._CellInPage]
      strmem &= self.CellPages.Cells.Addr[self._CellInPage] & ':' & self.CellPages.Cells.Len[self._CellInPage]
      Dispose(strmem)
      strmem &= new String(rLength)
      self.CellPages.Cells.Addr[self._CellInPage] = address(strmem)
      self.CellPages.Cells.Size[self._CellInPage] = rLength
    End
    MemCpy(self.CellPages.Cells.Addr[self._CellInPage],rAddress,rLength)
    self.CellPages.Cells.Len[self._CellInPage] = rLength
  End
  Return

!-----------------------------------------------------------------
! This version of SetCell does not NEW or DISPOSE memory. It simply points to an address.
! HOWEVER the memory will be DISPOSED when the cell is overwritten. So this MUST be called pointing to memory
! the PROGRAM NEW'd (but did not dispose). It cannot use a pointer into the inside of a database or odbc dll.
DriverResultSetClass.iResultSet.SetCellAddr      Procedure(Long pRow, Long pColumn, Long pType, *BigInt rAddress, *BigInt rLength)
  code
  If pColumn > self.NumColumns then self.NumColumns = pColumn.
  If self._WithCell(pRow,pColumn) = driver:ok
    self.CellPages.Cells.Type[self._CellInPage] = pType
    self.CellPages.Cells.Addr[self._CellInPage] = rAddress
    self.CellPages.Cells.Size[self._CellInPage] = rLength
    self.CellPages.Cells.Len[self._CellInPage] = rLength
  end
  Return

!-----------------------------------------------------------------
! this is a slightly slower version of GetCell, because the return value is always converted to a CLIPPED string. But for ad-hoc queries
! it's fast enough, and convenient. Use this form if a null should be treated as ''
! reply is limited to String(255)
DriverResultSetClass.iResultSet.GetCell          Procedure(Long pRow, Long pColumn)
rNull  byte
  code
  Return self.iResultSet.GetCell(pRow,pColumn,rNull)

!-----------------------------------------------------------------
! this is a slightly slower version of GetCell, because the return value is always converted to a CLIPPED string. But for ad-hoc queries
! it's fast enough, and convenient. Will set rNull if the field is null, so can be used to check if the field is null.
! if the cell is out of range, then a blank string is returned, and rNull is set to NoRecErr
! reply is limited to String(100 000)
DriverResultSetClass.iResultSet.GetCell          Procedure(Long pRow, Long pColumn, *Byte rNull)
CellAddr    BIGINT
CellLen     BIGINT
CellType    Long
strx        string(100000)
rTextLen    Long
  code
  If self._WithCell(pRow,pColumn) = driver:ok
    self.iResultSet.GetCell(pRow,pColumn,CellType,CellAddr,CellLen)
    case CellType
    of ClaNULL
      rNull = true
      Return ''
    else
      rNull = false
      rTextLen = 1
      self.obj._morph('',ClaString, address(strx), size(strx), CellType, CellAddr, CellLen,0,false,rTextLen)
      If rTextLen < 1 then Return ''.
      If rTextLen > size(strx) then rTextLen = size(strx).
      Return Strx[1 : rTextLen]
    End
  End
  rNull = NoRecErr
  Return ''

!-----------------------------------------------------------------
! pType: Coming in contains the required data type. If the incoming pType is set to ClaRAW then the data is returned as it is in the result set
! rType: The type being returned, or ClaNULL if the field is null. If the field is null then the Address and Length are set to 0.
! The contents in the rAddress and RLength returned are only valid untill the next call to GetCell
DriverResultSetClass.iResultSet.GetCell         Procedure(Long pRow, Long pColumn, *Long rType, *BigInt rAddress, *BigInt rLength)
  code
  If self._WithCell(pRow,pColumn) = driver:ok
    rType = self.CellPages.Cells.Type[self._CellInPage]
    rAddress = self.CellPages.Cells.Addr[self._CellInPage]
    rLength = self.CellPages.Cells.Len[self._CellInPage]
    !self.trace('GetCell(' & pRow & ',' & pColumn & ' rType=' & rType & ' rAddress=' & rAddress & ' rLength=' & rLength)
  else
    rType = 0
    rAddress = 0
    rLength = 0
    !self.trace('call to GetCell failed: ' & pRow & ' ' & pColumn)
  End
  Return

!-----------------------------------------------------------------
DriverResultSetClass.iResultSet.SetColumns            Procedure(Long pColumns)
  code
  self.NumColumns = pColumns

!-----------------------------------------------------------------
DriverResultSetClass.iResultSet.Columns               Procedure()
  code
  return self.NumColumns

!-----------------------------------------------------------------
DriverResultSetClass.iResultSet.Rows                  Procedure()
  code
  return self.NumRows

!-----------------------------------------------------------------
DriverResultSetClass.iResultSet.IncrementRowNumber    Procedure()
  code
  self.NumRows += 1
  return self.NumRows

!-----------------------------------------------------------------
DriverResultSetClass.iResultSet.GetState              Procedure(Long pStateId)
x         long,Auto
z         long,Auto
strmem    &string,auto
  Code
  self.state.Id = pStateId
  Get(self.state,self.state.id)
  If Errorcode()
    Clear(self.state)
    self.state.Id = pStateId
    self.state.Columns &= New ColumnNamesQueueType
    self.state.CellPages &= New CellPageQueueType
    Add(self.state)
  End

  self.state.NumColumns         =  self.NumColumns
  self.state.NumRows            =  self.NumRows
  self.state.ColumnsIndexMax    =  self.ColumnsIndexMax
  self.state.ColumnsIndex       =  self.ColumnsIndex
  self.state.ColumnsType        =  self.ColumnsType
  self.state.ColumnsNameMax     =  self.ColumnsNameMax
  self.state.ColumnsName        =  self.ColumnsName
  self.state._CellInPage        =  self._CellInPage

  ! columns
  Free(self.state.Columns)
  Loop x = 1 to Records(self.Columns)
    Get(self.Columns,x)
    self.state.Columns = self.Columns
    Add(self.state.Columns)
  End

  ! cells
  Free(self.state.CellPages)
  Loop x = 1 to Records(self.CellPages)
    Get(self.CellPages,x)
    self.state.CellPages.PageNumber = self.CellPages.PageNumber
    self.state.CellPages.Cells &= New CellsPageClass
    Clear(self.state.CellPages.Cells.Addr)
    Clear(self.state.CellPages.Cells.Size)
    self.state.CellPages.Cells.Len = self.CellPages.Cells.Len
    self.state.CellPages.Cells.Type = self.CellPages.Cells.Type
    Loop z = 1 to Maximum(self.CellPages.Cells.Addr,1)
      If self.CellPages.Cells.Addr[z] and self.CellPages.Cells.Size[z] and self.CellPages.Cells.Len[z]
        strmem &= new String(self.CellPages.Cells.Len[z])
        self.state.CellPages.Cells.Addr[z] = address(strmem)
        self.state.CellPages.Cells.Size[z] = self.CellPages.Cells.Len[z]
        MemCpy(self.state.CellPages.Cells.Addr[z],self.CellPages.Cells.Addr[z],self.CellPages.Cells.Len[z])
      End
    End
    Add(self.state.CellPages)
  End

  Put(self.state)
  Return

!-----------------------------------------------------------------
DriverResultSetClass.iResultSet.RestoreState          Procedure(Long pStateId)
x      Long,Auto
z      Long,Auto
strmem &String,Auto
  Code
  self.state.Id = pStateId
  Get(self.state,self.state.id)
  If Errorcode()
    self.trace('DriverResultSetClass.iResultSet.RestoreState : Invalid State ' & pStateId)
    return
  End
  self.NumColumns         =  self.state.NumColumns
  self.NumRows            =  self.state.NumRows
  self.ColumnsIndexMax    =  self.state.ColumnsIndexMax
  self.ColumnsIndex       =  self.state.ColumnsIndex
  self.ColumnsType        =  self.state.ColumnsType
  self.ColumnsNameMax     =  self.state.ColumnsNameMax
  self.ColumnsName        =  self.state.ColumnsName
  Free(self.Columns)

  Loop x = 1 to records(self.state.Columns)
    get(self.state.Columns,x)
    self.Columns = self.state.Columns
    Add(self.Columns)
  End
  Loop x = 1 to Records(self.state.CellPages)
    Get(self.state.CellPages,x)
    If self._WithPage(x) = driver:ok
    End
    self.CellPages = self.state.CellPages
    self.CellPages.Cells.Len = self.state.CellPages.Cells.Len
    self.CellPages.Cells.Type = self.state.CellPages.Cells.Type

    Loop z = 1 to Maximum(self.CellPages.Cells.Addr,1)
      If self.CellPages.Cells.Addr[z] and self.state.CellPages.Cells.Addr[z] and self.CellPages.Cells.Size[z] >= self.state.CellPages.Cells.Len[z]
        ! both set, cell is big enough, just copy. Sizes are unaltered.
        If self.state.CellPages.Cells.Len[z]
          MemCpy(self.CellPages.Cells.Addr[z],self.state.CellPages.Cells.Addr[z],self.state.CellPages.Cells.Len[z] )
        End
      ElsIf self.state.CellPages.Cells.Addr[z] = 0
        ! nothing in the saved cell, so nothing to do. Len will take care of it.  Sizes are unaltered.
      Else
        ! something is in the saved cell. And it needs more space.
        ! dispose old one
        If self.CellPages.Cells.Addr[z] and self.CellPages.Cells.Size[z]
          Strmem &= self.CellPages.Cells.Addr[z] & ':' & self.CellPages.Cells.Size[z]
          Dispose(StrMem)
        End
        ! get space for new one
        StrMem &= new String(self.state.CellPages.Cells.Len[z])
        self.CellPages.Cells.Addr[z] = address(strmem)
        ! set new size
        self.CellPages.Cells.Size[z] = self.state.CellPages.Cells.Len[z]
        ! copy value
        If self.state.CellPages.Cells.Len[z]
          MemCpy(self.CellPages.Cells.Addr[z],self.state.CellPages.Cells.Addr[z],self.state.CellPages.Cells.Len[z] )
        End
      End
    End
  End
  Return

!-----------------------------------------------------------------
! CLOSE must not call FreeState
DriverResultSetClass.iResultSet.FreeState             Procedure(Long pStateId)
x      Long,Auto
z      Long,Auto
strmem &String,Auto
  Code
  self.state.Id = pStateId
  Get(self.state,self.state.id)
  If Errorcode() then return.
  Dispose(self.state.Columns)
  Loop x = 1 to Records(self.state.CellPages)
    Get(self.state.CellPages,x)
    Loop z = 1 to Maximum(self.state.CellPages.Cells.Addr,1)
      If self.state.CellPages.Cells.Addr[z]
        StrMem &= self.state.CellPages.Cells.Addr[z] & ':' & self.state.CellPages.Cells.Size[z]
        Dispose(StrMem)
      End
    End
    Dispose(self.state.CellPages.Cells)
  End
  Dispose(self.state.CellPages)
  Delete(self.state)
  Return

!-----------------------------------------------------------------
!=================================================================
!=================================================================
!-----------------------------------------------------------------
DriverConnectionPoolClass.Construct                 Procedure()
  code
  self.Connections &= New DriverConnectionsQueueType
  Return

!-----------------------------------------------------------------
DriverConnectionPoolClass.Destruct                  Procedure()
  code
  ! The Queue should be empty here, assuming that all objects disconnected
  Dispose(self.Connections)
  Return

!-----------------------------------------------------------------
DriverConnectionPoolClass.Trace                     Procedure(String pStr)
cstr  Cstring(size(pStr)+50)
  Code
  cstr = '[' & thread() & '][POOL][' & self.driver & '] ' & clip(pStr)
  osOutputDebugString(cstr)
  Return

!-----------------------------------------------------------------
DriverConnectionPoolClass.GetConnection             Procedure(String pConnectString, Long pPool, Long pOptions)!,Long
ans  Long
  Code
  PushErrors()
  self.connections.Connection = lower(clip(pConnectString))
  self.connections.Pool = pPool
  self.connections.Options = pOptions
  Get(self.connections,self.connections.Connection,self.connections.Pool,self.connections.Options)
  If Errorcode() = NoError
    Self.Connections.Counter += 1
    Put(self.Connections)
    Ans = self.Connections.Handle
  End
  PopErrors()
  Return Ans

!-----------------------------------------------------------------
DriverConnectionPoolClass.SetConnection             Procedure(String pConnectString, Long pPool,Long pOptions,Long pHandle)
  Code
  PushErrors()
  self.connections.Connection = lower(clip(pConnectString))
  self.connections.Pool = pPool
  self.connections.Options = pOptions
  self.Connections.Handle = pHandle
  Get(self.connections,self.connections.Connection,self.connections.Pool,self.connections.Options,self.Connections.Handle)
  If Errorcode()
    Self.Connections.Counter = 1
    Add(self.Connections)
  End
  PopErrors()
  Return

!-----------------------------------------------------------------
DriverConnectionPoolClass.Disconnect                Procedure(Long pHandle)
ans   Long
  Code
  self.Connections.Handle = pHandle
  PushErrors()
  Get(self.connections,self.Connections.Handle)
  If Errorcode() = 0
    Self.Connections.Counter -= 1
    If Self.Connections.Counter = 0
      Delete(Self.Connections)
      ans = true
    Else
      Put(self.Connections)
    End
  End
  PopErrors()
  Return Ans

!-----------------------------------------------------------------
DriverConnectionPoolClass.SetTransaction                  Procedure(Long pHandle, Byte pValue)!,VIRTUAL
  Code
  PushErrors()
  self.Connections.Handle = pHandle
  Get(self.connections,self.Connections.Handle)
  If Errorcode() = NoError
    Self.Connections.Transaction = pValue
    Put(self.Connections)
  End
  PopErrors()
  Return

!-----------------------------------------------------------------
DriverConnectionPoolClass.GetTransaction                  Procedure(Long pHandle)!,Long,VIRTUAL
  Code
  PushErrors()
  self.Connections.Handle = pHandle
  Get(self.connections,self.Connections.Handle)
  If Errorcode()
    Self.Connections.Transaction = false
  End
  PopErrors()
  Return Self.Connections.Transaction

!=================================================================
!=================================================================
!-----------------------------------------------------------------
DriverCriticalSection.Construct                Procedure()
  CODE
  SELF.CS &= NewCriticalSection()
  RETURN

!-----------------------------------------------------------------
DriverCriticalSection.Destruct                 Procedure()
  CODE
  SELF.CS.Kill()
  RETURN

!-----------------------------------------------------------------
DriverCriticalSection.Wait                     Procedure()
  CODE
  SELF.CS.Wait()
  RETURN

!-----------------------------------------------------------------
DriverCriticalSection.Release                  Procedure()
  CODE
  SELF.CS.Release()
  RETURN

!-----------------------------------------------------------------
DriverCriticalSection.GetIFace                 Procedure()
  CODE
  RETURN SELF.CS

!-----------------------------------------------------------------
!-----------------------------------------------------------------
MemCpy  Procedure(long dest, long src,  long count)!, long, proc, name('memcpy')
lg   long,auto
sh   short,auto
bt   byte,auto
  code
  loop bshift(count,-2) times
    peek(src,lg)
    poke(dest,lg)
    src  += 4
    dest += 4
  end
  if band(count,2)
    peek(src,sh)
    poke(dest,sh)
    src  += 2
    dest += 2
  end
  if band(count,1)
    peek(src,bt)
    poke(dest,bt)
  end
  Return count


