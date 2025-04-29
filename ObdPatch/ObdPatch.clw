!--------------------------------------------------------------------------------------------!
!                                                                                            !
!   OBDPatch is a utility to patch Object Based File Drivers after they have been compiled.  !
!   Copyright © 2025 by CapeSoft Software                                                    !
!   Released under the MIT License                                                           !
!                                                                                            !
!--------------------------------------------------------------------------------------------!
!
!  command line parameters
!     -d=DriverDLLName       ! (required) full path name to Driver.DLL
!     -c=driver.Clw          ! (optional) CLW containing equate "TDescAddress Equate(???)". 
!     -w=1                   ! (optional) Write back the DLL with the correct TDesc value embedded
!
!--------------------------------------------------------------------------------------------!
! CLW will not be edited if DLL is correct
! CLW will not be edited if -c parameter is not included
! DLL will not be edited if -w parameter is not set 
!
! Output goes to console, and DebugView
!--------------------------------------------------------------------------------------------!

  PROGRAM

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

  include('StringTheory.Inc'),Once

STD_OUTPUT_HANDLE          Equate(-11)    
ATTACH_PARENT_PROCESS      Equate(-1)
  
console                    Long
Err                        Long 
x                          Long
Result                     Long

dllFileName                cString(256)
clwFileName                cString(256)  
writeBack                  byte  
  
str                        StringTheory
lne                        StringTheory
addr                       Long
sec                        Long
tDescAddress               Long
st4                        string(4),over(tDescAddress)
tDescOffset                Long


MsDosHeader                Group
e_magic                      String(2)
e_cblp                       Short
e_cp                         Short
e_crlc                       Short
e_cparhdr                    Short
e_minalloc                   Short
e_maxalloc                   Short
e_ss                         Short
e_sp                         Short
e_csum                       Short
e_ip                         Short
e_cs                         Short
e_lfarlc                     Short
e_ovno                       Short
e_res                        String(8)
e_oemid                      Short
e_oeminfo                    Short
e_res2                       String(20)
e_lfanew                     Long
                           End               ! File offset to the PE header (the "NT Header" or "PE Signature").

PESig                      String(4)         ! This comes before the COFF Header

COFFHeader                 Group
Machine                      Short
NumberOfSections             Short
TimeDateStamp                Long
PointerToSymbolTable         Long
NumberOfSymbols              Long
SizeOfoptionalHeader         Short
Characteristics              Short
                           End

OptionalHeader             Group
Magic                        String(2)
MajorLinkerVersion           Byte
MinorLinkerVersion           Byte
SizeOfCode                   Long
SizeOfInitialisedData        Long
SizeOfUnInitialisedData      Long
AddressOfEntryPoint          Long
BaseOfCode                   Long
BaseOfData                   Long
ImageBase                    Long
SectionAlignment             Long
FileAlignment                Long
MajorOperatingSystemVersion  Short
MinorOperatingSystemVersion  Short
MajorImageVersion            Short
MinorImageVersion            Short
MajorSubSystemVersion        Short
MinorSubSystemVersion        Short
Win32VersionValue            Long
SizeOfImage                  Long
SizeOfHeaders                Long
CheckSum                     Long
SubSystem                    Short    
DllCharacteristics           Short
SizeOfStackReserve           Long
SizeOfStackCommit            Long
SizeOfHeapReserve            Long
SizeOfHeapCommit             Long
LoaderFlags                  Long
NumberOfRvaAndSizes          Long
                           End

SectionTableEntry          Group
name                         cstring(8)
VirtualSize                  long
VirtualAddress               long
SizeOfRawData                long
PointerToRawData             long
                           End

