AutoShop            2.4  5.03                                                                                                           ��  CLVTItem              �             �             �             �(* ZIO���������ģ������ӳ��� *)

CASE iZioDDItem OF
	0:    (* System initialization *)
	;
	
	1:    (* EEPROM read write *)
	SBR_DDTEST();
	
	2:    (* ZIO module calibration *)
	;(* No calibration for DO module *)
	
	3:    (* ZIO module test *)
	;
	
ELSE
	;
END_CASE;
    