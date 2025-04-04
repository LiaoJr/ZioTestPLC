AutoShop            2.4  5.03                                                                                                           ��  CLVTItem              �             �             �             ��(* 
 * @brief  ����������ӳ���
 * @Result_CPs ��������Խ����
 *			Result_CPs        : 0->not test yet, 1->success, 2->failed
 *          Result_Eeprom     : 0->not test yet, 1->success, 2->failed
 *          Result_Ecat       : 0->not test yet, 1->success, 2->failed
 *			Result_LEDs_CP    : 0->not test yet, 1->success, 2->failed, 3->LED confirm timeout
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

if iMode = 0 THEN
	FB_ESI_Write1(WR_EN := ESI_WR_EN, 
				  esi_id_in := ESI_ID, 
				  SlavePos := 1, 
				  uid_in := 1, 
				  ESI_RET => ESI_WR_RET);
elsif iMode = 1 THEN
	FB_ESI_Read1(RD_EN := ESI_RD_EN,
				 FileSize := 1024,
				 SlavePos := 0,
				 UID_OUT_H => UID_CP_h,
				 UID_OUT_L => UID_CP_l,
				 ESI_RET => ESI_RD_RET);
END_IF
    