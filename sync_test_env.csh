#-------------------------------------------------------------------
#  Script name     : sync_test_env.csh
#  Purpose         : The environment file for sync tools testing 
#
#  Copyright (c) 2008-2014 by cisco Systems, Inc.
#  All right reserved.
#--------------------------------------------------------------------

# Track dir
setenv SYNC_BETA_TRACKING_DIR "/nfs/scmlog/synctools/TEST_LOG/track"

# Test Database Env
setenv CDBRC                "HOST=scmdb.cisco.com;SIC=scmdb:ssctsadmin:ctsadmin"
setenv ORACLE_DB            "smdev"
#setenv ORACLE_DB            "smdev2"
setenv ORACLE_USER_CCLIST   "qrtools_stage"
setenv ORACLE_CCLIST_PASSWD "qrtools_stage"
setenv ORACLE_RO_USER       "qrtools_stage"
setenv ORACLE_RO_PASSWD     "qrtools_stage"
setenv CCTOOLSDB_ETCDIR     "/usr/local/packages/cctoolsdb/current/etc/staging"
setenv CCTOOLSDB_SBINDIR    "/usr/cisco/packages/cctoolsdb/TESTING/sbin"

# Stage prrq
# Setting the PRRQ to 'dev' instead of 'stage' as 'stage' link is down
setenv PRRQ_CISCO_LIFE  "dev"
#setenv PRRQ_CISCO_LIFE  "stage"

# Test tools location
setenv STT_DIR_NAME     "/auto/vwsxab/${SYNC_REG_TEST}"
setenv STT_DIR          "/auto/vwsxab/SYNC_TEST_SABIND"
setenv STT_BIN_DIR      "${STT_DIR}/bin"
setenv STT_DATA_DIR     "${STT_DIR}/datafile"
setenv STT_LIB_DIR      "${STT_DIR}/lib"
setenv STT_SUITES_DIR   "${STT_DIR}/test-suites"

# Working partition
setenv STT_WK_DIR       "/auto/vwsxab/SYNC_TEST"
#setenv STT_WK_DIR       "/ws/sj-iresync1"

# Sync Tools version
setenv STT_TEST_VERSION "SYNC_TOOLS_6_3_0"

# The test log location
setenv STT_LOG_DIR      "${STT_DIR}"

# sync_bug_find specific environments
setenv DEBUG_TESTER     1
setenv NO_VIEW_CLEANUP  1
setenv PRIV_TEST_DIR    "stt" 

#Remedy web-interface query for any case opened to synctools
setenv ST_REMEDY_STAGE 1


# The alias to send test results
setenv CC_MAIL_ALIASES  $LOGNAME  
setenv CCADM_MAILALIAS  $LOGNAME
setenv SYNC_EMAIL_ALIAS $LOGNAME

# Test vob using for the tests
setenv STT_VOB          "/vob/ios"

# Test base label/parent/child branches
##NEON Specific settings
setenv STT_SS_NEON       "BEGIN_STT_NEON_PRNT%stt_ss_neon_prnt%stt_ss_neon_chld"
setenv PTT_SS_NEON       "RAINIER_BASE_FOR_V122_33_SRA_THROTTLE%rainier%ptt_ss_neon_tgt1"

##IOS Specific settings
setenv STT_MONO          "SYNC_TEST_CHILD_BASE_POINT%sync_test_geo_t%sync_test_child_clone_new"
setenv STT_MONO_COSI1    "SYNC_TEST_CHILD_BASE_POINT%test_parent7_new%test_parent7_child_new"
setenv STT_MONO_IPINFO   "ST_CHILD_IPINFO_BASE_POINT_NEW1%st_ipinfo_new%st_child_ipinfo1_new2"
setenv STT_MONO_EMPTY1   "SYNC_TEST_CHILD_BASE_POINT%sync_test_geo_t%stt_mono_empty_cosi_3_new"
setenv STT_MONO_EMPTY    "SYNC_TEST_CHILD_BASE_POINT%sync_test_geo_t%sync_test_child_empty_ctran_new"
setenv STT_MONO_LABEL    "SYNC_TEST_CHILD_BASE_POINT%sync_test_geo_t%sync_test_child_labels_ctran_new"
setenv STT_MONO_PRRQ     "SYNC_TEST_CHILD_BASE_POINT%sync_test_geo_t%prrq_sync_test_child_1b_new"
setenv STT_BUILD_PLACE   "V124_21_14_1_PIC1%redoak%test_redoak_cbs2_01_new"
setenv STT_SS            "STT_SS_PARENT_A_FW_12222008%stt_ss_parent_a%tst_stt_ss_test_child_1_new"
setenv STT_SS_BLDTHRU_PM "STT_SS_PARENT_A_FW_12222008%stt_ss_parent_a%tst_stt_ss_child_bldthru_pm_new"
setenv STT_SS_SKIPMER    "STT_SS_PARENT_A_FW_12222008%stt_ss_parent_a%stt_ss_child_skip_merge_new"
setenv STT_TS            "V122_32_8_11_SR137%autobahn76%tst_stt_ts_c1_1_new"
setenv STT_COMPONENT     "(ptt_comp_source)1.0.1%comp_api_impact_test_ptt_comp_source%comp_api_impact_test_tst_stt_comp_child_1"
setenv STT_COMP_HLINK_FIX "(hard_child)1.0.0%comp_api_impact_test_hardlink_par%comp_api_impact_test_hard_child"

