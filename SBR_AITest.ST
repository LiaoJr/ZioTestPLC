AutoShop            2.4  5.03                                                                                                           ��  CLVTItem              �             �             �             ��>(* 
 * @brief  AIģ������ӳ���
 * @Result_AIs AIģ����Խ����
 *			Result_AIs        : 0->not test yet, 1->success, <0 ->failed
 *          Result_ADC_AI     : 0->not test yet, 1->success, -1->communicate failed, -2->timeout
 *          Result_Eeprom_AI  : 0->not test yet, 1->success, -1->communicate failed, -2->timeout
 *          Result_Ecat_AI    : 0->not test yet, 1->success, -1->failed
 *          Result_AIs_Cal    : 0->not test yet, 1->success, -1~-19->failed, -20->command timeout
 *			Result_AIs_Test   : 0->not test yet, 1->success, -1~-8->failed, -9->command timeout
 *			Result_LEDs_AI    : 0->not test yet, 1->success, -1->failed, -2->LED confirm timeout
 *)

ESI_UPDATE1(UD_EN := ESI_UD_EN, 
			ESI_ID_IN := ESI_ID, 
			T_UD_PT := ESI_UD_PT, 
			T_UD_ET => ESI_UD_ET, 
			UD_RET => ESI_UD_RET);

(* ��ʱ��ģ�� *)
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
diBarStepTime := diAITime / 100;
diBarTemp := diBarStepTime / 2;

GET_CODE_OF_SET(GET_EN := xGetCode, state => iCodeState, CODE_RET => iCode);

if iMode = 0 THEN
	diAITime := 25000;
	FB_ESI_Write1(WR_EN := ESI_WR_EN, 
				  esi_id_in := ESI_ID, 
				  SlavePos := 0, 
				  uid_in := 1, 
				  ESI_RET => ESI_WR_RET);
ELSIF iMode = 1 THEN
	diAITime := 56000;
	FB_ESI_Read1(RD_EN := ESI_RD_EN,
				 FileSize := 1024,
				 SlavePos := 0,
				 UID_OUT_H => UID_AI_h,
				 UID_OUT_L => UID_AI_l,
				 ESI_RET => ESI_RD_RET);
END_IF

IF iLED_CF_Mode = 0 THEN  (* LED�Զ���� *)
	LED_TEST_WTX(WTX_IN := xLED_WTX_IN, module_in := ModuleSel, md_sel := iZioAISel, LED_RET => Result_LEDs_AI);
ELSIF iLED_CF_Mode = 1 THEN  (* LED�ֶ���� *)
	LED_TEST_MAN(LED_MAN_IN := xLED_MAN_IN, LED_CF_IN := iLED_CF_IN, LED_RET => Result_LEDs_AI);
END_IF

FB_DATA_LOG(DL_EN := DL_EN, MD_SEL := ModuleSel, DL_RET => DL_RET);
limit_switch_check(md_in := ModuleSel, limit_switch_out => xLimitSwitch);

adc_config(adc_en := xADC_EN, range_in := iRange, ret_out => iRetADC);  (* ADCģ������ *)
(* ��ȡADCģ�����͡��汾�š����õ� *)
MB_Master(Execute := xRdCfg,
          iPort := 0,
          iAddr := 1,
          iFuncCode := 3,
          diDataAddr := 128,
          iDataNums := 4,
          iDataBuf := iDataBuf,
          xDone => xRdCfgDone,
          xBusy => ,
          xError => ,
          dwErrorID => );

(* ����ADCģ������̣�����ģʽ�� *)
MB_Master(Execute := xWrCfg1,
          iPort := 0,
          iAddr := 1,
          iFuncCode := 16,
          diDataAddr := 136,
          iDataNums := 1,
          iDataBuf := iWrBuf,
          xDone => xWrCfg1Done,
          xBusy => ,
          xError => xWrCfg1Error,
          dwErrorID => iWrCfg1ErrorId);
MB_Master(Execute := xWrCfg2,
          iPort := 0,
          iAddr := 1,
          iFuncCode := 16,
          diDataAddr := 5100,
          iDataNums := 3,
          iDataBuf := iWrBuf,
          xDone => xWrCfg2Done,
          xBusy => ,
          xError => xWrCfg2Error,
          dwErrorID => iWrCfg2ErrorId);

