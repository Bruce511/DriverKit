!------------------------------------------------------------------------------------------------
!   CapeSoft Clarion File Driver Kit classes are copyright © 2025 by CapeSoft                   !
!   Docs online at : https://capesoft.com/docs/Driverkit/ClarionObjectBasedDrivers.htm
!   Released under MIT License
!------------------------------------------------------------------------------------------------

! This module is the main module for a driver along with the accompaning ClaLit2.Exp file 
! Note the Conditional Compile Symbols in the Project are set;   DRVLM=>1;DRVDM=>0;DRVLITE2LM=>1;DRVLITE2DM=>0
! This module is sometimes known as the "thunking" module as it's basically a thunk between the compiler call and the class.
!------------------------------------------------------------------------------------------------
! To build a new driver based on this file;
! 1. Clone this file to your own CLW name   
! 2. Adjust the set of equates in block below
! 3. Your Driver Class Name should be used in place of SQLite2Driver 
! 4. ShortName should be set to your DriverPrefix. Suggest keep it as 3 letters. 
! 5. The DRIVER_HAS equates can be set to YES or NO. HOWEVER the chr lines in the TypeDescription must be piped in or out to match
! 6. The SQLite2DriverGroup fields should be set as desired by your driver. Care should be taken with this group not to change any sizes.
! 7. ClaLit2.Exp should cloned to match your DLL Name, and the functions in there named to match your ShortName   
! 8. The project should have appropriate "Condiional Compilation Symbols". In this case DRVLM=>1;DRVDM=>0;DRVLITE2LM=>1;DRVLITE2DM=>0
!------------------------------------------------------------------------------------------------

  PROGRAM

! When you change LongName, to be unique for your driver, then adjust it in the EXP file as well.

ShortName    Equate('LIT2')                                                        ! 4 Characters long. If the length is changed, then adjust dll_name and dsi_name below
LongName     Equate('SQLite2')                                                     ! Spaces Not Welcome
DriverName   Equate(LongName & '<0>{13}')                                          ! Maintain length as exactly 20 characters
Copyright    Equate('(c) 2025 by CapeSoft<0>{20}')                                 ! Maintain length as exactly 40 chars
DriverDesc   Equate('SQLite2 {23}')                                                ! Maintain length as exactly 30 characters
DLLName      Equate('CLA'&ShortName&'.DLL<0>')                                     ! Maintain length as exactly 12 characters
DSIDLLNAME   Equate('CLA'&ShortName&'S.DLL')                                       ! Maintain length as exactly 12 characters
TDescAddress Equate(00a5282ch)

  MAP
    SQLite2DriverPipe(Long pOpCode, long pClaFCB, long pVarList),long,name(LongName)   
    SQLite2DriverPipeView(Long pOpCode, Long pClaVCB, long pVarList),long
    SQLite2DriverSetObject(Long pOpCode, Long pClaFCB, long pVarList),Long
    SQLite2DriverSetObjectView(Long pOpCode, Long pClaVCB, long pVarList),Long
    !
    module('windows')
      ods(*cstring msg), raw, pascal, name('OutputDebugStringA')
    end    
  END             
  
  include('driver.inc'),once
  include('SQLite2DriverClass.Inc'),once
  
dbg              cstring(255),auto
YES                                 Equate(1)
NO                                  Equate(0)
BOTH                                Equate(3)

! these are convenience equates which are used as "defaults" for the features.
! setting them here can be a quick way of seeing ones below. However the driver
! can still set any feature to YES or NO if desired.
!
! When adding and removing features, the TypeDescriptor must be changed to match.     

DRIVER_HAS_KEYS                     Equate(YES)
DRIVER_HAS_BLOBS                    Equate(YES)   ! memos and blobs are treated as equivalent. 
DRIVER_HAS_VIEWS                    Equate(YES)
DRIVER_HAS_TRANSACTIONS             Equate(YES)
DRIVER_HAS_SQL                      Equate(YES)   
DRIVER_HAS_NULLS                    Equate(YES)
DRIVER_HAS_STATE                    Equate(YES)

! These are capabilities of the driver. Some use the defaults declared above, but they are
! just defaults. Any driver is free to support any subset of features they like.                         
!
! When adding and removing features, the TypeDescriptor must be changed to match.      

