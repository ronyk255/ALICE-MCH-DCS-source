// $License: NOLICENSE
//--------------------------------------------------------------------------------
/**
  @file $relPath
  @copyright $copyright
  @author rkuriako
*/

//--------------------------------------------------------------------------------
// Libraries used (#uses)
#uses "CtrlRDBAccess"
#uses "fwFSM/fwCU"
//--------------------------------------------------------------------------------
// Variables and Constants
//--------------------------------------------------------------------------------
/**
 */

void main()
{
  /*DpConnect provides a connection to the Data-point recursively whenever the value in the data-point gets changed and executes the function mchConfigFEE*/
 //dpConnect("mchConfigFEE","mch_hvLvLeft:aliDcsRun_1.state","mch_hvLvLeft:LHCClock.TTCMI/MICLOCK_TRANSITION_test","mch_hvLvLeft:LHCClock.TTCMI/MICLOCK_test","mch_hvLvLeft:LHCClock.ClockChange");
  dpConnect("mchConfigFEE", "mch_hvLvLeft:aliDcsRun_1.state", "mch_hvLvLeft:LHCClock.TTCMI/MICLOCK_TRANSITION", "mch_hvLvLeft:LHCClock.TTCMI/MICLOCK", "mch_hvLvLeft:LHCClock.ClockChange");
}

