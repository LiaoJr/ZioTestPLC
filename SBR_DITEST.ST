AutoShop            2.4  5.03                                                                                                           ��  CLVTItem              �             �             �             �wI(* 
 * @brief  DIģ������ӳ���
 * @Result_DIs ���ʽʽģ����Խ����
 *			Result_DIs        : 0->not test yet, 1->success, 2->failed
 *          Result_Eeprom_DI  : 0->not test yet, 1->success, 2->failed
 *          Result_Ecat_DI    : 0->not test yet, 1->success, 2->failed
 *			Result_DIs_2ms    : 0->not test yet, 18->success, 1~16->4ms period failed, 17->command timeout
 *          Result_DIs_4ms    : 0->not test yet, 18->success, 1~16->4ms period failed, 17->command timeout
 *			Result_LEDs_DI    : 0->not test yet, 1->success, 2->failed, 3->LED confirm timeout
 *)

ESI_UPDATE1(UD_EN := ESI_UD_EN, 
			ESI_ID_IN := ESI_ID, 
			T_UD_PT := ESI_UD_PT, 
			T_UD_ET => ESI_UD_ET, 
			UD_RET => ESI_UD_RET);

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
TPR(IN := TPR16_En, PT := TPR16_PT, R := TPR16_Rst, Q => TPR16_Q, ET => TPR16_ET);

diTestTime := TACR1_ET / 1000;
diBarStepTime := diDITime / 100;
diBarTemp := diBarStepTime / 2;

GET_CODE_OF_SET(GET_EN := xGetCode, state => iCodeState, CODE_RET => iCode);  (* ��ȡ���Լ�ʶ���� *)

if iMode = 0 THEN
	diDITime := 22000;
	FB_ESI_Write1(WR_EN := ESI_WR_EN, 
				  esi_id_in := ESI_ID, 
				  SlavePos := 0, 
				  uid_in := 1, 
				  ESI_RET => ESI_WR_RET);
ELSIF iMode = 1 THEN
	diDITime := 36000;
	FB_ESI_Read1(RD_EN := ESI_RD_EN,
             FileSize := 1024,
             SlavePos := 0,
             UID_OUT_H => UID_DI_h,
             UID_OUT_L => UID_DI_l,
             ESI_RET => ESI_RD_RET);
END_IF

FB_600E_DO_LEVEL0_A(cmd_en := DO_LEVEL0_EN_A, ch_in := 12, level_in := 1, cmd_ret => DO_LEVEL0_RET_A);//600E DO output 1
FB_600E_DO_LEVEL1_A(cmd_en := DO_LEVEL1_EN_A, ch_in := 12, level_in := 0, cmd_ret => DO_LEVEL1_RET_A);//600E DO output 0
FB_600E_DO_LEVEL0_B(cmd_en := DO_LEVEL0_EN_B, ch_in := 13, level_in := 1, cmd_ret => DO_LEVEL0_RET_B);//600E DO output 1
FB_600E_DO_LEVEL1_B(cmd_en := DO_LEVEL1_EN_B, ch_in := 13, level_in := 0, cmd_ret => DO_LEVEL1_RET_B);//600E DO output 0
FB_600E_DO_PWM_4ms_A(cmd_en := DO_PWM1_EN_A,  ch_in := 12, period_in := 4, duty_in := 2, cmd_ret => DO_PWM1_RET_A);
FB_600E_DO_PWM_8ms_A(cmd_en := DO_PWM2_EN_A,  ch_in := 12, period_in := 8, duty_in := 4, cmd_ret => DO_PWM2_RET_A);
FB_600E_DO_PWM_4ms_B(cmd_en := DO_PWM1_EN_B,  ch_in := 13, period_in := 4, duty_in := 2, cmd_ret => DO_PWM1_RET_B);
FB_600E_DO_PWM_8ms_B(cmd_en := DO_PWM2_EN_B,  ch_in := 13, period_in := 8, duty_in := 4, cmd_ret => DO_PWM2_RET_B);

if iLED_CF_Mode = 1 THEN  (* LED�ֶ���� *)
	LED_TEST_MAN(LED_MAN_IN := xLED_MAN_IN, LED_CF_IN := iLED_CF_IN, LED_RET => Result_LEDs_DI);
