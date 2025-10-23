!------------------------------------------------------------------------------------------------
!   CapeSoft Clarion File Driver Kit classes are copyright © 2025 by CapeSoft                   !
!   Docs online at : https://capesoft.com/docs/Driverkit/ClarionObjectBasedDrivers.htm
!   Released under MIT License
!------------------------------------------------------------------------------------------------

!Region ----------  Includes ----------
  !Include('ClaComp.inc'),Once   ! Structures used by the compiler when dealing with FILE and VIEW
  !Include('FileCB.Inc'),Once    ! Clarion's File Callback Interface Declaration in LIBSRC
  Include('CWDriver.Int'),Once    ! Interfaces declared for use by the object based drivers.
!EndRegion: Includes

! Properties and Errors are in cwDriver.Inc
! ----------------------------------------------------------------------------------------------
!Region ----------  Equates ----------
Driver:ok               Equate(0)
Driver:notok            Equate(1)
driver:SetBoundary      Equate(-1)

driver:NotSet           Equate(0)
driver:SetFile          Equate(1)
driver:SetKey           Equate(2)
driver:SetKeyKey        Equate(3)
driver:SetKeyPos        Equate(4)
driver:SetFilePos       Equate(5)

driver:Ascending        Equate(0)
driver:Descending       Equate(1)

driver:keys             Equate(1)

driver:database         Equate(0)
driver:dict             Equate(1)
driver:dictfield        Equate(2)
driver:dictkey          Equate(3)
driver:strictdict       Equate(4)

driver:one              Equate(1)
driver:many             Equate(2)
driver:root             Equate(3)   ! used for the root table in the view. Basically also a "many".

driver:default:none     Equate(0)
driver:default:number   Equate(1)
driver:default:string   Equate(2)

driver:DontFreeRam      Equate(0)
driver:FreeRam          Equate(1)

Driver:Blobs            Equate(1)
Driver:NoBlobs          Equate(0)

driver:buffer           Equate(1)
driver:shadow           Equate(2)
driver:nobuffer         Equate(4)

driver:unknown          Equate(0)
driver:field            Equate(1)
driver:constant         Equate(2)
driver:bound            Equate(3)    ! label is bound using regular clarion BIND command, not BindField method
driver:bindfield        Equate(4)    ! label is bound using BINDFIELD method

driver:high             Equate(1)
driver:low              Equate(2)

driver:IsNull           Equate(1)

driver:FromBuffer             Equate(1)
driver:FromShadow             Equate(2)
driver:FromPrimaryKeyPosition Equate(3)
!driver:FromPosition          Equate(3)

!driver:SqlTable         Equate(1)
!driver:DosFile          Equate(2)
!driver:Column           Equate(4)

driver:filter           Equate(1)
driver:sqlfilter        Equate(2)
driver:order            Equate(3)
driver:sqlorder         Equate(4)
driver:groupby          Equate(5)
driver:having           Equate(6)
driver:project          Equate(7)
driver:parameter        Equate(8)
driver:join             Equate(9)
driver:expression       Equate(10)
driver:searchfilter     Equate(13)

! driver:sqltable is 10
! driver:dosfile is 11
! driver:append is 128

driver:SqlTable         Equate(10)
driver:SqlColumn        Equate(12)
driver:DosFile          Equate(11)
driver:SqlSavepoint     Equate(13)

driver:withdot          Equate(1)
driver:nodot            Equate(0)

driver:LeftJoin         Equate(0)   ! this is the current clarion default when not ,INNER
driver:InnerJoin        Equate(1)   ! this is the Clarion ,INNER property
driver:RightJoin        Equate(2)
driver:FullJoin         Equate(3)
driver:CrossJoin        Equate(4)
driver:SelfJoin         Equate(5)

driver:ProjectNone      Equate(0)
driver:ProjectFields    Equate(1)
driver:ProjectBlobs     Equate(2)
driver:ProjectAll       Equate(3)

driver:ProjectAllKeys     Equate(0)
driver:ProjectNoKeys      Equate(1)
driver:ProjectPrimaryKeys Equate(2)

driver:ResetToBufferRow   Equate(1)
driver:ShadowBufferPrimed Equate(2)
driver:BufferPrimed       Equate(3)

driver:all                Equate('*')

driver:GroupOverTimeStamp  Equate(1)
driver:StringToTimeStamp   Equate(2)
driver:StringToTimeStamp2  Equate(3)
driver:StringToTimeStampTZ Equate(4)

Watch:off               Equate(0)
Watch:on                Equate(1)
Watch:loaded            Equate(2)
Watch:disabled          Equate(3)
Watch:put               Equate(4)
Watch:canput            Equate(5)
Watch:armed             Equate(6)

token:expression    equate('E')
token:condition     equate('C')
token:label         equate('L')
token:value         equate('V')
token:function      equate('F')
token:operator      equate('O')

