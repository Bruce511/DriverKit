!------------------------------------------------------------------------------------------------
!   CapeSoft Clarion File Driver Kit classes are copyright © 2025 by CapeSoft                   !
!   Docs online at : https://capesoft.com/docs/Driverkit/ClarionObjectBasedDrivers.htm
!   Released under MIT License
!------------------------------------------------------------------------------------------------
! Object based drivers introduces new properties, FILE and VIEW commands. This module acts as a simple
! bridge so those commands can be called just like any other FILE or VIEW command.
!
! This INC file needs to be added to Global Includes to support the new commands
! For new Opcodes and FieldTypes see Driver.Inc
!------------------------------------------------------------------------------------------------

Driver:Version  Equate('1.10')

!Region ----------  Equates ----------
! BIGINT: use this for now as a 52 bit integer. In later clarion versions could become a int64
BIGINT                  Equate(REAL)
Driver:BufferWholeFile  Equate(-1)
Driver:FreeBuffer       Equate(-2)

Driver:HTML             Equate(4)    ! Export : Format parameter
Driver:JSON             Equate(3)
Driver:XML              Equate(2)
Driver:CSV              Equate(1)

Driver:Clipboard        Equate(128)  ! Export:  used in place of file name

Driver:Append           Equate(128)  ! Export : Options parameters
Driver:Header           Equate(1)
Driver:Upsert           Equate(2)
Driver:Add              Equate(4)
Driver:Bin2Base64       Equate(8)
Driver:Base64           Equate(8)

Driver:LogSql           Equate(1)
Driver:LogClarion       Equate(2)
Driver:LogDetails       Equate(4)
Driver:LogData          Equate(4)
Driver:LogBind          Equate(8)
Driver:LogExplain       Equate(16)
Driver:LogOptions       Equate(32)
Driver:LogConnections   Equate(64)

Driver:UniqueKeys       Equate(1)
Driver:DefaultValues    Equate(2)
Driver:Constraints      Equate(4)
Driver:ForeignKeys      Equate(8)
Driver:Indexes          Equate(16)
Driver:Triggers         Equate(32)

driver:Table                Equate(1)    ! U
driver:StoredProcedure      Equate(2)    ! P
driver:SP                   Equate(2)
driver:Trigger              Equate(3)    ! TR
driver:Index                Equate(4)
driver:PrimaryKey           Equate(5)    ! PK
driver:UniqueConstraint     Equate(6)    ! UQ
driver:ForeignKeyConstraint Equate(7)    ! F
driver:DefaultConstraint    Equate(8)    ! D
driver:ScalarFunction       Equate(9)    ! FN
driver:TableValuedFunction  Equate(10)   ! TF
driver:View                 Equate(11)   ! V

Driver:In                   Equate(1)
Driver:Out                  Equate(2)

driver:NoAction         Equate(0)
driver:Cascade          Equate(1)
driver:CascadeUpdate    Equate(1)
driver:CascadeDelete    Equate(1)
driver:Clear            Equate(2)
driver:ClearUpdate      Equate(2)
driver:ClearDelete      Equate(2)
driver:Restrict         Equate(3)
driver:RestrictUpdate   Equate(3)
driver:RestrictDelete   Equate(3)

!EndRegion: Equates

!Region ----------  Map ----------
  MAP
    MODULE('CWDriver.Clw')
