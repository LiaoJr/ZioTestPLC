AutoShop            2.4  5.03                                                                                                           ��  CLVTItem              �             �             �             �(* �����EEPROM��д�������ӳ��� *)

CASE iZioZCPItem OF
	0:    (* System initialization *)
	;
	
	1:    (* EEPROM read write *)
	SBR_CPTEST();
	
	2:    (* ZIO module calibration *)
	;(* No calibration for DO module *)
	
	3:    (* ZIO module test *)
	;
	
ELSE
	; 
END_CASE;
    