token:plus          equate(token:operator & '0001 ')
token:minus         equate(token:operator & '0002 ')
token:divide        equate(token:operator & '0003 ')
token:multiply      equate(token:operator & '0004 ')
token:mod           equate(token:operator & '0005 ')
token:comma         equate(token:operator & '0006 ')
token:power         equate(token:operator & '0007 ')
token:concat        equate(token:operator & '0008 ')
token:asc           equate(token:operator & '0009 ')
token:desc          equate(token:operator & '0010 ')
token:as            equate(token:operator & '0011 ')



!EndRegion: Equates

!Region ----------  OpCodes ----------
!==================================================================================================
! Opcodes. Calls into the driver are made into the Pipe function.
! Which has a prototype of DRV(Long iOpCode,Cla_FCBBLK *pFCB, VALIST vArgs)
! the first parameter is the opcode. These are those codes.
! The comment for each code indicates the parameters expected.

Opcode:NONE                    equate(0)
Opcode:ADD                     equate(1)   !     DRV(code,fcb);
Opcode:ADDfilelen              equate(51)  !     DRV(code,fcb,unsigned len);
Opcode:APPEND                  equate(4)   !     DRV(code,fcb);
Opcode:APPENDlen               equate(59)  !     DRV(code,fcb,unsigned len);
Opcode:BOF                     equate(2)   !     DRV(code,fcb);
Opcode:BUFFER                  equate(80)  !     DRV(code,fcb, unsigned buffers);
Opcode:BUILDdyn                equate(5)   !     DRV(code,fcb,key,char *str,int len);
Opcode:BUILDdynfilter          equate(34)  !     DRV(code,fcb,key); + 2 strings Added in CW1.5
Opcode:BUILDfile               equate(3)   !     DRV(code,fcb);
Opcode:BUILDkey                equate(6)   !     DRV(code,fcb,key);
Opcode:BYTES                   equate(52)  !     DRV(code,fcb);
Opcode:EOF                     equate(14)  !     DRV(code,fcb);
Opcode:CLOSE                   equate(7)   !     DRV(code,fcb);
Opcode:COMMITdrv               equate(8)   !     DRV(code,fcb);
Opcode:OPEN                    equate(25)  !     DRV(code,fcb,int mode);
Opcode:COPY                    equate(9)   !     DRV(code,fcb,char *str,int len);
Opcode:CREATE                  equate(10)  !     DRV(code,fcb);
Opcode:DELETE                  equate(11)  !     DRV(code,fcb);
Opcode:DUPLICATE               equate(12)  !     DRV(code,fcb);
Opcode:DUPLICATEkey            equate(57)  !     DRV(code,fcb,key);
Opcode:EMPTY                   equate(13)  !     DRV(code,fcb);
Opcode:FLUSH                   equate(29)  !     DRV(code,fcb);
Opcode:GET                     equate(15)  !     DRV(code,fcb,key);
Opcode:GETfilekey              equate(15)  !     DRV(code,fcb,key);
Opcode:GETfileptrlen           equate(53)  !     DRV(code,fcb,long ptr,unsigned len)
Opcode:GETfileptr              equate(16)  !     DRV(code,fcb,long ptr);
Opcode:GETkeyptr               equate(17)  !     DRV(code,fcb,key,long ptr);
Opcode:HOLD                    equate(18)  !     DRV(code,fcb)
Opcode:HOLDfile                equate(18)  !     DRV(code,fcb)
Opcode:HOLDfilesec             equate(19)  !     DRV(code,fcb,int seconds);
Opcode:LOCKfile                equate(20)  !     DRV(code,fcb)
Opcode:LOCKfilesec             equate(21)  !     DRV(code,fcb,int seconds);
Opcode:LOGOUTdrv               equate(22)  !     DRV(code,fcb);
Opcode:NAME                    equate(23)  !     DRV(code,fcb);
Opcode:NEXT                    equate(24)  !     DRV(code,fcb);
Opcode:PACK                    equate(26)  !     DRV(code,fcb);
Opcode:POINTERfile             equate(27)  !     DRV(code,fcb);
Opcode:POINTERkey              equate(28)  !     DRV(code,fcb,key);
Opcode:POSITIONfile            equate(61)  !     DRV(code,fcb);
Opcode:POSITIONView            equate(61)  !     DRV(code,fcb);
Opcode:POSITIONkey             equate(62)  !     DRV(code,fcb,key);
Opcode:PREV                    equate(31)  !     DRV(code,fcb);
Opcode:PREVIOUS                equate(31)  !     DRV(code,fcb);
Opcode:PUT                     equate(30)  !     DRV(code,fcb);
Opcode:PUTfileptr              equate(54)  !     DRV(code,fcb,long ptr);
Opcode:PUTfileptrlen           equate(55)  !     DRV(code,fcb,long ptr,unsigned l);
Opcode:RECORDS                 equate(32)  !     DRV(code,fcb);
Opcode:RECORDSfile             equate(32)  !     DRV(code,fcb);
Opcode:RECORDSkey              equate(33)  !     DRV(code,fcb,key);
Opcode:RELEASE                 equate(36)  !     DRV(code,fcb);
Opcode:REMOVE                  equate(37)  !     DRV(code,fcb);
Opcode:RENAME                  equate(38)  !     DRV(code,fcb,char *str,int len);
Opcode:RESETfile               equate(63)  !     DRV(code,fcb,char *str);
Opcode:RESETkey                equate(64)  !     DRV(code,fcb,key,char *str);
Opcode:ROLLBACKdrv             equate(40)  !     DRV(code,fcb);
Opcode:SEND                    equate(60)  !     DRV(code,fcb,char *str,int len);
Opcode:SET                     equate(41)  !     DRV(code,fcb);
Opcode:SETfile                 equate(41)  !     DRV(code,fcb);
Opcode:SETfilekey              equate(42)  !     DRV(code,fcb,key);
Opcode:SETfileptr              equate(43)  !     DRV(code,fcb,long ptr);
Opcode:SETkey                  equate(44)  !     DRV(code,fcb,key);
Opcode:SETkeykeyptr            equate(47)  !     DRV(code,fcb,key,key,long ptr);
Opcode:SETkeykey               equate(45)  !     DRV(code,fcb,key,key);
Opcode:SETkeyptr               equate(46)  !     DRV(code,fcb,key,long ptr);
Opcode:SHARE                   equate(48)  !     DRV(code,fcb,int mode);
Opcode:SKIP                    equate(49)  !     DRV(code,fcb,long num);
Opcode:STREAM                  equate(56)  !     DRV(code,fcb);
Opcode:UNLOCK                  equate(50)  !     DRV(code,fcb);