AddRelation   Procedure(File pChildFile, File pParentFile, Long pOnUpdate, Long pOnDelete, *? pChildField1, *? pParentField1, <*? pChildField2>, <*? pParentField2>, <*? pChildField3>, <*? pParentField3>, <*? pChildField4>, <*? pParentField4>, <*? pChildField5>, <*? pParentField5>, <*? pChildField6>, <*? pParentField6>, <*? pChildField7>, <*? pParentField7>, <*? pChildField8>, <*? pParentField8>, <*? pChildField9>, <*? pParentField9>, <*? pChildField10>, <*? pParentField10>),Name('ADDRELATION'),Dll(dll_mode)
BindField   Procedure(FILE pFile,String pName, *Long pLong),name('BINDlong'),Dll(dll_mode)
BindField   Procedure(FILE pFile,String pName, *Real pReal),name('BINDreal'),Dll(dll_mode)
BindField   Procedure(FILE pFile,String pName, *String pString),name('BINDstring'),Dll(dll_mode)
BindField   Procedure(FILE pFile,String pName, *Cstring pCstring),name('BINDcstring'),Dll(dll_mode)
BindField   Procedure(VIEW pView,String pName, *Long pLong),name('BINDlongV'),Dll(dll_mode)
BindField   Procedure(VIEW pView,String pName, *Real pReal),name('BINDrealV'),Dll(dll_mode)
BindField   Procedure(VIEW pView,String pName, *String pString),name('BINDstringV'),Dll(dll_mode)
BindField   Procedure(VIEW pView,String pName, *Cstring pCstring),name('BINDcstringV'),Dll(dll_mode)
Bytes64   Procedure(FILE pFile),BIGINT,name('BYTES64'),Dll(dll_mode)
CallOut   Procedure(FILE pFile,String pStoredProcedure,*? pParm1,<*? pParm2>,<*? pParm3>,<*? pParm4>,<*? pParm5>,<*? pParm6>,<*? pParm7>,<*? pParm8>,<*? pParm9>,<*? pParm10>,<*? pParm11>,<*? pParm12>,<*? pParm13>,<*? pParm14>,<*? pParm15>,<*? pParm16>,<*? pParm17>,<*? pParm18>,<*? pParm19>,<*? pParm20>),name('CALLOUT'),Dll(dll_mode)
Call   Procedure(FILE pFile,String pStoredProcedure,<? pParm1>,<? pParm2>,<? pParm3>,<? pParm4>,<? pParm5>,<? pParm6>,<? pParm7>,<? pParm8>,<? pParm9>,<? pParm10>,<? pParm11>,<? pParm12>,<? pParm13>,<? pParm14>,<? pParm15>,<? pParm16>,<? pParm17>,<? pParm18>,<? pParm19>,<? pParm20>),name('CALLspVal'),Dll(dll_mode)
ClearProps   Procedure(FILE pFile),name('CLEARPROPSfile'),Dll(dll_mode)
ClearProps   Procedure(VIEW pView),name('CLEARPROPSview'),Dll(dll_mode)
Commit   Procedure(FILE pFile),name('COMMITconn'),Dll(dll_mode)
Connect   Procedure(FILE pFile,Long pOptions=0),name('CONNECT'),Dll(dll_mode)
Copy   Procedure(FILE pFile, String pFileName, Long pOptions),name('COPYoptions'),Dll(dll_mode)
CreateDB   Procedure(FILE pFile,String pDatabaseName),name('CREATEDBname'),Dll(dll_mode)
CreateDB   Procedure(FILE pFile),name('CREATEDB'),Dll(dll_mode)
CreateField   Procedure(FILE pFile,*? pField1),name('CREATEfield'),Dll(dll_mode)
CreateField   Procedure(FILE pFile,String pName, String pType, String pConstraint),name('CREATEfieldtext'),Dll(dll_mode)
CreateKey   Procedure(KEY pKey),name('CREATEkey'),Dll(dll_mode)
CreateKey   Procedure(File pFile,String pName, Long pOptions, *? pField1, *? pField2, <*? pField3>, <*? pField4>, <*? pField5>, <*? pField6>, <*? pField7>, <*? pField8>, <*? pField9>, <*? pField10>),name('CREATEnewkey'),Dll(dll_mode)
CreateRelations   Procedure(File pFile),name('CREATErelations'),Dll(dll_mode)
Declaration   Procedure(FILE pFile,Long pOptions=0),STRING,name('DECLARATION'),Dll(dll_mode)
Declaration   Procedure(KEY pKey,Long pOptions=0),STRING,name('DECLARATIONkey'),Dll(dll_mode)
Delete   Procedure(FILE pFile,String pFilter),Name('DeleteFilter'),Dll(dll_mode)
Disconnect   Procedure(FILE pFile),name('DISCONNECT'),Dll(dll_mode)
Except   Procedure(FILE pFile,<String pFilter>),name('EXCEPT'),Dll(dll_mode)
Exists   Procedure(FILE pFile),LONG,name('EXISTS'),Dll(dll_mode)
Exists   Procedure(FILE pFile,STRING pTableName),LONG,name('EXISTSname'),Dll(dll_mode)
ExistsDB   Procedure(FILE pFile,STRING pDatabaseName),LONG,name('EXISTSdbname'),Dll(dll_mode)
Exists   Procedure(FILE pFile,Long pWhat, STRING pName),LONG,name('EXISTSwhat'),Dll(dll_mode)
Export   Procedure(FILE pFile,STRING pFileName, Long pOptions=0,Long pFormat=driver:csv),name('EXPORTfile'),Dll(dll_mode)
!Export   Procedure(VIEW pFile,STRING pFileName,Long pFormat,Long pAppend),name('EXPORTview'),Dll(dll_mode)
Get64   Procedure(FILE pFile,BIGINT pFilePointer),name('GET64'),Dll(dll_mode)
Get64   Procedure(FILE pFile,BIGINT pFilePointer, LONG pLength),name('GET64len'),Dll(dll_mode)
GetRandom   Procedure(FILE pFile),name('GETRANDOMfile'),Dll(dll_mode)
GetRandom   Procedure(FILE pFile,String pFilter),name('GETRANDOMfilefilter'),Dll(dll_mode)
Import   Procedure(FILE pFile,STRING pFileName, Long pOptions=0,Long pFormat=driver:csv),name('IMPORTfile'),Dll(dll_mode)
Intersect   Procedure(FILE pFile,<String pFilter>),name('INTERSECT'),Dll(dll_mode)
JoinTable   Procedure(VIEW pView, FILE pParentFile, *KEY pKey, Byte pJoinType, *? pField1),name('JoinKey'),Dll(dll_mode)
JoinTable   Procedure(VIEW pView, FILE pParentFile, *KEY pKey, Byte pJoinType, *? pField1, *? pField2, <*? pField3>, <*? pField4>, <*? pField5>, <*? pField6>, <*? pField7>, <*? pField8>, <*? pField9>, <*? pField10>),name('JoinKeyEx'),Dll(dll_mode)
JoinTable   Procedure(VIEW pView, FILE pParentFile, *FILE pJoinFile, Byte pJoinType, String pExpression),name('JoinTable'),Dll(dll_mode)
Log   Procedure(FILE pFile,String pText),name('LOG'),Dll(dll_mode)
LogBuffer   Procedure(FILE pFile),name('LOGBUFFER'),Dll(dll_mode)
LogBuffer   Procedure(VIEW pView),name('LOGBUFFERview'),Dll(dll_mode)
LoggingOn   Procedure(FILE pFILE,<String pFileName>,Long pOptions=0),name('LOGGINGON'),Dll(dll_mode)
LoggingOff   Procedure(FILE pFILE),name('LOGGINGOFF'),Dll(dll_mode)
LoggingOn   Procedure(VIEW pVIEW,<String pFileName>,Long pOptions=0),name('LOGGINGONview'),Dll(dll_mode)
LoggingOff   Procedure(VIEW pView),name('LOGGINGOFFview'),Dll(dll_mode)
LogoutConnection   Procedure(FILE pFile),name('LOGOUTconn'),Dll(dll_mode)
Merge   Procedure(FILE pFile,FILE pDestination, Long pOptions=0),name('MERGE'),Dll(dll_mode)
Merge   Procedure(FILE pFile,STRING pDestination, Long pOptions=0),name('MERGEname'),Dll(dll_mode)
Pointer64   Procedure(FILE pFile),BIGINT,name('POINTER64'),Dll(dll_mode)
ProjectField   Procedure(VIEW pView,String pExpression,String pAs),name('PROJECTFIELD'),Dll(dll_mode)
ProjectField   Procedure(VIEW pView,FILE pFile,Long pIndex),name('PROJECTFIELDindex'),Dll(dll_mode)
ProjectField   Procedure(VIEW pView,*? pField),name('PROJECTFIELDlabel'),Dll(dll_mode)
Put64   Procedure(FILE pFile,BIGINT pFilePointer),name('PUT64'),Dll(dll_mode)
Put64   Procedure(FILE pFile,BIGINT pFilePointer, LONG pLength),name('PUT64len'),Dll(dll_mode)
Records   Procedure(FILE pFile,String pFilter),BIGINT,name('RECORDSFilter'),Dll(dll_mode)
Records   Procedure(FILE pFile,*? pField1, <*? pField2>, <*? pField3>, <*? pField4>, <*? pField5>),BIGINT,name('RECORDSfield'),Dll(dll_mode)
Records64   Procedure(FILE pFile),BIGINT,name('RECORDS64'),Dll(dll_mode)
Records64   Procedure(VIEW pView),BIGINT,name('RECORDS64View'),Dll(dll_mode)
Records   Procedure(VIEW pView, Long pNumber),BIGINT,name('RECORDS64ViewNumber'),Dll(dll_mode)
!Relate(FILE pParent, FILE pChild, Byte pType, Byte pOnUpdate, Byte pOnDelete, String pRelationship),name('RELATE'),Dll(dll_mode)
RemoveField   Procedure(FILE pFile,String pName),name('REMOVEfield'),Dll(dll_mode)
RemoveKey   Procedure(FILE pFile,String pName),name('REMOVEkeyname'),Dll(dll_mode)
RemoveKey   Procedure(KEY pKey),name('REMOVEkey'),Dll(dll_mode)
Reopen   Procedure(FILE pFile,LONG pNewMode),name('REOPEN'),Dll(dll_mode)
ResultGet   Procedure(FILE pFile,BIGINT pRow),name('RESULTGET'),Dll(dll_mode)
ResultGet   Procedure(VIEW pView,BIGINT pRow),name('RESULTGETview'),Dll(dll_mode)
ResultGet   Procedure(FILE pFile,BIGINT pRow,Long pColumn),String,name('RESULTGETcell'),Dll(dll_mode)
ResultGet   Procedure(VIEW pView,BIGINT pRow,Long pColumn),String,name('RESULTGETcellView'),Dll(dll_mode)
ResultGet   Procedure(FILE pFile,BIGINT pRow,Long pColumn,*Byte pNull),String,name('RESULTGETcellNull'),Dll(dll_mode)
ResultGet   Procedure(VIEW pView,BIGINT pRow,Long pColumn,*Byte pNull),String,name('RESULTGETcellNullView'),Dll(dll_mode)
ResultNext   Procedure(FILE pFile),name('RESULTNEXT'),Dll(dll_mode)
ResultNext   Procedure(VIEW pView),name('RESULTNEXTview'),Dll(dll_mode)
ResultPrevious   Procedure(FILE pFile),name('RESULTPREVIOUS'),Dll(dll_mode)
ResultPrevious   Procedure(VIEW pView),name('RESULTPREVIOUSview'),Dll(dll_mode)
ResultRow   Procedure(FILE pFile),BIGINT,name('RESULTROW'),Dll(dll_mode)
ResultRow   Procedure(VIEW pView),BIGINT,name('RESULTROWView'),Dll(dll_mode)
ResultRecords   Procedure(FILE pFile),BIGINT,name('RESULTRECORDS'),Dll(dll_mode)
ResultRecords   Procedure(VIEW pView),BIGINT,name('RESULTRECORDSView'),Dll(dll_mode)
ResumeRelations   Procedure(FILE pFile),name('RESUMERELATIONS'),Dll(dll_mode)
Rollback   Procedure(FILE pFile),name('ROLLBACKconn'),Dll(dll_mode)
Rollback   Procedure(FILE pFile,String pSavePoint),name('ROLLBACKsavepoint'),Dll(dll_mode)
SavePoint   Procedure(FILE pFile,String pSavePoint),name('SAVEPOINT'),Dll(dll_mode)
Search   Procedure(FILE pFile,String pSearchString,<*? pField1>, <*? pField2>, <*? pField3>, <*? pField4>, <*? pField5>, <*? pField6>, <*? pField7>, <*? pField8>, <*? pField9>, <*? pField10>,<*? pField11>, <*? pField12>, <*? pField13>, <*? pField14>, <*? pField15>),Name('SEARCHfile'),Dll(dll_mode)
Search   Procedure(VIEW pView,String pSearchString,<*? pField1>, <*? pField2>, <*? pField3>, <*? pField4>, <*? pField5>, <*? pField6>, <*? pField7>, <*? pField8>, <*? pField9>, <*? pField10>,<*? pField11>, <*? pField12>, <*? pField13>, <*? pField14>, <*? pField15>),Name('SEARCHview'),Dll(dll_mode)
Set   Procedure(FILE pFile,*BIGINT pPointer),name('SET64ptr'),Dll(dll_mode)
Set   Procedure(KEY pKey, *BIGINT pSetPointer), name('SET64keyptr'),Dll(dll_mode)
Set   Procedure(KEY pKey, KEY pStart, *BIGINT pSetPointer),name('SET64keykeyptr'),Dll(dll_mode)
Set64   Procedure(FILE pFile,BIGINT pPointer),name('SET64ptra'),Dll(dll_mode)
SetCustomType   Procedure(FILE pFILE,String pFieldLabel,iDriverField pCustom),name('SETCUSTOMTYPE'),Dll(dll_mode)
Skip64   Procedure(FILE pFile,BIGINT pValue),name('SKIP64'),Dll(dll_mode)
SQL   Procedure(FILE pFILE,String pSql,<? pParm1>,<? pParm2>,<? pParm3>,<? pParm4>,<? pParm5>,<? pParm6>,<? pParm7>,<? pParm8>,<? pParm9>,<? pParm10>,<? pParm11>,<? pParm12>,<? pParm13>,<? pParm14>,<? pParm15>,<? pParm16>,<? pParm17>,<? pParm18>,<? pParm19>,<? pParm20>),name('SQLFile'),Dll(dll_mode)
Subset   Procedure(FILE pFILE,*? pParm1,<*? pParm2>,<*? pParm3>,<*? pParm4>,<*? pParm5>,<*? pParm6>,<*? pParm7>,<*? pParm8>,<*? pParm9>,<*? pParm10>,<*? pParm11>,<*? pParm12>,<*? pParm13>,<*? pParm14>,<*? pParm15>,<*? pParm16>,<*? pParm17>,<*? pParm18>,<*? pParm19>,<*? pParm20>),name('SUBSET'),Dll(dll_mode)
SuspendRelations   Procedure(FILE pFile),name('SUSPENDRELATIONS'),Dll(dll_mode)
ToQueue   Procedure(FILE pFile,Queue pQueue),name('TOQUEUE'),Dll(dll_mode)
FromQueue   Procedure(FILE pFile,Queue pQueue),name('FROMQUEUE'),Dll(dll_mode)
Union   Procedure(FILE pFile,<String pFilter>),name('UNION'),Dll(dll_mode)
Update   Procedure(File pFile,String pFilter,*? pField1,String pValue1,<*? pField2>,<String pValue2>,<*? pField3>,<String pValue3>,<*? pField4>,<String pValue4>,<*? pField5>,<String pValue5>,<*? pField6>,<String pValue6>,<*? pField7>,<String pValue7>,<*? pField8>,<String pValue8>,<*? pField9>,<String pValue9>,<*? pField10>,<String pValue10>),Name('UPDATE'),Dll(dll_mode)
Update   Procedure(Key pKey,*? pField1,String pValue1,<*? pField2>,<String pValue2>,<*? pField3>,<String pValue3>,<*? pField4>,<String pValue4>,<*? pField5>,<String pValue5>,<*? pField6>,<String pValue6>,<*? pField7>,<String pValue7>,<*? pField8>,<String pValue8>,<*? pField9>,<String pValue9>,<*? pField10>,<String pValue10>),Name('UPDATEKey'),Dll(dll_mode)
Upsert   Procedure(File pFile),Name('UPSERT'),Dll(dll_mode)
    END
  END
