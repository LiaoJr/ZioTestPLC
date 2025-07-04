AutoShop            2.4  5.03                                                                                                           ��  CLVTItem              �             �             �             ��'(* 
 * @brief  ����������ӳ���
 * @Result_CPs ��������Խ����
 *			Result_CPs        : 0->not test yet, 1->success, 2->failed
 *          Result_Eeprom     : 0->not test yet, 1->success, 2->failed
 *          Result_Ecat       : 0->not test yet, 1->success, 2->failed
 *			Result_LEDs_CP    : 0->not test yet, 1->success, 2->failed, 3->LED confirm timeout
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
diBarStepTime := diCPTime / 100;
diBarTemp := diBarStepTime / 2;

GET_CODE_OF_SET(GET_EN := xGetCode, state => iCodeState, CODE_RET => iCode);

if iMode = 0 THEN
	diCPTime := 20000;
	FB_ESI_Write1(WR_EN := ESI_WR_EN, 
				  esi_id_in := ESI_ID, 
				  SlavePos := 0, 
				  uid_in := 1, 
				  ESI_RET => ESI_WR_RET);
elsif iMode = 1 THEN
	diCPTime := 33000;
	FB_ESI_Read1(RD_EN := ESI_RD_EN,
				 FileSize := 1024,
				 SlavePos := 0,
				 UID_OUT_H => UID_CP_h,
				 UID_OUT_L => UID_CP_l,
				 ESI_RET => ESI_RD_RET);
END_IF

if iLED_CF_Mode = 1 THEN  (* LED�ֶ���� *)
	LED_TEST_MAN(LED_MAN_IN := xLED_MAN_IN, LED_CF_IN := iLED_CF_IN, LED_RET => Result_LEDs_CP);
ELSIF iLED_CF_Mode = 0 THEN  (* LED�Զ���� *)
	LED_TEST_WTX(WTX_IN := xLED_WTX_IN, module_in := ModuleSel, md_sel := iZioCPSel, LED_RET => Result_LEDs_CP);
END_IF

FB_DATA_LOG(DL_EN := DL_EN, MD_SEL := ModuleSel, DL_RET => DL_RET);
limit_switch_check(md_in := ModuleSel, limit_switch_out => xLimitSwitch);
AI_SAMPLE1(AI_EN := AI_SMP_EN, VAL_IN := fAIVal_Aux[0], VAL_OUT => fValLogCP3d3, RET_OUT => AI_SMP_RET1);

case iCPTestState OF
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
	IF _ECATMaster.bMasterRunState = FALSE THEN
		xPower_3p3V := FALSE;
		xPower_MD1 := FALSE;  //module power down
	END_IF
	timer_disable();
	result_reset(MD_IN := ModuleSel);
	
	IF iZioCPSel = 1 THEN  (* ZCPC-80801 *)
		ZCPC_80801.bDisableEnable := FALSE;
		ZIOC_E0008AU_Aux.bDisableEnable := FALSE;
		CP_AUX.bDisableEnable := FALSE;
		AI_AUX.bDisableEnable := FALSE;
		AO_AUX.bDisableEnable := FALSE;
		ESI_ID := 1;
		PID_DO := 16#01020004;
	ELSIF iZioCPSel = 2 THEN  (* ZCPC-80801-Pio *)
		ZCPC_80801_Pio.bDisableEnable := FALSE;
		ZIOC_E0008AU_Aux.bDisableEnable := FALSE;
		CP_AUX.bDisableEnable := FALSE;
		AI_AUX.bDisableEnable := FALSE;
		AO_AUX.bDisableEnable := FALSE;
		ESI_ID := 12;
		PID_DO := 16#01020005;
	END_IF
	
	lmsw_btn_handler(iTestState => iCPTestState);
	
1:(*============================== CP module test config ==============================*)
	xLED_RUN := TRUE;
	xLED_STOP := FALSE;
	xBeep := FALSE;
	xCPTestSuccess := FALSE;
	xCPTestFailed := FALSE;
	TACR1_IN := TRUE;
	TPR1_En := TRUE;
	TPR2_En := TRUE;
		
	IF TPR1_ET <= 800 THEN
		xBeep := TRUE;
		xPower_24V := TRUE;
		xPower_3p3V := TRUE;  //����Դ�ϵ�
		xPower_MD1 := TRUE;  //��Ʒ��Դ�ϵ�
		xWrongSet := FALSE;
		xGetCode := FALSE;
	ELSIF TPR1_ET > 800 and TPR1_ET <=2000 THEN
		xBeep := FALSE;
		xGetCode := TRUE;
	END_IF
	
//	serial_number_check(ret_out => iRetCheck);  (* ������кż�� *)
//	IF iRetCheck = 0 THEN
//		RETURN;
//	ELSIF iRetCheck = -1 THEN
//		iCPTestState := 0;
//		RETURN;
//	END_IF
	testset_check(mode_in := 0, code_in := 2, ret_out => iRetCheck);  (* �����Լ�ʶ������ *)
	IF iRetCheck = 0 THEN
		RETURN;
	ELSIF iRetCheck = -1 THEN
		iCPTestState := 0;
		RETURN;
	END_IF
	testset_check(mode_in := 1, code_in := 93, ret_out => iRetCheck);  (* ��Ʒ���Լ�ʶ������ *)
	IF iRetCheck = 0 THEN
		RETURN;
	ELSIF iRetCheck = -1 THEN
		iCPTestState := 0;
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
		Result_Eeprom_CP := -1;
		iCPTestState := 7;
	ELSIF TPR1_ET = TPR1_PT and (ESI_WR_RET = 0 or ESI_RD_RET = 0) THEN  (* ESI write/read timeout *)
		Result_Eeprom_CP := -2;
		iCPTestState := 7;
	END_IF
	
	IF _ECATMaster.bMasterRunState = TRUE THEN
		TPR1_En := FALSE;
		ESI_WR_EN := FALSE;
		ESI_RD_EN := FALSE;
		Result_Eeprom_CP := 1;
		Result_Ecat_CP := 1;
		iCPTestState := 2;  //go to next state
	END_IF

	IF TPR1_ET = TPR1_PT THEN  (* CP module config timeout failed *)
		TPR1_En := FALSE;
		Result_Ecat_CP := -1;
		iCPTestState := 7;
	END_IF
	