DRIVER_HAS_ADD                      Equate(YES)
DRIVER_HAS_ADDfilelen               Equate(YES)
DRIVER_HAS_APPEND                   Equate(YES)
DRIVER_HAS_APPENDlen                Equate(YES)
DRIVER_HAS_BLOB_DO_PROPERTY         Equate(DRIVER_HAS_BLOBS)
DRIVER_HAS_BLOBS_GETPROPERTY        Equate(DRIVER_HAS_BLOBS)
DRIVER_HAS_BLOBS_SETPROPERTY        Equate(DRIVER_HAS_BLOBS)
DRIVER_HAS_BLOBS_SIZE               Equate(DRIVER_HAS_BLOBS)
DRIVER_HAS_BLOBS_TAKE               Equate(DRIVER_HAS_BLOBS)
DRIVER_HAS_BLOBS_YIELD              Equate(DRIVER_HAS_BLOBS)
DRIVER_HAS_BOF                      Equate(YES)
DRIVER_HAS_BUFFER                   Equate(YES)
DRIVER_HAS_BUILDdyn                 Equate(DRIVER_HAS_KEYS)
DRIVER_HAS_BUILDdynfilter           Equate(DRIVER_HAS_KEYS)
DRIVER_HAS_BUILDfile                Equate(DRIVER_HAS_KEYS)
DRIVER_HAS_BUILDkey                 Equate(DRIVER_HAS_KEYS)
DRIVER_HAS_BULK_READ_ON             Equate(YES) 
DRIVER_HAS_BULK_READ_OFF            Equate(YES)  
DRIVER_HAS_BYTES                    Equate(YES)
DRIVER_HAS_CALLBACK                 Equate(YES)    
DRIVER_HAS_CLEARfile                Equate(YES)
DRIVER_HAS_CLOSE                    Equate(YES)
DRIVER_HAS_COMMITdrv                Equate(DRIVER_HAS_TRANSACTIONS)
DRIVER_HAS_CONNECT                  Equate(DRIVER_HAS_SQL) 
DRIVER_HAS_COPY                     Equate(YES)
DRIVER_HAS_CREATE                   Equate(YES)
DRIVER_HAS_DELETE                   Equate(YES)
DRIVER_HAS_DESTROYf                 Equate(YES)
DRIVER_HAS_DO_PROPERTY              Equate(YES)
DRIVER_HAS_DUPLICATE                Equate(DRIVER_HAS_KEYS)
DRIVER_HAS_DUPLICATEkey             Equate(DRIVER_HAS_KEYS)
DRIVER_HAS_EMPTY                    Equate(YES)
DRIVER_HAS_ENDTRAN                  Equate(DRIVER_HAS_TRANSACTIONS)
DRIVER_HAS_EOF                      Equate(YES)
DRIVER_HAS_EXCEEDS_RECS             Equate(YES) 
DRIVER_HAS_FIXFORMAT                Equate(YES)
DRIVER_HAS_FLUSH                    Equate(YES)
DRIVER_HAS_FREESTATE                Equate(DRIVER_HAS_STATE)
DRIVER_HAS_GETfilekey               Equate(DRIVER_HAS_KEYS)
DRIVER_HAS_GETfileptrlen            Equate(YES)
DRIVER_HAS_GETfileptr               Equate(YES)
DRIVER_HAS_GETkeyptr                Equate(DRIVER_HAS_KEYS)
DRIVER_HAS_GETNULLS                 Equate(DRIVER_HAS_NULLS)
DRIVER_HAS_GET_PROPERTY             Equate(YES)
DRIVER_HAS_GETSTATE                 Equate(DRIVER_HAS_STATE)
DRIVER_HAS_KEY_DOPROPERTY           Equate(DRIVER_HAS_KEYS)
DRIVER_HAS_KEY_SETPROPERTY          Equate(DRIVER_HAS_KEYS)
DRIVER_HAS_KEY_GETPROPERTY          Equate(DRIVER_HAS_KEYS)
DRIVER_HAS_HOLDfile                 Equate(YES)
DRIVER_HAS_HOLDfilesec              Equate(YES)
DRIVER_HAS_LOCKfile                 Equate(NO)
DRIVER_HAS_LOCKfilesec              Equate(NO)
DRIVER_HAS_LOGOUTdrv                Equate(DRIVER_HAS_TRANSACTIONS)
DRIVER_HAS_NAME                     Equate(YES)
DRIVER_HAS_NEXT                     Equate(YES)
DRIVER_HAS_NOMEMO                   Equate(DRIVER_HAS_BLOBS)
DRIVER_HAS_NULL                     Equate(DRIVER_HAS_NULLS)
DRIVER_HAS_OPEN                     Equate(YES)
DRIVER_HAS_PACK                     Equate(DRIVER_HAS_KEYS)
DRIVER_HAS_POINTERfile              Equate(YES)
DRIVER_HAS_POINTERkey               Equate(DRIVER_HAS_KEYS)
DRIVER_HAS_POSITIONfile             Equate(YES)
DRIVER_HAS_POSITIONkey              Equate(DRIVER_HAS_KEYS)
DRIVER_HAS_PREV                     Equate(YES)
DRIVER_HAS_PUT                      Equate(YES)
DRIVER_HAS_PUTfileptr               Equate(YES)
DRIVER_HAS_PUTfileptrlen            Equate(YES)
DRIVER_HAS_QUERYKEY                 Equate(DRIVER_HAS_KEYS)
DRIVER_HAS_QUERYVIEW                Equate(DRIVER_HAS_VIEWS)
DRIVER_HAS_RECORDSfile              Equate(YES)
DRIVER_HAS_RECORDSkey               Equate(DRIVER_HAS_KEYS)
DRIVER_HAS_REGETfile                Equate(YES)
DRIVER_HAS_REGETkey                 Equate(DRIVER_HAS_KEYS)
DRIVER_HAS_REGISTER                 Equate(YES)    
DRIVER_HAS_RELEASE                  Equate(YES)
DRIVER_HAS_REMOVE                   Equate(YES)
DRIVER_HAS_RENAME                   Equate(YES)
DRIVER_HAS_RESETfile                Equate(YES)
DRIVER_HAS_RESETkey                 Equate(DRIVER_HAS_KEYS)
DRIVER_HAS_RESETviewf               Equate(DRIVER_HAS_VIEWS)
DRIVER_HAS_RESTORESTATE             Equate(DRIVER_HAS_STATE)
DRIVER_HAS_ROLLBACKdrv              Equate(DRIVER_HAS_TRANSACTIONS)
DRIVER_HAS_SEND                     Equate(YES)
DRIVER_HAS_SETfile                  Equate(YES)
DRIVER_HAS_SETfilekey               Equate(DRIVER_HAS_KEYS)
DRIVER_HAS_SETfileptr               Equate(YES)
DRIVER_HAS_SETkey                   Equate(DRIVER_HAS_KEYS)
DRIVER_HAS_SETkeykeyptr             Equate(DRIVER_HAS_KEYS)
DRIVER_HAS_SETkeykey                Equate(DRIVER_HAS_KEYS)
DRIVER_HAS_SETkeyptr                Equate(DRIVER_HAS_KEYS)
DRIVER_HAS_SETviewfields						Equate(DRIVER_HAS_VIEWS)
DRIVER_HAS_SETNULL                  Equate(DRIVER_HAS_NULLS)
DRIVER_HAS_SETNULLS                 Equate(DRIVER_HAS_NULLS)
DRIVER_HAS_SETNONNULL               Equate(DRIVER_HAS_NULLS)
DRIVER_HAS_SET_PROPERTY             Equate(YES)
DRIVER_HAS_SHARE                    Equate(YES)
DRIVER_HAS_SKIP                     Equate(YES)
DRIVER_HAS_SQL_CALLBACK             Equate(DRIVER_HAS_SQL)
DRIVER_HAS_START_BUILD              Equate(DRIVER_HAS_KEYS)    
DRIVER_HAS_STARTTRAN                Equate(DRIVER_HAS_TRANSACTIONS)
DRIVER_HAS_STREAM                   Equate(YES)
DRIVER_HAS_UNFIXFORMAT              Equate(YES)
DRIVER_HAS_UNLOCK                   Equate(YES)
DRIVER_HAS_WATCH                    Equate(YES)
DRIVER_HAS_WHO_ARE_YOU              Equate(YES)                           

