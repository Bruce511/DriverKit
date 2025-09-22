!------------------------------------------------------------------------------------------------
!   CapeSoft Clarion File Driver Kit classes are copyright © 2025 by CapeSoft                   !
!   Docs online at : https://capesoft.com/docs/Driverkit/ClarionObjectBasedDrivers.htm
!   Released under MIT License
!------------------------------------------------------------------------------------------------

!!!todo export client-side views to server-side views?
!!!todo ResultGet et al support setting PrimaryKeyPosition so can be updated?
!!!todo - check prop:distinct on files, making result set read-only, so not needing to include primary key
!!!todo - make sure prop:project is including primary key values if not in read-only mode.
!!!todo -  Make GlobalOwnerString = '',  then connect through the connection box.. then look at filename{Prop:ConnectString} afterward to see what it made. (Connectionstrings.com)
!!!todo truncated reading of data detected, and set error.

  member()
  map
    Module('Windows')
      osSHGetFolderPath(long pHandle, long pCSIDL, long hToken, long pFlags, *CSTRING szPath),long, raw, pascal, name('SHGetFolderPathA'), dll(1)
    End
    Module('SQLite api')
        sqlite3_open_v2(*cString pFileName,Long pHandleAddress, Long pFlags, Long pVFS),Long,C,Raw,name('sqlite3_open_v2'),dll(1) ! filename in utf-8 format
        sqlite3_close(Long pHandle),Long,C,Proc,dll(1)

        sqlite3_bind_blob    (Long pStmt, Long pParm, Long pAddress, Long pSize,Long pLife),Long,C,Raw,name('sqlite3_bind_blob'),dll(1)
        sqlite3_bind_int     (Long pStmt, Long pParm, Long pValue),Long,C,Raw,name('sqlite3_bind_int'),dll(1)
        sqlite3_bind_double  (Long pStmt, Long pParm, Real pValue),Long,C,Raw,name('sqlite3_bind_double')   ,dll(1)
        sqlite3_bind_null    (Long pStmt, Long pParm),Long,C,Raw,name('sqlite3_bind_null'),dll(1)
        sqlite3_bind_text    (Long pStmt, Long pParm,Long pAddress, Long pSize, Long pLife),Long,C,Raw,name('sqlite3_bind_text'),dll(1)
        sqlite3_bind_textA   (Long pStmt, Long pParm,*String pString, Long pSize, Long pLife),Long,C,Raw,name('sqlite3_bind_text'),dll(1)
        sqlite3_changes      (Long pHandle),long,C,raw,name('sqlite3_changes'),dll(1)
        sqlite3_total_changes(Long pHandle),long,C,raw,name('sqlite3_total_changes'),dll(1)
        sqlite3_step         (Long pStmt),Long,C,Raw,name('sqlite3_step'),dll(1)
        sqlite3_column_count (Long pStmt),Long,C,Raw,name('sqlite3_column_count'),dll(1)
        sqlite3_column_type  (Long pStmt, Long iCol),Long,C,Raw,name('sqlite3_column_type'),dll(1)
        sqlite3_column_name  (Long pStmt, Long iCol),*cstring,C,Raw,name('sqlite3_column_name') ,dll(1)
        sqlite3_column_int   (Long pStmt, Long iCol),long,C,Raw,name('sqlite3_column_int'),dll(1)
        sqlite3_column_double(Long pStmt, Long iCol),real,C,Raw,name('sqlite3_column_double'),dll(1)
        sqlite3_column_text  (Long pStmt, Long iCol),long,C,Raw,name('sqlite3_column_text'),dll(1)
        sqlite3_column_bytes (Long pStmt, Long iCol),long,C,Raw,name('sqlite3_column_bytes'),dll(1)
        sqlite3_column_blob  (Long pStmt, Long iCol),long,C,Raw,name('sqlite3_column_blob'),dll(1)

        sqlite3_prepare_v2   (Long pHandle,Long pSQL,Long pSizeSql, *Long pStmtHandleAddress, *Long pTail),Long,C,Raw,name('sqlite3_prepare_v2'),dll(1)
        sqlite3_reset        (Long pStmt),Long,C,Raw,name('sqlite3_reset'),dll(1)
        sqlite3_clear_bindings(Long pStmt),Long,C,Raw,name('sqlite3_clear_bindings'),dll(1)
        sqlite3_finalize     (Long pStmt),Long,C,Raw,name('sqlite3_finalize'),dll(1)
        sqlite3_wal_checkpoint (Long pHandle, *cString pFileName),Long,Raw,C,name('sqlite3_wal_checkpoint'),dll(1)
        sqlite3_errmsg(Long),*Cstring,C,Raw,name('sqlite3_errmsg'),dll(1)
        sqlite3_extended_result_codes(Long pHandle, Long pOnOff),Long,C,Raw,name('sqlite3_extended_result_codes'),dll(1)
        sqlite3_progress_handler(Long,Long,Long,Long),C,dll(1)
        sqlite3_busy_timeout(Long,Long),Long,C,Proc  ,dll(1)
        sqlite3_next_stmt(Long pHandle, Long pStmt),Long,C,name('sqlite3_next_stmt'),dll(1)
    End
    module('rtl')
      MemCpy(long dest, long src,  unsigned count), long, proc, name('_memcpy'),dll(DLL_Mode)
      MemSet(long dest, long char, unsigned count), long, proc, name('_memset'),dll(DLL_Mode)
    end
  end

  include('SQLite2DriverClass.Inc'),once
  include('StringTheory.inc'),Once
  include('Errors.clw'),once

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
driver:TraceFile       aString       ! file to store tracing in

!=====================================================================================================================
! Threaded, Driver-level object. Shared by all files using this driver on this thread.
ConnectionPoolSQlite2     Class(DriverConnectionPoolClass),Thread
Construct                   Procedure()
                          End

!-----------------------------------------------------------------
ConnectionPoolSQlite2.Construct                 Procedure()
  code
  self.Driver = 'SQLite2'
  Return

!-----------------------------------------------------------------
! In derived classes derive this method with this exact same code, but
! replace the declaration of old with your class name. DO NOT call the parent class.
DriverFileSQLite2Class.ReplaceObject          PROCEDURE(Long pOldObjectAddress)
old    &DriverFileSQLite2Class,Auto
  Code
  If pOldObjectAddress <> 0
    old &= (pOldObjectAddress)
    self :=: old
    dispose(old)
  End
  self.ClaFCB.rblock = address(self)
  Return

!-----------------------------------------------------------------
DriverFileSQLite2Class.Construct  Procedure()
  code
  self.opt:BusyTimeout = 53000   ! 53 seconds
  self._ThisSqlType = 'SQLITE2TYPE'    ! used in dict in extended attributes to identify type settings specific to SQLITE
  self.QuoteString = '"'
  self.AllowParameterRepeats = true
  Return

!-----------------------------------------------------------------
DriverFileSQLite2Class.Destruct  Procedure()
  code
  If self.dbHandle
    self.Disconnect()
  End
  Dispose(self._PutSqlCache)
  Dispose(self.opt:LogFileName)
  Dispose(self.opt:LogMessage)
  Return

!-----------------------------------------------------------------
DriverFileSQLite2Class.InterpretSQLType            Procedure(Long pType)
  Code
  case pType
  of SQLITE_INTEGER
    return 'SQLITE_INTEGER'
  of SQLITE_FLOAT
    return 'SQLITE_FLOAT'
  of SQLITE_BLOB
    return 'SQLITE_BLOB'
  of SQLITE_NULL
    return 'SQLITE_NULL'
  of SQLITE_TEXT
    return 'SQLITE_TEXT'
  end
  Return pType
!-----------------------------------------------------------------
! loads Driver-Wide values from an INI file when the first file in this driver is Initialized.
! Although this code is common to all the drivers, it can't be moved into the base class because of the
! global module variables.
DriverFileSQLite2Class.LoadLogging  procedure
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
! this driver supports the "custom" field types; UUID4 and UUID7 "out of the box".
! Primarly as an example of how custom fields can be supported.
DriverFileSQLite2Class._parseFields      PROCEDURE(Long pAddr)
x  long
  code
  parent._ParseFields(pAddr)
  Loop x = 1 to self.SharedProperties.FieldList.nodes
    self.Fields &= self._WithFieldNode(x)
    Case self.Fields.UUID
    Of 4 Orof 7
      If (self.Fields.Type = ClaSTRING and self.Fields.length = 36)
        self.Fields.Interface &= (Address(DriverGuidSQLite2))
        self.Fields.SourceSize = self.Fields.Interface.GetSourceSize()
        !Put(self.Fields)
        !!!todo
        !self.trace('_parseFields : SetInterface and source size=' & self.Fields.SourceSize)
      End
    End
  End
  Return

!-----------------------------------------------------------------
DriverFileSQLite2Class.SetErrorSqlite  PROCEDURE(Long pSQLiteErrorCode, String pRef)
str  StringTheory
  Code
  If errorcode() then return. ! The first error is always the one reported back to the program.
  Case pSQLiteErrorCode
  of SQLite_Ok
    self.SetError(NoError)
    self.SetFileError(pSQLiteErrorCode, '')
  of SQLite_Error
    self.SetError(FileSystemErr)
    self.SetFileError(pSQLiteErrorCode, pRef & 'SQLite Error.')
  of SQLite_Internal
    self.SetError(FileSystemErr)
    self.SetFileError(pSQLiteErrorCode, pRef & 'SQLite Internal Error.')
  of SQLITE_PERM
    self.SetError(NoAccessErr)
    self.SetFileError(pSQLiteErrorCode, pRef & 'The requested access mode for a newly created database could not be provided.')
  of SQLite_Abort
    self.SetError(FileSystemErr)
    self.SetFileError(pSQLiteErrorCode, pRef & 'An operation was aborted prior to completion.')
  of SQLite_Busy
    self.SetError(FileSystemErr)
    self.SetFileError(pSQLiteErrorCode, pRef & 'The database file could not be written (or in some cases read) because of concurrent activity.')
  of SQLite_Locked
    self.SetError(IsLockedErr)
    self.SetFileError(pSQLiteErrorCode, pRef & 'A write operation could not continue because of a conflict within the same database connection or a conflict with a different database connection that uses a shared cache.')
  of SQLite_NoMem
    self.SetError(NoMemErr)
    self.SetFileError(pSQLiteErrorCode, pRef & 'SQLite was unable to allocate all the memory it needed to complete the operation.')
  of SQLite_Readonly
    self.SetError(NoAccessErr)
    self.SetFileError(pSQLiteErrorCode, pRef & 'An attempt is made to alter some data for which the current database connection does not have write permission.')
  of SQLite_Interrupt
    self.SetError(FileSystemErr)
    self.SetFileError(pSQLiteErrorCode, pRef & 'An operation was interrupted.')
  of SQLite_IOErr
    self.SetError(FileSystemErr)
    self.SetFileError(pSQLiteErrorCode, pRef & 'The operating system reported an I/O error.')
  of SQLite_Corrupt
    self.SetError(FileSystemErr)
    self.SetFileError(pSQLiteErrorCode, pRef & 'The database file has been corrupted.')
  of SQLite_NotFound
    self.SetError(NoFileErr)
    self.SetFileError(pSQLiteErrorCode, pRef & 'SQLite File Not Found')
  of SQLite_Full
    self.SetError(FileSystemErr)
    self.SetFileError(pSQLiteErrorCode, pRef & 'The disk is full.')
  of SQLite_CantOpen
    self.SetError(FileSystemErr)
    self.SetFileError(pSQLiteErrorCode, pRef & 'Unable to open a file.')
  of SQLite_Protocol
    self.SetError(FileSystemErr)
    self.SetFileError(pSQLiteErrorCode, pRef & 'A problem with the file locking protocol used by SQLite.')
  of SQLite_Empty
    self.SetError(FileSystemErr)
    self.SetFileError(pSQLiteErrorCode, pRef & '')
  of SQLite_Schema
    self.SetError(FileSystemErr)
    self.SetFileError(pSQLiteErrorCode, pRef & 'The database schema has changed.')
  of SQLite_TooBig
    self.SetError(FileSystemErr)
    self.SetFileError(pSQLiteErrorCode, pRef & 'A string or BLOB was too large.')
  of SQLite_Constraint
    self.SetError(FileSystemErr)
    self.SetFileError(pSQLiteErrorCode, pRef & 'A SQL constraint violation occurred while trying to process an SQL statement. ' & Choose(self.dbHandle > 0 ,sqlite3_errmsg(self.dbHandle),'') )
  of SQLite_MisMatch
    self.SetError(FileSystemErr)
    self.SetFileError(pSQLiteErrorCode, pRef & 'Indicates a datatype mismatch.')
  of SQLite_Misuse
    self.SetError(FileSystemErr)
    self.SetFileError(pSQLiteErrorCode, pRef & 'The application uses a SQLite interface in a way that is undefined or unsupported.')
  of SQLite_Nolfs
    self.SetError(FileSystemErr)
    self.SetFileError(pSQLiteErrorCode, pRef & 'No Large File Support.')
  of SQLite_Auth
    self.SetError(FileSystemErr)
    self.SetFileError(pSQLiteErrorCode, pRef & 'A SQL statement being prepared is not authorized.')
  of SQLite_Format
    self.SetError(FileSystemErr)
    self.SetFileError(pSQLiteErrorCode, pRef & '')
  of SQLite_Range
    self.SetError(FileSystemErr)
    self.SetFileError(pSQLiteErrorCode, pRef & 'The parameter number argument to one of the sqlite3_bind routines or the column number in one of the sqlite3_column routines is out of range.')
  of SqLite_NotADb
    self.SetError(FileSystemErr)
    self.SetFileError(pSQLiteErrorCode, pRef & 'The file being opened does not appear to be an SQLite database file.')
  of SQLite_Notice
    self.SetError(FileSystemErr)
    self.SetFileError(pSQLiteErrorCode, pRef & '')
  of SQLite_Warning
    self.SetError(FileSystemErr)
    self.SetFileError(pSQLiteErrorCode, pRef & '')
  of SQLite_Row
    self.SetError(FileSystemErr)
    self.SetFileError(pSQLiteErrorCode, pRef & 'Another row of output is available.')
  of SQLite_Done
    self.SetError(NoError)
    self.SetFileError(pSQLiteErrorCode, pRef & 'An operation has completed.')
  of SQLite_Ok_Load_Permanently
    self.SetError(FileSystemErr)
    self.SetFileError(pSQLiteErrorCode, pRef & '')
  of SQLITE_Error_Missing_Colseq
    self.SetError(FileSystemErr)
    self.SetFileError(pSQLiteErrorCode, pRef & 'A SQL statement could not be prepared because a collating sequence named in that SQL statement could not be located.')
  of SQLITE_Busy_Recovery
    self.SetError(FileSystemErr)
    self.SetFileError(pSQLiteErrorCode, pRef & 'An operation could not continue because another process is busy recovering a WAL mode database file following a crash.')
  of SQLITE_Locked_SharedCache
    self.SetError(IsLockedErr)
    self.SetFileError(pSQLiteErrorCode, pRef & 'Access to an SQLite data record is blocked by another database connection that is using the same record in shared cache mode.')
  of SQLITE_Readonly_Recovery
    self.SetError(FileSystemErr)
    self.SetFileError(pSQLiteErrorCode, pRef & 'A WAL mode database cannot be opened because the database file needs to be recovered and recovery requires write access but only read access is available.')
  of SQLITE_IOERR_READ
    self.SetError(FileSystemErr)
    self.SetFileError(pSQLiteErrorCode, pRef & 'This error might result from a hardware malfunction or because a filesystem came unmounted while the file was open.')
  of SQLITE_CORRUPT_VTAB
    self.SetError(FileSystemErr)
    self.SetFileError(pSQLiteErrorCode, pRef & 'Content in the virtual table is corrupt.')
  of SQLITE_CANTOPEN_NOTEMPDIR
    self.SetError(FileSystemErr)
    self.SetFileError(pSQLiteErrorCode, pRef & '')
  of SQLITE_CONSTRAINT_CHECK
    self.SetError(InvalidFieldError)
    If self.dbHandle > 0
      str.SetValue(sqlite3_errmsg(self.dbHandle) & ' ')
      str.SetAfter(' check_')
      str.Prepend('Field Constraint Failed: ')
    else
      str.SetValue('Field constraint failed.')
    End
    self.SetFileError(pSQLiteErrorCode, pRef & str.GetValue())
  of SQLITE_AUTH_USER
    self.SetError(FileSystemErr)
    self.SetFileError(pSQLiteErrorCode, pRef & 'An operation was attempted on a database for which the logged in user lacks sufficient authorization.')
  of SQLITE_NOTICE_RECOVER_WAL
    self.SetError(FileSystemErr)
    self.SetFileError(pSQLiteErrorCode, pRef & 'The SQLITE_NOTICE_RECOVER_WAL result code is passed to the callback of sqlite3_log() when a WAL mode database file is recovered.')
  of SQLITE_WARNING_AUTOINDEX
    self.SetError(FileSystemErr)
    self.SetFileError(pSQLiteErrorCode, pRef & 'The SQLITE_WARNING_AUTOINDEX result code is passed to the callback of sqlite3_log() whenever automatic indexing is used.')
  of SQLITE_ERROR_RETRY
    self.SetError(FileSystemErr)
    self.SetFileError(pSQLiteErrorCode, pRef & 'Try again to prepare a statement that failed with an error on the previous attempt.')
  of SQLITE_ABORT_ROLLBACK
    self.SetError(FileSystemErr)
    self.SetFileError(pSQLiteErrorCode, pRef & 'A SQL statement aborted because the transaction that was active when the SQL statement first started was rolled back.')
  of SQLITE_BUSY_SNAPSHOT
    self.SetError(FileSystemErr)
    self.SetFileError(pSQLiteErrorCode, pRef & 'A database connection tries to promote a read transaction into a write transaction but finds that another database connection has already written to the database and thus invalidated prior reads.')
  of SQLITE_LOCKED_VTAB
    self.SetError(FileSystemErr)
    self.SetFileError(pSQLiteErrorCode, pRef & '')
  of SQLITE_READONLY_CANTLOCK
    self.SetError(FileSystemErr)
    self.SetFileError(pSQLiteErrorCode, pRef & 'SQLite is unable to obtain a read lock on a WAL mode database because the shared-memory file associated with that database is read-only.')
  of SQLITE_IOERR_SHORT_READ
    self.SetError(FileSystemErr)
    self.SetFileError(pSQLiteErrorCode, pRef & 'A read attempt in the VFS layer was unable to obtain as many bytes as was requested. This might be due to a truncated file.')
  of SQLITE_CORRUPT_SEQUENCE
    self.SetError(FileSystemErr)
    self.SetFileError(pSQLiteErrorCode, pRef & 'The schema of the sqlite_sequence table is corrupt.')
  of SQLITE_CANTOPEN_ISDIR
    self.SetError(FileSystemErr)
    self.SetFileError(pSQLiteErrorCode, pRef & 'A file open operation failed because the file is really a directory.')
  of SQLITE_CONSTRAINT_COMMITHOOK
    self.SetError(FileSystemErr)
    self.SetFileError(pSQLiteErrorCode, pRef & 'A commit hook callback returned non-zero that thus caused the SQL statement to be rolled back.')
  of SQLITE_NOTICE_RECOVER_ROLLBACK
    self.SetError(FileSystemErr)
    self.SetFileError(pSQLiteErrorCode, pRef & 'The SQLITE_NOTICE_RECOVER_ROLLBACK result code is passed to the callback of sqlite3_log() when a hot journal is rolled back.')
  of SQLITE_ERROR_SNAPSHOT
    self.SetError(FileSystemErr)
    self.SetFileError(pSQLiteErrorCode, pRef & '')
  of SQLITE_BUSY_TIMEOUT
    self.SetError(FileSystemErr)
    self.SetFileError(pSQLiteErrorCode, pRef & '')
  of SQLITE_READONLY_ROLLBACK
    self.SetError(FileSystemErr)
    self.SetFileError(pSQLiteErrorCode, pRef & 'Indicates that a database cannot be opened because it has a hot journal that needs to be rolled back but cannot because the database is readonly.')
  of SQLITE_IOERR_WRITE
    self.SetError(FileSystemErr)
    self.SetFileError(pSQLiteErrorCode, pRef & 'This error might result from a hardware malfunction or because a filesystem came unmounted while the file was open.')
  of SQLITE_CORRUPT_INDEX
    self.SetError(FileSystemErr)
    self.SetFileError(pSQLiteErrorCode, pRef & 'SQLite detected an entry is or was missing from an index.')
  of SQLITE_CANTOPEN_FULLPATH
    self.SetError(FileSystemErr)
    self.SetFileError(pSQLiteErrorCode, pRef & 'A file open operation failed because the operating system was unable to convert the filename into a full pathname.')
  of SQLITE_CONSTRAINT_FOREIGNKEY
    If self._ParameterOpcode = Opcode:DELETE
      self.SetError(RestrictedDelete)
    Else
      self.SetError(ForeignKeyFailed)
    End
    self.SetFileError(pSQLiteErrorCode, pRef & 'A foreign key (must be in file) constraint failed.')
  of SQLITE_READONLY_DBMOVED
    self.SetError(FileSystemErr)
    self.SetFileError(pSQLiteErrorCode, pRef & 'A database cannot be modified because the database file has been moved since it was opened, and so any attempt to modify the database might result in database corruption if the processes crashes because the rollback journal would not be correctly named.')
  of SQLITE_IOERR_FSYNC
    self.SetError(FileSystemErr)
    self.SetFileError(pSQLiteErrorCode, pRef & '')
  of SQLITE_CANTOPEN_CONVPATH
    self.SetError(FileSystemErr)
    self.SetFileError(pSQLiteErrorCode, pRef & '')
  of SQLITE_CONSTRAINT_FUNCTION
    self.SetError(FileSystemErr)
    self.SetFileError(pSQLiteErrorCode, pRef & '')
  of SQLITE_READONLY_CANTINIT
    self.SetError(FileSystemErr)
    self.SetFileError(pSQLiteErrorCode, pRef & 'The shared memory region used by WAL mode exists buts its content is unreliable and unusable by the current process since the current process does not have write permission on the shared memory region.')
  of SQLITE_IOERR_DIR_FSYNC
    self.SetError(FileSystemErr)
    self.SetFileError(pSQLiteErrorCode, pRef & '')
  of SQLITE_CANTOPEN_DIRTYWAL
    self.SetError(FileSystemErr)
    self.SetFileError(pSQLiteErrorCode, pRef & '')
  of SQLITE_CONSTRAINT_NOTNULL
    self.SetError(NotNullFailed)
    If self.dbHandle > 0
      str.SetValue(sqlite3_errmsg(self.dbHandle) & ' ')
      !str.SetAfter(' check_')
      !str.Prepend('Not Null Constraint Failed: ')
    else
      str.SetValue('Not Null constraint failed.')
    End
    self.SetFileError(pSQLiteErrorCode, pRef & str.GetValue())
    !self.SetError(FileSystemErr)
    !self.SetFileError(pSQLiteErrorCode, pRef & 'A NOT NULL constraint failed')
  of SQLITE_READONLY_DIRECTORY
    self.SetError(FileSystemErr)
    self.SetFileError(pSQLiteErrorCode, pRef & 'The database is read-only because process does not have permission to create a journal file in the same directory as the database and the creation of a journal file is a prerequisite for writing.')
  of SQLITE_IOERR_TRUNCATE
    self.SetError(FileSystemErr)
    self.SetFileError(pSQLiteErrorCode, pRef & 'An I/O error in the VFS layer while trying to truncate a file to a smaller size.')
  of SQLITE_CANTOPEN_SYMLINK
    self.SetError(FileSystemErr)
    self.SetFileError(pSQLiteErrorCode, pRef & 'The SQLITE_OPEN_NOFOLLOW flag is used and the database file is a symbolic link.')
  of SQLITE_CONSTRAINT_PRIMARYKEY
    self.SetError(DupKeyErr)
    self.SetFileError(pSQLiteErrorCode, pRef & 'A PRIMARY KEY constraint failed.')
  of SQLITE_IOERR_FSTAT
    self.SetError(FileSystemErr)
    self.SetFileError(pSQLiteErrorCode, pRef & 'An I/O error in the VFS layer while trying to invoke fstat() (or the equivalent) on a file in order to determine information such as the file size or access permissions.')
  of SQLITE_CONSTRAINT_TRIGGER
    If self._ParameterOpcode = Opcode:DELETE
      self.SetError(RestrictedDelete)
    Else
      self.SetError(ForeignKeyFailed)
    End
    !self.SetError(FileSystemErr)
    self.SetFileError(pSQLiteErrorCode, pRef & 'A RAISE function within a trigger fired, causing the SQL statement to abort.')
  of SQLITE_IOERR_UNLOCK
    self.SetError(FileSystemErr)
    self.SetFileError(pSQLiteErrorCode, pRef & 'An I/O error within xUnlock method on the sqlite3_io_methods object')
  of SQLITE_CONSTRAINT_UNIQUE
    self.SetError(DupKeyErr)
    self.SetFileError(pSQLiteErrorCode, pRef & 'A UNIQUE constraint failed.')
  of SQLITE_IOERR_RDLOCK
    self.SetError(FileSystemErr)
    self.SetFileError(pSQLiteErrorCode, pRef & 'An I/O error within xLock method on the sqlite3_io_methods object while trying to obtain a read lock.')
  of SQLITE_CONSTRAINT_VTAB
    self.SetError(FileSystemErr)
    self.SetFileError(pSQLiteErrorCode, pRef & '')
  of SQLITE_IOERR_DELETE
    self.SetError(FileSystemErr)
    self.SetFileError(pSQLiteErrorCode, pRef & 'An I/O error within xDelete method on the sqlite3_vfs object.')
  of SQLITE_CONSTRAINT_ROWID
    self.SetError(DupKeyErr)
    self.SetFileError(pSQLiteErrorCode, pRef & 'A rowid is not unique.')
  of SQLITE_IOERR_BLOCKED
    self.SetError(FileSystemErr)
    self.SetFileError(pSQLiteErrorCode, pRef & '')
  of SQLITE_CONSTRAINT_PINNED
    self.SetError(FileSystemErr)
    self.SetFileError(pSQLiteErrorCode, pRef & 'An UPDATE trigger attempted do delete the row that was being updated in the middle of the update.')
  of SQLITE_IOERR_NOMEM
    self.SetError(FileSystemErr)
    self.SetFileError(pSQLiteErrorCode, pRef & 'An operation could not be completed due to the inability to allocate sufficient memory.')
  of SQLITE_CONSTRAINT_DATATYPE
    self.SetError(FileSystemErr)
    self.SetFileError(pSQLiteErrorCode, pRef & 'An insert or update attempted to store a value inconsistent with the column''s declared type in a table defined as STRICT.')
  of SQLITE_IOERR_ACCESS
    self.SetError(FileSystemErr)
    self.SetFileError(pSQLiteErrorCode, pRef & 'An I/O error within the xAccess method on the sqlite3_vfs object.')
  of SQLITE_IOERR_CHECKRESERVEDLOCK
    self.SetError(FileSystemErr)
    self.SetFileError(pSQLiteErrorCode, pRef & 'An I/O error within the xCheckReservedLock method on the sqlite3_io_methods object.')
  of SQLITE_IOERR_LOCK
    self.SetError(FileSystemErr)
    self.SetFileError(pSQLiteErrorCode, pRef & 'An I/O error in the advisory file locking logic.')
  of SQLITE_IOERR_CLOSE
    self.SetError(FileSystemErr)
    self.SetFileError(pSQLiteErrorCode, pRef & 'An I/O error within the xClose method on the sqlite3_io_methods object.')
  of SQLITE_IOERR_DIR_CLOSE
    self.SetError(FileSystemErr)
    self.SetFileError(pSQLiteErrorCode, pRef & '')
  of SQLITE_IOERR_SHMOPEN
    self.SetError(FileSystemErr)
    self.SetFileError(pSQLiteErrorCode, pRef & '')
  of SQLITE_IOERR_SHMSIZE
    self.SetError(FileSystemErr)
    self.SetFileError(pSQLiteErrorCode, pRef & '')
  of SQLITE_IOERR_SHMLOCK
    self.SetError(FileSystemErr)
    self.SetFileError(pSQLiteErrorCode, pRef & '')
  of SQLITE_IOERR_SHMMAP
    self.SetError(FileSystemErr)
    self.SetFileError(pSQLiteErrorCode, pRef & '')
  of SQLITE_IOERR_SEEK
    self.SetError(FileSystemErr)
    self.SetFileError(pSQLiteErrorCode, pRef & '')
  of SQLITE_IOERR_DELETE_NOENT
    self.SetError(FileSystemErr)
    self.SetFileError(pSQLiteErrorCode, pRef & '')
  of SQLITE_IOERR_MMAP
    self.SetError(FileSystemErr)
    self.SetFileError(pSQLiteErrorCode, pRef & '')
  of SQLITE_IOERR_GETTEMPPATH
    self.SetError(FileSystemErr)
    self.SetFileError(pSQLiteErrorCode, pRef & 'The VFS is unable to determine a suitable directory in which to place temporary files.')
  of SQLITE_IOERR_CONVPATH
    self.SetError(FileSystemErr)
    self.SetFileError(pSQLiteErrorCode, pRef & '')
  of SQLITE_IOERR_VNODE
    self.SetError(FileSystemErr)
    self.SetFileError(pSQLiteErrorCode, pRef & '')
  of SQLITE_IOERR_AUTH
    self.SetError(FileSystemErr)
    self.SetFileError(pSQLiteErrorCode, pRef & '')
  of SQLITE_IOERR_BEGIN_ATOMIC
    self.SetError(FileSystemErr)
    self.SetFileError(pSQLiteErrorCode, pRef & '')
  of SQLITE_IOERR_COMMIT_ATOMIC
    self.SetError(FileSystemErr)
    self.SetFileError(pSQLiteErrorCode, pRef & '')
  of SQLITE_IOERR_ROLLBACK_ATOMIC
    self.SetError(FileSystemErr)
    self.SetFileError(pSQLiteErrorCode, pRef & '')
  of SQLITE_IOERR_DATA
    self.SetError(FileSystemErr)
    self.SetFileError(pSQLiteErrorCode, pRef & '')
  of SQLITE_IOERR_CORRUPTFS
    self.SetError(FileSystemErr)
    self.SetFileError(pSQLiteErrorCode, pRef & '')
  else
    self.SetError(FileSystemErr)
    self.SetFileError(pSQLiteErrorCode, pRef & '')
  End
  Return

