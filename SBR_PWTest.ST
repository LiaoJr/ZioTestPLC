AutoShop            2.4  5.03                                                                                                           ��  CLVTItem              �             �             �             ��(* 
 * @brief  PWģ������ӳ���
 * @Result_PWs PWģ����Խ����
 *			Result_PWs        : 0->not test yet, 1->success, 2->failed
 *          Result_Ecat_PW    : 0->not test yet, 1->success, 2->failed
 *			Result_PW_Vol     : 0->not test yet, 18->success, 1~16->failed, 17->command timeout
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
TPR(IN := TPR16_En, PT := TPR16_PT, R := TPR16_Rst, Q => TPR16_Q, ET => TPR16_ET);

diTestTime := TACR1_ET / 1000;
diBarStepTime := diPWTime / 100;
diBarTemp := diBarStepTime / 2;

GET_CODE_OF_SET(GET_EN := xGetCode, state => iCodeState, CODE_RET => iCode);
FB_DATA_LOG(DL_EN := DL_EN, MD_SEL := ModuleSel, DL_RET => DL_RET);
limit_switch_check(md_in := ModuleSel, limit_switch_out => xLimitSwitch);
AI_SAMPLE1(AI_EN := AI_SMP_EN, VAL_IN := fAIVal_Aux[0], VAL_OUT => fValLogPW3d3, RET_OUT => AI_SMP_RET1);

case iPWTestState OF
0:(*============================== PW module test init ==============================*)
	xPower_24V := FALSE;
	xPower_3p3V := FALSE;
	xPower_MD1 := FALSE;  //module power down
	timer_disable();
	result_reset(MD_IN := ModuleSel);
	
	IF iZioPWSel = 1 THEN  (* ZPWC-240304 *)
		CP_AUX.bDisableEnable := FALSE;
		AI_AUX.bDisableEnable := FALSE;
		AO_AUX.bDisableEnable := FALSE;
	END_IF
	
	lmsw_btn_handler(iTestState => iPWTestState);
	
1:(*============================== CP module test config ==============================*)
	xPower_24V := TRUE;
	xPower_3p3V := TRUE;
	xPower_MD1 := TRUE;
	xLED_RUN := TRUE;
	xLED_STOP := FALSE;
	xBeep := FALSE;
	xPWTestSuccess := FALSE;
	xPWTestFailed := FALSE;
	TACR1_IN := TRUE;
	TPR1_En := TRUE;
	TPR2_En := TRUE;
	
	IF TPR1_ET <= 800 THEN
		xBeep := TRUE;
		xWrongSet := FALSE;
		xGetCode := FALSE;
		//xHide_Result_window := TRUE;
	ELSIF TPR1_ET > 800 AND TPR1_ET <= 1600 THEN
		xBeep := FALSE;
		xGetCode := TRUE;
		//xHide_Result_window := FALSE;
	ELSIF TPR1_ET > 1500 THEN
		_ECATMaster.bStartMaster := TRUE;
	END_IF
	
	testset_check(mode_in := 0, code_in := 117, ret_out => iRetCheck);  (* �����Լ�ʶ������ *)
	IF iRetCheck = 0 THEN
		RETURN;
	ELSIF iRetCheck = -1 THEN
		iPWTestState := 0;
		RETURN;
	END_IF
	
	if TPR1_ET > 3000 AND _ECATMaster.bMasterRunState = TRUE THEN
		Result_Ecat_PW := 1;
		iPWTestState := 2;  //go to next state
	END_IF

	IF TPR1_ET = TPR1_PT THEN  (* module config timeout failed *)
		TPR1_En := FALSE;
		Result_Ecat_PW := -1;
		iPWTestState := 7;
	END_IF
	
2:(*============================== PW module test process ==============================*)
	TPR3_PT := 1000;
	TPR3_En := TRUE;
	IF TPR3_ET < TPR3_PT THEN
		RETURN;
	END_IF
	
	AI_SMP_EN := TRUE;
	IF AI_SMP_RET1 = 1 THEN
		IF fValLogPW3d3 > 3.25 AND fValLogPW3d3 < 3.35 
		AND xDI_GL20_A[0] = TRUE AND xDI_GL20_A[1] = TRUE
		AND xDI_GL20_A[2] = TRUE AND xDI_GL20_A[3] = TRUE THEN
			Result_PW_Vol := 1;
			Result_PWs := 1;
			iPWTestState := 7;
		ELSE
			Result_PW_Vol := -1;
			iPWTestState := 7;
		END_IF
	ELSIF AI_SMP_RET1 = -1 THEN
		Result_PW_Vol := -1;
		iPWTestState := 7;
	END_IF

7:(*============================== datat log process ==============================*)
	xHide_LED_Window := TRUE;
	TPR6_En := FALSE;
	TPR6_Rst := TRUE;
	result_error_get(module_in := ModuleSel);
	xPWTestRecord := TRUE;
	DL_EN := TRUE;
	IF DL_RET < 0 THEN
		iPWTestState := 9;
	ELSIF DL_RET = 1 AND Result_PWs <> 1 THEN
		iPWTestState := 9;
	ELSIF DL_RET = 1 AND Result_PWs = 1 THEN
		iPWTestState := 8;
	END_IF

8:(*============================== PW module test success ==============================-*)
	_ECATMaster.bStopMaster := TRUE;
	IF _ECATMaster.bMasterRunState = FALSE THEN
		xPower_3p3V := FALSE;
		xPower_24V := FALSE;
		xPower_MD1 := FALSE;
	END_IF
	TACR1_IN := FALSE;
	TPR2_En := FALSE;
	iBarCnt := 100;
	xPWTestSuccess := TRUE;
	
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
	
	IF xLimitSwitch = FALSE OR xButton_Start = TRUE THEN
		iPWTestState := 16;
	END_IF
	
9:(*============================== PW module test failed ==============================-*)
	_ECATMaster.bStopMaster := TRUE;
	IF _ECATMaster.bMasterRunState = FALSE THEN
		xPower_3p3V := FALSE;
		xPower_24V := FALSE;
		xPower_MD1 := FALSE;
	END_IF
	TACR1_IN := FALSE;
	TPR2_En := FALSE;
	xPWTestFailed := TRUE;
	
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
	
	IF xLimitSwitch = FALSE OR xButton_Start = TRUE THEN
		iPWTestState := 16;
	END_IF
	
ELSE
	_ECATMaster.bStopMaster := TRUE;
	timer_reset();
	//xHide_Result_window := TRUE;
	TPR16_PT := 144;
	TPR16_En := TRUE;
	IF TPR16_ET = TPR16_PT THEN
		iPWTestState := 0;
	END_IF
END_CASE

if iPWTestState > 0 and iPWTestState < 8 THEN  (* test in progess *)
	if (TACR1_ET mod diBarStepTime = diBarTemp) AND iBarCnt < 99 THEN  (* Progress bar control *)
		iBarCnt := iBarCnt + 1;  
	END_IF
	
	IF TPR2_ET = TPR2_PT THEN  (* Total timer error *)
		TPR2_En := FALSE;
		Result_PWs := -99;
		iPWTestState := 7;
	END_IF
	
	IF xLimitSwitch = FALSE THEN
		xHide_LED_Window := TRUE;
		//xHide_Result_window := TRUE;
		iPWTestState := 16;
	END_IF
END_IF

if xButton_Stop = TRUE THEN
	xHide_LED_Window := TRUE;
	//xHide_Result_window := TRUE;
	iPWTestState := 16;
END_IF
    