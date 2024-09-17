*&---------------------------------------------------------------------*
*& Include          ZRETLAI013_FLOW
*&---------------------------------------------------------------------*
START-OF-SELECTION.
  perform f_get_parametrizacion.
  PERFORM f_user_command_9000_modifp using ''.
  call screen 9000.