ELSIF iLED_CF_Mode = 0 THEN  (* LED�Զ���� *)
	LED_TEST_WTX(WTX_IN := xLED_WTX_IN, module_in := ModuleSel, md_sel := iZioDISel, LED_RET => Result_LEDs_DI);
END_IF

FB_DATA_LOG(DL_EN := DL_EN, MD_SEL := ModuleSel, DL_RET => DL_RET);
limit_switch_check(md_in := ModuleSel, limit_switch_out => xLimitSwitch);

AI_SAMPLE1(AI_EN := AI_SMP_EN, VAL_IN := fAIVal_Aux[0], VAL_OUT => fVolTemp1[0], RET_OUT => AI_SMP_RET1);
AI_SAMPLE2(AI_EN := AI_SMP_EN, VAL_IN := fAIVal_Aux[1], VAL_OUT => fVolTemp1[1], RET_OUT => AI_SMP_RET2);
AI_SAMPLE3(AI_EN := AI_SMP_EN, VAL_IN := fAIVal_Aux[2], VAL_OUT => fVolTemp1[2], RET_OUT => AI_SMP_RET3);
AI_SAMPLE4(AI_EN := AI_SMP_EN, VAL_IN := fAIVal_Aux[3], VAL_OUT => fVolTemp1[3], RET_OUT => AI_SMP_RET4);

CASE iDITestState OF
0:(*============================== DI module test init ==============================*)
	IF iMode = 1 THEN
		T_CAM_IN := TRUE;
		IF T_CAM_ET < T_CAM_PT THEN
			xWindow_WaitCam := TRUE;
		ELSE
			xWindow_WaitCam := FALSE;
		END_IF
	END_IF
	
	DI();
	xPower_3p3V := FALSE;
	IF iMode = 0 THEN
		xPower_24V := FALSE;
	ELSIF iMode = 1 THEN
		xPower_24V := TRUE;
	END_IF
	xPower_MD1 := FALSE;
	xPower_MD3 := FALSE;
	xPower_MD4 := FALSE;
	xSW_PN1 := FALSE;
	timer_disable();
	result_reset(MD_IN := ModuleSel);
	
	for i := 0 to 15 by 1 DO
		xDI_N[i] := FALSE;
		xDI_P[i] := FALSE;
		xDI_P_Pio[i] := FALSE;
		iDI_Valid_Times[i] := 0;
	END_FOR
	
	(* Enable slave according to iZioDISel *)
	IF iZioDISel = 1 THEN  (* ZIOC-E1600DN *)
		ZIOC_E1600DN.bDisableEnable := FALSE;
		CP_AUX.bDisableEnable := FALSE;
		AI_AUX.bDisableEnable := FALSE;
		AO_AUX.bDisableEnable := FALSE;
		ESI_ID := 8;
		PID_DO := 16#0101001A;
	ELSIF iZioDISel = 2 THEN  (* ZIOC-E1600DP *)
		ZIOC_E1600DP.bDisableEnable := FALSE;
		CP_AUX.bDisableEnable := FALSE;
		AI_AUX.bDisableEnable := FALSE;
		AO_AUX.bDisableEnable := FALSE;
		ESI_ID := 9;
		PID_DO := 16#0101001B;
	ELSIF iZioDISel = 3 THEN  (* ZIOC-E0016DP-Pio *)
		ZIOC_E1600DP_Pio.bDisableEnable := FALSE;
		CP_AUX.bDisableEnable := FALSE;
		AI_AUX.bDisableEnable := FALSE;
		AO_AUX.bDisableEnable := FALSE;
		ESI_ID := 14;
		PID_DO := 16#01010028;
	END_IF
	
	lmsw_btn_handler(iTestState => iDITestState);
	
1:(*============================== DI module test config ==============================*)
	xLED_RUN := TRUE;
	xLED_STOP := FALSE;
	xBeep := FALSE;
	TACR1_IN := TRUE;
	TPR1_En := TRUE;
	TPR2_En := TRUE;
	
	IF TPR1_ET <= 800 THEN
		xBeep := TRUE;
		xPower_24V := TRUE;
		xPower_MD1 := TRUE;
		xPower_3p3V := TRUE;
		IF iZioDISel = 1 THEN
			xSW_PN1 := TRUE;
		END_IF
		xWrongSet := FALSE;
		xGetCode := FALSE;
	ELSIF TPR1_ET > 800 and TPR1_ET <= 3000 THEN
		xBeep := FALSE;
		xGetCode := TRUE;
	END_IF
	
