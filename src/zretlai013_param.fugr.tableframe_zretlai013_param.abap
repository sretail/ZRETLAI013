*---------------------------------------------------------------------*
*    program for:   TABLEFRAME_ZRETLAI013_PARAM
*   generation date: 26.10.2020 at 08:01:55
*   view maintenance generator version: #001407#
*---------------------------------------------------------------------*
FUNCTION TABLEFRAME_ZRETLAI013_PARAM   .

  PERFORM TABLEFRAME TABLES X_HEADER X_NAMTAB DBA_SELLIST DPL_SELLIST
                            EXCL_CUA_FUNCT
                     USING  CORR_NUMBER VIEW_ACTION VIEW_NAME.

ENDFUNCTION.