(* ��ȡADCģ��ɼ��Ļ������� *)
MB_Master(Execute := xRdData,
          iPort := 0,
          iAddr := 1,
          iFuncCode := 3,
          diDataAddr := 0,
          iDataNums := 16,
          iDataBuf := iDataBuf,
          xDone => xRdDataDone,
          xBusy => ,
          xError => xRdDataError,
          dwErrorID => );

AI_SAMPLE1(AI_EN := AI_SMP_EN, VAL_IN := fAIVal_ch1[iZioAISel], VAL_OUT => fValLogAI3d2, RET_OUT => AI_SMP_RET1);
AI_SAMPLE2(AI_EN := AI_SMP_EN, VAL_IN := fAIVal_Aux[0], VAL_OUT => fValLogAI1d25, RET_OUT => AI_SMP_RET2);
AI_SAMPLE3(AI_EN := AI_SMP_EN, VAL_IN := fAIVal_Aux[1], VAL_OUT => fValLogAI3d3, RET_OUT => AI_SMP_RET3);
AI_SAMPLE4(AI_EN := AI_SMP_EN, VAL_IN := fAIVal_Aux[2], VAL_OUT => fValLogAI2d5, RET_OUT => AI_SMP_RET4);
AI_SAMPLE5(AI_EN := AI_SMP_EN, VAL_IN := fAIVal_Aux[3], VAL_OUT => fValLogAI5, RET_OUT => AI_SMP_RET5);

CASE iAITestState OF
0:(*============================== AI module test init ==============================*)
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
	timer_disable();
	result_reset(MD_IN := ModuleSel);
	
	IF iZioAISel = 1 THEN  (* ZIOC-E0800AI *)
		//ZIOC_E0800AI.bDisableEnable := FALSE;
		ESI_ID := 2;
		PID_AI := 16#01010020;
		iRange := 16#00_0E;
	ELSIF iZioAISel = 2 THEN  (* ZIOC-E0800AU *)
		ZIOC_E0800AU.bDisableEnable := FALSE;
		CP_AUX.bDisableEnable := FALSE;
		AI_AUX.bDisableEnable := FALSE;
		AO_AUX.bDisableEnable := FALSE;
		ESI_ID := 3;
		PID_AI := 16#01010021;
		iRange := 16#00_0E;
	ELSIF iZioAISel = 3 THEN  (* ZIOC-E0800AU1 *)
		ZIOC_E0800AU1.bDisableEnable := FALSE;
		CP_AUX.bDisableEnable := FALSE;
		AI_AUX.bDisableEnable := FALSE;
		AO_AUX.bDisableEnable := FALSE;
		ESI_ID := 4;
		PID_AI := 16#01010022;
		iRange := 16#00_0E;
	ELSIF iZioAISel = 4 THEN  (* ZIOC-E0800AU1-Pio *)
		ZIOC_E0800AU1_Pio.bDisableEnable := FALSE;
		CP_AUX.bDisableEnable := FALSE;
		AI_AUX.bDisableEnable := FALSE;
		AO_AUX.bDisableEnable := FALSE;
		ESI_ID := 16;
		PID_AI := 16#01010024;
		iRange := 16#00_0E;
	END_IF
	
	lmsw_btn_handler(iTestState => iAITestState);
	
1:(*============================== AI module test config1 ==============================*)
	xLED_RUN := TRUE;
	xLED_STOP := FALSE;
	TACR1_IN := TRUE;
	TPR1_En := TRUE;
	TPR2_En := TRUE;
	
	IF TPR1_ET <= 800 THEN
		xBeep := TRUE;
		xPower_3p3V := TRUE;
		xPower_MD1 := TRUE;
		xWrongSet := FALSE;
		xGetCode := FALSE;
		RETURN;
	ELSIF TPR1_ET >800 THEN
		xBeep := FALSE;
		xADC_EN := TRUE;
		xGetCode := TRUE;
	END_IF
	
//	serial_number_check(ret_out => iRetCheck);  (* ������кż�� *)
//	IF iRetCheck = 0 THEN
//		RETURN;
//	ELSIF iRetCheck = -1 THEN
//		iAITestState := 0;
//		RETURN;
//	END_IF
	
	testset_check(mode_in := 1, code_in := 56, ret_out => iRetCheck);  (* ��Ʒ���Լ�ʶ������ *)
	IF iRetCheck = 0 THEN
		RETURN;
	ELSIF iRetCheck = -1 THEN
		iAOTestState := 0;
		RETURN;
	END_IF
	
	IF iRetADC = 1 THEN
		Result_ADC_AI := 1;
		iAITestState := 2;
	ELSIF iRetADC = -1 THEN
		Result_ADC_AI := -1;
		iAITestState := 7;
	END_IF

	IF TPR1_ET = TPR1_PT THEN  (* DO module config timeout failed *)
		xWrCfg2 := FALSE;
		TPR1_En := FALSE;
		Result_ADC_AI := -2;
		iAITestState := 7;
	END_IF
	
