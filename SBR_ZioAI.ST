AutoShop            2.4  5.03                                                                                                           ��  CLVTItem              �             �             �             �(* ZIOģ��������ģ��EEPROM��д�����ԡ�У׼�ӳ��� *)

CASE iZioAIItem OF
	0:    (* System initialization *)
	;
	
	1:    (* ZIO module test *)
	SBR_AITEST();
	
	2:    (* EEPROM read write *)
	;//SBR_EEPROMRW();
	
	3:    (* ZIO module calibration *)
	;//SBR_AICAL();
	
ELSE
	; 
END_CASE;    