!-----------------------------------------------------------------
! data has been read, and the whole result row is now moving from the SQL engine into the pResult.
! called from DriverClass and DriverViewClass, so avoid referencing the "self" object here.
DriverFileSQLite2Class._ToResult         PROCEDURE(Long pStmt, Long pColumns, iResultSet pResult)
column        long,Auto
sqcol         long,Auto
row           long,Auto
rl            real,Auto
lg            long,Auto
str           &string,Auto
colname       &cstring,Auto
coltype       long,Auto
Addr          BIGINT,Auto
Len           BIGINT,Auto
  code
  row = pResult.IncrementRowNumber()
  Loop column = 1 to pColumns
    sqcol = column - 1
    If row = 1
      colname &= sqlite3_column_name(pStmt,sqcol)
      If not colname &= null
        pResult.SetColumnName(column,colname)
        If self.opt:dummy = false
          If self._WithFieldNamed(colname) = Driver:ok
            pResult.SetColumnIndex(column,self.fields.Index)
          End
        Else
          pResult.SetColumnIndex(column,column)
        End
      Else
        pResult.SetColumnIndex(column,column)
      End
    End
    coltype = sqlite3_column_type(pStmt,sqcol)
    Case coltype
    Of SQLITE_INTEGER
      lg =  sqlite3_column_int(pStmt,sqcol)
      Addr = address(lg)
      Len = 4
      pResult.SetCell(row,column,SQLITE_INTEGER,Addr,Len)

    Of SQLITE_FLOAT
      rl = sqlite3_column_double(pStmt,sqcol)
      Addr = address(rl)
      Len = 8
      pResult.SetCell(row,column,SQLITE_FLOAT,Addr,Len)
    Of SQLITE_TEXT
      Addr = sqlite3_column_text(pStmt,sqcol)
      Len = sqlite3_column_bytes(pStmt,sqcol)
      pResult.SetCell(row,column,SQLITE_TEXT,Addr,Len)
    Of SQLITE_BLOB
      addr = sqlite3_column_blob(pStmt,sqcol)
      len = sqlite3_column_bytes(pStmt,sqcol)
      pResult.SetCell(row,column,SQLITE_BLOB,Addr,Len)
    Of SQLITE_NULL
      Addr = 0
      Len = 0
      pResult.SetCell(row,column,SQLITE_NULL,Addr,Len)
    End
  End
  Return

!-----------------------------------------------------------------
! in SQLite dates are stored as a text field in @d010- format.
!           times are stored as a text field in @t093z format
!           decimals are stored as a number, but returned to us as a string.
!           timestamps are stored as DateTTime
! Fields node must already be loaded
! given text, returns binary data of the correct size
DriverFileSQLite2Class.DeformatText Procedure(String pText)
strmem   string(16),Auto
dt       Date,Auto
tm       Time ,Auto
sdt      string(4),over(dt)
stm      string(4),over(tm)
i        long,Auto
j        long,Auto
gr       Group,Auto
dt1        Date
tm1        Time
         End
  code
  If self.Deformat &= null
    self.Deformat &= new StringDeformat
  End
  If self.fields.SqlTimeStamp
    j = len(self.DateTimeSeparator)
    i = instring(self.DateTimeSeparator,pText,1,1)
    if i = 0 then i = instring(' T ',pText,1,1) ; j = 3.
    if i = 0 then i = instring(' ',pText,1,1) ; j = 1.
    if i = 0 then i = instring('T',pText,1,1) ; j = 1.
    if i
      gr.dt1 = self.Deformat.DeformatDate(sub(pText,1,i-1),'@d10-')
      gr.tm1 = self.Deformat.DeformatTime(sub(pText,i+j,len(pText)),'@t93')
    end
    Return gr
  End
  Case self.Fields.Type
  of ClaDATE
      dt = self.Deformat.DeformatDate(pText,'@d10-')
      return sdt
  of ClaTIME
      tm = self.Deformat.DeformatTime(pText,'@t93')
      return stm
  of ClaDECIMAL
  orof ClaPDECIMAL
     self._StringToDec(pText,self.Fields.Type, address(strmem), self.Fields.DecimalSize, self.Fields.DecimalPlaces)
     return strmem
  end
  return pText

!-----------------------------------------------------------------
DriverFileSQLite2Class.SetDriverOption            Procedure(String pOption, String pValue)
ans     cstring(255)
result  long,auto
mode    string(20)
  Code
  If self._logOptions then self.Log('[OPTN]' & clip(pOption) & ' =[' & clip(pValue & ']')).
  Case upper(pOption)
  of '/AUTOINC'       ! If the AUTOINCREMENT keyword appears after INTEGER PRIMARY KEY, that changes the automatic ROWID assignment algorithm to prevent the reuse of ROWIDs over the lifetime of the database.
                      ! In other words, the purpose of AUTOINCREMENT is to prevent the reuse of ROWIDs from previously deleted rows.  The AUTOINCREMENT keyword imposes extra CPU, memory, disk space, and
                      ! disk I/O overhead and should be avoided if not strictly needed. It is usually not needed.
    If pValue <> ''
      do checkBoolean
      self.opt:AutoInc = pValue
    End
    Return self.opt:AutoInc
  of '/BUSYTIMEOUT'
    If pValue <> ''
      self.opt:BusyTimeout = pValue
      If self.dbHandle
        result = sqlite3_busy_timeout(self.dbHandle,self.opt:BusyTimeout)
      End
    End
    Return self.opt:BusyTimeout
  of '/NOPRIMARY'                ! There is no documentation as to what this does. In SQLite2 it adds WITHOUT ROWID to the CREATE statement.
    If pValue <> ''
      do checkBoolean
      self.opt:NoPrimary = pValue
    End
    Return self.opt:NoPrimary
  of '/USEPRIMARY'               ! There is no documentation on what this does.
    If pValue <> ''
      do checkBoolean
      self.opt:UsePrimary = pValue
    End
    Return self.opt:UsePrimary
  of '/WHERE'
    self.SetProp:Where(pValue)
    return self.GetProp:where()
  of '/WAL'
     If self.Owner = '' then return ''.
     If self.CheckConnect() = Driver:notok then return ''.
     mode = self.send('/pragma_journal_mode=WAL')
     self.send('/pragma_synchronous=NORMAL')
     return mode
  else
    If lower(sub(pOption,1,8)) = '/pragma_'
      If self.CheckConnect() = Driver:notok then return ''.
      self.SqlCode.SetValue('PRAGMA ' & sub(pOption,9,len(clip(pOption))))
      If pValue <> '' then self.SqlCode.Append('=' & clip(pValue)).
      self.SqlCode.Append(';')
      If self._ExecuteSql() = Driver:ok
        If self.Result.Rows()
          ans = self.Result.GetCell(1,1)
        End
      End
      Return ans
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
DriverFileSQLite2Class._ExecuteToRecord    Procedure(Long pStmt,Long pWhichBuffer,Byte pErrIfNoRecord,Long pOpCode)
result        Long,Auto
totalchanged  long,auto
found         Byte
  code
  !self.trace('DriverFileSQLite2Class._ExecuteToRecord')
  If self._BindParameters(pStmt) = driver:ok
    !self.NewResultSet(driver:DontFreeRam)     ! Explicitly do NOT touch the Result set here
    totalchanged = sqlite3_total_changes(self.dbHandle)
    If self._logSQL then self.Log('[SQL ]' & self.SqlCode.GetValue()).
    Loop
      result = sqlite3_step(pStmt)
      Case result
      Of SQLite_Done
        case pOpCode
        of Opcode:DELETE
        orof Opcode:PUT
          self.Affected = sqlite3_changes(self.dbHandle)
          self.ChildrenAffected = sqlite3_total_changes(self.dbHandle) - totalChanged - self.Affected
          If self.Affected = 0 and pErrIfNoRecord Then self.SetError(pErrIfNoRecord).
        of Opcode:ADD
        orof Opcode:APPEND
          If pErrIfNoRecord Then self.SetError(pErrIfNoRecord).
        of Opcode:GET
          If found = false and pErrIfNoRecord Then self.SetError(pErrIfNoRecord).
        End
        break
      Of SQLite_Row
        If found = false then self._toRecord(pStmt,pWhichBuffer).
        found = true
      Else
        self.SetErrorSqlite(result,'[p001]')
        Break
      End
    End
    result = sqlite3_reset(pStmt)              ! does an implicit commit if the transaction is implicit
  End
  result = sqlite3_clear_bindings(pStmt)     ! do not leak values to next call.
  Return

!-----------------------------------------------------------------
! moves the results from the SQLITE result set to the .Results parameter using the SQLite API.
! called from DriverClass and DriverViewClass, so avoid referencing the "self" object here.
DriverFileSQLite2Class._ExecuteToResults    Procedure(Long pStmt,iResultSet pResult)
result        long,auto
columns       long,auto
totalchanged  long,auto
  code
  pResult.NewResultSet(driver:DontFreeRam)
  self.ResultRow = 0
  self._ResultRow = 0
  self.Affected = 0
  If pStmt = 0 then Return.
  If self.CheckConnect() = driver:notok then Return.
  totalchanged = sqlite3_total_changes(self.dbHandle)
  If self._logSQL then self.Log('[SQL ]' & self.SqlCode.GetValue()).
  result = sqlite3_step(pStmt)  ! executes the sql and returns the first row
  columns = sqlite3_column_count(pStmt)
  Loop
    Case result
    Of SQLite_Done
      self.Affected = sqlite3_changes(self.dbHandle)
      self.ChildrenAffected = sqlite3_total_changes(self.dbHandle) - totalChanged - self.Affected
      Break
    Of SQLite_Row
      self._ToResult(pStmt,columns,pResult)   ! copies the whole row to pResult
    Else
      self.SetErrorSqlite(result,'[p001]')
      Break
    End
    result = sqlite3_step(pStmt)  ! next row, and cycle.
  End
  If self._logSQL then self.Log('[SQL ]' & pResult.Rows() & ' rows, ' & pResult.Columns() & ' columns in result set').
  Return

!-----------------------------------------------------------------
! prepares and executes the SQL in SqlCode.
DriverFileSQLite2Class._executeSql procedure()
stmt    Long ,Auto
  code
  If self.CheckConnect() = driver:notok then Return driver:notok.
  stmt = self._Prepare()
  If stmt
    Return self._ExecuteSqlWork(stmt)
  else
    Return Driver:notok
  End
  Return driver:ok

!-----------------------------------------------------------------
DriverFileSQLite2Class._executeSql procedure(Long pStmt)
  Code
  If self.CheckConnect() = driver:notok then Return driver:notok.
  Return self._ExecuteSqlWork(pStmt)

!-----------------------------------------------------------------
!  binds parameters and executes the SQL in SqlCode.
! SQL is not cached.
! results are set to Results
! returns driver:notok if the SQL part is faulty
DriverFileSQLite2Class._ExecuteSqlWork procedure(Long pStmt)
result  Long,Auto
  code
  If pStmt
    If self._BindParameters(pStmt) = Driver:ok
      self._ExecuteToResults(pStmt,self.result)
    End
    result = sqlite3_finalize(pStmt)
    self.SetErrorSqlite(result,'[p010]')
    If self._ParameterOpcode then self._ClearParameterQueue(self._ParameterOpcode).
    If Errorcode()
      Return driver:notok
    End
  Else
    Return driver:notok
  End
  Return driver:ok

!-----------------------------------------------------------------
! does a parameterized request, with up to 20 parameters
! returns driver:notok if the SQL part is faulty
DriverFileSQLite2Class._ExecuteSql     Procedure(StringTheory pSQL, <? pParm1>,<? pParm2>,<? pParm3>,<? pParm4>,<? pParm5>,<? pParm6>,<? pParm7>,<? pParm8>,<? pParm9>,<? pParm10>,<? pParm11>,<? pParm12>,<? pParm13>,<? pParm14>,<? pParm15>,<? pParm16>,<? pParm17>,<? pParm18>,<? pParm19>,<? pParm20>)
stmt    long
result  long
len     long
parm    any
count   long
s      &string
rl     real
  code
  If self.CheckConnect() = driver:notok then Return driver:notok.
  self.SqlCode.SetValue(pSql)
  stmt = self._Prepare()
  If stmt

    self._ResultRow = 0
    If not omitted(pParm1) then parm = pParm1 ; do BindParm.
    If not omitted(pParm2) then parm = pParm2 ; do BindParm.
    If not omitted(pParm3) then parm = pParm3 ; do BindParm.
    If not omitted(pParm4) then parm = pParm4 ; do BindParm.
    If not omitted(pParm5) then parm = pParm5 ; do BindParm.
    If not omitted(pParm6) then parm = pParm6 ; do BindParm.
    If not omitted(pParm7) then parm = pParm7 ; do BindParm.
    If not omitted(pParm8) then parm = pParm8 ; do BindParm.
    If not omitted(pParm9) then parm = pParm9 ; do BindParm.
    If not omitted(pParm10) then parm = pParm10 ; do BindParm.
    If not omitted(pParm11) then parm = pParm11 ; do BindParm.
    If not omitted(pParm12) then parm = pParm12 ; do BindParm.
    If not omitted(pParm13) then parm = pParm13 ; do BindParm.
    If not omitted(pParm14) then parm = pParm14 ; do BindParm.
    If not omitted(pParm15) then parm = pParm15 ; do BindParm.
    If not omitted(pParm16) then parm = pParm16 ; do BindParm.
    If not omitted(pParm17) then parm = pParm17 ; do BindParm.
    If not omitted(pParm18) then parm = pParm18 ; do BindParm.
    If not omitted(pParm19) then parm = pParm19 ; do BindParm.
    If not omitted(pParm20) then parm = pParm20 ; do BindParm.
    !self.NewResultSet(driver:DontFreeRam)
    self._ExecuteToResults(stmt,self.result)
    result = sqlite3_finalize(stmt)
    self._ClearParameterQueue(self._ParameterOpcode)
    self.SetErrorSqlite(result,'[p015]')
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
  If IsString(parm)
    len = len(clip(parm))
    s &= new(string(len))
    s = parm
    If self._logBind then self.Log('[BIND][sb1]' & count & ' (string)[' & s & ']').
    result = sqlite3_bind_textA(stmt,count,s, len ,SQLITE_TRANSIENT)
    self.SetErrorSqlite(result,'[p020]')
    Dispose(s)
  Else
    rl = parm
    If self._logBind then self.Log('[BIND][sb2]' & count & ' (real)' & rl).
    result = sqlite3_bind_double(stmt,count,rl)
    self.SetErrorSqlite(result,'[p021]')
  End

!-----------------------------------------------------------------
DriverFileSQLite2Class._ClearStmts  Procedure()
result  long
x       long
  code
  If self.dbHandle and self.Stmt_Add
    result = sqlite3_finalize(self.Stmt_Add)
    self.SetErrorSqlite(result,'[p030]')
  End
  self.Stmt_Add = 0
  Dispose(self._AddSqlCache)

  If self.dbHandle and self.Stmt_Append
    result = sqlite3_finalize(self.Stmt_Append)
    self.SetErrorSqlite(result,'[p031]')
  End
  self.Stmt_Append = 0
  Dispose(self._AppendSqlCache)

  If self.dbHandle and self.Stmt_Put
    result = sqlite3_finalize(self.Stmt_Put)
    self.SetErrorSqlite(result,'[p032]')
  End
  self.Stmt_Put = 0
  Dispose(self._PutSqlCache)

  If self.dbHandle and self.Stmt_Delete
    result = sqlite3_finalize(self.Stmt_Delete)
    self.SetErrorSqlite(result,'[p033]')
  End
  self.Stmt_Delete = 0
  Dispose(self._DeleteSqlCache)

  If self.dbHandle and self.Stmt_Upsert
    result = sqlite3_finalize(self.Stmt_Upsert)
    self.SetErrorSqlite(result,'[p034]')
  End
  self.Stmt_Upsert = 0
  Dispose(self._UpsertSqlCache)

  If self.dbHandle and self.Stmt_Set
    result = sqlite3_finalize(self.Stmt_Set)
    self.SetErrorSqlite(result,'[p035]')
  End
  self.Stmt_Set = 0

  If self.dbHandle and self.Stmt_Get
    result = sqlite3_finalize(self.Stmt_Get)
    self.SetErrorSqlite(result,'[p036]')
  End
  self.Stmt_Get = 0
  Dispose(self._GetSqlCache)
  self._ClearParameterQueue(0)
  Return

!-----------------------------------------------------------------
! take a SQL statement and pass it to the SQLite prepare call
DriverFileSQLite2Class._Prepare  Procedure()
  code
  Return self._Prepare(self.SqlCode)

!-----------------------------------------------------------------
! take a SQL statement and pass it to the SQLite prepare call
DriverFileSQLite2Class._Prepare  Procedure(StringTheory pSqlCode)
result        long,Auto
stmt          long
tail          long
  Code
  If pSqlCode.Length() = 0 then return 0.
  result = sqlite3_prepare_v2(self.dbHandle,pSqlCode.GetAddress(),pSqlCode.Length(), stmt, tail)
  Case result
  of SQLite_Ok
  Else
  End
  self.SetErrorSqlite(result,'[p040]')
  Return stmt

