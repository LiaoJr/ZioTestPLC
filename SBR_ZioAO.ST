AutoShop            2.4  5.03                                                                                                           ��  CLVTItem              �             �             �             �(* ZIO AOģ��EEPROM��д�����ԡ�У׼�ӳ��� *)

CASE iZioAOItem OF
	0:    (* System initialization *)
	;
	
	1:    (* ZIO module test *)
	SBR_AOTEST();
	
	2:    (* EEPROM read write *)
	;//SBR_EEPROMRW();
	
	3:    (* ZIO module calibration *)
	;//SBR_AOCAL();
	
	
	
ELSE
	; 
END_CASE;    