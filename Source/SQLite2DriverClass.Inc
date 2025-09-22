!------------------------------------------------------------------------------------------------
!   CapeSoft Clarion File Driver Kit classes are copyright © 2025 by CapeSoft                   !
!   Docs online at : https://capesoft.com/docs/Driverkit/ClarionObjectBasedDrivers.htm
!   Released under MIT License
!------------------------------------------------------------------------------------------------

  include('Equates.Clw'),once
  include('DriverClass.Inc'),once
  include('DriverFields.Inc'),once

SQLite_Major_Required         Equate(3)
SQLite_Minor_Required         Equate(38)
SQLite_Build_Required         Equate(0)

SQLITE_STATIC                 Equate(0)
SQLITE_TRANSIENT              Equate(-1)

SQLite_Ok                     Equate(0)
SQLite_Error                  Equate(1)
SQLite_Internal               Equate(2)
SQLite_Perm                   Equate(3)
SQLite_Abort                  Equate(4)
SQLite_Busy                   Equate(5)
SQLite_Locked                 Equate(6)
SQLite_NoMem                  Equate(7)
SQLite_Readonly               Equate(8)
SQLite_Interrupt              Equate(9)
SQLite_IOErr                  Equate(10)
SQLite_Corrupt                Equate(11)
SQLite_NotFound               Equate(12)
SQLite_Full                   Equate(13)
SQLite_CantOpen               Equate(14)
SQLite_Protocol               Equate(15)
SQLite_Empty                  Equate(16)
SQLite_Schema                 Equate(17)
SQLite_TooBig                 Equate(18)
SQLite_Constraint             Equate(19)
SQLite_MisMatch               Equate(20)
SQLite_Misuse                 Equate(21)
SQLite_Nolfs                  Equate(22)
SQLite_Auth                   Equate(23)
SQLite_Format                 Equate(24)
SQLite_Range                  Equate(25)
SqLite_NotADb                 Equate(26)
SQLite_Notice                 Equate(27)
SQLite_Warning                Equate(28)
SQLite_Row                    Equate(100)
SQLite_Done                   Equate(101)
SQLite_Ok_Load_Permanently    Equate(256)
SQLite_Error_Missing_Colseq   Equate(257)
SQLite_Busy_Recovery          Equate(261)
SQLite_Locked_SharedCache     Equate(262)
SQLite_Readonly_Recovery      Equate(264)
SQLITE_IOERR_READ             Equate(266)
SQLITE_CORRUPT_VTAB           Equate(267)
SQLITE_CANTOPEN_NOTEMPDIR     Equate(270)
SQLITE_CONSTRAINT_CHECK       Equate(275)
SQLITE_AUTH_USER              Equate(279)
SQLITE_NOTICE_RECOVER_WAL     Equate(283)
SQLITE_WARNING_AUTOINDEX      Equate(284)
SQLITE_ERROR_RETRY            Equate(513)
SQLITE_ABORT_ROLLBACK         Equate(516)
SQLITE_BUSY_SNAPSHOT          Equate(517)
SQLITE_LOCKED_VTAB            Equate(518)
SQLITE_READONLY_CANTLOCK      Equate(520)
SQLITE_IOERR_SHORT_READ       Equate(522)
SQLITE_CORRUPT_SEQUENCE       Equate(523)
SQLITE_CANTOPEN_ISDIR         Equate(526)
SQLITE_CONSTRAINT_COMMITHOOK  Equate(531)
SQLITE_NOTICE_RECOVER_ROLLBACK Equate(539)
SQLITE_ERROR_SNAPSHOT         Equate(769)
SQLITE_BUSY_TIMEOUT           Equate(773)
SQLITE_READONLY_ROLLBACK      Equate(776)
SQLITE_IOERR_WRITE            Equate(778)
SQLITE_CORRUPT_INDEX          Equate(779)
SQLITE_CANTOPEN_FULLPATH      Equate(782)
SQLITE_CONSTRAINT_FOREIGNKEY  Equate(787)
SQLITE_READONLY_DBMOVED       Equate(1032)
SQLITE_IOERR_FSYNC            Equate(1034)
SQLITE_CANTOPEN_CONVPATH      Equate(1038)
SQLITE_CONSTRAINT_FUNCTION    Equate(1043)
SQLITE_READONLY_CANTINIT      Equate(1288)
SQLITE_IOERR_DIR_FSYNC        Equate(1290)
SQLITE_CANTOPEN_DIRTYWAL      Equate(1294)
SQLITE_CONSTRAINT_NOTNULL     Equate(1299)
SQLITE_READONLY_DIRECTORY     Equate(1544)
SQLITE_IOERR_TRUNCATE         Equate(1546)
SQLITE_CANTOPEN_SYMLINK       Equate(1550)
SQLITE_CONSTRAINT_PRIMARYKEY  Equate(1555)
SQLITE_IOERR_FSTAT            Equate(1802)
SQLITE_CONSTRAINT_TRIGGER     Equate(1811)
SQLITE_IOERR_UNLOCK           Equate(2058)
SQLITE_CONSTRAINT_UNIQUE      Equate(2067)
SQLITE_IOERR_RDLOCK           Equate(2314)
SQLITE_CONSTRAINT_VTAB        Equate(2323)
SQLITE_IOERR_DELETE           Equate(2570)
SQLITE_CONSTRAINT_ROWID       Equate(2579)
SQLITE_IOERR_BLOCKED          Equate(2826)
SQLITE_CONSTRAINT_PINNED      Equate(2835)
SQLITE_IOERR_NOMEM            Equate(3082)
SQLITE_CONSTRAINT_DATATYPE    Equate(3091)
SQLITE_IOERR_ACCESS           Equate(3338)
SQLITE_IOERR_CHECKRESERVEDLOCK Equate(3594)
SQLITE_IOERR_LOCK             Equate(3850)
SQLITE_IOERR_CLOSE            Equate(4106)
SQLITE_IOERR_DIR_CLOSE        Equate(4362)
SQLITE_IOERR_SHMOPEN          Equate(4618)
SQLITE_IOERR_SHMSIZE          Equate(4874)
SQLITE_IOERR_SHMLOCK          Equate(5130)
SQLITE_IOERR_SHMMAP           Equate(5386)
SQLITE_IOERR_SEEK             Equate(5642)
SQLITE_IOERR_DELETE_NOENT     Equate(5898)
SQLITE_IOERR_MMAP             Equate(6154)
SQLITE_IOERR_GETTEMPPATH      Equate(6410)
SQLITE_IOERR_CONVPATH         Equate(6666)
SQLITE_IOERR_VNODE            Equate(6922)
SQLITE_IOERR_AUTH             Equate(7178)
SQLITE_IOERR_BEGIN_ATOMIC     Equate(7434)
SQLITE_IOERR_COMMIT_ATOMIC    Equate(7690)
SQLITE_IOERR_ROLLBACK_ATOMIC  Equate(7946)
SQLITE_IOERR_DATA             Equate(8202)
SQLITE_IOERR_CORRUPTFS        Equate(8458)