! These are the data types for the driver. The driver is free to support any number 
! of data types. If you change values here they must be changed in the Type Descriptor 
! section below.                  
DRIVER_HAS_ANY              Equate(NO)  ! 
DRIVER_HAS_BFLOAT4          Equate(NO) !  /* IBM Basic 4 byte float             */
DRIVER_HAS_BFLOAT8          Equate(NO) !  /* IBM Basic 8 byte float             */
DRIVER_HAS_BLOB             Equate(YES) !  /* Blob                               */
DRIVER_HAS_BYTE             Equate(YES) !  /* Signed 1 byte binary               */
DRIVER_HAS_CSTRING          Equate(YES) !  /* C string (trailing null)           */
DRIVER_HAS_DATE             Equate(YES) !  /* 4 Byte Binary YYMD                 */
DRIVER_HAS_DECIMAL          Equate(YES) !  /* Clarion packed decimal             */
DRIVER_HAS_GROUP            Equate(YES) ! 
DRIVER_HAS_LONG             Equate(YES) !  /* Signed 4 byte binary               */
DRIVER_HAS_MEMO             Equate(YES) !  /* Memo                               */
DRIVER_HAS_PDECIMAL         Equate(YES) !  /* IBM Packed Decimal                 */
DRIVER_HAS_PSTRING          Equate(YES) !  /* Pascal string (leading len ind)    */
DRIVER_HAS_REAL             Equate(YES) !  /* Signed 8 byte float                */
DRIVER_HAS_SHORT            Equate(YES) !  /* Signed 2 byte binary               */       
DRIVER_HAS_SIGNED           Equate(NO)  ! 
DRIVER_HAS_SREAL            Equate(YES) !  /* Signed 4 byte float                */
DRIVER_HAS_STRING           Equate(YES) !  /* ASCII sequence of characters       */   Adds PICTURE as well.
DRIVER_HAS_TIME             Equate(YES) !  /* 4 Byte Binary HMSH                 */
DRIVER_HAS_TYPE             Equate(NO) ! 
DRIVER_HAS_ULONG            Equate(YES) !  /* Unsigned 4 byte binary             */
DRIVER_HAS_USHORT           Equate(YES) !  /* Unsigned 2 byte binary             */
DRIVER_HAS_USIGNED          Equate(NO)  ! 

! These features make up the Attribute value in the DRVREG structure.  
! Some of them are inherited from settings above, however any can be set any way the driver supports.
DRIVER_HAS_createfile Equate(00000001h * DRIVER_HAS_CREATE) ! :1; // supports create attribute
DRIVER_HAS_owner      Equate(00000002h * YES) ! :1; // owner attribute ?
DRIVER_HAS_encrypt    Equate(00000004h * YES) ! :1; // data encryption ?
DRIVER_HAS_reclaim    Equate(00000008h * YES) ! :1; // reclaim attribute ?

DRIVER_HAS_keys_      Equate(00000010h * DRIVER_HAS_KEYS) ! :1; // keys supported ?

! uncomment 1, and only 1, of these 3. If driver does not support keys, then uncomment the first.
!DRIVER_HAS_kseq  equate(0)       ! only asc
DRIVER_HAS_kseq  equate(20h)     ! can be asc/des mixed
!DRIVER_HAS_kseq   equate(40h)     ! can be asc or dsc, not mixed

DRIVER_HAS_kunique    Equate(00000080h * YES * DRIVER_HAS_KEYS) ! :1; // key unique key supported ?