Opcode:WATCH                   equate(58)  !     DRV(code,fcb);
Opcode:NOMEMO                  equate(65)  !     DRV(code,fcb);
Opcode:REGETfile               equate(66)  !     DRV(code,fcb,char *str)
Opcode:REGETkey                equate(67)  !     DRV(code,fcb,char *str)
Opcode:NULL                    equate(68)  !     DRV(code,fcb,void * field)
Opcode:SETNULL                 equate(69)  !     DRV(code,fcb,void * field)
Opcode:SETNONNULL              equate(70)  !     DRV(code,fcb,void * field)
Opcode:SET_PROPERTY            equate(71)  !     DRV(code,fcb)
Opcode:GET_PROPERTY            equate(72)  !     DRV(code,fcb)
Opcode:QUERY_KEY               equate(73)  !     DRV(code,fcb)
Opcode:QUERY_VIEW              equate(74)  !     DRV(code)
Opcode:_BLOB_YIELD             equate(75)  !     DRV(code,fcb,unsigned short, unsigned long, unsigned long)
Opcode:_BLOB_TAKE              equate(76)  !     DRV(code,fcb,unsigned short, unsigned long, unsigned long)
Opcode:_BLOB_SIZE              equate(77)  !     DRV(code,fcb,unsigned short)
Opcode:_BLOB_SETPROPERTY       equate(78) !     DRV(code,fcb,unsigned short)
Opcode:_BLOB_GETPROPERTY       equate(79) !     DRV(code,fcb,unsigned short)

Opcode:SETviewfields           equate(81)  !     DRV(code,vcb,long fields)
Opcode:CLEARfile               equate(82)  !     DRV(code,fcb)
Opcode:RESETviewf              equate(83)  !     DRV(code,vcb,fcb)
Opcode:START_BUILD             equate(84)  !     DRV(code,fcb)
Opcode:KEY_SETPROPERTY         equate(85)  !     DRV(code,fcb,key)
Opcode:KEY_GETPROPERTY         equate(86)  !     DRV(code,fcb,key)
Opcode:REGISTER                equate(87)  !     Internal used to start buffer
Opcode:DO_PROPERTY             equate(88)  !     DRV(code,fcb)
Opcode:KEY_DOPROPERTY          equate(89)  !     DRV(code,fcb,key,ndx)
Opcode:BLOB_DOPROPERTY         equate(90)  !     DRV(code,fcb,memo)
Opcode:WHO_ARE_YOU             equate(91)  !     Internal used in buffering code
Opcode:BULK_READ_ON            equate(92)  !     Used by View Engine
Opcode:BULK_READ_OFF           equate(93)  !     Used by View Engine
Opcode:CONNECT                 equate(94)  !     Internal used by RPC system
Opcode:EXCEEDS_RECS            equate(95)  !     Internal. Used by eval version
Opcode:GETNULLS                equate(96)   !    DRV(code,fcb)
Opcode:SETNULLS                equate(97)   !    DRV(code,fcb, char *str)
Opcode:GETSTATE                equate(98)   !    DRV(code,fcb)
Opcode:RESTORESTATE            equate(99)   !    DRV(code,fcb,long,byte)
Opcode:CALLBACK                equate(100)  !    Opcode:FILE_CALLBACK
Opcode:FREESTATE               equate(102)  !    DRV(code,fcb,long)
Opcode:SQLCALLBACK             equate(103)  !    DRV(code,fcb,interface *, char, uchar)
Opcode:DESTROYf                equate(104)  !    DRV(code,fcb,int)
Opcode:STARTTRAN               equate(35)   !    DRV(code,fcb,int)
Opcode:ENDTRAN                 equate(39)   !    DRV(code,fcb,int)
Opcode:FIXFORMAT               equate(105)  !    DRV(code,fcb)
Opcode:UNFIXFORMAT             equate(106)  !    DRV(code,fcb)
Opcode:SQL                     equate(107)  !    DRV(code, fcb, const char *sql, char textAsStr, char imageAsStr) Internally used by DynFile.cpp
Opcode:VALIDATE                equate(108)  !    DRV(code, fcb) Internally used by DynFile.cpp
Opcode:SET_DOTNET_PROPERTY     equate(109)  !    Used by the .NET to Win32 communicationlayer
Opcode:GET_DOTNET_PROPERTY     equate(110)  !    Used by the .NET to Win32 communicationlayer
Opcode:SET_DOTNET_KEY_PROPERTY equate(111)  !    Used by the .NET to Win32 communicationlayer
Opcode:GET_DOTNET_KEY_PROPERTY equate(112)  !    Used by the .NET to Win32 communicationlayer

