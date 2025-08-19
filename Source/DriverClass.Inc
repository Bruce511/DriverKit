!------------------------------------------------------------------------------------------------
!   CapeSoft Clarion File Driver Kit classes are copyright © 2025 by CapeSoft                   !
!   Docs online at : https://capesoft.com/docs/Driverkit/ClarionObjectBasedDrivers.htm
!   Released under MIT License
!------------------------------------------------------------------------------------------------

!!!todo PROP:TraceFile          EQUATE (7356H)  ! Set/Get the name of the INI file used to get driver wide file tracing settings
!!!todo PROP:TraceKey           EQUATE (7357H)  ! Set/Get the name of the Registry key used to get driver wide file tracing settings
!!!todo PROP:DriverTracing      EQUATE (7358H)  ! Set/Get the state of system wide driver tracing '' = off, '1' = on


!------------------------------------------------------------------------------------------------
!Region ----------  Includes ----------
  include('Equates.Clw'),once  
  include('CwDriver.Inc'),once  
  include('CwDriver.Int'),once  
  include('Driver.Inc'),once  
  include('StringTheory.Inc'),once  
  include('CWSYNCH.INT'),once  
!EndRegion: Includes

!Region ----------  Equates ----------
COMPILERINT                  Equate(LONG)

FILE:MAXFILENAME2            Equate(1024)        ! max length of disk file names including full path
DRIVER:MAXRAM                Equate(1073741824)  ! 1 gig
DRIVER:MINRAM                Equate(65536)       ! 64 k
DRIVER:MAX_PRIMARY_KEY_SIZE  Equate(512)
DRIVER:MAXFILEFIELDS         Equate(2048) 
DRIVER:MAXBLOBFIELDS         Equate(1024) 
DRIVER:MAXFIELDNAMELEN       Equate(256) 
DRIVER:MAXPROJECTEDFIELDS    Equate(DRIVER:MAXFILEFIELDS + DRIVER:MAXBLOBFIELDS)  ! must always be >=  DRIVER:MAXFILEFIELDS + DRIVER:MAXBLOBFIELDS
DRIVER:MAXKEYCOMPONENTS      Equate(256)    
DRIVER:MAXDIMS               Equate(10)     
DRIVER:MAXCALLBACKS          Equate(20)         
DRIVER:MAXCONNECTCLAUSES     Equate(20)       
DRIVER:MAXORDERBYFIELDS      Equate(255)    
DRIVER:MAXJOINLINKINGFIELDS  Equate(255) 
DRIVER:MAXFILESINVIEW        Equate(100)
DRIVER:MAXOWNER              Equate(256)
DRIVER:MAXALIASLENGTH        Equate(32)
DRIVER:MAXPARAMETERS         Equate(4096)
!EndRegion: Equates

!Region ----------  Types ----------
! The Keys Queue cannot be optimised into a global list because the KeyPtr value varies from thread to thread.
KeysQueueType     Queue,Type
keyptr              long         ! &key
type                long 
name                astring      ! external key name
attributes          cstring(256) ! extended name attributes
label               aString      ! cstring(128)   ! // label name for key
dbName              aString      ! the external name, as it is in the database, prefix is included with _
index               byte
dup                 byte
opt                 byte
nocase              byte
primary             byte
cluster             byte
components          byte            ! // number of components for key
component           long,dim(DRIVER:MAXKEYCOMPONENTS)   ! field number of key component. 
descending          byte,dim(DRIVER:MAXKEYCOMPONENTS)   ! true if component is descending.
                  End            

! The Blobs Queue cannot be optimised into a global list because memostring and handle parameters are threaded.
BlobsQueueType    Queue,Type
index               Long         ! blob number. This value is > 0
name                cString(256) ! Whole External name, including | attributes
label               aString 
Column              aString      ! the external name, as it is in the database, no prefix or attributes
UpperColumn         aString      ! upper form of the column name - no reserved-wrapping
memostring          &string      ! if a Memo, then it goes in here. 
memosize            BIGINT       ! size of memo string.
handle              Long         ! if a Blob then the memory is here. Returned by GlobalAlloc (which is important for prop:handle)
handlesize          Long         ! size of the Blob memory
Memo                byte         ! true if a memo
Binary              byte         ! true if binary
! -- extended name attibutes
CheckForNull        Byte
HasDefault          Byte
NotNull             Byte
NoWhere             Byte
ReadOnly            Byte
Watch               Byte
Crc32               Long
Collate             aString
DefaultValue        aString
SelectName          aString
UpdateName          aString
InsertName          aString
SQLType             aString
                  End    
                  
RelationsQueueType  Queue,type
ParentFile            &File
OnUpdate              Byte
OnDelete              Byte
ChildIndex            Long,dim(10)
ParentIndex           Long,dim(10)
                    End                  

!------------------------------------------------------------------------------
! These are "read only" data structures, which is shared across all the threads.
! can't use Queues in here because they are not thread safe.
! can't do &Group so using &Class instead.
FilePropertiesType  Class(),type , MODULE('DriverClass.Clw'),LINK('DriverClass.Clw',DRVLM), DLL(DRVDM)     ! is used by the SharedProperties property.
Label                 aString                             ! FILE's label. 
Prefix                aString                             ! FILE's prefix. 
FieldList             &ListType                           ! a dynamic array of nodes. Each node is a field descriptor. 
HasCustomFields       Byte
HasOwner              Byte                                !fileAttr 
Encrypt               Byte                                !fileAttr                
Reclaim               Byte                                !fileAttr                
Create                Byte                                !fileAttr                
Threaded              Byte                                !fileAttr                
Oem                   Byte                                !fileAttr                
Cdrom                 Byte                                !fileAttr 
_haswatch             Byte
_PrimaryKeyIndex      Byte
ValidatedOwner        Cstring(DRIVER:MAXOWNER)
ValidatedFileName     Cstring(FILE:MAXFILENAME2)
HasIdentity           Long                                ! false, or field number
HasUUID               Long                                ! false, or field number
HasUUIDs              Long                                ! the number of uuid fields in the table
_PKComponents         Long
_PKcomponentOffset    Long,dim(DRIVER:MAXKEYCOMPONENTS)   ! for each primary key component, stores the start offset in the record buffer
_PKcomponentLength    Long,dim(DRIVER:MAXKEYCOMPONENTS)   ! for each primary key component, stores the length in the record buffer
                    End

ListType            Class(),Type  , MODULE('DriverClass.Clw') ,LINK('DriverClass.Clw',DRVLM), DLL(DRVDM)           ! think of this as a GROUP,dim(x)
nodes                 Long
nodelist              &String             ! each node is &GroupType ! so this is the "queue". 
                    End

FieldGroupType      Class(),Type , MODULE('DriverClass.Clw') ,LINK('DriverClass.Clw',DRVLM), DLL(DRVDM)     
! these come from tdesc
Index                 Long
Type                  Byte
Attribute             Byte
Name                  Cstring(1024) ! Whole External name, including | attributes. Can be modified at runtime, but applies to all FILE's on all threads.
Label                 aString
Picture               aString
DecimalPlaces         Byte                         
DecimalSize           Byte
Size                  Long          ! Field size in bytes, in the record structure. Basic field type, not allowing for array.
GroupFields           Long
GroupDef              Long          ! the length of the group definition, including all fields in the group
Dims                  Byte
Dim                   Byte,dim(DRIVER:MAXDIMS)  ! the dictionary limits dimensions to 4, but the structure can cope with more.
Over                  Long
! these are added for convenience
Level                 Long          ! the level of the field. Going into a group increments the Level
Length                Long          ! total length of memory for the field, taking arrays, and size, into account.
DimProduct            Long          ! all the dimensions multiplied together
Ref                   Byte          ! field is a reference to an object (CLA_Reference) !!! not implemented yet
Offset                Long          ! offset of the field in the file record
Column                aString       ! the external name, as it is in the database, no prefix or attributes
UpperColumn           aString       ! upper form of the column name - no reserved-wrapping
InOverGroup           Long          ! The index of the Group, which is OVER something, that this field is in
Interface             &iDriverField ! custom field type  
SourceSize            Long          ! cached from iDriverField
Primary               Byte          ! Is in the primary key
InCase                Byte          ! if 255 then not in any key. If true then in a Case Sensitive key. If False then in a non-sensitive key
SqlTimeStamp          Byte          ! Field is a String(8), with an OverGroup, containing Date and Time fields.

! -- extended name attibutes
Binary                Byte
Boolean               Byte          ! Validation
GreaterThan           &string       ! Possibly > or >=
LessThan              &string       ! Possibly < or <=
NotEqual              &string
InList                &String       ! Validation
Validate              &String       ! Validation
CheckForNull          Byte
IsIdentity            Byte
NotNull               Byte
NoWhere               Byte
ReadOnly              Byte
UUID                  Byte
Watch                 Byte
HasDefault            Byte
SelectName            aString
UpdateName            aString
InsertName            aString
DefaultValue          aString
SQLType               aString
Collate               aString
                    End  
     
BlobPointersQueueType  Queue,type
index                    long
memory                   &string
                       End

! 
! Some data is stored outside the class. However it applies when Saving and Restoring State.
!      - errorcode, error, fileErrorCode, FileError
! Some data is stored in the FCB as pointers
!      - recbuf
! Some data is just in the FCB
!      - status
! Some data is stored in the class as pointers
!      - blob data
! Most data is stored in the class 

StateQueueType         Queue,Type
Id                       Long          ! The ID number of this state
RecordPointer            BIGINT        ! the position of the current record buffer in the file. Not used in SQL.
RecordLength             BIGINT        ! The Length of the last read when doing GET(pointer,length)
SetPointer               BIGINT        ! The position of the last SET command. 
Status                   Long          ! File Open/Closed and access mode
Errorcode                Long
Error                    String(255)
FileErrorCode            Long
FileError                String(255)
FullPathName             cString(FILE:MAXFILENAME2)
Owner                    cString(DRIVER:MAXOWNER)
Record                   &String
BlobPointers             &BlobPointersQueueType    ! BASE
PropertyQueue            &PropertyQueueType        ! BASE                             ! Custom properties
OrderQueue               &OrderQueueType           ! BASE
BindQueue                &BindQueueType            ! BASE

ShadowBuffer             &String                   ! FILE
WatchBuffer              &String                   ! FILE
Project                  &Cstring                  ! FILE
_ProjectClauses          &StringTheory             ! FILE

Level1                   &String
Level2                   &String
Level3                   &String
Level4                   &String
Level5                   &String
Level6                   &String

_Buffer                  &String                  ! DOS2
ProjectList              &StringTheory            ! SQL
SqlCode                  &StringTheory            ! SQL
Filter                   &Cstring                 ! SQL
SQLFilter                &Cstring                 ! SQL
Where                    &Cstring                 ! SQL
WherePage                &Cstring                 ! SQL
Order                    &Cstring                 ! SQL
SQLOrder                 &Cstring                 ! SQL
OrderBy                  &Cstring                 ! SQL
GroupBy                  &Cstring                 ! SQL
Having                   &Cstring                 ! SQL
Search                   &Cstring                 ! SQL

Result                   &iResultSet              ! SQL

                       End

Driver:ParametersPerPage Equate(100)

ParameterQueueType       Queue,Type 
ParameterArrayPageIndex    Long
ParameterArrayIndex        Long
ParameterArray             Group,Dim(Driver:ParametersPerPage)
OpCode                       Long
Count                        Long
Value                        &String
FieldNode                    &FieldGroupType
BlobIndex                    Long   
Offset                       Long
Source                       Byte
                           End
                         End

BindQueueType       Queue,Type 
Name                  Cstring(52)
lg                    &Long
rl                    &Real
st                    &String
cst                   &Cstring
                    End
              
ConditionQueueType  queue,type  
Condition             cstring(5)
                    end  

OperatorQueueType   queue,type  
Operator              cstring(5)
                    end  

ExpressionQueueType queue,type
Expression           cstring(4096) 
brackets             byte
                    End

ValueQueueType      queue,type
Value                 cstring(4096)
Parm                  Byte
                    End

LabelQueueType      queue,type
Label                 cstring(128)
As                    byte
                    End

FunctionQueueType   queue,type
Func                  cstring(128)
Parms                 cstring(4096)
                    End

PropertyQueueType  queue,type                 ! Custom Properties
Property             cstring(255)
Index                long
Value                cstring(255)
                   End    
                   
OrderQueueType     Queue,type
Clause               Cstring(100)
Fixed                Byte
Nocase               Byte
IsCalc               Byte
Direction            Byte ! Driver:Ascending, Driver:Descending
FileIndex            Long
FieldIndex           Long
                   End  
                   
SubsetQueueType    Queue,type
Operation            Byte
File                 &File
From                 cString(255)
Filter               &String
Name                 cString(255),dim(10)
                   End
                   
!EndRegion: Types                   
!==================================================================================================
! Base class for File Drivers  
! Code here is shared between the DriverClass and the DriverViewClass
DriverBaseClass          Class(), Type, Module('DriverClass.Clw'),Link('DriverClass.Clw',DRVLM), DLL(DRVDM)

! This block are properties not saved and restored by GETSTATE and RESTORESTATE
! -----------------------------------------------------------------------------
rid                        Long
_Result                    &DriverResultSetClass    ! This is the class (not the interface). This isn't changed by saving state
QuoteString                Cstring(4)               ! sets or returns the column name delimiter (typically a quote) that the Driver uses to surround column names within its generated SQL statements.  
AllowParameterRepeats      Byte                     ! Some databases allow parameter numbers to be repeated, some do not.
_PropsCache                Byte                     ! an incrementing number which increments when one of the SQL properties is changed. (Project, Distinct, NotDistinct, Filter, GroupBy, Having, Order, OrderBy, SQLFilter, SQLOrder, Where, WherePage, Explain, FetchSize, ExceptFilter, ExceptTable)
_structure                 String(1)                ! either F for FILE structures or V for View Structures
NoKeyProject               Byte                     ! inform the SQL view engine not to automatically project key components.  

    ! unicode