DRIVER_HAS_kcase      Equate(00000100h * YES * DRIVER_HAS_KEYS) ! :1; // key case sensative support ?
DRIVER_HAS_kxnulls    Equate(00000200h * YES * DRIVER_HAS_KEYS) ! :1; // key exclude nulls supported ?
DRIVER_HAS_indexes    Equate(00000400h * YES * DRIVER_HAS_KEYS) ! :1; // indexes supported ?

! uncomment 1, and only 1, of these 3. If driver does not support keys, then uncomment the first.
!DRIVER_HAS_iseq  equate(0)       ! only asc
DRIVER_HAS_iseq  equate(00000800h)     ! can be asc/des mixed
!DRIVER_HAS_iseq   equate(00001000h)     ! can be asc or dsc, not mixed
            
DRIVER_HAS_icase      Equate(00002000h * YES * DRIVER_HAS_KEYS) ! :1; // index case sensative support ?
DRIVER_HAS_ixnulls    Equate(00004000h * YES * DRIVER_HAS_KEYS) ! :1; // index exclude nulls supported ?
DRIVER_HAS_dynind     Equate(00008000h * YES * DRIVER_HAS_KEYS) ! :1; // dynamic indexes supported ?
                                     
! uncomment 1, and only 1, of these 3. If driver does not support keys, then uncomment the first.
!DRIVER_HAS_dseq  equate(0)       ! only asc
DRIVER_HAS_dseq  equate(00010000h)     ! can be asc/des mixed
!DRIVER_HAS_dseq   equate(00020000h)     ! can be asc or dsc, not mixed

DRIVER_HAS_dcase      Equate(00040000h * YES * DRIVER_HAS_KEYS) ! :1; // dyn index case sensative support ?
DRIVER_HAS_dxnulls    Equate(00080000h * YES * DRIVER_HAS_KEYS) ! :1; // dyn index exclude nulls supported ?

DRIVER_HAS_memos      Equate(00100000h * DRIVER_HAS_BLOBS) ! :1; // memos supported ?
DRIVER_HAS_memobin    Equate(00200000h * DRIVER_HAS_BLOBS) ! :1; // memos binary supported ?
DRIVER_HAS_sql_       Equate(00400000h * DRIVER_HAS_SQL) ! :1; // SQL file driver?
DRIVER_HAS_oem        Equate(00800000h * YES) ! :1; // ANSI to OEM support

DRIVER_HAS_logalias   Equate(01000000h * YES) ! :1; // logout file and alias?
DRIVER_HAS_dsi        Equate(02000000h * NO) ! :1; // synchroniser supported ?
DRIVER_HAS_import     Equate(04000000h * NO) ! :1; // can do an import
DRIVER_HAS_locale     Equate(08000000h * NO) ! :1; // supports locale attribute