! The following define is used to set up utility internal tables regarding driver functionality within clarion (accounting for expansion)
Opcode:TOTFOPCODES             equate(113)

!------------------------------------------------------------------------------------------------
! New OpCodes
OpCode:Exists                  equate(150)
OpCode:Merge                   equate(151)
OpCode:Reopen                  equate(152)
OpCode:Upsert                  equate(153)
OpCode:Bytes64                 equate(154)
OpCode:Pointer64               equate(155)
OpCode:Records64               equate(156)
OpCode:Set64                   equate(157)
OpCode:SetCustomType           equate(158)
!OpCode:Connect                 equate(159)
OpCode:Disconnect              equate(160)
OpCode:BindField               equate(161)
OpCode:ProjectField            equate(162)
Opcode:JoinTable               equate(163)
Opcode:CreateDb                equate(164)
Opcode:Status                  equate(165)
Opcode:RecordsFilter           equate(166)
Opcode:GetRandom               equate(167)
Opcode:Search                  equate(168)
Opcode:FromQueue               equate(169)
Opcode:ToQueue                 equate(170)
Opcode:Union                   equate(171)
Opcode:UnionAll                equate(172)
Opcode:Except                  equate(173)
Opcode:Intersect               equate(174)
Opcode:Subset                  equate(175)
Opcode:ResultGet               equate(176)
Opcode:Update                  equate(177)

!EndRegion: Opcodes

!Region ----------  Data Types ----------
! ----------------------------------------------------------------------------------------------
! Data Types. These are equates for all the data types. At the driver level support for these types can be turned on and off.
!
ClaRAW           Equate(0)
ClaNULL          Equate(0)
ClaBYTE          Equate(1) !                      /* 0x01 Signed 1 Byte Binary      */  x
ClaSHORT         Equate(2) !                      /* 0x02 Signed 2 Byte Binary      */  x
ClaUSHORT        Equate(3) !                      /* 0x03 Unsigned 2 Byte Binary    */
ClaDATE          Equate(4) !                      /* 0x04 4 Byte Binary YYMD        */
ClaTIME          Equate(5) !                      /* 0x05 4 Byte Binary HMSH        */
ClaLONG          Equate(6) !                      /* 0x06 Signed 4 Byte Binary      */  x
ClaULONG         Equate(7) !                      /* 0x07 Unsigned 4 Byte Binary    */
ClaSREAL         Equate(8) !                      /* 0x08 Signed 4 Byte Float       */
ClaREAL          Equate(9) !                      /* 0x09 Signed 8 Byte Float       */ x
ClaDECIMAL       Equate(00Ah) !                   /* 0x0A Clarion Packed Decimal    */ x
ClaPDECIMAL      Equate(00Bh) !                   /* 0x0B IBM Packed Decimal        */
ClaSBYTE         Equate(00Ch) !
ClaBFLOAT4       Equate(00Dh) !                   /* 0x0D Basic FLOAT 4 bytes       */
ClaBFLOAT8       Equate(00Eh) !                   /* 0x0E Basic FLOAT 8 bytes       */   &= 1F
ClaANY           Equate(00Fh)
ClaSIGNED        Equate(010h)
ClaUNSIGNED      Equate(011h)
ClaSTRING        Equate(012h) ! 18                /* 0x12 ASCII character sequence  */  x
ClaCSTRING       Equate(013h) ! 19                 /* 0x13 C string (trailing null)  */
ClaPSTRING       Equate(014h) !                   /* 0x14 Pascal string (len byte)  */
ClaMEMO          Equate(015h) ! 21                /* 0x15 Memo                      */  x      ?
ClaGROUP         Equate(016h) !                   /* 0x16 Clarion Group structure   */  x
ClaCLASS         Equate(017h) !                   /* 0x17 Class type descriptor     */
ClaNOTHING       Equate(018h) !                   Nothing                               x
                 Equate(019h) !                   Not valid