!EndRegion: Map

!------------------------------------------------------------------------------------------------
!
!Region ----------  Properties ----------
!------------------------------------------------------------------------------------------------
! New Properties
PROP:PageSize           EQUATE(7341H)   ! not new, but synonym for prop:FetchSize
PROP:Prefix             EQUATE(7354H)   ! not new, but synonym for prop:pre, Can now be read.
PROP:LogData            EQUATE (7329H)  ! not new, but synonym for prop:Details. Set tracing of record buffer

Prop:Pointer            Equate(7401h)
Prop:Records            Equate(7402h)
!Prop:LogToDebug         Equate(7403h)
Prop:Uuid               Equate(7405h)
Prop:Uuid4              Equate(7406h)
Prop:Uuid7              Equate(7407h)
Prop:Uuid8              Equate(7408h)
Prop:Limit              Equate(7409h)
Prop:Offset             Equate(740Ah)
Prop:Distinct           Equate(740Bh)
Prop:Explain            Equate(740Ch)
Prop:Paging             Equate(740Dh)
Prop:NoPrevious         Equate(740Eh)
Prop:DatabaseName       Equate(740Fh)
Prop:OrderBy            Equate(7410h)
Prop:DbVersionMajor     Equate(7411h)
Prop:DbVersionMinor     Equate(7412h)
Prop:DbVersionBuild     Equate(7413h)
Prop:AddOnly            Equate(7414h)
Prop:NoMemo             Equate(7415h)
Prop:ClearProps         Equate(7416h)
Prop:Reopen             Equate(7417h)    ! write only, more of a command than a property
Prop:Connect            Equate(7418h)
Prop:AutoProject        Equate(7419h)    ! when no fields are projected in the view for  table, then just project all fields.
Prop:Merge              Equate(741Ah)
Prop:MergeName          Equate(741Bh)
Prop:Exists             Equate(741Ch)    ! does the table exist? (ie has it been created in the database?)
Prop:Server             Equate(741Dh)    ! the "server" part of the connection string
Prop:Database           Equate(741Eh)    ! the "database" part of the connection string
Prop:User               Equate(741Fh)    ! the "user" part of the connection string
Prop:Bytes              Equate(7420h)
Prop:Project            Equate(7421h)
Prop:Attributes         Equate(7422h)
Prop:ResultGet          Equate(7423h)
Prop:ResultNext         Equate(7424h)
Prop:ResultPrevious     Equate(7425h)
Prop:ResultRow          Equate(7426h)
Prop:ResultRecords      Equate(7427h)
Prop:ResultFree         Equate(7428h)
Prop:NotDistinct        Equate(7429h)     ! used to find duplicate records
Prop:WherePage          Equate(742Ah)
Prop:Json               Equate(742Bh)
prop:Affected           Equate(742Ch)
prop:Pool               Equate(742Dh)
prop:RelationsOff       Equate(742Eh)
prop:OBD                Equate(742Fh)
prop:FastWrite          Equate(7430h)
prop:Arrays             Equate(7431h)    ! returns 1 if the driver supports arrays, blank otherwise
prop:ChildrenAffected   Equate(7432h)
prop:Separator          Equate(7433h)    ! used in EXPORT command
prop:LineEndings        Equate(7434h)    ! used in EXPORT command
prop:AlwaysQuote        Equate(7435h)    ! used in EXPORT command
prop:NullString         Equate(7436h)    ! used in EXPORT command
prop:DateTimeSeparator  Equate(7437h)    ! used in EXPORT command
prop:LogClarion         Equate(7438h)
PROP:LogBind            Equate(7439h)    ! Log BINDing of SQL values
PROP:LogExplain         Equate(743Ah)    ! Log EXPLAIN of all SET/NEXT loops
PROP:LogOptions         Equate(743Bh)
prop:LogConnections     Equate(743Ch)

