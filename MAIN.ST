AutoShop            2.4  5.03                                                                                                           ��  CLVTItem              �             �             �             �!(* MAIN PROGRAM *)

//xECAT_Ctrl := TRUE;
//xBeep := TRUE;
//xPowerRelay := TRUE;

FB_ESI_Update1(UD_EN := ESI_UD_EN,
               FileSize := 1024,
               SlavePos := 1,
               UD_PT := ESI_UD_PT,
               UD_RET => ESI_UD_RET,
               UD_ET => ESI_UD_ET);

(* ���ݶ�Ӧ��ZIOģ������Ӧ���ӳ��� *)
CASE ModuleSel OF
	0:
	test_times := 0;
	(* �������д�վ *)
	ZCPC_80801.bDisableEnable := TRUE;
	ZCPC_80801_Pio.bDisableEnable := TRUE;
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
	
	ZIOC_E0008AU_Pio_Aux.bDisableEnable := TRUE;
	ZIOD_E0808DN_Aux.bDisableEnable := TRUE;
	
	_ECATMaster.bStopMaster := TRUE;
	
	(* ����ѡ�����ý����¼���� *)
	if diPassWordIn = diPassWordSet AND xPassWord_CF = TRUE THEN
		xLoginSuccess := true;
		xPassWord_CF := false;
	elsif diPassWordIn <> diPassWordSet AND xPassWord_CF = TRUE THEN
		xLoginFailed := TRUE;
		xPassWord_CF := false;
	END_IF
	
	1:(* ==============================ZCPC-E80801============================== *)
	SBR_ZCP();
	
	2:(* ==============================ZIO-E0016DX============================== *)
	SBR_ZIODO();
	
	3:(* ==============================ZIO-E1600DX============================== *)
	SBR_ZIODI();
	
	4:(* ==============================ZIO-E0008AX============================== *)
	SBR_ZIOAO();
	
	5:(* ==============================ZIO-E0800AX============================== *)
	SBR_ZIOAI();
	
	6:(* ==============================ZIO-E0808DX============================== *)
	SBR_ZIODD();
	
ELSE
	;
END_CASE;
    