ClaQUEUE         Equate(01Ah) !                   /* 0x1A Queue          */        ?
ClaBLOB          Equate(01Bh) ! 27                /* 0x1B Blob and TempStr          */        ?
ClaREFERENCE     Equate(01Fh)
ClaTYPE          Equate(08Eh)
ClaInt64         Equate(064h)   ! Placeholder for now - bj
!EndRegion: Data Types

!Region ----------  Field Attributes ----------
! ----------------------------------------------------------------------------------------------
! Field Attributes
ClaAttrName         Equate(1)
ClaAttrLabel        Equate(2)
ClaAttrPic          Equate(4)
ClaAttrOver         Equate(8)
ClaAttrDim          Equate(10h)

! ----------------------------------------------------------------------------------------------
! Sharing mode and Access mode defines for OPEN and SHARE---------------------
Access:ReadOnly     Equate(0)       !     Access Mode read only
Access:WriteOnly    Equate(1)       !     Access Mode write only
Access:ReadWrite    Equate(2)       !     Access Mode read/write

Access:DENY_RW      Equate(10h)      !   Sharing mode deny read/write
Access:DENY_W       Equate(20h)      !   Sharing mode deny write
Access:DENY_R       Equate(30h)      !   Sharing mode deny read
Access:DENY_NONE    Equate(40h)      !   Sharing mode deny none

!EndRegion: Field Attributes

!Region ----------  Compiler Data Structures ----------
! ----------------------------------------------------------------------------------------------
! for a driver to be registered in the IDE, a group of this type is populated with fixed
! values and exported. It's important that the group is populated with fixed values, as it's
! read directly out the DLL file on disk. The DLL is not loaded, and hence can't set these
! values at runtime.
! ----------------------------------------------------------------------------------------------
DrvRegType            Group,Type
raw_name                cstring(21)
dll_name                cstring(13)
copywrite               cstring(41)
desc                    cstring(31)
driver                  long !  Cla_PIPE_FUNC
drvattr                 Group
attrval                   long
reserved                  byte
                        End
clastrlen               ushort       ! if supported, max clarion string length
cstrlen                 ushort       ! max cstring length
reclen                  ushort       ! total record length - 64K max
clastrlen32             ulong        ! if supported, max clarion string length for 32bit apps
cstrlen32               ulong        ! max cstring length for 32bit apps
reclen32                ulong        ! total record length for 32bit apps
maxdims                 byte         ! total number of dimensions
maxkeys                 byte         ! total keys and indeces - 255 max
maxmemos                byte         ! total memos - 255 max
memosize                short        ! maximum memo size
memosize32              ulong        ! maximum memo size for 32bit apps
fldsize                 ulong        ! size of the Drv_FLD structure
kcbsize                 ulong        ! size of the Drv_KCB structure
mcbsize                 ulong        ! size of the Drv_MCB structure
fcbsize                 ulong        ! size of the Drv_FCB structure
reserved1               byte,dim(12) ! reserved allowing for sizes
tdesc                   long ! *char ! pointer to type descriptor for functions and data types supported
dsi_name                cstring(13)  ! dsi dll name    ! Data Ststem Import (DSI). ie Data Syncroniser / Data Import in Dict
driverMeta              long         ! DRV_META_FUNC   ! This is the window called when the user clicks on the ... button next to driver string in the dict.
                      End

! ------------------------------------------------------------------------------
! File Control Block (aka FILE aka rBlock)
Drv_FCB               Group,Type
filename                long  ! *char ! FILE's name,
labname                 long  ! *char ! FILE's label
fileOwner               long  ! *char ! The string specified in the OWNER attribute of the FILE.
fileStr                 long  ! *char ! The string specified as the second string in DRIVER attribute.
fileAttr                long  ! could be byte. ! encrypt, create, reclaim, thread, oem  TODO - check byte or long
recbuf                  long  ! *void ! FILE's RECORD buffer, this points to a buffer allocated by the Clarion run-time.  Data may be copied to it but it may not be reallocated or freed by the File Driver.
reclen                  ulong
memoArr                 long  ! *Drv_MCB. Array of MEMO field descriptors.  There is one entry per MEMO field.
memoCnt                 ulong ! Number of elements in memoArr
keyArr                  long  ! *Drv_KCB. Array of KEY and INDEX descriptors.  There is one entry for each KEY and INDEX declaration in the FILE structure.
keyCnt                  ulong ! Number of elements in memoArr
fldArr                  long  ! *Drv_FLD  Array of field descriptors.  There is one entry for each field declared in the FILE's RECORD structure.
fldCnt                  ulong ! Number of elements in fldArr
iMode                   long  ! Open mode of file.  This is the mode parameter passed to the OPEN() or SHARE() statements.
seqOp                   ulong ! Last sequential operation.  This will contain one of the following values to identify the previous sequential operation: Opcode:NEXT,Opcode:PREV, Opcode:RESETfile, Opcode:RESETkey,Opcode:SETfile, Opcode:SETfilekey, Opcode:SETfileptr,Opcode:SETkey, Opcode:SETkeykeyptr, Opcode:SETkeykey,Opcode:SETkeyptr
seqErr                  long
retOp                   long
usAct                   long
usState                 ulong ! Current file state - see doc
!usAct                   ulong ! Action variable used by the state management code and should not be modified by the File Driver Primitives.
fldstate                long
iErro                   long
tracefile               long !iTraceFile ! 22
dirty                   byte
buildop                 long
buildkcb                &Drv_KCB
buildparm               byte
buildparm2              byte
sliceamount             short
buildcompleted          short
server                  long
driver                  long
fcbHnd                  &Cla_FCBBLK
curkey                  &Drv_KCB
seqpos                  long
seqposlen               long
restorePos              long
restorePosLen           long
resetPos                long
resetPosLen             long
holdSecs                long
setFK                   &Cla_KEYDESC
setPtr                  long
partInit                byte
duplicatekey            &Drv_KCB
dateTimefields          Long
dateTimeCount           Long
                        ! Custom fields required by the specific driver can be included here.
                      End

