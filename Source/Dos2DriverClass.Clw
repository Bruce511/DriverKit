!------------------------------------------------------------------------------------------------
!   CapeSoft Clarion File Driver Kit classes are copyright © 2025 by CapeSoft                   !
!   Docs online at : https://capesoft.com/docs/Driverkit/ClarionObjectBasedDrivers.htm
!   Released under MIT License
!------------------------------------------------------------------------------------------------

! the goal here is to be backwards compatible, but also "just work" on files > 2 gigs.
! when dealing with files > 2 gigs with the old driver, errors could be generated. Where possible the right
! action is taken here, the error is avoided. However Extended functions exist for
!   RECORDS(RECORDS64) where answer might be > 2 gigs.
!
! differences to DOS driver:
!   Driver supports files > 2 gigs in size.
!      Records: Works up to 2 billion records. Use Records64 if file record is very small, and file is very big.
!      Pointer: Works up to 2 billion bytes.   Use Pointer64 if file is > 2 gigs
!      Bytes: Works up to 2 billion records.   Use Bytes64 if file > 2 gigs
!
!   Newly-Supported commands: BUFFER
!   New commands : FREEBUFFER, FILESIZE
!   Different Behaviour: BYTES returns the FileSize when the file is Closed.
!                        ONLY thread-safe if ,THREAD. Files not marked as ,THREAD should regard the driver as not thread safe.

  member()
  map
    module('clarun')
       MemCpy(long dest, long src,  unsigned count), long, proc, name('_memcpy')
       MemSet(long dest, long char, unsigned count), long, proc, name('_memset')
    end
    module('windows')
      DosGetLastError(), ulong, raw, pascal, name('GetLastError')
      DosFormatMessage(long pFlags,long lpSource,long pMessageId,long pLanguageId,*cstring pBuffer,long pSize,long pVaList),long,Pascal,raw,name('FormatMessageA')
      DosCreateFile(*cstring lpFileName, long dwDesiredAccess, long dwSharedMode, long lpSecurityAttributes, |
                      long dwCreationDisposition, long dwFlagsAndAttributes, long hTemplateFile), long, raw, pascal, name('CreateFileA')
      DosCloseHandle(long hObject),long, proc, pascal, name('CloseHandle')
      DosReadFile(long hFile, *string lpBuffer, long nNumberOfBytesToRead, *long lpNumberOfBytesRead, long lpOverlapped), raw, long, pascal, name('ReadFile')
      DosWriteFile(long hFile, long lpBuffer, long nNumberOfBytesToWrite, *long lpNumberOfBytesWritten, |
                     long lpOverlapped), long, proc, raw, pascal, name('WriteFile')
      DosFindFirstFile(*cstring pFileName,Long rFileData), long, proc, raw, pascal, name('FindFirstFileA')
      DosGetFileSizeEx(long hFile,*Int64 FileSize), long, raw, pascal, name('GetFileSizeEx')
      DosSetFilePointerEx(long hFile,Int64 liDistanceToMove,*Int64 lpNewFilePointer,long dwMoveMethod), |
                      long, raw, pascal, proc, name('SetFilePointerEx')
      DosFlushFileBuffers(long hFile), long, pascal, name('FlushFileBuffers')
      DosDeleteFile(*cstring lpFileName), long, proc, raw, pascal, name('DeleteFileA')
      DosSetEndOfFile(long hFile),long, proc, raw, pascal, name('SetEndOfFile')
      DosMoveFileEx(*cstring pFromName, *cstring pToName, long pFlags),long, proc, raw, pascal, name('MoveFileExA')
      DosCopyFile(*cstring pOldName, *cstring pNewName, long pFailIfExists ),long, proc, raw, pascal, name('CopyFileA')
      DosLockFile(long hFile,uLong dwFileOffsetLow, ulong dwFileOffsetHigh, ulong nNumberOfBytesToLockLow, long nNumberOfBytesToLockHigh),long, proc, raw, pascal, name('LockFile')
      DosUnlockFile(long hFile,uLong dwFileOffsetLow, ulong dwFileOffsetHigh, ulong nNumberOfBytesToLockLow, long nNumberOfBytesToLockHigh),long, proc, raw, pascal, name('UnlockFile')
      DosSleep(Long pMilliseconds), raw, pascal, name('Sleep')
    end
  end

  include('Dos2DriverClass.Inc'),once
  include('errors.clw'),once
  include('AbFile.Equ'),once

Extensions     Equate('*.dos')
ExtensionName  Equate('Binary DOS files')

MAXULONG                       equate(4294967296)
MAXLONG                        equate(2147483647)

! Windows Equates
dos:GENERIC_ALL                equate(10000000h)
dos:GENERIC_READ               equate(80000000h)
dos:GENERIC_WRITE              equate(40000000h)
dos:FILE_DENY_ALL              equate(00000000h)
dos:FILE_SHARE_READ            equate(00000001h)
dos:FILE_SHARE_WRITE           equate(00000002h)
dos:FILE_SHARE_DELETE          equate(00000004h)
dos:CREATE_NEW                 equate(1)
dos:CREATE_ALWAYS              equate(2)
dos:CREATE_EXISTING            equate(3)
dos:OPEN_ALWAYS                equate(4)
dos:OPEN_EXISTING              equate(3)
dos:TRUNCATE_EXISTING          equate(5)
dos:INVALID_SET_FILE_POINTER   equate(-1)
dos:FILE_BEGIN                 equate(0)
dos:FILE_CURRENT               equate(1)
dos:FILE_END                   equate(2)
dos:FILE_ATTRIBUTE_NORMAL      equate(080h)
dos:HANDLE                     equate(0)
dos:INVALID_HANDLE_VALUE       equate(-1)
dos:MEMORYTABLE                equate(-2)

dos:ERROR_FILE_NOT_FOUND       equate(2)
dos:ERROR_PATH_NOT_FOUND       equate(3)
dos:ERROR_TOO_MANY_OPEN_FILES  equate(4)
dos:ERROR_ACCESS_DENIED        equate(5)
dos:ERROR_SHARING_VIOLATION    equate(32)
dos:ERROR_LOCK_VIOLATION       equate(33)
dos:ERROR_ALREADY_EXISTS       equate(183)

dos:MOVEFILE_COPY_ALLOWED    equate(2)
dos:MOVEFILE_WRITE_THROUGH   equate(8)

dos:_WIN32_FIND_DATAA       Group,TYPE
dwFileAttributes              Long
ftCreationTimeLow             uLong
ftCreationTimeHigh            uLong
ftLastAccessTimeLow           uLong
ftLastAccessTimeHigh          uLong
ftLastWriteTimeLow            uLong
ftLastWriteTimeHigh           uLong
nFileSizeHigh                 uLong
nFileSizeLow                  uLong
dwReserved0                   Long
dwReserved1                   Long
cFileName                     cstring(256)
cAlternateFileName            cstring(14)
dwFileType                    Long       ! // Obsolete. Do not use.
dwCreatorType                 Long       ! // Obsolete. Do not use
wFinderFlags                  Short      ! // Obsolete. Do not use
                            End

!============================================================
! helper functions
!-----------------------------------------------------------------
DriverFileDos2Class.CONSTRUCT             PROCEDURE()
  Code
  Self.SetMethod = driver:NotSet
  self._justset = true
  self.opt:BusyTimeout = 5

