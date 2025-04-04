AutoShop            2.4  5.03                                                                                                           ��  CLVTItem              �             �             �             �G6(* 
 * @brief  DIģ������ӳ���
 * @Result_DIs ���ʽʽģ����Խ����
 *			Result_DIs        : 0->not test yet, 1->success, 2->failed
 *          Result_Eeprom_DI  : 0->not test yet, 1->success, 2->failed
 *          Result_Ecat_DI    : 0->not test yet, 1->success, 2->failed
 *			Result_DIs_2ms    : 0->not test yet, 18->success, 1~16->4ms period failed, 17->command timeout
 *          Result_DIs_4ms    : 0->not test yet, 18->success, 1~16->4ms period failed, 17->command timeout
 *			Result_LEDs_DI    : 0->not test yet, 1->success, 2->failed, 3->LED confirm timeout
 *)

(* Timer *)
TACR(IN := TACR1_IN, PT := TACR1_PT, R := TACR1_R, Q => TACR1_Q, ET => TACR1_ET);
TPR(IN := TPR1_En, PT := TPR1_PT, R := TPR1_Rst, Q => TPR1_Q, ET => TPR1_ET);//for config timeout
TPR(IN := TPR2_En, PT := TPR2_PT, R := TPR2_Rst, Q => TPR2_Q, ET => TPR2_ET);//for total timeout
TPR(IN := TPR3_En, PT := TPR3_PT, R := TPR3_Rst, Q => TPR3_Q, ET => TPR3_ET);
TPR(IN := TPR4_En, PT := TPR4_PT, R := TPR4_Rst, Q => TPR4_Q, ET => TPR4_ET);
TPR(IN := TPR5_En, PT := TPR5_PT, R := TPR5_Rst, Q => TPR5_Q, ET => TPR5_ET);
TPR(IN := TPR6_En, PT := TPR6_PT, R := TPR6_Rst, Q => TPR6_Q, ET => TPR6_ET);//for LED confirm
TPR(IN := TPR7_En, PT := TPR7_PT, R := TPR7_Rst, Q => TPR7_Q, ET => TPR7_ET);//for ESI write
TPR(IN := TPR8_En, PT := TPR8_PT, R := TPR8_Rst, Q => TPR8_Q, ET => TPR8_ET);//for ESI read
TPR(IN := TPR9_En, PT := TPR9_PT, R := TPR9_Rst, Q => TPR9_Q, ET => TPR9_ET);//for test success beep
TPR(IN := TPR10_En, PT := TPR10_PT, R := TPR10_Rst, Q => TPR10_Q, ET => TPR10_ET);//for test failed beep
diTestTime := TACR1_ET / 1000;

if iMode = 0 THEN
	FB_ESI_Write1(WR_EN := ESI_WR_EN, 
				  esi_id_in := ESI_ID, 
				  SlavePos := 1, uid_in := 1, 
				  ESI_RET => ESI_WR_RET);
ELSIF iMode = 1 THEN
	FB_ESI_Read1(RD_EN := ESI_RD_EN,
             FileSize := 1024,
             SlavePos := 1,
             UID_OUT_H => UID_DI_h,
             UID_OUT_L => UID_DI_l,
             ESI_RET => ESI_RD_RET);
END_IF

FB_600E_DO_LEVEL0(cmd_en := DO_LEVEL0_EN, ch_in := 15, level_in := 1, cmd_ret => DO_LEVEL0_RET);//600E DO output 1
FB_600E_DO_LEVEL1(cmd_en := DO_LEVEL1_EN, ch_in := 15, level_in := 0, cmd_ret => DO_LEVEL1_RET);//600E DO output 0
FB_600E_DO_PWM_4ms(cmd_en := DO_PWM1_EN,  ch_in := 15, period_in := 4, duty_in := 2, cmd_ret => DO_PWM1_RET);
FB_600E_DO_PWM_8ms(cmd_en := DO_PWM2_EN,  ch_in := 15, period_in := 8, duty_in := 4, cmd_ret => DO_PWM2_RET);

if iLED_CF_Mode = 1 THEN  (* LED�ֶ���� *)
	FB_LED_MAN_DI(LED_MAN_IN := xLED_MAN_IN, LED_CF_IN := iLED_CF_IN, LED_RET => Result_LEDs_DI);