setenv CTT_MONO          "TST_COLP_MONO_PARENT_1_NEW_POSTPORT_CT_MONO_PARENT_CMT_2%tst_colp_mono_parent_1_new%tst_colp_mono_child_1_new"
setenv CTT_MONO_NTLST    "TST_COLP_MONO_PARENT_1_NEW_POSTPORT_CT_MONO_PARENT_CMT_2%tst_colp_mono_parent_1_new%tst_colp_mono_child_ntlst_1_new"
setenv CTT_MONO_CMT      "TST_CT_MONO_CHILD_CMT_1_POSTPORT_CT_MONO_CHILD_CMT_3%tst_ct_mono_parent_cmt_1%tst_ct_mono_child_cmt_1_new"

setenv CTT_SS            "TEST_SS_NEWSTAGE_P1_C1_POSTPORT_CT_SS_CHILD_CMT_1%test_ss_newstage_p1_new%test_ss_newstage_p1_c1_new"
setenv CTT_SS_NTLST      "TEST_SS_NEWSTAGE_P1_PREPORT_CT_SS_PARENT_CMT_2%test_ss_newstage_p1_new%test_ct_ss_child_ntlst1_new"
setenv CTT_SS_DUALDIR    "TEST_SS_NEWSTAGE_P1_DD_NEW_POSTPORT_CT_SS_CHILD_DUALDIR_CMT_1%test_ss_newstage_p1_new%test_ss_newstage_p1_dd_new"
setenv CTT_SS_HLINK      "TEST_SS_NEWSTAGE_P1_HLNK_POSTPORT_CT_SS_CHILD_HLINK_CMT_1%test_ss_newstage_p1_new%test_ss_newstage_p1_hlnk_new"
setenv CTT_SS_DIRHLNK    "TEST_SS_NEWSTAGE_P1_DHLNK_NEW_POSTPORT_CT_SS_CHILD_DIRHLINK_CMT_2%test_ss_newstage_p1_new%test_ss_newstage_p1_dhlnk_new"
setenv CTT_SS_DIRDIFF    "TEST_SS_NEWSTAGE_P1_NEW_DNOTSAME_POSTPORT_CT_SS_CHILD_DIRNOTSAME_CMT_1%test_ss_newstage_p1_new%test_ss_newstage_p1_dnotsame_new"
setenv CTT_SS_REM_CHILD  "TEST_SS_NEWSTAGE_P1_DNOTSAME_POSTPORT_CT_SS_CHILD_DIRNOTSAME_CMT_1%colp_test_parent1%colp_test_par1_child_rem_new3"
setenv CTT_SS_REM_PARENT  "SYNC_TEST_CHILD_BASE_POINT%sync_test_geo_t%test_ct_ss_local_chi13_new1"
setenv CTT_SS_CMT1       "TST_CT_CHILD_1_POSTPORT_CT_SS_CHILD_CMT_1%tst_ct_ss_parent_1%tst_ct_child_1"
setenv CTT_SS_CMT2       "TST_CT_CHILD_2_POSTPORT_CT_SS_CHILD_CMT_1%tst_ct_ss_parent_2%tst_ct_child_2"
setenv CTT_SS_CMT3       "TST_CT_CHILD_3_POSTPORT_CT_SS_CHILD_CMT_1%tst_ct_ss_parent_3%tst_ct_child_3"
setenv CTT_SS_REM_CMT    "TST_CT_SS_CHILD_REM_1_POSTPORT_CT_SS_CHILD_CMT_1%tst_ct_ss_parent_rem_1%tst_ct_ss_child_rem_1"