!-----------------------------------------------------------------
! In derived classes derive this method with this exact same code, but
! replace the declaration of old with your class name. DO NOT
! call the parent class.
DriverFileDos2Class.REPLACEOBJECT          PROCEDURE(Long pOldObjectAddress)
old    &DriverFileDos2Class
  Code
  If pOldObjectAddress <> 0
    old &= (pOldObjectAddress)
    self :=: old
    dispose(old)
  End
  self.ClaFCB.rblock = address(self)
  Return

!-----------------------------------------------------------------
DriverFileDos2Class.SetDriverOption            Procedure(String pOption, String pValue)
  Code
  Case upper(pOption)
  of '/BUSYTIMEOUT'
    If pValue <> ''
      self.opt:BusyTimeout = pValue
    End
  End
  Return parent.SetDriverOption(pOption,pValue)

!-----------------------------------------------------------------
DriverFileDos2Class._ConvertAccessMode  PROCEDURE(Long pAccessmode)
! from clarion access mode to Windows CreateFile mode
  Code
  Case band(pAccessmode,0fh)
  Of ReadOnly
    Return dos:GENERIC_READ
  Of WriteOnly
    Return dos:GENERIC_WRITE
  Of ReadWrite
    Return dos:GENERIC_READ + dos:GENERIC_WRITE
  Else
    Return dos:GENERIC_READ     ! if low-byte of accessmode is invalid, then assume read-only access
  End

!-----------------------------------------------------------------
! from clarion access mode to Windows CreateFile mode
DriverFileDos2Class._ConvertShareMode  PROCEDURE(Long pAccessmode)
  Code
  Case band(pAccessmode,0f0h)
  Of AnyAccess
    Return dos:FILE_SHARE_READ + dos:FILE_SHARE_WRITE + dos:FILE_SHARE_DELETE
  Of DenyAll
    Return dos:FILE_DENY_ALL
  Of DenyWrite
    Return dos:FILE_SHARE_READ
  Of DenyRead
    Return dos:FILE_SHARE_WRITE
  Of DenyNone
    Return dos:FILE_SHARE_READ + dos:FILE_SHARE_WRITE + dos:FILE_SHARE_DELETE
  Else
    Return dos:FILE_DENY_ALL ! if high byte is invalid assume deny-all access
  End

!-----------------------------------------------------------------
! from clarion access mode to Windows CreateFile mode
DriverFileDos2Class._ConvertError  PROCEDURE(Long pWindowsErrorCode)
FORMAT_MESSAGE_FROM_SYSTEM  equate(1000h)
result           long
ErrMess          cstring(1024)
  Code
  Case pWindowsErrorCode
  Of dos:ERROR_FILE_NOT_FOUND
    Return NoFileErr
  Of dos:ERROR_PATH_NOT_FOUND
    Return NoPathErr
  Of dos:ERROR_TOO_MANY_OPEN_FILES
    Return TooManyErr
  Of dos:ERROR_ACCESS_DENIED
    Return NoAccessErr
  Of dos:ERROR_LOCK_VIOLATION
    Return NoAccessErr            ! return IsLockedErr  ! compatibility with existing DOS driver
  of dos:ERROR_ALREADY_EXISTS
    Return NoAccessErr
  Else
    result = DosFormatMessage(FORMAT_MESSAGE_FROM_SYSTEM,0,pWindowsErrorCode,0,ErrMess,size(ErrMess),0)
    self.SetFileError(pWindowsErrorCode,ErrMess)
    Return FileSystemErr
  End

!-----------------------------------------------------------------
! copies a block from the buffer memory to the record memory.
! the buffer memory has been read "from the disk". So this is copying "from the disk,
! into the record buffer.
DriverFileDos2Class._CopyBufferIntoRecord    PROCEDURE(BIGINT pFilePointer, BIGINT pBufferPos, LONG pLength)
x             long
l             long
bufferoffset  long
recordoffset  long
  Code
  If self.SharedProperties.HasCustomFields
    ! the table has custom field interface(s). So the copy must be done on a field-by-field basis.
    ! Two counters are involved - the offset into the buffer, and the offset into the record.
    ! They likely won't align after the first custom field.
     Loop x = 1 to self.SharedProperties.FieldList.nodes
       self.Fields &= self._WithFieldNode(x)
       If self.Fields.Interface &= NULL
         ! no custom interface, so can do a simply copy here
         memcpy(self.ClaFCB.rec_buf + recordoffset,address(self._buffer[pBufferPos+bufferoffset]),self.Fields.Size)
         bufferoffset += self.Fields.Size
         recordoffset += self.Fields.Size
       Else
         ! Custom Field
         If len(self._buffer) >= pBufferPos + bufferoffset + self.Fields.Interface.GetSourceSize()
           l = self.Fields.Interface.ToRecordField(self.Fields.Type, self.ClaFCB.rec_buf + recordoffset,self.Fields.Size,ClaString,address(self._buffer[pBufferPos+bufferoffset]),self.Fields.Interface.GetSourceSize())
           recordoffset += self.Fields.Size
           bufferoffset += l
         End
       End
     End
  Else
    ! if the table does not use custom fields, then a simple mem copy is fast.
    memcpy(self.ClaFCB.rec_buf,address(self._buffer[pBufferPos]),pLength)
    If pLength < self.ClaFCB.rec_len
      MemSet(self.ClaFCB.rec_buf+pLength, 32,self.ClaFCB.rec_len - pLength)
    End
    self._bytes = pLength
  End
  self.RecordPointer = pFilePointer
  self.RecordLength = pLength
  Return

!-----------------------------------------------------------------
! reads the data out of the buffer, refreshing the buffer from disk if necessary.
DriverFileDos2Class._Read             PROCEDURE(BIGINT pFilePointer, LONG pLength)
i long
  code
  Loop i = 1 to 2
    If self._ReadFromBuffer(pFilePointer,pLength) = Driver:ok
      If i = 1 then self._bufferhit += 1.
      Return
    End
    self._buffermiss += 1
    If self._hfile >= dos:Handle
      If self._ReadDisk(pFilePointer) = Driver:notok or ErrorCode()
        self._bytes = 0
        Break
      end
      Cycle  ! try reading from the buffer again
    End
    Break
  End
  Return

!-----------------------------------------------------------------
DriverFileDos2Class._ReadDisk        PROCEDURE(BIGINT pFilePointer)!,VIRTUAL
result long
bytesread  long
  Code
  If self._buffer &= null
    self.Buffer()
  End
  If self._hfile < dos:Handle then return Driver:Notok.
  If self._SetDisk(pFilePointer-1) = Driver:Notok then Return Driver:NotOk.!_SetDisk is 0 based
  If ErrorCode() then Return Driver:NotOk.

  result = DosReadFile(self._hFile, self._buffer, self._buffersize, bytesRead, 0)
  self._diskreads += 1
  if result = 0
    self.SetError(self._ConvertError(dosGetLastError()))
    return Driver:notok
  elsif bytesRead = 0

  else
    self._bufferstart = pFilePointer
    self._bufferend = pFilePointer + bytesRead - 1
  End
  Return Driver:ok