ELSIF iLED_CF_Mode = 0 THEN  (* LED�Զ���� *)
	FB_LED_WTX_DI(WTX_IN := xLED_WTX_IN, module_in := ModuleSel, LED_RET => Result_LEDs_DI);
END_IF

FB_DATA_LOG_DI(DL_EN := DL_EN, MD_SEL := ModuleSel, DL_RET => DL_RET);

CASE iDITestState OF
0:(*============================== DI module test init ==============================*)
	xPowerRelay := TRUE;
	DI();
	timer_disable();
	bDITestSuccess := FALSE;
	bDITestFailed := FALSE;
	
	DO_LEVEL0_EN := FALSE;
	DO_LEVEL1_EN := FALSE;
	DO_PWM1_EN := FALSE;
	DO_PWM2_EN := FALSE;
	
	UID_DI_h := 0;
	UID_DI_l := 0;
	Result_DIs := 0;
	Result_Eeprom_DI := 0;
	Result_Ecat_DI := 0;
	Result_DIs_2ms := 0;
	Result_DIs_4ms := 0;
	Result_LEDs_DI := 0;
	xDITestRecord := FALSE;
	
	ESI_WR_EN := FALSE;
	ESI_RD_EN := FALSE;
	xLED_MAN_IN := FALSE;
	iLED_CF_IN := 0;
	xLED_WTX_IN := FALSE;
	DL_EN := FALSE;
	
	xBeep := FALSE;
	iBarCnt := 0;
	
	for i := 0 to 15 by 1 DO
		iDI_Valid_Times[i] := 0;
	END_FOR
	
	(* Enable slave according to iZioDISel *)
	IF iZioDISel = 1 THEN  (* ZIOC-E1600DN *)
		ZCPC_80801.bDisableEnable := FALSE;
		ZIOC_E1600DN.bDisableEnable := FALSE;
		ZIOD_E0808DN_Aux.bDisableEnable := FALSE;
		ESI_ID := 8;
		PID_DO := 16#0101001A;
	ELSIF iZioDISel = 2 THEN  (* ZIOC-E1600DP *)
		ZCPC_80801.bDisableEnable := FALSE;
		ZIOC_E1600DP.bDisableEnable := FALSE;
		ZIOD_E0808DN_Aux.bDisableEnable := FALSE;
		ESI_ID := 9;
		PID_DO := 16#0101001B;
	ELSIF iZioDISel = 3 THEN  (* ZIOC-E0016DP-Pio *)
		ZCPC_80801_Pio.bDisableEnable := FALSE;
		ZIOC_E1600DP_Pio.bDisableEnable := FALSE;
		ZIOD_E0808DN_Aux.bDisableEnable := FALSE;
		ESI_ID := 14;
		PID_DO := 16#01010028;
	END_IF
	
1:(*============================== DI module test config ==============================*)
	xPowerRelay := FALSE;  //module power up
	bDITestSuccess := FALSE;
	bDITestFailed := FALSE;
	TACR1_IN := TRUE;
	TPR1_PT := diCfgTimeout;  //for config timeout
	TPR2_PT := diTestTimeout;  //for total timeout
	TPR1_En := TRUE;
	TPR2_En := TRUE;
	
	IF SerialNo = 0 and iMode = 0 THEN  (* �����Ա����������к� *)
		bSN_Input_Rq := TRUE;
		iDITestState := 0;
		TPR1_En := FALSE;
		TPR2_En := FALSE;
		TPR1_Rst := TRUE;
		TPR2_Rst := TRUE;
		RETURN;
	END_IF
	
	IF TPR1_ET > 3000 and iMode = 0 THEN  (* time for relay stable/naked board *)
		uid_get(module_in := ModuleSel, no_in := 1);
		ESI_WR_EN := TRUE;  //write ESI
	ELSIF TPR1_ET > 3000 AND iMode = 1 THEN  (* time for relay stable/shelled board *)
		ESI_RD_EN := TRUE;  //read ESI
	END_IF
	
	IF (ESI_WR_RET = 1) OR (ESI_RD_RET = 1) then
		IF TPR1_ET > 11000 AND TPR1_ET < 12000 THEN
			xPowerRelay := TRUE;  //Module power down
		ELSIF TPR1_ET > 12500 AND TPR1_ET < 13000 THEN
			xPowerRelay := FALSE;  //Modele power up
		ELSIF TPR1_ET > 15000 THEN
			_ECATMaster.bStartMaster := TRUE;  (* start the EtherCAT master========> *)
		ELSE
			xPowerRelay := FALSE;
		END_IF
	ELSIF ESI_WR_RET < 0 OR ESI_RD_RET < 0 THEN  (* ESI write/read failed *)
		Result_Eeprom_DI := -1;
		iDITestState := 7;
	ELSIF TPR1_ET = TPR1_PT AND (ESI_WR_RET = 0 or ESI_RD_RET = 0) THEN  (* ESI write/read failed *)
		Result_Eeprom_DI := -2;
		iDITestState := 7;
		RETURN;
	END_IF
	
	IF _ECATMaster.bMasterRunState = TRUE THEN
		iBarCnt := 20;
		TPR1_En := FALSE;
		ESI_WR_EN := FALSE;
		ESI_RD_EN := FALSE;
		Result_Eeprom_DI := 1;
		Result_Ecat_DI := 1;
		iDITestState := 2;  //go to next state
	END_IF
	
	if (TPR1_ET mod 1000 = 500) AND iBarCnt < 20 THEN  (* Progress bar control *)
		iBarCnt := iBarCnt + 1;  
	END_IF
	
	IF TPR1_ET = TPR1_PT THEN  (* DO module config timeout failed *)
		TPR1_En := FALSE;
		Result_Ecat_DI := -1;
		iDITestState := 7;
	END_IF
	
