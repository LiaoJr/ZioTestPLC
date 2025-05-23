AutoShop            2.4  5.03                                                                                                           ��  CLVTItem              �             �             �             �(* AIģ��У׼�ӳ��� *)

(* ��ʱ��ģ�� *)
TPR(IN := TPR11_En, PT := TPR11_PT, R := TPR11_Rst, Q => TPR11_Q, ET => TPR11_ET);
TPR(IN := TPR12_En, PT := TPR12_PT, R := TPR12_Rst, Q => TPR12_Q, ET => TPR12_ET);

//IF iAITestState <> 3 THEN
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

case iAICalStatus OF
0:(*------------------------------ AI calibration Init state ------------------------------*)
	xWrCfg2 := FALSE;
	xRdCfg := FALSE;
	xRdData := FALSE;
	
	xAICal_Start[iZioAISel] := FALSE;
	iAICal_Ch_Ctrl[iZioAISel] := 0;
	iAICal_Pnt_Ctrl[iZioAISel] := 0;
	iAICal_Ch_n[iZioAISel] := 0;
	iAICal_Pnt_n[iZioAISel] := 0;
	
	xAICalSuccess := FALSE;
	xAICalFailed := FALSE;
	
	iAICal_Pnt_Max := 2;  //У׼�ο�������
	
	(* Disable all timer *)
	TPR11_En := FALSE;
	TPR12_En := FALSE;
	TPR11_Rst := FALSE;
	TPR12_Rst := FALSE;
	
	xAICal_Ready := TRUE;

1:(*------------------------------ AI Calibration Config ------------------------------*)
	xAICal_Ready := FALSE;
	TPR11_PT := 1000;
	TPR12_PT := diAICalTimeout;
	TPR11_En := TRUE;
	TPR12_En := TRUE;
	
	IF TPR11_ET = TPR11_PT THEN
		TPR11_En := FALSE; 
		xAICal_Start[iZioAISel] := TRUE;  //��λУ׼��־λ
		iAICalStatus := 2;
	END_IF

2:(*------------------------------ Calibration process state ------------------------------*)
	(*
	 * @brief У׼״̬��
	 *)
	CASE iAICal_Ch_Stat[iZioAISel] OF
	0:(*---------- iAICal_Ch_Status[Calibration init] ----------*)
		iAICal_Ch_Ctrl[iZioAISel] := 1;
	
	1:(*---------- iAICal_Ch_Status[get calibration reference point] ----------*)
		IF iAICal_Pnt_n[iZioAISel] <= iAICal_Pnt_Max THEN  (* �жϲ��Ե㷶Χ *)
			FB_AICalRefPnt1(iAISelIn := iZioAISel, 
							iCalPntIn := iAICal_Pnt_n[iZioAISel], 
							iCalRet => iAICalPntRet);
			IF iAICalPntRet = 1 THEN  (* get reference point success *)
				iAICal_Pnt_n[iZioAISel] := iAICal_Pnt_n[iZioAISel] + 1;  (* set the next reference point *)
			ELSIF iAICalPntRet < 0 THEN  (* get reference point failed *)
				Result_AIs_Cal := iAICalPntRet;
				iAICalStatus := 9;
			ELSIF iAICalPntRet = 0 AND TPR12_ET = diAICalTimeout THEN  (* get reference point timeout *)
				Result_AIs_Cal := -10;  //AI calibration timeout
				iAICalStatus := 9;
			END_IF
		END_IF
		
		(* �ж����еĲο����Ƿ��ѳɹ���ȡ *)
		if (iAICal_Pnt_n[iZioAISel] = iAICal_Pnt_Max + 1) THEN
		//AND iAICal_Pnt_Stat[iZioAISel] = REAL_TO_INT(EXPT(2, iAICal_Pnt_Max)) - 1 THEN
			iAICal_Ch_Ctrl[iZioAISel] := 2;
		END_IF
		
	2:(*---------- iAICal_Ch_Status[calculate the coefficient] ----------*)
		for i := 0 to 7 by 1 DO
			iAOCode_Aux[i] := 0;
		END_FOR
		iAICal_Ch_Ctrl[iZioAISel] := 3;
	
	3:(*---------- iAICal_Ch_Status[Write the coefficient to flash] ----------*)
		IF xAICal_Finish[iZioAISel] = TRUE THEN
			iAICal_Ch_Ctrl[iZioAISel] := 4;
		END_IF
	
	4:(*---------- iAOCal_Ch_Status[Calibration Finish] ----------*)
		TPR12_En := FALSE;
		iAICal_Ch_Ctrl[iZioAISel] := 0;  (* ��λ��վУ׼״̬ *)
		IF xAICal_Error[iZioAISel] = FALSE THEN  (* Calibration success!! *)
			iAICalStatus := 8;
		ELSE  (* Calibration failed-_- *)
			Result_AIs_Cal := -9;  //Calibration coeffecient write failed
			iAICalStatus := 9;
		END_IF
	END_CASE
	
	IF TPR12_ET = diAICalTimeout THEN  (* Calibration timeout failed *)
		bAICalTimeOut := true;
		Result_AIs_Cal := -9;  //AI calibration timeout
		iAICalStatus := 9;
	END_IF

8:(*------------------------------ AO module calibration success ------------------------------*)
	TPR12_En := FALSE;
	xAICalSuccess := TRUE;

9:(*------------------------------ AO module calibration failed ------------------------------*)
	TPR12_En := FALSE;
	xAICalFailed := TRUE;

ELSE(*------------------------------ default state ------------------------------*)
	xAICal_Ready := FALSE;
	TPR11_Rst := TRUE;
	TPR12_Rst := TRUE;
	TPR11_En := FALSE;
	TPR12_En := FALSE;
	xAICal_Start[iZioAISel] := FALSE;
	iAICal_Ch_Ctrl[iZioAISel] := 0;
	iAICal_Pnt_Ctrl[iZioAISel] := 0;
	iAICal_Ch_n[iZioAISel] := 0;
	iAICal_Pnt_n[iZioAISel] := 0;
	iAICalStatus := 0;
END_CASE
    