!-----------------------------------------------------------------
DriverFileDos2Class._WriteDisk        PROCEDURE(BIGINT pFilePointer, Long pLength)!,VIRTUAL
result       Long
written      Long
x            Long,Auto
l            Long,Auto
desired      Long,Auto
ramlength    Long,Auto
ramoffset    Long
recordoffset Long
srclen       Long,Auto

  code
  If pLength = Dos:RecordLength then pLength = self._SourceSize() .
  If pLength > self._SourceSize() then pLength = self._SourceSize() .
  If self._SetDisk(pFilePointer-1) = Driver:notok then return driver:notok.     !_SetDisk is 0 based
  If self.SharedProperties.HasCustomFields
    ! the table has custom field interface(s). So the copy must be done on a field-by-field basis.
    ! Two counters are involved - the offset into the buffer, and the offset into the record.
    ! They likely won't align after the first custom field.
    srclen = self._SourceSize()
    If pLength > srclen  then desired = pLength else desired = srclen.

    If self._ram &= null
      self._ram &= new String(desired)         ! sourcelength is the disk record length, not the clarion record length
    Elsif Len(self._Ram) < desired
      Dispose(self._ram)
      self._ram &= new String(desired)         ! sourcelength is the disk record length, not the clarion record length
    End
    memset(address(self._ram),'<0>',desired)         ! clear to nulls
    ramlength = desired

    Loop x = 1 to self.SharedProperties.FieldList.nodes
      self.Fields &= self._WithFieldNode(x)
      If self.Fields.Interface &= NULL
        ! no custom interface, so can do a simply copy here
        memcpy(address(self._ram) + ramoffset, self.ClaFCB.rec_buf + recordoffset, self.Fields.Size)
        ramoffset += self.Fields.Size
        recordoffset += self.Fields.Size
      Else
        l = self.Fields.Interface.FromRecordField(self.Fields.Type,self.ClaFCB.rec_buf + recordoffset,self.Fields.Size,address(self._ram) + ramoffset,self.Fields.SourceSize)
        recordoffset += self.Fields.Size
        ramoffset += l
      End
    End
    !now the whole block can be written to the disk.
    If self._hfile >= dos:Handle
      result = DosWriteFile(self._hFile, address(self._ram), pLength, written, false)
      If result = 0
        self.SetError(self._ConvertError(dosGetLastError()))
        Return driver:notok
      End
    End
    Self._BufferUpdate(pFilePointer, address(self._ram), pLength)
  Else
    ! if the table does not use custom fields, then can simply write from the record
    If self._hfile >= dos:Handle
      result = DosWriteFile(self._hFile, self.ClaFCB.rec_buf, pLength, written, false)
      If result = 0
        self.SetError(self._ConvertError(dosGetLastError()))
        Return driver:notok
      End
    End
    Self._BufferUpdate(pFilePointer, self.ClaFCB.rec_buf, pLength)
  End
  self._bytes = pLength
  Return driver:ok

!-----------------------------------------------------------------
! When doing a write to the disk, it's necessary to update the buffer at the same time
! so that subsequent reads (from the buffer) get the updated values.
DriverFileDos2Class._BufferUpdate  Procedure(BIGINT pFilePointer, LONG pAddr, Long pLength)
bufpos  BIGINT
bufn    Long
  code
  If self._bufferwholefile
    ! make sure buffer is big enough
    if self._buffersize < pFilePointer + pLength
      self._ExtendBuffer(pFilePointer + (pLength*10)) ! extend buffer size, and pad with nulls, going to allow some extra space in case this is growing in a loop.
    end
    ! write new data into buffer
    memcpy(address(self._buffer[pFilePointer]), pAddr, pLength)
    if self._bufferend < pFilePointer + pLength - 1 then self._bufferend = pFilePointer + pLength - 1.
    self._bufferstart = 1
    return
  End
  If self._buffer &= null then return. ! buffer is not active

  ! ok, to get here the buffer has a fixed size, and is a "window" into the file
  if self._bufferstart = 0   ! nothing in the buffer.
    If pLength > self._buffersize then pLength = self._buffersize.  ! crop length to buffer size if necessary
    memcpy(address(self._buffer[1]), pAddr, pLength)                ! copy data into buffer.
    self._bufferstart = pFilePointer
    self._bufferend = pFilePointer + pLength - 1
    return
  end
  ! to get here the buffer already has something in it. Check and see if the current write overwites any of the existing buffer
  bufpos = pFilePointer - self._bufferstart + 1

  ! check if new data falls completely outside current buffer range.
  If self._bufferstart + self._buffersize - 1 < pFilePointer then return.   ! new data is after buffer
  If pFilePointer + pLength - 1 < self._bufferstart then return.        ! new data if before buffer

  ! does whole new text fits inside buffer
  If self._bufferstart <= pFilePointer and self._buffersize >= bufpos + pLength - 1
    memcpy(address(self._buffer[bufpos]), pAddr, pLength)
    If self._bufferend < bufpos + pLength - 1 then self._bufferend = bufpos + pLength - 1.
    Return
  End
  ! does the new text overlap the buffer completely, both in front and behind
  If pFilePointer < self._bufferstart and pFilePointer + pLength - 1 >  self._bufferstart + self._buffersize
    bufn = self._bufferstart - pFilePointer + 1
    memcpy(address(self._buffer[1]), pAddr + bufn, self._buffersize)
    self._bufferend = self._bufferstart  + self._buffersize
    return
  End
  ! start of new text is inside buffer, but end is not
  If self._bufferstart <= pFilePointer
    pLength = self._buffersize - bufpos + 1
    memcpy(address(self._buffer[bufpos]), pAddr, pLength)
    self._bufferend = self._buffersize
    Return
  End
  ! start of new text is before buffer, but end is inside
  If pFilePointer < self._bufferstart
    bufn = self._bufferstart - pFilePointer + 1
    pLength = pLength - bufn + 1
    memcpy(address(self._buffer[1]), pAddr + bufn, pLength)
    If self._bufferend < pLength then self._bufferend = pLength.
    Return
  End
  Assert(false,'Shouldnt get here')
  Return

!-----------------------------------------------------------------
DriverFileDos2Class._ExtendBuffer    PROCEDURE(Long pNewSize)
s  &string,Auto
  Code
  if pNewSize <= self._buffersize then return.
  s &= self._buffer
  If pNewSize > 0
    self._buffer &= New String(pNewSize)
    memcpy(address(self._buffer[1]), address(s), self._buffersize)
    memset(address(self._buffer[self._buffersize+1]) ,'<0>', pNewSize - self._buffersize)
    self._buffersize = pNewSize
  End
  Dispose(s)

