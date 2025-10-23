!------------------------------------------------------------------------------------------------
!   CapeSoft Clarion File Driver Kit classes are copyright © 2025 by CapeSoft                   !
!   Docs online at : https://capesoft.com/docs/Driverkit/ClarionObjectBasedDrivers.htm
!   Released under MIT License
!------------------------------------------------------------------------------------------------

  include('Equates.Clw'),once
  include('DriverClass.Inc'),once

Dos:SetEndOfFile        Equate(-2)
Dos:SetStartOfFile      Equate(0)
Dos:RecordLength        Equate(-1)

!----------------------------------------------------------------------------------------------------------------------
DriverFileDos2Class     Class(DriverFileClass), Type, MODULE('Dos2DriverClass.Clw'),LINK('Dos2DriverClass.Clw',DRVDOS2LM), DLL(DRVDOS2DM)

! driver options
opt:Buffers               Long      !/FILEBUFFERS=2
opt:QuickScan             Byte      !/QUICKSCAN=ON
_ram                      &string   ! Used in Write To Disk. A property here to save time on each write.

! -----------------------------------------------------------------------------
! This block contain pointers which need to be cloned when doing a GETSTATE and RESTORESTATE
! Pointers cloned when State is saved, and restored
! if a pointer is added here then the StateQueueType needs to be updated, and code in SaveState / RestoreState /FreeState added

_buffer                   &String ! a big block of Ram. This maps to the file on disk (ie unconverted custom fields)


! -----------------------------------------------------------------------------
! This block contain properties which need to be copied when doing a GETSTATE and RESTORESTATE
! no pointers allowed in here.

__DOSSTATESTART           Byte                        ! do NOT move me
! properties
_hfile                    Long
_winerror                 Long

_bufferstart              BIGINT  ! the position in the file, where the buffer currently starts
_bufferend                BIGINT  ! the position in the file, where the buffer currently ends
_buffersize               Long
_bufferwholefile          Byte

! buffer performance properties, useful for measuring buffer performance
_diskreads                Long
_bufferhit                Long
_buffermiss               Long

! other
_filesize                 BIGINT  ! allow for files > 4 gigs.  REAL is good for about 4503 terabytes
diskpointer               BIGINT

_eof                      Byte
_bof                      Byte
_MemoryTable              Byte

__DOSSTATEEND             Byte                        ! do NOT move me
! -----------------------------------------------------------------------------

CONSTRUCT                 PROCEDURE()

! helper methods
_ConvertAccessMode        PROCEDURE(LONG pAccessmode),LONG,VIRTUAL
_ConvertShareMode         PROCEDURE(LONG pAccessmode),LONG,VIRTUAL
_ConvertError             PROCEDURE(LONG pWindowsErrorCode),LONG,VIRTUAL
_Read                     PROCEDURE(BIGINT pFilePointer, LONG pLength),VIRTUAL
_ReadDisk                 PROCEDURE(BIGINT pFilePointer),LONG,VIRTUAL
_WriteDisk                PROCEDURE(BIGINT pFilePointer, LONG pLength),LONG,VIRTUAL
_SetDisk                  PROCEDURE(BIGINT pFilePointer),LONG,VIRTUAL
_CopyBufferIntoRecord     PROCEDURE(BIGINT pFilePointer, BIGINT pBufferPos, LONG pLength),VIRTUAL
_ReadFromBuffer           PROCEDURE(BIGINT pFilePointer, LONG pLength),LONG,VIRTUAL
_BufferUpdate             PROCEDURE(BIGINT pFilePointer, LONG pAddr, Long pLength),VIRTUAL
_ExtendBuffer             PROCEDURE(Long pNewSize),VIRTUAL
_Get                      PROCEDURE(BIGINT pFilePointer, LONG Length),VIRTUAL
_ExpandName               PROCEDURE(),VIRTUAL
SetDriverOption           Procedure(String pOption, String pValue),STRING,Derived

! MUST Derive (and Override) methods
REPLACEOBJECT             PROCEDURE(LONG pOldObjectAddress),DERIVED

