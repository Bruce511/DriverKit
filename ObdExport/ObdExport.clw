!--------------------------------------------------------------------------------------------!
!                                                                                            !
!   OBDExport is a utility to generate EXP files from hand-coded class INC files             !
!   Copyright © 2025 by CapeSoft Software                                                    !
!   Released under the MIT License                                                           !
!   Version 1.09                                                                             !
!                                                                                            !
!--------------------------------------------------------------------------------------------!
!--------------------------------------------------------------------------------------------!

  PROGRAM
  include('stringtheory.inc'),once

  MAP
    Module('Windows')
       AttachConsole(ulong dwProcessId), long, raw, pascal, name('AttachConsole'),dll(1)
       FreeConsole(), long, proc, raw, pascal, name('FreeConsole')
       GetStdHandle(long nStdHandle), ulong, proc, pascal, raw, name('GetStdHandle'),dll(1)
       CloseHandle(long hHandle), long, proc, raw, pascal, name('CloseHandle'),dll(1)
       GetLastError(), ulong, raw, pascal, name('GetLastError'),dll(1)
       WriteFile(long hFile, *cstring lpBuffer, long nNumberOfBytesToWrite, *long lpNumberOfBytesWritten, long lpOverlapped), long, proc, raw, pascal, Name('WriteFile')
    End
    WriteOut(String pString)
    CharFind(STRING pChar, STRING pText, *LONG OutCharPos),LONG,PROC  !Also Returns Char Position for IF. Replaces X=Instring('?',Txt,1,1) as CharFind('?',Txt,<X)
  END

STD_OUTPUT_HANDLE          Equate(-11)
ATTACH_PARENT_PROCESS      Equate(-1)

console                    Long
Err                        Long
Result                     Long