!-----------------------------------------------------------------
! A Wrap around the DosSetFilePointerEx function.
! Incoming parameter is 0 based.
! Dos:SetEndOfFile means the position is set to the end of the file
! If Error then DiskPointer is set to -1, and the Errorcode() is set.
DriverFileDos2Class._SetDisk       PROCEDURE(BIGINT pFilePointer)
Offset like(int64)
Ptr    like(int64)
  Code
  If pFilePointer = Dos:SetEndOfFile
    Offset.hi = 0
    Offset.lo = 0
    If self._hfile >= dos:Handle
      If DosSetFilePointerEx(self._hFile,Offset,ptr,dos:FILE_END) = 0
        self.SetError(self._ConvertError(dosGetLastError()))
        self.DiskPointer = 0
        return Driver:notok
      Else
        self.DiskPointer = (ptr.hi * MAXULONG) + (ptr.lo) + 1    ! self.DiskPointer is 1 based
      End
    Else
      Self.DiskPointer = self._bufferend
    End
  Else
    If pFilePointer < 0
      self.SetError(NoAccessErr)
      self.DiskPointer = 0
      Return Driver:notok
    End
    If self._hfile >= dos:Handle
      Offset.hi = pFilePointer / MAXULONG
      Offset.lo = pFilePointer % MAXULONG
      If DosSetFilePointerEx(self._hFile,Offset,ptr,dos:FILE_BEGIN) = 0
        self.SetError(self._ConvertError(dosGetLastError()))
        self.DiskPointer = 0
        return Driver:notok
      Else
        self.DiskPointer = (ptr.hi * MAXULONG) + (ptr.lo) + 1   ! self.DiskPointer is 1 based
      End
    Else
      self.DiskPointer = pFilePointer
    End
  End
  Return Driver:ok