void mchConfigFEE(string dpe1, int state, string dpe2, string ClockTransition, string dpe3, string Clock, string dpe4, string ClockChng)
{
  time t1, tr1, tr2;
  time clocktime;

  //Below gets data from the MCH main Run unit for the current exectuion of SOR from AliECS if SOR was executed
  string clocktransitionUpdate, clockupdate, clockchange, runType, triggerMode, sorMode, runNumber, CSUM;
  float clusterSum,LastCSUM;
  dpGet("mch_hvLvLeft:LHCClock.ClockChange", clockchange);
  dpGet("mch_hvLvLeft:aliDcsRun_1.runType:_original.._value", runType);
  dpGet("mch_hvLvLeft:aliDcsRun_1.runNo:_original.._value", runNumber);
  dpGet("mch_hvLvLeft:aliDcsRun_1.triggerMode:_original.._value", triggerMode);
  dpGet("mch_hvLvLeft:aliDcsRun_1.clusterSum:_original.._value", clusterSum);
  dpGet("mch_hvLvLeft:aliDcsRun_1.sorMode:_original.._value", sorMode);
  dpGet("mch_fee:mchUseCurrentConfig.UseCurrentCSum:_original.._value", LastCSUM);
 

  dpGet("mch_hvLvLeft:LHCClock.TTCMI/MICLOCK_TRANSITION_test:_original.._stime", tr1);
  dpGet("mch_hvLvLeft:LHCClock.TTCMI/MICLOCK_test:_original.._stime", tr2);
  if (clusterSum == TRUE || LastCSUM ==  TRUE)
  {
    CSUM = "ENABLED";
  }
  else
  {
    CSUM = "DISABLED";
  }
  if (state == 2)
  {
    dpSet("mch_fee:OutputDataScreens.MCHSORLog", "------------------------------------------------");
    dpSet("mch_fee:OutputDataScreens.MCHSORLog", "------------------------------------------------");
    dpSet("mch_fee:OutputDataScreens.MCHSORLog", "START OF SOR PROGRESSING");
    dpSet("mch_fee:OutputDataScreens.MCHSORLog", "------------------------------------------------");
    dpSet("mch_fee:OutputDataScreens.MCHSORLog", "------------------------------------------------");
  }

  if (tr1 >= t1)
  {
    clocktransitionUpdate = "TRUE";
  }
  if (tr2 >= t1)
  {
    clockupdate = "TRUE";
  }
  //main check to see if a clock transition was initiated from central team or if a SOR was executed from ALIECS
  if ((state == 2 && runType == "PEDESTALS") || (state == 2 && (runType == "PHYSICS" || runType == "TECHNICAL" || runType == "COSMICS") && triggerMode != "") || (ClockTransition == 5 && ClockChng == "FALSE") || (ClockTransition == 5 && ClockChng == "TRUE")) //first ClockTransition = "3 and 2nd = "0" for enable else both = "5" for disable
  {

    dpSet("mch_fee:OutputDataScreens.MCHSORLog", "");
    dyn_dyn_mixed SolLV_CH, FECLV_CH, sol_links, CRU_ID, mask_links, DS_links;
    dyn_string sol_crates, sol_boards, sol_lvps, sol_chan, flp_id_check, cru_addr, sol_id, flp_id, cham_side, fec_lvps, fec_dchan, fec_achan, CHAMID;
    dyn_string sol_crates, sol_boards, sol_lvps, sol_chan, cru_addr, sol_id, flp_id, cham_side, fec_lvps, fec_dchan, fec_achan;
    dyn_string sol_crates, sol_boards, sol_lvps, sol_chan, cru_id, sol_id, flp_id, cham_side, CHAMID;
    dbCommand FEC_lvps_cmd, SOL_cmd, SOL_lvps_cmd, MASK_cmd, tempTable_cmd, DROPtempTable_cmd, SOLLV_cmd, FECLV_cmd;
    int l = 1, j;
    time sortime;
    dyn_string GBTClockReturn, GBTPhaseReturn;
    dyn_string Solfail, Solarfail;
    dyn_string InitReturnANS, InitReturnERR, failedSOLAR;
    dyn_time InittimeANS, InittimeERR;
    time t1, t2;

    dbCommand incldet_cmd;
    dyn_dyn_mixed INCL_DET;
    string connectString = "Driver=QOCI8;DATABASE=alionr;User=mchfero;Password=mch1234"; //connection string necessary for DB function communication to Oracle DB
    string errMsg;
    dbConnection dbCon;
    dyn_mixed pass_detparams;
    string sel_mch, sel_st, sel_ch, sel_chside, sel_DE, configMode;
    string gbtclock, dp = "mch_fee:", dp2 = "mch_hvLvLeft", dp3 = "mch_hvLvRight";
    int len_links, len_cru, len_sol, len_mask_links, len_DS_links, len_SOLLV, len_FECLV;
    dyn_int cru_links, cru_IDS;

    // get included chmabers/slats from FSM
    dyn_string ds_chamber, ds_children,ds_list,ds_log,included_cham,included_slatfsm;
		dyn_int di_childrenType;
		string s_node,s_type,s_state,included_ch,included_slat;
		int i,j,k,r=1;
		included_ch ="(";
		included_slat ="(";
		s_node="MchHvLvLeft";
		ds_chamber=fwCU_getIncludedChildren(di_childrenType, s_node);
		//checking chambers 01-04 and 05-10 left
		for (i=1;i<=dynlen(ds_chamber);i++) {
	  ds_children=fwCU_getIncludedChildren(di_childrenType,ds_chamber[i]);

			for (j=1;j<=dynlen(ds_children);j++) {
				fwCU_getType(ds_children[j],s_type);
							if ((s_type=="FwWienerMarathonChannelLv")) {
					//DebugTN(ds_chamber[i]+" child="+ds_children[j]+" type="+s_type);
					included_slatfsm[r] = ds_children[j];
					r++;
				}

			}
		}

		s_node="MchHvLvRight";
		ds_chamber=fwCU_getIncludedChildren(di_childrenType, s_node);
		//checking chambers 01-04 and 05-10 left
		for (i=1;i<=dynlen(ds_chamber);i++) {
			ds_children=fwCU_getIncludedChildren(di_childrenType,ds_chamber[i]);
			for (j=1;j<=dynlen(ds_children);j++) {
				fwCU_getType(ds_children[j],s_type);
				if ((s_type=="FwWienerMarathonChannelLv")) {
				//	DebugTN(ds_chamber[i]+" child="+ds_children[j]+" type="+s_type);
					included_slatfsm[r] = ds_children[j];
					r++;
				}

			}

		}



    /*  for (i = 1; i <= dynlen(included_cham); i++)
      {
        if (i < dynlen(included_cham))
        {
          included_ch += "'" + included_cham[i] + "',";
          included_slat += "'" + included_slatfsm[i] + "',";
        }
        else
        {
          included_ch += "'" + included_cham[i] + "')";
          included_slat += "'" + included_slatfsm[i] + "')";
        }
      }*/

     DebugTN("Included soalr list from FSM: ", included_slatfsm);
    // DebugTN("child", included_slat);

    /////  -----------------------------DB Access-------------------------------------------////

    fwDbOption("Reset", 0);
    if (!isFunctionDefined("fwDbOption"))
    {
      DebugTN("ERROR: CtrlRDBAccess library not loaded, please add it to your config file");
      return;
    }

    // Open the DB connection
    fwDbOpenConnection(connectString, dbCon);
    if (fwDbCheckError(errMsg, dbCon))
    {
      DebugTN("ERROR: fwDbOpenConnection ", errMsg);
      dpSet("mch_fee:OutputDataScreens.MCHSORLog", "ERROR: fwDbOpenConnection " + errMsg);
      return;
    }

    fwDbStartCommand(dbCon, "DELETE FROM INCL_DETECTORS", DROPtempTable_cmd);
    if (fwDbCheckError(errMsg, DROPtempTable_cmd))
    {
      DebugTN("ERROR: fwDbStartCommandDELETE ", errMsg);
      return;
    }
    fwDbExecuteCommand(DROPtempTable_cmd);


    // Check if the CtrlRDBAccess is loaded


    dbCommand FEC_lvps_cmd, SOL_cmd, SOL_lvps_cmd, MASK_cmd, tempTable_cmd, DROPtempTable_cmd, SOLLV_cmd, FECLV_cmd;
    // Insert included items into tmp table in DB

    fwDbStartCommand(dbCon, "DELETE FROM INCL_DETECTORS_FSM", DROPtempTable_cmd);
    if (fwDbCheckError(errMsg, DROPtempTable_cmd))
    {
      DebugTN("ERROR: fwDbStartCommandDELETE ", errMsg);
      return;
    }
    fwDbExecuteCommand(DROPtempTable_cmd);
    if (fwDbCheckError(errMsg, DROPtempTable_cmd))
    {
      DebugTN("ERROR: fwDbExecuteCommand ", errMsg);
      return;
    }

    fwDbStartCommand(dbCon, "INSERT INTO INCL_DETECTORS_FSM(DS_CHAMBERS,SOLAR_FLAG,GBT_FLAG,SAMPA_FLAG) VALUES(:pass_detparams1,0,0,0)", tempTable_cmd);
    if (fwDbCheckError(errMsg, tempTable_cmd))
    {
      DebugTN("ERROR: fwDbStartCommand ", errMsg);
      return;
    }
    dyn_dyn_mixed pass_inclparams;
    for (int i = 1; i <= dynlen(included_slatfsm); i++)
    {
      pass_inclparams[i][1] = included_slatfsm[i];
    }
    fwDbBindAndExecute(tempTable_cmd, pass_inclparams);
    if (fwDbCheckError(errMsg, tempTable_cmd))
    {
      DebugTN("ERROR: fwDbBindAndExecute ", errMsg);
      return;
    }

    //// Starting the command, this is where you put your SQL query
    // Read lvps OF SOLAR FROM DB
    fwDbStartCommand(dbCon, "SELECT DISTINCT sol_crate,SOL_LVPS,SOL_CHAN,cru_id FROM CRU_Mapping WHERE DS_SOLARFSM in (SELECT DS_CHAMBERS FROM INCL_DETECTORS_FSM)", SOL_lvps_cmd);
    // Read Lvps OF FEC FROM DB
    fwDbStartCommand(dbCon, "SELECT DISTINCT FEC_LVPS,FEC_DCHAN,FEC_ACHAN FROM CRU_Mapping WHERE DS_SOLARFSM in (SELECT DS_CHAMBERS FROM INCL_DETECTORS_FSM)", FEC_lvps_cmd);
    // Read Solar links and cru id FROM DB
    fwDbStartCommand(dbCon, "SELECT c_ID,cru_link,cru_id,SOL_CRATE,sol_board_id,SOL_LVPS,SOL_CHAN,SOLAR_ID,flp_id,ch_side,ds_chamber,ds_children,fec_lvps,fec_dchan,fec_achan,ch_id,DS_SOLARFSM,PCI_ADDR FROM CRU_Mapping WHERE DS_SOLARFSM in (SELECT DS_CHAMBERS FROM INCL_DETECTORS_FSM) order by c_id", SOL_cmd);
    // Read cru id FROM DB
    fwDbStartCommand(dbCon, "SELECT enable_mask FROM board_enabled WHERE DS_SOLARFSM in (SELECT DS_CHAMBERS FROM INCL_DETECTORS_FSM)", MASK_cmd);
    // Read SOL LV channels
    fwDbStartCommand(dbCon, "SELECT DISTINCT ch_side,SOL_LVPS,SOL_CHAN FROM CRU_Mapping WHERE DS_SOLARFSM in (SELECT DS_CHAMBERS FROM INCL_DETECTORS_FSM)", SOLLV_cmd);
    // Read FEC LV channels
    fwDbStartCommand(dbCon, "SELECT DISTINCT ch_side, FEC_LVPS,FEC_DCHAN,FEC_ACHAN FROM CRU_Mapping WHERE DS_SOLARFSM in (SELECT DS_CHAMBERS FROM INCL_DETECTORS_FSM)", FECLV_cmd);

    if (fwDbCheckError(errMsg, FEC_lvps_cmd))
    {
      DebugTN("ERROR: fwDbStartCommand FEC_lvps_cmd ", errMsg);
      return;
    }
    if (fwDbCheckError(errMsg, SOL_lvps_cmd))

    {
      DebugTN("ERROR: fwDbStartCommand SOL_lvps_cmd ", errMsg);
      return;
    }

    if (fwDbCheckError(errMsg, SOL_cmd))

    {
      DebugTN("ERROR: fwDbStartCommand SOL_cmd ", errMsg);
      return;
    }

    if (fwDbCheckError(errMsg, MASK_cmd))

    {
      DebugTN("ERROR: fwDbStartCommand MASK_cmd ", errMsg);
      return;
    }

    if (fwDbCheckError(errMsg, SOLLV_cmd))

    {
      DebugTN("ERROR: fwDbStartCommand SOLLV_cmd ", errMsg);
      return;
    }

    if (fwDbCheckError(errMsg, FECLV_cmd))

    {
      DebugTN("ERROR: fwDbStartCommand FECLV_cmd", errMsg);
      return;
    }

    fwDbExecuteCommand(FEC_lvps_cmd);
    fwDbExecuteCommand(SOL_lvps_cmd);
    fwDbExecuteCommand(SOL_cmd);
    fwDbExecuteCommand(MASK_cmd);

    fwDbExecuteCommand(SOLLV_cmd);
    fwDbExecuteCommand(FECLV_cmd);
    // DebugTN("data",SOL_cmd);

    if (fwDbCheckError(errMsg, FEC_lvps_cmd))
    {
      DebugTN("ERROR: fwDbExecuteCommand FEC_lvps_cmd ", errMsg);
      return;
    }
    if (fwDbCheckError(errMsg, SOL_lvps_cmd))

    {
      DebugTN("ERROR: fwDbExecuteCommand SOL_lvps_cmd", errMsg);
      return;
    }
    if (fwDbCheckError(errMsg, SOL_cmd))
    {
      DebugTN("ERROR: fwDbExecuteCommand SOL_cmd ", errMsg);
      return;
    }

    if (fwDbCheckError(errMsg, MASK_cmd))
    {
      DebugTN("ERROR: fwDbExecuteCommand MASK_cmd", errMsg);
      return;
    }

    if (fwDbCheckError(errMsg, SOLLV_cmd))

    {
      DebugTN("ERROR: fwDbExecuteCommand SOLLV_cmd ", errMsg);
      return;
    }

    if (fwDbCheckError(errMsg, FECLV_cmd))

    {
      DebugTN("ERROR: fwDbExecuteCommand FECLV_cmd", errMsg);
      return;
    }

    dyn_dyn_mixed SOL_LVPS, FEC_LVPS, sol_links, CRU_ID, mask_links, DS_links, SolLV_CH, FECLV_CH;

    // get data from the SQL query db command and store it in vairable (only dyn_dyn_mixed variable works to get data from db)
    fwDbGetData(FEC_lvps_cmd, FEC_LVPS);
    fwDbGetData(SOL_lvps_cmd, SOL_LVPS);
    fwDbGetData(SOL_cmd, sol_links);
    fwDbGetData(MASK_cmd, mask_links);
    fwDbGetData(SOLLV_cmd, SolLV_CH);
    fwDbGetData(FECLV_cmd, FECLV_CH);

     DebugTN("List of SOLAR LV channels used for clock transition to be Switched off: ",SolLV_CH);

    if (fwDbCheckError(errMsg, FEC_lvps_cmd))
    {
      DebugTN("ERROR: fwDbGetData FEC_lvps_cmd ", errMsg);
      return;
    }
    if (fwDbCheckError(errMsg, SOL_lvps_cmd))
    {
      DebugTN("ERROR: fwDbGetData SOL_lvps_cmd", errMsg);
      return;
    }

    if (fwDbCheckError(errMsg, SOL_cmd))
    {
      DebugTN("ERROR: fwDbGetData SOL_cmd", errMsg);
      return;
    }
    if (fwDbCheckError(errMsg, MASK_cmd))
    {
      DebugTN("ERROR: fwDbGetData MASK_cmd", errMsg);
      return;
    }

    if (fwDbCheckError(errMsg, SOLLV_cmd))

    {
      DebugTN("ERROR: fwDbGetData SOLLV_cmd ", errMsg);
      return;
    }

    if (fwDbCheckError(errMsg, FECLV_cmd))

    {
      DebugTN("ERROR: fwDbGetData FECLV_cmd", errMsg);
      return;
    }

    /////  -----------------------------CONFIGURE FEE-------------------------------------------////

    len_links = dynlen(sol_links);

    len_sol = dynlen(SOL_LVPS);

    len_cru = dynlen(CRU_ID);
    len_mask_links = dynlen(mask_links);
    len_DS_links = dynlen(DS_links);
    len_SOLLV = dynlen(SolLV_CH);
    len_FECLV = dynlen(FECLV_CH);
    // DebugTN("DS_links OF   ",DS_links[1]);
    // DebugTN("NUMBER OF SOLAR LINKS ",sol_links);

    int l = 1;
    for (int i = 1; i <= len_links; i++)
    {
      sol_id[l] = sol_links[i][8];
      cru_links[l] = sol_links[i][2];
      sol_crates[l] = sol_links[i][4];
      sol_boards[l] = sol_links[i][5];
      sol_lvps[l] = sol_links[i][6];
      sol_chan[l] = sol_links[i][7];
      flp_id[l] = sol_links[i][9];
      flp_id_check[l] = sol_links[i][9];
      cham_side[l] = sol_links[i][10];
      fec_lvps[l] = sol_links[i][13];
      fec_dchan[l] = sol_links[i][14];
      fec_achan[l] = sol_links[i][15];
      CHAMID[l] = sol_links[i][16];
      cru_id[l] = sol_links[i][3];
      cru_addr[l] = sol_links[i][18];
      l++;
    }
    // int len_links = dynlen(cru_links);
    int len_cruid = dynlen(cru_IDS);
    int len_sollvps = dynlen(sol_lvps);
    int len_solchan = dynlen(sol_chan);
    // DebugTN("sol_id ", sol_id);
    //  DebugTN("cru_links ", cru_links);
    //  DebugTN("sol_crates ", sol_crates);
    //  DebugTN("sol_boards", sol_boards);
    // DebugTN("sol_lvps", sol_lvps);
    // DebugTN("sol_chan", sol_chan);
    // DebugTN("len_links  ", len_links);

    delay(1);
    dyn_string switchoff, switchon;
   // if (ClockTransition != "0" && ClockTransition != "2" && ClockTransition != "1" && clockchange == "FALSE")
      if (ClockTransition == "5" && clockchange == "FALSE") //clockTransition == "5" disable clock transition procedure, "3"  enable clock tranistion
    {

      dpSet("mch_hvLvLeft:aliDcsRun_1.state", 6);
      // dpSet("mch_fee:mchUseCurrentConfig.UseCurrentRunType:_original.._value", "");

      dpSet("mch_fee:OutputDataScreens.MCHSORLog", "---------------------------------------");
      dpSet("mch_fee:OutputDataScreens.MCHSORLog", "---------------------------------------");
      dpSet("mch_fee:OutputDataScreens.MCHSORLog", "START OF CLOCK TRANSITION PROCEDURE");
      dpSet("mch_fee:OutputDataScreens.MCHSORLog", "---------------------------------------");
      dpSet("mch_fee:OutputDataScreens.MCHSORLog", "---------------------------------------");
      dpSet("mch_hvLvLeft:LHCClock.ClockChange:_original.._value", "TRUE");

      dpSet("mch_fee:OutputDataScreens.MCHSORLog", "");
      dpSet("mch_fee:OutputDataScreens.MCHSORLog", "CLOCK TRANSITION STARTED");
      dpSet("mch_fee:OutputDataScreens.MCHSORLog", "SWITCHING OFF ALL SOLAR LV...");

      for (int i = 1; i <= len_SOLLV; i++)
      {
        if (SolLV_CH[i][1] == "L")
        {
          switchoff[i] = "Y";
          DebugTN("SWITCHING OFF SOLAR FOR MCH LEFT");
          // SOLAR OFF
          dpSetWait(dp2 + ":Wiener/" + SolLV_CH[i][2] + "/Channel" + SolLV_CH[i][3] + ".Settings.OnOffChannel:_original.._value", FALSE);
        }
        if (SolLV_CH[i][1] == "R")
        {
          switchoff[i] = "Y";
          DebugTN("SWITCHING OFF SOLAR FOR MCH RIGHT");
          // SOLAR OFF
          dpSetWait(dp3 + ":Wiener/" + SolLV_CH[i][2] + "/Channel" + SolLV_CH[i][3] + ".Settings.OnOffChannel:_original.._value", FALSE);
        }
      }

      if (dynCount(switchoff, "Y") == len_SOLLV)
      {
        dpSet("mch_fee:OutputDataScreens.MCHSORLog", "SWITCHED OFF ALL SOLAR LV");
        dpSet("mch_fee:OutputDataScreens.MCHSORLog", "WAITING FOR CLOCK TRANSITION TO COMPLETE..WAIT FEW MOMENTS!!!");
      }
    }

    string UseCurrentRunType, UseCurrentTriggerMode, UseCurrentCSum;
    dpGet("mch_fee:mchUseCurrentConfig.UseCurrentRunType", UseCurrentRunType);
    dpGet("mch_fee:mchUseCurrentConfig.UseCurrentTriggerMode", UseCurrentTriggerMode);
    dpGet("mch_fee:mchUseCurrentConfig.UseCurrentCSum", UseCurrentCSum);

//Below further checks to distinguish the current procedure (i.e SOR or clock tranistion)
    if ((state == 2 && (UseCurrentRunType != runType || sorMode == "FULL")) || (clockchange == "TRUE" && ClockTransition == "5")) //ClockTransition =="5" disable clock transition procedure, "0" enable clock tranistion
   //if ((state == 2 && (UseCurrentRunType != runType || sorMode == "FULL")) || (clockchange == "TRUE" && ClockTransition == "0"))
    {

       if (runType != "")
      {

        dpSet("mch_fee:mchUseCurrentConfig.UseCurrentRunType:_original.._value", runType);
        dpSet("mch_fee:mchUseCurrentConfig.UseCurrentTriggerMode:_original.._value", triggerMode);
        dpSet("mch_fee:mchUseCurrentConfig.UseCurrentCSum:_original.._value", clusterSum);

      dpGet("mch_fee:mchUseCurrentConfig.UseCurrentRunType", UseCurrentRunType);
      dpGet("mch_fee:mchUseCurrentConfig.UseCurrentTriggerMode", UseCurrentTriggerMode);
      dpGet("mch_fee:mchUseCurrentConfig.UseCurrentCSum", UseCurrentCSum);
}
   //Below access temporary tble that gets populated with data from FSM to know which parts of the MCH to exclude
      fwDbStartCommand(dbCon, "DELETE FROM INCL_DETECTORS", DROPtempTable_cmd);
      if (fwDbCheckError(errMsg, DROPtempTable_cmd))
      {
        DebugTN("ERROR: fwDbStartCommandDELETE ", errMsg);
        return;
      }
      fwDbExecuteCommand(DROPtempTable_cmd);
      if (fwDbCheckError(errMsg, DROPtempTable_cmd))
      {
        DebugTN("ERROR: fwDbExecuteCommand ", errMsg);
        return;
      }
      fwDbStartCommand(dbCon, "INSERT INTO INCL_DETECTORS(DS_CHAMBERS,DS_CHILDREN,DS_SOLARFSM, SOLAR_FLAG,GBT_FLAG,SAMPA_FLAG) VALUES(:pass_inclparams1,:pass_inclparams2,:pass_inclparams3,0,0,0)", tempTable_cmd);
      if (fwDbCheckError(errMsg, tempTable_cmd))
      {
        DebugTN("ERROR: fwDbStartCommand ", errMsg);
        return;
      }
      dyn_dyn_mixed pass_inclparams;
      for (int i = 1; i <= len_links; i++)
      {
        pass_inclparams[i][1] = sol_links[i][11];
        pass_inclparams[i][2] = sol_links[i][12];
        pass_inclparams[i][3] = sol_links[i][17];
      }
      fwDbBindAndExecute(tempTable_cmd, pass_inclparams);
      if (fwDbCheckError(errMsg, tempTable_cmd))
      {
        DebugTN("ERROR: fwDbBindAndExecute ", errMsg);
        return;
      }

      if ((clockchange == "TRUE" && ClockTransition == "0"))
      {

        dpSet("mch_fee:OutputDataScreens.MCHSORLog", "");
        dpSet("mch_fee:OutputDataScreens.MCHSORLog", "CLOCK TRANSITION COMPLETED");
        dpSet("mch_fee:OutputDataScreens.MCHSORLog", "SWITCHING ON ALL SOLAR LV...");
        // delay(5);
        for (int i = 1; i <= len_SOLLV; i++)
        {
          if (SolLV_CH[i][1] == "L")
          {
            switchon[i] = "Y";
            DebugTN("SWITCHING ON SOLAR FOR MCH LEFT");
            // SOLAR ON
            dpSetWait(dp2 + ":Wiener/" + SolLV_CH[i][2] + "/Channel" + SolLV_CH[i][3] + ".Settings.OnOffChannel:_original.._value", TRUE);
          }
          if (SolLV_CH[i][1] == "R")
          {
            switchon[i] = "Y";
            DebugTN("SWITCHING ON SOLAR FOR MCH LEFT");
            // SOLAR ON
            dpSetWait(dp3 + ":Wiener/" + SolLV_CH[i][2] + "/Channel" + SolLV_CH[i][3] + ".Settings.OnOffChannel:_original.._value", TRUE);
          }
        }
        if (dynCount(switchon, "Y") == len_SOLLV)
        {
          dpSet("mch_fee:OutputDataScreens.MCHSORLog", "SWITCHED ON ALL SOLAR LV");
          dpSet("mch_hvLvLeft:LHCClock.ClockChange:_original.._value", "FALSE");
          dpSet("mch_fee:OutputDataScreens.MCHSORLog", "");
          // dpSet("mch_fee:OutputDataScreens.MCHSORLog","CHECKING TO MAKE SURE ALL LINKS ARE UP...HOLD ON!!!");
        }
        delay(15);
      }

      // dpSet("mch_fee:OutputDataScreens.MCHSORLog","");
      t1 = getCurrentTime();
      // PowerCycling();

      dpSet("mch_fee:OutputDataScreens.MCHSORLog", "---------------------------------------");
      dpSet("mch_fee:OutputDataScreens.MCHSORLog", "START OF FEE CONFIGURATION");
      dpSet("mch_fee:OutputDataScreens.MCHSORLog", "---------------------------------------");
      dpSet("mch_fee:OutputDataScreens.MCHSORLog", "");
      dpSet("mch_fee:OutputDataScreens.MCHSORLog", "CHECKING STATUS OF SOLAR LINKS...");
      DebugTN("BEGIN CHECKING OF SOLAR LINK STATUS...");
      DebugTN("----------------------------");

      ////-----------Start of CRU_Link checks and init of FEE-----------/////
      int len_sollvps = dynlen(SOL_LVPS);
      int len_feclvps = dynlen(FEC_LVPS);
      // DebugTN("Number of FEC_LVPS ", len_feclvps);
      DebugTN("Number of len_links ", len_links);

      // int CRULinkfault;

      ///---- power cycle Solar LVPS when links are down ----////
      int num = 1;
      int p;
      string gbtRegwrite, gbtRegwrite2;
      dyn_string gbtwriteRET_ANS, gbtwriteRET_ERR;
      // DebugTN("Number of flp_id ", flp_id);

      do

      { // DebugTN("BEGIN CHECKING OF SOLAR LINK STATUS2...");

        t1 = getCurrentTime();
        gbtRegwrite = "0xAA";
        gbtRegwrite2 = "0x0";
        //  int p = 0;
        // dyn_time tr1,tr2;
        dyn_string splitcrus, spliteachcru, lstatus;
        dyn_dyn_string linkstatus, linkstat;
        int len_splitcru;
        string lstat, s, linkstatus_af, linkstatus_d8, linkstatus_3b;
        dyn_string ch_id_pc, ch_id_pcfin, sol_crates_pc, sollvps_pc, solchan_pc, solchmside_pc, solchmside_pcfin, splitlinksaf, splitlinks3b, splitlinksd8, sol_lvps_pc, sol_chan_pc, solcrates_pc, solboard_pc, solcrates_pcfin, solboard_pcfin, sol_chan_pcfin, sol_lvps_pcfin, sol_lvps_chide, sol_lvps_chsidefin, sol_crates_pcfin;
        // DebugTN("sol_lvps...  ",sol_lvps);
        delay(10);
        int r = 1;
        // int r=1;
        for (int b = 1; b <= len_links; b++)
        { // DebugTN("BEGIN CHECKING OF SOLAR LINK STATUS6...");

          dpSet(dp + sol_crates[b] + ".GBTREGTestSend.Solar" + sol_boards[b], gbtRegwrite);
          //  dpGet(dp+sol_crates[b]+".GBTClockRet.Solar"+sol_boards[b]+":_original.._value",gbtwriteRET[b]);
        }

        time tr1, tr2;
        for (int b = 1; b <= len_links; b++)
        { // DebugTN("BEGIN CHECKING OF SOLAR LINK STATUS3...",sol_crates[b]);
          bool br = true;
          // gets the answers back from gBT register writes to know which SOLAR boards fail
          while (br)
          { t2 =  getCurrentTime();
            int timestuck = minute(t2 -t1);
            // DebugTN("BEGIN CHECKING OF SOLAR LINK STATUS4...",sol_crates[b],sol_boards[b]);
            dpGet(dp + sol_crates[b] + ".GBTREGTest_ANS.Solar" + sol_boards[b] + ":_original.._stime", tr2);
            dpGet(dp + sol_crates[b] + ".GBTREGTest_ERR.Solar" + sol_boards[b] + ":_original.._stime", tr1);
            // dpGet(dp+sol_crates[b]+".GBTREGTest_ANS.Solar"+sol_boards[b]+":_original.._value",gbtwriteRET_ANS[b]);
            //  dpGet(dp+sol_crates[b]+".GBTREGTest_ERR.Solar"+sol_boards[b]+":_original.._value",gbtwriteRET_ERR[b]);
            if (tr1 >= t1)
            {
              br = false;
              // DebugTN("BEGIN CHECKING OF SOLAR LINK STATUS5...");
              sollvps_pc[r] = sol_lvps[b];
              solchan_pc[r] = sol_chan[b];
              solchmside_pc[r] = cham_side[b];
              sol_crates_pc[r] = sol_crates[b];
              ch_id_pc[r] = CHAMID[b];
              p++;
              r++;
            }
            else if (tr2 >= t1)
            {
              br = false;
              // DebugTN("BEGIN CHECKING OF SOLAR LINK STATUS.4..");
            }

           //Below code in the if statement is an added feature to solve rare occassions of timeout errors and recover the MCH system
           if (timestuck > 6)
          {
             dpSet("mch_fee:OutputDataScreens.MCHSORLog", "");
             dpSet("mch_fee:OutputDataScreens.MCHSORLog", "FRED Segmentation fault... exiting SOR script");

                   dpSet("mch_fee:OutputDataScreens.MCHSORLog", "");
                          dpSet("mch_fee:OutputDataScreens.MCHSORLog", "------------------------------------------");
                          dpSet("mch_fee:OutputDataScreens.MCHSORLog", "------------------------------------------");
                          dpSet("mch_fee:OutputDataScreens.MCHSORLog", "RECOVER STUCK SOR PROCEDURE");
                          dpSet("mch_fee:OutputDataScreens.MCHSORLog", "------------------------------------------");
                          dpSet("mch_fee:OutputDataScreens.MCHSORLog", "------------------------------------------");
                          dpSet("mch_fee:OutputDataScreens.MCHSORLog", "");
                          dpSet("mch_hvLvLeft:aliDcsRun_1.state", 1);
                          dpSet("mch_fee:OutputDataScreens.MCHSORLog", "RESET OF MCH DCS RUN STATE DONE!!!");
                          dpSet("mch_fee:OutputDataScreens.MCHSORLog", "");
                          dpSet("mch_fee:OutputDataScreens.MCHSORLog", "RESTARTING FREDSERVERS...");
                          dpSet("mch_fee:OutputDataScreens.MCHSORLog", "");
                          string stdoutput1,stderror1;
                          system("ssh -o StrictHostKeyChecking=no -i D:/FREDsshkeys/fred003/id_ed25519 mch@alimchfred001.cern.ch /home/mch/restart_FREDServers.sh",stdoutput1,stderror1);
                          delay(2);
                          system("ssh -o StrictHostKeyChecking=no -i D:/FREDsshkeys/fred003/id_ed25519 mch@alimchfred001.cern.ch /home/mch/restart_FREDServers.sh",stdoutput1,stderror1);
                          dpSet("mch_fee:OutputDataScreens.MCHSORLog", "  FRED001 RESTARTED!!!");
                          DebugN("stdoutput1",stdoutput1);
                          dpSet("mch_fee:OutputDataScreens.MCHSORLog",stdoutput1);
                          DebugN("stderror1",stderror1);


                          string stdoutput2,stderror2;
                          system("ssh -o StrictHostKeyChecking=no -i D:/FREDsshkeys/fred003/id_ed25519 mch@alimchfred002.cern.ch /home/mch/restart_FREDServers.sh",stdoutput2,stderror2);
                          delay(2);
                          system("ssh -o StrictHostKeyChecking=no -i D:/FREDsshkeys/fred003/id_ed25519 mch@alimchfred002.cern.ch /home/mch/restart_FREDServers.sh",stdoutput2,stderror2);
                          DebugN("stdoutput2",stdoutput2);
                          dpSet("mch_fee:OutputDataScreens.MCHSORLog", "  FRED002 RESTARTED!!!");
                          dpSet("mch_fee:OutputDataScreens.MCHSORLog",stdoutput2);
                          DebugN("stderror2",stderror2);
                          //DebugN("ans",ans);


                          string stdoutput3,stderror3;
                          system("ssh -o StrictHostKeyChecking=no -i D:/FREDsshkeys/fred003/id_ed25519 mch@alimchfred003.cern.ch /home/mch/restart_FREDServers.sh",stdoutput3,stderror3);
                          delay(2);
                          system("ssh -o StrictHostKeyChecking=no -i D:/FREDsshkeys/fred003/id_ed25519 mch@alimchfred003.cern.ch /home/mch/restart_FREDServers.sh",stdoutput3,stderror3);
                          DebugN("stdoutput3",stdoutput3);
                          dpSet("mch_fee:OutputDataScreens.MCHSORLog", "  FRED003 RESTARTED!!!");
                          dpSet("mch_fee:OutputDataScreens.MCHSORLog",stdoutput3);
                          DebugN("stderror3",stderror3);

                          dpSet("mch_fee:OutputDataScreens.MCHSORLog", "RESTART OF FREDSERVERS DONE!!!");
                          dpSet("mch_fee:OutputDataScreens.MCHSORLog", "");

                          dpSet("mch_fee:OutputDataScreens.MCHSORLog", "");


                          delay(2);
                          dpSet("mch_fee:OutputDataScreens.MCHSORLog", "RESTARTING WINCC-OA MANAGERS...");

                          string serverName = "alidcssrv047";
                          /*string searchCriteria1 = "WCCOAdim;2;30;2;2;-num 16 -dim_dns_node alimchfred001.cern.ch -dim_dp_config DimFRED1";
                          string searchCriteria2 = "WCCOAdim;2;30;2;2;-num 17 -dim_dns_node alimchfred002.cern.ch -dim_dp_config DimFRED2";
                          string searchCriteria3 = "WCCOAdim;2;30;2;2;-num 18 -dim_dns_node alimchfred003.cern.ch -dim_dp_config DimFRED3";
                          string searchCriteria4 = "WCCOActrl;0;30;2;2;-num 7 mchConfigSampa/CheckClockChange.ctl";*/


                          int handle;
                          string str, line;
                          dyn_string params, list;
                          dyn_errClass err;
                          dyn_int manNumber=makeDynInt(26,31,32,33);
                          /* Initialise TCP connection with PMON manager */
                          handle = tcpOpen(serverName, 4999);
                          err = getLastError();
                          if ( dynlen(err) >= 1 ){
                          if ( handle != -1 )
                          tcpClose(handle);
                          throwError(err);
                          if(myManType()==UI_MAN){errorDialog(err);}
                          DebugTN("Can't reach the remote host");

                          }

                          /* Find manager */

                          line = my_pmon_write(handle, "", "", "MGRLIST:LIST");
                          list = stringToDynString(line, "\n");
                          DebugTN("line",line);
                          DebugTN("list",list);
                          int lenmanNumber =dynlen(manNumber);

                          DebugTN("manNumber",manNumber);

                          // Option (long one) //
                          for (int i=1;i<=lenmanNumber;i++)
                          {
                          if(false){
                          if(sscanf(strsplit(list[1],":")[2], "%d", manNumber[i])<0){
                          DebugTN("Bad string request");

                          return;
                          }

                          }
                          if(manNumber[i] < 1){
                          DebugTN("Manager not found");
                          return;
                          }
                          DebugTN("manNumber2",manNumber[i]);

                          // DebugTN(list, manNumber, my_pmon_write(handle, "", "", "SINGLE_MGR:PROP_GET "+manNumber));

                          // Read parameters for defined manager and change startup property to proper one //

                          if(true){

                          line = my_pmon_write(handle, "", "", "SINGLE_MGR:PROP_GET "+manNumber[i]);
                          params = strsplit(line, " ");
                          params[1] = "always"; // change "autostart" property to manual/always
                          line = my_pmon_write(handle, "", "", "SINGLE_MGR:PROP_PUT "+manNumber[i]+" "+dynStringToString(params, " ")); // Write property back
                          // if manager should be stopped:
                          if(true){
                          line = my_pmon_write(handle, "", "", "SINGLE_MGR:STOP "+manNumber[i]); // Now we can stop manager

                          if(!strpos(line, "OK")){
                          DebugTN("FSM Manager stopped and resterted");
                          }
                          } // No need to start manager, because it will start automatically when property will be changed to always
                          else{
                          DebugTN("");
                          }
                          }
                          }
                          // End part. Closing connections. //
                          tcpClose(handle);

                          delay(2);
                                dpSet("mch_fee:OutputDataScreens.MCHSORLog", "RESTART OF WINCC-OA MANAGERS DONE!!!");
                                delay(2);
                                dpSet("mch_fee:OutputDataScreens.MCHSORLog", "");

                                dpSet("mch_fee:mchUseCurrentConfig.UseCurrentRunType:_original.._value", "");
                                  dpSet("mch_fee:mchUseCurrentConfig.UseCurrentTriggerMode:_original.._value", "");
                                  dpSet("mch_fee:mchUseCurrentConfig.UseCurrentCSum:_original.._value", "");
                          dpSet("mch_fee:OutputDataScreens.MCHSORLog", "RESET OF LAST RUNTYPE VALUES DONE!!!");
                                dpSet("mch_fee:OutputDataScreens.MCHSORLog", "");
                                dpSet("mch_fee:OutputDataScreens.MCHSORLog", "------------------------------------------");
                                dpSet("mch_fee:OutputDataScreens.MCHSORLog", "------------------------------------------");
                                dpSet("mch_fee:OutputDataScreens.MCHSORLog", "END OF RECOVER STUCK SOR PROCEDURE");
                                dpSet("mch_fee:OutputDataScreens.MCHSORLog", "------------------------------------------");
                                dpSet("mch_fee:OutputDataScreens.MCHSORLog", "------------------------------------------");
                                return;

          }
          }
        }

        // DebugTN("gbtwriteRET...  ",gbtwriteRET);

        DebugTN("----------------------------");
        DebugTN("----------------------------");
        // dpSet("mch_fee:OutputDataScreens.MCHSORLog", "");
        // delay(0);

        //  dpSet("mch_fee:OutputDataScreens.MCHSORLog","CHECKING IF ANY LINKS ARE DOWN:");
        DebugTN("CHECK IF CRU LINKS ARE DOWN...  ");

        // DebugTN("tr1",tr1);
        //  DebugTN("sollvps_pc",sollvps_pc);
        DebugTN("solchan_pc", solchan_pc);
        DebugTN("sol_crates_pc", sol_crates_pc);

        if (dynlen(sollvps_pc) == 0)
        { // DebugTN("No links down");
          // DebugTN("BEGIN CHECKING OF SOLAR LINK STATUS...");
          p = 0;
        }

        //gets the information from the aLF-FRED chain for the boards that failed and power-cycles them
        if (p != 0)
        { // dpSet("mch_fee:OutputDataScreens.MCHSORLog","");
          //  delay(0);
          dpSet("mch_fee:OutputDataScreens.MCHSORLog", "");
          dpSet("mch_fee:OutputDataScreens.MCHSORLog", "Some links are down:");
          // delay(0);
          DebugTN("Some links are down");
          DebugTN("----------------------------");
          // delay(0);
          dpSet("mch_fee:OutputDataScreens.MCHSORLog", "Establishing SOLAR LVPS to be powercycled...");
          DebugTN("Establishing SOLAR LVPS to be powercycled...");
          int len_sol_lvps_pc = dynlen(sollvps_pc), n = 1;
          DebugTN("len_sol_lvps_pc", len_sol_lvps_pc);
          string remdupl, remdupl2;
          for (int k = 1; k <= len_sol_lvps_pc; k++)
          {
            remdupl = sol_crates_pc[k];
            remdupl2 = sollvps_pc[k];
            if (k < len_sol_lvps_pc)

            {
              if (remdupl != sol_crates_pc[k + 1])
              {
                sol_chan_pcfin[n] = solchan_pc[k];
                sol_lvps_pcfin[n] = sollvps_pc[k];
                // solcrates_pcfin[n]=solcrates_pc[k];
                //    solboard_pcfin[n]=solboard_pc[k];
                solchmside_pcfin[n] = solchmside_pc[k];
                sol_crates_pcfin[n] = sol_crates_pc[k];
                ch_id_pcfin[n] = ch_id_pc[k];
                // delay(0);
                dpSet("mch_fee:OutputDataScreens.MCHSORLog", "CH" + ch_id_pcfin[n] + solchmside_pcfin[n] + " LVPS " + sol_lvps_pcfin[n] + " channel " + sol_chan_pcfin[n] + " crate " + sol_crates_pcfin[n]);
                DebugTN("CH" + solchmside_pcfin[n] + " LVPS " + sol_lvps_pcfin[n] + " channel " + sol_chan_pcfin[n] + " crate " + sol_crates_pcfin[n]);
                n++;
              }
            }
            else if (k == len_sol_lvps_pc)
            {
              sol_chan_pcfin[n] = solchan_pc[k];
              sol_lvps_pcfin[n] = sollvps_pc[k];
              //   solcrates_pcfin[n]=solcrates_pc[k];
              //     solboard_pcfin[n]=solboard_pc[k];
              solchmside_pcfin[n] = solchmside_pc[k];
              sol_crates_pcfin[n] = sol_crates_pc[k];
              ch_id_pcfin[n] = ch_id_pc[k];
              //  delay(0);
              dpSet("mch_fee:OutputDataScreens.MCHSORLog", "CH" + ch_id_pcfin[n] + solchmside_pcfin[n] + " LVPS " + sol_lvps_pcfin[n] + " channel " + sol_chan_pcfin[n] + " crate " + sol_crates_pcfin[n]);
              DebugTN("CH" + solchmside_pcfin[n] + " LVPS " + sol_lvps_pcfin[n] + " channel " + sol_chan_pcfin[n] + " crate " + sol_crates_pcfin[n]);
            }
          }

          int len_sol_lvps_pcfin = dynlen(sol_chan_pcfin);

          // DebugTN("sol_lvps_pcfin",sol_lvps_pcfin);
          // DebugTN("sol_chan_pcfin",sol_chan_pcfin);
          DebugTN("----------------------------");
          // delay(0);
          dpSet("mch_fee:OutputDataScreens.MCHSORLog", "");
          // delay(0);
          dpSet("mch_fee:OutputDataScreens.MCHSORLog", "Power-cycling SOLAR LVs...");
          DebugTN("Begin Powercyle of LVPS...");
          // delay(0);
          dpSet("mch_fee:OutputDataScreens.MCHSORLog", "Powercycle try: " + num);
          DebugTN("Powercycle try: ", num);
          for (int k = 1; k <= len_sol_lvps_pcfin; k++)
          {
            if (solchmside_pcfin[k] == "L")
            {
              dpSet(dp2 + ":Wiener/" + sol_lvps_pcfin[k] + "/Channel" + sol_chan_pcfin[k] + ".Settings.OnOffChannel", FALSE);

              // dpSet("mch_fee:OutputDataScreens.MCHSORLog","Powercycling LVPS "+sol_lvps_pcfin[k]+" channel "+sol_chan_pcfin[k]+" crate "+sol_crates_pcfin[k]+" :DONE");
              // DebugTN("Powercycling LVPS "+sol_lvps_pcfin[k]+" channel "+sol_chan_pcfin[k]+" crate "+sol_crates_pcfin[k]+" :DONE");
            }
            if (solchmside_pcfin[k] == "R")
            {
              dpSet(dp3 + ":Wiener/" + sol_lvps_pcfin[k] + "/Channel" + sol_chan_pcfin[k] + ".Settings.OnOffChannel", FALSE);
              // dpSet("mch_fee:OutputDataScreens.MCHSORLog","Powercycling LVPS "+sol_lvps_pcfin[k]+" channel "+sol_chan_pcfin[k]+" crate "+sol_crates_pcfin[k]+" :DONE");
              // DebugTN("Powercycling LVPS "+sol_lvps_pcfin[k]+" channel "+sol_chan_pcfin[k]+" crate "+sol_crates_pcfin[k]+" :DONE");
            }
          }
          delay(7);
          for (int k = 1; k <= len_sol_lvps_pcfin; k++)
          {
            if (solchmside_pcfin[k] == "L")
            {
              // dpSet(dp2+":Wiener/"+sol_lvps_pcfin[k]+"/Channel"+sol_chan_pcfin[k]+".Settings.OnOffChannel",	FALSE);
              //    //DebugTN("SOLAR SWITCHED OFF");

              dpSet(dp2 + ":Wiener/" + sol_lvps_pcfin[k] + "/Channel" + sol_chan_pcfin[k] + ".Settings.OnOffChannel", TRUE);
              // DebugTN("SOLAR SWITCHED ON");
              dpSet("mch_fee:OutputDataScreens.MCHSORLog", "Powercycling LVPS " + sol_lvps_pcfin[k] + " channel " + sol_chan_pcfin[k] + " crate " + sol_crates_pcfin[k] + " :DONE");
              DebugTN("Powercycling LVPS " + sol_lvps_pcfin[k] + " channel " + sol_chan_pcfin[k] + " crate " + sol_crates_pcfin[k] + " :DONE");
            }
            if (solchmside_pcfin[k] == "R")
            {
              // dpSet(dp3+":Wiener/"+sol_lvps_pcfin[k]+"/Channel"+sol_chan_pcfin[k]+".Settings.OnOffChannel",	FALSE);
              // DebugTN("SOLAR SWITCHED OFF");
              //  delay(8);
              dpSet(dp3 + ":Wiener/" + sol_lvps_pcfin[k] + "/Channel" + sol_chan_pcfin[k] + ".Settings.OnOffChannel", TRUE);
              // Debu
              dpSet("mch_fee:OutputDataScreens.MCHSORLog", "Powercycling LVPS " + sol_lvps_pcfin[k] + " channel " + sol_chan_pcfin[k] + " crate " + sol_crates_pcfin[k] + " :DONE");
              DebugTN("Powercycling LVPS " + sol_lvps_pcfin[k] + " channel " + sol_chan_pcfin[k] + " crate " + sol_crates_pcfin[k] + " :DONE");
            }
          }
          DebugTN("Powercyling of LVPS DONE!!!");
          dpSet("mch_fee:OutputDataScreens.MCHSORLog", "Powercyling of LVPS done!!!");
          dpSet("mch_fee:OutputDataScreens.MCHSORLog", "");
          delay(10);

          DebugTN("----------------------------");
        }

        if (num != 1 && p == 0)
        {
          dpSet("mch_fee:OutputDataScreens.MCHSORLog", "POWER-CYCLING DONE WITH ALL LINKS UP!!!");
          DebugTN("POWER-CYCLING DONE WITH ALL LINKS ARE UP!!!");
          for (int b = 1; b <= len_links; b++)
          {

            dpSet(dp + sol_crates[b] + ".GBTREGTestSend.Solar" + sol_boards[b], gbtRegwrite2);

            //  dpGet(dp+sol_crates[b]+".GBTREGTestSend.Solar"+sol_boards[b]+":_original.._value","");
          }
        }
        if (num == 1 && p == 0)
        {
          dpSet("mch_fee:OutputDataScreens.MCHSORLog", "ALL LINKS WERE ALREADY UP!!!");
          DebugTN("ALL LINKS WERE ALREADY UP!!!");
          for (int b = 1; b <= len_links; b++)
          {

            dpSet(dp + sol_crates[b] + ".GBTREGTestSend.Solar" + sol_boards[b], gbtRegwrite2);

            //  dpGet(dp+sol_crates[b]+".GBTREGTestSend.Solar"+sol_boards[b]+":_original.._value","");
          }
        }

        if (num == 4 && p != 0)
        {
          dpSet("mch_fee:OutputDataScreens.MCHSORLog", "POWER-CYCLING ATTEMPTS DONE - SOME LINKS ARE STILL DOWN!!!");
          for (int b = 1; b <= len_links; b++)
          {

            dpSet(dp + sol_crates[b] + ".GBTREGTestSend.Solar" + sol_boards[b], gbtRegwrite2);

            //  dpGet(dp+sol_crates[b]+".GBTREGTestSend.Solar"+sol_boards[b]+":_original.._value","");
          }
        }

        num++;
        DebugTN("num", num);
      } while (num < 5 && p != 0);

      fwDbStartCommand(dbCon, "SELECT DS_CHAMBERS,DS_CHILDREN,DS_SOLARFSM, SOLAR_FLAG,GBT_FLAG,SAMPA_FLAG FROM INCL_DETECTORS", incldet_cmd);

      if (fwDbCheckError(errMsg, incldet_cmd))
      {
        DebugTN("ERROR: fwDbStartCommand ", errMsg);
        return;
      }
      fwDbExecuteCommand(incldet_cmd);
      if (fwDbCheckError(errMsg, incldet_cmd))
      {
        DebugTN("ERROR: fwDbExecuteCommand ", errMsg);
        return;
      }

      fwDbGetData(incldet_cmd, INCL_DET);
      if (fwDbCheckError(errMsg, incldet_cmd))
      {
        DebugTN("ERROR: fwDbGetData ", errMsg);
        return;
      }
      // DebugTN("INCL_DET",INCL_DET);

      // ConfigureSCARegisters();
      dpSet("mch_fee:OutputDataScreens.MCHSORLog", "");
      dpSet("mch_fee:OutputDataScreens.MCHSORLog", "CONFIGURING SCA REGISTERS...");
      DebugTN("BEGIN CONIGURATION OF SOLAR...");
      DebugTN("----------------------------");

      ////-----------Start of CRU_Link checks and init of FEE-----------/////

      int len_sollvps = dynlen(SOL_LVPS);
      int len_feclvps = dynlen(FEC_LVPS);
      // DebugTN("Number of FEC_LVPS ", len_feclvps);
      // DebugTN("Number of SOL_LVPS ", len_sollvps);

      ////Start to send initialization commands to FEE/////////
      int n = 1;

      DebugTN("----------------------------");

      // DebugTN("Configuring SOLAR...");
      DebugTN("----------------------------");
      int num = 1;

      do
      {
        t1 = getCurrentTime();
        delay(4);
        for (int k = 1; k <= len_links; k++)
        { // DebugTN("num",num );

          if (INCL_DET[k][4] == 0)
          { // DebugTN("event config");
            dpSetWait(dp + sol_crates[k] + ".SolarInitCommands.Solar" + sol_boards[k], "");
            //		delay(0);
          }
        }
        delay(5);
        int s = 1;
        for (int k = 1; k <= len_links; k++)
        {
          if (INCL_DET[k][4] == 0)
          { // DebugTN("event return 1");
            dpGet(dp + sol_crates[k] + ".SolarInitStatus_ERR.Solar" + sol_boards[k] + ":_original.._stime", InittimeERR[n]);
            dpGet(dp + sol_crates[k] + ".SolarInitStatus_ANS.Solar" + sol_boards[k] + ":_original.._stime", InittimeANS[n]);
            dpGet(dp + sol_crates[k] + ".SolarInitStatus_ERR.Solar" + sol_boards[k] + ":_original.._value", InitReturnERR[n]);
            dpGet(dp + sol_crates[k] + ".SolarInitStatus_ANS.Solar" + sol_boards[k] + ":_original.._value", InitReturnANS[n]);
            // DebugTN("SCA ERROR FROM CRU "+cru_addr[k]+" LINK ",cru_links[k]+" : "+InitReturn[n]);
            string IntegrityCheckIgnore;

            IntegrityCheckIgnore = substr(InitReturnERR[n], 0, 22);

            if (InittimeERR[n] >= t1 && IntegrityCheckIgnore != "FAILED: SCA: Integrity")
            { // DebugTN("event return 2");
              //	dpSet("mch_fee:OutputDataScreens.MCHSORLog","SCA CONFIGURATION FOR CH"+CHAMID[k]+cham_side[k]+" CRU "+cru_id[k]+" LINK "+cru_links[k]+" - FAILED: "+InitReturnERR[n]);
              failedSOLAR[s] = "CH" + CHAMID[k] + cham_side[k] + " CRU " + cru_id[k] + " LINK " + (string)cru_links[k] + " - FAILED: " + InitReturnERR[n];
              //	DebugTN("SCA CONFIGURATION FOR CH"+CHAMID[k]+cham_side[k]+" CRU "+cru_id[k]+" LINK "+cru_links[k]+" - FAILED: "+InitReturnERR[n]);
              Solarfail[n] = "0";
              s++;
            }
            else if (InitReturnERR[n] == "0")
            { // DebugTN("event return 3");
              //	dpSet("mch_fee:OutputDataScreens.MCHSORLog","SCA CONFIGURATION FAILED - ALF-FRED NOT RESPONDING");
              //		DebugTN("SCA CONFIGURATION FAILED - ALF-FRED NOT RESPONDING");
              Solarfail[n] = "0";
            }
            else if (InittimeANS[n] >= t1)
            { // DebugTN("event return 4");
              //		dpSet("mch_fee:OutputDataScreens.MCHSORLog","SCA CONFIGURATION FOR CH"+CHAMID[k]+cham_side[k]+" CRU "+cru_id[k]+" LINK ",cru_links[k]+" - SUCCESS");
              //		DebugTN("SCA CONFIGURATION FOR CH"+CHAMID[k]+cham_side[k]+" CRU "+cru_id[k]+" LINK ",cru_links[k]+" - SUCCESS");
              INCL_DET[k][4] = 1;
              Solarfail[n] = "1";
            }
          }
          else if (INCL_DET[k][4] == 1)
          { // DebugTN("event no config");
            Solfail[k] = "1";
            Solarfail[n] = "1";
          }

          n++;
        }
        num++;
      } while (dynCount(Solarfail, "1") != len_links && num < 4);

      DebugTN("----------------------------");
      // DebugTN("failedSOLAR ",failedSOLAR);
      // DebugTN("INCL_DET ",INCL_DET);

      int n = 1;
      t2 = getCurrentTime();

      // sets button color to green if success or red if failure to init
      if (dynCount(Solfail, "1") == len_links)
      {
        // dpSet("mch_fee:OutputDataScreens.MCHSORLog","");
        dpSet("mch_fee:OutputDataScreens.MCHSORLog", "CONFIGURATION OF SOLAR SCA REGISTERS COMPLETED WITH NO ERRORS!!!");
        DebugTN("CONFIGURATION OF SOLAR SCA REGISTERS COMPLETED WITH NO ERRORS!!!");
      }
      else if (dynCount(Solarfail, "1") != len_links)

      {
        // dpSet("mch_fee:OutputDataScreens.MCHSORLog","");
        dpSet("mch_fee:OutputDataScreens.MCHSORLog", "CONFIGURATION OF SOLAR SCA REGISTERS COMPLETED WITH THE BELOW ERRORS: ");
        DebugTN("CONFIGURATION OF SOLAR SCA REGISTERS COMPLETED WITH THE BELOW ERRORS: ");
        for (int k = 1; k <= dynlen(failedSOLAR); k++)
        {
          dpSet("mch_fee:OutputDataScreens.MCHSORLog", failedSOLAR[k]);
          DebugTN(failedSOLAR[k]);
        }
      }
      else
      {
        delay(3);
        // dpSet("mch_fee:OutputDataScreens.MCHSORLog","");
        dpSet("mch_fee:OutputDataScreens.MCHSORLog", "CONFIGURATION OF SOLAR SCA REGISTERS COMPLETED WITH NO ERRORS!!!");
        DebugTN("CONFIGURATION OF SOLAR SCA REGISTERS COMPLETED WITH NO ERRORS");
        // this.backCol = "STD_valve_open";
      }

      /*  fwDbStartCommand(dbCon, "DELETE FROM INCL_DETECTORS", DROPtempTable_cmd);
        if (fwDbCheckError(errMsg, DROPtempTable_cmd))
        {
          DebugTN("ERROR: fwDbStartCommandDELETE ", errMsg);
          return;
        }
        fwDbExecuteCommand(DROPtempTable_cmd);
        if (fwDbCheckError(errMsg, DROPtempTable_cmd))
        {
          DebugTN("ERROR: fwDbExecuteCommand ", errMsg);
          return;
        }
        fwDbStartCommand(dbCon, "INSERT INTO INCL_DETECTORS(DS_CHAMBERS,DS_CHILDREN,DS_SOLARFSM, SOLAR_FLAG,GBT_FLAG,SAMPA_FLAG) VALUES(:pass_inclparam1,:pass_inclparam2,:pass_inclparam3,:pass_inclparam4,0,0)", tempTable_cmd);
        if (fwDbCheckError(errMsg, tempTable_cmd))
        {
          DebugTN("ERROR: fwDbStartCommand ", errMsg);
          return;
        }
        int n = 1;
        dyn_dyn_mixed pass_inclparams;
        for (int i = 1; i <= len_links; i++)
        {
          pass_inclparams[i][1] = sol_links[i][11];
          pass_inclparams[i][2] = sol_links[i][12];
          pass_inclparams[i][3] = sol_links[i][17];
          pass_inclparams[i][4] = Solarfail[n];
          n++;
        }
        fwDbBindAndExecute(tempTable_cmd, pass_inclparams);
        if (fwDbCheckError(errMsg, tempTable_cmd))
        {
          DebugTN("ERROR: fwDbBindAndExecute ", errMsg);
          return;
        }*/
      DebugTN("----------------------------");
      DebugTN("Start time: ", (string)t1);
      DebugTN("End time: ", (string)t2);
      DebugTN("----------------------------");
      DebugTN("----------------------------");

      ///////---------------------GBT AND SAMPA-----------------/////
      dpSet("mch_fee:OutputDataScreens.MCHSORLog", "");
      string dp = "mch_fee:";

      dbCommand DS_cmd, SOL_cmd, cmd_ODD, cmd_EVEN, enable_cmd, GBTPhase_cmd, BadChan_cmd, DROPbadchanTable_cmd, CRUconfig_cmd, incldet_cmd;
      dbCommand FEC_lvps_cmd, SOL_cmd, SOL_lvps_cmd, MASK_cmd, tempTable_cmd, DROPtempTable_cmd, SOLLV_cmd, FECLV_cmd;
      dyn_dyn_mixed fec_cards, sol_links, ped_ODD, ped_EVEN, Badchannels, GBTPhase_dat, CRUconfig_data;

      dyn_string GBTClocktimeANS, GBTClocktimeERR, GBTClockReturnERR, GBTClockReturnANS;
      dyn_string GBTPhasetimeStartERR, GBTPhasetimeStartANS, GBTPhaseReturnStartERR, GBTPhaseReturnStartANS, GBTPhasetimeStopERR, GBTPhasetimeStopANS, GBTPhaseReturnStopERR, GBTPhaseReturnStopANS;
      dyn_string GBTPhaseStatictimeERR, GBTPhasetimeStaticANS, GBTPhaseReturnStaticERR, GBTPhaseReturnStaticANS;

      dyn_string gbtflag, gbtclockfail, gbtclockflag, gbtphasefail, gbtphaseflag;
      dyn_dyn_int excl_boards, boardList, chip, chipds;
      dyn_int fec_count = 0, ds_count = 0, board_count = 0, SAMPAfailcheck, Solconn, DSboard;
      dyn_string InitReturn;

      string connectString = "Driver=QOCI8;DATABASE=alionr;User=mchfero;Password=mch1234";
      string errMsg;
      dbConnection dbCon;
      dyn_dyn_mixed SOL_LVPS, FEC_LVPS, sol_links, CRU_ID, mask_links, DS_links, SolLV_CH, FECLV_CH, en_mask;
      int len_links, len_cruid, len_solcrate;
      int len_fectotal, len_links, len_links_CRUconfig_data, len_pedeven, len_pedodd;
      dyn_dyn_string sampa_BoardConfigList;

      time tr1, tr2;
      time t2, lastupd, tsamp, tsamp2;
      dyn_string enable_DSf;
      string enableDSchange;

      dyn_int fec_count = 0, ds_count = 0, board_count = 0;

      int cru_af = 0, cru_d8 = 0, cru_3b = 0;
      dyn_dyn_string SAMPABoardReturn, SAMPABoardReturnFinal, SAMPApass, SAMPAfail, SAMPAfailnoreply;
      dyn_string enable_DS;
      dyn_string hardrest_input;
      dyn_dyn_mixed INCL_DET;
      int len_pedfeven, len_pedfodd;
      int l = 1, j;
      dyn_int lenpedf_even, lenpedf_odd;
      dyn_string sampa_config_file_0, sampa_config_file_1, sampaconfigcommand, s, s1;
      int l1 = 1, n = 1, s = 1;
      dyn_dyn_string sampa_config_file_1f, sampa_config_file_0f;
      string SampaCommands;
      dyn_string gbtfail;
      dyn_string InitReturn;
      dyn_dyn_string d_AnyArray;
      string maskd;
      string mask, tmask;
      dyn_dyn_string gbtmask;
      dyn_string fmask, gbtfmask;
      dyn_string sol_id;
      int r = 1, t = 1, lenfeccount;

      dyn_string cru_IDS, xFEEID1, xFEEID2;
      dyn_int cru_links;
      dyn_int FEEID1, FEEID2;

      string enableDSchange;
      int lenDSen;
      dyn_string sol_crates, sol_boards, cru_addr, ch_id, ch_side, GBTPhaseAlgn_data, solID, st_id, slatID, CRUConfig_cruids, CRUConfig_flpids;
      dyn_string cru_config_trigger;
      string SampaReturnCheck;

      dyn_string sampa_config_final, SampaConfigReturn;
      dyn_mixed pass_detparams, pass_confparams;
      string sel_mch, sel_st, sel_ch, sel_chside, sel_DE, sel_config, configMode;

      dyn_mixed pass_confparams;

      if (runType == "PEDESTALS")
      {
        pass_confparams[1] = 1;
          dpSet("mch_fee:OutputDataScreens.MCHSORLog", "------------------------------------------------------");
        dpSet("mch_fee:OutputDataScreens.MCHSORLog", "------------------------------------------------------");
        dpSet("mch_fee:OutputDataScreens.MCHSORLog", "PEDESTAL CONFIGURATION");
      }
      else if (UseCurrentRunType == "PEDESTALS")
      {
        pass_confparams[1] = 1;
        dpSet("mch_fee:OutputDataScreens.MCHSORLog", "------------------------------------------------------");
        dpSet("mch_fee:OutputDataScreens.MCHSORLog", "------------------------------------------------------");
        dpSet("mch_fee:OutputDataScreens.MCHSORLog", "PEDESTAL CONFIGURATION");
      }
      if ((runType == "PHYSICS" || runType == "TECHNICAL" || runType == "COSMICS") && triggerMode == "CONTINUOUS" && clusterSum == FALSE)
      {
        pass_confparams[1] = 2;
        dpSet("mch_fee:OutputDataScreens.MCHSORLog", "------------------------------------------------------");
        dpSet("mch_fee:OutputDataScreens.MCHSORLog", "------------------------------------------------------");
        dpSet("mch_fee:OutputDataScreens.MCHSORLog", "PHYSICS CONFIGURATION CONTINUOUS MODE CSUM DISABLED");
      }
      else if (((UseCurrentRunType == "PHYSICS" || UseCurrentRunType == "TECHNICAL" || UseCurrentRunType == "COSMICS") && runType != "PEDESTALS") && UseCurrentTriggerMode == "CONTINUOUS" && UseCurrentCSum == FALSE)
      {
        pass_confparams[1] = 2;
        dpSet("mch_fee:OutputDataScreens.MCHSORLog", "------------------------------------------------------");
        dpSet("mch_fee:OutputDataScreens.MCHSORLog", "------------------------------------------------------");
        dpSet("mch_fee:OutputDataScreens.MCHSORLog", "PHYSICS CONFIGURATION CONTINUOUS MODE CSUM DISABLED");
      }
      if ((runType == "PHYSICS" || runType == "TECHNICAL" || runType == "COSMICS") && triggerMode == "CONTINUOUS" && clusterSum == TRUE)
      {
        pass_confparams[1] = 3;
        dpSet("mch_fee:OutputDataScreens.MCHSORLog", "------------------------------------------------------");
        dpSet("mch_fee:OutputDataScreens.MCHSORLog", "------------------------------------------------------");
        dpSet("mch_fee:OutputDataScreens.MCHSORLog", "PHYSICS CONFIGURATION CONTINUOUS MODE CSUM ENABLED");
      }
      else if (((UseCurrentRunType == "PHYSICS" || UseCurrentRunType == "TECHNICAL" || UseCurrentRunType == "COSMICS") && runType != "PEDESTALS") && UseCurrentTriggerMode == "CONTINUOUS" && UseCurrentCSum == TRUE)
      {
        pass_confparams[1] = 3;
        dpSet("mch_fee:OutputDataScreens.MCHSORLog", "------------------------------------------------------");
        dpSet("mch_fee:OutputDataScreens.MCHSORLog", "------------------------------------------------------");
        dpSet("mch_fee:OutputDataScreens.MCHSORLog", "PHYSICS CONFIGURATION CONTINUOUS MODE CSUM ENABLED");
      }
      if ((runType == "PHYSICS" || runType == "TECHNICAL" || runType == "COSMICS") && triggerMode == "TRIGGERED" && clusterSum == FALSE)
      {
        pass_confparams[1] = 4;
        dpSet("mch_fee:OutputDataScreens.MCHSORLog", "------------------------------------------------------");
        dpSet("mch_fee:OutputDataScreens.MCHSORLog", "------------------------------------------------------");
        dpSet("mch_fee:OutputDataScreens.MCHSORLog", "PHYSICS CONFIGURATION TRIGGERED MODE CSUM DISABLED");
      }
      else if (((UseCurrentRunType == "PHYSICS" || UseCurrentRunType == "TECHNICAL" || UseCurrentRunType == "COSMICS") && runType != "PEDESTALS") && UseCurrentTriggerMode == "TRIGGERED" && UseCurrentCSum == FALSE)
      {
        pass_confparams[1] = 4;
        dpSet("mch_fee:OutputDataScreens.MCHSORLog", "------------------------------------------------------");
        dpSet("mch_fee:OutputDataScreens.MCHSORLog", "------------------------------------------------------");
        dpSet("mch_fee:OutputDataScreens.MCHSORLog", "PHYSICS CONFIGURATION TRIGGERED MODE CSUM DISABLED");
      }
      if ((runType == "PHYSICS" || runType == "TECHNICAL" || runType == "COSMICS") && triggerMode == "TRIGGERED" && clusterSum == TRUE)
      {
        pass_confparams[1] = 5;
        dpSet("mch_fee:OutputDataScreens.MCHSORLog", "------------------------------------------------------");
        dpSet("mch_fee:OutputDataScreens.MCHSORLog", "------------------------------------------------------");
        dpSet("mch_fee:OutputDataScreens.MCHSORLog", "PHYSICS CONFIGURATION TRIGGERED MODE CSUM ENABLED");
      }
      else if (((UseCurrentRunType == "PHYSICS" || UseCurrentRunType == "TECHNICAL" || UseCurrentRunType == "COSMICS") && runType != "PEDESTALS") && UseCurrentTriggerMode == "TRIGGERED" && UseCurrentCSum == TRUE)
      {
        pass_confparams[1] = 5;
        dpSet("mch_fee:OutputDataScreens.MCHSORLog", "------------------------------------------------------");
        dpSet("mch_fee:OutputDataScreens.MCHSORLog", "------------------------------------------------------");
        dpSet("mch_fee:OutputDataScreens.MCHSORLog", "PHYSICS CONFIGURATION TRIGGERED MODE CSUM ENABLED");
      }

      /////  -----------------------------CONFIGURE FEC-------------------------------------------////
      dpSet("mch_fee:OutputDataScreens.MCHSORLog", "------------------------------------------------------");
      dpSet("mch_fee:OutputDataScreens.MCHSORLog", "------------------------------------------------------");
      if ((runType == "PHYSICS" || runType == "TECHNICAL" || runType == "COSMICS") || (UseCurrentRunType == "PHYSICS" || UseCurrentRunType == "TECHNICAL" || UseCurrentRunType == "COSMICS"))
      {

        dpSet("mch_fee:OutputDataScreens.MCHSORLog", "");
        time t1 = getCurrentTime();
        string localTime = formatTime("%Y%m%d_%H%M%S", t1);
        dpSet("dcs_devmon:CCDB_MCH_BadChannelCalib.Request:_original.._value", localTime);
        dpSet("mch_fee:OutputDataScreens.MCHSORLog", "CCDB OBJECT WITH BAD CHANNEL DATA PUSHED TO ORACLE DB");
      }

      /////-----------DB Access-----------/////
      fwDbOption("Reset", 0);
      string connectString = "Driver=QOCI8;DATABASE=alionr;User=mchfero;Password=mch1234";
      string errMsg;
      dbConnection dbCon;

      // Check if the CtrlRDBAccess is loaded
      if (!isFunctionDefined("fwDbOption"))
      {
        DebugTN("ERROR: CtrlRDBAccess library not loaded, please add it to your config file");
        return;
      }

      // Open the connection
      fwDbOpenConnection(connectString, dbCon);
      if (fwDbCheckError(errMsg, dbCon))
      {
        DebugTN("ERROR: fwDbOpenConnection ", errMsg);
        return;
      }

      // Extract coniguration dat from DB
      dbCommand DS_cmd, SOL_cmd, cmd_ODD, cmd_EVEN, enable_cmd, BadChan_cmd, DROPbadchanTable_cmd, GBTPhase_cmd, CRUconfig_cmd;

      //// Starting the command, this is where you put your SQL query
      // Read FEC Cards per SOLAR port from DB
      fwDbStartCommand(dbCon, "SELECT cm.SOLAR_ID, cm.CRU_LINK, cm.SOL_CRATE, cm.SOL_BOARD_ID,cm.cru_id,sm.DS_ID1,sm.DS_ID2,sm.DS_ID3,sm.DS_ID4,sm.DS_ID5  FROM CRU_Mapping cm inner join SOLAR_Mapping sm on cm.SOLAR_ID = sm.sol_id  WHERE cm.DS_SOLARFSM in (SELECT DS_CHAMBERS FROM INCL_DETECTORS_FSM) order by cm.C_id,sm.flex_id", DS_cmd);
      // Read Solar links and cru id from DB
      fwDbStartCommand(dbCon, "SELECT c_ID,cru_link,cru_id,SOL_CRATE,sol_board_id,solar_id,ch_id,ch_side,ds_chamber,ds_children,slat_id,DS_SOLARFSM FROM CRU_Mapping WHERE CRU_Mapping.DS_SOLARFSM in (SELECT DS_CHAMBERS FROM INCL_DETECTORS_FSM) MINUS SELECT ssm_id,ds_id1,SLAT_ID,SOL_ID,flex_id,sol_id,ch_id,ch_side,ds_chamber,ds_children,CH_SIDE,DS_SOLARFSM  FROM SOLAR_Mapping WHERE SOLAR_Mapping.DS_SOLARFSM in (SELECT DS_CHAMBERS FROM INCL_DETECTORS_FSM) order by 1", SOL_cmd);
      // read bad channel data from DB
      fwDbStartCommand(dbCon, "SELECT SOLARID,DSID,CH FROM FEROCC.CCDB_MCH_BAD_CHANNELS order by 1", BadChan_cmd);
      // Read gbt phase aligner data FROM DB
      fwDbStartCommand(dbCon, "SELECT GBTPE_ID,link_ID,GBTPhaseMask,SOL_CRATE,ch_id,ch_side,slat_id FROM GBTPhase_Static WHERE DS_SOLARFSM in (SELECT DS_CHAMBERS FROM INCL_DETECTORS_FSM) order by 1", GBTPhase_cmd);
      // Get data for patplayer config
      fwDbStartCommand(dbCon, "SELECT DISTINCT cru_id,FLP_ID FROM CRU_Mapping WHERE CRU_Mapping.DS_SOLARFSM in (SELECT DS_CHAMBERS FROM INCL_DETECTORS_FSM) order by 1", CRUconfig_cmd);

      if (runType == "PEDESTALS" || UseCurrentRunType == "PEDESTALS")
      { // config MODE read out from DB for even chips
        fwDbStartCommand(dbCon, "SELECT chan_addr,reg_addr,data_value FROM config_registers WHERE config_ID = :1 and odd_even = 'even' and version_number = (select max(version_number) from config_registers) order by CR_ID", cmd_EVEN);
        // pedestal config read out from DB for odd chips
        fwDbStartCommand(dbCon, "SELECT chan_addr,reg_addr,data_value FROM config_registers WHERE config_ID = :1 and odd_even = 'odd' and version_number = (select max(version_number) from config_registers) order by CR_ID", cmd_ODD);
      }
      if ((runType == "PHYSICS" || runType == "TECHNICAL" || runType == "COSMICS") || UseCurrentRunType == "PHYSICS" || UseCurrentRunType == "TECHNICAL" || UseCurrentRunType == "COSMICS")
      { // DebugTN("enter1");
        // physics config read out from DB for even chips
        fwDbStartCommand(dbCon, "SELECT chan_addr,reg_addr,data_value FROM config_registers WHERE config_ID = :1 and odd_even = 'even' and version_number = (select max(version_number) from config_registers) order by CR_ID", cmd_EVEN);
        // physics config read out from DB for odd chips
        fwDbStartCommand(dbCon, "SELECT chan_addr,reg_addr,data_value FROM config_registers WHERE config_ID = :1 and odd_even = 'odd' and version_number = (select max(version_number) from config_registers) order by CR_ID", cmd_ODD);
      }

      if (fwDbCheckError(errMsg, DS_cmd))
      {
        DebugTN("ERROR: fwDbStartCommand DS_cmd ", errMsg);
        return;
      }
      if (fwDbCheckError(errMsg, SOL_cmd))
      {
        DebugTN("ERROR: fwDbStartCommand SOL_cmd ", errMsg);
        return;
      }
      if (fwDbCheckError(errMsg, BadChan_cmd))
      {
        DebugTN("2 ERROR: fwDbStartCommand BadChan_cmd ", errMsg);
        return;
      }
      if (fwDbCheckError(errMsg, GBTPhase_cmd))
      {
        DebugTN("2 ERROR: fwDbStartCommand GBTPhase_cmd ", errMsg);
        return;
      }
      if (fwDbCheckError(errMsg, cmd_ODD))
      {
        DebugTN("ERROR: fwDbStartCommand cmd_ODD ", errMsg);
        dpSet("mch_fee:OutputDataScreens.MCHSORLog", "ERROR: ORACLE DB ACCESS TO SAMPA CONFIGS FAIL (POSSIBLE MISSING RUNTYPE)");
        return;
      }
      if (fwDbCheckError(errMsg, cmd_EVEN))
      {
        DebugTN("ERROR: fwDbStartCommand cmd_EVEN ", errMsg);
        dpSet("mch_fee:OutputDataScreens.MCHSORLog", "ERROR: ORACLE DB ACCESS TO SAMPA CONFIGS FAIL (POSSIBLE MISSING RUNTYPE)");
        return;
      }

      fwDbBindParams(cmd_ODD, pass_confparams);
      fwDbBindParams(cmd_EVEN, pass_confparams);

      if (fwDbCheckError(errMsg, DS_cmd))
      {
        DebugTN("ERROR: fwDbBindParams ", errMsg);
        return;
      }
      if (fwDbCheckError(errMsg, SOL_cmd))
      {
        DebugTN("ERROR: fwDbBindParams ", errMsg);
        return;
      }
      if (fwDbCheckError(errMsg, cmd_ODD))
      {
        DebugTN("ERROR: fwDbBindParams ", errMsg);
                dpSet("mch_fee:OutputDataScreens.MCHSORLog", "ERROR: ORACLE DB ACCESS TO SAMPA CONFIGS FAIL (POSSIBLE MISSING RUNTYPE)");
        return;
      }
      if (fwDbCheckError(errMsg, cmd_EVEN))
      {
        DebugTN("ERROR: fwDbBindParams ", errMsg);
                dpSet("mch_fee:OutputDataScreens.MCHSORLog", "ERROR: ORACLE DB ACCESS TO SAMPA CONFIGS FAIL (POSSIBLE MISSING RUNTYPE)");
        return;
      }
      if (fwDbCheckError(errMsg, CRUconfig_cmd))
      {
        DebugTN("3 ERROR: fwDbBindParams CRUconfig_cmd ", errMsg);
        return;
      }

      fwDbExecuteCommand(DS_cmd);
      fwDbExecuteCommand(CRUconfig_cmd);
      fwDbExecuteCommand(SOL_cmd);
      fwDbExecuteCommand(cmd_ODD);
      fwDbExecuteCommand(cmd_EVEN);
      fwDbExecuteCommand(BadChan_cmd);
      fwDbExecuteCommand(GBTPhase_cmd);
      // DebugTN("data",DS_cmd);

      if (fwDbCheckError(errMsg, DS_cmd))
      {
        DebugTN("ERROR: fwDbExecuteCommand DS_cmd ", errMsg);
        return;
      }
      if (fwDbCheckError(errMsg, CRUconfig_cmd))
      {
        DebugTN("ERROR: fwDbExecuteCommand CRUconfig_cmd ", errMsg);
        return;
      }
      if (fwDbCheckError(errMsg, SOL_cmd))
      {
        DebugTN("ERROR: fwDbExecuteCommand SOL_cmd ", errMsg);
        return;
      }
      if (fwDbCheckError(errMsg, BadChan_cmd))
      {
        DebugTN("ERROR: fwDbExecuteCommand BadChan_cmd ", errMsg);
        return;
      }
      if (fwDbCheckError(errMsg, GBTPhase_cmd))
      {
        DebugTN("ERROR: fwDbExecuteCommand GBTPhase_cmd ", errMsg);
        return;
      }
      if (fwDbCheckError(errMsg, cmd_ODD))
      {
        DebugTN("ERROR: fwDbExecuteCommand cmd_ODD ", errMsg);
                dpSet("mch_fee:OutputDataScreens.MCHSORLog", "ERROR: ORACLE DB ACCESS TO SAMPA CONFIGS FAIL (POSSIBLE MISSING RUNTYPE)");
        return;
      }
      if (fwDbCheckError(errMsg, cmd_EVEN))
      {
        DebugTN("ERROR: fwDbExecuteCommand cmd_EVEN ", errMsg);
                dpSet("mch_fee:OutputDataScreens.MCHSORLog", "ERROR: ORACLE DB ACCESS TO SAMPA CONFIGS FAIL (POSSIBLE MISSING RUNTYPE)");
        return;
      }

      dyn_dyn_mixed fec_cards, sol_links, ped_ODD, ped_EVEN, Badchannels, GBTPhase_dat, CRUconfig_data;
      fwDbGetData(DS_cmd, fec_cards);
      fwDbExecuteCommand(CRUconfig_cmd);
      fwDbGetData(SOL_cmd, sol_links);
      fwDbGetData(cmd_ODD, ped_ODD);
      fwDbGetData(cmd_EVEN, ped_EVEN);
      fwDbGetData(CRUconfig_cmd, CRUconfig_data);
      fwDbGetData(BadChan_cmd, Badchannels);
      fwDbGetData(GBTPhase_cmd, GBTPhase_dat);

      if (fwDbCheckError(errMsg, DS_cmd))
      {
        DebugTN("ERROR: fwDbGetData ", errMsg);
      }
      if (fwDbCheckError(errMsg, CRUconfig_cmd))
      {
        DebugTN("ERROR: fwDbGetData CRUconfig_cmd ", errMsg);
      }
      if (fwDbCheckError(errMsg, SOL_cmd))
      {
        DebugTN("ERROR: fwDbGetData ", errMsg);
      }
      if (fwDbCheckError(errMsg, BadChan_cmd))
      {
        DebugTN("ERROR: fwDbGetData ", errMsg);
      }
      if (fwDbCheckError(errMsg, cmd_ODD))
      {
        DebugTN("ERROR: fwDbGetData ", errMsg);
                dpSet("mch_fee:OutputDataScreens.MCHSORLog", "ERROR: ORACLE DB ACCESS TO SAMPA CONFIGS FAIL (POSSIBLE MISSING RUNTYPE)");
      }

      if (fwDbCheckError(errMsg, cmd_EVEN))
      {
        DebugTN("ERROR: fwDbGetData ", errMsg);
                dpSet("mch_fee:OutputDataScreens.MCHSORLog", "ERROR: ORACLE DB ACCESS TO SAMPA CONFIGS FAIL (POSSIBLE MISSING RUNTYPE)");

      }

DebugTN("GBTPhasedata ",GBTPhase_dat);

      /////  -----------------------------GET DATA FROM DB TO CONFIGURE FEC-------------------------------------------////

      len_links = dynlen(sol_links);
      // DebugTN("sol_links ", sol_links);
      /* fwDbStartCommand(dbCon, "DELETE FROM INCL_DETECTORS", DROPtempTable_cmd);
       if (fwDbCheckError(errMsg, DROPtempTable_cmd))
       {
         DebugTN("ERROR: fwDbStartCommandDELETE ", errMsg);
         return;
       }
       fwDbExecuteCommand(DROPtempTable_cmd);
       if (fwDbCheckError(errMsg, DROPtempTable_cmd))
       {
         DebugTN("ERROR: fwDbExecuteCommand ", errMsg);
         return;
       }
       fwDbStartCommand(dbCon, "INSERT INTO INCL_DETECTORS(DS_CHAMBERS,DS_CHILDREN,DS_SOLARFSM,SOLAR_FLAG, GBT_FLAG,SAMPA_FLAG) VALUES(:pass_inclparams1,:pass_inclparams2,:pass_inclparams3,1,0,0)", tempTable_cmd);
       if (fwDbCheckError(errMsg, tempTable_cmd))
       {
         DebugTN("ERROR: fwDbStartCommand ", errMsg);
         return;
       }
       dyn_dyn_mixed pass_inclparams;
       for (int i = 1; i <= len_links; i++)
       {
         pass_inclparams[i][1] = sol_links[i][9];
         pass_inclparams[i][2] = sol_links[i][10];
         pass_inclparams[i][3] = sol_links[i][12];
       }
       fwDbBindAndExecute(tempTable_cmd, pass_inclparams);
       if (fwDbCheckError(errMsg, tempTable_cmd))
       {
         DebugTN("ERROR: fwDbBindAndExecute ", errMsg);
         return;
       }*/

      // DebugTN("sol ped_EVEN",ped_EVEN);

      len_fectotal = dynlen(fec_cards);
      len_links = dynlen(sol_links);
      int len_links_CRUconfig_data = dynlen(CRUconfig_data);
      len_pedeven = dynlen(ped_EVEN);
      len_pedodd = dynlen(ped_ODD);

      for (int i = 1; i <= len_links_CRUconfig_data; i++)
      {
        CRUConfig_cruids[i] = CRUconfig_data[i][1];
        CRUConfig_flpids[i] = CRUconfig_data[i][2];
      }

      //	WriteCRUReg
      dyn_string WriteCRURegData, WriteCRUReg = "0x00c80004";
      if (((runType == "PHYSICS" || runType == "TECHNICAL" || runType == "COSMICS") && clusterSum == TRUE) || ((UseCurrentRunType == "PHYSICS" || UseCurrentRunType == "TECHNICAL" || UseCurrentRunType == "COSMICS") && UseCurrentCSum == TRUE))
      {
        for (int i = 1; i <= len_links_CRUconfig_data; i++)
        {
          FEEID1[i] = (int)CRUConfig_cruids[i] * 2;
          FEEID2[i] = ((int)CRUConfig_cruids[i] * 2) + 1;
          FEEID1[i] = FEEID1[i] + 256;
          FEEID2[i] = FEEID2[i] + 256;
          sprintf(xFEEID1[i], "%04x", FEEID1[i]);
          sprintf(xFEEID2[i], "%04x", FEEID2[i]);
          WriteCRURegData[i] = "0x" + xFEEID2[i] + xFEEID1[i];
        }
        for (int i = 1; i <= dynlen(CRUConfig_cruids); i++)
        {
          // dpSet("mch_fee:CRURegisterWrite." + CRUConfig_flpids[i] + "C" + CRUConfig_cruids[i] + ":_original.._value", WriteCRUReg);
          dpSet("mch_fee:CRURegisterWrite." + CRUConfig_flpids[i] + "C" + CRUConfig_cruids[i] + ":_original.._value", WriteCRUReg + "," + WriteCRURegData[i]);
        }
        dpSet("mch_fee:OutputDataScreens.MCHSORLog", "");
        dpSet("mch_fee:OutputDataScreens.MCHSORLog", "FEEIDs SET FOR ALL CRUs WITH CLUSTERSUM ENABLED");
      }
      if (clusterSum != TRUE || UseCurrentCSum != TRUE)
      {
        for (int i = 1; i <= len_links_CRUconfig_data; i++)
        {
          FEEID1[i] = (int)CRUConfig_cruids[i] * 2;
          FEEID2[i] = ((int)CRUConfig_cruids[i] * 2) + 1;
          sprintf(xFEEID1[i], "%04x", FEEID1[i]);
          sprintf(xFEEID2[i], "%04x", FEEID2[i]);
          WriteCRURegData[i] = "0x" + xFEEID2[i] + xFEEID1[i];
        }
        for (int i = 1; i <= dynlen(CRUConfig_cruids); i++)
        {
          // dpSet("mch_fee:CRURegisterWrite." + CRUConfig_flpids[i] + "C" + CRUConfig_cruids[i] + ":_original.._value", WriteCRUReg);
          dpSet("mch_fee:CRURegisterWrite." + CRUConfig_flpids[i] + "C" + CRUConfig_cruids[i] + ":_original.._value", WriteCRUReg + "," + WriteCRURegData[i]);
        }
        dpSet("mch_fee:OutputDataScreens.MCHSORLog", "");
        dpSet("mch_fee:OutputDataScreens.MCHSORLog", "FEEIDs SET FOR ALL CRUs WITH CLUSTERSUM DISABLED");
      }
      // DebugTN("WriteCRURegData",WriteCRURegData);

      fwDbStartCommand(dbCon, "SELECT DS_CHAMBERS,DS_CHILDREN,DS_SOLARFSM, SOLAR_FLAG,GBT_FLAG,SAMPA_FLAG FROM INCL_DETECTORS", incldet_cmd);

      if (fwDbCheckError(errMsg, incldet_cmd))
      {
        DebugTN("ERROR: fwDbStartCommand ", errMsg);
        return;
      }
      fwDbExecuteCommand(incldet_cmd);
      if (fwDbCheckError(errMsg, incldet_cmd))
      {
        DebugTN("ERROR: fwDbExecuteCommand ", errMsg);
        return;
      }

      fwDbGetData(incldet_cmd, INCL_DET);
      if (fwDbCheckError(errMsg, incldet_cmd))
      {
        DebugTN("ERROR: fwDbGetData ", errMsg);
        return;
      }

      int l = 1;
      for (int i = 1; i <= len_links; i++)
      {
        cru_links[l] = sol_links[i][2];
        sol_crates[l] = sol_links[i][4];
        sol_boards[l] = sol_links[i][5];
        ch_id[l] = sol_links[i][7];
        ch_side[l] = sol_links[i][8];
        sol_id[l] = sol_links[i][6];
        cru_IDS[l] = sol_links[i][3];
        slatID[l] = sol_links[i][11];
        l++;
      }

      len_cruid = dynlen(cru_IDS);
      len_solcrate = dynlen(sol_crates);

      int len_Badchannels = dynlen(Badchannels);
      dyn_dyn_string bad_channel;
      int t = 1, bad_chan, bad_chip;

      int r = 1, t = 1;
      //  DebugTN("sol_id ", sol_id);
      // DebugTN("DS_links ", DS_links);
      for (int i = 1; i <= len_fectotal; i++)
      { // int t =1;
        //  DebugTN("sol_id ", sol_id[r]);
        if (fec_cards[i][1] == sol_id[r])
        {
          for (int j = 6; j <= 10; j++)
          {
            if (fec_cards[i][j] != "0" && fec_cards[i][j] != "12345678")
            {
              enable_DS[t] += "1";
            }
            else
            {
              enable_DS[t] += "0";
            }
          }
          //  DebugTN("enable_DS ", enable_DS[t]);
        }
        else
        {
          r++;
          t++;
          for (int j = 6; j <= 10; j++)
          {
            if (fec_cards[i][j] != "0" && fec_cards[i][j] != "12345678")
            {
              enable_DS[t] += "1";
            }
            else
            {
              enable_DS[t] += "0";
            }
          }
          //  DebugTN("enable_DS ", enable_DS[t]);
        }
      }
      int c;
      // DebugTN("enable_DS ",enable_DS);
      //  DebugTN("c ",c);
      // ADD "0" TO ENABLE MASK OR BOARDS NOT CONNECTED AT ALL
      // DebugTN("len_links",len_links);
      for (int i = 1; i <= len_links; i++)
      {
        c = 40 - strlen(enable_DS[i]);
        if (c != 0)
        {
          for (int j = 1; j <= c; j++)
          {
            enable_DS[i] += "0";
          }
        }
      }

      // DebugTN("enable_DS ",enable_DS);

      for (int i = 1; i <= len_links; i++)
      {
        enableDSchange = enable_DS[i];
        // lenDSen= strlen(enableDSchange);
        // DebugTN("lenDSen",lenDSen);
        for (int s = 40; s >= 0; s--)
        {
          enable_DSf[i] += enableDSchange[s];
        }
      }

      // UPDATE BOARD_ENABLE TABLE WITH ENABLE MASK ROM CURRENT DS BOARD SETUP - IF FEC.MAP CHANGES FOR ANY DS BOARDS IT GETS UPDATED////
      // DebugTN("enable_DSf ",enable_DSf);
      fwDbStartCommand(dbCon, "UPDATE board_enabled SET board_enabled.enable_mask = :en_mask1 where board_enabled.DS_CHAMBER = :en_mask2 and board_enabled.DS_CHILDREN = :en_mask3", enable_cmd);

      for (int i = 1; i <= len_links; i++)
      {
        en_mask[i][1] = enable_DS[i];
        en_mask[i][2] = sol_links[i][9];
        en_mask[i][3] = sol_links[i][10];
      }
      if (fwDbCheckError(errMsg, enable_cmd))

      {
        DebugTN("ERROR: fwDbStartCommand ", errMsg);
        return;
      }
      fwDbBindAndExecute(enable_cmd, en_mask);

      if (fwDbCheckError(errMsg, enable_cmd))

      {
        DebugTN("ERROR: fwDbBindAndExecute ", errMsg);
        return;
      }

      // buildGBTRegistersforConfig()

      d_AnyArray[1] = makeDynString("0", "0000");
      d_AnyArray[2] = makeDynString("1", "0001");
      d_AnyArray[3] = makeDynString("2", "0010");
      d_AnyArray[4] = makeDynString("3", "0011");
      d_AnyArray[5] = makeDynString("4", "0100");
      d_AnyArray[6] = makeDynString("5", "0101");
      d_AnyArray[7] = makeDynString("6", "0110");
      d_AnyArray[8] = makeDynString("7", "0111");
      d_AnyArray[9] = makeDynString("8", "1000");
      d_AnyArray[10] = makeDynString("9", "1001");
      d_AnyArray[11] = makeDynString("A", "1010");
      d_AnyArray[12] = makeDynString("B", "1011");
      d_AnyArray[13] = makeDynString("C", "1100");
      d_AnyArray[14] = makeDynString("D", "1101");
      d_AnyArray[15] = makeDynString("E", "1110");
      d_AnyArray[16] = makeDynString("F", "1111");

      int y = dynContains(d_AnyArray, "1111");
      int len_d_AnyArray = dynlen(d_AnyArray);

      ////-----------GBT INPUT SIGNAL commands For enabled boards only-----------/////

      for (int i = 1; i <= len_links; i++)
      {
        int pos = 32;
        mask = enable_DSf[i];

        for (int j = 1; j <= 5; j++)
        {
          dyn_string imask;
          tmask = substr(mask, pos, 8);
          imask[1] = substr(tmask, 0, 4);
          pos = pos - 8;

          imask[2] = substr(tmask, 4, 4);
          for (int u = 1; u <= len_d_AnyArray; u++)
          {
            if (imask[1] == d_AnyArray[u][2])
            {
              fmask[j] = "0x" + d_AnyArray[u][1];
            }
          }
          for (int u = 1; u <= len_d_AnyArray; u++)
          {
            if (imask[2] == d_AnyArray[u][2])
            {
              fmask[j] += d_AnyArray[u][1];
            }
          }

          gbtmask[i][j] = fmask[j];
        }
        gbtfmask[i] = makeDynString(gbtmask[i][1] + "," + gbtmask[i][2] + "," + gbtmask[i][3] + "," + gbtmask[i][4] + "," + gbtmask[i][5] + ",");
        gbtfmask[i] += makeDynString(gbtmask[i][1] + "," + gbtmask[i][2] + "," + gbtmask[i][3] + "," + gbtmask[i][4] + "," + gbtmask[i][5] + ",");
        gbtfmask[i] += makeDynString(gbtmask[i][1] + "," + gbtmask[i][2] + "," + gbtmask[i][3] + "," + gbtmask[i][4] + "," + gbtmask[i][5]);
      }

      dyn_dyn_string GBT_PhaseStaticVal;
      for (int k = 1; k <= dynlen(GBTPhase_dat); k++)
      {
        int w = 1, n = 0;
        for (int t = 0; t <= strlen(GBTPhase_dat[k][3]); t++)
        {
          string val1, val2;
          while (w <= 20)
          {
            val1 = substr(GBTPhase_dat[k][3], n, 1);
            n++;
            val2 = substr(GBTPhase_dat[k][3], n, 1);
            n++;

            GBT_PhaseStaticVal[k][w] = "0x" + val2 + val1;
            //  DebugTN("GBT_PhaseStaticVal",  GBT_PhaseStaticVal[k][w]);
            w++;
          }
        }
      }
      //  DebugTN("GBT_PhaseStaticVal", GBT_PhaseStaticVal);
      dyn_string GBT_PhaseStaticWrite;

      dyn_int GBT_PhaseStaticReg = makeDynInt(69, 68, 67, 66, 93, 92, 91, 90, 117, 116, 115, 114, 141, 140, 139, 138, 165, 164, 163, 162);
      for (int k = 1; k <= dynlen(GBTPhase_dat); k++)
      {
        int s = 1;
        for (int m = 1; m <= dynlen(GBT_PhaseStaticReg); m++)
        {
          string gbtreg1, gbtreg2, gbtreg3;
          if (s == 1)
          {
            GBT_PhaseStaticWrite[k] = "0x0";
          }
          if (s == 2 || s <= dynlen(GBT_PhaseStaticReg))
          {
            GBT_PhaseStaticWrite[k] += "," + GBT_PhaseStaticVal[k][m];
            GBT_PhaseStaticWrite[k] += "," + GBT_PhaseStaticVal[k][m];
            GBT_PhaseStaticWrite[k] += "," + GBT_PhaseStaticVal[k][m];
            s++;
          }
          else if (s == dynlen(GBT_PhaseStaticReg))
          {
            GBT_PhaseStaticWrite[k] += "," + GBT_PhaseStaticVal[k][m];
            GBT_PhaseStaticWrite[k] += "," + GBT_PhaseStaticVal[k][m];
            GBT_PhaseStaticWrite[k] += "," + GBT_PhaseStaticVal[k][m];
          }
        }
      }
      time t1 = getCurrentTime();
      // DebugTN("GBT_PhaseStaticWrite gbt",GBT_PhaseStaticWrite);
      // configGBTRegisters();
      dpSet("mch_fee:OutputDataScreens.MCHSORLog", "");
      dpSet("mch_fee:OutputDataScreens.MCHSORLog", "CONFIGURING GBT REGISTERS...");
      DebugTN("----------------------------");
      DebugTN("Configuring GBT REGISTERS...");
      DebugTN("----------------------------");
      for (int k = 1; k <= len_links; k++)
      { // DebugTN("enter gbt");
        if (INCL_DET[k][5] == 0)
        {
          dpSetWait(dp + sol_crates[k] + ".GBTClockEnable.Solar" + sol_boards[k], gbtfmask[k]); // gbtfmask[k]
          if (GBT_PhaseStaticWrite[k] == "")
          {
            dpSetWait(dp + sol_crates[k] + ".GBTPhaseAlignStart.Solar" + sol_boards[k], "");
            deay(2);
            dpSetWait(dp + sol_crates[k] + ".GBTPhaseAlignStop.Solar" + sol_boards[k], "");
          }
          else
          {  DebugTN("Event GBTPhaseAlignStatic1", GBT_PhaseStaticWrite[k]+ " "+ k);
            dpSetWait(dp + sol_crates[k] + ".GBTPhaseAlignStatic.Solar" + sol_boards[k], GBT_PhaseStaticWrite[k]);
          }
        }
      }
      delay(5);
      int m = 1, s = 1;
      for (int k = 1; k <= len_links; k++)
      { // DebugTN("enter gbt");
        if (INCL_DET[k][5] == 0)
        { // DebugTN("Event 1");
          dpGet(dp + sol_crates[k] + ".GBTClockRet_ANS.Solar" + sol_boards[k] + ":_original.._stime", GBTClocktimeANS[n]);
          dpGet(dp + sol_crates[k] + ".GBTClockRet_ERR.Solar" + sol_boards[k] + ":_original.._stime", GBTClocktimeERR[n]);
          dpGet(dp + sol_crates[k] + ".GBTClockRet_ERR.Solar" + sol_boards[k] + ":_original.._value", GBTClockReturnERR[n]);
          dpGet(dp + sol_crates[k] + ".GBTClockRet_ANS.Solar" + sol_boards[k] + ":_original.._value", GBTClockReturnANS[n]);

          if (GBT_PhaseStaticWrite[k] == "")
          { // DebugTN("Event 2");
            dpGet(dp + sol_crates[k] + ".GBTPhaseAlignStartRet_ERR.Solar" + sol_boards[k] + ":_original.._stime", GBTPhasetimeStartERR[n]);
            dpGet(dp + sol_crates[k] + ".GBTPhaseAlignStartRet_ANS.Solar" + sol_boards[k] + ":_original.._stime", GBTPhasetimeStartANS[n]);
            dpGet(dp + sol_crates[k] + ".GBTPhaseAlignStartRet_ERR.Solar" + sol_boards[k] + ":_original.._value", GBTPhaseReturnStartERR[n]);
            dpGet(dp + sol_crates[k] + ".GBTPhaseAlignStartRet_ANS.Solar" + sol_boards[k] + ":_original.._value", GBTPhaseReturnStartANS[n]);
            dpGet(dp + sol_crates[k] + ".GBTPhaseAlignStopRet_ERR.Solar" + sol_boards[k] + ":_original.._stime", GBTPhasetimeStopERR[n]);
            dpGet(dp + sol_crates[k] + ".GBTPhaseAlignStopRet_ANS.Solar" + sol_boards[k] + ":_original.._stime", GBTPhasetimeStopANS[n]);
            dpGet(dp + sol_crates[k] + ".GBTPhaseAlignStopRet_ERR.Solar" + sol_boards[k] + ":_original.._value", GBTPhaseReturnStopERR[n]);
            dpGet(dp + sol_crates[k] + ".GBTPhaseAlignStopRet_ANS.Solar" + sol_boards[k] + ":_original.._value", GBTPhaseReturnStopANS[n]);
          }
          else
          { // DebugTN("Event 3");
            dpGet(dp + sol_crates[k] + ".GBTPhaseAlignStatic_ERR.Solar" + sol_boards[k] + ":_original.._stime", GBTPhaseStatictimeERR[n]);
            dpGet(dp + sol_crates[k] + ".GBTPhaseAlignStatic_ANS.Solar" + sol_boards[k] + ":_original.._stime", GBTPhasetimeStaticANS[n]);
            dpGet(dp + sol_crates[k] + ".GBTPhaseAlignStatic_ERR.Solar" + sol_boards[k] + ":_original.._value", GBTPhaseReturnStaticERR[n]);
            dpGet(dp + sol_crates[k] + ".GBTPhaseAlignStatic_ERR.Solar" + sol_boards[k] + ":_original.._value", GBTPhaseReturnStaticANS[n]);
          }

          // DebugTN("INCL_DET 6");
          if (GBT_PhaseStaticWrite[k] == "")
          { // DebugTN("Event 6");

            if (GBTClocktimeERR[n] >= t1)
            { // DebugTN("enter gbt 1");
              // dpSet("mch_fee:OutputDataScreens.MCHSORLog","                            GBT CONFIGURATION FOR DS BOARDS CONNECTED TO CH"+ch_id[k]+ch_side[k]+" CRU "+cru_IDS[k]+" LINK "+cru_links[k]+" - FAILED: "+GBTClockReturnERR[n]);
              //	DebugTN("           GBT CONFIGURATION FOR DS BOARDS CONNECTED TO CH"+ch_id[k]+ch_side[k]+" CRU "+cru_IDS[k]+" LINK "+cru_links[k]+" - FAILED: "+GBTClockReturnERR[n]);
              gbtphasefail[m] = "CH" + ch_id[k] + ch_side[k] + " CRU " + cru_IDS[k] + " LINK " + (string)cru_links[k] + " - " + GBTPhaseReturnStopERR[n];
              gbtclockfail[m] = "CH" + ch_id[k] + ch_side[k] + " CRU " + cru_IDS[k] + " LINK " + (string)cru_links[k] + " - " + GBTClockReturnERR[n];
              gbtclockflag[n] = "0";
              m++;
            }
            else if (GBTClocktimeANS[n] == "0")
            {
              //	dpSet("mch_fee:OutputDataScreens.MCHSORLog","           GBT CONFIGURATION FAILED - ALF-FRED NOT RESPONDING");
              //		DebugTN("           GBT CONFIGURATION FAILED - ALF-FRED NOT RESPONDING");
              gbtclockfail[m] = "CH" + ch_id[k] + ch_side[k] + " CRU " + cru_IDS[k] + " LINK " + (string)cru_links[k] + " - ALF-FRED NOT RESPONDING";
              gbtclockflag[n] = "0";
              m++;
            }
            else if (GBTClocktimeANS[n] >= t1)
            { // DebugTN("enter gbt 3");
              //	dpSet("mch_fee:OutputDataScreens.MCHSORLog","                      GBT CONFIGURATION FOR DS BOARDS CONNECTED TO CH"+ch_id[k]+ch_side[k]+" CRU "+cru_IDS[k]+" LINK "+cru_links[k]+" - SUCCESS");
              //		DebugTN("           GBT CONFIGURATION FOR DS BOARDS CONNECTED TO CH"+ch_id[k]+ch_side[k]+" CRU "+cru_IDS[k]+" LINK "+cru_links[k]+" - SUCCESS");
              gbtclockflag[n] = "1";
              INCL_DET[k][5] = 1;
            }
          }
          else
          { // DebugTN("enter gbt 111");

            if (GBTClocktimeERR[n] >= t1)
            { // DebugTN("enter gbt 11");
              //  dpSet("mch_fee:OutputDataScreens.MCHSORLog","                            GBT CONFIGURATION FOR DS BOARDS CONNECTED TO CH"+ch_id[k]+ch_side[k]+" CRU "+cru_IDS[k]+" LINK "+cru_links[k]+" - FAILED: "+GBTClockReturnERR[n]);
              //	DebugTN("           GBT CONFIGURATION FOR DS BOARDS CONNECTED TO CH"+ch_id[k]+ch_side[k]+" CRU "+cru_IDS[k]+" LINK "+cru_links[k]+" - FAILED: "+GBTClockReturnERR[n]);
              gbtclockfail[m] = "CH" + ch_id[k] + ch_side[k] + " CRU " + cru_IDS[k] + " LINK " + (string)cru_links[k] + " - " + GBTClockReturnERR[n];
              gbtphasefail[m] = "CH" + ch_id[k] + ch_side[k] + " CRU " + cru_IDS[k] + " LINK " + (string)cru_links[k] + " - " + GBTPhaseReturnStaticERR[n];
              gbtclockflag[n] = "0";
              m++;
            }
            else if (GBTClocktimeANS[n] == "0")
            { // DebugTN("enter gbt 22");
              //		dpSet("mch_fee:OutputDataScreens.MCHSORLog","           GBT CONFIGURATION FAILED - ALF-FRED NOT RESPONDING");
              //	DebugTN("           GBT CONFIGURATION FAILED - ALF-FRED NOT RESPONDING");
              gbtclockfail[m] = "CH" + ch_id[k] + ch_side[k] + " CRU " + cru_IDS[k] + " LINK " + (string)cru_links[k] + " - ALF-FRED NOT RESPONDING";
              gbtclockflag[n] = "0";
              m++;
            }
            else if (GBTClocktimeANS[n] >= t1)
            { // DebugTN("enter gbt 33");
              //		dpSet("mch_fee:OutputDataScreens.MCHSORLog","                      GBT CONFIGURATION FOR DS BOARDS CONNECTED TO CH"+ch_id[k]+ch_side[k]+" CRU "+cru_IDS[k]+" LINK "+cru_links[k]+" - SUCCESS");
              //	DebugTN("           GBT CONFIGURATION FOR DS BOARDS CONNECTED TO CH"+ch_id[k]+ch_side[k]+" CRU "+cru_IDS[k]+" LINK "+cru_links[k]+" - SUCCESS");
              gbtclockflag[n] = "1";
              gbtphaseflag[n] = "1";
              INCL_DET[k][5] = 1;
            }
          }
        }
        else if (INCL_DET[k][5] == 1)
        {
          gbtflag[s] = "1";
          gbtphaseflag[s] = "1";
          s++;
        }
        n++;
      }
      DebugTN("----------------------------");
      // DebugTN("gbtfail ",gbtfail);
      //		dpSet("mch_fee:OutputDataScreens.MCHSORLog","");

      time t2 = getCurrentTime();

      if (dynCount(gbtflag, "1") == len_links)
      { // dpSet("mch_fee:OutputDataScreens.MCHSORLog","");
        dpSet("mch_fee:OutputDataScreens.MCHSORLog", "CONFIGURATION OF GBT REGISTERS COMPLETED WITH NO ERRORS!!!");
        DebugTN("GBT REGISTERS FOR ALL LINKS ALREADY CONFIGURED CORRECTLY!!!");
      }
      else if (dynCount(gbtclockflag, "1") != len_links)
      {
        // dpSet("mch_fee:OutputDataScreens.MCHSORLog","");
        dpSet("mch_fee:OutputDataScreens.MCHSORLog", "CONFIGURATION OF GBT REGISTERS COMPLETED WITH BELOW ERRORS:");
        DebugTN("CONFIGURATION OF GBT REGISTERS COMPLETED WITH BELOW ERRORS:");
        for (int k = 1; k <= dynlen(gbtclockfail); k++)
        {
          dpSet("mch_fee:OutputDataScreens.MCHSORLog", gbtclockfail[k]);
        }
        //   dpSet("mch_fee:OutputDataScreens.MCHSORLog",gbtphasefail);

        DebugTN("CONFIGURATION OF GBT REGISTERS FAILED WITH BELOW LINKS:\n", gbtclockfail, "\n", gbtphasefail);
        // DebugTN("CONFIGURATION OF GBT FAILED WITH BELOW LINKS:");

        //	 this.backCol = "STD_value_not_ok";
        // PanelOff("configSAMPA");
      }
      else
      {
        delay(2);
        // dpSet("mch_fee:OutputDataScreens.MCHSORLog","");
        dpSet("mch_fee:OutputDataScreens.MCHSORLog", "CONFIGURATION OF GBT REGISTERS COMPLETED WITH NO ERRORS!!!");
        DebugTN("CONFIGURATION OF GBT REGISTERS FOR ALL LINKS SUCCESSFUL!!!");
        // this.backCol = "STD_valve_open";
      }

      DebugTN("----------------------------");
      DebugTN("Start time: ", (string)t1);
      DebugTN("End time: ", (string)t2);
      DebugTN("----------------------------");
      DebugTN("----------------------------");
      // this.backCol ="_Button";
      //  this.backCol ="_Button";

      dpSet("mch_fee:OutputDataScreens.MCHSORLog", "");
      dyn_string WriteULLinksEnabled = "0x00000000", WriteULLinksDisabled = "0x0FFF0FFF", WriteCRURegLink = "0x00c80008";
      //	WriteCRUReg
      for (int i = 1; i <= dynlen(CRUConfig_cruids); i++)
      {
        // dpSet("mch_fee:CRURegisterWrite." + CRUConfig_flpids[i] + "C" + CRUConfig_cruids[i] + ":_original.._value", WriteCRURegLink);
        dpSet("mch_fee:CRURegisterWrite." + CRUConfig_flpids[i] + "C" + CRUConfig_cruids[i] + ":_original.._value", WriteCRURegLink + "," + WriteULLinksDisabled);
      }
      dpSet("mch_fee:OutputDataScreens.MCHSORLog", "SET LINK PATTERN FOR ALL CRUs TO " + WriteULLinksDisabled);

      dyn_string WriteULReset = "0x00000003", WriteCRURegReset = "0x00c80000";
      //	WriteCRUReg
      for (int i = 1; i <= dynlen(CRUConfig_cruids); i++)
      {
        // dpSet("mch_fee:CRURegisterWrite." + CRUConfig_flpids[i] + "C" + CRUConfig_cruids[i] + ":_original.._value", WriteCRURegReset);
        dpSet("mch_fee:CRURegisterWrite." + CRUConfig_flpids[i] + "C" + CRUConfig_cruids[i] + ":_original.._value", WriteCRURegReset + "," + WriteULReset);
      }
      // dpSet("mch_fee:OutputDataScreens.MCHSORLog", "");
      delay(3);

      dyn_string WriteULReset = "0x00000000", WriteCRURegReset = "0x00c80000";
      //	WriteCRUReg
      for (int i = 1; i <= dynlen(CRUConfig_cruids); i++)
      {
        //  dpSet("mch_fee:CRURegisterWrite." + CRUConfig_flpids[i] + "C" + CRUConfig_cruids[i] + ":_original.._value", WriteCRURegReset);
        dpSet("mch_fee:CRURegisterWrite." + CRUConfig_flpids[i] + "C" + CRUConfig_cruids[i] + ":_original.._value", WriteCRURegReset + "," + WriteULReset);
      }
      dpSet("mch_fee:OutputDataScreens.MCHSORLog", "");

      for (int i = 1; i <= len_links_CRUconfig_data; i++)
      {
        CRUConfig_cruids[i] = CRUconfig_data[i][1];
        CRUConfig_flpids[i] = CRUconfig_data[i][2];
      }
      // DebugTN("CRUConfig_cruids",CRUConfig_cruids);
      // DebugTN("CRUConfig_flpids",CRUConfig_flpids);
      // sendHardReset();

      hardrest_input = "0x0,0x0,0x0C0300C0300C0300C030,1,0,3000,30,29,false,false,true";

      for (int i = 1; i <= dynlen(CRUConfig_cruids); i++)
      {
        dpSet("mch_fee:CRUConfig." + CRUConfig_flpids[i] + "C" + CRUConfig_cruids[i] + ":_original.._value", hardrest_input);
      }

      dpSet("mch_fee:OutputDataScreens.MCHSORLog", "HARD RESET FOR SAMPA REGISTERS DONE");
      // dyn_string flexids = makeDynString("0","1","2","3","4","5","6","7");

      // check each Solar board for missing DS boards/boards to be excluded from configuration
      //  getListOfChipsIncluded();

      int r = 1, l1 = 1, n = 1, s = 1;
      for (int i = 1; i <= len_fectotal; i++)
      {
        if (fec_cards[i][1] == sol_id[r])
        {

          for (int j = 6; j <= 10; j++)
          {
            board_count[r]++;
            fec_count[r]++;
            fec_count[r]++;
            if (fec_cards[i][j] != "0" && fec_cards[i][j] != "12345678")
            {
              boardList[r][s] += 1;
              s++;
              ds_count[r]++;
              ds_count[r]++;
            }

            else if (fec_cards[i][j] == "0" || fec_cards[i][j] == "12345678")
            {
              boardList[r][s] += 0;
              s++;
              excl_boards[r][l1] = fec_count[r] - 2;
              l1++;
              excl_boards[r][l1] = fec_count[r] - 1;
              l1++;
            }
            else
            {
              excl_boards[r][l1] = 1000;
              //   DebugTN("not conn 1");
            }
          }
        }
        else
        {
          t = 1;
          s = 1;
          r++;
          l1 = 1;

          for (int j = 6; j <= 10; j++)
          {
            board_count[r]++;
            fec_count[r]++;
            fec_count[r]++;
            if (fec_cards[i][j] != "0" && fec_cards[i][j] != 12345678)
            {
              boardList[r][s] += 1;
              s++;
              ds_count[r]++;
              ds_count[r]++;
            }

            else if (fec_cards[i][j] == "0" || fec_cards[i][j] == 12345678)
            {
              boardList[r][s] += 0;
              s++;
              excl_boards[r][l1] = fec_count[r] - 2;
              l1++;
              excl_boards[r][l1] = fec_count[r] - 1;
              l1++;
            }
            else
            {
              excl_boards[r][l1] = 1000; // solar group not connected
              // DebugTN("not conn 2");
            }
          }
        }
      }
      // DebugTN("excl_boards ",excl_boards);
      // DebugTN("boardList ",boardList);
      // DebugTN("board_count1st ",board_count);
      //   DebugTN("Number of ds chips conn total ", ds_count);
      //    DebugTN("Number of ds chips total ", fec_count);
      //   DebugTN("Number of ds chips disconnected ", excl_boards);

      delay(3);

      delay(2);

      // DebugTN("Number ped_EVEN solar boards ", ped_EVEN);
      // DebugTN("Number ped_EVEN solar boards ", ped_ODD);
      // DebugTN("Number of crates ", sol_crates);
      // DebugTN("Number of crus ", cru_IDS);
      // DebugTN("Number of Solar links ", cru_links);
      // DebugTN("Number of DS boards ", ds_count);

      // DebugTN("cru ids", cru_IDS);
      // DebugTN("excluded boards  IDS", excl_boards);

      ////-----------DB Access End for processing-----------/////

      ////-----------Start of ped_config arrangement and configuration of FEC-----------/////

      // preparing pedestal config for even chips into a dyn_string
      // buildSAMPAConfigList();
      DebugTN("event 1: extract even chip configs for SAMPA");
      for (int i = 1; i <= len_pedeven; i++)
      {
        for (int j = 1; j <= 3; j++)
        {
          if (j != 3)
          {
            sampa_config_file_0[i] += (string)ped_EVEN[i][j];
            sampa_config_file_0[i] += " ";
          }
          else
          {
            sampa_config_file_0[i] = sampa_config_file_0[i] + (string)ped_EVEN[i][j];
          }
        }
      }

      // preparing pedestal config for odd chips into a dynf_string
      for (int i = 1; i <= len_pedodd; i++)
      {
        for (int j = 1; j <= 3; j++)
        {
          if (j != 3)
          {
            sampa_config_file_1[i] += (string)ped_ODD[i][j];
            sampa_config_file_1[i] += " ";
          }
          else
          {
            sampa_config_file_1[i] = sampa_config_file_1[i] + (string)ped_ODD[i][j];
          }
        }
      }
      // DebugTN("sampa_config_file 1 \n",sampa_config_file_0);
      //  DebugTN("sampa_config_file 2\n",sampa_config_file_1);

      /////////create final dyn_string  containing chipnumber added to config string to be sent to FRED for pedestal even chips\\\\\\\\\
DebugTN("event 2: extract ODD chip configs for SAMPA");
      // but has empty entries for those excluded boards
      lenfeccount = dynlen(fec_count);
      // DebugTN("event 1 len_pedeven ");
      // DebugTN("fec_count ",fec_count[1]);
      int k = 1;
      for (int l = 1; l <= lenfeccount; l++)
      {
        int chipnumb_even = 0, r = 1;
        for (int j = 1; j <= fec_count[l]; j++)
        {
          if ((!dynContains(excl_boards[l], chipnumb_even)) && chipnumb_even <= (fec_count[l] - 1)) //|| !dynContains(excl_boards[l],0)
          {
            for (int i = 1; i <= (len_pedeven); i++)
            {
              sampa_config_file_0f[k][r] = (string)chipnumb_even + " " + sampa_config_file_0[i];
              r++;
            }
          }
          chipnumb_even = chipnumb_even + 2;
        }
        k++;
        // chipnumb_even++;
      }
      // DebugTN("sampa_config_file with chip number even \n",sampa_config_file_0f);

      /////////create final dyn_string containing chipnumber added to config string to be sent to FRED for pedestal odd chips\\\\\\\\

DebugTN("event 3: build  configs for SAMPA");
      int chipnumb_odd = 1;
      int k = 1;
      for (int l = 1; l <= lenfeccount; l++)
      {
        int chipnumb_odd = 1, r = 1;

        for (int j = 1; j <= fec_count[l]; j++)
        {
          if (!dynContains(excl_boards[l], chipnumb_odd) && chipnumb_odd <= (fec_count[l] - 1))
          { // DebugTN("Dyn contains", dynContains(excl_boards,chipnumb_odd));
            for (int i = 1; i <= len_pedodd; i++)
            {
              sampa_config_file_1f[k][r] = (string)chipnumb_odd + " " + sampa_config_file_1[i];
              r++;
            }
          }
          chipnumb_odd = chipnumb_odd + 2;
        }
        k++;
        // chipnumb_odd++;
      }

      // DebugTN("sampa_config_file\n",sampa_config_file);
      //  DebugTN("sampa_config_file ini\n",sampa_config_file_1f);

      len_pedfeven = dynlen(sampa_config_file_0f);
      len_pedfodd = dynlen(sampa_config_file_1f);

      // DebugTN("len_pedfeven length ",len_pedfeven);
      //  DebugTN("len_pedfodd length ",len_pedfodd);
      // bad_channel
      if (((runType == "PHYSICS" || runType == "TECHNICAL" || runType == "COSMICS") && clusterSum == TRUE) || ((UseCurrentRunType == "PHYSICS" || UseCurrentRunType == "TECHNICAL" || UseCurrentRunType == "COSMICS") && UseCurrentCSum == TRUE))
      { DebugTN("event 4: extract bad channel from db");
        dpSet("mch_fee:OutputDataScreens.MCHSORLog", "");
        dpSet("mch_fee:OutputDataScreens.MCHSORLog", "BAD CHANNEL DATA EXTRACTED FROM ORACLE DB");
        for (int l = 1; l <= len_solcrate; l++)
        {
          int r = 1, r1 = 1, r2 = 1;
          dyn_string solNobadchan;

          for (int k = 1; k <= len_Badchannels; k++)
          { // DebugTN("bad_chip strt");
            if (sol_id[l] == Badchannels[k][1])
            { // DebugTN("bad_chip 1");

              if (Badchannels[k][3] > 31) // checks the range 0-63 to distinguish even chip
              {
                bad_chip = ((int)Badchannels[k][2] * 2) + 1;
                bad_chan = (int)Badchannels[k][3] - 32;

                bad_channel[l][r] = (string)bad_chip + " " + (string)bad_chan + " " + "0x09 " + "0xff";
                r++;
              }
              else
              { // DebugTN("bad_chip 1");
                bad_chip = ((int)Badchannels[k][2] * 2);
                bad_chan = (int)Badchannels[k][3];
                bad_channel[l][r] = (string)bad_chip + " " + (string)bad_chan + " " + "0x09 " + "0xff";

                r++;
              }
            }
            else
            {
              solNobadchan[k] = "1";
            }
          }
          if (dynCount(solNobadchan, "1") == len_Badchannels)
          {
            bad_channel[l] = "";
          }
          t++;
        }

        // DebugTN("bad_channel 5", bad_channel);
        DebugTN("event 5: building bad channel inton config list to be sent to MAPI");

        int m = 1;
        dyn_int s;

        dyn_string singleConfig;
        for (int k = 1; k <= len_pedfeven; k++)
        {
          int r = 1, s = 1;
          dyn_string splitbadchan;
          string chipNum, chanNum, regNum;
          for (int w = 1; w <= dynlen(bad_channel[k]); w++)
          {
            if (bad_channel[k] != "")
            {

              splitbadchan = strsplit(bad_channel[k][w], " ");
              // DebugTN("splitbadchan ",splitbadchan);
              if ((int)splitbadchan[1] % 2 == 0)
              {
                for (int l = 1; l <= dynlen(sampa_config_file_0f[k]); l++)
                {
                  dyn_string splitConfigeven;
                  splitConfigeven = strsplit(sampa_config_file_0f[k][l], " ");
                  if (splitConfigeven[1] == splitbadchan[1] && splitConfigeven[2] == splitbadchan[2] && splitConfigeven[3] == splitbadchan[3])
                  {
                    sampa_config_file_0f[k][l] = bad_channel[k][w];
                  }
                }
              }
              else
              {
                for (int l = 1; l <= dynlen(sampa_config_file_0f[k]); l++)
                {
                  dyn_string splitConfigodd;
                  splitConfigodd = strsplit(sampa_config_file_1f[k][l], " ");
                  if (splitConfigodd[1] == splitbadchan[1] && splitConfigodd[2] == splitbadchan[2] && splitConfigodd[3] == splitbadchan[3])
                  {
                    sampa_config_file_1f[k][l] = bad_channel[k][w];
                  }
                }
              }
            }
          }
        }
        dpSet("mch_fee:OutputDataScreens.MCHSORLog", "");
        dpSet("mch_fee:OutputDataScreens.MCHSORLog", "BAD CHANNEL DATA COMPUTED AND INCLUDED IN SAMPA CONFIGURATION LIST");
      }
      // DebugTN("sampa_config_file after\n",sampa_config_file_1f);
      //
      // DebugTN("sampa_config_file_0f length ", sampa_config_file_0f);
      // DebugTN("sampa_config_file_0f length ", sampa_config_file_1f);

      // dyn_dyn_string sampa_config_final;

      /// Begin preparing all configuration for specified numberof DS boards for each solar link

      for (int l = 1; l <= len_solcrate; l++)
      {

        lenpedf_even[l] = dynlen(sampa_config_file_0f[l]);
        lenpedf_odd[l] = dynlen(sampa_config_file_1f[l]);
      }

      DebugTN("event 6: creating config string delimnated by comma for each link");

      // DebugTN("lenpedf_even length ",lenpedf_even);
      // DebugTN("lenpedf_odd length ",lenpedf_odd);
      int t = 1;
      for (int l = 1; l <= len_solcrate; l++)
      {
        int r = 1, r1 = 1, r2 = 1;
        for (int j = 1; j <= (lenpedf_even[t] / len_pedodd); j++)
        {
          for (int k = 1; k <= len_pedodd; k++)
          {
            if (r != (lenpedf_even[t] * 2))
            {
              sampa_config_final[t] += sampa_config_file_0f[t][r1] + ",";
              r++;
              r1++;
            }
            else
            {
              sampa_config_final[t] += sampa_config_file_0f[t][r1];
              r++;
              r1++;
            }
          }
          for (int p = 1; p <= len_pedodd; p++)
          {
            if (r != (lenpedf_even[t] * 2))
            {
              sampa_config_final[t] += sampa_config_file_1f[t][r2] + ",";
              r2++;
              // j++;
              r++;
            }
            else
            {
              sampa_config_final[t] += sampa_config_file_1f[t][r2];
              r2++;
              // j++;
              r++;
            }
          }
        }
        t++;
      }
      // int  len_Badchannels = dynlen(Badchannels);
      len_pedeven = len_pedeven * 2;
        dpSet("mch_fee:OutputDataScreens.MCHSORLog", "");
        dpSet("mch_fee:OutputDataScreens.MCHSORLog", "FINAL COMMA-DELIMINATED SAMPA CONFIGURATION STRINGS FOR EACH GBT LINK BUILD");
      DebugTN("event 7: adding number of configs per board for each mode to all config strings");
      for (int l = 1; l <= len_solcrate; l++)

      {

        sampa_config_final[l] = (string)len_pedeven + "," + sampa_config_final[l];
      }


      delay(1);
      //
      /////Start of sending configurations for each cru link connected to FEC\\\\\\

      //DebugTN("sampa_config_final ",sampa_config_final);

      // configSAMPARegisters();
      t1 = getCurrentTime();

      dpSet("mch_fee:OutputDataScreens.MCHSORLog", "");
      dpSet("mch_fee:OutputDataScreens.MCHSORLog", "CONFIGURING SAMPA REGISTERS...");
      DebugTN("BEGIN CONFIGURATION OF SAMPA:");
      DebugTN("----------------------------");
      // string sampaconfinn = "0 -1 0x0e 0x05"+","+"0 -1 0x0d 0x20"+","+"0 -1 0x12 0x31"+","+"0 -1 0x07 0x11";
      //  DebugTN("sol_boards ",sampaconfinn);
      int t = 1, n2 = 1;
      for (int l = 1; l <= len_solcrate; l++)
      {
        if (INCL_DET[l][6] == 0)
        {
          dpSet(dp + sol_crates[l] + ".configSAMPA.Solar" + sol_boards[l] + ":_original.._value", sampa_config_final[l]); // sampa_config_final[l]);
                                                                                                                          //	delay(0,100);
        }
      }

      delay(15);

      for (int l = 1; l <= len_solcrate; l++)

      {
        if (INCL_DET[l][6] == 0)
        {
          // DebugTN("CONFIGRRET", l);
          bool br = true;

          while (br)
          { // DebugTN("config "+l+" sol_crates "+sol_crates[l]+ "sol_boards "+sol_boards[l]);
            t2 = getCurrentTime();
           int timestuck = minute(t2-t1);
            dpGet(dp + sol_crates[l] + ".configSAMPARet_ANS.Solar" + sol_boards[l] + ":_online.._stime", tr2);
            if (tr2 >= t1)
            {
              br = false;
              dpGet(dp + sol_crates[l] + ".configSAMPARet_ANS.Solar" + sol_boards[l] + ":_original.._value", SampaConfigReturn[l]);
            }
            if (tr1 >= t1)
            {
              br = false;
              // DebugTN("BEGIN CHECKING OF SOLAR LINK STATUS5...");
              sollvps_pc[r] = sol_lvps[b];
              solchan_pc[r] = sol_chan[b];
              solchmside_pc[r] = cham_side[b];
              sol_crates_pc[r] = sol_crates[b];
              ch_id_pc[r] = CHAMID[b];
              p++;
              r++;
            }
            else if (tr2 >= t1)
            {
              br = false;
              // DebugTN("BEGIN CHECKING OF SOLAR LINK STATUS.4..");
            }

           if (timestuck > 6)
          {
             dpSet("mch_fee:OutputDataScreens.MCHSORLog", "");
             dpSet("mch_fee:OutputDataScreens.MCHSORLog", "DIM timeout errors... exiting SOR script");

                   dpSet("mch_fee:OutputDataScreens.MCHSORLog", "");
                          dpSet("mch_fee:OutputDataScreens.MCHSORLog", "------------------------------------------");
                          dpSet("mch_fee:OutputDataScreens.MCHSORLog", "------------------------------------------");
                          dpSet("mch_fee:OutputDataScreens.MCHSORLog", "RECOVER STUCK SOR PROCEDURE");
                          dpSet("mch_fee:OutputDataScreens.MCHSORLog", "------------------------------------------");
                          dpSet("mch_fee:OutputDataScreens.MCHSORLog", "------------------------------------------");
                          dpSet("mch_fee:OutputDataScreens.MCHSORLog", "");
                          dpSet("mch_hvLvLeft:aliDcsRun_1.state", 1);
                          dpSet("mch_fee:OutputDataScreens.MCHSORLog", "RESET OF MCH DCS RUN STATE DONE!!!");
                          dpSet("mch_fee:OutputDataScreens.MCHSORLog", "");
                          dpSet("mch_fee:OutputDataScreens.MCHSORLog", "RESTARTING FREDSERVERS...");
                          dpSet("mch_fee:OutputDataScreens.MCHSORLog", "");
                           string stdoutput1,stderror1;
                          system("ssh -o StrictHostKeyChecking=no -i D:/FREDsshkeys/fred003/id_ed25519 mch@alimchfred001.cern.ch /home/mch/restart_FREDServers.sh",stdoutput1,stderror1);
                          delay(2);
                          system("ssh -o StrictHostKeyChecking=no -i D:/FREDsshkeys/fred003/id_ed25519 mch@alimchfred001.cern.ch /home/mch/restart_FREDServers.sh",stdoutput1,stderror1);
                          dpSet("mch_fee:OutputDataScreens.MCHSORLog", "  FRED001 RESTARTED!!!");
                          DebugN("stdoutput1",stdoutput1);
                          dpSet("mch_fee:OutputDataScreens.MCHSORLog",stdoutput1);
                          DebugN("stderror1",stderror1);


                          string stdoutput2,stderror2;
                          system("ssh -o StrictHostKeyChecking=no -i D:/FREDsshkeys/fred003/id_ed25519 mch@alimchfred002.cern.ch /home/mch/restart_FREDServers.sh",stdoutput2,stderror2);
                          delay(2);
                          system("ssh -o StrictHostKeyChecking=no -i D:/FREDsshkeys/fred003/id_ed25519 mch@alimchfred002.cern.ch /home/mch/restart_FREDServers.sh",stdoutput2,stderror2);
                          DebugN("stdoutput2",stdoutput2);
                          dpSet("mch_fee:OutputDataScreens.MCHSORLog", "  FRED002 RESTARTED!!!");
                          dpSet("mch_fee:OutputDataScreens.MCHSORLog",stdoutput2);
                          DebugN("stderror2",stderror2);
                          //DebugN("ans",ans);


                          string stdoutput3,stderror3;
                          system("ssh -o StrictHostKeyChecking=no -i D:/FREDsshkeys/fred003/id_ed25519 mch@alimchfred003.cern.ch /home/mch/restart_FREDServers.sh",stdoutput3,stderror3);
                          delay(2);
                          system("ssh -o StrictHostKeyChecking=no -i D:/FREDsshkeys/fred003/id_ed25519 mch@alimchfred003.cern.ch /home/mch/restart_FREDServers.sh",stdoutput3,stderror3);
                          DebugN("stdoutput3",stdoutput3);
                          dpSet("mch_fee:OutputDataScreens.MCHSORLog", "  FRED003 RESTARTED!!!");
                          dpSet("mch_fee:OutputDataScreens.MCHSORLog",stdoutput3);
                          DebugN("stderror3",stderror3);


                                dpSet("mch_fee:OutputDataScreens.MCHSORLog", "RESTART OF FREDSERVERS DONE!!!");
                                dpSet("mch_fee:OutputDataScreens.MCHSORLog", "");

                                 dpSet("mch_fee:OutputDataScreens.MCHSORLog", "");


                          delay(2);
                           dpSet("mch_fee:OutputDataScreens.MCHSORLog", "RESTARTING WINCC-OA MANAGERS...");

                                  // script

                          string serverName = "alidcssrv047";
                          /*string searchCriteria1 = "WCCOAdim;2;30;2;2;-num 16 -dim_dns_node alimchfred001.cern.ch -dim_dp_config DimFRED1";
                          string searchCriteria2 = "WCCOAdim;2;30;2;2;-num 17 -dim_dns_node alimchfred002.cern.ch -dim_dp_config DimFRED2";
                          string searchCriteria3 = "WCCOAdim;2;30;2;2;-num 18 -dim_dns_node alimchfred003.cern.ch -dim_dp_config DimFRED3";
                          string searchCriteria4 = "WCCOActrl;0;30;2;2;-num 7 mchConfigSampa/CheckClockChange.ctl";*/


                          int handle;
                          string str, line;
                          dyn_string params, list;
                          dyn_errClass err;
                          dyn_int manNumber=makeDynInt(26,31,32,33);
                          /* Initialise TCP connection with PMON manager */
                          handle = tcpOpen(serverName, 4999);
                          err = getLastError();
                          if ( dynlen(err) >= 1 ){
                          if ( handle != -1 )
                          tcpClose(handle);
                          throwError(err);
                          if(myManType()==UI_MAN){errorDialog(err);}
                          DebugTN("Can't reach the remote host");

                          }

                          /* Find manager */

                          line = my_pmon_write(handle, "", "", "MGRLIST:LIST");
                          list = stringToDynString(line, "\n");
                          DebugTN("line",line);
                          DebugTN("list",list);
                          int lenmanNumber =dynlen(manNumber);

                          DebugTN("manNumber",manNumber);

                          // Option (long one) //
                          for (int i=1;i<=lenmanNumber;i++)
                          {
                          if(false){
                          if(sscanf(strsplit(list[1],":")[2], "%d", manNumber[i])<0){
                          DebugTN("Bad string request");

                          return;
                          }

                          }
                          if(manNumber[i] < 1){
                          DebugTN("Manager not found");
                          return;
                          }
                          DebugTN("manNumber2",manNumber[i]);

                          // DebugTN(list, manNumber, my_pmon_write(handle, "", "", "SINGLE_MGR:PROP_GET "+manNumber));

                          // Read parameters for defined manager and change startup property to proper one //

                          if(true){

                          line = my_pmon_write(handle, "", "", "SINGLE_MGR:PROP_GET "+manNumber[i]);
                          params = strsplit(line, " ");
                          params[1] = "always"; // change "autostart" property to manual/always
                          line = my_pmon_write(handle, "", "", "SINGLE_MGR:PROP_PUT "+manNumber[i]+" "+dynStringToString(params, " ")); // Write property back
                          // if manager should be stopped:
                          if(true){
                          line = my_pmon_write(handle, "", "", "SINGLE_MGR:STOP "+manNumber[i]); // Now we can stop manager

                          if(!strpos(line, "OK")){
                          DebugTN("FSM Manager stopped and resterted");
                          }
                          } // No need to start manager, because it will start automatically when property will be changed to always
                          else{
                          DebugTN("");
                          }
                          }
                          }
                          // End part. Closing connections. //
                          tcpClose(handle);




                          delay(2);
                                dpSet("mch_fee:OutputDataScreens.MCHSORLog", "RESTART OF WINCC-OA MANAGERS DONE!!!");
                                delay(2);
                                dpSet("mch_fee:OutputDataScreens.MCHSORLog", "");

                                dpSet("mch_fee:mchUseCurrentConfig.UseCurrentRunType:_original.._value", "");
                                  dpSet("mch_fee:mchUseCurrentConfig.UseCurrentTriggerMode:_original.._value", "");
                                  dpSet("mch_fee:mchUseCurrentConfig.UseCurrentCSum:_original.._value", "");
                          dpSet("mch_fee:OutputDataScreens.MCHSORLog", "RESET OF LAST RUNTYPE VALUES DONE!!!");
                                dpSet("mch_fee:OutputDataScreens.MCHSORLog", "");
                                dpSet("mch_fee:OutputDataScreens.MCHSORLog", "------------------------------------------");
                                dpSet("mch_fee:OutputDataScreens.MCHSORLog", "------------------------------------------");
                                dpSet("mch_fee:OutputDataScreens.MCHSORLog", "END OF RECOVER STUCK SOR PROCEDURE");
                                dpSet("mch_fee:OutputDataScreens.MCHSORLog", "------------------------------------------");
                                dpSet("mch_fee:OutputDataScreens.MCHSORLog", "------------------------------------------");
                                return;

          }
          }
          dpGet(dp + sol_crates[l] + ".configSAMPARet_ANS.Solar" + sol_boards[l] + ":_original.._value", SampaConfigReturn[l]);

        }
      }
      for (int l = 1; l <= len_solcrate; l++)
      {
        if (SampaConfigReturn[l] == "")
        {
          SAMPABoardReturn[l] = "nO aNSWER failure";
        }
        else
        {
          SAMPABoardReturn[l] = strsplit(SampaConfigReturn[l], " ");
        }
      }
      // DebugTN("SAMPABoardReturn: ", SAMPABoardReturn);

      int s = 1;
      for (int l = 1; l <= len_solcrate; l++)
      {
        if (INCL_DET[l][6] == 0)
        {
          if (dynContains(SAMPABoardReturn[l], "failure") && dynCount(SAMPABoardReturn[l], "failure") == dynlen(SAMPABoardReturn[l]))
          {
            // SAMPAfail[l][1] = "failure";
            //	dpSet("mch_fee:OutputDataScreens.MCHSORLog","       All configurations of SAMPA chips connected to CH"+ch_id[l]+ch_side[l]+" CRU "+(string)cru_IDS[l]+" link "+(string)cru_links[l], " failed");
            //		DebugTN("       All configurations of SAMPA chips connected to CH"+ch_id[l]+ch_side[l]+" CRU "+(string)cru_IDS[l]+" link "+(string)cru_links[l], " failed");
            //		DebugTN("----------------------------");
            SAMPAfailcheck[l] = 1;
            s++;
          }
          else if (dynContains(SAMPABoardReturn[l], "failure") && dynCount(SAMPABoardReturn[l], "failure") < dynlen(SAMPABoardReturn[l])) //&& dynCount(SampaConfigReturn[l],"failure") > 22)
          {
         //   dpSet("mch_fee:OutputDataScreens.MCHSORLog", "       Some SAMPA chips failed to configure for CH" + ch_id[l] + ch_side[l] + " CRU" + cru_IDS[l] + " LINK " + cru_links[l] + "!!");
            //	 DebugTN("               Some SAMPA chips failed to configure for CH"+ch_id[l]+ch_side[l]+" CRU"+cru_IDS[l]+" LINK "+cru_links[l]+"!!");
            //			DebugTN("----------------------------");
            SAMPAfailcheck[l] = 1;
            s++;
          }
          else if (dynContains(SAMPABoardReturn[l], "success") && (dynCount(SAMPABoardReturn[l], "success") == dynlen(SAMPABoardReturn[l])))
          {
            //	dpSet("mch_fee:OutputDataScreens.MCHSORLog","Successfully configured ALL SAMPA chips for CH"+ch_id[l]+ch_side[l]+" CRU"+cru_IDS[l]+" LINK "+cru_links[l]+"!!");
            //	DebugTN("Successfully configured all SAMPA chips for CH"+ch_id[l]+ch_side[l]+" CRU"+cru_IDS[l]+" LINK "+cru_links[l]+"!!");
            //	DebugTN("----------------------------");
            INCL_DET[l][6] = 1;
            SAMPAfailcheck[l] = 0;
            s++;
          }
          else if (dynContains(SAMPABoardReturn[l], "") && (dynCount(SAMPABoardReturn[l], "") == dynlen(SAMPABoardReturn[l]))) //&& dynCount(SampaConfigReturn[l],"failure") > 22)
          {
            dpSet("mch_fee:OutputDataScreens.MCHSORLog", "       All SAMPA chips failed to configure for CH" + ch_id[l] + ch_side[l] + " CRU" + cru_IDS[l] + " LINK " + cru_links[l] + "NO REPLIES FORM ALF");
            DebugTN("               Some SAMPA chips failed to configure for CH" + ch_id[l] + ch_side[l] + " CRU" + cru_IDS[l] + " LINK " + cru_links[l] + "NO REPLIES FORM ALF");
            DebugTN("----------------------------");
            SAMPAfailcheck[l] = 1;
            s++;
          }
          else if (dynContains(SAMPABoardReturn[l], "0") && (dynCount(SAMPABoardReturn[l], "0") == dynlen(SAMPABoardReturn[l])))
          {
          //  dpSet("mch_fee:OutputDataScreens.MCHSORLog", "       All SAMPA chips failed to configure for CH" + ch_id[l] + ch_side[l] + " CRU" + cru_IDS[l] + " LINK " + cru_links[l] + "ALF-FRED SERVER DOWN");
            dpSet("mch_fee:OutputDataScreens.MCHSORLog", "ALF-FRED SERVER DOWN");
            //	DebugTN("               ALF-fred DOWN "+ch_id[l]+ch_side[l]+" CRU"+cru_IDS[l]+" LINK "+cru_links[l]);
            //	DebugTN("----------------------------");
            SAMPAfailcheck[l] = 1;
            s++;
          }
        }
        else if (INCL_DET[l][6] == 1)
        {
          SAMPAfailcheck[l] = 0;
        }
      }
      // DebugTN("boardList: ", boardList);

      // Check reply from ALF for SAMPA configs to see which boards configured correctly
      for (int l = 1; l <= len_solcrate; l++)
      {
        int r = 1;

        for (int k = 1; k <= board_count[l]; k++)
        {
          if (boardList[l][k] == "1")
          { // DebugTN ("enter 1");
            if (SAMPABoardReturn[l][r] == "success")
            { // DebugTN ("enter 2");
              SAMPABoardReturnFinal[l][k] = SAMPABoardReturn[l][r];

              // DebugTN("boardList: ", boardList);

              r++;
            }
            else if (SAMPABoardReturn[l][r] == "failure")
            {
              SAMPABoardReturnFinal[l][k] = SAMPABoardReturn[l][r];
              // DebugTN("SAMPABoardReturnFinal2: ", SAMPABoardReturnFinal[l][k]);
              r++;
            }
            else if (SAMPABoardReturn[l][r] == "NoALFReply")
            {
              SAMPABoardReturnFinal[l][k] = SAMPABoardReturn[l][r];
              // DebugTN("SAMPABoardReturnFinal3: ", SAMPABoardReturnFinal[l][k]);
              r++;
            }
          }
          else if (boardList[l][k] == "0")
          { // DebugTN ("enter 2");
            SAMPABoardReturnFinal[l][k] = "NotConn";
          }
        }
      }

      //   DebugTN ("SAMPABoardReturnFinal",SAMPABoardReturnFinal);
      //   DebugTN ("boardList",boardList);
      //    DebugTN ("board_count",board_count);
      int k = 1;

      for (int l = 1; l <= len_solcrate; l++)
      {
        k = board_count[l] + 1;

        while (k < 41)
        {
          SAMPABoardReturnFinal[l][k] = "NotConn";
          k++;
        }
        // DebugTN ("SAMPABoardReturnFinal length 2",dynlen(SAMPABoardReturnFinal[l]));
      }
      // DebugTN ("SAMPABoardReturnFinal length 2",dynlen(SAMPABoardReturnFinal[l]));

      for (int l = 1; l <= len_solcrate; l++)
      {
        int s = 1;
        int r = 1, t = 1;
        for (int k = 0; k <= 39; k++)
        {

          // DebugTN("sol_boards link ",sol_boards[l], "sampa_config_final ", sampa_config_final[l][n1]);
          if (SAMPABoardReturnFinal[l][t] == "failure") // checks when ALF sends "failure" string - else it will send 'success'
          {
            // DebugTN("sampa_config_file_fin ",sampa_config_final[l][n1]);

            Solconn[s] = (k / 5) + 1;
            DSboard[s] = (k % 5) / 2;

            // DebugTN("Solconn ",Solconn);
            // DebugTN("DSboard ",DSboard);
            SAMPAfail[l][s] = "CH" + (string)ch_id[l] + ch_side[l] +" DE" + slatID[l]+ " CRU " + (string)cru_IDS[l] + " link " + (string)cru_links[l] + "  J" + (string)Solconn[s] + "  DS" + (string)DSboard[s] + " Failed";
            s++;
          }
          if (SAMPABoardReturnFinal[l][t] == "NoALFReply")
          {
            // DebugTN("sampa_config_file_fin ",sampa_config_final[l][n1]);
            Solconn[s] = (k / 5) + 1;
            DSboard[s] = (k % 5) / 2;

            SAMPAfailnoreply[l][r] = "CH" + (string)ch_id[l] + ch_side[l] + " DE" + slatID[l] + " CRU " + (string)cru_IDS[l] + " link " + (string)cru_links[l] + "  J" + (string)Solconn[s] + "  DS" + (string)DSboard[s] + " got no reply from ALF ";
            r++;
            s++;
          }
          if (SAMPABoardReturnFinal[l][t] == "NotConn")
          {
            // DebugTN("sampa_config_file_fin ",sampa_config_final[l][n1]);
            r++;
            s++;
            SAMPAfail[l][s] = "";
            s++;
          }

          if (SAMPABoardReturnFinal[l][t] == "success")
          {
            SAMPApass[l][s] = "success";
            SAMPAfail[l][s] = "";
            s++;
          }
          t++;
        }
         //DebugTN(" DSboard ",DSboard);
      }
      // DebugTN("SAMPApass: ", SAMPApass);
      // DebugTN("SAMPAfailnoreply: ", SAMPAfailnoreply);
      // DebugTN("SAMPAfail: ", SAMPAfail);
      // DebugTN("DSboard: ", DSboard);
      // DebugTN("Solconn: ", Solconn);
      dpSet("mch_fee:OutputDataScreens.SAMPABoardVisual", "");
      /* string dp = "Reconfigure";
       string dpt2 = "mchReconfigure";
       int rc, sc;

       // rc=dpDelete(dp);
       delay(1);
       sc = dpCreate(dp, dpt2);
 */
      for (int l = 1; l <= len_solcrate; l++)
      {
        strjoin(SAMPABoardReturnFinal[l], " ");
      }

      for (int l = 1; l <= len_solcrate; l++)
      {
        SAMPABoardReturnFinal[l] = "CH" + ch_id[l] + ch_side[l] + " " + sol_crates[l] + " S" + sol_id[l] + " DE" + slatID[l] + " " + SAMPABoardReturnFinal[l];
      }
      dpSet("mch_fee:OutputDataScreens.SAMPABoardVisual", SAMPABoardReturnFinal);
      // DebugTN("incl_det",INCL_DET);
int totalconfigured = 0, totalboards = 0, failedBoards = 0;
 for (int l = 1; l <= len_solcrate; l++)
      {
        for (int k = 1; k <= dynlen(SAMPABoardReturn[l]); k++)
        {

          if (SAMPABoardReturn[l][k] == "success")
          {
            totalconfigured++;
          }
        }
        totalboards += dynlen(SAMPABoardReturn[l]);
      }
     // dbCommand tempTable_cmd;
      // Insert included items into tmp table in DB
      //   if (sel_run =="NewRun")

      //

      /*  fwDbStartCommand(dbCon, "UPDATE INCL_DETECTORS SET SOLAR_FLAG=:pass_inclparams1,GBT_FLAG=:pass_inclparams2,SAMPA_FLAG=:pass_inclparams3 WHERE DS_CHAMBERS =:pass_inclparams4 and DS_CHILDREN = :pass_inclparams5 and DS_SOLARFSM = :pass_inclparams6", tempTable_cmd);
        if (fwDbCheckError(errMsg, tempTable_cmd))
        {
          DebugTN("ERROR: fwDbStartCommand ", errMsg);
          return;
        }

        dyn_dyn_mixed pass_inclparams;
        for (int i = 1; i <= len_links; i++)
        {
          pass_inclparams[i][1] = INCL_DET[i][4];
          pass_inclparams[i][2] = INCL_DET[i][5];
          pass_inclparams[i][3] = INCL_DET[i][6];
          pass_inclparams[i][4] = INCL_DET[i][1];
          pass_inclparams[i][5] = INCL_DET[i][2];
          pass_inclparams[i][6] = INCL_DET[i][3];

          // pass_inclparams[i][2] = dschild[i];
        }
        fwDbBindAndExecute(tempTable_cmd, pass_inclparams);
        if (fwDbCheckError(errMsg, tempTable_cmd))
        {
          DebugTN("ERROR: fwDbBindAndExecute ", errMsg);
          return;
        }*/

       if (dynCount(SAMPAfailcheck, "0") != len_links)
      {


        dpSet("mch_fee:OutputDataScreens.MCHSORLog", "");
        dpSet("mch_fee:OutputDataScreens.MCHSORLog", "SAMPA CONFIGURATION COMPLETED WITH BELOW ERRROS: ");

        for (int t = 1; t <= len_solcrate; t++)
        {
          for (int l = 1; l <= dynlen(SAMPAfail[t]); l++)
          {
            if (SAMPAfail[t][l] != "" && SAMPAfail[t][l] != "|")
            {
              dpSet("mch_fee:OutputDataScreens.MCHSORLog", "  " + SAMPAfail[t][l]);
            }
          }
        }
        dpSet("mch_fee:OutputDataScreens.MCHSORLog", "");
          failedBoards = totalboards - totalconfigured;
        dpSet("mch_fee:OutputDataScreens.MCHSORLog", "DS boards configured: " + totalconfigured + "/" + totalboards);
        DebugTN("DS boards configured: " + totalconfigured + "/" + totalboards);
        dpSet("mch_fee:OutputDataScreens.MCHSORLog", "DS boards failed: " + failedBoards + "/" + totalboards);
        DebugTN("DS boards failed: " + failedBoards + "/" + totalboards);

      }
       else
      {

        dpSet("mch_fee:OutputDataScreens.MCHSORLog", "SAMPA CONFIGURATION FOR ALL SAMPA COMPLETED WITH NO ERRORS!!!");
         dpSet("mch_fee:OutputDataScreens.MCHSORLog", "");
          failedBoards = totalboards - totalconfigured;
        dpSet("mch_fee:OutputDataScreens.MCHSORLog", "DS boards configured: " + totalconfigured + "/" + totalboards);
        DebugTN("DS boards configured: " + totalconfigured + "/" + totalboards);
        dpSet("mch_fee:OutputDataScreens.MCHSORLog", "DS boards failed: " + failedBoards + "/" + totalboards);
        DebugTN("DS boards failed: " + failedBoards + "/" + totalboards);

      }

      // Check reply from ALF for SAMPA configs to see which boards configured correctly


      if ((runType == "PEDESTALS") || (UseCurrentRunType == "PEDESTALS"))
      {
        // DebugTN("sel_config: 1");

        cru_config_trigger = "0x3C0F03C0F03C0F03C0F0,0x0F03C0F03C0F03C0F03C,0x0C0300C0300C0300C030,1,0,3000,12,4,false,false,false";
        for (int i = 1; i <= dynlen(CRUConfig_cruids); i++)
        {
          dpSet("mch_fee:CRUConfig." + CRUConfig_flpids[i] + "C" + CRUConfig_cruids[i] + ":_original.._value", cru_config_trigger);
        }
        dpSet("mch_fee:OutputDataScreens.MCHSORLog", "");
        dpSet("mch_fee:OutputDataScreens.MCHSORLog", "CONFIGURATION OF ALL CRUs FOR TRIGGERS WITH UL ENABLED DONE");
      }
      // PHYSICS CONTINUOUS csum
      if (((runType == "PHYSICS" || runType == "TECHNICAL" || runType == "COSMICS") && clusterSum == TRUE) || ((UseCurrentRunType == "PHYSICS" || UseCurrentRunType == "TECHNICAL" || UseCurrentRunType == "COSMICS") && UseCurrentCSum == TRUE))
      {
        DebugTN("sel_config: 2");
        cru_config_trigger = "0x0FC3F0FC3F0FC3F0FC3F,0x0F03C0F03C0F03C0F03C,0x0C0300C0300C0300C030,1,0,3000,12,11,false,false,false";
        for (int i = 1; i <= dynlen(CRUConfig_cruids); i++)
        {
          dpSet("mch_fee:CRUConfig." + CRUConfig_flpids[i] + "C" + CRUConfig_cruids[i] + ":_original.._value", cru_config_trigger);
        }
        dpSet("mch_fee:OutputDataScreens.MCHSORLog", "");
        dpSet("mch_fee:OutputDataScreens.MCHSORLog", "CONFIGURATION OF ALL CRUs FOR TRIGGERS WITH UL AND CSUM ENABLED DONE");
      }
      DebugTN("cru_config_trigger: ", cru_config_trigger);

      dyn_string WriteULLinksEnabled = "0x00000000", WriteULLinksDisabled = "0x0FFF0FFF", WriteCRURegLink = "0x00c80008";
      //	WriteCRUReg
      for (int i = 1; i <= dynlen(CRUConfig_cruids); i++)
      {
        // dpSet("mch_fee:CRURegisterWrite." + CRUConfig_flpids[i] + "C" + CRUConfig_cruids[i] + ":_original.._value", WriteCRURegLink);
        dpSet("mch_fee:CRURegisterWrite." + CRUConfig_flpids[i] + "C" + CRUConfig_cruids[i] + ":_original.._value", WriteCRURegLink + "," + WriteULLinksEnabled);
      }
      dpSet("mch_fee:OutputDataScreens.MCHSORLog", "");
      dpSet("mch_fee:OutputDataScreens.MCHSORLog", "SET LINK PATTERN FOR ALL CRUs TO " + WriteULLinksEnabled);
      if (dynCount(SAMPAfailcheck, "0") != len_links)
      {
        dpSet("mch_hvLvLeft:aliDcsRun_1.state", 1);
        dpSet("mch_fee:OutputDataScreens.MCHSORLog", "");

        dpSet("mch_fee:OutputDataScreens.MCHSORLog", "------------------------------------");
        dpSet("mch_fee:OutputDataScreens.MCHSORLog", " END OF FEE CONFIGURATION");
        dpSet("mch_fee:OutputDataScreens.MCHSORLog", "------------------------------------");

        dpSet("mch_fee:OutputDataScreens.MCHSORLog", "");
        if (state == 2)
        {
           dpGet("mch_hvLvLeft:aliDcsRun_1.runType:_original.._stime", sortime);
        dpSet("mch_fee:mchUseCurrentConfig.ProcTime:_original.._value", (string)sortime);

          dpSet("mch_fee:OutputDataScreens.MCHSORLog", "SUMMARY OF SOR:");
          dpSet("mch_fee:OutputDataScreens.MCHSORLog", "    RUN NUMBER = " + runNumber);
          if (runType == "PHYSICS" || runType == "TECHNICAL" || runType == "COSMICS")
          {
            dpSet("mch_fee:mchUseCurrentConfig.Procedure:_original.._value", "FULL SOR ("+runNumber+" - "+runType + " IN " + triggerMode + " MODE WITH CSUM " + CSUM+")");
           dpSet("mch_fee:mchUseCurrentConfig.LastRunNumber:_original.._value", runNumber);
            dpSet("mch_fee:OutputDataScreens.MCHSORLog", "    RUN DESCRIPTION = " + runType + " IN " + triggerMode + " MODE WITH CSUM " + CSUM);
          }
          else if (runType == "PEDESTALS")
          {
            dpSet("mch_fee:mchUseCurrentConfig.Procedure:_original.._value", "FULL SOR ("+runNumber+" - "+runType+")");
           dpSet("mch_fee:mchUseCurrentConfig.LastRunNumber:_original.._value", runNumber);

            dpSet("mch_fee:OutputDataScreens.MCHSORLog", "    RUN DESCRIPTION = " + runType);
          }
          dpSet("mch_fee:OutputDataScreens.MCHSORLog", "    MCH STATE MOVED TO RUN OK - FULL CONFIGURATION DONE");
          dpSet("mch_fee:OutputDataScreens.MCHSORLog", "");

          dpSet("mch_fee:OutputDataScreens.MCHSORLog", "------------------------------------------------");
          dpSet("mch_fee:OutputDataScreens.MCHSORLog", "------------------------------------------------");
          dpSet("mch_fee:OutputDataScreens.MCHSORLog", "END OF SOR PROGRESSING");
          dpSet("mch_fee:OutputDataScreens.MCHSORLog", "------------------------------------------------");
          dpSet("mch_fee:OutputDataScreens.MCHSORLog", "------------------------------------------------");
        }
        else
        {


      dpGet("mch_hvLvLeft:LHCClock.TTCMI/MICLOCK_TRANSITION:_original.._stime", clocktime);
      dpSet("mch_fee:mchUseCurrentConfig.ProcTime:_original.._value", (string)clocktime);
          dpSet("mch_fee:OutputDataScreens.MCHSORLog", "SUMMARY OF CLOCK TRANSTION:");

          if (UseCurrentRunType == "PHYSICS" || UseCurrentRunType == "TECHNICAL" || UseCurrentRunType == "COSMICS")
          {
                      dpSet("mch_fee:mchUseCurrentConfig.Procedure:_original.._value", "CLK_TRANSITION ("+UseCurrentRunType + " IN " + UseCurrentTriggerMode + " MODE WITH CSUM " + CSUM+")");
            dpSet("mch_fee:OutputDataScreens.MCHSORLog", "    LAST KNOWN RUNTYPE  = " + UseCurrentRunType + " IN " + UseCurrentTriggerMode + " MODE WITH CSUM " + CSUM);
          }
          else if (UseCurrentRunType == "PEDESTALS")
          {
                      dpSet("mch_fee:mchUseCurrentConfig.Procedure:_original.._value", "CLK_TRANSITION ("+UseCurrentRunType +")");
            dpSet("mch_fee:OutputDataScreens.MCHSORLog", "    LAST KNOWN RUNTYPE   = " + UseCurrentRunType);
          }
          dpSet("mch_fee:OutputDataScreens.MCHSORLog", "    FULL CONFIGURATION DONE FOR LAST KNOWN RUNTYPE");
          dpSet("mch_fee:OutputDataScreens.MCHSORLog", "");
          dpSet("mch_fee:OutputDataScreens.MCHSORLog", "---------------------------------------");
          dpSet("mch_fee:OutputDataScreens.MCHSORLog", "---------------------------------------");
          dpSet("mch_fee:OutputDataScreens.MCHSORLog", "END OF CLOCK TRANSITION PROCEDURE");
          dpSet("mch_fee:OutputDataScreens.MCHSORLog", "---------------------------------------");
          dpSet("mch_fee:OutputDataScreens.MCHSORLog", "---------------------------------------");
        }

        dpSet("mch_fee:OutputDataScreens.MCHSORLog", "");
      }
      else
      {
        dpSet("mch_hvLvLeft:aliDcsRun_1.state", 1);
        dpSet("mch_fee:OutputDataScreens.MCHSORLog", "");

        dpSet("mch_fee:OutputDataScreens.MCHSORLog", "------------------------------------");
        dpSet("mch_fee:OutputDataScreens.MCHSORLog", " END OF FEE CONFIGURATION");
        dpSet("mch_fee:OutputDataScreens.MCHSORLog", "------------------------------------");
        dpSet("mch_fee:OutputDataScreens.MCHSORLog", "");
        if (state == 2)
        {
           dpGet("mch_hvLvLeft:aliDcsRun_1.runType:_original.._stime", sortime);
        dpSet("mch_fee:mchUseCurrentConfig.ProcTime:_original.._value", (string)sortime);
          dpSet("mch_fee:OutputDataScreens.MCHSORLog", "SUMMARY OF SOR:");
          dpSet("mch_fee:OutputDataScreens.MCHSORLog", "    RUN NUMBER = " + runNumber);
          if (runType == "PHYSICS" || runType == "TECHNICAL" || runType == "COSMICS")
          {
            dpSet("mch_fee:mchUseCurrentConfig.Procedure:_original.._value", "FULL SOR ("+runNumber+" - "+runType + " IN " + triggerMode + " MODE WITH CSUM " + CSUM+")");
           dpSet("mch_fee:mchUseCurrentConfig.LastRunNumber:_original.._value", runNumber);

            dpSet("mch_fee:OutputDataScreens.MCHSORLog", "    RUN DESCRIPTION = " + runType + " IN " + triggerMode + " MODE WITH CSUM " + CSUM);
          }
          else if (runType == "PEDESTALS")
          {
            dpSet("mch_fee:mchUseCurrentConfig.Procedure:_original.._value", "FULL SOR ("+runNumber+" - "+runType+")");
           dpSet("mch_fee:mchUseCurrentConfig.LastRunNumber:_original.._value", runNumber);

            dpSet("mch_fee:OutputDataScreens.MCHSORLog", "    RUN DESCRIPTION = " + runType);
          }
          dpSet("mch_fee:OutputDataScreens.MCHSORLog", "    MCH STATE MOVED TO RUN OK - FULL CONFIGURATION DONE");
          dpSet("mch_fee:OutputDataScreens.MCHSORLog", "");
          dpSet("mch_fee:OutputDataScreens.MCHSORLog", "------------------------------------------------");
          dpSet("mch_fee:OutputDataScreens.MCHSORLog", "------------------------------------------------");
          dpSet("mch_fee:OutputDataScreens.MCHSORLog", "END OF SOR PROGRESSING");
          dpSet("mch_fee:OutputDataScreens.MCHSORLog", "------------------------------------------------");
          dpSet("mch_fee:OutputDataScreens.MCHSORLog", "------------------------------------------------");
        }
        else
        {
          dpSet("mch_fee:OutputDataScreens.MCHSORLog", "");
          dpSet("mch_fee:OutputDataScreens.MCHSORLog", "SUMMARY OF CLOCK TRANSTION:");
 dpGet("mch_hvLvLeft:LHCClock.TTCMI/MICLOCK_TRANSITION:_original.._stime", clocktime);
      dpSet("mch_fee:mchUseCurrentConfig.ProcTime:_original.._value", (string)clocktime);
          if (UseCurrentRunType == "PHYSICS" || UseCurrentRunType == "TECHNICAL" || UseCurrentRunType == "COSMICS")
          {
                              dpSet("mch_fee:mchUseCurrentConfig.Procedure:_original.._value", "CLK_TRANSITION ("+UseCurrentRunType + " IN " + UseCurrentTriggerMode + " MODE WITH CSUM " + CSUM+")");
            dpSet("mch_fee:OutputDataScreens.MCHSORLog", "    LAST KNOWN RUNTYPE  = " + UseCurrentRunType + " IN " + UseCurrentTriggerMode + " MODE WITH CSUM " + CSUM);
          }
          else if (UseCurrentRunType == "PEDESTALS")
          {
                                  dpSet("mch_fee:mchUseCurrentConfig.Procedure:_original.._value", "CLK_TRANSITION ("+UseCurrentRunType +")");
            dpSet("mch_fee:OutputDataScreens.MCHSORLog", "    LAST KNOWN RUNTYPE  = " + UseCurrentRunType);
          }
          dpSet("mch_fee:OutputDataScreens.MCHSORLog", "    FULL CONFIGURATION DONE FOR LAST KNOWN RUNTYPE");
          dpSet("mch_fee:OutputDataScreens.MCHSORLog", "");

          dpSet("mch_fee:OutputDataScreens.MCHSORLog", "---------------------------------------");
          dpSet("mch_fee:OutputDataScreens.MCHSORLog", "---------------------------------------");
          dpSet("mch_fee:OutputDataScreens.MCHSORLog", "END OF CLOCK TRANSITION PROCEDURE");
          dpSet("mch_fee:OutputDataScreens.MCHSORLog", "---------------------------------------");
          dpSet("mch_fee:OutputDataScreens.MCHSORLog", "---------------------------------------");
        }
        dpSet("mch_fee:OutputDataScreens.MCHSORLog", "");
      }

      // dyn_string SampaConfigReturn;

      time t2 = getCurrentTime();

      // DebugTN("SampaConfigReturn: ", sampa_config_final);
      //	DebugTN("SAMPABoardReturn: ", SAMPABoardReturn);

      // DebugTN ("sampa_config_final with nreg ",sampa_config_final);
      // dpSet("mch_fee:OutputDataScreens.MCHSORLog", "");
      DebugTN("----------------------------");
      //	DebugTN("SampaConfigReturn ",SampaConfigReturn);
      DebugTN("SampaConfigReturn ", SampaConfigReturn);
     // DebugTN("SAMPAfailnoreply: ", SAMPAfail);

      DebugTN("----------------------------");

      DebugTN("----------------------------");
      DebugTN("Start time: ", (string)t2);
      DebugTN("Endtime: ", (string)t1);
      //	DebugTN ("Sampa fail ",SAMPAfailcheck);

      // configureCRUforTriggers();
      // PEDESTAL

      if (runType != "")
      {
        dpSet("mch_fee:mchUseCurrentConfig.UseCurrentRunType:_original.._value", runType);
        dpSet("mch_fee:mchUseCurrentConfig.UseCurrentTriggerMode:_original.._value", triggerMode);
        dpSet("mch_fee:mchUseCurrentConfig.UseCurrentCSum:_original.._value", clusterSum);
      }

      dpSet("mch_fee:OutputDataScreens.MCHSORLog", "");
    }
    else if (state == 2 && (UseCurrentRunType == runType))
    {
      dpGet("mch_hvLvLeft:aliDcsRun_1.runType:_original.._stime", sortime);
        dpSet("mch_fee:mchUseCurrentConfig.ProcTime:_original.._value", (string)sortime);
      dpSet("mch_fee:OutputDataScreens.MCHSORLog", "FEE ALREADY CONFIGURED FOR CURRENT RUNTYPE!!! ");
      dpSet("mch_hvLvLeft:aliDcsRun_1.state", 1);
      dpSet("mch_fee:OutputDataScreens.MCHSORLog", "");
      dpSet("mch_fee:OutputDataScreens.MCHSORLog", "SUMMARY OF SOR:");
      dpSet("mch_fee:OutputDataScreens.MCHSORLog", "    RUN NUMBER = " + runNumber);
      if (runType == "PHYSICS" || runType == "TECHNICAL" || runType == "COSMICS")
      {
                    dpSet("mch_fee:mchUseCurrentConfig.Procedure:_original.._value", "FAST SOR ("+runNumber+" - "+runType + " IN " + triggerMode + " MODE WITH CSUM " + CSUM+")");
        dpSet("mch_fee:OutputDataScreens.MCHSORLog", "    RUN DESCRIPTION = " + runType + " IN " + triggerMode + " MODE WITH CSUM " + CSUM);
      }
      else if (runType == "PEDESTALS")
      {
                            dpSet("mch_fee:mchUseCurrentConfig.Procedure:_original.._value", "FAST SOR ("+runNumber+" - "+runType +")");
        dpSet("mch_fee:OutputDataScreens.MCHSORLog", "    RUN DESCRIPTION = " + runType);
      }
      dpSet("mch_fee:OutputDataScreens.MCHSORLog", "    MCH STATE MOVED TO RUN OK - USING EXISTING CONFIGURATION");
      dpSet("mch_fee:OutputDataScreens.MCHSORLog", "");
      dpSet("mch_fee:OutputDataScreens.MCHSORLog", "------------------------------------------------");
      dpSet("mch_fee:OutputDataScreens.MCHSORLog", "------------------------------------------------");
      dpSet("mch_fee:OutputDataScreens.MCHSORLog", "END OF SOR PROGRESSING");
      dpSet("mch_fee:OutputDataScreens.MCHSORLog", "------------------------------------------------");
      dpSet("mch_fee:OutputDataScreens.MCHSORLog", "------------------------------------------------");
      dpSet("mch_fee:OutputDataScreens.MCHSORLog", "");
      dpSet("mch_fee:OutputDataScreens.MCHSORLog", "");
    }
  }
  else if ((state == 2 && runType != "PEDESTALS") || (state == 2 && (runType != "PHYSICS" || runType != "TECHNICAL") && triggerMode == ""))
  {
    dpSet("mch_fee:OutputDataScreens.MCHSORLog", "");
    dpSet("mch_fee:OutputDataScreens.MCHSORLog", "MCH SOR parameters not provided!!!");
    dpSet("mch_hvLvLeft:aliDcsRun_1.state", 1);
    dpSet("mch_fee:OutputDataScreens.MCHSORLog", "");
    dpSet("mch_fee:OutputDataScreens.MCHSORLog", "SUMMARY OF SOR:");
    dpSet("mch_fee:OutputDataScreens.MCHSORLog", "    RUN NUMBER = " + runNumber);
    if (runType == "PHYSICS" || runType == "TECHNICAL" || runType == "COSMICS")
    {
      dpSet("mch_fee:OutputDataScreens.MCHSORLog", "    RUN DESCRIPTION = " + runType + " IN " + triggerMode + " MODE WITH CSUM " + CSUM);
    }
    else if (runType == "PEDESTALS")
    {
      dpSet("mch_fee:OutputDataScreens.MCHSORLog", "    RUN DESCRIPTION = " + runType);
    }
    dpSet("mch_fee:OutputDataScreens.MCHSORLog", "    MCH STATE MOVED TO RUN OK - FEE NOT CONFIGURED DUE TO MISSING SOR PARAMETERS FROM AliECS");
    dpSet("mch_fee:OutputDataScreens.MCHSORLog", "");
    dpSet("mch_fee:OutputDataScreens.MCHSORLog", "------------------------------------------------");
    dpSet("mch_fee:OutputDataScreens.MCHSORLog", "------------------------------------------------");
    dpSet("mch_fee:OutputDataScreens.MCHSORLog", "END OF SOR PROGRESSING");
    dpSet("mch_fee:OutputDataScreens.MCHSORLog", "------------------------------------------------");
    dpSet("mch_fee:OutputDataScreens.MCHSORLog", "------------------------------------------------");
    dpSet("mch_fee:OutputDataScreens.MCHSORLog", "");
    dpSet("mch_fee:OutputDataScreens.MCHSORLog", "");
  }
  fwDbOption("Reset", 0);
  //fwDbCloseConnection(dbCon);

}
string my_pmon_write(int handle, string user, string pass, string command){
string str, line;
dyn_errClass err;
int ret;
string cmd;
if(strlen(user)){
cmd = user+"#"+pass+"#"+command+"\n"; // get manager properties
}
else{
cmd = "##"+command+"\n"; // get manager properties
}
ret = tcpWrite(handle, cmd);
err = getLastError();
if ((ret == -1) || (dynlen(err) >= 1)) //Error in tcpWrite
{
throwError(err);
return("");
}
line = "";
do{
str = "";
tcpRead(handle, str, 5);
line += str;
}while(str!="");
return line;
}