!-----------------------------------------------------------------
! Called From the CONNECT procedure, this queries the database to get the SQLITE version number
! This method takes the step of displaying a message, because a database with too low a version
! is not good.
DriverFileSQLite2Class._GetDBVersion   Procedure
  Code
  If self.GetProp:DBMSVer() = ''
    self.SqlCode.SetValue('select sqlite_version();')
    self._ParameterOpcode = 0
    If self._ExecuteSql() = Driver:ok and self.result.Rows()
      self._ParseVersionDb(self.Result.GetCell(1,1))
      If self.CheckVersion(SQLite_Major_Required, SQLite_Minor_Required,SQLite_Build_Required) <> driver:ok
        self.trace('Database Version : ' & self.DBVersionMajor & '.' & self.DBVersionMinor & '.' & self.DBVersionBuild  & ' Too Old. Need ' & SQLite_Major_Required & '.' & SQLite_Minor_Required & '.' & SQLite_Build_Required & ' or later.')
        self.BugAlert('[' & self.GetPROP:Driver() & '] ' & self.GetPROP:Database() & ' Database Version : ' & self.DBVersionMajor & '.' & self.DBVersionMinor & '.' & self.DBVersionBuild  & ' Too Old. Need ' & SQLite_Major_Required & '.' & SQLite_Minor_Required & '.' & SQLite_Build_Required & ' or later.')
      End
    End
  End
  Return

!-----------------------------------------------------------------
! this is used to set non-persistent PRAGMAS to take affect after the connection is opened.
DriverFileSQLite2Class._SetDefaultPragmas   Procedure()
journal_mode  String(20)
  code
  self.SqlCode.SetValue('PRAGMA journal_mode;')
  self._ParameterOpcode = 0
  If self._ExecuteSql() = Driver:ok and self.result.Rows()
    journal_mode = self.Result.GetCell(1,1)
    case lower(journal_mode)
    of 'wal'
      self.SqlCode.SetValue('PRAGMA syncronous=NORMAL;')
      If self._ExecuteSql() = Driver:ok
      End
      ! so mmap_size allows for memory mapped files, but it gets allocated on a per-connection basis - meaning per thread.
      ! so not sure if performance gain is worth the memory cost - especially in highly threaded applications.
      !self.SqlCode.SetValue('PRAGMA mmap_size=10485760')  ! 10 megs. Makes performance on small files very fast.
      !If self._ExecuteSql() = Driver:ok
      !End
    End
  End


!-----------------------------------------------------------------
DriverFileSQLite2Class._GenParm                PROCEDURE(Long pCount)
  code
  Return '?' & pCount

!-----------------------------------------------------------------
! can take Opcode:Add, Opcode:Append, Opcode:Upsert as the parameter.
! although mostly common SQL syntax, use of ON CONFLICT and RETURNING are SQLite specific.
DriverFileSQLite2Class._AddSQL  Procedure(Long pOpcode)
x              Long,Auto
returning      StringTheory
excluded       StringTheory
FieldsList     StringTheory
ValuesList     StringTheory

  code
  self._fromcache = false
  self._ClearParameterQueue(pOpcode)
  self.ParseProject()
  Loop x = 1 to self.SharedProperties.FieldList.nodes
    self.Fields &= self._WithFieldNode(x)
    if self.Fields.Over or self.Fields.InOverGroup or self.Fields.Type = ClaGROUP then Cycle.
    If self.Fields.ReadOnly or self.Fields.IsIdentity
      returning.Append(self.Fields.Column,st:noclip,',')
      Cycle
    End
    If self._ProjectField[x] = false
      If self.Fields.HasDefault
        returning.Append(self.Fields.Column,st:noclip,',')
      End
      Cycle                                ! importantly, 255, not 1, if included.
    End
    FieldsList.Append(self.Fields.Column,st:NoClip,',')
    self._ParameterCount += 1
    self._SetParameterNode(self._ParameterCount,self.fields,driver:FromBuffer,0)
    ValuesList.Append(self._genparm(self._ParameterCount),st:NoClip,',')
    If pOpcode = OpCode:Upsert and self.Fields.Primary = false
      excluded.append( self.Fields.Column & '= excluded.' & self.Fields.Column ,st:NoClip,',')
    End
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
  self.SqlCode.SetValue('INSERT INTO ' & self._sanitize(self.FullPathName,driver:sqlTable) & ' (' & FieldsList.GetValue() & ') VALUES (' & ValuesList.GetValue() & ') ')
  If pOpcode = OpCode:Upsert
    self.SqlCode.Append(' ON CONFLICT DO UPDATE SET ' & excluded.GetValue())
  End
  If returning.Length() and self._FastWrite = false
    self.SqlCode.Append(' RETURNING ' & returning.GetValue())
  End
  self.SqlCode.Append(';')
  return driver:ok

!-----------------------------------------------------------------
! can take Opcode:Add, Opcode:Append, Opcode:Upsert as the parameter.
! although mostly common SQL syntax, use of ON CONFLICT and RETURNING are SQLite specific.
DriverFileSQLite2Class._PrepareAdd  Procedure(Long pOpcode)
x              Long,auto
result         Long,auto
  Code
  self._fromcache = true
  If pOpcode = Opcode:ADD and self.Stmt_Add and self._AddCache = self._PropsCache and self._AddMemoCache = self._nomemo
    self.SqlCode.SetValue(self._AddSqlCache)
    Return
  End
  If pOpcode = Opcode:APPEND and self.Stmt_Append and self._AppendCache = self._PropsCache and self._AppendMemoCache = self._nomemo
    self.SqlCode.SetValue(self._AppendSqlCache)
    Return
  End
  If pOpcode = Opcode:UPSERT and self.Stmt_Upsert and self._UpsertCache = self._PropsCache and self._UpsertMemoCache = self._nomemo
    self.SqlCode.SetValue(self._UpsertSqlCache)
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
        result = sqlite3_finalize(self.Stmt_Add)
        self.SetErrorSqlite(result,'[p050]')
      End
      self.Stmt_Add = self._prepare()
      If self.Stmt_Add
        If self._AddSqlCache &= null
          self._AddSqlCache &= new StringTheory
        End
        self._AddSqlCache.SetValue(self.SqlCode)
      End
    End
    self._AddCache = self._PropsCache
    self._AddMemoCache = self._nomemo

  of Opcode:APPEND
    If self.Stmt_Append = 0 or self._AppendSqlCache &= null or self._AppendSqlCache.Equals(self.SqlCode,ST:SimpleCompare) = false
      If self.Stmt_Append
        result = sqlite3_finalize(self.Stmt_Append)
        self.SetErrorSqlite(result,'[p050]')
      End
      self.Stmt_Append = self._prepare()
      If self.Stmt_Append
        If self._AppendSqlCache &= null
          self._AppendSqlCache &= new StringTheory
        End
        self._AppendSqlCache.SetValue(self.SqlCode)
      End
    End
    self._AppendCache = self._PropsCache
    self._AppendMemoCache = self._nomemo

  of OpCode:Upsert
    If self._UpsertSqlCache &= null or self._UpsertSqlCache.Equals(self.SqlCode,ST:SimpleCompare) = false or self.Stmt_Upsert = 0
      If self.Stmt_Upsert
        result = sqlite3_finalize(self.Stmt_Upsert)
        self.SetErrorSqlite(result,'[p050]')
      End
      self.Stmt_Upsert = self._prepare()
      If self.Stmt_Upsert
        If self._UpsertSqlCache &= null
          self._UpsertSqlCache &= new StringTheory
        End
        self._UpsertSqlCache.SetValue(self.SqlCode)
      End
    End
    self._UpsertCache = self._PropsCache
    self._UpsertMemoCache = self._nomemo
  End
  Return

!-----------------------------------------------------------------
DriverFileSQLite2Class._PrepareDelete  Procedure()
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
    Return Driver:ok
  End
  Return Driver:Notok

!-----------------------------------------------------------------
DriverFileSQLite2Class._PrepareDelete  Procedure(String pFilter)
stmt  Long
  Code
  If self._DeleteSql(pFilter) = driver:ok
    stmt = self._prepare()
    Return stmt
  End
  Return 0

!-----------------------------------------------------------------
DriverFileSQLite2Class._PrepareGet  Procedure(KEY pKey)
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
        result = sqlite3_finalize(self.Stmt_Get)
        self.SetErrorSqlite(result,'[p050]')
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
        Return self.Stmt_Get
      End
    End
  End
  Return 0

!-----------------------------------------------------------------
! builds sqlcode suitable for MERGE command
DriverFileSQLite2Class._MergeSQL  Procedure(DriverFileSQLClass pDestination,String pDestinationName)
x           Long,Auto
offset      BIGINT
limit       BIGINT
fieldlist   StringTheory
sets        StringTheory
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
    If self.Fields.Primary
      primary.append(self.Fields.Column,,',')
    Else
      sets.append(self.Fields.Column & ' = excluded.' & self.Fields.Column,,', ')
    End
  End
  If self.NoMemoArmed = false                                   ! doing Writes, wthout reads, so directly check if a call to NOMEMO is active.
    Loop x = 1 to Records(self.blobs)
      Get(self.blobs,x)
      If self._ProjectBlobField[x] = false then cycle.          ! importantly, 255, not 1, if included.
      do CheckDestinationFromBlobName
      If pleaseCycle then cycle.
      FieldList.append(self.blobs.Column,,',')
      sets.append(self.blobs.Column & '= excluded.' & self.blobs.Column,,',')
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
  self.SqlCode.SetValue('INSERT OR REPLACE INTO ' & clip(pDestinationName) & '(' & fieldlist.GetValue() & ')' &|
               ' SELECT ' & fieldlist.GetValue() &|
               ' FROM ' & self._sanitize(self.FullPathName,driver:sqlTable) & |
               choose(not self.where &= null and len(self.where) > 0, ' WHERE ' & self.where,'') )
  offset = self.GetPROP:Offset()
  limit = self.GetPROP:Limit()
  If offset and limit = 0 then limit = -1.
  If offset
    self.SqlCode.Append(' LIMIT ' & limit & ' OFFSET ' & offset)
  Elsif limit
    self.SqlCode.Append(' LIMIT ' & limit)
  End
  self.SqlCode.Append(';')

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
! the PUT updates the record by doing a WHERE on the Primary Key. Thus all FILE Reads MUST read the Primary Key values.
! supports prop:project - only projected fields will be updated.
DriverFileSQLite2Class._PreparePut Procedure()
result          Long,Auto
FieldsList      StringTheory
where           StringTheory
returning       StringTheory
  Code
  if self._PutSql() = driver:ok and self.SqlCode.Length()
    If self.Stmt_Put and self.SqlCode.Equals(self._PutSqlCache)
      Return self.Stmt_Put
    End
    If self.Stmt_Put
      result = sqlite3_finalize(self.Stmt_Put)
      self.SetErrorSqlite(result,'[p155]')
      self.Stmt_Put = 0
    End
    self.Stmt_Put = self._prepare()
    self._PutCache = self._PropsCache
    self._PutMemoCache = self._nomemo
    If self._PutSqlCache &= null
      self._PutSqlCache &= new StringTheory
    end
    self._PutSqlCache.SetValue(self.SqlCode)
    Return self.Stmt_Put
  End
  Return 0

!-----------------------------------------------------------------
DriverFileSQLite2Class._PrepareRandom  Procedure(String pFilter, BIGINT pOffset)
stmt   Long
  Code
  If Self._RandomSql(pFilter, pOffset) = driver:ok
    stmt = self._prepare()
  End
  Return stmt

!-----------------------------------------------------------------
! note that this is the FILE set, not the VIEW set, however prop:order and prop:filter are in play
! this is called at the end of a SET, and also inside NextPrevious if the direction changes
DriverFileSQLite2Class._GenerateSelect            Procedure(Long pOpcode)
result Long ,Auto
  Code
  If self.CheckConnect() = driver:notok then Return.
  If self.opt:explain or self._logExplain or self.Explain
    self._explain = True
  End
  If self._SelectSql(pOpCode) = driver:ok
    If self.Stmt_Set
      result = sqlite3_finalize(self.Stmt_Set)
      self.SetErrorSqlite(result,'[p055]')
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
DriverFileSQLite2Class.SetOrderByFromQueue            Procedure()
OrderBy      Stringtheory
x            Long,Auto
  code
  Loop x = 1 to Records(self.OrderQueue)                       ! Turn the OrderBy queue into SQLite SQL code.
    Get(self.OrderQueue,x)
    OrderBy.Append(self.OrderQueue.Clause,,',')
    If self.OrderQueue.Nocase
      OrderBy.Append(' COLLATE NOCASE')
    End
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
! If the File is in paging mode, then in order to find the next page, all the order values need to be in the filter.
! uses self.OrderQueue and prop:where as input, self.wherePage as output
DriverFileSQLite2Class._AppendOrderQueueToWhere  Procedure()
  code

!-----------------------------------------------------------------
DriverFileSQLite2Class._BindParameters  Procedure(Long pStmt)
x       Long,Auto
y       Long,Auto
p       Long,Auto
result  Long,Auto
Len     Long,Auto
addr    Long,Auto
  code
  If self.ParameterQueue &= null then return driver:ok.
  If self._ParameterOpcode = 0 then return driver:ok.
  PushErrors()
  If self._SearchParameter
    If self._logBind then self.Log('[BIND][sb3]' & self._SearchParameter & ' (real)' & self.SearchRank).
    result = sqlite3_bind_double(pStmt,self._SearchParameter,self.SearchRank)
  End
  Loop y = 1 to Records(self.ParameterQueue)
    Get(self.ParameterQueue,y)
    Loop x = 1 to self.ParameterQueue.ParameterArrayIndex
      If self.ParameterQueue.ParameterArray[x].OpCode <> self._ParameterOpcode then cycle.
      If not self.ParameterQueue.ParameterArray[x].Value &= null
        len = len(self.ParameterQueue.ParameterArray[x].Value)
        If self._logBind then self.Log('[BIND][sb4]' & self.ParameterQueue.ParameterArray[x].Count & ' (string)' & self.ParameterQueue.ParameterArray[x].Value).
        result = sqlite3_bind_textA(pStmt,self.ParameterQueue.ParameterArray[x].Count ,self.ParameterQueue.ParameterArray[x].Value, len ,SQLITE_STATIC)
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
        self._BindField(pStmt,self.ParameterQueue.ParameterArray[x].Count,addr)
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
DriverFileSQLite2Class._BindBlob  Procedure(Long pStmt,Long pCount)
result  long,auto
  code
  If self.blobs.Memo
    If not self.Blobs.memostring &= null
      If Self.Blobs.Binary
        If self._logBind then self.Log('[BIND][sb5]' & pCount & ' (memo)' & self.Blobs.memostring).
        result = sqlite3_bind_blob(pStmt,pCount,address(self.Blobs.memostring), Self.Blobs.memosize ,SQLITE_STATIC)
        self.SetErrorSqlite(result,'[p060]')
      Else
        If self._logBind then self.Log('[BIND][sb6]' & pCount & ' (memo)' & self.Blobs.memostring).
        result = sqlite3_bind_text(pStmt,pCount,address(self.Blobs.memostring), len(clip(self.Blobs.memostring)) ,SQLITE_STATIC)
        self.SetErrorSqlite(result,'[p061]')
      End
    Else
      If self._logBind then self.Log('[BIND][sb7]' & pCount & ' (null)').
      result = sqlite3_bind_null(pStmt,pCount)
    End
  Else
    If self.Blobs.handle
      If Self.Blobs.Binary
        If self._logBind then self.Log('[BIND][sb8]' & pCount & ' (blob)').
        result = sqlite3_bind_blob(pStmt,pCount,self.Blobs.handle, Self.Blobs.HandleSize ,SQLITE_STATIC)
        self.SetErrorSqlite(result,'[p062]')
      Else
        If self._logBind then self.Log('[BIND][sb9]' & pCount & ' (blob)').
        result = sqlite3_bind_text(pStmt,pCount,self.Blobs.handle, Self.Blobs.HandleSize ,SQLITE_STATIC)
        self.SetErrorSqlite(result,'[p063]')
      End
    Else
      If self._logBind then self.Log('[BIND][sb10]' & pCount & ' (null)').
      result = sqlite3_bind_null(pStmt,pCount)
    End
  End

!-----------------------------------------------------------------
! binds one field to a parameter. Source of the field is the mem address in the 3rd parameter.
! The self.Fields queue must be loaded with the correct record before this is called.
! Do not call this for Blob or Memo fields.
DriverFileSQLite2Class._BindField  Procedure(Long pStmt,Long pCount, Long pAddress)
result  long,auto
len     long,auto
p       long,auto
sqtype  string(20),auto
strmem  &string
cstr    &cstring
pstr    &pstring
bin     string(16),auto
sx      string(32),auto
bt      byte,over(sx)
sh      short,over(sx)
ush     ushort,over(sx)
lg      long,over(sx)
ulg     ulong,over(sx)
rl      real,over(sx)
srl     sreal,over(sx)
dt      date,over(sx)
tm      time,over(sx)
i64     Group,pre()
lo        ulong
hi        Long
        End

  code
  If not self.Fields.Interface &= null
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
           If self._logBind then self.Log('[BIND][sb11]' & pCount & ' (byte)' & bt).
          result = sqlite3_bind_int(pStmt,pCount,bt)
          self.SetErrorSqlite(result,'[p070]')
        of 2
        If self._logBind then self.Log('[BIND][sb12]' & pCount & ' (short)' & sh).
          result = sqlite3_bind_int(pStmt,pCount,sh)
          self.SetErrorSqlite(result,'[p071]')
        of 4
          If self._logBind then self.Log('[BIND][sb3]' & pCount & ' (long)' & lg).
          result = sqlite3_bind_int(pStmt,pCount,lg)
          self.SetErrorSqlite(result,'[p072]')
        of 8
          !!!todo int64
        End
      of 'REAL'
      orof 'FLOAT'
      orof 'DOUBLE'
        If self._logBind then self.Log('[BIND][sb14]' & pCount & ' (real)' & rl).
        result = sqlite3_bind_double(pStmt,pCount,rl)
        self.SetErrorSqlite(result,'[p073]')
      of 'SREAL'
        If self._logBind then self.Log('[BIND][sb15]' & pCount & ' (sreal)' & srl).
        result = sqlite3_bind_double(pStmt,pCount,srl)
        self.SetErrorSqlite(result,'[p074]')
      of 'TEXT'
      orof 'CHAR'
      orof 'NCHAR'
      orof 'VARCHAR'
      orof 'NVARCHAR'
        If self._logBind then self.Log('[BIND][sb16]' & pCount & ' (string)' & strmem).
        result = sqlite3_bind_textA(pStmt,pCount,strmem, len ,SQLITE_TRANSIENT)
        self.SetErrorSqlite(result,'[p075]')
      End
      Dispose(strmem)
    End
  ElsIf self.Fields.DimProduct > 1
    do HandleArray
  Else
    p = self.Fields.index
    If self.null_(p) = true
      If self._logBind then self.Log('[BIND][sb17]' & pCount & ' (null)').
      result = sqlite3_bind_null(pStmt,pCount)
      self.SetErrorSqlite(result,'[p077]')
      Return
    End
    self.Fields &= self._WithFieldNode(p)
    strmem &= pAddress & ':' & self.Fields.Length
    sx = strmem
    Case self.Fields.Type
    Of ClaCSTRING
      cstr &= pAddress & ':' & self.Fields.Length
      len = len(cstr)
      If self._logBind then self.Log('[BIND][sb18]' & pCount & ' (cstring)' & cstr).
      result = sqlite3_bind_text(pStmt,pCount,pAddress, len,SQLITE_TRANSIENT)
      self.SetErrorSqlite(result,'[p078]')

    Of ClaPSTRING
      peek(pAddress,bt)
      len = bt
      If self._logBind then self.Log('[BIND][sb19]' & pCount & ' (pstring)' & strmem).       !!!todo bug here
      result = sqlite3_bind_text(pStmt,pCount,pAddress+1, len,SQLITE_TRANSIENT)
      self.SetErrorSqlite(result,'[p079]')

    Of ClaSTRING
      If self.fields.SqlTimeStamp
        sx = self.FormatTimeStamp(sx)
        len = len(clip(sx))
        If self._logBind then self.Log('[BIND][sb20]' & pCount & ' (timestamp)' & sx).
        result = sqlite3_bind_text(pStmt,pCount,address(sx), len ,SQLITE_TRANSIENT)
      ElsIf self.Fields.binary = false
        len = len(clip(strmem))
        If self._logBind then self.Log('[BIND][sb21]' & pCount & ' (string: ' & len & ')[' & strmem & ']').
        result = sqlite3_bind_text(pStmt,pCount,pAddress, len ,SQLITE_TRANSIENT)
        self.SetErrorSqlite(result,'[p080]')
      Else
        len = self.Fields.Length
        If self._logBind then self.Log('[BIND][sb22]' & pCount & ' (binarystring: ' & len & ')[' & strmem & ']').
        result = sqlite3_bind_blob(pStmt,pCount,pAddress, len ,SQLITE_TRANSIENT)
      End
    of ClaREAL
      If self._logBind then self.Log('[BIND][sb23]' & pCount & ' (real)' & rl).
      result = sqlite3_bind_double(pStmt,pCount,rl)
      self.SetErrorSqlite(result,'[p081]')

    of ClaSREAL
      If self._logBind then self.Log('[BIND][sb24]' & pCount & ' (sreal)' & srl).
      result = sqlite3_bind_double(pStmt,pCount,srl)
      self.SetErrorSqlite(result,'[p082]')

    of ClaBYTE
      If self._logBind then self.Log('[BIND][sb25]' & pCount & ' (byte)' & bt).
      result = sqlite3_bind_int(pStmt,pCount,bt)
      self.SetErrorSqlite(result,'[p083]')

    of ClaSHORT
      If self._logBind then self.Log('[BIND][sb26]' & pCount & ' (short)' & sh).
      result = sqlite3_bind_int(pStmt,pCount,sh)
      self.SetErrorSqlite(result,'[p084]')

    of ClaUSHORT
      If self._logBind then self.Log('[BIND][sb27]' & pCount & ' (ushort)' & ush).
      result = sqlite3_bind_int(pStmt,pCount,ush)
      self.SetErrorSqlite(result,'[p085]')

    of ClaLong
      If self._logBind then self.Log('[BIND][sb28]' & pCount & ' (long)' & lg).
      result = sqlite3_bind_int(pStmt,pCount,lg)
      self.SetErrorSqlite(result,'[p086]')

    of ClaULong
      If self._logBind then self.Log('[BIND][sb29]' & pCount & ' (ulong)' & ulg).
      result = sqlite3_bind_int(pStmt,pCount,ulg)
      self.SetErrorSqlite(result,'[p087]')

    of ClaDate
      sx = self.FormatDate(dt)
      len = len(clip(sx))
      If self._logBind then self.Log('[BIND][sb31]' & pCount & ' (date)' & sx).
      result = sqlite3_bind_text(pStmt,pCount,address(sx), len ,SQLITE_TRANSIENT)
      self.SetErrorSqlite(result,'[p088]')

    of ClaTime
      sx = self.FormatTime(tm)
      len = len(clip(sx))
      If self._logBind then self.Log('[BIND][sb32]' & pCount & ' (time)' & sx).
      result = sqlite3_bind_text(pStmt,pCount,address(sx), len ,SQLITE_TRANSIENT)
      self.SetErrorSqlite(result,'[p089]')

    of ClaDecimal
    orof ClaPDecimal
      ! binding them as strings to preserve the numeric. SQLite will treat them as numerics though.
      self._DecToString(address(sx),self.Fields.length, self.Fields.DecimalSize,self.Fields.DecimalPlaces,self.Fields.Type,sx)
      len = len(clip(sx))
      If self._logBind then self.Log('[BIND][sb33]' & pCount & ' (decimal)' & sx).
      result = sqlite3_bind_text(pStmt,pCount,address(sx), len ,SQLITE_TRANSIENT)
      self.SetErrorSqlite(result,'[p090]')
    End
  End
  Return

HandleArray  routine
  data