Prop:ClientVersionMajor Equate(7440h)
Prop:ClientVersionMinor Equate(7441h)
Prop:ClientVersionBuild Equate(7442h)
Prop:ClientVer          Equate(7443h)
Prop:Locked             Equate(7444h)
Prop:Search             Equate(7445h)
prop:SearchRank         Equate(7446h)
prop:TryConnectedAs     Equate(7447h)
prop:DriverVersion      Equate(7448h)
Prop:DbHandle           Equate(PROP:HDBC)

!EndRegion: Properties
!Region ----------  Errors ----------
!------------------------------------------------------------------------------------------------
! New Errors
ConstraintErr           Equate(19)    !  Returned by traditional SQLite driver
BadOwnerErr             Equate(82)    !  "Invalid Owner"              ! Not declared in errors.clw, but used For FileErrorCode in SQLITE driver
BadFilterErr            Equate(120)   !  "Invalid Filter"
BadProjectErr           Equate(121)   !  "Invalid Project List"
OldDatabaseErr          Equate(122)   !  "Database Too Old"           ! Used when database version < required version
UnsafeSQLErr            Equate(123)   !  "Unsafe SQL"                 ! Trap old use of unsanitized prop:sql calls
SQLErr                  Equate(124)   !  "Invalid SQL"                ! A Prop:Sql contained invalid SQL
InvalidSavePointErr     Equate(125)   !  "Invalid Savepoint"          ! Rollback to a savepoint failed
BadFieldErr             Equate(126)   !  "Field does not belong to file"  ! used in SUBSET and RECORDS and CREATERELATIONS
BadJoinFileError        Equate(127)   !  "Node in join list has no FILE or TABLENAME"
InvalidFieldError       Equate(128)   !  "One or more fields are not valid"
RestrictedDelete        Equate(129)   !  "Delete Failed because Child Records Exist"
ForeignKeyFailed        Equate(130)   !  "An Insert or Update failed because of a Foreign Key constraint"
NotNullFailed           Equate(131)   !  "An Insert or Update failed because A not-null field is null
DataTruncatedError      Equate(132)   !  "Data retrieved from the database could not fit in the Clarion field"
FieldMismatchError      Equate(133)   !  "The returned SQL data type cannot be morphed into the Clarion field"
MissingFilterErr        Equate(134)   !  "Missing Filter"
BadExpressionErr        Equate(135)   !  "Bad Expression"
MissingPrimaryKeyErr    Equate(136)   !  "Table Does Not Have A Primary Key"
ObjectExistsErr         Equate(137)   !  "There is already an object named '...' in the database."
OrphanExistsErr         Equate(138)   !  A new relationship cannot be made because orphans already exist in the table.
!EndRegion: Errors
!------------------------------------------------------------------------------------------------