SQLITE_INTEGER                Equate(1)
SQLITE_FLOAT                  Equate(2)
SQLITE_BLOB                   Equate(4)
SQLITE_NULL                   Equate(5)
SQLITE_TEXT                   Equate(3)

SQLITE_OPEN_READONLY          Equate(1)
SQLITE_OPEN_READWRITE         Equate(2)
SQLITE_OPEN_CREATE            Equate(4)
SQLITE_OPEN_URI               Equate(40h)
SQLITE_OPEN_MEMORY            Equate(80h)
SQLITE_OPEN_NOMUTEX           Equate(8000h)
SQLITE_OPEN_FULLMUTEX         Equate(10000h)
SQLITE_OPEN_SHAREDCACHE       Equate(20000h)
SQLITE_OPEN_PRIVATECACHE      Equate(40000h)
SQLITE_OPEN_NOFOLLOW          Equate(01000000h)
SQLITE_OPEN_EXRESCODE         Equate(02000000h)

!============================================================================================================
DriverFileSQLite2Class   Class(DriverFileSQLClass), Type, MODULE('SQLite2DriverClass.Clw'),LINK('SQLite2DriverClass.Clw',DRVLITE2LM), DLL(DRVLITE2DM)

! driver options

!opt:where                  &CString       ! CString(255) !/WHERE=dude ! sets prop:where
opt:autoInc                 Byte           ! /AUTOINC=FALSE | TRUE  ! SQLite does AutoIncrement If AUTOINC is set to TRUE and there is a
                                                           ! primary Key on the table that has only one component and that component is of type
                                                           ! Long, then the CREATE statement will create an AUTOINCREMENT PRIMARY Key
                                                           ! constraint on that component and ADD will retrieve the value for that field as
                                                           ! set by SQLite.

opt:NoPrimary               Byte
opt:UsePrimary              Byte
!opt:Busy_timeout            Long

!properties not saved by a GETSTATE or updated by RESTORESTATE
Deformat                    &StringDeformat   ! used in DeformatText so preCreated here for performance