CodePage                   Long

    ! log properties
_LogFile                   Cstring(255)
_logHandle                 Long
_logClarion                Byte
_logSQL                    Byte
_logBind                   Byte
_logData                   Byte
_logExplain                Byte
_logOptions                Byte
_logConnections            Byte

! pre-declared temp holders
TempStr                    &StringTheory ! worker stringtheory object. Only use in places where there are no calls to self.method.
TokenStr                   &StringTheory ! worker stringtheory object. Typically passed to ParseProperty.
_ParseContext              Long          ! caches the context passed into ParseProperty, so it doesn't have to be passed through.

! -----------------------------------------------------------------------------
! these queues are used in parsing Clarion expressions into SQL code.
ConditionQueue             &ConditionQueueType
ValueQueue                 &ValueQueueType
LabelQueue                 &LabelQueueType
FunctionQueue              &FunctionQueueType
ExpressionQueue            &ExpressionQueueType   
ParameterQueue             &ParameterQueueType      
SubsetQueue                &SubsetQueueType

_NoAlias                   Byte
_Destructing               Byte

! -----------------------------------------------------------------------------
! This block contain pointers which need to be cloned when doing a GETSTATE and RESTORESTATE
! Pointers cloned when State is saved, and restored  
! if a pointer is added here then the StateQueueType needs to be updated, and code in SaveState / RestoreState /FreeState added

PropertyQueue              &PropertyQueueType                                     ! Custom properties
OrderQueue                 &OrderQueueType   ! a deep dive into the prop:orderBy  ! although the properties are in the base class, the BuildOrderBy methods are set at the DriverClass and DriverViewClass level.
BindQueue                  &BindQueueType

! SQL drivers                                          ! since these are only used at the SQL level, the save and restore is done in the SqlFileClass.
Result                     &iResultSet    
SqlCode                    &StringTheory    
ProjectList                &StringTheory                                    
Filter                     &Cstring                    ! prop:filter is the Clarion statement
SQLFilter                  &Cstring                    ! prop:SqlFilter is a SQL add-on to the clarion statement
Where                      &Cstring                    ! prop:where is the calculated SQL WHERE clause.
WherePage                  &Cstring                    ! prop:wherepage is the WHERE clause, plus the paging position

Order                      &Cstring                    ! prop:order is the Clarion statement
SQLOrder                   &Cstring                    ! prop:SqlOrder is a SQL add-on to the clarion statement
OrderBy                    &CString                    ! prop:OrderBy is the calculated SQL ORDER BY clause. An amalgamtion of the above 2, and additional fields to make it unique.

GroupBy                    &Cstring
Having                     &Cstring
Search                     &Cstring

! End SQL Drivers

! -----------------------------------------------------------------------------
! This block contain properties which need to be copied when doing a GETSTATE and RESTORESTATE  
! no pointers allowed in here.
__BASESTATESTART           byte                        ! do NOT move me
ResultRow                  BIGINT
_ResultRow                 BIGINT
_ResultSetDirection        Byte
_opened                    Byte
opt:unsafe                 Byte    ! /UNSAFE=true, /UNSAFE=stop
opt:explain                Byte    ! if set to true then all SET/NEXT loops on File, and View (if this is primary file) are Explained by default.
opt:dummy                  Byte    ! /DUMMY, if set then result sets are mapped by order, and not by name.
opt:BusyTimeout            Long 
DBVersionMajor             Short   
DBVersionMinor             Short
DBVersionBuild             Short
ClientVersionMajor         Short   
ClientVersionMinor         Short
ClientVersionBuild         Short

  ! properties used by FILEs and VIEWs
FullPathName               Cstring(FILE:MAXFILENAME2) !  FILE's name  ! here so can be used in debugging. Not usually set in VIEW.
FetchSize                  Long
IPRequestCount             Long  
_justset                   Byte
_justreset                 Byte   
_setdirection              Byte
_PropFilterCalled          Byte
_PropOrderCalled           Byte
_PropSQLCalled             Byte

  ! properties that apply to SET
Distinct                   Byte                        !
NotDistinct                Long                        ! the opposite of distinct, set to a minimum number of duplicates
Paging                     Byte
_Paging                    Byte                        ! a copy when SET is called, so that changing it to false Inside the loop has no effect.
NoPrevious                 Byte
ReadOnly                   Byte   
Explain                    Byte
_Explain                   Byte
Limit                      BIGINT
_Limit                     BIGINT
Offset                     BIGINT
_ParameterCount            Long
_ParameterOpcode           Byte                        ! set by a command, allows the methods to know which command they are in
_HasBeenSet                Byte
_HasBeenSetFromFile        Byte
_HasBeenPropSql            Byte
                               
! properties set after doing a SQL command                               
Affected                   Long                        ! set after a insert, update or delete. prop:Affected
ChildrenAffected           Long                        ! set after a relational insert, update or delete. prop:ChildrenAffected
                               
  !  properties that apply to Export
Separator                  cstring(11)
LineEndings                cstring(11)
AlwaysQuote                byte
NullString                 cstring(11)
                                                                     
PrimaryKeyPosition         String(DRIVER:MAX_PRIMARY_KEY_SIZE)        ! the position of the current record buffer in the file
_OrderHasCalc              Byte  

SubsetInFields             Cstring(255)
SubSetFields               Cstring(255) 
SearchFilter               Cstring(255) 
_SearchOrderClause         Cstring(40)
SearchRank                 Real
_SearchParameter           Long
_JustSetSearch             Byte
SubsetPrimaryFile          &File
HasSubset                  Byte

__BASESTATEEND                 byte                        ! do NOT move me
! -------------------------------------------------------------------------------------
                                                      
Construct                  Procedure
Destruct                   Procedure,Virtual                               
SetError                   Procedure(LONG pError),Virtual
SetFileError               Procedure(String pError, String pMessage),VIRTUAL
InterpretOPCode            Procedure(LONG pOpCode),String,Virtual    
InterpretProperty          Procedure(LONG pProperty),String,Virtual   
InterpretType              Procedure(Byte pType),String,Virtual   
Trace                      Procedure(STRING pStr),Virtual   
BugAlert                   Procedure(String pStr),Virtual
LoadLogging                Procedure(),Virtual   
GetAnyType                 Procedure(*? pField),Long,Virtual
GetAnySize                 Procedure(*? pField),Long,Virtual
GetAnyAddress              Procedure(*? pField),Long,Virtual
FormatDate                 Procedure(Date pDate),String,Virtual
FormatTime                 Procedure(Time pTime),String,Virtual
FormatTimeStamp            Procedure(String pStr),String,Virtual
_FreeSubset                Procedure(),VIRTUAL
_ViewTokens                Procedure(),VIRTUAL
_Sanitize                  Procedure(String pStr,Long pContext),String,Virtual
_memchk                    Procedure(long pSrc, byte pchar, Long pCount),Long,Virtual
_WinError                  Procedure(),Virtual
_CheckOpen                 Procedure(),Long,Virtual
_CheckClosed               Procedure(),Long,Virtual
_GetParmAsLong             Procedure(ULONG pAddr,LONG pParmNumber),Long,Virtual
_GetParmAsUShort           Procedure(ULONG pAddr,LONG pParmNumber),Ushort,Virtual
_GetParmAsByte             Procedure(ULONG pAddr,LONG pParmNumber),Byte,Virtual
_PopString                 Procedure(),String,Virtual
_PushString                Procedure(String pStr),Virtual
_GetString                 Procedure(*Cla_StrDesc pStr),String,Virtual
_LongToHex                 Procedure(LONG pX),String,Virtual
_HexToLong                 Procedure(String pHex),Long,Virtual
_BinToLong                 Procedure(String pHex),Long,Virtual
_DecToString               Procedure(Long pMem, Long pLength, Long pDecSize, Long pDecPlaces, Byte pType),String,Virtual
_StringToDec               Procedure(String pStr, Long pDecSize, Long pDecPlaces, Byte pType),String,Virtual
_parseVersionDb            Procedure(String pVersion),Virtual
_parseVersionClient        Procedure(String pVersion),Virtual
_parseOrderByField         Procedure(String pClause,*Byte pDescending,*Byte pNoCase),String,Virtual
_reparm                    Procedure(StringTheory pOrc, *Long pCount),String,Virtual
_GetColumnNameFromOrder    Procedure(String pClause),String,Virtual  !!! todo - obsolete this in favor of the above?
_GenParm                   Procedure(Long pCount),String,Virtual
CheckVersion               Procedure(Long pMajorRqd, Long pMinorRqd, Long pBuildRqd),Long,Virtual
ExplainStart               Procedure(),String,Virtual
ExplainEnd                 Procedure(),String,Virtual
_Morph                     Procedure(String pFieldLabel,Byte pClarionType, Long pClarionAddress, Long pClarionLength, Long pCellType, Long pCellAddress, Long pCellLength, Long pSqlTimeStamp),Virtual

SeedRandom                 Procedure(),Virtual
GetElapsedTimeUTC          Procedure(),Real,Virtual
GenerateUUIDv4             Procedure(),String,Virtual
GenerateUUIDv7             Procedure(),String,Virtual
GenerateUUIDv8             Procedure(),String,Virtual

! methods to parse out properties, SQL properties, and convert to SQL
BuildGroupBy               Procedure(),Virtual
BuildHaving                Procedure(),Virtual
BuildWhere                 Procedure(),Virtual   
BuildOrderBy               Procedure(),Virtual
BuildOrderByProps          Procedure(),Virtual
AddTokensToOrderBy         Procedure(StringTheory pTokenString),Virtual
_FillOrderFromLabel        Procedure(String pLabel, Byte pCase),Long,Virtual

! Parse input string to token and queues
ParseProperty              Procedure(String pProperty, Long pContext,StringTheory rTokenString),Long,Proc,Virtual
ParseProperty              Procedure(*Cstring pProperty, Long pContext,StringTheory rTokenString),Long,Proc,Virtual
_Tokenize                  Procedure(String pStr, Long pContext),String,Virtual
_Functionize               Procedure(StringTheory pStr,String pToken, String pFunction),String,Virtual
_FindMatching              Procedure(*String pStr, Long pStart),Long,Virtual
OperatorsToFunction        Procedure(StringTheory pStr),Long,Proc,Virtual

! Expand token and 
_ExpandExpression          Procedure(String pTokenString,<String pPrefix>,<String pSuffix>),String,Virtual
_ExpandToken               Procedure(String pTokenString,*Long pTokenPos),String,Virtual
_Optimize                  Procedure(String pFunction,String pExpression),String,Virtual

TranslateCondition         Procedure(*cstring pCondition),String,Proc,Virtual
TranslateFunction          Procedure(*cString pFunc, *cString pParms,string pTokenString,*Long pTokenPos),String,Proc,Virtual
TranslateBeginsWith        Procedure(*Cstring pFunc, *CString pParms,string pTokenString,*Long pTokenPos,*Cstring[] pExParm,Long pNumParms),String,Virtual
TranslateChr               Procedure(*Cstring pFunc, *CString pParms,string pTokenString,*Long pTokenPos,*Cstring[] pExParm,Long pNumParms),String,Virtual
TranslateClip              Procedure(*Cstring pFunc, *CString pParms,string pTokenString,*Long pTokenPos,*Cstring[] pExParm,Long pNumParms),String,Virtual
TranslateDate              Procedure(*Cstring pFunc, *CString pParms,string pTokenString,*Long pTokenPos,*Cstring[] pExParm,Long pNumParms),String,Virtual
_TranslateDateSql          Procedure(String pMonth, String pDay, String pYear, Byte pLabelType, *Cstring pCond),String,Virtual
TranslateDay               Procedure(*Cstring pFunc, *CString pParms,string pTokenString,*Long pTokenPos,*Cstring[] pExParm,Long pNumParms),String,Virtual
_TranslateDaySQL           Procedure(*CString pField),String,Virtual
TranslateEndsWith          Procedure(*Cstring pFunc, *CString pParms,string pTokenString,*Long pTokenPos,*Cstring[] pExParm,Long pNumParms),String,Virtual
TranslateInList            Procedure(*Cstring pFunc, *CString pParms,string pTokenString,*Long pTokenPos,*Cstring[] pExParm,Long pNumParms),String,Virtual
TranslateInRange           Procedure(*Cstring pFunc, *CString pParms,string pTokenString,*Long pTokenPos,*Cstring[] pExParm,Long pNumParms),String,Virtual
TranslateInString          Procedure(*Cstring pFunc, *CString pParms,string pTokenString,*Long pTokenPos,*Cstring[] pExParm,Long pNumParms),String,Virtual
TranslateInStr             Procedure(*Cstring pFunc, *CString pParms,string pTokenString,*Long pTokenPos,*Cstring[] pExParm,Long pNumParms),String,Virtual
TranslateInt               Procedure(*Cstring pFunc, *CString pParms,string pTokenString,*Long pTokenPos,*Cstring[] pExParm,Long pNumParms),String,Virtual
TranslateMatch             Procedure(*Cstring pFunc, *CString pParms,string pTokenString,*Long pTokenPos,*Cstring[] pExParm,Long pNumParms),String,Virtual
TranslateMonth             Procedure(*Cstring pFunc, *CString pParms,string pTokenString,*Long pTokenPos,*Cstring[] pExParm,Long pNumParms),String,Virtual
_TranslateMonthSQL         Procedure(*CString pField),String,Virtual
TranslateNull              Procedure(*Cstring pFunc, *CString pParms,string pTokenString,*Long pTokenPos,*Cstring[] pExParm,Long pNumParms),String,Virtual
TranslateSearchX           Procedure(*Cstring pFunc, *CString pParms,string pTokenString,*Long pTokenPos,*Cstring[] pExParm,Long pNumParms),String,Virtual
TranslateSqrt              Procedure(*Cstring pFunc, *CString pParms,string pTokenString,*Long pTokenPos,*Cstring[] pExParm,Long pNumParms),String,Virtual
TranslateSub               Procedure(*Cstring pFunc, *CString pParms,string pTokenString,*Long pTokenPos,*Cstring[] pExParm,Long pNumParms),String,Virtual
TranslateYear              Procedure(*Cstring pFunc, *CString pParms,string pTokenString,*Long pTokenPos,*Cstring[] pExParm,Long pNumParms),String,Virtual
_TranslateYearSQL          Procedure(*CString pField),String,Virtual
_GetFreeParameter          Procedure(),Long,Virtual
_SetParameterString        Procedure(Long pCount, String pValue), Virtual
_SetParameterNode          Procedure(Long pCount, *FieldGroupType pNode, Byte pSource, Long pOffset), Virtual
_SetParameterBlob          Procedure(Long pCount, Long pIndex), Virtual
_DuplicateParameter        Procedure(Long pCount, Long pFrom),Virtual
_ResetParameterValue       Procedure(Long pIndex, String pValue, Long pLength),Virtual
_ClearParameterQueue       Procedure(Long pOpcode),Virtual
_FreeParameterQueue        Procedure(),Virtual