arr StringTheory ! moved into a routine for performance
  code
    ! Array Support.  This will likely vary from one driver to another.
    ! In SQLite arrays become JSON fields, stored in a TEXT field
    arr.SetValue(self.GetProp:Json(self.Fields.Index))  ! get a JSON form of the Array
    If self._logBind then self.Log('[BIND][sb34]' & pCount & ' (array)' & arr.GetValue()).
    result = sqlite3_bind_text(pStmt,pCount,arr.GetAddress(), arr.Length() ,SQLITE_TRANSIENT)
    self.SetErrorSqlite(result,'[p076]')

!-----------------------------------------------------------------
! Data has come from the database, and is in the pStr "raw" (ie as it is in the database).
! It needs to move into the field in the record. The fieldsQueue is already loaded.
! In SQLite the data is stored in a Text Array, so all we need to do is call self._PutJsonAsField
DriverFileSQLite2Class._LoadArray        Procedure(*String pStr,Long pIndex)
  code
  self._PutJsonAsField(pStr,pIndex)

!-----------------------------------------------------------------
! data has been read, and is now moving from the SQL engine directly into the record.
! called from GET.
DriverFileSQLite2Class._ToRecord         PROCEDURE(Long pStmt, Long pBuffer)
cols          Long,Auto
x             Long,Auto
SQLFieldType  Long,Auto
rl            Real,Auto
lg            Long,Auto
str           &String,Auto
colname       &Cstring,Auto
Buffer        Long

dbAddress     Long
dbLength      Long
dbText        Byte
dbNull        Byte
canNull       Byte
rTextLen      Long
  code
  Case pBuffer
  of 0
  orof driver:buffer
    Buffer = self.ClaFCB.rec_buf
    canNull = true
  of driver:shadow
    Buffer = address(self.ShadowBuffer)
  of driver:nobuffer
  End

  cols = sqlite3_column_count(pStmt)

  If errorcode() = 0 and pBuffer <> driver:nobuffer
    Loop x = 0 to cols-1                                  ! loop through the result columns
      SQLFieldType = sqlite3_column_type(pStmt,x)
      colname &= sqlite3_column_name(pStmt,x)
      ! Get the address and length for the SQL data
      dbNull = false
      dbText = false
      rTextLen = 0
      Case SQLFieldType
      Of SQLITE_INTEGER
        lg =  sqlite3_column_int(pStmt,x)
        dbAddress = address(lg)
        dbLength = size(lg)
      Of SQLITE_FLOAT
        rl = sqlite3_column_double(pStmt,x)
        dbAddress = address(rl)
        dbLength = size(rl)
      Of SQLITE_TEXT
        dbAddress = sqlite3_column_text(pStmt,x)
        dbLength = sqlite3_column_bytes(pStmt,x)
        dbText = true
      Of SQLITE_BLOB
        dbAddress = sqlite3_column_blob(pStmt,x)
        dbLength = sqlite3_column_bytes(pStmt,x)
      Of SQLITE_NULL
        dbNull = true
      End
      If not colname &= null and self._WithFieldNamed(colname) = driver:ok        ! see if a FILE field matches this name. This is case insensitive.
        If dbNull
          self._SetFieldNull()
        ElsIf not self.Fields.Interface &= NULL
          self.Fields.interface.ToRecordField(self.Fields.Type,Buffer + self.Fields.Offset,self.Fields.length,SQLFieldType,dbAddress,dbLength)
        ElsIf self.Fields.DimProduct > 1                     ! field matching this column is an array. In SQLite this means a TEXT field, in JSON form. ! Parse the JSON and move the values into the record buffer
           If dbText
             str &= dbAddress & ':' & dbLength
             self._LoadArray(str,self.Fields.index)
           Else
             self._ClearField()
           End
        Else
          self._Morph(self.fields.label,self.Fields.type,Buffer + self.Fields.Offset,self.Fields.Length,SQLFieldType,dbAddress,dbLength,self.fields.SqlTimeStamp,true * canNull,rTextLen)
        End
      ElsIf self._WithBlobNamed(colname) = driver:ok   ! not a FILE field, so check for MEMO and BLOB
        If dbNull
          self.SetBlobProp:Value(self.blobs.index,'')
        ElsIf self.blobs.Memo
          self._Morph(self.blobs.label,ClaMemo,address(self.blobs.memostring),self.blobs.memosize,SQLFieldType,dbAddress,dbLength,0,false,rTextLen)
        else
          self._Morph(self.blobs.label,ClaBlob,self.blobs.index,self.blobs.handlesize,SQLFieldType,dbAddress,dbLength,0,false,rTextLen)
        End
        self.SetBlobCrc()
        Put(self.blobs)
      elsIf not self.BindQueue &= null
        self.BindQueue.Name = upper(colname)
        PushErrors()
        Get(self.BindQueue,self.BindQueue.Name)
        If Errorcode() = 0
          If not self.bindqueue.lg &= null
            self._Morph(self.BindQueue.Name,ClaLONG,address(self.bindqueue.lg),4,SQLFieldType,dbAddress,dbLength,0,false,rTextLen)
          ElsIf not self.bindqueue.rl &= null
            self._Morph(self.BindQueue.Name,ClaREAL,address(self.bindqueue.rl),8,SQLFieldType,dbAddress,dbLength,0,false,rTextLen)
          Elsif not self.bindqueue.st &= null
            self._Morph(self.BindQueue.Name,ClaSTRING,address(self.bindqueue.st),size(self.bindqueue.st),SQLFieldType,dbAddress,dbLength,0,false,rTextLen)
          Elsif not self.bindqueue.cst &= null
            self._Morph(self.BindQueue.Name,ClaCSTRING,address(self.bindqueue.cst),size(self.bindqueue.cst),SQLFieldType,dbAddress,dbLength,0,false,rTextLen)
          End
        End
        PopErrors()
      Else
        !!!todo match field by number, for dummy sql context.
        Self.trace('DriverFileSQLite2Class._ToRecord: Note: Incoming Field not found in structure: ' & colname)
      End
      If errorcode() then break.
    End
  End

!-----------------------------------------------------------------
! a function which copies data from the database format to the clarion format.
! this is a matrix which converts database types to Clarion types.
! This can be as simple, or as flexible as you want. In this case, since Clarion has automatica type conversion
! an so does SQLite, this function is quite long so as to handle as many cases as is possible. If it's not possible
! to store the SQL data into the Clarion type then errorcode is set to DataTruncatedError
! For databases which support a lot of types, this function could get VERY long.
! converting can take time, so matching the clarion type to the database type to begin with will speed things along.
! if the pClarionType is ClaBlob then pClarionAddress is the blob index (as a neg number)
! if the pClarionType is a ClaMEMO then the pClarionAddress and pClarionLength are set as normal
! if the pClarionType is a CLADECIMAL or CLAPDECIMAL then the Fields node has to be loaded. Otherwise fields is not used.
DriverFileSQLite2Class._Morph      Procedure(String pFieldLabel, Byte pClarionType, Long pClarionAddress, Long pClarionLength, Long pCellType, Long pCellAddress, Long pCellLength, Long pSqlTimeStamp, Byte pSetFieldNull, *Long rTextLength)
lg      long,Auto
sr      Sreal,Auto
rl      Real,Auto
ush     Ushort,Auto
cst     Cstring(21),Auto  !bigint range is -9 223 372 036 854 775 808 -- 18 446 744 073 709 551 615
len     Long,Auto
strmem  String(36),Auto
str     &string
StrLen  Long,Auto
  Code
  !self.trace('DriverFileSQLite2Class._Morph pFieldLabel=' & clip(pFieldLabel) & ' pClarionType=' & pClarionType & ' ' & self.InterpretType(pClarionType) & ' rTextLength=' & rTextLength & ' pCellType=' & pCellType & ' ' & self.InterpretSQLType(pCellType) & ' pCellLength=' & pCellLength)
  Case pCellType
!region - SQLITE_INTEGER
!------------------------------------------------
  Of SQLITE_INTEGER
    memcpy(address(lg),pCellAddress,4)   !!!todo limited to 32 bit integers for now
    Case pClarionType
!region -     ClaBYTE
    of ClaBYTE
      If band(lg,0FFFFFF00h) > 0 and self.opt:ignoretruncation = false
        self.SetError(DataTruncatedError)
        self.SetFileError(DataTruncatedError,'Field: ' & clip(pFieldLabel) & ' SQL Type: ' & self.InterpretSQLType(pCellType) & '(' & pCellType & ')' & ' Clarion Type: ' & self.InterpretType(pClarionType) & '(' & 1 & ')' & ' value: ' & lg)
        Return
      End
      memcpy(pClarionAddress,pCellAddress,1)
!endregion
!region -     ClaLONG
    of ClaLONG orof ClaSIGNED
      memcpy(pClarionAddress,pCellAddress,4)

!endregion
!region -     ClaSHORT
    of ClaSHORT
      If (lg < -32768 or lg > 32767) and self.opt:ignoretruncation = false
        self.SetError(DataTruncatedError)
        self.SetFileError(DataTruncatedError,'Field: ' & clip(pFieldLabel) & ' SQL Type: ' & self.InterpretSQLType(pCellType) & '(' & pCellType & ')' & ' Clarion Type: ' & self.InterpretType(pClarionType) & '(' & 2 & ')' & ' value: ' & lg)
        Return
      End
      memcpy(pClarionAddress,pCellAddress,2)

!endregion
!region -     ClaUSHORT
    of ClaUSHORT
      If band(lg,0FFFF0000h) > 0 and self.opt:ignoretruncation = false
        self.SetFileError(DataTruncatedError,'Field: ' & clip(pFieldLabel) & ' SQL Type: ' & self.InterpretSQLType(pCellType) & '(' & pCellType & ')' & ' Clarion Type: ' & self.InterpretType(pClarionType) & '(' & 2 & ')' & ' value: ' & lg)
        self.SetError(DataTruncatedError)
        Return
      End
      ush = lg
      memcpy(pClarionAddress,address(ush),2)
!endregion
!region -     ClaULONG
    of ClaULONG orof ClaUNSIGNED
      memcpy(pClarionAddress,pCellAddress,4)

    ! integers from the db can be stored in real fields in clarion.
    !!!todo support integers past long up to 15 digits
!endregion
!region -     ClaSREAL
    of ClaSREAL
      If (lg < -16777216 or lg > 16777216 )  and self.opt:ignoretruncation = false     ! sReal has 23 bits of integer space
        self.SetError(DataTruncatedError)
        self.SetFileError(DataTruncatedError,'Field: ' & clip(pFieldLabel) & ' SQL Type: ' & self.InterpretSQLType(pCellType) & '(' & pCellType & ')' & ' Clarion Type: ' & self.InterpretType(pClarionType) & '(' & 4 & ')' & ' value: ' & lg)
        Return
      End
      sr = lg
      memcpy(pClarionAddress,address(sr),4)

!endregion
!region -     ClaREAL
    of ClaREAL
      !!!todo support integers past long up to 15 digits
      rl = lg
      memcpy(pClarionAddress,address(rl),8)

!endregion
!region -     ClaDATE , ClaTIME
    of ClaDATE
    orof ClaTIME
      self.SetError(FieldMismatchError)
      self.SetFileError(FieldMismatchError,'Field: ' & clip(pFieldLabel) & ' SQL Type: ' & self.InterpretSQLType(pCellType) & '(' & pCellType & ')' & ' Clarion Type: ' & self.InterpretType(pClarionType) & '(' & pClarionType & ')' & ' value: ' & lg)
!endregion
!region -     ClaDECIMAL, ClaPDECIMAL
    of ClaDECIMAL
    orof ClaPDECIMAL
      !!!todo support integers past long
      strmem = lg
      self._StringToDec(strmem,self.Fields.Type, address(strmem), self.Fields.DecimalSize, self.Fields.DecimalPlaces)
      memcpy(pClarionAddress,address(strmem),pClarionLength)

!endregion
!region -     ClaSTRING ClaMEMO
    of ClaSTRING orof ClaMEMO
      !!! todo handle integers longer than a long
      cst = lg
      len = len(cst)
      If len > pClarionLength and self.opt:ignoretruncation = false
        self.SetError(DataTruncatedError)
        self.SetFileError(DataTruncatedError,'Field: ' & clip(pFieldLabel) & ' SQL Type: ' & self.InterpretSQLType(pCellType) & '(' & pCellType & ')' & ' Clarion Type: ' & self.InterpretType(pClarionType) & '(' & pClarionLength & ')' & ' value: ' & lg)
        Return
      End
      If len > pClarionLength then len = pClarionLength.
      memcpy(pClarionAddress,address(cst),len)
      StrLen = len
      If rTextLength = 0 then do PadString.
      rTextLength = Len

!endregion
!region -     ClaCSTRING
    of ClaCSTRING
      !!! todo handle integers longer than a long
      If pCellLength > 4 and self.opt:ignoretruncation = false
        self.SetError(DataTruncatedError)
        self.SetFileError(DataTruncatedError,'Field: ' & clip(pFieldLabel) & ' SQL Type: ' & self.InterpretSQLType(pCellType) & '(' & pCellType & ')' & ' Clarion Type: ' & self.InterpretType(pClarionType) & '(' & pClarionLength & ')' & ' value: ' & lg)
        Return
      End
      cst = lg
      len = len(cst)
      If len > pClarionLength and self.opt:ignoretruncation = false
        self.SetError(DataTruncatedError)
        Return
      End
      If len > pClarionLength-1 then len = pClarionLength-1.
      memcpy(pClarionAddress,address(cst),len+1)
      StrLen = len
      do PadString

!endregion
!region -     ClaPSTRING
    of ClaPSTRING
      !!! todo handle integers longer than a long
      If pCellLength > 4 and self.opt:ignoretruncation = false
        self.SetError(DataTruncatedError)
        self.SetFileError(DataTruncatedError,'Field: ' & clip(pFieldLabel) & ' SQL Type: ' & self.InterpretSQLType(pCellType) & '(' & pCellType & ')' & ' Clarion Type: ' & self.InterpretType(pClarionType) & '(' & pClarionLength & ')' & ' value: ' & lg)
        Return
      End
      cst = lg
      len = len(cst)
      If len + 1 > pClarionLength and self.opt:ignoretruncation = false
        self.SetError(DataTruncatedError)
        Return
      End
      If len > pClarionLength-1 then len = pClarionLength-1.
      memcpy(pClarionAddress+1,address(cst),len)
      memset(pClarionAddress,len,1)
      StrLen = len
      do PadString
!endregion
!region -     Else
    else
      self.SetError(FieldMismatchError)
      self.SetFileError(FieldMismatchError,'Field: ' & clip(pFieldLabel) & ' SQL Type: ' & self.InterpretSQLType(pCellType) & '(' & pCellType & ')' & ' Clarion Type: ' & self.InterpretType(pClarionType) & '(' & pClarionType & ')' & ' value: ' & lg)
!endregion
    End
!endregion
!region - SQLITE_FLOAT
!------------------------------------------------
  Of SQLITE_FLOAT
    case pClarionType
!region -     ClaREAL
    of ClaREAL
      memcpy(pClarionAddress,pCellAddress,8)
!endregion
!region -     ClaSREAL
    of ClaSREAL
      !!!todo, REAL into SREAL needs work to see if a) the integer part will fit, b) the exponent part will fit.  Using SREAL in the file declaration is thus not recommended.
      memcpy(address(rl),pCellAddress,8)
      If rl > 07fffffh and self.opt:ignoretruncation = false  ! sReal has 23 bits of integer space
        self.SetError(DataTruncatedError)
        self.SetFileError(DataTruncatedError,'Field: ' & clip(pFieldLabel) & ' SQL Type: ' & self.InterpretSQLType(pCellType) & '(' & pCellType & ')' & ' Clarion Type: ' & self.InterpretType(pClarionType) & '(' & 4 & ')' & ' value: ' & rl)
        Return
      End
      sr = rl
      memcpy(pClarionAddress,address(sr),4)

!endregion
!region -     ClaDECIMAL , ClaPDECIMAL
    of ClaDECIMAL
    orof ClaPDECIMAL
      memcpy(address(rl),pCellAddress,8)
      !!!todo - some sort of range check to see if the real "fit" into the declared decimal field. Note that decimal field may have fewer decimal places. That's not neceessarily a truncation.
      strmem = rl
      self._StringToDec(strmem,self.Fields.Type, address(strmem), self.Fields.DecimalSize, self.Fields.DecimalPlaces)
      memcpy(pClarionAddress,address(strmem),pClarionLength)

!endregion
!region -     ClaSTRING , ClaMEMO
    of ClaSTRING orof ClaMEMO
      memcpy(address(rl),pCellAddress,8)
      cst = rl
      len = len(cst)
      If len > pClarionLength and self.opt:ignoretruncation = false
        self.SetError(DataTruncatedError)
        self.SetFileError(DataTruncatedError,'Field: ' & clip(pFieldLabel) & ' SQL Type: ' & self.InterpretSQLType(pCellType) & '(' & pCellType & ')' & ' Clarion Type: ' & self.InterpretType(pClarionType) & '(' & pClarionLength & ')' & ' value: ' & rl)
        Return
      End
      If len > pClarionLength then len = pClarionLength.
      memcpy(pClarionAddress,address(cst),len)
      StrLen = len
      If rTextLength = 0 then do PadString.
      rTextLength = Len

!endregion
!region -     ClaCSTRING
    of ClaCSTRING
      memcpy(address(rl),pCellAddress,8)
      cst = rl
      len = len(cst)
      If len > pClarionLength and self.opt:ignoretruncation = false
        self.SetError(DataTruncatedError)
        self.SetFileError(DataTruncatedError,'Field: ' & clip(pFieldLabel) & ' SQL Type: ' & self.InterpretSQLType(pCellType) & '(' & pCellType & ')' & ' Clarion Type: ' & self.InterpretType(pClarionType) & '(' & pClarionLength & ')' & ' value: ' & rl)
        Return
      End
      If len > pClarionLength-1 then len = pClarionLength-1.
      StrLen = len
      memcpy(pClarionAddress,address(cst),len+1)
      do PadString

!endregion
!region -     ClaPSTRING
    of ClaPSTRING
      memcpy(address(rl),pCellAddress,8)
      cst = rl
      len = len(cst)
      If len + 1 > pClarionLength and self.opt:ignoretruncation = false
        self.SetError(DataTruncatedError)
        self.SetFileError(DataTruncatedError,'Field: ' & clip(pFieldLabel) & ' SQL Type: ' & self.InterpretSQLType(pCellType) & '(' & pCellType & ')' & ' Clarion Type: ' & self.InterpretType(pClarionType) & '(' & pClarionLength & ')' & ' value: ' & rl)
        Return
      End
      If len > pClarionLength-1 then len = pClarionLength-1.
      memcpy(pClarionAddress+1,address(cst),len)
      memset(pClarionAddress,len,1)
      StrLen = len
      do PadString
!endregion
!region -     Else
    else
      memcpy(address(rl),pCellAddress,8)
      self.SetError(FieldMismatchError)
      self.SetFileError(FieldMismatchError,'Field: ' & clip(pFieldLabel) & ' SQL Type: ' & self.InterpretSQLType(pCellType) & '(' & pCellType & ')' & ' Clarion Type: ' & self.InterpretType(pClarionType) & '(' & pClarionLength & ')' & ' value: ' & rl)
!endregion
    End
!endregion
!region - SQLITE_TEXT
!------------------------------------------------
  Of SQLITE_TEXT
    If pClarionType = ClaSTRING and pSqlTimeStamp   ! Special Case
      str &= pCellAddress & ':' & pCellLength
      strmem = self.DeformatText(str)
      If pClarionLength < 8 and self.opt:ignoretruncation = false
        self.SetError(DataTruncatedError)
        self.SetFileError(DataTruncatedError,'Field: ' & clip(pFieldLabel) & ' SQL Type: ' & self.InterpretSQLType(pCellType) & '(' & pCellLength & ')' & ' Clarion Type: ' & self.InterpretType(pClarionType) & '(' & pClarionLength & ')' & ' value: ' & str)
        Return
      End
      memcpy(pClarionAddress,address(strmem),8)
    Else
      Case pClarionType
!region -     ClaDATE
      of ClaDATE
          str &= pCellAddress & ':' & pCellLength
          strmem = self.DeformatText(str)
          memcpy(pClarionAddress,address(strmem),4)
!endregion
!region -     ClaTIME
      of ClaTIME
          str &= pCellAddress & ':' & pCellLength
          strmem = self.DeformatText(str)
          memcpy(pClarionAddress,address(strmem),4)
!endregion
!region -     ClaCSTRING
      of ClaCSTRING
          len = pCellLength
          If pClarionLength < len + 1 and self.opt:ignoretruncation = false
            str &= pCellAddress & ':' & pCellLength
            self.SetFileError(DataTruncatedError,'Field: ' & clip(pFieldLabel) & ' SQL Type: ' & self.InterpretSQLType(pCellType) & '(' & pCellLength & ')' & ' Clarion Type: ' & self.InterpretType(pClarionType) & '(' & pClarionLength & ')' & ' value: ' & str)
            self.SetError(DataTruncatedError)
            Return
          End
          If len > pClarionLength-1 then len = pClarionLength-1.
          memcpy(pClarionAddress,pCellAddress,len)
          memset(pClarionAddress+len,0,1)
          StrLen = Len
          do PadString
!endregion
!region -     ClaSTRING , CLAMEMO
      of ClaSTRING
      orof ClaMEMO
          len = pCellLength
          If pClarionLength < len and self.opt:ignoretruncation = false
            str &= pCellAddress & ':' & pCellLength
            self.SetError(DataTruncatedError)
            self.SetFileError(DataTruncatedError,'Field: ' & clip(pFieldLabel) & ' SQL Type: ' & self.InterpretSQLType(pCellType) & '(' & pCellLength & ')' & ' Clarion Type: ' & self.InterpretType(pClarionType) & '(' & pClarionLength & ')' & ' value: ' & str)
            Return
          End
          If len > pClarionLength then len = pClarionLength.
          memcpy(pClarionAddress,pCellAddress,Len)
          StrLen = len
          If rTextLength = 0 then do PadString.
          rTextLength = pCellLength

!endregion
!region -     ClaPSTRING
      of ClaPSTRING
          len = pCellLength
          If pClarionLength < len + 1 and self.opt:ignoretruncation = false
            str &= pCellAddress & ':' & pCellLength
            self.SetError(DataTruncatedError)
            self.SetFileError(DataTruncatedError,'Field: ' & clip(pFieldLabel) & ' SQL Type: ' & self.InterpretSQLType(pCellType) & '(' & pCellLength & ')' & ' Clarion Type: ' & self.InterpretType(pClarionType) & '(' & pClarionLength & ')' & ' value: ' & str)
            Return
          End
          If len > pClarionLength-1 then len = pClarionLength-1.
          memcpy(pClarionAddress+1,pCellAddress,pCellLength)
          memset(pClarionAddress,pCellLength,1)
          StrLen = len
          do PadString

!endregion
!region -     ClaBLOB
      of ClaBLOB
        self.SetBlobFromAddr(pClarionAddress, 0, pCellAddress, pCellLength)      ! if ClaBlob then pClarionAddress is the blob index
!endregion
!region -     else
      else
        str &= pCellAddress & ':' & pCellLength
        self.SetError(FieldMismatchError)
        self.SetFileError(FieldMismatchError,'Field: ' & clip(pFieldLabel) & ' SQL Type: ' & self.InterpretSQLType(pCellType) & '(' & pCellType & ')' & ' Clarion Type: ' & self.InterpretType(pClarionType) & '(' & pClarionType & ')' & ' value: ' & str)
!endregion
      End
    End

!endregion
!region - SQLITE_BLOB
!------------------------------------------------
  Of SQLITE_BLOB
    Case pClarionType
!region -     ClaBLOB
    of ClaBLOB
      self.SetBlobFromAddr(pClarionAddress, 0, pCellAddress, pCellLength)      ! if ClaBlob then pClarionAddress is the blob index
