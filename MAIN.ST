AutoShop            2.4  5.03                                                                                                           ��  CLVTItem              �             �             �             �d(* MAIN PROGRAM *)
IF iMode = 1 THEN
	TPR(IN := T_CAM_IN, PT := T_CAM_PT, R := T_CAM_R, Q => T_CAM_Q, ET => T_CAM_ET);
	T_CAM_PT := 10000;
	T_CAM_W := (T_CAM_PT - T_CAM_ET) / 1000;
END_IF

(* ���ݶ�Ӧ��ZIOģ������Ӧ���ӳ��� *)
CASE ModuleSel OF
	0:
	TPR(IN := T_ST_EN, PT := T_ST_PT, R := T_ST_R, Q => T_ST_Q, ET => T_ST_ET);
	T_ST_PT := 15000;
	T_ST_EN := TRUE;
	T_ST_WAIT := (T_ST_PT - T_ST_ET) / 1000;
	IF T_ST_ET < T_ST_PT THEN
		xWindow_Startup := TRUE;
	ELSE
		xWindow_Startup := FALSE;
	END_IF
	
	iCode := 0;
	test_times := 0;
	xLED_RUN := FALSE;
	xLED_STOP := FALSE;
	
	xPower_48V := FALSE;
	xPower_24V := FALSE;
	xPower_3p3V := FALSE;
	xPower_MD1 := FALSE;
	xPower_MD2 := FALSE;
	xBeep := FALSE;
	
	(* CP *)
	ZCPC_80801.bDisableEnable := TRUE;
	ZCPC_80801_Pio.bDisableEnable := TRUE;
	ZIOC_E0008AU_Aux.bDisableEnable := TRUE;
	(* DI/DO *)
	ZIOC_E0016DN.bDisableEnable := TRUE;
	ZIOC_E0016DP.bDisableEnable := TRUE;
	ZIOC_E1600DN.bDisableEnable := TRUE;
	ZIOC_E1600DP.bDisableEnable := TRUE;
	(* AI/AO *)
	ZIOC_E0008AU.bDisableEnable := TRUE;
	ZIOC_E0008AU1.bDisableEnable := TRUE;
	ZIOC_E0800AU.bDisableEnable := TRUE;
	ZIOC_E0800AU1.bDisableEnable := TRUE;
	(* Pio�����ͺ� *)
	ZIOC_E0016DP_Pio.bDisableEnable := TRUE;
	ZIOC_E1600DP_Pio.bDisableEnable := TRUE;
	ZIOC_E0008AU_Pio.bDisableEnable := TRUE;
	ZIOC_E0800AU1_Pio.bDisableEnable := TRUE;
	(* С����ֲ�ʽ�ͺ� *)
	ZIOD_E0808DN.bDisableEnable := TRUE;
	ZIOD_E0808DP.bDisableEnable := TRUE;
	
	(* ZLG��������ģ�� *)
	CP_AUX.bDisableEnable := TRUE;
	AI_AUX.bDisableEnable := TRUE;
	AO_AUX.bDisableEnable := TRUE;
	_ECATMaster.bStopMaster := TRUE;

	TPR1_PT := diCfgTimeout;  //set for config timeout
	TPR2_PT := diTestTimeout;  //Set for total timeout
	
	(* ����ѡ�����ý����¼���� *)
	if diPassWordIn = diPassWordSet AND xPassWord_CF = TRUE THEN
		xLoginSuccess := true;
		xPassWord_CF := false;
	ELSIF diPassWordIn = 0 AND xPassWord_CF = TRUE THEN
		xLoginSuccess := FALSE;
		xLoginFailed := FALSE;
		xPassWord_CF := FALSE;
	elsif diPassWordIn <> diPassWordSet AND xPassWord_CF = TRUE THEN
		xLoginFailed := TRUE;
		xPassWord_CF := false;
	END_IF
	
	1:(* ==============================CP============================== *)
	SBR_ZCP();
	
	2:(* ==============================DO============================== *)
	SBR_ZIODO();
	
	3:(* ==============================DI============================== *)
	SBR_ZIODI();
	
	4:(* ==============================AO============================== *)
	SBR_ZIOAO();
	
	5:(* ==============================AI============================== *)
	SBR_ZIOAI();
	
	6:(* ==============================DD============================== *)
	SBR_ZIODD();
	
	7:(* ==============================PW============================== *)
	SBR_ZIOPW();
	
	8:(* =========================ESI��������========================== *)
	diUpgPt := 5000;
	APP_UPGRADE1(UPG_EN := xUpgEn, T_UPG_PT := diUpgPt, T_UPG_ET => diUpgEt, UPG_RET => iUpgRet);

	9:(* ���Դ��� *)
	fAOVal_Ch1[3] := 9.0;
	fAOVal_Ch2[3] := 9.0;
	fAOVal_Ch3[3] := 9.0;
	fAOVal_Ch4[3] := 9.0;
	fAOVal_Ch5[3] := 9.0;
	fAOVal_Ch6[3] := 9.0;
	fAOVal_Ch7[3] := 9.0;
	fAOVal_Ch8[3] := 9.0;
	iRange := 16#00_0E;
	xADC_EN := TRUE;
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
			  xError => xRdCfgError,
			  dwErrorID => iRdCfgErrorId);
	
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
			  dwErrorID => dwRdDataErrorID);
	adc_data_set();
ELSE
	;
END_CASE;
    