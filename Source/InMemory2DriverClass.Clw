!------------------------------------------------------------------------------------------------
!   CapeSoft Clarion File Driver Kit classes are copyright © 2025 by CapeSoft                   !
!   Docs online at : https://capesoft.com/docs/Driverkit/ClarionObjectBasedDrivers.htm
!   Released under MIT License
!------------------------------------------------------------------------------------------------

  Member()
  Map                       
    Module('Windows')
      osOutputDebugString(*cstring msg), raw, pascal, name('OutputDebugStringA')
    End
    Module('SQLite api')
      sqlite3_open_v2(*cString pFileName,Long pHandleAddress, Long pFlags, Long pVFS),Long,C,Raw,name('sqlite3_open_v2') ! filename in utf-8 format
      sqlite3_close(Long pHandle),Long,C,Proc
    End
  End

  include('InMemory2DriverClass.Inc'),once
  include('StringTheory.inc'),Once
  include('Errors.clw'),once

!-----------------------------------------------------------------
! Once the last connection closes, the database goes away. 
! So for each database encountered, a connection needs to be made, and kept open.
! for now, we'll just put them in a queue
! This queue is global, not threaded. So is accessible to all objects on all threads.
InMemThreadManager  DriverInMemoryThread,Thread   

DBQCS               DriverCriticalSection

DatabaseQueue       Queue
Owner                 cString(255)
dbHandle              Long
Thread                Long
                    End


!-----------------------------------------------------------------
DriverInMemoryThread.Trace                        Procedure(String pStr)
cstr  Cstring(size(pStr) + 10)
  code
  cstr = '[' & thread() & '][imt]' & pStr
  osOutputDebugString(cstr)
  
!-----------------------------------------------------------------
DriverInMemoryThread.Construct                    Procedure()
  Code

!-----------------------------------------------------------------
! So when a thread destructs then any threaded databases need to be cleaned up.
DriverInMemoryThread.Destruct                     Procedure()
result   long,auto           
t        long,auto
  Code
  t = thread()
  DBQCS.wait()
  Loop 
    DatabaseQueue.Thread = t
    Get(DataBaseQueue,DatabaseQueue.Thread)
    If Errorcode() then break.
    ! There's a threaded-content database, and the thread is ending, so let's close the permanent connection.
    If DatabaseQueue.dbHandle
      result = sqlite3_close(DatabaseQueue.dbHandle)
    End  
    Delete(DataBaseQueue)
  End   
  DBQCS.release()
  Return

!=============================================================================================================
!-----------------------------------------------------------------
DriverFileInMemory2Class.CONSTRUCT        Procedure()
  Code
  self._ThisSqlType = 'INMEM2TYPE'    ! used in dict in extended attributes to identify type settings specific to INMEM driver
  Return

!-----------------------------------------------------------------
DriverFileInMemory2Class.PushDatabase      Procedure(string pOwner)
saveowner cstring(255),auto
options   long,auto
result    long,auto
x         Long,auto
  code
  DBQCS.wait()
  saveOwner = pOwner
  x = instring('?',pOwner,1,1)
  If x then pOwner = sub(pOwner,1,x-1).
  DatabaseQueue.Owner = clip(lower(pOwner))                        ! note this queue is not a property. It's a global, unthreaded queue.
  Get(DatabaseQueue,DatabaseQueue.Owner)
  If errorcode() 
    Options =  SQLITE_OPEN_READWRITE + SQLITE_OPEN_CREATE
    If sub(DatabaseQueue.Owner,1,5) = 'file:'
      Options = Bor(Options,SQLITE_OPEN_URI)
    End  
    result = sqlite3_open_v2(saveOwner,address(DatabaseQueue.dbHandle), Options ,0) 
    If self.opt:ThreadedContent
      DatabaseQueue.Thread = thread()
    Else
      DatabaseQueue.Thread = 1  ! so databases with not /ThreadedContent will die when thread 1 ends.
    End  
    If result = SQLite_Ok  
      Add(DatabaseQueue)
    End   
  End  
  DBQCS.release()
  Return
  
!-----------------------------------------------------------------
! In derived classes derive this method with this exact same code, but 
! replace the declaration of old with your class name. DO NOT call the parent class.
DriverFileInMemory2Class.ReplaceObject        Procedure(Long pOldObjectAddress)
old    &DriverFileInMemory2Class     
  Code
  If pOldObjectAddress <> 0
    old &= (pOldObjectAddress)
    self :=: old
    Dispose(old)
  End  
  self.ClaFCB.rblock = address(self)  
  Return

!-----------------------------------------------------------------
DriverFileInMemory2Class.SetDriverOption     Procedure(String pOption, String pValue)
  Code                  
  Case upper(pOption) 
  Of '/THREADEDCONTENT'
    self.opt:ThreadedContent = TRUE
  End
  Return Parent.SetDriverOption(pOption,pValue)  
  
!-----------------------------------------------Procedure----------------
DriverFileInMemory2Class.CONNECT             PROCEDURE(Long pOptions=0)
  Code
  If Errorcode() = 0
    self.PushDatabase(self.Owner)
  End
  pOptions = SQLITE_OPEN_READWRITE + SQLITE_OPEN_CREATE + SQLITE_OPEN_URI
  Parent.Connect(pOptions)  
  Return 

!-----------------------------------------------------------------
! In the Memory Driver, Disconnect "does nothing"
! Threaded databases will be destroyed by the DESTRUCT of the DriverInMemoryThread object
! Unthreaded databases exist forever, and will be cleaned up when the program closes.
DriverFileInMemory2Class.DISCONNECT     PROCEDURE()!
!result  Long,Auto
!stmt    Long
  Code
!  parent.Disconnect()
!  If self.dbHandle
!    If ConnectionPoolSQlite2.Disconnect(self.dbHandle) = true
!      result = sqlite3_close(self.dbHandle)
!      self.SetErrorSqlite(result,'[p115]')
!    End
!    self.dbHandle = 0
!  End
  Return
!-----------------------------------------------------------------
! no need for stream optimization in mem driver
DriverFileInMemory2Class.STREAM           PROCEDURE()  
  Code
  If self._logClarion then self.Log('[CLAR]STREAM()').
  self.SetError(NoError)
  Return

!-----------------------------------------------------------------
DriverFileInMemory2Class._UpdateFileStrings  Procedure()  
s  cstring(255)
  Code
  If self._locknames = false
    parent._UpdateFileStrings()  
    s = self.Owner
    if s = '' then s = 'memdb'.
    If self.opt:ThreadedContent then s = s & thread().
    self.Owner        = 'file::'& s &'?mode=memory&cache=shared&journal_mode=MEMORY&synchronous=OFF&busy_timeout=30000'
  End  
  Return  
  
!-----------------------------------------------------------------
DriverFileInMemory2Class.GETPROP:Driver   PROCEDURE()  
  code
  Return 'InMemory2' 
  
!-----------------------------------------------------------------
DriverViewInMemory2Class.GETPROP:Driver   PROCEDURE() 
  code
  Return 'InMemory2' 
  
!-----------------------------------------------------------------