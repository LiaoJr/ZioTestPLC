AutoShop            2.4  5.03                                                                                                           ��  CLVTItem              �             �             �             ��(* AOģ��У׼�ӳ��� *)

(* ��ʱ��ģ�� *)
TPR(IN := TPR11_En, PT := TPR11_PT, R := TPR11_Rst, Q => TPR11_Q, ET => TPR11_ET);
TPR(IN := TPR12_En, PT := TPR12_PT, R := TPR12_Rst, Q => TPR12_Q, ET => TPR12_ET);

//IF iAOTestState <> 3 THEN
//	(* ��ȡADCģ�����͡��汾�š����õ� *)
//	MB_Master(Execute := xRdCfg,
//			  iPort := 0,
//			  iAddr := 1,
//			  iFuncCode := 3,
//			  diDataAddr := 128,
//			  iDataNums := 4,
//			  iDataBuf := iDataBuf,
//			  xDone => xRdCfgDone,
//			  xBusy => ,
//			  xError => ,
//			  dwErrorID => );
//	
//	(* ����ADCģ������̣�����ģʽ�� *)
//	MB_Master(Execute := xWrCfg2,
//			  iPort := 0,
//			  iAddr := 1,
//			  iFuncCode := 16,
//			  diDataAddr := 5100,
//			  iDataNums := 3,
//			  iDataBuf := iWrBuf,
//			  xDone => xWrCfg1Done,
//			  xBusy => ,
//			  xError => xWrCfg1Error,
//			  dwErrorID => );
//	
//	(* ��ȡADCģ��ɼ��Ļ������� *)
//	MB_Master(Execute := xRdData,
//			  iPort := 0,
//			  iAddr := 1,
//			  iFuncCode := 3,
//			  diDataAddr := 0,
//			  iDataNums := 16,
//			  iDataBuf := iDataBuf,
//			  xDone => xRdDataDone,
//			  xBusy => ,
//			  xError => xRdDataError,
//			  dwErrorID => dwRdDataErrorID);
//END_IF

CASE iAOCalStatus OF
0:(*------------------------------ AO calibration Init state ------------------------------*)
	xWrCfg2 := FALSE;
	xRdCfg := FALSE;
	xRdData := FALSE;
	
	xAOCal_Start[iZioAOSel] := FALSE;
	iAOCal_Ch_Ctrl[iZioAOSel] := 0;
	iAOCal_Pnt_Ctrl[iZioAOSel] := 0;  //reserved
	iAOCal_Ch_n[iZioAOSel] := 0;  //reserved
	iAOCal_Pnt_n[iZioAOSel] := 0;
	
	if iZioAOSel = 1 or iZioAOSel = 3 THEN
		iAOCal_Pnt_Max := 6;  //У׼�ο�������
	ELSIF iZioAOSel = 2 THEN
		iAOCal_Pnt_Max := 11;  //У׼�ο�������
	END_IF
	
	xAOCalSuccess := FALSE;
	xAOCalFailed := FALSE;
	
	(* Disable all timer *)
	TPR11_En := FALSE;
	TPR12_En := FALSE;
	TPR11_Rst := FALSE;
	TPR12_Rst := FALSE;
	xAOCal_Ready := TRUE;
	xAOCal_End := FALSE;
	
1:(*------------------------------ AO Calibration Config ------------------------------*)
	xAOCal_Ready := FALSE;
	TPR11_PT := 800;  //����У׼���ó�ʱʱ��
	TPR12_PT := diAOCalTimeout;
	TPR11_En := TRUE;  //calibration config timeout
	TPR12_En := TRUE;  //calibration process timeout
	
	IF TPR11_ET = TPR11_PT THEN
		TPR11_En := FALSE;
		xAOCal_Start[iZioAOSel] := TRUE;  //��У׼��־λ
		iAOCalStatus := 2;  //go to next state
	END_IF
	
