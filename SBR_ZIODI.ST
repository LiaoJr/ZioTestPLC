AutoShop            2.4  5.03                                                                                                           ��  CLVTItem              �             �             �             �(* ZIO����������ģ���ӳ��� *)

CASE iZioDIItem OF
	0:    (* System initialization *)
	;
	
	1:    (* EEPROM read write *)
	SBR_DITEST();
	
	2:    (* ZIO module calibration *)
	;(* No calibration for DO module *)
	
	3:
	;//SBR_EEPROMRW();
	
ELSE
	; 
END_CASE;
    