Stmt_Add                    Long
Stmt_Append                 Long
Stmt_Delete                 Long
Stmt_Get                    Long
Stmt_Put                    Long
Stmt_Set                    Long
Stmt_Upsert                 Long

_fromCache                  Byte
_AddCache                   Byte   ! these store the value that was in propscache when the Stmt_ was created. If a property is changed
_AddMemoCache               Byte            ! the status of nomemo when the Add SQL was cached.
_AddSqlCache                &StringTheory   ! the SQL for the ADD command. So that prop:sql is set after the call.

_AppendCache                Byte   ! then the Stmt_ s are no Longer valid, and need to be-compiled by the database engine.
_AppendMemoCache            Byte            ! the status of nomemo when the Append SQL was cached.
_AppendSqlCache             &StringTheory   ! the SQL for the APPEND command. So that prop:sql is set after the call.

_DeleteCache                Byte   !
_DeleteSqlCache             &StringTheory   ! the SQL for the DELETE command. So that prop:sql is set after the call.

_GetCache                   Byte   !
_GetMemoCache               Byte            ! the status of nomemo when the Get SQL was cached.
_GetKeyCache                &Key
_GetSqlCache                &StringTheory   ! the SQL for the GET command. So that prop:sql is set after the call.

_PutCache                   Byte   !
_PutMemoCache               Byte            ! the status of nomemo when the Put SQL was cached.
_PutSqlCache                &StringTheory   ! the SQL for the PUT command. So that prop:sql is set after the call.

_UpsertCache                Byte   !
_UpsertMemoCache            Byte            ! the status of nomemo when the Upsert SQL was cached.
_UpsertSqlCache             &StringTheory   ! the SQL for the UPSERT command. So that prop:sql is set after the call.

! properties saved by a GETSTATE and restored by a RESTORESTATE
__SQLiteSTATESTART          Byte

_SynchronousAtStream        Byte
_CacheSizeAtStream          Long

__SQLiteSTATEEND            Byte

! methods
! -------
CONSTRUCT                   Procedure()
DESTRUCT                    Procedure(),Virtual
LoadLogging                 Procedure(),Derived
_parseFields                Procedure(Long pAddr),Derived
InterpretSQLType            Procedure(Long pType),String,Virtual
SetErrorSqlite              Procedure(Long pSQLiteErrorCode,String pRef),Virtual
CheckConnect                Procedure(),Long,Derived
AfterConnect                Procedure(),Virtual
_SetDefaultPragmas          Procedure(),Virtual
ReplaceObject               Procedure(Long pOldObjectAddress),Derived
ValidateStructure           Procedure(),Long,Derived
_ValidateSearchTable        Procedure(),Long,VIRTUAL
_CreateFTS                  Procedure(),Long,VIRTUAL
ExplainStart                Procedure(),String,Derived
_ExecuteSql                 Procedure(),Long,Derived
_ExecuteSql                 Procedure(Long pStmt),Long,Virtual
_ExecuteSqlWork             Procedure(Long pStmt),Long,Virtual
_ExecuteSql                 Procedure(StringTheory pSQL, <? pParm1>,<? pParm2>,<? pParm3>,<? pParm4>,<? pParm5>,<? pParm6>,<? pParm7>,<? pParm8>,<? pParm9>,<? pParm10>,<? pParm11>,<? pParm12>,<? pParm13>,<? pParm14>,<? pParm15>,<? pParm16>,<? pParm17>,<? pParm18>,<? pParm19>,<? pParm20>),Long,Derived
_ClearStmts                 Procedure(),Virtual
_GetDBVersion               Procedure(),Virtual
_GenParm                    Procedure(Long pCount),String,Derived
_AddSQL                     Procedure(Long pOpcode),Long,Virtual
_MergeSQL                   Procedure(DriverFileSQLClass pDestination,String pDestinationName),Virtual
_Prepare                    Procedure(),Long,Virtual
_Prepare                    Procedure(StringTheory pSqlCode),Long,Virtual
_PrepareAdd                 Procedure(Long pOpcode),Virtual
_PrepareDelete              Procedure(),Long,Virtual
_PrepareDelete              Procedure(String pFilter),Long,Virtual
_PrepareGet                 Procedure(Key pKey),Long,Virtual
_PreparePut                 Procedure(),Long,Virtual
_PrepareRandom              Procedure(String pFilter, BIGINT pOffset),Long,Virtual