TranslateLabel             Procedure(*cstring pValue,*byte pReturnType),String,Proc,Virtual
TranslateConstant          Procedure(*cstring pValue,*long pConstant),Long,Virtual

TranslateNoCase            Procedure(*CString pExpr,*CString pColumn),String,Virtual
TranslateOperatorPower     Procedure(),String,Virtual
TranslateOperatorMod       Procedure(),String,Virtual
TranslateOperatorConcat    Procedure(),String,Virtual
TranslateOrder             Procedure(StringTheory pStr),Virtual
TranslateRegularExpression Procedure(*CString pExpr,*CString pColumn),String,Virtual
TranslateVariable          Procedure(*cstring pValue),String,Proc,Virtual

! Property methods common to FILEs and VIEWs
NewResultSet               Procedure(Long pOptions),VIRTUAL
ResultGet                  Procedure(BIGINT pRow),VIRTUAL 
ResultNext                 Procedure(),VIRTUAL 
ResultPrevious             Procedure(),VIRTUAL 
ResultRow                  Procedure(),BIGINT,VIRTUAL 
ResultRecords              Procedure(),BIGINT,VIRTUAL 
ResultToExplain            Procedure(iResultSet pResult),VIRTUAL
ResultToBindField          Procedure(Long pRow, Long pCol),VIRTUAL

GETPROPERTY                Procedure(String pProperty,Long pIndex=0),String,VIRTUAL          ! x = file{prop:something}
GetCustomProperty          Procedure(String pProperty,Long pIndex=0),String,VIRTUAL          
SETPROPERTY                Procedure(String pProperty,Long pIndex,STRING pValue),VIRTUAL     ! file{prop:something} = x
SetCustomProperty          Procedure(String pProperty,Long pIndex,STRING pValue),VIRTUAL
DOPROPERTY                 Procedure(String pProperty,Long pIndex=0),VIRTUAL                 ! file{prop:something}
CLEARPROPS                 Procedure(),VIRTUAL  
CLOSE                      Procedure(),VIRTUAL 
FLUSH                      Procedure(),VIRTUAL 
OPEN                       Procedure(),VIRTUAL  
LOG                        Procedure(String pLog),VIRTUAL     ! Writes to the log file
LOGGINGON                  Procedure(<String pFileName>,Long pOptions=0),VIRTUAL
LOGGINGOFF                 Procedure(),VIRTUAL
SEND                       Procedure(STRING pMessage),STRING,PROC,VIRTUAL  
SetDriverOption            Procedure(String pOption, String pValue),STRING,VIRTUAL
SQL                        Procedure(String pSql,<? pParm1>,<? pParm2>,<? pParm3>,<? pParm4>,<? pParm5>,<? pParm6>,<? pParm7>,<? pParm8>,<? pParm9>,<? pParm10>,<? pParm11>,<? pParm12>,<? pParm13>,<? pParm14>,<? pParm15>,<? pParm16>,<? pParm17>,<? pParm18>,<? pParm19>,<? pParm20>),VIRTUAL   
STATUS                     Procedure(),LONG,VIRTUAL
SUBSET                     Procedure(FILE pFile,*? pParm1,<*? pParm2>,<*? pParm3>,<*? pParm4>,<? pParm5>,<? pParm6>,<? pParm7>,<? pParm8>,<? pParm9>,<? pParm10>),VIRTUAL
_AddSubsetCommand          Procedure(Byte pOperation, File pFile,<String pFilter>),VIRTUAL
BuildSubsetCTE             Procedure(StringTheory pCTE),VIRTUAL 
BuildSubsetWhere           Procedure(StringTheory pWhere, String pAlias),VIRTUAL 
PrimeSubset                Procedure(),VIRTUAL

GetPROP:Affected           Procedure(),STRING,VIRTUAL             ! Get name of the database from the connect string
GetProp:AlwaysQuote        Procedure(),STRING,VIRTUAL 
SetProp:AlwaysQuote        Procedure(Byte pValue),VIRTUAL
GetPROP:ChildrenAffected   Procedure(),STRING,VIRTUAL 
GetPROP:CodePage           Procedure(),STRING,VIRTUAL 
SetPROP:CodePage           Procedure(Long pCodePage),VIRTUAL

GetPROP:Database           Procedure(),STRING,VIRTUAL             ! Get name of the database from the connect string
GetPROP:DatabaseName       Procedure(),STRING,VIRTUAL             ! Get database name - ie SQLITE, PostgreSQL etc.
GetProp:DbVersionMajor     Procedure(),STRING,VIRTUAL  
GetProp:DbVersionMinor     Procedure(),STRING,VIRTUAL 
GetProp:ClientVersionBuild Procedure(),STRING,VIRTUAL 
GetProp:ClientVersionMajor Procedure(),STRING,VIRTUAL  
GetProp:ClientVersionMinor Procedure(),STRING,VIRTUAL 
GetProp:DbVersionBuild     Procedure(),STRING,VIRTUAL 
GetPROP:DBMSVer            Procedure(),STRING,VIRTUAL  ! returns a character string indicating the version of the DBMS accessed by the driver.
GetPROP:ClientVer          Procedure(),STRING,VIRTUAL  ! returns a character string indicating the version of the client DLL or ODBC DLL accessed by the driver
GetPROP:Distinct           Procedure(),STRING,VIRTUAL 
SetPROP:Distinct           Procedure(BYTE pDistinct),VIRTUAL
GetPROP:Driver             Procedure(),STRING,VIRTUAL             ! Get name of file driver
GetPROP:Fields             Procedure(Long pIndex),STRING,VIRTUAL  
GetPROP:FetchSize          Procedure(),STRING,VIRTUAL  ! Get the pagesize parameter for the last BUFFER statement executed
SetPROP:FetchSize          Procedure(Long pValue),VIRTUAL  ! Set the pagesize parameter
GetProp:Explain            Procedure(),String,Virtual
SetProp:Explain            Procedure(Byte pValue),Virtual
GetProp:Filter             Procedure(),String,Virtual
SetProp:Filter             Procedure(String pValue),Virtual
GetProp:GroupBy            Procedure(),String,Virtual
SetProp:GroupBy            Procedure(String pValue),Virtual
GetProp:Having             Procedure(),String,Virtual
SetProp:Having             Procedure(String pValue),Virtual
GetProp:IPrequestCount     Procedure(),String,Virtual
SetProp:IPrequestCount     Procedure(Long pValue),Virtual
GetPROP:Label              Procedure(LONG pIndex),STRING,VIRTUAL  ! Get file label
GetPROP:Limit              Procedure(),STRING,VIRTUAL 
SetPROP:Limit              Procedure(BIGINT pLimit),VIRTUAL
GetProp:LineEndings        Procedure(),STRING,VIRTUAL 
SetProp:LineEndings        Procedure(String pValue),VIRTUAL
GetProp:LogBind            Procedure(),STRING,VIRTUAL 
SetProp:LogBind            Procedure(String pValue),VIRTUAL
GetProp:LogClarion         Procedure(),STRING,VIRTUAL 
SetProp:LogClarion         Procedure(String pValue),VIRTUAL
GetProp:LogConnections     Procedure(),STRING,VIRTUAL 
SetProp:LogConnections     Procedure(String pValue),VIRTUAL
GetProp:LogData            Procedure(),STRING,VIRTUAL 
SetProp:LogData            Procedure(String pValue),VIRTUAL
GetProp:LogExplain         Procedure(),STRING,VIRTUAL 
SetProp:LogExplain         Procedure(String pValue),VIRTUAL
GetProp:LogOptions         Procedure(),STRING,VIRTUAL 
SetProp:LogOptions         Procedure(String pValue),VIRTUAL
GetProp:LogSQL             Procedure(),STRING,VIRTUAL 
SetProp:LogSQL             Procedure(String pValue),VIRTUAL
GetPROP:Paging             Procedure(),STRING,VIRTUAL 
SetPROP:Paging             Procedure(Byte pValue),VIRTUAL
GetPROP:NoPrevious         Procedure(),STRING,VIRTUAL 
SetPROP:NoPrevious         Procedure(Byte pValue),VIRTUAL
GetPROP:NotDistinct        Procedure(),STRING,VIRTUAL 
SetPROP:NotDistinct        Procedure(Long pNotDistinct),VIRTUAL
GetProp:NullString         Procedure(),STRING,VIRTUAL 
SetProp:NullString         Procedure(String pValue),VIRTUAL
GetPROP:OBD                Procedure(),STRING,VIRTUAL 
GetPROP:Offset             Procedure(),STRING,VIRTUAL 
SetPROP:Offset             Procedure(BIGINT pOffset),VIRTUAL
GetProp:Order              Procedure(),String,Virtual
SetProp:Order              Procedure(String pValue),Virtual
GetProp:OrderBy            Procedure(),String,Virtual
SetProp:OrderBy            Procedure(String pValue),Virtual
GetPROP:Profile            Procedure(),STRING,VIRTUAL  ! Set file profiling
SetPROP:Profile            Procedure(String pLogFile),VIRTUAL  ! Set file profiling
GetPROP:QuoteString        Procedure(),STRING,VIRTUAL             ! sets or returns the column name delimiter (typically a quote) that the SQL Accelerator Driver uses to surround column names within its generated SQL statements
SetPROP:QuoteString        Procedure(String pValue),VIRTUAL  
GetPROP:ReadOnly           Procedure(),STRING,VIRTUAL 
SetPROP:ReadOnly           Procedure(Byte pValue),VIRTUAL
GetPROP:ResultRecords      Procedure(),STRING,VIRTUAL
GetPROP:ResultRow          Procedure(),STRING,VIRTUAL
GetProp:Search             Procedure(),STRING,VIRTUAL 
SetProp:Search             Procedure(String pValue),VIRTUAL
GetProp:SearchRank         Procedure(),STRING,VIRTUAL 
GetProp:Separator          Procedure(),STRING,VIRTUAL 
SetProp:Separator          Procedure(String pValue),VIRTUAL
GetPROP:Server             Procedure(),STRING,VIRTUAL             ! the name of the server from the connect string
GetPROP:SQL                Procedure(),STRING,VIRTUAL  !  execute SQL statements in your program. 
SetPROP:SQL                Procedure(String pSQL),VIRTUAL
DoPROP:SQL                 Procedure(),VIRTUAL
_ExecuteSql                Procedure(StringTheory pSQL, <? pParm1>,<? pParm2>,<? pParm3>,<? pParm4>,<? pParm5>,<? pParm6>,<? pParm7>,<? pParm8>,<? pParm9>,<? pParm10>,<? pParm11>,<? pParm12>,<? pParm13>,<? pParm14>,<? pParm15>,<? pParm16>,<? pParm17>,<? pParm18>,<? pParm19>,<? pParm20>),LONG,VIRTUAL
_ExecuteSql                Procedure(),LONG,VIRTUAL
GetPROP:SQLFilter          Procedure(),STRING,VIRTUAL             ! this statement should be replaced by the more versatile SQL() statement.
SetPROP:SQLFilter          Procedure(String pValue),VIRTUAL  
GetProp:SQLOrder           Procedure(),String,Virtual
SetProp:SQLOrder           Procedure(String pValue),Virtual    
GetPROP:User               Procedure(),STRING,VIRTUAL             ! the name of the server from the connect string
GetProp:Where              Procedure(),String,Virtual
SetProp:Where              Procedure(String pValue),Virtual
GetProp:WherePage          Procedure(),String,Virtual
SetProp:WherePage          Procedure(String pValue),Virtual
                       End
  
!==================================================================================================
! Class for FILE support in Driver
DriverFileClass       Class(DriverBaseClass), Type, MODULE('DriverClass.Clw'),LINK('DriverClass.Clw',DRVLM), DLL(DRVDM)