//	serial_number_check(ret_out => iRetCheck);
//	IF iRetCheck = 0 THEN
//		RETURN;
//	ELSIF iRetCheck = -1 THEN
//		iDITestState := 0;
//		RETURN;
//	END_IF
	
	testset_check(mode_in := 0, code_in := 126, ret_out => iRetCheck);  (* �����Լ�ʶ������ *)
	IF iRetCheck = 0 THEN
		RETURN;
	ELSIF iRetCheck = -1 THEN
		iDITestState := 0;
		RETURN;
	END_IF
	testset_check(mode_in := 1, code_in := 57, ret_out => iRetCheck);  (* ��Ʒ���Լ�ʶ������ *)
	IF iRetCheck = 0 THEN
		RETURN;
	ELSIF iRetCheck = -1 THEN
		iDITestState := 0;
		RETURN;
	END_IF
	
	IF TPR1_ET > 2000 and iMode = 0 THEN  (* time for relay stable/naked board *)
		uid_get(module_in := ModuleSel, no_in := 1);
		ESI_WR_EN := TRUE;  //write ESI
	ELSIF TPR1_ET > 2000 AND iMode = 1 THEN  (* time for relay stable/shelled board *)
		ESI_RD_EN := TRUE;  //read ESI
	END_IF
	
	IF (ESI_WR_RET = 1) OR (ESI_RD_RET = 1) then
		IF TPR1_ET > 8000 AND TPR1_ET < 9000 THEN
			xPower_3p3V := FALSE;
			xPower_MD1 := FALSE;  //Module power down
		ELSIF TPR1_ET > 9000 AND TPR1_ET < 10000 THEN
			xPower_3p3V := TRUE;
			xPower_MD1 := TRUE;  //Modele power up
		ELSIF TPR1_ET > 11000 THEN
			_ECATMaster.bStartMaster := TRUE;  (* start the EtherCAT master========> *)
		ELSE
			xPower_3p3V := TRUE;
			xPower_MD1 := TRUE;
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
		TPR1_En := FALSE;
		ESI_WR_EN := FALSE;
		ESI_RD_EN := FALSE;
		Result_Eeprom_DI := 1;
		Result_Ecat_DI := 1;
		iDITestState := 2;  //go to next state
	END_IF
	
	IF TPR1_ET = TPR1_PT THEN  (* DO module config timeout failed *)
		TPR1_En := FALSE;
		Result_Ecat_DI := -1;
		iDITestState := 7;
	END_IF
	
2:(*============================== DI module test process1 ==============================*)
	IF iMode = 0 THEN  (* �����Ե�1 *)
		IF iZioDISel = 1 then  (* DIN *)
			xPower_MD4 := TRUE;
		ELSIF iZioDISel = 2 or iZioDISel = 3 THEN  (* DIP *)
			xPower_MD3 := TRUE;
		END_IF
		TPR3_PT := 1000;
		TPR3_En := TRUE;
		if TPR3_ET = TPR3_PT THEN
			IF iZioDISel = 1 THEN
				IF xDI_N[12] = TRUE THEN  (* DI bare board test success *)
					Result_DIs := 1;
					iDITestState := 7;
				ELSE  (* DI bare board test failed *)
					Result_DI_Vol := -1;
					iDITestState := 7;
				END_IF
			ELSIF iZioDISel = 2 THEN
				IF xDI_P[14] = TRUE THEN  (* DI bare board test success *)
					Result_DIs := 1;
					iDITestState := 7;
				ELSE  (* DI bare board test failed *)
					Result_DI_Vol := -1;
					iDITestState := 7;
				END_IF
			ELSIF iZioDISel = 3 THEN
				IF xDI_P_Pio[14] = TRUE THEN  (* DI bare board test success *)
					Result_DIs := 1;
					iDITestState := 7;
				ELSE  (* DI bare board test failed *)
					Result_DI_Vol := -1;
					iDITestState := 7;
				END_IF
			END_IF
		END_IF
	ELSE  (* iMode = 1, ��Ʒ���Ե�1 *)
		(*
		 * @brief 600E DO �����Ч��ƽ
		 *)
		TPR3_PT := 6000;
		TPR3_En := TRUE;
		IF TPR3_ET < 1000 THEN
			DO_LEVEL0_EN_A := TRUE;  (* 600E DO�����Ч��ƽ *)
		END_IF
		
		IF DO_LEVEL0_RET_A < 0 OR DO_LEVEL0_RET_B < 0 THEN  (* 600E DO command failed *)
			TPR3_En := FALSE;
			DO_LEVEL0_EN_A := false;
			DO_LEVEL0_EN_B := FALSE;
			Result_DIs_2ms := -17;
			iDITestState := 7;
		END_IF
		
		IF DO_LEVEL0_RET_A = 1 THEN  (* 600E DO command success *)
			DO_LEVEL0_EN_A := false;
			DO_LEVEL0_EN_B := TRUE;
		ELSIF DO_LEVEL0_RET_B = 1 THEN
			TPR3_En := FALSE;
			DO_LEVEL0_EN_A := false;
			DO_LEVEL0_EN_B := FALSE;
			iDITestState := 3;  //go to next state
		END_IF
	END_IF
	