!-----------------------------------------------------------------
! read from the buffer into the record structure.
! pFilePointer points to the starting address in the disk file.
! pLength is the number of bytes to read.
! (if pLength is > the record size (after decoding) then it is ignored. The read effectivly stops when the
! record is full.
DriverFileDos2Class._ReadFromBuffer    PROCEDURE(BIGINT pFilePointer, LONG pLength)
ix  BIGINT
  Code
  if self._bufferstart = 0 or self._bufferend = 0 then return Driver:notok.  ! buffer not loaded
  If pLength > self._SourceSize() then pLength = self._SourceSize().
  If pFilePointer >= self._bufferstart and (pFilePointer + pLength - 1) <= self._bufferend
    ! thing we want to get is already in the buffer,so just read it out of there.
    ix = pFilePointer - self._bufferstart + 1
    self._CopyBufferIntoRecord(pFilePointer,ix,pLength)
    return Driver:ok
  Elsif pFilePointer >= self._bufferstart and self.filesize() = self._bufferend
    ix = pFilePointer - self._bufferstart + 1
    self._CopyBufferIntoRecord(pFilePointer,ix,self._bufferend-pFilePointer+1)
    return Driver:ok
  end
  return Driver:notok

!-----------------------------------------------------------------
DriverFileDos2Class._ExpandName                 PROCEDURE()
  Code
  If Lower(self.FullPathName) <> ':memory:'
    If Sub(self.FullPathName,1,2) = '.\'
      self.FullPathName = longpath() & sub(self.FullPathName,2,len(self.FullPathName)-1)
    Elsif instring('\',self.FullPathName,1,1) = 0 and instring('/',self.FullPathName,1,1) = 0
      self.FullPathName = longpath() & '\' & self.FullPathName
    End
  End
  Return

!=================================================================
! driver functions
!-----------------------------------------------------------------
! In a KeyLess Driver, ADD and APPEND do the same thing.
DriverFileDos2Class.ADD              PROCEDURE()
  Code
  self.SetError(NoError)
  parent.Add()
  If Errorcode() then return.
  If self._SetDisk(Dos:SetEndOfFile) = Driver:ok
    If self._WriteDisk(self.DiskPointer,self._SourceSize()) = driver:ok
      self.RecordPointer = self.DiskPointer
      self.RecordLength = self.ClaFCB.rec_len
    End
  End
  Return

!-----------------------------------------------------------------
DriverFileDos2Class.ADD              PROCEDURE(LONG pLength)
  Code
  parent.Add(pLength)
  If Errorcode() then return.
  If pLength  = 0 then return.
  If pLength < 0
    self._Bytes = pLength   ! this is very strange, but here to duplicate DOS driver behaviour.
    return
  End
  If self._SetDisk(Dos:SetEndOfFile) = Driver:ok
    If self._WriteDisk(self.DiskPointer,pLength) = driver:ok
      self.RecordPointer = self.DiskPointer
      self.RecordLength = pLength
    End
  End
  Return

!-----------------------------------------------------------------
DriverFileDos2Class.APPEND           PROCEDURE()
  Code
  self.Add()
  Return

!-----------------------------------------------------------------
DriverFileDos2Class.APPEND           PROCEDURE(LONG pLength)
  Code
  self.Add(pLength)
  Return

!-----------------------------------------------------------------
DriverFileDos2Class.BOF              PROCEDURE()     !!! new to DOS2
  Code
  If self._CheckOpen() = false then Return True. ! Bof returns true when file is closed.
  self.SetError(NoError)
  Return self._bof

!-----------------------------------------------------------------
! This one is NEW, not supported by shipping DOS driver.
! Must be called after OPEN
! Hint: Do it AFTER calls to SetPROP:Interface
! Hint: For random reads (GETs) IF the whole file can be buffered there is a significant (10x) speed improvement. However Ram will be used.
!       To use buffer in this way call BUFFER(Driver:BufferWholeFile,maxmemoryallowed). If filesize <= maxmemoryallowed then it will be loaded, else buffer will be disabled.
! Random reads "moving forward" will benefit from Buffers if the buffersize spans the distance between reads.
! pPageSize - number of "records per page".
! pBehind -  when pPageSize = -1 : min-size of buffer in bytes
!            when page size > -1 : ignored
! pAhead  - the number of "pages" to read ahead (ie cache) when the buffer is invalid
! pTimeout - not used
DriverFileDos2Class.BUFFER           PROCEDURE(UNSIGNED pPageSize=1, UNSIGNED pBehind=0, UNSIGNED pAhead=0, UNSIGNED pTimeout=0)  !!! new to DOS2
l  long,over(pPageSize)
  Code
  parent.Buffer(pPageSize,pBehind,pAhead,pTimeout)  ! Checks the file is Open
  If Errorcode() then return.
  Dispose(self._buffer)
  self._bufferwholefile = false
  If l = Driver:FreeBuffer  ! over(pPageSize)
  ElsIf l = Driver:BufferWholeFile  ! over(pPageSize)
    If pBehind = 0 or self.FileSize() > pBehind
      pBehind = self.FileSize()
    End
    If pBehind = 0
      pBehind = DRIVER:MINRAM
    ElsIf pBehind > DRIVER:MAXRAM
      pBehind = DRIVER:MAXRAM
    End
    self._buffersize = pBehind
    self._bufferwholefile = true
  Else
    If pPageSize < 1 then pPageSize = 1.
    self._buffersize = (self._SourceSize() * pPageSize) * (pAhead + 1)
  end
  self._buffer &= null
  self._buffer &= New String(self._buffersize)
  If address(self._buffer) = 0
    self._buffersize = DRIVER:MINRAM
    self._buffer &= New String(DRIVER:MINRAM)
    self._bufferwholefile = false
  End
  If address(self._buffer)
    MemSet(address(self._buffer),'<0>', self._buffersize) ! NEW will clear it to spaces, but want it cleared to nulls
  End
  self._bufferstart = 0
  self._bufferend = 0
  Return

!-----------------------------------------------------------------
! In DOS, Bytes will return 0 if the file is closed.
! In DOS2 Bytes will return the size of the file even if the file is closed.
DriverFileDos2Class.BYTES            PROCEDURE()!,BIGINT
ans   BIGINT,Auto
x     long,Auto
  Code
  self._ExpandName()
  x = parent.Bytes()
  If self._opened and self._bytes
    Return self._bytes
  End
  ans = self.FileSize()
  Return ans

!-----------------------------------------------------------------
DriverFileDos2Class.CLOSE            PROCEDURE()
  Code
  Self.SetError(NoError)
  If self._opened and self._hfile >= dos:Handle
    dosCloseHandle(self._hfile)
  End
  self._filesize = 0
  self._Bytes = 0
  parent.Close()
  Return

!-----------------------------------------------------------------
DriverFileDos2Class.COPY             PROCEDURE(STRING pNewFileName, Long pOptions)
NewFileName  cstring(size(pNewFileName)+1)
e               Long,auto
x               Long,auto
  Code
  !If self._CheckClosed() = false then Return.   ! DOS requires it to be closed, but does it really need to be closed?
  self.SetError(NoError)
  NewFileName = clip(pNewFileName)
  self._UpdateFileStrings()
  self._ExpandName()
  Loop x = 0 to self.opt:BusyTimeout                           ! small loop in case the file will be "released shortly". Perhaps being held in AV scan etc.
    If DosCopyFile(self.FullPathName, NewFileName, false) <> 0
      break
    End
    e = DosGetLastError()
    If e = dos:ERROR_ACCESS_DENIED and x < self.opt:BusyTimeout
      DosSleep(1000)
      Cycle
    End
    self.SetError(self._ConvertError(e))
    Break
  End
  Return

!-----------------------------------------------------------------
! In the context of DOS files, the method name "CreateTable" may be confusing to read.
! a synonym CreateFile is provided as a way of making the code more readable.
DriverFileDos2Class.CREATEFILE       PROCEDURE()
hfile           Long,auto
e               Long,auto
x               Long,auto
Filename        Cstring(FILE:MAXFILENAME2),auto
  code
  parent.CreateTable()
  If Errorcode() then return.
  self._ExpandName()
  If Exists(self.Name())
    self.Remove()
  End
  FileName = self.name()
  Loop x = 0 to self.opt:BusyTimeout                           ! small loop in case the file will be "released shortly". Perhaps being held in AV scan etc.
    hFile = DosCreateFile(FileName, dos:GENERIC_WRITE, dos:FILE_DENY_ALL, 0, dos:CREATE_ALWAYS, dos:FILE_ATTRIBUTE_NORMAL, 0)
    If hFile >= 0
      DosCloseHandle(hfile)
      break
    End
    e = DosGetLastError()
    If e = dos:ERROR_ACCESS_DENIED and x < self.opt:BusyTimeout
      DosSleep(1000)
      Cycle
    End
    self.SetError(self._ConvertError(e))
    Break
  End
  Return

!-----------------------------------------------------------------
DriverFileDos2Class.CREATETABLE      PROCEDURE()
  Code
  self.CreateFile()
  Return

!-----------------------------------------------------------------
DriverFileDos2Class.DELETE           PROCEDURE()
  code
  parent.Delete()
  Self.setError(NoDriverSupport)
  self._AfterWrite(opcode:Delete)
  Return

!-----------------------------------------------------------------
DriverFileDos2Class.EMPTY            PROCEDURE()
openmode  long
Offset    like(int64)
Ptr       like(int64)
  Code
  parent.Empty()
  If errorcode() then return.
  If self._hfile >= dos:Handle
    openmode = self.Status()
    If OpenMode = ReadWrite + DenyAll or OpenMode = ReadWrite + DenyWrite
      If DosSetFilePointerEx(self._hFile,Offset,ptr,dos:FILE_BEGIN) = 0
        self.SetError(self._ConvertError(dosGetLastError()))
      Else
        If DosSetEndOfFile(self._hfile) = 0
          self.SetError(self._ConvertError(dosGetLastError()))
        End
      End
    Else
      self.SetError(ExclReqErr)
    End
  Else
    self.FreeBuffer()
  End
  Return

!-----------------------------------------------------------------
DriverFileDos2Class.EOF              PROCEDURE()
  Code
  If self._CheckOpen() = false then Return True. ! Eof returns true when file is closed.
  self.SetError(NoError)
  Return self._eof

!-----------------------------------------------------------------
DriverFileDos2Class.EXISTS           PROCEDURE(String pTablename)
tablename   cstring(255),auto
  Code
  If pTablename
    tablename = clip(pTablename)
  Else
    tablename = clip(self._GetString(self.ClaFCB.phyname))
  End
  If tablename = ''
    Self.SetError(BadNameErr)
    Return false
  End
  Self.SetError(NoError)
  Return Exists(TableName)

!-----------------------------------------------------------------
DriverFileDos2Class.FILESIZE         PROCEDURE()
siz                         like(int64)
FORMAT_MESSAGE_FROM_SYSTEM  equate(1000h)
result                      long
ErrMess                     cstring(1024)
rData                       like(dos:_WIN32_FIND_DATAA)
  Code
  self.SetError(NoError)
  If self._opened = false
    self._UpdateFileStrings()
    self._ExpandName()
    If lower(self.FullPathName) = ':memory:'
      self._filesize = self._bufferend
    Else
      result = DosFindFirstFile(self.FullPathName,address(rdata))
      if result <> dos:INVALID_HANDLE_VALUE
        self._filesize = rData.nFileSizeHigh * MAXULONG + rData.nFileSizeLow
      else
        self.trace('ERROR: dos:INVALID_HANDLE_VALUE [' & self.FullPathName & ']')
      end
    End
  Else
    If self._hfile >= dos:Handle
      result = dosGetFileSizeEx(self._hfile,siz)
      If result = 0
        ! failed
        result = DosFormatMessage(FORMAT_MESSAGE_FROM_SYSTEM,0,DosGetLastError(),0,ErrMess,size(ErrMess),0)
        self.SetFileError(DosGetLastError(),ErrMess)
        self.SetError(FileSystemErr)
      End
      self._filesize = siz.hi * MAXULONG + siz.lo
    Else
      self._Filesize = self._bufferend
    End
  End
  Return self._filesize

!-----------------------------------------------------------------
DriverFileDos2Class.FLUSH            PROCEDURE()
  Code
  parent.Flush()
  If Errorcode() then Return.
  self.FreeBuffer()
  Return

!-----------------------------------------------------------------
! This one is NEW, not part of the driver interface
DriverFileDos2Class.FREEBUFFER  PROCEDURE()
  Code
  Dispose(self._buffer)
  self._buffersize = 0
  self._bufferstart = 0
  self._bufferend = 0
  self._bufferwholefile = FALSE
  Return

!-----------------------------------------------------------------
DriverFileDos2Class.GET              PROCEDURE(BIGINT pFilePointer)
  Code
  Self._BeforeRead(Opcode:GETfileptr)
  If Errorcode() then return.
  If pFilePointer = 0
    self.RecordPointer = 0
    Return       !In the DOS driver, Get(file,0) does NOT clear the FilePointer, only the RecordPointer.
  End
  Self._Get(pFilePointer,self._SourceSize())
  Parent.Get(pFilePointer)
  Return

!-----------------------------------------------------------------
DriverFileDos2Class.GET              PROCEDURE(BIGINT pFilePointer, LONG pLength)
  Code
  Self._BeforeRead(Opcode:GETfileptrlen)
  If Errorcode() then return.
  If pFilePointer = 0 then return.       !In the DOS driver, Get(file,0) does NOT clear the record pointer.
  if pLength = 0 then Return.
  Self._Get(pFilePointer,pLength)
  Parent.Get(pFilePointer,pLength)
  Return

!-----------------------------------------------------------------
DriverFileDos2Class._Get              PROCEDURE(BIGINT pFilePointer, LONG pLength)
  Code
  If pFilePointer > self.FileSize() or pFilePointer < 0
    self.SetError(BadRecErr)
    self._bytes = 0          ! BYTES is cleared by a GET Error
    self.RecordPointer = 0        ! reset to 0. Tells POINTER to return BadRecErr
    self._recordLoaded = false
    Return
  End
  if pFilePointer > 0
    self._Read(pFilePointer,pLength)
  End
  Return

!-----------------------------------------------------------------
! keys are not supported, so parent code must be suppressed
DriverFileDos2Class.GET              PROCEDURE(KEY pkeyLabel)
  Code
  Self.SetError(NoDriverSupport)
  Return

!-----------------------------------------------------------------
! keys are not supported, so parent code must be suppressed
DriverFileDos2Class.GET              PROCEDURE(KEY pkeyLabel, BIGINT pKeyPointer)
  Code
  Self.SetError(NoDriverSupport)
  Return

!-----------------------------------------------------------------
DriverFileDos2Class.GETSTATE               Procedure(Long pSaveBlob)
len  Long,Auto
i    Long,Auto
e    Long,Auto
  Code
  e = errorcode()
  i = parent.GetState(pSaveBlob)   ! creates a new state record
  ! object properties
  len = address(self.__DOSSTATEEND) - address(self.__DOSSTATESTART)
  Dispose(self.State.Level2)
  self.State.Level2 &= new String(len)
  MemCpy(address(self.State.Level2),address(self.__DOSSTATESTART),len)
  ! object pointers
  If not self._buffer &= null
    self.State._buffer &= New String(size(self._buffer))
    MemCpy(address(self.State._buffer),address(self._buffer),size(self._buffer))
  End
  Put(self.State)
  self.SetError(e)      ! GetState should not alter errorcode.
  Return i

!-----------------------------------------------------------------
DriverFileDos2Class.LOCK             PROCEDURE(LONG pSeconds)
x  Long,auto
e  Long,auto
  Code
  If self._CheckOpen() = false then Return.
  If self._locked
    Self.SetError(IsLockedErr)
    Return
  End
  If pSeconds < 0 then pSeconds = 300.             ! 5 minutes rather than forever  ! compiler sends -1 if no seconds are passed
  self.SetError(NoError)
  Loop x = 0 to pSeconds                           ! small loop in case the file will be "released shortly". Perhaps being held in AV scan etc.
    self._locked = DosLockFile(self._hFile,0, 0, 0FFFFFFFFh,  0FFFFFFFFh)
    If self._locked then break.
    DosSleep(1000)
  End
  If self._locked = false
    self.SetError(self._ConvertError(DosGetLastError()))
  End
  Return

!-----------------------------------------------------------------
! reads the next block out of the buffer. If the buffer is exhausted then toss it, and
! load a new buffer
DriverFileDos2Class.NEXT             PROCEDURE()! !
  Code
  Self._BeforeRead(Opcode:Next)
  If Errorcode() then Return.
  If self.FileSize() = 0 or Self.SetMethod = driver:NotSet
    self.SetError(BadRecErr)
    self._bytes = 0
    self._bof = true
    self._eof = true
    self.SetPointer = 0
    self._recordloaded = false
    self.RecordPointer = 0
    Return
  ElsIf self.SetPointer = driver:SetBoundary
    If self._SetDisk(Dos:SetStartOfFile) = driver:ok
      self.SetPointer = self.DiskPointer
    else
      ! _SetDisk will have set the errorcode
      Return
    End
  ElsIf self._justset = false
    self.SetPointer += self._SourceSize()
  else
    self.SetPointer = self.SetPointer
    self._justset = false
  End
  self._bof = false
  self._eof = false
  If self.SetPointer > self._FileSize
    self.SetError(BadRecErr)
    self._bytes = 0
    self._eof = true
    self._recordloaded = false
    self.RecordPointer = 0
    self.SetPointer = driver:SetBoundary
    Return
  End
  self._Read(self.SetPointer,self._SourceSize())   ! will set RecordPointer if successful
  If self.SetPointer + self._SourceSize() >= self._filesize
    self._eof = true
  End
  parent.next()  ! must call parent
  Return

!-----------------------------------------------------------------
! This is new to OBD. It's called from RESTORESTATE to just change the Access Mode of the OPEN.
! The name of the file has not changed.

DriverFileDos2Class.REOPEN           PROCEDURE(Long pAccessMode)
DesiredAccess      Long,Auto
ShareMode          Long,Auto
SecurityAttributes Long(0)
  Code
  ! not going to call the parent, rather do it here.
  If lower(self.FullPathName) = ':memory:' then Return.
  If self._hfile >= dos:Handle
    dosCloseHandle(self._hfile)
  End
  If pAccessMode = 0 then pAccessMode = ReadOnly + DenyNone.
  self._ExpandName()
  DesiredAccess = self._ConvertAccessMode(pAccessMode)
  ShareMode = self._ConvertShareMode(pAccessMode)
  self._hFile = DosCreateFile(self.FullPathName, DesiredAccess, ShareMode, SecurityAttributes, dos:OPEN_EXISTING, dos:FILE_ATTRIBUTE_NORMAL, 0)
  If self._hFile = dos:INVALID_HANDLE_VALUE
    self.SetError(self._ConvertError(dosGetLastError()))
    self._opened = false
    self.SetStatus(0)
  Else
    self._opened = true
    self.SetStatus(pAccessMode)
  End
  Return

!-----------------------------------------------------------------
DriverFileDos2Class.RESTORESTATE           Procedure(Long pState, Byte pBuffer)
len  Long,Auto
  Code
  ! parent restores all parent object information.
  ! gets the self.State queue record
  Parent.RestoreState(pState,pBuffer)
  If Errorcode() then Return.

  ! Restore object properties
  len = address(self.__DOSSTATEEND) - address(self.__DOSSTATESTART)
  MemCpy(address(self.__DOSSTATESTART),address(self.State.Level2),len)

  ! Restore object pointers
  Dispose(self._buffer)
  If not self.state._buffer &= null
    self._buffer &= New String(size(self.state._buffer))
    MemCpy(address(self._buffer),address(self.state._buffer),size(self.state._buffer))
  End
  Return

!-----------------------------------------------------------------
DriverFileDos2Class.OPEN             PROCEDURE(LONG pAccessMode=022h)! read write, deny write
DesiredAccess      Long,Auto
ShareMode          Long,Auto
SecurityAttributes Long(0)
Opened             byte
  Code
  parent.Open(pAccessMode)
  If errorcode() then Return.
  If pAccessMode = 0 then pAccessMode = ReadOnly + DenyNone.
  self._filesize = 0
  self._ExpandName()
  If lower(self.FullPathName) = ':memory:'
    ! DOS2 driver supports threaded in-memory file. Data is not shared across threads. In ram, so Ram-size limited.
    self._MemoryTable = true
    self._opened = true
    self.Buffer(Driver:BufferWholeFile)
    self._hFile = dos:MEMORYTABLE
  Else
    DesiredAccess = self._ConvertAccessMode(pAccessMode)
    ShareMode = self._ConvertShareMode(pAccessMode)
    self._hFile = DosCreateFile(self.FullPathName, DesiredAccess, ShareMode, SecurityAttributes, dos:OPEN_EXISTING, dos:FILE_ATTRIBUTE_NORMAL, 0)
    If self._hFile = dos:INVALID_HANDLE_VALUE
      self.SetError(self._ConvertError(dosGetLastError()))
      Opened = false
    Else
      Opened = true
    End
  End
  self._bufferhit = 0
  self._buffermiss = 0
  self._diskreads = 0
  self._bytes = 0
  self.SetPointer = driver:SetBoundary  ! just a convenience. Allows NEXT to be called without a SET.
  Self.SetMethod = driver:SetFile
  self._justset = true
  self.AfterOpen(pAccessMode,Opened)  ! derived class must call AfterOpen with result
  Return

!-----------------------------------------------------------------
! POINTER returns the RecordPointer. Except immediately after a Get(,0). Then it returns 0.
! But record pointer remains undisturbed in case there's a PUT.
DriverFileDos2Class.POINTER          PROCEDURE()
ans  BIGINT
  code
  If self._CheckOpen() = 0 then Return 0.
 ! self.SetError(NoError)   ! Pointer does not clear the errorcode
  ans = self.RecordPointer
  Return Ans

!-----------------------------------------------------------------
! previous will only return a record if that record is full. Partial records are not loaded.
DriverFileDos2Class.PREVIOUS         PROCEDURE()! !
  Code
  Self._BeforeRead(Opcode:PREVIOUS)
  If Errorcode() then Return.

  If self.FileSize() = 0 or (self._filesize - self._SourceSize() < 0)  or |  ! file is too small for a full record
    self.SetPointer > 0 and self.SetPointer < self._SourceSize()  or |       ! pointer is less than record size
    Self.SetMethod = driver:NotSet
    ! previous will read before the start of the file, so fail.
    self.SetError(BadRecErr)
    self.SetPointer = driver:SetBoundary

    self._bytes = 0
    self._bof = true
    self._recordloaded = FALSE
    self.RecordPointer = 0
    if self._filesize = 0 then self._eof = true.
    Return
  ElsIf self.SetPointer = driver:SetBoundary
    if self._SetDisk(self._filesize - self._SourceSize()) = driver:ok !_SetDisk is 0 based
      self.SetPointer = self.diskpointer
    End
  ElsIf self._justset = false
    self.SetPointer -= self._SourceSize()
  else
    self.SetPointer = self.SetPointer
    self._justset = false
  End
  self._eof = false
  self._bof = false
  self._Read(self.SetPointer,self._SourceSize())  ! will set RecordPointer if successful
  If self.SetPointer - self._SourceSize() < 0
    self._bof = true
  End
  parent.previous()  ! must call parent
  Return

!-----------------------------------------------------------------
DriverFileDos2Class.PUT              PROCEDURE()
  Code
  If self.RecordPointer = 0
    self.RecordPointer = self.DiskPointer
    self.RecordLength = self.ClaFCB.rec_len
  End
  Parent.Put() ! Parent MUST be called before writing the record. Abort if Errorcode set.
  If Errorcode() then return.
  If self.RecordPointer >= 1
    if self._writeDisk(self.RecordPointer,Dos:RecordLength) = Driver:ok
      self.RecordPointer = self.Diskpointer
      self.RecordLength = self.ClaFCB.rec_len
    end
  End
  self._AfterWrite(opcode:Put)
  Return

!-----------------------------------------------------------------
DriverFileDos2Class.PUT              PROCEDURE(BIGINT pFilePointer)
  Code
  Parent.Put(pFilePointer) ! Parent MUST be called before writing the record. Abort if Errorcode set.
  If Errorcode() then return.
  If pFilePointer = 0
    self.Add()
  Else
    If self._writeDisk(pFilePointer,Dos:RecordLength) = Driver:ok
      self.RecordPointer = self.Diskpointer
      self.RecordLength = self.ClaFCB.rec_len
    End
  End
  self._AfterWrite(opcode:Put)
  Return

!-----------------------------------------------------------------
DriverFileDos2Class.PUT              PROCEDURE(BIGINT pFilePointer, LONG pLength)
result long
  Code
  Parent.Put(pFilePointer,pLength) ! Parent MUST be called before writing the record. Abort if Errorcode set.
  If Errorcode() then return.
  If pLength = 0 then return.
  If pFilePointer = 0
    self.Add(pLength)
  ElsIf pFilePointer < 0
    self.SetError(NoAccessErr)
  ElsIf Errorcode() = NoError
    If self._writeDisk(pFilePointer,pLength) = Driver:ok
      self.RecordPointer = self.Diskpointer
      self.RecordLength = pLength
    End
  End
  self._AfterWrite(opcode:Put)
  Return

!-----------------------------------------------------------------
DriverFileDos2Class.RECORDS          PROCEDURE()!,BIGINT
Ans   BIGINT
  Code
  self.SetError(NoError)
  Ans = int(self.FileSize() / self._SourceSize())
  Return Ans

!-----------------------------------------------------------------
! In this form of REGET the pStr comes from POSITION, which for the file case is a 8 byte real position, plus a 8 byte real length.
DriverFileDos2Class.REGET            PROCEDURE(STRING pPosition)
s  string(8),over(self.RecordPointer)
  Code
  If self._CheckOpen() = false then Return.
  If pPosition = ''
    Self.SetError(NoRecErr)
    Return
  End
  If len(pPosition) < 8
    Self.SetError(BadRecErr)
    Return
  End
  Self._BeforeRead(Opcode:REGETfile)
  If Errorcode() then Return.
  self.SetError(NoError)
  s = sub(pPosition,1,8)                            ! sets self.RecordPointer
  Self.Get(self.RecordPointer)                 ! GET's a full record length. The length of the POSITION read is not used.
  ! don't need to call parent, as call to GET will do
  Return

!-----------------------------------------------------------------
! keys are not supported, so parent code must be suppressed
DriverFileDos2Class.REGET            PROCEDURE(KEY pKey, STRING pPosition)
  Code
  self.SetError(NoDriverSupport)
  Return

!-----------------------------------------------------------------
DriverFileDos2Class.REMOVE           PROCEDURE()
e   Long,Auto
x   Long,Auto
  Code
  self.SetError(NoError)
  If self._CheckClosed() = false then Return.
  self._UpdateFileStrings()
  self._ExpandName()
  Loop x = 0 to self.opt:BusyTimeout                           ! small loop in case the file will be "released shortly". Perhaps being held in AV scan etc.
    If DosDeleteFile(self.FullPathName) <> 0 then break.       ! 0 means failed.  If DosDeleteFile succeeds, the return value is nonzero.
    e = DosGetLastError()
    If e = dos:ERROR_ACCESS_DENIED and x < self.opt:BusyTimeout
      DosSleep(1000)
      Cycle
    End
    self.SetError(self._ConvertError(e))
    Break
  End
  Return

!-----------------------------------------------------------------
DriverFileDos2Class.RENAME           PROCEDURE(STRING pNewFileName)
ToName   Cstring(size(pNewFileName)+255),Auto
x        long,Auto
y        long,Auto
e        long,Auto
  Code
  If self._CheckClosed() = false then Return.
  self._UpdateFileStrings()
  self._ExpandName()
  ToName = clip(pNewFileName)
  If Right(Toname,1) = '\'
    do ExpandName
  End
  Loop x = 0 to self.opt:BusyTimeout                           ! small loop in case the file will be "released shortly". Perhaps being held in AV scan etc.
    If DosMoveFileEx(self.FullPathName,ToName, dos:MOVEFILE_COPY_ALLOWED + dos:MOVEFILE_WRITE_THROUGH) <> 0  ! 0 means failed.  If DosMoveFileEx succeeds, the return value is nonzero.
      Break
    End
    e = DosGetLastError()
    If e = dos:ERROR_ACCESS_DENIED and x < self.opt:BusyTimeout
      DosSleep(1000)
      Cycle
    End
    self.SetError(self._ConvertError(e))
    Break
  End
  Return

ExpandName  routine
  y = 0
  loop
    x = instring('\',self.FullPathName,1,y+1)
    if x = 0 then break.
    y = x
  end
  toname = toname & sub(self.FullPathName,y+1,255)

!-----------------------------------------------------------------
! given a POSITION string, set the SetPointer and RecordLength properties.
DriverFileDos2Class.RESET                        PROCEDURE(STRING pPosition)
s  string(8),over(self.SetPointer)
l  string(8),over(self.RecordLength)
  Code
  If self._CheckOpen() = false then Return.
  self.SetError(NoError)
  s = sub(pPosition,1,8)   ! sets self.SetPointer
  l = sub(pPosition,9,8)   ! sets self.RecordLength
  parent.Reset(pPosition)
  Return

!-----------------------------------------------------------------
DriverFileDos2Class.SEND                         PROCEDURE(STRING pMessage)!STRING
  Code
  Return ''

!-----------------------------------------------------------------
! Note that SKIP jumps by Disk Record Size NOT Bytes. To Jump by Bytes use SET(FilePointer) instead.
DriverFileDos2Class.SKIP                         PROCEDURE(BIGINT pCount)  !!! new to DOS2
skipping  BIGINT
  Code
  parent.Skip(pCount)
  If Errorcode() then return.
  If pCount = 0 then return.
  If pCount < 0
    If self.SetPointer = driver:SetBoundary
      Self.SetPointer = self.FileSize() - self._SourceSize()
    End
  else
    If self.SetPointer = driver:SetBoundary
       self.SetPointer = 1
    End
  End
  skipping = pCount * self._SourceSize()
  If self.SetPointer + skipping < 1
    self.SetPointer = driver:SetBoundary
    self.SetError(BadRecErr)
    self._justset = true
    self._bytes = 0
    self._bof = true
    return
  Elsif self.SetPointer + skipping > self.FileSize()
    self.SetPointer = self._filesize + 1
    self.SetError(BadRecErr)
    self._justset = true
    self._bytes = 0
    self._eof = true
    return
  End
  self.SetPointer += skipping
  Return

!-----------------------------------------------------------------
DriverFileDos2Class.UNLOCK                       PROCEDURE()
result  Long
  Code
  If self._locked = false then Return.
  self.SetError(NoError)
  result = DosUnlockFile(self._hFile,0, 0, 0FFFFFFFFh,  0FFFFFFFFh)
  If result = false
    self.SetError(self._ConvertError(DosGetLastError()))
  else
    self._locked = false
  End
  Return

!-----------------------------------------------------------------
DriverFileDos2Class.GetProp:Driver               PROCEDURE()
  code
  Return 'DOS2'

!-----------------------------------------------------------------
DriverFileDos2Class.GetProp:FileSize             PROCEDURE()
  code
  Return self.FileSize()

!!================================================================================================
!!================================================================================================
!! The DOS2MetaData interface are a collection of methods called by the IDE. These allow the IDE to
!! provide driver related information to the user while they are using the IDE
!
!Dos2MetaData.IDrvMetaWindow.HasOperation PROCEDURE(SIGNED opCode)
!  CODE
!  Return true
!!---------------------------------------------------------------------------------
!Dos2MetaData.IDrvMetaWindow.Extensions PROCEDURE()
!  Code
!  Return extensions
!!---------------------------------------------------------------------------------
!Dos2MetaData.IDrvMetaWindow.ExtensionName PROCEDURE()
!  Code
!  Return extensionName
!!---------------------------------------------------------------------------------
!! This method provides a UI window to assist the user in constructing DRIVER strings in the dictionary.
!Dos2MetaData.IDrvMetaWindow.BuildDriverString PROCEDURE (*CSTRING inStr, LONG info)
!
!BuilderWindow WINDOW('DOS2 Driver String Builder'),AT(,,183,85),CENTER,MODAL,GRAY,FONT('Segoe UI',10),DOUBLE
!    BUTTON('&OK'),AT(74,66,50,14),USE(?OK),DEFAULT
!    BUTTON('Cancel'),AT(126,66,50,14),USE(?Cancel)
!    PROMPT('Buffers'),AT(7,10),USE(?PromptBuffers)
!    ENTRY(@s20),AT(86,10),USE(SELF.Buffers)
!    OPTION('Quick Scan'),AT(7,23,169,22),USE(SELF.QuickScan),BOXED
!      RADIO('Default'),AT(52,32),USE(?Quickscan:Default)
!      RADIO('On'),AT(101,32),USE(?Quickscan:On),VALUE('ON')
!      RADIO('Off'),AT(141,32),USE(?Quickscan:Off),VALUE('OFF')
!    END
!    CHECK('In-Memory'),AT(11,49),USE(Self.InMemory)
!  END
!
!ReturnValue    BOOL
!fontinfo       &MetaDataInfo
!
!  CODE
!  fontinfo &= (info)
!  Self.AddOption(Self.Buffers,'BUFFERS',5)
!  Self.AddOption(Self.QuickScan,'QUICKSCAN','')
!  Self.AddOption(Self.InMemory,'INMEMORY','OFF')
!  self.Parse(inStr)
!  If not fontinfo &= NULL and fontinfo.SetFontData
!    SetFont (BuilderWindow, fontinfo.FontFace, fontinfo.FontSize, fontinfo.FontColor, fontinfo.FontStyle, fontinfo.FontCharSet)
!  End
!
!  Open (BuilderWindow)
!  Accept
!    If Event() = EVENT:Accepted
!      Case Accepted()
!      Of ?OK
!        ReturnValue = TRUE
!        self.CreateString(inStr)
!        Break
!      Of ?Cancel
!        Break
!      End
!    End
!  End
!  Close(BuilderWindow)
!
!  Return ReturnValue
!!---------------------------------------------------------------------------------