2:(*============================== AI module test config2 ==============================*)
	IF TPR1_ET > 3000 and iMode = 0 THEN  (* time for relay stable/naked board *)
		uid_get(module_in := ModuleSel, no_in := 1);
		ESI_WR_EN := TRUE;  //write ESI
	ELSIF TPR1_ET > 3000 AND iMode = 1 THEN  (* time for relay stable/shelled board *)
		ESI_RD_EN := TRUE;  //read ESI
	END_IF
	
	IF (ESI_WR_RET = 1) OR (ESI_RD_RET = 1) then  (* ESI write/read success *)
		IF TPR1_ET > 9000 AND TPR1_ET < 10000 THEN
			xPower_3p3V := FALSE;
			xPower_MD1 := FALSE;  //Module power down
		ELSIF TPR1_ET > 11000 AND TPR1_ET < 12000 THEN
			xPower_3p3V := TRUE;
			xPower_MD1 := TRUE;  //Modele power up
		ELSIF TPR1_ET > 13000 THEN
			_ECATMaster.bStartMaster := TRUE;  (* start the EtherCAT master========> *)
		ELSE
			xPower_3p3V := TRUE;
			xPower_MD1 := TRUE;
		END_IF
	ELSIF ESI_WR_RET < 0 OR ESI_RD_RET < 0 THEN  (* ESI write/read failed *)
		Result_Eeprom_AI := -1;
		iAITestState := 7;
	ELSIF TPR1_ET = TPR1_PT and (ESI_WR_RET = 0 or ESI_RD_RET = 0) THEN  (* ESI write/read timeout *)
		Result_Eeprom_AI := -2;
		iAITestState := 7;
	END_IF
	
	IF _ECATMaster.bMasterRunState = TRUE THEN
		IF test_times = 0 THEN
			test_times := test_times + 1;
			_ECATMaster.bStopMaster := TRUE;
			iAITestState := 1;
		ELSE
			TPR1_En := FALSE;
			ESI_WR_EN := FALSE;
			ESI_RD_EN := FALSE;
			Result_Eeprom_AI := 1;
			Result_Ecat_AI := 1;
			iAITestState := 3;
		END_IF
	END_IF
	
	IF TPR1_ET = TPR1_PT THEN  (* Ecat OP request timeout *)
		TPR1_En := FALSE;
		Result_Ecat_AI := -1;
		iAITestState := 7;
	END_IF
	
3:(*============================== AI module bare board test process ==============================*)
	if iMode = 0 THEN
		xPower_MD1 := TRUE;
		TPR3_PT := 1000;
		TPR3_En := TRUE;
		IF TPR3_ET < TPR3_PT THEN
			RETURN;
		END_IF
		
		AI_SMP_EN := TRUE;
		IF AI_SMP_RET1 = 1 AND AI_SMP_RET2 = 1 AND AI_SMP_RET3 = 1 AND AI_SMP_RET4 = 1 AND AI_SMP_RET5 = 1 THEN
			IF fValLogAI3d2 > 3.2 AND fValLogAI3d2 < 3.4 
			AND fValLogAI1d25 > 1.1 AND fValLogAI1d25 < 1.4 
			AND fValLogAI3d3 > 3.20 AND fValLogAI3d3 < 3.40 
			AND fValLogAI2d5 > 2.40 AND fValLogAI2d5 < 2.60 
			AND fValLogAI5 > 4.8 AND fValLogAI5 < 5.2 THEN
				Result_AI_Vol := 1;
				Result_AIs := 1;
				iAITestState := 7;
			ELSE
				Result_AI_Vol := -1;
				iAITestState := 7;
			END_IF
		ELSIF AI_SMP_RET1 = -1 or AI_SMP_RET2 = -1 or AI_SMP_RET3 = -1 or AI_SMP_RET4 = -1 or AI_SMP_RET5 = -1 THEN
			Result_AI_Vol := -1;
			iAITestState := 7;
		END_IF
	ELSIF iMode = 1 THEN
		TPR3_PT := 8000;
		TPR3_En := TRUE;
		IF TPR3_ET < 1000 THEN
			_ECATMaster.bStopMaster := TRUE;
		ELSE
			_ECATMaster.bStartMaster := TRUE;
			IF _ECATMaster.bMasterRunState = TRUE AND TPR3_ET > 4000 THEN
				TPR3_En := FALSE;
				iAITestState := 4;  //go to next state
			END_IF
			
			IF TPR3_ET = TPR3_PT AND _ECATMaster.bMasterRunState = FALSE THEN
				TPR3_En := FALSE;
				Result_Ecat_AI := -2;
				iAITestState := 7;
			END_IF
		END_IF
	END_IF
	