! --------------------------------------------------------------------
! properties which are unaltered by a GETSTATE or RESTORESTATE
File                    &File         ! unchanging, unless INIT is called again
State                   &StateQueueType
ClaFCB                  &Cla_FCBBLK   ! same as File property, but different type                                       
blobs                   &BlobsQueueType   ! Queue of MEMO field descriptors.  There is one entry per MEMO field. 
keys                    &KeysQueueType    ! Queue of KEY and INDEX descriptors.  There is one entry for each KEY and INDEX declaration in the FILE structure.  
relations               &RelationsQueueType
primarykey              &Key
SharedProperties        &FilePropertiesType
Fields                  &FieldGroupType
recbuf                  &string       ! *void ! FILE's RECORD buffer, this points to a buffer allocated by the Clarion run-time.  Data may be copied to it but it may not be reallocated or freed by the File Driver.

_numBlobs               long
_numMemos               long
TypeDescriptorAddress   Long          ! set in driver.clw, not in class
LoginTimeout            Long          ! seconds
reclen                  Ulong  
_indicies               Long,dim(255)   
_inTransaction          Byte
_inStream               Byte
_transactionPrimary     Byte
_relationsOff           Byte
_GetBuffer              Byte          ! used when resetting a view to do the GET into the shadow buffer
_ThisSqlType            AString      
_locked                 Byte

! --------------------------------------------------------------------
! pointers which need to be cloned during a GETSTATE or RESTORESTATE
ShadowBuffer            &String
WatchBuffer             &String
Project                 &Cstring      ! a list of field names to be included in the SQL statement
_ProjectClauses         &StringTheory

! --------------------------------------------------------------------
! variables which need to be copied during a GETSTATE or RESTORESTATE
__FILESTATESTART        Byte
Owner                   cstring(DRIVER:MAXOWNER)  ! The string specified in the OWNER attribute of the FILE.  
_ConnectedAs            cstring(DRIVER:MAXOWNER)  ! The value in Owner when the last connection was made.
_ConnectedPool          long                      ! The value in prop:pool when the last connection was made.
DriverStr               cstring(256)  ! The string specified as the second string in DRIVER attribute.  
Alias                   cstring(DRIVER:MAXALIASLENGTH)   ! The Alias used for the file in Views. Defaults to A,B,C etc. Can be set here.
RecordPointer           BIGINT        ! the position of the current record buffer in the file
RecordLength            BIGINT        ! The Length of the last read when doing GET(pointer,length)
SetPointer              BIGINT        ! The position of the last SET command. 
Pool                    Long

_ProjectField           Byte,dim(DRIVER:MAXFILEFIELDS)
_ProjectBlobField       Byte,dim(DRIVER:MAXBLOBFIELDS)
_SearchJoin             Cstring(256)
_ProjectedPrimary       Byte          ! Will be set to true if the prop:project contains the primary key, false otherwise.
_SupplementalOrderFields Long          ! the point in the queue above where supplemental fields are added. These are added to ensure order uniqueness.

_Bytes                  Long  
_SourceSize             Long

SetMethod               Byte          ! The nature of the last SET command
AddOnly                 Byte          ! Set before doing a ADD() to bypass saving POSITION. Optimization for bulk ADDs.      
LogSql                  byte
NoMemoArmed             byte          ! set by a call to NOMEMO, cleared by a SET, GET or REGET.
_nomemo                 byte          ! set by the READ to the value of NoMemoArmed at the time of the read.
_nomemoset              byte          ! set by SET method depending on value of NoMemoArmed when SET is called.
_locknames              byte          ! used internally to bypass _UpdateFileStrings
_fastwrite              byte          ! if set, no RETURNING from PUT, ADD, APPEND, UPSERT clause

_nextstate              long          ! RestoreFile, SaveFile
_poslen                 long

watching                byte
held                    byte   
_inited                 byte
_bulkread               byte
_recordloaded           byte     
_watchCmdState          byte      ! has the user executed a WATCH command.   watch:on, watch:armed, or watch:off
_watchBufferState       byte      ! is the watch buffer loaded with the last read / last written record?
_doingWatchCheck        byte      ! only set during the actual WATCH check, before PUTTING
_exists                 byte     
_FullPathNameSetFromPropName Byte

_nullstr                &string   ! each byte in the string represents a field in the record, and whether it is null or not. 

SetKey                  &Key
SetKeyKey               &Key
_SetOffset              Long
__FILESTATEEND          Byte

                                     
! methods                                     
! -------                                     
Construct                Procedure()
Destruct                 Procedure(),VIRTUAL 

Init                     Procedure(FILE pFile, Long pForce=false),VIRTUAL
ReplaceObject            Procedure(Long pOldObjectAddress),VIRTUAL
SetError                 Procedure(LONG pError),DERIVED
SetFileError             Procedure(String pError, String pMessage),DERIVED
Pipe                     Procedure(LONG pOpCode, LONG pClaFCB,long pVarList),LONG,VIRTUAL

_GetVariableLengthNumber   Procedure(*Long pAddr,*byte pHighbit),Long,Virtual
_GetVariableLengthString   Procedure(*Long pAddr),String,Virtual

_parseFields             Procedure(Long pAddr),Virtual
_AfterParseFields        Procedure(),Virtual
_parseFieldsB            Procedure(FieldGroupType pNode),Virtual
_parseFieldsWalker       Procedure(*Long pAddr,Long pFields,*Long pIndex,Long pLastRealOffSet,Long pLastRealLength,Long pInOveredGroup,Long pLevel),Virtual

_parseBlobs              Procedure(Byte pIndex),VIRTUAL
_parseKeys               Procedure(Byte pIndex),VIRTUAL
_parseKeyNameAttributes  Procedure(),VIRTUAL
_parseBlobNameAttributes Procedure(),VIRTUAL
_parseFieldNameAttributes Procedure(FieldGroupType pNode),VIRTUAL
_Optimize                Procedure(),VIRTUAL
_writeHandle             Procedure(),VIRTUAL    
_newMemoMemory           Procedure(Long pNewSize),VIRTUAL
_FreeKeys                Procedure(),VIRTUAL
_FreeBlobs               Procedure(),VIRTUAL
_ClearBlobs              Procedure(),VIRTUAL
_FreeFields              Procedure(),VIRTUAL
_SetSourceSize           Procedure(),VIRTUAL
_SourceSize              Procedure(),LONG,VIRTUAL

_WithField               Procedure(Long pIndex),Long,Virtual
_WithFieldPtr            Procedure(*? pField),Long,Virtual
_WithFieldNode           Procedure(Long pIndex),*FieldGroupType,Virtual
_WithFieldLabeled        Procedure(*CString pLabel),Long,Virtual
_WithFieldLabeled        Procedure(String pLabel),Long,Virtual
_WithFieldNamed          Procedure(*CString pName),Long,Virtual
_WithFieldNamed          Procedure(String pName),Long,Virtual
_WithFieldOffset         Procedure(Long pOffset,Long pSize),Long,Virtual

_WithBlob                Procedure(Long pIndex),Long,Virtual
_WithBlobLabel           Procedure(*CString pName),Long,Virtual
_WithBlobNamed           Procedure(*CString pName),Long,Virtual
_WithBlobNamed           Procedure(String pName),Long,Virtual

_WithKey                 Procedure(*KEY pKey),Long,VIRTUAL
_WithKey                 Procedure(Long pIndex),Long,VIRTUAL
_WithPrimaryKey          Procedure(),Long,VIRTUAL
_FieldInPrimaryKey       Procedure(Long pIndex),Long,Virtual
_FieldInCaseKey          Procedure(Long pIndex),Long,Virtual
_FieldInNoCaseKey        Procedure(Long pIndex),Long,Virtual
_FieldAloneInUniqueKey   Procedure(Long pIndex),Long,Virtual
                     
_FieldIsBlank             Procedure(),Long,Virtual
_FillShadowBufferFromPosition  Procedure(KEY pKey, STRING pStr),Virtual
_PopulateUuidFields       Procedure(),VIRTUAL
_GenerateSelect           Procedure(Long pOpcode),Virtual
BuildGroupBy              Procedure(),Derived
BuildProjectList          Procedure(),Virtual
BuildProjectListAppendClauses Procedure(),Virtual

SetPrimaryKeyPosition     Procedure(),VIRTUAL
ClearPrimaryKeyPosition   Procedure(),VIRTUAL
_GetPrimaryKeyPosition    Procedure(*Long rLength),String, Virtual
_SetPrimaryKeyPosition    Procedure(String pPosition,Long pBuffer,*Long rLen), Virtual
_BeforeRead               Procedure(Long pOpCode),VIRTUAL
_BeforeWrite              Procedure(Long pOpCode),VIRTUAL
_AfterWrite               Procedure(Long pOpCode),VIRTUAL
_AfterRead                Procedure(Long pOpCode),VIRTUAL
ValidateStructure         Procedure(),Long,Virtual
BuildOrderBy              Procedure(),Derived
BuildOrderByKey           Procedure(Key pKey),Virtual
BuildPropOrderByKey       Procedure(Key pKey),String,Virtual
BuildOrderByUnique        Procedure(),Virtual     
SetOrderByFromQueue       Procedure(),Virtual
_FillOrderFromLabel       Procedure(String pLabel, Byte pCase),Long,Derived

ParseProject              Procedure(),Virtual
_ProjectField             Procedure(),Virtual
_ProjectBlob              Procedure(),Virtual

! parse parameter methods
_UpdateFileStrings         Procedure(),Virtual    

! Helper methods
_CallFunctionCalled        Procedure(),LONG,VIRTUAL
_CallFunctionDone          Procedure(),LONG,VIRTUAL 
_CallExecutingCode         Procedure(),LONG,VIRTUAL
FreeBuffer                 Procedure(),VIRTUAL  
SetCustomType              Procedure(String pFieldLabel,iDriverField pInterface),Long,Proc,Virtual
TranslateLabel             Procedure(*cstring pValue,*byte pReturnType),String,Proc,Derived
TranslateReserved          Procedure(*cstring pColumn),String,Virtual
WrapReserved               Procedure(*cstring pColumn),String,Virtual
UnwrapReserved             Procedure(*cstring pColumn),String,Virtual
_TranslateLabelOverDateSQL Procedure(FieldGroupType pNode),String,Virtual
_TranslateLabelOverTimeSQL Procedure(FieldGroupType pNode),String,Virtual
TranslateSearch            Procedure(String pSearchString),String,Virtual

_CalcIndex                 Procedure(),Long,Virtual
_GetFieldAsJson            Procedure(Long pIndex),String,Virtual
_GetArrayAsJson            Procedure(StringTheory pStr,Long pIndex),Virtual
_GetArrayAsJsonWalker      Procedure(StringTheory pStr,Long pIndex,LONG pDim),Virtual

_GetFieldAsText            Procedure(Long pIndex),String,Virtual
_GetArrayAsText            Procedure(Long pIndex),String,Virtual
_GetFieldAsText            Procedure(Long pIndex, Long pArrayIndex),String,Virtual

_PutJsonAsField            Procedure(*String pStr,Long pIndex),Virtual
_PutJsonAsFieldWorker      Procedure(StringTheory pStr, Long pIndex, Long pArrayIndex),Virtual 

_LoadArray                 Procedure(*String pStr,Long pIndex),Virtual  ! Pure virtual, filled in by the actual driver
_GetAlias                  Procedure(Byte pWithDot),String,Virtual

DeformatText               Procedure(String pText),String,Virtual
!SetDriverOption            Procedure(String pOption, String pValue),STRING,Derived

! File Procedures
BindField                  Procedure(String pName,*Long pLong),Virtual
BindField                  Procedure(String pName,*Real pReal),Virtual
BindField                  Procedure(String pName,*String pString),Virtual                  
BindField                  Procedure(String pName,*Cstring pCstring),Virtual                          
_FindBindQueue             Procedure(Long pAddress),Long,Virtual

BLOBSIZE                   Procedure(Long pIndex),BIGINT,VIRTUAL
BLOBTAKE                   Procedure(Long pIndex,BIGINT pStartPos, BIGINT pEndPos),VIRTUAL
SetBlobFromAddr            Procedure(Long pIndex,BIGINT pStartPos, BIGINT pAddress, BIGINT pSize),VIRTUAL
SetBlob                    Procedure(Long pIndex,BIGINT pStartPos, String pValue, Long pSetSize),VIRTUAL
SetBlob                    Procedure(Long pIndex,String pValue),VIRTUAL
SetBlob                    Procedure(Long pIndex,Blob pValue),VIRTUAL
CheckBlobCrc               Procedure(),Long,VIRTUAL
SetBlobsCrc                Procedure(),VIRTUAL
SetBlobCrc                 Procedure(),VIRTUAL
BLOBYIELD                  Procedure(Long pIndex,BIGINT pStartPos, BIGINT pEndPos),VIRTUAL
ViewBlob                   Procedure(Long pIndex),Virtual
GetBlob                    Procedure(Long pIndex),String,VIRTUAL
GetBlob                    Procedure(Long pIndex,BIGINT pStartPos),String,VIRTUAL
GetBlob                    Procedure(Long pIndex,BIGINT pStartPos, BIGINT pEndPos),String,VIRTUAL

