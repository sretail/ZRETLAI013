*===================================================================================================
*& Include          ZRETLAI014_FORMS
*===================================================================================================

*&---------------------------------------------------------------------*
*& Form f_initialization
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM f_initialization .
*>Carpeta de servidor por defecto con los ficheros LIBMOD a procesar
  select single valor1
    from ZRETLAI013_param
    into p_fol_in
   where param = 'CARPETA_LIBMOD_IN'.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form f_at_selection_screen_output
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM f_at_selection_screen_output .
  if p_consm = 'X'.
    loop at screen.
      if screen-name cs 'P_FOL_IN' or
         screen-name cs 'P_ON' or
         screen-name cs 'P_OFF'.
        screen-input = 0.
        screen-invisible = 1.
      endif.

      MODIFY SCREEN.
    endloop.
  else.
    loop at SCREEN.
      if screen-name cs 'S_MATNR' or
         screen-name cs 'S_FICHERO' or
         screen-name cs 'S_EAN11' or
         screen-name cs 'S_UNAME' or
         screen-name cs 'S_DATUM' or
         screen-name cs 'S_UZEIT' or
         screen-name cs 'S_FILE'.
        screen-input = 0.
        screen-invisible = 1.
      endif.

      MODIFY SCREEN.
    endloop.
  endif.
ENDFORM.