2:(*============================== DI module test process1 ==============================*)
	(*
	 * @brief 600E DO �����Ч��ƽ
	 *)
	TPR3_PT := 5000;
	TPR3_En := TRUE;
	IF TPR3_ET < 1000 THEN
		DO_LEVEL0_EN := TRUE;
	ELSIF DO_LEVEL0_RET < 0 THEN  (* 600E DO command failed *)
		TPR3_En := FALSE;
		DO_LEVEL0_EN := false;
		Result_DIs_2ms := -17;
		iDITestState := 7;
	END_IF
	
	IF DO_LEVEL0_RET = 1 THEN  (* 600E DO command success *)
		TPR3_En := FALSE;
		DO_LEVEL0_EN := false;
		iBarCnt := 25;
		iDITestState := 3;  //go to next state
	END_IF
	
	if TPR3_ET mod 1000 = 500 AND iBarCnt < 25 THEN   (* Progress bar control *)
		iBarCnt := iBarCnt + 1;
	END_IF
	
	IF TPR2_ET = TPR2_PT THEN  (* Total timer error *)
		TPR2_En := FALSE;
		Result_DIs_2ms := -17;
		iDITestState := 7;
	END_IF
	
3:(*============================== DI module test process2 ==============================*)
	(*
	 * @brief 600E DO ���4ms����PWM
	 *)
	TPR4_PT := 10000;
	TPR4_En := TRUE;
	IF TPR4_ET < 1000 THEN
		DO_PWM1_EN := TRUE;
	ELSIF DO_PWM1_RET < 0 THEN  (* 600E DO command failed *)
		TPR4_En := FALSE;
		DO_PWM1_EN := false;
		Result_DIs_2ms := -17;
		iDITestState := 7;
	END_IF
	
	IF DO_PWM1_RET = 1 THEN
		if iMode = 1 and iLED_CF_Mode = 1 THEN  (* װ�ǰ�LED�˹�ȷ�� *)
			TPR6_PT := diLED_Timeout;
			TPR6_En := TRUE;
			xLED_MAN_IN := TRUE;
		END_IF
		FOR i := 0 to 15 by 1 DO
			if iZioDISel = 1 AND xDI_N[i] = TRUE THEN  (* DI test failed *)
				TPR4_En := FALSE;
				DO_PWM1_EN := FALSE;
				Result_DIs_2ms := -1 - i;
				iDITestState := 7;  //DI test failed
				EXIT;
			ELSIF iZioDISel = 2 AND xDI_P[i] = TRUE THEN  (* DI test failed *)
				TPR4_En := FALSE;
				DO_PWM1_EN := FALSE;
				Result_DIs_2ms := -1 - i;
				iDITestState := 7;  //DI test failed
				EXIT;
			ELSIF iZioDISel = 3 AND xDI_P_Pio[i] = TRUE THEN  (* DI_Pio test failed *)
				TPR4_En := FALSE;
				DO_PWM1_EN := FALSE;
				Result_DIs_2ms := -1 - i;
				iDITestState := 7;  //DI test failed
				EXIT;
			END_IF
		END_FOR
		IF TPR4_ET = TPR4_PT THEN  (* DI 2ms test success *)
			TPR4_En := FALSE;
			DO_PWM1_EN := FALSE;
			iBarCnt := 55;
			Result_DIs_2ms := 1;
			iDITestState := 4;  //go to next state
		END_IF
	END_IF
	
	IF TPR4_ET mod 330 = 160 AND iBarCnt < 55 THEN  (* Progress bar control *)
		iBarCnt := iBarCnt + 1;
	END_IF
	
	if Result_LEDs_DI < 0 THEN  (* LED failed *)
		TPR6_En := FALSE;
		iDITestState := 7;
	END_IF
	
	IF TPR2_ET = TPR2_PT THEN  (* Total timer error *)
		TPR2_En := FALSE;
		Result_DIs_2ms := -17;
		iDITestState := 7;
	END_IF
	
