!------------------------------------------------------------------------------------------------
!   CapeSoft Clarion File Driver Kit classes are copyright © 2025 by CapeSoft                   !
!   Docs online at : https://capesoft.com/docs/Driverkit/ClarionObjectBasedDrivers.htm
!   Released under MIT License
!------------------------------------------------------------------------------------------------
! Object based drivers introduces new FILE and VIEW commands. This module acts as a simple 
! bridge so those commands can be called just like any other FILE or VIEW command.
!------------------------------------------------------------------------------------------------
  Member()
  Include('errors.clw'),once
  Include('cwdriver.inc'),once
  Include('driverclass.inc'),once      
  Map
    Module('rtl')
      ClaSetError(Long pError),name('Cla$seterror')
    End  
  End

!------------------------------------------------------------------------------------------------
ADDRELATION            Procedure(File pChildFile, File pParentFile, Long pOnUpdate, Long pOnDelete, *? pChildField1, *? pParentField1, <*? pChildField2>, <*? pParentField2>, <*? pChildField3>, <*? pParentField3>, <*? pChildField4>, <*? pParentField4>, <*? pChildField5>, <*? pParentField5>, <*? pChildField6>, <*? pParentField6>, <*? pChildField7>, <*? pParentField7>, <*? pChildField8>, <*? pParentField8>, <*? pChildField9>, <*? pParentField9>, <*? pChildField10>, <*? pParentField10>)
obj      &DriverFileClass
  code
  obj &= pChildFile{prop:object}
  If obj &= null 
    ClaSetError(NoDriverSupport)
    Return 
  End
  If obj._logClarion then obj.Log('[CLAR]ADDRELATION(' & name(pParentFile) & ',' & pOnUpdate & ',' & pOnDelete & ')').
  obj.AddRelation(pParentFile,pOnUpdate,pOnDelete,pChildField1,pParentField1,pChildField2,pParentField2,pChildField3,pParentField3,pChildField4,pParentField4,pChildField5,pParentField5,pChildField6,pParentField6,pChildField7,pParentField7,pChildField8,pParentField8,pChildField9,pParentField9,pChildField10,pParentField10)  
  Return

!------------------------------------------------------------------------------------------------
BINDFIELD                  Procedure(FILE pFile,String pName, *Long pLong)
obj      &DriverFileClass
  Code
  obj &= pFile{prop:object}
  If obj &= null
    ClaSetError(NoDriverSupport)
    Return 
  End
  If obj._logClarion then obj.Log('[CLAR]BINDFIELD(' & clip(pName) & ', long)').
  obj.BindField(pName,pLong)
  Return

!------------------------------------------------------------------------------------------------
BINDFIELD                  Procedure(FILE pFile,String pName, *Real pReal)
obj      &DriverFileClass
  Code
  obj &= pFile{prop:object}
  If obj &= null
    ClaSetError(NoDriverSupport)
    Return 
  End
  If obj._logClarion then obj.Log('[CLAR]BINDFIELD(' & clip(pName) & ', real)').
  obj.BindField(pName,pReal)
  Return
  
!------------------------------------------------------------------------------------------------
BINDFIELD                 Procedure(FILE pFile,String pName, *String pString)
obj      &DriverFileClass
  Code
  obj &= pFile{prop:object}
  If obj &= null
    ClaSetError(NoDriverSupport)
    Return 
  End                           
  If obj._logClarion then obj.Log('[CLAR]BINDFIELD(' & clip(pName) & ', string)').
  obj.BindField(pName,pString)
  Return

!------------------------------------------------------------------------------------------------
BINDFIELD                 Procedure(FILE pFile,String pName, *Cstring pCstring)
obj      &DriverFileClass
  Code
  obj &= pFile{prop:object}
  If obj &= null
    ClaSetError(NoDriverSupport)
    Return 
  End
  If obj._logClarion then obj.Log('[CLAR]BINDFIELD(' & clip(pName) & ', cstring)').
  obj.BindField(pName,pCstring)
  Return

!------------------------------------------------------------------------------------------------
BINDFIELD                  Procedure(VIEW pView,String pName, *Long pLong)
obj      &DriverViewClass
  Code
  obj &= pView{prop:object}
  If obj &= null
    ClaSetError(NoDriverSupport)
    Return 
  End             
  If obj._logClarion then obj.Log('[CLAR]BINDFIELD(' & clip(pName) & ', long)').  
  obj.BindField(pName,pLong)
  Return

!------------------------------------------------------------------------------------------------
BINDFIELD                  Procedure(VIEW pView,String pName, *Real pReal)
obj      &DriverViewClass
  Code
  obj &= pView{prop:object}
  If obj &= null
    ClaSetError(NoDriverSupport)
    Return 
  End
  If obj._logClarion then obj.Log('[CLAR]BINDFIELD(' & clip(pName) & ', real)').
  obj.BindField(pName,pReal)
  Return
  
!------------------------------------------------------------------------------------------------
BINDFIELD                 Procedure(VIEW pView,String pName, *String pString)
obj      &DriverViewClass
  Code
  obj &= pView{prop:object}
  If obj &= null
    ClaSetError(NoDriverSupport)
    Return 
  End
  If obj._logClarion then obj.Log('[CLAR]BINDFIELD(' & clip(pName) & ', string)').
  obj.BindField(pName,pString)
  Return

!------------------------------------------------------------------------------------------------
BINDFIELD                 Procedure(VIEW pView,String pName, *Cstring pCstring)
obj      &DriverViewClass
  Code
  obj &= pView{prop:object}
  If obj &= null
    ClaSetError(NoDriverSupport)
    Return 
  End
  If obj._logClarion then obj.Log('[CLAR]BINDFIELD(' & clip(pName) & ', cstring)').
  obj.BindField(pName,pCstring)
  Return

!------------------------------------------------------------------------------------------------
BYTES64                   Procedure(FILE pFile)  
obj      &DriverFileClass
  Code 
  obj &= pFile{prop:object}
  If obj &= null
    Return BYTES(pFile)
  End                      
  If obj._logClarion then obj.Log('[CLAR]BYTES64()').
  Return obj.BYTES()
               