setenv CTT_COMP          "(tst_colp_p2_c12)2.0.0%comp_api_impact_test_tst_colp_p2%comp_api_impact_test_tst_colp_p2_c12"
setenv CTT_COMP_NTLST    "(tst_colp_p2_c2_ntlst)2.0.0%comp_api_impact_test_tst_colp_p2%comp_api_impact_test_tst_colp_p2_c2_ntlst"
setenv CTT_COMP_REM_PARENT  "(tst_colp_loc_c2)2.0.0%comp_api_impact_test_tst_colp_rem_p2%comp_api_impact_test_tst_colp_loc_c2"
setenv CTT_COMP_HLINK    "(tst_colp_p2_hlnk1)1.1.0%comp_api_impact_test_tst_colp_p2%comp_api_impact_test_tst_colp_p2_hlnk1"
setenv CTT_COMP_SLINK    "(tst_colp_p2_slnk)1.0.1%comp_api_impact_test_tst_colp_p2%comp_api_impact_test_tst_colp_p2_slnk"
setenv CTT_COMP_CMT1     "(tst_ct_child_11)2.0.0%comp_api_impact_test_tst_ct_parent_11%comp_api_impact_test_tst_ct_child_11"
setenv CTT_COMP_CMT2     "(tst_ct_child_21)2.0.0%comp_api_impact_test_tst_ct_parent_21%comp_api_impact_test_tst_ct_child_21"
setenv CTT_COMP_CMT3     "(tst_ct_child_3)2.0.0%comp_api_impact_test_tst_ct_parent_3%comp_api_impact_test_tst_ct_child_3"
setenv CTT_MONO_COSI     "TST_COLP_MONO_PARENT_1_NEW_POSTPORT_CT_MONO_PARENT_CMT_2%tst_parent_coll_new%tst_colp_mono_child_cosi_1_new"

setenv PTT_MONO                 "SYNC_TEST_CHILD_BASE_POINT%sync_test_geo_t%tst_mono_test_child_tb_new1"
setenv PTT_MONO_SC6                 "BASE_CHILD_SC6_NEW%new_parent_sc6%new_tst_br_sc6"
#setenv PTT_MONO                 "SYNC_TEST_CHILD_BASE_POINT%sync_test_geo_t%tst_mono_test_child_tb"
setenv PTT_MONO_1               "SYNC_TEST_CHILD_BASE_POINT%sync_test_geo_t%tst_mono_test_child_cc_co1_new"
setenv PTT_MONO_2               "BEGIN_OF_PT_PRT_TO_PARENT%pt_prt_to_parent%tst_pt_prt_to_child_scn3_1_new"
setenv PTT_MONO_MAKE            "V123_10_3_T2%geo_t%tst_port_test_buildplace_new"
setenv PTT_SINGLE_SOURCE        "V124_21_13_PI9%haw_t_pi9%ptt_ss_target_3_clone_1_new"
setenv PTT_SS_POSTMER           "V124_21_13_PI9%haw_t_pi9%stt_ss_tgt_skip_merge_new"
setenv PTT_COMP                 "1.0.0%comp_api_impact_test_main%comp_api_impact_test_tst_ptt_comp_target_1"
setenv PTT_COMP_COSI            "1.0.0%comp_api_impact_test_main%comp_api_impact_test_tst_target_2"

setenv PCTT_MONO           "SYNC_TEST_CHILD_BASE_POINT%collapse_test_mono_pc2_new%collapse_test_mono_pc2_child2_new"
setenv PCTT_MONO_NTL      "TST_PCOLP_MONO_PARENT_1_NEW_POSTPORT_TST_COLP_MONO_PARENT_1_NEW_POSTPORT_CT_MONO_PARENT_CMT_2%tst_pcolp_mono_parent_1_new%tst_pcolp_mono_child_1_new"
setenv PCTT_MONO_FINAL    "FINAL_PSEUDO_COL_1_NEW%test_final_pcollapse_parent1_new%test_final_pcollapse_child1_new"

setenv PCTT_MONO_REM_CHILD  "COLLAPSE_TEST_MONO_PC2_NEW_POSTPORT_CT_MONO_PARENT_CMT_2%collapse_test_mono_pc2_new%collapse_test_mono_pc2_child2_rem_new1"
setenv PCTT_MONO_MER1     "TST_COLP_MONO_PARENT_1_NEW_POSTPORT_CT_MONO_PARENT_CMT_2%tst_colp_mono_parent_1_new%tst_colp_mono_child_1_new"
setenv PCTT_PM          "COLLAPSE_TEST_MONO_PC2_NEW_POSTPORT_CT_MONO_PARENT_CMT_2%collapse_test_mono_pc2_new%collapse_test_mono_pc2_child2_new"
setenv PCTT_MONO_CMT     "TST_PCOLP_MONO_PARENT4_CMT_NEW1_POSTPORT_TST_COLP_MONO_PARENT_1_NEW_POSTPORT_CT_MONO_PARENT_CMT_2%tst_pcolp_mono_parent5_cmt_new1%tst_pcolp_mono_child5_cmt_new1"
setenv PCTT_MONO_CMT1     "TST_PCOLP_MONO_PARENT7_CMT_NEW_POSTPORT_TST_COLP_MONO_PARENT_1_NEW_POSTPORT_CT_MONO_PARENT_CMT_2%tst_pcolp_mono_parent7_cmt_new%tst_pcolp_mono_child7_cmt_new"
