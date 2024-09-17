*---------------------------------------------------------------------*
*    view related data declarations
*---------------------------------------------------------------------*
*...processing: ZRETLAI013_T04..................................*
DATA:  BEGIN OF STATUS_ZRETLAI013_T04                .   "state vector
         INCLUDE STRUCTURE VIMSTATUS.
DATA:  END OF STATUS_ZRETLAI013_T04                .
CONTROLS: TCTRL_ZRETLAI013_T04
            TYPE TABLEVIEW USING SCREEN '0001'.
*.........table declarations:.................................*
TABLES: *ZRETLAI013_T04                .
TABLES: ZRETLAI013_T04                 .

* general table data declarations..............
  INCLUDE LSVIMTDT                                .