HASRELATION                PROCEDURE(File pParentFile),Long,VIRTUAL
ADDRELATION                Procedure(File pParentFile, Long pOnUpdate, Long pOnDelete, *? pChildField1, *? pParentField1, <*? pChildField2>, <*? pParentField2>, <*? pChildField3>, <*? pParentField3>, <*? pChildField4>, <*? pParentField4>, <*? pChildField5>, <*? pParentField5>, <*? pChildField6>, <*? pParentField6>, <*? pChildField7>, <*? pParentField7>, <*? pChildField8>, <*? pParentField8>, <*? pChildField9>, <*? pParentField9>, <*? pChildField10>, <*? pParentField10>),VIRTUAL
_AddRelationField          Procedure(Long pIndex,DriverFileClass pParent,*? pChildField, *? pParentField),VIRTUAL
BOF                        Procedure(),LONG,VIRTUAL 
BUFFER                     Procedure(UNSIGNED pPageSize=1, UNSIGNED pBehind=0, UNSIGNED pAhead=0, UNSIGNED pTimeout=0),VIRTUAL 
BUILD                      Procedure(),VIRTUAL 
BUILD                      Procedure(KEY pKey),VIRTUAL
BUILD                      Procedure(KEY pKey, <STRING pComponents>,STRING pFilter),VIRTUAL
BUILD                      Procedure(KEY pKey, STRING pComponents),VIRTUAL
BYTES                      Procedure(),BIGINT,VIRTUAL  
CALL                       Procedure(String pStoredProcedure,<? pParm1>,<? pParm2>,<? pParm3>,<? pParm4>,<? pParm5>,<? pParm6>,<? pParm7>,<? pParm8>,<? pParm9>,<? pParm10>,<? pParm11>,<? pParm12>,<? pParm13>,<? pParm14>,<? pParm15>,<? pParm16>,<? pParm17>,<? pParm18>,<? pParm19>,<? pParm20>),VIRTUAL
CLEARPROPS                 Procedure(),DERIVED  
CLOSE                      Procedure(),DERIVED
CONNECT                    Procedure(Long pOptions=0),VIRTUAL                
COPY                       Procedure(STRING pNewFileName, Long pOptions),VIRTUAL 
CREATEDB                   Procedure(String pDatabaseName),VIRTUAL  
CREATETABLE                Procedure(),VIRTUAL  
_CREATETABLE               Procedure(),VIRTUAL            ! splitting this into a separate method allows it to be called without the parent checks.
_CreateValidation          Procedure(),VIRTUAL
_CreateDefault             Procedure(Long pHasDefault, Long pType, String pDefault),VIRTUAL
_CreateForeignKeys         Procedure(),VIRTUAL  
CLONE                      Procedure(String pNewTableName,Long pOptions),VIRTUAL
CREATEFIELD                Procedure(*? pField1),VIRTUAL 
CREATEFIELD                Procedure(String pName, String pType, String pConstraint),VIRTUAL 
CREATEKEY                  Procedure(KEY pKey),VIRTUAL
CREATEKEY                  Procedure(String pName, Long pOptions, *? pField1, *? pField2, <*? pField3>, <*? pField4>, <*? pField5>, <*? pField6>, <*? pField7>, <*? pField8>, <*? pField9>, <*? pField10>),VIRTUAL
CLEARFILE                  Procedure(Long pWhat),VIRTUAL  
DECLARATION                Procedure(Long pOptions=0),STRING,VIRTUAL
DECLARATION                Procedure(Key pKey,Long pOptions=0),STRING,VIRTUAL
DISCONNECT                 Procedure(),VIRTUAL
DUPLICATE                  Procedure(),VIRTUAL,LONG  
DUPLICATE                  Procedure(KEY pKey),VIRTUAL,LONG
EMPTY                      Procedure(),VIRTUAL  
EOF                        Procedure(),LONG,VIRTUAL 
EXISTS                     Procedure(String pTablename),LONG,PROC,VIRTUAL
EXISTS                     Procedure(Long pWhat,String pName),LONG,PROC,VIRTUAL
EXISTSDB                   Procedure(String pDatabaseName),LONG,PROC,VIRTUAL
EXPORT                     Procedure(String pDosFileName, Long pOptions=0,Long pFormat=0),LONG,PROC,VIRTUAL
IMPORT                     Procedure(String pDosFileName, Long pOptions=0,Long pFormat=0),LONG,PROC,VIRTUAL
EXPORTCSV                  Procedure(String pDosFileName, Long pOptions=0),LONG,PROC,VIRTUAL
IMPORTCSV                  Procedure(String pDosFileName, Long pOptions=0),LONG,PROC,VIRTUAL
FREESTATE                  Procedure(Long pState),VIRTUAL 
GETRANDOM                  Procedure(String pFilter),VIRTUAL
GETSTATE                   Procedure(Long pSaveBlob),LONG,VIRTUAL  
LOCK                       Procedure(),VIRTUAL 
LOCK                       Procedure(LONG pSeconds),VIRTUAL 
LOGBUFFER                  Procedure(),VIRTUAL
NAME                       Procedure(),STRING,VIRTUAL  
OPEN                       Procedure(LONG pAccessMode=022h),VIRTUAL
AfterOPEN                  Procedure(LONG pAccessMode=022h,Byte pOpened),Virtual
REOPEN                     Procedure(LONG pAccessMode),VIRTUAL  
PACK                       Procedure(),VIRTUAL  
POINTER                    Procedure(),BIGINT,VIRTUAL  
POINTER                    Procedure(KEY pKey),BIGINT,VIRTUAL  
POSITION                   Procedure(),STRING,VIRTUAL  
POSITION                   Procedure(KEY pKey),STRING,VIRTUAL  
RECORDS                    Procedure(),BIGINT,VIRTUAL  
RECORDSFILTER              Procedure(String pFilter),BIGINT,VIRTUAL  
RECORDS                    Procedure(*? pField1, <*? pField2>, <*? pField3>, <*? pField4>, <*? pField5>,<*? pField6>, <*? pField7>, <*? pField8>, <*? pField9>, <*? pField10>,<*? pField11>, <*? pField12>, <*? pField13>, <*? pField14>, <*? pField15>),BIGINT,VIRTUAL
RECORDS                    Procedure(KEY pKey),BIGINT,VIRTUAL  
REMOVE                     Procedure(),VIRTUAL   
REMOVEFIELD                Procedure(String pName),VIRTUAL
REMOVEKEY                  Procedure(String pName),VIRTUAL
REMOVEKEY                  Procedure(KEY pKey),VIRTUAL  
RENAME                     Procedure(STRING pNewFileName),VIRTUAL  
RESTORESTATE               Procedure(Long pState, Byte pBuffer),VIRTUAL
RESUMERELATIONS            Procedure(),VIRTUAL
SHARE                      Procedure(LONG pAccessMode=042h),VIRTUAL  
STATUS                     Procedure(),LONG,DERIVED
SETSTATUS                  Procedure(Long pAccessMode),VIRTUAL  
STREAM                     Procedure(),VIRTUAL  
SUSPENDRELATIONS           Procedure(),VIRTUAL
TOQUEUE                    Procedure(Queue pQueue),VIRTUAL  
FROMQUEUE                  Procedure(Queue pQueue),VIRTUAL  
UNLOCK                     Procedure(),VIRTUAL  
UPDATE                     Procedure(String pFilter,*? pField1,String pValue1,<*? pField2>,<String pValue2>,<*? pField3>,<String pValue3>,<*? pField4>,<String pValue4>,<*? pField5>,<String pValue5>,<*? pField6>,<String pValue6>,<*? pField7>,<String pValue7>,<*? pField8>,<String pValue8>,<*? pField9>,<String pValue9>,<*? pField10>,<String pValue10>),VIRTUAL  
UPDATE                     Procedure(Key pKey,*? pField1,String pValue1,<*? pField2>,<String pValue2>,<*? pField3>,<String pValue3>,<*? pField4>,<String pValue4>,<*? pField5>,<String pValue5>,<*? pField6>,<String pValue6>,<*? pField7>,<String pValue7>,<*? pField8>,<String pValue8>,<*? pField9>,<String pValue9>,<*? pField10>,<String pValue10>),VIRTUAL  

! Record Access
ADD                        Procedure(),VIRTUAL  
ADD                        Procedure(LONG pLength),VIRTUAL  
APPEND                     Procedure(),VIRTUAL  
APPEND                     Procedure(LONG pLength),VIRTUAL  
DELETE                     Procedure(),VIRTUAL  
DELETE                     Procedure(String pFilter),VIRTUAL  
GET                        Procedure(BIGINT pFilePointer),VIRTUAL 
GET                        Procedure(BIGINT pFilePointer, LONG pLength),VIRTUAL 
GET                        Procedure(KEY pKey),VIRTUAL 
GET                        Procedure(KEY pKey, BIGINT pKeyPointer),VIRTUAL
GETROW                     Procedure(FILE pFile,*? pField1, ? pValue1,<*? pField2>,<? pValue2>,<*? pField3>,<? pValue3>,<*? pField4>,<? pValue4>,<*? pField5>,<? pValue5>,<*? pField6>,<? pValue6>,<*? pField7>,<? pValue7>,<*? pField8>,<? pValue8>,<*? pField9>,<? pValue9>,<*? pField10>,<? pValue10>),Virtual
HOLD                       Procedure(),VIRTUAL  
HOLD                       Procedure(LONG pSeconds),VIRTUAL  
MERGE                      Procedure(FILE pDestination, LONG pOptions),VIRTUAL                                      
MERGE                      Procedure(String pDestination, LONG pOptions),VIRTUAL                                    
NEXT                       Procedure(),VIRTUAL  
NOMEMO                     Procedure(),VIRTUAL  
PREVIOUS                   Procedure(),VIRTUAL  
PUT                        Procedure(),VIRTUAL 
PUT                        Procedure(BIGINT pFilePointer),VIRTUAL 
PUT                        Procedure(BIGINT pFilePointer, LONG pLength),VIRTUAL 
RELEASE                    Procedure(),VIRTUAL 
REGET                      Procedure(STRING pPosition),VIRTUAL 
REGET                      Procedure(KEY pKey, STRING pPosition),VIRTUAL 
RESET                      Procedure(STRING pPosition),VIRTUAL 
RESET                      Procedure(KEY pKey, STRING pPosition),VIRTUAL 
ResultGet                  Procedure(BIGINT pRow),DERIVED 
ResultToRecord             Procedure(Long pRow, Long pAddressRecord, Byte pBlobs),VIRTUAL
ResultToBind               Procedure(Long pRow, Long pCol, *cstring pColName),Virtual
ResultToBlob               Procedure(iResultSet pResult,Long pRow, Long pColumn),VIRTUAL
ResultToField              Procedure(iResultSet pResult,Long pRow, Long pColumn, Long pAddr),VIRTUAL
ResultToFieldNumber        Procedure(iResultSet pResult,Long pRow, Long pColumn, Long pFieldNumber,Long pOptions),VIRTUAL
SEARCH                     Procedure(String pSearchString,<*? pField1>, <*? pField2>, <*? pField3>, <*? pField4>, <*? pField5>, <*? pField6>, <*? pField7>, <*? pField8>, <*? pField9>, <*? pField10>,<*? pField11>, <*? pField12>, <*? pField13>, <*? pField14>, <*? pField15>),VIRTUAL
_SET                       Procedure(Byte pSetMethod, BigInt pPointer,Key pSetKey, Key pSetKeyKey),VIRTUAL
SET                        Procedure(),VIRTUAL 
SET                        Procedure(Byte pSpacer=0,KEY pKey),VIRTUAL 
SET                        Procedure(BIGINT pSetPointer),VIRTUAL 
SET                        Procedure(KEY pKey),VIRTUAL 
SET                        Procedure(KEY pKey, KEY pStart),VIRTUAL 
SET                        Procedure(KEY pKey, BIGINT pSetPointer),VIRTUAL 
SET                        Procedure(KEY pKey, KEY pStart, BIGINT pSetPointer),VIRTUAL 

SUBSET                     Procedure(*? pParm1,<*? pParm2>,<*? pParm3>,<*? pParm4>,<? pParm5>,<? pParm6>,<? pParm7>,<? pParm8>,<? pParm9>,<? pParm10>),VIRTUAL
UNION                      Procedure(<String pFilter>),VIRTUAL 
UNIONALL                   Procedure(<String pFilter>),VIRTUAL 
EXCEPT                     Procedure(<String pFilter>),VIRTUAL 
INTERSECT                  Procedure(<String pFilter>),VIRTUAL 
PrimeSubset                Procedure(),DERIVED

SKIP                       Procedure(BIGINT pCount),VIRTUAL 
UPSERT                     Procedure(),VIRTUAL                                        ! New Command
WATCH                      Procedure(),VIRTUAL
_WatchCmdArm               Procedure(),VIRTUAL
_WatchCmdOff               Procedure(),VIRTUAL
_WatchBuffLoad             Procedure(),VIRTUAL      
_WatchCheck                Procedure(),VIRTUAL

! Transaction Processing
LOGOUTCONNECTION           Procedure(),VIRTUAL 
COMMIT                     Procedure(),VIRTUAL 
ROLLBACK                   Procedure(),VIRTUAL 
ROLLBACK                   Procedure(String pSavePoint),VIRTUAL 
SAVEPOINT                  Procedure(String pSavePoint),VIRTUAL 
STARTTRAN                  Procedure(Long pOpcode),VIRTUAL   ! these can be called from Logout, Commit, and Rollback
ENDTRAN                    Procedure(Long pOpcode),VIRTUAL

! Null Data Processing  
NULL_                      Procedure(Long pAddr, Long pSize),LONG,VIRTUAL 
NULL_                      PROCEDURE(Long pIndex),LONG,VIRTUAL 
SETNULL_                   Procedure(Long pAddr, Long pSize),VIRTUAL 
SETNULL_                   Procedure(*Long pIndex),VIRTUAL 
SETNULL_                   Procedure(*Cstring pColumn),VIRTUAL 
_SetFieldNull              Procedure(),VIRTUAL
_ClearField                Procedure(),VIRTUAL
SETNONNULL                 Procedure(Long pAddr, Long pSize),VIRTUAL 
SETNULLS                   Procedure(String pNulls),VIRTUAL 
_SetAllNoNull              Procedure(),Virtual
GETNULLS                   Procedure(),STRING,VIRTUAL 

