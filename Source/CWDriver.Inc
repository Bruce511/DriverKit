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

!Region ----------  Equates ----------
! BIGINT: use this for now as a 52 bit integer. In later clarion versions could become a int64
BIGINT                  Equate(REAL)
Driver:BufferWholeFile  Equate(-1)
Driver:FreeBuffer       Equate(-2)

Driver:HTML             Equate(4)
Driver:JSON             Equate(3)
Driver:XML              Equate(2)
Driver:CSV              Equate(1)
Driver:Clipboard        Equate(128)

Driver:Append           Equate(128)
Driver:Header           Equate(1)
Driver:Upsert           Equate(2)
Driver:Add              Equate(4)
Driver:Bin2Base64       Equate(8)

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

!EndRegion: Equates

!Region ----------  Map ----------
  MAP
    MODULE('CWDriver.Clw')
      AddRelation(File pChildFile, File pParentFile, Long pOnUpdate, Long pOnDelete, *? pChildField1, *? pParentField1, <*? pChildField2>, <*? pParentField2>, <*? pChildField3>, <*? pParentField3>, <*? pChildField4>, <*? pParentField4>, <*? pChildField5>, <*? pParentField5>, <*? pChildField6>, <*? pParentField6>, <*? pChildField7>, <*? pParentField7>, <*? pChildField8>, <*? pParentField8>, <*? pChildField9>, <*? pParentField9>, <*? pChildField10>, <*? pParentField10>),Name('ADDRELATION')
      BindField(FILE pFile,String pName, *Long pLong),name('BINDlong')
      BindField(FILE pFile,String pName, *Real pReal),name('BINDreal')
      BindField(FILE pFile,String pName, *String pString),name('BINDstring')
      BindField(FILE pFile,String pName, *Cstring pCstring),name('BINDcstring')
      BindField(VIEW pView,String pName, *Long pLong),name('BINDlongV')
      BindField(VIEW pView,String pName, *Real pReal),name('BINDrealV')
      BindField(VIEW pView,String pName, *String pString),name('BINDstringV')
      BindField(VIEW pView,String pName, *Cstring pCstring),name('BINDcstringV')
      Bytes64(FILE pFile),BIGINT,name('BYTES64')
      ClearProps(FILE pFile),name('CLEARPROPSfile')
      ClearProps(VIEW pView),name('CLEARPROPSview')
      Commit(FILE pFile),name('COMMITconn')
      Connect(FILE pFile,Long pOptions=0),name('CONNECT')
      Copy(FILE pFile, String pFileName, Long pOptions),name('COPYoptions')
      CreateDB(FILE pFile,String pDatabaseName),name('CREATEDBname')
      CreateDB(FILE pFile),name('CREATEDB')
      CreateField(FILE pFile,*? pField1),name('CREATEfield')
      CreateField(FILE pFile,String pName, String pType, String pConstraint),name('CREATEfieldtext')
      CreateKey(KEY pKey),name('CREATEkey')
      CreateKey(File pFile,String pName, Long pOptions, *? pField1, *? pField2, <*? pField3>, <*? pField4>, <*? pField5>, <*? pField6>, <*? pField7>, <*? pField8>, <*? pField9>, <*? pField10>),name('CREATEnewkey')
      Declaration(FILE pFile,Long pOptions=0),STRING,name('DECLARATION')
      Declaration(KEY pKey,Long pOptions=0),STRING,name('DECLARATIONkey')
      Delete(FILE pFile,String pFilter),Name('DeleteFilter')
      Disconnect(FILE pFile),name('DISCONNECT')
      Except(FILE pFile,<String pFilter>),name('EXCEPT')
      Exists(FILE pFile),LONG,name('EXISTS')
      Exists(FILE pFile,STRING pTableName),LONG,name('EXISTSname')
      ExistsDB(FILE pFile,STRING pDatabaseName),LONG,name('EXISTSdbname')
      Export(FILE pFile,STRING pFileName, Long pOptions=0,Long pFormat=driver:csv),name('EXPORTfile')
      !Export(VIEW pFile,STRING pFileName,Long pFormat,Long pAppend),name('EXPORTview')
      Get64(FILE pFile,BIGINT pFilePointer),name('GET64')
      Get64(FILE pFile,BIGINT pFilePointer, LONG pLength),name('GET64len')
      GetRandom(FILE pFile),name('GETRANDOMfile')
      GetRandom(FILE pFile,String pFilter),name('GETRANDOMfilefilter')
      Import(FILE pFile,STRING pFileName, Long pOptions=0,Long pFormat=driver:csv),name('IMPORTfile')
      Intersect(FILE pFile,<String pFilter>),name('INTERSECT')
      JoinTable(VIEW pView, FILE pParentFile, *KEY pKey, Byte pJoinType, *? pField1),name('JoinKey')
      JoinTable(VIEW pView, FILE pParentFile, *KEY pKey, Byte pJoinType, *? pField1, *? pField2, <*? pField3>, <*? pField4>, <*? pField5>, <*? pField6>, <*? pField7>, <*? pField8>, <*? pField9>, <*? pField10>),name('JoinKeyEx')
      JoinTable(VIEW pView, FILE pParentFile, *FILE pJoinFile, Byte pJoinType, String pExpression),name('JoinTable')
      Log(FILE pFile,String pText),name('LOG')
      LogBuffer(FILE pFile),name('LOGBUFFER')
      LogBuffer(VIEW pView),name('LOGBUFFERview')
      LoggingOn(FILE pFILE,<String pFileName>,Long pOptions=0),name('LOGGINGON')
      LoggingOff(FILE pFILE),name('LOGGINGOFF')
      LoggingOn(VIEW pVIEW,<String pFileName>,Long pOptions=0),name('LOGGINGONview')
      LoggingOff(VIEW pView),name('LOGGINGOFFview')
      LogoutConnection(FILE pFile),name('LOGOUTconn')
      Merge(FILE pFile,FILE pDestination, Long pOptions=0),name('MERGE')
      Merge(FILE pFile,STRING pDestination, Long pOptions=0),name('MERGEname')
      Pointer64(FILE pFile),BIGINT,name('POINTER64')
      ProjectField(VIEW pView,String pExpression,String pAs),name('PROJECTFIELD')
      ProjectField(VIEW pView,FILE pFile,Long pIndex),name('PROJECTFIELDindex')
      ProjectField(VIEW pView,*? pField),name('PROJECTFIELDlabel')
      Put64(FILE pFile,BIGINT pFilePointer),name('PUT64')
      Put64(FILE pFile,BIGINT pFilePointer, LONG pLength),name('PUT64len')
      Records(FILE pFile,String pFilter),BIGINT,name('RECORDSFilter')
      Records(FILE pFile,*? pField1, <*? pField2>, <*? pField3>, <*? pField4>, <*? pField5>),BIGINT,name('RECORDSfield')
      Records64(FILE pFile),BIGINT,name('RECORDS64')
      Records64(VIEW pView),BIGINT,name('RECORDS64View')
      Records(VIEW pView, Long pNumber),BIGINT,name('RECORDS64ViewNumber')
      !Relate(FILE pParent, FILE pChild, Byte pType, Byte pOnUpdate, Byte pOnDelete, String pRelationship),name('RELATE')
      RemoveField(FILE pFile,String pName),name('REMOVEfield')
      RemoveKey(FILE pFile,String pName),name('REMOVEkeyname')
      RemoveKey(KEY pKey),name('REMOVEkey')
      Reopen(FILE pFile,LONG pNewMode),name('REOPEN')
      ResultGet(FILE pFile,BIGINT pRow),name('RESULTGET')
      ResultGet(VIEW pView,BIGINT pRow),name('RESULTGETview')
      ResultGet(FILE pFile,BIGINT pRow,Long pColumn),String,name('RESULTGETcell')
      ResultGet(VIEW pView,BIGINT pRow,Long pColumn),String,name('RESULTGETcellView')
      ResultGet(FILE pFile,BIGINT pRow,Long pColumn,*Byte pNull),String,name('RESULTGETcellNull')
      ResultGet(VIEW pView,BIGINT pRow,Long pColumn,*Byte pNull),String,name('RESULTGETcellNullView')
      ResultNext(FILE pFile),name('RESULTNEXT')
      ResultNext(VIEW pView),name('RESULTNEXTview')
      ResultPrevious(FILE pFile),name('RESULTPREVIOUS')
      ResultPrevious(VIEW pView),name('RESULTPREVIOUSview')
      ResultRow(FILE pFile),BIGINT,name('RESULTROW')
      ResultRow(VIEW pView),BIGINT,name('RESULTROWView')
      ResultRecords(FILE pFile),BIGINT,name('RESULTRECORDS')
      ResultRecords(VIEW pView),BIGINT,name('RESULTRECORDSView')
      ResumeRelations(FILE pFile),name('RESUMERELATIONS')
      Rollback(FILE pFile),name('ROLLBACKconn')
      Rollback(FILE pFile,String pSavePoint),name('ROLLBACKsavepoint')
      SavePoint(FILE pFile,String pSavePoint),name('SAVEPOINT')
      Search(FILE pFile,String pSearchString,<*? pField1>, <*? pField2>, <*? pField3>, <*? pField4>, <*? pField5>, <*? pField6>, <*? pField7>, <*? pField8>, <*? pField9>, <*? pField10>,<*? pField11>, <*? pField12>, <*? pField13>, <*? pField14>, <*? pField15>),Name('SEARCHfile')
      Search(VIEW pView,String pSearchString,<*? pField1>, <*? pField2>, <*? pField3>, <*? pField4>, <*? pField5>, <*? pField6>, <*? pField7>, <*? pField8>, <*? pField9>, <*? pField10>,<*? pField11>, <*? pField12>, <*? pField13>, <*? pField14>, <*? pField15>),Name('SEARCHview')
      Set(FILE pFile,*BIGINT pPointer),name('SET64ptr')
      Set(KEY pKey, *BIGINT pSetPointer), name('SET64keyptr')
      Set(KEY pKey, KEY pStart, *BIGINT pSetPointer),name('SET64keykeyptr')
      Set64(FILE pFile,BIGINT pPointer),name('SET64ptra')
      SetCustomType(FILE pFILE,String pFieldLabel,iDriverField pCustom),name('SETCUSTOMTYPE')
      Skip64(FILE pFile,BIGINT pValue),name('SKIP64')
      SQL(FILE pFILE,String pSql,<? pParm1>,<? pParm2>,<? pParm3>,<? pParm4>,<? pParm5>,<? pParm6>,<? pParm7>,<? pParm8>,<? pParm9>,<? pParm10>,<? pParm11>,<? pParm12>,<? pParm13>,<? pParm14>,<? pParm15>),name('SQLFile')
      Subset(FILE pFILE,*? pParm1,<*? pParm2>,<*? pParm3>,<*? pParm4>,<? pParm5>,<? pParm6>,<? pParm7>,<? pParm8>,<? pParm9>,<? pParm10>),name('SUBSET')
      SuspendRelations(FILE pFile),name('SUSPENDRELATIONS')
      ToQueue(FILE pFile,Queue pQueue),name('TOQUEUE')
      FromQueue(FILE pFile,Queue pQueue),name('FROMQUEUE')
      Union(FILE pFile,<String pFilter>),name('UNION')
      Update(File pFile,String pFilter,*? pField1,String pValue1,<*? pField2>,<String pValue2>,<*? pField3>,<String pValue3>,<*? pField4>,<String pValue4>,<*? pField5>,<String pValue5>,<*? pField6>,<String pValue6>,<*? pField7>,<String pValue7>,<*? pField8>,<String pValue8>,<*? pField9>,<String pValue9>,<*? pField10>,<String pValue10>),Name('UPDATE')
      Update(Key pKey,*? pField1,String pValue1,<*? pField2>,<String pValue2>,<*? pField3>,<String pValue3>,<*? pField4>,<String pValue4>,<*? pField5>,<String pValue5>,<*? pField6>,<String pValue6>,<*? pField7>,<String pValue7>,<*? pField8>,<String pValue8>,<*? pField9>,<String pValue9>,<*? pField10>,<String pValue10>),Name('UPDATEKey')
      Upsert(File pFile),Name('UPSERT')
    END
  END
!EndRegion: Map

 PRAGMA('compile(CWDRIVER.CLW)')

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
prop:LogClarion         Equate(7437h)
PROP:LogBind            Equate(7438H)    ! Log BINDing of SQL values
PROP:LogExplain         Equate(7439H)    ! Log EXPLAIN of all SET/NEXT loops
PROP:LogOptions         Equate(743AH)
prop:LogConnections     Equate(743Bh)

Prop:ClientVersionMajor Equate(7440h)
Prop:ClientVersionMinor Equate(7441h)
Prop:ClientVersionBuild Equate(7442h)
Prop:ClientVer          Equate(7443h)
Prop:Locked             Equate(7444h)
Prop:Search             Equate(7445h)
prop:SearchRank         Equate(7446h)

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
BadFieldErr             Equate(126)   !  "Field does not belong to file"  ! used in SUBSET and RECORDS and CREATERELATION
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
!EndRegion: Errors
!------------------------------------------------------------------------------------------------