! this equate just counts how many operations have been turned on. It does not need to be changed, 
! unless new opcodes are added.                    
NUM_DRIVER_OPS          Equate(|
                        + DRIVER_HAS_ADD                     |
                        + DRIVER_HAS_ADDfilelen              |
                        + DRIVER_HAS_APPEND                  |
                        + DRIVER_HAS_APPENDlen               |
                        + DRIVER_HAS_BLOB_DO_PROPERTY        |
                        + DRIVER_HAS_BLOBS_GETPROPERTY       |
                        + DRIVER_HAS_BLOBS_SETPROPERTY       |
                        + DRIVER_HAS_BLOBS_SIZE              |
                        + DRIVER_HAS_BLOBS_TAKE              |
                        + DRIVER_HAS_BLOBS_YIELD             |
                        + DRIVER_HAS_BOF                     |
                        + DRIVER_HAS_BUFFER                  |
                        + DRIVER_HAS_BUILDdyn                |
                        + DRIVER_HAS_BUILDdynfilter          |
                        + DRIVER_HAS_BUILDfile               |
                        + DRIVER_HAS_BUILDkey                |
                        + DRIVER_HAS_BULK_READ_ON            |
                        + DRIVER_HAS_BULK_READ_OFF           |
                        + DRIVER_HAS_BYTES                   |
                        + DRIVER_HAS_CALLBACK                |  
                        + DRIVER_HAS_CLEARfile               |
                        + DRIVER_HAS_CLOSE                   |
                        + DRIVER_HAS_COMMITdrv               |
                        + DRIVER_HAS_CONNECT                 |
                        + DRIVER_HAS_COPY                    |
                        + DRIVER_HAS_CREATE                  |
                        + DRIVER_HAS_DELETE                  |
                        + DRIVER_HAS_DESTROYf                |
                        + DRIVER_HAS_DO_PROPERTY             |
                        + DRIVER_HAS_DUPLICATE               |
                        + DRIVER_HAS_DUPLICATEkey            |
                        + DRIVER_HAS_EMPTY                   |
                        + DRIVER_HAS_ENDTRAN                 |
                        + DRIVER_HAS_EOF                     |
                        + DRIVER_HAS_EXCEEDS_RECS            |
                        + DRIVER_HAS_FIXFORMAT               |
                        + DRIVER_HAS_FLUSH                   |
                        + DRIVER_HAS_FREESTATE               |
                        + DRIVER_HAS_GETfilekey              |
                        + DRIVER_HAS_GETfileptrlen           |
                        + DRIVER_HAS_GETfileptr              |
                        + DRIVER_HAS_GETkeyptr               |
                        + DRIVER_HAS_GETNULLS                |
                        + DRIVER_HAS_GET_PROPERTY            |
                        + DRIVER_HAS_GETSTATE                |  
                        + DRIVER_HAS_KEY_DOPROPERTY          |                        
                        + DRIVER_HAS_KEY_SETPROPERTY         |
                        + DRIVER_HAS_KEY_GETPROPERTY         |
                        + DRIVER_HAS_HOLDfile                |
                        + DRIVER_HAS_HOLDfilesec             |
                        + DRIVER_HAS_LOCKfile                |
                        + DRIVER_HAS_LOCKfilesec             |
                        + DRIVER_HAS_LOGOUTdrv               |
                        + DRIVER_HAS_NAME                    |
                        + DRIVER_HAS_NEXT                    |
                        + DRIVER_HAS_NOMEMO                  |
                        + DRIVER_HAS_NULL                    |
                        + DRIVER_HAS_OPEN                    |
                        + DRIVER_HAS_PACK                    | 
                        + DRIVER_HAS_POINTERfile             |
                        + DRIVER_HAS_POINTERkey              |
                        + DRIVER_HAS_POSITIONfile            | 
                        + DRIVER_HAS_POSITIONkey             | 
                        + DRIVER_HAS_PREV                    |
                        + DRIVER_HAS_PUT                     |
                        + DRIVER_HAS_PUTfileptr              | 
                        + DRIVER_HAS_PUTfileptrlen           |
                        + DRIVER_HAS_QUERYKEY                | 
                        + DRIVER_HAS_QUERYVIEW               | 
                        + DRIVER_HAS_RECORDSfile             | 
                        + DRIVER_HAS_RECORDSkey              |
                        + DRIVER_HAS_REGETfile               |
                        + DRIVER_HAS_REGETkey                |
                        + DRIVER_HAS_REGISTER                |
                        + DRIVER_HAS_RELEASE                 |
                        + DRIVER_HAS_REMOVE                  |
                        + DRIVER_HAS_RENAME                  |
                        + DRIVER_HAS_RESETfile               |
                        + DRIVER_HAS_RESETkey                |
                        + DRIVER_HAS_RESETviewf              |
                        + DRIVER_HAS_RESTORESTATE            |
                        + DRIVER_HAS_ROLLBACKdrv             |
                        + DRIVER_HAS_SEND                    | 
                        + DRIVER_HAS_SETfile                 | 
                        + DRIVER_HAS_SETfilekey              |
                        + DRIVER_HAS_SETfileptr              |
                        + DRIVER_HAS_SETkey                  |
                        + DRIVER_HAS_SETkeykeyptr            |
                        + DRIVER_HAS_SETkeykey               |
                        + DRIVER_HAS_SETkeyptr               |
                        + DRIVER_HAS_SETviewfields					 |
                        + DRIVER_HAS_SETNULL                 |
                        + DRIVER_HAS_SETNULLS                |
                        + DRIVER_HAS_SETNONNULL              |
                        + DRIVER_HAS_SET_PROPERTY            |
                        + DRIVER_HAS_SHARE                   |
                        + DRIVER_HAS_SKIP                    |
                        + DRIVER_HAS_SQL_CALLBACK            |
                        + DRIVER_HAS_START_BUILD             |  
                        + DRIVER_HAS_STARTTRAN               |
                        + DRIVER_HAS_STREAM                  |
                        + DRIVER_HAS_UNFIXFORMAT             |
                        + DRIVER_HAS_UNLOCK                  |
                        + DRIVER_HAS_WATCH                   | 
                        + DRIVER_HAS_WHO_ARE_YOU             |
                        )
                            
! this equate just counts how many types have been turned on. It does not need to be changed, 
! unless new types are added.                    
NUM_DRIVER_TYPES        Equate(|
                        + DRIVER_HAS_ANY           |  
                        + DRIVER_HAS_BFLOAT4       | 
                        + DRIVER_HAS_BFLOAT8       |   
                        + DRIVER_HAS_BLOB          |  
                        + DRIVER_HAS_BYTE          |
                        + DRIVER_HAS_CSTRING       |  
                        + DRIVER_HAS_DATE          |
                        + DRIVER_HAS_DECIMAL       |  
                        + DRIVER_HAS_GROUP         |
                        + DRIVER_HAS_LONG          |  
                        + DRIVER_HAS_MEMO          |  
                        + DRIVER_HAS_PDECIMAL      |  
                        + DRIVER_HAS_PSTRING       |  
                        + DRIVER_HAS_REAL          |  
                        + DRIVER_HAS_SHORT         |  
                        + DRIVER_HAS_SIGNED        | 
                        + DRIVER_HAS_SREAL         |  
                        + DRIVER_HAS_STRING        |  
                        + DRIVER_HAS_TIME          | 
                        + DRIVER_HAS_TYPE          | 
                        + DRIVER_HAS_ULONG         |   
                        + DRIVER_HAS_USHORT        |   
                        + DRIVER_HAS_USIGNED       |  
                        )

  
