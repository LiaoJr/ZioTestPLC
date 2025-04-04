AutoShop            2.4  5.03                                                                                                           ��  CLVTItem              �             �             �             �?6(* 
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
diTestTime := TACR1_ET / 1000;

IF iLED_CF_Mode = 0 THEN  (* LED�Զ���� *)
	;
ELSIF iLED_CF_Mode = 1 THEN  (* LED�ֶ���� *)
	FB_LED_MAN_AI(LED_MAN_IN := xLED_MAN_IN, LED_CF_IN := iLED_CF_IN, LED_RET => Result_LEDs_AI);
END_IF

if iMode = 0 THEN
	FB_ESI_Write1(WR_EN := ESI_WR_EN, 
				  esi_id_in := ESI_ID, 
				  SlavePos := 1, 
				  uid_in := 1, 
				  ESI_RET => ESI_WR_RET);
ELSIF iMode = 1 THEN
	FB_ESI_Read1(RD_EN := ESI_RD_EN,
				 FileSize := 1024,
				 SlavePos := 1,
				 UID_OUT_H => UID_AI_h,
				 UID_OUT_L => UID_AI_l,
				 ESI_RET => ESI_RD_RET);
END_IF

FB_DATA_LOG_AI(DL_EN := DL_EN, MD_SEL := ModuleSel, DL_RET => DL_RET);

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
MB_Master(Execute := bRdData,
          iPort := 0,
          iAddr := 1,
          iFuncCode := 3,
          diDataAddr := 0,
          iDataNums := 16,
          iDataBuf := iDataBuf,
          xDone => bRdDataDone,
          xBusy => ,
          xError => bRdDataError,
          dwErrorID => );

CASE iAITestState OF
0:(*============================== AI module test init ==============================*)
	xPowerRelay := TRUE;
	DI();
	timer_disable();
	bAITestSuccess := FALSE;
	bAITestFailed := FALSE;
	
	xWrCfg1 := FALSE;
	xWrCfg2 := FALSE;
	xRdCfg := FALSE;
	bRdData := FALSE;
	iBarCnt := 0;
	
	iTestPnt := 0;
	iTestPntMax := 5;
	
	UID_AI_h := 0;
	UID_AI_l := 0;
	Result_AIs := 0;
	Result_ADC_AI := 0;
	Result_Eeprom_AI := 0;
	Result_Ecat_AI := 0;
	Result_AIs_Cal := 0;
	Result_AIs_Test := 0;
	Result_LEDs_AI := 0;
	xAITestRecord := FALSE;
	
	ESI_WR_EN := FALSE;
	ESI_RD_EN := FALSE;
	xLED_MAN_IN := FALSE;
	DL_EN := FALSE;
	
	xBeep := FALSE;
	iBarCnt := 0;
	
	IF iZioAISel = 1 THEN  (* ZIOC-E0800AI *)
		ZCPC_80801_Pio.bDisableEnable := FALSE;
		//ZIOC_E0800AI.bDisableEnable := FALSE;
		ZIOC_E0008AU_Pio_Aux.bDisableEnable := FALSE;
		ZIOD_E0808DN_Aux.bDisableEnable := FALSE;
		ESI_ID := 2;
		PID_AI := 16#01010020;
		iRange := 16#00_0E;
	ELSIF iZioAISel = 2 THEN  (* ZIOC-E0800AU *)
		ZCPC_80801_Pio.bDisableEnable := FALSE;
		ZIOC_E0800AU.bDisableEnable := FALSE;
		ZIOC_E0008AU_Pio_Aux.bDisableEnable := FALSE;
		ZIOD_E0808DN_Aux.bDisableEnable := FALSE;
		ESI_ID := 3;
		PID_AI := 16#01010021;
		iRange := 16#00_0E;
	ELSIF iZioAISel = 3 THEN  (* ZIOC-E0800AU1 *)
		ZCPC_80801_Pio.bDisableEnable := FALSE;
		ZIOC_E0800AU1.bDisableEnable := FALSE;
		ZIOC_E0008AU_Pio_Aux.bDisableEnable := FALSE;
		ZIOD_E0808DN_Aux.bDisableEnable := FALSE;
		ESI_ID := 4;
		PID_AI := 16#01010022;
		iRange := 16#00_0E;
	ELSIF iZioAISel = 4 THEN  (* ZIOC-E0800AU1-Pio *)
		ZCPC_80801_Pio.bDisableEnable := FALSE;
		ZIOC_E0800AU1_Pio.bDisableEnable := FALSE;
		ZIOC_E0008AU_Pio_Aux.bDisableEnable := FALSE;
		ZIOD_E0808DN_Aux.bDisableEnable := FALSE;
		ESI_ID := 16;
		PID_AI := 16#01010024;
		iRange := 16#00_0E;
	END_IF
	
1:(*============================== AI module test config1 ==============================*)
	xPowerRelay := FALSE;  //module power up
	bAITestSuccess := FALSE;
	bAITestFailed := FALSE;
	TACR1_IN := TRUE;
	TPR1_PT := diCfgTimeout;  //set for config timeout
	TPR2_PT := diTestTimeout;  //set for total timeout
	TPR1_En := TRUE;
	TPR2_En := TRUE;
	iConvEn := 2;  //����ʹ��
	iConvDatatype := 4;  //����֮��������Ϊfloat
	
	IF SerialNo = 0 and iMode = 0 THEN  (* �����Ա����������к� *)
		bSN_Input_Rq := TRUE;
		iAITestState := 0;
		TPR1_En := FALSE;
		TPR2_En := FALSE;
		TPR1_Rst := TRUE;
		TPR2_Rst := TRUE;
		RETURN;
	END_IF
	
	CASE iADCState OF
	0:(****** ��ȡADCģ����ͺ� ******)
		xRdCfg := TRUE;
		if xRdCfgDone = TRUE AND xRdCfgError = FALSE THEN
			IF iDataBuf[0] = iDevType THEN  (* read ADC module type success *)
				xRdCfg := FALSE;
				iADCState := 1;
			ELSE  (* read ADC module type failed *)
				xRdCfg := FALSE;
				iADCState := 4;
			END_IF
		ELSIF xRdCfgError = TRUE THEN  (* Modbus RTU error *)
			xRdCfg := FALSE;
			iADCState := 4;
		END_IF
	1:(***** ADCģ���������� *****)
		iWrBuf[0] := iRange;
		xWrCfg1 := TRUE;
		if xWrCfg1Done = TRUE AND xWrCfg1Error = FALSE THEN
			xWrCfg1 := FALSE;
			iADCState := 2;
		ELSIF xWrCfg1Error = TRUE THEN
			xWrCfg1 := FALSE;
			iADCState := 4;
		END_IF
	2:(* ADCģ�黻��ʹ��, ����Ϊ��ȡ��ѹʵ��ֵ(������) *)
		iWrBuf[0] := iConvEn;
		iWrBuf[1] := iConvDatatype;
		xWrCfg2 := TRUE;
		IF xWrCfg2Done = TRUE AND xWrCfg2Error = FALSE THEN
			xWrCfg2 := FALSE;
			iADCState := 3;
		ELSIF xWrCfg2Error = TRUE THEN
			xWrCfg2 := FALSE;
			iADCState := 4;
		END_IF
	3:(********* ADC module config success **********)
		TPR1_En := FALSE;
		Result_ADC_AI := 1;
		iADCState := 0;
		iAITestState := 2;
	4:(********* ADC module config failed **********)
		TPR1_En := FALSE;
		Result_ADC_AI := -1;
		iADCState := 0;
		iAITestState := 7;
	END_CASE

	if (iBarCnt mod 1000 = 500) AND iBarCnt < 20 THEN  (* Progress bar control *)
		iBarCnt := iBarCnt + 1;  
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
			iBarCnt := 20;
			TPR1_En := FALSE;
			ESI_WR_EN := FALSE;
			ESI_RD_EN := FALSE;
			Result_Eeprom_AI := 1;
			Result_Ecat_AI := 1;
			IF iMode = 0 THEN
				iAITestState := 3;  //go to calibration state
			ELSIF iMode = 1 THEN
				iAITestState := 4;  //go to test state
			END_IF
		END_IF
	END_IF
	
	if (TPR1_ET mod 1000 = 500) AND iBarCnt < 20 THEN  (* Progress bar control *)
		iBarCnt := iBarCnt + 1;  
	END_IF
	
	IF TPR1_ET = TPR1_PT THEN  (* Ecat OP request timeout *)
		TPR1_En := FALSE;
		Result_Ecat_AI := -1;
		iAITestState := 7;
	END_IF

3:(*============================== AI module calibration process ==============================*)
	IF iAICalStatus = 0 AND xAICal_Ready = TRUE THEN  (* Start calibration *)
		iAICalStatus := 1;
	ELSIF iAICalStatus = 8 AND xAICalSuccess = TRUE THEN  (* calibration success *)
		iAICalStatus := 16;
		iBarCnt := 40;
		Result_AIs_Cal := 1;  //AI calibration success
		iAITestState := 4;  //go to next state
	ELSIF iAICalStatus = 9 and xAICalFailed = TRUE THEN  (* calibration failed *)
		iAICalStatus := 16;
		iAITestState := 7;
	END_IF
	
	SBR_AICAL();
	
	IF iMode = 1 and iLED_CF_Mode = 1 THEN  (* װ�ǰ��˹�LED��� *)
		iAICal_Pnt_Ctrl[iZioAISel] := 16#C8;  //open all led
		TPR6_PT := diLED_Timeout;
		TPR6_En := TRUE;
		xLED_MAN_IN := TRUE;
	END_IF
	IF Result_LEDs_AI < 0 THEN  (* LED failed *)
		TPR6_En := FALSE;
		iAITestState := 7;
	END_IF
	
	IF (TPR12_ET mod 1000 = 500) AND iBarCnt < 40 THEN  (* Progress bar control *)
		iBarCnt := iBarCnt + 1;
	END_IF
	
	IF TPR2_ET = TPR2_PT THEN  (* Total timer error *)
		TPR2_En := FALSE;
		Result_AIs := -140;
		iAITestState := 7;
	END_IF

4:(*============================== AI module test process ==============================*)
	Result_AIs_Cal := 1;
	IF iTestPnt < iTestPntMax THEN
		FB_AITestPnt1(iAISelIn := iZioAISel, iTestPntIn := iTestPnt, iTestRet => iAITestRet);
		IF iAITestRet = 1 THEN  (* AI module test success *)
			iTestPnt := iTestPnt + 1;
			iBarCnt := iBarCnt + 1;
			IF iTestPnt = iTestPntMax THEN  (* all test point pass *)
				iTestPnt := 0;
				Result_AIs_Test := 1;
				Result_AIs := 1;
				iAITestState := 7;
			END_IF
		ELSIF iAITestRet = 0 THEN  (* AI module processing *)
			;//waiting
		ELSE  (* AI module test failed *)
			Result_AIs_Test := iAITestRet;
			iAITestState := 7;
		END_IF
	END_IF

	IF Result_LEDs_AI < 0 THEN  (* LED failed *)
		TPR6_En := FALSE;
		iAITestState := 7;
	END_IF
	
	IF iMode = 0 AND (TPR2_ET mod 600 = 300) AND iBarCnt < 99 THEN  (* Progress bar control *)
		iBarCnt := iBarCnt + 1;
	ELSIF iMode = 1 AND (TPR2_ET mod 400 = 200) AND iBarCnt < 99 THEN
		iBarCnt := iBarCnt + 1;
	END_IF
	
	IF TPR2_ET = TPR2_PT THEN  (* AI module test timeout *)
		TPR2_En := FALSE;
		Result_AIs_Test := -10;  //AI module test timeout
		iAITestState := 7;
	END_IF

5:(*============================== LED test process ==============================*)
	IF iLED_CF_Mode = 0 THEN  (* LED�Զ���ⷽʽ *)
		TPR6_PT := diLED_Timeout;
		TPR6_En := TRUE;
		if Result_LEDs_AI = 0 THEN
			xLED_WTX_IN := TRUE;
		END_IF
	END_IF
	
	if Result_LEDs_AI <> 0 THEN
		if Result_LEDs_AI = 1 THEN  (* DI LED test success *)
			Result_AIs := 1;  (* DI test success *)
		END_IF
		TPR6_En := FALSE;
		//xLED_MAN_IN := FALSE;
		//xLED_WTX_IN := FALSE;
		iAITestState := 7;
	END_IF
	
	IF TPR6_ET mod 1000 = 500 AND iBarCnt < 99 THEN  (* Progress bar control *)
		iBarCnt := iBarCnt + 1;
	END_IF
	
7:(*============================== datat log process ==============================*)
	iAICal_Pnt_Ctrl[iZioAISel] := 16#F9;  //close all leds
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
	TACR1_IN := FALSE;
	TPR2_En := FALSE;
	iBarCnt := 100;
	bAITestSuccess := TRUE;
		
	TPR9_PT := 3000;
	TPR9_En := TRUE;
	(* Beep control *)
	if TPR9_ET mod 1000 < 5 THEN
		xBeep := FALSE;
	ELSIF TPR9_ET mod 1000 > 495 and TPR9_ET mod 1000 < 505 THEN
		xBeep := TRUE;
	END_IF
	
9:(*============================== AI module test failed ==============================*)
	TACR1_IN := FALSE;
	TPR2_En := FALSE;
	bAITestFailed := TRUE;

	TPR10_PT := 3000;
	TPR10_En := TRUE;
	(* Beep control *)
	if TPR10_ET < 3000 THEN
		xBeep := TRUE;
	ELSE
		xBeep := FALSE;
	END_IF
	
ELSE
	timer_reset();
	ESI_WR_EN := FALSE;
	ESI_RD_EN := FALSE;
	xAITestRecord := FALSE;
	iAICalStatus := 16;

	(* if ADC module is online, reset it *)
	iWrBuf[0] := 0;  //�ر�ADCģ�黻��ʹ��
	iWrBuf[1] := 0;
	iWrBuf[2] := 0;
	xWrCfg2 := TRUE;
	IF xWrCfg1Done = TRUE AND xWrCfg1Error = FALSE THEN
		xWrCfg2 := FALSE;
	END_IF
	
	_ECATMaster.bStopMaster := TRUE;  //ֹͣEtherCAT��վ
	if _ECATMaster.bMasterRunState = FALSE THEN
		xPowerRelay := TRUE;  //module power down
		iAITestState := 0;
	END_IF
END_CASE
    