!------------------------------------------------------------------------------------------------
CLEARPROPS              Procedure(FILE pFile)
obj      &DriverFileClass
  Code 
  obj &= pFile{prop:object}
  If obj &= null
    ClaSetError(NoDriverSupport)
    Return
  End
  If obj._logClarion then obj.Log('[CLAR]CLEARPROPS()').
  obj.ClearProps()
  Return

!------------------------------------------------------------------------------------------------
CLEARPROPS              Procedure(View pView)
obj      &DriverViewClass
  Code
  obj &= pView{prop:object}
  If obj &= null
    ClaSetError(NoDriverSupport)
    Return
  End
  If obj._logClarion then obj.Log('[CLAR]CLEARPROPS()').
  obj.ClearProps()
  Return

!------------------------------------------------------------------------------------------------
COMMIT              Procedure (FILE pFile)
obj      &DriverFileClass
  code
  obj &= pFile{prop:object}
  If obj &= null 
    ClaSetError(NoDriverSupport)
    Return 
  End
  If obj._logClarion then obj.Log('[CLAR]COMMIT()').
  obj.Commit()             
  Return 
  
!------------------------------------------------------------------------------------------------
COPY                 Procedure(FILE pFile, String pFileName, Long pOptions)
obj      &DriverFileClass
  code
  obj &= pFile{prop:object}
  If obj &= null 
    ClaSetError(NoDriverSupport)
    Return
  End                     
  If obj._logClarion then obj.Log('[CLAR]COPY('&clip(pFileName)&',' & pOptions & ')').
  obj.Copy(pFileName,pOptions)             
  Return

!------------------------------------------------------------------------------------------------
CONNECT              Procedure(FILE pFile,Long pOptions=0)
obj      &DriverFileClass
  code
  obj &= pFile{prop:object}
  If obj &= null 
    ClaSetError(NoDriverSupport)
    Return
  End                     
  If obj._logClarion then obj.Log('[CLAR]CONNECT()').
  obj.Connect(pOptions)             
  Return

!------------------------------------------------------------------------------------------------
CREATEDB                Procedure(FILE pFile)
obj      &DriverFileClass
  code
  obj &= pFile{prop:object}
  If obj &= null 
    ClaSetError(NoDriverSupport)
    Return
  End  
  If obj._logClarion then obj.Log('[CLAR]CREATEDB()').
  obj.CreateDB('')
  Return             
  