! The TypeDescriptor is very important to get correct as it is used by the IDE as well as your
! program. Things that are turned ON are left "as is". Things that are turned OFF have a PIPE (|)
! character at the front of the line. These pipes MUST match the equates set above.
! Because the address of the type descriptor has to be hard-coded into the DLL code itself, 
! two boundaries are added here to facilitate utilities to locate the address. They shoud remain
! unchanged. 
! The structure of the type descriptor is [number of opcodes],<opcodes>,[number of types],<types>,0
boundary1       string('CAP3S0FT')        
TypeDescriptor  String('' |  
                 & chr(NUM_DRIVER_OPS)         |
                 & chr(Opcode:ADD)             |  
                 & chr(Opcode:ADDfilelen)      |                    
                 & chr(Opcode:APPEND)          |   
                 & chr(Opcode:APPENDlen)       |   
                 & chr(Opcode:BLOB_DOPROPERTY) |  
                 & chr(Opcode:_BLOB_SETPROPERTY) |   
                 & chr(Opcode:_BLOB_GETPROPERTY) |   
                 & chr(Opcode:_BLOB_SIZE)      |     
                 & chr(Opcode:_BLOB_TAKE)      |     
                 & chr(Opcode:_BLOB_YIELD)     |                      
                 & chr(Opcode:BOF)             |   
                 & chr(Opcode:BUFFER)          |  
                 & chr(Opcode:BUILDdyn)        |   
                 & chr(Opcode:BUILDdynfilter)  |
                 & chr(Opcode:BUILDfile)       |
                 & chr(Opcode:BUILDkey)        |
                 & chr(Opcode:BULK_READ_ON)    |
                 & chr(Opcode:BULK_READ_OFF)   |                  
                 & chr(Opcode:BYTES)           |
                 & chr(Opcode:CALLBACK)        |
                 & chr(Opcode:CLEARfile)       |
                 & chr(Opcode:CLOSE)           |
                 & chr(Opcode:COMMITdrv)       |
                 & chr(Opcode:CONNECT)         |
                 & chr(Opcode:COPY)            |
                 & chr(Opcode:CREATE)          |
                 & chr(Opcode:DELETE)          |
                 & chr(Opcode:DESTROYf)        |
                 & chr(Opcode:DO_PROPERTY)     |   
                 & chr(Opcode:KEY_DOPROPERTY)  |   
                 & chr(Opcode:DUPLICATE)       |
                 & chr(Opcode:DUPLICATEkey)    |
                 & chr(Opcode:EMPTY)           |
                 & chr(Opcode:ENDTRAN)         | 
                 & chr(Opcode:EOF)            |                 
                 & chr(Opcode:EXCEEDS_RECS)    |
                 & chr(Opcode:FIXFORMAT)       |                 
                 & chr(Opcode:FLUSH)           |
                 & chr(Opcode:FREESTATE)       |  
                 & chr(Opcode:GETfilekey)      |
                 & chr(Opcode:GETfileptrlen)   |
                 & chr(Opcode:GETfileptr)      |
                 & chr(Opcode:GETkeyptr)       | 
                 & chr(Opcode:GETNULLS)       | 
                 & chr(Opcode:GET_PROPERTY)    |     
                 & chr(Opcode:GETSTATE)        |  
                 & chr(Opcode:KEY_GETPROPERTY) |    
                 & chr(Opcode:KEY_SETPROPERTY) |    
                 & chr(Opcode:HOLDfile)        |
                 & chr(Opcode:HOLDfilesec)     |
                 | & chr(Opcode:LOCKfile)        |
                 | & chr(Opcode:LOCKfilesec)     |
                 & chr(Opcode:LOGOUTdrv)       |
                 & chr(Opcode:NAME)            |
                 & chr(Opcode:NEXT)            | 
                 & chr(Opcode:NOMEMO)          | 
                 & chr(Opcode:NULL)            |                    
                 & chr(Opcode:OPEN)            |                   
                 & chr(Opcode:PACK)            |
                 & chr(Opcode:POINTERfile)     |
                 & chr(Opcode:POINTERkey)      |
                 & chr(Opcode:POSITIONfile)    |
                 & chr(Opcode:POSITIONkey)     |
                 & chr(Opcode:PREVIOUS)        |
                 & chr(Opcode:PUT)             |
                 & chr(Opcode:PUTfileptr)      |
                 & chr(Opcode:PUTfileptrlen)   |   
                 & chr(Opcode:QUERY_KEY)       |
                 & chr(Opcode:QUERY_VIEW)      |                 
                 & chr(Opcode:RECORDSfile)     |
                 & chr(Opcode:RECORDSkey)      |
                 & chr(Opcode:REGETfile)       |   
                 & chr(Opcode:REGETkey)        |   
                 & chr(Opcode:REGISTER)        |                 
                 & chr(Opcode:RELEASE)         | 
                 & chr(Opcode:REMOVE)          |
                 & chr(Opcode:RENAME)          | 
                 & chr(Opcode:RESETfile)       |
                 & chr(Opcode:RESETkey)        |   
                 & chr(Opcode:RESETviewf)      |
                 & chr(Opcode:RESTORESTATE)    |                  
                 & chr(Opcode:ROLLBACKdrv)     |                 
                 & chr(Opcode:SEND)            |
                 & chr(Opcode:SETfile)         |
                 & chr(Opcode:SETfilekey)      | 
                 & chr(Opcode:SETfileptr)      |
                 & chr(Opcode:SETkey)          |
                 & chr(Opcode:SETkeykeyptr)    |
                 & chr(Opcode:SETkeykey)       |
                 & chr(Opcode:SETkeyptr)       |   
                 & chr(Opcode:SETviewfields)   |
                 & chr(Opcode:SETNULL)         |    
                 & chr(Opcode:SETNULLS)        |   
                 & chr(Opcode:SETNONNULL)      |    
                 & chr(Opcode:SET_PROPERTY)    |                    
                 & chr(Opcode:SHARE)           |
                 & chr(Opcode:SKIP)            |
                 & chr(Opcode:SQLCALLBACK)     |  
                 & chr(Opcode:START_BUILD)     |
                 & chr(Opcode:STARTTRAN)       |                 
                 & chr(Opcode:STREAM)          |
                 & chr(Opcode:UNFIXFORMAT)     |
                 & chr(Opcode:UNLOCK)          |
                 & chr(Opcode:WATCH)           |   
                 & chr(Opcode:WHO_ARE_YOU)     |
                 |
                & chr(NUM_DRIVER_TYPES) |
                |& chr(ClaANY)          |
                |& chr(ClaBFLOAT4)       |
                |& chr(ClaBFLOAT8)       |
                & chr(ClaBLOB)          |
                & chr(ClaBYTE)          |
                & chr(ClaCSTRING)       |
                & chr(ClaDATE)          |
                & chr(ClaDECIMAL)       |
                & chr(ClaGROUP)         |
                & chr(ClaLONG)          |
                & chr(ClaMEMO)          |
                & chr(ClaPDECIMAL)      |
                & chr(ClaPSTRING)       |
                & chr(ClaREAL)          |
                & chr(ClaSHORT)         |
                |& chr(ClaSIGNED)       |
                & chr(ClaSREAL)         |
                & chr(ClaSTRING)        |
                & chr(ClaTIME)          |
                |& chr(ClaTYPE)         |
                & chr(ClaULONG)         |
                & chr(ClaUSHORT)        |
                |& chr(ClaUNSIGNED)     |
                & '<0>' )
