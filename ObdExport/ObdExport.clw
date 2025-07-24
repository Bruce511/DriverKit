!--------------------------------------------------------------------------------------------!
!                                                                                            !
!   OBDExport is a utility to generate EXP files from hand-coded class INC files             !
!   Copyright © 2025 by CapeSoft Software                                                    !
!   Released under the MIT License                                                           !
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
x          long
y          long
inClass    cstring(255)
proc       cstring(255)
mangle     StringTheory
ref          byte
omitable     byte
array        byte
append       byte
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
  append = command('-a')
  If incFileName = '' or expFileName = '' or libraryname = ''
    WriteOut('Parameters not set. Operation aborted.')
    WriteOut('')
    WriteOut('-i=name  INC Name (include extension)')
    WriteOut('-e=name  EXP Name (include extension)')
    WriteOut('-l=name  Library Name (no extension)')
    WriteOut('-a=1     Append to existing EXP')
    WriteOut('-d=name  Driver Name (optional - only for Drivers) (eg DOS2 or SQLite2 etc)')
    WriteOut('-b=hexaddress  Address for Image Base (optional) (eg 7E0000H)')
    WriteOut('Press Enter to continue')
    FreeConsole()
    Return
  End

  drivername = command('-d')
  imagebase = upper(command('-b'))

  str.loadfile(incFileName)
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
    lne.SetBefore('!')
    lne.SplitIntoWords(1,st:text,'. <13><10><9>,-;"''!?&()*/+=<>')
    case upper(lne.Getline(2))
    of 'CLASS'
      !out.append('; Class: ' & lne.GetLine(1) & ' ',,'<13,10>')
      out.append('      VMT$' & upper(lne.GetLine(1)) & '                                              @?',,'<13,10>')
      out.append('      TYPE$' & upper(lne.GetLine(1)) & '                                             @?',,'<13,10>')
      inClass = upper(lne.GetLine(1))
    of 'PROCEDURE'
      mangle.SetValue('')
      prototype.SetValue(str.GetLine(x))
      If prototype.instring('name(''',1,1,0,st:nocase)
        mangle.SetValue(prototype.Between('name(''',''')',1,0,st:nocase))
        out.append('      ' & mangle.GetValue() & '   @?',,'<13,10>')
      Else
        prototype.SetBetween('(',')',,,,,true)
        if prototype.length()
          prototype.Split(',')
          loop y = 1 to records(prototype)
            do AddMangle
          end
        End
        proc = upper(lne.GetLine(1))
        out.append('      ' & proc &'@F' & Len(inClass) & inClass & mangle.GetValue() & '   @?',,'<13,10>')
      end
    End
  End
  out.savefile(expFileName,append)
  WriteOut('EXP: [' & clip(expFileName) & '] updated.')
    FreeConsole()
  return

AddMangle  routine
  parameter.SetValue(left(upper(Prototype.GetLine(y))))
  parameter.split(' ')
  !str.trace('p: ' & Parameter.GetLine(1) & '|' & parameter.getline(2))
  name = left(upper(parameter.GetLine(1)))
  ref = false
  omitable = false
  array = false
  if sub(name,1,1) = '<'
    omitable = true
    name = sub(name,2,255)
    if right(name,1) = '>'
      name = sub(name,1,len(name)-1)
    end
  end
  if sub(name,1,1) = '*'
    ref = true
    name = sub(name,2,255)
  end
  if instring('[',name,1,1)
    array = TRUE
    name = sub(name,1,instring('[',name,1,1)-1)
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
  if array
    mangle.append('A')
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


