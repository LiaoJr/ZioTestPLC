AutoShop            2.4  5.03                                                                                                           ��  CLVTItem              �             �             �             �4(* 
 * @brief  DOģ������ӳ���
 * @Result_DOs DOģ����Խ����
 *			Result_DOs        : 0->not test yet, 1->success, 2->failed
 *          Result_Eeprom_DO  : 0->not test yet, 1->success, 2->failed
 *          Result_Ecat_DO    : 0->not test yet, 1->success, 2->failed
 *			Result_DO_ShortCut: 0->not test yet, 18->success, 1~16->failed, 17->command timeout
 *			Result_DOs_Carry  : 0->not test yet, 18->success, 1~16->failed, 17->command timeout
 *			Result_LEDs_DO    : 0->not test yet, 1->success, 2->failed, 3->LED confirm timeout
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
diBarStepTime := diDOTime / 100;
diBarTemp := diBarStepTime / 2;

GET_CODE_OF_SET(GET_EN := xGetCode, state => iCodeState, CODE_RET => iCode);  (* ��ȡ���Լ�ʶ���� *)

if iMode = 0 THEN
	diDOTime := 34000;
	FB_ESI_Write1(WR_EN := ESI_WR_EN, 
				  esi_id_in := ESI_ID, 
				  SlavePos := 0, 
				  uid_in := 1, 
				  ESI_RET => ESI_WR_RET);
ELSIF iMode = 1 THEN
	diDOTime := 36000;
	FB_ESI_Read1(RD_EN := ESI_RD_EN,
				 FileSize := 1024,
				 SlavePos := 0,
				 UID_OUT_H => UID_DO_h,
				 UID_OUT_L => UID_DO_l,
				 ESI_RET => ESI_RD_RET);
END_IF

IF iLED_CF_Mode = 0 THEN  (* LED�Զ���� *)
	LED_TEST_WTX(WTX_IN := xLED_WTX_IN, module_in := ModuleSel, md_sel := iZioDOSel, LED_RET => Result_LEDs_DO);
ELSIF iLED_CF_Mode = 1 THEN  (* LED�ֶ���� *)
	LED_TEST_MAN(LED_MAN_IN := xLED_MAN_IN, LED_CF_IN := iLED_CF_IN, LED_RET => Result_LEDs_DO);
END_IF

FB_DATA_LOG(DL_EN := DL_EN, MD_SEL := ModuleSel, DL_RET => DL_RET);
limit_switch_check(md_in := ModuleSel, limit_switch_out => xLimitSwitch);

CASE iDOTestState OF
0:(*============================== DO module test init ==============================*)
	IF iMode = 1 THEN
		T_CAM_IN := TRUE;
		IF T_CAM_ET < T_CAM_PT THEN
			xWindow_WaitCam := TRUE;
		ELSE
			xWindow_WaitCam := FALSE;
		END_IF
	END_IF
	
	xPower_24V := TRUE;
	xPower_3p3V := FALSE;
	xPower_MD1 := FALSE;
	xSW_PN1 := FALSE;
	xPower_MD4 := FALSE;
	xRelay1 := FALSE;
	timer_disable();
	result_reset(MD_IN := ModuleSel);
	
	IF iZioDOSel = 1 THEN  (* ZIOC-E0016DN *)
		ZIOC_E0016DN.bDisableEnable := FALSE;
		CP_AUX.bDisableEnable := FALSE;
		AI_AUX.bDisableEnable := FALSE;
		AO_AUX.bDisableEnable := FALSE;
		ESI_ID := 6;
		PID_DO := 16#0101001C;
	ELSIF iZioDOSel = 2 THEN  (* ZIOC-E0016DP *)
		ZIOC_E0016DP.bDisableEnable := FALSE;
		CP_AUX.bDisableEnable := FALSE;
		AI_AUX.bDisableEnable := FALSE;
		AO_AUX.bDisableEnable := FALSE;
		ESI_ID := 7;
		PID_DO := 16#0101001D;
	ELSIF iZioDOSel = 3 THEN  (* ZIOD-E0016DP-Pio *)
		ZIOC_E0016DP_Pio.bDisableEnable := FALSE;
		CP_AUX.bDisableEnable := FALSE;
		AI_AUX.bDisableEnable := FALSE;
		AO_AUX.bDisableEnable := FALSE;
		ESI_ID := 13;
		PID_DO := 16#01010029;
	END_IF
	
	lmsw_btn_handler(iTestState => iDOTestState);
	
1:(*============================== DO module test config ==============================*)
	xLED_RUN := TRUE;
	xLED_STOP := FALSE;
	xBeep := FALSE;
	TACR1_IN := TRUE;
	TPR1_En := TRUE;
	TPR2_En := TRUE;
	
	IF TPR1_ET <= 800 THEN
		xBeep := TRUE;
		xPower_24V := TRUE;
		xPower_3p3V := TRUE;
		xPower_MD1 := TRUE;
		IF iZioDOSel = 1 THEN
			xSW_PN1 := TRUE;
			xPower_MD4 := TRUE;
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
//		iDOTestState := 0;
//		RETURN;
//	END_IF
	
	testset_check(mode_in := 0, code_in := 123, ret_out => iRetCheck);  (* �����Լ�ʶ������ *)
	IF iRetCheck = 0 THEN
		RETURN;
	ELSIF iRetCheck = -1 THEN
		iDOTestState := 0;
		RETURN;
	END_IF
	testset_check(mode_in := 1, code_in := 59, ret_out => iRetCheck);  (* ��Ʒ���Լ�ʶ������ *)
	IF iRetCheck = 0 THEN
		RETURN;
	ELSIF iRetCheck = -1 THEN
		iDOTestState := 0;
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
		Result_Eeprom_DO := -1;
		iDOTestState := 7;
	ELSIF TPR1_ET = TPR1_PT and (ESI_WR_RET = 0 or ESI_RD_RET = 0) THEN  (* ESI write/read timeout *)
		Result_Eeprom_DO := -2;
		iDOTestState := 7;
	END_IF
	
	IF _ECATMaster.bMasterRunState = TRUE THEN
		TPR1_En := FALSE;
		ESI_WR_EN := FALSE;
		ESI_RD_EN := FALSE;
		Result_Eeprom_DO := 1;
		Result_Ecat_DO := 1;
		iDOTestState := 2;  //go to next state
	END_IF
	
	IF TPR1_ET = TPR1_PT THEN  (* DO module config timeout failed *)
		TPR1_En := FALSE;
		Result_Ecat_DO := -1;
		iDOTestState := 7;
	END_IF
	
2:(*============================== DO module test process1 ==============================*)
	(* 
	 * @details DO 8��ͨ���������������1S
	 *)
	FOR i := 0 TO 15 BY 1 DO  (* DO�����Ч��ƽ��׼���������״̬ *)
		IF iZioDOSel = 1 THEN
			xDO_N[i] := TRUE;
		ELSIF iZioDOSel = 2 THEN
			xDO_P[i] := TRUE;
		ELSIF iZioDOSel = 3 THEN
			xDO_P_Pio[i] := TRUE;
		END_IF
	END_FOR
	
	TPR3_PT := 1800;
	TPR3_En := TRUE;  //Start timer for DO test
	IF TPR3_ET = TPR3_PT THEN  (* DO test success *)
		TPR3_En := FALSE;
		iDOTestState := 3;  (* go to next state *)
	END_IF
	
	if TPR3_ET > 800 THEN
		FOR i := 0 to 15 BY 1 DO
			IF TPR3_ET > 1000 AND (xDI_GL20_A[i] = FALSE) THEN  (* DO test failed-_- *)
				Result_DOs_Carry := -1 - i;
				iDOTestState := 7;
				EXIT;  //exit loop
			END_IF
		END_FOR
	END_IF
	
3:(*============================== DO module test process2 ==============================*)
	(* 
	 * @details �պϼ̵�����DO��·����0.5S
	**)
	xRelay1 := TRUE;  //�պϼ̵���
	TPR4_PT := 700;  //200ms for output stable time, 500ms for shortcut test
	TPR4_En := TRUE;
	IF TPR4_ET = TPR4_PT THEN
		TPR4_En := FALSE;
		xRelay1 := FALSE;  //�ɿ��̵���
		Result_DOs_ShortCut := 1;  //DO shortcut test success!
		iDOTestState := 4;  // go to next state
	END_IF
	
	for i := 0 to 15 by 1 DO
		IF TPR4_ET > 200 AND xDI_GL20_A[i] = TRUE THEN  (* DO test failed-_- *)
			TPR4_En := FALSE;
			Result_DOs_ShortCut := -1 - i;
			iDOTestState := 7;
			EXIT;
		END_IF
	END_FOR
	
4:(*============================== DO module test process3 ==============================*)
	(*
	 * @details ���DOͨ��������Ч��ƽ
	**)
	IF iMode = 1 and iLED_CF_Mode = 1 THEN  (* LED�˹���ⷽʽ *)
		TPR6_PT := diLED_Timeout;
		TPR6_En := TRUE;
		xLED_MAN_IN := TRUE;
	END_IF
	IF iMode = 1 AND iLED_CF_Mode = 0 THEN  (* LED�Զ���ⷽʽ *)
		TPR6_PT := diLED_Timeout;
		TPR6_En := TRUE;
		if Result_LEDs_DO = 0 THEN
			xLED_WTX_IN := TRUE;
		END_IF
	END_IF
	
	TPR5_PT := diDOutputTime;  (* ����DO�������ʱ�� *)
	TPR5_En := TRUE;
	IF TPR5_ET = TPR5_PT THEN  (* DO output test success! *)
		TPR5_En := FALSE;
		Result_DOs_Carry := 1;
		if iMode = 0 THEN  (* ��岻��ҪLED���� *)
			Result_LEDs_DO := 1;
			Result_DOs := 1;  (* DI test success *)
			iDOTestState := 7;
		ELSIF iMode = 1 THEN  (* ��Ʒ����LED���� *)
			iDOTestState := 5;  //go to next state
		END_IF
	END_IF
	
	FOR i := 0 to 15 by 1 DO
		IF TPR5_ET > 500 and xDI_GL20_A[i] = FALSE THEN  (* DO test failed-_- *)
			TPR5_En := FALSE;
			Result_DOs_Carry := -1 - i;  //DO output test failed
			iDOTestState := 7;
			EXIT;
		END_IF
	END_FOR
	
	if Result_LEDs_DO < 0 THEN
		TPR6_En := FALSE;
		iDOTestState := 7;
	END_IF

5:(*============================== LED confirm time ==============================*)
	IF Result_LEDs_DO = 1 THEN
		TPR6_En := FALSE;
		Result_DO_Vol := 1;
		Result_DOs := 1;
		iDOTestState := 7;
	ELSIF Result_LEDs_DO < 0 THEN
		TPR6_En := FALSE;
		iDOTestState := 7;
	END_IF

7:(*============================== datat log process ==============================*)
	TPR6_En := FALSE;
	TPR6_Rst := TRUE;
	xHide_LED_Window := true;
	result_error_get(module_in := ModuleSel);
	xDOTestRecord := TRUE;
	DL_EN := TRUE;
	IF DL_RET < 0 THEN
		iDOTestState := 9;
	ELSIF DL_RET = 1 AND Result_DOs <> 1 THEN
		iDOTestState := 9;
	ELSIF DL_RET = 1 AND Result_DOs = 1 THEN
		iDOTestState := 8;
	END_IF

8:(*============================== DO module test success ==============================-*)
	FOR i :=0 TO 15 BY 1 DO  (* DO�����Ч��ƽ����ɲ��� *)
		if iZioDOSel = 1 THEN
			xDO_N[i] := FALSE;
		ELSIF iZioDOSel = 2 THEN
			xDO_P[i] := FALSE;
		ELSIF iZioDOSel = 3 THEN
			xDO_P_Pio[i] := FALSE;
		END_IF
	END_FOR
	_ECATMaster.bStopMaster := TRUE;
	IF _ECATMaster.bMasterRunState = FALSE THEN
		xPower_3p3V := FALSE;
		xSW_PN1 := FALSE;
		xPower_MD4 := FALSE;
	END_IF
	TACR1_IN := FALSE;
	TPR2_En := FALSE;
	iBarCnt := 100;
	xDOTestSuccess := TRUE;
	
	led_run_blk(led_in := TRUE, duty_ms := 150, xled_out => xLED_RUN);
	led_stp_blk(led_in := FALSE, duty_ms := 150, xled_out => xLED_STOP);
	(* Beep control *)
	TPR9_PT := 3000;
	TPR9_En := TRUE;
	if TPR9_ET mod 1000 < 5 THEN
		xBeep := FALSE;
	ELSIF TPR9_ET mod 1000 > 495 and TPR9_ET mod 1000 < 505 THEN
		xBeep := TRUE;
	END_IF
	
	IF xLimitSwitch = FALSE or xButton_Start = TRUE THEN
		iDOTestState := 16;
	END_IF
	
9:(*============================== DO module test failed ==============================*)
	FOR i :=0 TO 15 BY 1 DO  (* DO�����Ч��ƽ���������� *)
		if iZioDOSel = 1 THEN
			xDO_N[i] := FALSE;
		ELSIF iZioDOSel = 2 THEN
			xDO_P[i] := FALSE;
		ELSIF iZioDOSel = 3 THEN
			xDO_P_Pio[i] := FALSE;
		END_IF
	END_FOR
	_ECATMaster.bStopMaster := TRUE;
	IF _ECATMaster.bMasterRunState = FALSE THEN
		xPower_3p3V := FALSE;
		xSW_PN1 := FALSE;
		xPower_MD4 := FALSE;
	END_IF
	TACR1_IN := FALSE;
	TPR2_En := FALSE;
	xDOTestFailed := TRUE;
	
	led_run_blk(led_in := FALSE, duty_ms := 150, xled_out => xLED_RUN);
	led_stp_blk(led_in := TRUE, duty_ms := 150, xled_out => xLED_STOP);
	(* Beep control *)
	TPR10_PT := 3000;
	TPR10_En := TRUE;
	if TPR10_ET < 3000 THEN
		xBeep := TRUE;
	ELSE
		xBeep := FALSE;
	END_IF
	
	IF xLimitSwitch = FALSE or xButton_Start = TRUE THEN
		iDOTestState := 16;
	END_IF
	
10:(*============================== ESI write ==============================*)
	IF SerialNo = 0 THEN
		xSN_Input_Rq := TRUE;
		iDOTestState := 0;
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
	_ECATMaster.bStopMaster := TRUE;
	timer_reset();
	TPR16_PT := 144;
	TPR16_En := TRUE;
	IF TPR16_ET = TPR16_PT THEN
		iDOTestState := 0;
	END_IF
END_CASE

if iDOTestState > 0 and iDOTestState < 8 THEN  (* test in progess *)
	if (TACR1_ET mod diBarStepTime = diBarTemp) AND iBarCnt < 99 THEN  (* Progress bar control *)
		iBarCnt := iBarCnt + 1;  
	END_IF
	
	IF TPR2_ET = TPR2_PT THEN  (* Total timer error *)
		TPR2_En := FALSE;
		Result_DOs := -99;
		iDOTestState := 7;
	END_IF
	
	IF xLimitSwitch = FALSE THEN
		xHide_LED_Window := TRUE;
		iDOTestState := 16;
	END_IF
END_IF

if xButton_Stop = TRUE THEN
	xHide_LED_Window := TRUE;
	iDOTestState := 16;
END_IF
    