GETPROPERTY                Procedure(String pProperty,Long pIndex=0),String,DERIVED                         
SETPROPERTY                Procedure(String pProperty,Long pIndex,STRING pValue),DERIVED                         
DOPROPERTY                 Procedure(String pProperty,Long pIndex=0),DERIVED

GETKEYPROPERTY             Procedure(Long pProperty,KEY pKeyPtr,Long pIndex=0),STRING,VIRTUAL                         
SETKEYPROPERTY             Procedure(Long pProperty,KEY pKeyPtr,Long pIndex=0,STRING pValue),VIRTUAL                         
DOKEYPROPERTY              Procedure(Long pProperty,KEY pKeyPtr,Long pIndex=0),VIRTUAL                         

GETBLOBPROPERTY            Procedure(Long pProperty,Long pIndex),STRING,VIRTUAL                         
DOBLOBPROPERTY             Procedure(Long pProperty,Long pIndex),STRING,VIRTUAL                         
SETBLOBPROPERTY            Procedure(Long pProperty,Long pIndex,STRING pValue),VIRTUAL                         
                         
!FILE Properties
GetPROP:AddOnly            Procedure(),STRING,VIRTUAL  
SetPROP:AddOnly            Procedure(Byte pValue),VIRTUAL 
GetPROP:Arrays             Procedure(),STRING,VIRTUAL  
GetPROP:Attributes         Procedure(Long pIndex=0),STRING,VIRTUAL  
GetPROP:Binary             Procedure(Long pIndex),STRING,VIRTUAL 
GetPROP:Blob               Procedure(Long pIndex),STRING,VIRTUAL ! Get reference to blob data 
GetPROP:Blobs              Procedure(),STRING,VIRTUAL ! Get number of blobs in file
GetPROP:Column             Procedure(Long pIndex=0),STRING,VIRTUAL   
SetPROP:Column             Procedure(Long pIndex,String pColumn),VIRTUAL 
GetPROP:Completed          Procedure(),STRING,VIRTUAL  ! Get BUILD completed status
GetPROP:Create             Procedure(),STRING,VIRTUAL    ! Get create status
SetPROP:Create             Procedure(BYTE pCreate),VIRTUAL ! Set create status
GetPROP:CurrentKey         Procedure(),STRING,VIRTUAL  ! Get current sequential or build key
GetPROP:DefaultExtension   Procedure(),STRING,VIRTUAL  ! The extension, including the dot, added to a file if no extension is supplied.                         
SetPROP:DefaultExtension   Procedure(STRING pExtension),VIRTUAL ! The extension, including the dot, added to a file if no extension is supplied.                         
GetPROP:Dim                Procedure(Long pIndex),STRING,VIRTUAL  ! connection wide.  So every file on every thread that uses the same connection (same OWNER attribute) is closed.
GetPROP:DriverLogsoutAlias Procedure(),STRING,VIRTUAL  ! Get the capacity of LOGOUT
GetPROP:DriverString       Procedure(),STRING,VIRTUAL  ! Get driver string
SetPROP:DriverString       Procedure(STRING pDriverString),VIRTUAL  ! Set driver string
GetPROP:DuplicateKey       Procedure(),STRING,VIRTUAL  ! (read only) The key that cause error code 40
GetPROP:DynamicFile        Procedure(),STRING,VIRTUAL  ! (read only) Returns '1' if the file was created by NEW(File)
GetPROP:Encrypt            Procedure(),STRING,VIRTUAL    ! Get encrypt status
SetPROP:Encrypt            Procedure(BYTE pEncrypt),VIRTUAL ! Set encrypt status
GetPROP:Exists             Procedure(),STRING,VIRTUAL  ! return the result of the last call to EXISTS
GetPROP:FastWrite          Procedure(),STRING,VIRTUAL 
SetPROP:FastWrite          Procedure(STRING pValue),VIRTUAL 
GetPROP:Fields             Procedure(Long pIndex),STRING,DERIVED  ! Get number of fields in file (group)   
GetPROP:FileDriver         Procedure(),STRING,VIRTUAL  ! Set the file driver (dynamic file support required)
GetPROP:File               Procedure(),STRING,VIRTUAL 
GetPROP:FileSize           Procedure(),BIGINT,VIRTUAL  ! Get the size of the file
GetPROP:Held               Procedure(),STRING,VIRTUAL  ! Get record hold status
GetPROP:Json               Procedure(Long pIndex),STRING,VIRTUAL 
GetPROP:Interface          Procedure(LONG pIndex),STRING,VIRTUAL  ! Get pointer to the field interface
SetPROP:Interface          Procedure(LONG pIndex,Long pAddress),VIRTUAL  ! Set pointer to the field interface
GetPROP:Key                Procedure(Long pIndex),STRING,VIRTUAL  
GetPROP:Keys               Procedure(),STRING,VIRTUAL  ! Get number of keys in file
GetPROP:Label              Procedure(LONG pIndex),STRING,DERIVED  ! Get file/key/memo/blob/field's label
SetPROP:Label              Procedure(Long pIndex,STRING pValue),VIRTUAL  ! Set file label
GetPROP:Locked             Procedure(),STRING,VIRTUAL  
GetPROP:Logout             Procedure(),STRING,VIRTUAL  ! Get/Set files logout status
SetPROP:Logout             Procedure(Long pValue),VIRTUAL  ! Get/Set files logout status
GetPROP:Memo               Procedure(),STRING,VIRTUAL  ! Remove memo from file definition (dynamic file support required)
GetPROP:Memos              Procedure(),STRING,VIRTUAL  ! Get number of memos in file
GetPROP:Name               Procedure(Long pIndex=0),STRING,VIRTUAL  ! Get file/key/memo/blob/field's name
SetPROP:Name               Procedure(Long pIndex,STRING pName),VIRTUAL  ! Set the name
GetPROP:Object             Procedure(),STRING,VIRTUAL             ! Get pointer to the file object
SetPROP:Object             Procedure(Long pAddress),VIRTUAL     ! Set pointer to the file object
GetPROP:Over               Procedure(Long pIndex),STRING,VIRTUAL             ! Get pointer to the file object
GetPROP:OEM                Procedure(),STRING,VIRTUAL    ! Get OEM attribute
SetPROP:OEM                Procedure(Byte pOEM),VIRTUAL ! Set OEM attribute
GetPROP:Owner              Procedure(),STRING,VIRTUAL  ! Get Owner
SetPROP:Owner              Procedure(STRING pOwner),VIRTUAL ! Set Owner
GetPROP:Places             Procedure(Long pIndex),STRING,VIRTUAL  ! Number of Decimal Places
GetProp:Pool               Procedure(),Long,VIRTUAL
SetProp:Pool               Procedure(Long pValue),VIRTUAL
GetPROP:Prefix             Procedure(),STRING,VIRTUAL  ! Get the prefix of the file
GetPROP:ProgressEvents     Procedure(),STRING,VIRTUAL  ! Set amount of events for BUILD
GetProp:Project            Procedure(),String,VIRTUAL
SetProp:Project            Procedure(String pValue),VIRTUAL
SetPROP:ReadOnly           Procedure(Byte pValue),DERIVED
GetPROP:Reclaim            Procedure(),STRING,VIRTUAL    ! Get Reclaim attribute
GetPROP:Record             Procedure(),STRING,VIRTUAL  ! Get the file's record buffer         
GetProp:RelationsOff       Procedure(),STRING,VIRTUAL
GetPROP:Size               Procedure(Long pIndex),STRING,VIRTUAL  
SetPROP:Size               Procedure(Long pIndex,BIGINT pValue),VIRTUAL
SetPROP:ServerAutoInc      Procedure(Long pIndex,BIGINT pValue),VIRTUAL
GetPROP:SQLDriver          Procedure(),STRING,VIRTUAL  ! '1' = Driver is SQL aware
GetPROP:SupportsOp         Procedure(Byte pOpCode),STRING,VIRTUAL  ! Get which functions are supported
GetPROP:SupportsType       Procedure(Byte pType),STRING,VIRTUAL  ! Get which data types are supported
GetPROP:Text               Procedure(Long pIndex),STRING,VIRTUAL 
SetPROP:Text               Procedure(Long pIndex,String pValue),VIRTUAL 
GETPROP:Thread             Procedure(),STRING,VIRTUAL
GETPROP:Touched            Procedure(Long pIndex),STRING,VIRTUAL
GETPROP:Type               Procedure(Long pIndex),STRING,VIRTUAL
GETPROP:Uuid               Procedure(Long pIndex),STRING,VIRTUAL
GETPROP:Uuid4              Procedure(Long pIndex),STRING,VIRTUAL
GETPROP:Uuid7              Procedure(Long pIndex),STRING,VIRTUAL
GETPROP:Uuid8              Procedure(Long pIndex),STRING,VIRTUAL
GetPROP:Value              Procedure(Long pIndex),STRING,VIRTUAL ! returns the specified MEMO or BLOB field's data
SetPROP:Value              Procedure(Long pIndex,String pValue),VIRTUAL ! sets the specified MEMO or BLOB field's data
GetPROP:Watched            Procedure(),STRING,VIRTUAL  ! Get record watch status

!SQL Related Properties
GetPROP:Alias              Procedure(),STRING,VIRTUAL  ! the alias the SQL Accelerator driver uses when generating SELECT statements for a view.
SetPROP:Alias              Procedure(String pAlias),VIRTUAL
GetPROP:AlwaysRebind       Procedure(),STRING,VIRTUAL  ! the toggle that controls whether the SQL Accelerator rebinds memory locations when a NULL state changes.
GetPROP:ConnectString      Procedure(),STRING,VIRTUAL  ! returns an SQL database's connection information. 
GetPROP:Handle             Procedure(Long pIndex),STRING,VIRTUAL  
GetPROP:Hdbc               Procedure(),STRING,VIRTUAL  ! returns the current hdbc used by the ODBC driver
GetPROP:Henv               Procedure(),STRING,VIRTUAL  ! returns the current henv (environment handle) used by the SQL driver
GetPROP:Hstmt              Procedure(),STRING,VIRTUAL  ! returns the current hstmt used by the SQL driver.
GetPROP:LoginTimeout       Procedure(),STRING,VIRTUAL  ! sets a time limit in seconds for an SQL database's login screen
SetPROP:LoginTimeout       Procedure(Long pSeconds),VIRTUAL  ! sets a time limit in seconds for an SQL database's login screen
GetPROP:LogonScreen        Procedure(),STRING,VIRTUAL  ! Driver automatically prompts for logon information
GetPROP:LogoutIsolationLevel Procedure(),STRING,VIRTUAL  ! controls what isolation level is used within a transaction frame. SQL only.
GetPROP:LogSQL             Procedure(),STRING,VIRTUAL  ! turns on or off logging of calls to the backend for SQL drivers
SetPROP:LogSQL             Procedure(Byte pLogSql),VIRTUAL  ! turns on or off logging of calls to the backend for SQL drivers
GetPROP:MaxStatements      Procedure(),STRING,VIRTUAL    ! find out how many statements can be active before a new connection to the database is raised. SQL only
GetPROP:StmtAttr           Procedure(),STRING,VIRTUAL  ! read or set the ODBC Statement Attribute


! Key properties
GetKEYPROP:Label           Procedure(KEY pKey),STRING,VIRTUAL 
GetKEYPROP:Name            Procedure(KEY pKey),STRING,VIRTUAL  
GetKEYPROP:Components      Procedure(KEY pKey),LONG,VIRTUAL 
GetKEYPROP:Dup             Procedure(KEY pKey),STRING,VIRTUAL 
GetKEYPROP:Opt             Procedure(KEY pKey),STRING,VIRTUAL 
GetKEYPROP:NoCase          Procedure(KEY pKey),STRING,VIRTUAL 
GetKEYPROP:Primary         Procedure(KEY pKey),STRING,VIRTUAL  
GetKEYPROP:Ascending       Procedure(KEY pKey, Long pField),STRING,VIRTUAL  
GetKEYPROP:Field           Procedure(KEY pKey, Long pField),STRING,VIRTUAL  
GetKEYPROP:Type            Procedure(KEY pKey),STRING,VIRTUAL    

! Blob Properties
SETBLOBPROP:Handle         Procedure(Long pIndex, BIGINT pValue),VIRTUAL
SETBLOBPROP:Size           Procedure(Long pIndex, BIGINT pValue),VIRTUAL
SETBLOBPROP:Value          Procedure(Long pIndex, STRING pValue),VIRTUAL
               END

!==================================================================================================
DriverFileSQLClass      Class(DriverFileClass), Type, MODULE('DriverClass.Clw'),LINK('DriverClass.Clw',DRVLM), DLL(DRVDM)

! these properties are not saved, and restored by SaveState / RestoreState
dbHandle                  long 
!dbConnectionTimeout       long
!dbExecTimeout             long

! these properties are saved, and restored by SaveState / RestoreState
__SQLSTATESTART           Byte
opt:LogFileName           &Cstring       ! cString(255)  !/LOGFILE=lfn [mess]
opt:LogMessage            &Cstring       ! cString(255)
opt:ZeroDate              Long           ! /ZERODATE=19010101
opt:AllowDetails          Byte           ! /ALLOWDETAILS=TRUE
opt:TurboSQL              Byte           ! /TURBOSQL=true
opt:Master                Byte
_closing                  Byte      
_connect                  Cstring(256),dim(DRIVER:MAXCONNECTCLAUSES)
_PutCols                  Long
_PutNoMemoCols            Long  
_WhereParmNumber          Long
_OffsetParmNumber         Long   
__SQLSTATEEND             Byte