str        stringtheory
lne        stringtheory
out        stringtheory
prototype  stringtheory
parameter  stringtheory
CharPos    long             !Use with CharFind('*',Name,CharPos)
x          long
y          long
inClass    cstring(255)
proc       cstring(255)
mangle     StringTheory
ref          byte
omitable     byte
arrayDims    byte           !Count of Array Dims []=1 [,]=2 [,,]=3 which mangles as A AA AAA
append       byte
verboseEXP   byte           !-v=1 adds "; comments" to EXP with original prototype, etc
verboseIndent EQUATE(' {50} ;  ')
name         cstring(255)
incFileName  String(255)
expFileName  String(255)
libraryName  cString(255)
driverName   cString(255)
imagebase    cString(255)

  CODE
  str.trace('path=' & longpath())
  str.trace('command(0)=' & command(0))
  console = AttachConsole(ATTACH_PARENT_PROCESS)
  console = GetStdHandle(STD_OUTPUT_HANDLE)

  WriteOut('')
  WriteOut('=================================================================')
  WriteOut('OBD Export - Generate EXP file from Class INC file               ')
  WriteOut('=================================================================')


  incFileName = command('-i')
  expFileName = command('-e')
  libraryName = upper(command('-l'))
  append      = command('-a')
  driverName  = command('-d')
  imagebase   = upper(command('-b'))
  verboseEXP  = command('-v')            !Carl added to add ; Prototype to EXP

  If incFileName = '' or expFileName = '' or libraryname = ''
    WriteOut('Parameters not set. Operation aborted.')
    WriteOut('')
    WriteOut('-i=name  INC Name (include extension) -i=' & CHOOSE(~incFileName,'Not Set / Required',CLIP(incFileName)) )
    WriteOut('-e=name  EXP Name (include extension) -e=' & CHOOSE(~expFileName,'Not Set / Required',CLIP(expFileName)) )
    WriteOut('-l=name  Library Name (no extension)  -l=' & CHOOSE(~libraryname,'Not Set / Required',CLIP(libraryname)) )
    WriteOut('-a=1     Append to existing EXP file  ' & CHOOSE(~append,'','-a=' & append))
    WriteOut('-d=name  Driver Name (optional) (only for Drivers, eg DOS2 or SQLite2 etc) '& CHOOSE(~driverName,'','-d=' & CLIP(driverName)) )
    WriteOut('-b=hex   Address for Image Base (optional) (eg 007E0000H) '& CHOOSE(~imagebase,'','-b=' & CLIP(imagebase)) )
    WriteOut('-v=1     Verbose EXP with Comments '  & CHOOSE(~verboseEXP,'','-v=' & verboseEXP))
    IF Command() THEN WriteOut('<13,10>Command Line: '& Command() ).
    WriteOut('={65}')
    WriteOut('Press Enter to continue')
    FreeConsole()
    Return
  End

  If ~str.loadfile(incFileName) Then    !Carl catch that Load failed and tell user
      WriteOut('Operation aborted. Failed to Load INC File: '& clip(incFileName))
      WriteOut(Str.LastError)
      If str.winErrorCode Then
         WriteOut('Win Error Code: '& str.winErrorCode &': '& str.FormatMessage(str.WinErrorCode))
      End
      WriteOut('Press Enter to continue')
      FreeConsole()
      Return
  End

  str.split('<13,10>')
  If not append
    out.append('LIBRARY '''& libraryName &''' GUI',,'<13,10>')
    if imagebase
      out.append('IMAGE_BASE ' & imageBase,,'<13,10>')
    end
    out.append('EXPORTS',,'<13,10>')
    If drivername
      out.append('  ' & DriverName & '$DrvReg    @?',,'<13,10>')
      out.append('  ' & DriverName & '           @?',,'<13,10>')
    End
  else
    out.append('<13,10>')
  End
  Loop x = 1 to str.records()
    lne.SetValue(str.GetLine(x))     
    If lne.After('!') = 'EXPORT'
    Else
      lne.SetBefore('!')
    End  
    lne.SplitIntoWords(1,st:text,'. <13><10><9>,-;"''!?&()*/+=<>')
    case upper(lne.Getline(2))
    of 'CLASS'
      IF verboseEXP THEN out.append(verboseIndent & LEFT(lne.GetValue()),,'<13,10>' ).
      !out.append('; Class: ' & lne.GetLine(1) & ' ',,'<13,10>')
      out.append('      VMT$' & upper(lne.GetLine(1)) & '                                              @?',,'<13,10>')
      out.append('      TYPE$' & upper(lne.GetLine(1)) & '                                             @?',,'<13,10>')
      inClass = upper(lne.GetLine(1))
    of 'PROCEDURE'
    orof 'FUNCTION'
      If verboseEXP THEN out.append(verboseIndent & LEFT(lne.GetValue()),,'<13,10>' ).
      mangle.SetValue('')
      prototype.SetValue(str.GetLine(x))
      If prototype.instring('name(''',1,1,0,st:nocase)
        mangle.SetValue(prototype.Between('name(''',''')',1,0,st:nocase))
        out.append('      ' & mangle.GetValue() & '   @?',,'<13,10>')
      Else
        prototype.SetBetween('(',')',,,,,true)
        if prototype.length()
          prototype.Split(',','[',']')   !Carl added '[',']' for 2D Array PROCEDURE(*LONG[,] A2dim) the [commas] would confuse Split and add extra parameter "]"
          loop y = 1 to records(prototype)
            do AddMangle
          end
        End
        proc = upper(lne.GetLine(1))
        If inClass Then                               !If in MAP then InClass='' so this prevents @F0 (@ F Zero)
           mangle.Prepend(Len(inClass) & inClass)     !Add Class SELF first as "##ClassName"
        End
        out.append('      ' & proc &'@F' & mangle.GetValue() & '   @?',,'<13,10>')
      end
    End
    Case upper(lne.Getline(3))
    Of 'EXPORT'
      out.append('      $' & upper(lne.GetLine(1)) & '                                              @?',,'<13,10>')    
    End
  End
  If verboseEXP THEN            !Carl: maybe always add this footer?  If so I would add the Date Stamp of the INC file.
     out.append('<13,10>')
     out.append('; Made by ObdExport '& CLIP(FORMAT(TODAY(),@D4)) &' '& FORMAT(CLOCK(),@t3)&' from INC: '& incFileName ,,'<13,10>')
     out.append('; Command: '& Command('0') &'  '& Command() ,,'<13,10>')
  End

  If ~out.savefile(expFileName,append) Then
      WriteOut('Operation aborted. Failed to Save EXP File: '& clip(expFileName))
      WriteOut(out.LastError)
      If out.winErrorCode Then
         WriteOut('Win Error Code: '& out.winErrorCode &': '& out.FormatMessage(out.WinErrorCode))
      End
      WriteOut('Press Enter to continue')
      FreeConsole()
      return
  End

  WriteOut('EXP: [' & clip(expFileName) &'] '& CHOOSE(~append,'created','appended') &|
           ' from ['& CLIP(incFileName) &'] '& CHOOSE(~driverName,'','for Driver ['& driverName &']') )
  FreeConsole()
  return

AddMangle  routine
  parameter.SetValue(left(upper(Prototype.GetLine(y))))
  name = clip(parameter.GetValue())
  ref = false
  omitable = false
  arrayDims = 0
  if sub(name,1,1) = '<'                     !Is it? "<*STRING S4>" i.e. omittable
    omitable = true
    name = clip(left(sub(name,2,255)))       !Remove leading "<"
    if right(name,1) = '>'                   !Is it? "*STRING S4>" i.e. trailing ">"
      name = clip(sub(name,1,len(name)-1))   !Remove trailing ">"
    end                                      !now==  "*STRING S4" without "<>"
  end
  if sub(name,1,6) = 'CONST ' then           !Is it? "CONST *DECIMAL Label" - CONST has NO mangle affect but hides the Type
    name = clip(left(sub(name,7,255)))       !now==        "*DECIMAL Label"
  end
  if sub(name,1,1) = '*'                     !Is it? "*DECIMAL Label" i.e. * = by address / ref
    ref = true
    name = clip(left(sub(name,2,255)))       !now==   "DECIMAL Label" without "*"
  end
  if CharFind('[',name,CharPos)              !Is it? "LONG[,] Label" i.e. an Array  (note: always by address "*LONG[,]: but the "*" cutoff above)
    arrayDims = 1 + parameter.Count(',')     !                        Array[,] - Each Dim gets 1 'A' in mangle e.g. "*LONG [,]" => AA
    name = clip(sub(name,1,CharPos-1))       !now==  "LONG" i.e. cutoff "[,] Label"
  end
  if CharFind('=',name,CharPos)              !Is it? "TYPE=Default" i.e. "=Default" without Label
    name = clip(sub(name,1,CharPos-1))       !now==  "TYPE"         without "=Default"
  end
  if CharFind(' ',name,CharPos)              !Is it? "TYPE Label" with a Space between?
    name = clip(sub(name,1,CharPos-1))       !now==  "TYPE"       without Label"
  end
  !mangle.append('_' & name & '_')
  case name
  of 'BYTE'
    do prepend
    mangle.append('Uc')
  of 'SHORT'
    do prepend
    mangle.append('s')
  of 'USHORT'
    do prepend
    mangle.append('Us')
  of 'LONG'
  orof 'UNSIGNED'
  orof 'SIGNED'
  orof 'BOOL'
    do prepend
    mangle.append('l')
  of 'ULONG'
    do prepend
    mangle.append('Ul')
  of 'DATE'
    do prepend
    mangle.append('bd')
  of 'TIME'
    do prepend
    mangle.append('bt')
  of 'DECIMAL'
    do prepend
    mangle.append('e')
  of 'PDECIMAL'
    do prepend
    mangle.append('p')
  of 'SREAL'
    do prepend
    mangle.append('f')
  of 'REAL'
  orof 'BIGINT'
    do prepend
    mangle.append('d')
  of '?'
  orof 'ANY'
    do prepend
    mangle.append('u')
  of 'STRING'
    do prepend
    mangle.append('sb')
  of 'CSTRING'
    do prepend
    mangle.append('sc')
  of 'PSTRING'
    do prepend
    mangle.append('sp')
  of 'ASTRING'
    do prepend
    mangle.append('sa')
  of 'BSTRING'
    do prepend
    mangle.append('sw')
  of 'GROUP'
    do prepend
    mangle.append('g')
  of 'FILE'
    mangle.append('Bf')
  of 'VIEW'
    mangle.append('Bi')
  of 'BLOB'
    mangle.append('Bb')
  of 'KEY'
  orof 'INDEX'
    mangle.append('Bk')
  of 'QUEUE'
    mangle.append('Bq')
  of 'REPORT'
    mangle.append('Br')
  of 'WINDOW'
    mangle.append('Bw')
  else
    mangle.append(len(name) & name)
  end

prepend  routine
  if omitable and ref
    mangle.append('P')
  elsif ref
    mangle.append('R')
  elsif omitable
    mangle.append('O')
  end
  if arrayDims
    mangle.append(all('A',arrayDims))  ! Need 1 'A' per Dim so []=>'A'  [,]=>'AA'
  end

!-------------------------------------------------------------------------
WriteOut  procedure(String pString)
output   cString(size(pString)+5)
written  Long
  code
  output = pString & '<13,10>'
  WriteFile(console,output,len(clip(output)),written,0)
  str.Trace(clip(output))
!-------------------------------------------------------------------------
CharFind PROCEDURE(STRING pChar, STRING pText, *LONG OutCharPos) !,LONG,PROC  Returns Position Also as a kind of True/False
    CODE
    OutCharPos = instring(pChar,pText,1,1)
    RETURN OutCharPos

