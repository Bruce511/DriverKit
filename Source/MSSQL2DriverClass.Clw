!------------------------------------------------------------------------------------------------
!   CapeSoft Clarion File Driver Kit classes are copyright © 2026 by CapeSoft                   !
!   Docs online at : https://capesoft.com/docs/Driverkit/ClarionObjectBasedDrivers.htm
!   Commercial release - all rights reserved
!------------------------------------------------------------------------------------------------

!!!todo export client-side views to server-side views?
!!!todo ResultGet et al support setting PrimaryKeyPosition so can be updated?
!!!todo - check prop:distinct on files, making result set read-only, so not needing to include primary key
!!!todo - make sure prop:project is including primary key values if not in read-only mode.
!!!todo -  Make GlobalOwnerString = '',  then connect through the connection box.. then look at filename{Prop:ConnectString} afterward to see what it made. (Connectionstrings.com)
!!!todo truncated reading of data detected, and set error.


  !TPS to SQL guy
    ! Create tables using VARCHAR for strings. Automatically Null Terminate them.
       ! will result in strings not being able to use the last character
       ! perhaps VARCHAR should be size(String)+1?
    ! or
      ! create tables using CHAR for strings. Expect issues with trailing spaces in comparisons and so on

   !Guy importing from SQL
     ! Import VACHAR to CSTRING and CHAR to STRING

   !Guy who has been using the old driver;
     !He might already be using Cstrings & VarChars?
     ! What did old driver CREATE?

   ! Current CREATE Behavior:
   ! MSSQL ->   CSTRING(100) goes to VARCHAR(99)
   !                    STRING(100) goes to CHAR(100)
   ! because SQL does not store the null, while Clarion does. So Clarion Cstrings are VARCHAR(n) = CSTRING(n+1)



!!!todo reports can turn off bookmarks explicity - as in SQLSetStmtAttr(hStmt, SQL_ATTR_USE_BOOKMARKS, (SQLPOINTER)SQL_UB_OFF, 0); Perhaps browses too

  member()
  include('MSSQL2DriverClass.Inc'),once
  include('StringTheory.inc'),Once
  include('Errors.clw'),once

SQLFET  Equate(0)

  map
    Module('Windows')
      osSHGetFolderPath(long pHandle, long pCSIDL, long hToken, long pFlags, *CSTRING szPath),long, raw, pascal, name('SHGetFolderPathA'), dll(1)
      osSleep(Long pMilliseconds), raw, pascal, name('Sleep'), dll(1)
    End
    Module('ODBC3 api')
        SQLGetDiagRec(SQLSMALLINT HandleType, SQLHANDLE Handle, SQLSMALLINT RecNumber, Long SQLStateAddress, Long NativeErrorPtr,    |
                      Long MessageTextAddress, SQLSMALLINT BufferLength, Long TextLengthPtr),SQLRETURN,Pascal,Raw,Name('SQLGetDiagRec'),dll(1) ! odbc 3.0

        SQLGetDiagField(SQLSMALLINT HandleType, SQLHANDLE Handle, SQLSMALLINT RecNumber, SQLSMALLINT DiagIdentifier,SQLPOINTER DiagInfoPtr, |
                        SQLSMALLINT BufferLength,*SQLSMALLINT StringLengthPtr),SQLRETURN,Pascal,Raw,Name('SQLGetDiagField'),dll(1) ! odbc 3.0

        SQLAllocHandle(SQLSMALLINT HandleType, SQLHANDLE InputHandle, *SQLHANDLE OutputHandlePtr),SQLRETURN,Pascal,Raw,Name('SQLAllocHandle') ,dll(1) ! odbc 3.0
        SQLFreeHandle(SQLSMALLINT HandleType, SQLHANDLE Handle),SQLRETURN,Pascal,Raw,Name('SQLFreeHandle'),dll(1)  ! odbc 3.0

        SQLSetEnvAttr(SQLHENV EnvironmentHandle, SQLINTEGER Attribute, SQLPOINTER ValuePtr,SQLINTEGER StringLength),SQLRETURN,Pascal,Raw,Name('SQLSetEnvAttr'),dll(1)  ! odbc 3.0
        SQLSetConnectAttr(SQLHDBC ConnectionHandle, SQLINTEGER Attribute, SQLPOINTER ValuePtr, SQLINTEGER StringLength),SQLRETURN,Pascal,Raw,Name('SQLSetConnectAttr'),dll(1)  ! odbc 3.0
        SQLGetConnectAttr(SQLHDBC ConnectionHandle, SQLINTEGER Attribute, SQLPOINTER ValuePtr, SQLINTEGER BufferAddress, SQLINTEGER BufferLength),SQLRETURN,Pascal,Raw,Name('SQLGetConnectAttr'),dll(1)  ! odbc 3.0

        SQLDriverConnect(SQLHDBC ConnectionHandle, SQLHWND WindowHandle, Long InConnectionStringAddress, SQLSMALLINT StringLength1, |
                        Long OutConnectionStringAddress, SQLSMALLINT BufferLength,  |
                        Long StringLength2Addr, SQLUSMALLINT DriverCompletion),SQLRETURN,Pascal,Raw,Name('SQLDriverConnectA'),dll(1)  ! odbc 1.0

        SQLDrivers(SQLHENV EnvironmentHandle,SQLUSMALLINT Direction, *Cstring DriverDescription,SQLSMALLINT BufferLength1, |
                   *SQLSMALLINT DescriptionLengthPtr, *Cstring DriverAttributes,SQLSMALLINT BufferLength2, |
                   *SQLSMALLINT AttributesLengthPtr),SQLRETURN,Pascal,Raw,Name('SQLDrivers'),dll(1)  ! odbc 2.0

        SQLDisconnect(SQLHDBC ConnectionHandle),SQLRETURN,Pascal,Raw,Name('SQLDisconnect')  ! odbc 1.0

        SQLColumns(SQLHSTMT StatementHandle, *Cstring CatalogName, SQLSMALLINT NameLength1, *Cstring SchemaName, SQLSMALLINT NameLength2,  |
                   *Cstring TableName, SQLSMALLINT NameLength3, *Cstring ColumnName, SQLSMALLINT NameLength4),SQLRETURN,Pascal,Raw,Name('SQLColumns'),dll(1)  ! odbc 1.0

        SQLPrepare(SQLHSTMT StatementHandle,Long StatementTextAddress,SQLINTEGER TextLength),SQLRETURN,Pascal,Raw,Name('SQLPrepare'),dll(1) ! odbc 1.0

        SQLSetStmtAttr(SQLHSTMT StatementHandle,SQLINTEGER Attribute, SQLPOINTER ValuePtr, SQLINTEGER StringLength),SQLRETURN,Pascal,Raw,Name('SQLSetStmtAttr'),dll(1)   ! odbc 3.0
        SQLGetStmtAttr(SQLHSTMT StatementHandle,SQLINTEGER Attribute, SQLPOINTER ValuePtr, SQLINTEGER BufferLength, *SQLINTEGER StringLengthPtr),SQLRETURN,Pascal,Raw,Name('SQLGetStmtAttr'),dll(1) ! odbc 3.0

        SQLFreeStmt(SQLHSTMT StatementHandle, SQLUSMALLINT Option),SQLRETURN,Pascal,Raw,Name('SQLFreeStmt'),dll(1) ! odbc 1.0

        SQLBindCol(SQLHSTMT StatementHandle,SQLUSMALLINT ColumnNumber, SQLSMALLINT TargetType, SQLPOINTER TargetValuePtr, |
                   SQLLEN BufferLength, *SQLLEN StrLen_or_IndPtr),SQLRETURN,Pascal,Raw,Name('SQLBindCol'),dll(1) ! odbc 1.0

        SQLBindParameter(SQLHSTMT StatementHandle, |
                         SQLUSMALLINT ParameterNumber, |
                         SQLSMALLINT InputOutputType, |
                         SQLSMALLINT ValueType, |
                         SQLSMALLINT ParameterType,  |
                         SQLULEN ColumnSize, |
                         SQLSMALLINT DecimalDigits, |
                         SQLPOINTER ParameterValuePtr, |
                         SQLLEN BufferLength,|
                         *SQLLEN StrLen_or_IndPtr),SQLRETURN,Pascal,Raw,Name('SQLBindParameter'),dll(1) ! odbc 2.0

        SQLExecDirect(SQLHSTMT StatementHandle, *Cstring StatementText, SQLINTEGER TextLength),SQLRETURN,Pascal,Raw,Name('SQLExecDirect'),dll(1) ! odbc 1.0
        SQLExecute(SQLHSTMT StatementHandle),SQLRETURN,Pascal,Raw,Name('SQLExecute'),dll(1) ! odbc 1.0

        SQLFetch(SQLHSTMT StatementHandle),SQLRETURN,Pascal,Raw,Name('SQLFetch'),dll(1)  ! odbc 1.0

        SQLFetchScroll(SQLHSTMT StatementHandle,SQLSMALLINT FetchOrientation,SQLLEN FetchOffset),SQLRETURN,Pascal,Raw,Name('SQLFetchScroll'),dll(1)  ! odbc 3.0

        SQLNumResultCols(SQLHSTMT StatementHandle, *SQLSMALLINT ColumnCountPtr),SQLRETURN,Pascal,Raw,Name('SQLNumResultCols'),dll(1) ! odbc 1.0


        SQLDescribeCol(SQLHSTMT StatementHandle, SQLUSMALLINT ColumnNumber, *Cstring ColumnName, SQLSMALLINT BufferLength, |
                       *SQLSMALLINT NameLengthPtr, *SQLSMALLINT DataTypePtr, *SQLULEN ColumnSizePtr, *SQLSMALLINT DecimalDigitsPtr, |
                       *SQLSMALLINT NullablePtr),SQLRETURN,Pascal,Raw,Name('SQLDescribeCol'),dll(1) ! odbc 1.0

        SQLColAttribute(SQLHSTMT StatementHandle,SQLUSMALLINT ColumnNumber, SQLUSMALLINT FieldIdentifier,SQLPOINTER CharacterAttributePtr,|
                        SQLSMALLINT BufferLength, *SQLSMALLINT StringLengthPtr, *SQLLEN NumericAttributePtr),SQLRETURN,Pascal,Raw,Name('SQLColAttribute'),dll(1)  ! odbc 3.0

        SQLSetDescField(SQLHDESC DescriptorHandle, SQLSMALLINT RecNumber, SQLSMALLINT FieldIdentifier, SQLPOINTER ValuePtr, SQLINTEGER BufferLength),SQLRETURN,Pascal,Raw,Name('SQLSetDescField'),dll(1)  ! odbc 3.0

        SQLGetData(SQLHSTMT StatementHandle, SQLUSMALLINT Col_or_Param_Num, SQLSMALLINT TargetType, SQLPOINTER TargetValuePtr,  |
                   SQLLEN BufferLength, *Long StrLen_or_IndPtr),SQLRETURN,Pascal,Raw,Name('SQLGetData'),dll(1)  ! odbc 1.0


        SQLRowCount(SQLHSTMT StatementHandle, *SQLLEN RowCountPtr),SQLRETURN,Pascal,Raw,Name('SQLRowCount'),dll(1)  ! odbc 1.0

        SQLGetInfo(SQLHDBC ConnectionHandle, SQLUSMALLINT InfoType, SQLPOINTER InfoValuePtr, SQLSMALLINT BufferLength, *SQLSMALLINT StringLengthPtr),SQLRETURN,Pascal,Raw,Name('SQLGetInfo'),dll(1)  ! odbc 1.0

        SQLTables(SQLHSTMT StatementHandle,Long CatalogNameAddress,SQLSMALLINT NameLength1, Long SchemaNameAddress, SQLSMALLINT NameLength2,  |
                  Long TableNameAddress, SQLSMALLINT NameLength3,Long TableTypeAddress, SQLSMALLINT NameLength4),SQLRETURN,Pascal,Raw,Name('SQLTables'),dll(1)  ! odbc 1.0

    End
    module('rtl')
      MemCpy(long dest, long src,  unsigned count), long, proc, name('_memcpy'),dll(DLL_Mode)
      MemSet(long dest, long char, unsigned count), long, proc, name('_memset'),dll(DLL_Mode)
      _MemCmp(long buf1, long buf2, unsigned count), long, name('_memcmp'),dll(DLL_Mode)
    end
  end


! normally one would not put global, unthreaded, variables into the class module.
! but these are read from an INI File, so we don't want to do it per-object. They are
! per-driver, so reading them when initing the first object is enough. If the INI value changes
! the program will need to be restarted to see the effect.

driver:loaded          byte
driver:trace           byte          ! trace calls to the backend
driver:BindData        byte          ! show bound data
driver:Profile         byte          ! show clarion statements
driver:Flush           byte          ! flush after write
driver:DebugLog        byte          ! Output to Debugview
driver:Details         byte          ! show record buffer contents
driver:TraceIntoFiles  byte          ! log commands generated by view engine
driver:odbc17exists    byte          ! checks odbc to see if the version 17 driver is installed
driver:odbc18exists    byte          ! checks odbc to see if the version 18 driver is installed
driver:TraceFile       aString       ! file to store tracing in

BlankString  Cstring(2)
!===================================================================================================================
!=====================================================================================================================
! Threaded, Driver-level object. Shared by all files using this driver on this thread.
ConnectionPoolMSSQL2ok    Byte,Thread   ! The connection object might be disposed before the file driver object
ConnectionPoolMSSQL2      Class(DriverConnectionPoolClass),Thread
envHandle                   Long                  ! Each thread has it's own Env Handle, but all objects on a thread share the same Env Handle.  !!! Experimental
Construct                   Procedure()
Destruct                    Procedure(),Derived
                          End

!-----------------------------------------------------------------
ConnectionPoolMSSQL2.Construct                 Procedure()
  code
  self.Driver = 'MSSQL'
  ConnectionPoolMSSQL2ok = true
  Return

!-----------------------------------------------------------------
ConnectionPoolMSSQL2.Destruct                 Procedure()
result   Long,Auto
  code
  ConnectionPoolMSSQL2ok = false
  If ConnectionPoolMSSQL2.envHandle
    result = SQLFreeHandle(SQL_HANDLE_ENV, ConnectionPoolMSSQL2.envHandle)
    ConnectionPoolMSSQL2.envHandle = SQL_NULL_HANDLE
  End
  Return

!-----------------------------------------------------------------
! In derived classes derive this method with this exact same code, but
! replace the declaration of old with your class name. DO NOT call the parent class.
DriverFileMSSQL2Class.ReplaceObject          PROCEDURE(Long pOldObjectAddress)
old    &DriverFileMSSQL2Class,Auto
  Code
  If pOldObjectAddress <> 0
    old &= (pOldObjectAddress)
    self :=: old
    dispose(old)
  End
  self.ClaFCB.rblock = address(self)
  Return

!-----------------------------------------------------------------
DriverFileMSSQL2Class.Construct  Procedure()
  code
  self.opt:BusyTimeout = 5    ! 5 seconds
  self._ThisSqlType = 'MSSQLTYPE' ! used in dict in extended attributes to identify type settings specific to MSSQL
  self.QuoteString = '['     ! mssql
  Return

!-----------------------------------------------------------------
DriverFileMSSQL2Class.Destruct  Procedure()
  code
  self._Destructing = true
  If self.dbHandle
    self.Disconnect()
  End
  Dispose(self._PutSqlCache)
  Dispose(self.opt:LogFileName)
  Dispose(self.opt:LogMessage)
  Return

!-----------------------------------------------------------------
DriverFileMSSQL2Class.Init   Procedure(FILE pFile, Long pForce=false)
  code
  self.ConnectionPool &= ConnectionPoolMSSQL2
  parent.Init(pFile,pForce)
  Return

!-----------------------------------------------------------------
! loads Driver-Wide values from an INI file when the first file in this driver is Initialized.
! Although this code is common to all the drivers, it can't be moved into the base class because of the
! global module variables.
DriverFileMSSQL2Class.LoadLogging  procedure
CSIDL_APPDATA  Equate(01Ah)
iniName        cstring(255)
inisection     string(50),auto
str            StringTheory
root           Long,auto
  code
  !self.trace('DriverFileMSSQL2Class.LoadLogging sdt=' & System{prop:DriverTracing} & ' driver:loaded=' & driver:loaded)
  If driver:loaded
    do InitLogVars
    Return
  End
  driver:loaded = true
  If System{prop:DriverTracing} = 0 then return.

  inisection = 'CW' & self.GetProp:Driver()
  !self.trace('inisection=' & inisection & '  tk=' & system{PROP:TraceKey})
  ! Check if global trace settings are set in the registry
  If system{PROP:TraceKey}
    str.SetValue(system{PROP:TraceKey})
    str.split('\')
    case upper(str.GetLine(1))
    of 'HKEY_CLASSES_ROOT'
      root = REG_CLASSES_ROOT
    of 'HKEY_CURRENT_USER_ROOT'
      root = REG_CURRENT_USER
    of 'HKEY_LOCAL_MACHINE'
      root = REG_LOCAL_MACHINE
    of 'HKEY_USERS'
      root = REG_USERS
    of 'HKEY_CURRENT_CONFIG'
      root = REG_CURRENT_CONFIG
    else
      root = 0
    End
    Str.DeleteLine(1)
    Str.Join('/')
    driver:trace           = GetReg(root,str.GetValue(),'Trace')             ! trace calls to the backend
    driver:BindData        = GetReg(root,str.GetValue(),'BindData')          ! show bound data
    driver:Profile         = GetReg(root,str.GetValue(),'Profile')           ! show clarion statements
    driver:Flush           = GetReg(root,str.GetValue(),'Flush')             ! flush after write
    driver:DebugLog        = GetReg(root,str.GetValue(),'DebugLog')          ! Output to Debugview
    driver:Details         = GetReg(root,str.GetValue(),'Details')           ! show record buffer contents
    driver:TraceIntoFiles  = GetReg(root,str.GetValue(),'TraceIntoFiles')    ! log commands generated by view engine
    driver:TraceFile       = GetReg(root,str.GetValue(),'TraceFile')            ! file to store tracing in
  Else
  ! Check if global trace settings are set in a custom inifile
    If system{PROP:TraceFile} = 'default'
      If osSHGetFolderPath(0, CSIDL_APPDATA, 0, 0, iniName) = 0
        ininame = iniName & '\SoftVelocity\Clarion\Drivers.ini'
      End
    ElsIf system{PROP:TraceFile}
      ininame = system{PROP:TraceFile}
    End
    !self.trace('IniName=' & clip(IniName) & ' inisection=' & inisection)
    If IniName
      driver:trace           = GetIni(inisection,'Trace',0,ininame)          ! trace calls to the backend               --
      driver:BindData        = GetIni(inisection,'BindData',0,ininame)       ! show bound data
      driver:Profile         = GetIni(inisection,'Profile',0,ininame)        ! show clarion statements
      driver:Flush           = GetIni(inisection,'Flush',0,ininame)          ! flush after write
      driver:DebugLog        = GetIni(inisection,'DebugLog',0,ininame)       ! Output to Debugview
      If driver:Profile
        driver:Details         = GetIni(inisection,'Details',0,ininame)        ! show record buffer contents
      Else
        driver:Details = 0
      End
      driver:TraceIntoFiles  = GetIni(inisection,'TraceIntoFiles',0,ininame) ! log commands generated by view engine
      driver:TraceFile       = GetIni(inisection,'TraceFile',0,ininame)      ! file to store tracing in                 --
    End
  End
  do InitLogVars
  !self.trace('loadlogging done driver:trace=' & driver:trace & ' driver:BindData=' & driver:BindData & ' driver:Profile=' & driver:Profile & ' driver:Flush=' & driver:Flush & ' driver:DebugLog=' & driver:DebugLog & ' driver:Details=' & driver:Details & ' driver:TraceIntoFiles=' & driver:TraceIntoFiles & ' driver:TraceFile=' & driver:TraceFile)

InitLogVars  routine
  self._logClarion = driver:Profile
  self._logSQL     = driver:trace
                   ! = driver:Flush
  self._logBind    = driver:BindData
  self._logData    = driver:Details
  self._logOptions = driver:trace ! same as SQL
  self._logExplain = false
  self._logConnections = driver:trace ! same as SQL
  self._LogFile = driver:TraceFile

!-----------------------------------------------------------------
DriverFileMSSQL2Class.CALL             Procedure(String pStoredProcedure,<? pParm1>,<? pParm2>,<? pParm3>,<? pParm4>,<? pParm5>,<? pParm6>,<? pParm7>,<? pParm8>,<? pParm9>,<? pParm10>,<? pParm11>,<? pParm12>,<? pParm13>,<? pParm14>,<? pParm15>,<? pParm16>,<? pParm17>,<? pParm18>,<? pParm19>,<? pParm20>)
str  stringtheory
x    Long,Auto
  code
  str.SetValue('{{ CALL ' & clip(pStoredProcedure) &'(')
  Loop x = 3 to 23                     ! remember, Class Methods Omitted by number, start at 2, so pParm1 is parameter 3
    If omitted(x) then break.
    If x = 3
      str.append('?')
    Else
      str.append(',?')
    End
  End
  str.append(')}')
  If self._executeSql(str,pParm1,pParm2,pParm3,pParm4,pParm5,pParm6,pParm7,pParm8,pParm9,pParm10,pParm11,pParm12,pParm13,pParm14,pParm15,pParm16,pParm17,pParm18,pParm19,pParm20) = Driver:ok
  End
  Return

!-----------------------------------------------------------------
DriverFileMSSQL2Class.CLEARPROPS                  Procedure()
  code
  parent.ClearProps()
  !self.SetProp:Separator('<9>')
  !self.SetProp:LineEndings('\n')
  !self.SetProp:AlwaysQuote(false)
  !self.SetProp:NullString('')
  Return

!-----------------------------------------------------------------
! In order to null-pad strings when binding, we need some memory set aside, with the string length + 1 to accomodate the null.
DriverFileMSSQL2Class._AfterParseFields    Procedure()
strx   &string,Auto
x      Long,Auto
  code
  !self.trace('DriverFileMSSQL2Class._AfterParseFields')
  parent._AfterParseFields()
  Return

!-----------------------------------------------------------------
! Postgres, SQ Lite, Oracle and Firebird use double quotes.
! Sql Server uses [ ], MySQL uses `. Derive as appropriate
DriverFileMSSQL2Class.WrapReserved       PROCEDURE(*cstring pColumn)
  code
  If pColumn[1] = '"'                            ! might have been set with a leading " in the dict. If so remove, and replace.
    Return '[' &  sub(pColumn,2,Len(pColumn)-2) & ']'
  End
  Return '[' & pColumn & ']'

!-----------------------------------------------------------------
DriverFileMSSQL2Class.UnwrapReserved    Procedure(*cstring pColumn)
  code
  If Left(pColumn,1) = '[' and Right(pColumn,1) = ']'
    Return sub(pColumn,2,Len(pColumn)-2)
  End
  Return parent.UnwrapReserved(pColumn)

!-----------------------------------------------------------------
DriverFileMSSQL2Class.UnwrapReserved    Procedure(*Astring pColumn)
Column  cstring(len(pColumn)+1)
  code
  Column = pColumn
  If Left(Column,1) = '[' and Right(Column,1) = ']'
    Return sub(Column,2,Len(Column)-2)
  End
  Return parent.UnwrapReserved(pColumn)

!=====================================================================================================================
!-----------------------------------------------------------------
DriverFileMSSQL2Class._BindParameter            Procedure(Long pStmt, Long pCount, ? pParm, DriverParmBufferClass pParmBuffer, Long pCodePage)
ParmType  Long,Auto
ParmSize  Long,Auto
ParmAddr  Long,Auto

result    Long
lg        Long
rl        Real
st        String(255)
len       Long
Found  byte

  code
  ParmType = Self.GetAnyType(pParm)
  ParmSize = self.GetAnySize(pParm)    ! only for Strings and Groups
  ParmAddr = self.GetAnyAddress(pParm)
  !self.trace('DriverFileMSSQL2Class._BindParameter ParmType=' & ParmType & ' ParmSize=' & ParmSize & ' ParmAddr=' & ParmAddr & ' size=' & size(pParm)  & ' len=' & len(pParm))
  If self._FindBindQueue(ParmAddr) = driver:ok
    Found = true
  End

  case ParmType
  of ClaByte
  orof ClaShort
  orof ClaUShort
  orof ClaLONG
    If not Found !InOut = SQL_PARAM_INPUT
      lg = pParm
      If self._logBind then self.Log('[BIND][bp1]' & pCount & ' (long) = ' & lg).
      pParmBuffer._SetParmBuffer(pCount,Address(lg),4,SQL_INTEGER,0,driver:Dispose,pCodepage)
      Self.ParameterSlip[pCount] = pParmBuffer.ParmBufferLen[pCount]
      result = SQLBindParameter(pStmt,pCount, SQL_PARAM_INPUT, SQL_C_LONG, SQL_INTEGER, 0, 0, pParmBuffer.ParmBufferAddr[pCount], 4, Self.ParameterSlip[pCount])
    Else
      If self._logBind then self.Log('[BIND][bp2]' & pCount & ' (long) AS INPUT_OUTPUT').
      Self.ParameterSlip[pCount] = 4
      result = SQLBindParameter(pStmt,pCount, SQL_PARAM_INPUT_OUTPUT, SQL_C_LONG, SQL_INTEGER, 0, 0, address(self.BindQueue.lg), 4, Self.ParameterSlip[pCount])
    End

  of ClaREAL
  orof ClaSREAL
    If not Found
      rl = pParm
      If self._logBind then self.Log('[BIND][bp3]' & pCount & ' (real) = ' & rl).
      pParmBuffer._SetParmBuffer(pCount,Address(rl),8,SQL_DOUBLE,0,driver:Dispose,pCodePage)
      Self.ParameterSlip[pCount] = pParmBuffer.ParmBufferLen[pCount]
      result = SQLBindParameter(pStmt,pCount, SQL_PARAM_INPUT, SQL_C_DOUBLE, SQL_DOUBLE, 0, 0, pParmBuffer.ParmBufferAddr[pCount], 8, Self.ParameterSlip[pCount])
    Else
      If self._logBind then self.Log('[BIND][bp4]' & pCount & ' (real) AS OUTPUT').
      Self.ParameterSlip[pCount] = 8
      result = SQLBindParameter(pStmt,pCount, SQL_PARAM_OUTPUT, SQL_C_DOUBLE, SQL_DOUBLE, 0, 0, address(self.BindQueue.rl), 8, Self.ParameterSlip[pCount])
    End

  of ClaSTRING
  orof ClaPSTRING
  orof ClaCSTRING
    If not Found
      st = pParm
      len  = len(clip(st))
      If self._logBind then self.Log('[BIND][bp5]' & pCount & ' (' & len & ') (string) = [' & pParm &']').
      pParmBuffer._SetParmBuffer(pCount,Address(st),len,SQL_CHAR,0,driver:Dispose,pCodePage)
      Self.ParameterSlip[pCount] = pParmBuffer.ParmBufferLen[pCount] !+ 1
      result = SQLBindParameter(pStmt, pCount, SQL_PARAM_INPUT, SQL_C_CHAR, SQL_CHAR, Len+1, 0, pParmBuffer.ParmBufferAddr[pCount], pParmBuffer.ParmBufferLen[pCount], Self.ParameterSlip[pCount])
    Else
      If self._logBind then self.Log('[BIND][bp6]' & pCount & ' (' & len & ') (string) AS OUTPUT').
      If Not self.BindQueue.st &= null
        Self.ParameterSlip[pCount] = len(self.BindQueue.st)
        result = SQLBindParameter(pStmt, pCount, SQL_PARAM_OUTPUT, SQL_C_CHAR, SQL_CHAR, Len, 0, address(self.BindQueue.st),  len(self.BindQueue.st), Self.ParameterSlip[pCount])
      ElsIf Not self.BindQueue.cst &= null
        Self.ParameterSlip[pCount] = len(self.BindQueue.cst)
        result = SQLBindParameter(pStmt, pCount, SQL_PARAM_OUTPUT, SQL_C_CHAR, SQL_CHAR, Len, 0, address(self.BindQueue.cst),  len(self.BindQueue.cst), Self.ParameterSlip[pCount])
      End
    End
  End
  If result <> SQL_SUCCESS AND result <> SQL_SUCCESS_WITH_INFO
    self.SetErrorMssql(SQL_HANDLE_STMT,pStmt,'[d075]')
  End

!-----------------------------------------------------------------
! Called from _BindParameter
! Blobs queue is loaded
DriverFileMSSQL2Class._BindBlob  Procedure(Long pStmt,Long pCount)
result  long,auto
len     long,auto
strmem  &string
  code
  !self.trace('_BindBlob pStmt=' & pStmt & ' pCount=' & pCount )
  If self.blobs.Memo
    If not self.Blobs.memostring &= null
      If Self.Blobs.Binary
        ! BINARY MEMO Not NULL
        If self._logBind then self.Log('[BIND][bb1]' & pCount & ' (memo) ' & self.Blobs.memostring).
        Self.ParameterSlip[pCount] = Self.Blobs.MemoSize
        result = SQLBindParameter(pStmt, pCount, SQL_PARAM_INPUT, SQL_C_BINARY, SQL_LONGVARBINARY, |
                                  INT_MAX, 0, address(self.Blobs.memostring), Self.Blobs.MemoSize, Self.ParameterSlip[pCount])
        !self.trace('Z51 SBP')
        If result <> SQL_SUCCESS AND result <> SQL_SUCCESS_WITH_INFO
          self.SetErrorMssql(SQL_HANDLE_STMT,pStmt,'[d061]')
        End
      Else
        ! TEXT MEMO Not NULL
        If self._logBind then self.Log('[BIND][bb2]' & pCount & ' (memo) ' & self.Blobs.memostring).
        len = len(clip(self.Blobs.memostring))
        Self.ParameterSlip[pCount] = len
        result = SQLBindParameter(pStmt, pCount, SQL_PARAM_INPUT, SQL_C_CHAR, SQL_LONGVARCHAR, |
                                 INT_MAX, 0, address(self.Blobs.memostring), len+1, Self.ParameterSlip[pCount])
        !self.trace('Z52 SBP')
        If result <> SQL_SUCCESS AND result <> SQL_SUCCESS_WITH_INFO
          self.SetErrorMssql(SQL_HANDLE_STMT,pStmt,'[d062]')
        End
      End
    Else
      ! NULL MEMO
      If self._logBind then self.Log('[BIND][bb3]' & pCount & ' (null)').
      Self.ParameterSlip[pCount] = SQL_NULL_DATA
      result = SQLBindParameter(pStmt, pCount, SQL_PARAM_INPUT, SQL_C_CHAR, SQL_VARCHAR,0, 0, 0, 0, Self.ParameterSlip[pCount])
      !self.trace('Z53 SBP')
      If result <> SQL_SUCCESS AND result <> SQL_SUCCESS_WITH_INFO
        self.SetErrorMssql(SQL_HANDLE_STMT,pStmt,'[d063]')
      End
    End
  Else
    If self.Blobs.handle
      If Self.Blobs.Binary
        ! BINARY BLOB NOT NULL
        If self._logBind
          If self.Blobs.handle
            strmem &= self.Blobs.handle & ':' & Self.Blobs.HandleSize
            self.Log('[BIND][bb4]' & pCount & ' (blob)  size=' & Self.Blobs.HandleSize & ' ' & strmem)
          else
            self.Log('[BIND][bb5]' & pCount & ' (blob) size=' & Self.Blobs.HandleSize)
          End
        End
        Self.ParameterSlip[pCount] = Self.Blobs.HandleSize
        result = SQLBindParameter(pStmt, pCount, SQL_PARAM_INPUT, SQL_C_BINARY, SQL_LONGVARBINARY, |
                                  INT_MAX, 0, self.Blobs.handle, Self.Blobs.HandleSize, Self.ParameterSlip[pCount])
        !self.trace('Z54 SBP')
        If result <> SQL_SUCCESS AND result <> SQL_SUCCESS_WITH_INFO
          self.SetErrorMssql(SQL_HANDLE_STMT,pStmt,'[d064]')
        End
      Else
        ! TEXT BLOB NOT NULL
        If self._logBind
          If self.Blobs.handle
            strmem &= self.Blobs.handle & ':' & Self.Blobs.HandleSize
            self.Log('[BIND][bb6]' & pCount & ' (blob) ' & strmem)
          Else
            self.Log('[BIND][bb7]' & pCount & ' (empty blob)')
          End
        End
        Self.ParameterSlip[pCount] = Self.Blobs.HandleSize
        result = SQLBindParameter(pStmt, pCount, SQL_PARAM_INPUT, SQL_C_CHAR, SQL_LONGVARCHAR,  |
                                 INT_MAX, 0, self.Blobs.handle, Self.Blobs.HandleSize+1, Self.ParameterSlip[pCount])
        !self.trace('Z55 SBP')
        If result <> SQL_SUCCESS AND result <> SQL_SUCCESS_WITH_INFO
          self.SetErrorMssql(SQL_HANDLE_STMT,pStmt,'[d065]')
        End
      End
    Else
      ! BLOB NULL
      If self._logBind then self.Log('[BIND][bb8]' & pCount & ' (null)').
      Self.ParameterSlip[pCount] = 0
      If Self.Blobs.Binary
        ! BLOB NULL BINARY
        result = SQLBindParameter(pStmt, pCount, SQL_PARAM_INPUT, SQL_C_BINARY, SQL_LONGVARBINARY,INT_MAX, 0, 0, 0, Self.ParameterSlip[pCount])
        !self.trace('Z56 SBP')
      Else
        ! BLOB NULL NOT BINARY
        result = SQLBindParameter(pStmt, pCount, SQL_PARAM_INPUT, SQL_C_BINARY, SQL_LONGVARCHAR,INT_MAX, 0, 0, 0, Self.ParameterSlip[pCount])
        !self.trace('Z57 SBP')
      End
      If result <> SQL_SUCCESS AND result <> SQL_SUCCESS_WITH_INFO
        self.SetErrorMssql(SQL_HANDLE_STMT,pStmt,'[d066]')
      End
    End
  End

!-----------------------------------------------------------------
! binds one field to a parameter. Source of the field is the mem address in the 3rd parameter.
!
! The self.Fields queue must be loaded with the correct record before this is called.
! Do not call this for Blob or Memo fields. Fields node is loaded
DriverFileMSSQL2Class._BindField  Procedure(Long pStmt,Long pCount, Long pAddress, DriverParmBufferClass pParmBuffer, Long pCodePage)
fieldtype long,auto
result  long,auto
len     long,auto
p       long,auto
x       long,auto
sqtype  string(20),auto
strmem  &string
cstr    &cstring
pstr    &pstring
bin     string(16),auto
sxc     cstring(40),auto
sx      string(40),auto
bt      byte,over(sx)
sh      short,over(sx)
ush     ushort,over(sx)
lg      long,over(sx)
ulg     ulong,over(sx)
rl      real,over(sx)
srl     sreal,over(sx)
ts      like(TimeStampGroupType)
dt      like(DateGroupType)
tsz     like(TimeStampTZGroupType)
tm      like(TimeGroupType)
bound   byte

datetimeoffset  group
date              date
time              time
timel             long,over(time)
offset            long
                end

datetime  group
date         date
time         time
timel        long,over(time)
          end
datetime2 group
date         date
time         long
          end
datetime3 group
date         long
time         time
          end
datetime4 group
date         long
time         long
          end

i64  group,pre()
lo     ulong
hi     Long
     End

  code
  !self.trace('_BindField pStmt=' & pStmt & ' pCount=' & pCount & ' pAddress=' & pAddress & ' rec_buf =' & self.ClaFCB.rec_buf)
  If not self.Fields.Interface &= null
  !region - Custom Fields
    len = self.Fields.SourceSize
    If len
      strmem &= new string(len)
      self.Fields.Interface.FromRecordField(self.Fields.Type,pAddress,self.Fields.length,address(strmem),len)
      sqtype = self.Fields.Interface.GetSQLType()
      p = instring('(',sqtype,1,1)
      if p
        sqtype = sub(sqtype,1,p-1)
      End
      case upper(sqtype)
      of 'INT'
      orof 'INTEGER'
      orof 'NUMBER'
        sx = strmem
        case len
        of 1
          If self._logBind then self.Log('[BIND][bi1]' & pCount & ' (byte) = ' & bt).
          pParmBuffer._SetParmBuffer(pCount,address(strmem),1,SQL_SMALLINT,0,driver:Dispose,pCodePage)
          Self.ParameterSlip[pCount] = 1
          result = SQLBindParameter(pStmt,pCount, SQL_PARAM_INPUT, SQL_C_CHAR, SQL_SMALLINT, SQL_IGNORED, SQL_IGNORED, pParmBuffer.ParmBufferAddr[pCount], SQL_IGNORED, Self.ParameterSlip[pCount]);   !!!todo check sql_smallint
          If result <> SQL_SUCCESS AND result <> SQL_SUCCESS_WITH_INFO
            self.SetErrorMssql(SQL_HANDLE_STMT,pStmt,'[d041]')
          End
        of 2
          If self._logBind then self.Log('[BIND][bi1]' & pCount & ' (short) = ' & sh).
          pParmBuffer._SetParmBuffer(pCount,address(strmem),2,SQL_SMALLINT,0,driver:Dispose,pCodePage)
          Self.ParameterSlip[pCount] = 2
          result = SQLBindParameter(pStmt,pCount, SQL_PARAM_INPUT, SQL_C_SHORT, SQL_SMALLINT, SQL_IGNORED, SQL_IGNORED, pParmBuffer.ParmBufferAddr[pCount], SQL_IGNORED, Self.ParameterSlip[pCount]);
          If result <> SQL_SUCCESS AND result <> SQL_SUCCESS_WITH_INFO
            self.SetErrorMssql(SQL_HANDLE_STMT,pStmt,'[d042]')
          End
        of 4
          If self._logBind then self.Log('[BIND][bi2]' & pCount & ' (long) = ' & lg).
          pParmBuffer._SetParmBuffer(pCount,address(strmem),4,SQL_INTEGER,0,driver:Dispose,pCodePage)
          Self.ParameterSlip[pCount] = 4
          result = SQLBindParameter(pStmt,pCount, SQL_PARAM_INPUT, SQL_C_LONG, SQL_INTEGER, SQL_IGNORED, SQL_IGNORED, pParmBuffer.ParmBufferAddr[pCount], SQL_IGNORED, Self.ParameterSlip[pCount]);
          If result <> SQL_SUCCESS AND result <> SQL_SUCCESS_WITH_INFO
            self.SetErrorMssql(SQL_HANDLE_STMT,pStmt,'[d043]')
          End
        of 8
          !!!todo int64
        End
      of 'REAL'
      orof 'FLOAT'
      orof 'DOUBLE'
        If self._logBind then self.Log('[BIND][bi3]' & pCount & ' (real) = ' & rl).
        pParmBuffer._SetParmBuffer(pCount,address(strmem),8,SQL_DOUBLE,0,driver:Dispose,pCodePage)
        self.ParameterSlip[pCount] = 8
        result = SQLBindParameter(pStmt,pCount, SQL_PARAM_INPUT, SQL_C_DOUBLE, SQL_DOUBLE, SQL_IGNORED, SQL_IGNORED, pParmBuffer.ParmBufferAddr[pCount], SQL_IGNORED, Self.ParameterSlip[pCount]);
        If result <> SQL_SUCCESS AND result <> SQL_SUCCESS_WITH_INFO
          self.SetErrorMssql(SQL_HANDLE_STMT,pStmt,'[d044]')
        End
      of 'SREAL'
        If self._logBind then self.Log('[BIND][bi4]' & pCount & ' (sreal) = ' & srl).
        pParmBuffer._SetParmBuffer(pCount,address(strmem),4,SQL_REAL,0,driver:Dispose,pCodePage)
        self.ParameterSlip[pCount] = 4
        result = SQLBindParameter(pStmt,pCount, SQL_PARAM_INPUT, SQL_C_FLOAT, SQL_REAL, SQL_IGNORED, SQL_IGNORED, pParmBuffer.ParmBufferAddr[pCount], SQL_IGNORED, Self.ParameterSlip[pCount]);
        If result <> SQL_SUCCESS AND result <> SQL_SUCCESS_WITH_INFO
          self.SetErrorMssql(SQL_HANDLE_STMT,pStmt,'[d045]')
        End
      of 'TEXT'
      orof 'CHAR'
      orof 'NCHAR'
      orof 'VARCHAR'
      orof 'NVARCHAR'
        If self._logBind then self.Log('[BIND][bi5]' & pCount & ' (string: ' & len & ')[' & strmem & ']').
        pParmBuffer._SetParmBuffer(pCount,address(strmem),len,self.DatabaseFieldType[self.Fields.Index],0,driver:Dispose,pCodePage)
        Self.ParameterSlip[pCount] = len
        result = SQLBindParameter(pStmt, pCount, SQL_PARAM_INPUT, SQL_C_CHAR, self.DatabaseFieldType[self.Fields.Index] , self.DatabaseFieldSize[self.Fields.Index], 0,  pParmBuffer.ParmBufferAddr[pCount], pParmBuffer.ParmBufferLen[pCount]+1, Self.ParameterSlip[pCount] )
        If result <> SQL_SUCCESS !AND result <> SQL_SUCCESS_WITH_INFO
          self.SetErrorMssql(SQL_HANDLE_STMT,pStmt,'[d046]')
        End
      of 'VARBINARY'

      of 'UNIQUEIDENTIFIER'
      orof 'UUID'
        If self._logBind then self.Log('[BIND][bi6]' & pCount & ' (uniqueidentifier-reversed ' & len & ')[' & strmem & ']').
        pParmBuffer._SetParmBuffer(pCount,address(strmem),len,self.DatabaseFieldType[self.Fields.Index],0,driver:Dispose,pCodePage)
        Self.ParameterSlip[pCount] = len
        result = SQLBindParameter(pStmt, pCount, SQL_PARAM_INPUT, SQL_C_BINARY, self.DatabaseFieldType[self.Fields.Index] , self.DatabaseFieldSize[self.Fields.Index], 0,  pParmBuffer.ParmBufferAddr[pCount], pParmBuffer.ParmBufferLen[pCount]+1, Self.ParameterSlip[pCount] )
        If result <> SQL_SUCCESS !AND result <> SQL_SUCCESS_WITH_INFO
          self.SetErrorMssql(SQL_HANDLE_STMT,pStmt,'[d046]')
        End

      End
      Dispose(strmem)
    End
  ElsIf self.Fields.DimProduct > 1
  !endregion
  !region - Arrays
    do HandleArray
  Else
  !endregion
  !region - Clarion Fields
    self.Fields &= self._WithFieldNode(self.Fields.index)
    strmem &= pAddress & ':' & self.Fields.Length
    sx = strmem
    !self.trace('_BindField ' & self.Fields.index & ' self.Fields.Type = ' & self.Fields.Type & ' self.Fields.Length=' & self.Fields.Length & ' self.fields.SqlTimeStamp='  & self.fields.SqlTimeStamp & ' self.Fields.binary=' & self.Fields.binary & ' self.DatabaseFieldType[i]=' & self.DatabaseFieldType[self.Fields.Index] & ' self.DatabaseFieldSize[i]=' & self.DatabaseFieldSize[self.Fields.Index] & ' len(strmem) = ' & len(strmem) & ' self.fields.SQLType=' & self.fields.SQLType)
    FieldType = self.Fields.Type
    If self.DatabaseFieldType[self.Fields.index] = SQL_BIT
      FieldType = ClaByte
    End
    Case FieldType
    !region - ClaCSTRING
    Of ClaCSTRING
      ! NULL CSTRING
      If self.null_(self.Fields.index) = true
        If self._logBind then self.Log('[BIND][bf1]' & pCount & ' (cstring) as (null)').
        Self.ParameterSlip[pCount] = SQL_NULL_DATA
        result = SQLBindParameter(pStmt, pCount, SQL_PARAM_INPUT, SQL_C_CHAR, self.DatabaseFieldType[self.Fields.Index], self.DatabaseFieldSize[self.Fields.Index], 0, 0, 0, Self.ParameterSlip[pCount])
        !self.trace('Z8 SBP')
      Else
      ! NOT NULL CSTRING
        If self.fields.SqlTimeStamp = driver:StringToTimeStamp2 ! string of the form yyyy-mm-dd hh:mm:ss.ccccccc
          do BindStringToTimeStamp2
        ElsIf self.fields.SqlTimeStamp = driver:StringToTimeStampTZ ! string of the form yyyy-mm-dd hh:mm:ss.ccccccc +01:30
          do BindStringToTimeStampTZ

        ElsIf upper(sub(self.fields.SQLType,1,4)) = 'TIME'
          cstr &= pAddress & ':' & self.Fields.Length
          If self._logBind then self.Log('[BIND][bf51]' & pCount & ' (time) = ' & cstr).
          pParmBuffer._SetParmBuffer(pCount,address(cstr),len(cstr),SQL_SS_TIME2,0,driver:Dispose,pCodePage)
          Self.ParameterSlip[pCount] = SQL_NTS
          result = SQLBindParameter(pStmt,pCount, SQL_PARAM_INPUT, SQL_C_CHAR, SQL_SS_TIME2, len(cstr), 7, pParmBuffer.ParmBufferAddr[pCount], pParmBuffer.ParmBufferLen[pCount], Self.ParameterSlip[pCount])

        Else ! CString
          cstr &= pAddress & ':' & self.Fields.Length
          len = len(cstr)
          pParmBuffer._SetParmBuffer(pCount,pAddress,self.Fields.Length,self.DatabaseFieldType[self.Fields.Index],0,driver:Dispose,pCodePage)
          If self._logBind then self.Log('[BIND][bf2]' & pCount & ' (cstring) [' & cstr & '][' & len & '] into ' & self.DatabaseFieldType[self.Fields.Index] & '(' & self.DatabaseFieldSize[self.Fields.Index] & ')').
          Self.ParameterSlip[pCount] = SQL_NTS
          result = SQLBindParameter(pStmt, pCount, SQL_PARAM_INPUT, SQL_C_CHAR, self.DatabaseFieldType[self.Fields.Index] , self.DatabaseFieldSize[self.Fields.Index], 0, pParmBuffer.ParmBufferAddr[pCount], pParmBuffer.ParmBufferLen[pCount], Self.ParameterSlip[pCount] )
        End
      End
      If result <> SQL_SUCCESS AND result <> SQL_SUCCESS_WITH_INFO
        self.SetErrorMssql(SQL_HANDLE_STMT,pStmt,'[d047]')
      End
    !endregion
    !region - ClaPSTRING
    Of ClaPSTRING
      ! NULL PSTRING
      If self.null_(self.Fields.index) = true
        If self._logBind then self.Log('[BIND][bf3]' & pCount & ' (pstring) as (null)').
        Self.ParameterSlip[pCount] = SQL_NULL_DATA
        result = SQLBindParameter(pStmt, pCount, SQL_PARAM_INPUT, SQL_C_CHAR, self.DatabaseFieldType[self.Fields.Index], self.DatabaseFieldSize[self.Fields.Index], 0, 0, 0, Self.ParameterSlip[pCount])
        !self.trace('Z11 SBP')
      Else
      ! NOT NULL PSTRING
        peek(pAddress,bt)
        If self._logBind then self.Log('[BIND][bf34]' & pCount & ' (pstring: ' & bt & ')[' & sub(strmem,1,bt) & ']').
        pParmBuffer._SetParmBuffer(pCount,pAddress+1,bt,self.DatabaseFieldType[self.Fields.Index],0,driver:Dispose,pCodePage)
        Self.ParameterSlip[pCount] = bt
        result = SQLBindParameter(pStmt, pCount, SQL_PARAM_INPUT, SQL_C_BINARY, self.DatabaseFieldType[self.Fields.Index] , self.DatabaseFieldSize[self.Fields.Index], 0,  pParmBuffer.ParmBufferAddr[pCount], pParmBuffer.ParmBufferLen[pCount], Self.ParameterSlip[pCount] )
      End
      If result <> SQL_SUCCESS AND result <> SQL_SUCCESS_WITH_INFO
        self.SetErrorMssql(SQL_HANDLE_STMT,pStmt,'[d048]')
      End
    !endregion
    !region - ClaSTRING
    Of ClaSTRING
      If self.fields.SqlTimeStamp = driver:GroupOverTimeStampTz
        len = len(sx)
        ! NULL TIMESTAMPOFFSET
        If self.null_(self.Fields.index) = true
          If self._logBind then self.Log('[BIND][bf53]' & pCount & ' (timestampoffset) as (null)').
          Self.ParameterSlip[pCount] = SQL_NULL_DATA
          result = SQLBindParameter(pStmt, pCount, SQL_PARAM_INPUT, SQL_C_BINARY, self.DatabaseFieldType[self.Fields.Index], self.DatabaseFieldSize[self.Fields.Index], 0, 0, 0, Self.ParameterSlip[pCount])
        Elsif len >= 8 ! allow date/time over timestampoffset, even if offset part missing.
        ! NOT NULL TIMESTAMPOFFSET
          memcpy(address(datetimeoffset), pAddress,12)

          tsz.hour  = bshift(datetimeoffset.timel,-24)
          tsz.minute = band(bshift(datetimeoffset.timel,-16),255)
          tsz.second = band(bshift(datetimeoffset.timel,-8),255)
          tsz.fraction = band(datetimeoffset.timel,255) * 10000000
          tsz.timezone_hour  = datetimeoffset.offset / 360000
          tsz.timezone_minute = (datetimeoffset.offset % 360000) / 6000
          if tsz.timezone_hour < 0
            tsz.timezone_minute = -tsz.timezone_minute   ! minute must have same sign as hour
          End
          tsz.year = year(datetimeoffset.date)
          tsz.month = month(datetimeoffset.date)
          tsz.day   = day(datetimeoffset.date)

          If tsz.year = 0 and tsz.month = 0 and tsz.day = 0
            case self.opt:ZeroDate
            of -1
              If self._logBind then self.Log('[BIND][bf54]' & pCount & ' (timestampoffset) as (null)').
              Self.ParameterSlip[pCount] = SQL_NULL_DATA
              result = SQLBindParameter(pStmt, pCount, SQL_PARAM_INPUT, SQL_C_BINARY, self.DatabaseFieldType[self.Fields.Index], self.DatabaseFieldSize[self.Fields.Index], 0, 0, 0, Self.ParameterSlip[pCount])
              If result <> SQL_SUCCESS AND result <> SQL_SUCCESS_WITH_INFO
                self.SetErrorMssql(SQL_HANDLE_STMT,pStmt,'[d048]')
              End
              Return
            of 0
            of 1
              tsz.year  = 1
              tsz.month = 1
              tsz.day   = 1
            else
              tsz.year  = self.opt:ZeroDate / 10000
              tsz.month = (self.opt:ZeroDate / 100) % 100
              tsz.day   = self.opt:ZeroDate % 100
            end
          End
          If self._logBind then self.Log('[BIND][bf55]' & pCount & ' (timestampoffset) ' & size(tsz) &' [' & format(tsz.year,'@n04') & '-' & format(tsz.month,'@n02') &'-' & format(tsz.day,'@n02') & ' ' & format(tsz.hour,'@n02') & ':' & format(tsz.minute,'@n02') & ':' & format(tsz.second,'@n02') & '.' & format(tsz.fraction/10000000,'@n03') & choose(tsz.timezone_hour > 0 ,' +' & format(tsz.timezone_hour,@n02),' ' & format(tsz.timezone_hour,@n-03)) & ':' & format(tsz.timezone_minute,@n02) & '] ' ).
          pParmBuffer._SetParmBuffer(pCount,address(tsz),size(tsz),SQL_SS_TIMESTAMPOFFSET,0,driver:Dispose,pCodePage)
          Self.ParameterSlip[pCount] = size(tsz)
          result = SQLBindParameter(pStmt, pCount, SQL_PARAM_INPUT, SQL_C_BINARY, SQL_SS_TIMESTAMPOFFSET , size(tsz), 7,  pParmBuffer.ParmBufferAddr[pCount], 0, Self.ParameterSlip[pCount] )
        End

      ElsIf self.fields.SqlTimeStamp >= driver:GroupOverTimeStamp and self.fields.SqlTimeStamp <= driver:GroupOverTimeStamp4
        len = len(strmem)
        ! NULL TIMESTAMP
        If self.null_(self.Fields.index) = true
          If self._logBind then self.Log('[BIND][bf4]' & pCount & ' (timestamp) as (null)').
          Self.ParameterSlip[pCount] = SQL_NULL_DATA
          result = SQLBindParameter(pStmt, pCount, SQL_PARAM_INPUT, SQL_C_CHAR, self.DatabaseFieldType[self.Fields.Index], self.DatabaseFieldSize[self.Fields.Index], 0, 0, 0, Self.ParameterSlip[pCount])
          !self.trace('Z12 SBP')
        Elsif len >= 8
        ! NOT NULL TIMESTAMP
          case self.fields.SqlTimeStamp
          of driver:GroupOverTimeStamp   ! Date,Time
            memcpy(address(datetime), pAddress,8)

          of driver:GroupOverTimeStamp2  ! Date,Long
            memcpy(address(datetime2), pAddress,8)
            datetime.date = datetime2.date
            datetime.time = datetime2.time

          of driver:GroupOverTimeStamp3  ! Long,Time
            memcpy(address(datetime3), pAddress,8)
            datetime.date = datetime3.date                  !!!todo simple Long to Date conversion, but doesn't support dates < 1801
            datetime.time = datetime3.time

          of driver:GroupOverTimeStamp4  ! Long,Long
            memcpy(address(datetime4), pAddress,8)         !!!todo simple Long to Date conversion, but doesn't support dates < 1801
            datetime.date = datetime4.date
            datetime.time = datetime4.time

          End
          ts.hour  = bshift(datetime.timel,-24)!datetime.time / 360000
          ts.minute = band(bshift(datetime.timel,-16),255)!(datetime.time % 360000) / 6000
          ts.second = band(bshift(datetime.timel,-8),255)!(datetime.time % 6000) / 100
          ts.fraction = band(datetime.timel,255) * 10000000 !(datetime.time % 100) * 10000000

          !memcpy(address(datetime), pAddress,8)
          ts.year = year(datetime.date)
          ts.month = month(datetime.date)
          ts.day   = day(datetime.date)
          If ts.year = 0 and ts.month = 0 and ts.day = 0
            case self.opt:ZeroDate
            of -1
              If self._logBind then self.Log('[BIND][bf5]' & pCount & ' (timestamp) as (null)').
              Self.ParameterSlip[pCount] = SQL_NULL_DATA
              result = SQLBindParameter(pStmt, pCount, SQL_PARAM_INPUT, SQL_C_TYPE_TIMESTAMP, self.DatabaseFieldType[self.Fields.Index], self.DatabaseFieldSize[self.Fields.Index], 0, 0, 0, Self.ParameterSlip[pCount])
              If result <> SQL_SUCCESS AND result <> SQL_SUCCESS_WITH_INFO
                self.SetErrorMssql(SQL_HANDLE_STMT,pStmt,'[d048]')
              End
              !self.trace('Z13 SBP')
              Return
            of 0
            of 1
              ts.year  = 1
              ts.month = 1
              ts.day   = 1
            else
              ts.year  = self.opt:ZeroDate / 10000
              ts.month = (self.opt:ZeroDate / 100) % 100
              ts.day   = self.opt:ZeroDate % 100
            end
          End
          If self._logBind then self.Log('[BIND][bf6]' & pCount & ' (timestamp) ' & size(ts) &' [' & format(ts.year,'@n04') & '-' & format(ts.month,'@n02') &'-' & format(ts.day,'@n02') & ' ' & format(ts.hour,'@n02') & ':' & format(ts.minute,'@n02') & ':' & format(ts.second,'@n02') & '.' & format(ts.fraction/10000000,'@n03') & '] ' ).
          pParmBuffer._SetParmBuffer(pCount,address(ts),size(ts),SQL_TYPE_TIMESTAMP,0,driver:Dispose,pCodePage)
          Self.ParameterSlip[pCount] = size(ts)
          result = SQLBindParameter(pStmt, pCount, SQL_PARAM_INPUT, SQL_C_TYPE_TIMESTAMP, SQL_TYPE_TIMESTAMP , 27, 7,  pParmBuffer.ParmBufferAddr[pCount], 0, Self.ParameterSlip[pCount] )
          !self.trace('Z14 SBP')
        End
      ElsIf self.fields.SqlTimeStamp = driver:StringToTimeStamp2 ! string of the form yyyy-mm-dd hh:mm:ss.ccccccc
        do BindStringToTimeStamp2
      ElsIf self.fields.SqlTimeStamp = driver:StringToTimeStampTZ ! string of the form yyyy-mm-dd hh:mm:ss.ccccccc +01:30
        do BindStringToTimeStampTZ

      ElsIf self.Fields.binary = false
        ! NOT BINARY STRING NULL
        If self.null_(self.Fields.index) = true
          If self._logBind then self.Log('[BIND][bf7]' & pCount & ' (string) as (null)').
          Self.ParameterSlip[pCount] = SQL_NULL_DATA
          result = SQLBindParameter(pStmt, pCount, SQL_PARAM_INPUT, SQL_C_CHAR, self.DatabaseFieldType[self.Fields.Index], self.DatabaseFieldSize[self.Fields.Index], 0, 0, 0, Self.ParameterSlip[pCount])
          !self.trace('Z15 SBP')
        Else
        ! NOT BINARY STRING NOT NULL
          If upper(sub(self.fields.SQLType,1,4)) = 'TIME'
            If self._logBind then self.Log('[BIND][bf52]' & pCount & ' (time) = ' & clip(strmem)).
            pParmBuffer._SetParmBuffer(pCount,address(strmem),len(strmem),SQL_SS_TIME2,0,driver:Dispose,pCodePage)
            Self.ParameterSlip[pCount] = SQL_NTS
            result = SQLBindParameter(pStmt,pCount, SQL_PARAM_INPUT, SQL_C_CHAR, SQL_SS_TIME2, len(strmem), 7, pParmBuffer.ParmBufferAddr[pCount], pParmBuffer.ParmBufferLen[pCount], Self.ParameterSlip[pCount])
          Else
            len = len(strmem)
            If self._logBind then self.Log('[BIND][bf8]' & pCount & ' (string: ' & len & ')[' & strmem & ']').
            pParmBuffer._SetParmBuffer(pCount,pAddress,Len,self.DatabaseFieldType[self.Fields.Index],0,driver:Dispose,pCodePage)
            Self.ParameterSlip[pCount] = len
            result = SQLBindParameter(pStmt, pCount, SQL_PARAM_INPUT, SQL_C_CHAR, self.DatabaseFieldType[self.Fields.Index] , self.DatabaseFieldSize[self.Fields.Index], 0,  pParmBuffer.ParmBufferAddr[pCount], pParmBuffer.ParmBufferLen[pCount]+1, Self.ParameterSlip[pCount] )
          End
        End
        If result <> SQL_SUCCESS !AND result <> SQL_SUCCESS_WITH_INFO
          self.SetErrorMssql(SQL_HANDLE_STMT,pStmt,'[d049]')
        End

      Else
        !  BINARY STRING NULL
        If self.null_(self.Fields.index) = true
          If self._logBind then self.Log('[BIND][bf9]' & pCount & ' (binary string) as (null)').
          Self.ParameterSlip[pCount] = SQL_NULL_DATA
          result = SQLBindParameter(pStmt, pCount, SQL_PARAM_INPUT, SQL_C_BINARY, self.DatabaseFieldType[self.Fields.Index], self.DatabaseFieldSize[self.Fields.Index], 0, 0, 0, Self.ParameterSlip[pCount])
          !self.trace('Z17 SBP')
        Else
          Self.ParameterSlip[pCount] = self.Fields.Length
          If self._logBind then self.Log('[BIND][bf10]' & pCount & ' (binarystring: ' & self.Fields.Length & ')[' & strmem & ']').
          pParmBuffer._SetParmBuffer(pCount,pAddress,self.Fields.Length,self.DatabaseFieldType[self.Fields.Index],0,driver:Dispose,pCodePage)
          result = SQLBindParameter(pStmt, pCount, SQL_PARAM_INPUT, SQL_C_BINARY, self.DatabaseFieldType[self.fields.Index], self.DatabaseFieldSize[self.fields.Index], 0, pParmBuffer.ParmBufferAddr[pCount], pParmBuffer.ParmBufferLen[pCount], Self.ParameterSlip[pCount])
          !self.trace('Z18 SBP')
        End
        If result <> SQL_SUCCESS AND result <> SQL_SUCCESS_WITH_INFO
          self.SetErrorMssql(SQL_HANDLE_STMT,pStmt,'[d050]')
        End
      End
    !endregion
    !region - ClaREAL
    of ClaREAL
      ! NULL REAL
      If self.null_(self.Fields.index) = true
        If self._logBind then self.Log('[BIND][bf11]' & pCount & ' (real) as (null)').
        Self.ParameterSlip[pCount] = SQL_NULL_DATA
        result = SQLBindParameter(pStmt, pCount, SQL_PARAM_INPUT, SQL_C_DOUBLE, self.DatabaseFieldType[self.Fields.Index], self.DatabaseFieldSize[self.Fields.Index], 0, pAddress, 8, Self.ParameterSlip[pCount])
        !self.trace('Z17 SBP')
      Else
      ! NOT NULL REAL
        If self._logBind then self.Log('[BIND][bf12]' & pCount & ' (real) = ' & rl).
        pParmBuffer._SetParmBuffer(pCount,pAddress,8,self.DatabaseFieldType[self.Fields.Index],0,driver:Dispose,pCodePage)
        Self.ParameterSlip[pCount] = 8
        result = SQLBindParameter(pStmt,pCount, SQL_PARAM_INPUT, SQL_C_DOUBLE, self.DatabaseFieldType[self.Fields.Index], self.DatabaseFieldSize[self.Fields.Index], 0, pParmBuffer.ParmBufferAddr[pCount], pParmBuffer.ParmBufferLen[pCount], Self.ParameterSlip[pCount])
        !self.trace('Z19 SBP')
      End
      If result <> SQL_SUCCESS AND result <> SQL_SUCCESS_WITH_INFO
        self.SetErrorMssql(SQL_HANDLE_STMT,pStmt,'[d051]')
      End
    !endregion
    !region - ClaSREAL
    of ClaSREAL
      !NULL SREAL
      If self.null_(self.Fields.index) = true
        If self._logBind then self.Log('[BIND][bf13]' & pCount & ' (sreal) as (null)').
        Self.ParameterSlip[pCount] = SQL_NULL_DATA
        result = SQLBindParameter(pStmt, pCount, SQL_PARAM_INPUT, SQL_C_FLOAT, self.DatabaseFieldType[self.Fields.Index], self.DatabaseFieldSize[self.Fields.Index], 0, pAddress, 4, Self.ParameterSlip[pCount])
        !self.trace('Z17 SBP')
      Else
      ! NOT NULL SREAL
        If self._logBind then self.Log('[BIND][bf14]' & pCount & ' (sreal) = ' & srl).
        pParmBuffer._SetParmBuffer(pCount,pAddress,4,self.DatabaseFieldType[self.Fields.Index],0,driver:Dispose,pCodePage)
        Self.ParameterSlip[pCount] = 4
        result = SQLBindParameter(pStmt,pCount, SQL_PARAM_INPUT, SQL_C_FLOAT, self.DatabaseFieldType[self.Fields.Index], self.DatabaseFieldSize[self.Fields.Index], 0, pParmBuffer.ParmBufferAddr[pCount], pParmBuffer.ParmBufferLen[pCount], Self.ParameterSlip[pCount])
        !self.trace('Z20 SBP')
      End
      If result <> SQL_SUCCESS AND result <> SQL_SUCCESS_WITH_INFO
        self.SetErrorMssql(SQL_HANDLE_STMT,pStmt,'[d052]')
      End
    !endregion
    !region - ClaBYTE
    of ClaBYTE
      ! NULL BYTE
      If self.null_(self.Fields.index) = true
        If self._logBind then self.Log('[BIND][bf15]' & pCount & ' (byte) as (null)').
        Self.ParameterSlip[pCount] = SQL_NULL_DATA
        result = SQLBindParameter(pStmt, pCount, SQL_PARAM_INPUT, SQL_C_TINYINT, self.DatabaseFieldType[self.Fields.Index], self.DatabaseFieldSize[self.Fields.Index], 0, pAddress, 1, Self.ParameterSlip[pCount])
        !self.trace('Z17 SBP')
      Else
        If self._logBind then self.Log('[BIND][bf16]' & pCount & ' (byte) = ' & bt).
        pParmBuffer._SetParmBuffer(pCount,pAddress,1,self.DatabaseFieldType[self.Fields.Index],0,driver:Dispose,pCodePage)
        Self.ParameterSlip[pCount] = 1
        result = SQLBindParameter(pStmt,pCount, SQL_PARAM_INPUT, SQL_C_TINYINT, self.DatabaseFieldType[self.Fields.Index], self.DatabaseFieldSize[self.Fields.Index], 0, pParmBuffer.ParmBufferAddr[pCount], pParmBuffer.ParmBufferLen[pCount], Self.ParameterSlip[pCount])  ! MSSQL maps SQL_C_TINYINT as Unsigned
        !self.trace('Z21 SBP ' & pAddress)
      End
      If result <> SQL_SUCCESS AND result <> SQL_SUCCESS_WITH_INFO
        self.SetErrorMssql(SQL_HANDLE_STMT,pStmt,'[d053]')
      End
    !endregion
    !region - ClaSHORT
    of ClaSHORT
      ! NULL SHORT
      If self.null_(self.Fields.index) = true
        If self._logBind then self.Log('[BIND][bf17]' & pCount & ' (short) as (null)').
        Self.ParameterSlip[pCount] = SQL_NULL_DATA
        result = SQLBindParameter(pStmt, pCount, SQL_PARAM_INPUT, SQL_C_SHORT, self.DatabaseFieldType[self.Fields.Index], self.DatabaseFieldSize[self.Fields.Index], 0, pParmBuffer.ParmBufferAddr[pCount], pParmBuffer.ParmBufferLen[pCount], Self.ParameterSlip[pCount])
        !self.trace('Z17 SBP')
      Else
        If self._logBind then self.Log('[BIND][bf18]' & pCount & ' (short) = ' & sh).
        pParmBuffer._SetParmBuffer(pCount,pAddress,2,self.DatabaseFieldType[self.Fields.Index],0,driver:Dispose,pCodePage)
        Self.ParameterSlip[pCount] = 2
        result = SQLBindParameter(pStmt,pCount, SQL_PARAM_INPUT, SQL_C_SHORT, self.DatabaseFieldType[self.Fields.Index], self.DatabaseFieldSize[self.Fields.Index], 0, pParmBuffer.ParmBufferAddr[pCount], pParmBuffer.ParmBufferLen[pCount], Self.ParameterSlip[pCount])
        !self.trace('Z22 SBP')
      End
      If result <> SQL_SUCCESS AND result <> SQL_SUCCESS_WITH_INFO
        self.SetErrorMssql(SQL_HANDLE_STMT,pStmt,'[d054]')
      End
    !endregion
    !region - ClaUSHORT
    of ClaUSHORT  ! UShorts are tricky, because not all backends support a unsigned short data type. For safely therefore the backend is assumed to be using a long (Int).
                  !!!todo possibly this needs to be under developer control. Test when driver is complete against backends that do, and do not, support unsigned ushort
      ! NULL USHORT
      If self.null_(self.Fields.index) = true
        If self._logBind then self.Log('[BIND][bf19]' & pCount & ' (ushort) as (null)').
        Self.ParameterSlip[pCount] = SQL_NULL_DATA
        result = SQLBindParameter(pStmt, pCount, SQL_PARAM_INPUT, SQL_C_TINYINT, self.DatabaseFieldType[self.Fields.Index], self.DatabaseFieldSize[self.Fields.Index], 0, pAddress, 0, Self.ParameterSlip[pCount])
        !self.trace('Z17 SBP')
      Else
        If self._logBind then self.Log('[BIND][bf20]' & pCount & ' (ushort) = ' & ush).
        Self.ParameterSlip[pCount] = 4
        lg = 0                                                               ! Clear the 4 bytes of the long
        memcpy(address(ush), pAddress,2)                                    ! take the ushort, put it in a Long
        pParmBuffer._SetParmBuffer(pCount,address(lg),4,self.DatabaseFieldType[self.Fields.Index],0,driver:Dispose,pCodePage)
        result = SQLBindParameter(pStmt,pCount, SQL_PARAM_INPUT, SQL_C_LONG, self.DatabaseFieldType[self.Fields.Index], self.DatabaseFieldSize[self.Fields.Index], 0, pParmBuffer.ParmBufferAddr[pCount], 4, Self.ParameterSlip[pCount])
        !self.trace('Z23 SBP')
      End
      If result <> SQL_SUCCESS AND result <> SQL_SUCCESS_WITH_INFO
        self.SetErrorMssql(SQL_HANDLE_STMT,pStmt,'[d055]')
      End
    !endregion
    !region - ClaLONG
    of ClaLong
      ! NULL LONG
      If self.null_(self.Fields.index) = true
        If self._logBind then self.Log('[BIND][bf21]' & pCount & ' (long) as (null)').
        Self.ParameterSlip[pCount] = SQL_NULL_DATA
        result = SQLBindParameter(pStmt, pCount, SQL_PARAM_INPUT, SQL_C_LONG, self.DatabaseFieldType[self.Fields.Index], self.DatabaseFieldSize[self.Fields.Index], 0, pAddress, 4, Self.ParameterSlip[pCount])
        !self.trace('Z17 SBP')
      Else
        If self._logBind then self.Log('[BIND][bf22]' & pCount & ' x(long) = ' & lg).
        pParmBuffer._SetParmBuffer(pCount,address(lg),4,self.DatabaseFieldType[self.Fields.Index],0,driver:Dispose,pCodePage)
        Self.ParameterSlip[pCount] = 4
        result = SQLBindParameter(pStmt,pCount, SQL_PARAM_INPUT, SQL_C_LONG, self.DatabaseFieldType[self.Fields.Index], self.DatabaseFieldSize[self.Fields.Index], 0, pParmBuffer.ParmBufferAddr[pCount], 4, Self.ParameterSlip[pCount])
        !self.trace('Z24 SBP pAddress=' & pAddress)
      End
      If result <> SQL_SUCCESS AND result <> SQL_SUCCESS_WITH_INFO
        self.SetErrorMssql(SQL_HANDLE_STMT,pStmt,'[d056]')
      End
    !endregion
    !region - ClaULONG
    of ClaULong
      ! NULL ULONG
      If self.null_(self.Fields.index) = true
        If self._logBind then self.Log('[BIND][bf23]' & pCount & ' (ulong) as (null)').
        Self.ParameterSlip[pCount] = SQL_NULL_DATA
        result = SQLBindParameter(pStmt, pCount, SQL_PARAM_INPUT, SQL_C_SBIGINT, self.DatabaseFieldType[self.Fields.Index], self.DatabaseFieldSize[self.Fields.Index], 0, pAddress, 8, Self.ParameterSlip[pCount])
        !self.trace('Z17 SBP')
      Else
        If self._logBind then self.Log('[BIND][bf24]' & pCount & ' (ulong) = ' & ulg).
        i64.lo = ulg
        pParmBuffer._SetParmBuffer(pCount,address(i64),8,self.DatabaseFieldType[self.Fields.Index],0,driver:Dispose,pCodePage)
        Self.ParameterSlip[pCount] = 8
        result = SQLBindParameter(pStmt,pCount, SQL_PARAM_INPUT, SQL_C_SBIGINT, self.DatabaseFieldType[self.Fields.Index], self.DatabaseFieldSize[self.Fields.Index], 0, pParmBuffer.ParmBufferAddr[pCount], 8, Self.ParameterSlip[pCount])
        !self.trace('Z25 SBP')
      End
      If result <> SQL_SUCCESS AND result <> SQL_SUCCESS_WITH_INFO
        self.SetErrorMssql(SQL_HANDLE_STMT,pStmt,'[d057]')
      End
    !endregion
    !region - ClaDATE
    of ClaDate
      ! NULL DATE
      If self.null_(self.Fields.index) = true   ! when this is called with the shadow buffer, then nulls are not checked for.
        If self._logBind then self.Log('[BIND][bf25]' & pCount & ' (date) as (null)').
        pParmBuffer._SetParmBuffer(pCount,address(dt),size(dt),self.DatabaseFieldType[self.Fields.Index],0,driver:Dispose,pCodePage)
        Self.ParameterSlip[pCount] = SQL_NULL_DATA
        result = SQLBindParameter(pStmt, pCount, SQL_PARAM_INPUT, SQL_C_TYPE_DATE, self.DatabaseFieldType[self.Fields.Index], self.DatabaseFieldSize[self.Fields.Index], 0 ,pParmBuffer.ParmBufferAddr[pCount], Size(dt), Self.ParameterSlip[pCount])
        !self.trace('Z26 SBP')
      ElsIf lg = 0 and self.opt:ZeroDate = -1
      ! ZERO DATE
        If self._logBind then self.Log('[BIND][bf26]' & pCount & ' (date) which is 0 as (null)').
        pParmBuffer._SetParmBuffer(pCount,address(dt),size(dt),self.DatabaseFieldType[self.Fields.Index],0,driver:Dispose,pCodePage)
        Self.ParameterSlip[pCount] = SQL_NULL_DATA
        result = SQLBindParameter(pStmt, pCount, SQL_PARAM_INPUT, SQL_C_TYPE_DATE, self.DatabaseFieldType[self.Fields.Index], self.DatabaseFieldSize[self.Fields.Index], 0 ,pParmBuffer.ParmBufferAddr[pCount], Size(dt), Self.ParameterSlip[pCount])
        !self.trace('Z27 SBP')
      Else
      ! NOT ZERO DATE
        If lg = 0
          case self.opt:ZeroDate
          Of -1
          Of 0
            dt.year  = 0
            dt.month = 0
            dt.day   = 0
          Of 1
            dt.year  = 1
            dt.month = 1
            dt.day   = 1
          Else
            dt.year  = self.opt:ZeroDate / 10000
            dt.month = (self.opt:ZeroDate / 100) % 100
            dt.day   = self.opt:ZeroDate % 100
          End
        Else
          dt.year  = bshift(lg,-16)
          dt.month = band(bshift(lg,-8),0ffh)
          dt.day   = band(lg,0ffh)
        End
        If self._logBind then self.Log('[BIND][bf27]' & pCount & ' (date) = [' & format(dt.year,@n04) & '/' & format(dt.month,'@n02') & '/' & format(dt.day,'@n02') & ']').
        pParmBuffer._SetParmBuffer(pCount,address(dt),size(dt),self.DatabaseFieldType[self.Fields.Index],0,driver:Dispose,pCodePage)
        Self.ParameterSlip[pCount] = size(dt)
        result = SQLBindParameter(pStmt, pCount, SQL_PARAM_INPUT, SQL_C_TYPE_DATE, self.DatabaseFieldType[self.Fields.Index], self.DatabaseFieldSize[self.Fields.Index], 0, pParmBuffer.ParmBufferAddr[pCount], Size(dt), Self.ParameterSlip[pCount])
        !self.trace('Z28 SBP ')
      End
      If result <> SQL_SUCCESS AND result <> SQL_SUCCESS_WITH_INFO
        self.SetErrorMssql(SQL_HANDLE_STMT,pStmt,'[d058]')
      End
    !endregion
    !region - ClaTIME
    of ClaTime
      ! NULL TIME
      If self.null_(self.Fields.index) = true   ! when this is called with the shadow buffer, then nulls are not checked for.
        If self._logBind then self.Log('[BIND][bf28]' & pCount & ' (time) as (null)').
        pParmBuffer._SetParmBuffer(pCount,address(tm),size(tm),self.DatabaseFieldType[self.Fields.Index],0,driver:Dispose,pCodePage)
        Self.ParameterSlip[pCount] = SQL_NULL_DATA
        result = SQLBindParameter(pStmt, pCount, SQL_PARAM_INPUT, SQL_C_BINARY, self.DatabaseFieldType[self.Fields.Index], self.DatabaseFieldSize[self.Fields.Index], 0 ,pParmBuffer.ParmBufferAddr[pCount], Size(tm), Self.ParameterSlip[pCount])
        !self.trace('Z26 SBP')
      Else
      ! NOT NULL TIME
        tm.hour = bshift(lg,-24)
        tm.minute = band( bshift(lg,-16) , 255)
        tm.second = band( bshift(lg,-8), 255)
        tm.fraction = band(lg,255) * 10000000
        If self._logBind then self.Log('[BIND][bf29]' & pCount & ' (time) = ' & tm.hour & ':' & tm.minute & ':' & tm.second & '.' & tm.fraction).
        pParmBuffer._SetParmBuffer(pCount,address(tm),size(tm),SQL_SS_TIME2,0,driver:Dispose,pCodePage)
        Self.ParameterSlip[pCount] = 12
        result = SQLBindParameter(pStmt,pCount, SQL_PARAM_INPUT, SQL_C_BINARY, SQL_SS_TIME2, 12, 7, pParmBuffer.ParmBufferAddr[pCount], Size(tm), Self.ParameterSlip[pCount])   !!!todo deal with time (3) and time(7)

        !self.trace('Z29 SBP')
      END
      If result <> SQL_SUCCESS AND result <> SQL_SUCCESS_WITH_INFO
        self.SetErrorMssql(SQL_HANDLE_STMT,pStmt,'[d059]')
      End
    !endregion
    !region - ClaDECIMAL / ClaPDECIMAL
    of ClaDecimal
    orof ClaPDecimal
      ! NULL DECIMAL
      If self.null_(self.Fields.index) = true   ! when this is called with the shadow buffer, then nulls are not checked for.
        If self._logBind then self.Log('[BIND][bf30]' & pCount & ' (decimal) as (null)').
        pParmBuffer._SetParmBuffer(pCount,address(bt),size(bt),self.DatabaseFieldType[self.Fields.Index],0,driver:Dispose,pCodePage)
        Self.ParameterSlip[pCount] = SQL_NULL_DATA
        result = SQLBindParameter(pStmt, pCount, SQL_PARAM_INPUT, SQL_C_CHAR, self.DatabaseFieldType[self.Fields.Index], self.DatabaseFieldSize[self.Fields.Index], self.Fields.DecimalPlaces ,pParmBuffer.ParmBufferAddr[pCount], 0, Self.ParameterSlip[pCount])
      Else
      ! NOT NULL DECIMAL
        self._DecToString(address(sx),self.Fields.length, self.Fields.DecimalSize,self.Fields.DecimalPlaces,self.Fields.Type,sx)
        len = len(clip(sx))
        If self._logBind then self.Log('[BIND][bf31]' & pCount & ' (decimal) [' & clip(sx) & ']').
        pParmBuffer._SetParmBuffer(pCount,address(sx),len,self.DatabaseFieldType[self.Fields.Index],0,driver:Dispose,pCodePage)
        Self.ParameterSlip[pCount] = len
        result = SQLBindParameter(pStmt,pCount, SQL_PARAM_INPUT, SQL_C_CHAR,  self.DatabaseFieldType[self.Fields.Index], self.DatabaseFieldSize[self.Fields.Index], self.Fields.DecimalPlaces, pParmBuffer.ParmBufferAddr[pCount], len, Self.ParameterSlip[pCount])
      End
      If result <> SQL_SUCCESS AND result <> SQL_SUCCESS_WITH_INFO
        self.SetErrorMssql(SQL_HANDLE_STMT,pStmt,'[d059]')
      End
    !endregion
    End
  End

  !self.trace('bind field done')
  Return

! set sx before coming in here
BindStringToTimeStamp2  routine
        If self.null_(self.Fields.index) = true
          If self._logBind then self.Log('[BIND][bf35]' & pCount & ' (timestamp2) as (null)').
          Self.ParameterSlip[pCount] = SQL_NULL_DATA
          result = SQLBindParameter(pStmt, pCount, SQL_PARAM_INPUT, SQL_C_CHAR, self.DatabaseFieldType[self.Fields.Index], self.DatabaseFieldSize[self.Fields.Index], 0, 0, 0, Self.ParameterSlip[pCount])
          If result <> SQL_SUCCESS AND result <> SQL_SUCCESS_WITH_INFO
            self.SetErrorMssql(SQL_HANDLE_STMT,pStmt,'[d048]')
          End
        Else
          If sx=''
            Case self.opt:ZeroDate
            of -1
              If self._logBind then self.Log('[BIND][bf36]' & pCount & ' (timestamp2) as (null)').
              Self.ParameterSlip[pCount] = SQL_NULL_DATA
              result = SQLBindParameter(pStmt, pCount, SQL_PARAM_INPUT, SQL_C_CHAR, self.DatabaseFieldType[self.Fields.Index], self.DatabaseFieldSize[self.Fields.Index], 0, 0, 0, Self.ParameterSlip[pCount])
              If result <> SQL_SUCCESS AND result <> SQL_SUCCESS_WITH_INFO
                self.SetErrorMssql(SQL_HANDLE_STMT,pStmt,'[d048]')
              End
              Return
            of 0
            of 1
              If self.DatabaseFieldPrecision[self.Fields.Index]
                sx = '0001-01-01 00:00:00.' & all('0',self.DatabaseFieldPrecision[self.Fields.Index])
              else
                sx = '0001-01-01 00:00:00'
              End
            Else
              sx = format(self.opt:ZeroDate / 10000,'@n04') & '-' & format((self.opt:ZeroDate / 100) % 100,'@n02') & '-' & format(self.opt:ZeroDate % 100,'@n02') & ' 00:00:00'
              If self.DatabaseFieldPrecision[self.Fields.Index]
                sx = clip(sx) & '.' & all('0',self.DatabaseFieldPrecision[self.Fields.Index])
              End
            End
          End
          len = len(clip(sx))
          If self._logBind then self.Log('[BIND][bf37]' & pCount & ' (timestamp2) ' & len & ' as [' & clip(sx) & '] ' & self.DatabaseFieldPrecision[self.Fields.Index]).
          Self.ParameterSlip[pCount] = SQL_NTS
          pParmBuffer._SetParmBuffer(pCount,address(sx),len,SQL_TYPE_TIMESTAMP,0,driver:Dispose,pCodePage)
          result = SQLBindParameter(pStmt, pCount, SQL_PARAM_INPUT, SQL_C_CHAR, SQL_TYPE_TIMESTAMP, self.DatabaseFieldSize[self.Fields.Index], self.DatabaseFieldPrecision[self.Fields.Index], pParmBuffer.ParmBufferAddr[pCount], pParmBuffer.ParmBufferLen[pCount], Self.ParameterSlip[pCount])
        End

! set sx before coming in here
BindStringToTimeStampTZ  routine
        If self.null_(self.Fields.index) = true
          If self._logBind then self.Log('[BIND][bf56]' & pCount & ' (timestampoffset) as (null)').
          Self.ParameterSlip[pCount] = SQL_NULL_DATA
          result = SQLBindParameter(pStmt, pCount, SQL_PARAM_INPUT, SQL_C_CHAR, self.DatabaseFieldType[self.Fields.Index], self.DatabaseFieldSize[self.Fields.Index], 0, 0, 0, Self.ParameterSlip[pCount])
          If result <> SQL_SUCCESS AND result <> SQL_SUCCESS_WITH_INFO
            self.SetErrorMssql(SQL_HANDLE_STMT,pStmt,'[d048]')
          End
        Else
          If sx=''
            Case self.opt:ZeroDate
            of -1
              If self._logBind then self.Log('[BIND][bf57]' & pCount & ' (timestampoffset) as (null)').
              Self.ParameterSlip[pCount] = SQL_NULL_DATA
              result = SQLBindParameter(pStmt, pCount, SQL_PARAM_INPUT, SQL_C_CHAR, self.DatabaseFieldType[self.Fields.Index], self.DatabaseFieldSize[self.Fields.Index], 0, 0, 0, Self.ParameterSlip[pCount])
              If result <> SQL_SUCCESS AND result <> SQL_SUCCESS_WITH_INFO
                self.SetErrorMssql(SQL_HANDLE_STMT,pStmt,'[d048]')
              End
              Return
            of 0
            of 1
              If self.DatabaseFieldPrecision[self.Fields.Index]
                sx = '0001-01-01 00:00:00.' & all('0',self.DatabaseFieldPrecision[self.Fields.Index]) & ' +00:00'
              else
                sx = '0001-01-01 00:00:00 +00:00'
              End
            Else
              sx = format(self.opt:ZeroDate / 10000,'@n04') & '-' & format((self.opt:ZeroDate / 100) % 100,'@n02') & '-' & format(self.opt:ZeroDate % 100,'@n02') & ' 00:00:00'
              If self.DatabaseFieldPrecision[self.Fields.Index]
                sx = clip(sx) & '.' & all('0',self.DatabaseFieldPrecision[self.Fields.Index]) & ' +00:00'
              Else
                sx = clip(sx) & ' +00:00'
              End
            End
          End
          x = instring('/',sx,1,1)
          loop while x
            sx[x] = '-'
            x = instring('/',sx,1,x)
          end
          len = len(clip(sx))
          If self._logBind then self.Log('[BIND][bf58]' & pCount & ' (timestampoffset) ' & len & ' as [' & clip(sx) & '] ' & self.DatabaseFieldPrecision[self.Fields.Index]).
          Self.ParameterSlip[pCount] = SQL_NTS
          pParmBuffer._SetParmBuffer(pCount,address(sx),len,SQL_TYPE_TIMESTAMP,0,driver:Dispose,pCodePage)
          result = SQLBindParameter(pStmt, pCount, SQL_PARAM_INPUT, SQL_C_CHAR, SQL_SS_TIMESTAMPOFFSET, self.DatabaseFieldSize[self.Fields.Index], self.DatabaseFieldPrecision[self.Fields.Index], pParmBuffer.ParmBufferAddr[pCount], pParmBuffer.ParmBufferLen[pCount], Self.ParameterSlip[pCount])
        End

HandleArray  routine
  data
arr StringTheory ! moved into a routine for performance
  code
  ! Array Support.  This will likely vary from one driver to another.
  ! In MSSQL arrays become JSON fields, stored in a TEXT field
  If self.null_(self.Fields.index) = true
    If self._logBind then self.Log('[BIND][bf32]' & pCount & ' (array) as (null)').
    Self.ParameterSlip[pCount] = SQL_NULL_DATA
    result = SQLBindParameter(pStmt, pCount, SQL_PARAM_INPUT, SQL_C_CHAR, self.DatabaseFieldType[self.Fields.Index], self.DatabaseFieldSize[self.Fields.Index], 0, 0, 0, Self.ParameterSlip[pCount])
    !self.trace('Z15 SBP')
  Else
  ! NOT NULL ARRAY
    arr.SetValue(self.GetProp:Json(self.Fields.Index))  ! get a JSON form of the Array
    If self._logBind then self.Log('[BIND][bf33]' & pCount & ' (array)' & arr.GetValue()).
    pParmBuffer._SetParmBuffer(pCount,arr.GetAddress(),arr.Length(),self.DatabaseFieldType[self.Fields.Index],0,driver:Dispose,pCodePage)
    Self.ParameterSlip[pCount] = arr.Length()
    If self.Fields.Binary = true
      result = SQLBindParameter(pStmt, pCount, SQL_PARAM_INPUT, SQL_C_BINARY, self.DatabaseFieldType[self.Fields.Index] , self.DatabaseFieldSize[self.Fields.Index], 0,  pParmBuffer.ParmBufferAddr[pCount], pParmBuffer.ParmBufferLen[pCount]+1, Self.ParameterSlip[pCount] )
    Else
      result = SQLBindParameter(pStmt, pCount, SQL_PARAM_INPUT, SQL_C_CHAR, self.DatabaseFieldType[self.Fields.Index] , self.DatabaseFieldSize[self.Fields.Index], 0,  pParmBuffer.ParmBufferAddr[pCount], pParmBuffer.ParmBufferLen[pCount]+1, Self.ParameterSlip[pCount] )
    End
    !self.trace('Z50 SBP')
  End
  If result <> SQL_SUCCESS !AND result <> SQL_SUCCESS_WITH_INFO
    self.SetErrorMssql(SQL_HANDLE_STMT,pStmt,'[d061]')
  End
  Return

!-----------------------------------------------------------------
DriverFileMSSQL2Class._BindParameters  Procedure(Long pStmt, DriverParmBufferClass pParmBuffer, Long pCodePage)
x       Long,Auto
y       Long,Auto
p       Long,Auto
result  Long,Auto
Len     Long,Auto
addr    Long,Auto
lg      Long,Auto
rl      Real,Auto
count   Long,auto
  code
  !self.trace('DriverFileMSSQL2Class._BindParameters ' & self._ParameterOpcode)
  If self._ParameterOpcode = 0 then return driver:ok.
  If self.ParameterQueue &= null then return driver:ok.
  PushErrors()
  !self.trace('DriverFileMSSQL2Class._BindParameters ')

  Loop y = 1 to Records(self.ParameterQueue)
    Get(self.ParameterQueue,y)
    Loop x = 1 to self.ParameterQueue.ParameterArrayIndex
      If self.ParameterQueue.ParameterArray[x].OpCode <> self._ParameterOpcode then cycle.
      If not self.ParameterQueue.ParameterArray[x].Value &= null
        ! fixed value parameter, not a field in the buffer or shadow buffer, and not a blob. Stored as a string, but could be different type
        case self.ParameterQueue.ParameterArray[x].Source
        of ClaLong
          lg = self.ParameterQueue.ParameterArray[x].Value
          If self._logBind then self.Log('[BIND][bp7]' & self.ParameterQueue.ParameterArray[x].Count & ' (long) [' & lg &']').
          pParmBuffer._SetParmBuffer(self.ParameterQueue.ParameterArray[x].Count,Address(lg),4,SQL_INTEGER,0,driver:Dispose,pCodePage)
          Self.ParameterSlip[self.ParameterQueue.ParameterArray[x].Count] = 4
          count = self.ParameterQueue.ParameterArray[x].Count
          result = SQLBindParameter(pStmt, Count, SQL_PARAM_INPUT, SQL_C_LONG, SQL_INTEGER , SQL_IGNORED , SQL_IGNORED, pParmBuffer.ParmBufferAddr[count], pParmBuffer.ParmBufferLen[Count], Self.ParameterSlip[Count] )
        of ClaReal
          rl = self.ParameterQueue.ParameterArray[x].Value
          If self._logBind then self.Log('[BIND][bp8]' & self.ParameterQueue.ParameterArray[x].Count & ' (real) [' & rl &']').
          pParmBuffer._SetParmBuffer(self.ParameterQueue.ParameterArray[x].Count,Address(rl),8,SQL_INTEGER,0,driver:Dispose,pCodePage)
          Self.ParameterSlip[self.ParameterQueue.ParameterArray[x].Count] = 8
          count = self.ParameterQueue.ParameterArray[x].Count
          result = SQLBindParameter(pStmt, Count, SQL_PARAM_INPUT, SQL_C_DOUBLE, SQL_DOUBLE , SQL_IGNORED , SQL_IGNORED, pParmBuffer.ParmBufferAddr[count], pParmBuffer.ParmBufferLen[Count], Self.ParameterSlip[Count] )
        else
          len = len(self.ParameterQueue.ParameterArray[x].Value)
          If self._logBind then self.Log('[BIND][bp9]' & self.ParameterQueue.ParameterArray[x].Count & ' (string) [' & self.ParameterQueue.ParameterArray[x].Value &']').
          pParmBuffer._SetParmBuffer(self.ParameterQueue.ParameterArray[x].Count,Address(self.ParameterQueue.ParameterArray[x].Value),Len,SQL_VARCHAR,0,driver:Dispose,pCodePage)
          Self.ParameterSlip[self.ParameterQueue.ParameterArray[x].Count] = len
          count = self.ParameterQueue.ParameterArray[x].Count
          result = SQLBindParameter(pStmt, Count, SQL_PARAM_INPUT, SQL_C_CHAR, SQL_VARCHAR , len , SQL_IGNORED,  pParmBuffer.ParmBufferAddr[count], pParmBuffer.ParmBufferLen[Count], Self.ParameterSlip[Count] )

        end
      Elsif not self.ParameterQueue.ParameterArray[x].FieldNode &= null
        self.Fields &= self.ParameterQueue.ParameterArray[x].FieldNode
        case self.ParameterQueue.ParameterArray[x].Source
        of driver:FromBuffer
          addr = self.ClaFCB.rec_buf + self.Fields.Offset
        of driver:FromShadow
          addr = address(self.ShadowBuffer) + self.Fields.Offset
        of driver:FromPrimaryKeyPosition
          addr = address(self.PrimaryKeyPosition) + self.ParameterQueue.ParameterArray[x].Offset
        End
        self._BindField(pStmt,self.ParameterQueue.ParameterArray[x].Count,addr,pParmBuffer,pCodePage)
      ElsIf self.ParameterQueue.ParameterArray[x].BlobIndex <> 0
        If self._WithBlob(self.ParameterQueue.ParameterArray[x].BlobIndex) = driver:ok
          self._BindBlob(pStmt,self.ParameterQueue.ParameterArray[x].Count)
        End
      End
    End
  End
  PopErrors()
  Return driver:ok


!-----------------------------------------------------------------
! check if the connection string is the old format. If it is, convert to ODBC format
DriverFileMSSQL2Class._MassageOwner       PROCEDURE(String pOwner)
strOwner             StringTheory
Lne                  StringTheory
x                    Long
  code
  ! Massage OWNER
  strOwner.SetValue(pOwner)

  ! the old MsSql driver allowed a connection string of the form server,database,user,pwd
  ! the ODBC connection uses a ; separated list. Should have either a DSN= or a {ODBC Driver 17 for SQL Server} value.
  strOwner.split(';')
  Lne.SetValue(strOwner.GetLine(1))
  Lne.split(',','"','"',true)
  If Lne.Records() > 1
    Loop x = 1 to Lne.Records()
      If Instring(';',Lne.GetLine(x),1,1)
        Lne.SetLine(x,'"' & Lne.GetLine(x) & '"')
      End
    End
    If driver:odbc18exists = true or self._ExistsODBCDriver('ODBC Driver 18 for SQL Server') = driver:ok
      strOwner.SetLine(1,'Driver={{ODBC Driver 18 for SQL Server};Server=' & Lne.GetLine(1) &';Database=' & Lne.GetLine(2) & ';UID=' & Lne.GetLine(3) & ';PWD=' & Lne.GetLine(4))
      driver:odbc18exists = true
    ElsIf driver:odbc17exists = true or self._ExistsODBCDriver('ODBC Driver 17 for SQL Server') = driver:ok
      strOwner.SetLine(1,'Driver={{ODBC Driver 17 for SQL Server};Server=' & Lne.GetLine(1) &';Database=' & Lne.GetLine(2) & ';UID=' & Lne.GetLine(3) & ';PWD=' & Lne.GetLine(4))
      driver:odbc17exists = true
    End
    strOwner.join(';','')
  End
  If self.opt:TrustedConnection and strOwner.Instring('Trusted_Connection',1,1,0,st:nocase) = 0
    strOwner.Append(';Trusted_Connection=True')
  End
  Return strOwner.GetValue()

!-----------------------------------------------------------------
DriverFileMSSQL2Class._GetEnvironmentHandle             PROCEDURE(Long pOptions=0)
result  Long
  Code
  ! Allocate environment handle if not already allocated
  If ConnectionPoolMSSQL2.envHandle = SQL_NULL_HANDLE
    result = SQLAllocHandle(SQL_HANDLE_ENV, SQL_NULL_HANDLE, ConnectionPoolMSSQL2.envHandle)
    If result <> SQL_SUCCESS AND result <> SQL_SUCCESS_WITH_INFO
      self.SetErrorMssql(SQL_HANDLE_ENV,ConnectionPoolMSSQL2.envHandle,'[d001]')
      ConnectionPoolMSSQL2.envHandle = SQL_NULL_HANDLE
      Return driver:notok
    End
    If self._logConnections then self.Log('[CONN] New ENV Connection. Handle= ' & ConnectionPoolMSSQL2.envHandle).

    ! Set ODBC version
    result = SQLSetEnvAttr(ConnectionPoolMSSQL2.envHandle, SQL_ATTR_ODBC_VERSION, SQL_OV_ODBC3, 0)
    IF result <> SQL_SUCCESS AND result <> SQL_SUCCESS_WITH_INFO
      If self._logConnections then self.Log('[CONN] Env Connection Failed. Not ODBC 3.0 or later') .
      self.SetErrorMssql(SQL_HANDLE_ENV,ConnectionPoolMSSQL2.envHandle,'[d002]')
      result = SQLFreeHandle(SQL_HANDLE_ENV, ConnectionPoolMSSQL2.envHandle)
      ConnectionPoolMSSQL2.envHandle = SQL_NULL_HANDLE
      Return driver:notok
    End
  End
  Return driver:ok

!-----------------------------------------------------------------
DriverFileMSSQL2Class.Connect             PROCEDURE(Long pOptions=0)
result               SQLRETURN,Auto
str                  StringTheory
outConnectionString  String(4096)
outLength            Short
owner                cstring(DRIVER:MAXOWNER)
  code
  parent.Connect(pOptions)
  If ErrorCode() Then Return.

  If self._GetEnvironmentHandle(pOptions) <> Driver:ok
    self.trace('DriverFileMSSQL2Class.Connect : Failed to get Environment Handle')
    Return
  End
  Owner = self._MassageOwner(self.Owner)

  self._TryConnectedAs = Owner
  self.dbHandle = ConnectionPoolMSSQL2.GetConnection(Owner,self.Pool,pOptions)
  If self.dbHandle = SQL_NULL_HANDLE
    ! Allocate connection handle
    If self._logConnections then self.Log('[CONN] Getting New Connection owner = ' & Owner) .
    result = SQLAllocHandle(SQL_HANDLE_DBC, ConnectionPoolMSSQL2.envHandle, self.dbHandle)
    If result <> SQL_SUCCESS And result <> SQL_SUCCESS_WITH_INFO
      If self._logConnections then self.Log('[CONN] Connection Failed. Unable to get Handle. [' & Owner & ']') .
      self._ConnectedAs = ''
      self._ConnectedPool = 0
      self.SetErrorMssql(SQL_HANDLE_ENV,ConnectionPoolMSSQL2.envHandle,'[d003]')
      Return
    End
    If self._logConnections then self.Log('[CONN] New Connection handle = ' & self.dbHandle & ' ' & Owner) .
    if self.LoginTimeout = 0 then self.LoginTimeout = 15.  !!! if it's not connected in 15 seconds, it aint gonna connect.
    ! Set connection timeout if needed
    If self.LoginTimeout > 0
      result = SQLSetConnectAttr(self.dbHandle, SQL_ATTR_CONNECTION_TIMEOUT, self.LoginTimeout, SQL_IS_INTEGER);
    End
    If self.LoginTimeout > 0
      result = SQLSetConnectAttr(self.dbHandle, SQL_ATTR_LOGIN_TIMEOUT, self.LoginTimeout, SQL_IS_INTEGER)
    End
    ! Connect to data source
    result = SQLDriverConnect(self.dbHandle, 0, address(owner), size(owner) , address(outConnectionString), size(outConnectionString), address(outLength), SQL_DRIVER_NOPROMPT)   !
    If result <> SQL_SUCCESS And result <> SQL_SUCCESS_WITH_INFO
      If self._logConnections
        self.Log('[CONN] New Connection failed. Handle=' & self.dbHandle & ' Result=' & Result)
      End
      ! Get error information
      self.SetErrorMssql(SQL_HANDLE_DBC,self.dbHandle,'[d004]')
      self._ConnectedAs = ''
      self._ConnectedPool = 0
      ! Free the connection handle since connection failed
      result = SQLFreeHandle(SQL_HANDLE_DBC, self.dbHandle)
      self.dbHandle = SQL_NULL_HANDLE
      Return
    End
    If self._logConnections then self.Log('[CONN] New Connection successful. DB Handle=' & self.dbHandle) .

    ! IMPORTANT: Set connection attributes to avoid server-side cursors
    result = SQLSetConnectAttr(self.dbHandle, SQL_ATTR_CURSOR_TYPE, SQL_CURSOR_FORWARD_ONLY, SQL_IS_INTEGER)
    result = SQLSetConnectAttr(self.dbHandle, SQL_ATTR_CONCURRENCY, SQL_CONCUR_READ_ONLY, SQL_IS_INTEGER)

    If self.opt:BusyTimeout
      result = SQLSetConnectAttr(self.dbHandle, SQL_ATTR_CONNECTION_TIMEOUT, self.opt:BusyTimeout, SQL_IS_INTEGER)
    End

    ConnectionPoolMSSQL2.SetConnection(self.Owner,self.Pool,pOptions,self.dbHandle)
    self._ConnectedAs = self.Owner                                                  ! not owner. We want to be able to compare to self.owner later
    self._ConnectedPool = self.Pool
    self.SetError(NoError)
    self.AfterConnect()
    If Errorcode() = NoError
      str.start()
      str.SetValue(self.SqlCode)  ! Connect might happen when trying to execute another command. So preserve that command here.
      Self._GetDBVersion()
      result = SQLGetInfo(self.dbHandle, SQL_SERVER_NAME, address(self._connect[1]), size(self._connect[1]), outLength)
      result = SQLGetInfo(self.dbHandle, SQL_DATABASE_NAME, address(self._connect[2]), size(self._connect[2]), outLength)
      result = SQLGetInfo(self.dbHandle, SQL_USER_NAME, address(self._connect[3]), size(self._connect[3]), outLength)
      ConnectionPoolMSSQL2.SetConnectionDetails(self.Owner,self.Pool,pOptions,self._connect[1],self._connect[2],self._connect[3])
      self.SqlCode.SetValue(str)
    Else
      self._connect[1] = ''
      self._connect[2] = ''
      self._connect[3] = ''
    End
  Else
    If self._logConnections then self.Log('[CONN] Connection Reused. Handle= ' & self.dbHandle).
    self._ConnectedAs = self.Owner                                                    ! not owner. We want to be able to compare to self.owner later
    self._ConnectedPool = self.Pool
    ConnectionPoolMSSQL2.GetConnectionDetails(self.Owner,self.Pool,pOptions,self._connect[1],self._connect[2],self._connect[3])
  End
  Return

!-----------------------------------------------------------------
DriverFileMSSQL2Class._ExistsODBCDriver     PROCEDURE(String pDriver)
result   Long
driver   Cstring(256)
attr     Cstring(256)
rdlen    short
ralen    short
fetch    short
  code
  fetch = SQL_FETCH_FIRST
  pDriver = lower(pDriver)
  Loop
    result = SQLDrivers(ConnectionPoolMSSQL2.envHandle,fetch,driver,size(driver),rdlen,attr,size(attr),ralen)
    case result
    of SQL_NO_DATA
      break
    of SQL_INVALID_HANDLE
      break
    End
    If pDriver = Lower(driver) then Return driver:ok.
    !self.trace('Driver: [' & driver & '] attr=[' & attr & ']')
    fetch = SQL_FETCH_NEXT
  End
  Return driver:notok

!-----------------------------------------------------------------
DriverFileMSSQL2Class.DISCONNECT     PROCEDURE()
result  Long,Auto
stmt    Long
  Code
  parent.Disconnect()
  If self.dbHandle <> SQL_NULL_HANDLE
    If ConnectionPoolMSSQL2ok and ConnectionPoolMSSQL2.Disconnect(self.dbHandle) = true     ! Only returns true if this is the last object using the connection.
      result = SQLDisconnect(self.dbHandle)
      If result <> SQL_SUCCESS and result <> SQL_SUCCESS_WITH_INFO
        self.SetErrorMssql(SQL_HANDLE_DBC,self.dbHandle,'[d010]')
      End
      ! going to carry on anyway.
      result = SQLFreeHandle(SQL_HANDLE_DBC, self.dbHandle)
      If result <> SQL_SUCCESS AND result <> SQL_SUCCESS_WITH_INFO
        self.SetErrorMssql(SQL_HANDLE_DBC,self.dbHandle,'[d011]')
      End
    End
    self.dbHandle = SQL_NULL_HANDLE
  End
  Return

!-----------------------------------------------------------------
DriverFileMSSQL2Class._BindOffset             PROCEDURE()
result  Long,Auto
  Code
  If self._OffsetParmNumber
    ! Bind OFFSET
    If self._logBind then self.Log('[BIND][es1]' & self._OffsetParmNumber & ' Offset (long) = ' & self._SetOffset).
    self._SetOffsetMem = self._SetOffset
    result = SQLBindParameter(self.Stmt_Set,self._OffsetParmNumber, SQL_PARAM_INPUT, SQL_C_LONG, SQL_INTEGER, SQL_IGNORED, SQL_IGNORED, Address(self._SetOffsetMem), SQL_IGNORED, Self.ParameterSlip[self._OffsetParmNumber]);
    !self.trace('Z40 SBP')
    If result <> SQL_SUCCESS AND result <> SQL_SUCCESS_WITH_INFO
      self.SetErrorMssql(SQL_HANDLE_STMT,self.Stmt_Set,'[d036]')
    End
    self._SetOffset = 1    ! sets it so the next call through here will have Offset 1.
  End

!-----------------------------------------------------------------
! trigger a call to the backend, and put the result set into self.result.
! The "whole" result set is retrieved, no resources are left on the *server*.
! The "first" NEXT command will get it all, from the server to the localresult set. (built-in paging applies though.)
DriverFileMSSQL2Class._ExecuteSelect             PROCEDURE()
result   Long,auto
Slip      Long
  code
  If not Self.Stmt_Set then Return.
  If self.CheckConnect() = driver:notok then Return.
  If ErrorCode() = NoError
    self._ParameterOpcode = Opcode:SET
    If self.ParmBufferX &= Null then self.ParmBufferX &= NEW DriverParmBufferClass.
    If self._BindParameters(Self.Stmt_Set,self.ParmBufferX,self.CodePage) = driver:ok
      self._BindOffset()
      If ErrorCode() = NoError
        ! Execute statement, and move results to Results interface
        If self._ExecuteSqlToResults(Self.Stmt_Set,self.result) = driver:ok
        End
      End
      ! reset the statement so it can be used again
      result = SQLFreeStmt(Self.Stmt_Set, SQL_CLOSE)
      result = SQLFreeStmt(Self.Stmt_Set, SQL_RESET_PARAMS)
    End
  End
  parent._ExecuteSelect()
  !self.trace('DriverFileMSSQL2Class._ExecuteSelect done')
  Return

!-----------------------------------------------------------------
DriverFileMSSQL2Class._ExecuteSqlToRecord    Procedure()
stmt   Long,Auto
  Code
  If self.CheckConnect() = driver:notok then Return driver:notok.
  stmt = self._Prepare()
  If stmt
    Return self._ExecuteSqlToRecord(stmt,driver:buffer,self._StmtCols)
  end
  Return driver:notok

!-----------------------------------------------------------------
DriverFileMSSQL2Class._ExecuteSqlToRecord    Procedure(Long pStmt,Long pWhichBuffer, Long pColumns)
result        long,auto
  Code
  If ErrorCode() = NoError
    If self.ParmBufferX &= Null then self.ParmBufferX &= NEW DriverParmBufferClass.
    If self._BindParameters(pStmt,self.ParmBufferX,self.CodePage) = driver:ok
      If self._logSQL then self.Log('[SQL ]' & self.SqlCode.GetValue()).
      self._ToRecord(pStmt,pWhichBuffer,pColumns,Choose(pWhichBuffer=driver:nobuffer,false,true))  ! Will do the SQLExecute and the SQLFetch  . True is for ExpectReturn
      result = SQLFreeStmt(pStmt, SQL_CLOSE)
    End
    result = SQLFreeStmt(pStmt, SQL_RESET_PARAMS)
  End
  Return Driver:ok

!-----------------------------------------------------------------
! moves the results from the MSSQL result set to the .Results parameter using the ODBC API.
! called from DriverClass and DriverViewClass, so avoid referencing the "self" object here.
DriverFileMSSQL2Class._ExecuteSqlToResults    Procedure(Long pStmt,iResultSet pResult)
result        long,auto
  code
  !self.trace('DriverFileMSSQL2Class.ExecuteSqlToResults')
  pResult.NewResultSet(driver:DontFreeRam)
  self.ResultRow = 0
  self._ResultRow = 0
  self.Affected = 0
  If pStmt = 0 then Return driver:notok.
  If self.CheckConnect() = driver:notok then Return driver:notok.
  If self._logSQL then self.Log('[SQL ]' & self.SqlCode.GetValue()).
  result = SQLSetStmtAttr(pStmt, SQL_ATTR_QUERY_TIMEOUT, self.opt:BusyTimeout, SQL_IS_INTEGER)
  result = SQLExecute(pStmt)                                            ! get a page of rows
  case result
  of SQL_SUCCESS
  of SQL_SUCCESS_WITH_INFO
  of SQL_NO_DATA
  Else
    self.SetErrorMssql(SQL_HANDLE_STMT,pStmt,'[d083]')
    Return driver:notok
  End
  self._ToResults(pStmt,pResult)
  result = SQLFreeStmt(pStmt, SQL_CLOSE)
  result = SQLFreeStmt(pStmt, SQL_RESET_PARAMS)
  Return driver:ok

!-----------------------------------------------------------------
! called from DriverClass and DriverViewClass, so avoid referencing the "self" object here.
DriverFileMSSQL2Class._ToResults    Procedure(Long pStmt,iResultSet pResult)
result        Long,auto
columns       Short,auto
Offset        Long,Auto
SqlBuffer     &String

  code
  result = SQLNumResultCols(pStmt, columns)
  If result <> SQL_SUCCESS AND result <> SQL_SUCCESS_WITH_INFO
    self.SetErrorMssql(SQL_HANDLE_STMT,pStmt,'[d084]')
    Return
  End

  result = SQLRowCount(pStmt,self.Affected)
  If result <> SQL_SUCCESS AND result <> SQL_SUCCESS_WITH_INFO
    self.SetErrorMssql(SQL_HANDLE_STMT,pStmt,'[d085]')
  End

  Offset = self._DescribeResult(pStmt, columns, pResult)
  sqlBuffer &= New String(Offset)
  self._BindResult(pStmt, columns,address(sqlBuffer))

  If columns
    Loop
      result = SQLFetch(pStmt)
      case result
      of SQL_NO_DATA
        Break
      of SQL_SUCCESS
        self._ToResult(pStmt,columns,address(sqlBuffer),pResult)   ! copies the whole row to pResult
      !of SQL_SUCCESS_WITH_INFO
      !  self._ToResult(pStmt,columns,address(sqlBuffer),pResult)   ! with info means it only kinda worked, so for now want this to be an error.
      Else
        self.SetErrorMssql(SQL_HANDLE_STMT,pStmt,'[d090]')
        Break
      End

    End
  End
  Dispose(SqlBuffer)
  If self._logSQL then self.Log('[SQL ]' & pResult.Rows() & ' rows, ' & pResult.Columns() & ' columns in result set').
  Return

!-----------------------------------------------------------------
DriverFileMSSQL2Class._FreeStmt procedure(Long pStmt)
result   long,auto
  Code
  result = SQLFreeStmt(pStmt, SQL_CLOSE)
  If result <> SQL_SUCCESS AND result <> SQL_SUCCESS_WITH_INFO
    self.SetErrorMssql(SQL_HANDLE_STMT,pStmt,'[d031]')
  End
  result = SQLFreeStmt(pStmt, SQL_UNBIND)        ! Unbind columns
  result = SQLFreeStmt(pStmt, SQL_RESET_PARAMS)  ! Unbind parameters
  result = SQLFreeHandle(SQL_HANDLE_STMT, pStmt) ! Free statement handle
  Return

!-----------------------------------------------------------------
! Called From the CONNECT procedure, this queries the database to get the ODBC version number
! This method takes the step of displaying a message, because a client with too low a version
! is not good.
DriverFileMSSQL2Class._GetDBVersion   Procedure
version   cstring(256)
verlen    short
result    long
  Code
  If self.GETPROP:DBMSVer() = ''
    result = SQLGetInfo(self.dbHandle, SQL_DBMS_VER, address(version), size(version), verLen)
    self._ParseVersionDb(version)

    result = SQLGetInfo(self.dbHandle, SQL_DRIVER_VER, address(version), size(version), verLen)
    self._ParseVersionClient(version)

    If self.CheckVersionDb(Ms_Server_Major_Required, Ms_Server_Minor_Required,Ms_Server_Build_Required) <> driver:ok
      self.trace('MS SQL Server Version : ' & self.ClientVersionMajor & '.' & self.ClientVersionMinor & '.' & self.ClientVersionBuild  & ' Too Old. Need ' & Ms_Server_Major_Required & '.' & Ms_Server_Minor_Required & '.' & Ms_Server_Build_Required & ' or later.')
      self.BugAlert('[' & self.GetPROP:Driver() & '] ' & self.GetPROP:Database() & ' MS SQL Server Version : ' & self.DbVersionMajor & '.' & self.DbVersionMinor & '.' & self.DbVersionBuild  & ' Too Old. Need ' & Ms_Server_Major_Required & '.' & Ms_Server_Minor_Required & '.' & Ms_Server_Build_Required & ' or later.')
    End

    If self.CheckVersionClient(MsOdbc_Client_Major_Required, MsOdbc_Client_Minor_Required,MsOdbc_Client_Build_Required) <> driver:ok
      self.trace('ODBC Client Version : ' & self.ClientVersionMajor & '.' & self.ClientVersionMinor & '.' & self.ClientVersionBuild  & ' Too Old. Need ' & MsOdbc_Client_Major_Required & '.' & MsOdbc_Client_Minor_Required & '.' & MsOdbc_Client_Build_Required & ' or later.')
      self.BugAlert('[' & self.GetPROP:Driver() & '] ' & self.GetPROP:Database() & ' ODBC Client Version : ' & self.ClientVersionMajor & '.' & self.ClientVersionMinor & '.' & self.ClientVersionBuild  & ' Too Old. Need ' & MsOdbc_Client_Major_Required & '.' & MsOdbc_Client_Minor_Required & '.' & MsOdbc_Client_Build_Required & ' or later.')
    End
  End
  Return

!-----------------------------------------------------------------
! The other forms of GET all set the error to NoDriverSupport
DriverFileMSSQL2Class.GET              PROCEDURE(KEY pKey)
result  Long,Auto
stmt    Long,Auto
  Code
  If self.CheckConnect() = driver:notok then Return.
  self._ParameterOpcode = Opcode:GET
  self._nomemo = self.NoMemoArmed
  Self._BeforeRead(Opcode:GET)
  If Errorcode() then Return.
  If self._WithKey(pKey) = Driver:ok
    stmt = self._PrepareGet(pKey)
    self._ExecuteSqlToRecord(stmt,self._GetBuffer,self._GetColsCache)
  Else
    self.SetError(InvKeyErr)
  End
  Parent.Get(pKey)
  Return

!-----------------------------------------------------------------
DriverFileMSSQL2Class.GETRANDOM              PROCEDURE(String pFilter)
recs    BIGINT,Auto
rnd     BIGINT,Auto
result  Long,Auto
stmt    Long,Auto
  Code
  If self.CheckConnect() = driver:notok then Return.
  self._ParameterOpcode = Opcode:GETRANDOM
  self._nomemo = self.NoMemoArmed
  Self._BeforeRead(Opcode:GETRANDOM)
  If Errorcode() then Return.
  recs = self.RecordsFilter(pFilter)
  If recs = 0
    Self.SetError(BadRecErr)
  End
  If Errorcode() = NoError
    rnd = Random(0,recs-1)                     !!!todo - Random only returns in the range 1 to 2 billion.
    stmt = self._PrepareRandom(pFilter,rnd)    ! rnd becomes the offset
    If stmt
      self._ExecuteSqlToRecord(stmt,driver:buffer,self._StmtCols)
!      If self._BindParameters(stmt) = driver:ok
!        !self.NewResultSet(driver:DontFreeRam)  ! The GET doesn't go to the result set, so no need to clear that here?
!        If self._logSQL then self.Log('[SQL ]' & self.SqlCode.GetValue()).
!        self._toRecord(stmt,driver:buffer,true)     ! Will do the SQLExecute and the SQLFetch
!        self._FreeStmt(stmt)
!      End
    End
    Parent.GetRandom(pFilter)
  End
  Return

!-----------------------------------------------------------------
DriverFileMSSQL2Class._TypeNameToSQL  Procedure(*cString pTypeName)
  Code
  Case Lower(pTypeName)
  of 'int'                ; Return SQL_INTEGER
  of 'smallint'           ; Return SQL_SMALLINT
  of 'tinyint'            ; Return SQL_TINYINT
  of 'bigint'             ; Return SQL_BIGINT
  of 'bit'                ; Return SQL_BIT
  of 'float'              ; Return SQL_FLOAT
  of 'real'               ; Return SQL_REAL
  of 'decimal'            ; Return SQL_DECIMAL
  of 'numeric'            ; Return SQL_NUMERIC
  of 'money'              ; Return SQL_DECIMAL
  of 'smallmoney'         ; Return SQL_DECIMAL
  of 'char'               ; Return SQL_CHAR
  of 'varchar'            ; Return SQL_VARCHAR
  of 'text'               ; Return SQL_LONGVARCHAR
  of 'nchar'              ; Return SQL_WCHAR
  of 'nvarchar'           ; Return SQL_WVARCHAR
  of 'ntext'              ; Return SQL_WLONGVARCHAR
  of 'binary'             ; Return SQL_BINARY
  of 'varbinary'          ; Return SQL_VARBINARY
  of 'image'              ; Return SQL_LONGVARBINARY
  of 'date'               ; Return SQL_TYPE_DATE
  of 'time'               ; Return SQL_SS_TIME2
  of 'datetime'           ; Return SQL_TYPE_TIMESTAMP
  of 'datetime2'          ; Return SQL_TYPE_TIMESTAMP
  of 'smalldatetime'      ; Return SQL_TYPE_TIMESTAMP
  of 'datetimeoffset'     ; Return SQL_SS_TIMESTAMPOFFSET
  of 'uniqueidentifier'   ; Return SQL_GUID
  of 'xml'                ; Return SQL_LONGVARCHAR
  of 'sql_variant'        ; Return SQL_SS_VARIANT
  of 'hierarchyid'        ; Return SQL_VARBINARY
  of 'geometry'           ; Return SQL_LONGVARBINARY
  of 'geography'          ; Return SQL_LONGVARBINARY
  of 'timestamp'          ; Return SQL_BINARY
  of 'rowversion'         ; Return SQL_BINARY
  End
  Return SQL_BINARY

!-----------------------------------------------------------------
DriverFileMSSQL2Class.InterpretCType            Procedure(Long pType)
  Code
  case pType
  of SQL_C_CHAR
    Return 'SQL_C_CHAR'
  of SQL_C_LONG
    Return 'SQL_C_LONG'
  of SQL_C_SHORT
    Return 'SQL_C_SHORT'
  of SQL_C_FLOAT
    Return 'SQL_C_FLOAT'
  of SQL_C_DOUBLE
    Return 'SQL_C_DOUBLE'
  of SQL_C_NUMERIC
    Return 'SQL_C_NUMERIC'
  of SQL_C_DEFAULT
    Return 'SQL_C_DEFAULT'
  of SQL_C_DATE
    Return 'SQL_C_DATE'
  of SQL_C_TYPE_DATE
    Return 'SQL_C_TYPE_DATE'
  of SQL_C_TIME
    Return 'SQL_C_TIME'
  orof SQL_C_TYPE_TIME
    Return 'SQL_C_TYPE_TIME'
  of SQL_C_TIMESTAMP
    Return 'SQL_C_TIMESTAMP'
  of SQL_C_TYPE_TIMESTAMP
    Return 'SQL_C_TYPE_TIMESTAMP'
  of SQL_C_BINARY
    Return 'SQL_C_BINARY'
  of SQL_C_BIT
    Return 'SQL_C_BIT'
  of SQL_C_TINYINT
    Return 'SQL_C_TINYINT'
  of SQL_C_ULONG
    Return 'SQL_C_ULONG'
  of SQL_C_USHORT
    Return 'SQL_C_USHORT'
  of SQL_C_UTINYINT
    Return 'SQL_C_UTINYINT'
  of SQL_C_SBIGINT
    Return 'SQL_C_SBIGINT'
  of SQL_C_UBIGINT
    Return 'SQL_C_UBIGINT'
  of SQL_C_WCHAR
    Return 'SQL_C_WCHAR'
  of SQL_NULLTYPE
    Return 'SQL_NULLTYPE'
  of SQL_C_SS_TIME2
    return 'SQL_C_SS_TIME2'
  End
  Return pType

!-----------------------------------------------------------------
DriverFileMSSQL2Class.InterpretSQLType            Procedure(Long pType)
  Code
  case pType
  of SQL_BIGINT
    return 'SQL_BIGINT'
  of SQL_BINARY
    return 'SQL_BINARY'
  of SQL_BIT
    return 'SQL_BIT'
  of SQL_CHAR
    return 'SQL_CHAR'
  of SQL_DATE
    return 'SQL_DATE'
  of SQL_DECIMAL
    return 'SQL_DECIMAL'
  of SQL_DOUBLE
    return 'SQL_DOUBLE'
  of SQL_FLOAT
    return 'SQL_FLOAT'
  of SQL_GUID
    return 'SQL_GUID'
  of SQL_INTEGER
    return 'SQL_INTEGER'
  of SQL_LONGVARBINARY
    return 'SQL_LONGVARBINARY'
  of SQL_LONGVARCHAR
    return 'SQL_LONGVARCHAR'
  of SQL_NUMERIC
    return 'SQL_NUMERIC'
  of SQL_REAL
    return 'SQL_REAL'
  of SQL_SMALLINT
    return 'SQL_SMALLINT'
  of SQL_SS_TIME2
    return 'SQL_SS_TIME2'
  of SQL_TIME
    return 'SQL_TIME'
  of SQL_TIMESTAMP
    return 'SQL_TIMESTAMP'
  of SQL_TINYINT
    return 'SQL_TINYINT'
  of SQL_TYPE_DATE
    return 'SQL_TYPE_DATE'
  of SQL_TYPE_TIME
    return 'SQL_TYPE_TIME'
  of SQL_TYPE_TIMESTAMP
    return 'SQL_TYPE_TIMESTAMP'
  of SQL_VARBINARY
    return 'SQL_VARBINARY'
  of SQL_VARCHAR
    return 'SQL_VARCHAR'
  of SQL_WCHAR
    return 'SQL_WCHAR'
  of SQL_WVARCHAR
    return 'SQL_WVARCHAR'
  of SQL_WLONGVARCHAR
    return 'SQL_WLONGVARCHAR'
  end
  Return pType

!-----------------------------------------------------------------
! a function which copies data from the database format (C Type) to the clarion type.
! this is a matrix which converts database types to Clarion types.
! This can be as simple, or as flexible as you want.
! If it's not possible to store the SQL data into the Clarion type then errorcode is set to DataTruncatedErr
! converting can take time, so matching the clarion type to the database type to begin with will speed things along.
! if the pClarionType is ClaBlob then pClarionAddress is the blob index (as a neg number)
! if the pClarionType is a ClaMEMO then the pClarionAddress and pClarionLength are set as normal
! if the pClarionType is a CLADECIMAL or CLAPDECIMAL then the Fields node has to be loaded. Otherwise fields is not used.
DriverFileMSSQL2Class._Morph      Procedure(String pFieldLabel, Byte pClarionType, Long pClarionAddress, Long pClarionLength, Long pCellType, Long pCellAddress, Long pCellLength, Long pSqlTimeStamp, Byte pSetFieldNull, *Long rTextLength)
lg          long,Auto
ulg         Ulong,Auto
sh          Short,Auto
ush         UShort,Auto
bt          Byte,Auto
srl         Sreal,Auto
rl          Real,Auto
st          string(30),Auto
cst         Cstring(30),Auto  !bigint range is -9 223 372 036 854 775 808 -- 18 446 744 073 709 551 615
len         Long,Auto
strmem      String(36),Auto
str         &string
ansistr     &string
cstr        &cstring
StrLen      Long,Auto
dt          Date,Auto
dtl         Long,over(dt)
tm          Time,Auto
tml         Long,over(tm)
bigi        group
lo            ulong
hi            long
            end
bigd        decimal(31)
bintime     Like(TimeGroupType)
bindate     Like(DateGroupType)
bindatetime Like(TimeStampTZGroupType)
num         Like(NumericGroupType)
x           long

  Code
  !self.trace('_morph : pFieldLabel=' & pFieldLabel & ' pClarionType=' & pClarionType & ' (' & self.InterpretType(pClarionType) & ') pCellType=' & pCellType & ' (' & self.InterpretCType(pCellType) & ') pClarionLength=' & pClarionLength & ' pCellLength=' & pCellLength)
  If pCellType =  SQL_C_BINARY and pClarionType = ClaString and |
  ((pClarionLength = 8 and pSqlTimeStamp = driver:GroupOverTimeStamp) or |
   (pClarionLength = 12 and pSqlTimeStamp = driver:GroupOverTimeStampTZ) or |
   (pClarionLength >= 27 and pSqlTimeStamp = driver:StringToTimeStamp2) or |
   (pClarionLength >= 34 and pSqlTimeStamp = driver:StringToTimeStampTZ)  )
    pCellType = SQL_C_TYPE_TIMESTAMP
  ElsIf pCellType =  SQL_C_BINARY and pClarionType = ClaCString and |
   ((pClarionLength >= 28 and pSqlTimeStamp = driver:StringToTimeStamp2) or |
    (pClarionLength >= 35 and pSqlTimeStamp = driver:StringToTimeStampTZ)  )
    pCellType = SQL_C_TYPE_TIMESTAMP
  End

  Case pCellType
!region - SQL_C_NUMERIC
  ! ===================
  of SQL_C_NUMERIC                              ! Maps to Decimal and pDecimal
    !self.trace('ERROR todo map SQL decimal to clarion decimal and pdecimal pClarionType=' & pClarionType)
    memcpy(address(num),pCellAddress,pCellLength)
    Case pClarionType
    of ClaDECIMAL
    orof ClaPDECIMAL
      !!! maybe to do map SQL decimal to clarion decimal and pdecimal. But probably not, since
      !!! when fetching the data, the type is requested as SQL_CHAR so not expecting to come in here at all.
      self.trace('ERROR: map SQL decimal to clarion decimal and pdecimal.')
    Else
      self.SetError(FieldMismatchErr)
      self.SetFileError(FieldMismatchErr,'Field: ' & clip(pFieldLabel) & ' SQL Type: ' & self.InterpretCType(pCellType) & '(' & pCellType & ')' & ' Clarion Type: ' & self.InterpretType(pClarionType) & '(' & pClarionType & ')' & ' value: ' )
    End
!endregion
!region - SQL_C_LONG
  ! ================
  of SQL_C_LONG
    memcpy(address(lg),pCellAddress,4)
    Case pClarionType
    ! LONG to LONG
    of ClaLONG
    orof ClaSIGNED
      memcpy(pClarionAddress,pCellAddress,4)

    ! LONG to ULONG
    of ClaULONG
      If (lg < 0) and self.opt:ignoretruncation = false
        self.SetError(DataTruncatedErr)
        self.SetFileError(DataTruncatedErr,'Field: ' & clip(pFieldLabel) & ' SQL Type: ' & self.InterpretCType(pCellType) & '(' & pCellType & ')' & ' Clarion Type: ' & self.InterpretType(pClarionType) & '(' & 2 & ')' & ' value: ' & lg)
        Return
      End
      memcpy(pClarionAddress,pCellAddress,4)

    ! LONG to SHORT
    of ClaSHORT
      If (lg < -32768 or lg > 32767) and self.opt:ignoretruncation = false
        self.SetError(DataTruncatedErr)
        self.SetFileError(DataTruncatedErr,'Field: ' & clip(pFieldLabel) & ' SQL Type: ' & self.InterpretCType(pCellType) & '(' & pCellType & ')' & ' Clarion Type: ' & self.InterpretType(pClarionType) & '(' & 2 & ')' & ' value: ' & lg)
        Return
      End
      memcpy(pClarionAddress,pCellAddress,2)

    ! LONG to USHORT
    of ClaUSHORT
      If (lg < 0 or lg > 65535) and self.opt:ignoretruncation = false
        self.SetError(DataTruncatedErr)
        self.SetFileError(DataTruncatedErr,'Field: ' & clip(pFieldLabel) & ' SQL Type: ' & self.InterpretCType(pCellType) & '(' & pCellType & ')' & ' Clarion Type: ' & self.InterpretType(pClarionType) & '(' & 2 & ')' & ' value: ' & lg)
        Return
      End
      memcpy(pClarionAddress,pCellAddress,2)

    ! LONG to BYTE
    of ClaBYTE
      If (lg < 0 or lg > 255) and self.opt:ignoretruncation = false
        self.SetError(DataTruncatedErr)
        self.SetFileError(DataTruncatedErr,'Field: ' & clip(pFieldLabel) & ' SQL Type: ' & self.InterpretCType(pCellType) & '(' & pCellType & ')' & ' Clarion Type: ' & self.InterpretType(pClarionType) & '(' & 2 & ')' & ' value: ' & lg)
        Return
      End
      memcpy(pClarionAddress,pCellAddress,1)

    ! LONG to STRING
    of ClaSTRING
      cst = lg
      len = len(cst)
      If len > pClarionLength and self.opt:ignoretruncation = false
        self.SetError(DataTruncatedErr)
        self.SetFileError(DataTruncatedErr,'Field: ' & clip(pFieldLabel) & ' SQL Type: ' & self.InterpretSQLType(pCellType) & '(' & pCellType & ')' & ' Clarion Type: ' & self.InterpretType(pClarionType) & '(' & pClarionLength & ')' & ' value: ' & lg)
        Return
      End
      memcpy(pClarionAddress,address(cst),len)
      StrLen = len
      If rTextLength = 0 then do PadString.
      rTextLength = Len

    ! LONG to PSTRING
    of ClaPSTRING
      cst = lg
      len = len(cst)
      If len > pClarionLength and self.opt:ignoretruncation = false
        self.SetError(DataTruncatedErr)
        self.SetFileError(DataTruncatedErr,'Field: ' & clip(pFieldLabel) & ' SQL Type: ' & self.InterpretSQLType(pCellType) & '(' & pCellType & ')' & ' Clarion Type: ' & self.InterpretType(pClarionType) & '(' & pClarionLength & ')' & ' value: ' & lg)
        Return
      End
      If len > pClarionLength then len = pClarionLength.
      memcpy(pClarionAddress+1,address(cst),len)
      memset(pClarionAddress,len,1)
      StrLen = len
      If rTextLength = 0 then do PadString.
      rTextLength = Len

    ! LONG to CSTRING
    of ClaCSTRING
      cst = lg
      len = len(cst)
      If len > pClarionLength and self.opt:ignoretruncation = false
        self.SetError(DataTruncatedErr)
        self.SetFileError(DataTruncatedErr,'Field: ' & clip(pFieldLabel) & ' SQL Type: ' & self.InterpretSQLType(pCellType) & '(' & pCellType & ')' & ' Clarion Type: ' & self.InterpretType(pClarionType) & '(' & pClarionLength & ')' & ' value: ' & lg)
        Return
      End
      memcpy(pClarionAddress,address(cst),len+1)
      StrLen = Len
      do PadString

    ! LONG to REAL
    of ClaREAL
      rl = lg
      memcpy(pClarionAddress,address(rl),8)

    ! LONG to DATE
    of ClaDATE
      dt = lg
      memcpy(pClarionAddress,address(dt),4)

    ! LONG to TIME
    of ClaTIME
      tm = lg
      memcpy(pClarionAddress,address(tm),4)

    ! LONG to DECIMAL
    of ClaDecimal
    orof ClaPDecimal
      st = lg
      if len(clip(st)) > self.Fields.DecimalSize - self.Fields.DecimalPlaces and self.opt:ignoretruncation = false
        self.SetError(DataTruncatedErr)
        self.SetFileError(DataTruncatedErr,'Field: ' & clip(pFieldLabel) & ' SQL Type: ' & self.InterpretSQLType(pCellType) & '(' & pCellType & ')' & ' Clarion Type: ' & self.InterpretType(pClarionType) & '(' & self.Fields.DecimalSize - self.Fields.DecimalPlaces & ')' & ' value: ' & lg)
        Return
      end
      self._StringToDec(st, pClarionType, address(strmem), self.Fields.DecimalSize, self.Fields.DecimalPlaces)
      memcpy(pClarionAddress,address(strmem),pClarionLength)

    else
      self.SetError(FieldMismatchErr)
      self.SetFileError(FieldMismatchErr,'Field: ' & clip(pFieldLabel) & ' SQL Type: ' & self.InterpretCType(pCellType) & '(' & pCellType & ')' & ' Clarion Type: ' & self.InterpretType(pClarionType) & '(' & pClarionType & ')' & ' value: ' )
    end
!endregion
!region - SQL_C_SHORT
  ! =================
  of SQL_C_SHORT                              ! Maps to Short, but can also go into Long
    memcpy(address(sh),pCellAddress,2)
    Case pClarionType

    ! SHORT to SHORT
    of ClaSHORT
      memcpy(pClarionAddress,pCellAddress,2)

    ! SHORT to LONG
    of ClaLONG
      memcpy(address(sh),pCellAddress,2)
      lg = sh
      memcpy(pClarionAddress,address(lg),4)

    ! SHORT to REAL
    of ClaReal
      memcpy(address(sh),pCellAddress,2)
      rl = sh
      memcpy(pClarionAddress,address(rl),8)

    ! SHORT to SREAL
    of ClaSreal
      memcpy(address(sh),pCellAddress,2)
      srl = sh
      memcpy(pClarionAddress,address(srl),4)

    ! SHORT to DECIMAL
    of ClaDecimal
    orof ClaPDecimal
      st = sh
      if len(clip(st)) > self.Fields.DecimalSize - self.Fields.DecimalPlaces and self.opt:ignoretruncation = false
        self.SetError(DataTruncatedErr)
        self.SetFileError(DataTruncatedErr,'Field: ' & clip(pFieldLabel) & ' SQL Type: ' & self.InterpretSQLType(pCellType) & '(' & pCellType & ')' & ' Clarion Type: ' & self.InterpretType(pClarionType) & '(' & self.Fields.DecimalSize - self.Fields.DecimalPlaces & ')' & ' value: ' & sh)
        Return
      end
      self._StringToDec(st, pClarionType, address(strmem), self.Fields.DecimalSize, self.Fields.DecimalPlaces)
      memcpy(pClarionAddress,address(strmem),pClarionLength)

    ! SHORT to STRING
    of ClaSTRING
      memcpy(address(sh),pCellAddress,2)
      cst = sh
      len = len(cst)
      If len > pClarionLength and self.opt:ignoretruncation = false
        self.SetError(DataTruncatedErr)
        self.SetFileError(DataTruncatedErr,'Field: ' & clip(pFieldLabel) & ' SQL Type: ' & self.InterpretSQLType(pCellType) & '(' & pCellType & ')' & ' Clarion Type: ' & self.InterpretType(pClarionType) & '(' & pClarionLength & ')' & ' value: ' & sh)
        Return
      End
      memcpy(pClarionAddress,address(cst),len)
      StrLen = len
      If rTextLength = 0 then do PadString.
      rTextLength = Len

    ! SHORT to CSTRING
    of ClaCSTRING
      memcpy(address(sh),pCellAddress,2)
      cst = sh
      len = len(cst)
      If len > pClarionLength and self.opt:ignoretruncation = false
        self.SetError(DataTruncatedErr)
        self.SetFileError(DataTruncatedErr,'Field: ' & clip(pFieldLabel) & ' SQL Type: ' & self.InterpretSQLType(pCellType) & '(' & pCellType & ')' & ' Clarion Type: ' & self.InterpretType(pClarionType) & '(' & pClarionLength & ')' & ' value: ' & sh)
        Return
      End
      memcpy(pClarionAddress,address(cst),len+1)
      StrLen = len
      do PadString

    else
      self.SetError(FieldMismatchErr)
      self.SetFileError(FieldMismatchErr,'Field: ' & clip(pFieldLabel) & ' SQL Type: ' & self.InterpretCType(pCellType) & '(' & pCellType & ')' & ' Clarion Type: ' & self.InterpretType(pClarionType) & '(' & pClarionType & ')' & ' value: ' )
    end

!endregion
!region - SQL_C_TINYINT / SQL_C_BIT
  ! ===================
  of SQL_C_TINYINT                               ! Maps to Byte, but can also go into Short, UShort, Long, ULong etc
  orof SQL_C_BIT                                 ! Maps to Byte, but can also go into Short, UShort, Long, ULong etc
    memcpy(address(bt),pCellAddress,1)
    Case pClarionType
    Of ClaBYTE
      memcpy(pClarionAddress,pCellAddress,1)

    Of ClaSHORT
      sh = bt
      memcpy(pClarionAddress,address(sh),2)

    Of ClaUSHORT
      ush = bt
      memcpy(pClarionAddress,address(ush),2)

    Of ClaLONG
      lg = bt
      memcpy(pClarionAddress,address(lg),4)

    Of ClaULONG
      ulg = bt
      memcpy(pClarionAddress,address(ulg),4)

    of ClaReal
      rl = bt
      memcpy(pClarionAddress,address(rl),8)

    of ClaSReal
      srl = bt
      memcpy(pClarionAddress,address(srl),4)

    ! BYTE to DECIMAL
    of ClaDecimal
    orof ClaPDecimal
      st = bt
      if len(clip(st)) > self.Fields.DecimalSize - self.Fields.DecimalPlaces and self.opt:ignoretruncation = false
        self.SetError(DataTruncatedErr)
        self.SetFileError(DataTruncatedErr,'Field: ' & clip(pFieldLabel) & ' SQL Type: ' & self.InterpretSQLType(pCellType) & '(' & pCellType & ')' & ' Clarion Type: ' & self.InterpretType(pClarionType) & '(' & self.Fields.DecimalSize - self.Fields.DecimalPlaces & ')' & ' value: ' & bt)
        Return
      end
      self._StringToDec(st, pClarionType, address(strmem), self.Fields.DecimalSize, self.Fields.DecimalPlaces)
      memcpy(pClarionAddress,address(strmem),pClarionLength)

    ! BYTE to STRING
    of ClaSTRING
      cst = bt
      len = len(cst)
      If len > pClarionLength and self.opt:ignoretruncation = false
        self.SetError(DataTruncatedErr)
        self.SetFileError(DataTruncatedErr,'Field: ' & clip(pFieldLabel) & ' SQL Type: ' & self.InterpretSQLType(pCellType) & '(' & pCellType & ')' & ' Clarion Type: ' & self.InterpretType(pClarionType) & '(' & pClarionLength & ')' & ' value: ' & bt)
        Return
      End
      memcpy(pClarionAddress,address(cst),len)
      StrLen = len
      If rTextLength = 0 then do PadString.
      rTextLength = Len

    ! BYTE to CSTRING
    of ClaCSTRING
      cst = bt
      len = len(cst)
      If len > pClarionLength and self.opt:ignoretruncation = false
        self.SetError(DataTruncatedErr)
        self.SetFileError(DataTruncatedErr,'Field: ' & clip(pFieldLabel) & ' SQL Type: ' & self.InterpretSQLType(pCellType) & '(' & pCellType & ')' & ' Clarion Type: ' & self.InterpretType(pClarionType) & '(' & pClarionLength & ')' & ' value: ' & bt)
        Return
      End
      memcpy(pClarionAddress,address(cst),len+1)
      StrLen = len
      do PadString

    else
      self.SetError(FieldMismatchErr)
      self.SetFileError(FieldMismatchErr,'Field: ' & clip(pFieldLabel) & ' SQL Type: ' & self.InterpretCType(pCellType) & '(' & pCellType & ')' & ' Clarion Type: ' & self.InterpretType(pClarionType) & '(' & pClarionType & ')' & ' value: ' )
    End
!endregion
!region - SQL_C_FLOAT
  ! =================
  of SQL_C_FLOAT                                  ! Float (which are short reals) can map to a Clarion REAL  or SREAL
     memcpy(address(srl),pCellAddress,4)
    Case pClarionType
    of ClaSREAL
      memcpy(pClarionAddress,pCellAddress,4)

    of ClaREAL
      rl = srl
      memcpy(pClarionAddress,address(rl),8)

    of ClaSTRING
      cst = srl
      len = len(cst)
      If len > pClarionLength and self.opt:ignoretruncation = false
        self.SetError(DataTruncatedErr)
        self.SetFileError(DataTruncatedErr,'Field: ' & clip(pFieldLabel) & ' SQL Type: ' & self.InterpretSQLType(pCellType) & '(' & pCellType & ')' & ' Clarion Type: ' & self.InterpretType(pClarionType) & '(' & pClarionLength & ')' & ' value: ' & srl)
        Return
      End
      memcpy(pClarionAddress,address(cst),len)
      StrLen = len
      If rTextLength = 0 then do PadString.
      rTextLength = Len

    of ClaCSTRING
      cst = srl
      len = len(cst)
      If len > pClarionLength and self.opt:ignoretruncation = false
        self.SetError(DataTruncatedErr)
        self.SetFileError(DataTruncatedErr,'Field: ' & clip(pFieldLabel) & ' SQL Type: ' & self.InterpretSQLType(pCellType) & '(' & pCellType & ')' & ' Clarion Type: ' & self.InterpretType(pClarionType) & '(' & pClarionLength & ')' & ' value: ' & srl)
        Return
      End
      memcpy(pClarionAddress,address(cst),len+1)
      StrLen = len
      do PadString

    else
      self.SetError(FieldMismatchErr)
      self.SetFileError(FieldMismatchErr,'Field: ' & clip(pFieldLabel) & ' SQL Type: ' & self.InterpretCType(pCellType) & '(' & pCellType & ')' & ' Clarion Type: ' & self.InterpretType(pClarionType) & '(' & pClarionType & ')' & ' value: ' )
    end
!endregion
!region - SQL_C_DOUBLE
  ! ==================
  of SQL_C_DOUBLE                               ! SQL Doubles (real) can map to a short-real, as long as the data is in range
    memcpy(address(rl),pCellAddress,8)
    Case pClarionType
    of ClaREAL
      memcpy(pClarionAddress,pCellAddress,8)

    of ClaSREAL
      If rl > 07fffffh and self.opt:ignoretruncation = false  ! sReal only has 23 bits of integer space
        self.SetError(DataTruncatedErr)
        self.SetFileError(DataTruncatedErr,'Field: ' & clip(pFieldLabel) & ' SQL Type: ' & self.InterpretCType(pCellType) & '(' & pCellType & ')' & ' Clarion Type: ' & self.InterpretType(pClarionType) & '(' & 4 & ')' & ' value: ' & rl)
        Return
      End
      srl = rl
      memcpy(pClarionAddress,address(srl),4)

    of ClaSTRING
      cst = rl
      len = len(cst)
      If len > pClarionLength and self.opt:ignoretruncation = false
        self.SetError(DataTruncatedErr)
        self.SetFileError(DataTruncatedErr,'Field: ' & clip(pFieldLabel) & ' SQL Type: ' & self.InterpretSQLType(pCellType) & '(' & pCellType & ')' & ' Clarion Type: ' & self.InterpretType(pClarionType) & '(' & pClarionLength & ')' & ' value: ' & rl)
        Return
      End
      memcpy(pClarionAddress,address(cst),len)
      StrLen = len
      If rTextLength = 0 then do PadString.
      rTextLength = Len

    of ClaCSTRING
      cst = rl
      len = len(cst)
      If len > pClarionLength and self.opt:ignoretruncation = false
        self.SetError(DataTruncatedErr)
        self.SetFileError(DataTruncatedErr,'Field: ' & clip(pFieldLabel) & ' SQL Type: ' & self.InterpretSQLType(pCellType) & '(' & pCellType & ')' & ' Clarion Type: ' & self.InterpretType(pClarionType) & '(' & pClarionLength & ')' & ' value: ' & rl)
        Return
      End
      memcpy(pClarionAddress,address(cst),len+1)
      StrLen = len
      do PadString

    else
      self.SetError(FieldMismatchErr)
      self.SetFileError(FieldMismatchErr,'Field: ' & clip(pFieldLabel) & ' SQL Type: ' & self.InterpretCType(pCellType) & '(' & pCellType & ')' & ' Clarion Type: ' & self.InterpretType(pClarionType) & '(' & pClarionType & ')' & ' value: ' )
    end

!endregion
!region - SQL_C_TYPE_TIMESTAMP
  ! ==========================
  of SQL_C_TYPE_TIMESTAMP
    Clear(bindatetime,-1)
    len = size(bindatetime)                            ! will be including tz
    If pCellLength < len then len = pCellLength.       ! pCell might include tz, or not. If not, then trim the len a bit
    MemCpy(Address(bindatetime),pCellAddress,len)

    If bindatetime.year < 1 then bindatetime.year = 1
    Elsif bindatetime.year > 9999 then bindatetime.year = 9999
    End
    If bindatetime.month < 1 then bindatetime.month = 1
    Elsif bindatetime.month > 12 then bindatetime.month = 12
    End
    If bindatetime.day < 1 then bindatetime.day = 1
    Elsif bindatetime.day > 31 then bindatetime.day = 31
    End

    Case pClarionType
    of ClaString
      If pSqlTimeStamp >= driver:GroupOverTimeStamp and pSqlTimeStamp <= driver:GroupOverTimeStampTZ
        dtl = bshift(bindatetime.year,16) + bshift(bindatetime.month,8) + bindatetime.day
        tml = bshift(bindatetime.hour,24) + bshift(bindatetime.minute,16) + bshift(bindatetime.second,8) + bindatetime.fraction / 10000000
        lg = tm
        Case pSqlTimeStamp
        of driver:GroupOverTimeStamp
          memcpy(pClarionAddress,address(dt),4)
          memcpy(pClarionAddress+4,address(tm),4)

        of driver:GroupOverTimeStampTZ
          memcpy(pClarionAddress,address(dt),4)
          memcpy(pClarionAddress+4,address(tm),4)
          lg = bindatetime.timezone_hour * 360000 + bindatetime.timezone_minute * 6000  ! if neg, both hour and minute are neg, so this works
          memcpy(pClarionAddress+8,address(lg),4)

        of driver:GroupOverTimeStamp2
          memcpy(pClarionAddress,address(dt),4)
          lg = tm
          memcpy(pClarionAddress+4,address(lg),4)

        of driver:GroupOverTimeStamp3
          lg = dt
          memcpy(pClarionAddress,address(lg),4)
          memcpy(pClarionAddress+4,address(tm),4)

        of driver:GroupOverTimeStamp4
          lg = dt
          memcpy(pClarionAddress,address(lg),4)
          lg = tm
          memcpy(pClarionAddress+4,address(lg),4)
        End

      Else
        strmem = format(bindatetime.year,@n04) & '-' & format(bindatetime.month,'@n02') & '-' & format(bindatetime.day,'@n02') & self.DateTimeSeparator |
               & format(bindatetime.hour,'@n02') & ':' & format(bindatetime.minute,'@n02') & ':' & format(bindatetime.second,'@n02')
        lg = self.DatabaseFieldPrecision[self.fields.index]
        if lg
          strmem = clip(strmem) & '.' & sub(bindatetime.fraction,1,lg)
        End
        if pSqlTimeStamp = driver:StringToTimeStampTZ
          if bindatetime.timezone_hour >= 0
            strmem = clip(strmem) & ' +' & format(bindatetime.timezone_hour,@n02) & ':' & format(bindatetime.timezone_minute,@n02)
          else
            strmem = clip(strmem) & ' -' & format(bindatetime.timezone_hour*-1,@n02) & ':' & format(bindatetime.timezone_minute*-1,@n02)
          end
        end
        len = len(clip(strmem))
        memcpy(pClarionAddress,address(strmem),len)
        StrLen = len
        If rTextLength = 0 then do PadString.
        rTextLength = Len
      End

    of ClaCString
        strmem = format(bindatetime.year,@n04) & '-' & format(bindatetime.month,'@n02') & '-' & format(bindatetime.day,'@n02') & self.DateTimeSeparator |
               & format(bindatetime.hour,'@n02') & ':' & format(bindatetime.minute,'@n02') & ':' & format(bindatetime.second,'@n02')
        lg = self.DatabaseFieldPrecision[self.fields.index]
        if lg
          strmem = clip(strmem) & '.' & sub(bindatetime.fraction,1,lg)
        End
        if pSqlTimeStamp = driver:StringToTimeStampTZ
          if bindatetime.timezone_hour >= 0
            strmem = clip(strmem) & ' +' & format(bindatetime.timezone_hour,@n02) & ':' & format(bindatetime.timezone_minute,@n02)
          else
            strmem = clip(strmem) & ' -' & format(bindatetime.timezone_hour*-1,@n02) & ':' & format(bindatetime.timezone_minute*-1,@n02)
          end
        end

        len = len(clip(strmem))
        memcpy(pClarionAddress,address(strmem),len)
        StrLen = len
        If rTextLength = 0 then do PadString.
        rTextLength = Len

!    of ClaLONG
!      lg = date(bindate.month, bindate.day, bindate.year)
!      memcpy(pClarionAddress,address(lg),4)
!    of ClaDATE
!      dt = date(bindate.month, bindate.day, bindate.year)
!      memcpy(pClarionAddress,address(dt),4)
    else
      self.SetError(FieldMismatchErr)
      self.SetFileError(FieldMismatchErr,'Field Mismatch Error: Field: ' & clip(pFieldLabel) & ' SQL Type: ' & self.InterpretCType(pCellType) & '(' & pCellType & ')' & ' Clarion Type: ' & self.InterpretType(pClarionType) & '(' & pClarionType & ')' & ' value: ' )
    end

!endregion
!region - SQL_C_DATE
  ! ================
  of SQL_C_DATE
  orof SQL_C_TYPE_DATE
    MemCpy(Address(bindate),pCellAddress,size(bindate))

    If bindate.year < 1 then bindate.year = 1
    Elsif bindate.year > 9999 then bindate.year = 9999
    End
    If bindate.month < 1 then bindate.month = 1
    Elsif bindate.month > 12 then bindate.month = 12
    End
    If bindate.day < 1 then bindate.day = 1
    Elsif bindate.day > 31 then bindate.day = 31
    End

    dtl = bshift(bindate.year,16) + bshift(bindate.month,8) + bindate.day  !!!todo dates before 1801 are out of range.

    Case pClarionType
    of ClaLONG
      lg = dt ! date(bindate.month, bindate.day, bindate.year)
      memcpy(pClarionAddress,address(lg),4)
    of ClaDATE
      memcpy(pClarionAddress,address(dt),4)
    of ClaSTRING
    orof ClaCSTRING   ! date to string is in format yyyy/mm/dd
      strmem = format(bindate.year,@n04) & '/' & format(bindate.month,@n02) & '/' & format(bindate.day,@n02)   !!!todo, fixed date format here?
      len = 10
      If len > pClarionLength and self.opt:ignoretruncation = false
        self.SetError(DataTruncatedErr)
        self.SetFileError(DataTruncatedErr,'Field: ' & clip(pFieldLabel) & ' SQL Type: ' & self.InterpretSQLType(pCellType) & '(' & pCellType & ')' & ' Clarion Type: ' & self.InterpretType(pClarionType) & '(' & pClarionLength & ')' & ' value: ' & strmem)
        Return
      End
      If len > pClarionLength then len = pClarionLength.
      memcpy(pClarionAddress,address(strmem),len)
      StrLen = len
      If rTextLength = 0 then do PadString.
      rTextLength = StrLen
    Else
      self.SetError(FieldMismatchErr)
      self.SetFileError(FieldMismatchErr,'Field: ' & clip(pFieldLabel) & ' SQL Type: ' & self.InterpretCType(pCellType) & '(' & pCellType & ')' & ' Clarion Type: ' & self.InterpretType(pClarionType) & '(' & pClarionType & ')' & ' value: ' )
    End

!endregion
!region - SQL_SS_TIME2
  ! ==================
  of SQL_C_SS_TIME2
    Case pClarionType
    of ClaTIME
      clear(bintime,-1)
      memcpy(address(bintime),pCellAddress,pCellLength)
      lg = bshift(bintime.hour,24) + bshift(bintime.minute,16) + bshift(bintime.second,8) + (bintime.fraction / 10000000)
      memcpy(pClarionAddress,address(lg),4)
    of ClaSTRING
    orof ClaCSTRING
      If self.fields.index
        lg = self.DatabaseFieldPrecision[self.fields.index]
      else
        lg = 7
      End
      memcpy(address(bintime),pCellAddress,pCellLength)
      if lg = 0
        strmem = format(bintime.hour,@n02) & ':' & format(bintime.minute,@n02) & ':' & format(bintime.second,@n02)
      else
        strmem = format(bintime.hour,@n02) & ':' & format(bintime.minute,@n02) & ':' & format(bintime.second,@n02) & '.' & sub(bintime.fraction,1,lg)
      end
      Len = len(clip(strmem))
      If len > pClarionLength and self.opt:ignoretruncation = false
        self.SetError(DataTruncatedErr)
        self.SetFileError(DataTruncatedErr,'Field: ' & clip(pFieldLabel) & ' SQL Type: ' & self.InterpretSQLType(pCellType) & '(' & pCellType & ')' & ' Clarion Type: ' & self.InterpretType(pClarionType) & '(' & pClarionLength & ')' & ' value: ' & strmem)
        Return
      End
      If len > pClarionLength then len = pClarionLength.
      memcpy(pClarionAddress,address(strmem),Len)
      StrLen = Len
      If rTextLength = 0 then do PadString.
      rTextLength = StrLen
    Else
      self.SetError(FieldMismatchErr)
      self.SetFileError(FieldMismatchErr,'Field: ' & clip(pFieldLabel) & ' SQL Type: ' & self.InterpretCType(pCellType) & '(' & pCellType & ')' & ' Clarion Type: ' & self.InterpretType(pClarionType) & '(' & pClarionType & ')' & ' value: ' )
    End

!endregion
!region - SQL_C_TIME
  ! ================
  of SQL_C_TIME
    !!!todo experiment with different SQL time types
    Case pClarionType
    else
      self.SetError(FieldMismatchErr)
      self.SetFileError(FieldMismatchErr,'Field: ' & clip(pFieldLabel) & ' SQL Type: ' & self.InterpretCType(pCellType) & '(' & pCellType & ')' & ' Clarion Type: ' & self.InterpretType(pClarionType) & '(' & pClarionType & ')' & ' value: ' )
    end

!endregion
!region - SQL_C_TIMESTAMP
  ! =====================
  of SQL_C_TIMESTAMP                                  ! Maps to Clarion Group with Date and Time
    If pClarionType = ClaSTRING
      str &= pCellAddress & ':' & pCellLength
      If pSqlTimeStamp
        strmem = self.DeformatText(str,pSqlTimeStamp)
        !!!todo map TimeStamp to Date Time
        len = 8
        If pClarionLength < len and self.opt:ignoretruncation = false
          self.SetError(DataTruncatedErr)
          self.SetFileError(DataTruncatedErr,'Field: ' & clip(pFieldLabel) & ' SQL Type: ' & self.InterpretCType(pCellType) & '(' & pCellLength & ')' & ' Clarion Type: ' & self.InterpretType(pClarionType) & '(' & pClarionLength & ')' & ' value: ' & str)
          Return
        End
        If len > pClarionLength then len = pClarionLength.
        memcpy(pClarionAddress,address(strmem),len)
      Else
        len = len(clip(str))
        strmem = str
        memcpy(pClarionAddress,address(strmem),len)
        StrLen = Len
        If rTextLength = 0 then do PadString.
        rTextLength = StrLen
      End
    else
      self.SetError(FieldMismatchErr)
      self.SetFileError(FieldMismatchErr,'Field: ' & clip(pFieldLabel) & ' SQL Type: ' & self.InterpretCType(pCellType) & '(' & pCellType & ')' & ' Clarion Type: ' & self.InterpretType(pClarionType) & '(' & pClarionType & ')' & ' value: ' )
    End

!endregion
!region - SQL_C_BINARY
  ! ==================
  of SQL_C_BINARY
    Case pClarionType
    of ClaTime
      memcpy(address(bintime),pCellAddress,pCellLength)
      lg = bshift(bintime.hour,24) + bshift(bintime.minute,16) + bshift(bintime.second,8) + (bintime.fraction / 10000000)
      memcpy(pClarionAddress,address(lg),4)

    of ClaMEMO
    orof ClaSTRING
      str &= pCellAddress & ':' & pCellLength
      len = pCellLength
      If pClarionLength < len and self.opt:ignoretruncation = false
        self.SetFileError(DataTruncatedErr,'Field: ' & clip(pFieldLabel) & ' SQL Type: ' & self.InterpretCType(pCellType) & '(' & pCellLength & ')' & ' Clarion Type: ' & self.InterpretType(pClarionType) & '(' & pClarionLength & ')' & ' value: ' & str)
        self.SetError(DataTruncatedErr)
        Return
      End
      If len > pClarionLength then len = pClarionLength.
      memcpy(pClarionAddress,pCellAddress,len)
      StrLen = len
      If rTextLength = 0 then do PadString.
      rTextLength = StrLen

    !of ClaCSTRING
    !  If pClarionLength = 37 and pCellLength = 16
    !  End

    of ClaBLOB
      self.SetBlobFromAddr(pClarionAddress, 0, pCellAddress, pCellLength)      ! if ClaBlob then pClarionAddress is the blob index

    else
      self.SetError(FieldMismatchErr)
      self.SetFileError(FieldMismatchErr,'Field: ' & clip(pFieldLabel) & ' SQL Type: ' & self.InterpretCType(pCellType) & '(' & pCellType & ')' & ' Clarion Type: ' & self.InterpretType(pClarionType) & '(' & pClarionType & ')' & ' value: ' )
    End

!endregion
!region - SQL_C_WCHAR
  of SQL_C_WCHAR
    str &= pCellAddress & ':' & pCellLength
    ansistr &= self.tempstr.Utf16ToAnsi(str,len,pCellLength/2,self.codePage)
    If ansistr &= null
      self.SetFileError(UnicodeConversionError,'Field: ' & clip(pFieldLabel) & ' SQL Type: ' & self.InterpretCType(pCellType) & '(' & pCellLength & ')' & ' Clarion Type: ' & self.InterpretType(pClarionType) & '(' & pClarionLength & ')' & ' value: ' & str)
      self.SetError(UnicodeConversionError)
      Return
    Else
      Case pClarionType
      of ClaSTRING
        If pClarionLength < len and self.opt:ignoretruncation = false
          self.SetError(DataTruncatedErr)
          self.SetFileError(DataTruncatedErr,'Field: ' & clip(pFieldLabel) & ' SQL Type: ' & self.InterpretCType(pCellType) & '(' & pCellLength & ')' & ' Clarion Type: ' & self.InterpretType(pClarionType) & '(' & pClarionLength & ')' & ' value: ' & ansistr)
          Dispose(AnsiStr)
          Return
        End
        If len > pClarionLength then len = pClarionLength.
        memcpy(pClarionAddress,address(ansistr),len)
        StrLen = len
        If rTextLength = 0 then do PadString.
        rTextLength = StrLen

      of ClaCSTRING
        If pClarionLength < len and self.opt:ignoretruncation = false
          self.SetFileError(DataTruncatedErr,'Field: ' & clip(pFieldLabel) & ' SQL Type: ' & self.InterpretCType(pCellType) & '(' & pCellLength & ')' & ' Clarion Type: ' & self.InterpretType(pClarionType) & '(' & pClarionLength & ')' & ' value: ' & ansistr)
          self.SetError(DataTruncatedErr)
          Dispose(AnsiStr)
          Return
        End
        If len > pClarionLength then len = pClarionLength.
        memcpy(pClarionAddress,address(ansistr),len)
        memset(pClarionAddress+len,0,1)
        StrLen = len
        do PadString
      End
      Dispose(AnsiStr)
    End

!endregion
!region - SQL_C_CHAR
  ! ================
  of SQL_C_CHAR                                   ! all these map to String, Cstring, PString, Memo and Blob
    Case pClarionType
    of ClaCSTRING
      len = pCellLength
      If pClarionLength < len + 1 and self.opt:ignoretruncation = false
        str &= pCellAddress & ':' & pCellLength
        self.SetFileError(DataTruncatedErr,'Field: ' & clip(pFieldLabel) & ' SQL Type: ' & self.InterpretCType(pCellType) & '(' & pCellLength & ')' & ' Clarion Type: ' & self.InterpretType(pClarionType) & '(' & pClarionLength & ')' & ' value: ' & str)
        self.SetError(DataTruncatedErr)
        Return
      End
      If len > pClarionLength then len = pClarionLength.
      memcpy(pClarionAddress,pCellAddress,len)
      memset(pClarionAddress+pCellLength,0,1)
      StrLen = len
      do PadString

    of ClaSTRING
      len = pCellLength
      If pClarionLength < len and self.opt:ignoretruncation = false
        str &= pCellAddress & ':' & (pCellLength)
        self.SetError(DataTruncatedErr)
        self.SetFileError(DataTruncatedErr,'Field: ' & clip(pFieldLabel) & ' SQL Type: ' & self.InterpretCType(pCellType) & '(' & pCellLength & ')' & ' Clarion Type: ' & self.InterpretType(pClarionType) & '(' & pClarionLength & ')' & ' value: ' & str)
        Return
      End
      If len > pClarionLength then len = pClarionLength.
      memcpy(pClarionAddress,pCellAddress,len)
      StrLen = len
      If rTextLength = 0 then do PadString.
      rTextLength = StrLen

    of ClaMEMO
      !If pCellLength <> 0 then pCellLength -= 1.
      str &= pCellAddress & ':' & (pCellLength)
      len = pCellLength
      If pClarionLength < len and self.opt:ignoretruncation = false
        self.SetError(DataTruncatedErr)
        self.SetFileError(DataTruncatedErr,'Field: ' & clip(pFieldLabel) & ' SQL Type: ' & self.InterpretCType(pCellType) & '(' & pCellLength & ')' & ' Clarion Type: ' & self.InterpretType(pClarionType) & '(' & pClarionLength & ')' & ' value: ' & str)
        Return
      End
      If len > pClarionLength then len = pClarionLength.
      memcpy(pClarionAddress,pCellAddress,pCellLength)
      StrLen = len
      do PadString

    of ClaPSTRING
      str &= pCellAddress & ':' & pCellLength
      len = pCellLength
      If pClarionLength < len + 1 and self.opt:ignoretruncation = false
        self.SetError(DataTruncatedErr)
        self.SetFileError(DataTruncatedErr,'Field: ' & clip(pFieldLabel) & ' SQL Type: ' & self.InterpretCType(pCellType) & '(' & pCellLength & ')' & ' Clarion Type: ' & self.InterpretType(pClarionType) & '(' & pClarionLength & ')' & ' value: ' & str)
        Return
      End
      If len > pClarionLength then len = pClarionLength.
      memcpy(pClarionAddress+1,pCellAddress,len)
      memset(pClarionAddress,len,1)
      StrLen = len
      do PadString

    of ClaBLOB
      self.SetBlobFromAddr(pClarionAddress, 0, pCellAddress, pCellLength)      ! if ClaBlob then pClarionAddress is the blob index

    !of ClaDATE
      !!!todo map string date to ClaDate
      !str &= pCellAddress & ':' & pCellLength
      !strmem = self.DeformatText(str)
      !memcpy(pClarionAddress,address(strmem),4)

    !of ClaTime
       !!!todo map string date to ClaTime
    !  str &= pCellAddress & ':' & pCellLength
    !  strmem = self.DeformatText(str)
    !  memcpy(pClarionAddress,address(strmem),4)

    of ClaDECIMAL
    orof ClaPDECIMAL
      str &= pCellAddress & ':' & pCellLength
      self._StringToDec(str,self.Fields.Type, address(strmem), self.Fields.DecimalSize, self.Fields.DecimalPlaces)
      memcpy(pClarionAddress,address(strmem),pClarionLength)

    of ClaLONG
      str &= pCellAddress & ':' & pCellLength
      lg = str
      memcpy(pClarionAddress,address(lg),4)

    of ClaULONG
      str &= pCellAddress & ':' & pCellLength
      ulg = str
      memcpy(pClarionAddress,address(ulg),4)

    of ClaSHORT
      str &= pCellAddress & ':' & pCellLength
      sh = str
      memcpy(pClarionAddress,address(sh),2)

    of ClaUSHORT
      str &= pCellAddress & ':' & pCellLength
      ush = str
      memcpy(pClarionAddress,address(ush),2)

    of ClaBYTE
      str &= pCellAddress & ':' & pCellLength
      bt = str
      memcpy(pClarionAddress,address(bt),1)

    of ClaREAL
      str &= pCellAddress & ':' & pCellLength
      rl = str
      memcpy(pClarionAddress,address(rl),8)

    of ClaSREAL
      str &= pCellAddress & ':' & pCellLength
      srl = str
      memcpy(pClarionAddress,address(srl),4)

    else
      str &= pCellAddress & ':' & pCellLength
      self.SetError(FieldMismatchErr)
      self.SetFileError(FieldMismatchErr,'Field: ' & clip(pFieldLabel) & ' SQL Type: ' & self.InterpretCType(pCellType) & '(' & pCellType & ')' & ' Clarion Type: ' & self.InterpretType(pClarionType) & '(' & pClarionType & ')' & ' value: ' )

    End

!endregion
!region - SQL_C_SBIGINT
  ! ================
  of SQL_C_SBIGINT
    Case pClarionType
    of ClaULONG
      memcpy(address(bigi),pCellAddress,8)
      If self._i64Fit(bigi,ClaULONG,0) = driver:notok !and self.opt:ignoretruncation = false
        self.SetError(DataTruncatedErr)
        self.SetFileError(DataTruncatedErr,'Field: ' & clip(pFieldLabel) & ' SQL Type: ' & self.InterpretCType(pCellType) & '(' & pCellType & ')' & ' Clarion Type: ' & self.InterpretType(pClarionType) & '(' & 2 & ')' & ' value: ' & bigd)
        Return
      End
      memcpy(pClarionAddress,pCellAddress,4)

    of ClaSTRING
      memcpy(address(bigi),pCellAddress,8)
      Len = self._i64ToCString(bigi,cst)
      If Len > pClarionLength and self.opt:ignoretruncation = false
        self.SetError(DataTruncatedErr)
        self.SetFileError(DataTruncatedErr,'Field: ' & clip(pFieldLabel) & ' SQL Type: ' & self.InterpretSQLType(pCellType) & '(' & pCellType & ')' & ' Clarion Type: ' & self.InterpretType(pClarionType) & '(' & pClarionLength & ')' & ' value: ' & rl)
        Return
      End
      If Len > pClarionLength then Len = pClarionLength.
      memcpy(pClarionAddress,address(cst),Len)
      StrLen = Len
      If rTextLength = 0 then do PadString.
      rTextLength = StrLen

    of ClaCSTRING
      memcpy(address(bigi),pCellAddress,8)
      Len = self._i64ToCString(bigi,cst)
      If Len > pClarionLength-1 and self.opt:ignoretruncation = false
        self.SetError(DataTruncatedErr)
        self.SetFileError(DataTruncatedErr,'Field: ' & clip(pFieldLabel) & ' SQL Type: ' & self.InterpretSQLType(pCellType) & '(' & pCellType & ')' & ' Clarion Type: ' & self.InterpretType(pClarionType) & '(' & pClarionLength & ')' & ' value: ' & rl)
        Return
      End
      If Len > pClarionLength-1 then Len = pClarionLength-1.
      memcpy(pClarionAddress,address(cst),Len)
      StrLen = Len
      If rTextLength = 0 then do PadString.
      rTextLength = StrLen

    of ClaDECIMAL
      memcpy(address(bigi),pCellAddress,8)
      bigd = bigi.hi * 0FFFFFFFFh + bigi.lo
      strmem = bigd
      self._StringToDec(strmem,self.Fields.Type, address(strmem), self.Fields.DecimalSize, self.Fields.DecimalPlaces)
      memcpy(pClarionAddress,address(strmem),pClarionLength)

    of ClaPDECIMAL  !!!todo
    Else
      self.SetError(FieldMismatchErr)
      self.SetFileError(FieldMismatchErr,'Field: ' & clip(pFieldLabel) & ' SQL Type: ' & self.InterpretCType(pCellType) & '(' & pCellType & ')' & ' Clarion Type: ' & self.InterpretType(pClarionType) & '(' & pClarionType & ')' & ' value: ')
    End
!endregion
!region - SQL_C_BIT
  ! ================================
  of SQL_C_BIT
    !!! todo map BIT type to something
    Case pClarionType
    Else
      self.SetError(FieldMismatchErr)
      self.SetFileError(FieldMismatchErr,'Field: ' & clip(pFieldLabel) & ' SQL Type: ' & self.InterpretCType(pCellType) & '(' & pCellType & ')' & ' Clarion Type: ' & self.InterpretType(pClarionType) & '(' & pClarionType & ')' & ' value: ' )
    End
!endregion
!region - SQL_NULLTYPE
  !=====================
  of SQL_NULLTYPE
    case pClarionType
    of ClaBLOB
      self.SetBlobFromAddr(pClarionAddress, 0, pCellAddress, pCellLength)      ! if ClaBlob then pClarionAddress is the blob index
    of ClaMEMO
      StrLen = 0
      do PadString
    Else
      If pSetFieldNull
        self._SetFieldNull()
      Else
        case pClarionType        ! these 4 cases are for the BindQueue
        of ClaLONG
          lg = 0
          memcpy(pClarionAddress,address(lg),4)
        of ClaREAL
          rl = 0
          memcpy(pClarionAddress,address(rl),8)
        of ClaSTRING
          str &= pClarionAddress & ':' & (pClarionLength)
          str = ''
        of ClaCSTRING
          cstr &= pClarionAddress & ':' & (pClarionLength)
          cstr = ''
        End
      End
    End
!endregion
!region - else

  Else
    self.SetError(FieldMismatchErr)
    self.SetFileError(FieldMismatchErr,'Field: ' & clip(pFieldLabel) & ' SQL Type: ' & self.InterpretCType(pCellType) & '(' & pCellType & ')' & ' Clarion Type: ' & self.InterpretType(pClarionType) & '(' & pClarionType & ')' & ' value: ' )
!endregion
  End

! StrLen is the length of the incoming sql string (not including the terminating 0) - which may be less than the clarion string.
PadString  routine
  If pClarionLength > StrLen and StrLen >= 0
    Case pClarionType
    of ClaSTRING  orof ClaMEMO
       memset(pClarionAddress + StrLen ,32, pClarionLength - StrLen)               ! pad with spaces
    of ClaCSTRING
       memset(pClarionAddress + StrLen ,0, pClarionLength - StrLen)               ! pad with zeros
    of ClaPSTRING
      If pClarionLength-1 > StrLen
        memset(pClarionAddress + StrLen + 1,32, pClarionLength - StrLen - 1)     ! pad with spaces
      End
    End
  End

!-----------------------------------------------------------------
DriverFileMSSQL2Class._ParseDefaultDefault   Procedure(FieldGroupType pNode)
  code
  If pNode.sqlUuid = true
    pNode.HasDefault = true
    case pNode.UUID
    of 4
      pNode.DefaultValue = '!NEWID()'
    of 7
      pNode.DefaultValue = '!NEWSEQUENTIALID()'
    End
  End

!-----------------------------------------------------------------
DriverFileMSSQL2Class._ParseFieldSQLType       Procedure(FieldGroupType pNode)
  code
  parent._ParseFieldSQLType(pNode)
  Case upper(pNode.SqlType)
  of 'BOOLEAN'
    pNode.SqlType = 'BIT'
  of 'TIMESTAMPTZ'
    pNode.SqlType = 'DATETIMEOFFSET'
  of 'UUID'
    pNode.SqlType = 'UNIQUEIDENTIFIER'
  End

  Case upper(pNode.SqlType)
  of 'BIT'
    !pNode.BooleanType = true
  of 'CHAR'
    case pNode.Type
    of ClaCSTRING
      pNode.SqlType = 'CHAR(' & pNode.Size-1 & ')'
    Else
      pNode.SqlType = 'CHAR(' & pNode.Size & ')'
    End
  of 'NVARCHAR'
    pNode.SqlType = 'NVARCHAR(' & pNode.Size & ')'
  of 'NCHAR'
    case pNode.Type
    of ClaCSTRING
      pNode.SqlType = 'NCHAR(' & pNode.Size-1 & ')'
    Else
      pNode.SqlType = 'NCHAR(' & pNode.Size & ')'
    end
  of 'STRING'
    case pNode.Type
    of ClaCSTRING
      pNode.SqlType = 'VARCHAR(' & pNode.Size-1 & ')'
    Else
      pNode.SqlType = 'CHAR(' & pNode.Size & ')'
    End
  Of 'UNIQUEIDENTIFIER'
    pNode.sqlUuid = true
  of 'VARCHAR'
    case pNode.Type
    of ClaCSTRING
      pNode.SqlType = 'VARCHAR(' & pNode.Size-1 & ')'
    Else
      pNode.SqlType = 'VARCHAR(' & pNode.Size & ')'
    End
  Else
    If pNode.Size = 8
      If Instring('DATETIME2',upper(pNode.SqlType),1,1) or Instring('DATETIME',upper(pNode.SqlType),1,1)
        pNode.SqlTimeStamp = driver:GroupOverTimeStamp
      ElsIf Instring('DATETIMEOFFSET',upper(pNode.SqlType),1,1)
        pNode.SqlTimeStamp = driver:GroupOverTimeStampTZ
      End
    ElsIf pNode.Size = 12
      If Instring('DATETIMEOFFSET',upper(pNode.SqlType),1,1) or Instring('TIMESTAMPTZ',upper(pNode.SqlType),1,1)
        pNode.SqlTimeStamp = driver:GroupOverTimeStampTZ
      End
    ElsIf pNode.Size > 12
      If Instring('DATETIME2',upper(pNode.SqlType),1,1)
        pNode.SqlTimeStamp = driver:StringToTimeStamp2
      ElsIf Instring('DATETIMEOFFSET',upper(pNode.SqlType),1,1) or Instring('TIMESTAMPTZ',upper(pNode.SqlType),1,1)
        pNode.SqlTimeStamp = driver:StringToTimeStampTZ
      ElsIf Instring('DATETIME',upper(pNode.SqlType),1,1)
        pNode.SqlTimeStamp = driver:StringToTimeStamp
      End
    End
  End
  Return

!-----------------------------------------------------------------
! take a SQL statement and pass it to the MSSQL prepare call
DriverFileMSSQL2Class._Prepare  Procedure()
  code
  Return self._prepare(self.SqlCode)

!-----------------------------------------------------------------
! take a SQL statement and pass it to the MSSQL prepare call
DriverFileMSSQL2Class._Prepare  Procedure(StringTheory pSqlCode)
result        long,Auto
stmt          long
  Code
  If pSqlCode.Length() = 0 then return 0.

! Allocate a statement handle
  result = SQLAllocHandle(SQL_HANDLE_STMT, self.dbHandle, stmt)
  IF result <> SQL_SUCCESS AND result <> SQL_SUCCESS_WITH_INFO
    self.SetErrorMssql(SQL_HANDLE_DBC,self.dbHandle,'[d021]')
    Return SQL_NULL_HSTMT
  End

  ! Set statement attributes to avoid server-side cursors
  ! Force forward-only cursor for efficiency

  ! Prepare the SQL statement
  result = SQLPrepare(stmt, pSqlCode.GetAddress(), pSqlCode.Length())

  IF result <> SQL_SUCCESS AND result <> SQL_SUCCESS_WITH_INFO
    self.SetErrorMssql(SQL_HANDLE_STMT,stmt,'[d025]')
    result = SQLFreeHandle(SQL_HANDLE_STMT, stmt)
    Return SQL_NULL_HSTMT
  End
  result = SQLNumResultCols(stmt, self._StmtCols)
  Return stmt

!-----------------------------------------------------------------
DriverFileMSSQL2Class.RemoveStoredProcedure       Procedure(String pSPName)
  Code
  If pSPName = '' then return driver:ok.
  self.SqlCode.SetValue('IF OBJECT_ID(''' & pSPName & ''', ''P'') IS NOT NULL DROP PROCEDURE ' & pSPName & ';')
  Return self._ExecuteSqlNoParms()

!-----------------------------------------------------------------
DriverFileMSSQL2Class._SetBusyTimeOut         PROCEDURE(Long pTimeOut)
Result  Long
  Code
  result = SQLSetConnectAttr(self.dbHandle, SQL_ATTR_CONNECTION_TIMEOUT, pTimeOut, SQL_IS_INTEGER)
  Return

!-----------------------------------------------------------------
DriverFileMSSQL2Class._SetBusyRetries         PROCEDURE(Long pTries)
Result  Long
  Code
  !result = SQLSetConnectAttr(self.dbHandle, SQL_ATTR_CONNECTION_TIMEOUT, pTimeOut, SQL_IS_INTEGER)
  Return

!-----------------------------------------------------------------
DriverFileMSSQL2Class.SetErrorMssql  PROCEDURE(Long pHandleType, Long pHandle, String pRef)
SqlState     Cstring(6)
odbcMessage  cString(4096)  ! odbc has no max length defined, so this could fail.
mess         StringTheory
ReqSize      UShort
NativeError  Long
NativeError1 Long
Result       SqlReturn,Auto
x            Long,Auto
lc           Long
row          uLong
column       uLong
Slip         short
  Code
  x = 1
  !self.trace('DriverFileMSSQL2Class.SetErrorMssql  sem 1')
  Loop
    result = SQLGetDiagRec(pHandleType, pHandle, x, address(SqlState), Address(NativeError), address(odbcMessage), Size(odbcMessage), ReqSize)
    !self.trace('DriverFileMSSQL2Class.SetErrorMssql x=' & x & ' opcode=' & self._ParameterOpcode & ' pRef=' & pRef & ' sqlState=' & sqlState & ' NativeError=' & NativeError & ' odbcMessage=' & odbcMessage )
    If x = 1
      NativeError1 = NativeError
      Case SqlState
      of '22003'
        self.SetError(DataTruncatedErr)
      of '23000'
        case self._ParameterOpcode
        of Opcode:DELETE
          self.SetError(RestrictedDeleteErr)
        of Opcode:ADD
          case NativeError
          of 515  !Cannot insert the value NULL into column 'NotNull1', table 'filedriverkit.dbo.VAL121'; column does not allow nulls. INSERT fails.]
            self.SetError(NotNullFailedErr)
          of 547  ! The INSERT statement conflicted with the CHECK constraint "check_NotEqual1". The conflict occurred in database "filedriverkit", table "dbo.VAL121", column 'NotEqual1'.
            if instring('FOREIGN KEY constraint',odbcMessage,1,1)   ! The INSERT statement conflicted with the FOREIGN KEY constraint "FK__LineItems__INVOI__2DF1BF10". The conflict occurred in database "filedriverkitRel", table "dbo.Invoice", column 'Guid'. // [Microsoft][ODBC Driver 17 for SQL Server][SQL Server]The statement has been terminated.[LineItems]
              self.SetError(ForeignKeyFailedErr)
            else
              self.SetError(InvalidFieldErr)
            end
          else
            self.SetError(DupKeyErr)
          End
        of Opcode:DUPLICATE
          self.SetError(DupKeyErr)
        of Opcode:PUT
          case NativeError
          of 2627
          orof 2601
            self.SetError(DupKeyErr)
          else
            self.SetError(ForeignKeyFailedErr)
          end
        else
          self.SetError(ForeignKeyFailedErr)
        End
      of '42S01'  ! Object already exists (like table, stored procedure etc)
        self.SetError(ObjectExistsErr)    !

      of '42S02'  ! Object does not exist, or permission nt granted.
        self.SetError(NoFileErr)    !

      of '42S22' ! Column Not Found
        self.SetError(FileSystemErr)

      of '2601'
        self.SetError(DupKeyErr)
      of 'HYT00'
        self.SetError(NoAccessErr)
      else
        !self.trace('sem 5 ' & SqlState & ' ' & NativeError1)
        self.SetError(FileSystemErr)
      end
    End
    !self.trace('sem 6 ' & odbcMessage)
    lc =  len(clip(odbcMessage))
    !self.trace('DriverFileMSSQL2Class.SetErrorMssql Result=' & Result & ' pHandleType=' & pHandleType & ' pHandle=' & pHandle & ' x=' & x & ' ReqSize=' & ReqSize & ' pRef=' & pRef & ' lc=' & lc)

    case result
    of SQL_SUCCESS
    of SQL_NO_DATA
      If x = 1
        !self.trace(clip(pRef) & 'SQLGetDiagRec=SQL_NO_DATA SqlState=' & SqlState & ' NativeError=' & NativeError & ' ' & clip(odbcMessage) )
        !self.SetFileError(NativeError, clip(pRef) & 'SQLGetDiagRec=SQL_NO_DATA SqlState=' & SqlState & ' NativeError=' & NativeError & ' ' & clip(odbcMessage))
        mess.append('SQLGetDiagRec=SQL_NO_DATA SqlState=' & SqlState & ' NativeError=' & NativeError & ' ' & clip(odbcMessage))
      end
      break
    else
      break
    End
    result = SQLGetDiagField(pHandleType, pHandle, x, SQL_DIAG_ROW_NUMBER,address(row), 4,slip)        ! row is base 1
    result = SQLGetDiagField(pHandleType, pHandle, x, SQL_DIAG_COLUMN_NUMBER,address(column), 4,slip)  ! column is base 1
    self.trace(clip(pRef) & ' SqlState=' & SqlState & ' NativeError=' & NativeError & ' row=' & row & ' column=' & column & ' [' & clip(odbcMessage) & ']')
    !if x = 1 then self.SetFileError(NativeError, clip(pRef) & ' SqlState=' & SqlState & ' NativeError=' & NativeError & ' row=' & row & ' column=' & column & ' ' & clip(odbcMessage)).
    if x = 1
      mess.append(' SqlState=' & SqlState & ' NativeError=' & NativeError & ' row=' & row & ' column=' & column & ' ' & clip(odbcMessage))
    else
      mess.append(' // ' &  clip(odbcMessage))
    end
    x += 1
  End
  self.SetFileError(NativeError1, clip(pRef) & mess.GetValue())
  !self.trace('set error done')
  Return

!-----------------------------------------------------------------
! A statement has been primed, and is ready to execute.
! The result will go straight into the record buffer
! called from GET and GETRANDOM. Also INSERT / UPSERT
! bypasses the result set
DriverFileMSSQL2Class._ToRecord         PROCEDURE(Long pStmt, Long pBuffer, Long pColumns, Byte pExpectReturn)
result            Long,Auto
columns           Short,Auto
x                 Long,Auto
recs              Long

SmallBuff         String(1024)
BigBuff           &String

srl               SReal,Auto
rl                Real,Auto
lg                Long,Auto
sh                Short,Auto
ush               Short,Auto


str               &String,Auto

SQLcolumnName     Cstring(DRIVER:MAXFIELDNAMELEN)
SQLcolumnType     Short
CcolumnType       Short
gdtype            Short
SQLcolumnSize     Ulong
SQLcolumnDecimal  Short
SQLcolumnNullable Short
SQLcolumnNameLen  Short

Slip              Long              ! StrLen_or_IndPtr
SaveSlip          Long              ! StrLen_or_IndPtr
Scale             Long

Buffer            Long
hStmt             Long

dbAddress         Long
dbLength          Long
dbNull            Byte
canNull           Byte
rTextLength       Long     ! do not ,Auto
  code
  !self.trace('DriverFileMSSQL2Class._ToRecord pBuffer=' & pBuffer & ' pExpectReturn=' & pExpectReturn & ' pStmt=' & pStmt)
  Case pBuffer
  of 0
  orof driver:buffer
    Buffer = self.ClaFCB.rec_buf
    cannull = true
  of driver:shadow
    Buffer = address(self.ShadowBuffer)
  of driver:nobuffer
    pExpectReturn = false
  End

  ! getting column information is done after the prepare, but before the SQL is executed.
  columns = pColumns

  ! this is a GET (or Returning values from ADD), so only retrieving 1 row.
  ! so there's no need to bind the columns, SQLGetData is sufficient
  ! since this is only getting 1 row, it's ok to read out each column as we go.
  result = SQLSetStmtAttr(pStmt, SQL_ATTR_QUERY_TIMEOUT, self.opt:BusyTimeout, SQL_IS_INTEGER)
  result = SQLExecute(pStmt)
  case result
  of SQL_SUCCESS
    ! drop through
  of SQL_SUCCESS_WITH_INFO
    ! drop through
  of SQL_NO_DATA
    result = SQLRowCount(pStmt,self.Affected)
    self.SetError(NoRecErr)
    Return
  else
    self.SetErrorMssql(SQL_HANDLE_STMT,pStmt,'[d111]')
    self.Affected = 0
    Return
  End
  result = SQLRowCount(pStmt,self.Affected)
  !self.trace('DriverFileMSSQL2Class._ToRecord pExpectReturn=' & pExpectReturn & ' columns=' & columns & ' self.Affected=' & self.Affected & ' result=' & result)
  If pExpectReturn = false  or columns = 0
    If self._ParameterOpcode = Opcode:ADD and self.SqlCode.instring(' OUTPUT ') > 0
    Else
      ! not expecting anything back, so can return now.
      Return
    End
  end
  ! Handle result set if expected
  !* for the Validation Test it's necessary to do the SQLNumResultCols after the SQLExecute?
  result = SQLNumResultCols(pStmt, columns)
  If result <> SQL_SUCCESS AND result <> SQL_SUCCESS_WITH_INFO
    self.setErrorMssql(SQL_HANDLE_STMT,pStmt,'[d113]')
  End
  Loop
    result = SQLFetch(pStmt)
    recs += 1
    case result
    of SQL_NO_DATA
      if recs = 1 then self.SetError(NoRecErr).
      Break
    of SQL_SUCCESS
    of SQL_SUCCESS_WITH_INFO
    Else
      self.SetErrorMssql(SQL_HANDLE_STMT,pStmt,'[d112]')
      Break
    End
    Loop x = 1 to columns                                  ! loop through the result columns
      result = SQLDescribeCol(pStmt, x, SQLcolumnName, Size(SQLcolumnName), SQLColumnNameLen, SQLcolumnType, SQLcolumnSize, SQLcolumnDecimal, SQLcolumnNullable) ! column number is 1 based.
      CcolumnType = self.SQLtoCtype(SQLcolumnType,SQLcolumnSize)
      case CcolumnType
      of SQL_C_SS_TIME2         ! SQLGetData can't handle SQL_C_SS_TIME2 , but morph still gets  SQL_C_SS_TIME2
        gdtype = SQL_C_BINARY
      of SQL_C_NUMERIC          ! Let ODBC convert the numeric to a string , morph gets SQL_C_CHAR
        gdtype = SQL_C_CHAR
        CcolumnType = SQL_C_CHAR
      else
        gdtype= CcolumnType
      End
      dbAddress = Address(SmallBuff)
      dbLength = Size(SmallBuff)
      result = SQLGetData(pStmt,x,gdtype,dbAddress,dbLength,slip)
      rTextLength = 0
      If slip > Size(SmallBuff)
        ! Otherwise use GetData to get size of data
        ! whole response did not fit into SmallBuff, So create a BigBuff to store the whole thing.
        saveSlip = slip                                     ! slip does not allow for the trailing 0, which will be added to the end
        If slip+1 > size(BigBuff)
          Dispose(BigBuff)
          BigBuff &= New String(slip+1)
        End
        ! now move smallBuff into the start of BigBuff
        case SQLcolumnType
        of SQL_VARCHAR ! small buff contains a trailing 0
          MemCpy(address(BigBuff),Address(SmallBuff),Size(SmallBuff)-1)
          dbAddress = Address(BigBuff) + Size(SmallBuff) - 1
        else
          MemCpy(address(BigBuff),Address(SmallBuff),Size(SmallBuff)-1)
          dbAddress = Address(BigBuff) + Size(SmallBuff)
        End
        dbLength = SaveSlip - Size(SmallBuff) + 2
        result = SQLGetData(pStmt,x,CcolumnType,dbAddress,dbLength,slip)
        dbAddress = Address(BigBuff)
        slip = saveSlip + 1                                 ! get the original length returned, and add 1 for the trailing 0
      End
      If self._WithFieldNamed(SQLcolumnName) = driver:ok        ! see if a FILE field matches this name. This is case insensitive.
        If slip = SQL_NULL_DATA
          self._SetFieldNull()
        ElsIf not self.Fields.Interface &= NULL
          self.Fields.interface.ToRecordField(self.Fields.Type,Buffer + self.Fields.Offset,self.Fields.length,SQLcolumnType,dbAddress,dbLength)
        ElsIf self.Fields.DimProduct > 1                     ! field matching this column is an array. In MSSQL this means a VarChar(Max) field, in JSON form. ! Parse the JSON and move the values into the record buffer
          If dbLength
             str &= dbAddress & ':' & slip
             self._LoadArray(str,self.Fields.index,Buffer,canNull)
          Else
             self._ClearField()
          End
        Else
          self._Morph(self.fields.label,self.Fields.type,Buffer + self.Fields.Offset,self.Fields.Length,CcolumnType,dbAddress,slip,self.fields.SqlTimeStamp,CanNull * true,rTextLength)
        End
      ElsIf self._WithBlobNamed(SQLcolumnName) = driver:ok   ! not a FILE field, so check for MEMO and BLOB
        If slip = SQL_NULL_DATA
          self.SETBLOBPROP:Value(self.blobs.index,'')
        ElsIf self.blobs.Memo
          self._Morph(self.blobs.label,ClaMemo,address(self.blobs.memostring),self.blobs.memosize,CcolumnType,dbAddress,slip,0,false,rTextLength)
        else
          self._Morph(self.blobs.label,ClaBlob,self.blobs.index,self.blobs.handlesize,CcolumnType,dbAddress,slip,0,false,rTextLength)
        End
        self.SetBlobCrc()
        Put(self.blobs)
      ElsIf not self.BindQueue &= null
        self.BindQueue.Name = upper(SQLcolumnName)
        PushErrors()
        Get(self.BindQueue,self.BindQueue.Name)
        If Errorcode() = 0
          If not self.bindqueue.lg &= null
            self._Morph(self.BindQueue.Name,ClaLONG,address(self.bindqueue.lg),4,CcolumnType,dbAddress,slip,0,false,rTextLength)
          ElsIf not self.bindqueue.rl &= null
            self._Morph(self.BindQueue.Name,ClaREAL,address(self.bindqueue.rl),8,CcolumnType,dbAddress,slip,0,false,rTextLength)
          Elsif not self.bindqueue.st &= null
            self._Morph(self.BindQueue.Name,ClaSTRING,address(self.bindqueue.st),size(self.bindqueue.st),CcolumnType,dbAddress,slip,0,false,rTextLength)
          Elsif not self.bindqueue.cst &= null
            self._Morph(self.BindQueue.Name,ClaCSTRING,address(self.bindqueue.cst),size(self.bindqueue.cst),CcolumnType,dbAddress,slip,0,false,rTextLength)
          End
        End
        PopErrors()
      Else
        !!!todo match field by number, for dummy sql context.
        Self.trace('DriverFileMSSQL2Class._ToRecord: Note: Incoming Field not found in structure: ' & SQLcolumnName)
      End
      If errorcode() then break.
    End
    ! done all the columns, so loop to see if there's another record.
  End
  Dispose(BigBuff)
  Return

!-----------------------------------------------------------------
! parameterized SQL call, designed to be a safer prop:sql
! ODBC does not allow for numbered parameters, just ?, so the numbered parameters are replaced with ?
DriverFileMSSQL2Class.SQL            PROCEDURE(String pSql,<? pParm1>,<? pParm2>,<? pParm3>,<? pParm4>,<? pParm5>,<? pParm6>,<? pParm7>,<? pParm8>,<? pParm9>,<? pParm10>,<? pParm11>,<? pParm12>,<? pParm13>,<? pParm14>,<? pParm15>,<? pParm16>,<? pParm17>,<? pParm18>,<? pParm19>,<? pParm20>)
NUMBERPARMS   Equate(20)
str           StringTheory
t             Long ,Auto
  Code
  str.SetValue(clip(pSql))
  loop t = NUMBERPARMS to 1 by -1
    str.Replace('?' & t , '?')
  end
  Parent.Sql(str.GetValue(),pParm1,pParm2,pParm3,pParm4,pParm5,pParm6,pParm7,pParm8,pParm9,pParm10,pParm11,pParm12,pParm13,pParm14,pParm15,pParm16,pParm17,pParm18,pParm19,pParm20)

!-----------------------------------------------------------------
DriverFileMSSQL2Class.SQLtoCtype  Procedure(Short pSQLcolumnType, ULong pSQLcolumnSize)
  code
  !self.trace('SQLtoCtype pSQLcolumnType=' & pSQLcolumnType & ' pSQLcolumnSize=' & pSQLcolumnSize)
  Case pSQLcolumnType
  of SQL_CHAR
  orof SQL_VARCHAR
  orof SQL_LONGVARCHAR
    Return(SQL_C_CHAR)
  of SQL_NUMERIC
  orof SQL_DECIMAL
    Return(SQL_C_NUMERIC)
  of SQL_INTEGER
    Return(SQL_C_LONG)
  of SQL_SMALLINT
    Return(SQL_C_SHORT)
  of SQL_FLOAT
    Case pSQLcolumnSize
    Of 1 to 7
      Return(SQL_C_FLOAT)
    Else
      Return(SQL_C_DOUBLE)
    End
  of SQL_REAL
    Return(SQL_C_FLOAT)
  of SQL_DOUBLE
    Return(SQL_C_DOUBLE)
  of SQL_DATE
    Return(SQL_C_DATE)
  of SQL_TIME
    Return(SQL_C_TIME)
  of SQL_TIMESTAMP
    Return(SQL_C_TIMESTAMP)
  of SQL_BINARY
  orof SQL_VARBINARY
  orof SQL_LONGVARBINARY
    Return(SQL_C_BINARY)
  of SQL_BIGINT
    Return(SQL_C_SBIGINT)
  of SQL_TINYINT
    Return(SQL_C_TINYINT)
  of SQL_BIT
    Return(SQL_C_BIT)
  of SQL_WCHAR
  orof SQL_WVARCHAR
    Return(SQL_C_WCHAR)
  of SQL_SS_TIME2
    Return SQL_C_SS_TIME2
  of SQL_TYPE_TIMESTAMP
    Return SQL_C_TYPE_TIMESTAMP
  of SQL_TYPE_DATE
    Return SQL_C_TYPE_DATE
  of SQL_TYPE_TIME
    Return SQL_C_TYPE_TIME
  of SQL_SS_VARIANT
    Return SQL_C_BINARY
  of SQL_GUID
    Return SQL_C_BINARY
  of SQL_WCHAR
  orof SQL_WVARCHAR
  orof SQL_WLONGVARCHAR
    Return SQL_C_WCHAR
  of SQL_SS_TIMESTAMPOFFSET
    Return SQL_C_BINARY

  End
  self.trace('Unknown SQL type ' & pSQLcolumnType)
  Return SQL_C_BINARY !pSQLcolumnType

!-----------------------------------------------------------------
! this can be called after the ExecuteSQL, but before rows are SQLFetched.
! It gets all the columns, and builds a "SQLRecord" out of the parts. The "description" of this "record"
! is put into self.Bindmap, storing the Offset and Len of each returned column.
! The function returns the final offset - which is therefore the necessary required size of the buffer
! Some fields won't be of a type recognised below. So that offset and len will be 0. These columns are not bound, and SQLGetData will be used.
! The Offset is an Index into the record - the first field starts at index 1.
DriverFileMSSQL2Class._DescribeResult         PROCEDURE(Long pStmt, Long pColumns, iResultSet pResult )
column            Long,Auto
result            Long,Auto
offset            Long !not Auto
nbIndex           Long !not auto
SQLcolumnName     Cstring(DRIVER:MAXFIELDNAMELEN),Auto
CcolumnType       Long
SQLcolumnSize     Ulong
SQLcolumnType     Short
SQLcolumnDecimal  Short
SQLcolumnNullable Short
SQLcolumnNameLen  Short
EndBind           Byte ! not auto
ColNumber         Long,Auto ! counting up fields in the destination record when matching by number, ignoring Group and Over.
  code
  clear(self.BindMap.offset)
  clear(self.BindMap.len)
  ColNumber = 1
  Loop column = 1 to pColumns
    ! If this is the first row in the result set, then inspect the column data, and cache it in the result
    result = SQLDescribeCol(pStmt, column, SQLcolumnName, Size(SQLcolumnName), SQLColumnNameLen, SQLcolumnType, SQLcolumnSize, SQLcolumnDecimal, SQLcolumnNullable) ! column number is 1 based.
    If Result <> SQL_SUCCESS and Result <> SQL_SUCCESS_WITH_INFO
      self.SetErrorMssql(SQL_HANDLE_STMT,pStmt,'[d080]')
      Return 0
    End

    pResult.SetColumnName(column,SQLcolumnName)
    If self.opt:dummy = False and self._MatchByNumber = false
      If self._WithFieldNamed(SQLcolumnName) = Driver:ok
        pResult.SetColumnIndex(column,self.fields.Index)
      End
    Else
      do SetColIndex
    End
    ColNumber += 1
    CcolumnType = self.SQLtoCtype(SQLcolumnType,SQLcolumnSize)
    case CcolumnType
    Of SQL_C_NUMERIC
      Case self.Fields.Type
      of ClaDecimal
      orof ClaPDecimal
        CcolumnType = SQL_C_CHAR                                     ! Let ODBC convert from Numeric to Char.
        SQLcolumnSize = 36
      of ClaREAL                                                     ! let ODBC do the conversion
        CcolumnType = SQL_C_DOUBLE
      of ClaSREAL
        CcolumnType = SQL_C_FLOAT
      of ClaLong
        CcolumnType = SQL_C_LONG
      of ClaShort
        CcolumnType = SQL_C_SHORT
      of ClaByte
        CcolumnType = SQL_C_TINYINT
      of ClaSTRING
      orof ClaCSTRING
      orof ClaPString
        CcolumnType = SQL_C_CHAR
      End
    End

    pResult.SetColumnType(column,CcolumnType)

    If endbind Then cycle.

    self.BindMap.offset[column] = offset
    self.BindMap.cType[column] = CcolumnType
    case CcolumnType
    Of SQL_C_BIT                ; self.BindMap.Len[column] = 1
    Of SQL_C_TINYINT            ; self.BindMap.Len[column] = 1
    Of SQL_C_UTINYINT           ; self.BindMap.Len[column] = 1
    Of SQL_C_SHORT              ; self.BindMap.Len[column] = 2
    Of SQL_C_USHORT             ; self.BindMap.Len[column] = 2
    Of SQL_C_LONG               ; self.BindMap.Len[column] = 4
    Of SQL_C_ULONG              ; self.BindMap.Len[column] = 4
    Of SQL_C_FLOAT              ; self.BindMap.Len[column] = 4
    Of SQL_C_DOUBLE             ; self.BindMap.Len[column] = 8
    Of SQL_C_SBIGINT            ; self.BindMap.Len[column] = 8
    Of SQL_C_UBIGINT            ; self.BindMap.Len[column] = 8
    Of SQL_C_NUMERIC            ! do nothing, handled above
    Of SQL_C_CHAR               ; if SQLcolumnSize > 0 then self.BindMap.Len[column] = SQLcolumnSize + 1.
    Of SQL_C_WCHAR              ; if SQLcolumnSize > 0 then  self.BindMap.Len[column] = (SQLcolumnSize + 1) * 2.
    Of SQL_C_BINARY             ; if SQLcolumnSize > 0 and SQLcolumnSize < 8193 then self.BindMap.Len[column] = SQLcolumnSize.

    Of SQL_C_DATE               ; self.BindMap.Len[column] = 6
    Of SQL_C_TIME               ; self.BindMap.Len[column] = 6
    Of SQL_C_TIMESTAMP          ; self.BindMap.Len[column] = 16
    Of SQL_C_TYPE_TIMESTAMP     ; self.BindMap.Len[column] = 16
    Of SQL_C_TYPE_DATE          ; self.BindMap.Len[column] = 6
    Of SQL_C_TYPE_TIME          ; self.BindMap.Len[column] = 6
    Of SQL_C_SS_TIME2           ; self.BindMap.cType[column] = SQL_C_BINARY ; self.BindMap.Len[column] = 12
    Of SQL_C_SS_TIMESTAMPOFFSET ; self.BindMap.Len[column] = size(TimeStampTZGroupType)
    End
    offset += self.BindMap.Len[column]
    If self.BindMap.Len[column] = 0
      endbind = true  ! MSSQL is wackadoodle. Cannot BIND columns after an unbound column
    End
  End
  Return offset

SetColIndex  Routine
  Loop
    If Self._WithField(ColNumber) = driver:ok
      If self.Fields.Type = ClaGROUP or self.Fields.Over
        ColNumber += 1
        Cycle
      End
      pResult.SetColumnIndex(column,ColNumber)
    Else
      pResult.SetColumnIndex(column,0)  ! no field for this value to go into
    End
    Break
  End

!-----------------------------------------------------------------
DriverFileMSSQL2Class._BindResult         PROCEDURE(Long pStmt, Long pColumns, Long pBufferAddress )
column  Long,Auto
result  Long,Auto
Ard     Long,Auto
Slip    Long
  code
  Loop column = 1 to pColumns
    If self.BindMap.Len[column] = 0 then cycle.
    result = SQLBindCol(pStmt, column, self.BindMap.cType[column],  pBufferAddress + self.BindMap.offset[column],  self.BindMap.Len[column],  self.BindMap.Slip[column])
    case result
    of SQL_ERROR
      self.BindMap.Len[column] = 0  ! mark this field as not bound
    End
  End
  Return

!-----------------------------------------------------------------
! data has been read, and the whole result row is now moving from the SQL engine into the pResult.
! It is stored as the native result, as from the database. SQL Type is stored in pType
! called from DriverClass and DriverViewClass, so avoid referencing the "self" object here.
DriverFileMSSQL2Class._ToResult         PROCEDURE(Long pStmt, Long pColumns, Long pBufferAddress, iResultSet pResult)
SmallBuff         String(4096),Auto

column            long,Auto
row               long,Auto

SQLcolumnName     Cstring(DRIVER:MAXFIELDNAMELEN),Auto
SQLcolumnType     Short
CcolumnType       Long
SQLcolumnSize     Ulong
SQLcolumnDecimal  Short
SQLcolumnNullable Short
SQLcolumnNameLen  Short

BigBuff           &String
Slip              long  ! not auto
dbAddress         Long,Auto
dbLength          Long,Auto
result            Long
cType             Short,Auto
gdType            Short,Auto
lg                long  !?

Addr              BIGINT,Auto
Len               BIGINT,Auto

  code
  row = pResult.IncrementRowNumber()
  Loop column = 1 to pColumns
    If self.BindMap.Len[column] > 0
      ! column is bound, so just move it from Bind Buffer into result
      If self.BindMap.Slip[column] = SQL_NULL_DATA
        Addr = 0
        Len = 0
        pResult.SetCell(row,column,SQL_NULLTYPE,Addr,Len)
        Cycle
      End
      Case self.BindMap.cType[column]
      Of SQL_C_CHAR
      OrOf SQL_C_WCHAR
      OrOf SQL_C_BINARY
        Len = self.BindMap.Slip[column]
        cType = pResult.GetColumnType(column)
      Else
        Len = self.BindMap.Len[column]
        cType = self.BindMap.cType[column]
      End
      addr = pBufferAddress+self.BindMap.Offset[column]
      pResult.SetCell(row,column,cType,addr,Len)

    Else
      ! column is not bound, so use GetData
      dbAddress = Address(SmallBuff)
      dbLength = Size(SmallBuff)
      cType = pResult.GetColumnType(column)
      Case cType
      Of SQL_C_SS_TIME2         ! SQLGetData can't handle SQL_C_SS_TIME2, but Ctype remains as SQL_C_SS_TIME2
        gdtype = SQL_C_BINARY
      Of SQL_C_NUMERIC          ! Let ODBC convert the numeric to a string and ctype changes to SQL_C_CHAR
        gdtype = SQL_C_CHAR
        cType = SQL_C_CHAR
      Else
        gdtype= cType
      End

      result = SQLGetData(pStmt,column,gdType,dbAddress,dbLength,slip)
      If Result <> SQL_SUCCESS and Result <> SQL_SUCCESS_WITH_INFO
        self.SetErrorMssql(SQL_HANDLE_STMT,pStmt,'[d081] ' & result)
        Return
      End

      ! Turns out it was a null
      If slip = SQL_NULL_DATA
        Addr = 0
        Len = 0
        pResult.SetCell(row,column,SQL_NULLTYPE,Addr,Len)
        Cycle
      End

      ! It did fit into SmallBuff
      If slip <= Size(SmallBuff)
        Case cType
        of SQL_C_WCHAR
          do ToAnsiS
        end
        Addr = Address(SmallBuff)
        Len = slip
        pResult.SetCell(row,column,cType,Addr,Len)
        Cycle
      End

      ! It did not fit into small buff, so it needs to go to BigBuff

      BigBuff &= New String(slip)
      dbAddress = Address(BigBuff)
      dbLength = Size(BigBuff)

      case SQLcolumnType
      of SQL_VARCHAR ! small buff contains a trailing 0
        MemCpy(address(BigBuff),Address(SmallBuff),Size(SmallBuff)-1)
        dbAddress = Address(BigBuff) + Size(SmallBuff) - 1
      else
        MemCpy(address(BigBuff),Address(SmallBuff),Size(SmallBuff)-1)
        dbAddress = Address(BigBuff) + Size(SmallBuff)
      End
      dbLength = Size(BigBuff) - Size(SmallBuff)

      result = SQLGetData(pStmt,column,cType,dbAddress,dbLength,slip)
      Addr = Address(BigBuff)
      Len = Size(BigBuff)
      case SQLcolumnType
      of SQL_VARCHAR ! small buff contains a trailing 0
        len -= 1
      End

      pResult.SetCellAddr(row,column,cType,Addr,Len)
      ! BigBuff is not disposed here - the memory is now "owned" by the pResult
    End
  End
  Return

ToAnsiS  routine
  self.TempStr.SetValue(sub(SmallBuff,1,slip))
  self.TempStr.ToAnsi(st:EncodeUtf16)
  smallbuff = self.TempStr.GetValue()
  slip = self.TempStr.Length()
  cType = SQL_C_CHAR

!-----------------------------------------------------------------
! TOP is only generate if Offset is blank and Limit > 0
DriverFileMSSQL2Class.TranslateLimitAbove              PROCEDURE(Long pLimit, String pOffset)
  Code
  If pOffset then return ''.
  If pLimit <= 0 then return ''.
  Return ' TOP ' & pLimit

!-----------------------------------------------------------------
! Clause only generated if OFFSET is set to something.
DriverFileMSSQL2Class.TranslateLimitBelow              PROCEDURE(Long pLimit, String pOffset)
  Code
  If pOffset = '' then return ''.
  If pLimit = 0 then clear(pLimit,1).
  Return ' OFFSET ' & pOffset & ' ROWS FETCH NEXT ' & pLimit & ' ROWS ONLY'

!-----------------------------------------------------------------
! Note: Not all SQL engines support INSTR, some use POSITION, CHARINDEX, LOCATE etc
DriverFileMSSQL2Class.TranslateInStr       Procedure(*Cstring pFunc, *CString pParms,String pTokenString,*Long pTokenPos,*Cstring[] pExParm,Long pNumParms)
  code
  return 'CHARINDEX(' & self._ExpandExpression(pExParm[1]) & ',' & self._ExpandExpression(pExParm[2]) & ')'


!============================================================================================================
!-----------------------------------------------------------------
! Transaction Processing
!-----------------------------------------------------------------
DriverFileMSSQL2Class.LOGOUTCONNECTION         PROCEDURE()
result  long,auto
  Code
  parent.LogoutConnection()
  If self.dbHandle and Errorcode() = NoError
    result = SQLSetConnectAttr(self.dbHandle, SQL_ATTR_AUTOCOMMIT, SQL_AUTOCOMMIT_OFF, 0);
  End
  Return

DriverFileMSSQL2Class.COMMITCONNECTION         PROCEDURE()
result  long,auto
  Code
  parent.CommitConnection()
  If self.dbHandle
    result = SQLSetConnectAttr(self.dbHandle, SQL_ATTR_AUTOCOMMIT, SQL_AUTOCOMMIT_ON, 0);
  End
  Return

DriverFileMSSQL2Class.ROLLBACKCONNECTION         PROCEDURE()
result  long,auto
  Code
  parent.RollBackConnection()
  If self.dbHandle
    result = SQLSetConnectAttr(self.dbHandle, SQL_ATTR_AUTOCOMMIT, SQL_AUTOCOMMIT_ON, 0);
  End
  Return


!============================================================================================================

!-----------------------------------------------------------------
! this driver supports the "custom" field types; UUID4 and UUID7 "out of the box".
! In MSSQL UUID4 can be stored as a UNIQUEIDENTIFIER data type.
DriverFileMSSQL2Class._parseFields      PROCEDURE(Long pAddr)
x  long,Auto
  code
  parent._ParseFields(pAddr)
  Loop x = 1 to self.SharedProperties.FieldList.nodes
    self.Fields &= self._WithFieldNode(x)
    If self.Fields.SQLType = 'STRING' or self.Fields.SQLType = 'TEXT' or upper(Sub(self.Fields.SQLType,1,4)) = 'CHAR'  or upper(Sub(self.Fields.SQLType,1,7)) = 'VARCHAR' then cycle.
    If self.Fields.UUID = 4 or self.Fields.UUID = 7 or Upper(self.fields.SQLType) = 'UNIQUEIDENTIFIER' or Upper(self.fields.SQLType) = 'UUID'
      Case self.Fields.Type
      of ClaSTRING
      orof ClaCSTRING
        self.Fields.Interface &= (Address(DriverUniqueIdentifierMSObject))
        self.Fields.SourceSize = self.Fields.Interface.GetSourceSize()
      End
    End
  End
  Return

!-----------------------------------------------------------------
DriverFileMSSQL2Class._GetCollation      Procedure(Long pIndex)
poc         long
collation   cstring(100)
  code
  If self.CheckConnect() = driver:notok then Return ''.
  If pIndex = 0
    self.Sqlcode.SetValue('SELECT CAST(DATABASEPROPERTYEX(DB_NAME(), ''Collation'') AS VARCHAR(100)) AS c;')
  ElsIf  pIndex > 0
    If self._WithField(pIndex) = Driver:NotOk
      Return ''
    End
    self.SqlCode.SetValue('SELECT c.collation_name FROM sys.columns c JOIN sys.tables t ON c.object_id = t.object_id ' & |
                          'WHERE t.name = ''' & self.FullPathName & ''' AND c.name = ''' & self.fields.Column & ''';')
  ElsIf  pIndex < 0
    If self._WithBlob(pIndex) = Driver:NotOk
      Return ''
    End
    self.SqlCode.SetValue('SELECT c.collation_name FROM sys.columns c JOIN sys.tables t ON c.object_id = t.object_id ' & |
                          'WHERE t.name = ''' & self.FullPathName & ''' AND c.name = ''' & self.blobs.Column & ''';')
  End
  Self.SetError(NoError)
  poc = self._ParameterOpcode
  self._ParameterOpcode = Opcode:NONE
  If self._ExecuteSqlNoParms(self.result) = driver:ok
    If self.result.Rows()
      collation = self.result.GetCell(1,1)
    End
  End
  self._ParameterOpcode = poc
  Return collation

!-----------------------------------------------------------------
! timestamps are stored as DateTTime
! Fields node must already be loaded
! given text, returns binary data of the correct size
DriverFileMSSQL2Class.DeformatText Procedure(String pText,Long pGroupPattern)
strmem   string(16),Auto
dt       Date,Auto
dts      String(4),over(dt)
tm       Time ,Auto
sdt      string(4),over(dt)
stm      string(4),over(tm)
i        long,Auto
j        long,Auto
k        long,Auto
tl       long,Auto

gr       Group,Auto
dt1        Date
tm1        Time
         End

gr2       Group,Auto
dt2        Date
tm2        Time
off2       Long
         End

  code
  If self.Deformat &= null
    self.Deformat &= new StringDeformat
  End
  If self.fields.SqlTimeStamp = driver:GroupOverTimeStamp
    j = len(self.DateTimeSeparator)
    i = instring(self.DateTimeSeparator,pText,1,1)
    if i = 0 then i = instring(' T ',pText,1,1) ; j = 3.
    if i = 0 then i = instring(' ',pText,1,1) ; j = 1.
    if i = 0 then i = instring('T',pText,1,1) ; j = 1.
    if i
      gr.dt1 = self.Deformat.DeformatDateDate(sub(pText,1,i-1),'@d010-')              !!!todo, check deformat for dates < 1801
      gr.tm1 = self.Deformat.DeformatTime(sub(pText,i+j,len(pText)),'@t093')
    end
    Return gr
  End
  If self.fields.SqlTimeStamp = driver:GroupOverTimeStampTZ
    j = len(self.DateTimeSeparator)

    i = instring(self.DateTimeSeparator,pText,1,1)
    if i = 0 then i = instring(' T ',pText,1,1) ; j = 3.
    if i = 0 then i = instring(' ',pText,1,1) ; j = 1.
    if i = 0 then i = instring('T',pText,1,1) ; j = 1.

    k = instring(' +',pText,1,i)
    if k = 0 then i = instring(' -',pText,1,i).
    if k
      tl = k - i - j
    else
      tl = len(pText) - i - j
    end

    if i
      gr2.dt2 = self.Deformat.DeformatDateDate(sub(pText,1,i-1),'@d010-')              !!!todo, check deformat for dates < 1801
      gr2.tm2 = self.Deformat.DeformatTime(sub(pText,i+j,tl),'@t093')

      if k
        gr2.off2 = self.Deformat.DeformatTime(sub(pText,k+2,5),'@t093')
        If pText[k+1] = '-'
          gr2.off2 = -gr2.off2
        End
      else
        gr2.off2 = 0
      end
    end
    Return gr2
  End

  Case self.Fields.Type
  of ClaDATE
      dts = self.Deformat.DeformatDateDate(pText,'@d010-')
      Return sdt
  of ClaTIME
      tm = self.Deformat.DeformatTime(pText,'@t093')
      Return stm
  of ClaDECIMAL
  orof ClaPDECIMAL
     self._StringToDec(pText,self.Fields.Type, address(strmem), self.Fields.DecimalSize, self.Fields.DecimalPlaces)
     Return strmem
  end
  Return pText

!-----------------------------------------------------------------
DriverFileMSSQL2Class.SetDriverOption            Procedure(String pOption, String pValue)
ans     cstring(255)
result  long,auto
mode    string(20)
  Code
  Case upper(pOption)
  of '/AUTOINC'
    If pValue <> ''
      do checkBoolean
      self.opt:AutoInc = pValue
    End
    Return self.opt:AutoInc
  of '/BUSYRETRIES'
    If pValue <> ''
      self.opt:BusyRetries = pValue
      If self.dbHandle
        self._SetBusyRetries(self.opt:BusyRetries)
      End
    End
    If self._logOptions then self.Log('[OPTN]' & clip(pOption) & '=[' & clip(pValue & ']')).
    Return self.opt:BusyRetries
  of '/BUSYTIMEOUT'
    If pValue <> ''
      self.opt:BusyTimeout = pValue
      If self.dbHandle
        self._SetBusyTimeOut(self.opt:BusyTimeout)
      End
    End
    If self._logOptions then self.Log('[OPTN]' & clip(pOption) & '=[' & clip(pValue & ']')).
    Return self.opt:BusyTimeout
  of '/TRUSTEDCONNECTION'
    If pValue <> ''
      do checkBoolean
      self.opt:TrustedConnection = pValue
    End
    If self._logOptions then self.Log('[OPTN]' & clip(pOption) & '=[' & clip(pValue & ']')).
    Return self.opt:TrustedConnection
  of '/USEPRIMARY'               ! There is no documentation on what this does.
    If pValue <> ''
      do checkBoolean
      self.opt:UsePrimary = pValue
    End
    If self._logOptions then self.Log('[OPTN]' & clip(pOption) & '=[' & clip(pValue & ']')).
    Return self.opt:UsePrimary
  of '/WHERE'
    self.SetProp:Where(pValue)
    If self._logOptions then self.Log('[OPTN]' & clip(pOption) & '=[' & clip(pValue & ']')).
    Return self.GetProp:Where()
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
DriverFileMSSQL2Class._ExecuteSqlNoParms    Procedure(iResultSet pResult)
result        Long,auto
stmt          Long,Auto
cstr          &Cstring
  code
  !self.trace('DriverFileMSSQL2Class._ExecuteSqlNoParmsToResults')
  If self.CheckConnect() = driver:notok then Return driver:notok.
  If self._logSQL then self.Log('[SQL ]' & self.SqlCode.GetValue()).

  pResult.NewResultSet(driver:DontFreeRam)
  self.ResultRow = 0
  self._ResultRow = 0
  self.Affected = 0

  ! Allocate a statement handle
  result = SQLAllocHandle(SQL_HANDLE_STMT, self.dbHandle, stmt)
  IF result <> SQL_SUCCESS AND result <> SQL_SUCCESS_WITH_INFO
    self.SetErrorMssql(SQL_HANDLE_DBC,self.dbHandle,'[d031]')
    Return driver:notok
  End

  cstr &= self.SqlCode.ToCstring()
  result = SQLSetConnectAttr(self.dbhandle, SQL_ATTR_QUERY_TIMEOUT, self.opt:BusyTimeout, SQL_IS_INTEGER)
  result = SQLExecDirect(stmt, cstr, SQL_NTS)    ! get a page of rows
  Dispose(cstr)
  case result
  of SQL_SUCCESS
  of SQL_SUCCESS_WITH_INFO
  of SQL_NO_DATA
  Else
    self.SetErrorMssql(SQL_HANDLE_STMT,Stmt,'[d089]')
    Return driver:notok
  End
  self._ToResults(Stmt,pResult)
  result = SQLFreeHandle(SQL_HANDLE_STMT, stmt);
  Return driver:ok

!-----------------------------------------------------------------
! prepares and executes the SQL in SqlCode.
DriverFileMSSQL2Class._executeSql procedure()
stmt    Long ,Auto
  code
  If self.CheckConnect() = driver:notok then Return driver:notok.
  stmt = self._Prepare()
  If stmt
    Return self._ExecuteSqlWork(stmt)
  End
  Return driver:ok

!-----------------------------------------------------------------
DriverFileMSSQL2Class._executeSql procedure(Long pStmt)
  Code
  If self.CheckConnect() = driver:notok then Return driver:notok.
  Return self._ExecuteSqlWork(pStmt)

!-----------------------------------------------------------------
!  binds parameters and executes the SQL in SqlCode.
! SQL is not cached.
! results are set to Results
! returns driver:notok if the SQL part is faulty
DriverFileMSSQL2Class._ExecuteSqlWork procedure(Long pStmt)
result  Long,Auto
  code
  If pStmt
    If self.ParmBufferX &= Null then self.ParmBufferX &= NEW DriverParmBufferClass.
    If self._BindParameters(pStmt,self.ParmBufferX,self.CodePage) = Driver:ok
      If self._ExecuteSqlToResults(pStmt,self.result)
      End
    End
    self._FreeStmt(pStmt)
    If self._ParameterOpcode then self._ClearParameterQueue(self._ParameterOpcode).
    If Errorcode()
      Return driver:notok
    End
  Else
    Return driver:notok
  End
  Return driver:ok

!-----------------------------------------------------------------
! does a parameterized request, with up to 15 parameters
! returns driver:notok if the SQL part is faulty
DriverFileMSSQL2Class._ExecuteSql     Procedure(StringTheory pSQL, <? pParm1>,<? pParm2>,<? pParm3>,<? pParm4>,<? pParm5>,<? pParm6>,<? pParm7>,<? pParm8>,<? pParm9>,<? pParm10>,<? pParm11>,<? pParm12>,<? pParm13>,<? pParm14>,<? pParm15>,<? pParm16>,<? pParm17>,<? pParm18>,<? pParm19>,<? pParm20>)
stmt    long,Auto
count   long ! do not auto
x       long,Auto
  code
  self.SqlCode.SetValue(pSql)
  If omitted(pParm1)
    Return self._ExecuteSqlNoParms(self.Result)
  End

  If self.CheckConnect() = driver:notok then Return driver:notok.
  stmt = self._Prepare()
  If stmt
    self._ResultRow = 0
    If not omitted(pParm1)
      If self.ParmBufferX &= Null then self.ParmBufferX &= NEW DriverParmBufferClass.
    End
    Loop x = 3 to 23
      If omitted(x) then break.
      do BindParm
    End
    If self._ExecuteSqlToResults(stmt,self.result)
    End
    self._FreeStmt(Stmt)
    If self._ParameterOpcode then self._ClearParameterQueue(self._ParameterOpcode).
    If Errorcode()
      Return driver:notok
    End
  else
    self.trace('Prepare failed on : ' & self.SqlCode.GetValue())
    Return driver:notok
  End
  Return Driver:ok

BindParm  routine
  count += 1
  execute count
    self._BindParameter(stmt,count,pParm1,self.ParmBufferX,self.CodePage)
    self._BindParameter(stmt,count,pParm2,self.ParmBufferX,self.CodePage)
    self._BindParameter(stmt,count,pParm3,self.ParmBufferX,self.CodePage)
    self._BindParameter(stmt,count,pParm4,self.ParmBufferX,self.CodePage)
    self._BindParameter(stmt,count,pParm5,self.ParmBufferX,self.CodePage)
    self._BindParameter(stmt,count,pParm6,self.ParmBufferX,self.CodePage)
    self._BindParameter(stmt,count,pParm7,self.ParmBufferX,self.CodePage)
    self._BindParameter(stmt,count,pParm8,self.ParmBufferX,self.CodePage)
    self._BindParameter(stmt,count,pParm9,self.ParmBufferX,self.CodePage)
    self._BindParameter(stmt,count,pParm10,self.ParmBufferX,self.CodePage)
    self._BindParameter(stmt,count,pParm11,self.ParmBufferX,self.CodePage)
    self._BindParameter(stmt,count,pParm12,self.ParmBufferX,self.CodePage)
    self._BindParameter(stmt,count,pParm13,self.ParmBufferX,self.CodePage)
    self._BindParameter(stmt,count,pParm14,self.ParmBufferX,self.CodePage)
    self._BindParameter(stmt,count,pParm15,self.ParmBufferX,self.CodePage)
    self._BindParameter(stmt,count,pParm16,self.ParmBufferX,self.CodePage)
    self._BindParameter(stmt,count,pParm17,self.ParmBufferX,self.CodePage)
    self._BindParameter(stmt,count,pParm18,self.ParmBufferX,self.CodePage)
    self._BindParameter(stmt,count,pParm19,self.ParmBufferX,self.CodePage)
    self._BindParameter(stmt,count,pParm20,self.ParmBufferX,self.CodePage)
  end

!-----------------------------------------------------------------
DriverFileMSSQL2Class._ClearStmts  Procedure()
result  long
x       long
  code
  If self.dbHandle and self.Stmt_Add
    self._FreeStmt(self.Stmt_Add)
  End
  self.Stmt_Add = 0
  Dispose(self._AddSqlCache)

  If self.dbHandle and self.Stmt_Append
    self._FreeStmt(self.Stmt_Append)
  End
  self.Stmt_Append = 0
  Dispose(self._AppendSqlCache)

  If self.dbHandle and self.Stmt_Put
    self._FreeStmt(self.Stmt_Put)
  End
  self.Stmt_Put = 0
  Dispose(self._PutSqlCache)

  If self.dbHandle and self.Stmt_Delete
    self._FreeStmt(self.Stmt_Delete)
  End
  self.Stmt_Delete = 0
  Dispose(self._DeleteSqlCache)

  If self.dbHandle and self.Stmt_Upsert
    self._FreeStmt(self.Stmt_Upsert)
  End
  self.Stmt_Upsert = 0
  Dispose(self._UpsertSqlCache)

  If self.dbHandle and self.Stmt_Set
    self._FreeStmt(self.Stmt_Set)
  End
  self.Stmt_Set = 0

  If self.dbHandle and self.Stmt_Get
    self._FreeStmt(self.Stmt_Get)
  End
  self.Stmt_Get = 0
  Dispose(self._GetSqlCache)
  self._ClearParameterQueue(0)
  Return

!-----------------------------------------------------------------
DriverFileMSSQL2Class._GenParm                PROCEDURE(Long pCount)
  code
  Return '?'

!-----------------------------------------------------------------
! can take Opcode:Add, Opcode:Append, Opcode:Upsert as the parameter.
! although mostly common SQL syntax, code for Upsert, and returning values is engine specific
DriverFileMSSQL2Class._AddSQL  Procedure(Long pOpcode)
x              Long,Auto
Returning      StringTheory
FieldsList     StringTheory
ValuesList     StringTheory

  code
  If pOpcode = OpCode:Upsert
    return self._UpsertSQL()
  End
  self._fromcache = false
  self._ClearParameterQueue(pOpcode)
  self.ParseProject()
  Loop x = 1 to self.SharedProperties.FieldList.nodes
    self.Fields &= self._WithFieldNode(x)
    if self.Fields.Over or self.Fields.InOverGroup or self.Fields.Type = ClaGROUP then Cycle.
    If self.Fields.ReadOnly or self.Fields.IsIdentity
      returning.Append('inserted.' & self.Fields.Column,st:noclip,',')
      Cycle
    End
    If self._ProjectField[x] = false
      If self.Fields.HasDefault
        returning.Append('inserted.' & self.Fields.Column,st:noclip,',')
      End
      Cycle                                ! importantly, 255, not 1, if included.
    End
    FieldsList.Append(self.Fields.Column,st:NoClip,',')
    self._ParameterCount += 1
    ! in almost all cases the field in the record buffer can simply be bound.
    ! However in some cases the Clarion type has to be translated into the SQL type.
    self._SetParameterField(self._ParameterCount,self.fields,driver:FromBuffer,0)
    !self._SetParameterNode(self._ParameterCount,self.fields,driver:FromBuffer,0)
    ValuesList.Append(self._genparm(self._ParameterCount),st:NoClip,',')
  End
  If self._NoMemo = false
    Loop x = 1 to Records(self.blobs)
      Get(self.blobs,x)
      If self.blobs.ReadOnly then cycle.
      If self._ProjectBlobField[x] = false then cycle.          ! importantly, 255, not 1, if included.
      FieldsList.Append(self.blobs.Column,st:NoClip,',')
      self._ParameterCount += 1
      self._SetParameterBlob(self._ParameterCount,self.blobs.index)
      ValuesList.Append(self._genparm(self._ParameterCount),st:NoClip,',')
    End
  End
  self.SqlCode.SetValue('INSERT INTO ' & self._sanitize(self.FullPathName,driver:sqlTable) & ' (' & FieldsList.GetValue() & ')')
  self.ExpectOutput = false
  If returning.Length() and self._FastWrite = false
    self.SqlCode.Append(' OUTPUT ' & returning.GetValue())
    self.ExpectOutput = true
  End
  Self.SqlCode.Append(' VALUES (' & ValuesList.GetValue() & ') ')
  self.SqlCode.Append(';')
  Return driver:ok

!-----------------------------------------------------------------
DriverFileMSSQL2Class._ClaimSql     Procedure(? pFIELD, ? pNewValue)
  code
  self.Sqlcode.SetValue('SELECT TOP 1 ' & self.projectlist.GetValue() & |
  ' FROM ' & self._sanitize(self.FullPathName,driver:sqlTable) & |
  ' WITH (UPDLOCK , ROWLOCK, READPAST)' & |
  ' WHERE ' & self.GetProp:Where()  & |
  ' ORDER BY ' & self.GetProp:Order() &';')
  Return driver:ok

!-----------------------------------------------------------------
DriverFileMSSQL2Class._LogoutSql                  Procedure()
  code
  self.SqlCode.SetValue('BEGIN TRANSACTION;')
  Return

!-----------------------------------------------------------------
DriverFileMSSQL2Class._RollbackSavePointSql  Procedure(String pSavePoint)
  code
  self.SqlCode.SetValue('ROLLBACK TRANSACTION ' & self._sanitize(pSavePoint,driver:SqlSavePoint) & ';')
  Return

!-----------------------------------------------------------------
DriverFileMSSQL2Class._SavePointSql    Procedure(String pSavePoint)
  code
  self.SqlCode.SetValue('SAVE TRANSACTION ' & self._sanitize(pSavePoint,driver:sqlSavePoint) & ';')
  Return

!-----------------------------------------------------------------
DriverFileMSSQL2Class._UpsertSQL  Procedure()
x              Long,Auto
returning      StringTheory
FieldsList     StringTheory
ValuesList     StringTheory
onList         StringTheory
updateList     StringTheory
insertList     StringTheory

  code
  self._fromcache = false
  self._ClearParameterQueue(OpCode:Upsert)
  self.ParseProject()

  Loop x = 1 to self.SharedProperties.FieldList.nodes
    self.Fields &= self._WithFieldNode(x)
    if self.Fields.Over or self.Fields.InOverGroup or self.Fields.Type = ClaGROUP then Cycle.
    If self.Fields.ReadOnly or self.Fields.IsIdentity
      returning.Append('inserted.' & self.Fields.Column,st:noclip,',')
      Cycle
    End
    If self._ProjectField[x] = false
      If self.Fields.HasDefault
        returning.Append('inserted.' & self.Fields.Column,st:noclip,',')
      End
     Cycle
    End
    If self.fields.Primary
      onList.Append('target.' & self.fields.Column & '=' & 'source.' & self.fields.Column,,' AND ')
    else
      updateList.Append('target.' & self.fields.Column & '=' & 'source.' & self.fields.Column,,',')
    End
    insertList.Append(self.fields.Column,,',')
    valuesList.Append('source.' & self.fields.Column,,',')
    FieldsList.Append('? AS ' & self.fields.Column,,',')
    self._ParameterCount += 1
    self._SetParameterNode(self._ParameterCount,self.fields,driver:FromBuffer,0)
  End
  If self._NoMemo = false
    Loop x = 1 to Records(self.blobs)
      Get(self.blobs,x)
      If self.blobs.ReadOnly then cycle.
      If self._ProjectBlobField[x] = false then cycle.          ! importantly, 255, not 1, if included.
      updateList.Append('target.' & self.blobs.Column & '=' & 'source.' & self.blobs.Column,,',')
      insertList.Append(self.blobs.Column,,',')
      valuesList.Append('source.' & self.blobs.Column,,',')
      FieldsList.Append('? AS ' & self.blobs.Column,,',')
      self._ParameterCount += 1
      self._SetParameterBlob(self._ParameterCount,self.blobs.index)
    End
  End
  self.SqlCode.SetValue('MERGE INTO ' & self._sanitize(self.FullPathName,driver:sqlTable) & ' AS target USING (SELECT ' & FieldsList.GetValue() & ') AS SOURCE')
  self.SqlCode.Append(' ON ' & onList.getvalue())
  self.SqlCode.Append(' WHEN MATCHED THEN UPDATE SET ' & updateList.GetValue())
  self.SqlCode.Append(' WHEN NOT MATCHED THEN INSERT (' & insertList.GetValue() &') VALUES (' & ValuesList.GetValue() & ')' )

  If returning.Length() and self._FastWrite = false
    self.SqlCode.Append(' OUTPUT ' & returning.GetValue())
    self.ExpectOutput = true
  End

  self.SqlCode.Append(';')
  return driver:ok

!-----------------------------------------------------------------
! can take Opcode:Add, Opcode:Append, Opcode:Upsert as the parameter.
DriverFileMSSQL2Class._PrepareAdd  Procedure(Long pOpcode)
x              Long,auto
result         Long,auto
  Code
  self._fromcache = true
  If pOpcode = Opcode:ADD and self.Stmt_Add and self._AddCache = self._PropsCache and self._AddMemoCache = self._nomemo
    self.SqlCode.SetValue(self._AddSqlCache)
    self.ExpectOutput = self._ExpectOutputAdd
    Return
  End
  If pOpcode = Opcode:APPEND and self.Stmt_Append and self._AppendCache = self._PropsCache and self._AppendMemoCache = self._nomemo
    self.SqlCode.SetValue(self._AppendSqlCache)
    self.ExpectOutput = false
    Return
  End
  If pOpcode = Opcode:UPSERT and self.Stmt_Upsert and self._UpsertCache = self._PropsCache and self._UpsertMemoCache = self._nomemo
    self.SqlCode.SetValue(self._UpsertSqlCache)
    self.ExpectOutput = self._ExpectOutputUpsert
    Return
  End

  If self._AddSql(pOpcode) = driver:notok
    Return
  End

  ! --------------------------
  Case pOpcode
  of Opcode:ADD
    If self.Stmt_Add = 0 or self._AddSqlCache &= null or self._AddSqlCache.Equals(self.SqlCode,ST:SimpleCompare) = false
      If self.Stmt_Add
        self._FreeStmt(self.Stmt_Add)
      End
      self.Stmt_Add = self._prepare()
      If self.Stmt_Add
        If self._AddSqlCache &= null
          self._AddSqlCache &= new StringTheory
        End
        self._AddSqlCache.SetValue(self.SqlCode)
        self._ExpectOutputAdd = self.ExpectOutput
        self._AddColsCache = self._StmtCols
      End
    End
    self._AddCache = self._PropsCache
    self._AddMemoCache = self._nomemo

  of Opcode:APPEND
    If self.Stmt_Append = 0 or self._AppendSqlCache &= null or self._AppendSqlCache.Equals(self.SqlCode,ST:SimpleCompare) = false
      If self.Stmt_Append
        self._FreeStmt(self.Stmt_Append)
      End
      self.Stmt_Append = self._prepare()
      If self.Stmt_Append
        If self._AppendSqlCache &= null
          self._AppendSqlCache &= new StringTheory
        End
        self._AppendSqlCache.SetValue(self.SqlCode)
        self._AppendColsCache = self._StmtCols
      End
    End
    self._AppendCache = self._PropsCache
    self._AppendMemoCache = self._nomemo

  of OpCode:Upsert
    If self._UpsertSqlCache &= null or self._UpsertSqlCache.Equals(self.SqlCode,ST:SimpleCompare) = false or self.Stmt_Upsert = 0
      If self.Stmt_Upsert
        self._FreeStmt(self.Stmt_Upsert)
      End
      self.Stmt_Upsert = self._prepare()
      If self.Stmt_Upsert
        If self._UpsertSqlCache &= null
          self._UpsertSqlCache &= new StringTheory
        End
        self._UpsertSqlCache.SetValue(self.SqlCode)
        self._ExpectOutputUpsert = self.ExpectOutput
        self._UpsertColsCache = self._StmtCols
      End
    End
    self._UpsertCache = self._PropsCache
    self._UpsertMemoCache = self._nomemo
  End
  Return

!-----------------------------------------------------------------
DriverFileMSSQL2Class._PrepareDelete  Procedure()
  Code
  If self.Stmt_Delete and self._DeleteCache = self._PropsCache
    self.SqlCode.SetValue(self._DeleteSqlCache)
    Return Driver:ok
  End
  If self._DeleteSql() = driver:ok
    self.Stmt_Delete = self._prepare()
    self._DeleteCache = self._PropsCache
    If self._DeleteSqlCache &= null
      self._DeleteSqlCache &= new StringTheory
    End
    self._DeleteSqlCache.SetValue(self.SqlCode)
    self._DeleteColsCache = self._StmtCols
    Return Driver:ok
  End
  Return Driver:Notok

!-----------------------------------------------------------------
DriverFileMSSQL2Class._PrepareDelete  Procedure(String pFilter)
stmt  Long
  Code
  If self._DeleteSql(pFilter) = driver:ok
    stmt = self._prepare()
    Return stmt
  End
  Return 0

!-----------------------------------------------------------------
DriverFileMSSQL2Class._PrepareGet  Procedure(KEY pKey)
count       Long
x           Long,Auto
result      Long
  Code
  If self._WithKey(pKey) = Driver:ok
    self._ParameterOpcode = Opcode:GET
    If (self.Stmt_Get and self._nomemo = self._GetMemoCache) and self._GetCache = self._PropsCache and self._GetKeyCache &= pKey
      self.SqlCode.SetValue(self._GetSqlCache)
      Return self.Stmt_Get
    End
    If Self._GetSql(pKey) = driver:ok
      If self.Stmt_Get
        self._FreeStmt(self.Stmt_Get)
      End
      self.Stmt_Get = self._prepare()
      If self.Stmt_Get
        self._GetCache = self._PropsCache
        self._GetMemoCache = self._nomemo
        self._GetKeyCache &= pKey
        If self._GetSqlCache &= null
          self._GetSqlCache &= new StringTheory
        end
        self._GetSqlCache.SetValue(self.SqlCode)
        self._GetColsCache = self._StmtCols
        Return self.Stmt_Get
      End
    End
  End
  Return 0

!-----------------------------------------------------------------
DriverFileMSSQL2Class._MergeSQL  Procedure(DriverFileSQLClass pDestination,String pDestinationName)
x           Long,Auto
offset      BIGINT
limit       BIGINT
fieldlist   StringTheory
sets        StringTheory
values      StringTheory
primary     StringTheory
PleaseCycle Byte
  code
  ! construct field list overlap between source and destination
  self.ParseProject()  ! does not build a field list, just sets the self._ProjectField[x] array.
  Loop x = 1 to self.SharedProperties.FieldList.nodes
    self.Fields &= self._WithFieldNode(x)
    If self.Fields.Over or self.Fields.InOverGroup or self.Fields.Type = ClaGROUP then cycle.
    If self._ProjectField[x] = false then cycle.          ! importantly, 255, not 1, if included.
    do CheckDestinationFromFieldName
    If pleaseCycle then cycle.
    fieldlist.append(self.Fields.Column,,',')
    values.append('source.' & self.Fields.Column,,', ')
    If self.Fields.Primary
      primary.append('target.' & self.Fields.Column & '= source.' & self.Fields.Column ,,',')
    Else
      sets.append('target.' & self.Fields.Column & '= source.' & self.Fields.Column,,', ')
    End
  End
  If self.NoMemoArmed = false                                   ! doing Writes, wthout reads, so directly check if a call to NOMEMO is active.
    Loop x = 1 to Records(self.blobs)
      Get(self.blobs,x)
      If self._ProjectBlobField[x] = false then cycle.          ! importantly, 255, not 1, if included.
      do CheckDestinationFromBlobName
      If pleaseCycle then cycle.
      FieldList.append(self.blobs.Column,,',')
      sets.append('target.' & self.blobs.Column & '= source.' & self.blobs.Column,,', ')
      values.append('source.' & self.Blobs.Column,,', ')
    End
  End
  !
  If fieldlist.Length() = 0
    self.SetError(BadProjectErr)
    self.SqlCode.SetValue('')
    Return
  End
  self._NoAlias = true
  self.BuildWhere() ! this populates self.where from self.filter and self.sqlfilter.
  self._NoAlias = false

  offset = self.GetPROP:Offset()
  limit = self.GetPROP:Limit()
  If Offset or Limit or (not self.Where &= Null and self.Where <> '')
    self.SqlCode.SetValue('WITH SourceFiltered AS (' & |
                          ' SELECT ' & fieldlist.GetValue() & |
                          ' FROM ' & self._sanitize(self.FullPathName,driver:sqlTable))
    If not self.Where &= Null and self.Where <> ''
      self.SqlCode.Append(' WHERE ' & self.Where)
    End
    If Offset or Limit
      If Limit = 0 then Clear(Limit,1).
      self.SqlCode.Append(' ORDER BY ' & primary.GetValue() & |
                          ' OFFSET ' & Offset & ' ROWS FETCH NEXT ' & Limit & ' ROWS ONLY' )
    End
    self.SqlCode.Append(')')
    self.SqlCode.Append('MERGE INTO ' & clip(pDestinationName) & ' AS target USING SourceFiltered AS source' & |
                        ' ON ' & primary.GetValue() &|
                        ' WHEN MATCHED THEN UPDATE SET ' & sets.GetValue() & |
                        ' WHEN NOT MATCHED THEN INSERT(' & fieldlist.GetValue() & ')' & |
                        ' VALUES( ' & values.GetValue() & ');')

  Else
    self.SqlCode.SetValue('MERGE INTO ' & clip(pDestinationName) & ' AS target USING ' & self._sanitize(self.FullPathName,driver:sqlTable) &' AS source' & |
                        ' ON ' & primary.GetValue() &|
                        ' WHEN MATCHED THEN UPDATE SET ' & sets.GetValue() & |
                        ' WHEN NOT MATCHED THEN INSERT(' & fieldlist.GetValue() & ')' & |
                        ' VALUES( ' & values.GetValue() & ');')
  End

CheckDestinationFromFieldName  routine
  PleaseCycle = false
  If not pDestination &= null
    If pDestination._WithFieldNamed(self.Fields.UpperColumn) = Driver:ok
      If pDestination.Fields.ReadOnly or pDestination.Fields.Over or pDestination.Fields.Type = ClaGROUP
        PleaseCycle = true
        Exit
      End
    ElsIf pDestination._WithBlobNamed(self.Fields.UpperColumn) = Driver:ok
      If pDestination.blobs.Readonly
        PleaseCycle = true
        Exit
      End
    Else
      PleaseCycle = true
      Exit
    End
  End


CheckDestinationFromBlobName  routine
  PleaseCycle = false
  If not pDestination &= null
    If pDestination._WithFieldNamed(self.Blobs.UpperColumn) = Driver:ok
      If pDestination.Fields.ReadOnly or pDestination.Fields.Over or pDestination.Fields.Type = ClaGROUP
        PleaseCycle = true
        Exit
      End
    ElsIf pDestination._WithBlobNamed(self.Blobs.UpperColumn) = Driver:ok
      If pDestination.blobs.Readonly
        PleaseCycle = true
        Exit
      End
    Else
      PleaseCycle = true
      Exit
    End
  End

!-----------------------------------------------------------------
! The SQL for a UPDATE is pretty standard. However this method may need to be derived in a specific driver
! if the SQL syntax is different. MSSql for example does not use RETURNING to return values, but OUTPUT
DriverFileMSSQL2Class._PutSql Procedure()
x              Long
stmt           Long
Offset         Long
FieldsList     StringTheory
where          StringTheory
returning      StringTheory
  Code
  self.BuildProjectList(false)                     ! ProjectClauses are not included here

  self._ClearParameterQueue(self._ParameterOpcode)

  Loop x = 1 to self.SharedProperties.FieldList.nodes
    self.Fields &= self._withFieldNode(x)
    If self.Fields.Over or self.Fields.InOverGroup or self.Fields.Type = ClaGroup then Cycle.

    ! readonly fields are reset by a PUT. They are not written to.
    If (self.Fields.ReadOnly or self.Fields.IsIdentity) and self._fastwrite = false
      returning.Append('inserted.' & self.Fields.Column,st:noclip,',')
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
        ! Readonly fields are restored with a PUT. Since there's nothing to write, but the RETURNING fields have been altered, these need to be reset.
        returning.remove('inserted.')
        self.SqlCode.SetValue('SELECT ' & returning.GetValue() & ' FROM ' & self._sanitize(self.FullPathName,driver:sqlTable) & ' WHERE ' & where.GetValue() )
      End
    Else
      self.SqlCode.SetValue('UPDATE ' & self._sanitize(self.FullPathName,driver:sqlTable) & ' SET ' & FieldsList.GetValue())
      If returning.length()
        self.SqlCode.append(' OUTPUT ' & returning.GetValue())
      End
      self.SqlCode.append(' WHERE ' & where.GetValue() )
    End
    If self.SqlCode.Length()
      self.SqlCode.append(';')
    End
    Return driver:ok
  End
  Return Driver:notok


!-----------------------------------------------------------------
! the PUT updates the record by doing a WHERE on the Primary Key. Thus all FILE Reads MUST read the Primary Key values.
! supports prop:project - only projected fields will be updated.
DriverFileMSSQL2Class._PreparePut Procedure()
result          Long,Auto
FieldsList      StringTheory
where           StringTheory
returning       StringTheory
  Code
  If self._PutSql() = driver:ok and self.SqlCode.Length()
    If self.Stmt_Put and self.SqlCode.Equals(self._PutSqlCache)
      Return self.Stmt_Put
    End
    If self.Stmt_Put
      self._FreeStmt(self.Stmt_Put)
      self.Stmt_Put = 0
    End
    self.Stmt_Put = self._prepare()
    self._PutCache = self._PropsCache
    self._PutMemoCache = self._nomemo
    If self._PutSqlCache &= null
      self._PutSqlCache &= new StringTheory
    end
    self._PutSqlCache.SetValue(self.SqlCode)
    self._PutColsCache = self._StmtCols
    Return self.Stmt_Put
  End
  Return 0

!-----------------------------------------------------------------
DriverFileMSSQL2Class._PrepareRandom  Procedure(String pFilter, BIGINT pOffset)
stmt   Long
  Code
  If Self._RandomSql(pFilter, pOffset) = driver:ok
    stmt = self._prepare()
  End
  Return stmt

!-----------------------------------------------------------------
! note that this is the FILE set, not the VIEW set, however prop:order and prop:filter are in play
! this is called at the end of a SET, and also inside NextPrevious if the direction changes
DriverFileMSSQL2Class._GenerateSelect            Procedure(Long pOpcode)
result Long ,Auto
  Code
  If self.CheckConnect() = driver:notok then Return.
  If self.opt:explain or self._logExplain or self.Explain
    self._explain = True
  End
  If self._SelectSql(pOpCode) = driver:ok
    If self.Stmt_Set
      self._FreeStmt(self.Stmt_Set)
      self.Stmt_Set = 0
    End
    self.Stmt_Set = self._prepare()
  End
  If self._Explain
    result = self._executeSql(self.Stmt_Set)                   ! runs the EXPLAIN statement and builds a result set
    self.ResultToExplain(self.Result)                          ! interprets the EXPLAIN result, and outputs it somewhere.
    self._Explain = false
    If self._SelectSql(pOpCode) = driver:ok                    ! prepares again, this time without the explain
      self.Stmt_Set = self._prepare()
    End
  End
  parent._GenerateSelect(pOpcode)
  Return

!-----------------------------------------------------------------
! The syntax for this part is dependent on the SQL engine being used.
! This takes the OrderBy queue as input, and generates the prop:OrderBy as output
! makes use of self._setDirection to determine the OpCode
! for MSSQL we *always* want an ORDER BY as this is necessary for OFFSET and LIMIT. In the absence of any orderBy being set, the Primary Key is assumed.
DriverFileMSSQL2Class.SetOrderByFromQueue            Procedure()
OrderBy      Stringtheory
x            Long,Auto
  code
  parent.SetOrderByFromQueue()
  Loop x = 1 to Records(self.OrderQueue)                       ! Turn the OrderBy queue into SQL code.
    Get(self.OrderQueue,x)
    OrderBy.Append(self.OrderQueue.Clause,,',')
    If self._setdirection = Opcode:NEXT
      If self.OrderQueue.Direction = driver:Descending
        OrderBy.Append(' DESC')
      Else
        OrderBy.Append(' ASC')
      End
    ElsIf self._setdirection = Opcode:PREVIOUS
      If self.OrderQueue.Direction = driver:Descending
        OrderBy.Append(' ASC')
      Else
        OrderBy.Append(' DESC')
      End
    End
  End
  self.SetProp:OrderBy(OrderBy.GetValue())
  Return

!-----------------------------------------------------------------
! Data has come from the database, and is in the pStr "raw" (ie as it is in the database).
! It needs to move into the field in the record. The fieldsQueue is already loaded.
! In MSSQL the data is stored in a Text Array, so all we need to do is call self._PutJsonAsField
DriverFileMSSQL2Class._LoadArray        Procedure(*String pStr,Long pIndex, Long pBuffer, Long pCanNull)
  code
  self._PutJsonAsField(pStr,pIndex,pBuffer)
  Return

!-----------------------------------------------------------------
DriverFileMSSQL2Class.ExplainStart      Procedure()
  Code
  Return 'SET SHOWPLAN_ALL ON; GO; '

!-----------------------------------------------------------------
! File Methods
!-----------------------------------------------------------------
!-----------------------------------------------------------------
DriverFileMSSQL2Class.BUILD            PROCEDURE()
  Code
  Self.SetError(NoError)
  If self.CheckConnect() <> driver:ok then return.
  self.SqlCode.setvalue('ALTER INDEX ALL ON ' & self._sanitize(self.FullPathName,driver:sqlTable) & ' REBUILD;')
  self._ParameterOpcode = 0
  If self._ExecuteSqlNoParms() = Driver:ok
  End
  Return

!-----------------------------------------------------------------
DriverFileMSSQL2Class.BUILD            PROCEDURE(KEY pKey)
  Code
  Self.SetError(NoError)
  If self._withkey(pKey) = driver:ok
    If self.keys.primary
      self.Build()   ! Primary key is not a separate Index, so rebuilding the primary key is the same as building the file.
    Else
      self.SqlCode.setvalue('ALTER INDEX ' & self._sanitize(self.FullPathName & '_' & self.keys.dbName,driver:sqlTable) & ' ON ' & self._sanitize(self.FullPathName,driver:sqlTable) & ' REBUILD;')
      self._ParameterOpcode = 0
      If self._ExecuteSqlNoParms() = Driver:ok
      End
    End
  End
  Return
!-----------------------------------------------------------------
DriverFileMSSQL2Class._ClearField           Procedure(Long pIndex, Byte pHighLow, Long pAddr)
lg  Long,Auto
sh  Short,Auto
bt  Byte,Auto
decString  string(36)
  Code
  parent._ClearField(pIndex,pHighLow,pAddr)
  If self.Fields &= null then return.
  Case self.Fields.Type
  of ClaDecimal
  orof ClaPDecimal
    case self.DatabaseFieldType[self.Fields.Index]
    of SQL_INTEGER
      if pHighLow = driver:high then decString = 2147483647 else decString = -2147483648.
      self._StringToDec(decString,self.Fields.Type,address(decstring),self.Fields.DecimalSize,self.Fields.DecimalPlaces)
      memcpy(pAddr + self.Fields.Offset,address(Decstring),self.Fields.Size)
    of SQL_SMALLINT
      if pHighLow = driver:high then decString = 32767 else decString = -32768.
      self._StringToDec(decString,self.Fields.Type,address(decstring),self.Fields.DecimalSize,self.Fields.DecimalPlaces)
      memcpy(pAddr + self.Fields.Offset,address(Decstring),self.Fields.Size)
    of SQL_TINYINT
      if pHighLow = driver:high then decString = 255 else decString = 0.
      self._StringToDec(decString,self.Fields.Type,address(decstring),self.Fields.DecimalSize,self.Fields.DecimalPlaces)
      memcpy(pAddr + self.Fields.Offset,address(Decstring),self.Fields.Size)
    end
  End
  Return

!-----------------------------------------------------------------
DriverFileMSSQL2Class.CLONE                 Procedure(String pNewTableName,Long pOptions)
cstr        Cstring(size(pNewTableName)+1)
cmd         StringTheory
  code
  cstr = self._sanitize(pNewTableName,driver:sqlTable)
  !self.trace('DriverFileMSSQL2Class.CLONE ' & self.FullPathName & ' to ' & clip(pNewTableName) & ' opt=' & pOptions)
  ! First clone the table structure
  !!! this first part looks redundant, but it's necessary
  self.SqlCode.SetValue('SELECT * INTO ' & cstr & ' FROM ' & self._sanitize(self.FullPathName,driver:sqlTable) & ' WHERE 1 = 2;')
  cmd.append(self.SqlCode,,'<13,10>')
  If self._ExecuteSqlNoParms() <> driver:ok
    Return
  End

  ! Primary Key and Unique
  self.SqlCode.SetValue( |
    'DECLARE @sql NVARCHAR(MAX) = '''';<13,10> ' &|
    'SELECT @sql += '' ' &|
    'ALTER TABLE ' & cstr & ' ADD CONSTRAINT '' + QUOTENAME(''' & cstr & '_'' + k.name) + '' '' + ' &|
    ' ''PRIMARY KEY '' + ' &|
    ' ''('' + STRING_AGG(QUOTENAME(c.name), '', '') WITHIN GROUP (ORDER BY ic.key_ordinal) + '');'' ' &|
    'FROM sys.key_constraints k ' &|
    'JOIN sys.tables t ON t.object_id = k.parent_object_id ' &|
    'JOIN sys.index_columns ic ON ic.object_id = t.object_id AND ic.index_id = k.unique_index_id ' &|
    'JOIN sys.columns c ON c.object_id = t.object_id AND c.column_id = ic.column_id ' &|
    'WHERE t.name = ''' & self._sanitize(self.FullPathName,driver:sqlTable) & ''' ' &|
    'GROUP BY k.name, k.type; ' &|
    'EXEC sp_executesql @sql; ')
  cmd.append(self.SqlCode,,'<13,10>')
  If self._ExecuteSqlNoParms() <> driver:ok
    Return
  End

  ! Unique Keys
  If band(pOptions,Driver:UniqueKeys)
    self.SqlCode.SetValue( |
      'DECLARE @sql NVARCHAR(MAX) = '''';<13,10> ' &|
      'SELECT @sql += '' ' &|
      'ALTER TABLE ' & cstr & ' ADD CONSTRAINT '' + QUOTENAME(''' & cstr & '_'' + k.name) + '' '' + ' &|
      ' ''UNIQUE '' + ' &|
      ' ''('' + STRING_AGG(QUOTENAME(c.name), '', '') WITHIN GROUP (ORDER BY ic.key_ordinal) + '');'' ' &|
      'FROM sys.key_constraints k ' &|
      'JOIN sys.tables t ON t.object_id = k.parent_object_id ' &|
      'JOIN sys.index_columns ic ON ic.object_id = t.object_id AND ic.index_id = k.unique_index_id ' &|
      'JOIN sys.columns c ON c.object_id = t.object_id AND c.column_id = ic.column_id ' &|
      'WHERE t.name = ''' & self._sanitize(self.FullPathName,driver:sqlTable) & ''' ' &|
      'GROUP BY k.name, k.type; ' &|
      'EXEC sp_executesql @sql; ')
    cmd.append(self.SqlCode,,'<13,10>')
    If self._ExecuteSqlNoParms() <> driver:ok
      Return
    End
  End

  ! default values
  If band(pOptions,driver:DefaultValues)
    self.SqlCode.SetValue( |
    'DECLARE @sql NVARCHAR(MAX) = '''';<13,10> ' &|
    'SELECT @sql += ' &|
    '''ALTER TABLE ' & cstr & ' ADD CONSTRAINT '' + QUOTENAME(''' & cstr & '_'' + dc.name) + ' &|
    ''' DEFAULT '' + dc.definition + ' &|
    ''' FOR '' + QUOTENAME(c.name) + '';'' + CHAR(13) ' &|
    ' FROM sys.default_constraints dc  ' &|
    ' JOIN sys.columns c ON c.default_object_id = dc.object_id  ' &|
    ' JOIN sys.tables t ON t.object_id = c.object_id ' &|
    ' WHERE t.name = ''' & self._sanitize(self.FullPathName,driver:sqlTable) & ''';<13,10>' &|
    ' EXEC sp_executesql @sql')
    cmd.append(self.SqlCode,,'<13,10>')
    If self._ExecuteSqlNoParms() <> driver:ok
      Return
    End
  End

  ! CHECK constraints
  If band(pOptions,driver:Constraints)
    self.SqlCode.SetValue( |
      'DECLARE @sql NVARCHAR(MAX) = '''';<13,10> ' &|
      'SELECT @sql += ''ALTER TABLE ' & cstr & ' ADD CONSTRAINT '' + QUOTENAME(''' & cstr & '_'' + cc.name) + ' &|
      '    '' CHECK '' + cc.definition + '';'' + CHAR(13) ' &|
      'FROM sys.check_constraints cc ' &|
      'JOIN sys.tables t ON t.object_id = cc.parent_object_id ' &|
      'WHERE t.name = ''' & self._sanitize(self.FullPathName,driver:sqlTable) & '''; ' &|
      'EXEC sp_executesql @sql;' )
    cmd.append(self.SqlCode,,'<13,10>')
    If self._ExecuteSqlNoParms() <> driver:ok
      Return
    End
  End

  !FOREIGN KEY constraints
  If band(pOptions,Driver:ForeignKeys)
    self.SqlCode.SetValue( |
      'DECLARE @sql NVARCHAR(MAX) = '''';<13,10> ' &|
      'SELECT @sql += '' ' &|
      'ALTER TABLE ' & cstr & ' ADD CONSTRAINT '' + QUOTENAME(''' & cstr & '_'' + fk.name) + ' &|
      ''' FOREIGN KEY ('' + ' &|
      '    STRING_AGG(QUOTENAME(pc.name), '', '') WITHIN GROUP (ORDER BY fkc.constraint_column_id) + ' &|
      ''') REFERENCES '' + QUOTENAME(rt.name) + '' ('' + ' &|
      '    STRING_AGG(QUOTENAME(rc.name), '', '') WITHIN GROUP (ORDER BY fkc.constraint_column_id) + ' &|
      ''');'' + CHAR(13) ' &|
      'FROM sys.foreign_keys fk ' &|
      'JOIN sys.foreign_key_columns fkc ON fk.object_id = fkc.constraint_object_id ' &|
      'JOIN sys.tables pt ON pt.object_id = fk.parent_object_id ' &|
      'JOIN sys.columns pc ON pc.object_id = pt.object_id AND pc.column_id = fkc.parent_column_id ' &|
      'JOIN sys.tables rt ON rt.object_id = fk.referenced_object_id ' &|
      'JOIN sys.columns rc ON rc.object_id = rt.object_id AND rc.column_id = fkc.referenced_column_id ' &|
      'WHERE pt.name = ''' & self._sanitize(self.FullPathName,driver:sqlTable) & ''' ' &|
      'GROUP BY fk.name, rt.name; ' &|
      'EXEC sp_executesql @sql;')
    cmd.append(self.SqlCode,,'<13,10>')
    If self._ExecuteSqlNoParms() <> driver:ok
      Return
    End
  End

  !  Indexes (not Primary Key or Unique Indexes)
  If band(pOptions,Driver:Indexes)
    self.SqlCode.SetValue( |
      'DECLARE @sql NVARCHAR(MAX) = '''';<13,10> ' &|
      'SELECT @sql += '' ' &|
      'CREATE '' + CASE WHEN i.is_unique = 1 THEN ''UNIQUE '' ELSE '''' END + ' &|
      '    i.type_desc + '' INDEX '' + QUOTENAME(''' & cstr & '_'' + i.name) + ' &|
      '    '' ON ' & cstr & ' ('' + ' &|
      '    STRING_AGG(QUOTENAME(c.name), '', '') WITHIN GROUP (ORDER BY ic.key_ordinal) + ' &|
      '    '');'' + CHAR(13) ' &|
      'FROM sys.indexes i ' &|
      'JOIN sys.tables t ON t.object_id = i.object_id ' &|
      'JOIN sys.index_columns ic ON ic.object_id = i.object_id AND ic.index_id = i.index_id ' &|
      'JOIN sys.columns c ON c.object_id = t.object_id AND c.column_id = ic.column_id ' &|
      'WHERE t.name = ''' & self._sanitize(self.FullPathName,driver:sqlTable) & ''' ' &|
      '  AND i.is_primary_key = 0 ' &|
      '  AND i.is_unique_constraint = 0 ' &|
      '  AND i.type > 0  ' &|
      'GROUP BY i.name, i.type_desc, i.is_unique; ' &|
      'EXEC sp_executesql @sql;')
    cmd.append(self.SqlCode,,'<13,10>')
    If self._ExecuteSqlNoParms() = Driver:notok
      Return
    End
  End
  ! Triggers
  If band(pOptions,Driver:Triggers)
    self.SqlCode.SetValue( |
      'DECLARE @originalTable SYSNAME = ''' & self._sanitize(self.FullPathName,driver:sqlTable) & '''; ' &|
      'DECLARE @clonedTable SYSNAME = ''' & cstr & '''; ' &|
      'DECLARE @triggerSQL NVARCHAR(MAX); ' &|
      'DECLARE @triggerName SYSNAME; ' &|
      'DECLARE trigger_cursor CURSOR FOR ' &|
      'SELECT name ' &|
      'FROM sys.triggers ' &|
      'WHERE parent_id = OBJECT_ID(@originalTable); ' &|
      'OPEN trigger_cursor; ' &|
      'FETCH NEXT FROM trigger_cursor INTO @triggerName; ' &|
      'WHILE @@FETCH_STATUS = 0 ' &|
      'BEGIN ' &|
      '    SELECT @triggerSQL = OBJECT_DEFINITION(OBJECT_ID(@triggerName)); ' &|
      '    IF @triggerSQL IS NOT NULL ' &|
      '    BEGIN ' &|
      '        -- Replace original table name with cloned table name ' &|
      '        SET @triggerSQL = REPLACE(@triggerSQL, @originalTable, @clonedTable); ' &|
      '        -- Optionally: also rename trigger (so it''s unique) ' &|
      '        DECLARE @newTriggerName SYSNAME = @triggerName + ''_Clone''; ' &|
      '        SET @triggerSQL = REPLACE(@triggerSQL, ''CREATE TRIGGER '' + QUOTENAME(@triggerName), ' &|
      '                                              ''CREATE TRIGGER '' + QUOTENAME(@newTriggerName)); ' &|
      '        -- Print or execute ' &|
      '        PRINT ''-- Creating trigger: '' + @newTriggerName; ' &|
      '        EXEC sp_executesql @triggerSQL; ' &|
      '    END ' &|
      '    FETCH NEXT FROM trigger_cursor INTO @triggerName; ' &|
      'END ' &|
      'CLOSE trigger_cursor; ' &|
      'DEALLOCATE trigger_cursor;')
    cmd.append(self.SqlCode,,'<13,10>')
    If self._ExecuteSqlNoParms() = Driver:notok
      Return
    End
  End
  self.SqlCode.SetValue(cmd)
  Return

!-----------------------------------------------------------------
DriverFileMSSQL2Class.CLOSE            PROCEDURE()
result   Long,Auto
  Code
  If self._Destructing = true then Return.
  If self.InTransaction()   ! do this here. (It needs to be done very first).
    self.SetError(LogActiveErr)
    Return
  End
  self._closing = true  ! needs to come before the call to Disconnect
  self.SetError(NoError)
  self._ClearStmts()
  self._WhereParmNumber   = 0
  self._OffsetParmNumber  = 0
  self.Disconnect()      ! Disconnect comes after the parent call, because Close may need to send things to the database. (like RestoreRelations).
  parent.Close()
  self._closing = false  ! needs to come before the call to Disconnect
  Return

!-----------------------------------------------------------------
! make sure the object is connected to the correct database (as specified in self.owner).
! if an error is set during the connection, return driver:notok.
DriverFileMSSQL2Class.CheckConnect        PROCEDURE()
  Code
  If self._opened and self.dbHandle
    !!!todo but other drivers may want to check the connection is ok as well.
    Return driver:ok                                                            ! If the table is open, then connection is fine.
  End
  self._UpdateFileStrings()
  !self.trace('DriverFileMSSQL2Class.CheckConnect ' & self.Owner & ' // ' & self.FullPathName)
  If Self.Owner = ''
    Self.SetError(FileSystemErr)
    self.SetFileError(BadOwnerErr,'Owner is blank')
    Return driver:notok
  End
  If Self.FullPathName = ''
    Self.SetError(BadNameErr)
    Return driver:notok
  End
  If self.dbHandle  and self.Owner = self._ConnectedAs and self.pool = self._ConnectedPool
    !!!todo but other drivers may want to check the connection is ok as well.
    Return driver:ok
  End
  If self.dbHandle <> 0
    self.Disconnect()                                 ! Owner has changed, so disconnect from old connection
  End
  self.Connect()
  If Errorcode() then Return driver:notok.
  Return driver:ok

!-----------------------------------------------------------------
! Called whenever a new connection is established. Code here should run on any new connection.
! bear in mind that connections are pooled, so this isn't necessarily called for every object.
DriverFileMSSQL2Class.AfterConnect  procedure
  Code
  Return

!-----------------------------------------------------------------
DriverFileMSSQL2Class.COPY             PROCEDURE(STRING pNewTableName, Long pOptions)
cstr        Cstring(size(pNewTableName)+1)
stmt        Long
len         Long
result      Long
fieldlist   StringTheory
where       StringTheory
Orderby     StringTheory
x           long
offset      BIGINT
limit       BIGINT
cmd         StringTheory
  Code
  If self.CheckConnect() = Driver:notok
    self.ClearProps()
    Return        ! File can be OPEN. If closed a new connection is established.
  End
  Self.SetError(NoError)
  If pNewTableName = self.FullPathName
    self.ClearProps()
    Return
  End
  self._ParameterOpcode = Opcode:COPY
  self._ClearParameterQueue(Opcode:COPY)
  self.ParseProject()
  If Errorcode()
    self.ClearProps()
    Return
  End
  Loop x = 1 to self.SharedProperties.FieldList.nodes
    self.Fields &= self._WithFieldNode(x)
    If self.Fields.Over or self.Fields.InOverGroup or self.Fields.Type = ClaGROUP then cycle.
    If self._ProjectField[x] = false then cycle.          ! importantly, 255, not 1, if included.
    fieldlist.Append(self.Fields.Column,,',')
  End
  If self.NoMemoArmed = false                                   ! doing Writes, wthout reads, so directly check if a call to NOMEMO is active.
    Loop x = 1 to Records(self.blobs)
      Get(self.blobs,x)
      If self._ProjectBlobField[x] = false then cycle.          ! importantly, 255, not 1, if included.
      FieldList.append(self.blobs.Column,,',')
    End
  End
  ! WHERE
  self.BuildWhere()  ! this populates self.where from self.filter and self.sqlfilter.
  If Errorcode()
    self.ClearProps()
    Return
  End
  where.setvalue(self.GetProp:Where())
  cstr = self._sanitize(pNewTableName,driver:sqlTable)
  self.SqlCode.SetValue('DROP TABLE IF EXISTS ' & cstr & ';')
  cmd.append(self.SqlCode,,'<13,10>')
  If self._ExecuteSqlNoParms() = driver:ok
    ! table has been dropped, so recreate it. This recreates all the columns, regardless of FieldList but doesn't copy any data
    pOptions = BOR(pOptions,Driver:DefaultValues)  ! Need the default values, otherwise they could be null and fall foul of NOT NULL constraints.
    self.Clone(pNewTableName,pOptions)
    If Errorcode() then Return.
    ! table is now created, so copy data across
    cmd.append(self.SqlCode,,'<13,10>')
    offset = self.GetPROP:Offset()
    limit = self.GetPROP:Limit()
    If offset or limit
      If self._WithPrimaryKey() <> Driver:ok
        self.SetError(MissingPrimaryKeyErr)
        Return
      End
      Loop x = 1 to self.keys.components
        If self._WithField(self.keys.component[x]) = driver:ok
          Orderby.append(self.fields.Column,',')
        End
      End

      self.SqlCode.setvalue('INSERT INTO ' & cstr & ' (' & FieldList.GetValue() & ')' & |
                            ' SELECT ' & FieldList.GetValue() & |
                            ' FROM ('   & |
                            ' SELECT ' & FieldList.GetValue() & ' FROM ' & self._sanitize(self.FullPathName,driver:sqlTable) & ' ' & self._GetAlias(driver:nodot)  & |
                            CHOOSE(where.length() > 0, ' WHERE ' & where.getValue(),'') &|
                            ' ORDER BY ' & Orderby.GetValue() & |
                            ' OFFSET ' & offset & ' ROWS FETCH NEXT ' & limit & ' ROWS ONLY ) ' & |
                            ' as SourceData;' )
    Else
      self.SqlCode.setvalue('INSERT INTO ' & cstr & ' (' & FieldList.GetValue() & ')' & |
                            ' SELECT ' & FieldList.GetValue() &|
                            ' FROM ('   & |
                            ' SELECT ' & FieldList.GetValue() & ' FROM ' & self._sanitize(self.FullPathName,driver:sqlTable) & ' ' & self._GetAlias(driver:nodot)  & |
                            CHOOSE(where.length() > 0, ' WHERE ' & where.getValue(),'') &')' &|
                            ' as SourceData;' )
    End
    If self._executeSql() = driver:ok
      cmd.append(self.SqlCode,,'<13,10>')
    End
  End
  self.SqlCode.SetValue(cmd)
  self.ClearProps()  ! clears all the properties (not prop:sql)
  Return

!-----------------------------------------------------------------
! breaking this into a separate method allows it to be called without the parent checks.
DriverFileMSSQL2Class._CREATETABLE      PROCEDURE()
col           Long  ,Auto
x             Long  ,Auto
y             Long  ,Auto
primaryset    Byte
PKDesc        Byte
primaryextra  Byte
comma         Byte
clusterSet    Byte  ! If any key is set to Clustered, then this will be set to true.
allSql        StringTheory
  Code
  If self.opt:dummy then Return.   ! Dummy Tables are not created.
  If self.CheckConnect() = Driver:notok then Return.

  ! before this table can be created, all the parent tables need to be created.
  self.CreateParentTables()

  Loop x = 1 to Records(self.keys)
    Get(self.keys,x)
    If self.keys.primary then cycle.
    If self.keys.cluster = true
      clusterSet = true
    End
  End

  primaryset = 0
  If clusterSet = false and self._withPrimaryKey() = Driver:ok  ! If a cluster key is set, then can't use in-column ,PRIMARY
    If self.keys.components = 1
      If self._WithField(self.keys.component[1]) = driver:ok
        If self.keys.descending[1] = false
          primaryset = self.keys.component[1]
        End
      End
    End
  End

  ! now we need to create the table.
  self.SqlCode.SetValue('CREATE TABLE ' & self._sanitize(self.FullPathName,driver:sqlTable) & ' (<13,10>' )

  ! column definitions
  Loop col = 1 to self.SharedProperties.FieldList.nodes
    self.Fields &= self._WithFieldNode(col)
    If self.Fields.Type = ClaGROUP then cycle.
    If self.Fields.Over or self.Fields.InOverGroup then cycle.
    If comma
      self.SqlCode.append(',<13,10>')
    End
    self.SqlCode.append(self.Fields.column)
    comma = true
    If self.Fields.SqlType
      Case upper(self.Fields.SqlType)
      Of 'UUID'
        self.SqlCode.append(' UNIQUEIDENTIFIER')
      Else
        self.SqlCode.append(' ' & self.Fields.SqlType)
      End
    ElsIf not self.Fields.Interface &= Null
      self.SqlCode.append(' ' & self.Fields.interface.GetSQLType())
    ElsIf self.Fields.DimProduct > 1
      If self.Fields.Binary = true
        self.SqlCode.append(' VARBINARY(MAX)')
      Else
        self.SqlCode.append(' VARCHAR(MAX)')
      End
    Else
      Case self.Fields.Type
      of ClaBYTE
        self.SqlCode.append(' TINYINT')    ! specific to MSSQL
      of ClaSHORT
        self.SqlCode.append(' SMALLINT')   ! fairly universal
      of ClaUSHORT
        self.SqlCode.append(' INTEGER')    ! could add a check constraint to limit value
      of ClaLONG
        self.SqlCode.append(' INTEGER')    ! universal
      of ClaUlONG
        self.SqlCode.append(' BIGINT')     ! could add a check constraint to limit value
      of ClaDATE
        self.SqlCode.append(' DATE')
      of ClaTIME
        self.SqlCode.append(' TIME')
      of ClaDECIMAL
      orof ClaPDECIMAL
        self.SqlCode.append(' NUMERIC(' & self.Fields.DecimalSize & ',' & self.Fields.DecimalPlaces & ')')
      of ClaREAL
        self.SqlCode.append(' FLOAT')    ! varies a lot between databases.
      of ClaSREAL
        self.SqlCode.append(' REAL')    ! varies a lot between databases.
      of ClaCSTRING
        If self.Fields.Binary = true
          self.SqlCode.append(' VARBINARY(' & self.fields.Size-1 & ')')
        Else
          self.SqlCode.append(' VARCHAR(' & self.fields.Size-1 & ')')
        End
      of ClaSTRING
        If self.Fields.SqlTimeStamp = driver:GroupOverTimeStampTz
          self.SqlCode.append(' DATETIMEOFFSET')
        ElsIf self.Fields.SqlTimeStamp >= driver:GroupOverTimeStamp and self.Fields.SqlTimeStamp <= driver:GroupOverTimeStamp4
          self.SqlCode.append(' DATETIME2')    ! some databases use TIMESTAMP
        ElsIf self.Fields.Binary = true
          self.SqlCode.append(' BINARY(' & self.fields.Size & ')')
        Else
          self.SqlCode.append(' CHAR(' & self.fields.Size & ')')
        End

      of ClaPSTRING
        If self.Fields.Binary = true
          self.SqlCode.append(' BINARY(' & self.fields.Size-1 & ')')
        Else
          self.SqlCode.append(' VARCHAR(' & self.fields.Size-1 & ')')
        End
      End
    End
    self._CreateValidation()  ! This adds field-level CHECK constraints
    If self.Fields.Collate
      self.SqlCode.append(' COLLATE ' & self.Fields.Collate)  ! field level collation
    ElsIf self.fields.fieldcase
      self.SqlCode.append(' COLLATE "' & self._CreateCollation(self.fields.fieldcase) & '"')
    End
    self._CreateDefault(self.Fields.HasDefault, self.Fields.Type, Self.Fields.DefaultValue)  ! field level default values
    If self.Fields.IsIdentity
      self.SqlCode.append(' IDENTITY(1,1)')   ! varies a lot between databases  , this is for MSSQL
    End

    If self.Fields.index = primaryset
      self.SqlCode.append(' PRIMARY KEY ')
    End
  End
  ! blob and memo fields
  Loop col = 1 to records(self.blobs)
    Get(Self.Blobs,col)
    If comma
      self.SqlCode.append(',<13,10>')
    End
    If self.blobs.Binary = false
      self.SqlCode.append(self.blobs.column & ' VARCHAR(MAX)')
    Else
      self.SqlCode.append(self.blobs.column & ' VARBINARY(MAX)')
    End
    If self.blobs.NotNull
      self.SqlCode.append(' NOT NULL')
    End
    self._CreateDefault(self.blobs.HasDefault, Choose(self.blobs.Memo,ClaMEMO,ClaBLOB), Self.blobs.DefaultValue)
  End

  ! primary key
  If PrimarySet = false
    If self._withPrimaryKey() = driver:ok
      PrimarySet = true
      If PrimarySet
        self.SqlCode.append(',<13,10>PRIMARY KEY ' & CHOOSE(clusterSet=1,'NONCLUSTERED ','') & '(')
        self._ConstructKey(true)
      End
    Else
      self.SetError(MissingPrimaryKeyErr)
      self.SetFileError(MissingPrimaryKeyErr,'Table does not have a Primary Key')
      Return
    End
  End
  self._CreateForeignKeys()
     ! close the CREATE
  self.SqlCode.append('<13,10>)')

  self.SqlCode.append(';<13,10>')
  self._ParameterOpcode = 0
  If self._ExecuteSqlNoParms() = Driver:notok
    Return
  End
  AllSql.SetValue(self.SqlCode)
  self.SqlCode.SetValue('')

! keys and indexes not yet defined
  Loop x = 1 to Records(self.keys)
    Get(self.keys,x)
    If self.keys.type = Cla_DynIndex then cycle.
    If self.keys.primary then cycle.
    self._ConstructKey(false)
    self.SqlCode.append(';<13,10>')
    If self._ExecuteSqlNoParms() = Driver:notok
      Return
    End
    AllSql.Append(self.SqlCode)
  End
  self.SqlCode.SetValue(allSql)
  Return

!-----------------------------------------------------------------
DriverFileMSSQL2Class._CreateCollation            Procedure(Long pCase)
  code
  Return ''

!-----------------------------------------------------------------
DriverFileMSSQL2Class._CreateDefault  Procedure(Long pHasDefault, Long pType, String pDefault)
  code
  If pHasDefault = false then return.
  Case lower(pDefault)
  Of 'now'
    If self.Fields.SqlType and sub(upper(self.Fields.SqlType),1,4) = 'TIME'
      self.SqlCode.Append(' DEFAULT CAST(SYSDATETIME() AS ' & self.Fields.SqlType & ')')
      Return
    ElsIf pType = ClaTIME
      self.SqlCode.Append(' DEFAULT CAST(SYSDATETIME() AS TIME(2))')
      Return
    End
  Of 'utcnow'
    If self.Fields.SqlType and sub(upper(self.Fields.SqlType),1,4) = 'TIME'
      self.SqlCode.Append(' DEFAULT CAST(SYSUTCDATETIME() AS ' & self.Fields.SqlType & ')')
      Return
    ElsIf pType = ClaTIME
      self.SqlCode.Append(' DEFAULT CAST(SYSUTCDATETIME() AS TIME(2))')
      Return
    End
  End
  parent._CreateDefault(pHasDefault,pType,pDefault)
  Return

!-----------------------------------------------------------------
DriverFileMSSQL2Class._CreateForeignKeys      PROCEDURE()
x       long,auto
i       long,auto
obj     &DriverFileClass
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
      self.SqlCode.Append('')
    End
    Case self.relations.OnDelete
    Of driver:NoAction
      self.SqlCode.Append(' ON DELETE NO ACTION')
    Of driver:CascadeDelete
      self.SqlCode.Append(' ON DELETE CASCADE')
    Of driver:ClearDelete
      self.SqlCode.Append(' ON DELETE SET NULL')
    Of driver:RestrictDelete
      self.SqlCode.Append('')
    End
  End
  Return

!-----------------------------------------------------------------
DriverFileMSSQL2Class._ConstructKey   Procedure(Long pPrimary)
col           long ,Auto
comma         byte
  Code
  If pPrimary = false
    self.SqlCode.SetValue('CREATE ')
    If self.keys.dup = false then self.SqlCode.Append('UNIQUE ').
    If self.keys.cluster then self.SqlCode.Append('CLUSTERED ').
    self.SqlCode.Append('INDEX ' & self._sanitize(self.FullPathName & '_' & self.keys.dbName,driver:sqlTable) & ' ON ' & self._sanitize(self.FullPathName,driver:sqlTable) & ' (')
  End
  Loop col = 1 to self.keys.components
    do AddFieldToKey
  End
  self.SqlCode.append(')')
  If pPrimary = false and self.keys.opt
    self.SqlCode.append(' WHERE ')
    Loop col = 1 to self.keys.components
      do AddCheckToKey
    End
  End
  Return

AddCheckToKey  routine
  If self._withField(self.keys.component[col]) = Driver:ok
    If col > 1
      self.SqlCode.append(' AND ')
    End
    case self.fields.Type
    of ClaSTRING
    orof ClaPSTRING
    orof ClaCSTRING
      self.SqlCode.append('(' & self.Fields.column & ' <<> '''' AND ' & self.Fields.column & ' IS NOT NULL)')
    Else
      self.SqlCode.append('(' & self.Fields.column & ' <<> 0 AND ' & self.Fields.column & ' IS NOT NULL)')
    End
  End

AddFieldToKey  routine
  If self._withField(self.keys.component[col]) = Driver:ok
    If comma then self.SqlCode.Append(',').
    comma = true
    self.SqlCode.Append(self.Fields.column)
    Case self.Fields.Type
    of ClaSTRING
    orof ClaCSTRING
    orof ClaPSTRING
    End
    If self.keys.descending[col]
      self.SqlCode.Append(' DESC')
    !Else
      !self.SqlCode.Append('')
    End
  End


!-----------------------------------------------------------------
!!!todo CreateField(field)
DriverFileMSSQL2Class.CREATEFIELD                Procedure(*? pField1)
  Code
  Return

!-----------------------------------------------------------------
DriverFileMSSQL2Class.CREATEFIELD                Procedure(String pName, String pType, String pConstraint)
  Code
  If self.CheckConnect() = Driver:notok then Return.   ! File can be OPEN. If closed a new connection is established.
  Self.SetError(NoError)
  self.SqlCode.setvalue('ALTER TABLE ' & self._sanitize(self.FullPathName,driver:sqlTable) & ' ADD COLUMN ' & self._sanitize(pName,driver:SqlColumn) & ' ' & clip(pType) & ' ' & clip(pConstraint) & ';')
  self._ParameterOpcode = 0
  If self._ExecuteSqlNoParms() = driver:ok
  End
  Return

!-----------------------------------------------------------------
DriverFileMSSQL2Class.CREATEKEY         PROCEDURE(KEY pKey)
  Code
  self.SetError(NoDriverSupport)
  If self._WithKey(pKey) = Driver:ok
    self._ConstructKey(false)
    self.SqlCode.append(';<13,10>')
    If self._ExecuteSqlNoParms() = Driver:notok
      Return
    End
  End
  Return

!-----------------------------------------------------------------
DriverFileMSSQL2Class.CREATEKEY         PROCEDURE(String pName, Long pOptions, *? pField1, *? pField2, <*? pField3>, <*? pField4>, <*? pField5>, <*? pField6>, <*? pField7>, <*? pField8>, <*? pField9>, <*? pField10>)
  Code
  self.SetError(NoDriverSupport)
  Return

!-----------------------------------------------------------------
DriverFileMSSQL2Class.CREATERELATIONS   PROCEDURE()
x            Long
i            Long
obj          &DriverFileClass
childList    StringTheory
parentlist   StringTheory
joinlist     StringTheory
parentwhere  StringTheory
allsql       StringTheory
  code
  ! First look for orphaned records.
  ! if orphans exist in this table, for *any* parent then *no* relationships are created.
  Loop x = 1 to Records(self.relations)
    Get(self.relations,x)
    If self.relations.ParentFile &= null then cycle.
    obj &= self.relations.ParentFile{prop:object}
    If obj &= null then cycle.
    childList.SetValue('')
    joinlist.SetValue('')
    parentwhere.SetValue('')
    Loop i = 1 to maximum(self.relations.ChildIndex,1)
      If self.relations.ChildIndex[i] = 0 then break.
      If self._withField(self.relations.ChildIndex[i]) = driver:ok and obj._withField(self.relations.ParentIndex[i]) = driver:ok
        ChildList.Append('child.' & self.fields.Column,,',')
        JoinList.Append(' child.' & self.fields.Column & ' = parent.' & obj.fields.Column,,' AND ')
        ParentWhere.Append(obj.fields.Column & ' IS NULL',,' AND ')
      End
    End

    ! check that there are no orphans in the child. So do a SELECT to look for orphans
    self.Sqlcode.SetValue('SELECT ' & childlist.GetValue() & |
                          ' FROM ' & self.FullPathName & ' as child' & |
                          ' LEFT JOIN ' & obj.FullPathName & ' as parent' & |
                          ' ON ' & joinlist.GetValue() & |
                          ' WHERE ' & ParentWhere.GetValue() & |
                          ';')
    allsql.Append(self.SqlCode,,'<13,10>')
    If self._ExecuteSqlNoParms(self.Result) <> driver:ok
      self.SetError(FileSystemErr)
      Return
    End
    If self.result.Rows() > 0
      self.SetError(OrphanExistsErr)
      self.SetFileError(obj.FullPathName,'Orphans exist in child ' & self.FullPathName)
      Return
    End
  End

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
    self.Sqlcode.SetValue('ALTER TABLE ' & self.FullPathName & |
                          ' ADD CONSTRAINT FK_' & self.FullPathName & '_' & obj.FullPathName &|
                          ' FOREIGN KEY (' & childlist.GetValue() & ') REFERENCES ' & obj.FullPathName & '(' & parentlist.GetValue() & ')')
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
    self.SqlCode.Append(';')
    allsql.Append(self.SqlCode,,'<13,10>')
    self._ParameterOpcode = 0
    If self._ExecuteSqlNoParms() = Driver:notok
      Return
    End
  End
  self.sqlcode.SetValue(allSql)
  Return

!-----------------------------------------------------------------
DriverFileMSSQL2Class.DECLARATION               Procedure(Long pOptions=0)
Ans     StringTheory
AllSql  StringTheory
x       Long
  Code
  If self.CheckConnect() = driver:notok then Return driver:notok.
  !!! todo

  Return ans.GetValue()

!-----------------------------------------------------------------
DriverFileMSSQL2Class.DECLARATION               Procedure(Key pKey,Long pOptions=0)
  Code
  Return ''

!-----------------------------------------------------------------
! note that DUPLICATE can return false (will not create a duplicate) and the ADD can still fail
! because another client added the record in the meantime. In most cases it's better to detect the
! duplicate error after the ADD and handle appropriately.
DriverFileMSSQL2Class.DUPLICATE        PROCEDURE(KEY pKey)
result   Long,Auto
stmt     Long,Auto
Ans      Long
  Code
  If self._CheckOpen() = false then Return Ans.
  If self.CheckConnect() = driver:notok then Return Ans.
  self._ParameterOpcode = Opcode:DUPLICATE
  If self._DuplicateSql(pKey) = driver:ok
    stmt = self._Prepare()
    If stmt
      If self.ParmBufferX &= Null then self.ParmBufferX &= NEW DriverParmBufferClass.
      If self._BindParameters(stmt,self.ParmBufferX,self.CodePage) = Driver:ok
        self._ExecuteSqlToRecord(Stmt,driver:shadow,self._StmtCols)
        If ErrorCode() = NoRecErr
          self.SetError(NoError)
          Return False ! no record found, so no duplicate
        End
        ! check the found primary key fields against the last read position.
        If self.ComparePrimaryKeyPosition(driver:shadow) = false
          Ans = true
        End
      End
      self._FreeStmt(stmt)
      self._ClearParameterQueue(self._ParameterOpcode)
    End
  End
  Return ans

!-----------------------------------------------------------------
DriverFileMSSQL2Class.EMPTY            PROCEDURE()
AllSql  StringTheory
r       Long
  Code
  parent.Empty()
  If ErrorCode() then Return.

  If ConnectionPoolMSSQL2.GetTransaction(self.dbHandle) = 0
    ! truncate is faster, but requires ALTER permissions, not just DELETE permissions.
    ! truncate resets Identity columns to 1
    ! don't call Truncate inside a transaction because if it fails it aborts the transaction.
    r = self.RecordsFilter('')
    self.SqlCode.setvalue('TRUNCATE TABLE ' & self._sanitize(self.FullPathName,driver:sqlTable) & ';')
    AllSql.SetValue(self.SqlCode)
    self._ParameterOpcode = 0
    If self._ExecuteSqlNoParms() = driver:ok
      self.Affected = r
      Return
    End
  End

  ! if Truncate fails, try the DELETE approach instead
  self.SetError(NoError)
  self.SqlCode.setvalue('DELETE FROM ' & self._sanitize(self.FullPathName,driver:sqlTable) & ';')
  AllSql.SetValue(self.SqlCode)
  self._ParameterOpcode = 0
  If self._ExecuteSqlNoParms() = driver:ok
    If self.SharedProperties.HasIdentity
      self.SqlCode.setvalue('DBCC CHECKIDENT (''' & self._sanitize(self.FullPathName,driver:sqlTable) & ''', RESEED, 0);')
      If self._ExecuteSqlNoParms() = driver:ok
        AllSql.Append(self.SqlCode)
      End
    End
  End
  Self.SqlCode.SetValue(AllSql)
  Return  ! the second part may have failed, but the first part succeeded

!-----------------------------------------------------------------
! check to see if a table exists in the database
DriverFileMSSQL2Class.EXISTS           PROCEDURE(String pTablename)
DatabaseName  Cstring(255)
TableName     Cstring(255)
SchemaName    Cstring(255)
stmt          Long,Auto
tbl           Cstring(6),Auto
result        Long,Auto
ans           Byte
dbcell        String(255)
slip          Long
x             Long
  Code
  !self.trace('DriverFileMSSQL2Class.EXISTS ' & errorcode())
  If self.CheckConnect() = Driver:notok     ! File can be OPEN. If closed a new connection is established.
    !self.trace('DriverFileMSSQL2Class.EXISTS connection failed')
    Return false
  End
  databasename = self.GETPROP:Database()
  If pTablename
    tablename = self._sanitize(clip(pTablename),driver:sqlTable)
  Else
    tablename =  self._sanitize(self.FullPathName,driver:sqlTable)
  End
  !self.trace('DriverFileMSSQL2Class.EXISTS : Tablename=[' & Tablename & '] owner=' & self.Owner)
  If Tablename = ''
    Self.SetError(BadNameErr)
    Return false
  End
  Self.SetError(NoError)
  tbl = 'TABLE'
  self._SplitSchema(TableName,SchemaName)
  If SchemaName = '' then SchemaName = 'dbo'.

 ! Allocate statement handle
  result = SQLAllocHandle(SQL_HANDLE_STMT, self.dbHandle, stmt)
  If Result <> SQL_SUCCESS and Result <> SQL_SUCCESS_WITH_INFO
    self.SetErrorMssql(SQL_HANDLE_STMT,stmt,'[d032]')
    self.SetError(FileSystemErr)
    Return false
  End
  result = SQLTables(stmt, address(databasename), len(databasename), address(SchemaName), Len(SchemaName), address(TableName), Len(TableName), address(tbl), 5)
  self.sqlcode.setvalue('SQLTables(''' & SchemaName & ''',''' & databasename & ''',''' & tablename & ''')')
  If self._logSQL then self.Log('[SQL ]' & self.SqlCode.GetValue()).
  If Result <> SQL_SUCCESS and Result <> SQL_SUCCESS_WITH_INFO
    self.SetErrorMssql(SQL_HANDLE_STMT,stmt,'[d033]')
    Return false
  End
  ! Fetch the result
  Result = SQLFetch(stmt)
  case Result
  of  SQL_SUCCESS
  orof SQL_SUCCESS_WITH_INFO
    Ans = true
  of SQL_NO_DATA
    Ans = False
  Else
    self.trace('failed to get SQLFetch - result = ' & result)
    self.SetErrorMssql(SQL_HANDLE_STMT,stmt,'[d034]')
  End

  ! Free the statement handle
  result = SQLFreeHandle(SQL_HANDLE_STMT, stmt)
  Return ans

!-----------------------------------------------------------------
DriverFileMSSQL2Class.EXISTS           PROCEDURE(Long pWhat,String pName)
ans   Long
typ   Cstring(3)
  Code
  case pWhat
  of driver:table                !Equate(1)    ! U
    typ = 'U'
  of driver:storedprocedure      !Equate(2)    ! P
  orof driver:sp                   !Equate(2)
    typ = 'P'
  of driver:trigger              !Equate(3)    ! TR
    typ = 'TR'
  of driver:index                !Equate(4)
    return false                 ! Not supported yet
  of driver:primarykey           !Equate(5)    ! PK
    typ = 'PK'
  of driver:uniqueconstraint     !Equate(6)    ! UQ
    typ = 'UQ'
  of driver:foreignkeyconstraint !Equate(7)    ! F
    typ = 'F'
  of driver:defaultconstraint    !Equate(8)    ! D
    typ = 'D'
  of driver:scalarfunction       !Equate(9)    ! FN
    typ = 'FN'
  of driver:tablevaluedfunction  !Equate(10)   ! TF
    typ = 'TF'
  of driver:view                 !Equate(11)   ! V
    typ = 'V'
  End
  self.SqlCode.SetValue('SELECT 1 FROM sys.objects WHERE type = ''' & typ &''' AND name = ''' & clip(pName) & ''';')
   If self._executeSql() = driver:ok
    If self.Result.Rows()
      ans = self.Result.GetCell(1,1)
    End
  End
  Return ans

!-----------------------------------------------------------------
DriverFileMSSQL2Class.EXISTSDB         PROCEDURE(String pDatabaseName)
ans       Long
namewas   string(255)
  Code
  self.SetError(NoError)
  If self.SwitchToMaster('database=','master',';',NameWas) = driver:ok
    self.SqlCode.SetValue('SELECT COUNT(*) AS DbExists FROM sys.databases WHERE name = N''' & clip(pDatabaseName) & ''';')
    If self._executeSql() = driver:ok
      If self.Result.Rows()
        ans = self.Result.GetCell(1,1)
      End
    End
  End
  self.SwitchBack()
  Return ans

!-----------------------------------------------------------------
DriverFileMSSQL2Class.SUSPENDRELATIONS           PROCEDURE()
result  long
  Code
  self.SetError(NoError)
  If self._opened = False
    self._UpdateFileStrings()
  End
  self._relationsOff = True
  self.SqlCode.SetValue('ALTER TABLE ' & self._sanitize(self.FullPathName,driver:sqlTable) & ' NOCHECK CONSTRAINT ALL;')
  self._ParameterOpcode = 0
  result = self._ExecuteSqlNoParms()
  Return

!-----------------------------------------------------------------
DriverFileMSSQL2Class.RESUMERELATIONS           PROCEDURE()
result  long
  Code
  self.SetError(NoError)
  !If self._relationsOff  ! With MSSQL the turning off of relations is not restricted to the program or thread.
    self._relationsOff = False
    !self.Send('ALTER TABLE your_table_name WITH CHECK CHECK CONSTRAINT ALL')
    self.SqlCode.setvalue('ALTER TABLE ' & self._sanitize(self.FullPathName,driver:sqlTable) & ' WITH CHECK CHECK CONSTRAINT ALL;')
    self._ParameterOpcode = 0
    result =  self._ExecuteSqlNoParms()
  !End
  Return

!-----------------------------------------------------------------
! Calling STREAM sets the database up for multiple writes.
! FLUSH? will return the system to the state it was before the STREAM
! consider also using SUSPENDRELATIONS for even faster performance.
DriverFileMSSQL2Class.STREAM           PROCEDURE()
cmd  StringTheory
  Code
  parent.Stream()
  If Errorcode() then Return.
  If self._inTransaction or self._InStream
    self.SetError(LogActiveErr)
  ElsIf self.dbHandle
    ! begin transaction
    self._ParameterOpcode = Opcode:NONE
    !!!todo
!    self.SqlCode.SetValue('BEGIN TRANSACTION;')
!    If self._ExecuteSqlNoParms() = Driver:ok
!      self._inStream = true
!    End
!    cmd.append(self.sqlcode,,'<13,10>')
  End
  self.SqlCode.SetValue(cmd)
  Return

!-----------------------------------------------------------------
DriverFileMSSQL2Class.FLUSH             Procedure
cmd  StringTheory
  Code
  If self._inTransaction                ! If you're inside a transaction, you can't call FLUSH
    self.SetError(LogActiveErr)
    Return
  elsif self._InStream = False          ! don't set an error - Flush can be called without STREAM
    !Self.SetError(NoLogoutErr)
  Else
    self._ParameterOpcode = Opcode:NONE
    !!!todo
!    self.SqlCode.SetValue('COMMIT;')
!    If self._ExecuteSqlNoParms() = Driver:ok
!    End
!    cmd.append(self.sqlcode,,'<13,10>')
  End

  self._inStream = False
  parent.Flush()
  If Errorcode() then Return.
  self.SqlCode.SetValue(cmd)
  Return

!-----------------------------------------------------------------
DriverFileMSSQL2Class.GETSTATE               Procedure(Long pSaveBlob)
len  Long,Auto
i    Long,Auto
  Code
  PushErrors()
  i = parent.GetState(pSaveBlob)
  len = address(self.__MSSQLSTATEEND) - address(self.__MSSQLSTATESTART)
  self.State.Level4 &= new String(len)
  MemCpy(address(self.State.Level4),address(self.__MSSQLSTATESTART),len)
  Put(self.State)
  PopErrors()     ! GetState should not alter errorcode.
  Return i

!-----------------------------------------------------------------
DriverFileMSSQL2Class.RESTORESTATE           Procedure(Long pState, Byte pBuffer)
len  Long
  Code
  Parent.RestoreState(pState,pBuffer)
  If self.state.id = 0 then Return.
  len = address(self.__MSSQLSTATEEND) - address(self.__MSSQLSTATESTART)
  MemCpy(address(self.__MSSQLSTATESTART),address(self.State.Level4),len)

  !if restoring from queues then do
  !Self.SetError(self.state.Errorcode)
  !Self.SetFileError(self.state.FileErrorCode,self.state.FileError)

  Return

!-----------------------------------------------------------------
DriverFileMSSQL2Class.MERGESlow              Procedure(FILE pDestination, LONG pOptions)
  Code
  !!!todo implement merge slow
  Return

!-----------------------------------------------------------------
DriverFileMSSQL2Class.MERGEFast      Procedure(FILE pDestination, LONG pOptions)
obj   &DriverFileSQLClass
  Code
  obj &= pDestination{prop:object}
  If obj &= null
    self.SetError(FileSystemErr)
    self.SetFileError(NoDriverSupport,'Failure to Merge. Destination Driver is not an Object Based Driver')
    Return
  End
  If self.GetPROP:Database() <> obj.GetPROP:Database()
    self.MergeSlow(pDestination,pOptions)
    Return
  End
  self._MergeWork(obj,obj.FullPathName,pOptions)
  Return

!-----------------------------------------------------------------
DriverFileMSSQL2Class.MERGEFast      Procedure(String pDestination, LONG pOptions)
obj   &DriverFileSQLClass
  Code
  self._MergeWork(obj,pDestination,pOptions)
  Return

!-----------------------------------------------------------------
DriverFileMSSQL2Class._MergeWork              Procedure(DriverFileSQLClass pObj, String pDestination, LONG pOptions)
stmt    long
  Code
  self._ParameterOpcode = OpCode:MERGE
  self._ClearParameterQueue(self._ParameterOpcode)
  self.SetError(NoError)
  self._MergeSQL(pObj,pDestination)
  stmt = self._Prepare()
  If stmt
    If self._ExecuteSql(stmt) = driver:ok
    End
  End
  Return

!-----------------------------------------------------------------
DriverFileMSSQL2Class.OPEN             PROCEDURE(LONG pAccessMode=022h)
OutLen  Short,Auto
Result  Long,Auto
  Code
  parent.Open(pAccessMode)                     ! Parent MUST be called before opening the table.
  If Errorcode() then Return.                   !  Abort if Errorcode set.
  self.Stmt_Add           = 0
  self.Stmt_Append        = 0
  self.Stmt_Put           = 0
  self._PutCols           = 0
  self._PutNoMemoCols     = 0
  self.Stmt_Delete        = 0
  self.Stmt_Upsert        = 0
  self.Stmt_Set           = 0
  self._WhereParmNumber   = 0
  self._OffsetParmNumber  = 0
  self._SynchronousAtStream = -1
  self._CacheSizeAtStream = 0
  If self.CheckConnect() = Driver:notok then Return.
  ! check that all the fields in the clarion table match the fields in the database.
  ! indexes do not need to match, unless asked for.
  ! sql table can have more fields than are listed here.
  !!!todo this is effectivly doing a / GATHERATOPEN. could test for that and check structure later if necessary.
  !self.trace('xxx3 OPEN self.SharedProperties.ValidatedOwner=[' & self.SharedProperties.ValidatedOwner & '] self.Owner=[' &self.Owner & '] self.SharedProperties.ValidatedFileName=[' & self.SharedProperties.ValidatedFileName & '] self.FullPathName=[' & sel
  If self.SharedProperties.ValidatedOwner <> self.Owner or self.SharedProperties.ValidatedFileName <> self.FullPathName or self.DatabaseFieldType[1] = 0
    If self.opt:dummy
      self.SharedProperties.ValidatedOwner     = self.Owner
      self.SharedProperties.ValidatedFileName  = self.FullPathName
      self.AfterOpen(pAccessmode,true)
    ElsIf self.ValidateStructure() = Driver:ok
      self.AfterOpen(pAccessmode,true)
      self.SharedProperties.ValidatedOwner     = self.Owner
      self.SharedProperties.ValidatedFileName  = self.FullPathName  !!!todo, could just use the server, port, database parts of the owner.
    Else
      self.AfterOpen(pAccessmode,false)
    End
  Else
    PushErrors()
    If self.Exists(self.FullPathName) = false
      PopErrors()
      self.SetError(NoFileErr)
    Else
      PopErrors()
      self.AfterOpen(pAccessmode,true)
    End
  End
  If self._opened
    result = SQLGetInfo(self.dbHandle, SQL_SERVER_NAME, address(self._connect[1]), size(self._connect[1]), outLen);
    result = SQLGetInfo(self.dbHandle, SQL_DATABASE_NAME,  address(self._connect[2]), size(self._connect[2]), outLen);
    result = SQLGetInfo(self.dbHandle, SQL_USER_NAME,  address(self._connect[3]), size(self._connect[3]), outLen);
  End
  Return

!-----------------------------------------------------------------
DriverFileMSSQL2Class._SplitSchema   PROCEDURE(*cstring pTableName, *Cstring pSchemaName)
x                  Long,Auto
  code
  x = instring('.',pTableName,1,1)
  If x
    pSchemaName = sub(pTableName,1,x-1)
    pTableName = sub(pTableName,x+1,Len(pTablename)-x)
  End

!-----------------------------------------------------------------
DriverFileMSSQL2Class._GetStructure   PROCEDURE()
result             Long,Auto
stmt               Long
x                  Long,Auto
TableName          Cstring(255),Auto
cstr               &cstring

! Bound column buffers
colName            Cstring(DRIVER:MAXFIELDNAMELEN)
typeName           Cstring(50)
maxLen             Long
precision          Short
scale              Short

! Null indicators for bound columns
slipColName        Long
slipTypeName       Long
slipMaxLen         Long
slipPrecision      Long
slipScale          Long

colSize            Long,Auto
dataType           Long,Auto
found              Long
  Code
  If self.opt:TurboSQL then Return Driver:ok.
  If self.CheckConnect() = driver:notok then Return driver:notok.

  TableName = self._sanitize(self.FullPathName,driver:sqlTable)
  If TableName = ''
    Self.SetError(BadNameErr)
    Return driver:notok
  End
  ! Clear arrays in case of re-validation
  Clear(self.DatabaseFieldType,0)
  Clear(self.DatabaseFieldSize,0)
  Clear(self.DatabaseFieldPrecision,0)

  ! Allocate statement handle
  result = SQLAllocHandle(SQL_HANDLE_STMT, self.dbHandle, stmt)
  If Result <> SQL_SUCCESS and Result <> SQL_SUCCESS_WITH_INFO
    self.SetErrorMssql(SQL_HANDLE_STMT,stmt,'[d070]')
    self.SetError(FileSystemErr)
    Return driver:notok
  End

  self.SqlCode.SetValue( 'SELECT c.name,t.name,c.max_length,c.precision,c.scale' & |
                         ' FROM sys.columns c' & |
                         ' JOIN sys.types t ON c.user_type_id=t.user_type_id' & |
                         ' WHERE c.object_id=OBJECT_ID(''' & TableName & ''')' )

  cstr &= self.SqlCode.ToCstring()
  result = SQLExecDirect(stmt, cstr, SQL_NTS)
  If Result <> SQL_SUCCESS and Result <> SQL_SUCCESS_WITH_INFO
    self.SetErrorMssql(SQL_HANDLE_STMT,stmt,'[d071]')
    result = SQLFreeHandle(SQL_HANDLE_STMT, stmt)
    Return driver:notok
  End
  Dispose(cstr)

  ! Bind the 5 result columns
  result = SQLBindCol(stmt, 1, SQL_C_CHAR,  Address(colName),  Size(colName),  slipColName)
  If Result <> SQL_SUCCESS and Result <> SQL_SUCCESS_WITH_INFO
    self.SetErrorMssql(SQL_HANDLE_STMT,stmt,'[d072]')
    result = SQLFreeHandle(SQL_HANDLE_STMT, stmt)
    Return driver:notok
  End
  result = SQLBindCol(stmt, 2, SQL_C_CHAR,  Address(typeName), Size(typeName), slipTypeName)
  result = SQLBindCol(stmt, 3, SQL_C_LONG,  Address(maxLen),   0,              slipMaxLen)
  result = SQLBindCol(stmt, 4, SQL_C_SHORT, Address(precision),0,              slipPrecision)
  result = SQLBindCol(stmt, 5, SQL_C_SHORT, Address(scale),    0,              slipScale)

  ! Fetch rows and populate DatabaseField arrays directly
  found = 0
  Loop
    result = SQLFetch(stmt)
    Case result
    of SQL_NO_DATA
      Break
    of SQL_SUCCESS
    orof SQL_SUCCESS_WITH_INFO
    Else
      self.SetErrorMssql(SQL_HANDLE_STMT,stmt,'[d073]')
      Break
    End
    found += 1
    If self._WithFieldNamed(colName) = Driver:ok
      dataType = self._TypeNameToSQL(typeName)
      Case dataType
      of SQL_VARCHAR
      orof SQL_CHAR
      orof SQL_BINARY
        if MaxLen < 0
          colSize = 0
        else
          colSize = MaxLen
        End
      of SQL_WCHAR orof SQL_WVARCHAR orof SQL_WLONGVARCHAR
        colSize = maxLen / 2
      !of SQL_DECIMAL orof SQL_NUMERIC
      !  colSize = precision
      Else
        colSize = precision
      End
      self.DatabaseFieldType[self.Fields.Index] = dataType
      self.DatabaseFieldSize[self.Fields.Index] = colSize
      self.DatabaseFieldPrecision[self.Fields.Index] = scale
      !self.trace('self.Fields.Index=' & self.Fields.Index & ' type=' & self.DatabaseFieldType[self.Fields.Index] & ' size=' & self.DatabaseFieldSize[self.Fields.Index] & ' precision='& self.DatabaseFieldPrecision[self.Fields.Index])
      If dataType = SQL_GUID
        Case self.Fields.Type
        of ClaSTRING
        orof ClaCSTRING
          If self.Fields.Interface &= null
            self.Fields.Interface &= (Address(DriverUniqueIdentifierMSObject))
            self.Fields.SourceSize = self.Fields.Interface.GetSourceSize()
          End
        End
      End
    End
  End

  result = SQLFreeHandle(SQL_HANDLE_STMT, stmt)

  If found = 0
    self.SetError(NoFileErr)
    Return Driver:notok
  End

  ! Verify all declared fields were found
  Loop x = 1 to self.SharedProperties.FieldList.nodes
    self.Fields &= self._WithFieldNode(x)
    If self.Fields.Type = ClaGROUP or self.Fields.Over or self.Fields.InOverGroup
      Cycle
    End
    If self.DatabaseFieldType[x] = 0
      self.SetError(InvalidFileErr)
      self.SetFileError(InvalidFileErr,'Missing field in backend table: ' & self.Fields.column & ' in ' & self.FullPathName & ' // ' & self.Owner)
      Return Driver:notok
    End
  End
  Return Driver:ok

!-----------------------------------------------------------------
! Trigger a call to the backend to get the table definition.
! That will be populated into the ResultSet.
!| Column # | Column Name           | Data Type    | Description                                                                                              |
!| -------- | --------------------- | ------------ | -------------------------------------------------------------------------------------------------------- |
!| 1        | TABLE_CAT             | SQL_VARCHAR  | Database (catalog) name; may be NULL if not supported.                                                   |
!| 2        | TABLE_SCHEM           | SQL_VARCHAR  | Schema name; may be NULL if not supported.                                                               |
!| 3        | TABLE_NAME            | SQL_VARCHAR  | Table name.                                                                                              |
!| 4        | COLUMN_NAME           | SQL_VARCHAR  | Column name.                                                                                             |
!| 5        | DATA_TYPE             | SQL_SMALLINT | SQL data type code (ODBC type, e.g., `SQL_INTEGER`).                                                     |
!| 6        | TYPE_NAME             | SQL_VARCHAR  | Data type name (database-specific, e.g., `"INT"`, `"VARCHAR"`).                                          |
!| 7        | COLUMN_SIZE           | SQL_INTEGER  | Column size (precision). For character types, max length in characters.                                  |
!| 8        | BUFFER_LENGTH         | SQL_INTEGER  | Length in bytes for transferring data.                                                                   |
!| 9        | DECIMAL_DIGITS        | SQL_SMALLINT | Scale for numeric/decimal types; otherwise NULL.                                                         |
!| 10       | NUM_PREC_RADIX        | SQL_SMALLINT | Radix for numeric types (10 for exact, 2 for approximate). NULL if not applicable.                       |
!| 11       | NULLABLE              | SQL_SMALLINT | Whether column can contain NULLs: `SQL_NO_NULLS` (0), `SQL_NULLABLE` (1), or `SQL_NULLABLE_UNKNOWN` (2). |
!| 12       | REMARKS               | SQL_VARCHAR  | Column description (if available).                                                                       |
!| 13       | COLUMN_DEF            | SQL_VARCHAR  | Default value of the column, as a string (may be database-dependent).                                    |
!| 14       | SQL_DATA_TYPE         | SQL_SMALLINT | SQL data type (same as `DATA_TYPE`, but used with `SQL_DATETIME_SUB`).                                   |
!| 15       | SQL_DATETIME_SUB      | SQL_SMALLINT | Subtype code for datetime/interval types (e.g., `SQL_CODE_DATE`), NULL otherwise.                        |
!| 16       | CHAR_OCTET_LENGTH     | SQL_INTEGER  | Max length in bytes for character/binary columns, NULL otherwise.                                        |
!| 17       | ORDINAL_POSITION      | SQL_INTEGER  | Column’s ordinal position in the table (1-based).                                                        |
!| 18       | IS_NULLABLE           | SQL_VARCHAR  | `"YES"` if NULL allowed, `"NO"` if not, empty string if unknown.                                         |
!| 19+      | Driver-specific columns | varies     | Some drivers return extra fields beyond column 18.                                                       |

!-----------------------------------------------------------------
DriverFileMSSQL2Class.ValidateStructure  Procedure()
  Code
  If self._GetStructure() = Driver:notok
    Return Driver:notok
  End
  Return parent.ValidateStructure()
!
!-----------------------------------------------------------------
DriverFileMSSQL2Class.PACK             PROCEDURE()
  Code
  If self.CheckConnect() = Driver:notok then Return.   ! File can be OPEN. If closed a new connection is established.
  Self.SetError(NoError)
  self.SqlCode.setvalue('ALTER INDEX ALL ON ' & self._sanitize(self.FullPathName,driver:sqlTable) & ' REORGANIZE;')
  self._ParameterOpcode = 0
  If self._ExecuteSqlNoParms() = driver:ok
  End
  Return

!-----------------------------------------------------------------
DriverFileMSSQL2Class.REMOVEFIELD          PROCEDURE(String pName)
  Code
  If self.CheckConnect() = Driver:notok then Return.   ! File can be OPEN. If closed a new connection is established.
  Self.SetError(NoError)
  self.SqlCode.setvalue('ALTER TABLE ' & self._sanitize(self.FullPathName,driver:sqlTable) & ' DROP COLUMN ' & self._sanitize(pName,driver:SqlColumn) & ';')
  self._ParameterOpcode = 0
  If self._ExecuteSqlNoParms() = driver:ok
  End
  Return

!-----------------------------------------------------------------
DriverFileMSSQL2Class.REMOVEKEY           PROCEDURE(String pName)
  Code
  If self.CheckConnect() = Driver:notok then Return.   ! File can be OPEN. If closed a new connection is established.
  Self.SetError(NoError)
  self.SqlCode.setvalue('DROP INDEX ' & clip(pName) & ';')
  self._ParameterOpcode = 0
  If self._ExecuteSqlNoParms() = driver:ok
  End
  Return

!-----------------------------------------------------------------
DriverFileMSSQL2Class.REMOVEKEY           PROCEDURE(Key pKey)
  Code
  If self.CheckConnect() = Driver:notok then Return.   ! File can be OPEN. If closed a new connection is established.
  Self.SetError(NoError)
  If self._WithKey(pKey) = Driver:ok
    self.SqlCode.setvalue('DROP INDEX ' & self._sanitize(self.FullPathName & '_' & self.keys.dbName,driver:sqlTable) & ';')
    self._ParameterOpcode = 0
    If self._ExecuteSqlNoParms() = Driver:notok
      Return
    End
  End
  Return

!-----------------------------------------------------------------
! because pNewFileName is not trusted, a parameterized statement is created and executed.
DriverFileMSSQL2Class.RENAME           PROCEDURE(STRING pNewFileName)
cstr    cstring(size(pNewFileName)+1),Auto
cmd     stringtheory
  Code
  If self.CheckConnect() = Driver:notok then Return.         ! File can be OPEN. If closed a new connection is established.
  cstr = self._sanitize(pNewFileName,driver:sqlTable)
  Self.SetError(NoError)
  self._ParameterOpcode = 0
  If self.Exists(cstr)
    self.SetError(NoAccessErr)
  Else
    self.SqlCode.setvalue('EXEC sp_rename ''' & self._sanitize(self.FullPathName,driver:sqlTable) & ''', ''' & cstr & ''';' )
    cmd.SetValue(self.SqlCode)
    If self._ExecuteSqlNoParms() = driver:ok
      self.SqlCode.SetValue('DECLARE @OldTableName NVARCHAR(128) = ''' & self._sanitize(self.FullPathName,driver:sqlTable) & ''';<13,10>' & |
                            'DECLARE @NewTableName NVARCHAR(128) = ''' & cstr & ''';<13,10>' & |
                            'DECLARE @sql NVARCHAR(MAX) = '''';<13,10>' & |
                            'DECLARE @name NVARCHAR(128);<13,10>' & |
                            'DECLARE @newname NVARCHAR(128);<13,10>' & |
                            'DECLARE @schema NVARCHAR(128);<13,10>' & |
                            'DECLARE @type NVARCHAR(60);<13,10>' & |
                            'DECLARE @fullOldName NVARCHAR(300);<13,10>' & |
                            'DECLARE cur_constraints CURSOR FOR <13,10>' & |
                            'SELECT <13,10>' & |
                            '    o.name, <13,10>' & |
                            '    s.name AS schema_name, <13,10>' & |
                            '    o.type_desc<13,10>' & |
                            ' FROM sys.objects o<13,10>' & |
                            ' JOIN sys.schemas s ON o.schema_id = s.schema_id<13,10>' & |
                            'WHERE o.name LIKE ''%'' + @OldTableName + ''%''<13,10>' & |
                            '  AND o.parent_object_id = OBJECT_ID(QUOTENAME(s.name) + ''.'' + QUOTENAME(@NewTableName));<13,10>' & |
                            'OPEN cur_constraints;<13,10>' & |
                            'FETCH NEXT FROM cur_constraints INTO @name, @schema, @type;<13,10>' & |
                            'WHILE @@FETCH_STATUS = 0 <13,10>' & |
                            'BEGIN<13,10>' & |
                            '    SET @newname = REPLACE(@name, @OldTableName, @NewTableName);<13,10>' & |
                            '    SET @fullOldName = QUOTENAME(@schema) + ''.'' + QUOTENAME(@name);<13,10>' & |
                            '    IF @type LIKE ''%INDEX%''<13,10>' & |
                            '        SET @sql = ''EXEC sp_rename '''''' + @fullOldName + '''''', '''''' + @newname + '''''', ''''INDEX'''';'';<13,10>' & |
                            '    ELSE<13,10>' & |
                            '        SET @sql = ''EXEC sp_rename '''''' + @fullOldName + '''''', '''''' + @newname + '''''', ''''OBJECT'''';'';<13,10>' & |
                            '    EXEC sp_executesql @sql;<13,10>' & |
                            '    FETCH NEXT FROM cur_constraints INTO @name, @schema, @type;<13,10>' & |
                            'END <13,10>' & |
                            'CLOSE cur_constraints;<13,10>' & |
                            'DEALLOCATE cur_constraints;<13,10>' & |    !---
                            'DECLARE cur_indexes CURSOR FOR <13,10>' & |
                            'SELECT<13,10>' & |
                            '    i.name,<13,10>' & |
                            '    s.name AS schema_name,<13,10>' & |
                            '    t.name AS table_name<13,10>' & |
                            'FROM sys.indexes i<13,10>' & |
                            'JOIN sys.tables t ON i.object_id = t.object_id<13,10>' & |
                            'JOIN sys.schemas s ON t.schema_id = s.schema_id<13,10>' & |
                            'WHERE t.name = @NewTableName<13,10>' & |
                            '  AND i.name IS NOT NULL<13,10>' & |
                            '  AND i.name LIKE ''%'' + @OldTableName + ''%''<13,10>' & |
                            '  AND i.index_id > 0;<13,10>' & |
                            'OPEN cur_indexes;<13,10>' & |
                            'FETCH NEXT FROM cur_indexes INTO @name, @schema, @type;<13,10>' & |
                            'WHILE @@FETCH_STATUS = 0<13,10>' & |
                            'BEGIN<13,10>' & |
                            '    SET @newname = REPLACE(@name, @OldTableName, @NewTableName);<13,10>' & |
                            '    SET @fullOldName = QUOTENAME(@NewTableName) + ''.'' + QUOTENAME(@name);<13,10>' & |
                            '    SET @sql = ''EXEC sp_rename '''''' + @fullOldName + '''''', '''''' + @newname + '''''', ''''INDEX'''';'';<13,10>' & |
                            '    EXEC sp_executesql @sql;<13,10>' & |
                            '    FETCH NEXT FROM cur_indexes INTO @name, @schema, @type; <13,10>' & |
                            'END<13,10>' & |
                            'CLOSE cur_indexes;<13,10>' & |
                            'DEALLOCATE cur_indexes;<13,10>' & |
                            '')
      cmd.Append(self.SqlCode)
      If self._ExecuteSqlNoParms() = driver:ok
      End
    End
  End
  self.SqlCode.SetValue(cmd)
  Return

!-----------------------------------------------------------------
! Record Access Methods
!-----------------------------------------------------------------
DriverFileMSSQL2Class.ADD              PROCEDURE()
result  long,Auto
  Code
  If self.CheckConnect() = driver:notok then Return.
  ! Parent MUST be called first for ADD. Abort if Errorcode set.
  parent.Add()
  If Errorcode() then Return.
  self._PrepareAdd(Opcode:Add)
  If self.Stmt_Add
    self._ExecuteSqlToRecord(self.Stmt_Add,self._GetBuffer,self._AddColsCache)
  End
  self._AfterWrite(opcode:Add)
  Return

!-----------------------------------------------------------------
! similar to an ADD, but does not get returning values, so is a touch faster.
! Useful for doing Bulk adds, where the Auto-numbered fields are not required.
DriverFileMSSQL2Class.APPEND              PROCEDURE()
result  long,Auto
  Code
  If self.CheckConnect() = driver:notok then Return.
  parent.Append()
  If Errorcode() then Return.
  self.SetError(NoError)
  self._PrepareAdd(Opcode:APPEND)
  If self.Stmt_Append
    self._ExecuteSqlToRecord(self.Stmt_Append,driver:nobuffer,self._AppendColsCache)
  End
  self._AfterWrite(opcode:Append)
  Return

!-----------------------------------------------------------------
DriverFileMSSQL2Class.DELETE           PROCEDURE()
result  long,Auto
  Code
  If self.CheckConnect() = driver:notok then Return.
  ! Parent MUST be called first for DELETE. Abort if Errorcode set.
  parent.Delete()
  If Errorcode() = NoError
    If self._PrepareDelete() = driver:ok and Errorcode() = NoError
      If self.stmt_Delete
        self._ExecuteSqlToRecord(self.Stmt_Delete,driver:nobuffer,self._DeleteColsCache)
      End
    End
  End
  self._AfterWrite(opcode:Delete)
  Return

!-----------------------------------------------------------------
DriverFileMSSQL2Class.DELETE           PROCEDURE(String pFilter)
stmt    Long
  Code
  ! Parent MUST be called first for DELETE. Abort if Errorcode set.
  If self.CheckConnect() = driver:notok then Return.
  self._ParameterOpcode = Opcode:DELETE
  parent.Delete(pFilter)
  If Errorcode() = NoError
    stmt = self._PrepareDelete(pFilter)
    If stmt and Errorcode() = NoError
      self._ExecuteSqlToRecord(stmt,driver:nobuffer,self._StmtCols)
      If self.Affected = 0
        self.SetError(NoRecErr)
      End
    End
  End
  self._AfterWrite(opcode:Delete)
  Return

!-----------------------------------------------------------------
! necessary to have this method, here because don't want to put BeforeRead into parent class.
DriverFileMSSQL2Class.NEXT         PROCEDURE()
  Code
  Self._BeforeRead(Opcode:Next)
  If Errorcode() then Return.
  Parent.Next()
  Return

!-----------------------------------------------------------------
! necessary to have this method, here because don't want to put BeforeRead into parent class.
DriverFileMSSQL2Class.PREVIOUS         PROCEDURE()
  Code
  Self._BeforeRead(Opcode:PREVIOUS)
  If Errorcode() then Return.
  Parent.Previous()
  Return

!-----------------------------------------------------------------
! The SQL Update statement primes the WHERE part of the statement using the self.PrimaryKeyPosition.
! The PrimaryKeyPosition property is populated after each READ of the file (GET, REGET, PREVIOUS, NEXT).
DriverFileMSSQL2Class.PUT              PROCEDURE()
stmt    long,auto
result  long,auto
  Code
  If self.CheckConnect() = driver:notok then Return.
  Parent.Put() ! Parent MUST be called before writing the record. Abort if Errorcode set.
  If Errorcode() then Return.
  stmt = self._PreparePut()
  If stmt
    self._ExecuteSqlToRecord(stmt,driver:buffer,self._PutColsCache)
  End
  self._AfterWrite(opcode:Put)
  Return

!-----------------------------------------------------------------
! the SEARCH procedure CREATES the Stred procedure, but des not execute it. That is done by the _NextPrev.
! This means all properties affecting the SELECT must be done prior to the call to SEARCH.
! the optional fields are not used at the moment
DriverFileMSSQL2Class.SEARCH                     Procedure(String pSearchString,<*? pField1>, <*? pField2>, <*? pField3>, <*? pField4>, <*? pField5>, <*? pField6>, <*? pField7>, <*? pField8>, <*? pField9>, <*? pField10>,<*? pField11>, <*? pField12>, <*? pField13>, <*? pField14>, <*? pField15>)
TableName     Cstring(255),Auto
SearchString  cString(255),Auto
fields        StringTheory
join          StringTheory
x             Long,Auto
result        Long,Auto
  code
  If self.CheckConnect() = driver:notok then Return.
  If pSearchString = ''
    self._SearchJoin = ''
    self.SearchFilter = ''
    self._SearchOrderClause = ''
    Return
  End
  ! _ValidateSearchTable checks that FullText is installed, that a fulltext catalog exists, and that a full text index on this table is created.
  If self._ValidateSearchTable() = Driver:ok
    TableName = self._sanitize(self.FullPathName,driver:sqlTable)
    ! This is done after the SET. So Project fields list is already in play.
    ! If not already there then add the fts.rank field.
    If self._ProjectClauses &= null
      self._ProjectClauses &= new StringTheory
    End
    If self._ProjectClauses.Instring('fts.rank') = 0
      self._ProjectClauses.append('fts.rank',,',')
    End

    ! construct the ON clause for the join, based on primary key fields.
    If self._WithPrimaryKey() = Driver:ok
      Loop x = 1 to self.keys.components
        If self._WithField(self.keys.component[x]) = Driver:ok
          Join.Append(self._GetAlias(driver:withdot) & self.fields.Column & ' = fts.[KEY]' ,, ',')
        End
      End
    End

    !If the fields are passed in as parameters then we can use those.
    !Else scan across all the string, and (text) memo and blobs.
    Loop x = 1 to self.SharedProperties.FieldList.nodes
      If self._WithField(x) = Driver:ok
        If self.fields.Binary then cycle.
        If self.Fields.UUID then cycle.
        If not self.fields.Interface &= null then cycle.
        If self.fields.SqlTimeStamp then cycle. !>= driver:GroupOverTimeStamp and self.fields.SqlTimeStamp <= driver:GroupOverTimeStampTZ then cycle.
        If self.fields.over then cycle.
        Case self.fields.Type
        of ClaCSTRING
        orof ClaPSTRING
        orof ClaSTRING
          Fields.append(self.fields.Column,,',')
        End
      End
    End
    Loop x = 1 to Records(self.blobs)
      Get(self.blobs,x)
      If self.Blobs.Binary then cycle.
      Fields.Append(self.blobs.Column,st:NoClip,',')
    End

    ! so the token string is stored in Prop:Search. This allows it to be expanded later on to populate the parameters in _SelectSQL
    self._SearchExpression = self.TranslateSearch(pSearchString)  ! returns a single token for the search expression as a single parameter

    ! now expand it, because the expanded form goes into the _SearchJoin
    SearchString = self._ExpandExpression(self._SearchExpression)  ! ? or ?1 or whatever is appropriate for this driver.

    ! join between the main table and the search table
    !!!todo WIP here. In this case the SearchString has to be a simple text term, not an expression. An expression would need to be sanitised before use here.
    self._SearchJoin = ' INNER JOIN CONTAINSTABLE(' & TableName & ', (' & fields.GetValue() & '), ' & SearchString & ') fts ON ' & join.GetValue()
    self.SearchFilter = ''                          ! unlike SQLite the searchterm is not used in a FILTER so SEARCHFILTER is always blank in MSSQL
    self._SearchOrderClause = 'fts.rank'            ! becomes the first field when doing a BuildOrderBy
    self._SearchRankType = ClaLong                  ! In MSSQL the rank result is a LONG, not a REAL etc

    ! now expand it again, but this time without substituting the Values for Parameters.
    self._ParseContext = driver:searchtext
    SearchString = self._ExpandExpression(self._SearchExpression)
    self._ParseContext = 0
    self.SetProp:Search(SearchString)              ! sets self.search

    self.BindField('fts.rank',self.SearchRank)
    self._JustSetSearch = true
  End
  Return

!-----------------------------------------------------------------
! words reserved by MSSQL so cannot be used as column names.
DriverFileMSSQL2Class.TranslateReserved       PROCEDURE(*cstring pColumn)
  code
  If len(pColumn) = 0 then return ''.
  If pColumn[1] = '"'                         ! might have been set with a leading " in the dict. If so remove, and replace.
    Return self.WrapReserved(pColumn)
  End
  case upper(pColumn)
  of 'ABORT' orof 'ACTION' orof 'ADD' orof 'AFTER' orof 'ALL' orof 'ALTER' orof 'ALWAYS' orof 'ANALYZE' orof 'AND' orof 'AS' orof 'ASC'
  orof 'ATTACH' orof 'AUTOINCREMENT' orof 'BEFORE' orof 'BEGIN' orof 'BETWEEN' orof 'BY' orof 'CASCADE' orof 'CASE' orof 'CAST' orof 'CHECK'
  orof 'COLLATE' orof 'COLUMN' orof 'COMMIT' orof 'CONFLICT' orof 'CONSTRAINT' orof 'CREATE' orof 'CROSS' orof 'CURRENT' orof 'CURRENT_DATE'
  orof 'CURRENT_TIME' orof 'CURRENT_TIMESTAMP' orof 'DATABASE' orof 'DEFAULT' orof 'DEFERRABLE' orof 'DEFERRED' orof 'DELETE' orof 'DESC'
  orof 'DETACH' orof 'DISTINCT' orof 'DO' orof 'DROP' orof 'EACH' orof 'ELSE' orof 'END' orof 'ESCAPE' orof 'EXCEPT' orof 'EXCLUDE'
  orof 'EXCLUSIVE' orof 'EXISTS' orof 'EXPLAIN' orof 'FAIL' orof 'FILTER' orof 'FIRST' orof 'FOLLOWING' orof 'FOR' orof 'FOREIGN' orof 'FROM'
  orof 'FULL' orof 'GENERATED' orof 'GLOB' orof 'GROUP' orof 'GROUPS' orof 'HAVING' orof 'IF' orof 'IGNORE' orof 'IMMEDIATE' orof 'IN'
  orof 'INDEX' orof 'INDEXED' orof 'INITIALLY' orof 'INNER' orof 'INSERT' orof 'INSTEAD' orof 'INTERSECT' orof 'INTO' orof 'IS' orof 'ISNULL'
  orof 'JOIN' orof 'KEY' orof 'LAST' orof 'LEFT' orof 'LIKE' orof 'LIMIT' orof 'MATCH' orof 'MATERIALIZED' orof 'NATURAL' orof 'NO' orof 'NOT'
  orof 'NOTHING' orof 'NOTNULL' orof 'NULL' orof 'NULLS' orof 'OF' orof 'OFFSET' orof 'ON' orof 'OR' orof 'ORDER' orof 'OTHERS' orof 'OUTER'
  orof 'OVER' orof 'PARTITION' orof 'PLAN' orof 'PRAGMA' orof 'PRECEDING' orof 'PRIMARY' orof 'QUERY' orof 'RAISE' orof 'RANGE' orof 'RECURSIVE'
  orof 'REFERENCES' orof 'REGEXP' orof 'REINDEX' orof 'RELEASE' orof 'RENAME' orof 'REPLACE' orof 'RESTRICT' orof 'RETURNING' orof 'RIGHT'
  orof 'ROLLBACK' orof 'ROW' orof 'ROWS' orof 'SAVEPOINT' orof 'SELECT' orof 'SET' orof 'TABLE' orof 'TEMP' orof 'TEMPORARY' orof 'THEN' orof 'TIES'
  orof 'TO' orof 'TRANSACTION' orof 'TRIGGER' orof 'UNBOUNDED' orof 'UNION' orof 'UNIQUE' orof 'UPDATE' orof 'USING' orof 'VACUUM' orof 'VALUES'
  orof 'VIEW' orof 'VIRTUAL' orof 'WHEN' orof 'WHERE' orof 'WINDOW' orof 'WITH' orof 'WITHOUT'
    Return self.WrapReserved(pColumn)
  Else
    Return pColumn
  End

!-----------------------------------------------------------------
!!! DERIVE if necessary
DriverFileMSSQL2Class.TranslateCondition Procedure(*cstring pCondition)
  code
  case self._ParseContext
  of driver:searchfilter
  orof driver:searchtext
    If pCondition = 'NOT'
      Return 'AND NOT'
    End
  End
  Return pCondition

!-----------------------------------------------------------------
! For MSSQL, the Full Text Search is done with the help of a catalog. This method makes sure the catalog and appropriate index exists.
DriverFileMSSQL2Class._ValidateSearchTable  Procedure()
IsNull Byte,Auto
Ans    Long,Auto
result Long,Auto
  code
  self.SqlCode.SetValue('SELECT OBJECTPROPERTY(OBJECT_ID(''' & self._sanitize(self.FullPathName,driver:sqlTable) & '''), ' & |
                        '''TableHasActiveFulltextIndex'') AS HasFullTextIndex')
  result = self._ExecuteSqlNoParms(self.Result)
  If Errorcode() = NoError
    If self.result.Rows()
      ans = self.Result.GetCell(1,1,IsNull)
      If IsNull ! Table name does not exist in database
        self.SetError(NoFileErr)
        Return Driver:notok
      End
      If self.result.Rows() > 0 and ans > 0  ! index already exists
        Return Driver:ok
      Else
        return self._CreateFTS()
      End
    End
  End
  Return Driver:notok

!-----------------------------------------------------------------
! Prepare the database for full text search capabilities. This activates on a table the first time SEARCH is called on that table.
DriverFileMSSQL2Class._CreateFTS  Procedure()
result        Long,Auto
status        Long,Auto
catalogname   Cstring(255),Auto
tablename     Cstring(255),Auto
pkName        Cstring(255),Auto
Fields        StringTheory
cmd           StringTheory
x             Long,Auto
Ans           String(5),Auto
  code
  ! first make sure that full-text is enabled
  self.SqlCode.SetValue('SELECT CAST(DATABASEPROPERTYEX(''' & self.GetPROP:Database() & ''', ''IsFulltextEnabled'') AS INT);')
  cmd.Append(self.SqlCode)
  result = self._ExecuteSqlNoParms(self.Result)
  If result = driver:notok
    return Driver:notok
  End
  If self.result.Rows() = 0
    return Driver:notok
  End

  ans = self.Result.GetCell(1,1)
  If Ans = 0
    ! need to handle full text not being installed. This isn't it...

!    self.SqlCode.SetValue('ALTER DATABASE ' & self.GetPROP:Database() & ' SET ENABLE_BROKER;')  ! this could take some time.
!    cmd.Append(self.SqlCode)
!    result = self._ExecuteSqlNoParms()
!    If result = driver:notok
!      self.SqlCode.SetValue(cmd)
!      Return Driver:notok
!    End
  End

  ! Create a full text catalog
  tablename = self._sanitize(self.FullPathName,driver:sqlTable)
  catalogname = tablename  & '_catalog'

  self.SqlCode.SetValue( |
    'IF NOT EXISTS (SELECT * FROM sys.fulltext_catalogs WHERE name = ''' & catalogname & ''')' & |
    ' BEGIN' & |
    ' CREATE FULLTEXT CATALOG ' & catalogname & |
    ' END')
  cmd.Append(self.SqlCode)
  result = self._ExecuteSqlNoParms()
  If result = driver:notok
    self.SqlCode.SetValue(cmd)
    Return Driver:notok
  End

  ! Get the name of the Primary Key
  self.SqlCode.SetValue( |
    ' SELECT CONSTRAINT_NAME AS PrimaryKeyName' & |
    ' FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS' & |
    ' WHERE TABLE_NAME = ''' & tablename & '''' & |
    ' AND CONSTRAINT_TYPE = ''PRIMARY KEY''')
  cmd.Append(self.SqlCode)
  result = self._ExecuteSqlNoParms(self.Result)
  If result = driver:notok
    self.SqlCode.SetValue(cmd)
    return Driver:notok
  end
  If self.result.Rows() = 0
    self.SqlCode.SetValue(cmd)
    return Driver:notok
  end
  pkName = self.Result.GetCell(1,1)

  Loop x = 1 to self.SharedProperties.FieldList.nodes
    If self._WithField(x) = Driver:ok
      If self.fields.Binary then cycle.
      If self.Fields.UUID then cycle.
      If not self.fields.Interface &= null then cycle.
      If self.fields.SqlTimeStamp then cycle.
      If self.fields.over then cycle.
      Case self.fields.Type
      of ClaCSTRING
      orof ClaPSTRING
      orof ClaSTRING
        Fields.append(self.fields.Column,,',')
      End
    End
  End
  Loop x = 1 to Records(self.blobs)
    get(self.blobs,x)
    If self.Blobs.Binary then cycle.
    Fields.Append(self.blobs.Column,st:NoClip,',')
  End

  ! create the index
  self.SqlCode.SetValue( |
    'CREATE FULLTEXT INDEX ON ' & tablename & |
    '(' & Fields.GetValue() &|
    ')' & |
    ' KEY INDEX ' & pkName & |
    ' ON ' & catalogname)
  cmd.Append(self.SqlCode)

  result = self._ExecuteSqlNoParms()
  If result = driver:notok
    self.SqlCode.SetValue(cmd)
    return Driver:notok
  end

  Loop 10 times ! maximum of 10 second delay
    self.SqlCode.SetValue('SELECT OBJECTPROPERTYEX(OBJECT_ID(''' & tablename & '''), ''TableFullTextPopulateStatus'')')
    result = self._ExecuteSqlNoParms()
    If self.result.Rows() = 0
      Return Driver:notok
    End
    status = self.Result.GetCell(1,1)
    Case status
    of 0 ! IDLE
      Break
    of 1 ! Full population In Progress
    of 2 ! Incremental Population In Progress
    of 3 ! Propagation In Progress
    of 4 ! Backgroup update index in progress
    of 5 ! Throttled or paused
    of 6 ! Error
      Break
    End
    osSleep(1000)
  End

  self.SqlCode.SetValue(cmd)
  Return Driver:ok

!-----------------------------------------------------------------
! Called for all forms of set by the parent call
! clears any existing SET statement, and also prepares the new SELECT statement.
DriverFileMSSQL2Class._SET              PROCEDURE(Byte pSetMethod, BigInt pPointer,Key pSetKey, Key pSetKeyKey)
result  long
  Code
  If self.CheckConnect() = driver:notok then Return.
  If self.Stmt_Set
    self._FreeStmt(self.Stmt_Set)
    self.Stmt_Set = 0
    self._ClearParameterQueue(Opcode:SET)
  End
  parent._Set(pSetMethod,pPointer,pSetKey,pSetKeyKey)
  Return

!-----------------------------------------------------------------
DriverFileMSSQL2Class.UPSERT           Procedure()
x        Long,Auto
result   Long,Auto
rType    Long,Auto
rAddress BIGINT,Auto
rLength  BIGINT,Auto
  Code
  If self.CheckConnect() = driver:notok then Return.
  ! Parent MUST be called first for UPSERT. Abort if Errorcode set.
  parent.Upsert()
  If Errorcode() then Return.
  self._PrepareAdd(Opcode:Upsert)
  If self.Stmt_Upsert
    self._ExecuteSqlToRecord(self.Stmt_Upsert,self._GetBuffer,self._UpsertColsCache)
  End
  self._AfterWrite(Opcode:Upsert)
  Return

!-----------------------------------------------------------------
DriverFileMSSQL2Class.ResultToExplain  Procedure(iResultSet pResult)
x long
  Code
  parent.ResultToExplain(pResult)
  If self._logExplain
    self.Log('[EXPN]-- EXPLAINING: ----------------------------------------------')
    self.Log('[EXPN]' & self.SqlCode.After('PLAN'))
    self.Log('[EXPN]- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -')
    self.Log('[EXPN]-- ID | Parent | Description')
    loop x = 1 to pResult.Rows()
      self.Log('[EXPN]-- ' & format(pResult.GetCell(x,1),@n02) & ' | ' & format(pResult.GetCell(x,2),@s6) & ' | ' & pResult.GetCell(x,4))
    End
    self.Log('[EXPN]-------------------------------------------------------------')
  End
  If (self.Explain or self.opt:explain) and self._LogFile <> ''
    self.Trace('-- EXPLAINING: ----------------------------------------------')
    self.Trace(self.SqlCode.After('PLAN'))
    self.Trace('- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -')
    self.Trace('-- ID | Parent | Description')
    loop x = 1 to pResult.Rows()
      self.Trace('-- ' & format(pResult.GetCell(x,1),@n02) & ' | ' & format(pResult.GetCell(x,2),@s6) & ' | ' & pResult.GetCell(x,4))
    End
    self.Trace('-------------------------------------------------------------')
  End
  Return

!-----------------------------------------------------------------
DriverFileMSSQL2Class.TranslateOperatorConcat            Procedure()
  code
  Return ' + '

!-----------------------------------------------------------------
! if pLabelType is driver:field, then the self.fields group is loaded with the field that this DATE() call is being compared *to*
!!!todo, this assumes it's a prop:filter, not a prop:order or prop:project.
DriverFileMSSQL2Class._TranslateDateSql  Procedure(*CString pField,String pMonth, String pDay, String pYear, Byte pLabelType,*Cstring pCond)
  code
  If pLabelType <> driver:field or self.Fields.Type = ClaDATE
    If Numeric(pMonth) = false or numeric(pDay) = false or numeric(pYear) = false
      Return 'DATEFROMPARTS(' & clip(pYear) & ',' & clip(pMonth) & ',' & clip(pDay) & ')'
    Else
      Return '''' & self.FormatDate(pMonth,pDay,pYear) & ''''
    End
  End
  If self.Fields.Type = ClaLONG
    If Numeric(pMonth) = false or numeric(pDay) = false or numeric(pYear) = false
      Return 'DATEFIFF(DAY,''1800-12-28'',DATEFROMPARTS(' & clip(pYear) & ',' & clip(pMonth) & ',' & clip(pDay) & '))'
    Else
      Return Date(pMonth,pDay,pYear)
    End
  End
  Return ''

!-----------------------------------------------------------------
DriverFileMSSQL2Class._TranslateLabelOverDateSQL Procedure(FieldGroupType pNode)
  code
  Return 'CAST(' & self._GetAlias(driver:withdot) & pNode.Column & ' AS DATE)'

!-----------------------------------------------------------------
DriverFileMSSQL2Class._TranslateLabelOverTimeSQL Procedure(FieldGroupType pNode)
  code
  Return 'TIME(' & self._GetAlias(driver:withdot) &  pNode.Column & ')'

!-----------------------------------------------------------------
!  as in DAY(date) or MONTH(date) or YEAR(date)
!  date is either a DATE field in the database, a LONG field in the database
DriverFileMSSQL2Class._TranslateDatePartSQL   Procedure(*CString pField,String pPart)
node  &FieldGroupType,Auto
  code
  If self.fields.type = ClaDate and self.fields.InOverGroup and self.fields.InOverGroup = self.fields.Index - 1 ! handle DATE part of DATE/TIME over TIMESTAMP
    node &= self._WithFieldNode(self.fields.InOverGroup)
    node &= self._WithFieldNode(node.over)
    If node.SqlTimeStamp
      Return pPart & '(' & self._GetAlias(driver:withdot) & node.Column &')'
    End
  ElsIf self.fields.type = ClaDate or self.fields.SqlTimeStamp = driver:GroupOverTimeStamp
    ! If pDay is a DATE column in the database then return the DAY/MONTH/YEAR NUMBER of the value in that date column
    Return pPart & '(' &  pField & ')'
  Else
    ! It's not a DATE column, so stored as a Clarion Stadard Date Number (LONG or bigger). Convert the Clarion number
    ! to a date, then return the DAY/MONTH/YEAR NUMBER of that date
    Return pPart & '(DATEADD(DAY, ' & pField & ', ''18001228'')) '
  End
  Return ''

!-----------------------------------------------------------------
DriverFileMSSQL2Class._TranslateDaySQL   Procedure(*CString pField)
  code
  Return self._TranslateDatePartSQL(pField,'DAY')

!-----------------------------------------------------------------
DriverFileMSSQL2Class._TranslateMonthSQL   Procedure(*CString pField)
  code
  Return self._TranslateDatePartSQL(pField,'MONTH')

!-----------------------------------------------------------------
DriverFileMSSQL2Class._TranslateYearSQL   Procedure(*CString pField)
  code
  Return self._TranslateDatePartSQL(pField,'YEAR')

!-----------------------------------------------------------------
DriverFileMSSQL2Class.TranslateRegularExpression Procedure(*CString pExpr,*CString pColumn)
  code
  !!!todo - Translate RegEx code goes here
  Return ''

!-----------------------------------------------------------------
DriverFileMSSQL2Class.CreateDB      PROCEDURE(String pDatabaseName, String pOptions)
result    Long
stmt      Long
namewas   String(255)
  code
  parent.CreateDB(pDatabaseName,pOptions)             ! file must be closed
  If self.SwitchToMaster('database=','master',';',NameWas) = driver:ok
    If self._GetEnvironmentHandle(0) <> Driver:ok
      Return
    End
    If pDatabaseName
      self.SqlCode.SetValue('CREATE DATABASE ' & clip(pDatabaseName))
    Else
      self.SqlCode.SetValue('CREATE DATABASE ' & clip(namewas) )
    End
    !If self.CollationDB = '' then self.collationDB = ' Latin1_General_100_CI_AS_SC' .   ! really not sure if I want to set this default.
    If self.CollationDB
      self.SqlCode.Append('COLLATE ' & self.CollationDB & ' ')
    End
    self.SqlCode.Append(pOptions & ';')

    stmt = self._Prepare()        ! bypassing _ExecuteSQL here as don't want to do another CheckConnect
    If stmt
      result = self._ExecuteSqlWork(stmt)
    End
  End
  self.SwitchBack()
  Return

!-----------------------------------------------------------------
DriverFileMSSQL2Class.GETPROP:Arrays         PROCEDURE()
  Code
  Return '1'


!-----------------------------------------------------------------
DriverFileMSSQL2Class.GetProp:Hdbc           PROCEDURE()!,STRING,VIRTUAL
  code
  Return self.dbHandle

!-----------------------------------------------------------------
! Get name of database, like PostgreSQL or whatever
! MSSQL is a bit unusual because it's not directly linked to the driver, it goes via ODBC
DriverFileMSSQL2Class.GetPROP:DatabaseName   PROCEDURE()
result  long,Auto
outlen  short,Auto
ans     Cstring(256)
  Code
  result = SQLGetInfo(self.dbHandle, SQL_DBMS_NAME,  address(ans), size(ans), outLen);
  Return ans

!-----------------------------------------------------------------
DriverFileMSSQL2Class.GETPROP:Driver         PROCEDURE()  ! Get the clarion name of the driver
  code
  Return 'MSSQL2'

!-----------------------------------------------------------------
DriverFileMSSQL2Class.GETPROP:DriverVersion  PROCEDURE()
  code
  Return driver:version

!-----------------------------------------------------------------
DriverFileMSSQL2Class.GetProp:TransactionStatus  Procedure()
tstatus  Long  ,Auto
result   Long  ,Auto
  code
  result = SQLGetConnectAttr(self.dbhandle, SQL_ATTR_AUTOCOMMIT, address(tstatus), 0, 0);
  Case tstatus
  Of SQL_AUTOCOMMIT_OFF
    Return driver:TransactionOn
  Else
    Return driver:TransactionOff
  End

!!-----------------------------------------------------------------
!================================================================================================
!================================================================================================
!================================================================================================
!-----------------------------------------------------------------
!============================================================================================================

!-----------------------------------------------------------------
! If the View is in paging mode, then in order to find the next page, all the order values need to be in the filter.
! uses self.OrderQueue and prop:where as input, self.wherePage as output
! this sets parameters.
! if GroupBy exists, then all key fields in Grouped tables do not apply.
DriverViewMSSQL2Class._AddOrderToWhere  Procedure(*Long pCount)
x         Long                 ,Auto
obj1      &DriverFileSQLClass ! ,Auto
obj       &DriverFileSQLClass  !,Auto
con       Cstring(3)
where     StringTheory
orc       StringTheory
alias     Cstring(DRIVER:MAXALIASLENGTH)
nocase    Cstring(20)
first     Byte
thisparm  cstring(7)
recs      long,auto
  code
  !self.trace('DriverViewMSSQL2Class._AddOrderToWhere')
  obj1 &= (self.FileObject[1])
  if obj1 &= null then return.
  recs = Records(self.OrderQueue)
  Loop x = 1 to recs
    Get(Self.OrderQueue,x)
    If self.OrderQueue.fixed then cycle.
    If self.OrderQueue.FileIndex
      obj &= (self.FileObject[self.OrderQueue.FileIndex])
      if obj &= null
        alias = ''
      else
        alias = self.GetPROP:Alias(self.OrderQueue.FileIndex)
      end
      !If not self.GroupBy &= null and self.GroupBy <> '' and x > 1  ! if groupby exists then only paging on primary file allowed
      !  Break
      !End
    Else
      ! doesn't have a file, much less a field.
      obj &= null
      alias = ''
    End
    ! set operator
    If self._setdirection = Opcode:Next
      If self.OrderQueue.Direction = driver:Descending then con = '<' Else con = '>'.
    Elsif self._setdirection = Opcode:Previous
      If self.OrderQueue.Direction = driver:Descending then con = '>' Else con = '<'.
    End
    If x = recs
      con = con & '='
    End
    If obj &= null  ! the parameter is not a file field
      self._ParameterCount += 1
      thisparm = obj1._genparm(self._ParameterCount)
      If first = false
        where.append('(' & self.OrderQueue.Clause & ' ' & con & ' ' &  thisparm  & ')')
        first = true
      Else
        where.append(' OR (' & self._reparm(orc,self._ParameterCount))
        where.append(' AND ' &  self.OrderQueue.Clause & ' ' & con & ' ' &  thisparm  & ')')
      End
      self._pagingfieldsadded += 1
      orc.append(self.OrderQueue.Clause & ' = @<<{{' & self._ParameterCount & '}>@' ,st:noclip,' AND ')
      self.ParameterFileIndex[self._ParameterCount] = 1
      !self._SearchParameter = self._ParameterCount
    ElsIf obj._WithField(self.OrderQueue.FieldIndex) = driver:ok
      nocase = ''
      obj._ParameterOpcode = Opcode:SET
      If first = false
        self._ParameterCount += 1
        obj._SetParameterNode(self._ParameterCount,obj.fields,driver:FromShadow,0)
        where.append('(' & alias  & '.' & obj.Fields.Column & ' ' & con & ' ' & obj._genparm(self._ParameterCount) & nocase & ')')
        first = true
        self.ParameterFileIndex[self._ParameterCount] = self.OrderQueue.FileIndex
      Else
        where.append(' OR (' & self._reparm(orc,self._ParameterCount))
        self._ParameterCount += 1
        obj._SetParameterNode(self._ParameterCount,obj.fields,driver:FromShadow,0)
        where.append(' AND ' &  alias & '.' & obj.Fields.Column & ' ' & con & ' ' & obj._genparm(self._ParameterCount) & nocase & ')')
        self.ParameterFileIndex[self._ParameterCount] = self.OrderQueue.FileIndex
      End
      self._pagingfieldsadded += 1
      orc.append(alias  & '.' & obj.Fields.Column & ' = @<<{{' & self._ParameterCount & '}>@' ,st:noclip,' AND ')
    End
  End
  If not self.Where &= Null and self.Where <> ''                                 ! self.filter and self.sqlfilter
    If where.Length()                                                            ! order fields constructed above
      where.SetValue('(' & self.Where & ') AND (' & where.GetValue() & ')')      ! AND the two parts together.
    else
      where.SetValue(self.Where)                                                ! or just move the filter into where
    End                                                                          ! which is then used below.
  End
  self.SetProp:WherePage(where.GetValue())
  Return

!-----------------------------------------------------------------
! loop through all the files in the file, and for their objects, call BindParameters.
DriverViewMSSQL2Class._BindParameters  Procedure(Long pStmt)
x         Long,Auto
Result    Long,Auto
obj       &DriverFileMSSQL2Class
Slip      Long
  code
  !self.trace('DriverViewMSSQL2Class._BindParameters self.Files=' & self.Files)
  Loop x = 1 to self.Files
    obj &= (self.FileObject[x])
    If obj &= null
      !If self._SearchParameter
      !  If self._logBind then self.Log('[BIND][vbp1]' & self._SearchParameter & ' (real)' & self.SearchRank).
      !  result = SQLBindParameter(pStmt,self._SearchParameter, SQL_PARAM_INPUT, SQL_C_DOUBLE, SQL_DOUBLE, SQL_IGNORED, SQL_IGNORED, Address(self.SearchRank), SQL_IGNORED, self._SearchParameterSlip);
      !  If result <> SQL_SUCCESS AND result <> SQL_SUCCESS_WITH_INFO
      !    self.PrimaryFileObject.SetErrorMssql(SQL_HANDLE_STMT,pStmt,'[d041]')
      !  End
      !End
    Else
      !self.trace('DriverViewMSSQL2Class._BindParameters self._ParameterOpcode=' & self._ParameterOpcode)
      obj._ParameterOpcode = self._ParameterOpcode
      If self.ParmBufferX &= Null then self.ParmBufferX &= NEW DriverParmBufferClass.
      If obj._BindParameters(pStmt,self.ParmBufferX,self.codepage) = Driver:ok
      End
    End
  End
  Return Driver:ok

!-----------------------------------------------------------------
DriverViewMSSQL2Class._BindOffset                Procedure()
Result  Long,Auto
  code
  If self._OffsetParmNumber
    If self._logBind then self.Log('[BIND][ves1]' & self._OffsetParmNumber & ' Offset (long) = ' & self._SetOffset).
    self._SetOffsetMem = self._SetOffset
    result = SQLBindParameter(self.Stmt_Set,self._OffsetParmNumber, SQL_PARAM_INPUT, SQL_C_LONG, SQL_INTEGER, SQL_IGNORED, SQL_IGNORED, Address(self._SetOffsetMem), SQL_IGNORED, Self._OffsetParmNumberSlip);
    If result <> SQL_SUCCESS AND result <> SQL_SUCCESS_WITH_INFO
      self.PrimaryFileObject.SetErrorMssql(SQL_HANDLE_STMT,self.Stmt_Set,'[d037]')
    End
    self._SetOffset = 1
  End

!-----------------------------------------------------------------
! self.FileObject is declared as  DriverFileMSSQL2Class so this can't be moved into the parent class
DriverViewMSSQL2Class.CheckConnect    Procedure()
  Code
  self.PrimaryFileObject &= (self.FileObject[1])
  Return self.PrimaryFileObject.CheckConnect()

!-----------------------------------------------------------------
DriverViewMSSQL2Class.Close                     Procedure()
  Code
  self.SetError(NoError)
  If self.Stmt_Set and self.CheckConnect() = driver:ok
    self.PrimaryFileObject._FreeStmt(self.Stmt_Set)
    self.Stmt_Set = 0
  End
  self._ClearParameterQueue(0)
  parent.Close()
  Return

!-----------------------------------------------------------------
! trigger a call to the backend, and put the result set into self.result.
! The "whole" result set is retrieved, no resources are left on the server.
! The "first" NEXT/PREVIOUS command will get it all. (built-in paging applies though.)
DriverViewMSSQL2Class._ExecuteSelect             PROCEDURE()
result   Long ! not ,Auto
Slip      Long
  code
  If Self.Stmt_Set = 0 then Return.
  If self.CheckConnect() = driver:notok then Return.
  !self.trace('DriverViewMSSQL2Class._ExecuteSelect self._OffsetParmNumber=' & self._OffsetParmNumber)
  If self._BindParameters(Self.Stmt_Set) = driver:ok                  ! Bind all the parameters for the files.
    self._BindOffset()
    self.NewResultSet(driver:DontFreeRam)                                  ! Want to do this here, before going to the file object.
    self.PrimaryFileObject.SqlCode.SetValue(self.SqlCode)                  ! for logging
    If self.PrimaryFileObject._ExecuteSqlToResults(Self.Stmt_Set,self.result)    ! Execute statement, and move resultset to Results interface
    End
    result = SQLFreeStmt(self.Stmt_Set, SQL_CLOSE)
    result = SQLFreeStmt(Self.Stmt_Set, SQL_RESET_PARAMS)
  else
     self.trace('DriverViewMSSQL2Class._ExecuteSelect : Bind Parameters not ok')
  End
  parent._ExecuteSelect()
  Return

!-----------------------------------------------------------------
! prepares, binds parameters and executes the SQL in SqlCode.
! SQL is not cached.
! results are set to Results
! returns driver:notok if the SQL part is faulty
DriverViewMSSQL2Class._executeSql procedure()
stmt    Long
result  Long
  code
  If self.CheckConnect() = driver:notok then Return driver:notok.
  stmt = self._Prepare()
  If stmt
    If self._BindParameters(stmt) = Driver:ok
      self.PrimaryFileObject.SqlCode.SetValue(self.SqlCode)  ! for logging
      If self.PrimaryFileObject._ExecuteSqlToResults(stmt,self.result)
      End
    End
    self.PrimaryFileObject._FreeStmt(stmt)
    If self._ParameterOpcode then self._ClearParameterQueue(self._ParameterOpcode).
  Else
    Return driver:notok
  End
  Return driver:ok

!-----------------------------------------------------------------
! must include a trailing space
DriverViewMSSQL2Class.ExplainStart      Procedure()
  Code
  Return 'SET SHOWPLAN_ALL ON; GO; '

!-----------------------------------------------------------------
DriverViewMSSQL2Class._Prepare  Procedure()
result        long,Auto
  Code
  If self.CheckConnect() = driver:notok then return 0 .
  Return self.PrimaryFileObject._prepare(self.SqlCode)


!-----------------------------------------------------------------
DriverViewMSSQL2Class.Search                    Procedure(String pSearchString,<*? pField1>, <*? pField2>, <*? pField3>, <*? pField4>, <*? pField5>, <*? pField6>, <*? pField7>, <*? pField8>, <*? pField9>, <*? pField10>,<*? pField11>, <*? pField12>, <*? pField13>, <*? pField14>, <*? pField15>)
obj              &DriverFileMSSQL2Class,Auto
linkfields       StringTheory
x                Long,Auto
  code
  obj &= (self.FileObject[1])
  If self._withNodeTableName(obj.FullPathName & '_fts') <> driver:ok    ! checks if a node with this table exists.
    If self._withNodeFileIndex(1) = Driver:Ok                 ! for now, VIEW searches are on the Main table.
      If obj._ValidateSearchTable() = Driver:Notok
        Return
      End
      ! add a child to the parent node
      If self.node.children &= NULL                          ! Adding a child, so make sure Children Queue is available
        self.node.children &= new(ViewTreeType)
        Put(self.node)
      End
      Clear(self.node.Children)
      self.node.Children.ParentFile  &= self.node.File
      self.node.Children.TableName   = lower(obj.FullPathName & '_fts')

      self.Files += 1
      self.node.Children.Driver      = self.node.File{prop:driver}
      self.node.Children.Alias       = 'fts'
      !                     join
      self.node.Children.Key         &= null                              ! no key, we need to do fields individually
      self.node.Children.JoinType    = driver:InnerJoin
      self.node.Children.LinkingExpr &= new cstring(100)
      If obj._WithPrimaryKey() = driver:ok
        Loop x = 1 to obj.keys.components
          If obj._WithField(obj.keys.component[x]) = driver:ok
            linkfields.Append(self.GetProp:Alias(1) & '.' & obj.fields.Column &' =  fts.' & obj.fields.Column, ,',')
          End
        End
        self.node.Children.LinkingExpr =  linkfields.GetValue()
      End
      Add(self.node.Children)

    End
    self.ProjectField('bm25(' & obj.FullPathName & '_fts)','rank_fts')
    self.BindField('rank_fts',self.SearchRank)
  End
  self._JustSetSearch = true
  self._SearchOrderClause = 'rank_fts'   ! becomes the first field when doing a BuildOrderBy
  self.SearchFilter = obj.FullPathName & '_fts MATCH ''' & obj.TranslateSearch(pSearchString) & ''''  ! if the SEARCH is a "second call" then just update the filter.
  Return

!-----------------------------------------------------------------
! The syntax for this part is dependent on the SQL engine being used.
! This takes the OrderBy queue as input, and generates the prop:OrderBy as output
! makes use of self._setDirection to determine the OpCode
DriverViewMSSQL2Class.SetOrderByFromQueue            Procedure()
OrderBy      StringTheory
x            Long,Auto
  code
  OrderBy.SetValue('')
  Loop x = 1 to Records(self.OrderQueue)                                                 ! Turn the OrderBy queue into SQL code.
    Get(self.OrderQueue,x)
    OrderBy.Append(self.OrderQueue.Clause,,',')
    !If self.OrderQueue.Nocase
      !OrderBy.Append(' COLLATE NOCASE')
    !End
    If self._setdirection = Opcode:NEXT
      If self.OrderQueue.Direction = driver:Descending
        OrderBy.Append(' DESC')
      Else
        OrderBy.Append(' ASC')
      End
    ElsIf self._setdirection = Opcode:PREVIOUS
      If self.OrderQueue.Direction = driver:Descending
        OrderBy.Append(' ASC')
      Else
        OrderBy.Append(' DESC')
      End
    End
  End
  self.SetProp:OrderBy(OrderBy.GetValue())
  Return

!-----------------------------------------------------------------
DriverViewMSSQL2Class.Set                       Procedure(Long pIndex)
result   long,auto
  Code
  If self.CheckConnect() = driver:notok then Return.
  Parent.Set(pIndex)
  If Errorcode() = NoError
    If self.Stmt_Set
      self.PrimaryFileObject._FreeStmt(self.Stmt_Set)
      self.Stmt_Set = 0
    End
  End
  Return

!-----------------------------------------------------------------
DriverViewMSSQL2Class._Set                       Procedure(Long pOpcode)
result  long
  Code
  If self.CheckConnect() = driver:notok then Return.
  Parent._Set(pOpcode)
  If Errorcode() = NoError
    If self.Stmt_Set
      self.PrimaryFileObject._FreeStmt(self.Stmt_Set)
      self.Stmt_Set = 0
    End
    self.Stmt_Set = self._Prepare()
  End
  Return

!!-----------------------------------------------------------------
!-----------------------------------------------------------------
! TOP is only generate if Offset is blank and Limit > 0
DriverViewMSSQL2Class.TranslateLimitAbove              PROCEDURE(Long pLimit, String pOffset)
  Code
  return ''
!  !self.trace('DriverViewMSSQL2Class.TranslateLimitAbove pLimit = ' & pLimit & ' pOffset=' & pOffset)
!  If pOffset <> '' and pOffset <> '0' then Return ''.
!  If pLimit <= 0 then Return ''.
!  Return 'TOP ' & pLimit & ' '

!-----------------------------------------------------------------
! Clause only generated if OFFSET is set to something.
DriverViewMSSQL2Class.TranslateLimitBelow              PROCEDURE(Long pLimit, String pOffset)
offset   cstring(255)
  Code
  If pLimit = 0 and (pOffset = '' or pOffset ='0')
    Return ''
  End
  offset = pOffset
  If Offset = '' then offset = '0'.
  If pLimit = 0 then clear(pLimit,1).
  Return 'OFFSET ' & Offset & ' ROWS FETCH NEXT ' & pLimit & ' ROWS ONLY'

!-----------------------------------------------------------------
DriverViewMSSQL2Class._GenParm                         PROCEDURE(Long pCount)
  code
  Return '?'

!!-----------------------------------------------------------------
DriverViewMSSQL2Class._reparm                          PROCEDURE(StringTheory pOrc, *Long pCount)
obj     &DriverFileSQLClass
neworc  StringTheory
x       cstring(10)
strt    long
einde   long
p       long
  code
  !self.trace('DriverViewMSSQL2Class._reparm ' & pOrc.GetValue() & ' pCount=' & pCount & ' self._ParameterCount=' & self._ParameterCount)
  newOrc.setValue(pOrc)
  loop
    strt = 0
    einde = 0
    x = newOrc.FindBetween('@<<{{','}>@',strt,einde,false,true)
    if strt = 0 or einde = 0 then break.
    pCount += 1
    obj &= (self.FileObject[self.ParameterFileIndex[x]])
    obj._DuplicateParameter(pCount,x)  ! duplicate parameter x into obj._ParameterCount
    newOrc.ReplaceSlice(strt-3,einde+3, self._genparm(pCount))
  end
  return newOrc.GetValue()

!!-----------------------------------------------------------------