2:(*------------------------------ Calibration process state ------------------------------*)
	(*
	 * @brief У׼��վ״̬��
	 *)
	CASE iAOCal_Ch_Stat[iZioAOSel] OF
	0:(*---------- iAOCal_Ch_Status[Calibration init] ----------*)
		iAOCal_Ch_Ctrl[iZioAOSel] := 1;

	1:(*---------- iAOCal_Ch_Status[get calibration reference point] ----------*)
		if iAOCal_Pnt_n[iZioAOSel] <= iAOCal_Pnt_Max THEN
			FB_AOCalRefPnt1(iAOSelIn := iZioAOSel, 
							iCalPntIn := iAOCal_Pnt_n[iZioAOSel], 
							iCalRet => iAOCalPntRet);
			IF iAOCalPntRet = 1 THEN  (* get reference point success *)
				iAOCal_Pnt_n[iZioAOSel] := iAOCal_Pnt_n[iZioAOSel] + 1;  (* set next reference point *)
			ELSIF iAOCalPntRet < 0 THEN  (* get reference point failed *)
				Result_AOs_Cal := iAOCalPntRet;
				iAOCalStatus := 9;
			ELSIF iAOCalPntRet = 0 AND TPR12_ET = diAOCalTimeout THEN  (* get reference point timeout *)
				Result_AOs_Cal := -10;  //AO calibration timeout
				iAOCalStatus := 9;
			END_IF
		END_IF
		
		(* �ж����еĲο����Ƿ��ѳɹ���ȡ *)
		if (iAOCal_Pnt_n[iZioAOSel] = iAOCal_Pnt_Max + 1) THEN
		//AND iAOCal_Pnt_Stat[iZioAOSel] = REAL_TO_INT(EXPT(2, iAOCal_Pnt_Max)) - 1 THEN
			iAOCal_Ch_Ctrl[iZioAOSel] := 2;
		END_IF

	2:(*---------- iAOCal_Ch_Status[calculate the coefficient] ----------*)
		iAOCal_Ch_Ctrl[iZioAOSel] := 3;
		
	3:(*---------- iAOCal_Ch_Status[Write the coefficient to flash] ----------*)
		if xAOCal_Finish[iZioAOSel] =TRUE THEN
			iAOCal_Ch_Ctrl[iZioAOSel] := 4;
		END_IF
		
	4:(*---------- iAOCal_Ch_Status[Calibration Finish] ----------*)
		TPR12_En := FALSE;
		iAOCal_Ch_Ctrl[iZioAOSel] := 0;  (* ��λ��վУ׼״̬ *)
		IF xAOCal_Error[iZioAOSel] = FALSE THEN  (* Calibration success!! *)
			iAOCalStatus := 8;
		ELSE  (* Calibration failed-_- *)
			Result_AOs_Cal := -9;  //Calibration coeffecient write failed
			iAOCalStatus := 9;  
		END_IF
		
	END_CASE  //End of {CASE iAOCal_Ch_Stat[iZioAOSel] OF}
	
	IF TPR12_ET = diAOCalTimeout THEN  (* Calibration timeout failed *)
		xAOCalTimeOut := true;
		Result_AOs_Cal := -9;
		iAOCalStatus := 9;
	END_IF
	
8:(*------------------------------ AO module calibration success ------------------------------*)
	TPR12_En := FALSE;
	xAOCalSuccess := true;
	
9:(*------------------------------ AO module calibration failed ------------------------------*)
	TPR12_En := FALSE;
	xAOCalFailed := TRUE;
	
ELSE(*------------------------------ default state ------------------------------*)
	xAOCal_Ready := false;
	xAOCal_End := true;
	TPR11_Rst := TRUE;
	TPR12_Rst := TRUE;
	TPR11_En := FALSE;
	TPR12_En := FALSE;
	xAOCal_Start[iZioAOSel] := FALSE;
	iAOCal_Ch_Ctrl[iZioAOSel] := 0;
	iAOCal_Pnt_Ctrl[iZioAOSel] := 0;
	iAOCal_Ch_n[iZioAOSel] := 0;
	iAOCal_Pnt_n[iZioAOSel] := 0;
	iAOCalStatus := 0;
END_CASE


IF xCalAgain=TRUE THEN  (* ѡ������У׼ *)
	iAOCal_Ch_Ctrl[iZioAOSel] := 0;
	iAOCal_Pnt_n[iZioAOSel] := 0;
	xAOCalSuccess := FALSE;
	xAOCalFailed := FALSE;
	iAOCalStatus := 0;
	xCalAgain := FALSE;
END_IF
    