4:(*============================== AI module calibration process ==============================*)
	xSW_AICal := TRUE;
	IF iAICalStatus = 0 AND xAICal_Ready = TRUE THEN  (* Start calibration *)
		iAICalStatus := 1;
	ELSIF iAICalStatus = 8 AND xAICalSuccess = TRUE THEN  (* calibration success *)
		_ECATMaster.bStopMaster := TRUE;
		TPR4_PT := 1000;
		TPR4_En := TRUE;
		IF TPR4_ET = TPR4_PT THEN
			TPR4_En := FALSE;
			iAICalStatus := 16;
			Result_AIs_Cal := 1;  //AI calibration success
			iAITestState := 5;  //go to next state
		END_IF
	ELSIF iAICalStatus = 9 and xAICalFailed = TRUE THEN  (* calibration failed *)
		iAICalStatus := 16;
		iAITestState := 7;
	END_IF
	
	SBR_AICAL();
	
	IF iMode = 1 and iLED_CF_Mode = 1 THEN  (* ��ƷLED�˹���� *)
		iAICal_Pnt_Ctrl[iZioAISel] := 16#C8;  //open all led
		TPR6_PT := diLED_Timeout;
		TPR6_En := TRUE;
		xLED_MAN_IN := TRUE;
	ELSIF iMode = 1 AND iLED_CF_Mode = 0 THEN  (* ��ƷLED�Զ���� *)
		;
	END_IF
	
	IF Result_LEDs_AI < 0 THEN  (* LED failed *)
		TPR6_En := FALSE;
		iAITestState := 7;
	END_IF
	
5:(*============================== AI module test process ==============================*)
	_ECATMaster.bStartMaster := TRUE;
	TPR5_PT := 8000;
	TPR5_En := TRUE;
	IF TPR5_ET = TPR5_PT AND _ECATMaster.bMasterRunState = FALSE THEN
		TPR5_En := FALSE;
		Result_Ecat_AI := -2;
		iAITestState := 7;
	END_IF
	
	IF _ECATMaster.bMasterRunState = TRUE AND TPR5_ET > 4000 
	AND iTestPnt < iTestPntMax THEN
		FB_AITestPnt1(iAISelIn := iZioAISel, iTestPntIn := iTestPnt, iTestRet => iAITestRet);
		IF iAITestRet = 1 THEN  (* AI module test success *)
			iTestPnt := iTestPnt + 1;
			IF iTestPnt = iTestPntMax THEN  (* all test point pass *)
				iTestPnt := 0;
				Result_AIs_Test := 1;
				Result_AIs := 1;
				for i := 0 to 7 BY 1 DO
					iAOCode_Aux[i] := 0;
				END_FOR
				TPR5_En := FALSE;
				iAITestState := 6;  //go to next state
			END_IF
		ELSIF iAITestRet < 0 THEN  (* AI module test failed *)
			TPR5_En := FALSE;
			Result_AIs_Test := iAITestRet;
			iAITestState := 7;  //go to next state
		END_IF
	END_IF

	IF iMode = 1 and iLED_CF_Mode = 1 THEN  (* ��ƷLED�˹���� *)
		IF iZioAISel = 1 THEN
			iAICal_Pnt_Ctrl[iZioAISel] := 16#C8;  //open all led
		END_IF
		TPR6_PT := diLED_Timeout;
		TPR6_En := TRUE;
		xLED_MAN_IN := TRUE;
	ELSIF iMode = 1 AND iLED_CF_Mode = 0 THEN  (* ��ƷLED�Զ���� *)
		IF iZioAISel = 1 THEN
			iAICal_Pnt_Ctrl[iZioAISel] := 16#C8;  //open all led
		END_IF
		TPR6_PT := diLED_Timeout;
		TPR6_En := TRUE;
		xLED_WTX_IN := TRUE;
	END_IF
	
	IF Result_LEDs_AI < 0 THEN  (* LED failed *)
		TPR5_En := FALSE;
		TPR6_En := FALSE;
		iAITestState := 7;
	END_IF