!endregion
!region -     ClaSTRING , ClaMEMO
    of ClaSTRING
    orof ClaMEMO
      len = pCellLength
      str &= pCellAddress & ':' & pCellLength
      If pClarionLength < len and self.opt:ignoretruncation = false
        self.SetError(DataTruncatedError)
        self.SetFileError(DataTruncatedError,'Field: ' & clip(pFieldLabel) & ' SQL Type: ' & self.InterpretSQLType(pCellType) & '(' & pCellLength & ')' & ' Clarion Type: ' & self.InterpretType(pClarionType) & '(' & pClarionLength & ')' & ' value: ' & str)
        Return
      End
      If len > pClarionLength then len = pClarionLength.
      memcpy(pClarionAddress,pCellAddress,len)
      StrLen = len
      If rTextLength = 0 then do PadString.
      rTextLength = pCellLength

!endregion
!region -     ClaCSTRING
    of ClaCSTRING
      len = pCellLength
      str &= pCellAddress & ':' & pCellLength
      If pClarionLength < len + 1 and self.opt:ignoretruncation = false
        self.SetError(DataTruncatedError)
        self.SetFileError(DataTruncatedError,'Field: ' & clip(pFieldLabel) & ' SQL Type: ' & self.InterpretSQLType(pCellType) & '(' & pCellLength & ')' & ' Clarion Type: ' & self.InterpretType(pClarionType) & '(' & pClarionLength & ')' & ' value: ' & str)
        Return
      End
      If len > pClarionLength-1 then len = pClarionLength-1.
      memcpy(pClarionAddress,pCellAddress,pCellLength)
      memset(pClarionAddress+pCellLength+1,0,1)
      StrLen = len
      do PadString

!endregion
!region -     ClaPSTRING
    of ClaPSTRING
      len = pCellLength
      str &= pCellAddress & ':' & pCellLength
      If pClarionLength < len + 1 and self.opt:ignoretruncation = false
        self.SetError(DataTruncatedError)
        self.SetFileError(DataTruncatedError,'Field: ' & clip(pFieldLabel) & ' SQL Type: ' & self.InterpretSQLType(pCellType) & '(' & pCellLength & ')' & ' Clarion Type: ' & self.InterpretType(pClarionType) & '(' & pClarionLength & ')' & ' value: ' & str)
        Return
      End
      If len > pClarionLength-1 then len = pClarionLength-1.
      memcpy(pClarionAddress+1,pCellAddress,pCellLength)
      memset(pClarionAddress,pCellLength,1)
      StrLen = len
      do PadString
!endregion
!region -     else
    else
      str &= pCellAddress & ':' & pCellLength
      If pClarionLength < pCellLength and self.opt:ignoretruncation = false
        self.SetError(DataTruncatedError)
        self.SetFileError(DataTruncatedError,'Field: ' & clip(pFieldLabel) & ' SQL Type: ' & self.InterpretSQLType(pCellType) & '(' & pCellLength & ')' & ' Clarion Type: ' & self.InterpretType(pClarionType) & '(' & pClarionLength & ')' & ' value: ' & str)
        Return
      End
      memcpy(pClarionAddress,pCellAddress,pCellLength)
!endregion
    End
!endregion
!region - SQLITE_NULL
!------------------------------------------------
  Of SQLITE_NULL
    case pClarionType
!region -     ClaBLOB
    of ClaBLOB
      self.SetBlobFromAddr(pClarionAddress, 0, pCellAddress, pCellLength)      ! if ClaBlob then pClarionAddress is the blob index
!endregion
!region -     ClaMEMO
    of ClaMEMO
      StrLen = 0
      do PadString
!endregion
!region -     Else
    Else
      If pSetFieldNull
        self._SetFieldNull()
      End
!endregion
    End
!endregion
  End

! StrLen is the length of the incoming sql string (not including the terminating 0) - which may be less than the clarion string.
PadString  routine
  If pClarionLength > StrLen and StrLen >= 0
    Case pClarionType
    of ClaSTRING  orof ClaMEMO
       memset(pClarionAddress + StrLen ,32, pClarionLength - StrLen)             ! pad with spaces
    of ClaCSTRING
       memset(pClarionAddress + StrLen ,0, pClarionLength - StrLen)              ! pad with zeros
    of ClaPSTRING
      If pClarionLength-1 > StrLen
        memset(pClarionAddress + StrLen + 1,32, pClarionLength - StrLen - 1)     ! pad with spaces
      End
    End
  End

!-----------------------------------------------------------------
DriverFileSQLite2Class.ExplainStart      Procedure()
  Code
  Return 'EXPLAIN QUERY PLAN '

!-----------------------------------------------------------------
! File Methods
!-----------------------------------------------------------------
!-----------------------------------------------------------------
! Syntax for REINDEX differs from database to database
DriverFileSQLite2Class.BUILD            PROCEDURE()
  Code
  Self.SetError(NoError)
  If self.CheckConnect() <> driver:ok then return.
  self.SqlCode.setvalue('REINDEX ' & self._sanitize(self.FullPathName,driver:sqlTable) & ';')
  self._ParameterOpcode = 0
  If self._executeSql() = Driver:ok
  End
  Return

!-----------------------------------------------------------------
DriverFileSQLite2Class.BUILD            PROCEDURE(KEY pKey)
  Code
  Self.SetError(NoError)
  If self._withkey(pKey) = driver:ok
    If self.keys.primary
      self.Build()   ! in SQLite the Primary key is not a separate Index, so rebuilding the primary key is the same as building the file.
    Else
      self.SqlCode.setvalue('REINDEX ' & self._sanitize(self.FullPathName & '_' & self.keys.dbName,driver:sqlTable) & ';')
      self._ParameterOpcode = 0
      If self._executeSql() = Driver:ok
      End
    End
  End
  Return

!-----------------------------------------------------------------
DriverFileSQLite2Class.CLOSE            PROCEDURE()
  Code
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
DriverFileSQLite2Class.CheckConnect        PROCEDURE()
  Code
  If self._opened and self.dbHandle
    ! SQLite cannot "lose" a connection - it's a DLL - but other drivers may want to check the connection is ok as well.
    return driver:ok                                                            ! If the table is open, then connection is fine.
  End
  self._UpdateFileStrings()
  If self.dbHandle  and self.Owner = self._ConnectedAs and self.pool = self._ConnectedPool
    ! SQLite cannot "lose" a connection - it's a DLL - but other drivers may want to check the connection is ok as well.
    return driver:ok
  End
  If self.dbHandle <> 0 then self.Disconnect().                                 ! Owner has changed, so disconnect from old connection
  self.Connect()                                                                ! SQLITE: This will trigger an OPEN to the disk file, and create that disk file if necessary.
  If Errorcode() then return driver:notok.
  Return driver:ok

!-----------------------------------------------------------------
DriverFileSQLite2Class.CONNECT             PROCEDURE(Long pOptions=0)
result  long,Auto
str     stringtheory
owner   cstring(DRIVER:MAXOWNER),Auto
  code
  parent.Connect(pOptions)
  If ErrorCode() Then Return.

  str.SetValue(self.Owner)
  str.ToUnicode(st:EncodeUtf8,self.codepage)
  owner = str.GetValue()

  If pOptions = 0
    pOptions =  SQLITE_OPEN_READWRITE + SQLITE_OPEN_CREATE
  End

  If lower(sub(owner,1,5)) = 'file:'
    pOptions = Bor(pOptions,SQLITE_OPEN_URI)
  End

  self.dbHandle = ConnectionPoolSQlite2.GetConnection(Owner,self.Pool,pOptions)
  If self.dbHandle = 0
    result = sqlite3_open_v2(self.Owner,address(self.dbHandle), pOptions ,0)
    If result = SQLite_Ok
      If self._logConnections then self.Log('[CONN] New Connection. Handle= ' & self.dbHandle & ' ' & Owner) .
      ConnectionPoolSQlite2.SetConnection(Owner,self.Pool,pOptions,self.dbHandle)
      self._ConnectedAs = self.Owner                                                  ! not owner. We want to be able to compare to self.owner later
      self._ConnectedPool = self.Pool
      self.SetError(NoError)
      self.AfterConnect()
    Else
      If self._logConnections then self.Log('[CONN] Connection Failed. [' & Owner & ']') .
      self._ConnectedAs = ''
      self._ConnectedPool = 0
      self.SetErrorSqlite(result,'[p100]')
    End
  else
    If self._logConnections then self.Log('[CONN] Connection Reused. Handle= ' & self.dbHandle).
    self._ConnectedAs = self.Owner                                                    ! not owner. We want to be able to compare to self.owner later
    self._ConnectedPool = self.Pool
  End

  If Errorcode() = NoError
    str.Start()
    str.SetValue(self.SqlCode)  ! Connect might happen when trying to execute another command. So preserve that command here.
    Self._GetDBVersion()
    self.SqlCode.SetValue(str)
  End
  Return

!-----------------------------------------------------------------
! Called whenever a new connection is established. Code here should run on any new connection.
! bear in mind that connections are pooled, so this isn't necessarily called for every object.
DriverFileSQLite2Class.AfterConnect  procedure
result  long
  code
  result = sqlite3_extended_result_codes(self.dbHandle,1) ! turns on extended codes
  result = sqlite3_busy_timeout(self.dbHandle,self.opt:BusyTimeout)
  Return

!-----------------------------------------------------------------
DriverFileSQLite2Class.COPY             PROCEDURE(STRING pNewTableName, Long pOptions)
cstr        Cstring(size(pNewTableName)+1)
stmt        Long
len         Long
result      Long
fieldlist   StringTheory
where       StringTheory
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
  If self._executeSql(self.SqlCode) = driver:ok     ! deliberatly go to the non-bindparameters version of the method.
    ! table does not exist, will create table
    self.SqlCode.setvalue('SELECT sql FROM sqlite_master WHERE type= ''table'' AND name = ''' & self._sanitize(self.FullPathName,driver:sqlTable) & ''';' )
    If self._executeSql(self.SqlCode) = driver:ok    ! deliberatly go to the non-bindparameters version of the method.
      If self.result.Rows()
        self.SqlCode.setvalue(self.result.GetCell(1,1) & ';')
        self.SqlCode.replace(clip(self.FullPathName),cstr,1,1,0,false)
        If self._executeSql(self.SqlCode) = driver:ok     ! deliberatly go to the non-bindparameters version of the method.
          cmd.append(self.SqlCode,,'<13,10>')
          ! table is now created, so copy data across
          self.SqlCode.setvalue('INSERT INTO ' & cstr & ' (' & fieldlist.GetValue() & ') SELECT ' & fieldlist.GetValue() & ' FROM ' & self._sanitize(self.FullPathName,driver:sqlTable) & ' ' & self._GetAlias(driver:nodot) )
          If where.length() > 0
            self.SqlCode.Append(' WHERE ' & where.getValue())
          End
          offset = self.GetPROP:Offset()
          limit = self.GetPROP:Limit()
          If offset and limit = 0 then limit = -1.
          If offset
            self.SqlCode.Append(' LIMIT ' & limit & ' OFFSET ' & offset)
          Elsif limit
            self.SqlCode.Append(' LIMIT ' & limit)
          End
          self.SqlCode.Append(';')

          If self._executeSql() = driver:ok
            cmd.append(self.SqlCode,,'<13,10>')
          End
        End
      End
    End
  End
  self.SqlCode.SetValue(cmd)
  self.ClearProps()  ! clears all the properties (not prop:sql)
  Return

!-----------------------------------------------------------------
! breaking this into a separate method allows it to be called without the parent checks.
DriverFileSQLite2Class._CREATETABLE      PROCEDURE()
col           Long  ,Auto
x             Long  ,Auto
primaryset    Byte
primaryextra  Byte
comma         Byte
allSql        StringTheory
  Code
  !self.trace('DriverFileSQLite2Class._CREATETABLE Path=' & longpath() )
  If self.opt:dummy then Return.   ! Dummy Tables are not created.
  If self.CheckConnect() = Driver:notok then Return.
  ! before this table can be created, all the parent tables need to be created.
  Loop x = 1 to Records(self.relations)
    Get(self.relations,x)
    If self.relations.ParentFile &= null then cycle.
    If Exists(self.relations.ParentFile) = FALSE
      Create(self.relations.ParentFile)
    End
  End

  primaryset = 0
  If self._withPrimaryKey() = Driver:ok
    If self.keys.components = 1
      If self._WithField(self.keys.component[1]) = driver:ok
        primaryset = self.keys.component[1]
      End
    End
    If self.keys.nocase
      Loop x = 1 to self.Keys.components
        If self._WithField(self.keys.component[x]) = driver:ok
          case self.fields.Type
          Of ClaSTRING
          OrOf ClaCSTRING
          OrOf ClaPSTRING
            primaryextra = True
            Break
          End
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
      self.SqlCode.append(' ' & self.Fields.SqlType)
    ElsIf not self.Fields.Interface &= Null
      self.SqlCode.append(' ' & self.Fields.interface.GetSQLType())
    ElsIf self.Fields.DimProduct > 1
      self.SqlCode.append(' TEXT')
    Else
      Case self.Fields.Type
      of ClaBYTE
      orof ClaSHORT
      orof ClaUSHORT
      orof ClalONG
      orof ClaUlONG
        self.SqlCode.append(' INTEGER')
      of ClaDATE
        self.SqlCode.append(' DATE')  ! will affinity to Numeric, but useful to distinguish.  will be stored as yyyy-mm-dd
      of ClaTIME
        self.SqlCode.append(' TIME')  ! will affinity to Numeric, but useful to distinguish   will be stored as hh:mm:ss.sss
      of ClaDECIMAL
      orof ClaPDECIMAL
        self.SqlCode.append(' NUMERIC(' & self.Fields.DecimalSize & ',' & self.Fields.DecimalPlaces & ')')
      of ClaREAL
      orof ClaSREAL
        self.SqlCode.append(' REAL')
      of ClaCSTRING
        self.SqlCode.append(' TEXT')
        If self.Fields.collate = ''
        !self.trace('CSTRING self.fields.column=' & self.fields.Column & ' ' & self.Fields.incase)
          case self.fields.InCase                       ! if -1 then not in any key. If true then in a Case Sensitive key. If False then in a non-sensitive key
          of true                                       ! is in a case sensitive key, so leave as case sensitive
            !self.SqlCode.append(' COLLATE RTRIM')
          of false                                      ! is in at least one case-insensitive key, and no case-insensitive keys, so make the default collation NoCase.
            self.SqlCode.append(' COLLATE NOCASE')
          of 255                                         ! strings not in any key,  default to leave it alone
            !self.SqlCode.append(' COLLATE RTRIM')
          End
        End
      of ClaSTRING
        If self.Fields.SqlTimeStamp
          self.SqlCode.append(' DATETIME')    ! will affinity to Numeric, but useful to distinguish will be stored as yyyy-mm-ddThh:mm:ss.sss
        ElsIf self.Fields.Binary = true
          self.SqlCode.append(' BLOB')
          If self.Fields.collate = '' then self.SqlCode.append(' COLLATE BINARY').
        Else
          self.SqlCode.append(' TEXT')
          If self.Fields.collate = ''
            !self.trace('STRING self.fields.column=' & self.fields.Column & ' ' & self.Fields.incase)
            ! SQLite doesn't allow for COLLATE NOCASE and RTRIM. There's also no database-wide default of Case Insensitive strings like say MsSql.
            ! For strings in NOCASE keys, default to COLLATE NOCASE, for other strings default to RTRIM
            case self.fields.InCase                       ! if -1 then not in any key. If true then in a Case Sensitive key. If False then in a non-sensitive key
            of true                                       ! is in a case sensitive key, so leave as case sensitive
              self.SqlCode.append(' COLLATE RTRIM')
            of false                                      ! is in at least one case-insensitive key, and no case-insensitive keys, so make the default collation NoCase.
              self.SqlCode.append(' COLLATE NOCASE')
            of 255                                         ! strings not in any key, default to RTRIM
              self.SqlCode.append(' COLLATE RTRIM')
            End
          End
        End
      of ClaPSTRING
        If self.Fields.Binary = true
          self.SqlCode.append(' BLOB')
          If self.Fields.collate = '' then self.SqlCode.append(' COLLATE BINARY').
        Else
          self.SqlCode.append(' TEXT')
          If self.Fields.collate = ''
            !self.trace('PSTRING self.fields.column=' & self.fields.Column & ' ' & self.Fields.incase)
            case self.fields.InCase                       ! if -1 then not in any key. If true then in a Case Sensitive key. If False then in a non-sensitive key
            of true                                       ! is in a case sensitive key, so leave as case sensitive
              !self.SqlCode.append(' COLLATE RTRIM')
            of false                                      ! is in at least one case-insensitive key, and no case-insensitive keys, so make the default collation NoCase.
              self.SqlCode.append(' COLLATE NOCASE')
            of 255                                        ! strings not in any key, default to leave it alone
              !self.SqlCode.append(' COLLATE RTRIM')
            End
          End
        End
      End
    End
    self._CreateValidation()
    If self.Fields.Collate
      self.SqlCode.append(' COLLATE ' & self.Fields.Collate)
    End
    self._CreateDefault(self.Fields.HasDefault, self.Fields.Type, Self.Fields.DefaultValue)
    If self.Fields.index = primaryset
      If self.opt:autoInc !or self.Fields.IsIdentity
        self.SqlCode.append(' PRIMARY KEY ASC AUTOINCREMENT')
      Else
        self.SqlCode.append(' PRIMARY KEY ASC')
      End
    End
  End
  ! blob and memo fields
  Loop col = 1 to records(self.blobs)
    Get(Self.Blobs,col)
    If comma
      self.SqlCode.append(',<13,10>')
    End
    If self.blobs.Binary = false
      self.SqlCode.append(self.blobs.column & ' TEXT COLLATE RTRIM')
    Else
      self.SqlCode.append(self.blobs.column & ' BLOB')
    End
    If self.blobs.NotNull
      self.SqlCode.append(' NOT NULL')
    End
    self._CreateDefault(self.blobs.HasDefault, Choose(self.blobs.Memo,ClaMEMO,ClaBLOB), Self.blobs.DefaultValue)
  End
  ! primary key
  If primaryset = false
    If self._withPrimaryKey() = driver:ok
      self.SqlCode.append(',<13,10>PRIMARY KEY (')
      self._ConstructKey(true)
    Else
      self.SetError(MissingPrimaryKeyErr)
      self.SetFileError(MissingPrimaryKeyErr,'Table does not have a Primary Key')
      Return
    End
  End

  self._CreateForeignKeys()

     ! constraints
  self.SqlCode.append('<13,10>)')

  ! table options
  If self.opt:NoPrimary
    self.SqlCode.append(' WITHOUT ROWID')
  End
  self.SqlCode.append(';<13,10>')
  self._ParameterOpcode = 0
  If self._executeSql() = Driver:notok
    Return
  End
  AllSql.SetValue(self.SqlCode)

  ! non-primary keys  and indexes
  Loop x = 1 to Records(self.keys)
    Get(self.keys,x)
    If self.keys.type = Cla_DynIndex then cycle.
    If self.keys.primary and primaryextra = false then cycle.
    self._ConstructKey(false)
    self.SqlCode.append(';<13,10>')
    If self._executeSql() = Driver:notok
      Return
    End
    AllSql.Append(self.SqlCode)
  End
  self.SqlCode.SetValue(allSql)
  Return

!-----------------------------------------------------------------
DriverFileSQLite2Class._ConstructKey   Procedure(Long pPrimary)
col           long ,Auto
comma         byte
  Code
  If pPrimary = false
    self.SqlCode.SetValue('CREATE ')
    If self.keys.dup = false then self.SqlCode.Append('UNIQUE ').
    self.SqlCode.Append('INDEX IF NOT EXISTS ' & self._sanitize(self.FullPathName & '_' & self.keys.dbName,driver:sqlTable) & ' ON ' & self._sanitize(self.FullPathName,driver:sqlTable) & ' (')
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

AddCheckToKey  routine
  If self._withField(self.keys.component[col]) = Driver:ok
    If col > 1
      self.SqlCode.append(' OR ')
    End
    self.SqlCode.append('(' & self.Fields.column & ' <<> '''' AND NOT ' & self.Fields.column & ' ISNULL)')
  end

AddFieldToKey  routine
  If self._withField(self.keys.component[col]) = Driver:ok
    If comma then self.SqlCode.Append(',').
    comma = true
    self.SqlCode.Append(self.Fields.column)
    Case self.Fields.Type
    of ClaSTRING
    orof ClaCSTRING
    orof ClaPSTRING    ! ok, so SQLite doesn't support PString, but if this code is cloned for another driver....
      If self.fields.binary
      ElsIf self.keys.nocase
        self.SqlCode.Append(' COLLATE NOCASE')
      End
    End
    If self.keys.descending[col]
      self.SqlCode.Append(' DESC')
    Else
      self.SqlCode.Append(' ASC')
    End
  End


!-----------------------------------------------------------------
!!!todo CreateField(field)
DriverFileSQLite2Class.CREATEFIELD                Procedure(*? pField1)
  Code
  Return

!-----------------------------------------------------------------
DriverFileSQLite2Class.CREATEFIELD                Procedure(String pName, String pType, String pConstraint)
  Code
  If self.CheckConnect() = Driver:notok then Return.   ! File can be OPEN. If closed a new connection is established.
  Self.SetError(NoError)
  self.SqlCode.setvalue('ALTER TABLE ' & self._sanitize(self.FullPathName,driver:sqlTable) & ' ADD COLUMN ' & self._sanitize(pName,driver:SqlColumn) & ' ' & clip(pType) & ' ' & clip(pConstraint) & ';')
  self._ParameterOpcode = 0
  If self._executeSql() = driver:ok
  End
  Return
  Return

!-----------------------------------------------------------------
DriverFileSQLite2Class.CREATEKEY         PROCEDURE(KEY pKey)
  Code
  self.SetError(NoDriverSupport)
  If self._WithKey(pKey) = Driver:ok
    self._ConstructKey(false)
    self.SqlCode.append(';<13,10>')
    If self._executeSql() = Driver:notok
      Return
    End
  End
  Return

!-----------------------------------------------------------------
DriverFileSQLite2Class.CREATEKEY         PROCEDURE(String pName, Long pOptions, *? pField1, *? pField2, <*? pField3>, <*? pField4>, <*? pField5>, <*? pField6>, <*? pField7>, <*? pField8>, <*? pField9>, <*? pField10>)
  Code
  self.SetError(NoDriverSupport)
  Return