3:(*============================== DI module test process2 ==============================*)

	IF iMode = 0 THEN  (* �����Ե�2 *)
		;
	ELSIF iMode = 1 THEN  (* ��Ʒ���Ե�2 *)
		(*
		 * @brief 600E DO ���4ms����PWM
		 *)
		TPR4_PT := 10000;
		TPR4_En := TRUE;
		IF TPR4_ET > 400 AND TPR4_ET < 1000 THEN
			DO_PWM1_EN_A := TRUE;
		END_IF
		
		IF DO_PWM1_RET_A < 0 OR DO_PWM1_RET_B < 0 THEN  (* 600E DO command failed *)
			TPR4_En := FALSE;
			DO_PWM1_EN_A := false;
			DO_PWM1_EN_B := FALSE;
			Result_DIs_2ms := -17;
			iDITestState := 7;
		END_IF
		
		IF DO_PWM1_RET_A = 1 AND TPR4_ET > 2500 THEN
			DO_PWM1_EN_A := FALSE;
			DO_PWM1_EN_B := TRUE;
		ELSIF DO_PWM1_RET_B = 1 THEN
			if iMode = 1 and iLED_CF_Mode = 1 THEN  (* ��ƷLED�˹�ȷ�� *)
				TPR6_PT := diLED_Timeout;
				TPR6_En := TRUE;
				xLED_MAN_IN := TRUE;
			ELSIF iMode = 1 AND iLED_CF_Mode = 0 AND TPR4_ET > 5000 THEN  (* LED�Զ���ⷽʽ *)
				TPR6_PT := diLED_Timeout;
				TPR6_En := TRUE;
				xLED_WTX_IN := TRUE;
			END_IF
			FOR i := 0 to 15 by 1 DO
				if iZioDISel = 1 AND xDI_N[i] = TRUE THEN  (* DI test failed *)
					TPR4_En := FALSE;
					DO_PWM1_EN_A := FALSE;
					DO_PWM1_EN_B := FALSE;
					Result_DIs_2ms := -1 - i;
					iDITestState := 7;  //DI test failed
					EXIT;
				ELSIF iZioDISel = 2 AND xDI_P[i] = TRUE THEN  (* DI test failed *)
					TPR4_En := FALSE;
					DO_PWM1_EN_A := FALSE;
					DO_PWM1_EN_B := FALSE;
					Result_DIs_2ms := -1 - i;
					iDITestState := 7;  //DI test failed
					EXIT;
				ELSIF iZioDISel = 3 AND xDI_P_Pio[i] = TRUE THEN  (* DI_Pio test failed *)
					TPR4_En := FALSE;
					DO_PWM1_EN_A := FALSE;
					DO_PWM1_EN_B := FALSE;
					Result_DIs_2ms := -1 - i;
					iDITestState := 7;  //DI test failed
					EXIT;
				END_IF
			END_FOR
			IF TPR4_ET = TPR4_PT THEN  (* DI 2ms test success *)
				TPR4_En := FALSE;
				DO_PWM1_EN_A := FALSE;
				DO_PWM1_EN_B := FALSE;
				Result_DIs_2ms := 1;
				iDITestState := 4;  //go to next state
			END_IF
		END_IF
		
		if Result_LEDs_DI < 0 THEN  (* LED failed *)
			TPR6_En := FALSE;
			iDITestState := 7;
		END_IF
	END_IF
	