! File methods
BOF                       PROCEDURE(),LONG,DERIVED ! IMPLEMENTED
BUFFER                    PROCEDURE(UNSIGNED pPageSize=1, UNSIGNED pBehind=0, UNSIGNED pAhead=0, UNSIGNED pTimeout=0),DERIVED ! IMPLEMENTED
BYTES                     PROCEDURE(),BIGINT,DERIVED                                                                          ! LARGEFILE
CLOSE                     PROCEDURE(),DERIVED
COPY                      PROCEDURE(STRING pNewFileName, Long pOptions),DERIVED
CREATEFILE                PROCEDURE(),VIRTUAL    ! a synonym for CREATETABLE
CREATETABLE               PROCEDURE(),DERIVED
EMPTY                     PROCEDURE(),DERIVED
EOF                       PROCEDURE(),LONG,DERIVED
EXISTS                    PROCEDURE(String pTablename),LONG,PROC,DERIVED                                                      ! NEW
FILESIZE                  PROCEDURE(),BIGINT,VIRTUAL                                                                          ! NEW ! LARGEFILE
FLUSH                     PROCEDURE(),DERIVED
FREEBUFFER                PROCEDURE(),VIRTUAL                                                                                 ! NEW
GETSTATE                  PROCEDURE(Long pSaveBlob),LONG,DERIVED
LOCK                      PROCEDURE(LONG pSeconds),DERIVED
OPEN                      PROCEDURE(LONG AccessMode=022h),DERIVED
POINTER                   PROCEDURE(),BIGINT,DERIVED
RECORDS                   PROCEDURE(),BIGINT,DERIVED                                                                          ! LARGEFILE
REMOVE                    PROCEDURE(),DERIVED
RENAME                    PROCEDURE(STRING pNewFileName),DERIVED
REOPEN                    PROCEDURE(Long pAccessMode),DERIVED
RESTORESTATE              PROCEDURE(Long pState, Byte pBuffer),DERIVED
SEND                      PROCEDURE(STRING pMessage),STRING,PROC,DERIVED
UNLOCK                    PROCEDURE(),DERIVED

! Record Read methods
GET                       PROCEDURE(BIGINT pFilePointer),DERIVED                                                              ! LARGEFILE
GET                       PROCEDURE(BIGINT pFilePointer, LONG pLength),DERIVED
GET                       PROCEDURE(KEY pKeyLabel),DERIVED
GET                       PROCEDURE(KEY pKeyLabel, BIGINT pKeyPointer),DERIVED

! LARGEFILE
NEXT                      PROCEDURE(),DERIVED
PREVIOUS                  PROCEDURE(),DERIVED
REGET                     PROCEDURE(STRING pPosition),DERIVED
REGET                     PROCEDURE(KEY pKey, STRING pPosition),DERIVED
RESET                     PROCEDURE(STRING pPosition),DERIVED
SKIP                      PROCEDURE(BIGINT pCount),DERIVED                                                                     ! IMPLEMENTED ! LARGEFILE

! Record Write methods
ADD                       PROCEDURE(),DERIVED
ADD                       PROCEDURE(LONG pLength),DERIVED
APPEND                    PROCEDURE(),DERIVED
APPEND                    PROCEDURE(LONG pLength),DERIVED
PUT                       PROCEDURE(),DERIVED
PUT                       PROCEDURE(BIGINT pFilePointer),DERIVED
PUT                       PROCEDURE(BIGINT pFilePointer, LONG pLength),DERIVED
DELETE                    PROCEDURE(),DERIVED

! properties
GetPROP:Driver            PROCEDURE(),STRING,DERIVED
GetPROP:DriverVersion     PROCEDURE(),STRING,DERIVED
GetPROP:FileSize          PROCEDURE(),BIGINT,DERIVED
                        END

!----------------------------------------------------------------------------------------------------------------------
DriverViewDos2Class Class(DriverViewClass), Type, MODULE('Dos2DriverClass.Clw'),LINK('Dos2DriverClass.Clw',DRVDOS2LM), DLL(DRVDOS2DM)
              End
!----------------------------------------------------------------------------------------------------------------------
!Dos2MetaData       CLASS(DriverMetaData),Implements(IDrvMetaWindow), Type, MODULE('Dos2DriverClass.Clw'),LINK('Dos2DriverClass.Clw',DRVDOS2LM), DLL(DRVDOS2DM)
!! list of properties that the driver supports via the SEND command and File Driver String
!Buffers              Long
!QuickScan            Byte
!InMemory             Byte
!                   END
!----------------------------------------------------------------------------------------------------------------------