!-----------------------------------------------------------------
DriverFileSQLite2Class.DECLARATION               Procedure(Long pOptions=0)
Ans     StringTheory
AllSql  StringTheory
x       Long
  Code
  If self.CheckConnect() = driver:notok then Return driver:notok.

  self.SqlCode.SetValue('Select sql from sqlite_master where type = ''table'' and name = '''& self._sanitize(self.FullPathName,driver:sqlTable) &''';')
  If self._executeSql() = driver:ok
    ans.SetValue(self.result.GetCell(1,1))
    If Band(pOptions,driver:keys)
      AllSql.SetValue(self.SqlCode)
      self.SqlCode.SetValue('Select sql from sqlite_master where type = ''index'' and tbl_name = '''& self._sanitize(self.FullPathName,driver:sqlTable) &''';')
      If self._executeSql() = driver:ok
        AllSql.Append(self.SqlCode,,'<13,10>')
        Loop x = 1 to self.Result.Rows()
          ans.Append(self.Result.GetCell(x,1),,';<13,10>')
        End
      End
    End
    ans.Append(';<13,10>')
  End
  Return ans.GetValue()

!-----------------------------------------------------------------
DriverFileSQLite2Class.DECLARATION               Procedure(Key pKey,Long pOptions=0)
  Code
  Return ''

!-----------------------------------------------------------------
! note that DUPLICATE can return false (will not create a duplicate) and the ADD can still fail
! because another client added the record in the meantime. In most cases it's better to detect the
! duplicate error after the ADD and handle appropriately.
DriverFileSQLite2Class.DUPLICATE        PROCEDURE(KEY pKey)
result   Long,Auto
stmt     Long,Auto
Ans      Long
  Code
  If self.CheckConnect() = driver:notok then Return ans.
  self._ParameterOpcode = Opcode:DUPLICATE
  If self._DuplicateSql(pKey) = driver:ok
    stmt = self._Prepare()
    If stmt
      If self._BindParameters(stmt) = Driver:ok
        self._ExecuteToResults(stmt,self.result)
        if self.result.GetCell(1,1) <> '0' then ans = true.
      End
      result = sqlite3_finalize(stmt)
      self.SetErrorSqlite(result,'[p105]')
      self._ClearParameterQueue(self._ParameterOpcode)
    End
  End
  Return ans

!-----------------------------------------------------------------
DriverFileSQLite2Class.EMPTY            PROCEDURE()
AllSql  StringTheory
  Code
  parent.Empty()
  If errorcode() then return.
  self.SqlCode.setvalue('DELETE FROM ' & self._sanitize(self.FullPathName,driver:sqlTable) & ';')
  AllSql.SetValue(self.SqlCode)
  self._ParameterOpcode = Opcode:EMPTY
  If self._executeSql() = driver:ok
    If self.SharedProperties.HasIdentity
      self.SqlCode.setvalue('DELETE FROM SQLITE_SEQUENCE WHERE name = ''' & self._sanitize(self.FullPathName,driver:sqlTable) & ''';')
      If self._executeSql() = driver:ok
        AllSql.Append(self.SqlCode)
      End
    End
  End
  Return  ! the second part may have failed, but the first part succeeded

!-----------------------------------------------------------------
! check to see if a table exists in the database
DriverFileSQLite2Class.EXISTS           PROCEDURE(String pTablename)     ! new command
tablename   cstring(255),Auto
poc         Long,Auto
  Code
  If self.CheckConnect() = Driver:notok     ! File can be OPEN. If closed a new connection is established.
    Return false
  End
  If pTablename
    tablename = self._sanitize(clip(pTablename),driver:sqlTable)
  Else
    tablename =  self._sanitize(self.FullPathName,driver:sqlTable)
  End
  If Tablename = ''
    Self.SetError(BadNameErr)
    Return false
  End
  Self.SetError(NoError)
  poc = self._ParameterOpcode
  self._ParameterOpcode = 0
  self.SqlCode.SetValue('SELECT name FROM sqlite_master WHERE type= ''table'' AND name = ''' & tablename & ''' COLLATE NOCASE;' )
  If self._executeSql() = driver:ok
    self._ParameterOpcode = poc
    If self.result.Rows()
      If lower(self.result.GetCell(1,1)) = lower(tablename)
        Return true
      End
    End
  End
  self._ParameterOpcode = poc
  Return false



!-----------------------------------------------------------------
DriverFileSQLite2Class.EXPORTCSV        PROCEDURE(String pDosFileName, Long pOptions=0)
append    Byte,Auto  ! driver:append
header    Byte,auto  ! driver:header
stmt      long,Auto
x         long,Auto
result    long,Auto
columns   long,Auto
str       StringTheory
val       StringTheory
colname   &cstring,Auto
coltext   &cstring,Auto
paging    Byte,auto
Addr      Long,auto
Len       Long,Auto

  Code
  If band(pOptions,driver:append) then append = true else append = false.
  If band(pOptions,driver:header) then header = true else header = false.

  If pDosFileName = driver:clipboard
    If append
      str.SetValue(Clipboard())
      If str.length() then header = false.
    End
  Else
    If Exists(pDosFileName) and str.FileSize(pDosFileName) > 0 and append
      header = false
    End
    If str.Stream(pDosFileName,10,Append) = st:notok
      self.SetError(FileSystemErr)
      Return driver:notok
    End
  End
  If self.CheckConnect() = driver:notok then Return driver:notok.
  paging = self.Paging
  self.Paging = false                     ! for SQLite there's no need to page, since it's a straight read-through
  self._GenerateSelect(Opcode:NEXT)       ! does the sql and the prepare.

  self.Paging = Paging
  If ErrorCode() then Return driver:notok.
  If self.Stmt_Set = 0
    self.SetError(FileSystemErr)
    If pDosFileName <> driver:clipboard then str.Flush().
    Return driver:notok
  End
  self._ParameterOpcode = Opcode:NEXT
  If self._BindParameters(Self.Stmt_Set) <> driver:ok
    self.SetError(FileSystemErr)
    If pDosFileName <> driver:clipboard then str.Flush().
    Return driver:notok
  End
  If self._OffsetParmNumber
    ! Bind OFFSET
    If self._logBind then self.Log('[BIND][sb35]' & self._OffsetParmNumber & ' (long)' & self._SetOffset).
    result = sqlite3_bind_int(self.Stmt_Set,self._OffsetParmNumber,self._SetOffset)
    self._SetOffset = 1
  End
  stmt = self.Stmt_Set
  self.Stmt_Set = 0
  If self._logSQL then self.Log('[SQL ]' & self.SqlCode.GetValue()).

  result = sqlite3_step(Stmt)  ! executes the sql and returns the first row
  columns = sqlite3_column_count(Stmt)
  ! possible header row
  If Header = true
    Loop x = 0 to columns - 1
      colname &= sqlite3_column_name(Stmt,x)
      str.Append(colname,,',')
    End
    str.Append('<13,10>')
  End
  ! loop through the data
  Loop
    case result
    of SQLite_Done
      break
    of SQLite_Row
      Loop x = 0 to columns - 1
        case sqlite3_column_type(stmt,x)
        of SQLITE_INTEGER
          Addr = sqlite3_column_text(Stmt,x)
          Len = sqlite3_column_bytes(Stmt,x)
          val.SetValueByAddress(Addr,Len)
        of SQLITE_FLOAT
          Addr = sqlite3_column_text(Stmt,x)
          Len = sqlite3_column_bytes(Stmt,x)
          val.SetValueByAddress(Addr,Len)
        of SQLITE_TEXT
          Addr = sqlite3_column_text(Stmt,x)
          Len = sqlite3_column_bytes(Stmt,x)
          val.SetValueByAddress(Addr,Len)
          val.CSVEncode(self.AlwaysQuote,self.Separator,self.LineEndings)
        of SQLITE_NULL
          val.setvalue(self.NullString)
        of SQLITE_BLOB
          addr = sqlite3_column_blob(Stmt,x)
          len = sqlite3_column_bytes(Stmt,x)
          val.SetValueByAddress(addr,len)
          If band(pOptions,Driver:Bin2Base64)
            val.Base64Encode(st:noWrap )
            val.Prepend('base64:')
          else
            val.ToHex(st:upper)
            val.Prepend('hex:')
          end
          If self.AlwaysQuote
            val.Prepend('"')
            val.Append('"')
          End
        End
        If x > 0 then str.Append(self.Separator).
        str.Append(val)
      End
      str.Append(self.LineEndings)
    Else
      self.SetErrorSqlite(result,'[p201]')
      Break
    End
    result = sqlite3_step(Stmt)  ! next row, and cycle.
  End

  result = sqlite3_finalize(stmt)
  If Errorcode()
    If pDosFileName <> driver:clipboard then str.Flush().
    Return driver:notok
  End
  If pDosFileName = driver:clipboard
    SetClipboard(str.GetValue())
  Else
    str.Flush()
  End
  Return driver:ok

!-----------------------------------------------------------------
! supports prop:project to limit the fields being added into SQL
DriverFileSQLite2Class.IMPORTCSV        PROCEDURE(String pDosFileName, Long pOptions=0)
Offset        BIGINT
Len           Long(10000000)  ! 10 megs'ish  ! must be longer than 2 lines can be, including blobs
str           StringTheory
lne           StringTheory
CsvCell       StringTheory

FieldsList    StringTheory
ValuesList    StringTheory
Excluded      StringTheory

sqlColumns    long,auto
sqlColumnName     Cstring(255),auto
sqlColumnNameSafe Cstring(255),auto
sqlColumnType long,dim(DRIVER:MAXFILEFIELDS)
sqlColumnNotNull Byte,dim(DRIVER:MAXFILEFIELDS)
csvColumns    long,Auto
mapColumns    long,dim(DRIVER:MAXFILEFIELDS)  ! not ,Auto
impColumns    long,Auto

header      byte

r           Real,auto
i           Long,auto
s           String(1)
x           Long,auto
y           Long,auto
recs        Long,auto
stmt        Long,Auto
result      Long,Auto
count       Long,Auto
  code
  ! read the SQL table to see what columns exist
  self.sqlcode.SetValue('SELECT * FROM pragma_table_info(''' & self._sanitize(self.FullPathName,driver:sqlTable) & ''') ORDER BY cid;')
  stmt = self._Prepare()
  If stmt = 0 then Return driver:notok.
  self._ExecuteToResults(stmt,self.Result)
  result = sqlite3_finalize(stmt)
  SqlColumns = self.result.Rows()
  impColumns = SqlColumns

  ! read in the first page
  If str.LoadFile(pDosfilename,Offset,Len) = false
    self.SetError(NoFileErr)
    Return driver:notok
  End
  str.SetEncodingFromBOM(st:removeBOM)
  str.Split(self.LineEndings)
  str.RemoveLines()
  Offset += str.EndOfLastLine - 1
  If str.eof
    recs = str.Records()
  else
    recs = str.Records()-1
  end

  Lne.SetValue(str.GetLine(1))
  Lne.Split(self.Separator,'"','"',st:remove)
  CsvColumns = lne.records()

  If Band(pOptions,driver:header)
    Header = 1
    count = 0
    Loop i = 1 to self.Result.Rows()                                   ! i is the column number in the database record
      sqlColumnName = self.result.GetCell(i,2)
      sqlColumnNameSafe = self.TranslateReserved(sqlColumnName)
      Loop y = 1 to lne.records()                                      ! y is the column number in the csv file
        If upper(lne.GetLine(y)) = upper(sqlColumnName)
          mapColumns[y] = i                                            ! mapcolumns[csv column] = db column
          sqlColumnNotNull[y] = self.result.GetCell(i,4)
          case self.result.GetCell(i,3)
          of 'INTEGER'
            sqlColumnType[y] = SQLITE_INTEGER
          of 'REAL'
            sqlColumnType[y] = SQLITE_FLOAT
          of 'TEXT'
            sqlColumnType[y] = SQLITE_TEXT
          of 'DATE'
            sqlColumnType[y] = SQLITE_TEXT
          of 'TIME'
            sqlColumnType[y] = SQLITE_TEXT
          of 'DATETIME'
            sqlColumnType[y] = SQLITE_TEXT
          of 'BLOB'
            sqlColumnType[y] = SQLITE_BLOB
          else
            sqlColumnType[y] = SQLITE_FLOAT   ! for other numerics
          end
          Break
        End
      End
      If mapColumns[y]
        FieldsList.Append(sqlColumnNameSafe,,',')
        count += 1
        ValuesList.Append(self._GenParm(count),,',')
        If self.Result.GetCell(y,6) = 0  ! not in the primary key
          excluded.Append( sqlColumnNameSafe & '= excluded.' & sqlColumnNameSafe ,st:NoClip,',')
        End
      End
    End
  Else
    Count = 0
    Loop y = 1 to lne.records()
      mapColumns[y] = y
      sqlColumnNotNull[y] = self.result.GetCell(i,4)
      case self.result.GetCell(i,3)
      of 'INTEGER'
        sqlColumnType[y] = SQLITE_INTEGER
      of 'REAL'
        sqlColumnType[y] = SQLITE_FLOAT
      of 'TEXT'
        sqlColumnType[y] = SQLITE_TEXT
      of 'DATE'
        sqlColumnType[y] = SQLITE_TEXT
      of 'TIME'
        sqlColumnType[y] = SQLITE_TEXT
      of 'DATETIME'
        sqlColumnType[y] = SQLITE_TEXT
      of 'BLOB'
        sqlColumnType[y] = SQLITE_BLOB
      else
        sqlColumnType[y] = SQLITE_FLOAT   ! for other numerics
      end
      FieldsList.Append(sqlColumnNameSafe,,',')
      count += 1
      ValuesList.Append(self._GenParm(count),,',')
      If self.Result.GetCell(y,6) = 0  ! not in the primary key
        excluded.append( sqlColumnNameSafe & '= excluded.' & sqlColumnNameSafe ,st:NoClip,',')
      End
    End
  End

  ! prepare the SQL statement
  self.SqlCode.SetValue('INSERT INTO ' & self._sanitize(self.FullPathName,driver:sqlTable) & ' (' & FieldsList.GetValue() & ') values (' & ValuesList.GetValue() & ') ')
  If Band(pOptions,driver:upsert)
    self.SqlCode.Append(' ON CONFLICT DO UPDATE SET ' & excluded.GetValue())
  End
  self.SqlCode.Append(';')

  stmt = self._Prepare()
  If stmt = 0
    self.SetError(SQLErr)
    Return Driver:notok
  End

  ! load the file in pages of Len size
  Loop
    do ImportPage
    If str.eof then break.
    If str.LoadFile(pDosfilename,Offset,Len) = false
      Break
    End
    str.Split(self.LineEndings)
    str.RemoveLines()
    Offset += str.EndOfLastLine - 1
    If str.eof
      recs = str.Records()
    else
      recs = str.Records()-1
    end
  End
  result = sqlite3_reset(stmt)              ! does an implicit commit if the transaction is implicit
  result = sqlite3_finalize(stmt)
  Return driver:ok

ImportPage  Routine
  ! BIND fields
  ! It's important that the CSV text is mapped to the parameters, and does NOT go through the file record.
  ! No data formatting, or deformating is done - the data is sent to the database directly as it is in the CSV.
  ! This is important for consistency with databases that can import CSV directly, bypassing the client program completely.
  Loop x = 1 to recs
    If header
      header = 0
      cycle
    End
    Lne.SetValue(str.GetLine(x))
    Lne.Split(self.Separator,'"','"')
    result = sqlite3_reset(stmt)
    count = 0
    Loop y = 1 to lne.Records()                                                                                                    ! y is the column number in the csv file
      If mapColumns[y] = 0 then cycle.  ! some items in the CSV can be excluded, if they are not in the Project List.              ! mapcolumns[csv column] = db column
      count += 1
      CsvCell.SetValue(lne.Getline(y))
      If CsvCell.GetValue() = self.NullString
        If sqlColumnNotNull[y]
          ! null not allowed, so revert to blank value
          Case sqlColumnType[y]
          Of SQLITE_INTEGER
            i = 0
            If self._logBind then self.Log('[BIND][sb36]' & mapColumns[y] & ' (int)' & i).
            result = sqlite3_bind_int(Stmt,count,i)
          Of SQLITE_FLOAT
            r = 0
            If self._logBind then self.Log('[BIND][sb37]' & mapColumns[y] & ' (real)' & r).
            result = sqlite3_bind_double(Stmt,count,r)
          Else
            !of SQLITE_TEXT
            !orof SQLITE_BLOB
            If self._logBind then self.Log('[BIND][sb38]' & mapColumns[y] & ' (string)' & s).   ! null not allowed, so setting the column to a blank string.
            result = sqlite3_bind_textA(stmt,count,s, 0 ,SQLITE_TRANSIENT)
          End
        Else
          If self._logBind then self.Log('[BIND][sb39]' & mapColumns[y] & ' (null)').           ! null in the csv, null in the database allowed
          result = sqlite3_bind_null(stmt,count)
        End
      Else ! text in CSV is not a "null"
        CsvCell.CSVDecode()
        If CsvCell.Sub(1,7) = 'base64:'
          CsvCell.Top(7)
          CsvCell.Base64Decode()
          If self._logBind then self.Log('[BIND][sb42]' & mapColumns[y] & ' (blob)' & CsvCell.GetValue()).
          result = sqlite3_bind_blob(stmt,count,CsvCell.GetValuePtr(), CsvCell.length() ,SQLITE_TRANSIENT)
          cycle
        End
        Case(sqlColumnType[y])
        of SQLITE_BLOB
          CsvCell.FromHex()
          If self._logBind then self.Log('[BIND][sb43]' & mapColumns[y] & ' (blob)' & CsvCell.GetValue()).
          result = sqlite3_bind_blob(stmt,count,CsvCell.GetValuePtr(), CsvCell.length() ,SQLITE_TRANSIENT)
          cycle

        of SQLITE_INTEGER
          If CsvCell.IsAllDigits()
            i = CsvCell.GetValue()
            If self._logBind then self.Log('[BIND][sb40]' & mapColumns[y] & ' (int)' & i).
            result = sqlite3_bind_int(Stmt,count,i)
            cycle
          End

        of SQLITE_FLOAT
          If numeric(CsvCell.GetValue())
            r = CsvCell.GetValue()
            If self._logBind then self.Log('[BIND][sb41]' & mapColumns[y] & ' (real)' & r).
            result = sqlite3_bind_double(Stmt,count,r)
            cycle
          End
        end
        If self._logBind then self.Log('[BIND][sb44]' & mapColumns[y] & ' (string)' & CsvCell.GetValue()).
        result = sqlite3_bind_textA(stmt,count,CsvCell.GetValuePtr(), CsvCell.length() ,SQLITE_TRANSIENT)
      End
    End
    ! execute SQL
    If self._logSQL then self.Log('[SQL ]' & self.SqlCode.GetValue()).
    Loop
      result = sqlite3_step(Stmt)  ! executes the sql
      Case result
      Of SQLite_Done !101
         break
      Of SQLite_Row
         cycle
      Else
        self.SetErrorSqlite(result,'[p091]')
        Break
      End
    End
    result = sqlite3_clear_bindings(stmt)
    If errorcode() then break.
  End

!-----------------------------------------------------------------
DriverFileSQLite2Class.SUSPENDRELATIONS           PROCEDURE()
  Code
  self.SetError(NoError)
  self._relationsOff = True
  self.Send('/pragma_foreign_keys=OFF')
  Return

!-----------------------------------------------------------------
DriverFileSQLite2Class.RESUMERELATIONS           PROCEDURE()
  Code
  self.SetError(NoError)
  If self._relationsOff
    self._relationsOff = False
    self.Send('/pragma_foreign_keys=ON')
  End
  Return

!-----------------------------------------------------------------
! Calling STREAM sets the database up for multiple writes.
! FLUSH? will return the system to the state it was before the STREAM
! consider also using SUSPENDRELATIONS for even faster performance.
DriverFileSQLite2Class.STREAM           PROCEDURE()
cmd  StringTheory
  Code
  parent.Stream()
  If Errorcode() then Return.
  If self._inTransaction or self._InStream
    self.SetError(LogActiveErr)
  ElsIf self.dbHandle
    ! synchronous
    self.SqlCode.SetValue('PRAGMA synchronous;')
    If self._ExecuteSql() = Driver:ok
      self._SynchronousAtStream = self.result.GetCell(1,1)
    Else
      self._SynchronousAtStream = 2
    End
    If self._SynchronousAtStream = 0  ! already OFF, so nothing to add
      self._SynchronousAtStream = -1
    Else
      self.SqlCode.SetValue('PRAGMA synchronous=OFF;')
      If self._ExecuteSql() = Driver:ok
      end
      cmd.append(self.sqlcode,,'<13,10>')
    End
    !cache_size
    self.SqlCode.SetValue('PRAGMA cache_size ;')
    If self._ExecuteSql() = Driver:ok
      self._CacheSizeAtStream = self.result.GetCell(1,1)
    Else
      self._CacheSizeAtStream = -2000
    End
    if self._CacheSizeAtStream > 0 then self._CacheSizeAtStream = (self._CacheSizeAtStream / 1024) * -1.
    if self._CacheSizeAtStream > -20000
      self.SqlCode.SetValue('PRAGMA cache_size=-20000;')
      If self._ExecuteSql() = Driver:ok
      end
      cmd.append(self.sqlcode,,'<13,10>')
    end
    ! begin transaction
    self._ParameterOpcode = Opcode:NONE
    self.SqlCode.SetValue('BEGIN;')
    If self._ExecuteSql() = Driver:ok
      self._inStream = true
    End
    cmd.append(self.sqlcode,,'<13,10>')
  End
  self.SqlCode.SetValue(cmd)
  Return

!-----------------------------------------------------------------
DriverFileSQLite2Class.FLUSH             Procedure
cmd  StringTheory
  Code
  If self._inTransaction                ! If you're inside a transaction, you can't call FLUSH
    self.SetError(LogActiveErr)
    Return
  elsif self._InStream = False          ! don't set an error - Flush can be called without STREAM
    !Self.SetError(NoLogoutErr)
  Else
    self._ParameterOpcode = Opcode:NONE
    self.SqlCode.SetValue('COMMIT;')
    If self._ExecuteSql() = Driver:ok
    End
    cmd.append(self.sqlcode,,'<13,10>')
  End
  If self._SynchronousAtStream > -1 and self._inStream
    self.SqlCode.SetValue('PRAGMA synchronous=' &  self._SynchronousAtStream & ';')
    If self._ExecuteSql() = Driver:ok
    End
    self._SynchronousAtStream = -1
    cmd.append(self.sqlcode,,'<13,10>')
  End
  If self._CacheSizeAtStream > -20000 and self._inStream
    self.SqlCode.SetValue('PRAGMA cache_size=' &  self._CacheSizeAtStream & ';')
    If self._ExecuteSql() = Driver:ok
    End
    self._CacheSizeAtStream = 0
    cmd.append(self.sqlcode,,'<13,10>')
  End

  self._inStream = False
  parent.Flush()
  If Errorcode() then Return.
  If self.dbHandle
    self._ParameterOpcode = Opcode:NONE
    self.SqlCode.SetValue('PRAGMA wal_checkpoint(PASSIVE);')
    If self._ExecuteSql() = Driver:ok
    End
    cmd.append(self.sqlcode,,'<13,10>')
  End
  self.SqlCode.SetValue(cmd)
  Return

!-----------------------------------------------------------------
DriverFileSQLite2Class.GETSTATE               Procedure(Long pSaveBlob)
len  Long,Auto
i    Long,Auto
  Code
  PushErrors()
  i = parent.GetState(pSaveBlob)
  len = address(self.__SQLiteSTATEEND) - address(self.__SQLiteSTATESTART)
  self.State.Level4 &= new String(len)
  MemCpy(address(self.State.Level4),address(self.__SQLiteSTATESTART),len)
  Put(self.State)
  PopErrors()     ! GetState should not alter errorcode.
  Return i

!-----------------------------------------------------------------
DriverFileSQLite2Class.RESTORESTATE           Procedure(Long pState, Byte pBuffer)
len  Long
  Code
  Parent.RestoreState(pState,pBuffer)
  If self.state.id = 0 then return.
  len = address(self.__SQLiteSTATEEND) - address(self.__SQLiteSTATESTART)
  MemCpy(address(self.__SQLiteSTATESTART),address(self.State.Level4),len)

  !if restoring from queues then do
  !Self.SetError(self.state.Errorcode)
  !Self.SetFileError(self.state.FileErrorCode,self.state.FileError)

  Return

!-----------------------------------------------------------------
DriverFileSQLite2Class.MERGESlow              Procedure(FILE pDestination, LONG pOptions)
  Code
  !!!todo implement merge slow
  Return

!-----------------------------------------------------------------
DriverFileSQLite2Class.MERGEFast      Procedure(FILE pDestination, LONG pOptions)
obj   &DriverFileSQLClass
  Code
  obj &= pDestination{prop:object}
  If obj &= null
    self.SetError(FileSystemErr)
    self.SetFileError(NoDriverSupport,'Failure to Merge. Destination Driver is not an Object Based Driver')
    Return
  End
  ! SQLite does not support fast merging across databases.
  If self.GetPROP:Database() <> obj.GetPROP:Database()
    self.MergeSlow(pDestination,pOptions)
    Return
  End
  self._MergeWork(obj,obj.FullPathName,pOptions)
  Return

!-----------------------------------------------------------------
DriverFileSQLite2Class.MERGEFast      Procedure(String pDestination, LONG pOptions)
obj   &DriverFileSQLClass
  Code
  self._MergeWork(obj,pDestination,pOptions)
  Return

!-----------------------------------------------------------------
DriverFileSQLite2Class._MergeWork              Procedure(DriverFileSQLClass pObj, String pDestination, LONG pOptions)
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
DriverFileSQLite2Class.OPEN             PROCEDURE(LONG pAccessMode=022h)
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
  If self.opt:dummy
    self.SharedProperties.ValidatedOwner     = self.Owner
    self.SharedProperties.ValidatedFileName  = self.FullPathName
    self.AfterOpen(pAccessmode,true)
  ElsIf self.SharedProperties.ValidatedOwner <> self.Owner or self.SharedProperties.ValidatedFileName <> self.FullPathName
    If self.ValidateStructure() = Driver:ok
      self.AfterOpen(pAccessmode,true)
      self.SharedProperties.ValidatedOwner     = self.Owner
      self.SharedProperties.ValidatedFileName  = self.FullPathName  !!!todo, could just use the server, port, database parts of the owner.
    Else
      self.AfterOpen(pAccessmode,false)  ! false means "not open"
    End
  Else
    self.AfterOpen(pAccessmode,true)
  End
  If self._opened and self.opt:dummy = false
    self.Send('/pragma_foreign_keys=ON')
  End
  Return

!-----------------------------------------------------------------
! Trigger a call to the backend to get the table definition.
! That will be populated into the ResultSet. Once that's done
! validate the structure is a superset of the FILE structure.
DriverFileSQLite2Class.ValidateStructure   PROCEDURE()
nextfield         Byte,Auto
x                 Long,Auto
y                 Long,Auto
saveSqlTimeStamp  Like(self.fields.SqlTimeStamp),Auto
dbg               CString(255),Auto
  Code
  If self.opt:TurboSQL then Return Driver:ok.
  self._ParameterOpcode = 0
  self.SqlCode.setvalue('PRAGMA table_info(' & self._sanitize(self.FullPathName,driver:sqlTable) & ');')
  If self._executeSql() = driver:ok
    If self.Result.Rows() = 0
      self.SetError(NoFileErr)
      Return driver:notok
    End
    Loop x = 1 to self.SharedProperties.FieldList.nodes
      self.Fields &= self._WithFieldNode(x)
      If self.Fields.Type = ClaGROUP or self.Fields.Over or self.Fields.InOverGroup then cycle.
      saveSqlTimeStamp = self.fields.SqlTimeStamp
      self.fields.SqlTimeStamp = false
      nextfield = False
      Loop y = 1 to self.Result.Rows()
        dbg = self.Result.GetCell(y,2)
        If upper(dbg) = self.Fields.UpperColumn
          nextfield = True
          break
        end
        If nextfield then break.
      End
      self.fields.SqlTimeStamp = saveSqlTimeStamp
      If nextfield = false
        self.SetError(InvalidFileErr)
        self.SetFileError(InvalidFileErr,'Missing field in backend table: ' & self.Fields.column & ' in ' & self.FullPathName & ' // ' & self.Owner)
        Return Driver:notok
      End
    End
  Else
    self.SetError(NoFileErr)
    self.SetFileError(NoFileErr,'Table not found in table_info ' & self.Owner & ' [' & self.FullPathName & ']')
    Return Driver:notok
  End
  Return parent.ValidateStructure()

!-----------------------------------------------------------------
DriverFileSQLite2Class.PACK             PROCEDURE()
  Code
  If self.CheckConnect() = Driver:notok then Return.   ! File can be OPEN. If closed a new connection is established.
  Self.SetError(NoError)
  self.SqlCode.setvalue('VACUUM;')
  self._ParameterOpcode = 0
  If self._executeSql() = driver:ok
  End
  Return

!-----------------------------------------------------------------
DriverFileSQLite2Class.REMOVEFIELD          PROCEDURE(String pName)
  Code
  If self.CheckConnect() = Driver:notok then Return.   ! File can be OPEN. If closed a new connection is established.
  Self.SetError(NoError)
  self.SqlCode.setvalue('ALTER TABLE ' & self._sanitize(self.FullPathName,driver:sqlTable) & ' DROP COLUMN ' & self._sanitize(pName,driver:SqlColumn) & ';')
  self._ParameterOpcode = 0
  If self._executeSql() = driver:ok
  End
  Return

!-----------------------------------------------------------------
DriverFileSQLite2Class.REMOVEKEY           PROCEDURE(String pName)
  Code
  If self.CheckConnect() = Driver:notok then Return.   ! File can be OPEN. If closed a new connection is established.
  Self.SetError(NoError)
  self.SqlCode.setvalue('DROP INDEX ' & clip(pName) & ';')
  self._ParameterOpcode = 0
  If self._executeSql() = driver:ok
  End
  Return

!-----------------------------------------------------------------
DriverFileSQLite2Class.REMOVEKEY           PROCEDURE(Key pKey)
  Code
  If self.CheckConnect() = Driver:notok then Return.   ! File can be OPEN. If closed a new connection is established.
  Self.SetError(NoError)
  If self._WithKey(pKey) = Driver:ok
    self.SqlCode.setvalue('DROP INDEX ' & self._sanitize(self.FullPathName & '_' & self.keys.dbName,driver:sqlTable) & ';')
    self._ParameterOpcode = 0
    If self._executeSql() = Driver:notok
      Return
    End
  End
  Return

!-----------------------------------------------------------------
! because pNewFileName is not trusted, a parameterized statement is created and executed.
DriverFileSQLite2Class.RENAME           PROCEDURE(STRING pNewFileName)
cstr    cstring(size(pNewFileName)+1),Auto
cmd     StringTheory
keysql  StringTheory
indexqueue  queue
name          cstring(255)
sql           cstring(1024)
            end
x       Long
  Code
  If self.CheckConnect() = Driver:notok then Return.         ! File can be OPEN. If closed a new connection is established.
  cstr = self._sanitize(pNewFileName,driver:sqlTable)
  Self.SetError(NoError)
  self._ParameterOpcode = 0
  self.SqlCode.setvalue('SELECT name FROM sqlite_master WHERE type=''table'' AND name = ''' & cstr & ''';')
  cmd.SetValue(self.SqlCode)
  If self._executeSql() = driver:ok
    If self.result.Rows() <> 0 ! table already exists
      self.SetError(NoAccessErr)
    Else
      self.SqlCode.setvalue('ALTER TABLE ' & self._sanitize(self.FullPathName,driver:sqlTable) & ' RENAME TO ' & cstr & ';' )
      cmd.append(self.sqlcode,'<13,10>')
      If self._executeSql() = driver:ok
        ! the table name has been changed, but now need to drop the old indexes and recreate those with the new name.
        Self.SqlCode.SetValue('SELECT name,sql FROM sqlite_master where type = ''index''')
        If self._executeSql() = driver:ok
          Loop x = 1 to self.result.Rows()
            indexqueue.name = self.result.GetCell(x,1)
            indexqueue.sql = self.result.GetCell(x,2)
            Add(indexqueue)
          End
          Loop x = 1 to records(indexQueue)
            Get(indexQueue,x)
            self.SqlCode.SetValue('DROP INDEX IF EXISTS ' & indexqueue.name & ';')
            cmd.append(self.sqlcode,'<13,10>')
            If self._executeSql() = driver:ok
              keySql.SetValue(indexqueue.sql)
              KeySql.replace(self._sanitize(self.FullPathName,driver:sqlTable) & '_',cstr & '_',0,1,0,st:nocase)
              self.SqlCode.SetValue(KeySql)
              cmd.append(self.sqlcode,'<13,10>')
              If self._executeSql() = driver:ok
              End
            End
          End
        End
      End
    End
  End
  self.SqlCode.SetValue(cmd)
  Return