4:(*============================== DI module test process3 ==============================*)
	(*
	 * @brief 600E DO ���8ms����PWM
	 *)
	TPR5_PT := 10000;
	TPR5_En := TRUE;
	IF TPR5_ET < 1000 THEN
		DO_PWM2_EN_A := TRUE;
	END_IF
	
	IF  DO_PWM2_RET_A < 0 OR DO_PWM2_RET_B < 0 THEN  (* 600E DO command failed *)
		TPR5_En := FALSE;
		DO_PWM2_EN_A := false;
		DO_PWM2_EN_B := false;
		Result_DIs_4ms := -17;
		iDITestState := 7;
	END_IF
	
	IF DO_PWM2_RET_A = 1 THEN
		DO_PWM2_EN_A := FALSE;
		DO_PWM2_EN_B := TRUE;
	ELSIF DO_PWM2_RET_B = 1 THEN
		DO_PWM2_EN_A := FALSE;
		DO_PWM2_EN_B := FALSE;
		iDITestState := 5;  //go to next state
	END_IF
	
5:(*============================== DI module test process4 ==============================*)
	IF TPR5_ET = TPR5_PT THEN
		for i := 0 to 15 by 1 DO
			IF iDI_Valid_Times[i] < 2000 THEN  (* DI test failed *)
				TPR5_En := FALSE;
				Result_DIs_4ms := -1 - i;
				iDITestState := 7;
				EXIT;
			ELSE  (* DI test success! *)
				TPR5_En := FALSE;
				Result_DIs_4ms := 1;
				iDITestState := 6;  //go to next state
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
	
//	TPR8_PT := 1000;
//	TPR8_En := TRUE;
//	IF TPR8_ET < TPR8_PT THEN
//		DO_LEVEL1_EN_A := true;  (* DI������Ч��ƽ *)
//	END_IF
//	
//	if DO_LEVEL1_RET_A < 0 OR DO_LEVEL1_RET_B < 0 THEN
//		DO_LEVEL1_EN_A := FALSE;
//		DO_LEVEL1_EN_B := FALSE;
//		TPR8_En := FALSE;
//		TPR6_En := FALSE;
//		Result_LEDs_DI := -1;
//		iDITestState := 7;
//		RETURN;
//	END_IF
//	IF DO_LEVEL1_RET_A = 1 THEN
//		DO_LEVEL1_EN_A := FALSE;
//		DO_LEVEL1_EN_B := TRUE;
//	END_IF

	IF Result_LEDs_DI = 1 THEN
		//DO_LEVEL1_EN_A := FALSE;
		//DO_LEVEL1_EN_B := FALSE;
		TPR8_En := FALSE;
		TPR6_En := FALSE;
		//iDITestState := 7;
	ELSIF Result_LEDs_DI < 0 THEN
		//DO_LEVEL1_EN_A := FALSE;
		//DO_LEVEL1_EN_B := FALSE;
		TPR8_En := FALSE;
		TPR6_En := FALSE;
		iDITestState := 7;
	END_IF

6:(*============================== LED test process ==============================*)
	IF Result_LEDs_DI = 1 THEN
		//DO_LEVEL1_EN_A := FALSE;
		//DO_LEVEL1_EN_B := FALSE;
		TPR8_En := FALSE;
		TPR6_En := FALSE;
		Result_DI_Vol := 1;
		Result_DIs := 1;
		iDITestState := 7;
	ELSIF Result_LEDs_DI < 0 THEN
		//DO_LEVEL1_EN_A := FALSE;
		//DO_LEVEL1_EN_B := FALSE;
		TPR8_En := FALSE;
		TPR6_En := FALSE;
		iDITestState := 7;
	END_IF
	