boundary2       string('CAPESOF2')

! this is a combination of the driver attributes. It does not need to be changed.                                      
DRIVER_ATTRIBUTES    Equate(DRIVER_HAS_createfile + DRIVER_HAS_owner + DRIVER_HAS_encrypt + DRIVER_HAS_reclaim |
                          + DRIVER_HAS_keys_ + DRIVER_HAS_kseq + DRIVER_HAS_kunique | 
                          + DRIVER_HAS_kcase + DRIVER_HAS_kxnulls + DRIVER_HAS_indexes + DRIVER_HAS_iseq |
                          + DRIVER_HAS_icase + DRIVER_HAS_ixnulls + DRIVER_HAS_dynind |
                          + DRIVER_HAS_dseq + DRIVER_HAS_dcase + DRIVER_HAS_dxnulls |
                          + DRIVER_HAS_memos + DRIVER_HAS_memobin + DRIVER_HAS_sql_ + DRIVER_HAS_oem |
                          + DRIVER_HAS_logalias + DRIVER_HAS_dsi + DRIVER_HAS_import + DRIVER_HAS_locale )
              
SQLite2DriverGroup  Group,name(LongName & '$DrvReg')
raw_name                cstring(DriverName)    ! cstring(21)    ! changing this name after you've got tables using this driver is not a good idea.
dll_name                cstring(DLLName)       ! cstring(13)
copywrite               cstring(Copyright)  ! cstring(41)
desc                    cstring(DriverDesc)   ! cstring(31)  ! this appears in Driver Registry list
pipeFunctionAddress     long(0)      !  Cla_PIPE_FUNC 
drvattr                 Group
attrval                   long(DRIVER_ATTRIBUTES)
reserved                  byte(0)
                        End
clastrlen               ushort(0feffh)      ! if supported, max clarion string length
cstrlen                 ushort(0fefeh)      ! max cstring length
reclen                  ushort(0feffh)      ! total record length - 64K max
clastrlen32             ulong(07fffffffh)   ! if supported, max clarion string length for 32bit apps
cstrlen32               ulong(07ffffffeh)   ! max cstring length for 32bit apps
reclen32                ulong(07ffffffeh)   ! total record length for 32bit apps
maxdims                 byte(0FFh)          ! total number of dimensions
maxkeys                 byte(255 * DRIVER_HAS_KEYS)           ! total keys and indeces - 255 max
maxmemos                byte(255 * DRIVER_HAS_BLOBS)          ! total memos - 255 max
memosize                short(65534)        ! maximum memo size
memosize32              ulong(07ffffffeh)   ! maximum memo size for 32bit apps
fldsize                 ulong(32)           ! size of the Drv_FLD structure
kcbsize                 ulong(21)           ! size of the Drv_KCB structure
mcbsize                 ulong(020h)         ! size of the Drv_MCB structure
fcbsize                 ulong(0e4h)         ! size of the Drv_FCB structure   !156
reserved1               byte,dim(12)        ! reserved allowing for sizes     
tdesc                   ulong(TDescAddress) ! pointer to type descriptor for functions and data types supported      !168
dsi_name                cstring(DsiDllName) !cstring(13)  !  dsi dll name
driverMeta              ulong(0)            ! DRV_META_FUNC
                     End

! The constructor in this class runs when the DLL loads. This is useful for setting addresses. 
SQLite2DriverOnLoadDll  Class
Construct                   Procedure()
                          End

  CODE

SQLite2DriverOnLoadDll.Construct  procedure()
  CODE