6:(*============================== LED test process ==============================*)
	IF iMode = 1 AND iLED_CF_Mode = 0 THEN  (* LED�Զ���ⷽʽ *)
		TPR6_PT := diLED_Timeout;
		TPR6_En := TRUE;
		if Result_LEDs_AI = 0 THEN
			xLED_WTX_IN := TRUE;
		END_IF
	END_IF
	
	IF Result_LEDs_AI = 1 THEN
		TPR6_En := FALSE;
		Result_AI_Vol := 1;
		Result_AIs := 1;
		iAITestState := 7;
	ELSIF Result_LEDs_AI < 0 THEN
		TPR6_En := FALSE;
		iAITestState := 7;
	END_IF
	
7:(*============================== datat log process ==============================*)
	xHide_LED_Window := true;
	IF iZioAISel = 1 THEN
		iAICal_Pnt_Ctrl[iZioAISel] := 16#F9;  //close all leds
	END_IF
	TPR6_En := FALSE;
	TPR6_Rst := TRUE;
	result_error_get(module_in := ModuleSel);
	xAITestRecord := TRUE;
	DL_EN := TRUE;
	IF DL_RET < 0 THEN
		iAITestState := 9;
	ELSIF DL_RET = 1 AND Result_AIs <> 1 THEN
		iAITestState := 9;
	ELSIF DL_RET = 1 AND Result_AIs = 1 THEN
		iAITestState := 8;
	END_IF

8:(*============================== AI module test success ==============================*)
	_ECATMaster.bStopMaster := TRUE;
	TACR1_IN := FALSE;
	TPR2_En := FALSE;
	iBarCnt := 100;
	xAITestSuccess := TRUE;
	
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
		xPower_3p3V := FALSE;
		xPower_MD1 := FALSE;
		iAITestState := 16;
	END_IF
	
9:(*============================== AI module test failed ==============================*)
	_ECATMaster.bStopMaster := TRUE;
	TACR1_IN := FALSE;
	TPR2_En := FALSE;
	xAITestFailed := TRUE;
	
	led_run_blk(led_in := FALSE, duty_ms := 150, xled_out => xLED_RUN);
	led_stp_blk(led_in := TRUE, duty_ms := 150, xled_out => xLED_STOP);
	TPR10_PT := 3000;
	TPR10_En := TRUE;
	(* Beep control *)
	if TPR10_ET < 3000 THEN
		xBeep := TRUE;
	ELSE
		xBeep := FALSE;
	END_IF
	
	IF xLimitSwitch = FALSE or xButton_Start = TRUE THEN
		xPower_3p3V := FALSE;
		xPower_MD1 := FALSE;
		iAITestState := 16;
	END_IF
	
ELSE
	_ECATMaster.bStopMaster := TRUE;
	timer_reset();
	iAICalStatus := 16;

	(* if ADC module is online, reset it *)
	iWrBuf[0] := 0;  //�ر�ADCģ�黻��ʹ��
	iWrBuf[1] := 0;
	iWrBuf[2] := 0;
	xWrCfg2 := TRUE;
	IF xWrCfg1Done = TRUE AND xWrCfg1Error = FALSE THEN
		xWrCfg2 := FALSE;
	END_IF
	
	TPR16_PT := 144;
	TPR16_En := TRUE;
	IF TPR16_ET = TPR16_PT THEN
		iAITestState := 0;
	END_IF
END_CASE

IF iAITestState > 0 and iAITestState < 8 THEN  (* test in progess *)
	if (TACR1_ET mod diBarStepTime = diBarTemp) AND iBarCnt < 99 THEN  (* Progress bar control *)
		iBarCnt := iBarCnt + 1;  
	END_IF
	
	IF TPR2_ET = TPR2_PT THEN  (* Total timer error *)
		TPR2_En := FALSE;
		Result_AIs := -99;
		iAITestState := 7;
	END_IF
	
	IF xLimitSwitch = FALSE THEN
		xHide_LED_Window := TRUE;
		iAITestState := 16;
	END_IF
END_IF

IF xButton_Stop = TRUE THEN
	xHide_LED_Window := TRUE;
	iAITestState := 16;
END_IF
    