!-----------------------------------------------------------------
! Record Access Methods
!-----------------------------------------------------------------
DriverFileSQLite2Class.ADD              PROCEDURE()
result  long,Auto
  Code
  If self.CheckConnect() = driver:notok then Return.
  ! Parent MUST be called first for ADD. Abort if Errorcode set.
  parent.Add()
  If Errorcode() then Return.
  self._PrepareAdd(Opcode:Add)
  If self.Stmt_Add
    self._ExecuteToRecord(self.Stmt_Add,driver:buffer,NoError,Opcode:ADD)
  End
  self._AfterWrite(opcode:Add)
  Return

!-----------------------------------------------------------------
! similar to an ADD, but does not get returning values, so is a touch faster.
! Useful for doing Bulk adds, where the Auto-numbered fields are not required.
DriverFileSQLite2Class.APPEND              PROCEDURE()
result  long,Auto
  Code
  If self.CheckConnect() = driver:notok then Return.
  parent.Append()
  If Errorcode() then Return.
  self.SetError(NoError)
  self._PrepareAdd(Opcode:APPEND)
  If self.Stmt_Append
    self._ExecuteToRecord(self.Stmt_Append,driver:nobuffer,NoError,Opcode:APPEND)
  End
  self._AfterWrite(opcode:Append)
  Return

!-----------------------------------------------------------------
DriverFileSQLite2Class.DELETE           PROCEDURE()
result  long,Auto
  Code
  If self.CheckConnect() = driver:notok then Return.
  ! Parent MUST be called first for DELETE. Abort if Errorcode set.
  parent.Delete()
  If Errorcode() = NoError
    If self._PrepareDelete() = driver:ok and Errorcode() = NoError
      self._ExecuteToRecord(self.Stmt_Delete,driver:buffer,NoRecErr,Opcode:DELETE)
    End
  End
  self._AfterWrite(opcode:Delete)
  Return

!-----------------------------------------------------------------
DriverFileSQLite2Class.DELETE           PROCEDURE(String pFilter)
stmt    Long
  Code
  ! Parent MUST be called first for DELETE. Abort if Errorcode set.
  If self.CheckConnect() = driver:notok then Return.
  self._ParameterOpcode = Opcode:DELETE
  parent.Delete(pFilter)
  If Errorcode() = NoError
    stmt = self._PrepareDelete(pFilter)
    If stmt and Errorcode() = NoError
      If self._ExecuteSQL(stmt) = driver:ok
        If self.Affected = 0
          self.SetError(NoRecErr)
        End
      End
    End
  End
  self._AfterWrite(opcode:Delete)
  Return

!-----------------------------------------------------------------
! The other forms of GET all set the error to NoDriverSupport
DriverFileSQLite2Class.GET              PROCEDURE(KEY pKey)
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
    If ErrorCode() = NoError
      ! the bit about memo or nomemo only affects the Project List, not the parameter list.
      self._ExecuteToRecord(stmt,self._GetBuffer,NoRecErr,Opcode:GET)
    End
  Else
    self.SetError(InvKeyErr)
  End
  Parent.Get(pKey)
  Return

!-----------------------------------------------------------------
DriverFileSQLite2Class.GETRANDOM              PROCEDURE(String pFilter)
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
    stmt = self._PrepareRandom(pFilter,rnd)
    If stmt
      self._ExecuteToRecord(stmt,driver:buffer,NoRecErr,Opcode:GET)
    End
    Parent.GetRandom(pFilter)
  End
  Return

!-----------------------------------------------------------------
! trigger a call to the backend, and put the resut set into self.result.
! The "whole" result set is retrieved, no resources are left on the *server*.
! The "first" NEXT command will get it all, from the server to the localresult set. (built-in paging applies though.)
DriverFileSQLite2Class._ExecuteSelect             PROCEDURE()
result   Long,auto
  code
  If not Self.Stmt_Set then Return.
  If self.CheckConnect() = driver:notok then Return.
  If ErrorCode() = 0
    self._ParameterOpcode = Opcode:SET
    If self._BindParameters(Self.Stmt_Set) = driver:ok
      If self._OffsetParmNumber
        ! Bind OFFSET
        If self._logBind then self.Log('[BIND][sb45]' & self._OffsetParmNumber & ' (long)' & self._SetOffset).
        result = sqlite3_bind_int(self.Stmt_Set,self._OffsetParmNumber,self._SetOffset)
        self._SetOffset = 1
      End
      ! Execute statement, and move results to Results interface
      self._ExecuteToResults(Self.Stmt_Set,self.result)
      ! reset the statement so it can be used again
      result = sqlite3_reset(Self.Stmt_Set)
      result = sqlite3_clear_bindings(Self.Stmt_Set)
    End
  End
  parent._ExecuteSelect()
  Return

!-----------------------------------------------------------------
! necessary to have this method, here because don't want to put BeforeRead into parent class.
DriverFileSQLite2Class.NEXT         PROCEDURE()
  Code
  Self._BeforeRead(Opcode:Next)
  If Errorcode() then Return.
  Parent.Next()
  Return

!-----------------------------------------------------------------
! necessary to have this method, here because don't want to put BeforeRead into parent class.
DriverFileSQLite2Class.PREVIOUS         PROCEDURE()
  Code
  Self._BeforeRead(Opcode:PREVIOUS)
  If Errorcode() then Return.
  Parent.Previous()
  Return

!-----------------------------------------------------------------
! The SQL Update statement primes the WHERE part of the statement using the self.PrimaryKeyPosition.
! The PrimaryKeyPosition property is populated after each READ of the file (GET, REGET, PREVIOUS, NEXT).
DriverFileSQLite2Class.PUT              PROCEDURE()
stmt    long,auto
result  long,auto
  Code
  If self.CheckConnect() = driver:notok then Return.
  Parent.Put() ! Parent MUST be called before writing the record. Abort if Errorcode set.
  If Errorcode() then Return.
  stmt = self._PreparePut()
  If stmt
    self._ExecuteToRecord(stmt,driver:buffer,NoError,Opcode:PUT)
  End
  self._AfterWrite(opcode:Put)
  Return

!-----------------------------------------------------------------
DriverFileSQLite2Class.SEARCH                     Procedure(String pSearchString,<*? pField1>, <*? pField2>, <*? pField3>, <*? pField4>, <*? pField5>, <*? pField6>, <*? pField7>, <*? pField8>, <*? pField9>, <*? pField10>,<*? pField11>, <*? pField12>, <*? pField13>, <*? pField14>, <*? pField15>)
FtsName       Cstring(255),Auto
!SearchString  cString(255),Auto
fields        StringTheory
join          StringTheory
x             Long,Auto
  code
  If self.CheckConnect() = driver:notok then Return.
  If pSearchString = ''
    self._SearchJoin = ''
    self.SearchFilter = ''
    self._SearchOrderClause = ''
    self.SetProp:Where('')
    Return
  End
  If self._ValidateSearchTable() = Driver:ok
    FtsName = self.FullPathName  & '_fts'
    !SearchString = self.TranslateSearch(pSearchString)
    If self._ProjectClauses &= null
      self._ProjectClauses &= new StringTheory
    End
    If self._ProjectClauses.Instring('bm25(') = 0
      self._ProjectClauses.append('bm25(' & ftsName & ') AS rank_fts',,',')
    End
    If self._WithPrimaryKey() = Driver:ok
      Loop x = 1 to self.keys.components
        If self._WithField(self.keys.component[x]) = Driver:ok
          Join.Append(self._GetAlias(driver:withdot) & self.fields.Column & ' = fts.' & self.fields.Column ,, ',')
        End
      End
    End
    self._SearchJoin = ' JOIN ' & FtsName & ' fts ON ' & Join.GetValue()
    self.SetProp:Search(self.TranslateSearch(pSearchString))
    self.SearchFilter = self.FullPathName & '_fts SEARCH( ''' & self.Search & ''')'
    ! Because the SEARCH function is tokenised, there's no need to bind the parameter - that's done by DriverBaseClass._ExpandToken

    self._SearchOrderClause = 'rank_fts'
    self.BindField('rank_fts',self.SearchRank)
    self._JustSetSearch = true
  End
  Return

!-----------------------------------------------------------------
! words reserved by SQLite so cannot be used as column names.
DriverFileSQLite2Class.TranslateReserved       PROCEDURE(*cstring pColumn)
  code
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
! In SQLITE the operators in the MATCH command are Case sensitive. hence AND, OR, NOT
! NOT operators should come after earlier operators
DriverFileSQLite2Class.TranslateSearch  Procedure(String pSearchString)
str   StringTheory
  code
  str.Setvalue(left(pSearchString),st:clip)
  str.Replace('and not',' NOT ',0,1,0,false)
  str.Replace('or not',' NOT ',0,1,0,false)
  str.Replace('and',' AND ',0,1,0,false)
  str.Replace('or',' OR ',0,1,0,false)
  str.Replace('not',' NOT ',0,1,0,false)
  str.Replace('+',' AND ')
  str.Replace('&&',' AND ')
  str.Replace('&',' AND ')
  str.Replace('-',' NOT ')
  str.Replace('!',' NOT ')
  str.Replace('~',' NOT ')
  str.Replace('||',' OR ')
  str.Replace('|',' OR ')
  If str.startswith(' OR ') then str.Top(4).
  If str.startswith(' AND ') then str.Top(5).
  If str.startswith(' NOT ') then str.Top(5).
  str.Replace('  ',' ',0,1,0,0,1)
  Return str.GetValue()

!-----------------------------------------------------------------
! For SQLite, the Full Text Search is done with the help of a table, the fts table. This method makes sure the table exists.
DriverFileSQLite2Class._ValidateSearchTable  Procedure()
  code
  If self.Exists(self._sanitize(self.FullPathName,driver:sqlTable)  & '_fts') = false
    Return self._CreateFTS()
  End
  Return Driver:ok

!-----------------------------------------------------------------
! For SQLite, the Full Text Search is done with the help of a table, the fts table. This method creates that table, and associated triggers.
DriverFileSQLite2Class._CreateFTS  Procedure()
FtsName         Cstring(255)
Fields          StringTheory
NewFields       StringTheory
UpdateFields    StringTheory
CreateKeyFields StringTheory
InsertKeyFields StringTheory
NewKeyFields    StringTheory
UpdateKeyFields StringTheory
WhereKeyFields  StringTheory
Ptr       Long
Offset    Long
x         Long
  code
  ! CREATE VIRTUAL TABLE email USING fts5(sender, title, body);
  FtsName = self._sanitize(self.FullPathName,driver:sqlTable)  & '_fts'

  If self._WithPrimaryKey() = Driver:ok
    Loop x = 1 to self.keys.components
      If self._WithField(self.keys.component[x]) = Driver:ok
        Case self.Fields.type
        of ClaSTRING
        orof ClaCSTRING
        orof ClaPSTRING
          If self.fields.Binary or self.Fields.UUID or self.fields.SqlTimeStamp or (not self.fields.Interface &= null)
            CreateKeyFields.Append(self.fields.Column & ' UNINDEXED',, ',')      ! Binary, UUID and custom key fields are not included in the index
          Else
            CreateKeyFields.Append(self.fields.Column,, ',')                     ! Text String Key fields are included in the index.
          End
        Else
          CreateKeyFields.Append(self.fields.Column & ' UNINDEXED',, ',')       ! Non-string fields are not included in the index
        End
        InsertKeyFields.Append(self.fields.Column,, ',')
        NewKeyFields.Append('new.' & self.fields.Column,, ',')
        UpdateKeyFields.Append(self.fields.Column & ' = new.' & self.fields.Column,, ', ')
        WhereKeyFields.Append(self.fields.Column & ' = old.' & self.fields.Column,, ' and ')
      End
    End
  End
  Loop x = 1 to self.SharedProperties.FieldList.nodes
    If self._WithField(x) = Driver:ok
      If self.fields.Binary then cycle.
      If self.Fields.UUID then cycle.
      If not self.fields.Interface &= null then cycle.
      If self.fields.Primary then cycle.
      If self.fields.SqlTimeStamp then cycle.
      If self.fields.over then cycle.
      Case self.fields.Type
      of ClaCSTRING
      orof ClaPSTRING
      orof ClaSTRING
      orof ClaMEMO
      orof ClaBLOB
        Fields.append(self.fields.Column,,',')
        NewFields.append('new.' & self.fields.Column,,',')
        UpdateFields.append(self.fields.Column & ' = new.' & self.fields.Column,,',')
      End
    End
  End
  Loop x = 1 to Records(self.blobs)
    get(self.blobs,x)
    If self.Blobs.Binary then cycle.
    Fields.append(self.Blobs.Column,,',')
    NewFields.append('new.' & self.Blobs.Column,,',')
    UpdateFields.append(self.Blobs.Column & ' = new.' & self.Blobs.Column,,',')
  End

    self.SqlCode.SetValue('CREATE VIRTUAL TABLE ' & FtsName & ' USING fts5(' & CreateKeyFields.GetValue() & ',' & fields.GetValue() &');')
    If self._ExecuteSql() = Driver:ok
      ! Populate table with the data from the primary table
      self.SqlCode.SetValue('INSERT INTO ' & FtsName & '(' & InsertKeyFields.getvalue() & ',' & fields.GetValue() &')' & |
          ' SELECT ' & InsertKeyFields.getvalue() & ',' & fields.GetValue() & |
          ' FROM ' & self._sanitize(self.FullPathName,driver:sqlTable) & ';')
      If self._ExecuteSql() = Driver:ok

        ! Create TRIGGERS on the parent table so this search table does not need t be rebuilt again
        ! Insert Trigger
        self.SqlCode.SetValue('CREATE TRIGGER after_insert_fts AFTER INSERT ON ' & self._sanitize(self.FullPathName,driver:sqlTable) & |
                              ' BEGIN ' & |
                              ' INSERT INTO ' & FtsName & |
                                   '(' & InsertKeyFields.GetValue() & ',' & |
                                   Fields.GetValue() & ') ' & |
                              ' VALUES ('& newKeyFields.GetValue() & ',' & newFields.GetValue() & '); ' & |
                              ' END;')
        If self._ExecuteSql() = Driver:ok
        End
        ! Update Trigger
        self.SqlCode.SetValue('CREATE TRIGGER after_update_fts AFTER UPDATE ON ' & self._sanitize(self.FullPathName,driver:sqlTable) & |
                              ' BEGIN ' & |
                              ' UPDATE ' & FtsName & ' ' & |
                              ' SET ' & UpdateKeyFields.GetValue() & ', ' & |
                                      UpdateFields.GetValue() & |
                              ' WHERE ' & WhereKeyFields.GetValue() &'; ' & |
                              ' END; ')
        If self._ExecuteSql() = Driver:ok
        End
        ! Delete Trigger
         self.SqlCode.SetValue('CREATE TRIGGER after_delete_fts AFTER DELETE ON ' & self._sanitize(self.FullPathName,driver:sqlTable) & |
                              ' BEGIN ' & |
                              ' DELETE FROM ' & FtsName & ' WHERE ' & WhereKeyFields.GetValue() &'; ' & |
                              ' END;' )
        If self._ExecuteSql() = Driver:ok
        End
      End
    End

  Return Driver:ok

!-----------------------------------------------------------------
! Called for all forms of set by the parent call
! clears any existing SET statement, and also prepares the new SELECT statement.
DriverFileSQLite2Class._SET              PROCEDURE(Byte pSetMethod, BigInt pPointer,Key pSetKey, Key pSetKeyKey)
result  long
  Code
  If self.CheckConnect() = driver:notok then Return.
  If self.Stmt_Set
    result = sqlite3_finalize(self.Stmt_Set)
    self.SetErrorSqlite(result,'[p110]')
    self.Stmt_Set = 0
    self._ClearParameterQueue(Opcode:SET)
  End
  parent._Set(pSetMethod,pPointer,pSetKey,pSetKeyKey)
  Return

!-----------------------------------------------------------------
DriverFileSQLite2Class._UpdateFileStrings  Procedure()
str   stringtheory
x     long
  code
  parent._UpdateFileStrings()
  str.setvalue(self.Owner)
  str.split(',','"','"',true,true,true)
  Loop x = 1 to str.records()
    if x > maximum(self._connect,1) then break.
    self._connect[x] = str.getline(x)
  End
  Return

!-----------------------------------------------------------------
DriverFileSQLite2Class.UPSERT           Procedure()
x        Long,Auto
result   Long,Auto
rType    Long,Auto
rAddress BIGINT,Auto
rLength  BIGINT,Auto
rTextLen Long
  Code
  If self.CheckConnect() = driver:notok then Return.
  ! Parent MUST be called first for UPSERT. Abort if Errorcode set.
  parent.Upsert()
  If Errorcode() then Return.
  self._PrepareAdd(Opcode:Upsert)
  If self.Stmt_Upsert
    If self._BindParameters(self.Stmt_Upsert) = Driver:ok
      self._ExecuteToResults(self.Stmt_Upsert,self.result)  ! POSSIBLY RETURN INTO
      If self.result.Rows()
        Loop x = 1 to self.SharedProperties.FieldList.nodes
          self.Fields &= self._WithFieldNode(x)
          If self.Fields.ReadOnly or self.Fields.IsIdentity
            self.result.GetCell(1,x,rType,rAddress,rLength)
            self._morph(self.fields.label,self.Fields.type,self.ClaFCB.rec_buf + self.Fields.offset, self.Fields.length,rType,rAddress,rLength,self.fields.SqlTimeStamp,true,rTextLen)
           End
        End
      End
      result = sqlite3_reset(self.Stmt_Upsert) ! does an implicit commit if the transaction is implicit
    End
    result = sqlite3_clear_bindings(self.Stmt_Upsert) ! do not leak values to next call.
  End
  self._AfterWrite(Opcode:Upsert)
  Return

!-----------------------------------------------------------------
DriverFileSQLite2Class.ResultToExplain  Procedure(iResultSet pResult)
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
! overriding base class. Note that Parent is not called.
DriverFileSQLite2Class.OperatorsToFunction  Procedure(StringTheory pStr)
ans  long
  code
  ans += self._functionize(pStr,token:power,'POWER')     ! SQLite Supports POWER for ^
  !ans += self._functionize(pStr,token:concat,'CONCAT')  ! SQLite uses || not ConCat
  Return ans

!-----------------------------------------------------------------
! In SQLite there is no DATE type, so dates are stored as a string in the format yyyy-mm-dd
! Thus the DATE function, as used in say a filter, must return a string of the form yyyy-mm-dd
! if pLabelType is driver:field, then the self.fields group is loaded with the field that this DATE() call is being compared *to*
!!!todo, this assumes it's a prop:filter, not a prop:order or prop:project.
DriverFileSQLite2Class._TranslateDateSql  Procedure(String pMonth, String pDay, String pYear, Byte pLabelType,*Cstring pCond)
  code
  If pLabelType <> driver:field or self.Fields.Type = ClaDATE
    If Numeric(pMonth) = false or numeric(pDay) = false or numeric(pYear) = false
      Return 'DATE(CAST(' & pYear & ' AS TEXT) || ''-'' || printf(''%02d'', ' & pMonth & ') || ''-'' || printf(''%02d'', ' & pDay & '))'
    Else
      Return '''' & self.FormatDate(Date(pMonth,pDay,pYear)) & ''''
    End
  End
  If self.Fields.Type = ClaLONG
    If Numeric(pMonth) = false or numeric(pDay) = false or numeric(pYear) = false
      Return 'CAST(julianday(CAST(year AS TEXT) || ''-'' || printf(''%02d'', month) || ''-'' || printf(''%02d'', day)) - 2378857 AS INTEGER)' ! 2378857 is Julianday(1800-12-28) which is clarion day 0
    Else
      Return Date(pMonth,pDay,pYear)
    End
  End
  Return ''

!-----------------------------------------------------------------
DriverFileSQLite2Class._TranslateLabelOverDateSQL Procedure(FieldGroupType pNode)
  code
  Return 'DATE(' & self._GetAlias(driver:withdot) & pNode.Column & ')'

!-----------------------------------------------------------------
DriverFileSQLite2Class._TranslateLabelOverTimeSQL Procedure(FieldGroupType pNode)
  code
  Return 'TIME(' & self._GetAlias(driver:withdot) &  pNode.Column & ')'

!-----------------------------------------------------------------
!  as in DAY(date) or MONTH(date) or YEAR(date)
!  date is either a DATE field in the database, a LONG field in the database
DriverFileSQLite2Class._TranslateDatePartSQL   Procedure(*CString pField,String pPart)
node  &FieldGroupType,Auto
  code
  If self.fields.type = ClaDate and self.fields.InOverGroup and self.fields.InOverGroup = self.fields.Index - 1 ! handle DATE part of DATE/TIME over TIMESTAMP
    node &= self._WithFieldNode(self.fields.InOverGroup)
    node &= self._WithFieldNode(node.over)
    If node.SqlTimeStamp
      Return 'CAST(strftime(''%'& pPart &''',' &  self._GetAlias(driver:withdot) & node.Column &') AS INTEGER)'
    End
  ElsIf self.fields.type = ClaDate or self.fields.SqlTimeStamp
    ! If pDay is a DATE column in the database then return the DAY/MONTH/YEAR NUMBER of the value in that date column
    Return 'CAST(strftime(''%'& pPart &''',' &  pField &') AS INTEGER)'
  Else
    ! It's not a DATE column, so stored as a Clarion Stadard Date Number (LONG or bigger). Convert the Clarion number
    ! to a date, then return the DAY/MONTH/YEAR NUMBER of that date
    Return 'CAST(strftime(''%'& pPart &''', date(''1800-12-28'', ''+'' ||  ' & pField & ' || '' days'' )) AS INTEGER)'
  End
  Return ''