! these two lines prevent the linker from excluding the TypeDescriptor structure. 
  x# = boundary1 & TypeDescriptor & boundary2      !TypeDescriptor
  Assert(x#=0)  ! x# has to be used :)
! ---
  
?  dbg = '['&ShortName&']['&x#&'] [' & clip(DriverDesc) & '] DLL Loaded. NUM_DRIVER_OPS=' & NUM_DRIVER_OPS & ' NUM_DRIVER_TYPES=' & NUM_DRIVER_TYPES & ' DRIVER_ATTRIBUTES=' & DRIVER_ATTRIBUTES & ' Drv_FCB=' & size(Drv_FCB) ; ods(dbg)
! this assert attempts to catch any mistakes when setting the opcode, and type lists
  Assert(Size(TypeDescriptor) = NUM_DRIVER_OPS +  NUM_DRIVER_TYPES + 3, Size(TypeDescriptor) & ' <> ' & NUM_DRIVER_OPS & ' + ' & NUM_DRIVER_TYPES & ' + 3')  
  SQLite2DriverGroup.pipeFunctionAddress = address(SQLite2DriverPipe)  ! sets the address for the pipe function below.
  SQLite2DriverGroup.tdesc = address(TypeDescriptor) ! ! unfortunately this address is post-load, and so not the address we are looking for at compile time.
  
!---------------------------------------------------------------------------------  
SQLite2DriverPipe  Procedure(Long pOpCode, long pClaFCB, long pVarList)
ClaFCB        &Cla_FCBBLK,auto
DriverObject  &DriverFileSQLite2Class,auto  
Result        Long
  code   
  ClaFCB &= (pClaFCB)
  !dbg = '[' & ShortName & '] Driver Pipe: [' & pOpCode & '] ' & ' pClaFCB=' & pClaFCB & ' pVarList = ' & pVarList & ' rblock=' & ClaFCB.rblock ; ods(dbg)  
  
  case pOpCode 
  of Opcode:WHO_ARE_YOU
    ! doing this special case here, because the address is in scope here, but not in scope in the object.
    Return Address(SQLite2DriverPipe) 
  of Opcode:QUERY_VIEW  
    ! doing this special case here, because the address is in scope here, but not in scope in the object.
    Return Address(SQLite2DriverPipeView)
  of Opcode:DESTROYf
    ! if the object has not been initialized, then do a quick exit here
    If ClaFCB.rblock = 0     
      Return 0
    End      
  end  
  DriverObject &= (SQLite2DriverSetObject(pOpCode,pClaFcb,pVarList))
  If not DriverObject &= null
    Result = DriverObject.Pipe(pOpCode,pClaFCB,pVarList)
    Case pOpCode 
    of Opcode:DESTROYf
       ClaFCB.rblock = 0     
    End 
  End
  Return Result 

!---------------------------------------------------------------------------------  
SQLite2DriverPipeView  Procedure(Long pOpCode, Long pClaVCB, long pVarList)
ViewObject  &DriverViewSQlite2Class,auto  
!vcb         &Cla_VCBBLK,auto 
  code       
  !vcb &= (pClaVCB)
?  !dbg = '[' & ShortName & '] Driver View Pipe: [' & pOpCode & '] ' & ' pClaVCB=' & pClaVCB & ' pVarList = ' & pVarList ; ods(dbg)  
  ViewObject &= (SQLite2DriverSetObjectView(pOpCode,pClaVCB,pVarList))
  If not ViewObject &= null
    return ViewObject.Pipe(pOpCode,pClaVCB,pVarList)
  End
  Return 0
    
!---------------------------------------------------------------------------------  
! if this is the first sight of this structure, set the rblock to point to a new driver object.
! The program can fetch a handle to this object using whatever &= file{prop:object}  
! the program can replace this object using file{prop:object} = whatever
! the program object must be derived from the object type below.
SQLite2DriverSetObject  Procedure(Long pOpCode, Long pClaFCB, long pVarList)
ClaFCB        &Cla_FCBBLK,auto
DriverObject  &DriverFileSQlite2Class,auto
f             &File,auto
  Code
  ClaFCB &= (pClaFCB)
  If ClaFCB.rblock = 0    
    DriverObject &= New DriverFileSQlite2Class
    ClaFCB.rblock = Address(DriverObject)
    f &= (pClaFCB)  
    DriverObject.Init(f)                       
  Else
    DriverObject &= (ClaFCB.rblock)
  End             
  If DriverObject.TypeDescriptorAddress = 0
    DriverObject.TypeDescriptorAddress = address(TypeDescriptor)
  End    
  Return ClaFCB.rblock
  
!---------------------------------------------------------------------------------  
!---------------------------------------------------------------------------------  
! if this is the first sight of this structure, set the rblock to point to a new driver object.
! The program can fetch a handle to this object using whatever &= file{prop:object}  
! the program can replace this object using file{prop:object} = whatever
! the program object must be derived from the object type below.
SQLite2DriverSetObjectView  Procedure(Long pOpCode, Long pClaVCB, long pVarList)
ClaVCB        &Cla_VCBBLK,auto  
ViewObject    &DriverViewSQLite2Class,auto  ! In this example the root DriverClass is used. In a real driver the actual Driver Class will be used.
v             &View
  Code
  ClaVCB &= (pClaVCB)
  If ClaVCB.rblock = 0    
    ViewObject &= new DriverViewSQLite2Class
    v &= (pClaVCB)  
    ViewObject.Init(v)                   
    ClaVCB.rblock = address(ViewObject)
  Else
    ViewObject &= (ClaVCB.rblock)
  End             
  Return ClaVCB.rblock
!---------------------------------------------------------------------------------  
  
