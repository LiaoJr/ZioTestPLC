AutoShop            2.4  5.03                                                                                                           ��  CLVTItem              �             �             �             �(* ZIO���������ģ������ӳ��� *)

CASE iZioDOItem OF
	0:    (* System initialization *)
	;
	
	1:    (* ZIO module test *)
	SBR_DOTEST();
	
	2:    (* ZIO module calibration *)
	;(* No calibration for DO module *)
	
	3:(* EEPROM read write *)
	;//SBR_EEPROMRW();
	
ELSE
	; 
END_CASE;    