!------------------------------------------------------------------------------------------------
CREATEDB                Procedure(FILE pFile,String pDatabaseName)
obj      &DriverFileClass
  code
  obj &= pFile{prop:object}
  If obj &= null 
    ClaSetError(NoDriverSupport)
    Return
  End  
  If obj._logClarion then obj.Log('[CLAR]CREATEDB(''' & clip(pDatabaseName) & ''')').
  obj.CreateDB(pDatabaseName)
  Return  
  
!------------------------------------------------------------------------------------------------
CREATEFIELD             Procedure(FILE pFile,*? pField1)
obj      &DriverFileClass
  code
  obj &= pFile{prop:object}
  If obj &= null 
    ClaSetError(NoDriverSupport)
    Return 
  End
  If obj._logClarion then obj.Log('[CLAR]CREATEFIELD(field)').
  obj.CreateField(pField1)             
  Return

!------------------------------------------------------------------------------------------------
CREATEFIELD             Procedure(FILE pFile,String pName, String pType, String pConstraint)
obj      &DriverFileClass
  code
  obj &= pFile{prop:object}
  If obj &= null 
    ClaSetError(NoDriverSupport)
    Return 
  End                    
  If obj._logClarion then obj.Log('[CLAR]CREATEFIELD('&clip(pName)& ',' & clip(pType) & ',' & clip(pConstraint) & ' )').
  obj.CreateField(pName,pType,pConstraint)             
  Return

!------------------------------------------------------------------------------------------------
CREATEKEY               Procedure(KEY pKey)
obj      &DriverFileClass
  code
  obj &= pKey{prop:object}
  If obj &= null 
    ClaSetError(NoDriverSupport)
    Return 
  End
  If obj._logClarion then obj.Log('[CLAR]CREATEKEY(key)').  
  obj.CreateKey(pKey)             
  Return

!------------------------------------------------------------------------------------------------
CREATEKEY               Procedure(File pFile,String pName, Long pOptions, *? pField1, *? pField2, <*? pField3>, <*? pField4>, <*? pField5>, <*? pField6>, <*? pField7>, <*? pField8>, <*? pField9>, <*? pField10>)
obj      &DriverFileClass
  code
  obj &= pFile{prop:object}
  If obj &= null 
    ClaSetError(NoDriverSupport)
    Return 
  End                   
  If obj._logClarion then obj.Log('[CLAR]CREATEKEY('&clip(pName)& ',' & clip(pOptions)  & ' )').
  obj.CreateKey(pOptions, pField1, pField2, pField3, pField4, pField5, pField6, pField7, pField8, pField9, pField10 )             
  Return
  
!------------------------------------------------------------------------------------------------
REMOVEFIELD               Procedure(FILE pFile,String pName)
obj      &DriverFileClass
  code
  obj &= pFile{prop:object}
  If obj &= null 
    ClaSetError(NoDriverSupport)
    Return 
  End      
  If obj._logClarion then obj.Log('[CLAR]REMOVEFIELD(' & clip(pName) & ')').
  obj.RemoveField(pName)             
  Return

!------------------------------------------------------------------------------------------------
REMOVEKEY               Procedure(KEY pKey)
obj      &DriverFileClass
  code
  obj &= pKey{prop:object}
  If obj &= null 
    ClaSetError(NoDriverSupport)
    Return 
  End
  If obj._logClarion then obj.Log('[CLAR]REMOVEKEY(key)').
  obj.RemoveKey(pKey)             
  Return

!------------------------------------------------------------------------------------------------
REMOVEKEY               Procedure(FILE pFile,String pName)
obj      &DriverFileClass
  code
  obj &= pFile{prop:object}
  If obj &= null 
    ClaSetError(NoDriverSupport)
    Return 
  End               
  If obj._logClarion then obj.Log('[CLAR]REMOVEKEY(' & clip(pName) & ')').
  obj.RemoveKey(pName)             
  Return
  
!------------------------------------------------------------------------------------------------
DECLARATION          Procedure(FILE pFile,Long pOptions=0)
obj      &DriverFileClass
  code
  obj &= pFile{prop:object}
  If obj &= null 
    ClaSetError(NoDriverSupport)
    Return ''
  End                    
  If obj._logClarion then obj.Log('[CLAR]DECLARATION(' & pOptions & ')').
  Return obj.Declaration(pOptions)             

!------------------------------------------------------------------------------------------------
DECLARATION      Procedure(KEY pKey,Long pOptions=0)
obj      &DriverFileClass
  code
  obj &= pKey{prop:object}
  If obj &= null 
    ClaSetError(NoDriverSupport)
    Return ''
  End
  If obj._logClarion then obj.Log('[CLAR]DECLARATION(key,' & pOptions & ')').
  Return obj.Declaration(pKey, pOptions)             
           
!------------------------------------------------------------------------------------------------
DELETE              Procedure (FILE pFile,String pFilter)
obj      &DriverFileClass
  code
  obj &= pFile{prop:object}
  If obj &= null 
    ClaSetError(NoDriverSupport)
    Return 
  End              
  If obj._logClarion then obj.Log('[CLAR]DELETE(' & clip(pFilter) & ')').
  obj.Delete(pFilter)             
  Return 

!------------------------------------------------------------------------------------------------
! resist the urge to call prop:disconnect here. That call is deprecated.
DISCONNECT           Procedure(FILE pFile)
obj      &DriverFileClass
  code
  obj &= pFile{prop:object}
  If obj &= null 
    ClaSetError(NoDriverSupport)
    Return 
  End             
  If obj._logClarion then obj.Log('[CLAR]DISCONNECT()').
  obj.Disconnect()             
  Return 
      
!------------------------------------------------------------------------------------------------
EXCEPT              Procedure (FILE pFile,<String pFilter>)
obj      &DriverFileClass
  code
  obj &= pFile{prop:object}
  If obj &= null 
    ClaSetError(NoDriverSupport)
    Return 
  End                   
  If obj._logClarion then obj.Log('[CLAR]EXCEPT(' & clip(pFilter) & ')').
  obj.Except(pFilter)             
  Return                 
  
!------------------------------------------------------------------------------------------------
EXISTS            Procedure(FILE pFile, String pTableName)  
obj      &DriverFileClass
  code
  obj &= pFile{prop:object}
  If obj &= null 
    ClaSetError(NoDriverSupport)
    Return false
  End
  If obj._logClarion then obj.Log('[CLAR]EXISTS(' & clip(pTableName) & ')').
  Return obj.Exists(pTableName)

!------------------------------------------------------------------------------------------------
EXISTS             Procedure(FILE pFile)  
obj      &DriverFileClass
  code
  obj &= pFile{prop:object}
  If obj &= null 
    ClaSetError(NoDriverSupport)
    Return false
  End
  If obj._logClarion then obj.Log('[CLAR]EXISTS()').
  Return obj.Exists('')

!------------------------------------------------------------------------------------------------
EXISTSDB          Procedure(FILE pFile, String pDatabaseName)  
obj      &DriverFileClass
  code
  obj &= pFile{prop:object}
  If obj &= null 
    ClaSetError(NoDriverSupport)
    Return false
  End
  If obj._logClarion then obj.Log('[CLAR]EXISTSDB(' & clip(pDatabaseName) & ')').
  Return obj.ExistsDB(pDatabaseName)
  
!------------------------------------------------------------------------------------------------
EXPORT            Procedure(FILE pFile, String pFileName, Long pOptions=0,Long pFormat=driver:csv)  
obj      &DriverFileClass
  code
  obj &= pFile{prop:object}
  If obj &= null 
    ClaSetError(NoDriverSupport)
    Return
  End                
  If obj._logClarion then obj.Log('[CLAR]EXPORT(' & clip(pFileName) & ',' & pFormat & ',' & pOptions & ')').
  obj.Export(pFileName,pOptions,pFormat)
  Return

!------------------------------------------------------------------------------------------------
GET64             Procedure(FILE pFile,BIGINT pFilePointer)
obj      &DriverFileClass
  code
  obj &= pFile{prop:object}
  If obj &= null 
    ClaSetError(NoDriverSupport)
    Return 
  End
  If obj._logClarion then obj.Log('[CLAR]GET64(' & pFilePointer & ')').
  obj.Get(pFilePointer)
  Return
  
!------------------------------------------------------------------------------------------------
GETROW            Procedure(FILE pFile,*? pField1, ? pValue1,<*? pField2>,<? pValue2>,<*? pField3>,<? pValue3>,<*? pField4>,<? pValue4>,<*? pField5>,<? pValue5>,<*? pField6>,<? pValue6>,<*? pField7>,<? pValue7>,<*? pField8>,<? pValue8>,<*? pField9>,<? pValue9>,<*? pField10>,<? pValue10>)
obj      &DriverFileClass
  code
  obj &= pFile{prop:object}
  If obj &= null 
    ClaSetError(NoDriverSupport)
    Return 
  End
  If obj._logClarion then obj.Log('[CLAR]GET(File,field,value,...)').
  obj.GetRow(pFile,pField1,pValue1,pField2,pValue2,pField3,pValue3,pField4,pValue4,pField5,pValue5,pField6,pValue6,pField7,pValue7,pField8,pValue8,pField9,pValue9,pField10,pValue10)
  Return

!------------------------------------------------------------------------------------------------
GETROW            Procedure(Key pKey,*? pField1, <*? pField2>,<*? pField3>,<*? pField4>,<*? pField5>,<*? pField6>,<*? pField7>,<*? pField8>,<*? pField9>,<*? pField10>)
  code

!------------------------------------------------------------------------------------------------
GET64             Procedure(FILE pFile,BIGINT pFilePointer, LONG pLength) 
obj      &DriverFileClass
  code
  obj &= pFile{prop:object}
  If obj &= null 
    ClaSetError(NoDriverSupport)
    Return 
  End
  If obj._logClarion then obj.Log('[CLAR]GET64(' & pFilePointer & ',' & pLength & ')').
  obj.Get(pFilePointer,pLength)
  Return
                                         
!------------------------------------------------------------------------------------------------
GETRANDOM         Procedure(FILE pFile)
obj      &DriverFileClass
  code
  obj &= pFile{prop:object}
  If obj &= null 
    ClaSetError(NoDriverSupport)
    Return 
  End
  If obj._logClarion then obj.Log('[CLAR]GETRANDOM()').
  obj.GetRandom('')
  Return
  
!------------------------------------------------------------------------------------------------
GETRANDOM         Procedure(FILE pFile,String pFilter)
obj      &DriverFileClass
  Code
  obj &= pFile{prop:object}
  If obj &= null
    ClaSetError(NoDriverSupport)
    Return
  End
  If obj._logClarion then obj.Log('[CLAR]GETRANDOM(' & clip(pFilter) & ')').
  obj.GetRandom(pFilter)
  Return

!------------------------------------------------------------------------------------------------
IMPORT            Procedure(FILE pFile, String pFileName, Long pOptions=0,Long pFormat=driver:csv)  
obj      &DriverFileClass
  code
  obj &= pFile{prop:object}
  If obj &= null 
    ClaSetError(NoDriverSupport)
    Return
  End
  If obj._logClarion then obj.Log('[CLAR]IMPORT(' & clip(pFileName) & ',' & pFormat & ',' & pOptions & ')').
  obj.Import(pFileName,pOptions,pFormat)
  Return
           
!------------------------------------------------------------------------------------------------
INTERSECT              Procedure (FILE pFile,<String pFilter>)
obj      &DriverFileClass
  code
  obj &= pFile{prop:object}
  If obj &= null 
    ClaSetError(NoDriverSupport)
    Return 
  End
  If obj._logClarion then obj.Log('[CLAR]INTERSECT(' & clip(pFilter) & ')') .
  obj.Intersect(pFilter)             
  Return                 
           
!------------------------------------------------------------------------------------------------
JOINTABLE               Procedure(VIEW pView, FILE pParentFile, *FILE pJoinFile, Byte pJoinType, String pExpression)
obj      &DriverViewClass
  code
  obj &= pView {prop:object}
  If obj &= null
    ClaSetError(NoDriverSupport)
    Return
  End
  If pParentFile &= null or pParentFile{prop:object} = ''
    ClaSetError(NoDriverSupport)
    Return
  End  
  If pJoinFile{prop:object} = ''   
    ClaSetError(NoDriverSupport)
    Return
  End                   
  If obj._logClarion then obj.Log('[CLAR]JOINTABLE()') .
  obj.JoinTable(pParentFile,pJoinFile,pJoinType,pExpression)
  Return
  
!------------------------------------------------------------------------------------------------
JOINTABLE               Procedure(VIEW pView, FILE pParentFile, *KEY pKey, Byte pJoinType, *? pField1) !, <*? pField2>, <*? pField3>, <*? pField4>, <*? pField5>, <*? pField6>, <*? pField7>, <*? pField8>, <*? pField9>, <*? pField10>)
obj      &DriverViewClass
  code
  obj &= pView {prop:object}
  If obj &= null
    ClaSetError(NoDriverSupport)
    Return
  End
  If pParentFile &= null or pParentFile{prop:object} = ''
    ClaSetError(NoDriverSupport)
    Return
  End  
  If obj._logClarion then obj.Log('[CLAR]JOINTABLE()') .
  obj.JoinTable(pParentFile,pKey,pJoinType,pField1)
  Return

!------------------------------------------------------------------------------------------------
JOINTABLE               Procedure(VIEW pView, FILE pParentFile, *KEY pKey, Byte pJoinType, *? pField1, *? pField2, <*? pField3>, <*? pField4>, <*? pField5>, <*? pField6>, <*? pField7>, <*? pField8>, <*? pField9>, <*? pField10>)
obj      &DriverViewClass
  code
  !!!todo
  
!------------------------------------------------------------------------------------------------
LOGOUTCONNECTION        Procedure(FILE pFile)
obj      &DriverFileClass
  code
  obj &= pFile{prop:object}
  If obj &= null
    ClaSetError(NoDriverSupport)
    Return 
  End  
  obj._transactionPrimary = true
  If obj._logClarion then obj.Log('[CLAR]LOGOUTCONNECTION()') . 
  obj.LogoutConnection()   
  Return               
  
!------------------------------------------------------------------------------------------------
LOG                 Procedure(FILE pFile,String pText)
obj      &DriverFileClass
  code
  obj &= pFile{prop:object}
  If obj &= null
    !ClaSetError(NoDriverSupport)   ! don't change the error code when logging
    Return 
  End  
  obj.Log(pText)
  Return               

!------------------------------------------------------------------------------------------------
LOGBUFFER             Procedure(FILE pFile)
obj      &DriverFileClass
  code
  obj &= pFile{prop:object}
  If obj &= null
    !ClaSetError(NoDriverSupport)  ! don't change the error code when logging
    Return 
  End  
  obj.LogBuffer()
  Return               

!------------------------------------------------------------------------------------------------
LOGBUFFER             Procedure(VIEW pView)
obj      &DriverViewClass
  code
  obj &= pView{prop:object}
  If obj &= null
    !ClaSetError(NoDriverSupport)   ! don't change the error code when logging
    Return 
  End  
  obj.LogBuffer()
  Return                       

!------------------------------------------------------------------------------------------------
LOGGINGON           Procedure(FILE pFile,<String pFileName>,Long pOptions=0)
obj      &DriverFileClass
  code
  obj &= pFile{prop:object}
  If obj &= null
    !ClaSetError(NoDriverSupport)   ! don't change the error code when logging
    Return 
  End  
  obj.LoggingOn(pFileName,pOptions)   
  Return               

!------------------------------------------------------------------------------------------------
LOGGINGON           Procedure(VIEW pView,<String pFileName>,Long pOptions=0)
obj      &DriverViewClass
  code
  obj &= pView{prop:object}
  If obj &= null
    !ClaSetError(NoDriverSupport)   ! don't change the error code when logging
    Return 
  End  
  obj.LoggingOn(pFileName,pOptions)   
  Return     

!------------------------------------------------------------------------------------------------
LOGGINGOFF          Procedure(FILE pFile)
obj      &DriverFileClass
  code
  obj &= pFile{prop:object}
  If obj &= null
    !ClaSetError(NoDriverSupport)   ! don't change the error code when logging
    Return 
  End  
  obj.LoggingOff()   
  Return               

!------------------------------------------------------------------------------------------------
LOGGINGOFF          Procedure(VIEW pView)
obj      &DriverViewClass
  code
  obj &= pView{prop:object}
  If obj &= null
    !ClaSetError(NoDriverSupport)   ! don't change the error code when logging
    Return 
  End  
  obj.LoggingOff()   
  Return               

!------------------------------------------------------------------------------------------------
MERGE              Procedure(FILE pFile,FILE pDestination, Long pOptions=0)  
obj      &DriverFileClass
  code
  obj &= pFile{prop:object}
  If obj &= null
    ClaSetError(NoDriverSupport)
    Return
  End                   
  If obj._logClarion then obj.Log('[CLAR]MERGE(' & name(pDestination) & ')') . 
  obj.Merge(pDestination,pOptions)
  Return

!------------------------------------------------------------------------------------------------
MERGE              Procedure(FILE pFile,STRING pDestination, Long pOptions=0)  
obj      &DriverFileClass
  code
  obj &= pFile{prop:object}
  If obj &= null
    ClaSetError(NoDriverSupport)
    Return
  End
  If obj._logClarion then obj.Log('[CLAR]MERGE(' & clip(pDestination) & ')') . 
  obj.Merge(pDestination,pOptions)
  Return
  
!------------------------------------------------------------------------------------------------
POINTER64          Procedure(FILE pFile)  
obj      &DriverFileClass
  code
  obj &= pFile{prop:object}
  If obj &= null
    Return Pointer(pFile)
  End  
  If obj._logClarion then obj.Log('[CLAR]POINTER64()') . 
  Return obj.Pointer() 
  
!------------------------------------------------------------------------------------------------
PROJECTFIELD       Procedure(VIEW pView,String pExpression,String pAs)
obj      &DriverViewClass
  Code
  obj &= pView{prop:object}
  If obj &= null
    ClaSetError(NoDriverSupport)
    Return 
  End
  If obj._logClarion then obj.Log('[CLAR]PROJECTFIELD(' & clip(pExpression) & ',''' & clip(pAs) & ''')') . 
  obj.ProjectField(pExpression,pAs)
  Return

!------------------------------------------------------------------------------------------------
PROJECTFIELD       Procedure(VIEW pView,FILE pFile,Long pIndex)
obj      &DriverViewClass
  Code
  obj &= pView{prop:object}
  If obj &= null
    ClaSetError(NoDriverSupport)
    Return 
  End
  If obj._logClarion then obj.Log('[CLAR]PROJECTFIELD(' & name(pFile) & ',' & pIndex & ')') . 
  obj.ProjectField(pFile,pIndex)
  Return

!------------------------------------------------------------------------------------------------
PROJECTFIELD       Procedure(VIEW pView,*? pField)
obj      &DriverViewClass
  Code
  obj &= pView{prop:object}
  If obj &= null
    ClaSetError(NoDriverSupport)
    Return 
  End
  If obj._logClarion then obj.Log('[CLAR]PROJECTFIELD(field)')  .
  obj.ProjectField(pField)
  Return

!------------------------------------------------------------------------------------------------
PUT64             Procedure(FILE pFile,BIGINT pFilePointer)
obj      &DriverFileClass
  code
  obj &= pFile{prop:object}
  If obj &= null 
    ClaSetError(NoDriverSupport)
    Return 
  End      
  If obj._logClarion then obj.Log('[CLAR]PUT64(' & pFilePointer & ')') . 
  obj.Put(pFilePointer)
  Return
  
!------------------------------------------------------------------------------------------------
PUT64             Procedure(FILE pFile,BIGINT pFilePointer, LONG pLength) 
obj      &DriverFileClass
  code
  obj &= pFile{prop:object}
  If obj &= null 
    ClaSetError(NoDriverSupport)
    Return 
  End
  If obj._logClarion then obj.Log('[CLAR]PUT64(' & pFilePointer &',' & pLength & ')') . 
  obj.Put(pFilePointer,pLength)
  Return
    
!------------------------------------------------------------------------------------------------
RECORDS            Procedure(FILE pFile,String pFilter)
obj      &DriverFileClass
  Code
  obj &= pFile{prop:object}
  If obj &= null
    ClaSetError(NoDriverSupport)
    Return 0
  End
  If obj._logClarion then obj.Log('[CLAR]RECORDS(' & clip(pFilter) & ')') .   
  Return obj.RecordsFilter(pFilter)

!------------------------------------------------------------------------------------------------
RECORDS            Procedure(FILE pFile,*? pField1, <*? pField2>, <*? pField3>, <*? pField4>, <*? pField5>)
obj      &DriverFileClass
  Code       
  obj &= pFile{prop:object}
  If obj &= null
    ClaSetError(NoDriverSupport)
    Return 0
  End
  If obj._logClarion then obj.Log('[CLAR]RECORDS(field(s))') .   
  Return obj.Records(pField1,pField2,pField3,pField4,pField5)
  
!------------------------------------------------------------------------------------------------
RECORDS            Procedure(VIEW pView, Long pNumber)
obj      &DriverViewClass
  Code       
  obj &= pView{prop:object}
  If obj &= null
    ClaSetError(NoDriverSupport)
    Return 0
  End                          
  If obj._logClarion then obj.Log('[CLAR]RECORDS(' & pNumber & ')') .     
  Return obj.Records(pNumber)

!------------------------------------------------------------------------------------------------
RECORDS64          Procedure(FILE pFile)  
obj      &DriverFileClass
  Code       
  obj &= pFile{prop:object}
  If obj &= null
    Return Records(pFile)
  End  
  If obj._logClarion then obj.Log('[CLAR]RECORDS64()').      
  Return obj.Records()

!------------------------------------------------------------------------------------------------
RECORDS64          Procedure(VIEW pView)  
obj      &DriverViewClass
  Code       
  obj &= pView{prop:object}
  If obj &= null
    Return Records(pView)
  End  
  If obj._logClarion then obj.Log('[CLAR]RECORDS64()').      
  Return obj.Records()
 
!------------------------------------------------------------------------------------------------
REOPEN             Procedure(FILE pFile,Long pNewMode)  
obj      &DriverFileClass
  Code       
  obj &= pFile{prop:object}
  If obj &= null
    ClaSetError(NoDriverSupport)
    Return
  End
  If obj._logClarion then obj.Log('[CLAR]REOPEN(' & pNewMode & ')') .  
  obj.Reopen(pNewMode)
  Return

!------------------------------------------------------------------------------------------------
RESULTGET          Procedure(FILE pFile,BIGINT pRow)
  Code
  If pFile{prop:object} = '' 
    ClaSetError(NoDriverSupport)
    Return
  End      
  pFile{prop:resultGet} = pRow         !!!todo
  Return

!------------------------------------------------------------------------------------------------
RESULTGET          Procedure(VIEW pView,BIGINT pRow)
  Code
  If pView{prop:object} = '' 
    ClaSetError(NoDriverSupport)
    Return
  End      
  pView{prop:resultGet} = pRow         !!!todo
  Return

!------------------------------------------------------------------------------------------------
ResultGet         Procedure(FILE pFile,BIGINT pRow,Long pColumn)                                  
obj      &DriverFileClass
  Code
  obj &= pFile{prop:object}
  If obj &= null
    ClaSetError(NoDriverSupport)
    Return ''
  End
  If obj.Result &= NULL
    Return ''
  End  
  If obj._logClarion then obj.Log('[CLAR]RESULTGET(' & pRow & ',' & pColumn & ')') .  
  Return obj.Result.GetCell(pRow,pColumn)
  
!------------------------------------------------------------------------------------------------
ResultGet         Procedure(VIEW pView,BIGINT pRow,Long pColumn)
obj      &DriverViewClass
  Code
  obj &= pView{prop:object}
  If obj &= null
    ClaSetError(NoDriverSupport)
    Return ''
  End
  If obj.Result &= NULL
    Return ''
  End  
  If obj._logClarion then obj.Log('[CLAR]RESULTGET(' & pRow & ',' & pColumn & ')') .  
  Return obj.Result.GetCell(pRow,pColumn)

!------------------------------------------------------------------------------------------------
ResultGet         Procedure(FILE pFile,BIGINT pRow,Long pColumn,*Byte pNull)                                  
obj      &DriverFileClass
  Code
  obj &= pFile{prop:object}
  If obj &= null
    ClaSetError(NoDriverSupport)
    Return ''
  End
  If obj.Result &= NULL
    Return ''
  End  
  If obj._logClarion then obj.Log('[CLAR]RESULTGET(' & pRow & ',' & pColumn & ')') .  
  Return obj.Result.GetCell(pRow,pColumn,pNull)
  
!------------------------------------------------------------------------------------------------
ResultGet         Procedure(VIEW pView,BIGINT pRow,Long pColumn,*Byte pNull)
obj      &DriverViewClass
  Code
  obj &= pView{prop:object}
  If obj &= null
    ClaSetError(NoDriverSupport)
    Return ''
  End
  If obj.Result &= NULL
    Return ''
  End  
  If obj._logClarion then obj.Log('[CLAR]RESULTGET(' & pRow & ',' & pColumn & ')') .  
  Return obj.Result.GetCell(pRow,pColumn,pNull)      
  
!------------------------------------------------------------------------------------------------
RESULTNEXT         Procedure(FILE pFile)
  Code
  If pFile{prop:object} = '' 
    ClaSetError(NoDriverSupport)
    Return
  End
  pFile{prop:resultNext}
  Return

!------------------------------------------------------------------------------------------------
RESULTNEXT         Procedure(VIEW pView)
  Code
  If pView{prop:object} = '' 
    ClaSetError(NoDriverSupport)
    Return
  End
  pView{prop:resultNext}     !!!todo
  Return

!------------------------------------------------------------------------------------------------
RESULTPREVIOUS     Procedure(FILE pFile)
  Code
  If pFile{prop:object} = '' 
    ClaSetError(NoDriverSupport)
    Return
  End                           
  pFile{prop:resultPrevious}   !!!todo
  Return

!------------------------------------------------------------------------------------------------
RESULTPREVIOUS     Procedure(VIEW pView)
  Code
  If pView{prop:object} = '' 
    ClaSetError(NoDriverSupport)
    Return
  End                           
  pView{prop:resultPrevious}   !!!todo
  Return
  
!------------------------------------------------------------------------------------------------
RESULTROW         Procedure(FILE pFile)!,BIGINT
  Code
  If pFile{prop:object} = '' 
    ClaSetError(NoDriverSupport)
    Return 0
  End
  Return pFile{prop:resultRow} !!todo

!------------------------------------------------------------------------------------------------
RESULTROW         Procedure(VIEW pView)!,BIGINT
  Code
  If pView{prop:object} = '' 
    ClaSetError(NoDriverSupport)
    Return 0
  End
  Return pView{prop:resultRow}   !!!todo

!------------------------------------------------------------------------------------------------
RESULTRECORDS      Procedure(FILE pFile)!,BIGINT 
  Code
  If pFile{prop:object} = '' 
    ClaSetError(NoDriverSupport)
    Return 0
  End
  Return pFile{prop:resultRecords} !!!todo

!------------------------------------------------------------------------------------------------
RESULTRECORDS      Procedure(VIEW pView)!,BIGINT 
  Code
  If pView{prop:object} = '' 
    ClaSetError(NoDriverSupport)
    Return 0
  End
  Return pView{prop:resultRecords}      !!!todo

!------------------------------------------------------------------------------------------------
RESUMERELATIONS        Procedure(FILE pFile)
obj      &DriverFileClass
  Code
  obj &= pFile{prop:object}
  If obj &= null
    ClaSetError(NoDriverSupport)
    Return
  End              
  If obj._logClarion then obj.Log('[CLAR]RESUMERELATIONS()') .  
  obj.ResumeRelations()

!------------------------------------------------------------------------------------------------
ROLLBACK              Procedure (FILE pFile)
obj      &DriverFileClass
  code
  obj &= pFile{prop:object}
  If obj &= null 
    ClaSetError(NoDriverSupport)
    Return 
  End
  If obj._logClarion then obj.Log('[CLAR]ROLLBACK()') .  
  obj.Rollback()             
  Return 
  
!------------------------------------------------------------------------------------------------
ROLLBACK           Procedure(FILE pFile,String pSavePoint)
obj      &DriverFileClass
  code
  obj &= pFile{prop:object}
  If obj &= null
    ClaSetError(NoDriverSupport)
    Return 
  End  
  If obj._logClarion then obj.Log('[CLAR]ROLLBACK(' & clip(pSavePoint) & ')') .  
  obj.Rollback(pSavePoint)
  Return

!------------------------------------------------------------------------------------------------
SavePoint          Procedure(FILE pFile,String pSavePoint)
obj      &DriverFileClass
  code
  obj &= pFile{prop:object}
  If obj &= null
    ClaSetError(NoDriverSupport)
    Return 
  End                        
  If obj._logClarion then obj.Log('[CLAR]SAVEPOINT(' & clip(pSavePoint) & ')') .  
  obj.SavePoint(pSavePoint)
  Return
  
!------------------------------------------------------------------------------------------------
SEARCH             Procedure(FILE pFile,String pSearchString,<*? pField1>, <*? pField2>, <*? pField3>, <*? pField4>, <*? pField5>, <*? pField6>, <*? pField7>, <*? pField8>, <*? pField9>, <*? pField10>,<*? pField11>, <*? pField12>, <*? pField13>, <*? pField14>, <*? pField15>)
obj      &DriverFileClass
  code
  obj &= pFile{prop:object}
  If obj &= null
    ClaSetError(NoDriverSupport)
    Return 
  End                 
  If obj._logClarion then obj.Log('[CLAR]SEARCH(' & clip(pSearchString) & ')') .    
  obj.Search(pSearchString,pField1,pField2,pField3,pField4,pField5,pField6,pField7,pField8,pField9,pField10,pField11,pField12,pField13,pField14,pField15)
  Return  

!------------------------------------------------------------------------------------------------
SEARCH             Procedure(VIEW pView,String pSearchString,<*? pField1>, <*? pField2>, <*? pField3>, <*? pField4>, <*? pField5>, <*? pField6>, <*? pField7>, <*? pField8>, <*? pField9>, <*? pField10>,<*? pField11>, <*? pField12>, <*? pField13>, <*? pField14>, <*? pField15>)
obj      &DriverViewClass
  code
  obj &= pView{prop:object}
  If obj &= null
    ClaSetError(NoDriverSupport)
    Return 
  End          
  If obj._logClarion then obj.Log('[CLAR]SEARCH(' & clip(pSearchString) & ')') .    
  obj.Search(pSearchString,pField1,pField2,pField3,pField4,pField5,pField6,pField7,pField8,pField9,pField10,pField11,pField12,pField13,pField14,pField15)
  Return  

!------------------------------------------------------------------------------------------------
SET                Procedure(FILE pFile,*BIGINT pPointer)
obj      &DriverFileClass
  code
  obj &= pFile{prop:object}
  If obj &= null
    SET(pFile,pPointer+0)
    Return
  End
  If obj._logClarion then obj.Log('[CLAR]SET(' & pPointer & ')') .      
  obj.Set(pPointer)
  Return

!------------------------------------------------------------------------------------------------
SET64              Procedure(FILE pFile,BIGINT pPointer)
obj      &DriverFileClass
  code
  obj &= pFile{prop:object}
  if obj &= null
    ClaSetError(NoDriverSupport)
    Return 
  End
  If obj._logClarion then obj.Log('[CLAR]SET64(' & pPointer & ')') .
  obj.Set(pPointer)
  Return

!------------------------------------------------------------------------------------------------
SET                Procedure(KEY pKey,*BIGINT pPointer)
obj      &DriverFileClass
  code
  obj &= pKey{prop:object}
  If obj &= null
    SET(pKey,pPointer+0)
    Return
  End
  If obj._logClarion then obj.Log('[CLAR]SET(' & pPointer & ')') .
  obj.Set(pKey,pPointer)
  Return

!------------------------------------------------------------------------------------------------
SET                Procedure(KEY pKey,KEY pStart,*BIGINT pPointer)
obj      &DriverFileClass
  code
  obj &= pKey{prop:object}
  If obj &= null
    SET(pKey,pStart,pPointer+0)
    Return
  End
  If obj._logClarion then obj.Log('[CLAR]SET(key,key,' & pPointer & ')') .
  obj.Set(pKey,pStart,pPointer)
  Return

!------------------------------------------------------------------------------------------------
SETCUSTOMTYPE      Procedure(FILE pFILE,String pFieldLabel, iDriverField pCustom)
obj      &DriverFileClass
  code
  obj &= pFile{prop:object}
  If obj &= null
    ClaSetError(NoDriverSupport)
    Return
  End
  If Numeric(pFieldLabel)
    If obj._logClarion then obj.Log('[CLAR]SETCUSTOMTYPE(' & clip(pFieldLabel) & ',address)') .
    pFile{prop:interface,pFieldLabel} = address(pCustom)
  Else
    If obj._logClarion then obj.Log('[CLAR]SETCUSTOMTYPE(' & clip(pFieldLabel) & ',iCustom)') .
    obj.SetCustomType(pFieldLabel,pCustom)
  End  
  Return

!------------------------------------------------------------------------------------------------
SKIP64           Procedure(FILE pFile,BIGINT pFilePointer)
obj      &DriverFileClass
  code
  obj &= pFile{prop:object}
  If obj &= null 
    ClaSetError(NoDriverSupport)
    Return 
  End            
  If obj._logClarion then obj.Log('[CLAR]SKIP(' & pFilePointer & ')') .
  obj.Skip(pFilePointer)
  Return

!------------------------------------------------------------------------------------------------
SQL              Procedure(FILE pFILE,String pSql,<? pParm1>,<? pParm2>,<? pParm3>,<? pParm4>,<? pParm5>,<? pParm6>,<? pParm7>,<? pParm8>,<? pParm9>,<? pParm10>,<? pParm11>,<? pParm12>,<? pParm13>,<? pParm14>,<? pParm15>)
obj      &DriverFileClass
  code
  obj &= pFile{prop:object}
  If obj &= null 
    ClaSetError(NoDriverSupport)
    Return
  End
  If obj._logClarion then obj.Log('[CLAR]SQL(' & clip(pSQL) & ')') .
  obj.Sql(pSql,pParm1,pParm2,pParm3,pParm4,pParm5,pParm6,pParm7,pParm8,pParm9,pParm10,pParm11,pParm12,pParm13,pParm14,pParm15)
  Return
                 
!------------------------------------------------------------------------------------------------
SUBSET              Procedure(FILE pFILE,*? pParm1,<*? pParm2>,<*? pParm3>,<*? pParm4>,<? pParm5>,<? pParm6>,<? pParm7>,<? pParm8>,<? pParm9>,<? pParm10>)
obj      &DriverFileClass
  code
  obj &= pFile{prop:object}
  If obj &= null 
    ClaSetError(NoDriverSupport)
    Return
  End
  If obj._logClarion then obj.Log('[CLAR]SUBSET(parm(s))') .
  obj.Subset(pParm1,pParm2,pParm3,pParm4,pParm5,pParm6,pParm7,pParm8,pParm9,pParm10)  
  Return  

!------------------------------------------------------------------------------------------------
SUSPENDRELATIONS        Procedure(FILE pFile)
obj      &DriverFileClass
  Code
  obj &= pFile{prop:object}
  If obj &= null
    ClaSetError(NoDriverSupport)
    Return
  End
  If obj._logClarion then obj.Log('[CLAR]SUSPENDRELATIONS()') .
  obj.SuspendRelations()
  Return
                 
!------------------------------------------------------------------------------------------------
ToQueue           Procedure(FILE pFile,Queue pQueue)
obj      &DriverFileClass
  code
  obj &= pFile{prop:object}
  If obj &= null
    ClaSetError(NoDriverSupport)
    Return
  End
  If obj._logClarion then obj.Log('[CLAR]TOQUEUE(queue)') .
  obj.ToQueue(pQueue)
  Return
  
!------------------------------------------------------------------------------------------------
FromQueue         Procedure(FILE pFile,Queue pQueue)
obj      &DriverFileClass
  code
  obj &= pFile{prop:object}
  If obj &= null
    ClaSetError(NoDriverSupport)
    Return
  End
  If obj._logClarion then obj.Log('[CLAR]FROMQUEUE(queue)') .
  obj.FromQueue(pQueue)
  Return

!------------------------------------------------------------------------------------------------
UNION              Procedure (FILE pFile,<String pFilter>)
obj      &DriverFileClass
  code
  obj &= pFile{prop:object}
  If obj &= null 
    ClaSetError(NoDriverSupport)
    Return 
  End
  If obj._logClarion then obj.Log('[CLAR]UNION(' & clip(pFilter) & ')') .
  obj.Union(pFilter)             
  Return   
  
!------------------------------------------------------------------------------------------------
UPDATE            Procedure(File pFile,String pFilter,*? pField1,String pValue1,<*? pField2>,<String pValue2>,<*? pField3>,<String pValue3>,<*? pField4>,<String pValue4>,<*? pField5>,<String pValue5>,<*? pField6>,<String pValue6>,<*? pField7>,<String pValue7>,<*? pField8>,<String pValue8>,<*? pField9>,<String pValue9>,<*? pField10>,<String pValue10>)
obj      &DriverFileClass
  code
  obj &= pFile{prop:object}
  If obj &= null 
    ClaSetError(NoDriverSupport)
    Return
  End  
  If obj._logClarion then obj.Log('[CLAR]UPDATE(' & clip(pFilter) & ')') .
  obj.Update(pFilter,pField1,pValue1,pField2,pValue2,pField3,pValue3,pField4,pValue4,pField5,pValue5,pField6,pValue6,pField7,pValue7,pField8,pValue8,pField9,pValue9,pField10,pValue10)
  Return

!------------------------------------------------------------------------------------------------
UPDATE            Procedure(Key pKey,*? pField1,String pValue1,<*? pField2>,<String pValue2>,<*? pField3>,<String pValue3>,<*? pField4>,<String pValue4>,<*? pField5>,<String pValue5>,<*? pField6>,<String pValue6>,<*? pField7>,<String pValue7>,<*? pField8>,<String pValue8>,<*? pField9>,<String pValue9>,<*? pField10>,<String pValue10>)
obj      &DriverFileClass
  code
  If pKey &= null 
    ClaSetError(NoDriverSupport)
    Return
  End  
  obj &= pKey{prop:object}
  If obj &= null 
    ClaSetError(NoDriverSupport)
    Return
  End  
  If obj._logClarion then obj.Log('[CLAR]UPDATE(key)') .
  obj.Update(pKey,pField1,pValue1,pField2,pValue2,pField3,pValue3,pField4,pValue4,pField5,pValue5,pField6,pValue6,pField7,pValue7,pField8,pValue8,pField9,pValue9,pField10,pValue10)
  Return

!------------------------------------------------------------------------------------------------
UPSERT            Procedure(FILE pFile)  
obj      &DriverFileClass
  code
  obj &= pFile{prop:object}
  If obj &= null 
    ClaSetError(NoDriverSupport)
    Return
  End  
  If obj._logClarion then obj.Log('[CLAR]UPSERT()') .
  obj.Upsert()
  Return
  
!------------------------------------------------------------------------------------------------
  
                                                                                                                              