CONSTRUCT                 Procedure()
DESTRUCT                  Procedure(),VIRTUAL
INIT                      Procedure(FILE pFile, Long pForce=false),DERIVED

SetDriverOption           Procedure(String pOption, String pValue),STRING,Derived
_ExecuteSelect            Procedure(),VIRTUAL

_ClearOrderFieldsInShadowBuffer Procedure(Long pOpCode, Long pFromField),Virtual
_ClearOrderFieldInShadowBuffer  Procedure(Long pOpCode, Long pDirection, Long pIndex),Virtual
_ClearField               Procedure(Long pIndex, Byte pHighLow, Long pAddr),Virtual
_AddSQL                   Procedure(Long pOpcode),Long,Virtual
_DeleteSQL                Procedure(),Long,Virtual
_DeleteSQL                Procedure(String pFilter),Long,Virtual
_DuplicateSql             Procedure(KEY pKey),Long,Virtual
_GetSQL                   Procedure(KEY pKey),Long,Virtual
_PutSql                   Procedure(),Long,Virtual
_RandomSQL                Procedure(String pFilter, BIGINT pOffset),Long,Virtual
_SelectSQL                Procedure(Long pOpcode),Long,Virtual
_AddOrderToWhere          Procedure(StringTheory pWhere,Byte pOpCode),Virtual

CheckConnect              Procedure(),Long,Virtual
TranslateLimitAbove       Procedure(Long pLimit, String pOffset),String,Virtual
TranslateLimitBelow       Procedure(Long pLimit, String pOffset),String,Virtual

ADD                       Procedure(LONG pLength),DERIVED  
APPEND                    Procedure(LONG pLength),DERIVED  
BYTES                     Procedure(),BIGINT,DERIVED  
GET                       Procedure(KEY pKey),DERIVED 
GET                       Procedure(BIGINT pFilePointer),DERIVED 
GET                       Procedure(BIGINT pFilePointer, LONG pLength),DERIVED 
GET                       Procedure(KEY pKey, BIGINT pKeyPointer),DERIVED
GETRANDOM                 Procedure(String pFilter),DERIVED
GETSTATE                  Procedure(Long pSaveBlob),LONG,DERIVED 
MERGE                     Procedure(FILE pDestination, LONG pOptions),DERIVED                                        ! New Command
MERGEFast                 Procedure(FILE pDestination, LONG pOptions),VIRTUAL                                        ! New Command (called via MERGE)
MERGESlow                 Procedure(FILE pDestination, LONG pOptions),VIRTUAL                                        ! New Command (called via MERGE)
MERGE                     Procedure(String pDestination, LONG pOptions),DERIVED                                      ! New Command
MERGEFast                 Procedure(String pDestination, LONG pOptions),VIRTUAL                                      ! New Command (called via MERGE)
NEXT                      Procedure(),DERIVED  
_NextPrevious             Procedure(Long pOpcode),VIRTUAL

POSITION                  Procedure(),STRING,DERIVED  
PREVIOUS                  Procedure(),DERIVED  
PUT                       Procedure(BIGINT pFilePointer),DERIVED 
PUT                       Procedure(BIGINT pFilePointer, LONG pLength),DERIVED  
RECORDS                   Procedure(),BIGINT,DERIVED              
RECORDSFILTER             Procedure(String pFilter),BIGINT,DERIVED  
RECORDS                   Procedure(*? pField1, <*? pField2>, <*? pField3>, <*? pField4>, <*? pField5>,<*? pField6>, <*? pField7>, <*? pField8>, <*? pField9>, <*? pField10>,<*? pField11>, <*? pField12>, <*? pField13>, <*? pField14>, <*? pField15>),BIGINT,DERIVED
RECORDS                   Procedure(KEY pKey),BIGINT,DERIVED      
REMOVE                    Procedure(),DERIVED                          
RESTORESTATE              Procedure(Long pState, Byte pBuffer),DERIVED
_SET                      Procedure(Byte pSetMethod, BigInt pPointer,Key pSetKey, Key pSetKeyKey),DERIVED
SKIP                      Procedure(BIGINT pCount),DERIVED 
SQL                       Procedure(String pSql,<? pParm1>,<? pParm2>,<? pParm3>,<? pParm4>,<? pParm5>,<? pParm6>,<? pParm7>,<? pParm8>,<? pParm9>,<? pParm10>,<? pParm11>,<? pParm12>,<? pParm13>,<? pParm14>,<? pParm15>,<? pParm16>,<? pParm17>,<? pParm18>,<? pParm19>,<? pParm20>),DERIVED   
_UpdateSql                Procedure(String pFilter,*? pField1,String pValue1,<*? pField2>,<String pValue2>,<*? pField3>,<String pValue3>,<*? pField4>,<String pValue4>,<*? pField5>,<String pValue5>,<*? pField6>,<String pValue6>,<*? pField7>,<String pValue7>,<*? pField8>,<String pValue8>,<*? pField9>,<String pValue9>,<*? pField10>,<String pValue10>),VIRTUAL
UPDATE                    Procedure(String pFilter,*? pField1,String pValue1,<*? pField2>,<String pValue2>,<*? pField3>,<String pValue3>,<*? pField4>,<String pValue4>,<*? pField5>,<String pValue5>,<*? pField6>,<String pValue6>,<*? pField7>,<String pValue7>,<*? pField8>,<String pValue8>,<*? pField9>,<String pValue9>,<*? pField10>,<String pValue10>),DERIVED
UPDATE                    Procedure(Key pKey,*? pField1,String pValue1,<*? pField2>,<String pValue2>,<*? pField3>,<String pValue3>,<*? pField4>,<String pValue4>,<*? pField5>,<String pValue5>,<*? pField6>,<String pValue6>,<*? pField7>,<String pValue7>,<*? pField8>,<String pValue8>,<*? pField9>,<String pValue9>,<*? pField10>,<String pValue10>),DERIVED

!Properties that are really commands
CREATEDB                  Procedure(String pDatabaseName),DERIVED
CONNECT                   Procedure(Long pOptions=0),DERIVED                
DISCONNECT                Procedure(),DERIVED

!GETPROPERTY               Procedure(String pProperty,Long pIndex=0),String,DERIVED                         
SETPROPERTY               Procedure(String pProperty,Long pIndex,STRING pValue),DERIVED                         
DOPROPERTY                Procedure(String pProperty,Long pIndex=0),DERIVED

GETPROP:Database          Procedure(),STRING,DERIVED
GETPROP:Server            Procedure(),STRING,DERIVED
GETPROP:SQLDriver         Procedure(),STRING,DERIVED
GETPROP:User              Procedure(),STRING,DERIVED
                        End
!==================================================================================================
! Views tend to have local, not global, scope, so the Ram constraints on the structure are less significant.
!Region ----------  Types ----------
ViewTreeType      Queue,Type  
ParentFile          &File              ! file for the parent node
File                &File              ! file for this node
TableName           Cstring(128)       ! we might not have a FILE object, but just a table name.
Driver              Cstring(50)        ! file driver name for this node
Alias               Cstring(DRIVER:MAXALIASLENGTH)
Index               Long

                    ! join properties
Key                 &key               ! foreign key
SqlJoinExpression   &Cstring           ! set by developer at runtime
LinkingExpr         &Cstring           ! custom expression
NumLinkingFields    short
LinkingField        short,dim(DRIVER:MAXJOINLINKINGFIELDS)     ! up to 255 linking fields in the join. 
JoinType            byte               ! driver:leftjoin, driver:innerjoin,driver:rightjoin,driver:fulljoin,driver:crossjoin,driver:selfjoin
Relation            byte               ! driver:one, driver:many
Hint                cstring(255)

! project
AutoProject         Byte                                    ! sum of  (driver:projectfields , driver:ProjectBlobs) or driver:ProjectNone
NumFields           Short                                   ! Number of Projected fields for this node (not including ProjectSQL)
Field               Short,dim(DRIVER:MAXPROJECTEDFIELDS)    ! Field number in the associated file.   up to 2048 projected fields per file 
Dynamic             Long                                    ! the first dynamic field added by code 
Name                Astring,dim(DRIVER:MAXPROJECTEDFIELDS)  ! Override of File Column Name. User can set it via {prop:name}

! joins 
numchildren         short
children            &ViewTreeType
                  End 
                  
!EndRegion: Types  

!==================================================================================================
! Class for VIEW support in Driver
DriverViewClass               Class(DriverBaseClass), Type, MODULE('DriverClass.Clw'),LINK('DriverClass.Clw',DRVLM), DLL(DRVDM)
View                            &View
ClaVCB                          &Cla_VCBBLK      ! same as View, but different type
_DeclaredOrder                  &Cstring
_DeclaredFilter                 &Cstring
Position                        String(4096)     ! value of all the primary key fields of all the tables in the view 
_PosLen                         Long             ! Length of Position string
_SetPropsCache                  Byte
Tree                            &ViewTreeType
Node                            &ViewTreeType    
ViewMapObj                      Long,dim(DRIVER:MAXPROJECTEDFIELDS) ! &DriverFileClass ! file object
ViewMapFieldNumber              Long,dim(DRIVER:MAXPROJECTEDFIELDS) ! + for fields, -ve for blobs
ViewMapFieldNode                Long,dim(DRIVER:MAXPROJECTEDFIELDS) ! &FieldGroupType  ! &= file._WithFieldNode(pIndex) ! file.Fields &= viewmap[n].FieldNode
ViewMapIsPrimary                Byte,dim(DRIVER:MAXPROJECTEDFIELDS) ! set to true if the field is a Primary Key Field.
                          
_RecordsViewMap                 Long
ViewDriver                      Cstring(50)
Files                           Long
FilePtr                         Long,dim(DRIVER:MAXFILESINVIEW)   
FileObject                      Long,dim(DRIVER:MAXFILESINVIEW)    
Fields                          Long
FieldsFile                      &File
_FieldsOffset                   Long
_fieldcounter                   Long

OrderAllTables                  Byte
OrderInSelect                   Byte ! Force any fields in OrderBy to also be in SELECT. Necessary for some uses of DISTINCT (SQLite, MySQL, Firebird)

_inited                         Byte               
_SetOffset                      Long

Construct                       Procedure()
Destruct                        Procedure(),Virtual

_BuildTree                      Procedure(),Virtual
_parseDescriptor                Procedure(*Long pAddr, *Long pFileIndex, ViewTreeType pNode, FILE pParentFile),Virtual
_FreeTree                       Procedure(ViewTreeType pNode),Virtual
_withNodeFileIndex              Procedure(Long pIndex),LONG,VIRTUAL
_withNodeFileIndexWalker        Procedure(ViewTreeType pNode, Long pIndex,Long pCounter),LONG,VIRTUAL
_withNodeFieldLabel             Procedure(String pLabel),Long,Virtual
_withNodeFieldLabelWalker       Procedure(ViewTreeType pNode, *CString pLabel),Long,Virtual
_withNodeField                  Procedure(Long pIndex),LONG,VIRTUAL
_withNodeFieldWalker            Procedure(ViewTreeType pNode, Long pIndex,Long pCounter),LONG,VIRTUAL
_withNodeFile                   Procedure(File pFile),long,VIRTUAL
_withNodeFileWalker             Procedure(ViewTreeType pNode,File pFile),long,VIRTUAL
_withNodeTableName              Procedure(String pTableName),long,VIRTUAL
_withNodeTableNameWalker        Procedure(ViewTreeType pNode, String pTableName),long,VIRTUAL
_countNodes                     Procedure(ViewTreeType pNode),Long,Virtual
_CountFields                    Procedure(),Virtual
_FillOrderFromLabel             Procedure(String pLabel, Byte pCase),Long,Derived
_SetViewFieldColumn             Procedure(String pLabel, String pValue),Virtual
_SetViewFieldWalker             Procedure(ViewTreeType pNode,String pLabel, String pValue,Long pFileNumber),Long,Virtual
_ForceAutoProjectNow            Procedure(ViewTreeType pNode),Virtual
_IsProjected                    Procedure(ViewTreeType pNode,Long pIndex),Long,Virtual  ! returns i in pNode.Field[i]
_ProjectField                   Procedure(ViewTreeType pNode,Long pIndex,String pExpression),Long,Proc,Virtual  ! returns i in pNode.Field[i]
_Morph                          Procedure(String pFieldLabel,Byte pClarionType, Long pClarionAddress, Long pClarionLength, Long pCellType, Long pCellAddress, Long pCellLength, Long pSqlTimeStamp),Derived


Walk                            Procedure(),VIRTUAL
_Walk                           Procedure(ViewTreeType pNode,Long pLevel),VIRTUAL
Pipe                            Procedure(Long pOpCode, LONG pClaVCB,long pVarList),LONG,Virtual
Init                            Procedure(View pView, Long pForce=false),Virtual
BindField                       Procedure(String pName,*Long pLong),Virtual
BindField                       Procedure(String pName,*Real pReal),Virtual
BindField                       Procedure(String pName,*String pString),Virtual
BindField                       Procedure(String pName,*CString pCstring),Virtual
_ClearParameterQueue            Procedure(Long pOpcode),Derived
PrimeSubset                     Procedure(),DERIVED
_FillBuffersFromPosition        Procedure(STRING pPosition, Long pOffset, Long pWhichBuffer),Long,Proc,VIRTUAL