7:(*============================== datat log process ==============================*)
	xHide_LED_Window := TRUE;
	result_error_get(module_in := ModuleSel);
	TPR6_En := FALSE;
	TPR6_Rst := TRUE;
	xDITestRecord := TRUE;
	DO_LEVEL0_EN_A := FALSE;
	DO_LEVEL0_EN_B := FALSE;
	
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
	_ECATMaster.bStopMaster := TRUE;
	IF _ECATMaster.bMasterRunState = FALSE THEN
		xPower_3p3V := FALSE;
		xPower_MD1 := FALSE;
		xPower_MD3 := FALSE;
		xPower_MD4 := FALSE;
	END_IF
	TACR1_IN := FALSE;
	TPR2_En := FALSE;
	iBarCnt := 100;
	xDITestSuccess := TRUE;
	
	led_run_blk(led_in := TRUE, duty_ms := 150, xled_out => xLED_RUN);
	led_stp_blk(led_in := FALSE, duty_ms := 150, xled_out => xLED_STOP);
	TPR9_PT := 3000;
	TPR9_En := TRUE;
	IF TPR9_ET < 1000 THEN
		DO_LEVEL0_EN_A := TRUE;
	END_IF
	IF DO_LEVEL0_RET_A = 1 THEN
		DO_LEVEL0_EN_A := FALSE;
		DO_LEVEL0_EN_B := TRUE;
	END_IF
	if TPR9_ET mod 1000 < 5 THEN
		xBeep := FALSE;
	ELSIF TPR9_ET mod 1000 > 495 and TPR9_ET mod 1000 < 505 THEN
		xBeep := TRUE;
	END_IF
	
	IF xLimitSwitch = FALSE or xButton_Start = TRUE THEN
		iDITestState := 16;
	END_IF

9:(*============================== DI module test failed ==============================*)
	_ECATMaster.bStopMaster := TRUE;
	IF _ECATMaster.bMasterRunState = FALSE THEN
		xPower_3p3V := FALSE;
		xPower_MD1 := FALSE;
		xPower_MD3 := FALSE;
		xPower_MD4 := FALSE;
	END_IF
	TACR1_IN := FALSE;
	TPR2_En := FALSE;
	xDITestFailed := TRUE;
	
	led_run_blk(led_in := FALSE, duty_ms := 100, xled_out => xLED_RUN);
	led_stp_blk(led_in := TRUE, duty_ms := 100, xled_out => xLED_STOP);
	TPR10_PT := 3000;
	TPR10_En := TRUE;
	IF TPR10_ET < 1000 THEN
		DO_LEVEL0_EN_A := TRUE;
	END_IF
	IF DO_LEVEL0_RET_A = 1 THEN
		DO_LEVEL0_EN_A := FALSE;
		DO_LEVEL0_EN_B := TRUE;
	END_IF
	if TPR10_ET < 3000 THEN
		xBeep := TRUE;
	ELSE
		xBeep := FALSE;
	END_IF
	
	IF xLimitSwitch = FALSE or xButton_Start = TRUE THEN
		iDITestState := 16;
	END_IF

10:(*============================== ESI write ==============================*)
	IF SerialNo = 0 THEN
		xSN_Input_Rq := TRUE;
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

ELSE(*============================== reset ==============================*)
	_ECATMaster.bStopMaster := TRUE;
	timer_reset();
	DO_LEVEL0_EN_A := FALSE;
	DO_LEVEL0_EN_B := FALSE;
	TPR16_PT := 144;
	TPR16_En := TRUE;
	IF TPR16_ET = TPR16_PT THEN
		iDITestState := 0;
	END_IF
END_CASE

if iDITestState > 0 and iDITestState < 8 THEN  (* test in progess *)
	if (TACR1_ET mod diBarStepTime = diBarTemp) AND iBarCnt < 99 THEN  (* Progress bar control *)
		iBarCnt := iBarCnt + 1;  
	END_IF
	
	IF TPR2_ET = TPR2_PT THEN  (* Total timer error *)
		TPR2_En := FALSE;
		Result_DIs := -99;
		iDITestState := 7;
	END_IF
	
	IF xLimitSwitch = FALSE THEN
		xHide_LED_Window := TRUE;
		iDITestState := 16;
	END_IF
END_IF

if xButton_Stop = TRUE THEN
	xHide_LED_Window := TRUE;
	iDITestState := 16;
END_IF
    