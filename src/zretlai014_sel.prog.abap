*===================================================================================================
*& Include          ZRETLAI014_SEL
*===================================================================================================
SELECTION-SCREEN begin of BLOCK b03 WITH FRAME TITLE text-003.
  parameters: p_procm RADIOBUTTON GROUP r02 USER-COMMAND R02,
              p_consm RADIOBUTTON GROUP r02.
SELECTION-SCREEN end of BLOCK b03.

SELECTION-SCREEN begin of BLOCK b01 WITH FRAME TITLE text-001.
  parameters: p_fol_in like rlgrap-filename.
SELECTION-SCREEN end of BLOCK b01.

SELECTION-SCREEN begin of BLOCK b02 WITH FRAME TITLE text-002.
  parameters: p_on  RADIOBUTTON GROUP r01,
              p_off RADIOBUTTON GROUP r01.
SELECTION-SCREEN end of BLOCK b02.

SELECTION-SCREEN begin of block b04 WITH FRAME TITLE text-004.
  select-options: s_matnr for mara-matnr,
                  s_ean11 for mara-ean11,
                  s_uname for sy-uname,
                  s_datum for sy-datum,
                  s_uzeit for sy-uzeit.

  SELECTION-SCREEN SKIP 1.

  select-options: s_datums for sy-datum,
                  s_file   for rlgrap-filename.
SELECTION-SCREEN end of BLOCK b04.

INITIALIZATION.
  perform f_initialization.

at SELECTION-SCREEN OUTPUT.
  perform f_at_selection_screen_output.