BUFFER                          Procedure(UNSIGNED pPageSize, UNSIGNED pBehind=0, UNSIGNED pAhead=0, UNSIGNED pTimeout=0),Virtual 
CLEARPROPS                      Procedure(),Derived  
CLOSE                           Procedure(),Derived
CreateView                      Procedure(FILE pMainFile),Long,Virtual
DELETE                          Procedure(),Virtual
GetProperty                     Procedure(String pProperty,Long pIndex=0),String,Virtual                         
JoinTable                       Procedure(FILE pParentFile,FILE pJoinFile, Byte pJoinType, String pExpression),Virtual
JoinTable                       Procedure(FILE pParentFile,KEY pKey, Byte pJoinType, <*? pField1>),Virtual
LOGBUFFER                       Procedure(),VIRTUAL
LOGGINGON                       Procedure(<String pFileName>,Long pOptions=0),VIRTUAL
LOGGINGOFF                      Procedure(),VIRTUAL
NEXT                            Procedure(),Virtual
OPEN                            Procedure(),Virtual
POSITION                        Procedure(),String,Virtual  
PREVIOUS                        Procedure(),Virtual
ProjectField                    Procedure(String pExpression,String pAs),Virtual
ProjectField                    Procedure(File pFile,Long pIndex),Virtual
ProjectField                    Procedure(*? pField),Virtual
PUT                             Procedure(),Virtual
RECORDS                         Procedure(),BIGINT,Virtual
RECORDS                         Procedure(Long pIndex),BIGINT,Virtual
REGET                           Procedure(String pPosition),Virtual
RESET                           Procedure(String pPosition),Virtual
RESET                           Procedure(),Virtual
ResultGet                       Procedure(BIGINT pRow),Derived
ResultToRecords                 Procedure(Long pRow,Long pOptions),Virtual
ResultToBind                    Procedure(Long pRow),Virtual
ResultToExplain                 Procedure(iResultSet pResult),Derived
DoPROP:SQL                      Procedure(),Derived
BuildMap                        Procedure(),Virtual
_BuildMapWalker                 Procedure(ViewTreeType pNode,*Long pIndex),Virtual
SEARCH                          Procedure(String pSearchString,<*? pField1>, <*? pField2>, <*? pField3>, <*? pField4>, <*? pField5>, <*? pField6>, <*? pField7>, <*? pField8>, <*? pField9>, <*? pField10>,<*? pField11>, <*? pField12>, <*? pField13>, <*? pField14>, <*? pField15>),VIRTUAL
_SetFromFile                    Procedure(),Long,Virtual
SET                             Procedure(Long pIndex),Virtual
STATUS                          Procedure(),LONG,DERIVED

SetProperty                     Procedure(String pProperty,Long pIndex,STRING pValue),Virtual                         
GetProp:Alias                   Procedure(Long pFileNumber),String,Virtual  
GetProp:AutoProject             Procedure(Long pIndex),String,Virtual
SetProp:AutoProject             Procedure(Long pIndex, Byte pValue),Virtual
_ClearPropsWalker               Procedure(ViewTreeType pNode),Virtual
GetProp:Field                   Procedure(Long pIndex),String,Virtual
GetProp:Fields                  Procedure(Long pIndex),String,Derived
GetProp:File                    Procedure(Long pIndex),String,Virtual
GetProp:Files                   Procedure(Long pIndex),String,Virtual
GetProp:FieldsFile              Procedure(Long pIndex),String,Virtual
GetProp:Hint                    Procedure(Long pIndex),String,Virtual
SetProp:Hint                    Procedure(Long pIndex, String pValue),Virtual
GetProp:Inner                   Procedure(Long pIndex),String,Virtual
SetProp:Inner                   Procedure(Long pIndex, Byte pValue),Virtual
GetProp:Name                    Procedure(Long pIndex),String,Virtual
SetProp:Name                    Procedure(Long pIndex,String pName),Virtual
GetProp:NoKeyProject            Procedure(Long pIndex),String,Virtual
SetProp:NoKeyProject            Procedure(Long pIndex, Byte pValue),Virtual
GetProp:Object                  Procedure(),String,Virtual
SetProp:Object                  Procedure(Long pAddress),Virtual
GetPROP:OrderAllTables          Procedure(),STRING,VIRTUAL             ! use linking fields and secondary files' key component fields, as well as the primary file's key component fields, in the ORDER BY clause it sends to the server.
SetPROP:OrderAllTables          Procedure(Byte pValue),VIRTUAL 
GetPROP:OrderInSelect           Procedure(),STRING,VIRTUAL             ! Some SQL backends require that any fields used in the ORDER BY clause also appear in the SELECT statement. 
SetPROP:OrderInSelect           Procedure(Byte pValue),VIRTUAL  
GetProp:Project                 Procedure(Long pIndex),String,Virtual
GetPROP:SQLJoinExpression       Procedure(Long pIndex),STRING,VIRTUAL  ! You can use PROP:SQLJoinExpression to structure your VIEWs using native SQL code rather than Clarion code.
SetPROP:SQLJoinExpression       Procedure(Long pIndex,String pValue),VIRTUAL  ! You can use PROP:SQLJoinExpression to structure your VIEWs using native SQL code rather than Clarion code.

                              End

!==================================================================================================                       
DriverViewSQLClass            Class(DriverViewClass), Type, MODULE('DriverClass.Clw'),LINK('DriverClass.Clw',DRVLM), DLL(DRVDM)
JoinList                        &StringTheory
_ProjectClauses                 &StringTheory

From                            Cstring(128)

_ViewFixedFields                Long           ! The number of fields set to fixed values when calling SET(View,number)
_pagingfieldsadded              Long
_OffsetParmNumber               Long   
_OrderParmNumber                Long

Construct                       Procedure()
Destruct                        Procedure(),Virtual

AddFixedToOrderBy               Procedure(),Virtual
BuildProjectList                Procedure(),Virtual
_BuildProjectListWalker         Procedure(ViewTreeType pNode),Virtual
BuildFrom                       Procedure(),Virtual
BuildJoinList                   Procedure(),Virtual
_BuildJoinListWalker            Procedure(ViewTreeType pNode, String pParentAlias),Virtual
BuildOrderBy                    Procedure(),Derived
BuildOrderByUniquexx            Procedure(),Virtual
BuildOrderByUnique              Procedure(),Virtual
_BuildOrderByUniqueWalker       Procedure(ViewTreeType pNode),Virtual
SetOrderByFromQueue             Procedure(),Virtual
_ClearOrderFieldsInShadowBuffer Procedure(Long pOpCode),Virtual
_ExecuteSelect                  Procedure(),VIRTUAL
_CalcLimitAndOffset             Procedure(*Long rLimit, *Long rOffset),VIRTUAL 
_PrependFixedToWhere            Procedure(Long pIndex),VIRTUAL 
_AppendOrderQueueToWhere        Procedure(*Long pCount),VIRTUAL

CheckConnect                    Procedure(),Long,Virtual
_GenerateSelect                 Procedure(),String,Virtual
_GenerateRecordsSelect          Procedure(Long pIndex),String,Virtual

TranslateLabel                  Procedure(*cstring pValue,*byte pReturnType),String,Proc,Derived
TranslateFieldClarion           Procedure(*cstring pValue),String,Proc,Virtual
TranslateFieldSQL               Procedure(*cstring pValue),String,Proc,Virtual
TranslateJoinHint               Procedure(String pHint),String,Virtual
TranslateSelectHint             Procedure(String pHint),String,Virtual
TranslateLimitAbove             Procedure(Long pLimit, String pOffset),String,Virtual
TranslateLimitBelow             Procedure(Long pLimit, String pOffset),String,Virtual

ProjectField                    Procedure(String pExpression,String pAs),Derived
ProjectField                    Procedure(File pFile,Long pIndex),Derived
ProjectField                    Procedure(*? pField),Derived
_ProjectFieldWalker             Procedure(ViewTreeType pNode,*? pField),Long,Virtual
_ClearDynamicProjects           Procedure(),Virtual
_ClearDynamicProjectsWalker     Procedure(ViewTreeType pNode),Virtual
_NextPrevious                   Procedure(Long pOpcode),Virtual

CLEARPROPS                      Procedure(),Derived  
NEXT                            Procedure(),Derived  
PREVIOUS                        Procedure(),Derived  
PUT                             Procedure(),Derived
SET                             Procedure(Long pIndex),Derived
_SET                            Procedure(Long pOpcode),Virtual
RECORDS                         Procedure(),BIGINT,Derived
RECORDS                         Procedure(Long pIndex),BIGINT,Derived
RESET                           Procedure(String pPosition),Derived
RESET                           Procedure(),Derived
                              End
                              
!==================================================================================================
!Region ----------  Types ----------
OptionsQueueType        Queue,type
option                    any
name                      string(255)
default                   string(255)
                        End    
!EndRegion: Types                          
!DriverMetaData          Class(), Implements(IDrvMetaWindow),Type, MODULE('DriverClass.Clw'),LINK('DriverClass.Clw',DRVLM), DLL(DRVDM)
!Count                     Long
!Options                   &OptionsQueueType
!AddOption                 Procedure(*? pOption, String pName, String pDefault),Virtual
!Parse                     Procedure(*Cstring pDriverString),Virtual
!CreateString              Procedure(*Cstring rResult),Virtual
!                        End
!==================================================================================================
!Region ----------  Types ----------
CellQueueType           Queue,Type
Column                    Long
Row                       Long
IsNull                    Byte
DataX                     &String
Len                       BigInt
                        End           

CellGroupType           Group,Type                    
DataX                     &String
Len                       BigInt
IsNull                    Byte
                        End    
                        

CellsPageClass          Class(),Type, MODULE('DriverClass.Clw'),LINK('DriverClass.Clw',DRVLM), DLL(DRVDM)
Addr                      Long,dim(1024)
Size                      Long,dim(1024)  ! memory size
Len                       Long,dim(1024)  ! data length
Type                      Short,dim(1024)
                        End
                        
! each cell page holds 1000 results.                        
CellPageQueueType       Queue,type
PageNumber                Long      
Cells                     &CellsPageClass  ! can't have a &group, so using a &class instead. This allows the cells to be updated, without needing an (expensive) PUT on the queue.
                        End                        
                
ColumnNamesQueueType    Queue,type
Column                    Long
Name                      AString
                        End               
!EndRegion: Types    

FASTCOLUMNS             Equate(255)

!==================================================================================================
DriverResultSetStateQueueType  Queue,Type
Id                               Long
NumColumns                       Long
NumRows                          Long
ColumnsIndexMax                  Long
ColumnsIndex                     Long,dim(DRIVER:MAXPROJECTEDFIELDS)
ColumnsType                      Long,dim(DRIVER:MAXPROJECTEDFIELDS)
ColumnsNameMax                   Long
ColumnsName                      Astring,dim(FASTCOLUMNS)
_CellInPage                      Long
Columns                          &ColumnNamesQueueType    
CellPages                        &CellPageQueueType
                               End  


DriverResultSetClass    Class(),Implements(iResultSet),Type, MODULE('DriverClass.Clw'),LINK('DriverClass.Clw',DRVLM), DLL(DRVDM)
obj                       &DriverBaseClass
state                     &DriverResultSetStateQueueType
NumColumns                Long
NumRows                   Long
Columns                   &ColumnNamesQueueType    
ColumnsIndexMax           Long
ColumnsIndex              Long,dim(DRIVER:MAXPROJECTEDFIELDS)
ColumnsType               Long,dim(DRIVER:MAXPROJECTEDFIELDS)
ColumnsNameMax            Long
ColumnsName               Astring,dim(FASTCOLUMNS)
CellPages                 &CellPageQueueType
_CellInPage               Long
RowPositionHash           String(16),dim(1000)

lg                        Long        ! these types provide memory for the destination when converting from the database type to a clarion type.
rl                        Real
srl                       Sreal
dt                        Date
tm                        Time
strmem                    &String

Construct                 Procedure()
Destruct                  Procedure(),Virtual   
Trace                     Procedure(String pStr),Virtual
_FreeStateQueue           Procedure(),Virtual
_CheckString              Procedure(Long pLength),Virtual
_WithCell                 Procedure(Long pRow, Long pColumn),Long,Virtual
_WithPage                 Procedure(Long pPageNumber),Long,Virtual
                        End
!==================================================================================================
DriverConnectionsQueueType    Queue,Type
Connection                      Cstring(255)
Pool                            Long                            
Options                         Long
Handle                          Long
Counter                         Long
Transaction                     Byte
                              End

DriverConnectionPoolClass     Class(),Type,MODULE('DriverClass.Clw'),LINK('DriverClass.Clw',DRVLM), DLL(DRVDM)
Driver                          Cstring(30)
Connections                     &DriverConnectionsQueueType
Construct                       Procedure()
Destruct                        Procedure(),VIRTUAL
Trace                           Procedure(STRING pStr),Virtual   
GetConnection                   Procedure(String pConnectString, Long pPool, Long pOptions),Long,VIRTUAL
SetConnection                   Procedure(String pConnectString, Long pPool, Long pOptions,Long pHandle),VIRTUAL
Disconnect                      Procedure(Long pHandle),Long,VIRTUAL
SetTransaction                  Procedure(Long pHandle, Byte pValue),VIRTUAL
GetTransaction                  Procedure(Long pHandle),Long,VIRTUAL
                              End
!==================================================================================================
DriverCriticalSection         Class(),Type,MODULE('DriverClass.Clw'),LINK('DriverClass.Clw',DRVLM), DLL(DRVDM)
CS                              &ICriticalSection,PRIVATE
Construct                       Procedure()
Destruct                        Procedure()
Wait                            Procedure()
Release                         Procedure()
GetIFace                        Procedure(),*ISyncObject
                              End                        
!==================================================================================================