! ------------------------------------------------------------------------------
! The Key Component Descriptor Structure
! A pointer to the array is passed in the fldArr element of the Drv_KCB.
Drv_CMP               Group,Type
fldHnd                  long ! *Drv_Fld ! Component field, this is a pointer to the appropriate element of the fldArr element in the Drv_FCB structure
fldOrd                  long ! Component fields sort order, TRUE - Component is descending
                      End

! ------------------------------------------------------------------------------
!The KEY and INDEX Control Block Structure: Drv_KCB
!A pointer to this array is passed as the keyArr of the Drv_FCB structure.

KeyAttr:Dup           Equate(01)
KeyAttr:Opt           Equate(02)
KeyAttr:NoCase        Equate(04)
KeyAttr:AutoInc       Equate(08)
KeyAttr:Primary       Equate(16)
KeyAttr:Ndx           Equate(32)
KeyAttr:Dyn           Equate(64)

! The following defines are for key, index, and dynamic index sequencing
KEYASC                Equate(0) ! ascending only
ASCDSC                Equate(1) ! ascending/descending. mixed
ASCDSC1               Equate(2) ! ascending/descending. All components must be the same

Drv_KCB               Group,Type
keyFCB                  &Drv_FCB !  Key's parent file.
keyName                 long     ! *Char    ! Contents of the KEY or INDEX NAME() attribute or NULL if there is no NAME() attribute.
labName                 long     ! *Char    ! KEY or INDEX label name.  The buffer is allocated on the heap.  Typically the KEY and INDEX file name (keyName) is derived from the labName if the NAME() attribute hasn't been specified.
fldArr                  long     ! *Drv_CMP  ! Array of fields comprising the keys components. So called 'dynamic' INDEXes are declared without components, the fldArr must be built at runtime by a call to drv_BuildDynKey()
fldCnt                  long     !          ! Number of elements in fldArr
sState                  byte     ! or MAYBE a Long. TODO. KeyAttr for the key. Dup, Opt, Nocase, AutoInc, Primary, ndx, dyn
ulState                 ulong    ! Current state of Key
keyNum                  ulong    ! 0 based identifier
kcbHnd                  long     ! * Cla_KEYDESC   ! Pointer to the Clarion run-time key descriptor. The information in the Drv_KCB is generated by parsing this structure.  Access to this structure is not usually necessary.
                        ! Custom fields required by the specific driver can be included here.
                      End

! ------------------------------------------------------------------------------
!The MEMO Control Block Structure: Drv_MCB
!  A pointer to this array is passed as the memoArr of the Drv_FCB structure.
Drv_MCB               Group,Type
memoName                long ! *Char  Contents of the MEMOs NAME() attribute, or NULL if there is no NAME() attribute.
labName                 long ! *Char  MEMO label name.
memoBuf                 long ! *Void Memo buffer
memoLen                 ulong ! Size of memo buffer
memoAttr                ulong ! Attributes. One of Memo, Image, Blob
memoFCB                 &Drv_FCB !  Memos's parent file.
memoHnd                 long ! *Cla_MEMODESC ! Pointer to the Clarion run-time memo descriptor. The information in the Drv_MCB is generated by parsing this structure.  Access to this structure is not usually necessary.
                        ! Custom fields required by the specific driver can be included here.
                      End