4:(*============================== DI module test process3 ==============================*)
	(*
	 * @brief 600E DO ���8ms����PWM
	 *)
	TPR5_PT := 10000;
	TPR5_En := TRUE;
	IF TPR5_ET < 1000 THEN
		DO_PWM2_EN := TRUE;
	ELSIF  DO_PWM2_RET < 0 THEN  (* 600E DO command failed *)
		TPR5_En := FALSE;
		DO_PWM2_EN := false;
		Result_DIs_4ms := -17;
		iDITestState := 7;
	END_IF
	
	IF DO_PWM2_RET = 1 THEN
		IF TPR5_ET = TPR5_PT THEN
			for i := 0 to 15 by 1 DO
				IF iDI_Valid_Times[i] < 2200 THEN  (* DI test failed *)
					DO_PWM2_EN := FALSE;
					Result_DIs_4ms := -1 - i;
					TPR5_En := FALSE;
					iDITestState := 7;
					EXIT;
				ELSE  (* DI test success! *)
					TPR5_En := FALSE;
					DO_PWM2_EN := FALSE;
					iBarCnt := 85;
					Result_DIs_4ms := 1;
					if iMode = 0 THEN  (* ��岻��ҪLED���� *)
						Result_LEDs_DI := 1;
						Result_DIs := 1;  (* DI test success *)
						iDITestState := 7;  //go to the next state
					ELSIF iMode = 1 THEN  (* װ�ǰ����LED���� *)
						iDITestState := 5;  //go to next state
					ELSE
						iDITestState := 7;  //go to the next state
					END_IF
				END_IF
			END_FOR
		ELSE
			FOR i := 0 to 15 by 1 DO  (* scan DI valid level times *)
				if iZioDISel = 1 AND xDI_N[i] = TRUE THEN
					iDI_Valid_Times[i] := iDI_Valid_Times[i] + 1;
				ELSIF iZioDISel = 2 AND xDI_P[i] = TRUE THEN
					iDI_Valid_Times[i] := iDI_Valid_Times[i] + 1;
				ELSIF iZioDISel = 3 AND xDI_P_Pio[i] = TRUE THEN
					iDI_Valid_Times[i] := iDI_Valid_Times[i] + 1;
				END_IF
			END_FOR
		END_IF
	END_IF
	
	IF TPR5_ET mod 300 = 150 AND iBarCnt < 90 THEN  (* Progress bar control *)
		iBarCnt := iBarCnt + 1;
	END_IF

	if Result_LEDs_DI < 0 THEN  (* LED failed *)
		TPR6_En := FALSE;
		iDITestState := 7;
	END_IF

	IF TPR2_ET = TPR2_PT THEN  (* Total timer error *)
		TPR2_En := FALSE;
		Result_DIs_4ms := -17;
		iDITestState := 7;
	END_IF
	
5:(*============================== LED test ==============================*)
	DO_LEVEL1_EN := true;  (* DI������Ч��ƽ *)
	if DO_LEVEL1_RET < 0 THEN
		DO_LEVEL1_EN := FALSE;
		TPR6_En := FALSE;
		Result_LEDs_DI := -1;
		iDITestState := 7;
		RETURN;
	END_IF
	
	IF iLED_CF_Mode = 0 THEN  (* LED�Զ���ⷽʽ *)
		TPR6_PT := diLED_Timeout;
		TPR6_En := TRUE;
		if DO_LEVEL1_RET = 1 AND Result_LEDs_DI = 0 THEN
			xLED_WTX_IN := TRUE;
		END_IF
	END_IF
	
	if Result_LEDs_DI <> 0 THEN
		if Result_LEDs_DI = 1 THEN  (* DI LED test success *)
			Result_DIs := 1;  (* DI test success *)
		END_IF
		TPR6_En := FALSE;
		DO_LEVEL1_EN := FALSE;
		//xLED_MAN_IN := FALSE;
		//xLED_WTX_IN := FALSE;
		iDITestState := 7;
	END_IF
	
	IF TPR6_ET mod 1000 = 500 AND iBarCnt < 99 THEN  (* Progress bar control *)
		iBarCnt := iBarCnt + 1;
	END_IF
	