!-----------------------------------------------------------------
DriverFileSQLite2Class._TranslateDaySQL   Procedure(*CString pField)
  code
  Return self._TranslateDatePartSQL(pField,'d')

!-----------------------------------------------------------------
DriverFileSQLite2Class._TranslateMonthSQL   Procedure(*CString pField)
  code
  Return self._TranslateDatePartSQL(pField,'m')

!-----------------------------------------------------------------
DriverFileSQLite2Class._TranslateYearSQL   Procedure(*CString pField)
  code
  Return self._TranslateDatePartSQL(pField,'Y')

!-----------------------------------------------------------------
DriverFileSQLite2Class.TranslateRegularExpression Procedure(*CString pExpr,*CString pColumn)
  code
  !!!todo - Translate RegEx code goes here
  Return ''

!-----------------------------------------------------------------
! Transaction Processing
!-----------------------------------------------------------------
!-----------------------------------------------------------------
! When called from cwDriver.Clw / LogoutConnection, then  self._transactionPrimary is set to true.
DriverFileSQLite2Class.LOGOUTCONNECTION    PROCEDURE()
t  Long,Auto
  Code
  If self.CheckConnect() = driver:notok then return.
  If self._transactionPrimary = false then return.
  parent.LogoutConnection()
  If Errorcode() then Return.
  If self.dbHandle
    t = ConnectionPoolSQlite2.GetTransaction(self.dbHandle)
    if t = 0
      self._ParameterOpcode = Opcode:NONE
      self.SqlCode.SetValue('BEGIN;')
      If self._ExecuteSql() = Driver:ok
        ConnectionPoolSQlite2.SetTransaction(self.dbHandle,true)
        self._inTransaction = true
      End
    else
      self.SetError(LogActiveErr)
      self._transactionPrimary = false
    End
  End
  Return

!-----------------------------------------------------------------
DriverFileSQLite2Class.COMMIT           PROCEDURE()
  Code
  If self.CheckConnect() = driver:notok then return.
  If self._transactionPrimary = false then return.
  parent.Commit()
  If Errorcode() then Return.
  If self.dbHandle
    If ConnectionPoolSQlite2.GetTransaction(self.dbHandle)
      self._ParameterOpcode = Opcode:NONE
      self.SqlCode.SetValue('COMMIT;')
      If self._ExecuteSql() = Driver:ok
        ConnectionPoolSQlite2.SetTransaction(self.dbHandle,false)
        self._inTransaction = false
      End
    End
  End
  self._transactionPrimary = false
  Return

!-----------------------------------------------------------------
DriverFileSQLite2Class.ROLLBACK         PROCEDURE()
  Code
  If self.CheckConnect() = driver:notok then return.
  if self._transactionPrimary = false then return.
  parent.Rollback()
  If Errorcode() then Return.
  If self.dbHandle
    If ConnectionPoolSQlite2.GetTransaction(self.dbHandle)
      self._ParameterOpcode = Opcode:NONE
      self.SqlCode.SetValue('ROLLBACK;')
      If self._ExecuteSql() = Driver:ok
        ConnectionPoolSQlite2.SetTransaction(self.dbHandle,false)
        self._inTransaction = false
      End
    End
  End
  self._transactionPrimary = false
  Return

!-----------------------------------------------------------------
DriverFileSQLite2Class.ROLLBACK         PROCEDURE(String pSavePoint)
t  Long,Auto
  Code
  If self.CheckConnect() = driver:notok then return.
  If self._transactionPrimary = false then return.
  parent.Rollback(pSavePoint)
  If Errorcode() then Return.
  If self.dbHandle
    t = ConnectionPoolSQlite2.GetTransaction(self.dbHandle)
    If t
      self._ParameterOpcode = Opcode:NONE
      self.SqlCode.SetValue('ROLLBACK TO ' & self._sanitize(pSavePoint,driver:sqlSavePoint) & ';')
      If self._ExecuteSql() = Driver:ok
      else
        self.SetError(InvalidSavePointErr)
      End
    Else
      self.SetError(NoLogoutErr)
    End
  End
  Return

!-----------------------------------------------------------------
DriverFileSQLite2Class.SAVEPOINT        PROCEDURE(String pSavePoint)
t  Long,Auto
  Code
  If self.CheckConnect() = driver:notok then return.
  parent.SavePoint(pSavePoint)
  If Errorcode() then Return.
  If self.dbHandle
    t = ConnectionPoolSQlite2.GetTransaction(self.dbHandle)
    If t
      self._ParameterOpcode = Opcode:NONE
      self.SqlCode.SetValue('SAVEPOINT ' & self._sanitize(pSavePoint,driver:sqlSavePoint) & ';')
      If self._ExecuteSql() = Driver:ok
      End
    Else
      self.SetError(NoLogoutErr)
    End
  End
  Return

!-----------------------------------------------------------------
DriverFileSQLite2Class.CreateDB      PROCEDURE(String pDatabaseName)
  code
  parent.CreateDB(pDatabaseName)
  If Errorcode() then Return.
  self.Connect()
  Return

!-----------------------------------------------------------------
DriverFileSQLite2Class.DISCONNECT     PROCEDURE()!
result  Long,Auto
stmt    Long
  Code
  parent.Disconnect()
  If self.dbHandle
    If ConnectionPoolSQlite2.Disconnect(self.dbHandle) = true
      result = sqlite3_close(self.dbHandle)
      self.SetErrorSqlite(result,'[p115]')
    End
    self.dbHandle = 0
  End
  Return

!-----------------------------------------------------------------
DriverFileSQLite2Class.GETPROP:Arrays       PROCEDURE()
  Code
  Return '1'

!-----------------------------------------------------------------
DriverFileSQLite2Class.GETPROP:Database       PROCEDURE()
  Code
  Return self._connect[1]

!-----------------------------------------------------------------
DriverFileSQLite2Class.GetProp:Hdbc           PROCEDURE()!,STRING,VIRTUAL
  code
  Return self.dbHandle

!-----------------------------------------------------------------
! SQLite is embeded so there is no "server"
DriverFileSQLite2Class.GetPROP:Server         PROCEDURE()
  code
  Return ''

!-----------------------------------------------------------------
DriverFileSQLite2Class.GetPROP:DatabaseName   PROCEDURE() ! Get name of database, like SQLITE or PostgreSQL or whatever
  code
  Return 'SQLite'

!-----------------------------------------------------------------
DriverFileSQLite2Class.GETPROP:Driver         PROCEDURE() ! Get the clarion name of the driver - like SQLite2
  code
  Return 'SQLite2'

!-----------------------------------------------------------------
DriverFileSQLite2Class.GETPROP:DriverVersion  PROCEDURE()
  code
  Return driver:version

!-----------------------------------------------------------------
! SQLite is embeded so there is no "user"
DriverFileSQLite2Class.GetPROP:User           PROCEDURE()
  code
  Return ''

!!-----------------------------------------------------------------
!================================================================================================
!================================================================================================
!================================================================================================
!-----------------------------------------------------------------
DriverViewSQLite2Class.Construct             PROCEDURE()
  Code
  self.AllowParameterRepeats = true
  Return

!-----------------------------------------------------------------
DriverViewSQLite2Class.GETPROP:Database       PROCEDURE()
  Code
  Return ''

!-----------------------------------------------------------------
! SQLite is embeded so there is no "server"
DriverViewSQLite2Class.GetPROP:Server         PROCEDURE()
  code
  Return ''

!-----------------------------------------------------------------
DriverViewSQLite2Class.GetPROP:DatabaseName    PROCEDURE() ! Get name of database, like SQLITE or PostgreSQL or whatever
  code
  Return 'SQLite'

!-----------------------------------------------------------------
DriverViewSQLite2Class.GETPROP:Driver   PROCEDURE()  ! Get the name of the driver
  code
  Return 'SQLite2'

!-----------------------------------------------------------------
! SQLite is embeded so there is no "user"
DriverViewSQLite2Class.GetPROP:User         Procedure()
  code
  Return ''

!-----------------------------------------------------------------
! must include a trailing space
DriverViewSQLite2Class.ExplainStart      Procedure()
  Code
  Return 'EXPLAIN QUERY PLAN '

!-----------------------------------------------------------------
DriverViewSQLite2Class.CheckConnect    PROCEDURE()
  Code
  self.PrimaryFileObject &= (self.FileObject[1])    ! self.FileObject is declared as  DriverFileSQLite2Class
  Return self.PrimaryFileObject.CheckConnect()

!-----------------------------------------------------------------
DriverViewSQLite2Class._Prepare  Procedure()
result        long,Auto
  Code
  If self.CheckConnect() = driver:notok then return 0 .
  Return self.PrimaryFileObject._prepare(self.SqlCode)

!-----------------------------------------------------------------
! loop through all the files in the file, and for their objects, call BindParameters.
DriverViewSQLite2Class._BindParameters  Procedure(Long pStmt)
x         Long,Auto
y         Long,Auto
z         Long,Auto
Len       Long,Auto
Result    Long,Auto
obj       &DriverFileSQLite2Class
  code
  !self.trace('DriverViewSQLite2Class._BindParameters self.Files=' & self.Files)
  Loop x = 1 to self.Files
    obj &= (self.FileObject[x])
    If obj &= null
      If self._SearchParameter
        If self._logBind then self.Log('[BIND][sb46]' & self._SearchParameter & ' (real)' & self.SearchRank).
        result = sqlite3_bind_double(pStmt,self._SearchParameter,self.SearchRank)
      End

      Loop y = 1 to Records(self.ParameterQueue)
        Get(self.ParameterQueue,y)
        Loop z = 1 to self.ParameterQueue.ParameterArrayIndex
          If self.ParameterQueue.ParameterArray[z].OpCode <> self._ParameterOpcode then cycle.
          If not self.ParameterQueue.ParameterArray[z].Value &= null
            len = len(self.ParameterQueue.ParameterArray[z].Value)
            If self._logBind then self.Log('[BIND][sb48]' & self.ParameterQueue.ParameterArray[z].Count & ' (string)' & self.ParameterQueue.ParameterArray[z].Value).
            result = sqlite3_bind_textA(pStmt,self.ParameterQueue.ParameterArray[z].Count ,self.ParameterQueue.ParameterArray[z].Value, len ,SQLITE_STATIC)
          End
        End
      End

    Else
      obj._ParameterOpcode = self._ParameterOpcode
      If obj._BindParameters(pStmt) = Driver:ok
      End
    End
  End
  Return Driver:ok

!-----------------------------------------------------------------
! The syntax for this part is dependent on the SQL engine being used.
! This takes the OrderBy queue as input, and generates the prop:OrderBy as output
! makes use of self._setDirection to determine the OpCode
DriverViewSQLite2Class.SetOrderByFromQueue            Procedure()
OrderBy      StringTheory
x            Long,Auto
  code
  OrderBy.SetValue('')
  Loop x = 1 to Records(self.OrderQueue)                                                 ! Turn the OrderBy queue into SQLite SQL code.
    Get(self.OrderQueue,x)
    OrderBy.Append(self.OrderQueue.Clause,,',')
    If self.OrderQueue.Nocase
      OrderBy.Append(' COLLATE NOCASE')
    End
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
! If the View is in paging mode, then in order to find the next page, all the order values need to be in the filter.
! uses self.OrderQueue and prop:where as input, self.wherePage as output
! this sets parameters.
DriverViewSQLite2Class._AppendOrderQueueToWhere  Procedure(*Long pCount)
x         Long                 ,Auto
obj1      &DriverFileSQLClass ! ,Auto
obj       &DriverFileSQLClass  !,Auto
con       Cstring(3)
where     StringTheory
orc       StringTheory
alias     Cstring(DRIVER:MAXALIASLENGTH)
nocase    Cstring(20)
first     Byte
thisparm  Cstring(7)
  code
  obj1 &= (self.FileObject[1])
  if obj1 &= null then return.
  Loop x = 1 to Records(self.OrderQueue)
    Get(Self.OrderQueue,x)
    If self.OrderQueue.fixed then cycle.
    If self.OrderQueue.FileIndex
      obj &= (self.FileObject[self.OrderQueue.FileIndex])
      if obj &= null
        alias = ''
      else
        alias = self.GetPROP:Alias(self.OrderQueue.FileIndex)
      end
    else
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
    If x = records(self.OrderQueue)
      con = con & '='
    End
    self._ParameterCount += 1

    If obj &= null
      thisparm = obj1._genparm(self._ParameterCount)
      If first = false
        where.append('(' & self.OrderQueue.Clause & ' ' & con & ' ' &  thisparm  & ')')
        first = true
      Else
        where.append(' OR (' & orc.getvalue() & ' AND ' &  self.OrderQueue.Clause & ' ' & con & ' ' &  thisparm  & ')')
      End
      self._pagingfieldsadded += 1
      orc.append(self.OrderQueue.Clause & ' = ' & thisparm & nocase ,st:noclip,' AND ')
      self._SearchParameter = self._ParameterCount
    ElsIf obj._WithField(self.OrderQueue.FieldIndex) = driver:ok
      nocase = ''
      If self.OrderQueue.Nocase
        Case obj.Fields.Type
        of ClaSTRING orof ClaPSTRING orof ClaCSTRING
          nocase = ' COLLATE NOCASE'
        End
      End
      obj._ParameterOpcode = Opcode:SET
      obj._SetParameterNode(self._ParameterCount,obj.fields,driver:FromShadow,0)
      If first = false
        where.append('(' & alias  & '.' & obj.Fields.Column & ' ' & con & ' ' & obj._genparm(self._ParameterCount) & nocase & ')')
        first = true
      Else
        where.append(' OR (' & orc.getvalue() & ' AND ' &  alias  & '.' & obj.Fields.Column & ' ' & con & ' ' & obj._genparm(self._ParameterCount) & nocase  & ')')
      End
      self._pagingfieldsadded += 1
      orc.append(alias  & '.' & obj.Fields.Column & ' = ' & obj._genparm(self._ParameterCount) & nocase ,st:noclip,' AND ')
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
! trigger a call to the backend, and put the result set into self.result.
! The "whole" result set is retrieved, no resources are left on the server.
! The "first" NEXT/PREVIOUS command will get it all. (built-in paging applies though.)
DriverViewSQLite2Class._ExecuteSelect             PROCEDURE()
result   Long ! not ,Auto
  code
  If Self.Stmt_Set = 0 then Return.
  If self.CheckConnect() = driver:notok then Return.
  self.PrimaryFileObject.SetErrorSqlite(result,'[p125]')              ! Clear error to 0
  If self._BindParameters(Self.Stmt_Set) = driver:ok                  ! Bind all the parameters for the files.
    If self._OffsetParmNumber
      If self._logBind then self.Log('[BIND][sb47]' & self._OffsetParmNumber & ' (long)' & self._SetOffset).
      result = sqlite3_bind_int(self.Stmt_Set,self._OffsetParmNumber,self._SetOffset)                          ! Bind OFFSET
      self._SetOffset = 1
    End
    self.NewResultSet(driver:DontFreeRam)                             ! Want to do this here, before going to the file object.
    self.PrimaryFileObject.SqlCode.SetValue(self.SqlCode)                       ! for logging
    self.PrimaryFileObject._ExecuteToResults(Self.Stmt_Set,self.result)    ! Execute statement, and move resultset to Results interface
    result = sqlite3_reset(Self.Stmt_Set)                           ! reset the statement so it can be used again
    result = sqlite3_clear_bindings(self.Stmt_Set)
  End
  parent._ExecuteSelect()
  Return

!-----------------------------------------------------------------
DriverViewSQLite2Class.Close                     Procedure()
result  Long,Auto
  Code
  self.SetError(NoError)
  If self.Stmt_Set and self.CheckConnect() = driver:ok
    result = sqlite3_finalize(self.Stmt_Set)
    self.Stmt_Set = 0
  End
  self._ClearParameterQueue(0)
  parent.Close()
  Return

!-----------------------------------------------------------------
DriverViewSQLite2Class.Search                    Procedure(String pSearchString,<*? pField1>, <*? pField2>, <*? pField3>, <*? pField4>, <*? pField5>, <*? pField6>, <*? pField7>, <*? pField8>, <*? pField9>, <*? pField10>,<*? pField11>, <*? pField12>, <*? pField13>, <*? pField14>, <*? pField15>)
obj              &DriverFileSQLite2Class,Auto
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
  self._SearchOrderClause = 'rank_fts'
  self.SetProp:Search(obj.TranslateSearch(pSearchString))
  self.SearchFilter = obj.FullPathName & '_fts SEARCH(''' & self.search & ''')'  ! if the SEARCH is a "second call" then just update the filter.
  ! Because the SEARCH function is tokenised, there's no need to bind the parameter - that's done by DriverBaseClass._ExpandToken
  Return

!-----------------------------------------------------------------
DriverViewSQLite2Class.Set                       Procedure(Long pIndex)
result   Long,auto
  Code
  If self.CheckConnect() = driver:notok then Return.
  Parent.Set(pIndex)
  If Errorcode() = NoError
    If self.Stmt_Set
      result = sqlite3_finalize(self.Stmt_Set)
      self.Stmt_Set = 0
    End
  End
  Return

!-----------------------------------------------------------------
DriverViewSQLite2Class._Set                       Procedure(Long pOpcode)
result    Long,Auto
  Code
  If self.CheckConnect() = driver:notok then Return.
  Parent._Set(pOpcode)
  If Errorcode() = NoError
    If self.Stmt_Set
      result = sqlite3_finalize(self.Stmt_Set)
      self.Stmt_Set = 0
    End
    self.Stmt_Set = self._Prepare()
  End
  Return

!-----------------------------------------------------------------
! prepares, binds parameters and executes the SQL in SqlCode.
! SQL is not cached.
! results are set to Results
! returns driver:notok if the SQL part is faulty
DriverViewSQLite2Class._executeSql procedure()
stmt    Long,Auto
result  Long,Auto
  code
  If self.CheckConnect() = driver:notok then Return driver:notok.
  stmt = self._Prepare()
  If stmt
    If self._BindParameters(stmt) = Driver:ok
      self.PrimaryFileObject.SqlCode.SetValue(self.SqlCode)  ! for logging
      self.PrimaryFileObject._ExecuteToResults(stmt,self.result)
    End
    result = sqlite3_finalize(stmt)
    self.PrimaryFileObject.SetErrorSqlite(result,'[p130]')
    If self._ParameterOpcode then self._ClearParameterQueue(self._ParameterOpcode).
  Else
    Return driver:notok
  End
  Return driver:ok
!-----------------------------------------------------------------
DriverViewSQLite2Class._GenParm                PROCEDURE(Long pCount)
  code
  Return '?' & pCount
!!-----------------------------------------------------------------