! ------------------------------------------------------------------------------
!EndRegion: Data Structures
! ------------------------------------------------------------------------------
!Region ----------  Compiler ----------
! ---------------------------------------------------------------------------------------
! Compiler data structures
! If structures in clacomp.hpp should change, then change here to match.
! (At time of writing these structures are compatible from Clarion 8 to Clarion 11.1)
! ---------------------------------------------------------------------------------------
!* This part of the  file defines several data structures and classes such as StrDesc, Cla_KEYCOMP,
! * Cla_KEYDESC, Cla_MEMODESC, Cla_FileCB, Cla_VCBBLK, Cla_NetVCBBLK, and Cla_FCBBLK. These are
! * used to represent various components of the Clarion runtime library, including strings,
! * keys, memos, and files.
!
! ------------------------------
Drv_Transaction       Group,TYPE
Outer                   &Drv_Transaction
Thread                  Long
Driver                  Long                ! Address of driver pipe function
Files                   Long
!OtherFileLogs           Group(Drv_LOGRECORD),Dim(100)    ! up to 100 files are allowed in the LOGOUT statement, so this is 100* size(Drv_LOGRECORD)
!                        End
                      End

Drv_LOGRECORD         Group,TYPE            ! aka Drv_FBlock
trn                     &Drv_Transaction
fcb                     &Drv_FCB            ! long
acc_mode                long                ! Access Mode as set by OPEN. STATUS command reads this value directly
logout                  long                ! These are Opcodes, which are set if the driver supports these operations.
rollback                long                !   "
commit                  long                !   "
lock                    long                !   "
unlock                  long                !   "
logoutPriority          ushort
                      End



! ------------------------------
! strings
! ------------------------------
Cla_StrDesc        Group,type
str                  long   ! address to string
len                  long
                   End

! ------------------------------
! keys
! ------------------------------
Cla_KEYCOMP        Group,Type            !   // Key Component Structure
fld_num              Long                !   // field number in record structure (-ve = descending)
                   End

Cla_KEYDESC        Group,Type
pname                like(Cla_StrDesc)   ! // physical key name
lname                like(Cla_StrDesc)   ! // label name for key
rt_kdesc             long                ! void * ! // additional runtime key info
key_attr             long                ! // attribute of key
num_comps            byte                ! // number of components for key
comps                long                !&Cla_KEYCOMP    ! // pointer to components
parent               long                !&Cla_FCBBLK     ! // pointer to owning file
padding1             byte
padding2             byte
padding3             byte
                   End

! // key_attr flags
Cla_DUP      Equate(01h)    !// key allows duplicates
Cla_OPT      Equate(02h)    !// suppress creation of keys with null value
Cla_NOCASE   Equate(04h)    !// key values are case insensitive
Cla_AUTOINC  Equate(08h)    !// 2 or 4 bytes autoincremented key
Cla_PRIMARY  Equate(10h)    !// primary key

! // The following key type is a clarion key type
Cla_Key        Equate(0000h)  !// key is a key
Cla_Index       Equate(4000h)  !// key is a external index
Cla_DynIndex    Equate(8000h)  !// key is a dynamic external index

!------------------------------------------------------------------
! Memos
!------------------------------------------------------------------

Cla_MEMODESC       Group,Type       ! // Memo Descriptor Structure
memo_name            like(Cla_StrDesc),pre(mn)  ! // field name of memo
memo_label           like(Cla_StrDesc),pre(ml)  ! // label name of memo
memo_data            long !void *   ! // pointer to memo data area
rt_mdesc             long !void *   ! // additional runtime memo info
memo_num             byte           ! // runtime memo number
memo_attr            byte           ! // indicates memo or image
memo_size            ulong          ! // total size of memo
padding1             byte
padding2             byte
                   End

! memo_attr values

Cla_Memo    equate(01)
Cla_Blob    equate(05)
Cla_Binary  equate(02)


!------------------------------------------------------------------
! Files
!------------------------------------------------------------------
! all the control blocks are derived from this, which one is in play is determined by the size
Cla_FileCB         Group,Type
cbSize               long                   ! // (compiler) Size of control block structure
pipe                 long  ! Cla_PIPE_FUNC  ! // (compiler) pointer to pipe function
patcher              long  ! PatchProc *    ! // (compiler) pointer to CB patch procedure
rblock               long  ! void *         ! // (runtime)  FILE/VIEW drivers runtime block . Object pointer goes in here. for traditional driver this is a &Drv_FCB
                   End

!  // VIEW Control Block
Cla_VCBBLK         Group(Cla_FileCB),Type
ViewDescriptor       long                   ! &cstring
FileIndex            long                   ! void ** ; pointer to an aray of (file) pointers
filter               long                   ! &cstring
order                long                   ! &cstring
                   End