7:(*============================== datat log process ==============================*)
	result_error_get(module_in := ModuleSel);
	xDITestRecord := TRUE;
	DO_LEVEL0_EN := FALSE;
	TPR6_En := FALSE;
	TPR6_Rst := TRUE;
	
	TPR7_PT := 1000;
	TPR7_En := TRUE;
	if TPR7_ET = TPR7_PT THEN
		DL_EN := TRUE;
	END_IF
	IF DL_RET < 0 THEN
		TPR7_En := FALSE;
		iDITestState := 9;
	ELSIF DL_RET = 1 AND Result_DIs <> 1 THEN
		TPR7_En := FALSE;
		iDITestState := 9;
	ELSIF DL_RET = 1 AND Result_DIs = 1 THEN
		TPR7_En := FALSE;
		iDITestState := 8;
	END_IF
	
8:(*============================== DI module test success ==============================*)
	DO_LEVEL0_EN := TRUE;
	TACR1_IN := FALSE;
	TPR2_En := FALSE;
	iBarCnt := 100;
	bDITestSuccess := TRUE;
	
	TPR9_PT := 3000;
	TPR9_En := TRUE;
	if TPR9_ET mod 1000 < 5 THEN
		xBeep := FALSE;
	ELSIF TPR9_ET mod 1000 > 495 and TPR9_ET mod 1000 < 505 THEN
		xBeep := TRUE;
	END_IF

9:(*============================== DI module test failed ==============================*)
	DO_LEVEL0_EN := TRUE;
	TACR1_IN := FALSE;
	TPR2_En := FALSE;
	bDITestFailed := TRUE;
	
	TPR10_PT := 3000;
	TPR10_En := TRUE;
	if TPR10_ET < 3000 THEN
		xBeep := TRUE;
	ELSE
		xBeep := FALSE;
	END_IF

10:(*============================== ESI write ==============================*)
	IF SerialNo = 0 THEN
		bSN_Input_Rq := TRUE;
		iDITestState := 0;
		RETURN;
	END_IF
	
	ESI_WR_EN := TRUE;
	TPR7_PT := 10000;  //set ESI write timeout
	TPR7_En := TRUE;

	if TPR7_ET mod 100 = 0 AND iEsiBarCnt < 100 THEN  (* Progress bar control *)
		iEsiBarCnt := iEsiBarCnt + 1;
	END_IF
	
	IF TPR7_ET = TPR7_PT AND ESI_WR_RET = 0 THEN  (* timeout error *)
		ESI_WR_RET := -2;
	ELSIF TPR7_ET = TPR7_PT and ESI_WR_RET = 1 THEN  (* ESI write success *)
		bESI_WrSuccess := TRUE;
	END_IF

11:(*============================== ESI read ==============================*)
	ESI_RD_EN := TRUE;
	TPR8_PT := 9000;  //set ESI read timeout
	TPR8_En := TRUE;
	
	if TPR8_ET mod 90 = 0 AND iEsiBarCnt < 100 THEN  (* Progress bar control *)
		iEsiBarCnt := iEsiBarCnt + 1;
	END_IF
	
	IF TPR8_ET = TPR8_PT AND ESI_RD_RET = 0 THEN  (* timeout error *)
		ESI_RD_RET := -2;
	ELSIF TPR8_ET = TPR8_PT and ESI_RD_RET = 1 THEN  (* ESI write success *)
		bESI_RdSuccess := TRUE;
	END_IF

ELSE
	timer_reset();
	ESI_WR_EN := FALSE;
	ESI_RD_EN := FALSE;
	xDITestRecord := FALSE;
	
	_ECATMaster.bStopMaster := TRUE;
	if _ECATMaster.bMasterRunState = FALSE THEN
		xPowerRelay := TRUE;  //module power down
		iDITestState := 0;
	END_IF
END_CASE
    