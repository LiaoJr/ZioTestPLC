AutoShop            2.4  5.03                                                                                                           ��  CLVTItem              �             �             �             �j/(* 
 * @brief  С����ֲ�ʽģ��[N��]�����ӳ���
 * @Result_DDs �ֲ�ʽģ����Խ����
 *			Result_DDs            : 0->not test yet, 1->success, 2->failed
 *			Result_DO_ShortCut: 0->not test yet, 1->success, 2->failed
 *			Result_DOs        : 0->not test yet, 1->success, 2->failed
 *			Result_DIs        : 0->not test yet, 1->success, 2->4ms period failed, 3->8ms period failed
 *			Result_LEDs       : 0->not test yet, 1->success, 2->failed, LED confirm timeout
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
TPR(IN := TPR3_En, PT := TPR3_PT, R := TPR3_Rst, Q => TPR3_Q, ET => TPR3_ET);//for DO test
TPR(IN := TPR4_En, PT := TPR4_PT, R := TPR4_Rst, Q => TPR4_Q, ET => TPR4_ET);//for DO test
TPR(IN := TPR5_En, PT := TPR5_PT, R := TPR5_Rst, Q => TPR5_Q, ET => TPR5_ET);//for DO test
TPR(IN := TPR6_En, PT := TPR6_PT, R := TPR6_Rst, Q => TPR6_Q, ET => TPR6_ET);//for LED confirm while DO output
TPR(IN := TPR7_En, PT := TPR7_PT, R := TPR7_Rst, Q => TPR7_Q, ET => TPR7_ET);//for ESI write
TPR(IN := TPR8_En, PT := TPR8_PT, R := TPR8_Rst, Q => TPR8_Q, ET => TPR8_ET);//for ESI read
TPR(IN := TPR9_En, PT := TPR9_PT, R := TPR9_Rst, Q => TPR9_Q, ET => TPR9_ET);//for test success beep
TPR(IN := TPR10_En, PT := TPR10_PT, R := TPR10_Rst, Q => TPR10_Q, ET => TPR10_ET);//for test failed beep
TPR(IN := TPR16_En, PT := TPR16_PT, R := TPR16_Rst, Q => TPR16_Q, ET => TPR16_ET);

diTestTime := TACR1_ET / 1000;

FB_ESI_Write1(WR_EN := ESI_WR_EN, esi_id_in := ESI_ID, SlavePos := 0, uid_in := 1, ESI_RET => ESI_WR_RET);
FB_ESI_Read1(RD_EN := ESI_RD_EN, FileSize := 1024, SlavePos := 0, ESI_RET => ESI_RD_RET);

case iDDTestState OF
0:(*-------------------- 8DI8DO module test init --------------------*)
	xPower_24V := TRUE;  //module power dowm
	DI();
	timer_disable();
	result_reset(MD_IN := ModuleSel);
	
	(* module selection *)
	IF iZioDDSel = 1 THEN  (* ZIOD-E0808DN *)
		ZIOD_E0808DN.bDisableEnable := FALSE;

		ESI_ID := 10;
		PID_DO := 16#0101001E;
	ELSIF iZioDDSel = 2 THEN  (* ZIOD-E0808DP *)
		ZIOD_E0808DP.bDisableEnable := FALSE;

		ESI_ID := 11;
		PID_DO := 16#0101001F;
	END_IF
	
1:(*-------------------- 8DI8DO module test config --------------------*)
	xPower_24V := FALSE;  //module power up
	xDDTestSuccess := FALSE;
	xDDTestFailed := FALSE;
	TACR1_IN := TRUE;
	TPR1_PT := diCfgTimeout;  //config timeout
	TPR2_PT := diTestTimeout;  //total timeout
	TPR1_En := TRUE;
	TPR2_En := TRUE;
	uid_get(module_in := ModuleSel, no_in := 1);
	
	IF SerialNo = 0 and iMode = 0 THEN  (* �����Ա����������к� *)
		xSN_Input_Rq := TRUE;
		iDDTestState := 0;
		TPR1_En := FALSE;
		TPR2_En := FALSE;
		TPR1_Rst := TRUE;
		TPR2_Rst := TRUE;
		RETURN;
	END_IF
	
	IF TPR1_ET > 3000 THEN  (* time for relay stable *)
		ESI_RD_EN := TRUE;  //read ESI for the UID
	END_IF
	
	IF ESI_RD_RET = 1 THEN  (* ESI Read success *)
		_ECATMaster.bStartMaster := TRUE;  (* start the EtherCAT master========> *)
	ELSIF ESI_RD_RET < 0 THEN  (* ESI read failed *)
		iDDTestState := 9;
	END_IF
	IF _ECATMaster.bMasterRunState = TRUE THEN
		ESI_RD_EN := FALSE;
		TPR1_En := FALSE;
		iBarCnt := 20;
		iDDTestState := 2;  (* go to next state *)
	END_IF
	
	if (TPR1_ET mod 500 = 250) and iBarCnt < 20 THEN
		iBarCnt := iBarCnt + 1;  (* Progress bar control *)
	END_IF

	IF TPR1_ET = TPR1_PT THEN  (* DO module config timeout failed *)
		TPR1_En := FALSE;
		iDDTestState := 9;
	END_IF

2:(*-------------------- 8DI8DO module test process1 --------------------*)
	(* 
	 * @details DO 8��ͨ���������������1S
	**)
	FOR i :=0 TO 7 BY 1 DO  (* DO�����Ч��ƽ��׼���������״̬ *)
		bDDO_N0[i] := TRUE;
	END_FOR
	
	TPR3_PT := 2000;
	TPR3_En := TRUE;  //Start timer for DO test
	IF TPR3_ET = TPR3_PT THEN  (* DO test success *)
		TPR3_En := FALSE;
		iBarCnt := 25;  //progress bar control
		iDDTestState := 3;  (* go to next state *)
	END_IF
	
	IF (TPR3_ET mod 500 = 0) AND iBarCnt < 25 THEN
		iBarCnt := iBarCnt + 1;  (* Progress bar control *)
	END_IF
	
	FOR i := 0 to 7 BY 1 DO
		IF TPR3_ET > 1000 AND xDI_GL20_A[i] = FALSE THEN  (* DO test failed-_- *)
			Result_DOs_Carry := 2;
			iDDTestState := 9;
		END_IF
	END_FOR
	
	IF TPR2_ET = TPR2_PT THEN  (* Total timer error *)
		TPR2_En := FALSE;
		iDDTestState := 9;
	END_IF

3:(*-------------------- 8DI8DO module test process2 --------------------*)
	(* 
	 * @details �պϼ̵�����DO��·����0.5S
	**)
	xRelay1 := TRUE;  //�պϼ̵���
	TPR4_PT := 700;  //200ms for output stable time, 500ms for shortcut test
	TPR4_En := TRUE;
	IF TPR4_ET = TPR4_PT THEN
		TPR4_En := FALSE;
		xRelay1 := FALSE;  //�ɿ��̵���
		iDDITestState := 0;
		iBarCnt := 30;
		Result_DOs_ShortCut := 1;
		iDDTestState := 4;  (* go to next state *)
	END_IF
	
	IF (TPR4_ET mod 200 = 0) AND iBarCnt < 30 THEN
		iBarCnt := iBarCnt + 1;  (* Progress bar control *)
	END_IF
	
	for i := 0 to 7 by 1 DO
		IF TPR4_ET > 200 AND xDI_GL20_A[i] = TRUE THEN  (* DO test failed-_- *)
			TPR4_En := FALSE;
			Result_DOs_Carry := 2;
			Result_DOs_ShortCut := 2;
			iDDTestState := 9;
		END_IF
	END_FOR

4:(*-------------------- 8DI8DO module test process3 --------------------*)
	(*
	 * @details DIͨ�����ԣ�ͬʱ���������DOͨ����Ч��ƽ
	**)
	TPR5_PT := 200;  //200ms for output stable time
	TPR5_En := TRUE;
	FOR j := 0 to 7 by 1 DO
		IF TPR5_ET = TPR5_PT and bDIEasy[j] = FALSE THEN  (* DO test failed-_- *)
			TPR5_En := FALSE;
			Result_DOs_Carry := 2;
			iDDTestState := 9;
		END_IF
	END_FOR

	case iDDITestState OF
	0:(*---------- DI test init ----------*)
		i := 0;
		iDIFailTimes := 0;
		iDDITestState := 1;
	
	1:(*---------- DI test state1 ----------*)
		iChnMax := 2;  //8 channel for DI
		TimerCnt1Max := 5000;
		EI();
		IF TimerCnt1 = TimerCnt1Max THEN
			DI();
			TimerCnt1 := 0;
			i := i + 1;
			if i = iChnMax THEN
				i := 0;
				TimerCnt1 := 0;
				iBarCnt := iBarCnt + 1;  //Progress bar control
				iDDITestState := 2;
			END_IF
		ELSIF TimerCnt1 mod 1000 = 0 THEN
			iBarCnt := iBarCnt + 1;  //Progress bar control
		END_IF
		
		for i_ddi := i to i+6 by 2 DO
			IF bDDI_N0[i_ddi] = TRUE THEN  (* DI test failed *)
				DI();
				TimerCnt1 := 0;
				Result_DIs_2ms := 2;
				iDIFailTimes := iDIFailTimes + 1;
				if iDIFailTimes >= 3 THEN
					iDDITestState := 4;
				END_IF
			END_IF
		END_FOR
	
	2:(*---------- DI test state2 ----------*)
		TimerCnt2Max := 5000;
		EI();
		IF TimerCnt2 = TimerCnt2Max THEN
			DI();
			TimerCnt2 := 0;
			i := i + 1;
			if i = iChnMax THEN
				FOR i := 0 to 7 by 1 DO
					if bDDI_OK[i] = FALSE THEN  (* DI test failed *)
						Result_DIs_2ms := 3;
						iDDITestState := 4;
					ELSE                        (* DI test success *)
						bDDI_OK[i] := FALSE;
						iDDITestState := 3;
					END_IF
				END_FOR
				i := 0;
				TimerCnt2 := 0;
			END_IF
		ELSIF TimerCnt2 mod 1000 = 0 THEN
			iBarCnt := iBarCnt + 1;  //Progress bar control
		END_IF
		
		for i_ddi := i to i+6 by 2 DO
			(*IF i_ddi = 0 THEN
				i_ddi_cp := i_ddi + 1;
			ELSIF i_ddi = 1 THEN
				i_ddi_cp := i_ddi - 1;
			END_IF*)
			IF bDDI_N0[i_ddi] = TRUE THEN
				bDDI_OK[i_ddi] := TRUE;
			END_IF
		END_FOR
	
	3:(*---------- DI test success ----------*)
		DI();
		TPR5_En := FALSE;
		iBarCnt := 50;
		Result_DIs_2ms := 1;
		iDDITestState := 0;
		iDDTestState := 5;
		
	4:(*---------- DI test failed ----------*)
		DI();
		TPR5_En := FALSE;
		iDDITestState := 0;
		iDDTestState := 9;

	END_CASE
	
	IF TPR2_ET = TPR2_PT THEN  (* Total timer error *)
		TPR2_En := FALSE;
		iDDTestState := 9;
	END_IF

5:(*-------------------- DO output test for 60S and LED confirm --------------------*)
	(*
	 * @details 60Sʱ��ȷ��LED�ƣ��˼�DOͨ��һֱ�����Ч��ƽ
	**)
	TPR2_En := FALSE;  //disable timer for total timeout
	//xLED_CF := TRUE;
	TPR6_PT := diDOutputTime;  //set DO output test time
	TPR6_En := TRUE;
	IF TPR6_ET < TPR6_PT THEN
		FOR i := 0 to 7 by 1 DO
			bDOEasy[i] := TRUE;  //ģ��DIͨ��������Ч
		END_FOR
	ELSE  (* LED confirm timeout *)
		Result_LEDs_DO := -2;
		iDDTestState := 9;  (* LED timeout failed-_- *)
	END_IF
	
	IF Result_LEDs_DO = 1 THEN
		iDDTestState := 6;  //go to the next state
	ELSIF Result_LEDs_DO = -1 THEN
		iDDTestState := 9;  //LED error
	END_IF
	
	IF TPR6_ET mod 10 = 0 THEN
		xBeep := FALSE;
	ELSIF TPR6_ET Mod 10 = 5 THEN
		xBeep := TRUE;
	END_IF
	
	iFrac := TPR6_PT/40;
	if TPR6_ET mod iFrac = 0 and iBarCnt < 95 THEN
		iBarCnt := iBarCnt + 1;  //progress bar control
	END_IF
	
	FOR j := 0 to 7 by 1 DO
		IF bDIEasy[j] = FALSE THEN  (* DO test failed-_- *)
			Result_DOs_Carry := 2;
			iDDTestState := 9;
		END_IF
	END_FOR

6:(*-------------------- keep DO output until 60S arrived --------------------*)
	xBeep := FALSE;
	
	IF TPR6_ET = TPR6_PT THEN
		TPR6_En := FALSE;
		iBarCnt := 95;
		Result_DOs_Carry := 1;
		for i := 0 to 7 BY 1 DO
			bDDO_N0[i] := FALSE;
		END_FOR
		iDDTestState := 7;  (* go to next state *)
		RETURN;
	END_IF
	
	iFrac := TPR6_PT/50;
	if TPR6_ET mod iFrac = 0 and iBarCnt < 95 THEN
		iBarCnt := iBarCnt + 1;  //progress bar control
	END_IF
	
	FOR j := 0 to 7 by 1 DO
		IF bDIEasy[j] = FALSE THEN  (* DO test failed-_- *)
			Result_DOs_Carry := 2;
			iDDTestState := 9;
		END_IF
	END_FOR

7:(*-------------------- DO output invalid for 1S --------------------*)
	TPR6_PT := 1000;
	TPR6_En := true;
	IF TPR6_ET = TPR6_PT THEN
		TPR6_En := FALSE;
		iBarCnt :=  100;  //Progress bar control
		iDDTestState := 8;
	ELSIF TPR6_ET Mod 200 = 0 AND iBarCnt < 100 THEN
		iBarCnt := iBarCnt + 1;  //progress bar control
	END_IF
	
	FOR j := 0 to 7 by 1 DO
		IF TPR6_ET > 100 AND bDIEasy[j] = TRUE THEN  (* DO test failed-_- *)
			TPR6_En := FALSE;
			Result_DOs_Carry := 2;
			iDDTestState := 9;
		END_IF
	END_FOR

8:(*-------------------- 8DI8DO module test success --------------------*)
	DI();
	TACR1_IN := FALSE;
	FOR i := 0 to 7 by 1 DO
		bDOEasy[i] := FALSE;
		bDDO_N0[i] := FALSE;
	END_FOR
	xDDTestSuccess := TRUE;
	
	Result_DDs := 1;
	xDDTestRecord := TRUE;
	
	TPR9_PT := 3000;
	TPR9_En := TRUE;
	if TPR9_ET mod 1000 < 5 THEN
		xBeep := FALSE;
	ELSIF TPR9_ET mod 1000 > 495 and TPR9_ET mod 1000 < 505 THEN
		xBeep := TRUE;
	END_IF

9:(*-------------------- 8DI8DO module test failed --------------------*)
	DI();
	FOR i := 0 to 7 by 1 DO
		bDOEasy[i] := FALSE;  //DI������Ч
		bDDO_N0[i] := FALSE;  //DO�����Ч
	END_FOR
	TACR1_IN := FALSE;
	xDDTestFailed := TRUE;
	
	Result_DDs := 0;
	xDDTestRecord := TRUE;
	
	TPR10_PT := 3000;
	TPR10_En := TRUE;
	if TPR10_ET < 3000 THEN
		xBeep := TRUE;
	ELSE
		xBeep := FALSE;
	END_IF

10:(*-------------------- ESI Write --------------------*)
	IF SerialNo = 0 THEN
		xSN_Input_Rq := TRUE;
		iDDTestState := 0;
		RETURN;
	END_IF
	
	ESI_WR_EN := TRUE;
	TPR7_PT := 13000;  //set ESI write timeout
	TPR7_En := TRUE;

	if TPR7_ET mod 130 = 0 AND iEsiBarCnt < 100 THEN  (* Progress bar control *)
		iEsiBarCnt := iEsiBarCnt + 1;
	END_IF
	
	IF TPR7_ET = TPR7_PT AND ESI_WR_RET = 0 THEN  (* timeout error *)
		ESI_WR_RET := -2;
	ELSIF TPR7_ET = TPR7_PT and ESI_WR_RET = 1 THEN  (* ESI write success *)
		bESI_WrSuccess := TRUE;//i8DI8DOTestState := 0;
	END_IF

11:(*-------------------- ESI Read --------------------*)
	ESI_RD_EN := TRUE;
	TPR8_PT := 9000;  //set ESI read timeout
	TPR8_En := TRUE;
	
	if TPR8_ET mod 90 = 0 AND iEsiBarCnt < 100 THEN  (* Progress bar control *)
		iEsiBarCnt := iEsiBarCnt + 1;
	END_IF
	
	IF TPR8_ET = TPR8_PT AND ESI_RD_RET = 0 THEN  (* timeout error *)
		ESI_RD_RET := -2;
	ELSIF TPR8_ET = TPR8_PT and ESI_RD_RET = 1 THEN  (* ESI write success *)
		bESI_RdSuccess := TRUE;//i8DI8DOTestState := 0;
	END_IF

12:
	;
	
ELSE
	DI();
	timer_reset();
	_ECATMaster.bStopMaster := TRUE;
	
	FOR i := 0 to 7 by 1 DO
		bDOEasy[i] := FALSE;  //DI������Ч
	END_FOR
	
	ESI_WR_EN := FALSE;
	ESI_RD_EN := FALSE;
	xDDTestRecord := FALSE;
	
	IF _ECATMaster.bMasterRunState = FALSE THEN
		;//xPowerRelay := TRUE;  //module power down
		iDDTestState := 0;
	END_IF
END_CASE
    