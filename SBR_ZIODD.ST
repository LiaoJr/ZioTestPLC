AutoShop            2.4  5.03                                                                                                           ��  CLVTItem              �             �             �             �"(* ZIO���������ģ������ӳ��� *)

CASE iZio8DI8DOItem OF
	0:    (* System initialization *)
	;
	
	1:    (* EEPROM read write *)
	;//SBR_EEPROMRW();
	
	2:    (* ZIO module calibration *)
	;(* No calibration for DO module *)
	
	3:    (* ZIO module test *)
	SBR_DDTEST();
	
ELSE
	;
END_CASE;
    