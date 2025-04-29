!------------------------------------------------------------------------------------------------
!   CapeSoft Clarion File Driver Kit classes are copyright © 2025 by CapeSoft                   !
!   Docs online at : https://capesoft.com/docs/Driverkit/ClarionObjectBasedDrivers.htm
!   Released under MIT License
!------------------------------------------------------------------------------------------------

  PROGRAM

  Include('StringTheory.Inc'),Once

  MAP
  END
  
  PRAGMA('compile(ojmd5.c)')
  Omit('***',_C90_)
  PRAGMA('link(winex.lib)')
  !*** 
  CODE