_GenerateSelect             Procedure(Long pOpcode),Derived
_BindParameters             Procedure(Long pStmt),Long,Virtual
_BindField                  Procedure(Long pStmt,Long pCount, Long pAddress),Virtual
_BindBlob                   Procedure(Long pStmt,Long pCount),Virtual
_ToRecord                   Procedure(Long pStmt,Long pBuffer),Virtual
_ExecuteToRecord            Procedure(Long pStmt,Long pWhichBuffer,Byte pErrIfNoRecord,Long pOpCode),Virtual
_ExecuteToResults           Procedure(Long pStmt,iResultSet pResult),Virtual
_ToResult                   Procedure(Long pStmt, Long pColumns,iResultSet pResult),Virtual
_ExecuteSelect              Procedure(),Derived
_MergeWork                  Procedure(DriverFileSQLClass pObj, String pDestination, Long pOptions),Virtual
DeformatText                Procedure(String pText),String,Derived
ResultToExplain             Procedure(iResultSet pResult),Derived
OperatorsToFunction         Procedure(StringTheory pStr),Long,Proc,Derived
_TranslateDateSql           Procedure(String pMonth, String pDay, String pYear, Byte pLabelType,*CString pCond),String,Derived
_TranslateDatePartSQL       Procedure(*CString pField,String pPart),String,Virtual
_TranslateDaySQL            Procedure(*CString pField),String,Derived
_TranslateMonthSQL          Procedure(*CString pField),String,Derived
_TranslateYearSQL           Procedure(*CString pField),String,Derived
_TranslateLabelOverDateSQL  Procedure(FieldGroupType pNode),String,Derived
_TranslateLabelOverTimeSQL  Procedure(FieldGroupType pNode),String,Derived
TranslateReserved           Procedure(*cString pColumn),String,Derived
TranslateSearch             Procedure(String pSearchString),String,Derived
TranslateRegularExpression  Procedure(*CString pExpr,*CString pColumn),String,Derived
_LoadArray                  Procedure(*String pStr,Long pIndex),Derived
_AppendOrderQueueToWhere    Procedure(),Virtual
SetOrderByFromQueue         Procedure(),Derived
SetDriverOption             Procedure(String pOption, String pValue),String,Derived
_ConstructKey               Procedure(Long pPrimary),Virtual
_Morph                      Procedure(String pFieldLabel,Byte pClarionType, Long pClarionAddress, Long pClarionLength, Long pDbType, Long pDbAddress, Long pDbLength, Long pSqlTimeStamp, Byte pSetFieldNull, *Long rTextLength),Derived
_UpdateFileStrings          Procedure(),Derived

! File Procedures
BUILD                       Procedure(),Virtual
BUILD                       Procedure(Key pKey),Virtual
CLOSE                       Procedure(),Derived
COPY                        Procedure(String pNewFileName, Long pOptions),Derived
_CREATETABLE                Procedure(),Derived
CREATEFIELD                 Procedure(*? pField1),Derived
CREATEFIELD                 Procedure(String pName, String pType, String pConstraint),Derived
CREATEKey                   Procedure(Key pKey),Derived
CREATEKey                   Procedure(String pName, Long pOptions, *? pField1, *? pField2, <*? pField3>, <*? pField4>, <*? pField5>, <*? pField6>, <*? pField7>, <*? pField8>, <*? pField9>, <*? pField10>),Derived
DECLARATION                 Procedure(Long pOptions=0),String,Derived
DECLARATION                 Procedure(Key pKey,Long pOptions=0),String,Derived
DUPLICATE                   Procedure(Key pKey),Derived,Long
EMPTY                       Procedure(),Derived
EXISTS                      Procedure(String pTablename),Long,PROC,Derived
FLUSH                       Procedure(),Derived
GETSTATE                    Procedure(Long pSaveBlob),Long,Derived
MERGEFast                   Procedure(File pDestination, Long pOptions),Virtual                                        ! New Command (called via MERGE)
MERGESlow                   Procedure(File pDestination, Long pOptions),Virtual                                        ! New Command (called via MERGE)
MERGEFast                   Procedure(String pDestination, Long pOptions),Virtual                                      ! New Command (called via MERGE)
OPEN                        Procedure(Long pAccessMode=022h),Derived
PACK                        Procedure(),Derived
REMOVEFIELD                 Procedure(String pName),Derived
REMOVEKey                   Procedure(String pName),Derived
REMOVEKey                   Procedure(Key pKey),Derived
RENAME                      Procedure(String pNewFileName),Derived
RESTORESTATE                Procedure(Long pState, Byte pBuffer),Derived
RESUMERELATIONS             Procedure(),Derived
STREAM                      Procedure(),Derived
SUSPENDRELATIONS            Procedure(),Derived