2:(*============================== CP module test process1 ==============================*)
	if iMode = 0 THEN  (********** ������ **********)
		Result_CPs := 1;  //�����Գɹ�
		iCPTestState := 7;
	ELSIF iMode = 1 THEN  (********** װ�ǰ���� **********)
		TPR3_PT := 1000;
		TPR3_En := TRUE;
		IF TPR3_ET < TPR3_PT THEN
			RETURN;
		END_IF
		
		AI_SMP_EN := TRUE;
		IF AI_SMP_RET1 = 1 THEN
			IF fValLogCP3d3 > 3.25 AND fValLogCP3d3 < 3.35 THEN
				Result_CP_Vol := 1;
				Result_CPs := 1;
				iCPTestState := 3;  //go to next state
			ELSE
				Result_CP_Vol := -1;
				iCPTestState := 7;
			END_IF
		ELSIF AI_SMP_RET1 = -1 THEN
			Result_CP_Vol := -1;
			iCPTestState := 7;
		END_IF
	END_IF
	
3:(*============================== CP module LED test ==============================*)
	TPR5_PT := 6000;
	TPR5_En := TRUE;

	if iLED_CF_Mode = 1 THEN  (* װ�ǰ�LED�˹�ȷ�� *)
		TPR6_PT := diLED_Timeout;
		TPR6_En := TRUE;
		xLED_MAN_IN := TRUE;
	elsif iLED_CF_Mode = 0 and TPR5_ET = TPR5_PT THEN  (* װ�ǰ�LED�Զ���� *)
		TPR6_PT := diLED_Timeout;
		TPR6_En := TRUE;
		xLED_WTX_IN := TRUE;
	END_IF
	
	if Result_LEDs_CP = 1 THEN  (* װ����������Գɹ� *)
		TPR5_En := FALSE;
		TPR6_En := FALSE;
		Result_CP_Vol := 1;
		Result_CPs := 1;
		iCPTestState := 7;  //=====>:)
	ELSIF Result_LEDs_CP < 0 THEN  (* LED failed *)
		TPR5_En := FALSE;
		TPR6_En := FALSE;
		iCPTestState := 7;
	END_IF
	
7:(*============================== datat log process ==============================*)
	xHide_LED_Window := true;
	TPR6_En := FALSE;
	TPR6_Rst := TRUE;
	result_error_get(module_in := ModuleSel);
	xCPTestRecord := TRUE;
	DL_EN := TRUE;
	IF DL_RET < 0 THEN
		iCPTestState := 9;
	ELSIF DL_RET = 1 AND Result_CPs <> 1 THEN
		iCPTestState := 9;
	ELSIF DL_RET = 1 AND Result_CPs = 1 THEN
		iCPTestState := 8;
	END_IF
	
8:(*============================== CP module test success ==============================-*)
	_ECATMaster.bStopMaster := TRUE;
	IF _ECATMaster.bMasterRunState = FALSE THEN
		xPower_3p3V := FALSE;
		xPower_MD1 := FALSE;
	END_IF
	TACR1_IN := FALSE;
	TPR2_En := FALSE;
	iBarCnt := 100;
	xCPTestSuccess := TRUE;
	
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
		iCPTestState := 16;
	END_IF
	
9:(*============================== DO module test failed ==============================*)
	_ECATMaster.bStopMaster := TRUE;
	IF _ECATMaster.bMasterRunState = FALSE THEN
		xPower_3p3V := FALSE;
		xPower_MD1 := FALSE;
	END_IF
	TACR1_IN := FALSE;
	TPR2_En := FALSE;
	xCPTestFailed := TRUE;
	
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
	
	if xLimitSwitch = FALSE or xButton_Start = TRUE THEN
		iCPTestState := 16;
	END_IF
	
ELSE(*============================== reset ==============================*)
	_ECATMaster.bStopMaster := TRUE;
	timer_reset();
	TPR16_PT := 144;
	TPR16_En := TRUE;
	IF TPR16_ET = TPR16_PT THEN
		iCPTestState := 0;
	END_IF
END_CASE

if iCPTestState > 0 and iCPTestState < 8 THEN  (* test in progess *)
	if (TACR1_ET mod diBarStepTime = diBarTemp) AND iBarCnt < 99 THEN  (* Progress bar control *)
		iBarCnt := iBarCnt + 1;  
	END_IF
	
	IF TPR2_ET = TPR2_PT THEN  (* Total timer error *)
		TPR2_En := FALSE;
		Result_CPs := -99;
		iCPTestState := 7;
	END_IF
	
	IF xLimitSwitch = FALSE THEN
		xHide_LED_Window := TRUE;
		iCPTestState := 16;
	END_IF
END_IF

if xButton_Stop = TRUE THEN
	xHide_LED_Window := TRUE;
	iCPTestState := 16;
END_IF
    