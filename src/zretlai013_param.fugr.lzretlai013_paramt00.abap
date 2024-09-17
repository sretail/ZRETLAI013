*---------------------------------------------------------------------*
*    view related data declarations
*---------------------------------------------------------------------*
*...processing: ZRETLAI013_PARAM................................*
DATA:  BEGIN OF STATUS_ZRETLAI013_PARAM              .   "state vector
         INCLUDE STRUCTURE VIMSTATUS.
DATA:  END OF STATUS_ZRETLAI013_PARAM              .
CONTROLS: TCTRL_ZRETLAI013_PARAM
            TYPE TABLEVIEW USING SCREEN '0001'.
*.........table declarations:.................................*
TABLES: *ZRETLAI013_PARAM              .
TABLES: ZRETLAI013_PARAM               .

* general table data declarations..............
  INCLUDE LSVIMTDT                                .