! // FILE Control Block Structure
Cla_FCBBLK         Group(Cla_FileCB),type                                                             !16
phyname              like(Cla_StrDesc)  !                 // (compiler) physical filename
drvstr               like(Cla_StrDesc)  !                 // (compiler) file driver string
oname                like(Cla_StrDesc)  !                 // (compiler) owner name for file            !40
rec_buf              long               ! void *          // (compiler) pointer to record buffer
rec_len              long               !                 // (compiler) record length
t_desc               long               ! void *          // (compiler) pointer to RECORD type desc.
k_desc               long               ! Cla_KEYDESC **  // (compiler) pointer to block of KEY point.
m_desc               long               ! Cla_MEMODESC ** // (compiler) pointer to block of MEMO point.    !60
num_keys             byte               !                 // (compiler) number of keys in this file
num_memos            byte               !                 // (compiler) number of memos in this file
fil_attr             byte               !                 // (compiler) file attribute
fil_flags            byte               !                 // (runtime)  file flags                        !64
locale               long               !                 // (compiler) locale id
codepage             long               !                 // (compiler) codepage
fblock               &Drv_LOGRECORD     ! void *          // (runtime)  associated data. NEW'd when file is opened for first time on this thread.
dynPipe              long               ! Cla_FILE_FUNC   // (runtime)  pointer to dynamic file support, if file created with NEW(File)
dynBlock             long               ! void *          // (runtime)  dynPipe's rblock
                   End

!// fil_attr flags
FILOWN        Equate(01h)           ! // owner
FILCRYP       Equate(02h)           ! // records are encrypted
FILCREA       Equate(04h)           ! // file can be created
FILRECL       Equate(08h)           ! // reclaim unused space
FILTHRD       Equate(10h)           ! // file is threaded
FILOEM        Equate(20h)           ! // String data translated to OEM character set
FILCD         Equate(40h)           ! // CD-ROM attribute

!// fil_flags flags
FILRPC        Equate(01h)           ! // file is remote
FILNOTRACE    Equate(02h)           ! // suppress tracing
FILPATCHED    Equate(04h)           ! // FCB structure has been patched

!EndRegion: Compiler


!Region ----------  UFO ----------
! From Mike Duglas on C.L.C. 2010-06-18 - in "Type of variable" thread.
! The interface was originally by Oleg Rudenko
driver:iUFO          INTERFACE,TYPE
_Type                  PROCEDURE(LONG _UfoAddr),LONG       !+00h Type of UFO
ToMem                  PROCEDURE                           !+04h
FromMem                PROCEDURE                           !+08h
OldFromMem             PROCEDURE                           !+0Ch
Pop                    PROCEDURE(LONG _UfoAddr)            !+10h Get a value from string stack
Push                   PROCEDURE(LONG _UfoAddr)            !+14h Put a vaule to string stack
DPop                   PROCEDURE(LONG _UfoAddr)            !+18h Get a value from DECIMAL stack
DPush                  PROCEDURE(LONG _UfoAddr)            !+1Ch Put a vaule to DECIMAL stack
_Real                  PROCEDURE(LONG _UfoAddr),REAL       !+20h Get a value as REAL
_Long                  PROCEDURE(LONG _UfoAddr),LONG       !+24h Get a value as LONG
_Free                  PROCEDURE(LONG _UfoAddr)            !+28h Disposes memory and frees a reference (sets it to NULL)
_Clear                 PROCEDURE                           !+2Ch Clears a variable
_Address               PROCEDURE(LONG _UfoAddr),LONG       !+30h Returns an address of a variable
AssignLong             PROCEDURE                           !+34h Assign LONG value
AssignReal             PROCEDURE                           !+38h Assign REAL value
AssignUFO              PROCEDURE                           !+3Ch Assign a value to another UFO object.
AClone                 PROCEDURE(LONG _UfoAddr),LONG       !+40h Returns a clone of this UFO object.
Select                 PROCEDURE                           !+44h For arrays and strings, _Var [Ptr] is equivalent
Slice                  PROCEDURE                           !+48h For strings, equivalent to _Var [Ptr1: Ptr2]
Designate              PROCEDURE                           !+4Ch Returns group field as UFO object
_Max                   PROCEDURE(LONG _UfoAddr),LONG       !+50h Number of elements in first dimension of an array
_Size                  PROCEDURE(LONG _UfoAddr),LONG       !+54h Size of an object
BaseType               PROCEDURE(LONG _UfoAddr),LONG       !+58h
DistinctUpper          PROCEDURE                           !+5Ch
DistinctsUFO           PROCEDURE                           !+60h
DistinctsLong          PROCEDURE                           !+64h
Cleared                PROCEDURE(LONG _UfoAddr)            !+68h Destroyed?
IsNull                 PROCEDURE(LONG _UfoAddr),LONG       !+6Ch was an object disposed?
OEM2ANSI               PROCEDURE(LONG _UfoAddr)            !+70h
ANSI2OEM               PROCEDURE(LONG _UfoAddr)            !+74h
_Bind                  PROCEDURE(LONG _UfoAddr)            !+78h bind all fields of a group
_Add                   PROCEDURE                           !+7Ch
Divide                 PROCEDURE                           !+80h
Hash                   PROCEDURE(LONG _UfoAddr),LONG       !+84h Calc CRC
SetAddress             PROCEDURE                           !+88h sets the address of a variable
Match                  PROCEDURE                           !+8Ch compares the type and the size of a field with a field of ClassDesc structure
Identical              PROCEDURE                           !+90h
Store                  PROCEDURE                           !+94h Writes the value of an object into the memory address
                     END

!EndRegion: UFO