! Record Access
ADD                         Procedure(),Derived
APPEND                      Procedure(),Derived
DELETE                      Procedure(),Derived
DELETE                      Procedure(String pFilter),Derived
EXPORTCSV                   Procedure(String pDosFileName, Long pOptions=0),Long,PROC,Derived
GET                         Procedure(Key pKey),Derived
GETRANDOM                   Procedure(String pFilter),Derived
IMPORTCSV                   Procedure(String pDosFileName, Long pOptions=0),Long,PROC,Derived
NEXT                        Procedure(),Derived
PREVIOUS                    Procedure(),Derived
PUT                         Procedure(),Derived
UPSERT                      Procedure(),Derived
SEARCH                      Procedure(String pSearchString,<*? pField1>, <*? pField2>, <*? pField3>, <*? pField4>, <*? pField5>, <*? pField6>, <*? pField7>, <*? pField8>, <*? pField9>, <*? pField10>,<*? pField11>, <*? pField12>, <*? pField13>, <*? pField14>, <*? pField15>),Derived
_SET                        Procedure(Byte pSetMethod, BigInt pPointer,Key pSetKey, Key pSetKeyKey),Derived

! Transaction Processing
LOGOUTCONNECTION           Procedure(),Derived
COMMIT                     Procedure(),Derived
ROLLBACK                   Procedure(),Derived
ROLLBACK                   Procedure(String pSavePoint),Derived
SAVEPOINT                  Procedure(String pSavePoint),Derived


!Properties that are really commands
CONNECT                     Procedure(Long pOptions=0),Derived    ! prop:connect
CREATEDB                    Procedure(String pDatabaseName),Derived                   ! prop:createdb
DISCONNECT                  Procedure(),Derived                   ! prop:disconnect

!Properties
GetPROP:Arrays              Procedure(),String,Derived            ! Return 1 if the driver supports arrays
GetPROP:Database            Procedure(),String,Derived            ! Get database name from connection String
GetPROP:DatabaseName        Procedure(),String,Derived            ! Get database name - ie SQLITE, PostgreSQL etc.
GETPROP:Driver              Procedure(),String,Derived            ! Get name of file driver !D
GetPROP:DriverVersion       Procedure(),String,Derived
GetProp:Hdbc                Procedure(),String,Derived
GetPROP:Server              Procedure(),String,Derived            ! Get server name from connection String
GetPROP:User                Procedure(),String,Derived            ! Get user name from connection String
                          End

!============================================================================================================
DriverViewSQlite2Class    Class(DriverViewSQLClass), Type, MODULE('SQLite2DriverClass.Clw'),LINK('SQLite2DriverClass.Clw',DRVLITE2LM), DLL(DRVLITE2DM)
PrimaryFileObject           &DriverFileSQLite2Class
Stmt_Set                    Long

Construct                   Procedure()
ExplainStart                Procedure(),String,Derived
_BindParameters             Procedure(Long pStmt),Long,Virtual
_GenParm                    Procedure(Long pCount),String,Derived
_ExecuteSelect              Procedure(),Derived
CLOSE                       Procedure(),Derived
SEARCH                      Procedure(String pSearchString,<*? pField1>, <*? pField2>, <*? pField3>, <*? pField4>, <*? pField5>, <*? pField6>, <*? pField7>, <*? pField8>, <*? pField9>, <*? pField10>,<*? pField11>, <*? pField12>, <*? pField13>, <*? pField14>, <*? pField15>),Derived
SET                         Procedure(Long pIndex),Derived
_Set                        Procedure(Long pOpcode),Derived
SetOrderByFromQueue         Procedure(),Derived
_AppendOrderQueueToWhere    Procedure(*Long pCount),Derived
CheckConnect                Procedure(),Long,Derived
_Prepare                    Procedure(),Long,Virtual
_ExecuteSql                 Procedure(),Long,Derived
GetPROP:Database            Procedure(),String,Derived         ! Get database name from connection String
GetPROP:DatabaseName        Procedure(),String,Derived         ! Get database name - ie SQLITE, PostgreSQL etc.
GETPROP:Driver              Procedure(),String,Derived         ! Get name of file driver !D
GetPROP:Server              Procedure(),String,Derived         ! Get server name from connection String
GetPROP:User                Procedure(),String,Derived         ! Get user name from connection String
                          End
!============================================================================================================
! Supported, Built-in, Custom Field Types
DriverGuidSQLite2         DriverGuidClass

!============================================================================================================