marker1       Long
marker2       Long  
changed       Byte


  CODE        

  console = AttachConsole(ATTACH_PARENT_PROCESS)
  
  console = GetStdHandle(STD_OUTPUT_HANDLE)
  
  
  dllFileName = command('-d')
  clwFileName = command('-c')
  writeBack = command('-w')

  WriteOut('')
  WriteOut('=================================================================')
  WriteOut('OBD Patcher - Update TDescAddress in OBD File Driver. Version 1.0')
  WriteOut('=================================================================')

  If dllFileName = ''
    WriteOut('DLL Filename not set. Use -d. Operation aborted.')
    WriteOut('')
    WriteOut('-d=name  DLL Name')
    WriteOut('-w=1     Write new address to DLL')
    WriteOut('-c=name  CLW Name (file will be altered)')    
    WriteOut('Press Enter to continue')        
    Return 
  End  

  If not Exists(dllFileName) 
    WriteOut('DLL File not found. [' & dllFileName & ']. Operation aborted.')
    Return 
  End  
  If writeBack = false
    WriteOut('DLL:' & dllFileName)
  End  
  str.LoadFile(dllFileName)

  ! first read the MS Dos header, and confirm it's a valid PE file.
  
  MsDosHeader = sub(str,1,size(MsDosHeader))
  If MsDosHeader.e_magic <> 'MZ'
    WriteOut('File not a DLL. [' & dllFileName & ']. First 2 bytes not MZ. Operation aborted.')
    Return 
  End  
  
  PESig = str.sub(MsDosHeader.e_lfanew+1,4)
   
  If PESig <> 'PE<0,0>' 
    WriteOut('File not a DLL. PE Signature not not PE00. Operation aborted. ')
    Return 
  End  
  
  COFFHeader = str.sub(MsDosHeader.e_lfanew+4+1,size(COFFHeader))
  
  If COFFHeader.SizeOfoptionalHeader <> 224
    WriteOut('Size of Optional Header is ' & COFFHeader.SizeOfOptionalHeader & '. Expected size is 224. Operation aborted.')
    Return 
  End  
  
  OptionalHeader = str.sub(MsDosHeader.e_lfanew + 4 + size(COFFHeader) + 1 , size(OptionalHeader))
  
  addr = MsDosHeader.e_lfanew + 4 + size(COFFHeader) + COFFHeader.SizeOfoptionalHeader
  
  Marker1 = str.Instring('CAP3S0FT')
  Marker2 = str.Instring('CAPESOF2')
  
  Loop sec = 0 to COFFHeader.NumberOfSections - 1
    SectionTableEntry = str.sub(1 + addr + sec * 40, 40) 
    If SectionTableEntry.name <> '.data' then cycle.
    tDescAddress = Marker1 - SectionTableEntry.PointerToRawData + SectionTableEntry.VirtualAddress + OptionalHeader.ImageBase + 8 - 1
    break
  End  
  
  
  tDescOffset = Marker2 + 178
  
  If writeBack
    If str.Slice(tDescOffset , tDescOffset + 3) = st4
      WriteOut('DLL: [' & dllFileName & '] not changed. tDescAddress is already set to ' & str.LongToHex(tDescAddress) & 'h.')
      changed = false
    Else
      str.SetSlice(tDescOffset , tDescOffset + 3, st4)
      str.SaveFile(dllFileName)
      WriteOut('DLL: [' & dllFileName & '] updated. tDescAddress = ' & str.LongToHex(tDescAddress) & 'h.')
      changed = false
    End  
  End
  If Writeback = false and clwFileName = ''
    WriteOut('tDescAddress = ' & str.LongToHex(tDescAddress) & 'h.')  
  End  
  
  If clwFileName !and changed = true
    If not exists(clwFileName)
      WriteOut('CLW File not found. [' & clwFileName & ']. Operation aborted.')
      Return 
    End  
    str.loadFile(clwFileName)
    lne.SetValue(left(str.Between('TDescAddress',')')))
    lne.SetValue(left(lne.After('Equate(')))
    If lne.GetValue() = str.LongToHex(tDescAddress) & 'h'
      WriteOut('CLW: [' & clwFileName & '] not updated. tDescAddress Equate already ' & lne.GetValue())
    Else
      Loop x = 1 to 5
        result = str.ReplaceBetween('TDescAddress' & all(' ',x) & 'Equate(',')','', str.LongToHex(tDescAddress) & 'h',1,1,0,st:nocase,st:replaceAll)
        If result then break.
      End  
      If result
        str.SaveFile(clwFileName)
        WriteOut('CLW: [' & clwFileName & '] updated. tDescAddress = ' & str.LongToHex(tDescAddress) & 'h.')
      Else
        WriteOut('CLW: [' & clwFileName & '] not updated. tDescAddress Equate not found.')
      End
    End  
  End  
  
  FreeConsole()
  Return 

!-------------------------------------------------------------------------  
WriteOut  procedure(String pString)
output   cString(size(pString)+5)
written  Long
  code
  output = pString & '<13,10>'
  WriteFile(console,output,len(clip(output)),written,0)
  str.Trace(clip(output))
!-------------------------------------------------------------------------  

  