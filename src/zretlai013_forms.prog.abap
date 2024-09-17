*&---------------------------------------------------------------------*
*& Include          ZRETLAI013_FORMS
*&---------------------------------------------------------------------*

*&---------------------------------------------------------------------*
*& Form f_user_command_9000
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM f_user_command_9000 .
  DATA: ld_okcode LIKE sy-ucomm.

  ld_okcode = gd_okcode_9000.

  CLEAR: gd_okcode_9000,
         sy-ucomm.



  CASE ld_okcode.
    WHEN 'EXIT' OR 'BACK' OR 'CANCEL'.
      LEAVE TO SCREEN 0.
    WHEN 'CREAR_ART'.
      PERFORM f_user_command_9000_crear_art.
    WHEN 'MODIF_ART'.
      PERFORM f_user_command_9000_modif_art.
    WHEN 'MODIFP'.
      IF zretlai013_s01-ean11 IS INITIAL.
        PERFORM f_user_command_9000_modifp USING 'X'.
      ENDIF.
    WHEN 'BTN_UNDO'.
      IF gf_libmod = 'X'.
        UPDATE zretlai013_t03
           SET tratado = 'X'
               tratado_usuario = sy-uname
               tratado_fecha = sy-datum
               tratado_hora = sy-uzeit
         WHERE ean11 = zretlai013_s01-ean11.
      ENDIF.

      PERFORM f_inicializar_pantalla.
    when 'CAMBIARTIENDA'.
      perform f_get_tienda_usuario using 'X'
                                CHANGING zretlai013_s02-get_werks_usuario zretlai013_s02-get_werks_usuariot.
  ENDCASE.
ENDFORM.

*&---------------------------------------------------------------------*
*&      Module  M_9000_PAI_VALIDAR_EAN11  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE m_9000_pai_validar_ean11 INPUT.
  PERFORM f_9000_pai_validar_ean11.
ENDMODULE.

*&---------------------------------------------------------------------*
*& Form f_9000_pai_validar_ean11
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM f_9000_pai_validar_ean11 .
* 0.- Declaración de variables
*===================================================================================================
  DATA: wa_zretlai013_t01  LIKE zretlai013_t01,
        wa_mara            LIKE mara,
        ld_response        TYPE string,
        ld_split_1         TYPE string,
        ld_split_2         TYPE string,
        ld_base64_string   TYPE string,
        ld_base64_xstring  TYPE xstring,
        lit_imagen_binario TYPE soli_tab,
        wa_imagen_binario  TYPE soli,
        ld_valor           TYPE string,
        ld_comando(2000).

* 1.- Lógica
*===================================================================================================
* Quitar guiones
  REPLACE ALL OCCURRENCES OF '-' IN zretlai013_s01-ean11 WITH ''.

  IF zretlai013_s01-ean11 IS NOT INITIAL.
*>>>Validar si el EAN ha sido consultado a CEGAL
    SELECT SINGLE *
      FROM zretlai013_t01
      INTO wa_zretlai013_t01
     WHERE get_ean11 = zretlai013_s01-ean11.

    IF sy-subrc = 0.
      gf_ean_leido = 'X'.
    ENDIF.

*>>>Validar si el EAN existe en el sistema
    SELECT SINGLE *
      FROM mara
      INTO wa_mara
     WHERE ean11 = zretlai013_s01-ean11.

    IF sy-subrc = 0.
      zretlai013_s01-sap = 'X'.
      zretlai013_s02-matnr = wa_mara-matnr.

      gf_ean_leido = 'X'.
    ENDIF.

    IF gf_ean_leido = ''.
*     Si el EAN nunca ha sido consultado a CEGAL, lanzamos consulta
      PERFORM f_consulta_ean_cegald USING zretlai013_s01-ean11 CHANGING ld_response.

*     Si la consulta devuelve error no hacemos nada y nos salimos
      IF ld_response CS '<ERRORES>'.                                                                "APRADAS-15.11.2021
*       Si la consulta devuelve errores...
        PERFORM f_get_valor_etiqueta USING '<DESCRIPCION>'
                                           '</DESCRIPCION>'
                                           ld_response
                                  CHANGING ld_valor.

        MESSAGE ld_valor TYPE 'I' DISPLAY LIKE 'E'.

        EXIT.
      ELSEIF ld_response IS INITIAL.
*       Si la consulta devuelve error de conexión...
        EXIT.
      ELSE.
*       Si la consulta es correcta, marcamos EAN como leido.
        gf_ean_leido = 'X'.
      ENDIF.
    ENDIF.
  ELSE.
*   Si EAN en blanco, inicializamos pantalla y nos salimos
    PERFORM f_inicializar_pantalla.
    EXIT.
  ENDIF.

* Si no tenemos resultado de consulta, es porque el EAN ya habia sido leido previamente, por lo que
* lanzamos consulta
  IF ld_response IS INITIAL.
    PERFORM f_consulta_ean_cegald USING zretlai013_s01-ean11 CHANGING ld_response.

*   Si la consulta devuelve error no hacemos nada y nos salimos
    IF ld_response CS '<ERRORES>'.                                                                  ""APRADAS-15.11.2021
*     Si la consulta devuelve errores...
      PERFORM f_get_valor_etiqueta USING '<DESCRIPCION>'
                                         '</DESCRIPCION>'
                                         ld_response
                                CHANGING ld_valor.

      MESSAGE ld_valor TYPE 'I' DISPLAY LIKE 'E'.

      EXIT.
    ELSEIF ld_response IS INITIAL.
*     Si la consulta devuelve error de conexión...
      EXIT.
    ENDIF.
  ENDIF.

* En este punto tendremos la consulta a CEGAL realizada correctamente

*---------------------------------------------------------------------------------------------------
*>Obtenemos valores de las distintas etiquetas de CEGAL que nos interesan
*---------------------------------------------------------------------------------------------------
  PERFORM f_get_valor_etiqueta USING  '<EAN>'
                                      '</EAN>'
                                      ld_response
                            CHANGING  ld_valor.

  zretlai013_s02-get_ean11 = ld_valor.

  PERFORM f_get_valor_etiqueta USING  '<ISBN>'
                                      '</ISBN>'
                                      ld_response
                            CHANGING  ld_valor.

  zretlai013_s02-get_isbn = ld_valor.

  PERFORM f_get_valor_etiqueta USING  '<ISBN_FACTURACION>'
                                      '</ISBN_FACTURACION>'
                                      ld_response
                            CHANGING  ld_valor.

  IF  zretlai013_s01-sap = 'X'.
    zretlai013_s02-get_isbn_facturacion_cegal   = ld_valor.
  ELSE.
    zretlai013_s02-get_isbn_facturacion   = ld_valor.
  ENDIF.

  PERFORM f_get_valor_etiqueta USING  '<ISBN_OBRA_COMPLETA>'
                                      '</ISBN_OBRA_COMPLETA>'
                                      ld_response
                            CHANGING  ld_valor.
  IF  zretlai013_s01-sap = 'X'.
    zretlai013_s02-get_isbn_obra_completa_cegal = ld_valor.
  ELSE.
    zretlai013_s02-get_isbn_obra_completa = ld_valor.
  ENDIF.

  PERFORM f_get_valor_etiqueta USING  '<ISBN_TOMO_COMPLETO>'
                                      '</ISBN_TOMO_COMPLETO>'
                                      ld_response
                            CHANGING  ld_valor.

  IF  zretlai013_s01-sap = 'X'.
    zretlai013_s02-get_isbn_tomo_completo_cegal = ld_valor.
  ELSE.
    zretlai013_s02-get_isbn_tomo_completo = ld_valor.
  ENDIF.

  PERFORM f_get_valor_etiqueta USING  '<ISBN_FASCICULO>'
                                      '</ISBN_FASCICULO>'
                                      ld_response
                            CHANGING  ld_valor.
  IF  zretlai013_s01-sap = 'X'.
    zretlai013_s02-get_isbn_fasciculo_cegal = ld_valor.
  ELSE.
    zretlai013_s02-get_isbn_fasciculo = ld_valor.
  ENDIF.

  PERFORM f_get_valor_etiqueta USING  '<TITULO><![CDATA['
                                      ']]></TITULO>'
                                      ld_response
                            CHANGING  ld_valor.

  IF  zretlai013_s01-sap = 'X'.
    zretlai013_s02-get_titulo_cegal = ld_valor.
    TRANSLATE zretlai013_s02-get_titulo_cegal to UPPER CASE.
  ELSE.
    zretlai013_s02-get_titulo = ld_valor.
    TRANSLATE zretlai013_s02-get_titulo to UPPER CASE.
  ENDIF.

  PERFORM f_get_valor_etiqueta USING  '<SUBTITULO><![CDATA['
                                      ']]></SUBTITULO>'
                                      ld_response
                            CHANGING  ld_valor.

  IF  zretlai013_s01-sap = 'X'.
    zretlai013_s02-get_subtitulo_cegal = ld_valor.
    translate zretlai013_s02-get_subtitulo_cegal to UPPER CASE.
  ELSE.
    zretlai013_s02-get_subtitulo = ld_valor.
    translate zretlai013_s02-get_subtitulo to UPPER CASE.
  ENDIF.

  PERFORM f_get_valor_etiqueta USING  '<PAIS_PUBLICACION>'
                                      '</PAIS_PUBLICACION>'
                                      ld_response
                            CHANGING  ld_valor.
  IF  zretlai013_s01-sap = 'X'.
    zretlai013_s02-get_pais_publicacion_cegal = ld_valor.
  ELSE.
    zretlai013_s02-get_pais_publicacion = ld_valor.
  ENDIF.

  PERFORM f_get_valor_etiqueta USING  '<ENCUADERNACION>'
                                      '</ENCUADERNACION>'
                                      ld_response
                            CHANGING  ld_valor.

*>APRADAS-28.10.2021 14:49:35-Inicio
* Si CEGAL devuelve 00 quiere decir que no tiene encuadernación
  IF ld_response = '00'.
    ld_response = ''.
  ENDIF.
*<APRADAS-28.10.2021 14:49:35-Fin

  IF  zretlai013_s01-sap = 'X'.
    zretlai013_s02-get_encuadernacion_cegal = ld_valor.
  ELSE.
    zretlai013_s02-get_encuadernacion = ld_valor.
  ENDIF.

  PERFORM f_get_valor_etiqueta USING  '<LENGUA_PUBLICACION>'
                                      '</LENGUA_PUBLICACION>'
                                      ld_response
                            CHANGING  ld_valor.

  IF  zretlai013_s01-sap = 'X'.
    PERFORM f_convertir_idioma_sinli USING ld_valor
                                  CHANGING zretlai013_s02-get_lengua_publicacion_cegal.
  ELSE.
    PERFORM f_convertir_idioma_sinli USING ld_valor
                                  CHANGING zretlai013_s02-get_lengua_publicacion.
  ENDIF.

  PERFORM f_get_valor_etiqueta USING  '<NUMERO_EDICION>'
                                      '</NUMERO_EDICION>'
                                      ld_response
                            CHANGING  ld_valor.
  IF  zretlai013_s01-sap = 'X'.
    zretlai013_s02-get_numero_edicion_cegal = ld_valor.
  ELSE.
    zretlai013_s02-get_numero_edicion = ld_valor.
  ENDIF.

  PERFORM f_get_valor_etiqueta USING  '<FECHA_PUBLICACION>'
                                      '</FECHA_PUBLICACION>'
                                      ld_response
                            CHANGING  ld_valor.

  IF  zretlai013_s01-sap = 'X'.
    IF ld_valor IS NOT INITIAL.
      CONCATENATE ld_valor+2(4) ld_valor(2) '01' INTO ld_valor.
    ENDIF.
    zretlai013_s02-get_fecha_publicacion_cegal  = ld_valor.
  ELSE.
    IF ld_valor IS NOT INITIAL.
      CONCATENATE ld_valor+2(4) ld_valor(2) '01' INTO ld_valor.
    ENDIF.
    zretlai013_s02-get_fecha_publicacion  = ld_valor.
  ENDIF.

  PERFORM f_get_valor_etiqueta USING  '<NUMERO_PAGINAS>'
                                      '</NUMERO_PAGINAS>'
                                      ld_response
                            CHANGING  ld_valor.
  IF  zretlai013_s01-sap = 'X'.
    zretlai013_s02-get_numero_paginas_cegal = ld_valor.
  ELSE.
    zretlai013_s02-get_numero_paginas = ld_valor.
  ENDIF.

  PERFORM f_get_valor_etiqueta USING  '<ANCHO>'
                                      '</ANCHO>'
                                      ld_response
                            CHANGING  ld_valor.
  IF  zretlai013_s01-sap = 'X'.
    zretlai013_s02-get_ancho_mm_cegal           = ld_valor / 10.
    zretlai013_s02-get_ancho_mm_meins_cegal     = 'CM'.
  ELSE.
    zretlai013_s02-get_ancho_mm           = ld_valor / 10.
    zretlai013_s02-get_ancho_mm_meins = 'CM'.
  ENDIF.

  PERFORM f_get_valor_etiqueta USING  '<ALTO>'
                                      '</ALTO>'
                                      ld_response
                            CHANGING  ld_valor.
  IF  zretlai013_s01-sap = 'X'.
    zretlai013_s02-get_alto_mm_cegal            = ld_valor / 10.
    zretlai013_s02-get_alto_mm_meins_cegal      = 'CM'.
  ELSE.
    zretlai013_s02-get_alto_mm            = ld_valor / 10.
    zretlai013_s02-get_alto_mm_meins = 'CM'.
  ENDIF.

  PERFORM f_get_valor_etiqueta USING  '<IBIC>'
                                      '</IBIC>'
                                      ld_response
                            CHANGING  ld_valor.

  REPLACE ALL OCCURRENCES OF ';' IN ld_valor WITH '/'.
  IF  zretlai013_s01-sap = 'X'.
    zretlai013_s02-get_ibic_cegal         = ld_valor.
  ELSE.
    zretlai013_s02-get_ibic               = ld_valor.
  ENDIF.

  PERFORM f_get_valor_etiqueta USING  '<CDU>'
                                      '</CDU>'
                                      ld_response
                            CHANGING ld_valor.
  REPLACE ALL OCCURRENCES OF ';' IN ld_valor WITH '/'.
  IF  zretlai013_s01-sap = 'X'.
    zretlai013_s02-get_cdu_cegal          = ld_valor.
  ELSE.
    zretlai013_s02-get_cdu                = ld_valor.
  ENDIF.

  PERFORM f_get_valor_etiqueta USING  '<DESCRIPTORES>'
                                      '</DESCRIPTORES>'
                                      ld_response
                            CHANGING  ld_valor.
  IF  zretlai013_s01-sap = 'X'.
    zretlai013_s02-get_descriptores_cegal = ld_valor.
  ELSE.
    zretlai013_s02-get_descriptores       = ld_valor.
  ENDIF.

  PERFORM f_get_valor_etiqueta USING  '<SITUACION>'
                                      '</SITUACION>'
                                      ld_response
                            CHANGING  ld_valor.
  IF  zretlai013_s01-sap = 'X'.
    zretlai013_s02-get_situacion_cegal    = ld_valor.
  ELSE.
    zretlai013_s02-get_situacion          = ld_valor.
  ENDIF.

  PERFORM f_get_valor_etiqueta USING  '<TIPO_PRODUCTO>'
                                      '</TIPO_PRODUCTO>'
                                      ld_response
                            CHANGING  ld_valor.
  IF  zretlai013_s01-sap = 'X'.
    zretlai013_s02-get_tipo_producto_cegal      = ld_valor.
  ELSE.
    zretlai013_s02-get_tipo_producto      = ld_valor.
  ENDIF.

  PERFORM f_get_valor_etiqueta USING  '<PRECIO_SIN_IVA>'
                                      '</PRECIO_SIN_IVA>'
                                      ld_response
                            CHANGING  ld_valor.
  IF  zretlai013_s01-sap = 'X'.
    zretlai013_s02-get_precio_sin_iva_cegal     = ld_valor / 100.
    zretlai013_s02-get_precio_sin_iva_waers_cegal = 'EUR'.
  ELSE.
    zretlai013_s02-get_precio_sin_iva     = ld_valor / 100.
    zretlai013_s02-get_precio_sin_iva_waers = 'EUR'.
  ENDIF.

  PERFORM f_get_valor_etiqueta USING  '<PRECIO_CON_IVA>'
                                      '</PRECIO_CON_IVA>'
                                      ld_response
                            CHANGING  ld_valor.
  IF  zretlai013_s01-sap = 'X'.
    zretlai013_s02-get_precio_con_iva_cegal     = ld_valor / 100.
    zretlai013_s02-get_precio_con_iva_waers_cegal = 'EUR'.
  ELSE.
    zretlai013_s02-get_precio_con_iva     = ld_valor / 100.
    zretlai013_s02-get_precio_con_iva_waers = 'EUR'.
  ENDIF.

  PERFORM f_get_valor_etiqueta USING  '<IVA>'
                                      '</IVA>'
                                      ld_response
                            CHANGING  ld_valor.
  IF  zretlai013_s01-sap = 'X'.
    zretlai013_s02-get_iva_cegal                = ld_valor / 100.
    zretlai013_s02-get_iva_waers_cegal = '%'.

    CASE zretlai013_s02-get_iva_cegal.
      WHEN 0.
        zretlai013_s02-get_taklv_cegal = 0.
      WHEN 4.
        zretlai013_s02-get_taklv_cegal = 1.
      WHEN 10.
        zretlai013_s02-get_taklv_cegal = 2.
      WHEN 21.
        zretlai013_s02-get_taklv_cegal = 3.
    ENDCASE.

    PERFORM f_get_taklvt USING zretlai013_s02-get_taklv_cegal
                      CHANGING zretlai013_s02-get_taklv_cegalt.
  ELSE.
    zretlai013_s02-get_iva                = ld_valor / 100.
    zretlai013_s02-get_iva_waers = '%'.

    CASE zretlai013_s02-get_iva.
      WHEN 0.
        zretlai013_s02-get_taklv = 0.
      WHEN 4.
        zretlai013_s02-get_taklv = 1.
      WHEN 10.
        zretlai013_s02-get_taklv = 2.
      WHEN 21.
        zretlai013_s02-get_taklv = 3.
    ENDCASE.

    PERFORM f_get_taklvt USING zretlai013_s02-get_taklv
                      CHANGING zretlai013_s02-get_taklvt.
  ENDIF.

  PERFORM f_get_valor_etiqueta USING  '<COLECCION><![CDATA['
                                      ']]></COLECCION>'
                                      ld_response
                            CHANGING  ld_valor.
  IF  zretlai013_s01-sap = 'X'.
    zretlai013_s02-get_coleccion_cegal          = ld_valor.
    translate zretlai013_s02-get_coleccion_cegal to UPPER CASE.
  ELSE.
    zretlai013_s02-get_coleccion          = ld_valor.
    translate zretlai013_s02-get_coleccion to UPPER CASE.
  ENDIF.

  PERFORM f_get_valor_etiqueta USING  '<NUMERO_COLECCION>'
                                      '</NUMERO_COLECCION>'
                                      ld_response
                            CHANGING  ld_valor.
  IF  zretlai013_s01-sap = 'X'.
    zretlai013_s02-get_numero_coleccion_cegal   = ld_valor.
  ELSE.
    zretlai013_s02-get_numero_coleccion   = ld_valor.
  ENDIF.

  PERFORM f_get_valor_etiqueta USING  '<NUMERO_VOLUMEN>'
                                      '</NUMERO_VOLUMEN>'
                                      ld_response
                            CHANGING  ld_valor.
  IF  zretlai013_s01-sap = 'X'.
    zretlai013_s02-get_numero_volumen_cegal   = ld_valor.
  ELSE.
    zretlai013_s02-get_numero_volumen   = ld_valor.
  ENDIF.

  PERFORM f_get_valor_etiqueta USING  '<URL>'
                                      '</URL>'
                                      ld_response
                            CHANGING  ld_valor.
  IF  zretlai013_s01-sap = 'X'.
    zretlai013_s02-get_url_cegal   = ld_valor.
  ELSE.
    zretlai013_s02-get_url   = ld_valor.
  ENDIF.

  PERFORM f_get_valor_etiqueta USING  '<ILUSTRADOR_CUBIERTA><![CDATA['
                                      ']]></ILUSTRADOR_CUBIERTA>'
                                      ld_response
                            CHANGING  ld_valor.
  IF  zretlai013_s01-sap = 'X'.
    zretlai013_s02-get_ilustrador_cubierta_cegal   = ld_valor.
    translate zretlai013_s02-get_ilustrador_cubierta_cegal to UPPER CASE.
  ELSE.
    zretlai013_s02-get_ilustrador_cubierta   = ld_valor.
    translate zretlai013_s02-get_ilustrador_cubierta to UPPER CASE.
  ENDIF.

  PERFORM f_get_valor_etiqueta USING  '<ILUSTRADOR_INTERIOR>'
                                      '</ILUSTRADOR_INTERIOR>'
                                      ld_response
                            CHANGING  ld_valor.
  IF  zretlai013_s01-sap = 'X'.
    zretlai013_s02-get_ilustrador_interior_cegal   = ld_valor.
  ELSE.
    zretlai013_s02-get_ilustrador_interior   = ld_valor.
  ENDIF.

  PERFORM f_get_valor_etiqueta USING  '<NUMERO_ILUSTRACIONES_COLOR>'
                                      '</NUMERO_ILUSTRACIONES_COLOR>'
                                      ld_response
                            CHANGING  ld_valor.
  IF  zretlai013_s01-sap = 'X'.
    zretlai013_s02-get_numero_ilustraciones_colrc   = ld_valor.
  ELSE.
    zretlai013_s02-get_numero_ilustraciones_color   = ld_valor.
  ENDIF.

  PERFORM f_get_valor_etiqueta USING '<TRADUCTOR><![CDATA['
                                     ']]></TRADUCTOR>'
                                     ld_response
                            CHANGING ld_valor.
  IF  zretlai013_s01-sap = 'X'.
    zretlai013_s02-get_traductor_cegal   = ld_valor.
    translate zretlai013_s02-get_traductor_cegal to UPPER CASE.
  ELSE.
    zretlai013_s02-get_traductor   = ld_valor.
    translate zretlai013_s02-get_traductor to UPPER CASE.
  ENDIF.


  PERFORM f_get_valor_etiqueta USING '<IDIOMA_ORIGINAL>'
                                     '</IDIOMA_ORIGINAL>'
                                     ld_response
                            CHANGING ld_valor.
  IF  zretlai013_s01-sap = 'X'.
    PERFORM f_convertir_idioma_sinli USING ld_valor
                                  CHANGING zretlai013_s02-get_idioma_original_cegal.
  ELSE.
    PERFORM f_convertir_idioma_sinli USING ld_valor
                                  CHANGING zretlai013_s02-get_idioma_original.

  ENDIF.
  PERFORM f_get_valor_etiqueta USING  '<GROSOR>'
                                      '</GROSOR>'
                                      ld_response
                            CHANGING ld_valor.
  IF  zretlai013_s01-sap = 'X'.
    zretlai013_s02-get_grosor_mm_cegal          = ld_valor / 10.
    zretlai013_s02-get_grosor_mm_meins_cegal = 'CM'.
  ELSE.
    zretlai013_s02-get_grosor_mm          = ld_valor / 10. zretlai013_s02-get_grosor_mm_meins = 'CM'.
  ENDIF.

  PERFORM f_get_valor_etiqueta USING  '<PESO>'
                                      '</PESO>'
                                      ld_response
                            CHANGING ld_valor.

  IF  zretlai013_s01-sap = 'X'.
    zretlai013_s02-get_peso_cegal               = ld_valor.
    zretlai013_s02-get_peso_meins_cegal = 'G'.
  ELSE.
    zretlai013_s02-get_peso               = ld_valor.
    zretlai013_s02-get_peso_meins = 'G'.
  ENDIF.

  PERFORM f_get_valor_etiqueta USING  '<AUDIENCIA>'
                                      '</AUDIENCIA>'
                                      ld_response
                            CHANGING  ld_valor.
  IF  zretlai013_s01-sap = 'X'.
    zretlai013_s02-get_audiencia_cegal          = ld_valor.
  ELSE.
    zretlai013_s02-get_audiencia          = ld_valor.
  ENDIF.

  PERFORM f_get_valor_etiqueta USING  '<NIVEL_LECTURA>'
                                      '</NIVEL_LECTURA>'
                                      ld_response
                            CHANGING  ld_valor.
  IF  zretlai013_s01-sap = 'X'.
    zretlai013_s02-get_nivel_lectura_cegal      = ld_valor.
  ELSE.
    zretlai013_s02-get_nivel_lectura      = ld_valor.
  ENDIF.

  PERFORM f_get_valor_etiqueta USING '<NIVEL>'
                                     '</NIVEL>'
                                     ld_response
                            CHANGING ld_valor.
  IF  zretlai013_s01-sap = 'X'.
    zretlai013_s02-get_nivel_cegal = ld_valor.
  ELSE.
    zretlai013_s02-get_nivel = ld_valor.
  ENDIF.

  PERFORM f_get_valor_etiqueta USING '<CURSO>'
                                     '</CURSO>'
                                     ld_response
                            CHANGING ld_valor.
  IF  zretlai013_s01-sap = 'X'.
    zretlai013_s02-get_curso_cegal = ld_valor.
  ELSE.
    zretlai013_s02-get_curso = ld_valor.
  ENDIF.

  PERFORM f_get_valor_etiqueta USING '<ASIGNATURA>'
                                     '</ASIGNATURA>'
                                     ld_response
                            CHANGING ld_valor.

  IF  zretlai013_s01-sap = 'X'.
    zretlai013_s02-get_asignatura_cegal = ld_valor.
  ELSE.
    zretlai013_s02-get_asignatura = ld_valor.
  ENDIF.

  PERFORM f_get_valor_etiqueta USING '<AUTONOMIA>'
                                     '</AUTONOMIA>'
                                     ld_response
                            CHANGING ld_valor.
  IF  zretlai013_s01-sap = 'X'.
    zretlai013_s02-get_asignatura_cegal = ld_valor.
  ELSE.
    zretlai013_s02-get_asignatura = ld_valor.
  ENDIF.

  PERFORM f_get_valor_largo    TABLES git_resumen
                                USING '<RESUMEN><![CDATA['
                                      ']]></RESUMEN>'
                                      ld_response .


  PERFORM f_get_valor_etiqueta USING  '<NOMBRE><![CDATA['
                                      ']]></NOMBRE>'
                                      ld_response
                            CHANGING  ld_valor.
  IF  zretlai013_s01-sap = 'X'.
    zretlai013_s02-get_nombre_autor_cegal       = ld_valor.
    translate zretlai013_s02-get_nombre_autor_cegal to UPPER CASE.
  ELSE.
    zretlai013_s02-get_nombre_autor       = ld_valor.
    translate zretlai013_s02-get_nombre_autor to UPPER CASE.
  ENDIF.

  PERFORM f_get_valor_largo    TABLES git_biografia
                                USING '<BIOGRAFIA><![CDATA['
                                      ']]></BIOGRAFIA>'
                                      ld_response.

  PERFORM f_get_valor_largo    TABLES git_indice
                                USING '<INDICE><![CDATA['
                                      ']]></INDICE>'
                                      ld_response.

  PERFORM f_get_valor_etiqueta USING  '<IMAGEN_PORTADA><![CDATA['
                                      ']]></IMAGEN_PORTADA>'
                                      ld_response
                            CHANGING  ld_valor.

  IF ld_valor IS NOT INITIAL.
    gf_cargar_photo = 'X'.

    ld_base64_string = ld_valor.

    PERFORM f_get_valor_etiqueta USING  '<FORMATO_PORTADA>'
                                        '</FORMATO_PORTADA>'
                                        ld_response
                              CHANGING  ld_valor.

*  >Obtener ruta base donde almacenar las imágenes de portada

    SELECT SINGLE valor
      FROM zhardcodes
      INTO gd_ruta_completa
     WHERE programa = 'ZRETLAI013'
       AND param    = 'RUTA_IMG_PORTADAS'.


*  >Crear carpeta para los los primeros 7 carácteres del EAN
***    CONCATENATE gd_ruta_completa zretlai013_s01-ean11(7) INTO gd_ruta_completa.
***    CONCATENATE gd_ruta_completa zretlai013_s01-ean11(7) INTO gd_ruta_completa.
***    CONCATENATE 'cmd /c mkdir' gd_ruta_completa INTO ld_comando SEPARATED BY space.
***    CALL 'SYSTEM' ID 'COMMAND' FIELD ld_comando.

*  >Borrar imágenes previas del EAN en el servidor de imágenes
****    PERFORM f_borrar_imagenes_servidor USING gd_ruta_completa
****                                             zretlai013_s01-ean11.


*  >Confeccionar ruta final completa para la imagen
    translate ld_valor to UPPER CASE.
    CONCATENATE gd_ruta_completa 'LIBROS\' zretlai013_s01-ean11 '.' ld_valor INTO gd_ruta_completa.


*   Abrir ruta-fichero en servidor
    OPEN DATASET gd_ruta_completa FOR OUTPUT IN BINARY MODE.

*   Convertimos String a XString
    CALL FUNCTION 'SCMS_BASE64_DECODE_STR'
      EXPORTING
        input  = ld_base64_string
*       UNESCAPE       = 'X'
      IMPORTING
        output = ld_base64_xstring
      EXCEPTIONS
        failed = 1
        OTHERS = 2.
    IF sy-subrc <> 0.
    ENDIF.

*     Convertimos XString a binario
    CALL FUNCTION 'SCMS_XSTRING_TO_BINARY'
      EXPORTING
        buffer     = ld_base64_xstring
*       APPEND_TO_TABLE       = ' '
*         IMPORTING
*       OUTPUT_LENGTH         =
      TABLES
        binary_tab = lit_imagen_binario.

*     Transferimos contenido binario a ruta-fichero abierto
    LOOP AT lit_imagen_binario INTO wa_imagen_binario.
      TRANSFER wa_imagen_binario-line TO gd_ruta_completa.
    ENDLOOP.

*     Cerramos ruta-fichero
    CLOSE DATASET gd_ruta_completa.
  ENDIF.

*>Determinar editorial en artículos nuevos
  IF  zretlai013_s01-sap = ''.
*   Determinar editorial
    PERFORM f_get_editorial    USING zretlai013_s02-get_ean11
                            CHANGING zretlai013_s02-get_mfrnr
                                     zretlai013_s02-get_mfrnrt.

*   Solicitar confirmación editorial determinada
    CALL SCREEN 0500 STARTING AT 10 10.
  ENDIF.

  IF zretlai013_s01-sap = 'X'.
*   Si EAN existe en SAP obtenemos la información del artículo en el sistema
    PERFORM f_cargar_datos_articulo_sap.

*  <APRADAS-11.03.2022 07:53:41-Inicio
*   Determinar si el nuevo artículo debe considerarse novedad o no
    perform f_determinar_si_es_novedad using zretlai013_s02-get_fecha_publicacion_cegal
                                    CHANGING zretlai013_s02-get_zz1_novedad2_prd.
*  <APRADAS-11.03.2022 07:53:41-Fin

  ELSE.
*   Si EAN no existe en SAP (nuevo artículo)

*   Marcar por defecto el pincho de catalogar en tienda web
    zretlai013_s02-get_catweb_tienda = 'X'.

*   Obtener tienda del usuario
    PERFORM f_get_tienda_usuario using ''
                              CHANGING zretlai013_s02-get_werks_usuario zretlai013_s02-get_werks_usuariot.

*   Determinamos los proveedores asociados a la editorial y el proveedor asociado a la tienda
    PERFORM f_get_prov_from_editorial USING    zretlai013_s02-get_mfrnr
                                               zretlai013_s02-get_werks_usuario
                                      CHANGING zretlai013_s02-get_lifnr
                                               zretlai013_s02-get_lifnrt.

    SELECT SINGLE valor1
      FROM zretlai013_param
      INTO zretlai013_s02-get_ekorg
     WHERE param = 'EKORG_DEFECTO'.

    PERFORM f_get_ekorgt USING zretlai013_s02-get_ekorg CHANGING zretlai013_s02-get_ekorgt.

    zretlai013_s02-get_brgew      = zretlai013_s02-get_peso.

    PERFORM f_get_from_param USING 'ATTYP_DEFECTO'
                          CHANGING zretlai013_s02-get_attyp.

    PERFORM f_get_attypt     USING zretlai013_s02-get_attyp
                          CHANGING zretlai013_s02-get_attypt.

    PERFORM f_get_from_param USING 'MEINS_DEFECTO'
                          CHANGING zretlai013_s02-get_meins.



    PERFORM f_get_from_param USING 'TRAGR_DEFECTO'
                          CHANGING zretlai013_s02-get_tragr.

    PERFORM f_get_tragrt USING zretlai013_s02-get_tragr
                      CHANGING zretlai013_s02-get_tragrt.

    PERFORM f_get_from_param USING 'MTPOS_MARA_DEFECTO'
                          CHANGING zretlai013_s02-get_mtpos_mara.

    PERFORM f_get_mtpos_marat USING zretlai013_s02-get_mtpos_mara
                           CHANGING zretlai013_s02-get_mtpos_marat.

    PERFORM f_get_from_param USING 'LADGR_DEFECTO'
                          CHANGING zretlai013_s02-get_ladgr.

    PERFORM f_get_ladgrt USING zretlai013_s02-get_ladgr
                      CHANGING zretlai013_s02-get_ladgrt.

    PERFORM f_get_from_param USING 'WBKLA_DEFECTO'
                          CHANGING zretlai013_s02-get_wbkla.

    PERFORM f_get_wbklat USING zretlai013_s02-get_wbkla
                      CHANGING zretlai013_s02-get_wbklat.

*   Grupo de compras por defecto + Denominación
    PERFORM f_get_from_param USING 'EKGRP_DEFECTO'
                          CHANGING zretlai013_s02-get_ekgrp.

    PERFORM f_get_ekgrpt USING    zretlai013_s02-get_ekgrp
                         CHANGING zretlai013_s02-get_ekgrpt.

*  >Valores por defecto "Datos tienda"

*   Característica planificación de necesidades
    PERFORM f_get_from_param USING 'DISMM_TIENDA_DEFECTO'
                          CHANGING zretlai013_s02-get_dismm_tienda.

*   Verificación de disponibilidad
    PERFORM f_get_from_param USING 'MTVFP_TIENDA_DEFECTO'
                          CHANGING zretlai013_s02-get_mtvfp_tienda.

*   Indicador de periodo
    PERFORM f_get_from_param USING 'PERKZ_TIENDA_DEFECTO'
                          CHANGING zretlai013_s02-get_perkz_tienda.

*   Planificador de necesidades
    PERFORM f_get_from_param USING 'DISPO_TIENDA_DEFECTO'
                          CHANGING zretlai013_s02-get_dispo_tienda.

*   Punto de pedido
    PERFORM f_get_from_param USING 'MINBE_TIENDA_DEFECTO'
                          CHANGING zretlai013_s02-get_minbe_tienda.

*   Plazo entrega previsto
    PERFORM f_get_from_param USING 'PLIFZ_TIENDA_DEFECTO'
                          CHANGING zretlai013_s02-get_plifz_tienda.

*   Fuente aprovisionamiento
    PERFORM f_get_from_param USING 'BWSCL_TIENDA_DEFECTO'
                          CHANGING zretlai013_s02-get_bwscl_tienda.

*   Stock seguridad
    PERFORM f_get_from_param USING 'EISBE_TIENDA_DEFECTO'
                          CHANGING zretlai013_s02-get_eisbe_tienda.

*   Stock objetivo
    PERFORM f_get_from_param USING 'SOBST_TIENDA_DEFECTO'
                          CHANGING zretlai013_s02-get_sobst_tienda.


    PERFORM f_get_from_param USING 'BWSCL_CENTRO_DEFECTO'
                          CHANGING zretlai013_s02-get_bwscl_centro.


    PERFORM f_get_from_param USING 'DISMM_CENTRO_DEFECTO'
                          CHANGING zretlai013_s02-get_dismm_centro.

    PERFORM f_get_from_param USING 'MTVFP_CENTRO_DEFECTO'
                          CHANGING zretlai013_s02-get_mtvfp_centro.


    PERFORM f_get_from_param USING 'PERKZ_CENTRO_DEFECTO'
                          CHANGING zretlai013_s02-get_perkz_centro.

    PERFORM f_get_from_param USING 'MEABM_DEFECTO'
                          CHANGING zretlai013_s02-get_meabm.

    PERFORM f_get_from_param USING 'DISPO_CENTRO_DEFECTO'
                          CHANGING zretlai013_s02-get_dispo_centro.

    PERFORM f_get_from_param USING 'BWSCL_CENTRO_DEFECTO'
                          CHANGING zretlai013_s02-get_bwscl_centro.

    PERFORM f_get_from_param USING 'WSTAW_DEFECTO'
                          CHANGING zretlai013_s02-get_wstaw.



    zretlai013_s02-get_zz1_etiquetas_prd = 'NO'.

*  >APRADAS-11.03.2022 07:53:41-Inicio
*    IF zretlai013_s02-get_situacion = '4'.
*      zretlai013_s02-get_zz1_novedad2_prd = 'SI'.
*    ELSE.
*      zretlai013_s02-get_zz1_novedad2_prd = 'NO'.
*    ENDIF.

*   Determinar si el nuevo artículo debe considerarse novedad o no
    perform f_determinar_si_es_novedad using zretlai013_s02-get_fecha_publicacion
                                    CHANGING zretlai013_s02-get_zz1_novedad2_prd.
*  <APRADAS-11.03.2022 07:53:41-Fin

    zretlai013_s02-get_precio_con_iva_datab = sy-datum.
    zretlai013_s02-get_precio_con_iva_datbi = '99991231'.

    zretlai013_s02-get_precio_sin_iva_datab = sy-datum.
    zretlai013_s02-get_precio_sin_iva_datbi = '99991231'.

    zretlai013_s02-get_situacion_datab = sy-datum.
  ENDIF.
ENDFORM.


*&---------------------------------------------------------------------*
*& Form f_get_editorial
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      <-- LD_MFRNR
*&---------------------------------------------------------------------*
FORM f_get_editorial    USING    pe_ean11
                        CHANGING ps_mfrnr
                                 ps_mfrnrt.
* 0.- Declaración de variables
*===================================================================================================
  DATA: ld_ean11        TYPE ean11,
        ld_ean11_like   TYPE char20,
        ld_ean11_strlen TYPE ean11.

* 1.- Lógica
*===================================================================================================
  CLEAR ps_mfrnr.

* Partimos del EAN y su longitud inicial
  ld_ean11        = pe_ean11.
  ld_ean11_strlen = strlen( pe_ean11 ).

  DO.
*   Reducimos el EAN en 1
    ld_ean11_strlen = ld_ean11_strlen - 1.
    ld_ean11 = ld_ean11(ld_ean11_strlen).

*   Buscamos ese ean en la tabla de determinación de editoriales
    CONCATENATE ld_ean11 '%' INTO ld_ean11_like.

    SELECT SINGLE editorial_lifnr
      FROM zretlai018t02
      INTO ps_mfrnr
     WHERE raiz_isbn LIKE ld_ean11_like.

    IF sy-subrc = 0.
*     Si encontramos editorial, nos salimos
      EXIT.
    ENDIF.

*   Si hemos llegado al final del EAN y no hemos encontrado editorial, nos salimos.
    IF ld_ean11_strlen = 1.
      EXIT.
    ENDIF.
  ENDDO.

  IF ps_mfrnr IS NOT INITIAL.
*    SELECT SINGLE name1
*      FROM lfa1
*      INTO ps_mfrnrt
*     WHERE lifnr = ps_mfrnr.
    SELECT SINGLE name_org1
      FROM but000
      INTO ps_mfrnrt
     WHERE partner = ps_mfrnr.
  ENDIF.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form f_9000_pbo_init_photo
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM f_9000_pbo_init_photo .
  CONSTANTS : cl_rfc_destination  TYPE  rfcdes-rfcdest  VALUE 'SAPHTTPA'.

  DATA: vl_body_length TYPE i.

  DATA: pic_data LIKE w3mime OCCURS 0 WITH HEADER LINE.
  DATA: ld_length TYPE i.

  DATA: vl_url(100) TYPE c .
  DATA: vl_url2(1000) TYPE c .
  DATA: ld_url(1000) TYPE c .

  DATA: ld_buffer TYPE xstring.

  DATA: ld_mime TYPE string.

  DATA: t_response         TYPE TABLE OF text WITH HEADER LINE,
        t_response_headers TYPE TABLE OF text WITH HEADER LINE.



  DATA: lr_mime_rep TYPE REF TO if_mr_api.

  DATA: lv_filename TYPE string.
  DATA: lv_path     TYPE string.
  DATA: lv_fullpath TYPE string.
  DATA: lv_content  TYPE xstring.
  DATA: lv_length   TYPE i.
  DATA: lv_rc TYPE sy-subrc.

  DATA: lt_file TYPE filetable.
  DATA: ls_file LIKE LINE OF lt_file.

  DATA: wa_mara      LIKE mara,
        ld_tipo(100).

  TYPES pic_line(1022) TYPE x.
  DATA  pic_tab TYPE TABLE OF pic_line.



  DATA: p_path TYPE string.

  DATA: lt_data TYPE STANDARD TABLE OF x255.

  p_path = gd_ruta_completa.

  CREATE OBJECT gr_container_photo
    EXPORTING
      container_name              = 'CONTAINER_PHOTO' "'CONT'
*     repid                       = sy-cprog "'ZRFMS_DRIVER_MASTER_FORM'
*     dynnr                       = '0100'
    EXCEPTIONS
      cntl_error                  = 1
      cntl_system_error           = 2
      create_error                = 3
      lifetime_error              = 4
      lifetime_dynpro_dynpro_link = 5
      OTHERS                      = 6.


  CREATE OBJECT image
    EXPORTING
      parent = gr_container_photo.


* Read it from application server
  OPEN DATASET p_path FOR INPUT IN BINARY MODE.
  READ DATASET p_path INTO lv_content .
  CLOSE DATASET p_path.

* Convert
  CALL FUNCTION 'SCMS_XSTRING_TO_BINARY'
    EXPORTING
      buffer     = lv_content
    TABLES
      binary_tab = lt_data.


  CALL FUNCTION 'DP_CREATE_URL'
    EXPORTING
      type    = 'IMAGE'
      subtype = 'GIF'
    TABLES
      data    = lt_data
    CHANGING
      url     = ld_url.

  CALL METHOD image->load_picture_from_url_async
    EXPORTING
      url = ld_url.

  image->set_display_mode( image->display_mode_fit_center ).
*   image->set_display_mode( image->DISPLAY_MODE_NORMAL_CENTER ).

*  cl_gui_cfw=>flush( ).
*
*  cl_gui_cfw=>update_view( ).
ENDFORM.

*&---------------------------------------------------------------------*
*&      Form  f_0200_free_image
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM f_free_image.
  IF image IS NOT INITIAL.
    CALL METHOD image->free
      EXCEPTIONS
        cntl_error        = 1
        cntl_system_error = 2
        OTHERS            = 3.
    IF sy-subrc <> 0.
*     Implement suitable error handling here
    ENDIF.

    FREE image.
  ENDIF.

  IF gr_container_photo IS NOT INITIAL.
    CALL METHOD gr_container_photo->free
      EXCEPTIONS
        cntl_error        = 1
        cntl_system_error = 2
        OTHERS            = 3.
    IF sy-subrc <> 0.
*       MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
*                  WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
    ENDIF.

    FREE gr_container_photo.
  ENDIF.
ENDFORM.                    "f_0200_free_image

*&---------------------------------------------------------------------*
*& Form f_get_valor_etiqueta
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> P_
*&      --> P_
*&      --> LD_RESPONSE
*&      <-- LD_VALOR
*&---------------------------------------------------------------------*
FORM f_get_valor_etiqueta  USING    pe_etiqueta_in
                                    pe_etiqueta_out
                                    pe_response
                           CHANGING ps_valor.

  DATA: ld_split_1 TYPE string,
        ld_split_2 TYPE string.

  CLEAR ps_valor.

  SPLIT pe_response AT pe_etiqueta_in INTO ld_split_1 ld_split_2.

  IF ld_split_2 IS NOT INITIAL.
    SPLIT ld_split_2 AT pe_etiqueta_out INTO ld_split_1 ld_split_2.

    ps_valor = ld_split_1.
  ENDIF.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form f_get_valor_etiqueta
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> P_
*&      --> P_
*&      --> LD_RESPONSE
*&      <-- LD_VALOR
*&---------------------------------------------------------------------*
FORM f_get_valor_largo  TABLES   it_texto STRUCTURE tline
                        USING    pe_etiqueta_in
                                 pe_etiqueta_out
                                 pe_response.

  DATA: ld_split_1 TYPE string,
        ld_split_2 TYPE string.

  REFRESH: it_texto.
  CLEAR:   it_texto.

  SPLIT pe_response AT pe_etiqueta_in INTO ld_split_1 ld_split_2.

  IF ld_split_2 IS NOT INITIAL.
    SPLIT ld_split_2 AT pe_etiqueta_out INTO ld_split_1 ld_split_2.

    DO.
      IF strlen( ld_split_1 ) > 132.
        it_texto-tdformat = '*'.
        it_texto-tdline = ld_split_1(132).
        ld_split_1 = ld_split_1+132.
        APPEND it_texto.
      ELSE.
        it_texto-tdformat = '*'.
        it_texto-tdline = ld_split_1.
        APPEND it_texto.

        EXIT.
      ENDIF.
    ENDDO.
  ENDIF.
ENDFORM.

*===================================================================================================
*& Form f_user_command_9000_crear_art
*===================================================================================================
*& Lanza el proceso de creación del artículo
*===================================================================================================
FORM f_user_command_9000_crear_art .
* 0.- Declaración de variables
*===================================================================================================
  DATA: wa_zretlai013_t01         LIKE zretlai013_t01,
        lit_zretlai013_t02        LIKE zretlai013_t02 OCCURS 0 WITH HEADER LINE,
        ld_cont                   TYPE int4,
        ld_respuesta              TYPE char1,
        lf_error(1),
        lf_error_b(1),
        ld_mode(1)                VALUE 'N',
        lr_headdata               LIKE bapie1mathead,
        lr_return                 LIKE bapireturn1,
        lr_header                 LIKE thead,
        lit_lines                 LIKE tline              OCCURS 0 WITH HEADER LINE,
        lit_clientdata            LIKE bapie1marart       OCCURS 0 WITH HEADER LINE,
        lit_clientdatax           LIKE bapie1marartx      OCCURS 0 WITH HEADER LINE,
        lit_materialdescription   LIKE bapie1maktrt       OCCURS 0 WITH HEADER LINE,
        lit_unitsofmeasure        LIKE bapie1marmrt       OCCURS 0 WITH HEADER LINE,
        lit_unitsofmeasurex       LIKE bapie1marmrtx      OCCURS 0 WITH HEADER LINE,
        lit_addnclientdata        LIKE bapie1maw1rt       OCCURS 0 WITH HEADER LINE,
        lit_addnclientdatax       LIKE bapie1maw1rtx      OCCURS 0 WITH HEADER LINE,
        lit_internationalartnos   LIKE bapie1meanrt       OCCURS 0 WITH HEADER LINE,
        lit_salesdata             LIKE bapie1mvkert       OCCURS 0 WITH HEADER LINE,
        lit_salesdatax            LIKE bapie1mvkertx      OCCURS 0 WITH HEADER LINE,
        lit_mensajes              LIKE bdcmsgcoll         OCCURS 0 WITH HEADER LINE,
        lit_plantdata             LIKE bapie1marcrt       OCCURS 0 WITH HEADER LINE,
        lit_plantdatax            LIKE bapie1marcrtx      OCCURS 0 WITH HEADER LINE,
        lit_t001w                 LIKE t001w              OCCURS 0 WITH HEADER LINE,
        lit_warehousenumberdata   LIKE bapie1mlgnrt       OCCURS 0 WITH HEADER LINE,
        lit_warehousenumberdatax  LIKE bapie1mlgnrtx      OCCURS 0 WITH HEADER LINE,
        lit_storagelocationdata   LIKE bapie1mardrt       OCCURS 0 WITH HEADER LINE,
        lit_storagelocationdatax  LIKE bapie1mardrtx      OCCURS 0 WITH HEADER LINE,
        lit_storagetypedata       LIKE bapie1mlgtrt       OCCURS 0 WITH HEADER LINE,
        lit_storagetypedatax      LIKE bapie1mlgtrtx      OCCURS 0 WITH HEADER LINE,
        ld_catalogar_ok           TYPE xflag,
        ld_docnum                 TYPE edi_docnum,
        lit_recipientparameters   LIKE bapi_wrpl_import   OCCURS 0 WITH HEADER LINE,
        lit_recipientparametersx  LIKE bapi_wrpl_importx  OCCURS 0 WITH HEADER LINE,
        lit_return                LIKE bapiret2           OCCURS 0 WITH HEADER LINE,
        lit_taxclassifications    LIKE bapie1mlanrt       OCCURS 0 WITH HEADER LINE,
        lit_return_wrf            TYPE bapi_wrf_return_tty,
        lr_hierarchy_data         TYPE bapi_wrf_hier_change_head,
        lr_testrun                TYPE bapi_wrf_testrun_sty,
        lit_hierarchy_structure   TYPE bapi_wrf_hier_ch_struc_tty,
        lit_description_hierarchy TYPE bapi_wrf_desc_ch_hier_tty,
        lit_description_structure TYPE bapi_wrf_desc_ch_struc_tty,
        lit_hierarchy_items       TYPE bapi_wrf_hier_ch_items_tty,
        wa_hierarchy_items        TYPE bapi_wrf_hier_change_items,
        lit_extensionin           TYPE bapi_wrf_extension_tty,
        wa_return                 LIKE bapiret2,
        ld_paso_alta_articulo(2),
        ld_paso_jerarquia(2),
        ld_paso_alta_textos(2),
        ld_paso_catalogar(2),
        ld_paso_reg_info(2),
        ld_paso_cond_ztar(2),
        ld_paso_act_status(2),
        ld_paso_stock_objetivo(2),
        lf_lifnr_9000(1),
        lf_lifnr_2000(1),
        ld_linea                  TYPE numc2,
        ld_dimensiones            LIKE mara-groes,
        wa_lfa1                   TYPE lfa1,
        wa_adrc                   TYPE adrc,
        wa_lagp                   LIKE lagp,
        wa_mlgt                   LIKE mlgt,
        ld_area_alm               LIKE mlgn-lgbkz,
        lit_zretlai001_t04        LIKE zretlai001_t04 OCCURS 0 WITH HEADER LINE,
        ld_get_dismm_tienda       LIKE zretlai013_s02-get_dismm_tienda,
        ld_get_sobst_tienda       LIKE zretlai013_s02-get_sobst_tienda.

* 1.- Lógica
*===================================================================================================
*>Inicializamos log
  REFRESH git_log.
  REFRESH git_log_all.

*>Validar que se hayan informado los datos requeridos en pantalla
  PERFORM f_validar_datos_pantalla.

  IF git_log[] IS NOT INITIAL.
    CALL SCREEN 0200 STARTING AT 5 5.
  ENDIF.

  READ TABLE git_log WITH KEY tipo = gc_minisemaforo_rojo.

  IF sy-subrc = 0.
    EXIT.
  ENDIF.

*>Msg: ¿Crear artículo en el sistema?
  PERFORM f_popup_to_confirm USING TEXT-q01 CHANGING ld_respuesta.

  IF ld_respuesta <> '1'.
    EXIT.
  ENDIF.

*===================================================================================================
*>Grabar todos los datos del CEGAL en la tabla intermedia
*===================================================================================================
* Datos generales
  MOVE-CORRESPONDING zretlai013_s02 TO wa_zretlai013_t01.
  wa_zretlai013_t01-get_erdat = sy-datum.
  wa_zretlai013_t01-get_erzet = sy-uzeit.
  wa_zretlai013_t01-get_ernam = sy-uname.

* Resumen
  CLEAR ld_cont.
  LOOP AT git_resumen.
    ADD 1 TO ld_cont.

    lit_zretlai013_t02-ean11  = zretlai013_s02-get_ean11.
    lit_zretlai013_t02-concepto = 'RESUMEN'.
    lit_zretlai013_t02-linea = ld_cont.
    lit_zretlai013_t02-valor = git_resumen-tdline.
    APPEND lit_zretlai013_t02.
  ENDLOOP.

* Biografía
  CLEAR ld_cont.
  LOOP AT git_biografia.
    ADD 1 TO ld_cont.

    lit_zretlai013_t02-ean11  = zretlai013_s02-get_ean11.
    lit_zretlai013_t02-concepto = 'BIOGRAFIA'.
    lit_zretlai013_t02-linea = ld_cont.
    lit_zretlai013_t02-valor = git_biografia-tdline.
    APPEND lit_zretlai013_t02.
  ENDLOOP.

* Índice
  CLEAR ld_cont.
  LOOP AT git_indice.
    ADD 1 TO ld_cont.

    lit_zretlai013_t02-ean11  = zretlai013_s02-get_ean11.
    lit_zretlai013_t02-concepto = 'INDICE'.
    lit_zretlai013_t02-linea = ld_cont.
    lit_zretlai013_t02-valor = git_indice-tdline.
    APPEND lit_zretlai013_t02.
  ENDLOOP.

  DELETE FROM zretlai013_t01
        WHERE get_ean11 = zretlai013_s02-get_ean11.

  DELETE FROM zretlai013_t02
        WHERE ean11 = zretlai013_s02-get_ean11.

  COMMIT WORK AND WAIT.

  MODIFY zretlai013_t01 FROM wa_zretlai013_t01.
  MODIFY zretlai013_t02 FROM TABLE lit_zretlai013_t02.

  COMMIT WORK AND WAIT.

*===================================================================================================
*>Crear artículo en SAP
*===================================================================================================
*===================================================================================================
* P1->Crear artículo
*===================================================================================================

* Obtener número de artículo
  PERFORM f_get_numero_articulo             CHANGING zretlai013_s02-matnr.
  PERFORM f_fill_01_headdata                CHANGING lr_headdata.
  PERFORM f_fill_02_clientdata              TABLES lit_clientdata
                                                   lit_clientdatax.
  PERFORM f_fill_03_addnclientdata          TABLES lit_addnclientdata
                                                   lit_addnclientdatax.
  PERFORM f_fill_04_unitsofmeasure          TABLES lit_unitsofmeasure
                                                   lit_unitsofmeasurex.
  PERFORM f_fill_05_materialdescription     TABLES lit_materialdescription.
  PERFORM f_fill_06_salesdata               TABLES lit_salesdata
                                                   lit_salesdatax.
  PERFORM f_fill_07_plantdata               TABLES lit_plantdata
                                                   lit_plantdatax.
  PERFORM f_fill_08_storagelocationdata     TABLES lit_storagelocationdata
                                                   lit_storagelocationdatax.
  PERFORM f_fill_09_taxclassificactions     TABLES lit_taxclassifications.

  CALL FUNCTION 'BAPI_MATERIAL_MAINTAINDATA_RT'
    EXPORTING
      headdata             = lr_headdata
    IMPORTING
      return               = lr_return
    TABLES
*     VARIANTSKEYS         =
*     CHARACTERISTICVALUE  =
*     CHARACTERISTICVALUEX =
      clientdata           = lit_clientdata
      clientdatax          = lit_clientdatax
*     CLIENTEXT            =
*     CLIENTEXTX           =
      addnlclientdata      = lit_addnclientdata
      addnlclientdatax     = lit_addnclientdatax
      materialdescription  = lit_materialdescription
      plantdata            = lit_plantdata
      plantdatax           = lit_plantdatax
*     PLANTEXT             =
*     PLANTEXTX            =
*     FORECASTPARAMETERS   =
*     FORECASTPARAMETERSX  =
*     FORECASTVALUES       =
*     TOTALCONSUMPTION     =
*     UNPLNDCONSUMPTION    =
*     PLANNINGDATA         =
*     PLANNINGDATAX        =
      storagelocationdata  = lit_storagelocationdata
      storagelocationdatax = lit_storagelocationdatax
*     STORAGELOCATIONEXT   =
*     STORAGELOCATIONEXTX  =
      unitsofmeasure       = lit_unitsofmeasure
      unitsofmeasurex      = lit_unitsofmeasurex
*     unitofmeasuretexts   =
      internationalartnos  = lit_internationalartnos
*     VENDOREAN            =
*     LAYOUTMODULEASSGMT   =
*     LAYOUTMODULEASSGMTX  =
      taxclassifications   = lit_taxclassifications
*     VALUATIONDATA        =
*     VALUATIONDATAX       =
*     VALUATIONEXT         =
*     VALUATIONEXTX        =
      warehousenumberdata  = lit_warehousenumberdata
      warehousenumberdatax = lit_warehousenumberdatax
*     WAREHOUSENUMBEREXT   =
*     WAREHOUSENUMBEREXTX  =
      storagetypedata      = lit_storagetypedata
      storagetypedatax     = lit_storagetypedatax
*     STORAGETYPEEXT       =
*     STORAGETYPEEXTX      =
      salesdata            = lit_salesdata
      salesdatax           = lit_salesdatax
*     SALESEXT             =
*     SALESEXTX            =
*     POSDATA              =
*     POSDATAX             =
*     POSEXT               =
*     POSEXTX              =
*     MATERIALLONGTEXT     =
*     PLANTKEYS            =
*     STORAGELOCATIONKEYS  =
*     DISTRCHAINKEYS       =
*     WAREHOUSENOKEYS      =
*     STORAGETYPEKEYS      =
*     VALUATIONTYPEKEYS    =
    .

*  Hacemos commit
  CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
    EXPORTING
      wait = 'X'
*    IMPORTING
*     RETURN        =
    .

*  Si error al crear articulo, registrar log y finalizar ejecución
  IF lr_return-type = 'E'.
*   Si ERROR...

*   Activamos Flag de error
    lf_error = 'X'.

*   Grabar Log
    CLEAR git_log_all.
    git_log_all-matnr   = zretlai013_s02-matnr.
    git_log_all-matnrt  = zretlai013_s02-get_titulo.
    git_log_all-status  = gc_minisemaforo_rojo.
    git_log_all-paso    = 'P01'.
    git_log_all-pasot   = 'Crear articulo en SAP'.
    git_log_all-mensaje = lr_return-message.
    git_log_all-mm90    = lr_return-message_v2.
    APPEND git_log_all.
  ELSE.
*   Si articulo creado correctamente, registramos log...

*   Registramos entrada de log
    CLEAR git_log_all.
    git_log_all-matnr   = zretlai013_s02-matnr.
    git_log_all-matnrt  = zretlai013_s02-get_titulo.
    git_log_all-status  = gc_minisemaforo_verde.
    git_log_all-paso    = 'P01'.
    git_log_all-pasot   = 'Crear articulo en SAP'.
    git_log_all-mensaje = 'Artículo creado en el sistema'.
    APPEND git_log_all.

*   Replicamos los textos breves del articulo en textos comerciales
    PERFORM f_crear_articulos_update_tcom.
  ENDIF.


*===================================================================================================
* P2->Actualizar campos ZZ de la MARA
*===================================================================================================
  IF lf_error = ''.
*   >APRADAS-28.10.2021 09:26:38-Inicio
*   Obtener de nuevo la denominación del formato por si ha cambiado
    PERFORM f_get_encuadernaciont USING    zretlai013_s02-get_encuadernacion
                                           zretlai013_s02-get_tipo_producto
                                           zretlai013_s02-get_mtart
                                  CHANGING zretlai013_s02-get_encuadernaciont.
*   <APRADAS-28.10.2021 09:26:38-Fin

    UPDATE mara SET zz1_autor_prd               = zretlai013_s02-get_nombre_autor
                    zz1_idiomaoriginal2_prd      = zretlai013_s02-get_idioma_original
                    zz1_traductor_prd           = zretlai013_s02-get_traductor
                    zz1_ilustrador_prd          = zretlai013_s02-get_ilustrador_cubierta
                    zz1_urlportada_prd          = zretlai013_s02-get_url
                    zz1_coleccion_prd           = zretlai013_s02-get_coleccion
                    zz1_cdu_prd                 = zretlai013_s02-get_cdu
                    zz1_ibic_prd                = zretlai013_s02-get_ibic
                    zz1_idioma2_prd              = zretlai013_s02-get_lengua_publicacion
                    zz1_numeroedicion_prd       = zretlai013_s02-get_numero_edicion
                    zz1_subttulo_prd            = zretlai013_s02-get_subtitulo
                    zz1_formato_prd             = zretlai013_s02-get_encuadernaciont                "APRADAS-28.10.2021
                    zz1_fechaedicin_prd         = zretlai013_s02-get_fecha_publicacion
                    zz1_npginas_prd             = zretlai013_s02-get_numero_paginas
                    zz1_etiquetas_prd           = zretlai013_s02-get_zz1_etiquetas_prd
                    zz1_tejueloalad_prd         = zretlai013_s02-get_zz1_tejueloalad_prd
                    zz1_novedad2_prd            = zretlai013_s02-get_zz1_novedad2_prd
                    mfrnr                       = zretlai013_s02-get_mfrnr
                    zz1_desceditorial_prd       = zretlai013_s02-get_mfrnrt
                    zz1_produccinpropia_prd     =  'NO'
                    zz1_cumplenormasegurid_prd  =  'NO'
                    zz1_envoltorioproviene_prd  =  'NO'
                    zz1_materialproducto_prd    =  'NO'
                    zz1_noaptomenores3aos_prd   =  'NO'
                    zz1_nocontenedorcomun_prd   =  'NO'
                    zz1_productoartesanal_prd   =  'NO'
                    zz1_productosocial_prd      =  'NO'
                    zz1_productosostenible_prd  =  'NO'
                    zz1_sistemagestinrecic_prd  =  'NO'
                    zz1_productolocal_prd       =  'NO'

       WHERE matnr = zretlai013_s02-matnr.

    CLEAR git_log_all.
    git_log_all-matnr   = zretlai013_s02-matnr.
    git_log_all-matnrt  = zretlai013_s02-get_titulo.
    git_log_all-status  = gc_minisemaforo_verde.
    git_log_all-paso    = 'P02'.
    git_log_all-pasot   = 'Actualizar datos cliente (ZZ)'.
    git_log_all-mensaje = 'Datos actualizados en artículo'.
    APPEND git_log_all.
*    endif.
  ENDIF.

*===================================================================================================
* P3->Actualizar código de importación
*===================================================================================================
  IF lf_error = ''.
    IF zretlai013_s02-get_wstaw IS NOT INITIAL.
      PERFORM f_set_stawn  USING zretlai013_s02-matnr
                                 zretlai013_s02-get_wstaw
                        CHANGING lf_error.
    ELSE.
      CLEAR git_log_all.
      git_log_all-matnr   = zretlai013_s02-matnr.
      git_log_all-matnrt  = zretlai013_s02-get_titulo.
      git_log_all-status  = gc_minisemaforo_ambar.
      git_log_all-paso    = 'P03'.
      git_log_all-pasot   = 'Actualizar código de importación'.
      git_log_all-mensaje = 'No aplica'.
      APPEND git_log_all.
    ENDIF.
  ENDIF.

*===================================================================================================
* P4->Actualizar datos reaprovisionamiento (tienda modelo)
*===================================================================================================
*  IF lf_error = ''.
**   Característica planificación de necesidades
*    PERFORM f_get_from_param USING 'DISMM_TIENDA_MODELO_DEFECTO'
*                          CHANGING ld_get_dismm_tienda.
**   Stock objetivo
*    PERFORM f_get_from_param USING 'SOBST_TIENDA_MODELO_DEFECTO'
*                          CHANGING ld_get_sobst_tienda.
*
*
*    IF ( ld_get_sobst_tienda IS NOT INITIAL OR
*         ld_get_dismm_tienda IS NOT INITIAL ).
*
*      REFRESH lit_recipientparameters.
*      CLEAR lit_recipientparameters.
*
*      lit_recipientparameters-recipient     = gd_tienda_modelo.
*      lit_recipientparameters-material      = zretlai013_s02-matnr.
*      lit_recipientparameters-mrp_type      = ld_get_dismm_tienda.
*      lit_recipientparameters-target_stock  = ld_get_sobst_tienda.
*
*      APPEND lit_recipientparameters.
*
*      REFRESH lit_recipientparametersx.
*      CLEAR lit_recipientparametersx.
*
*      lit_recipientparametersx-recipient    = gd_tienda_modelo.
*      lit_recipientparametersx-material     = zretlai013_s02-matnr.
*      lit_recipientparametersx-mrp_type     = 'X'.
*      lit_recipientparametersx-target_stock = 'X'.
*
*      APPEND lit_recipientparametersx.
*
*      REFRESH lit_return.
*      CALL FUNCTION 'BAPI_RTMAT_RPL_SAVEREPLICAMULT'
*        TABLES
*          recipientparameters  = lit_recipientparameters
*          recipientparametersx = lit_recipientparametersx
*          return               = lit_return.
*
**     Hacemos commit
*      CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
*        EXPORTING
*          wait = 'X'
**       IMPORTING
**         RETURN        =
*        .
*
*
*      LOOP AT lit_return INTO wa_return WHERE type = 'E'.
*        EXIT.
*      ENDLOOP.
*
*      IF sy-subrc = 0.
**       Activamos Flag de error
*        lf_error = 'X'.
*
**       Registramos entrada de log
*        CLEAR ld_linea.
*        CLEAR git_log_all.
*
*        ADD 1 TO ld_linea.
*        git_log_all-matnr   = zretlai013_s02-matnr.
*        git_log_all-matnrt  = zretlai013_s02-get_titulo.
*        git_log_all-status  = gc_minisemaforo_rojo.
*        git_log_all-lineam  = ld_linea.
*        git_log_all-paso    = 'P04'.
*        git_log_all-pasot   = 'Actualizar datos reaprovisionamiento (tienda modelo)'.
*        git_log_all-mensaje = '>>ERROR: Inicio log.'.
*        APPEND git_log_all.
*
*        LOOP AT lit_return.
*          ADD 1 TO ld_linea.
*          git_log_all-lineam   = ld_linea.
*          git_log_all-mensaje = lit_return-message.
*          APPEND git_log_all.
*        ENDLOOP.
*
*        ADD 1 TO ld_linea.
*        git_log_all-lineam  = ld_linea.
*        git_log_all-mensaje = '>>ERROR: Fin log.'.
*        APPEND git_log_all.
*
*      ELSE.
**       Registramos entrada de log
*        CLEAR git_log_all.
*        git_log_all-matnr   = zretlai013_s02-matnr.
*        git_log_all-matnrt  = zretlai013_s02-get_titulo.
*        git_log_all-status  = gc_minisemaforo_verde.
*        git_log_all-paso    = 'P04'.
*        git_log_all-pasot   = 'Actualizar datos reaprovisionamiento (tienda modelo)'.
*        git_log_all-mensaje = 'Paso realizado con éxito.'.
*        APPEND git_log_all.
*      ENDIF.
*
*    ELSE.
*      CLEAR git_log_all.
*      git_log_all-matnr   = zretlai013_s02-matnr.
*      git_log_all-matnrt  = zretlai013_s02-get_titulo.
*      git_log_all-status  = gc_minisemaforo_ambar.
*      git_log_all-paso    = 'P04'.
*      git_log_all-pasot   = 'Actualizar datos reaprovisionamiento (tienda modelo)'.
*      git_log_all-mensaje = 'No aplica'.
*      APPEND git_log_all.
*    ENDIF.
*  ENDIF.

*===================================================================================================
* P5->Actualizar datos reaprovisionamiento (centro modelo)
*===================================================================================================
*  IF lf_error = ''.
*    IF ( zretlai013_s02-get_dismm_centro IS NOT INITIAL ).
*
*      REFRESH lit_recipientparameters.
*      CLEAR lit_recipientparameters.
*
*      lit_recipientparameters-recipient     = gd_centro_modelo.
*      lit_recipientparameters-material      = zretlai013_s02-matnr.
*      lit_recipientparameters-mrp_type      = zretlai013_s02-get_dismm_centro.
*
*      APPEND lit_recipientparameters.
*
*      REFRESH lit_recipientparametersx.
*      CLEAR lit_recipientparametersx.
*
*      lit_recipientparametersx-recipient    = gd_centro_modelo.
*      lit_recipientparametersx-material     = zretlai013_s02-matnr.
*      lit_recipientparametersx-mrp_type     = 'X'.
*      APPEND lit_recipientparametersx.
*
*      REFRESH lit_return.
*      CALL FUNCTION 'BAPI_RTMAT_RPL_SAVEREPLICAMULT'
*        TABLES
*          recipientparameters  = lit_recipientparameters
*          recipientparametersx = lit_recipientparametersx
*          return               = lit_return.
*
**     Hacemos commit
*      CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
*        EXPORTING
*          wait = 'X'
**       IMPORTING
**         RETURN        =
*        .
*
*      LOOP AT lit_return INTO wa_return WHERE type = 'E'.
*        EXIT.
*      ENDLOOP.
*
*      IF sy-subrc = 0.
**       Activamos Flag de error
*        lf_error = 'X'.
*
**       Registramos entrada de log
*        CLEAR ld_linea.
*        CLEAR git_log_all.
*
*        ADD 1 TO ld_linea.
*        git_log_all-matnr   = zretlai013_s02-matnr.
*        git_log_all-matnrt  = zretlai013_s02-get_titulo.
*        git_log_all-status  = gc_minisemaforo_rojo.
*        git_log_all-lineam  = ld_linea.
*        git_log_all-paso    = 'P05'.
*        git_log_all-pasot   = 'Actualizar datos reaprovisionamiento (centro modelo)'.
*        git_log_all-mensaje = '>>ERROR: Inicio log.'.
*        APPEND git_log_all.
*
*        LOOP AT lit_return.
*          ADD 1 TO ld_linea.
*          git_log_all-lineam   = ld_linea.
*          git_log_all-mensaje = lit_return-message.
*          APPEND git_log_all.
*        ENDLOOP.
*
*        ADD 1 TO ld_linea.
*        git_log_all-lineam   = ld_linea.
*        git_log_all-mensaje = '>>ERROR: Fin log.'.
*        APPEND git_log_all.
*
*        EXIT.
*      ELSE.
**       Registramos entrada de log
*        CLEAR git_log_all.
*        git_log_all-matnr   = zretlai013_s02-matnr.
*        git_log_all-matnrt  = zretlai013_s02-get_titulo.
*        git_log_all-status  = gc_minisemaforo_verde.
*        git_log_all-paso    = 'P05'.
*        git_log_all-pasot   = 'Actualizar datos reaprovisionamiento (centro modelo)'.
*        git_log_all-mensaje = 'Paso realizado con éxito.'.
*        APPEND git_log_all.
*      ENDIF.
*    ELSE.
*      CLEAR git_log_all.
*      git_log_all-matnr   = zretlai013_s02-matnr.
*      git_log_all-matnrt  = zretlai013_s02-get_titulo.
*      git_log_all-status  = gc_minisemaforo_ambar.
*      git_log_all-paso    = 'P05'.
*      git_log_all-pasot   = 'Actualizar datos reaprovisionamiento (centro modelo)'.
*      git_log_all-mensaje = 'No aplica'.
*      APPEND git_log_all.
*    ENDIF.
*  ENDIF.

*===================================================================================================
* P6->Catalogar
*===================================================================================================
  IF lf_error = ''.
    PERFORM f_catalogar USING zretlai013_s02-matnr gc_modo_online CHANGING lf_error ld_docnum.

    CLEAR git_log_all.
    git_log_all-matnr   = zretlai013_s02-matnr.
    git_log_all-matnrt  = zretlai013_s02-get_titulo.
    git_log_all-status  = gc_minisemaforo_rojo.
    git_log_all-paso    = 'P06'.
    git_log_all-pasot   = 'Catalogar artículo'.
    IF lf_error = 'X'.
      git_log_all-status  = gc_minisemaforo_rojo.
      CONCATENATE 'Catalogación incorrecta: Idoc'  ld_docnum
             INTO git_log_all-mensaje
        SEPARATED BY space.
    ELSE.
      git_log_all-status  = gc_minisemaforo_verde.
      CONCATENATE 'Catalogación correcta: Idoc'  ld_docnum
             INTO git_log_all-mensaje
        SEPARATED BY space.
    ENDIF.

    APPEND git_log_all.
  ENDIF.

*===================================================================================================
* P61->Actualizar datos centro tienda usuario
*===================================================================================================
  IF lf_error = ''.
    PERFORM f_crear_articulos_update_tdxx CHANGING lf_error.
  ENDIF.

*===================================================================================================
* P62->Actualizar datos planificacion tienda usuario
*===================================================================================================
  IF lf_error = ''.
    PERFORM f_crear_articulos_update_tdxxp CHANGING lf_error.
  ENDIF.

*===================================================================================================
* P7-> Registro info
*===================================================================================================
  IF lf_error = ''.
    IF git_proveedores_editorial[] IS NOT INITIAL.
      PERFORM f_crear_articulos_update_prov CHANGING lf_error.
    ELSE.
      CLEAR git_log_all.
      git_log_all-matnr   = zretlai013_s02-matnr.
      git_log_all-matnrt  = zretlai013_s02-get_titulo.
      git_log_all-status  = gc_minisemaforo_ambar.
      git_log_all-paso    = 'P07'.
      git_log_all-pasot   = 'Alta registro info'.
      git_log_all-mensaje = 'Ningún registro info necesario'.
      APPEND git_log_all.
    ENDIF.
  ENDIF.

*===================================================================================================
* P8->Condición de venta VKP0/VKP1
*===================================================================================================
  IF lf_error = ''.
    IF zretlai013_s02-get_precio_con_iva IS NOT INITIAL.
      PERFORM f_crear_articulos_update_pvp USING gc_modo_online
                                                 zretlai013_s02-matnr
                                                 zretlai013_s02-get_titulo
                                        CHANGING lf_error.
    ELSE.
      CLEAR git_log_all.
      git_log_all-matnr   = zretlai013_s02-matnr.
      git_log_all-matnrt  = zretlai013_s02-get_titulo.
      git_log_all-status  = gc_minisemaforo_ambar.
      git_log_all-paso    = 'P08'.
      git_log_all-pasot   = 'Alta PVP'.
      git_log_all-mensaje = 'No aplica'.
      APPEND git_log_all.
    ENDIF.
  ENDIF.

*===================================================================================================
* P9->Textos: Resumen
*===================================================================================================
  IF lf_error = ''.
    CALL METHOD gr_editor->get_text_as_r3table
*      EXPORTING
*        only_when_modified     = FALSE
      IMPORTING
        table                  = git_lineas_texto_final[]
*       is_modified            =
      EXCEPTIONS
        error_dp               = 1
        error_cntl_call_method = 2
        error_dp_create        = 3
        potential_data_loss    = 4
        OTHERS                 = 5.

    IF sy-subrc <> 0. ENDIF.

    IF git_lineas_texto_final[] IS NOT INITIAL.
      PERFORM f_crear_articulos_update_redi CHANGING lf_error.
    ELSE.
      CLEAR git_log_all.
      git_log_all-matnr   = zretlai013_s02-matnr.
      git_log_all-matnrt  = zretlai013_s02-get_titulo.
      git_log_all-status  = gc_minisemaforo_ambar.
      git_log_all-paso    = 'P09'.
      git_log_all-pasot   = 'Textos: Resumen'.
      git_log_all-mensaje = 'No aplica'.
      APPEND git_log_all.
    ENDIF.
  ENDIF.

*===================================================================================================
* P10->Textos: Referencias libreria
*===================================================================================================
*  if lf_error = ''.
*    if git_monitor-status_p10 = gc_minisemaforo_inactivo or
*       git_monitor-status_p10 = gc_minisemaforo_rojo.
*
*
*      if git_monitor-db_textos_libreria = gc_minisemaforo_verde.
*        perform f_crear_articulos_update_rlib CHANGING lf_error.
*
*        IF lf_error = 'X'.
*          git_monitor-status_p10 = gc_minisemaforo_rojo.
*          git_monitor-log       = gc_icono_log.
*        ELSE.
*          git_monitor-status_p10 = gc_minisemaforo_verde.
*          git_monitor-log       = gc_icono_log.
*        ENDIF.
*      else.
*        git_monitor-status_p10 = gc_minisemaforo_ambar.
*        git_monitor-log       = gc_icono_log.
*
*        CLEAR git_log_all.
*        git_log_all-linea   = git_monitor-linea.
*        git_log_all-matnr   = ZRETLAI013_S02-matnr.
*        git_log_all-matnrt  = ZRETLAI013_S02-get_TITULO.
*        git_log_all-status  = gc_minisemaforo_ambar.
*        git_log_all-paso    = 'P10'.
*        git_log_all-pasot   = 'Textos: Referencias Librería'.
*        git_log_all-mensaje = 'No aplica'.
*        APPEND git_log_all.
*      endif.
*    endif.
*  endif.

*===================================================================================================
* P11->Datos planificación tienda
*===================================================================================================
*  IF lf_error = ''.
*    IF zretlai013_s02-get_dismm_tienda IS NOT INITIAL OR
*       zretlai013_s02-get_sobst_tienda IS NOT INITIAL.
*      PERFORM f_crear_articulos_update_plani CHANGING lf_error.
*    ELSE.
*      CLEAR git_log_all.
*      git_log_all-matnr   = zretlai013_s02-matnr.
*      git_log_all-matnrt  = zretlai013_s02-get_titulo.
*      git_log_all-status  = gc_minisemaforo_ambar.
*      git_log_all-paso    = 'P11'.
*      git_log_all-pasot   = 'Datos planificación tienda'.
*      git_log_all-mensaje = 'No aplica'.
*      APPEND git_log_all.
*    ENDIF.
*  ENDIF.

*===================================================================================================
* P12-> Verificación surtidos
*===================================================================================================
  IF lf_error = ''.
    PERFORM f_crear_articulos_verif_surt CHANGING lf_error.

    CLEAR git_log_all.
    git_log_all-matnr   = zretlai013_s02-matnr.
    git_log_all-matnrt  = zretlai013_s02-get_titulo.
    git_log_all-paso    = 'P12'.
    git_log_all-pasot   = 'Verificación surtidos'.
    git_log_all-status  = gc_minisemaforo_verde.
    git_log_all-mensaje = 'Verificación ejecutada'.
    APPEND git_log_all.
  ENDIF.

  CALL SCREEN 0300 STARTING AT 10 10.

  LOOP AT git_log_all WHERE status = gc_minisemaforo_rojo.
    EXIT.
  ENDLOOP.

  IF sy-subrc = 0.
    IF git_log_all-paso <> 'P01'.
      PERFORM f_inicializar_pantalla.
    ENDIF.
  ELSE.
    PERFORM f_inicializar_pantalla.
  ENDIF.
ENDFORM.

*===================================================================================================
*& Form f_crear_articulos_update_tcom
*===================================================================================================
* Actualiza en los textos comerciales del artículo, para todas las areas de venta en las que hemos
* creado el artículo, el título del artículo.
*===================================================================================================
FORM f_crear_articulos_update_tcom .
* 0.- Declaración de variables
*==========================================================================
  DATA: lit_lines LIKE tline              OCCURS 0 WITH HEADER LINE,
        lr_header LIKE thead,
        ld_lineam TYPE int4,
        BEGIN OF lit_idiomas OCCURS 0,
          idioma TYPE spras,
          texto  TYPE text255,
        END OF lit_idiomas,
        ld_obname TYPE tdobname.

* 1.- Lógica
*==========================================================================
  IF zretlai013_s02-get_titulo IS NOT INITIAL.
    lit_idiomas-idioma = 'S'.
    IF zretlai013_s01-sap = ''.
      lit_idiomas-texto  = zretlai013_s02-get_titulo.
    ELSE.
      lit_idiomas-texto  = zretlai013_s02-get_titulo_cegal.
    ENDIF.
    APPEND lit_idiomas.

*   Grabamos el título ES en CA y EN si el artículo es ZLIB, ZAUD o ZEBK
    IF zretlai013_s02-get_mtart = 'ZLIB' OR
       zretlai013_s02-get_mtart = 'ZAUD' OR
       zretlai013_s02-get_mtart = 'ZEBK'.
*     Añadir titulo CA para actualizar
      lit_idiomas-idioma = 'c'.
      IF zretlai013_s01-sap = ''.
        lit_idiomas-texto  = zretlai013_s02-get_titulo.
      ELSE.
        lit_idiomas-texto  = zretlai013_s02-get_titulo_cegal.
      ENDIF.
      APPEND lit_idiomas.

*     Añadir titulo EN para actualizar
      lit_idiomas-idioma = 'E'.
      IF zretlai013_s01-sap = ''.
        lit_idiomas-texto  = zretlai013_s02-get_titulo.
      ELSE.
        lit_idiomas-texto  = zretlai013_s02-get_titulo_cegal.
      ENDIF.
      APPEND lit_idiomas.
    ENDIF.
  ENDIF.

  lr_header-tdobject = 'MVKE'.
  lr_header-tdid     = '0001'.

  LOOP AT git_areas_de_venta.
    ld_obname     = zretlai013_s02-matnr.
    ld_obname+40  = git_areas_de_venta-valor1.
    ld_obname+44  = git_areas_de_venta-valor2.
    lr_header-tdname   = ld_obname.

    LOOP AT lit_idiomas.
      ADD 1 TO ld_lineam.

      lr_header-tdspras  = lit_idiomas-idioma.


      REFRESH: lit_lines.

      DO.
        IF strlen( lit_idiomas-texto ) > 132.
          lit_lines-tdformat = '*'.
          lit_lines-tdline   = lit_idiomas-texto(132).
          APPEND lit_lines.

          lit_idiomas-texto = lit_idiomas-texto+132.
        ELSE.
          lit_lines-tdformat = '*'.
          lit_lines-tdline   = lit_idiomas-texto.
          APPEND lit_lines.

          EXIT.
        ENDIF.
      ENDDO.

      CALL FUNCTION 'SAVE_TEXT'
        EXPORTING
*         CLIENT          = SY-MANDT
          header          = lr_header
          insert          = 'X'
          savemode_direct = ''
*         OWNER_SPECIFIED = ' '
*         LOCAL_CAT       = ' '
*       IMPORTING
*         FUNCTION        =
*         NEWHEADER       =
        TABLES
          lines           = lit_lines
        EXCEPTIONS
          id              = 1
          language        = 2
          name            = 3
          object          = 4
          OTHERS          = 5.

      IF sy-subrc <> 0. ENDIF.

      CALL FUNCTION 'COMMIT_TEXT'
*       EXPORTING
*         OBJECT                = '*'
*         NAME                  = '*'
*         ID                    = '*'
*         LANGUAGE              = '*'
*         SAVEMODE_DIRECT       = ' '
*         KEEP                  = ' '
*         LOCAL_CAT             = ' '
*       IMPORTING
*         COMMIT_COUNT          =
*       TABLES
*         T_OBJECT              =
*         T_NAME                =
*         T_ID                  =
*         T_LANGUAGE            =
        .

      COMMIT WORK AND WAIT.

      CALL FUNCTION 'DB_COMMIT'
*       EXPORTING
*         IV_DEFAULT       = ABAP_FALSE
        .
    ENDLOOP.
  ENDLOOP.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form f_crear_articulos_update_plani
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      <-- LF_ERROR
*&---------------------------------------------------------------------*
FORM f_crear_articulos_update_plani  CHANGING ps_error.
* 0.- Declaración de variables
*===================================================================================================
  DATA: BEGIN OF lit_werks OCCURS 0,
          werks LIKE marc-werks,
        END OF lit_werks,

        ld_linea                 TYPE numc2,

        lit_recipientparameters  LIKE bapi_wrpl_import OCCURS 0 WITH HEADER LINE,
        lit_recipientparametersx LIKE bapi_wrpl_importx OCCURS 0 WITH HEADER LINE,
        lit_return               LIKE bapiret2 OCCURS 0 WITH HEADER LINE.


* 1.- Lógica
*===================================================================================================
*>Inicializar retorno
  ps_error = ''.

*>Obtenemos las tiendas en las que se ha dado de alta el artículo
  SELECT marc~werks
    FROM marc JOIN t001w ON t001w~werks = marc~werks AND t001w~vlfkz = 'A'
    INTO TABLE lit_werks
   WHERE marc~matnr = zretlai013_s02-matnr.

*>Rellenamos datos de planificación para la bapi
  LOOP AT lit_werks.
    CLEAR: lit_recipientparameters,
           lit_recipientparametersx.

    lit_recipientparameters-recipient     = lit_werks-werks.                                        "Centro
    lit_recipientparametersx-recipient    = 'X'.

    lit_recipientparameters-material      = zretlai013_s02-matnr.                                   "Artículo
    lit_recipientparametersx-material     = 'X'.

    IF zretlai013_s02-get_dismm_tienda IS NOT INITIAL.                                              "Característica de planificación de necesidades
      lit_recipientparameters-mrp_type      = zretlai013_s02-get_dismm_tienda.
      lit_recipientparametersx-mrp_type     = 'X'.
    ENDIF.

    IF zretlai013_s02-get_sobst_tienda IS NOT INITIAL.
      lit_recipientparameters-target_stock      = zretlai013_s02-get_sobst_tienda.                  "Stock objetivo
      lit_recipientparametersx-target_stock     = 'X'.
    ENDIF.

    APPEND: lit_recipientparameters,
            lit_recipientparametersx.
  ENDLOOP.

*>Llamamos a la bapi
  CALL FUNCTION 'BAPI_RTMAT_RPL_SAVEREPLICAMULT'
    TABLES
      recipientparameters  = lit_recipientparameters
      recipientparametersx = lit_recipientparametersx
      return               = lit_return.

* Hacemos commit
  CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
    EXPORTING
      wait = 'X'
*   IMPORTING
*     RETURN        =
    .

  CLEAR git_log_all.
  git_log_all-matnr   = zretlai013_s02-matnr.
  git_log_all-matnrt  = zretlai013_s02-get_titulo.
  git_log_all-paso    = 'P11'.
  git_log_all-pasot   = 'Datos Planificación Tienda'.

  LOOP AT lit_return WHERE type = 'E'.
    EXIT.
  ENDLOOP.

  IF sy-subrc = 0.
    ps_error = 'X'.

    ADD 1 TO ld_linea.

    git_log_all-status  = gc_minisemaforo_rojo.
    git_log_all-mensaje = '>>ERROR: Inicio Log.'.
    git_log_all-lineam  = ld_linea.
    APPEND git_log_all.

    LOOP AT lit_return.
      ADD 1 TO ld_linea.
      git_log_all-lineam   = ld_linea.
      git_log_all-mensaje  = lit_return-message.
      APPEND git_log_all.
    ENDLOOP.

    ADD 1 TO ld_linea.
    git_log_all-lineam  = ld_linea.
    git_log_all-mensaje = '>>ERROR: Fin Log.'.
    APPEND git_log_all.
  ELSE.
    git_log_all-status  = gc_minisemaforo_verde.
    git_log_all-mensaje = 'Paso realizado con éxito'.
    APPEND git_log_all.
  ENDIF.
ENDFORM.


*&---------------------------------------------------------------------*
*& Form F_SAVE_TEXT
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> P_
*&      --> GIT_FILE1_ZZINGREDIENTES
*&---------------------------------------------------------------------*
FORM f_crear_articulos_update_redi CHANGING   ps_error.

* 0.- Declaración de variables
*==========================================================================
  DATA: lit_lines LIKE tline              OCCURS 0 WITH HEADER LINE,
        lr_header LIKE thead,
        ld_lineam TYPE int4,
        BEGIN OF lit_idiomas OCCURS 0,
          idioma TYPE spras,
        END OF lit_idiomas.

* 1.- Lógica
*==========================================================================
* El resumen se grabará siempre en idioma ES
  lit_idiomas-idioma = 'S'.
  APPEND lit_idiomas.

* Replicaremos el resumen ES en CA y EN si el articulo que creamos es ZLIB, ZAUD o ZEBK
  IF zretlai013_s02-get_mtart = 'ZLIB' OR
     zretlai013_s02-get_mtart = 'ZAUD' OR
     zretlai013_s02-get_mtart = 'ZEBK'.

*   Añadir idioma CA
    lit_idiomas-idioma = 'c'.
    APPEND lit_idiomas.

*   Añadir idioma EN
    lit_idiomas-idioma = 'E'.
    APPEND lit_idiomas.
  ENDIF.

  LOOP AT lit_idiomas.
*   Para cada idioma a actualizar...

*   Datos de cabecera del texto
    lr_header-tdobject = 'MATERIAL'.
    lr_header-tdid     = 'GRUN'.
    lr_header-tdname   = zretlai013_s02-matnr.
    lr_header-tdspras  = lit_idiomas-idioma.

*   Incrementar contador de log del paso
    ADD 1 TO ld_lineam.


*   Inicializar mensaje de log
    CLEAR git_log_all.
    git_log_all-matnr   = zretlai013_s02-matnr.
    git_log_all-matnrt  = zretlai013_s02-get_titulo.
    git_log_all-lineam  = ld_lineam.
    git_log_all-paso    = 'P09'.
    CASE lit_idiomas-idioma.
      WHEN 'S'.
        git_log_all-pasot   = 'Textos: Resumen (Castellano)'.
      WHEN 'c'.
        git_log_all-pasot   = 'Textos: Resumen (Catalán)'.
      WHEN 'E'.
        git_log_all-pasot   = 'Textos: Resumen (Inglés)'.
    ENDCASE.

*   Lineas de texto a grabar
    REFRESH: lit_lines.
    LOOP AT git_lineas_texto_final.
      lit_lines-tdformat = '*'.
      lit_lines-tdline   = git_lineas_texto_final.
      APPEND lit_lines.
    ENDLOOP.

*   Grabar texto
    CALL FUNCTION 'SAVE_TEXT'
      EXPORTING
*       CLIENT          = SY-MANDT
        header          = lr_header
        insert          = 'X'
        savemode_direct = ''
*       OWNER_SPECIFIED = ' '
*       LOCAL_CAT       = ' '
*       IMPORTING
*       FUNCTION        =
*       NEWHEADER       =
      TABLES
        lines           = lit_lines
      EXCEPTIONS
        id              = 1
        language        = 2
        name            = 3
        object          = 4
        OTHERS          = 5.

    IF sy-subrc <> 0.
*     Si
      ps_error = 'X'.

      git_log_all-status  = gc_minisemaforo_rojo.
      git_log_all-mensaje = 'Error al actualizar texto'.
    ELSE.
      git_log_all-status  = gc_minisemaforo_verde.
      git_log_all-mensaje = 'Texto actualizado correctamente'.
    ENDIF.

*   Añadir entrada al log
    APPEND git_log_all.

*   Commit
    CALL FUNCTION 'COMMIT_TEXT'
*       EXPORTING
*         OBJECT                = '*'
*         NAME                  = '*'
*         ID                    = '*'
*         LANGUAGE              = '*'
*         SAVEMODE_DIRECT       = ' '
*         KEEP                  = ' '
*         LOCAL_CAT             = ' '
*       IMPORTING
*         COMMIT_COUNT          =
*       TABLES
*         T_OBJECT              =
*         T_NAME                =
*         T_ID                  =
*         T_LANGUAGE            =
      .

    COMMIT WORK AND WAIT.

*   Commmit DB
    CALL FUNCTION 'DB_COMMIT'
*       EXPORTING
*         IV_DEFAULT       = ABAP_FALSE
      .
  ENDLOOP.
ENDFORM.

*===================================================================================================
* Form  F_CREAR_ARTICULOS_UPDATE_PVP
*===================================================================================================
* Función que genera un COND_A para grabar el precio VKP0 a nivel de todas las areas de ventas en
* las que el artículo ha sido dado de alta.
*===================================================================================================
FORM f_crear_articulos_update_pvp  USING    pe_modo
                                            pe_matnr
                                            pe_matnridt
                                   CHANGING         ps_error.
* 0.- Declaración de variables
*===================================================================================================
  DATA: lit_idoc_containers LIKE edidd OCCURS 0 WITH HEADER LINE,
        lr_e1bp_wrpl_import TYPE e1bp_wrpl_import,
        lr_e1bpe1mathead    TYPE e1bpe1mathead,
        lr_e1bpe1marcrt     TYPE e1bpe1marcrt,
        lr_e1bpe1marcrtx    TYPE e1bpe1marcrtx,
        lr_idoc_control_new LIKE edidc,
        lr_idoc_control     LIKE edidc,
        lf_error            LIKE sy-subrc,
        ld_kunnr_tienda     TYPE kunnr,
        ld_segnum           TYPE idocdsgnum,
        ld_segnum_cab       TYPE idocdsgnum,
        ld_identifier       LIKE edidc-docnum,
        lr_e1komg           LIKE e1komg,
        lr_e1konh           LIKE e1konh,
        lr_e1konp           LIKE e1konp,
        ld_status           LIKE edidc-status,
        ld_linea            TYPE numc2,
        ld_kbetr            TYPE p DECIMALS 4,
        ld_kbrue            TYPE p DECIMALS 4.


* 1.- Logica
*===================================================================================================
*>Inicializar retorno
  CLEAR: ps_error.

*>Registrar PVP para cada area de venta en la que se ha dado de alta el artículo
  LOOP AT git_areas_de_venta.
*   Para cada area de venta...

*   Inicializar datos
    CLEAR: lr_idoc_control,
           ld_identifier,
           lf_error,
           ld_segnum,
           ld_segnum_cab.

    REFRESH lit_idoc_containers.

*   Abrimos IDOC
    PERFORM f_idoc_abrir USING  'IDOC_CONDA' '' CHANGING lr_idoc_control_new ld_identifier lf_error.

*   Segmento E1KOMG
    CLEAR lr_e1komg.
    lr_e1komg-kvewe       = 'A'.
    lr_e1komg-kotabnr     = '073'.
    lr_e1komg-kappl       = 'V'.
    lr_e1komg-kschl       = 'VKP0'.
    CONCATENATE git_areas_de_venta-valor1(4)
                git_areas_de_venta-valor2(2)
                zretlai013_s02-matnr(18)
                zretlai013_s02-get_meins
           INTO lr_e1komg-vakey RESPECTING BLANKS.
    lr_e1komg-vkorg       = git_areas_de_venta-valor1(4).
    lr_e1komg-vtweg       = git_areas_de_venta-valor2(2).
    lr_e1komg-matnr       = zretlai013_s02-matnr.
*    lr_e1komg-pltyp      = 'Z1'.
    lr_e1komg-vrkme       = zretlai013_s02-get_meins.

    CALL FUNCTION 'UNIT_OF_MEASURE_SAP_TO_ISO'
      EXPORTING
        sap_code    = lr_e1komg-vrkme
      IMPORTING
        iso_code    = lr_e1komg-vrkme
      EXCEPTIONS
        not_found   = 1
        no_iso_code = 2
        OTHERS      = 3.

    lr_e1komg-evrtp = '00000'.
    lr_e1komg-posnr = '000000'.
    lr_e1komg-anzsn = '0000000000'.
    lr_e1komg-vakey_long = lr_e1komg-vakey.

    ADD 1 TO ld_segnum.
    CLEAR lit_idoc_containers.
    lit_idoc_containers-segnam  = 'E1KOMG'.
    lit_idoc_containers-sdata   = lr_e1komg.
    lit_idoc_containers-docnum  = ld_identifier.
    lit_idoc_containers-segnum  = ld_segnum.
    APPEND lit_idoc_containers.

    ld_segnum_cab = ld_segnum.

*   Segmento E1KONH
    CLEAR lr_e1konh.
    lr_e1konh-datab = zretlai013_s02-get_precio_con_iva_datab.
    lr_e1konh-datbi = zretlai013_s02-get_precio_con_iva_datbi.

    ADD 1 TO ld_segnum.
    CLEAR lit_idoc_containers.
    lit_idoc_containers-segnam  = 'E1KONH'.
    lit_idoc_containers-sdata   = lr_e1konh.
    lit_idoc_containers-docnum  = ld_identifier.
    lit_idoc_containers-segnum  = ld_segnum.
    lit_idoc_containers-psgnum  = ld_segnum_cab.
    APPEND lit_idoc_containers.
    ld_segnum_cab = ld_segnum.

*   Segmento E1KONP
    CLEAR lr_e1konp.
    lr_e1konp-kschl = 'VKP0'.
    lr_e1konp-stfkz = 'A'.
    lr_e1konp-krech = 'C'.
    IF zretlai013_s01-sap = 'X'.
      lr_e1konp-kbetr = zretlai013_s02-get_precio_con_iva_cegal.
    ELSE.
      lr_e1konp-kbetr = zretlai013_s02-get_precio_con_iva.
    ENDIF.

    lr_e1konp-konwa = zretlai013_s02-get_precio_con_iva_waers.
    lr_e1konp-kpein = 1.
    lr_e1konp-kmein = zretlai013_s02-get_meins.

    CALL FUNCTION 'UNIT_OF_MEASURE_SAP_TO_ISO'
      EXPORTING
        sap_code    = lr_e1konp-kmein
      IMPORTING
        iso_code    = lr_e1konp-kmein
      EXCEPTIONS
        not_found   = 1
        no_iso_code = 2
        OTHERS      = 3.

    IF sy-subrc <> 0.ENDIF.

    lr_e1konp-kwaeh = 'EUR'.
    lr_e1konp-zaehk_ind = '01'.

    ADD 1 TO ld_segnum.
    CLEAR lit_idoc_containers.
    lit_idoc_containers-segnam  = 'E1KONP'.
    lit_idoc_containers-sdata   = lr_e1konp.
    lit_idoc_containers-docnum  = ld_identifier.
    lit_idoc_containers-segnum  = ld_segnum.
    lit_idoc_containers-psgnum  = ld_segnum_cab.
    APPEND lit_idoc_containers.

*   Añadimos segmentos
    PERFORM f_idoc_add_segmentos TABLES lit_idoc_containers
                                 USING  ld_identifier
                                 CHANGING lf_error.

*   Cerramos IDOC
    PERFORM f_idoc_cerrar USING    ld_identifier
                          CHANGING lr_idoc_control_new
                                   lf_error.

*   Cambiamos STATUS al idoc
    PERFORM f_idoc_cambiar_status USING lr_idoc_control_new-docnum
                                        '64'
                                CHANGING lf_error.

    COMMIT WORK AND WAIT.

    CALL FUNCTION 'DEQUEUE_ALL'
*       EXPORTING
*         _SYNCHRON       = ' '
      .

    CLEAR ld_status.
*   Procesamos idoc si estamos en modo online
    IF pe_modo = gc_modo_online.
*     Hacemos 10 intentos para procesar el idoc
      DO 10 TIMES.
*       Procesamos idoc
        SUBMIT rbdapp01
          WITH docnum BETWEEN lr_idoc_control_new-docnum AND space
          WITH p_output = space
           AND RETURN.

        COMMIT WORK AND WAIT.

*       Obtenemos status del idoc
        PERFORM f_get_status_idoc USING lr_idoc_control_new-docnum CHANGING ld_status.

        IF ld_status = '53'.
*         Si idoc en verde, nos salimos
          EXIT.
        ELSE.
*         Si idoc no está en verde, esperamos un segundo y volvemos a procesar
          WAIT UP TO 1 SECONDS.
        ENDIF.
      ENDDO.

*     Chequear status final del idoc
      IF ld_status <> '53'.
        ps_error = 'X'.
      ENDIF.
    ENDIF.

*   Registrar Log
    ADD 1 TO ld_linea.
    CLEAR git_log_all.
    git_log_all-matnr   = zretlai013_s02-matnr.
    git_log_all-matnrt  = zretlai013_s02-get_titulo.
    git_log_all-lineam  = ld_linea.
    IF ld_status <> '53'.
      IF ld_status IS INITIAL.
        git_log_all-status  = gc_minisemaforo_ambar.
        CONCATENATE 'PVP'
                    git_areas_de_venta-valor1
                    git_areas_de_venta-valor2
                    'Creado correctamente: Idoc'
                    lr_idoc_control_new-docnum
                    '- Verif. status idoc'
               INTO git_log_all-mensaje
          SEPARATED BY space.
      ELSE.
        git_log_all-status  = gc_minisemaforo_rojo.
        CONCATENATE 'Error al crear PVP'
                    git_areas_de_venta-valor1
                    git_areas_de_venta-valor2
                    ': Idoc'
                    lr_idoc_control_new-docnum
               INTO git_log_all-mensaje
          SEPARATED BY space.
      ENDIF.
    ELSE.
      git_log_all-status  = gc_minisemaforo_verde.
      CONCATENATE 'PVP'
                  git_areas_de_venta-valor1
                  git_areas_de_venta-valor2
                  'Creado correctamente: Idoc'
                  lr_idoc_control_new-docnum
             INTO git_log_all-mensaje
        SEPARATED BY space.
    ENDIF.

    git_log_all-paso    = 'P08'.
    git_log_all-pasot   = 'Alta PVP'.
    git_log_all-docnum    = lr_idoc_control_new-docnum.
    APPEND git_log_all.
  ENDLOOP.


*>Registrar PVP sin iva para cada area de venta en la que se ha dado de alta el artículo
  LOOP AT git_areas_de_venta.
*   Para cada area de venta...

*   Inicializar datos
    CLEAR: lr_idoc_control,
           ld_identifier,
           lf_error,
           ld_segnum,
           ld_segnum_cab.

    REFRESH lit_idoc_containers.

*   Abrimos IDOC
    PERFORM f_idoc_abrir USING  'IDOC_CONDA' '' CHANGING lr_idoc_control_new ld_identifier lf_error.

*   Segmento E1KOMG
    CLEAR lr_e1komg.
    lr_e1komg-kvewe       = 'A'.
    lr_e1komg-kotabnr     = '073'.
    lr_e1komg-kappl       = 'V'.
    lr_e1komg-kschl       = 'VKP1'.
    CONCATENATE git_areas_de_venta-valor1(4)
                git_areas_de_venta-valor2(2)
                zretlai013_s02-matnr(18)
                zretlai013_s02-get_meins
           INTO lr_e1komg-vakey RESPECTING BLANKS.
    lr_e1komg-vkorg       = git_areas_de_venta-valor1(4).
    lr_e1komg-vtweg       = git_areas_de_venta-valor2(2).
    lr_e1komg-matnr       = zretlai013_s02-matnr.
*    lr_e1komg-pltyp      = 'Z1'.
    lr_e1komg-vrkme       = zretlai013_s02-get_meins.

    CALL FUNCTION 'UNIT_OF_MEASURE_SAP_TO_ISO'
      EXPORTING
        sap_code    = lr_e1komg-vrkme
      IMPORTING
        iso_code    = lr_e1komg-vrkme
      EXCEPTIONS
        not_found   = 1
        no_iso_code = 2
        OTHERS      = 3.

    lr_e1komg-evrtp = '00000'.
    lr_e1komg-posnr = '000000'.
    lr_e1komg-anzsn = '0000000000'.
    lr_e1komg-vakey_long = lr_e1komg-vakey.

    ADD 1 TO ld_segnum.
    CLEAR lit_idoc_containers.
    lit_idoc_containers-segnam  = 'E1KOMG'.
    lit_idoc_containers-sdata   = lr_e1komg.
    lit_idoc_containers-docnum  = ld_identifier.
    lit_idoc_containers-segnum  = ld_segnum.
    APPEND lit_idoc_containers.

    ld_segnum_cab = ld_segnum.

*   Segmento E1KONH
    CLEAR lr_e1konh.
    lr_e1konh-datab = zretlai013_s02-get_precio_sin_iva_datab.
    lr_e1konh-datbi = zretlai013_s02-get_precio_sin_iva_datbi.

    ADD 1 TO ld_segnum.
    CLEAR lit_idoc_containers.
    lit_idoc_containers-segnam  = 'E1KONH'.
    lit_idoc_containers-sdata   = lr_e1konh.
    lit_idoc_containers-docnum  = ld_identifier.
    lit_idoc_containers-segnum  = ld_segnum.
    lit_idoc_containers-psgnum  = ld_segnum_cab.
    APPEND lit_idoc_containers.
    ld_segnum_cab = ld_segnum.

*   Segmento E1KONP
    CLEAR lr_e1konp.
    lr_e1konp-kschl = 'VKP1'.
    lr_e1konp-stfkz = 'A'.
    lr_e1konp-krech = 'C'.
    IF zretlai013_s01-sap = 'X'.
      lr_e1konp-kbetr = zretlai013_s02-get_precio_sin_iva_cegal.
    ELSE.
      lr_e1konp-kbetr = zretlai013_s02-get_precio_sin_iva.
    ENDIF.
    lr_e1konp-konwa = zretlai013_s02-get_precio_sin_iva_waers.
    lr_e1konp-kpein = 1.
    lr_e1konp-kmein = zretlai013_s02-get_meins.

    CALL FUNCTION 'UNIT_OF_MEASURE_SAP_TO_ISO'
      EXPORTING
        sap_code    = lr_e1konp-kmein
      IMPORTING
        iso_code    = lr_e1konp-kmein
      EXCEPTIONS
        not_found   = 1
        no_iso_code = 2
        OTHERS      = 3.

    IF sy-subrc <> 0.ENDIF.

    lr_e1konp-kwaeh = 'EUR'.
    lr_e1konp-zaehk_ind = '01'.

    ADD 1 TO ld_segnum.
    CLEAR lit_idoc_containers.
    lit_idoc_containers-segnam  = 'E1KONP'.
    lit_idoc_containers-sdata   = lr_e1konp.
    lit_idoc_containers-docnum  = ld_identifier.
    lit_idoc_containers-segnum  = ld_segnum.
    lit_idoc_containers-psgnum  = ld_segnum_cab.
    APPEND lit_idoc_containers.

*   Añadimos segmentos
    PERFORM f_idoc_add_segmentos TABLES lit_idoc_containers
                                 USING  ld_identifier
                                 CHANGING lf_error.

*   Cerramos IDOC
    PERFORM f_idoc_cerrar USING    ld_identifier
                          CHANGING lr_idoc_control_new
                                   lf_error.

*   Cambiamos STATUS al idoc
    PERFORM f_idoc_cambiar_status USING lr_idoc_control_new-docnum
                                        '64'
                                CHANGING lf_error.

    COMMIT WORK AND WAIT.

    CALL FUNCTION 'DEQUEUE_ALL'
*       EXPORTING
*         _SYNCHRON       = ' '
      .

    CLEAR ld_status.

    IF pe_modo = gc_modo_online.
      DO 10 TIMES.
        SUBMIT rbdapp01
          WITH docnum BETWEEN lr_idoc_control_new-docnum AND space
          WITH p_output = space
           AND RETURN.

        COMMIT WORK AND WAIT.

        PERFORM f_get_status_idoc USING lr_idoc_control_new-docnum CHANGING ld_status.

        IF ld_status = '53'.
          EXIT.
        ELSE.
          WAIT UP TO 1 SECONDS.
        ENDIF.
      ENDDO.

      IF ld_status <> '53'.
        ps_error = 'X'.
      ENDIF.
    ENDIF.

*   Registrar Log
    ADD 1 TO ld_linea.
    CLEAR git_log_all.
    git_log_all-matnr   = zretlai013_s02-matnr.
    git_log_all-matnrt  = zretlai013_s02-get_titulo.
    git_log_all-lineam  = ld_linea.
    IF ld_status <> '53'.
      IF ld_status IS INITIAL.
        git_log_all-status  = gc_minisemaforo_ambar.
        CONCATENATE 'PVP Sin IVA' git_areas_de_venta-valor1 git_areas_de_venta-valor2 'Creado correctamente: Idoc' lr_idoc_control_new-docnum '- Verif. status idoc' INTO git_log_all-mensaje SEPARATED BY space.
      ELSE.
        git_log_all-status  = gc_minisemaforo_rojo.
        CONCATENATE 'Error al crear PVP Sin IVA' git_areas_de_venta-valor1 git_areas_de_venta-valor2 ': Idoc' lr_idoc_control_new-docnum INTO git_log_all-mensaje SEPARATED BY space.
      ENDIF.
    ELSE.
      git_log_all-status  = gc_minisemaforo_verde.
      CONCATENATE 'PVP Sin IVA' git_areas_de_venta-valor1 git_areas_de_venta-valor2 'Creado correctamente: Idoc' lr_idoc_control_new-docnum INTO git_log_all-mensaje SEPARATED BY space.
    ENDIF.

    git_log_all-paso    = 'P08'.
    git_log_all-pasot   = 'Alta PVP'.
    git_log_all-docnum    = lr_idoc_control_new-docnum.
    APPEND git_log_all.
  ENDLOOP.

ENDFORM.

*&---------------------------------------------------------------------*
*&      Form  f_idoc_add_segmentos
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->PE_IT_IDOC_CONTAINERS  text
*      -->PE_IDENTIFIER          text
*      -->PS_ERROR               text
*----------------------------------------------------------------------*
FORM f_idoc_add_segmentos TABLES   pe_it_idoc_containers STRUCTURE edidd
                          USING    pe_identifier
                          CHANGING ps_error.

  CLEAR ps_error.

  CALL FUNCTION 'EDI_SEGMENTS_ADD_BLOCK'
    EXPORTING
      identifier                    = pe_identifier
    TABLES
      idoc_containers               = pe_it_idoc_containers
    EXCEPTIONS
      identifier_invalid            = 1
      idoc_containers_empty         = 2
      parameter_error               = 3
      segment_number_not_sequential = 4
      OTHERS                        = 5.

  IF sy-subrc <> 0.
    ps_error = sy-subrc.
  ENDIF.

ENDFORM.                    "f_add_segmentos

*===================================================================================================
*& Form F_GET_STATUS_IDOC
*===================================================================================================
*& text
*===================================================================================================
* Devuelve el status de un idoc
*===================================================================================================
FORM f_get_status_idoc  USING    pe_docnum
                        CHANGING ps_status.

  CLEAR ps_status.

  SELECT SINGLE status
    FROM edidc
    INTO ps_status
   WHERE docnum = pe_docnum.

ENDFORM.

*&---------------------------------------------------------------------*
*&      Form  f_idoc_cerrar
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->PE_IDENTIFIER        text
*      -->PS_IDOC_CONTROL_NEW  text
*      -->PS_ERROR             text
*----------------------------------------------------------------------*
FORM f_idoc_cerrar USING    pe_identifier
                   CHANGING ps_idoc_control_new LIKE edidc
                            ps_error.

  CLEAR ps_error.

  CALL FUNCTION 'EDI_DOCUMENT_CLOSE_CREATE'
    EXPORTING
      identifier          = pe_identifier
*     NO_DEQUEUE          = ' '
*     SYN_ACTIVE          = ' '
    IMPORTING
      idoc_control        = ps_idoc_control_new
*     SYNTAX_RETURN       =
    EXCEPTIONS
      document_not_open   = 1
      document_no_key     = 2
      failure_in_db_write = 3
      parameter_error     = 4
      OTHERS              = 5.
  IF sy-subrc <> 0.
    ps_error = sy-subrc.
  ENDIF.

ENDFORM.                    " F_IDOC_CERRAR

*&---------------------------------------------------------------------*
*&      Form  f_idoc_cambiar_status
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->PE_NUMIDOC text
*      -->PE_STATUS  text
*      -->PS_ERROR   text
*----------------------------------------------------------------------*
FORM f_idoc_cambiar_status  USING    pe_numidoc
                                     pe_status
                            CHANGING ps_error.
* 0.- Declaracion de variables
*=======================================================================
  DATA: lt_edids TYPE TABLE OF bdidocstat WITH HEADER LINE.

* 1.- Logica
*=======================================================================
  CLEAR ps_error.

  CLEAR lt_edids.
  lt_edids-docnum   = pe_numidoc.
  lt_edids-status   = pe_status.
  lt_edids-uname    = sy-uname.
  lt_edids-repid    = sy-repid.
  lt_edids-tid      = sy-tcode.
  APPEND lt_edids.

  CALL FUNCTION 'IDOC_STATUS_WRITE_TO_DATABASE'
    EXPORTING
      idoc_number               = pe_numidoc
    TABLES
      idoc_status               = lt_edids[]
    EXCEPTIONS
      idoc_foreign_lock         = 1
      idoc_not_found            = 2
      idoc_status_records_empty = 3
      idoc_status_invalid       = 4
      db_error                  = 5
      OTHERS                    = 6.

  IF sy-subrc <> 0.
    ps_error = sy-subrc.
  ENDIF.

ENDFORM.                    " F_CAMBIAR_STATUS_IDOC


FORM f_idoc_abrir  USING pe_operacion
                         pe_tienda
                   CHANGING ps_lr_idoc_control STRUCTURE edidc
                            ps_identifier
                            ps_error.

* 0.- Declaracion de variables
*=======================================================================
  DATA: lit_zretlai001_t01 LIKE zretlai001_t01 OCCURS 0 WITH HEADER LINE.

* 1.- Logica
*=======================================================================
* Inicializamos parámetros de salida
  CLEAR: ps_lr_idoc_control,
         ps_identifier,
         ps_error.


* Recuperamos los datos de configuración del IDOC a abrir
  SELECT *
    FROM zretlai001_t01
    INTO TABLE lit_zretlai001_t01
   WHERE parametro = pe_operacion.

  LOOP AT lit_zretlai001_t01.
    CASE lit_zretlai001_t01-valor1.
      WHEN 'DOCREL'.
        ps_lr_idoc_control-docrel = lit_zretlai001_t01-valor2.
      WHEN 'DIRECT'.
        ps_lr_idoc_control-direct = lit_zretlai001_t01-valor2.
      WHEN 'RCVPOR'.
        ps_lr_idoc_control-rcvpor = lit_zretlai001_t01-valor2.
      WHEN 'RCVPRT'.
        ps_lr_idoc_control-rcvprt = lit_zretlai001_t01-valor2.
      WHEN 'RCVPRN'.
        ps_lr_idoc_control-rcvprn = lit_zretlai001_t01-valor2.
      WHEN 'STDVRS'.
        ps_lr_idoc_control-stdvrs = lit_zretlai001_t01-valor2.
      WHEN 'STDMES'.
        ps_lr_idoc_control-stdmes = lit_zretlai001_t01-valor2.
      WHEN 'TEST'.
        ps_lr_idoc_control-test   = lit_zretlai001_t01-valor2.
      WHEN 'SNDPOR'.
        ps_lr_idoc_control-sndpor = lit_zretlai001_t01-valor2.
      WHEN 'SNDPRT'.
        ps_lr_idoc_control-sndprt = lit_zretlai001_t01-valor2.
      WHEN 'SNDPRN'.
        IF lit_zretlai001_t01-valor1 = '<<TIENDA>>'.
          ps_lr_idoc_control-sndprn = pe_tienda.
        ELSE.
          ps_lr_idoc_control-sndprn = lit_zretlai001_t01-valor2.
        ENDIF.
      WHEN 'MESTYP'.
        ps_lr_idoc_control-mestyp = lit_zretlai001_t01-valor2.
      WHEN 'IDOCTP'.
        ps_lr_idoc_control-idoctp = lit_zretlai001_t01-valor2.
      WHEN 'SNDLAD'.
        ps_lr_idoc_control-sndlad = lit_zretlai001_t01-valor2.
      WHEN 'MESCOD'.
        ps_lr_idoc_control-mescod = lit_zretlai001_t01-valor2.
      WHEN 'MESFCT'.
        ps_lr_idoc_control-mesfct = lit_zretlai001_t01-valor2.
    ENDCASE.
  ENDLOOP.

  CONCATENATE sy-datum
              sy-uzeit
         INTO ps_lr_idoc_control-serial.

* Abrir creacion del IDOC
  CALL FUNCTION 'EDI_DOCUMENT_OPEN_FOR_CREATE'
    EXPORTING
      idoc_control         = ps_lr_idoc_control
*     PI_RFC_MULTI_CP      = '    '
    IMPORTING
      identifier           = ps_identifier
    EXCEPTIONS
      other_fields_invalid = 1
      OTHERS               = 2.
  IF sy-subrc <> 0.
    ps_error = sy-subrc.
  ENDIF.


ENDFORM.                    " F_IDOC_ABRIR

*===================================================================================================
*& Form F_CATALOGAR
*===================================================================================================
* Genera un idoc LIKOND para el catalogar en el sistema el artículo recibido
*===================================================================================================
FORM f_catalogar  USING    pe_matnr
                           pe_modo
                  CHANGING ps_error
                           ps_docnum.

* 0.- Declaracion de variables
*===================================================================================================
  DATA: lit_idoc_containers LIKE edidd OCCURS 0 WITH HEADER LINE,
        lt_edids            TYPE TABLE OF bdidocstat WITH HEADER LINE,
        lit_wrsz            LIKE wrsz OCCURS 0 WITH HEADER LINE,

        lr_e1matnr          LIKE e1matnr,
        lr_e1wlk1m          LIKE e1wlk1m,
        lr_idoc_control     LIKE edidc,
        lr_idoc_control_new LIKE edidc,

        ld_segnum           TYPE idocdsgnum,
        ld_segnum_cab       TYPE idocdsgnum,
        ld_identifier       LIKE edidc-docnum,
        ld_docrel           TYPE edi_docrel,
        ld_rcvpor           TYPE edi_rcvpor,
        ld_rcvprn           TYPE edi_rcvprn,
        ld_sndpor           TYPE edi_sndpor,
        ld_sndprn           TYPE edi_sndprn,
        ld_index            LIKE sy-tabix.

* 1.- Lógica
*===================================================================================================
*>Inicializamos retorno
  CLEAR ps_docnum.

*>Obtener configuración del IDOC a crear
  SELECT SINGLE valor1
    FROM zretlai001_t01
    INTO ld_docrel
   WHERE parametro = 'CATALOGAR_DOCREL'.

  SELECT SINGLE valor1
    FROM zretlai001_t01
    INTO ld_rcvpor
   WHERE parametro = 'CATALOGAR_RCVPOR'.

  SELECT SINGLE valor1
    FROM zretlai001_t01
    INTO ld_rcvprn
   WHERE parametro = 'CATALOGAR_RCVPRN'.

  SELECT SINGLE valor1
    FROM zretlai001_t01
    INTO ld_sndpor
   WHERE parametro = 'CATALOGAR_SNDPOR'.

  SELECT SINGLE valor1
    FROM zretlai001_t01
    INTO ld_sndprn
   WHERE parametro  = 'CATALOGAR_SNDPRN'.

*>Rellenar datos de control del IDOC
  lr_idoc_control-docrel = ld_docrel.
  lr_idoc_control-direct = '2'.
  lr_idoc_control-rcvpor = ld_rcvpor.
  lr_idoc_control-rcvprt = 'LS'.
  lr_idoc_control-rcvprn = ld_rcvprn.
  lr_idoc_control-sndpor = ld_sndpor.
  lr_idoc_control-sndprt = 'LS'.
  lr_idoc_control-sndprn = ld_sndprn.
  lr_idoc_control-mestyp = 'LIKOND'.
  lr_idoc_control-idoctp = 'LIKOND01'.

*>Abrir IDOC
  CALL FUNCTION 'EDI_DOCUMENT_OPEN_FOR_CREATE'
    EXPORTING
      idoc_control         = lr_idoc_control
    IMPORTING
      identifier           = ld_identifier
    EXCEPTIONS
      other_fields_invalid = 1
      OTHERS               = 2.
  IF sy-subrc <> 0.
  ENDIF.

*>Segmento E1MATNR
  lr_e1matnr-matnr = pe_matnr.
  ADD 1 TO ld_segnum.

  lit_idoc_containers-segnam  = 'E1MATNR'.
  lit_idoc_containers-sdata   = lr_e1matnr.
  lit_idoc_containers-docnum  = ld_identifier.
  lit_idoc_containers-segnum  = ld_segnum.
  ld_segnum_cab = ld_segnum.
  APPEND lit_idoc_containers.

*>Segmentos E1WLK1M

* Obtener los surtidos asociados a la tienda que sean distintos al surtido LIBRERIAS
  SELECT *
    FROM wrsz
    INTO TABLE lit_wrsz
   WHERE locnr = zretlai013_s02-get_werks_usuario
     AND asort <> 'LIBRERIAS'
     AND datab <= sy-datum
     AND datbi >= sy-datum.

  LOOP AT lit_wrsz.
    ld_index = sy-tabix.

    SELECT SINGLE asort
      FROM wrs1
      INTO lit_wrsz-asort
     WHERE asort = lit_wrsz-asort
       AND sotyp = 'C'.

    IF sy-subrc <> 0.
      DELETE lit_wrsz INDEX ld_index.
    ENDIF.
  ENDLOOP.

* Añadir los surtidos de la tienda obtenidos a la catalogación
  IF zretlai013_s02-get_mtart = 'ZLIB' OR
     zretlai013_s02-get_mtart = 'ZEBK'.
    LOOP AT lit_wrsz.
      lr_e1wlk1m-msgfn = '009'.
      lr_e1wlk1m-filia = lit_wrsz-asort.
      lr_e1wlk1m-datbi = '99991231'.
      lr_e1wlk1m-datab = sy-datum.
      lr_e1wlk1m-strnr = pe_matnr.

      ADD 1 TO ld_segnum.
      lit_idoc_containers-segnam  = 'E1WLK1M'.
      lit_idoc_containers-sdata   = lr_e1wlk1m.
      lit_idoc_containers-docnum  = ld_identifier.
      lit_idoc_containers-segnum  = ld_segnum.
      lit_idoc_containers-psgnum  = ld_segnum_cab.
      APPEND lit_idoc_containers.
    ENDLOOP.
  ENDIF.

* Añadir el surtido LIBRERIAS a la catalogación
  lr_e1wlk1m-msgfn = '009'.
  lr_e1wlk1m-filia = 'LIBRERIAS'.
  lr_e1wlk1m-datbi = '99991231'.
  lr_e1wlk1m-datab = sy-datum.
  lr_e1wlk1m-strnr = pe_matnr.
  ADD 1 TO ld_segnum.

  lit_idoc_containers-segnam  = 'E1WLK1M'.
  lit_idoc_containers-sdata   = lr_e1wlk1m.
  lit_idoc_containers-docnum  = ld_identifier.
  lit_idoc_containers-segnum  = ld_segnum.
  lit_idoc_containers-psgnum  = ld_segnum_cab.
  APPEND lit_idoc_containers.

* Añadir el surtido WEB si han marcado el pincho web en la pantalla
  IF zretlai013_s02-get_catweb_tienda = 'X'.
    lr_e1wlk1m-msgfn = '009'.
    lr_e1wlk1m-filia = 'ZWEB'.
    lr_e1wlk1m-datbi = '99991231'.
    lr_e1wlk1m-datab = sy-datum.
    lr_e1wlk1m-strnr = pe_matnr.

    ADD 1 TO ld_segnum.

    lit_idoc_containers-segnam  = 'E1WLK1M'.
    lit_idoc_containers-sdata   = lr_e1wlk1m.
    lit_idoc_containers-docnum  = ld_identifier.
    lit_idoc_containers-segnum  = ld_segnum.
    lit_idoc_containers-psgnum  = ld_segnum_cab.
    APPEND lit_idoc_containers.
  ENDIF.

*>Añadir segmentos al IDOC
  CALL FUNCTION 'EDI_SEGMENTS_ADD_BLOCK'
    EXPORTING
      identifier                    = ld_identifier
    TABLES
      idoc_containers               = lit_idoc_containers
    EXCEPTIONS
      identifier_invalid            = 1
      idoc_containers_empty         = 2
      parameter_error               = 3
      segment_number_not_sequential = 4
      OTHERS                        = 5.

  IF sy-subrc <> 0. ENDIF.

*>Cerrar IDOC
  CALL FUNCTION 'EDI_DOCUMENT_CLOSE_CREATE'
    EXPORTING
      identifier          = ld_identifier
*     NO_DEQUEUE          = ' '
*     SYN_ACTIVE          = ' '
    IMPORTING
      idoc_control        = lr_idoc_control_new
*     SYNTAX_RETURN       =
    EXCEPTIONS
      document_not_open   = 1
      document_no_key     = 2
      failure_in_db_write = 3
      parameter_error     = 4
      OTHERS              = 5.
  IF sy-subrc <> 0. ENDIF.

*>Cambiar el status del IDOC de 50 a 64
  CLEAR lt_edids.
  lt_edids-docnum   = lr_idoc_control_new-docnum.
  lt_edids-status   = '64'.
  lt_edids-uname    = sy-uname.
  lt_edids-repid    = sy-repid.
  lt_edids-tid      = sy-tcode.
  APPEND lt_edids.

  CALL FUNCTION 'IDOC_STATUS_WRITE_TO_DATABASE'
    EXPORTING
      idoc_number               = lr_idoc_control_new-docnum
    TABLES
      idoc_status               = lt_edids[]
    EXCEPTIONS
      idoc_foreign_lock         = 1
      idoc_not_found            = 2
      idoc_status_records_empty = 3
      idoc_status_invalid       = 4
      db_error                  = 5
      OTHERS                    = 6.


  COMMIT WORK AND WAIT.

  CALL FUNCTION 'DEQUEUE_ALL'
*   EXPORTING
*     _SYNCHRON       = ' '
    .

*>Procesar IDOC
  IF pe_modo = gc_modo_online.
    SUBMIT rbdapp01
      WITH docnum BETWEEN lr_idoc_control_new-docnum AND space
      WITH p_output = space
      AND RETURN.
  ENDIF.

*>Asignar numero de idoc creado al retorno de la función
  ps_docnum       = lr_idoc_control_new-docnum.

*>Si se ha procesado el IDOC, verificamos su estado para determinar si ha dado error o no y devolverlo
* como retorno en la función
  IF pe_modo = gc_modo_online.
    SELECT SINGLE docnum
      FROM edidc
      INTO ps_docnum
     WHERE docnum = ps_docnum
       AND status = '53'.

    IF sy-subrc = 0.
      ps_error = ''.
    ELSE.
      ps_error = 'X'.
    ENDIF.
  ELSE.
    ps_error = ''.
  ENDIF.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form F_SET_STAWN
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> LD_MATNR
*&      --> GIT_DATA_DB_DB_WSTAW
*&---------------------------------------------------------------------*
FORM f_set_stawn  USING    pe_matnr
                           pe_stawn
               CHANGING    ps_error.
* 0.- Declaración de variables
*===================================================================================================
  DATA: wa_comco_cls_distr  TYPE /sapsll/api_comco_cls_distr_s,
        lit_comco_cls_distr TYPE /sapsll/api_comco_cls_distr_st,
        lit_return          TYPE bapiret2_t,
        wa_return           LIKE bapiret2,
        ld_linea            TYPE numc2.

* 1.- Lógica
*===================================================================================================
  wa_comco_cls_distr-matnr = pe_matnr.
  wa_comco_cls_distr-stcts = 'EU01'.
  wa_comco_cls_distr-comco = pe_stawn.
  wa_comco_cls_distr-datab = sy-datum.
  wa_comco_cls_distr-datbi = '99991231'.
  APPEND wa_comco_cls_distr TO lit_comco_cls_distr.

  CALL FUNCTION '/SAPSLL/API_COMCO_CLS_DISTR'
    EXPORTING
      it_comco_cls_distr = lit_comco_cls_distr
*     IV_INITIAL_RUN     =
    IMPORTING
      et_messages        = lit_return.

  CLEAR git_log_all.
  git_log_all-matnr   = zretlai013_s02-matnr.
  git_log_all-matnrt  = zretlai013_s02-get_titulo.
  git_log_all-paso    = 'P03'.
  git_log_all-pasot   = 'Actualizar código de importación'.

  LOOP AT lit_return INTO wa_return WHERE type = 'E'.
    EXIT.
  ENDLOOP.

  IF sy-subrc = 0.
    ps_error = 'X'.

    ADD 1 TO ld_linea.

    git_log_all-status  = gc_minisemaforo_rojo.
    git_log_all-mensaje = '>>ERROR: Inicio log.'.
    git_log_all-lineam  = ld_linea.
    APPEND git_log_all.

    LOOP AT lit_return INTO wa_return.
      ADD 1 TO ld_linea.
      git_log_all-lineam   = ld_linea.
      git_log_all-mensaje = wa_return-message.
      APPEND git_log_all.
    ENDLOOP.

    ADD 1 TO ld_linea.
    git_log_all-lineam  = ld_linea.
    git_log_all-status  = gc_minisemaforo_rojo.
    git_log_all-mensaje = '>>ERROR: Fin log.'.
    APPEND git_log_all.
  ELSE.
    git_log_all-status  = gc_minisemaforo_verde.
    git_log_all-mensaje = 'Paso realizado con éxito'.
    APPEND git_log_all.
  ENDIF.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form F_CREAR_ARTICULOS_UPDATE_PROV
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> LD_MATNR
*&---------------------------------------------------------------------*
FORM f_crear_articulos_update_prov CHANGING ps_error.
* 0.- Declaración de variables
*=======================================================================
  DATA: wa_eina          TYPE mewieina,
        wa_einar         TYPE mewieina,
        wa_einax         TYPE mewieinax,
        wa_eine          TYPE mewieine,
        wa_einex         TYPE mewieinex,
        ld_linea         TYPE numc2,
        it_cond_validity LIKE mewivalidity  OCCURS 0 WITH HEADER LINE,
        it_condition     LIKE mewicondition OCCURS 0 WITH HEADER LINE,
        it_return        LIKE bapireturn    OCCURS 0 WITH HEADER LINE,
        lf_lifnr_existe.

* 1.- Logica
*=======================================================================
  CLEAR ps_error.

*>Damos de alta el registro info para todos los proveedores asociados a la editorial determinada
* para el EAN del artículo
  LOOP AT git_proveedores_editorial.
*   Para cada proveedor

*   Inicializaciones
    CLEAR: wa_eina,
           wa_einar,
           wa_einax,
           wa_eine,
           wa_einex,
           ld_linea,
           it_cond_validity,
           it_condition,
           it_return.

    REFRESH:  it_cond_validity,
              it_condition,
              it_return.

    IF zretlai013_s01-sap = 'X'.
*     Si estamos actualizando el articulo, miramos si el proveedor existe para el articulo
      SELECT SINGLE matnr
        FROM eina
        INTO zretlai013_s02-matnr
       WHERE matnr = zretlai013_s02-matnr
         AND lifnr = git_proveedores_editorial-lifnr.

      IF sy-subrc = 0.
        lf_lifnr_existe = 'X'.
      ENDIF.
    ENDIF.

*   Datos generales proveedor
    wa_eina-material      = zretlai013_s02-matnr.                                                   "Artículo
    wa_einax-material     = 'X'.

    wa_eina-vendor        = git_proveedores_editorial-lifnr.                                        "Proveedor
    wa_einax-vendor       = 'X'.

    IF zretlai013_s02-get_idnlf IS NOT INITIAL AND
       zretlai013_s02-get_lifnr = git_proveedores_editorial-lifnr.
      wa_eina-vend_mat      = zretlai013_s02-get_idnlf.                                             "Material proveedor
      wa_einax-vend_mat     = 'X'.
    ENDIF.

*   Proveedor regular solo lo marcaremos si estamos creando un artículo nuevo y se marcará para el
*   proveedor asociado a la tienda.
    IF zretlai013_s02-get_lifnr = git_proveedores_editorial-lifnr AND
       zretlai013_s01-sap = ''.
      wa_eina-norm_vend     = 'X'.                                                                  "Proveedor Regular
      wa_einax-norm_vend    = 'X'.
    ENDIF.

    IF zretlai013_s02-get_meins IS NOT INITIAL.
      wa_eina-po_unit       = zretlai013_s02-get_meins.                                             "Unidad de medida de pedido
      wa_einax-po_unit      = 'X'.
    ENDIF.

    IF zretlai013_s02-get_rueck IS NOT INITIAL AND
       zretlai013_s02-get_lifnr = git_proveedores_editorial-lifnr.
      wa_eina-back_agree    = zretlai013_s02-get_rueck.                                             "Acuerdo
      wa_einax-back_agree   = 'X'.
    ENDIF.

    wa_eina-var_ord_un    = '1'.                                                                    "Unidad variable de medida de pedido activa
    wa_einax-var_ord_un   = 'X'.

*   Datos organización de compras
    IF zretlai013_s02-get_ekorg IS NOT INITIAL.
      wa_eine-purch_org    = zretlai013_s02-get_ekorg.                                              "Organizacion de compras
      wa_einex-purch_org   = 'X'.
    ENDIF.

    wa_eine-info_type = '0'.
    wa_einex-info_type = 'X'.


    PERFORM f_get_eine_tax_code USING zretlai013_s02-get_taklv                                      "Indicador IVA
                                      git_proveedores_editorial-lifnr
                                CHANGING wa_eine-tax_code.
    wa_einex-tax_code = 'X'.



    IF zretlai013_s02-get_ekgrp IS NOT INITIAL.
      wa_eine-pur_group    = zretlai013_s02-get_ekgrp.                                              "Grupo de compras
      wa_einex-pur_group   = 'X'.
    ENDIF.

    IF zretlai013_s02-get_norbm IS NOT INITIAL AND
       zretlai013_s02-get_lifnr = git_proveedores_editorial-lifnr.
      wa_eine-nrm_po_qty  = zretlai013_s02-get_norbm.                                               "Cantidad de pedido estándar
      wa_einex-nrm_po_qty  = 'X'.
    ENDIF.

***    IF zretlai013_s02-get_plifz IS NOT INITIAL AND
***       zretlai013_s02-get_lifnr = git_proveedores_editorial-lifnr.
***      wa_eine-plnd_delry  = zretlai013_s02-get_plifz.                                            "Plazo de entrega previsto en días
***      wa_einex-plnd_delry  = 'X'.
***    ENDIF.

*    wa_eine-net_price   = git_monitor-pc_netpr.                                                    "Importe
*    wa_einex-net_price   = 'X'.

    wa_eine-price_unit  = 1.                                                                        "Cantidad base
    wa_einex-price_unit  = 'X'.

    wa_eine-conv_num1   = 1.                                                                        "Numerador para la conversión UMPRP en UMP
    wa_einex-conv_num1   = 'X'.

    wa_eine-conv_den1   = 1.                                                                        "Denominador para la conversión UMPRP en UMP
    wa_einex-conv_den1   = 'X'.

    IF zretlai013_s02-get_minbm IS NOT INITIAL.
      wa_eine-min_po_qty  = zretlai013_s02-get_minbm.                                               "Cantidad mínima de pedido
      wa_einex-min_po_qty  = 'X'.
    ENDIF.

    IF zretlai013_s02-get_meins IS NOT INITIAL.
      wa_eine-orderpr_un = zretlai013_s02-get_meins.                                                "Unidad medida de precio de pedido
      wa_einex-orderpr_un = 'X'.
    ENDIF.

    wa_eine-conf_ctrl = '0004'.                                                                     "Clave de control de confirmaciones
    wa_einex-conf_ctrl = 'X'.


    CALL FUNCTION 'ME_INFORECORD_MAINTAIN'
      EXPORTING
        i_eina        = wa_eina
        i_einax       = wa_einax
        i_eine        = wa_eine
        i_einex       = wa_einex
*       TESTRUN       =
      IMPORTING
        e_eina        = wa_einar
*       E_EINE        =
      TABLES
*       TXT_LINES     =
        cond_validity = it_cond_validity
        condition     = it_condition
*       COND_SCALE_VALUE       =
*       COND_SCALE_QUAN        =
        return        = it_return.

    COMMIT WORK AND WAIT.

    CALL FUNCTION 'DB_COMMIT'
*     EXPORTING
*       IV_DEFAULT       = ABAP_FALSE
      .

    CALL FUNCTION 'DEQUEUE_ALL'
*       EXPORTING
*         _SYNCHRON       = ' '
      .

    CLEAR git_log_all.
    git_log_all-matnr   = zretlai013_s02-matnr.
    git_log_all-matnrt  = zretlai013_s02-get_titulo.
    git_log_all-paso    = 'P07'.
    IF zretlai013_s01-sap = ''.
*     Si estamos creando un artículo, el proveedor siempre se estará dando de alta
      CONCATENATE 'Alta Prov:' git_proveedores_editorial-lifnr git_proveedores_editorial-lifnrt
             INTO git_log_all-pasot
        SEPARATED BY space.
    ELSE.
*     Si estamos modificando un artículo, determinamos si estamos dando de alta o actualizando proveedor
      IF lf_lifnr_existe = 'X'.
        CONCATENATE 'Actualizar Prov:' git_proveedores_editorial-lifnr git_proveedores_editorial-lifnrt
               INTO git_log_all-pasot
          SEPARATED BY space.
      ELSE.
        CONCATENATE 'Alta Prov:' git_proveedores_editorial-lifnr git_proveedores_editorial-lifnrt
               INTO git_log_all-pasot
          SEPARATED BY space.
      ENDIF.
    ENDIF.

    LOOP AT it_return WHERE type = 'E'.
      EXIT.
    ENDLOOP.

    IF sy-subrc = 0.
      ps_error = 'X'.

      ADD 1 TO ld_linea.

      git_log_all-status  = gc_minisemaforo_rojo.
      git_log_all-mensaje = '>>ERROR: Inicio Log.'.
      git_log_all-lineam  = ld_linea.
      APPEND git_log_all.

      LOOP AT it_return.
        ADD 1 TO ld_linea.
        git_log_all-lineam   = ld_linea.
        git_log_all-mensaje  = it_return-message.
        APPEND git_log_all.
      ENDLOOP.

      ADD 1 TO ld_linea.
      git_log_all-lineam  = ld_linea.
      git_log_all-mensaje = '>>ERROR: Fin Log.'.
      APPEND git_log_all.
    ELSE.
      git_log_all-status  = gc_minisemaforo_verde.
      git_log_all-mensaje = 'Paso realizado con éxito'.
      APPEND git_log_all.
    ENDIF.
  ENDLOOP.

ENDFORM.


*===================================================================================================
*& Form f_get_eine_tax_code
*===================================================================================================
* Determinación IVA del artículo
*===================================================================================================
FORM f_get_eine_tax_code  USING    pe_taklv
                                   pe_lifnr
                          CHANGING ps_tax_code.

* 0.- Declaración de variables
*===================================================================================================
  DATA: ld_land1 LIKE lfa1-land1,
        ld_comu  TYPE char04.

* 1.- Lógica
*===================================================================================================
* Inicializar retorno
  CLEAR ps_tax_code.

* Obtener pais del proveedor
  SELECT SINGLE land1
    FROM lfa1
    INTO ld_land1
   WHERE lifnr = pe_lifnr.

  IF ld_land1 <> 'ES'.
*   Si no es nacional, determinamos si es intracomunitario o extracomunitario
    SELECT SINGLE land1
      FROM t005
      INTO ld_land1
     WHERE land1 = ld_land1
       AND xegld = 'X'.

    IF sy-subrc = 0.
      ld_comu = 'INTRA'.
    ELSE.
      ld_comu = 'EXTRA'.
    ENDIF.
  ENDIF.

  CASE pe_taklv.
    WHEN '0'.
      IF ld_land1 = 'ES'.
        ps_tax_code = 'S0'.
      ELSEIF ld_comu = 'INTRA'.
        ps_tax_code = 'A0'.
      ELSEIF ld_comu = 'EXTRA'.
        ps_tax_code = 'I0'.
      ENDIF.
    WHEN '1'.
      IF ld_land1 = 'ES'.
        ps_tax_code = 'S1'.
      ELSEIF ld_comu = 'INTRA'.
        ps_tax_code = 'A1'.
      ELSEIF ld_comu = 'EXTRA'.
        ps_tax_code = 'I1'.
      ENDIF.
    WHEN '2'.
      IF ld_land1 = 'ES'.
        ps_tax_code = 'S2'.
      ELSEIF ld_comu = 'INTRA'.
        ps_tax_code = 'A2'.
      ELSEIF ld_comu = 'EXTRA'.
        ps_tax_code = 'I2'.
      ENDIF.
    WHEN '3'.
      IF ld_land1 = 'ES'.
        ps_tax_code = 'S3'.
      ELSEIF ld_comu = 'INTRA'.
        ps_tax_code = 'A3'.
      ELSEIF ld_comu = 'EXTRA'.
        ps_tax_code = 'I3'.
      ENDIF.
  ENDCASE.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form F_CONV_EXIT_CUNIT_OUTPUT
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> GIT_DATA_DB_KMEIN
*&      <-- IT_COND_VALIDITY_BASE_UOM
*&---------------------------------------------------------------------*
FORM f_conv_exit_cunit_output  USING    pe_valor
                               CHANGING ps_valor.


  CALL FUNCTION 'CONVERSION_EXIT_CUNIT_OUTPUT'
    EXPORTING
      input          = pe_valor
*     LANGUAGE       = SY-LANGU
    IMPORTING
*     LONG_TEXT      =
      output         = ps_valor
*     SHORT_TEXT     =
    EXCEPTIONS
      unit_not_found = 1
      OTHERS         = 2.

  IF sy-subrc <> 0. ENDIF.

ENDFORM.


*&---------------------------------------------------------------------*
*& Form f_fill_headdata
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      <-- LR_HEADDATA
*&---------------------------------------------------------------------*
FORM f_fill_01_headdata  CHANGING lr_headdata LIKE bapie1mathead.
  lr_headdata-function    = '009'.
  lr_headdata-material    = zretlai013_s02-matnr.                                                   "Código de material
  lr_headdata-matl_type   = zretlai013_s02-get_mtart.                                               "Tipo de material
  lr_headdata-matl_group  = zretlai013_s02-get_matkl.                                               "Grupo de articulos
  lr_headdata-matl_cat    = zretlai013_s02-get_attyp.                                               "Categoría del articulo
  lr_headdata-basic_view  = 'X'.                                                                    "Vista de datos basicos
  lr_headdata-sales_view  = 'X'.                                                                    "Vista de ventas
  lr_headdata-logdc_view  = 'X'.                                                                    "Vista Centro Distribución
  lr_headdata-logst_view  = 'X'.                                                                    "Vista tienda
ENDFORM.

*&---------------------------------------------------------------------*
*& Form f_fill_headdata
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      <-- LR_HEADDATA
*&---------------------------------------------------------------------*
FORM f_fill_01_headdata_mod  CHANGING lr_headdata LIKE bapie1mathead.
  lr_headdata-function    = '009'.
  lr_headdata-material    = zretlai013_s02-matnr.                                                   "Código de material
  lr_headdata-matl_type   = zretlai013_s02-get_mtart.                                               "Tipo de material
  lr_headdata-matl_group  = zretlai013_s02-get_matkl.                                               "Grupo de articulos
  lr_headdata-matl_cat    = zretlai013_s02-get_attyp.                                               "Categoría del articulo
  lr_headdata-basic_view  = 'X'.                                                                    "Vista de datos basicos
  lr_headdata-sales_view  = 'X'.                                                                    "Vista de ventas
  lr_headdata-logdc_view  = 'X'.                                                                    "Vista Centro Distribución
  lr_headdata-logst_view  = 'X'.                                                                    "Vista tienda
ENDFORM.

*&---------------------------------------------------------------------*
*& Form f_fill_clientdata
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> LIT_CLIENTDATA
*&      --> LIT_CLIENTDATAX
*&---------------------------------------------------------------------*
FORM f_fill_02_clientdata  TABLES   lit_clientdata STRUCTURE bapie1marart
                                 lit_clientdatax STRUCTURE bapie1marartx.

  CLEAR:  lit_clientdata,
          lit_clientdatax.

  lit_clientdata-function       = '009'.
  lit_clientdata-material       = zretlai013_s02-matnr.                                             "Código de artículo
  lit_clientdata-base_uom       = zretlai013_s02-get_meins.                                         "UMB
* lit_clientdata-po_unit        = zretlai013_s02-get_bstme.                                         "UMP a nivel de mandante
  lit_clientdata-net_weight     = zretlai013_s02-get_peso.                                          "Peso Neto
  lit_clientdata-tax_class      = zretlai013_s02-get_taklv.                                         "Indicador Impuestos
  lit_clientdata-prod_hier      = zretlai013_s02-get_prodh.                                         "Jerarquía de productos
* lit_clientdata-size_dim       = ld_dimensiones.                                                   "Medidas
* lit_clientdata-std_descr      = git_monitor-info_lifnr.                                           "Nº Proveedor
* lit_clientdata-brand_id       = ''.                                                               "Marca
  lit_clientdata-trans_grp      = zretlai013_s02-get_tragr.                                         "Grupo transporte
  lit_clientdata-item_cat       = zretlai013_s02-get_mtpos_mara.                                    "Grupo de tipos de posición general
* lit_clientdata-extmatlgrp     = git_monitor-db_extwg.
  lit_clientdata-old_mat_no     = zretlai013_s02-get_bismt.                                         "Nº antiguo material
  IF zretlai013_s02-get_situacion IS NOT INITIAL.
    lit_clientdata-pur_status     = zretlai013_s02-get_situacion.
    lit_clientdata-pvalidfrom     = zretlai013_s02-get_situacion_datab.
  ENDIF.

  IF zretlai013_s02-get_situacion IS NOT INITIAL.
    lit_clientdata-sal_status = zretlai013_s02-get_situacion.
    lit_clientdata-svalidfrom = zretlai013_s02-get_situacion_datab.
  ENDIF.

  lit_clientdatax-function       = '009'.
  IF zretlai013_s02-get_situacion IS NOT INITIAL.
    lit_clientdatax-pur_status     = 'X'.
    lit_clientdatax-pvalidfrom     = 'X'.
  ENDIF.

  IF zretlai013_s02-get_situacion IS NOT INITIAL.
    lit_clientdatax-sal_status = 'X'.
    lit_clientdatax-svalidfrom = 'X'.
  ENDIF.
  lit_clientdatax-material       = zretlai013_s02-matnr.
  lit_clientdatax-base_uom       = 'X'.
* lit_clientdatax-po_unit        = 'X'.
  lit_clientdatax-net_weight     = 'X'.
  lit_clientdatax-tax_class      = 'X'.
  lit_clientdatax-prod_hier      = 'X'.
  lit_clientdatax-size_dim       = 'X'.
  lit_clientdatax-std_descr      = 'X'.
  lit_clientdatax-trans_grp      = 'X'.
  lit_clientdatax-item_cat       = 'X'.
  lit_clientdatax-trans_grp      = 'X'.
* lit_clientdatax-brand_id       = 'X'.
  lit_clientdatax-extmatlgrp     = 'X'.
  lit_clientdatax-old_mat_no     = 'X'.

  APPEND: lit_clientdata,
          lit_clientdatax.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form f_fill_clientdata
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> LIT_CLIENTDATA
*&      --> LIT_CLIENTDATAX
*&---------------------------------------------------------------------*
FORM f_fill_02_clientdata_mod TABLES   lit_clientdata STRUCTURE bapie1marart
                                 lit_clientdatax STRUCTURE bapie1marartx.

  CLEAR:  lit_clientdata,
          lit_clientdatax.

  lit_clientdata-function       = '009'.
  lit_clientdata-material       = zretlai013_s02-matnr.                                             "Código de artículo
  lit_clientdata-base_uom       = zretlai013_s02-get_meins.                                         "UMB
*  lit_clientdata-po_unit        = zretlai013_s02-get_bstme.                                        "UMP a nivel de mandante
  lit_clientdata-net_weight     = zretlai013_s02-get_peso_cegal.                                    "Peso Neto
  lit_clientdata-tax_class      = zretlai013_s02-get_taklv_cegal.                                   "Indicador Impuestos
  lit_clientdata-prod_hier      = zretlai013_s02-get_prodh.                                         "Jerarquía de productos
*  lit_clientdata-size_dim       = ld_dimensiones.                                                  "Medidas
* lit_clientdata-std_descr      = git_monitor-info_lifnr.                                           "Nº Proveedor
* lit_clientdata-brand_id       = ''.                                                               "Marca
  lit_clientdata-trans_grp      = zretlai013_s02-get_tragr.                                         "Grupo transporte
  lit_clientdata-item_cat       = zretlai013_s02-get_mtpos_mara.                                    "Grupo de tipos de posición general
*  lit_clientdata-extmatlgrp     = git_monitor-db_extwg.
  lit_clientdata-old_mat_no     = zretlai013_s02-get_bismt.                                         "Nº antiguo material
***  IF zretlai013_s02-get_situacion_cegal IS NOT INITIAL.
***    lit_clientdata-pur_status     = zretlai013_s02-get_situacion_cegal.
***    lit_clientdata-pvalidfrom     = zretlai013_s02-get_situacion_datab.
***  ENDIF.


  lit_clientdatax-function       = '009'.
***  IF zretlai013_s02-get_situacion IS NOT INITIAL.
***    lit_clientdatax-pur_status     = 'X'.
***    lit_clientdatax-pvalidfrom     = 'X'.
***  ENDIF.

  lit_clientdatax-material       = zretlai013_s02-matnr.
  lit_clientdatax-base_uom       = 'X'.
*  lit_clientdatax-po_unit        = 'X'.
  lit_clientdatax-net_weight     = 'X'.
  lit_clientdatax-tax_class      = 'X'.
  lit_clientdatax-prod_hier      = 'X'.
  lit_clientdatax-size_dim       = 'X'.
  lit_clientdatax-std_descr      = 'X'.
  lit_clientdatax-trans_grp      = 'X'.
  lit_clientdatax-item_cat       = 'X'.
  lit_clientdatax-trans_grp      = 'X'.
*  lit_clientdatax-brand_id       = 'X'.
  lit_clientdatax-extmatlgrp     = 'X'.
  lit_clientdatax-old_mat_no     = 'X'.

  APPEND: lit_clientdata,
          lit_clientdatax.
ENDFORM.


FORM f_fill_03_addnclientdata  TABLES   lit_addnclientdata STRUCTURE bapie1maw1rt
                                     lit_addnclientdatax STRUCTURE bapie1maw1rtx.

  lit_addnclientdata-function   = '009'.
  lit_addnclientdata-material   = zretlai013_s02-matnr.
  lit_addnclientdata-loadinggrp = zretlai013_s02-get_ladgr.                                         "Grupo de carga
  lit_addnclientdata-val_class  = zretlai013_s02-get_wbkla.                                         "Categoría de valoración
* lit_addnclientdata-countryori = zretlai013_s02-get_wherl.                                         "País de origen del material (origen CCI)
* lit_addnclientdata-regionorig = zretlai013_s02-get_wherr.                                         "Región de origen del material (origen Cámara de Comercio)
* lit_addnclientdata-comm_code  = git_monitor-db_wstaw.                                             "Número estadístico de mercancía
  lit_addnclientdata-li_proc_st = 'B1'.                                                             "Procedimiento catalogación p.tienda u otros tipos de surtido
  lit_addnclientdata-li_proc_dc = 'B1'.
  lit_addnclientdata-repl_list  = 'A'.                                                              "Transferencia datos Retail: ampliación datos básicos
  APPEND lit_addnclientdata.

  lit_addnclientdatax-function   = '009'.
  lit_addnclientdatax-material   = zretlai013_s02-matnr.
  lit_addnclientdatax-loadinggrp = 'X'.
  lit_addnclientdatax-val_class  = 'X'.
* lit_addnclientdatax-countryori = 'X'.
* lit_addnclientdatax-regionorig = 'X'.
* lit_addnclientdatax-comm_code  = 'X'.
  lit_addnclientdatax-li_proc_st = 'X'.
  lit_addnclientdatax-li_proc_dc = 'X'.
  lit_addnclientdatax-repl_list  = 'X'.
  APPEND lit_addnclientdatax.
ENDFORM.


FORM f_fill_03_addnclientdata_mod  TABLES   lit_addnclientdata STRUCTURE bapie1maw1rt
                                     lit_addnclientdatax STRUCTURE bapie1maw1rtx.

  lit_addnclientdata-function   = '009'.
  lit_addnclientdata-material   = zretlai013_s02-matnr.
  lit_addnclientdata-loadinggrp = zretlai013_s02-get_ladgr.                                         "Grupo de carga
  lit_addnclientdata-val_class  = zretlai013_s02-get_wbkla.                                         "Categoría de valoración
*  lit_addnclientdata-countryori = zretlai013_s02-get_wherl.                                        "País de origen del material (origen CCI)
*  lit_addnclientdata-regionorig = zretlai013_s02-get_wherr.                                        "Región de origen del material (origen Cámara de Comercio)
*  lit_addnclientdata-comm_code  = git_monitor-db_wstaw.                                            "Número estadístico de mercancía
  lit_addnclientdata-li_proc_st = 'B1'.                                                             "Procedimiento catalogación p.tienda u otros tipos de surtido
  lit_addnclientdata-li_proc_dc = 'B1'.                                                             "Transferencia datos Retail: ampliación datos básicos
  APPEND lit_addnclientdata.

  lit_addnclientdatax-function   = '009'.
  lit_addnclientdatax-material   = zretlai013_s02-matnr.
  lit_addnclientdatax-loadinggrp = 'X'.
  lit_addnclientdatax-val_class  = 'X'.
*  lit_addnclientdatax-countryori = 'X'.
*  lit_addnclientdatax-regionorig = 'X'.
*  lit_addnclientdatax-comm_code  = 'X'.
  lit_addnclientdatax-li_proc_st = 'X'.
  lit_addnclientdatax-li_proc_dc = 'X'.
  APPEND lit_addnclientdatax.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form f_fill_unitsofmeasure
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> LIT_UNITSOFMEASURE
*&      --> LIT_UNITSOFMEASUREX
*&---------------------------------------------------------------------*
FORM f_fill_04_unitsofmeasure  TABLES   lit_unitsofmeasure     STRUCTURE bapie1marmrt
                                     lit_unitsofmeasurex    STRUCTURE bapie1marmrtx.

* UM Principal
*===================================================================================================
  CLEAR: lit_unitsofmeasure,
         lit_unitsofmeasurex.

  lit_unitsofmeasure-function   = '009'.
  lit_unitsofmeasure-material   = zretlai013_s02-matnr.                                             "Artículo
  lit_unitsofmeasure-alt_unit   = zretlai013_s02-get_meins.                                         "UMB
  IF zretlai013_s02-get_ean11 IS NOT INITIAL.
    lit_unitsofmeasure-ean_upc    = zretlai013_s02-get_ean11.                                       "EAN11
    lit_unitsofmeasure-ean_cat    = 'HE'.                                                           "Tipo de número del Número de Artículo Europeo
  ELSE.
    lit_unitsofmeasure-ean_cat    = 'VC'.
  ENDIF.
  lit_unitsofmeasure-volume     = zretlai013_s02-get_volum.                                         "Volumen
  lit_unitsofmeasure-volumeunit = zretlai013_s02-get_voleh.                                         "Unidad de volumen
  lit_unitsofmeasure-gross_wt   = zretlai013_s02-get_brgew.                                         "Peso Bruto
  lit_unitsofmeasure-unit_of_wt = zretlai013_s02-get_meabm.                                         "Unidad peso
  lit_unitsofmeasure-length     = zretlai013_s02-get_alto_mm.                                       "Longitud
  lit_unitsofmeasure-width      = zretlai013_s02-get_ancho_mm.                                      "Ancho
  lit_unitsofmeasure-height     = zretlai013_s02-get_grosor_mm.                                     "Altura
  lit_unitsofmeasure-unit_dim   = 'CM'.                                                             "Unidad dimensión

  lit_unitsofmeasurex-function   = '009'.
  lit_unitsofmeasurex-material   = zretlai013_s02-matnr.
  lit_unitsofmeasurex-alt_unit   = 'ST'.
  IF zretlai013_s02-get_ean11 IS NOT INITIAL.
    lit_unitsofmeasurex-ean_upc    = 'X'.
    lit_unitsofmeasurex-ean_cat    = 'X'.
  ELSE.
    lit_unitsofmeasurex-ean_cat    = 'X'.
  ENDIF.
  lit_unitsofmeasurex-volume     = 'X'.
  lit_unitsofmeasurex-volumeunit = 'X'.
  lit_unitsofmeasurex-gross_wt   = 'X'.
  lit_unitsofmeasurex-unit_of_wt = 'X'.
  lit_unitsofmeasurex-length     = 'X'.
  lit_unitsofmeasurex-width      = 'X'.
  lit_unitsofmeasurex-height     = 'X'.
  lit_unitsofmeasurex-unit_dim   = 'X'.

  APPEND: lit_unitsofmeasure,
          lit_unitsofmeasurex.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form f_fill_unitsofmeasure
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> LIT_UNITSOFMEASURE
*&      --> LIT_UNITSOFMEASUREX
*&---------------------------------------------------------------------*
FORM f_fill_04_unitsofmeasure_mod  TABLES   lit_unitsofmeasure     STRUCTURE bapie1marmrt
                                     lit_unitsofmeasurex    STRUCTURE bapie1marmrtx.

* UM Principal
*===================================================================================================
  CLEAR: lit_unitsofmeasure,
         lit_unitsofmeasurex.

  lit_unitsofmeasure-function   = '009'.
  lit_unitsofmeasure-material   = zretlai013_s02-matnr.                                             "Artículo
  lit_unitsofmeasure-alt_unit   = zretlai013_s02-get_meins.                                         "UMB
  IF zretlai013_s02-get_ean11 IS NOT INITIAL.
    lit_unitsofmeasure-ean_upc    = zretlai013_s02-get_ean11.                                       "EAN11
    lit_unitsofmeasure-ean_cat    = 'HE'.                                                           "Tipo de número del Número de Artículo Europeo
  ELSE.
    lit_unitsofmeasure-ean_cat    = 'VC'.
  ENDIF.
  lit_unitsofmeasure-volume     = zretlai013_s02-get_volum.                                         "Volumen
  lit_unitsofmeasure-volumeunit = zretlai013_s02-get_voleh.                                         "Unidad de volumen
  lit_unitsofmeasure-gross_wt   = zretlai013_s02-get_brgew.                                         "Peso Bruto
  lit_unitsofmeasure-unit_of_wt = zretlai013_s02-get_meabm.                                         "Unidad peso
  lit_unitsofmeasure-length     = zretlai013_s02-get_alto_mm_cegal.                                 "Longitud
  lit_unitsofmeasure-width      = zretlai013_s02-get_ancho_mm_cegal.                                "Ancho
  lit_unitsofmeasure-height     = zretlai013_s02-get_grosor_mm_cegal.                               "Altura
  lit_unitsofmeasure-unit_dim   = 'CM'.                                                             "Unidad dimensión

  lit_unitsofmeasurex-function   = '009'.
  lit_unitsofmeasurex-material   = zretlai013_s02-matnr.
  lit_unitsofmeasurex-alt_unit   = 'ST'.
  IF zretlai013_s02-get_ean11 IS NOT INITIAL.
    lit_unitsofmeasurex-ean_upc    = 'X'.
    lit_unitsofmeasurex-ean_cat    = 'X'.
  ELSE.
    lit_unitsofmeasurex-ean_cat    = 'X'.
  ENDIF.
  lit_unitsofmeasurex-volume     = 'X'.
  lit_unitsofmeasurex-volumeunit = 'X'.
  lit_unitsofmeasurex-gross_wt   = 'X'.
  lit_unitsofmeasurex-unit_of_wt = 'X'.
  lit_unitsofmeasurex-length     = 'X'.
  lit_unitsofmeasurex-width      = 'X'.
  lit_unitsofmeasurex-height     = 'X'.
  lit_unitsofmeasurex-unit_dim   = 'X'.

  APPEND: lit_unitsofmeasure,
          lit_unitsofmeasurex.

ENDFORM.

FORM f_fill_06_salesdata  TABLES   lit_salesdata   STRUCTURE bapie1mvkert
                                lit_salesdatax STRUCTURE bapie1mvkertx.

  LOOP AT git_areas_de_venta.
    CLEAR: lit_salesdata,
           lit_salesdatax.

    lit_salesdata-function      = '009'.
    lit_salesdata-material      = zretlai013_s02-matnr.
    lit_salesdata-sales_org     = git_areas_de_venta-valor1.
    lit_salesdata-distr_chan    = git_areas_de_venta-valor2.                                        "Canal
*   lit_salesdata-cash_disc     = 'X'.                                                              "Indicador: Derecho a descuentos
    lit_salesdata-item_cat      = zretlai013_s02-get_mtpos_mara.                                    "Grupo de tipos de posición del maestro de artículo
*   lit_salesdata-acct_assgt    = git_monitor-dv_ktgrm.                                             "Grupo de imputación para artículo
*   lit_salesdata-matl_grp_2    = git_monitor-dv_mvgr2.                                             "Grupo material 2

    lit_salesdatax-function      = '009'.
    lit_salesdatax-material      = zretlai013_s02-matnr.
    lit_salesdatax-sales_org     = git_areas_de_venta-valor1.
    lit_salesdatax-distr_chan    = git_areas_de_venta-valor2.
    lit_salesdatax-item_cat      = 'X'.

    APPEND: lit_salesdata,
           lit_salesdatax.
  ENDLOOP.
ENDFORM.

FORM f_fill_06_salesdata_mod  TABLES   lit_salesdata   STRUCTURE bapie1mvkert
                                lit_salesdatax STRUCTURE bapie1mvkertx.

  LOOP AT git_areas_de_venta.
    CLEAR: lit_salesdata,
           lit_salesdatax.

    lit_salesdata-function      = '009'.
    lit_salesdata-material      = zretlai013_s02-matnr.
    lit_salesdata-sales_org     = git_areas_de_venta-valor1.
    lit_salesdata-distr_chan    = git_areas_de_venta-valor2.                                        "Canal
*   lit_salesdata-cash_disc     = 'X'.                                                              "Indicador: Derecho a descuentos
*   lit_salesdata-item_cat      = 'NORM'.                                                           "Grupo de tipos de posición del maestro de artículo
*   lit_salesdata-acct_assgt    = git_monitor-dv_ktgrm.                                             "Grupo de imputación para artículo
*   lit_salesdata-matl_grp_2    = git_monitor-dv_mvgr2.                                             "Grupo material 2

    lit_salesdatax-function      = '009'.
    lit_salesdatax-material      = zretlai013_s02-matnr.
    lit_salesdatax-sales_org     = git_areas_de_venta-valor1.
    lit_salesdatax-distr_chan    = git_areas_de_venta-valor2.

    APPEND: lit_salesdata,
           lit_salesdatax.
  ENDLOOP.
ENDFORM.


FORM f_fill_05_materialdescription  TABLES   lit_materialdescription STRUCTURE bapie1maktrt .
  IF zretlai013_s02-get_titulo IS NOT INITIAL.
    CLEAR: lit_materialdescription.
    lit_materialdescription-function  = '009'.
    lit_materialdescription-material  = zretlai013_s02-matnr.                                       "Artículo
    lit_materialdescription-langu     = 'S'.                                                        "Idioma
    lit_materialdescription-matl_desc = zretlai013_s02-get_titulo.                                  "Descripción artículo
    APPEND: lit_materialdescription.

    IF zretlai013_s02-get_mtart = 'ZLIB' OR
       zretlai013_s02-get_mtart = 'ZAUD' OR
       zretlai013_s02-get_mtart = 'ZEBK'.

      CLEAR: lit_materialdescription.
      lit_materialdescription-function  = '009'.
      lit_materialdescription-material  = zretlai013_s02-matnr.                                     "Artículo
      lit_materialdescription-langu     = 'c'.                                                      "Idioma
      lit_materialdescription-matl_desc = zretlai013_s02-get_titulo.                                "Descripción artículo
      APPEND: lit_materialdescription.

      CLEAR: lit_materialdescription.
      lit_materialdescription-function  = '009'.
      lit_materialdescription-material  = zretlai013_s02-matnr.                                     "Artículo
      lit_materialdescription-langu     = 'E'.                                                      "Idioma
      lit_materialdescription-matl_desc = zretlai013_s02-get_titulo.                                "Descripción artículo
      APPEND: lit_materialdescription.
    ENDIF.
  ENDIF.
ENDFORM.


FORM f_fill_05_materialdescript_mod  TABLES   lit_materialdescription STRUCTURE bapie1maktrt .
  IF zretlai013_s02-get_titulo IS NOT INITIAL.
    CLEAR: lit_materialdescription.
    lit_materialdescription-function  = '009'.
    lit_materialdescription-material  = zretlai013_s02-matnr.                                       "Artículo
    lit_materialdescription-langu     = 'S'.                                                        "Idioma
    lit_materialdescription-matl_desc = zretlai013_s02-get_titulo_cegal.                            "Descripción artículo
    APPEND: lit_materialdescription.

    IF zretlai013_s02-get_mtart = 'ZLIB' OR
       zretlai013_s02-get_mtart = 'ZAUD' OR
       zretlai013_s02-get_mtart = 'ZEBK'.

      CLEAR: lit_materialdescription.
      lit_materialdescription-function  = '009'.
      lit_materialdescription-material  = zretlai013_s02-matnr.                                     "Artículo
      lit_materialdescription-langu     = 'c'.                                                      "Idioma
      lit_materialdescription-matl_desc = zretlai013_s02-get_titulo_cegal.                          "Descripción artículo
      APPEND: lit_materialdescription.

      CLEAR: lit_materialdescription.
      lit_materialdescription-function  = '009'.
      lit_materialdescription-material  = zretlai013_s02-matnr.                                     "Artículo
      lit_materialdescription-langu     = 'E'.                                                      "Idioma
      lit_materialdescription-matl_desc = zretlai013_s02-get_titulo_cegal.                          "Descripción artículo
      APPEND: lit_materialdescription.
    ENDIF.
  ENDIF.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form f_fill_plantdata
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> LIT_PLANTDATA
*&      --> LIT_PLANTDATAX
*&---------------------------------------------------------------------*
FORM f_fill_07_plantdata  TABLES   lit_plantdata  STRUCTURE bapie1marcrt
                                   lit_plantdatax STRUCTURE bapie1marcrtx.
* 0.- Declaración de variables
*===================================================================================================
  DATA: ld_get_dismm_tienda LIKE zretlai013_s02-get_dismm_tienda,
        ld_get_mtvfp_tienda LIKE zretlai013_s02-get_mtvfp_tienda,
        ld_get_perkz_tienda LIKE zretlai013_s02-get_perkz_tienda,
        ld_get_dispo_tienda LIKE zretlai013_s02-get_dispo_tienda,
        ld_get_minbe_tienda LIKE zretlai013_s02-get_minbe_tienda,
        ld_get_plifz_tienda LIKE zretlai013_s02-get_plifz_tienda,
        ld_get_bwscl_tienda LIKE zretlai013_s02-get_bwscl_tienda,
        ld_get_eisbe_tienda LIKE zretlai013_s02-get_eisbe_tienda,
        ld_get_sobst_tienda LIKE zretlai013_s02-get_sobst_tienda.

* 1.- Lógica
*===================================================================================================
* Obtener los valores por defecto con los que crear la vista de tienda modelo, ya que ahora lo que
* aparece por pantalla son los valores por defecto para la tienda del usuario

* Característica planificación de necesidades
  PERFORM f_get_from_param USING 'DISMM_TIENDA_MODELO_DEFECTO'
                        CHANGING ld_get_dismm_tienda.

* Verificación de disponibilidad
  PERFORM f_get_from_param USING 'MTVFP_TIENDA_MODELO_DEFECTO'
                        CHANGING ld_get_mtvfp_tienda.

* Indicador de periodo
  PERFORM f_get_from_param USING 'PERKZ_TIENDA_MODELO_DEFECTO'
                        CHANGING ld_get_perkz_tienda.

* Planificador de necesidades
  PERFORM f_get_from_param USING 'DISPO_TIENDA_MODELO_DEFECTO'
                        CHANGING ld_get_dispo_tienda.

* Punto de pedido
  PERFORM f_get_from_param USING 'MINBE_TIENDA_MODELO_DEFECTO'
                        CHANGING ld_get_minbe_tienda.

* Plazo entrega previsto
  PERFORM f_get_from_param USING 'PLIFZ_TIENDA_MODELO_DEFECTO'
                        CHANGING ld_get_plifz_tienda.

* Fuente aprovisionamiento
  PERFORM f_get_from_param USING 'BWSCL_TIENDA_MODELO_DEFECTO'
                        CHANGING ld_get_bwscl_tienda.

* Stock seguridad
  PERFORM f_get_from_param USING 'EISBE_TIENDA_MODELO_DEFECTO'
                        CHANGING ld_get_eisbe_tienda.

* Stock objetivo
  PERFORM f_get_from_param USING 'SOBST_TIENDA_MODELO_DEFECTO'
                        CHANGING ld_get_sobst_tienda.

*===================================================================================================
* Tienda Modelo
*===================================================================================================
  CLEAR: lit_plantdata, lit_plantdatax.

  lit_plantdata-function    = '009'.
  lit_plantdata-material    = zretlai013_s02-matnr.                                                 "Artículo
  lit_plantdata-plant       = gd_tienda_modelo.                                                     "Tienda
* lit_plantdata-MRPPROFILE  = git_monitor-tdmo_dispr.                                               "Material: Perfil de planificación de necesidades
* lit_plantdata-replentime  = git_monitor-tdmo_wzeit.                                               "Tiempo global de reaprovisionamiento (días laborables)
  lit_plantdata-mrp_type    = ld_get_dismm_tienda.                                                  "Característica de planificación de necesidades
  lit_plantdata-availcheck  = ld_get_mtvfp_tienda.                                                  "Grupo de verificación p.verificación de disponibilidad
  lit_plantdata-auto_p_ord  = 'X'.                                                                  "Indicador: pedido automático permitido
  lit_plantdata-period_ind  = ld_get_perkz_tienda.                                                  "Indicador de período
  lit_plantdata-mrp_ctrler  = ld_get_dispo_tienda.                                                  "Planificador de necesidades temporal
* lit_plantdata-lotsizekey  = git_monitor-tdmo_disls.                                               "Tamaño de lote de planificación de necesidades
  lit_plantdata-reorder_pt  = ld_get_minbe_tienda.                                                  "Punto de pedido
  lit_plantdata-plnd_delry  = ld_get_plifz_tienda.                                                  "Plazo de entrega previsto
  lit_plantdata-sup_source  = ld_get_bwscl_tienda.                                                  "Fuente de aprovisionamiento
  lit_plantdata-sloc_exprc  = gd_tienda_modelo_lgfsb.                                               "Almacén propuesto para aprovisionamiento externo
  lit_plantdata-pur_group   = zretlai013_s02-get_ekgrp.                                             "Grupo de compras
  lit_plantdata-neg_stocks  = 'X'.                                                                  "Permitir Stocks negativos
  lit_plantdata-determ_grp  = '0001'.                                                               "Grupo de determinación de stocks
* lit_plantdata-proc_type   = 'F'.                                                                  "Clase de aprovisionamiento
* lit_plantdata-round_prof  = git_monitor-tdmo_rdprf.                                               "Perfil redondeo tienda
  lit_plantdata-safety_stk  = ld_get_eisbe_tienda.                                                  "Stock de seguridad
  lit_plantdata-gr_pr_time = 1.                                                                     "Tiempo de tratamiento para la entrada de mercancía en días
  lit_plantdata-gi_pr_time = 1.                                                                     "Tiempo de tratamiento de salida de mercancías en días


  lit_plantdatax-function   = '009'.
  lit_plantdatax-material   = zretlai013_s02-matnr.
  lit_plantdatax-plant      = gd_tienda_modelo.
* lit_plantdatax-MRPPROFILE = 'X'.
* lit_plantdatax-replentime = 'X'.
  lit_plantdatax-mrp_type   = 'X'.
  lit_plantdatax-availcheck = 'X'.
  lit_plantdatax-auto_p_ord = 'X'.
  lit_plantdatax-period_ind = 'X'.
  lit_plantdatax-mrp_ctrler = 'X'.
* lit_plantdatax-lotsizekey = 'X'.
  lit_plantdatax-reorder_pt = 'X'.
  lit_plantdatax-plnd_delry = 'X'.
  lit_plantdatax-sup_source = 'X'.
  lit_plantdatax-sloc_exprc = 'X'.
  lit_plantdatax-pur_group  = 'X'.
  lit_plantdatax-neg_stocks = 'X'.
  lit_plantdatax-determ_grp = 'X'.
*  lit_plantdatax-proc_type  = 'X'.
* lit_plantdatax-round_prof = 'X'.
  lit_plantdatax-safety_stk = 'X'.
  lit_plantdatax-gr_pr_time = 'X'.                                                                  "Tiempo de tratamiento para la entrada de mercancía en días
  lit_plantdatax-gi_pr_time = 'X'.                                                                  "Tiempo de tratamiento de salida de mercancías en días


  APPEND: lit_plantdata, lit_plantdatax.

*===================================================================================================
* Centro modelo
*===================================================================================================
  CLEAR: lit_plantdata, lit_plantdatax.

  lit_plantdata-function    = '009'.
  lit_plantdata-material    = zretlai013_s02-matnr.                                                 "Artículo
  lit_plantdata-plant       = gd_centro_modelo.                                                     "Centro Modelo
* lit_plantdata-MRPPROFILE  = git_monitor-tdmo_dispr.                                               "Material: Perfil de planificación de necesidades
* lit_plantdata-replentime  = git_monitor-tdmo_wzeit.                                               "Tiempo global de reaprovisionamiento (días laborables)
  lit_plantdata-mrp_type    = zretlai013_s02-get_dismm_centro.                                      "Característica de planificación de necesidades
  lit_plantdata-availcheck  = zretlai013_s02-get_mtvfp_centro.                                      "Grupo de verificación p.verificación de disponibilidad
  lit_plantdata-auto_p_ord  = 'X'.                                                                  "Indicador: pedido automático permitido
  lit_plantdata-period_ind  = zretlai013_s02-get_perkz_centro.                                      "Indicador de período
  lit_plantdata-mrp_ctrler  = zretlai013_s02-get_dispo_centro.                                      "Planificador de necesidades temporal
* lit_plantdata-lotsizekey  = git_monitor-tdmo_disls.                                               "Tamaño de lote de planificación de necesidades
*  lit_plantdata-reorder_pt  = ''.                                                                  "Punto de pedido
  lit_plantdata-plnd_delry  = zretlai013_s02-get_plifz_centro.                                      "Plazo de entrega previsto
  lit_plantdata-sup_source  = zretlai013_s02-get_bwscl_centro.                                      "Fuente de aprovisionamiento
  lit_plantdata-sloc_exprc  = gd_centro_modelo_lgfsb.                                               "Almacén propuesto para aprovisionamiento externo
  lit_plantdata-pur_group   = zretlai013_s02-get_ekgrp.                                             "Grupo de compras
  lit_plantdata-neg_stocks  = 'X'.                                                                  "Permitir Stocks negativos
* lit_plantdata-proc_type   = 'F'.                                                                  "Clase de aprovisionamiento
* lit_plantdata-round_prof  = git_monitor-tdmo_rdprf.                                               "Perfil redondeo tienda
  lit_plantdata-safety_stk  = zretlai013_s02-get_eisbe_centro.                                      "Stock de seguridad
  lit_plantdata-distr_prof  = 'Z01'.                                                                "Perfil de distribución de material en centro
  lit_plantdata-determ_grp  = '0001'.                                                               "Grupo de determinación de stocks
  lit_plantdata-gr_pr_time = 1.                                                                     "Tiempo de tratamiento para la entrada de mercancía en días
  lit_plantdata-gi_pr_time = 1.                                                                     "Tiempo de tratamiento de salida de mercancías en días

  lit_plantdatax-function   = '009'.
  lit_plantdatax-material   = zretlai013_s02-matnr.
  lit_plantdatax-plant      = gd_centro_modelo.
* lit_plantdatax-MRPPROFILE = 'X'.
* lit_plantdatax-replentime = 'X'.
  lit_plantdatax-mrp_type   = 'X'.
  lit_plantdatax-availcheck = 'X'.
  lit_plantdatax-auto_p_ord = 'X'.
  lit_plantdatax-period_ind = 'X'.
  lit_plantdatax-mrp_ctrler = 'X'.
* lit_plantdatax-lotsizekey = 'X'.
  lit_plantdatax-reorder_pt = 'X'.
  lit_plantdatax-plnd_delry = 'X'.
  lit_plantdatax-sup_source = 'X'.
  lit_plantdatax-sloc_exprc = 'X'.
  lit_plantdatax-pur_group  = 'X'.
  lit_plantdatax-neg_stocks = 'X'.
* lit_plantdatax-proc_type  = 'X'.
* lit_plantdatax-round_prof = 'X'.
  lit_plantdatax-safety_stk = 'X'.
  lit_plantdatax-distr_prof = 'X'.
  lit_plantdatax-determ_grp = 'X'.
  lit_plantdatax-gr_pr_time = 'X'.                                                                  "Tiempo de tratamiento para la entrada de mercancía en días
  lit_plantdatax-gi_pr_time = 'X'.                                                                  "Tiempo de tratamiento de salida de mercancías en días

  APPEND: lit_plantdata, lit_plantdatax.
ENDFORM.


*&---------------------------------------------------------------------*
*& Form f_fill_plantdata
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> LIT_PLANTDATA
*&      --> LIT_PLANTDATAX
*&---------------------------------------------------------------------*
FORM f_fill_07_plantdata_mod TABLES lit_plantdata  STRUCTURE bapie1marcrt
                                    lit_plantdatax STRUCTURE bapie1marcrtx.
* 0.- Declaración de variables
*===================================================================================================
  DATA: ld_get_dismm_tienda LIKE zretlai013_s02-get_dismm_tienda,
        ld_get_mtvfp_tienda LIKE zretlai013_s02-get_mtvfp_tienda,
        ld_get_perkz_tienda LIKE zretlai013_s02-get_perkz_tienda,
        ld_get_dispo_tienda LIKE zretlai013_s02-get_dispo_tienda,
        ld_get_minbe_tienda LIKE zretlai013_s02-get_minbe_tienda,
        ld_get_plifz_tienda LIKE zretlai013_s02-get_plifz_tienda,
        ld_get_bwscl_tienda LIKE zretlai013_s02-get_bwscl_tienda,
        ld_get_eisbe_tienda LIKE zretlai013_s02-get_eisbe_tienda,
        ld_get_sobst_tienda LIKE zretlai013_s02-get_sobst_tienda.

* 1.- Lógica
*===================================================================================================
*===================================================================================================
* Tienda Usuario
*===================================================================================================
  CLEAR: lit_plantdata, lit_plantdatax.

  lit_plantdata-function    = '009'.
  lit_plantdata-material    = zretlai013_s02-matnr.                                                 "Artículo
  lit_plantdata-plant       = zretlai013_s02-get_werks_usuario.                                     "Tienda
* lit_plantdata-MRPPROFILE  = git_monitor-tdmo_dispr.                                               "Material: Perfil de planificación de necesidades
* lit_plantdata-replentime  = git_monitor-tdmo_wzeit.                                               "Tiempo global de reaprovisionamiento (días laborables)
  lit_plantdata-mrp_type    = zretlai013_s02-get_dismm_tienda.                                      "Característica de planificación de necesidades
  lit_plantdata-availcheck  = zretlai013_s02-get_mtvfp_tienda.                                      "Grupo de verificación p.verificación de disponibilidad
  lit_plantdata-auto_p_ord  = 'X'.                                                                  "Indicador: pedido automático permitido
  lit_plantdata-period_ind  = zretlai013_s02-get_perkz_tienda.                                      "Indicador de período
  lit_plantdata-mrp_ctrler  = zretlai013_s02-get_dispo_tienda.                                      "Planificador de necesidades temporal
* lit_plantdata-lotsizekey  = git_monitor-tdmo_disls.                                               "Tamaño de lote de planificación de necesidades
  lit_plantdata-reorder_pt  = zretlai013_s02-get_minbe_tienda.                                      "Punto de pedido
  lit_plantdata-plnd_delry  = zretlai013_s02-get_plifz_tienda.                                      "Plazo de entrega previsto
  lit_plantdata-sup_source  = zretlai013_s02-get_bwscl_tienda.                                      "Fuente de aprovisionamiento
  lit_plantdata-sloc_exprc  = gd_tienda_modelo_lgfsb.                                               "Almacén propuesto para aprovisionamiento externo
  lit_plantdata-pur_group   = zretlai013_s02-get_ekgrp.                                             "Grupo de compras
  lit_plantdata-neg_stocks  = 'X'.                                                                  "Permitir Stocks negativos
* lit_plantdata-proc_type   = 'F'.                                                                  "Clase de aprovisionamiento
* lit_plantdata-round_prof  = git_monitor-tdmo_rdprf.                                               "Perfil redondeo tienda
  lit_plantdata-safety_stk  = zretlai013_s02-get_eisbe_tienda.                                      "Stock de seguridad

  lit_plantdatax-function   = '009'.
  lit_plantdatax-material   = zretlai013_s02-matnr.
  lit_plantdatax-plant      = zretlai013_s02-get_werks_usuario.
* lit_plantdatax-MRPPROFILE = 'X'.
* lit_plantdatax-replentime = 'X'.
  lit_plantdatax-mrp_type   = 'X'.
  lit_plantdatax-availcheck = 'X'.
  lit_plantdatax-auto_p_ord = 'X'.
  lit_plantdatax-period_ind = 'X'.
  lit_plantdatax-mrp_ctrler = 'X'.
* lit_plantdatax-lotsizekey = 'X'.
  lit_plantdatax-reorder_pt = 'X'.
  lit_plantdatax-plnd_delry = 'X'.
  lit_plantdatax-sup_source = 'X'.
  lit_plantdatax-sloc_exprc = 'X'.
  lit_plantdatax-pur_group  = 'X'.
  lit_plantdatax-neg_stocks = 'X'.
* lit_plantdatax-proc_type  = 'X'.
* lit_plantdatax-round_prof = 'X'.
  lit_plantdatax-safety_stk = 'X'.

  APPEND: lit_plantdata, lit_plantdatax.
ENDFORM.


*&---------------------------------------------------------------------*
*& Form f_fill_storagelocationdata
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> LIT_STORAGELOCATIONDATA
*&      --> LIT_STORAGELOCATIONDATAX
*&---------------------------------------------------------------------*
FORM f_fill_08_storagelocationdata  TABLES   lit_storagelocationdata STRUCTURE bapie1mardrt
                                          lit_storagelocationdatax STRUCTURE bapie1mardrtx.
* Almacenes tienda modelo
*===================================================================================================
  LOOP AT git_almacenes_modelo_tdmo.

    CLEAR: lit_storagelocationdata, lit_storagelocationdatax.

    lit_storagelocationdata-function = '009'.
    lit_storagelocationdata-material = zretlai013_s02-matnr.
    lit_storagelocationdata-plant    = gd_tienda_modelo.
    lit_storagelocationdata-stge_loc = git_almacenes_modelo_tdmo-valor1.

    lit_storagelocationdatax-function = '009'.
    lit_storagelocationdatax-material = zretlai013_s02-matnr.
    lit_storagelocationdatax-plant    = gd_tienda_modelo.
    lit_storagelocationdatax-stge_loc = git_almacenes_modelo_tdmo-valor1.

    APPEND: lit_storagelocationdata, lit_storagelocationdatax.

  ENDLOOP.

* Almacenes centro modelo
*===================================================================================================
  LOOP AT git_almacenes_modelo_cdmo.

    CLEAR: lit_storagelocationdata, lit_storagelocationdatax.

    lit_storagelocationdata-function = '009'.
    lit_storagelocationdata-material = zretlai013_s02-matnr.
    lit_storagelocationdata-plant    = gd_centro_modelo.
    lit_storagelocationdata-stge_loc = git_almacenes_modelo_cdmo-valor1.

    lit_storagelocationdatax-function = '009'.
    lit_storagelocationdatax-material = zretlai013_s02-matnr.
    lit_storagelocationdatax-plant    = gd_centro_modelo.
    lit_storagelocationdatax-stge_loc = git_almacenes_modelo_cdmo-valor1.

    APPEND: lit_storagelocationdata, lit_storagelocationdatax.

  ENDLOOP.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form f_fill_taxclassificactions
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> LIT_TAXCLASSIFICATIONS
*&      --> LIT_TAXCLASSIFICATIONSX
*&---------------------------------------------------------------------*
FORM f_fill_09_taxclassificactions  TABLES   lit_taxclassifications STRUCTURE bapie1mlanrt.
* Clasificación fiscal
  CLEAR lit_taxclassifications.
  lit_taxclassifications-function     = '009'.
  lit_taxclassifications-material     = zretlai013_s02-matnr.
  lit_taxclassifications-depcountry   = 'ES'.
  lit_taxclassifications-tax_type_1   = 'MWST'.
  IF zretlai013_s01-sap = ''.
    lit_taxclassifications-taxclass_1   = zretlai013_s02-get_taklv_cegal.                           "Clasificación fiscal para el material
  ELSE.
    lit_taxclassifications-taxclass_1   = zretlai013_s02-get_taklv.                                 "Clasificación fiscal para el material
  ENDIF.
*  lit_taxclassifications-tax_type_2  = 'ZIGI'.
*  lit_taxclassifications-taxclass_2  = git_monitor-db_taklv2.
  APPEND lit_taxclassifications.
ENDFORM.


*&---------------------------------------------------------------------*
*& Form f_consulta_ean_cegald
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> ZRETLAI013_S02_EAN11
*&      <-- LD_RESPONSE
*&---------------------------------------------------------------------*
FORM f_consulta_ean_cegald  USING    pe_ean11
                            CHANGING ps_response.

* 0.- Declaración de variables
*===================================================================================================
  DATA: ld_absolute_uri(1000),
        lit_response_entity_body TYPE text1024 OCCURS 0 WITH HEADER LINE,
        lit_response_headers     TYPE text255 OCCURS 0 WITH HEADER LINE,
        ld_dataset(1000),
        ld_file_name             LIKE epsf-epsfilnam,
        ld_linea                 TYPE text1024,
        lv_hex(4)                TYPE x VALUE '0900',
        ld_cegalenred_usuario    TYPE text132,
        ld_cegalenred_password   TYPE text132.

  FIELD-SYMBOLS: <fs_0900> TYPE c.

* 1.- Lógica
*===================================================================================================
*>Inicializaciones
  CLEAR ps_response.
  ASSIGN lv_hex TO <fs_0900> CASTING.

*>Obtener usuario y contraseña de cegalenred
  SELECT SINGLE valor1
    FROM zretlai013_param
    INTO ld_cegalenred_usuario
   WHERE param = 'CEGALENRED_USUARIO'.

  SELECT SINGLE valor1
    FROM zretlai013_param
    INTO ld_cegalenred_password
   WHERE param = 'CEGALENRED_PASSWORD'.

  IF sy-sysid = 'LAD'.
    ld_dataset = 'D:\usr\sap\LAD\SYS\src\test.txt'.
  ELSEIF sy-sysid = 'LAP'.
    ld_dataset = 'D:\usr\sap\LAP\SYS\src\test.txt'.
  ENDIF.

*>Confeccionar URL de consulta GET a CEGALD
  CONCATENATE 'http://www.cegalenred.com/peticiones/fichalibro.xml.php?USUARIO='
              ld_cegalenred_usuario
              '&CLAVE='
              ld_cegalenred_password
              '&TIPOFICHA=C&version_sinli=09&ISBN='
              pe_ean11
              '&formato=XML'
         INTO ld_absolute_uri.

*>Lanzar consulta GET a CEGALD
  CALL FUNCTION 'HTTP_GET'
    EXPORTING
      absolute_uri          = ld_absolute_uri
*     REQUEST_ENTITY_BODY_LENGTH        =
      rfc_destination       = 'SAPHTTPA'
*     PROXY                 =
*     PROXY_USER            =
*     PROXY_PASSWORD        =
*     USER                  =
*     PASSWORD              =
      blankstocrlf          = 'X'
*     TIMEOUT               =
*   IMPORTING
*     STATUS_CODE           =
*     STATUS_TEXT           =
*     RESPONSE_ENTITY_BODY_LENGTH       =
    TABLES
*     REQUEST_ENTITY_BODY   =
      response_entity_body  = lit_response_entity_body
      response_headers      = lit_response_headers
*     REQUEST_HEADERS       =
    EXCEPTIONS
      connect_failed        = 1
      timeout               = 2
      internal_error        = 3
      tcpip_error           = 4
      data_error            = 5
      system_failure        = 6
      communication_failure = 7
      OTHERS                = 8.

  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE 'I' NUMBER sy-msgno
             WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.

    EXIT.
  ENDIF.

  OPEN DATASET ld_dataset FOR OUTPUT IN TEXT MODE ENCODING NON-UNICODE  IGNORING CONVERSION ERRORS.

  LOOP AT lit_response_entity_body.
    TRANSFER lit_response_entity_body TO ld_dataset.
  ENDLOOP.

  CLOSE DATASET ld_dataset.

  REFRESH lit_response_entity_body.

  OPEN DATASET ld_dataset FOR INPUT IN TEXT MODE ENCODING UTF-8 IGNORING CONVERSION ERRORS.

  DO.
    READ DATASET ld_dataset INTO ld_linea.

    IF sy-subrc = 0.
      lit_response_entity_body = ld_linea.
      APPEND lit_response_entity_body.
    ELSE.
      EXIT.
    ENDIF.
  ENDDO.

  CLOSE DATASET ld_dataset.

  LOOP AT lit_response_entity_body.
    CONCATENATE ps_response lit_response_entity_body INTO ps_response.
  ENDLOOP.

  REPLACE ALL OCCURRENCES OF <fs_0900>(1) IN ps_response WITH ''.



  CALL FUNCTION 'EPS_DELETE_FILE'
    EXPORTING
      file_name              = 'test.txt'
*     IV_LONG_FILE_NAME      =
      dir_name               = 'D:\usr\sap\LAD\SYS\src\'
*     IV_LONG_DIR_NAME       =
*   IMPORTING
*     FILE_PATH              =
*     EV_LONG_FILE_PATH      =
    EXCEPTIONS
      invalid_eps_subdir     = 1
      sapgparam_failed       = 2
      build_directory_failed = 3
      no_authorization       = 4
      build_path_failed      = 5
      delete_failed          = 6
      OTHERS                 = 7.
  IF sy-subrc <> 0.
* Implement suitable error handling here
  ENDIF.
ENDFORM.

*===================================================================================================
* FORM F_9000_PBO_CONFIG
*===================================================================================================
* Configuración campos pantalla 9000
*===================================================================================================
FORM f_pbo_9000_config .
  IF gf_ean_leido = 'X'.
*   Si han leido un EAN...
    PERFORM f_pbo_9000_config_ean_leido.
  ELSE.
*   Si no han leido un EAN
    PERFORM f_pbo_9000_config_ean_no_leido.
  ENDIF.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form f_inicializar_pantalla
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM f_inicializar_pantalla .
  gf_ean_leido      = ''.
  gd_ruta_completa  = ''.
  gf_cargar_photo   = ''.

  CLEAR: zretlai013_s02,
         zretlai013_s01,
         git_lineas_texto_final,
         git_log,
         git_log_all,
         git_resumen,
         git_resumen_sap,
         git_proveedores_editorial,
         gf_libmod.

  REFRESH:  git_lineas_texto_final,
            git_lineas_texto_final,
            git_log,
            git_log_all,
            git_resumen,
            git_resumen_sap,
            git_proveedores_editorial.

  PERFORM f_9000_free_textos.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form f_status_9000
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM f_status_9000 .
  DATA: lit_excluding LIKE sy-ucomm OCCURS 0.

  IF gf_ean_leido = ''.
    APPEND 'CREAR_ART' TO lit_excluding.
    APPEND 'MODIF_ART' TO lit_excluding.
  ELSE.
    APPEND 'MODIFP' TO lit_excluding.
    append 'CAMBIARTIENDA' to lit_excluding.

    IF zretlai013_s01-sap = 'X'.
      APPEND 'CREAR_ART' TO lit_excluding.
    ELSE.
      APPEND 'MODIF_ART' TO lit_excluding.
    ENDIF.
  ENDIF.

  SET PF-STATUS 'STATUS_9000' EXCLUDING lit_excluding.

  SET TITLEBAR 'T01' WITH zretlai013_s02-get_werks_usuario zretlai013_s02-get_werks_usuariot.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form f_9000_pbo_init_textos
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM f_9000_pbo_init_textos .
* 0.- Declaración de variables
*===================================================================================================
  DATA: lit_lineas_texto(132) OCCURS 0.

* 1.- Lógica
*===================================================================================================

*>Cargamos en pantalla cuadro de textos con el resumen del artículo.
* · En modo CREACION, mostrará el resumen devuelto por CEGAL
* · En modo MODIFICACIÓN, mostrará el resumen del artículo en SAP
  IF gr_editor_container IS INITIAL.
*   Crear cuadro de texto
    CREATE OBJECT gr_editor_container
      EXPORTING
        container_name              = 'CONTAINER_RESUMEN'
      EXCEPTIONS
        cntl_error                  = 1
        cntl_system_error           = 2
        create_error                = 3
        lifetime_error              = 4
        lifetime_dynpro_dynpro_link = 5.

    IF sy-subrc NE 0. ENDIF.

    CREATE OBJECT gr_editor
      EXPORTING
*       max_number_chars           =
*       style                      = 0
        wordwrap_mode              = cl_gui_textedit=>wordwrap_at_fixed_position
        wordwrap_position          = 132
        wordwrap_to_linebreak_mode = cl_gui_textedit=>true
*       filedrop_mode              = DROPFILE_EVENT_OFF
        parent                     = gr_editor_container
*       lifetime                   =
*       name                       =
      EXCEPTIONS
        error_cntl_create          = 1
        error_cntl_init            = 2
        error_cntl_link            = 3
        error_dp_create            = 4
        gui_type_not_supported     = 5
        OTHERS                     = 6.

    IF sy-subrc <> 0.  ENDIF.

    REFRESH lit_lineas_texto.
    IF zretlai013_s01-sap = 'X'.
*     Si el artículo existe en SAP, mostraremos el resumen que hay en SAP
      LOOP AT git_resumen_sap.
        APPEND git_resumen_sap-tdline TO lit_lineas_texto.
      ENDLOOP.
    ELSE.
*     Si el artículo NO existe en SAP, mostraremos el resumen devuelto por CEGAL
      LOOP AT git_resumen.
        APPEND git_resumen-tdline TO lit_lineas_texto.
      ENDLOOP.
    ENDIF.

    CALL METHOD gr_editor->set_text_as_r3table
      EXPORTING
        table           = lit_lineas_texto[]
      EXCEPTIONS
        error_dp        = 1
        error_dp_create = 2
        OTHERS          = 3.
    IF sy-subrc <> 0.
*    Implement suitable error handling here
    ENDIF.

    IF zretlai013_s01-sap = 'X'.
      CALL METHOD gr_editor->set_readonly_mode
        EXPORTING
          readonly_mode          = 1
        EXCEPTIONS
          error_cntl_call_method = 1
          invalid_parameter      = 2
          OTHERS                 = 3.
    ENDIF.
  ENDIF.

*>Cargamos en pantalla el cuadro de textos para el modificación donde siempre se mostrará el resumen
* devuelto por cegal y que no debe ser modificable.
  IF zretlai013_s01-sap = 'X'.
*   Crear cuadro de texto
    CREATE OBJECT gr_editor_container_cegal
      EXPORTING
        container_name              = 'CONTAINER_RESUMEN_CEGAL'
      EXCEPTIONS
        cntl_error                  = 1
        cntl_system_error           = 2
        create_error                = 3
        lifetime_error              = 4
        lifetime_dynpro_dynpro_link = 5.

    IF sy-subrc NE 0. ENDIF.

*   create calls constructor, which initializes, creats and links
*   TextEdit Control
    CREATE OBJECT gr_editor_cegal
      EXPORTING
*       max_number_chars           =
*       style                      = 0
        wordwrap_mode              = cl_gui_textedit=>wordwrap_at_fixed_position
        wordwrap_position          = 132
        wordwrap_to_linebreak_mode = cl_gui_textedit=>true
*       filedrop_mode              = DROPFILE_EVENT_OFF
        parent                     = gr_editor_container_cegal
*       lifetime                   =
*       name                       =
      EXCEPTIONS
        error_cntl_create          = 1
        error_cntl_init            = 2
        error_cntl_link            = 3
        error_dp_create            = 4
        gui_type_not_supported     = 5
        OTHERS                     = 6.

    IF sy-subrc <> 0.  ENDIF.

    REFRESH lit_lineas_texto.
    LOOP AT git_resumen.
      APPEND git_resumen-tdline TO lit_lineas_texto.
    ENDLOOP.

    CALL METHOD gr_editor_cegal->set_text_as_r3table
      EXPORTING
        table           = lit_lineas_texto[]
      EXCEPTIONS
        error_dp        = 1
        error_dp_create = 2
        OTHERS          = 3.
    IF sy-subrc <> 0.
*    Implement suitable error handling here
    ENDIF.
  ENDIF.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form f_9000_free_textos
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM f_9000_free_textos .

  IF gr_editor_cegal IS NOT INITIAL.
    CALL METHOD gr_editor_cegal->free
      EXCEPTIONS
        cntl_error        = 1
        cntl_system_error = 2
        OTHERS            = 3.
    IF sy-subrc <> 0. ENDIF.
  ENDIF.

  FREE gr_editor_cegal.

  IF gr_editor_container_cegal IS NOT INITIAL.
    CALL METHOD gr_editor_container_cegal->free
      EXCEPTIONS
        cntl_error        = 1
        cntl_system_error = 2
        OTHERS            = 3.
    IF sy-subrc <> 0.
    ENDIF.
  ENDIF.

  FREE gr_editor_container_cegal.

  IF gr_editor IS NOT INITIAL.
    CALL METHOD gr_editor->free
      EXCEPTIONS
        cntl_error        = 1
        cntl_system_error = 2
        OTHERS            = 3.
    IF sy-subrc <> 0. ENDIF.
  ENDIF.

  IF gr_editor_container IS NOT INITIAL.
    CALL METHOD gr_editor_container->free
      EXCEPTIONS
        cntl_error        = 1
        cntl_system_error = 2
        OTHERS            = 3.
    IF sy-subrc <> 0.
    ENDIF.
  ENDIF.

  FREE gr_editor.
  FREE gr_editor_container.



ENDFORM.

*===================================================================================================
*& Form f_get_lifnr_spp_from_nom_edit
*===================================================================================================
FORM f_get_prov_from_editorial USING    pe_mfrnr
                                        pe_werks
                               CHANGING ps_lifnr
                                        ps_lifnrt.

* 0.- Declaración de variables
*===================================================================================================
  DATA: lit_but050 LIKE but050 OCCURS 0 WITH HEADER LINE,

        BEGIN OF lit_lifnr OCCURS 0,
          lifnr  LIKE lfa1-lifnr,
          lifnrt LIKE lfa1-name1,
          lzone  TYPE lzone,
          lzonet TYPE bezei20,
          relif  LIKE eina-relif,
        END OF lit_lifnr.

* 1.- Lógica
*===================================================================================================
*>Inicializar retorno
  CLEAR: ps_lifnr,
         ps_lifnrt.

*>Si no se ha determinado editorial no podemos determinar proveedores, por lo que nos salimos
  IF pe_mfrnr IS INITIAL.
    EXIT.
  ENDIF.

*>Obtener proveedores vigentes asociados a la editorial
  SELECT *
    FROM but050
    INTO TABLE lit_but050
   WHERE partner2 = pe_mfrnr
     AND reltyp   = 'BUR002'
     AND date_from <= sy-datum
     AND date_to >= sy-datum.

*>Guardamos los proveedores asociados a la editorial de forma global
  REFRESH git_proveedores_editorial.

  LOOP AT lit_but050.
    CLEAR git_proveedores_editorial.

*   Numero proveedor BP
    git_proveedores_editorial-lifnr = lit_but050-partner1.

*   Convertimos a proveedor real
    SELECT SINGLE supplier
      FROM abusinesspartner
      INTO git_proveedores_editorial-lifnr
     WHERE businesspartner = git_proveedores_editorial-lifnr.

*   Nombre proveedor
    PERFORM f_get_lifnrt USING    git_proveedores_editorial-lifnr
                         CHANGING git_proveedores_editorial-lifnrt.
    APPEND git_proveedores_editorial.
  ENDLOOP.

*>Obtener país y zona de la tienda del usuario
  zretlai013_s06-werks = pe_werks.
  PERFORM f_get_werkst USING zretlai013_s06-werks CHANGING zretlai013_s06-werkst.
  PERFORM f_get_werks_zona USING    pe_werks
                           CHANGING zretlai013_s06-land1
                                    zretlai013_s06-land1t
                                    zretlai013_s06-lzone
                                    zretlai013_s06-lzonet.

*>Determinamos ahora cuál es el proveedor que aplica a la tienda del usuario

* Buscamos los proveedores que tengan la zona de la tienda o no tengan zona
  LOOP AT git_proveedores_editorial.
*   Para cada proveedor

*   Miramos si el proveedor está asignado a la zona de la tienda
    SELECT SINGLE lifnr
      FROM lflr
      INTO git_proveedores_editorial-lifnr
     WHERE lifnr = git_proveedores_editorial-lifnr
       AND lfreg = zretlai013_s06-lzone.

    IF sy-subrc = 0.
*      ps_lifnr = git_proveedores_editorial-lifnr.
*      ps_lifnrt = git_proveedores_editorial-lifnrt.

*      Si el proveedor está asignado a la zona de la tienda lo contemplamos
      CLEAR lit_lifnr.
      lit_lifnr-lifnr = git_proveedores_editorial-lifnr.
      lit_lifnr-lifnrt = git_proveedores_editorial-lifnrt.
      lit_lifnr-lzone = zretlai013_s06-lzone.
      lit_lifnr-lzonet = zretlai013_s06-lzonet.

      IF zretlai013_s01-sap = 'X'.
        SELECT SINGLE relif
          FROM eina
          INTO lit_lifnr-relif
         WHERE lifnr = lit_lifnr-lifnr
           AND matnr = zretlai013_s02-matnr.
      ENDIF.

      APPEND lit_lifnr.
    ELSE.
*     Si el proveedor no está asignado a la zona de la tienda, miramos si el proveedor no tiene zona
*     asignada
      SELECT SINGLE lifnr
        FROM lflr
        INTO git_proveedores_editorial-lifnr
       WHERE lifnr = git_proveedores_editorial-lifnr.

      IF sy-subrc <> 0.
*       Si el proveedor no tiene ninguna zona asignada también lo contemplamos
        CLEAR lit_lifnr.
        lit_lifnr-lifnr = git_proveedores_editorial-lifnr.
        lit_lifnr-lifnrt = git_proveedores_editorial-lifnrt.
        lit_lifnr-lzone = ''.
        lit_lifnr-lzonet = 'Sin zona asignada'.

        IF zretlai013_s01-sap = 'X'.
          SELECT SINGLE relif
            FROM eina
            INTO lit_lifnr-relif
           WHERE lifnr = lit_lifnr-lifnr
             AND matnr = zretlai013_s02-matnr.
        ENDIF.

        APPEND lit_lifnr.
      ENDIF.
    ENDIF.
  ENDLOOP.

  IF lines( lit_lifnr[] ) = 1.
*   Si hemos determinado un unico proveedor lo seleccionamos y nos salimos
    READ TABLE lit_lifnr INDEX 1.

    ps_lifnr = lit_lifnr-lifnr.
    ps_lifnrt = lit_lifnr-lifnrt.

    EXIT.
  ELSEIF lines( lit_lifnr[] ) > 1.
*   Si hemos determinado más de un proveedor, sacamos popup para que lo seleccionen
    git_lifnr_sel[] = lit_lifnr[].

    CALL SCREEN 0700 STARTING AT 5 5.

    ps_lifnr = gd_lifnr.
    ps_lifnrt = gd_lifnrt.

    EXIT.
  ENDIF.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form f_get_lifnrt
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> ZRETLAI013_S02_GET_LIFNR
*&      <-- ZRETLAI013_S02_GET_LIFNRT
*&---------------------------------------------------------------------*
FORM f_get_lifnrt  USING    pe_lifnr
                   CHANGING ps_lifnrt.

*  SELECT SINGLE name1
*    FROM lfa1
*    INTO ps_lifnrt
*   WHERE lifnr = pe_lifnr.

  SELECT SINGLE name_org1
 FROM  but000
 INTO ps_lifnrt
WHERE partner = pe_lifnr.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form f_9000_pai_validar_lifnr_ltsnr
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM f_9000_pai_validar_lifnr.
  IF zretlai013_s02-get_lifnr IS INITIAL.
    CLEAR: zretlai013_s02-get_lifnrt.
  ELSE.
    SELECT SINGLE lifnr
      FROM lfa1
      INTO zretlai013_s02-get_lifnr
     WHERE lifnr = zretlai013_s02-get_lifnr.

    IF sy-subrc <> 0.
*     Msg: Proveedor & no válido.
      MESSAGE e002(zretlai013) WITH zretlai013_s02-get_lifnr.
    ENDIF.
  ENDIF.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form f_9000_pbo_init_data
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM f_9000_pbo_init_data .
  IF zretlai013_s02-get_lifnr IS INITIAL.
    CLEAR zretlai013_s02-get_lifnrt.
  ELSE.
    PERFORM f_get_lifnrt USING zretlai013_s02-get_lifnr CHANGING zretlai013_s02-get_lifnrt.
  ENDIF.

* Tipo de producto
  IF zretlai013_s02-get_tipo_producto IS INITIAL.
    IF zretlai013_s01-sap = ''.
      CLEAR: zretlai013_s02-get_tipo_productot,
             zretlai013_s02-get_mtart,
             zretlai013_s02-get_mtartt.
    ENDIF.
  ELSE.
    PERFORM f_get_tipo_productot USING zretlai013_s02-get_tipo_producto CHANGING zretlai013_s02-get_tipo_productot.

    IF zretlai013_s02-get_mtart IS INITIAL.
      IF zretlai013_s02-get_tipo_producto = '00' OR
         zretlai013_s02-get_tipo_producto = '10' OR
         zretlai013_s02-get_tipo_producto = '60'.
        zretlai013_s02-get_mtart = 'ZLIB'.
      ELSEIF zretlai013_s02-get_tipo_producto = '20' OR
             zretlai013_s02-get_tipo_producto = '30' OR
             zretlai013_s02-get_tipo_producto = '40' OR
             zretlai013_s02-get_tipo_producto = '50'.
        zretlai013_s02-get_mtart = 'ZAUD'.
      ENDIF.
    ENDIF.
  ENDIF.

  IF zretlai013_s02-get_tipo_producto_cegal IS INITIAL.
    CLEAR zretlai013_s02-get_tipo_producto_cegal.
  ELSE.
    PERFORM f_get_tipo_productot USING    zretlai013_s02-get_tipo_producto_cegal
                                 CHANGING zretlai013_s02-get_tipo_producto_cegalt.
  ENDIF.



  IF zretlai013_s02-get_mtart IS INITIAL.
    CLEAR: zretlai013_s02-get_mtartt.
  ELSE.
    PERFORM f_get_mtartt USING zretlai013_s02-get_mtart CHANGING zretlai013_s02-get_mtartt.
  ENDIF.

  IF zretlai013_s02-get_encuadernacion IS INITIAL OR
     ( zretlai013_s02-get_tipo_producto IS INITIAL AND
       zretlai013_s02-get_mtart IS INITIAL ).
    CLEAR zretlai013_s02-get_encuadernaciont.
  ELSE.
    PERFORM f_get_encuadernaciont USING    zretlai013_s02-get_encuadernacion
                                           zretlai013_s02-get_tipo_producto
                                           zretlai013_s02-get_mtart
                                  CHANGING zretlai013_s02-get_encuadernaciont.

    PERFORM f_get_encuadernaciont USING    zretlai013_s02-get_encuadernacion_cegal
                                           zretlai013_s02-get_tipo_producto
                                           zretlai013_s02-get_mtart
                                  CHANGING zretlai013_s02-get_encuadernacion_cegalt.
  ENDIF.

  IF zretlai013_s02-get_matkl IS INITIAL.
    CLEAR: zretlai013_s02-get_matklt.
  ELSE.
    SELECT SINGLE wgbez60
      FROM t023t
      INTO zretlai013_s02-get_matklt
     WHERE spras = sy-langu
       AND matkl = zretlai013_s02-get_matkl.
  ENDIF.

  IF zretlai013_s02-get_ekgrp IS INITIAL.
    CLEAR zretlai013_s02-get_ekgrpt.
  ELSE.
    PERFORM f_get_ekgrpt USING zretlai013_s02-get_ekgrp CHANGING zretlai013_s02-get_ekgrpt.
  ENDIF.

  IF zretlai013_s02-get_situacion IS INITIAL.
    CLEAR zretlai013_s02-get_situaciont.
  ELSE.
    PERFORM f_get_situaciont USING zretlai013_s02-get_situacion CHANGING zretlai013_s02-get_situaciont.
  ENDIF.

  IF zretlai013_s02-get_situacion_cegal IS INITIAL.
    CLEAR zretlai013_s02-get_situacion_cegalt.
  ELSE.
    PERFORM f_get_situaciont USING zretlai013_s02-get_situacion_cegal CHANGING zretlai013_s02-get_situacion_cegalt.
  ENDIF.

*>Denominación indicador de impuestos
  IF zretlai013_s02-get_taklv IS INITIAL.
    CLEAR zretlai013_s02-get_taklvt.
  ELSE.
    PERFORM f_get_taklvt USING zretlai013_s02-get_taklv CHANGING zretlai013_s02-get_taklvt.
  ENDIF.

*>Denominación jerarquía de producto
  IF zretlai013_s02-get_prodh IS INITIAL.
    CLEAR zretlai013_s02-get_prodht.
  ELSE.
    PERFORM f_get_prodht USING zretlai013_s02-get_prodh CHANGING zretlai013_s02-get_prodht.
  ENDIF.

*>Denominación caracteristica planificación de necesidades tienda
  IF zretlai013_s02-get_dismm_tienda IS INITIAL.
    CLEAR zretlai013_s02-get_dismm_tiendat.
  ELSE.
    PERFORM f_get_dismmt USING zretlai013_s02-get_dismm_tienda CHANGING zretlai013_s02-get_dismm_tiendat.
  ENDIF.

*>Denominiación característica planificación de necesidades centro
  PERFORM f_get_dismmt USING zretlai013_s02-get_dismm_centro CHANGING zretlai013_s02-get_dismm_centrot.

*>Denominación verificación disponibilidad tienda
  IF zretlai013_s02-get_mtvfp_tienda IS INITIAL.
    CLEAR zretlai013_s02-get_mtvfp_tiendat.
  ELSE.
    PERFORM f_get_mtvfpt USING zretlai013_s02-get_mtvfp_tienda CHANGING zretlai013_s02-get_mtvfp_tiendat.
  ENDIF.

*>Denominación verificación disponibilidad centro
  IF zretlai013_s02-get_mtvfp_centro IS INITIAL.
    CLEAR zretlai013_s02-get_mtvfp_centrot.
  ELSE.
    PERFORM f_get_mtvfpt USING zretlai013_s02-get_mtvfp_centro CHANGING zretlai013_s02-get_mtvfp_centrot.
  ENDIF.

*>Denominación indicador de periodo tienda
  PERFORM f_get_perkzt USING zretlai013_s02-get_perkz_tienda CHANGING zretlai013_s02-get_perkz_tiendat.

*>Denominación indicador de periodo centro
  PERFORM f_get_perkzt USING zretlai013_s02-get_perkz_centro CHANGING zretlai013_s02-get_perkz_centrot.

*>Denominación planificador de necesidades tienda
  PERFORM f_get_dispot USING 'TDMO' zretlai013_s02-get_dispo_tienda CHANGING zretlai013_s02-get_dispo_tiendat.

*>Denominación planificador de necesidades centro
  PERFORM f_get_dispot USING 'CD01' zretlai013_s02-get_dispo_centro CHANGING zretlai013_s02-get_dispo_centrot.

*>Denominación fuente aprovisionamiento tienda
  IF zretlai013_s02-get_bwscl_tienda IS INITIAL.
    CLEAR zretlai013_s02-get_bwscl_tiendat.
  ELSE.
    PERFORM f_get_bwsclt USING zretlai013_s02-get_bwscl_tienda CHANGING zretlai013_s02-get_bwscl_tiendat.
  ENDIF.

*>Denominación fuente aprovisionamiento centro
  PERFORM f_get_bwsclt USING zretlai013_s02-get_bwscl_centro CHANGING zretlai013_s02-get_bwscl_centrot.

*>Denominación acuerdo devolución
  PERFORM f_get_rueckt USING zretlai013_s02-get_rueck CHANGING zretlai013_s02-get_rueckt.

*>Denominación idiomas
  if ZRETLAI013_S02-get_idioma_original is initial.
    clear ZRETLAI013_S02-get_idioma_originalt.
  else.
    perform f_get_idioma_originalt using ZRETLAI013_S02-get_idioma_original
                                CHANGING ZRETLAI013_S02-get_idioma_originalt.
  endif.

  if ZRETLAI013_S02-get_idioma_original_cegal is initial.
    clear ZRETLAI013_S02-get_idioma_original_cegalt.
  else.
    perform f_get_idioma_originalt using ZRETLAI013_S02-get_idioma_original_cegal
                                CHANGING ZRETLAI013_S02-get_idioma_original_cegalt.
  endif.

  if ZRETLAI013_S02-get_lengua_publicacion is initial.
    clear ZRETLAI013_S02-get_lengua_publicaciont.
  else.
    perform f_get_lengua_publicaciont using ZRETLAI013_S02-get_lengua_publicacion
                                   CHANGING ZRETLAI013_S02-get_lengua_publicaciont.
  endif.

  if ZRETLAI013_S02-get_lengua_publicacion_cegal is initial.
    clear ZRETLAI013_S02-get_lengua_publicacion_cegalt.
  else.
    perform f_get_lengua_publicaciont using ZRETLAI013_S02-get_lengua_publicacion_cegal
                                   CHANGING ZRETLAI013_S02-get_lengua_publicacion_cegalt.
  endif.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form f_get_tipo_productot
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> ZRETLAI013_S02_GET_TIPO_PRODUC
*&      <-- ZRETLAI013_S02_GET_TIPO_PRODUC
*&---------------------------------------------------------------------*
FORM f_get_tipo_productot  USING    pe_tipo_producto
                           CHANGING ps_tipo_productot.

  SELECT SINGLE valor2
    FROM zretlai013_param
    INTO ps_tipo_productot
   WHERE param = 'TIPO_PRODUCTO'
     AND valor1 = pe_tipo_producto.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form f_get_mtartt
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> ZRETLAI013_S02_GET_MTART
*&      <-- ZRETLAI013_S02_GET_MTARTT
*&---------------------------------------------------------------------*
FORM f_get_mtartt  USING    pe_mtart
                   CHANGING ps_mtartt.
  SELECT SINGLE mtbez
    FROM t134t
    INTO ps_mtartt
   WHERE spras = sy-langu
     AND mtart = pe_mtart.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form f_get_encuadernaciont
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> ZRETLAI013_S02_GET_ENCUADERNAC
*&      <-- ZRETLAI013_S02_GET_ENCUADERNAC
*&---------------------------------------------------------------------*
FORM f_get_encuadernaciont  USING    pe_encuadernacion
                                     pe_tipo_producto
                                     pe_mtart
                            CHANGING ps_encuadernaciont.

  IF pe_mtart IS NOT INITIAL.
    IF pe_mtart = 'ZLIB'.
      SELECT SINGLE valor2
        FROM zretlai013_param
        INTO ps_encuadernaciont
       WHERE param = 'ENCUADERNACION_LIBROS'
         AND valor1 = pe_encuadernacion.
    ELSE.
      SELECT SINGLE valor2
        FROM zretlai013_param
        INTO ps_encuadernaciont
       WHERE param = 'ENCUADERNACION_ELIBROS'
         AND valor1 = pe_encuadernacion.
    ENDIF.
  ELSE.
    IF pe_tipo_producto = '00' OR
       pe_tipo_producto = '10' OR
       pe_tipo_producto = '60'.
      SELECT SINGLE valor2
        FROM zretlai013_param
        INTO ps_encuadernaciont
       WHERE param = 'ENCUADERNACION_LIBROS'
         AND valor1 = pe_encuadernacion.
    ELSE.
      SELECT SINGLE valor2
        FROM zretlai013_param
        INTO ps_encuadernaciont
       WHERE param = 'ENCUADERNACION_ELIBROS'
         AND valor1 = pe_encuadernacion.
    ENDIF.
  ENDIF.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form f_9000_pai_validar_tipprod_enc
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM f_9000_pai_validar_tipprod_enc .
  IF zretlai013_s02-get_tipo_producto = '10'.
    SELECT SINGLE valor1
      FROM zretlai013_param
      INTO zretlai013_s02-get_encuadernacion
     WHERE param = 'ENCUADERNACION_LIBROS'
       AND valor1 = zretlai013_s02-get_encuadernacion.

    IF sy-subrc <> 0.
*     Msg: La combinación Tipo producto / Encuadernación no es válida.
      MESSAGE e004(zretlai013).
    ENDIF.
  ELSE.
    SELECT SINGLE valor1
      FROM zretlai013_param
      INTO zretlai013_s02-get_encuadernacion
     WHERE param = 'ENCUADERNACION_ELIBROS'
       AND valor1 = zretlai013_s02-get_encuadernacion.

    IF sy-subrc <> 0.
*     Msg: La combinación Tipo producto / Encuadernación no es válida.
      MESSAGE e004(zretlai013).
    ENDIF.
  ENDIF.
ENDFORM.

*===================================================================================================
*& Form f_convertir_idioma_sinli
*===================================================================================================
* Convierte el código de idioma CEGAL a idioma SAP de Laie
*===================================================================================================
FORM f_convertir_idioma_sinli  USING    pe_idioma
                               CHANGING ps_idioma.
*===================================================================================================
* 0.- Declaración de variables
*===================================================================================================
  DATA: ld_valor2 LIKE zretlai013_param-valor2.

*===================================================================================================
* 1.- Lógica
*===================================================================================================
  TRANSLATE pe_idioma to UPPER CASE.

*>Obtenemos conversión del idioma CEGAL a idioma SAP
  SELECT SINGLE valor2
    FROM zretlai013_param
    INTO ps_idioma
   WHERE param = 'IDIOMA_SINLI'
     AND valor1 = pe_idioma.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form f_get_ekorgt
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> ZRETLAI013_S02_GET_EKORG
*&      <-- ZRETLAI013_S02_GET_EKORGT
*&---------------------------------------------------------------------*
FORM f_get_ekorgt  USING    pe_ekorg
                   CHANGING ps_ekorgt.

  SELECT SINGLE ekotx
    FROM t024e
    INTO ps_ekorgt
   WHERE ekorg = pe_ekorg.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form f_9000_povr_ekgrp
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM f_9000_povr_ekgrp .
* 0.- Declaración de variables
*======================================================================
  DATA: BEGIN OF lit_ekgrp OCCURS 0,
          ekgrp TYPE ekgrp,
          eknam TYPE eknam,
        END OF lit_ekgrp.

* 1.- Logica
*======================================================================
  SELECT valor1 AS ekgrp
    FROM zretlai013_param
    INTO CORRESPONDING FIELDS OF TABLE lit_ekgrp
   WHERE param = 'EKGRP_POSIBLES'.

  LOOP AT lit_ekgrp.
    SELECT SINGLE eknam
      FROM t024
      INTO lit_ekgrp-eknam
     WHERE ekgrp = lit_ekgrp-ekgrp.

    MODIFY lit_ekgrp.
  ENDLOOP.

  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING
      dynpprog        = sy-repid
      dynpnr          = '9000'
      dynprofield     = 'ZRETLAI013_S02-EKGRP'
      retfield        = 'EKGRP'
      value_org       = 'S'
    TABLES
      value_tab       = lit_ekgrp
    EXCEPTIONS
      parameter_error = 1
      no_values_found = 2
      OTHERS          = 3.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form f_9000_pai_validar_ekgrp
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM f_9000_pai_validar_ekgrp .
  SELECT SINGLE valor1
    FROM zretlai013_param
    INTO zretlai013_s02-get_ekgrp
   WHERE param = 'EKGRP_POSIBLES'
     AND valor1 = zretlai013_s02-get_ekgrp.

  IF sy-subrc <> 0.
*   Msg: Grupo de compras & no válido.
    MESSAGE e005(zretlai013) WITH zretlai013_s02-get_ekgrp.
  ENDIF.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form f_user_command_9000_modif_art
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM f_user_command_9000_modif_art .
* 0.- Declaración de variables
*===================================================================================================
  DATA: wa_zretlai013_t01           LIKE zretlai013_t01,
        lit_zretlai013_t02          LIKE zretlai013_t02 OCCURS 0 WITH HEADER LINE,
        ld_cont                     TYPE int4,
        ld_respuesta                TYPE char1,
        lf_error(1),
        ld_index                    LIKE sy-tabix,
        lf_error_b(1),
        ld_mode(1)                  VALUE 'N',
        lr_headdata                 LIKE bapie1mathead,
        lr_return                   LIKE bapireturn1,
        lr_header                   LIKE thead,
        lit_lines                   LIKE tline              OCCURS 0 WITH HEADER LINE,
        lit_clientdata              LIKE bapie1marart       OCCURS 0 WITH HEADER LINE,
        lit_clientdatax             LIKE bapie1marartx      OCCURS 0 WITH HEADER LINE,
        lit_materialdescription     LIKE bapie1maktrt       OCCURS 0 WITH HEADER LINE,
        lit_unitsofmeasure          LIKE bapie1marmrt       OCCURS 0 WITH HEADER LINE,
        lit_unitsofmeasurex         LIKE bapie1marmrtx      OCCURS 0 WITH HEADER LINE,
        lit_addnclientdata          LIKE bapie1maw1rt       OCCURS 0 WITH HEADER LINE,
        lit_addnclientdatax         LIKE bapie1maw1rtx      OCCURS 0 WITH HEADER LINE,
        lit_internationalartnos     LIKE bapie1meanrt       OCCURS 0 WITH HEADER LINE,
*        lit_eans_adicionales      LIKE gr_ean11           OCCURS 0 WITH HEADER LINE,
        lit_salesdata               LIKE bapie1mvkert       OCCURS 0 WITH HEADER LINE,
        lit_salesdatax              LIKE bapie1mvkertx      OCCURS 0 WITH HEADER LINE,
        lit_mensajes                LIKE bdcmsgcoll         OCCURS 0 WITH HEADER LINE,
        lit_plantdata               LIKE bapie1marcrt       OCCURS 0 WITH HEADER LINE,
        lit_plantdatax              LIKE bapie1marcrtx      OCCURS 0 WITH HEADER LINE,
        lit_t001w                   LIKE t001w              OCCURS 0 WITH HEADER LINE,
        lit_warehousenumberdata     LIKE bapie1mlgnrt       OCCURS 0 WITH HEADER LINE,
        lit_warehousenumberdatax    LIKE bapie1mlgnrtx      OCCURS 0 WITH HEADER LINE,
        lit_storagelocationdata     LIKE bapie1mardrt       OCCURS 0 WITH HEADER LINE,
        lit_storagelocationdatax    LIKE bapie1mardrtx      OCCURS 0 WITH HEADER LINE,
        lit_storagetypedata         LIKE bapie1mlgtrt       OCCURS 0 WITH HEADER LINE,
        lit_storagetypedatax        LIKE bapie1mlgtrtx      OCCURS 0 WITH HEADER LINE,
        ld_catalogar_ok             TYPE xflag,
        ld_docnum                   TYPE edi_docnum,
*        lit_tiendas               TYPE zstiendas          OCCURS 0 WITH HEADER LINE,
        lit_recipientparameters     LIKE bapi_wrpl_import   OCCURS 0 WITH HEADER LINE,
        lit_recipientparametersx    LIKE bapi_wrpl_importx  OCCURS 0 WITH HEADER LINE,
        lit_return                  LIKE bapiret2           OCCURS 0 WITH HEADER LINE,
        lit_taxclassifications      LIKE bapie1mlanrt       OCCURS 0 WITH HEADER LINE,
        lit_return_wrf              TYPE bapi_wrf_return_tty,
        lr_hierarchy_data           TYPE bapi_wrf_hier_change_head,
        lr_testrun                  TYPE bapi_wrf_testrun_sty,
        lit_hierarchy_structure     TYPE bapi_wrf_hier_ch_struc_tty,
        lit_description_hierarchy   TYPE bapi_wrf_desc_ch_hier_tty,
        lit_description_structure   TYPE bapi_wrf_desc_ch_struc_tty,
        lit_hierarchy_items         TYPE bapi_wrf_hier_ch_items_tty,
        wa_hierarchy_items          TYPE bapi_wrf_hier_change_items,
        lit_extensionin             TYPE bapi_wrf_extension_tty,
        wa_return                   LIKE bapiret2,
        ld_paso_alta_articulo(2),
        ld_paso_jerarquia(2),
        ld_paso_alta_textos(2),
        ld_paso_catalogar(2),
        ld_paso_reg_info(2),
        ld_paso_cond_ztar(2),
        ld_paso_act_status(2),
        ld_paso_stock_objetivo(2),
        lf_lifnr_9000(1),
        lf_lifnr_2000(1),
        ld_linea                    TYPE numc2,
        ld_dimensiones              LIKE mara-groes,
        wa_lfa1                     TYPE lfa1,
        wa_adrc                     TYPE adrc,
        wa_lagp                     LIKE lagp,
        wa_mlgt                     LIKE mlgt,
        ld_area_alm                 LIKE mlgn-lgbkz,
        lit_zretlai001_t04          LIKE zretlai001_t04 OCCURS 0 WITH HEADER LINE,
        lit_lineas_texto_sap(132)   OCCURS 0 WITH HEADER LINE,
        lit_lineas_texto_cegal(132) OCCURS 0 WITH HEADER LINE,
        lf_diferencias_resumen,
        ld_mfrnr                    LIKE mara-mfrnr,
        ld_zz1_desceditorial_prd    LIKE mara-zz1_desceditorial_prd.


* 1.- Lógica
*===================================================================================================
*>Inicializamos log
  REFRESH git_log.
  REFRESH git_log_all.

*>Validar que se hayan informado los datos requeridos en pantalla
  PERFORM f_validar_datos_pantalla.

  IF git_log[] IS NOT INITIAL.
    CALL SCREEN 0200 STARTING AT 5 5.
  ENDIF.

  READ TABLE git_log WITH KEY tipo = gc_minisemaforo_rojo.

  IF sy-subrc = 0.
    EXIT.
  ENDIF.

*>Msg: ¿Actualizar artículo en el sistema?
  PERFORM f_popup_to_confirm USING TEXT-q02 CHANGING ld_respuesta.

  IF ld_respuesta <> '1'.
    EXIT.
  ENDIF.

*===================================================================================================
* P1->Crear artículo
*===================================================================================================

* Obtener número de artículo
  PERFORM f_fill_01_headdata_mod            CHANGING lr_headdata.
  PERFORM f_fill_02_clientdata_mod          TABLES lit_clientdata lit_clientdatax.
  PERFORM f_fill_03_addnclientdata_mod      TABLES lit_addnclientdata lit_addnclientdatax.
  PERFORM f_fill_04_unitsofmeasure_mod      TABLES lit_unitsofmeasure lit_unitsofmeasurex.
  PERFORM f_fill_05_materialdescript_mod    TABLES lit_materialdescription.
*  PERFORM f_fill_06_salesdata_mod           TABLES lit_salesdata lit_salesdatax.
  PERFORM f_fill_07_plantdata_mod              TABLES lit_plantdata lit_plantdatax.
*  PERFORM f_fill_08_storagelocationdata     TABLES lit_storagelocationdata lit_storagelocationdatax.
  PERFORM f_fill_09_taxclassificactions     TABLES lit_taxclassifications.

  CALL FUNCTION 'BAPI_MATERIAL_MAINTAINDATA_RT'
    EXPORTING
      headdata             = lr_headdata
    IMPORTING
      return               = lr_return
    TABLES
*     VARIANTSKEYS         =
*     CHARACTERISTICVALUE  =
*     CHARACTERISTICVALUEX =
      clientdata           = lit_clientdata
      clientdatax          = lit_clientdatax
*     CLIENTEXT            =
*     CLIENTEXTX           =
      addnlclientdata      = lit_addnclientdata
      addnlclientdatax     = lit_addnclientdatax
      materialdescription  = lit_materialdescription
      plantdata            = lit_plantdata
      plantdatax           = lit_plantdatax
*     PLANTEXT             =
*     PLANTEXTX            =
*     FORECASTPARAMETERS   =
*     FORECASTPARAMETERSX  =
*     FORECASTVALUES       =
*     TOTALCONSUMPTION     =
*     UNPLNDCONSUMPTION    =
*     PLANNINGDATA         =
*     PLANNINGDATAX        =
      storagelocationdata  = lit_storagelocationdata
      storagelocationdatax = lit_storagelocationdatax
*     STORAGELOCATIONEXT   =
*     STORAGELOCATIONEXTX  =
      unitsofmeasure       = lit_unitsofmeasure
      unitsofmeasurex      = lit_unitsofmeasurex
*     unitofmeasuretexts   =
      internationalartnos  = lit_internationalartnos
*     VENDOREAN            =
*     LAYOUTMODULEASSGMT   =
*     LAYOUTMODULEASSGMTX  =
      taxclassifications   = lit_taxclassifications
*     VALUATIONDATA        =
*     VALUATIONDATAX       =
*     VALUATIONEXT         =
*     VALUATIONEXTX        =
      warehousenumberdata  = lit_warehousenumberdata
      warehousenumberdatax = lit_warehousenumberdatax
*     WAREHOUSENUMBEREXT   =
*     WAREHOUSENUMBEREXTX  =
      storagetypedata      = lit_storagetypedata
      storagetypedatax     = lit_storagetypedatax
*     STORAGETYPEEXT       =
*     STORAGETYPEEXTX      =
      salesdata            = lit_salesdata
      salesdatax           = lit_salesdatax
*     SALESEXT             =
*     SALESEXTX            =
*     POSDATA              =
*     POSDATAX             =
*     POSEXT               =
*     POSEXTX              =
*     MATERIALLONGTEXT     =
*     PLANTKEYS            =
*     STORAGELOCATIONKEYS  =
*     DISTRCHAINKEYS       =
*     WAREHOUSENOKEYS      =
*     STORAGETYPEKEYS      =
*     VALUATIONTYPEKEYS    =
    .

*  Hacemos commit
  CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
    EXPORTING
      wait = 'X'
*    IMPORTING
*     RETURN        =
    .

*  Si error al crear articulo, registrar log y finalizar ejecución
  IF lr_return-type = 'E'.
*   Si ERROR...

*   Activamos Flag de error
    lf_error = 'X'.

*   Grabar Log
    CLEAR git_log_all.
    git_log_all-matnr   = zretlai013_s02-matnr.
    git_log_all-matnrt  = zretlai013_s02-get_titulo.
    git_log_all-status  = gc_minisemaforo_rojo.
    git_log_all-paso    = 'P01'.
    git_log_all-pasot   = 'Modificar articulo en SAP'.
    git_log_all-mensaje = lr_return-message.
    git_log_all-mm90    = lr_return-message_v2.
    APPEND git_log_all.
  ELSE.
*   Si articulo creado correctamente, registramos log...

*   Registramos entrada de log
    CLEAR git_log_all.
    git_log_all-matnr   = zretlai013_s02-matnr.
    git_log_all-matnrt  = zretlai013_s02-get_titulo.
    git_log_all-status  = gc_minisemaforo_verde.
    git_log_all-paso    = 'P01'.
    git_log_all-pasot   = 'Modificar articulo en SAP'.
    git_log_all-mensaje = 'Artículo actualizado en el sistema'.
    APPEND git_log_all.

*   Replicamos los textos breves del articulo en textos comerciales
    PERFORM f_crear_articulos_update_tcom.
  ENDIF.

*===================================================================================================
* P2->Actualizar campos ZZ de la MARA
*===================================================================================================
  IF lf_error = ''.
    IF zretlai013_s02-get_mfrnr_new IS NOT INITIAL.
      ld_mfrnr =  zretlai013_s02-get_mfrnr_new.
      ld_zz1_desceditorial_prd = zretlai013_s02-get_mfrnr_newt.
    ELSE.
      ld_mfrnr =  zretlai013_s02-get_mfrnr.
      ld_zz1_desceditorial_prd = zretlai013_s02-get_mfrnrt.
    ENDIF.

*   >APRADAS-28.10.2021 09:26:38-Inicio
*   Obtener de nuevo la denominación del formato por si ha cambiado
    PERFORM f_get_encuadernaciont USING    zretlai013_s02-get_encuadernacion
                                           zretlai013_s02-get_tipo_producto
                                           zretlai013_s02-get_mtart
                                  CHANGING zretlai013_s02-get_encuadernaciont.
*   <APRADAS-28.10.2021 09:26:38-Fin

    UPDATE mara SET zz1_autor_prd           = zretlai013_s02-get_nombre_autor_cegal
                    zz1_idiomaoriginal2_prd  = zretlai013_s02-get_idioma_original_cegal
                    zz1_traductor_prd       = zretlai013_s02-get_traductor_cegal
                    zz1_ilustrador_prd      = zretlai013_s02-get_ilustrador_cubierta_cegal
                    zz1_urlportada_prd      = zretlai013_s02-get_url_cegal
                    zz1_coleccion_prd       = zretlai013_s02-get_coleccion_cegal
                    zz1_cdu_prd             = zretlai013_s02-get_cdu_cegal
                    zz1_ibic_prd            = zretlai013_s02-get_ibic_cegal
                    zz1_idioma2_prd          = zretlai013_s02-get_lengua_publicacion_cegal
                    zz1_numeroedicion_prd   = zretlai013_s02-get_numero_edicion_cegal
                    zz1_subttulo_prd        = zretlai013_s02-get_subtitulo_cegal
                    zz1_formato_prd         = zretlai013_s02-get_encuadernacion_cegalt              "APRADAS-28.10.2021
                    zz1_fechaedicin_prd     = zretlai013_s02-get_fecha_publicacion_cegal
                    zz1_npginas_prd         = zretlai013_s02-get_numero_paginas_cegal
                    zz1_etiquetas_prd       = zretlai013_s02-get_zz1_etiquetas_prd
                    zz1_tejueloalad_prd     = zretlai013_s02-get_zz1_tejueloalad_prd
                    zz1_novedad2_prd        = zretlai013_s02-get_zz1_novedad2_prd
                    mfrnr                   = ld_mfrnr
                    zz1_desceditorial_prd   = ld_zz1_desceditorial_prd
       WHERE matnr = zretlai013_s02-matnr.

    CLEAR git_log_all.
    git_log_all-matnr   = zretlai013_s02-matnr.
    git_log_all-matnrt  = zretlai013_s02-get_titulo.
    git_log_all-status  = gc_minisemaforo_verde.
    git_log_all-paso    = 'P02'.
    git_log_all-pasot   = 'Actualizar datos cliente (ZZ)'.
    git_log_all-mensaje = 'Datos actualizados en artículo'.
    APPEND git_log_all.
*    endif.
  ENDIF.

**===================================================================================================
** P3->Actualizar código de importación
**===================================================================================================
*  IF lf_error = ''.
*    IF zretlai013_s02-get_wstaw IS NOT INITIAL.
*      PERFORM f_set_stawn  USING zretlai013_s02-matnr
*                                 zretlai013_s02-get_wstaw
*                        CHANGING lf_error.
*    ELSE.
*      CLEAR git_log_all.
*      git_log_all-matnr   = zretlai013_s02-matnr.
*      git_log_all-matnrt  = zretlai013_s02-get_titulo.
*      git_log_all-status  = gc_minisemaforo_ambar.
*      git_log_all-paso    = 'P03'.
*      git_log_all-pasot   = 'Actualizar código de importación'.
*      git_log_all-mensaje = 'No aplica'.
*      APPEND git_log_all.
*    ENDIF.
*  ENDIF.

*===================================================================================================
* P61->Actualizar datos centro tienda usuario
*===================================================================================================
*  IF lf_error = ''.
*    PERFORM f_crear_articulos_update_tdxx CHANGING lf_error.
*  ENDIF.

*===================================================================================================
* P62->Actualizar datos planificacion tienda usuario
*===================================================================================================
  IF lf_error = ''.
    PERFORM f_crear_articulos_update_tdxxp CHANGING lf_error.
  ENDIF.

*===================================================================================================
* P7-> Registro info
*===================================================================================================
  IF lf_error = ''.
*   Descartamos los proveedores de la editorial que ya estén dados de alta para el artículo, menos
*   el proveedor asociado a la tienda
    LOOP AT git_proveedores_editorial WHERE lifnr <> zretlai013_s02-get_lifnr.
      ld_index = sy-tabix.

      SELECT SINGLE lifnr
        FROM eina
        INTO git_proveedores_editorial-lifnr
       WHERE matnr = zretlai013_s02-matnr
         AND lifnr = git_proveedores_editorial-lifnr.

      IF sy-subrc = 0.
        DELETE git_proveedores_editorial INDEX ld_index.
      ENDIF.
    ENDLOOP.

*   Actualizamos proveedores
    IF git_proveedores_editorial[] IS NOT INITIAL.
      PERFORM f_crear_articulos_update_prov CHANGING lf_error.
    ELSE.
      CLEAR git_log_all.
      git_log_all-matnr   = zretlai013_s02-matnr.
      git_log_all-matnrt  = zretlai013_s02-get_titulo.
      git_log_all-status  = gc_minisemaforo_ambar.
      git_log_all-paso    = 'P07'.
      git_log_all-pasot   = 'Actualización registros info'.
      git_log_all-mensaje = 'Ningún registro info necesario'.
      APPEND git_log_all.
    ENDIF.
  ENDIF.

*===================================================================================================
* P8->Condición de venta VKP0/VKP1
*===================================================================================================
*  IF lf_error = ''.
*    IF zretlai013_s02-get_precio_con_iva IS NOT INITIAL and
*       zretlai013_s02-get_precio_con_iva <> zretlai013_s02-get_precio_con_iva_cegal.
*      PERFORM f_crear_articulos_update_pvp USING gc_modo_online zretlai013_s02-matnr zretlai013_s02-get_titulo
*                                        CHANGING lf_error.
*    ELSE.
*      CLEAR git_log_all.
*      git_log_all-matnr   = zretlai013_s02-matnr.
*      git_log_all-matnrt  = zretlai013_s02-get_titulo.
*      git_log_all-status  = gc_minisemaforo_verde.
*      git_log_all-paso    = 'P08'.
*      git_log_all-pasot   = 'Alta PVP'.
*      git_log_all-mensaje = 'No aplica - Precios SAP y CEGAL coincidentes'.
*      APPEND git_log_all.
*    ENDIF.
*  ENDIF.

*===================================================================================================
* P9->Textos: Resumen
*===================================================================================================
  IF lf_error = ''.
*   Obtener el resumen de sap
    CALL METHOD gr_editor->get_text_as_r3table
*      EXPORTING
*        only_when_modified     = FALSE
      IMPORTING
        table                  = lit_lineas_texto_sap[]
*       is_modified            =
      EXCEPTIONS
        error_dp               = 1
        error_cntl_call_method = 2
        error_dp_create        = 3
        potential_data_loss    = 4
        OTHERS                 = 5.

    IF sy-subrc <> 0. ENDIF.

*   Obtener el resumen CEGAL
    CALL METHOD gr_editor_cegal->get_text_as_r3table
*      EXPORTING
*        only_when_modified     = FALSE
      IMPORTING
        table                  = lit_lineas_texto_cegal[]
*       is_modified            =
      EXCEPTIONS
        error_dp               = 1
        error_cntl_call_method = 2
        error_dp_create        = 3
        potential_data_loss    = 4
        OTHERS                 = 5.

    IF sy-subrc <> 0. ENDIF.

*   Miramos si existen diferencias
    CLEAR lf_diferencias_resumen.

    LOOP AT lit_lineas_texto_cegal.
*     Para cada linea de resumen CEGAL

*     Cargamos linea de resumen SAP
      READ TABLE lit_lineas_texto_sap INDEX sy-tabix.

      IF lit_lineas_texto_cegal <> lit_lineas_texto_sap.
*       Si difiere el contenido de la linea, marcamos flag de diferencias y nos salimos
        lf_diferencias_resumen = 'X'.
        EXIT.
      ENDIF.
    ENDLOOP.

    IF lf_diferencias_resumen = 'X'.
*     Si hay diferencias en el resumen, actualizamos resumen en SAP
      git_lineas_texto_final[] = lit_lineas_texto_cegal[].

      IF git_lineas_texto_final[] IS NOT INITIAL.
        PERFORM f_crear_articulos_update_redi CHANGING lf_error.
      ELSE.
        CLEAR git_log_all.
        git_log_all-matnr   = zretlai013_s02-matnr.
        git_log_all-matnrt  = zretlai013_s02-get_titulo.
        git_log_all-status  = gc_minisemaforo_verde.
        git_log_all-paso    = 'P09'.
        git_log_all-pasot   = 'Textos: Resumen'.
        git_log_all-mensaje = 'No aplica - No existe resumen CEGAL'.
        APPEND git_log_all.
      ENDIF.
    ELSE.
      CLEAR git_log_all.
      git_log_all-matnr   = zretlai013_s02-matnr.
      git_log_all-matnrt  = zretlai013_s02-get_titulo.
      git_log_all-status  = gc_minisemaforo_verde.
      git_log_all-paso    = 'P09'.
      git_log_all-pasot   = 'Textos: Resumen'.
      git_log_all-mensaje = 'No aplica - Resumen CEGAL coincide con SAP'.
      APPEND git_log_all.
    ENDIF.
  ENDIF.

*===================================================================================================
* P11->Datos planificación tienda
*===================================================================================================
*  IF lf_error = ''.
*    IF zretlai013_s02-get_dismm_tienda IS NOT INITIAL OR
*       zretlai013_s02-get_sobst_tienda IS NOT INITIAL.
*      PERFORM f_crear_articulos_update_plani CHANGING lf_error.
*    ELSE.
*      CLEAR git_log_all.
*      git_log_all-matnr   = zretlai013_s02-matnr.
*      git_log_all-matnrt  = zretlai013_s02-get_titulo.
*      git_log_all-status  = gc_minisemaforo_ambar.
*      git_log_all-paso    = 'P11'.
*      git_log_all-pasot   = 'Datos planificación tienda'.
*      git_log_all-mensaje = 'No aplica'.
*      APPEND git_log_all.
*    ENDIF.
*  ENDIF.

  CALL SCREEN 0300 STARTING AT 10 10.

  LOOP AT git_log_all WHERE status = gc_minisemaforo_rojo.
    EXIT.
  ENDLOOP.

  IF sy-subrc = 0.
    IF git_log_all-paso <> 'P01'.
      PERFORM f_inicializar_pantalla.
    ENDIF.
  ELSE.
    IF gf_libmod = 'X'.
      UPDATE zretlai013_t03
         SET tratado = 'X'
             tratado_usuario = sy-uname
             tratado_fecha = sy-datum
             tratado_hora = sy-uzeit
       WHERE ean11 = zretlai013_s01-ean11.

      COMMIT WORK AND WAIT.
    ENDIF.

    PERFORM f_inicializar_pantalla.
  ENDIF.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form f_popup_to_confirm
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> TEXT_Q01
*&      <-- LD_RESPUESTA
*&---------------------------------------------------------------------*
FORM f_popup_to_confirm  USING    pe_pregunta
                         CHANGING ps_respuesta.

  CALL FUNCTION 'POPUP_TO_CONFIRM'
    EXPORTING
*     TITLEBAR       = ' '
*     DIAGNOSE_OBJECT             = ' '
      text_question  = pe_pregunta
*     TEXT_BUTTON_1  = 'Ja'(001)
*     ICON_BUTTON_1  = ' '
*     TEXT_BUTTON_2  = 'Nein'(002)
*     ICON_BUTTON_2  = ' '
*     DEFAULT_BUTTON = '1'
*     DISPLAY_CANCEL_BUTTON       = 'X'
*     USERDEFINED_F1_HELP         = ' '
*     START_COLUMN   = 25
*     START_ROW      = 6
*     POPUP_TYPE     =
*     IV_QUICKINFO_BUTTON_1       = ' '
*     IV_QUICKINFO_BUTTON_2       = ' '
    IMPORTING
      answer         = ps_respuesta
*   TABLES
*     PARAMETER      =
    EXCEPTIONS
      text_not_found = 1
      OTHERS         = 2.
  IF sy-subrc <> 0. ENDIF.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form f_9000_povr_encuadernacion
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM f_9000_povr_encuadernacion .
* 0.- Declaración de variables
*======================================================================
  DATA: BEGIN OF lit_encuadernacion OCCURS 0,
          encuadernacion  TYPE char02,
          encuadernaciont TYPE text60,
        END OF lit_encuadernacion.

* 1.- Logica
*======================================================================
*>Determinar valores de encuadernación en función del tipo de producto
  IF zretlai013_s02-get_mtart IS NOT INITIAL.
    IF zretlai013_s02-get_mtart = 'ZLIB'.
*     Si es un libro
      SELECT valor1 AS encuadernacion
             valor2 AS encuadernaciont
        FROM zretlai013_param
        INTO CORRESPONDING FIELDS OF TABLE lit_encuadernacion
       WHERE param = 'ENCUADERNACION_LIBROS'.
    ELSE.
*     Si es un ebook
      SELECT valor1 AS encuadernacion
             valor2 AS encuadernaciont
        FROM zretlai013_param
        INTO CORRESPONDING FIELDS OF TABLE lit_encuadernacion
       WHERE param = 'ENCUADERNACION_ELIBROS'.
    ENDIF.
  ELSE.
*  Si no hay tipo de producto informado, no podemos sacar ayuda de búsqueda
    IF zretlai013_s02-get_tipo_producto IS INITIAL.
      EXIT.
    ENDIF.

    IF zretlai013_s02-get_tipo_producto = '00' OR
       zretlai013_s02-get_tipo_producto = '10' OR
       zretlai013_s02-get_tipo_producto = '60'.
*     Si es un libro
      SELECT valor1 AS encuadernacion
             valor2 AS encuadernaciont
        FROM zretlai013_param
        INTO CORRESPONDING FIELDS OF TABLE lit_encuadernacion
       WHERE param = 'ENCUADERNACION_LIBROS'.
    ELSE.
*     Si es un ebook
      SELECT valor1 AS encuadernacion
             valor2 AS encuadernaciont
        FROM zretlai013_param
        INTO CORRESPONDING FIELDS OF TABLE lit_encuadernacion
       WHERE param = 'ENCUADERNACION_ELIBROS'.
    ENDIF.
  ENDIF.

  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING
      dynpprog        = sy-repid
      dynpnr          = '9000'
      dynprofield     = 'ZRETLAI013_S02-ENCUADERNACION'
      retfield        = 'ENCUADERNACION'
      value_org       = 'S'
    TABLES
      value_tab       = lit_encuadernacion
    EXCEPTIONS
      parameter_error = 1
      no_values_found = 2
      OTHERS          = 3.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form f_get_situaciont
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> ZRETLAI013_S02_SITUACION
*&      <-- ZRETLAI013_S02_SITUACIONT
*&---------------------------------------------------------------------*
FORM f_get_situaciont  USING    pe_situacion
                       CHANGING ps_situaciont.

  SELECT SINGLE mtstb
    FROM t141t
    INTO ps_situaciont
   WHERE spras = sy-langu
     AND mmsta = pe_situacion.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form f_9000_povr_tipo_producto
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM f_9000_povr_tipo_producto .
* 0.- Declaración de variables
*======================================================================
  DATA: BEGIN OF lit_tipo_producto OCCURS 0,
          tipo_producto  TYPE char02,
          tipo_productot TYPE text60,
        END OF lit_tipo_producto.

* 1.- Logica
*======================================================================
*>Determinar valores de tipo producto
  SELECT valor1 AS tipo_producto
         valor2 AS tipo_productot
    FROM zretlai013_param
    INTO CORRESPONDING FIELDS OF TABLE lit_tipo_producto
   WHERE param = 'TIPO_PRODUCTO'.

  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING
      dynpprog        = sy-repid
      dynpnr          = '9000'
      dynprofield     = 'ZRETLAI013_S02-TIPO_PRODUCTO'
      retfield        = 'TIPO_PRODUCTO'
      value_org       = 'S'
    TABLES
      value_tab       = lit_tipo_producto
    EXCEPTIONS
      parameter_error = 1
      no_values_found = 2
      OTHERS          = 3.
ENDFORM.

FORM f_9000_povr_rueck .
* 0.- Declaración de variables
*======================================================================
  DATA: BEGIN OF lit_rueck OCCURS 0,
          rueck  TYPE char02,
          rueckt TYPE text60,
        END OF lit_rueck.

* 1.- Logica
*======================================================================
*>Determinar valores de tipo producto
  SELECT valor1 AS rueck
         valor2 AS rueckt
    FROM zretlai013_param
    INTO CORRESPONDING FIELDS OF TABLE lit_rueck
   WHERE param = 'ACUERDO_DEVOLUCION'.

  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING
      dynpprog        = sy-repid
      dynpnr          = '9000'
      dynprofield     = 'ZRETLAI013_S02-GET_RUECK'
      retfield        = 'RUECK'
      value_org       = 'S'
    TABLES
      value_tab       = lit_rueck
    EXCEPTIONS
      parameter_error = 1
      no_values_found = 2
      OTHERS          = 3.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form f_9000_pai_validar_tipo_prod
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM f_9000_pai_validar_tipo_prod .
  SELECT SINGLE valor1
    FROM zretlai013_param
    INTO zretlai013_s02-get_tipo_producto
   WHERE param = 'TIPO_PRODUCTO'
     AND valor1 = zretlai013_s02-get_tipo_producto.

  IF sy-subrc <> 0.
*   Msg: Tipo producto no válido.
    MESSAGE e006(zretlai013) WITH zretlai013_s02-get_tipo_producto.
  ENDIF.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form f_0200_init_alvs
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM f_0200_init_alvs .
  IF gr_grid_03 IS INITIAL.
    PERFORM f_0200_init_alv_03.
  ELSE.
    PERFORM f_refresh_alv USING gr_grid_03 'X' 'X' 'X'.
  ENDIF.
ENDFORM.

FORM f_pbo_0400_init_alv .
  IF gr_grid_05 IS INITIAL.
    PERFORM f_pbo_0400_init_alv_05.
  ELSE.
    PERFORM f_refresh_alv USING gr_grid_05 'X' 'X' 'X'.
  ENDIF.
ENDFORM.

FORM f_pbo_0700_init_alv .
  IF gr_grid_06 IS INITIAL.
    PERFORM f_pbo_0700_init_alv_06.
  ELSE.
    PERFORM f_refresh_alv USING gr_grid_06 'X' 'X' 'X'.
  ENDIF.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form f_0200_init_alvs
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM f_0300_init_alvs .
  IF gr_grid_04 IS INITIAL.
    PERFORM f_0300_init_alv_04.
  ELSE.
    PERFORM f_refresh_alv USING gr_grid_04 'X' 'X' 'X'.
  ENDIF.
ENDFORM.

FORM f_refresh_alv  USING pe_grid TYPE REF TO cl_gui_alv_grid e_row e_column pe_soft_refresh.

  DATA: ld_lvc    TYPE lvc_s_stbl,
        it_filas  TYPE lvc_t_roid,
        ld_fila   TYPE int4,
        ld_col    TYPE int4,
        lr_filas  TYPE lvc_s_roid,
        lit_filas TYPE lvc_t_roid.

  ld_lvc-row = e_row.
  ld_lvc-col = e_column.

* Refrescar la tabla para actualizar los cambios
  CALL METHOD pe_grid->refresh_table_display
    EXPORTING
      is_stable      = ld_lvc
      i_soft_refresh = pe_soft_refresh
    EXCEPTIONS
      finished       = 1
      OTHERS         = 2.

ENDFORM.                    " f_9000_refresh_alv_1

FORM f_0200_init_alv_03.
* 0.- Declaracion de variables
*--------------------------------------------------------------------*
  DATA: it_filas  TYPE lvc_t_roid,
        ld_fila   TYPE int4,
        lr_filas  TYPE lvc_s_roid,
        lit_filas TYPE lvc_t_roid,
        lit_f4    TYPE lvc_t_f4 WITH HEADER LINE.

* 1.- Logica
*--------------------------------------------------------------------*

* Crear el contenedor en el control de la pantalla
  CREATE OBJECT gr_container_03
    EXPORTING
      container_name = 'CONTAINER_03'.

* Crear el ALV en el container
  CREATE OBJECT gr_grid_03
    EXPORTING
      i_parent = gr_container_03.

* Configurar layout
  PERFORM f_gen_layout_03.

* Configurar fieldcatalog
  PERFORM f_gen_fieldcatalog_03.

* Crear e activar eventos para el ALV
*  CREATE OBJECT gr_event_handler_03.
*  SET HANDLER gr_event_handler_03->handle_hotspot_click_alv_03 FOR gr_grid_03.

* Cargar el alv
  CALL METHOD gr_grid_03->set_table_for_first_display
    EXPORTING
      i_buffer_active = 'X'
      is_layout       = gr_layout_03
*     i_save          = 'A'
*     is_variant      = lr_variant
*     it_toolbar_excluding =
    CHANGING
      it_outtab       = git_log[]
      it_fieldcatalog = git_fieldcatalog_03
*     it_sort         =
    .
ENDFORM.

FORM f_pbo_0400_init_alv_05.
* 0.- Declaracion de variables
*--------------------------------------------------------------------*
  DATA: it_filas   TYPE lvc_t_roid,
        ld_fila    TYPE int4,
        lr_filas   TYPE lvc_s_roid,
        lit_filas  TYPE lvc_t_roid,
        lit_f4     TYPE lvc_t_f4 WITH HEADER LINE,
        lr_variant TYPE disvariant.

* 1.- Logica
*--------------------------------------------------------------------*

* Crear el contenedor en el control de la pantalla
  CREATE OBJECT gr_container_05
    EXPORTING
      container_name = 'CONTAINER_05'.

* Crear el ALV en el container
  CREATE OBJECT gr_grid_05
    EXPORTING
      i_parent = gr_container_05.

* Configurar layout
  PERFORM f_gen_layout_05.

* Configurar fieldcatalog
  PERFORM f_gen_fieldcatalog_05.

* Crear e activar eventos para el ALV
  CREATE OBJECT gr_event_handler_05.
  SET HANDLER gr_event_handler_05->handle_hotspot_click_alv_05 FOR gr_grid_05.

* Cargar el alv
  lr_variant-report = 'ZRETLAI013_LIBMOD'.
  CALL METHOD gr_grid_05->set_table_for_first_display
    EXPORTING
      i_buffer_active = 'X'
      is_layout       = gr_layout_05
      i_save          = 'A'
      is_variant      = lr_variant
*     it_toolbar_excluding =
    CHANGING
      it_outtab       = git_libmod[]
      it_fieldcatalog = git_fieldcatalog_05
*     it_sort         =
    .
ENDFORM.

FORM f_pbo_0700_init_alv_06.
* 0.- Declaracion de variables
*--------------------------------------------------------------------*
  DATA: it_filas   TYPE lvc_t_roid,
        ld_fila    TYPE int4,
        lr_filas   TYPE lvc_s_roid,
        lit_filas  TYPE lvc_t_roid,
        lit_f4     TYPE lvc_t_f4 WITH HEADER LINE,
        lr_variant TYPE disvariant.

* 1.- Logica
*--------------------------------------------------------------------*

* Crear el contenedor en el control de la pantalla
  CREATE OBJECT gr_container_06
    EXPORTING
      container_name = 'CONTAINER_06'.

* Crear el ALV en el container
  CREATE OBJECT gr_grid_06
    EXPORTING
      i_parent = gr_container_06.

* Configurar layout
  PERFORM f_gen_layout_06.

* Configurar fieldcatalog
  PERFORM f_gen_fieldcatalog_06.

* Crear e activar eventos para el ALV
  CREATE OBJECT gr_event_handler_06.
  SET HANDLER gr_event_handler_06->handle_hotspot_click_alv_06 FOR gr_grid_06.

* Cargar el alv
  CALL METHOD gr_grid_06->set_table_for_first_display
    EXPORTING
      i_buffer_active = 'X'
      is_layout       = gr_layout_06
      i_save          = 'A'
*     is_variant      =
*     it_toolbar_excluding =
    CHANGING
      it_outtab       = git_lifnr_sel[]
      it_fieldcatalog = git_fieldcatalog_06
*     it_sort         =
    .
ENDFORM.

FORM f_0300_init_alv_04.
* 0.- Declaracion de variables
*--------------------------------------------------------------------*
  DATA: it_filas  TYPE lvc_t_roid,
        ld_fila   TYPE int4,
        lr_filas  TYPE lvc_s_roid,
        lit_filas TYPE lvc_t_roid,
        lit_f4    TYPE lvc_t_f4 WITH HEADER LINE.

* 1.- Logica
*--------------------------------------------------------------------*

* Crear el contenedor en el control de la pantalla
  CREATE OBJECT gr_container_04
    EXPORTING
      container_name = 'CONTAINER_04'.

* Crear el ALV en el container
  CREATE OBJECT gr_grid_04
    EXPORTING
      i_parent = gr_container_04.

* Configurar layout
  PERFORM f_gen_layout_04.

* Configurar fieldcatalog
  PERFORM f_gen_fieldcatalog_04.

* Crear e activar eventos para el ALV
  CREATE OBJECT gr_event_handler_04.
  SET HANDLER gr_event_handler_04->handle_hotspot_click_alv_04 FOR gr_grid_04.

* Cargar el alv
  CALL METHOD gr_grid_04->set_table_for_first_display
    EXPORTING
      i_buffer_active = 'X'
      is_layout       = gr_layout_04
*     i_save          = 'A'
*     is_variant      = lr_variant
*     it_toolbar_excluding =
    CHANGING
      it_outtab       = git_log_all[]
      it_fieldcatalog = git_fieldcatalog_04
*     it_sort         =
    .
ENDFORM.

FORM f_gen_layout_03 .
  gr_layout_03-no_toolbar = 'X'.
*   gr_layout_01-no_rowmark = 'X'.
*  gr_layout_01-cwidth_opt = 'X'.
*   gr_layout_01-info_fname  = 'ROWCOLOR'.
*  gr_layout_02-sel_mode     = 'A'.
*  gr_layout_01-box_fname = 'SEL'.
*  gr_layout_01-stylefname = 'CELLSTYLES'.
*  gr_layout_03-zebra      = 'X'.
ENDFORM.                    " f_gen_layout_01

FORM f_gen_layout_05 .
*  gr_layout_05-no_toolbar = 'X'.
*   gr_layout_01-no_rowmark = 'X'.
*  gr_layout_01-cwidth_opt = 'X'.
*   gr_layout_01-info_fname  = 'ROWCOLOR'.
*  gr_layout_02-sel_mode     = 'A'.
*  gr_layout_01-box_fname = 'SEL'.
*  gr_layout_01-stylefname = 'CELLSTYLES'.
*  gr_layout_03-zebra      = 'X'.
ENDFORM.                    " f_gen_layout_01

FORM f_gen_layout_06 .
  gr_layout_05-no_toolbar = 'X'.
*   gr_layout_01-no_rowmark = 'X'.
*  gr_layout_01-cwidth_opt = 'X'.
*   gr_layout_01-info_fname  = 'ROWCOLOR'.
*  gr_layout_02-sel_mode     = 'A'.
*  gr_layout_01-box_fname = 'SEL'.
*  gr_layout_01-stylefname = 'CELLSTYLES'.
*  gr_layout_03-zebra      = 'X'.
ENDFORM.                    " f_gen_layout_01




FORM f_gen_layout_04 .
*  gr_layout_04-no_toolbar = 'X'.
*   gr_layout_01-no_rowmark = 'X'.
*  gr_layout_01-cwidth_opt = 'X'.
*   gr_layout_01-info_fname  = 'ROWCOLOR'.
*  gr_layout_02-sel_mode     = 'A'.
*  gr_layout_01-box_fname = 'SEL'.
*  gr_layout_01-stylefname = 'CELLSTYLES'.
*  gr_layout_03-zebra      = 'X'.
ENDFORM.                    " f_gen_layout_01

FORM f_gen_fieldcatalog_03.
* 0.- Declaracion de variables
*--------------------------------------------------------------------*
  DATA: wa_fieldcatalog LIKE LINE OF git_fieldcatalog_03,
        ld_index        LIKE sy-tabix.


* 1.- Logica
*--------------------------------------------------------------------*
  REFRESH git_fieldcatalog_03.
  CALL FUNCTION 'LVC_FIELDCATALOG_MERGE'
    EXPORTING
*     I_BUFFER_ACTIVE        =
      i_structure_name       = 'ZRETLAI013_S03'
*     I_CLIENT_NEVER_DISPLAY = 'X'
*     I_BYPASSING_BUFFER     =
*     I_INTERNAL_TABNAME     =
    CHANGING
      ct_fieldcat            = git_fieldcatalog_03
    EXCEPTIONS
      inconsistent_interface = 1
      program_error          = 2
      OTHERS                 = 3.
  IF sy-subrc <> 0.
  ENDIF.

  LOOP AT git_fieldcatalog_03 INTO wa_fieldcatalog.
    ld_index = sy-tabix.

    CASE wa_fieldcatalog-fieldname.
      WHEN 'TIPO'.
        wa_fieldcatalog-reptext   = 'Tipo Error'.
        wa_fieldcatalog-scrtext_l = 'Tipo'.
        wa_fieldcatalog-scrtext_m = 'Tipo'.
        wa_fieldcatalog-scrtext_s = 'Tipo'.
        wa_fieldcatalog-emphasize = 'C711'.
        wa_fieldcatalog-outputlen = 5.
        wa_fieldcatalog-just      = 'C'.
      WHEN 'MENSAJE'.
        wa_fieldcatalog-reptext   = 'Mensaje'.
        wa_fieldcatalog-scrtext_l = 'Mensaje'.
        wa_fieldcatalog-scrtext_m = 'Mensaje'.
        wa_fieldcatalog-scrtext_s = 'Mensaje'.
        wa_fieldcatalog-emphasize = 'C700'.
        wa_fieldcatalog-outputlen = 132.
      WHEN ''.
        wa_fieldcatalog-reptext   = ''.
        wa_fieldcatalog-scrtext_l = ''.
        wa_fieldcatalog-scrtext_m = ''.
        wa_fieldcatalog-scrtext_s = ''.
        wa_fieldcatalog-outputlen = 25.
    ENDCASE.

    MODIFY git_fieldcatalog_03 FROM wa_fieldcatalog.
  ENDLOOP.
ENDFORM.                    " f_gen_fieldcatalog_01

FORM f_gen_fieldcatalog_05.
* 0.- Declaracion de variables
*--------------------------------------------------------------------*
  DATA: wa_fieldcatalog LIKE LINE OF git_fieldcatalog_05,
        ld_index        LIKE sy-tabix.


* 1.- Logica
*--------------------------------------------------------------------*
  REFRESH git_fieldcatalog_05.
  CALL FUNCTION 'LVC_FIELDCATALOG_MERGE'
    EXPORTING
*     I_BUFFER_ACTIVE        =
      i_structure_name       = 'ZRETLAI013_S04'
*     I_CLIENT_NEVER_DISPLAY = 'X'
*     I_BYPASSING_BUFFER     =
*     I_INTERNAL_TABNAME     =
    CHANGING
      ct_fieldcat            = git_fieldcatalog_05
    EXCEPTIONS
      inconsistent_interface = 1
      program_error          = 2
      OTHERS                 = 3.
  IF sy-subrc <> 0.
  ENDIF.

  LOOP AT git_fieldcatalog_05 INTO wa_fieldcatalog.
    ld_index = sy-tabix.

    CASE wa_fieldcatalog-fieldname.
      WHEN 'FEMOD'.
        wa_fieldcatalog-reptext   = 'Fecha Modificación'.
        wa_fieldcatalog-scrtext_l = 'Fe.Mod.'.
        wa_fieldcatalog-scrtext_m = 'Fe.Mod.'.
        wa_fieldcatalog-scrtext_s = 'Fe.Mod.'.
        wa_fieldcatalog-f4availabl = ''.
        wa_fieldcatalog-emphasize = 'C311'.
        wa_fieldcatalog-outputlen = 10.
      WHEN 'ISBN'.
        wa_fieldcatalog-reptext   = 'ISBN'.
        wa_fieldcatalog-scrtext_l = 'ISBN'.
        wa_fieldcatalog-scrtext_m = 'ISBN'.
        wa_fieldcatalog-scrtext_s = 'ISBN'.
        wa_fieldcatalog-emphasize = 'C700'.
        wa_fieldcatalog-hotspot   = 'X'.
        wa_fieldcatalog-outputlen = 17.
      WHEN 'EAN11'.
        wa_fieldcatalog-reptext   = 'EAN'.
        wa_fieldcatalog-scrtext_l = 'EAN'.
        wa_fieldcatalog-scrtext_m = 'EAN'.
        wa_fieldcatalog-scrtext_s = 'EAN'.
        wa_fieldcatalog-emphasize = 'C700'.
        wa_fieldcatalog-outputlen = 13.
      WHEN 'MATNR'.
        wa_fieldcatalog-reptext   = 'Artículo'.
        wa_fieldcatalog-scrtext_l = 'Artículo'.
        wa_fieldcatalog-scrtext_m = 'Artículo'.
        wa_fieldcatalog-scrtext_s = 'Artículo'.
        wa_fieldcatalog-emphasize = 'C700'.
        wa_fieldcatalog-outputlen = 10.
      WHEN 'MATNRT'.
        wa_fieldcatalog-reptext   = 'Denominación artículo'.
        wa_fieldcatalog-scrtext_l = 'D.Artículo'.
        wa_fieldcatalog-scrtext_m = 'D.Artículo'.
        wa_fieldcatalog-scrtext_s = 'D.Artículo'.
        wa_fieldcatalog-emphasize = 'C700'.
        wa_fieldcatalog-outputlen = 35.
      WHEN 'FICHERO'.
        wa_fieldcatalog-reptext   = 'Fichero'.
        wa_fieldcatalog-scrtext_l = 'Fichero'.
        wa_fieldcatalog-scrtext_m = 'Fichero'.
        wa_fieldcatalog-scrtext_s = 'Fichero'.
        wa_fieldcatalog-emphasize = 'C700'.
        wa_fieldcatalog-outputlen = 40.
      WHEN ''.
        wa_fieldcatalog-reptext   = ''.
        wa_fieldcatalog-scrtext_l = ''.
        wa_fieldcatalog-scrtext_m = ''.
        wa_fieldcatalog-scrtext_s = ''.
        wa_fieldcatalog-outputlen = 25.
    ENDCASE.

    MODIFY git_fieldcatalog_05 FROM wa_fieldcatalog.
  ENDLOOP.
ENDFORM.                    " f_gen_fieldcatalog_01


FORM f_gen_fieldcatalog_06.
* 0.- Declaracion de variables
*--------------------------------------------------------------------*
  DATA: wa_fieldcatalog LIKE LINE OF git_fieldcatalog_06,
        ld_index        LIKE sy-tabix.


* 1.- Logica
*--------------------------------------------------------------------*
  REFRESH git_fieldcatalog_06.
  CALL FUNCTION 'LVC_FIELDCATALOG_MERGE'
    EXPORTING
*     I_BUFFER_ACTIVE        =
      i_structure_name       = 'ZRETLAI013_S05'
*     I_CLIENT_NEVER_DISPLAY = 'X'
*     I_BYPASSING_BUFFER     =
*     I_INTERNAL_TABNAME     =
    CHANGING
      ct_fieldcat            = git_fieldcatalog_06
    EXCEPTIONS
      inconsistent_interface = 1
      program_error          = 2
      OTHERS                 = 3.
  IF sy-subrc <> 0.
  ENDIF.

  LOOP AT git_fieldcatalog_06 INTO wa_fieldcatalog.
    ld_index = sy-tabix.

    CASE wa_fieldcatalog-fieldname.
      WHEN 'LIFNR'.
        wa_fieldcatalog-reptext   = 'Proveedor'.
        wa_fieldcatalog-scrtext_l = 'Proveedor'.
        wa_fieldcatalog-scrtext_m = 'Proveedor'.
        wa_fieldcatalog-scrtext_s = 'Proveedor'.
        wa_fieldcatalog-f4availabl = ''.
        wa_fieldcatalog-emphasize = 'C711'.
        wa_fieldcatalog-hotspot   = 'X'.
        wa_fieldcatalog-outputlen = 12.
      WHEN 'LIFNRT'.
        wa_fieldcatalog-reptext   = 'Nombre Proveedor'.
        wa_fieldcatalog-scrtext_l = 'N.Proveedor'.
        wa_fieldcatalog-scrtext_m = 'N.Proveedor'.
        wa_fieldcatalog-scrtext_s = 'N.Proveedor'.
        wa_fieldcatalog-outputlen = 35.
        wa_fieldcatalog-emphasize = 'C700'.
      WHEN 'LZONE'.
        wa_fieldcatalog-reptext   = 'Zona'.
        wa_fieldcatalog-scrtext_l = 'Zona'.
        wa_fieldcatalog-scrtext_m = 'Zona'.
        wa_fieldcatalog-scrtext_s = 'Zona'.
        wa_fieldcatalog-outputlen = 10.
        wa_fieldcatalog-emphasize = 'C500'.
      WHEN 'LZONET'.
        wa_fieldcatalog-reptext   = 'Denominación Zona'.
        wa_fieldcatalog-scrtext_l = 'D.Zona'.
        wa_fieldcatalog-scrtext_m = 'D.Zona'.
        wa_fieldcatalog-scrtext_s = 'D.Zona'.
        wa_fieldcatalog-outputlen = 25.
        wa_fieldcatalog-emphasize = 'C500'.
      WHEN 'RELIF'.
        IF zretlai013_s01-sap = ''.
          DELETE git_fieldcatalog_06 INDEX ld_index.
          CONTINUE.
        ENDIF.
        wa_fieldcatalog-reptext   = 'Regular'.
        wa_fieldcatalog-scrtext_l = 'Regular'.
        wa_fieldcatalog-scrtext_m = 'Regular'.
        wa_fieldcatalog-scrtext_s = 'Regular'.
        wa_fieldcatalog-outputlen = 8.
        wa_fieldcatalog-checkbox  = 'X'.
        wa_fieldcatalog-emphasize = 'C300'.
    ENDCASE.

    MODIFY git_fieldcatalog_06 FROM wa_fieldcatalog.
  ENDLOOP.
ENDFORM.                    " f_gen_fieldcatalog_01

FORM f_gen_fieldcatalog_04.
* 0.- Declaracion de variables
*--------------------------------------------------------------------*
  DATA: wa_fieldcatalog LIKE LINE OF git_fieldcatalog_04,
        ld_index        LIKE sy-tabix.


* 1.- Logica
*--------------------------------------------------------------------*
  REFRESH git_fieldcatalog_04.
  CALL FUNCTION 'LVC_FIELDCATALOG_MERGE'
    EXPORTING
*     I_BUFFER_ACTIVE        =
      i_structure_name       = 'ZRETLAI001S02'
*     I_CLIENT_NEVER_DISPLAY = 'X'
*     I_BYPASSING_BUFFER     =
*     I_INTERNAL_TABNAME     =
    CHANGING
      ct_fieldcat            = git_fieldcatalog_04
    EXCEPTIONS
      inconsistent_interface = 1
      program_error          = 2
      OTHERS                 = 3.
  IF sy-subrc <> 0.
  ENDIF.

  LOOP AT git_fieldcatalog_04 INTO wa_fieldcatalog.
    ld_index = sy-tabix.

    CASE wa_fieldcatalog-fieldname.
      WHEN 'LINEA'.
        DELETE git_fieldcatalog_04 INDEX ld_index.
        CONTINUE.
        wa_fieldcatalog-reptext   = 'Linea'.
        wa_fieldcatalog-scrtext_l = 'NL'.
        wa_fieldcatalog-scrtext_m = 'NL'.
        wa_fieldcatalog-scrtext_s = 'NL'.
        wa_fieldcatalog-emphasize = 'C700'.
        wa_fieldcatalog-outputlen = 3.
      WHEN 'MATNR'.
        wa_fieldcatalog-reptext   = 'ID Artículo'.
        wa_fieldcatalog-scrtext_l = 'ID'.
        wa_fieldcatalog-scrtext_m = 'ID'.
        wa_fieldcatalog-scrtext_s = 'ID'.
        wa_fieldcatalog-emphasize = 'C700'.
        wa_fieldcatalog-outputlen = 10.
      WHEN 'MATNRT'.
        wa_fieldcatalog-reptext   = 'D.ID Artículo'.
        wa_fieldcatalog-scrtext_l = 'D.ID'.
        wa_fieldcatalog-scrtext_m = 'D.ID'.
        wa_fieldcatalog-scrtext_s = 'D.ID'.
        wa_fieldcatalog-emphasize = 'C700'.
        wa_fieldcatalog-outputlen = 40.
      WHEN 'STATUS'.
        wa_fieldcatalog-reptext   = 'Status Mensaje'.
        wa_fieldcatalog-scrtext_l = 'SM'.
        wa_fieldcatalog-scrtext_m = 'SM'.
        wa_fieldcatalog-scrtext_s = 'SM'.
        wa_fieldcatalog-emphasize = 'C400'.
        wa_fieldcatalog-outputlen = 4.
        wa_fieldcatalog-just      = 'C'.
        wa_fieldcatalog-hotspot   = 'X'.
      WHEN 'PASO'.
        wa_fieldcatalog-reptext   = 'Paso'.
        wa_fieldcatalog-scrtext_l = 'Paso'.
        wa_fieldcatalog-scrtext_m = 'Paso'.
        wa_fieldcatalog-scrtext_s = 'Paso'.
        wa_fieldcatalog-emphasize = 'C400'.
        wa_fieldcatalog-outputlen = 4.
      WHEN 'PASOT'.
        wa_fieldcatalog-reptext   = 'Denominación Paso'.
        wa_fieldcatalog-scrtext_l = 'D.Paso'.
        wa_fieldcatalog-scrtext_m = 'D.Paso'.
        wa_fieldcatalog-scrtext_s = 'D.Paso'.
        wa_fieldcatalog-emphasize = 'C400'.
        wa_fieldcatalog-outputlen = 35.
      WHEN 'LINEAM'.
        wa_fieldcatalog-reptext   = 'Linea'.
        wa_fieldcatalog-scrtext_l = 'Linea'.
        wa_fieldcatalog-scrtext_m = 'Linea'.
        wa_fieldcatalog-scrtext_s = 'Linea'.
        wa_fieldcatalog-emphasize = 'C400'.
        wa_fieldcatalog-outputlen = 5.
      WHEN 'MENSAJE'.
        wa_fieldcatalog-reptext   = 'Mensaje'.
        wa_fieldcatalog-scrtext_l = 'Mensaje'.
        wa_fieldcatalog-scrtext_m = 'Mensaje'.
        wa_fieldcatalog-scrtext_s = 'Mensaje'.
        wa_fieldcatalog-outputlen = 100.
        wa_fieldcatalog-emphasize = 'C400'.
      WHEN 'MM90' OR 'DOCNUM'.
        DELETE git_fieldcatalog_04 INDEX ld_index.
        CONTINUE.
      WHEN ''.
        wa_fieldcatalog-reptext   = ''.
        wa_fieldcatalog-scrtext_l = ''.
        wa_fieldcatalog-scrtext_m = ''.
        wa_fieldcatalog-scrtext_s = ''.
        wa_fieldcatalog-outputlen = 25.
    ENDCASE.

    MODIFY git_fieldcatalog_04 FROM wa_fieldcatalog.
  ENDLOOP.
ENDFORM.                    " f_gen_fieldcatalog_01

*&---------------------------------------------------------------------*
*& Form f_user_command_0200
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM f_user_command_0200 .
  DATA: ld_okcode LIKE sy-ucomm.

  ld_okcode = gd_okcode_0200.

  CLEAR: sy-ucomm,
         gd_okcode_9000.

  CASE ld_okcode.
    WHEN 'ACEPTAR'.
      LEAVE TO SCREEN 0.
  ENDCASE.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form f_validar_datos_pantalla
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM f_validar_datos_pantalla .
*>Validar que se ha informado grupo de compras
  IF zretlai013_s02-get_ekgrp IS INITIAL.
    git_log-tipo = gc_minisemaforo_rojo.
    git_log-mensaje = 'Informar "Gpo.Compras"'.
    APPEND git_log.
  ENDIF.

*>Validar que se haya informado caracteristica planif. necesidades tienda
  IF zretlai013_s02-get_dismm_tienda IS INITIAL.
    git_log-tipo = gc_minisemaforo_rojo.
    git_log-mensaje = 'Informar "Car.planif.nec." tienda'.
    APPEND git_log.
  ENDIF.

*>Validar que se ha informado Título
  IF zretlai013_s02-get_titulo IS INITIAL.
    git_log-tipo = gc_minisemaforo_rojo.
    git_log-mensaje = 'Informar "Título"'.
    APPEND git_log.
  ENDIF.

*>Validar que se ha informado tipo de material
  IF zretlai013_s02-get_mtart IS INITIAL.
    git_log-tipo = gc_minisemaforo_rojo.
    git_log-mensaje = 'Informar "Tipo material"'.
    APPEND git_log.
  ENDIF.

*>Validar que se ha informado grupo de artículos
  IF zretlai013_s02-get_matkl IS INITIAL.
    git_log-tipo = gc_minisemaforo_rojo.
    git_log-mensaje = 'Informar "Gpo.art."'.
    APPEND git_log.
  ENDIF.

*>Validar que se ha informado indicador de impuestos
  IF zretlai013_s02-get_taklv IS INITIAL.
    git_log-tipo = gc_minisemaforo_rojo.
    git_log-mensaje = 'Informar indicador de impuestos'.
    APPEND git_log.
  ENDIF.

*>Validar que se ha informado EAN
  IF zretlai013_s02-get_ean11 IS INITIAL.
    git_log-tipo = gc_minisemaforo_rojo.
    git_log-mensaje = 'Informar "Código EAN"'.
    APPEND git_log.
  ENDIF.

*>Validar cantidad estandar >= cantidad minima
  IF zretlai013_s02-get_norbm IS NOT INITIAL AND
     zretlai013_s02-get_minbm IS NOT INITIAL.
    IF zretlai013_s02-get_norbm < zretlai013_s02-get_minbm.
      git_log-tipo = gc_minisemaforo_rojo.
      git_log-mensaje = '"Ctd.Estandar" tiene que ser igual o superior a "Ctd.mínima"'.
      APPEND git_log.
    ENDIF.
  ENDIF.

*>Validar que si caracteristica planificacion tienda es RP se ha informado stock objetivo y punto de pedido
  IF zretlai013_s02-get_dismm_tienda = 'RP' AND
     ( zretlai013_s02-get_sobst_tienda IS INITIAL OR
       zretlai013_s02-get_minbe_tienda IS INITIAL ).
    git_log-tipo = gc_minisemaforo_rojo.
    git_log-mensaje = '"Car.planif.nec." tienda RP requiere "Stock objetivo" y "Punto pedido"'.
    APPEND git_log.
  ENDIF.

*>Validar que el punto de pedido de la tienda no sea inferior a su stock de seguridad
  IF zretlai013_s02-get_minbe_tienda IS NOT INITIAL AND
     zretlai013_s02-get_eisbe_tienda IS NOT INITIAL.
    IF zretlai013_s02-get_minbe_tienda < zretlai013_s02-get_eisbe_tienda.
      git_log-tipo = gc_minisemaforo_rojo.
      git_log-mensaje = '"Punto pedido(tienda)" no puede ser inferior "Stock seguridad"'.
      APPEND git_log.
    ENDIF.
  ENDIF.

  IF zretlai013_s01-sap = ''.
*  >Validar que se ha informado precio con iva
    IF zretlai013_s02-get_precio_con_iva IS INITIAL.
      git_log-tipo = gc_minisemaforo_rojo.
      git_log-mensaje = 'Informar "Precio (C.IVA)"'.
      APPEND git_log.
    ENDIF.

*  >Validar que se ha especificado validez para el precio con IVA
    IF zretlai013_s02-get_precio_con_iva_datab IS INITIAL OR
       zretlai013_s02-get_precio_con_iva_datbi IS INITIAL.
      git_log-tipo = gc_minisemaforo_rojo.
      git_log-mensaje = 'Informar "Validez" para "Precio (C.IVA)"'.
      APPEND git_log.
    ENDIF.

*  >Validar que ha informado precio sin iva
    IF zretlai013_s02-get_precio_sin_iva IS INITIAL.
      git_log-tipo = gc_minisemaforo_rojo.
      git_log-mensaje = 'Informar "Precio (S.IVA)"'.
      APPEND git_log.
    ENDIF.

*  >Validar que se ha especificado validez para el precio sin IVA
    IF zretlai013_s02-get_precio_sin_iva_datab IS INITIAL OR
       zretlai013_s02-get_precio_sin_iva_datbi IS INITIAL.
      git_log-tipo = gc_minisemaforo_rojo.
      git_log-mensaje = 'Informar "Validez" para "Precio (S.IVA)"'.
      APPEND git_log.
    ENDIF.
  ENDIF.

*>Validar marcado de "catalogar en tienda web"
  IF zretlai013_s01-sap = ''.
*   Si estamos creando articulo
    IF zretlai013_s02-get_catweb_tienda = ''.
*     Si el pincho no se ha marcado
      git_log-tipo = gc_minisemaforo_ambar.
      git_log-mensaje = 'El artículo no se catalogará en tiendas WEB'.
      APPEND git_log.
    ENDIF.
  ENDIF.

*>Validar que se haya determinado editorial
  IF zretlai013_s01-sap = ''.
*   Si estamos creando articulo
    IF zretlai013_s02-get_mfrnr IS INITIAL.
*     Si no se ha determinado editorial
      git_log-tipo = gc_minisemaforo_ambar.
      git_log-mensaje = 'No se ha podido determinar editorial para el EAN del artículo.'.
      APPEND git_log.
    ENDIF.
  ENDIF.

*>Validar que se haya determinado proveedor para la tienda
  IF zretlai013_s01-sap = ''.
*   Si estamos creando articulo
    IF zretlai013_s02-get_lifnr IS INITIAL.
*     Si no se ha determinado proveedor...
      git_log-tipo = gc_minisemaforo_ambar.
      IF zretlai013_s02-get_mfrnr IS INITIAL.
        git_log-mensaje = 'Proveedor no determinado al no haber editorial.'.
      ELSE.
        git_log-mensaje = 'Ningun proveedor valido determinable para la tienda y editorial.'.
      ENDIF.
      APPEND git_log.
    ENDIF.
  ENDIF.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form f_get_numero_articulo
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      <-- ZRETLAI013_S02_MATNR
*&---------------------------------------------------------------------*
FORM f_get_numero_articulo  CHANGING ps_matnr.
* 0.- Declaración de variables
*===================================================================================================
  DATA: ld_nr_range_nr LIKE inri-nrrangenr.

* 1.- Lógica
*===================================================================================================
  SELECT SINGLE valor1
    FROM zretlai001_t01
    INTO ld_nr_range_nr
   WHERE parametro    = 'NR_RANGE_NR'.

  CALL FUNCTION 'NUMBER_GET_NEXT'
    EXPORTING
      nr_range_nr             = ld_nr_range_nr
      object                  = 'MATERIALNR'
*     QUANTITY                = '1'
*     SUBOBJECT               = ' '
*     TOYEAR                  = '0000'
*     IGNORE_BUFFER           = ' '
    IMPORTING
      number                  = ps_matnr
*     QUANTITY                =
*     RETURNCODE              =
    EXCEPTIONS
      interval_not_found      = 1
      number_range_not_intern = 2
      object_not_found        = 3
      quantity_is_0           = 4
      quantity_is_not_1       = 5
      interval_overflow       = 6
      buffer_overflow         = 7
      OTHERS                  = 8.
  IF sy-subrc <> 0.
  ENDIF.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form f_get_parametrizacion
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM f_get_parametrizacion .
* Tienda/almacén modelo
  SELECT SINGLE valor1
    FROM zretlai001_t01
    INTO gd_tienda_modelo
   WHERE parametro = 'TIENDA_MODELO'.

*  SELECT SINGLE valor1
*    FROM zretlai001_t01
*    INTO gd_tienda_modelo_almacen
*   WHERE parametro = 'TIENDA_MODELO_ALMACEN'.

  SELECT SINGLE valor1
    FROM zretlai001_t01
    INTO gd_tienda_modelo_lgfsb
   WHERE parametro = 'TIENDA_MODELO_LGFSB'.

* Obtener areas de venta en las que se tiene que cargar el artículo
  REFRESH git_areas_de_venta.

  SELECT *
    FROM zretlai001_t01
    INTO TABLE git_areas_de_venta
   WHERE parametro = 'AREAS_DE_VENTA'.

* Centro/almacén modelo
  SELECT SINGLE valor1
    FROM zretlai001_t01
    INTO gd_centro_modelo
   WHERE parametro = 'CENTRO_MODELO'.

*  SELECT SINGLE valor1
*    FROM zretlai001_t01
*    INTO gd_centro_modelo_almacen
*   WHERE parametro = 'CENTRO_MODELO_ALMACEN'.

  SELECT SINGLE valor1
    FROM zretlai001_t01
    INTO gd_centro_modelo_lgfsb
   WHERE parametro = 'CENTRO_MODELO_LGFSB'.

* Almacenes modelo
  SELECT *
    FROM zretlai001_t01
    INTO TABLE git_almacenes_modelo_tdmo
   WHERE parametro = 'TIENDA_MODELO_ALMACEN'.

  SELECT *
    FROM zretlai001_t01
    INTO TABLE git_almacenes_modelo_cdmo
   WHERE parametro = 'CENTRO_MODELO_ALMACEN'.

  PERFORM f_get_tienda_usuario using ''
                            CHANGING zretlai013_s02-get_werks_usuario zretlai013_s02-get_werks_usuariot.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form f_get_attypt
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> ZRETLAI013_S02_GET_ATTYP
*&      <-- ZRETLAI013_S02_GET_ATTYPT
*&---------------------------------------------------------------------*
FORM f_get_attypt  USING    pe_attyp
                   CHANGING ps_attypt.

  DATA: ld_domname  LIKE dd07v-domname,
        ld_domvalue LIKE dd07v-domvalue_l,
        ld_ddtext   LIKE dd07v-ddtext.

  ld_domname = 'ATTYP'.
  ld_domvalue = pe_attyp.

  CALL FUNCTION 'DOMAIN_VALUE_GET'
    EXPORTING
      i_domname  = ld_domname
      i_domvalue = ld_domvalue
    IMPORTING
      e_ddtext   = ld_ddtext
    EXCEPTIONS
      not_exist  = 1
      OTHERS     = 2.
  IF sy-subrc <> 0. ENDIF.

  ps_attypt = ld_ddtext.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form f_get_from_param
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> P_
*&      <-- ZRETLAI013_S02_GET_MEINS
*&---------------------------------------------------------------------*
FORM f_get_from_param  USING    pe_param
                       CHANGING ps_valor.

  DATA: ld_valor1 LIKE zretlai013_param-valor1.

  SELECT SINGLE valor1
      FROM zretlai013_param
      INTO ld_valor1
     WHERE param = pe_param.

  ps_valor = ld_valor1.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form f_get_taklvt
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> ZRETLAI013_S02_GET_TAKLV
*&      <-- ZRETLAI013_S02_GET_TAKLVT
*&---------------------------------------------------------------------*
FORM f_get_taklvt  USING    pe_taklv
                   CHANGING ps_taklvt.

  CASE pe_taklv.
    WHEN 0.
      ps_taklvt = 'IVA 0%'.
    WHEN 1.
      ps_taklvt = 'IVA 4%'.
    WHEN 2.
      ps_taklvt = 'IVA 10%'.
    WHEN 3.
      ps_taklvt = 'IVA 21%'.
  ENDCASE.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form f_get_prodht
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> ZRETLAI013_S02_GET_PRODH
*&      <-- ZRETLAI013_S02_GET_PRODHT
*&---------------------------------------------------------------------*
FORM f_get_prodht  USING    pe_prodh
                   CHANGING ps_prodht.

  SELECT SINGLE vtext
    FROM t179t
    INTO ps_prodht
   WHERE spras = sy-langu
     AND prodh = pe_prodh.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form f_9000_pai_validar_prodh
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM f_9000_pai_validar_prodh .
  SELECT SINGLE prodh
    FROM t179
    INTO zretlai013_s02-get_prodh
   WHERE prodh = zretlai013_s02-get_prodh.

  IF sy-subrc <> 0.
*   Msg: Jerarquía de producto & no válida.
    MESSAGE e007(zretlai013) WITH zretlai013_s02-get_prodh.
  ENDIF.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form f_get_tragrt
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> ZRETLAI013_S02_GET_TRAGR
*&      <-- ZRETLAI013_S02_GET_TRAGRT
*&---------------------------------------------------------------------*
FORM f_get_tragrt  USING    pe_tragr
                   CHANGING ps_tragrt.

  SELECT SINGLE vtext
    FROM ttgrt
    INTO ps_tragrt
   WHERE spras = sy-langu
     AND tragr = pe_tragr.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form f_get_mtpos_marat
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> ZRETLAI013_S02_GET_MTPOS_MARA
*&      <-- ZRETLAI013_S02_GET_MTPOS_MARAT
*&---------------------------------------------------------------------*
FORM f_get_mtpos_marat  USING    pe_mtpos_mara
                        CHANGING ps_get_mtpos_marat.

  SELECT SINGLE bezei
    FROM tptmt
    INTO ps_get_mtpos_marat
   WHERE spras = sy-langu
     AND mtpos = pe_mtpos_mara.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form f_get_mtpos_ladgrt
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> ZRETLAI013_S02_GET_LADGR
*&      <-- ZRETLAI013_S02_GET_LADGRT
*&---------------------------------------------------------------------*
FORM f_get_ladgrt  USING  pe_ladgr
                 CHANGING ps_ladgrt.

  SELECT SINGLE vtext
    FROM tlgrt
    INTO ps_ladgrt
   WHERE spras = sy-langu
     AND ladgr = pe_ladgr.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form f_get_mtpos_wbklat
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> ZRETLAI013_S02_GET_WBKLA
*&      <-- ZRETLAI013_S02_GET_WBKLAT
*&---------------------------------------------------------------------*
FORM f_get_wbklat  USING    pe_wbkla
                         CHANGING ps_wbklat.

  SELECT SINGLE bkbez
    FROM t025t
    INTO ps_wbklat
   WHERE spras = sy-langu
     AND bklas = pe_wbkla.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form f_get_dismmt
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> ZRETLAI013_S02_GET_DISMM_TIEND
*&      <-- ZRETLAI013_S02_GET_DISMM_TIEND
*&---------------------------------------------------------------------*
FORM f_get_dismmt  USING    pe_dismm
                   CHANGING ps_dismmt.

  SELECT SINGLE dibez
    FROM t438t
    INTO ps_dismmt
   WHERE spras = sy-langu
     AND dismm = pe_dismm.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form f_get_mtvfpt
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> ZRETLAI013_S02_GET_MTVFP_TIEND
*&      <-- ZRETLAI013_S02_GET_MTVFP_TIEND
*&---------------------------------------------------------------------*
FORM f_get_mtvfpt  USING    pe_mtvfp
                   CHANGING ps_mtvfpt.

  SELECT SINGLE bezei
    FROM tmvft
    INTO ps_mtvfpt
   WHERE spras = sy-langu
     AND mtvfp = pe_mtvfp.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form f_get_perkzt
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> ZRETLAI013_S02_GET_PERKZ_TIEND
*&      <-- ZRETLAI013_S02_GET_PERKZ_TIEND
*&---------------------------------------------------------------------*
FORM f_get_perkzt  USING    pe_perkz
                   CHANGING ps_perkzt.

  DATA: ld_domname  LIKE dd07v-domname,
        ld_domvalue LIKE dd07v-domvalue_l,
        ld_ddtext   LIKE dd07v-ddtext.

  ld_domname = 'PERKZ'.
  ld_domvalue = pe_perkz.

  CALL FUNCTION 'DOMAIN_VALUE_GET'
    EXPORTING
      i_domname  = ld_domname
      i_domvalue = ld_domvalue
    IMPORTING
      e_ddtext   = ld_ddtext
    EXCEPTIONS
      not_exist  = 1
      OTHERS     = 2.
  IF sy-subrc <> 0. ENDIF.

  ps_perkzt = ld_ddtext.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form f_get_dispot
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> ZRETLAI013_S02_GET_DISPO_CENTR
*&      <-- ZRETLAI013_S02_GET_DISPO_CENTR
*&---------------------------------------------------------------------*
FORM f_get_dispot  USING    pe_werks
                            pe_dispo
                   CHANGING ps_dispot.

  SELECT SINGLE dsnam
    FROM t024d
    INTO ps_dispot
   WHERE werks = pe_werks
     AND dispo = pe_dispo.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form f_Get_bwsclt
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> ZRETLAI013_S02_GET_BWSCL_TIEND
*&      <-- ZRETLAI013_S02_GET_BWSCL_TIEND
*&---------------------------------------------------------------------*
FORM f_get_bwsclt  USING    pe_bwscl
                   CHANGING ps_bwsclt.

  SELECT SINGLE bwscb
    FROM tmbwt
    INTO ps_bwsclt
   WHERE spras = sy-langu
     AND bwscl = pe_bwscl.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form f_get_rueckt
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> ZRETLAI013_S02_GET_RUECK
*&      <-- ZRETLAI013_S02_GET_RUECKT
*&---------------------------------------------------------------------*
FORM f_get_rueckt  USING    pe_rueck
                   CHANGING ps_rueckt.

  SELECT SINGLE valor2
    FROM zretlai013_param
    INTO ps_rueckt
   WHERE param = 'ACUERDO_DEVOLUCION'
     AND valor1 = pe_rueck.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form f_9000_pai_validar_rueck
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM f_9000_pai_validar_rueck .
  SELECT SINGLE valor1
    FROM zretlai013_param
    INTO zretlai013_s02-get_rueck
   WHERE valor1 = zretlai013_s02-get_rueck.

  IF sy-subrc <> 0.
*   Msg: Acuerdo devolución & no válido.
    MESSAGE e008(zretlai013) WITH zretlai013_s02-get_rueck.
  ENDIF.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form f_user_command_0300
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM f_user_command_0300 .
  DATA: ld_okcode LIKE sy-ucomm.

  ld_okcode = gd_okcode_0300.

  CLEAR: sy-ucomm,
         gd_okcode_0300.

  CASE ld_okcode.
    WHEN 'ACEPTAR'.
      PERFORM f_free_alv USING gr_grid_04 gr_container_04.
      LEAVE TO SCREEN 0.
  ENDCASE.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form F_FREE_ALV
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> GR_GRID_02
*&---------------------------------------------------------------------*
FORM f_free_alv  USING    pe_grid TYPE REF TO cl_gui_alv_grid
                          pe_container TYPE REF TO cl_gui_custom_container.

  CALL METHOD pe_grid->free
*    exceptions
*      cntl_error        = 1
*      cntl_system_error = 2
*      others            = 3
    .
  IF sy-subrc <> 0.
*   Implement suitable error handling here
  ENDIF.

  FREE pe_grid.

  CALL METHOD pe_container->free
*    exceptions
*      cntl_error        = 1
*      cntl_system_error = 2
*      others            = 3
    .
  IF sy-subrc <> 0.
*   Implement suitable error handling here
  ENDIF.

  FREE pe_container.

ENDFORM.


FORM f_handle_hotspot_click_alv_04 USING    e_row_id    TYPE  lvc_s_row
                                            e_column_id TYPE  lvc_s_col
                                            es_row_no   TYPE  lvc_s_roid.

  DATA: ld_fecha TYPE dats.

  ld_fecha = sy-datum - 90.

  READ TABLE git_log_all INDEX e_row_id-index.

  CASE e_column_id-fieldname.
    WHEN 'STATUS'. "Datos básicos
      IF git_log_all-mm90 IS NOT INITIAL.
        CALL FUNCTION 'APPL_LOG_DISPLAY'
          EXPORTING
            object                    = 'MATU'
*           SUBOBJECT                 = ' '
            external_number           = git_log_all-mm90
*           OBJECT_ATTRIBUTE          = 0
*           SUBOBJECT_ATTRIBUTE       = 0
*           EXTERNAL_NUMBER_ATTRIBUTE = 0
            date_from                 = ld_fecha
*           TIME_FROM                 = '000000'
*           DATE_TO                   = SY-DATUM
*           TIME_TO                   = SY-UZEIT
*           TITLE_SELECTION_SCREEN    = ' '
*           TITLE_LIST_SCREEN         = ' '
*           COLUMN_SELECTION          = '11112221122   '
            suppress_selection_dialog = 'X'
*           COLUMN_SELECTION_MSG_JUMP = '1'
*           EXTERNAL_NUMBER_DISPLAY_LENGTH       = 20
*           I_S_DISPLAY_PROFILE       =
*           I_VARIANT_REPORT          = ' '
*           I_SRT_BY_TIMSTMP          = ' '
*         IMPORTING
*           NUMBER_OF_PROTOCOLS       =
*         EXCEPTIONS
*           NO_AUTHORITY              = 1
*           OTHERS                    = 2
          .
        IF sy-subrc <> 0. ENDIF.
      ENDIF.
  ENDCASE.
ENDFORM.

FORM f_handle_hotspot_click_alv_05 USING    e_row_id    TYPE  lvc_s_row
                                            e_column_id TYPE  lvc_s_col
                                            es_row_no   TYPE  lvc_s_roid.

  READ TABLE git_libmod INDEX e_row_id-index.

  CASE e_column_id-fieldname.
    WHEN 'ISBN'.
      gf_libmod = 'X'.
      zretlai013_s01-ean11 = git_libmod-isbn.

      CALL METHOD cl_gui_cfw=>set_new_ok_code
        EXPORTING
          new_code = 'CANCELAR'.
  ENDCASE.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form f_9000_pai_validar_volumen
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM f_9000_pai_validar_volumen .
  IF zretlai013_s02-get_volum IS NOT INITIAL AND
     zretlai013_s02-get_voleh IS INITIAL.
*   Msg: Especificar unidad de volumen.
    MESSAGE e010(zretlai013).
  ENDIF.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form f_9000_pai_validar_situacion
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM f_9000_pai_validar_situacion .
  IF zretlai013_s02-get_situacion IS NOT INITIAL AND
     zretlai013_s02-get_situacion_datab IS INITIAL.
*   Msg: Especificar validez para la situación.
    MESSAGE e012(zretlai013).
  ENDIF.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form f_9000_pai_validar_siva_val
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM f_9000_pai_validar_siva_val .
  IF zretlai013_s02-get_precio_sin_iva_datab IS NOT INITIAL AND
     zretlai013_s02-get_precio_sin_iva_datbi IS NOT INITIAL.
    IF zretlai013_s02-get_precio_sin_iva_datab > zretlai013_s02-get_precio_sin_iva_datbi.
*     Msg: Rango de validez no válido.
      MESSAGE e009(zretlai013).
    ENDIF.
  ENDIF.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form f_9000_pai_validar_siva_val
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM f_9000_pai_validar_civa_val .
  IF zretlai013_s02-get_precio_con_iva_datab IS NOT INITIAL AND
     zretlai013_s02-get_precio_con_iva_datbi IS NOT INITIAL.
    IF zretlai013_s02-get_precio_con_iva_datab > zretlai013_s02-get_precio_con_iva_datbi.
*     Msg: Rango de validez no válido.
      MESSAGE e009(zretlai013).
    ENDIF.
  ENDIF.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form f_cargar_datos_articulo_sap
*&---------------------------------------------------------------------*
*& Obtiene los datos del articulo actualmente en SAP
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM f_cargar_datos_articulo_sap .
* 0.- Declaración de variables
*===================================================================================================
  DATA: lit_lines         LIKE tline OCCURS 0 WITH HEADER LINE,
        ld_id             LIKE thead-tdid,
        ld_language       LIKE thead-tdspras,
        ld_name           LIKE thead-tdname,
        ld_object         LIKE thead-tdobject,
        ld_vkorg          TYPE vkorg,
        ld_vtweg          TYPE vtweg,
        wa_zretlai013_t03 LIKE zretlai013_t03,
        ld_fecha(10),
        ld_hora(8).

* 1.- Lógica
*===================================================================================================
* Tienda del usuario
  PERFORM f_get_tienda_usuario using ''
                            CHANGING zretlai013_s02-get_werks_usuario zretlai013_s02-get_werks_usuariot.

* Datos básicos del artículo
  SELECT SINGLE attyp
                meins
                prdha
                bismt
                tragr
                mtpos_mara
                ean11
                ntgew
                gewei
                brgew
                gewei
                volum
                voleh
                zz1_autor_prd
                zz1_idiomaoriginal2_prd
                zz1_traductor_prd
                zz1_ilustrador_prd
                zz1_urlportada_prd
                zz1_coleccion_prd
                zz1_cdu_prd
                zz1_ibic_prd
                zz1_idioma2_prd
                zz1_numeroedicion_prd
                zz1_subttulo_prd
                zz1_formato_prd
                zz1_fechaedicin_prd
                zz1_npginas_prd
                zz1_etiquetas_prd
                zz1_tejueloalad_prd
                zz1_novedad2_prd
                mtart
                matkl
                mfrnr
                zz1_desceditorial_prd
                mstav
                mstde
                taklv
                hoehe
                meabm
    FROM mara
    INTO (zretlai013_s02-get_attyp,
          zretlai013_s02-get_meins,
          zretlai013_s02-get_prodh,
          zretlai013_s02-get_bismt,
          zretlai013_s02-get_tragr,
          zretlai013_s02-get_mtpos_mara,
          zretlai013_s02-get_ean11,
          zretlai013_s02-get_peso,
          zretlai013_s02-get_peso_meins,
          zretlai013_s02-get_brgew,
          zretlai013_s02-get_meabm,
          zretlai013_s02-get_volum,
          zretlai013_s02-get_voleh,
          zretlai013_s02-get_nombre_autor,
          zretlai013_s02-get_idioma_original,
          zretlai013_s02-get_traductor,
          zretlai013_s02-get_ilustrador_cubierta,
          zretlai013_s02-get_url,
          zretlai013_s02-get_coleccion,
          zretlai013_s02-get_cdu,
          zretlai013_s02-get_ibic,
          zretlai013_s02-get_lengua_publicacion,
          zretlai013_s02-get_numero_edicion,
          zretlai013_s02-get_subtitulo,
          zretlai013_s02-get_encuadernaciont,                                                       "APRADAS-28.10.2021
          zretlai013_s02-get_fecha_publicacion,
          zretlai013_s02-get_numero_paginas,
          zretlai013_s02-get_zz1_etiquetas_prd,
          zretlai013_s02-get_zz1_tejueloalad_prd,
          zretlai013_s02-get_zz1_novedad2_prd,
          zretlai013_s02-get_mtart,
          zretlai013_s02-get_matkl,
          zretlai013_s02-get_mfrnr,
          zretlai013_s02-get_mfrnrt,
          zretlai013_s02-get_situacion,
          zretlai013_s02-get_situacion_datab,
          zretlai013_s02-get_taklv,
          zretlai013_s02-get_grosor_mm,
          zretlai013_s02-get_grosor_mm_meins)
   WHERE matnr = zretlai013_s02-matnr.



*>APRADAS-28.10.2021 09:41:31-Inicio
* Obtener el código de encuadernación geslib
  SELECT SINGLE valor1
    FROM zretlai013_param
    INTO zretlai013_s02-get_encuadernacion
   WHERE ( param = 'ENCUADERNACION_LIBROS' OR
           param = 'ENCUADERNACION_ELIBROS' )
     AND valor2 = zretlai013_s02-get_encuadernaciont.
*<APRADAS-28.10.2021 09:41:31-Fin

  SELECT SINGLE maktx
    FROM makt
    INTO zretlai013_s02-get_titulo
   WHERE spras = sy-langu
     AND matnr = zretlai013_s02-matnr.

***  if ZRETLAI013_S02-get_situacion <> ZRETLAI013_S02-get_situacion_cegal.
***    ZRETLAI013_S02-GET_SITUACION_DATAB = sy-datum.
***  endif.

  CASE zretlai013_s02-get_taklv.
    WHEN 0.
      zretlai013_s02-get_iva = 0.
      zretlai013_s02-get_iva_waers = '%'.
    WHEN 1.
      zretlai013_s02-get_iva = 4.
      zretlai013_s02-get_iva_waers = '%'.
    WHEN 2.
      zretlai013_s02-get_iva = 10.
      zretlai013_s02-get_iva_waers = '%'.
    WHEN 3.
      zretlai013_s02-get_iva = 21.
      zretlai013_s02-get_iva_waers = '%'.
  ENDCASE.

*>Determinamos editorial asociada al EAN
  PERFORM f_get_editorial    USING zretlai013_s02-get_ean11
                          CHANGING zretlai013_s02-get_mfrnr_new
                                   zretlai013_s02-get_mfrnr_newt.

  IF zretlai013_s02-get_mfrnr_new <> zretlai013_s02-get_mfrnr.
*   Si editorial difiere

*   Preguntamos al usuario si quiere mantener la editorial actual o cambiar a la nueva editorial
    CLEAR gf_cambiar_editorial.

    CALL SCREEN 0600 STARTING AT 10 10.

    IF gf_cambiar_editorial = 'X'.

*     Activamos flag
      gf_nueva_editorial = 'X'.

*     Determinamos los proveedores asociados a la editorial y el proveedor asociado a la tienda
      PERFORM f_get_prov_from_editorial USING    zretlai013_s02-get_mfrnr_new
                                                 zretlai013_s02-get_werks_usuario
                                        CHANGING zretlai013_s02-get_lifnr
                                                 zretlai013_s02-get_lifnrt.
    ELSE.
*     Desactivamos flag
      gf_nueva_editorial = ''.

*     Inicializamos info de nueva editorial
      CLEAR:  zretlai013_s02-get_mfrnr_new,
              zretlai013_s02-get_mfrnr_newt.

*     Determinamos los proveedores asociados a la editorial y el proveedor asociado a la tienda
      PERFORM f_get_prov_from_editorial USING    zretlai013_s02-get_mfrnr
                                                 zretlai013_s02-get_werks_usuario
                                        CHANGING zretlai013_s02-get_lifnr
                                                 zretlai013_s02-get_lifnrt.
    ENDIF.
  ELSE.
*   Si editorial coincide

*   Desactivamos flag
    gf_nueva_editorial = ''.

*   Inicializamos info de nueva editorial
    CLEAR:  zretlai013_s02-get_mfrnr_new,
            zretlai013_s02-get_mfrnr_newt.

*   Determinamos los proveedores asociados a la editorial y el proveedor asociado a la tienda
    PERFORM f_get_prov_from_editorial USING    zretlai013_s02-get_mfrnr
                                               zretlai013_s02-get_werks_usuario
                                      CHANGING zretlai013_s02-get_lifnr
                                               zretlai013_s02-get_lifnrt.
  ENDIF.

*>Datos proveedor
  SELECT SINGLE eina~rueck
                eina~idnlf
                eine~norbm
                eine~minbm
                eine~aplfz
    FROM eina JOIN eine ON eina~infnr = eine~infnr  AND eine~esokz = '0' AND eine~werks = ''
    INTO (zretlai013_s02-get_rueck,
          zretlai013_s02-get_idnlf,
          zretlai013_s02-get_norbm,
          zretlai013_s02-get_minbm,
          zretlai013_s02-get_plifz)
   WHERE eina~matnr = zretlai013_s02-matnr
     AND eina~lifnr = zretlai013_s02-get_lifnr.

  PERFORM f_get_from_param USING 'EKORG_DEFECTO'
                          CHANGING zretlai013_s02-get_ekorg.

  PERFORM f_get_from_param USING 'EKGRP_DEFECTO'
                          CHANGING zretlai013_s02-get_ekgrp.

  SELECT SINGLE wbkla
                wladg
*                wherl
*                wherr
    FROM maw1
    INTO (zretlai013_s02-get_wbkla,
          zretlai013_s02-get_ladgr)
*          zretlai013_s02-get_wherl,
*          zretlai013_s02-get_wherr)
   WHERE matnr = zretlai013_s02-matnr.

  SELECT SINGLE stawn
    FROM marc
    INTO zretlai013_s02-get_wstaw
   WHERE matnr = zretlai013_s02-matnr
     AND stawn <> ''.

  PERFORM f_get_attypt    USING zretlai013_s02-get_attyp
                       CHANGING zretlai013_s02-get_attypt.

  PERFORM f_get_prodht    USING zretlai013_s02-get_prodh
                       CHANGING zretlai013_s02-get_prodht.

  PERFORM f_get_tragrt    USING zretlai013_s02-get_tragr
                       CHANGING zretlai013_s02-get_tragrt.

  PERFORM f_get_ladgrt    USING zretlai013_s02-get_ladgr
                       CHANGING zretlai013_s02-get_ladgrt.

  PERFORM f_get_wbklat    USING zretlai013_s02-get_wbkla
                       CHANGING zretlai013_s02-get_wbklat.

  PERFORM f_get_mtpos_marat USING zretlai013_s02-get_mtpos_mara
                         CHANGING zretlai013_s02-get_mtpos_marat.


  SELECT SINGLE dismm
                mtvfp
                minbe
                plifz
                bwscl
                dispo
                eisbe
    FROM marc
    INTO (zretlai013_s02-get_dismm_tienda,
          zretlai013_s02-get_mtvfp_tienda,
          zretlai013_s02-get_minbe_tienda,
          zretlai013_s02-get_plifz_tienda,
          zretlai013_s02-get_bwscl_tienda,
          zretlai013_s02-get_dispo_tienda,
          zretlai013_s02-get_eisbe_tienda)
   WHERE werks = gd_tienda_modelo
     AND matnr = zretlai013_s02-matnr.

  SELECT SINGLE sobst
    FROM wrpl
    INTO zretlai013_s02-get_sobst_tienda
   WHERE kunnr = gd_tienda_modelo
     AND matnr = zretlai013_s02-matnr.





  IF zretlai013_s02-get_prodh IS NOT INITIAL.
    PERFORM f_get_prodht USING zretlai013_s02-get_prodh CHANGING zretlai013_s02-get_prodht.
  ENDIF.

  IF zretlai013_s02-get_lifnr IS NOT INITIAL.
    PERFORM f_get_lifnrt USING zretlai013_s02-get_lifnr CHANGING zretlai013_s02-get_lifnrt.
  ENDIF.

  IF zretlai013_s02-get_ekgrp IS NOT INITIAL.
    PERFORM f_get_ekgrpt USING zretlai013_s02-get_ekgrp CHANGING zretlai013_s02-get_ekgrpt.
  ENDIF.

  IF zretlai013_s02-get_ekorg IS NOT INITIAL.
    PERFORM f_get_ekorgt USING zretlai013_s02-get_ekorg CHANGING zretlai013_s02-get_ekorgt.
  ENDIF.

* Resumen artículo en SAP
  ld_object     = 'MATERIAL'.
  ld_name       = zretlai013_s02-matnr.
  ld_id	        = 'GRUN'.
  ld_language	  = 'S'.

  CALL FUNCTION 'READ_TEXT'
    EXPORTING
*     CLIENT                  = SY-MANDT
      id                      = ld_id
      language                = ld_language
      name                    = ld_name
      object                  = ld_object
*     ARCHIVE_HANDLE          = 0
*     LOCAL_CAT               = ' '
*   IMPORTING
*     HEADER                  =
*     OLD_LINE_COUNTER        =
    TABLES
      lines                   = lit_lines
    EXCEPTIONS
      id                      = 1
      language                = 2
      name                    = 3
      not_found               = 4
      object                  = 5
      reference_check         = 6
      wrong_access_to_archive = 7
      OTHERS                  = 8.

  IF sy-subrc <> 0. ENDIF.

  LOOP AT lit_lines.
    git_resumen_sap-tdline = lit_lines-tdline.
    APPEND git_resumen_sap.
  ENDLOOP.

  SELECT SINGLE vkorg
                vtweg
    FROM t001w
    INTO (ld_vkorg,
          ld_vtweg)
   WHERE werks = zretlai013_s02-get_werks_usuario.

  SELECT SINGLE a073~datab
                a073~datbi
                konp~kbetr
                konp~konwa
    INTO (zretlai013_s02-get_precio_con_iva_datab,
          zretlai013_s02-get_precio_con_iva_datbi,
          zretlai013_s02-get_precio_con_iva,
          zretlai013_s02-get_precio_con_iva_waers)
    FROM a073 JOIN konp ON konp~knumh = a073~knumh
   WHERE a073~kappl = 'V'
     AND a073~kschl = 'VKP0'
     AND a073~vkorg = '1000'
     AND a073~vtweg = '20'
     AND a073~matnr = zretlai013_s02-matnr
     AND a073~vrkme = 'ST'
     AND a073~datbi >= sy-datum
     AND a073~datab <= sy-datum.

  IF zretlai013_s02-get_precio_con_iva <> zretlai013_s02-get_precio_con_iva_cegal.
    zretlai013_s02-get_precio_con_iva_datab = sy-datum.
  ENDIF.

  SELECT SINGLE a073~datab
                a073~datbi
                konp~kbetr
                konp~konwa
    INTO (zretlai013_s02-get_precio_sin_iva_datab,
          zretlai013_s02-get_precio_sin_iva_datbi,
          zretlai013_s02-get_precio_sin_iva,
          zretlai013_s02-get_precio_sin_iva_waers)
    FROM a073 JOIN konp ON konp~knumh = a073~knumh
   WHERE a073~kappl = 'V'
     AND a073~kschl = 'VKP1'
     AND a073~vkorg = '1000'
     AND a073~vtweg = '20'
     AND a073~matnr = zretlai013_s02-matnr
     AND a073~vrkme = 'ST'
     AND a073~datbi >= sy-datum
     AND a073~datab <= sy-datum.

  IF zretlai013_s02-get_precio_sin_iva <> zretlai013_s02-get_precio_sin_iva_cegal.
    zretlai013_s02-get_precio_sin_iva_datab = sy-datum.
  ENDIF.

* Informacion LIBMOD
  IF gf_libmod = 'X'.
*   Si se ha accedido al articulo desde el popup de modificaciones pendiente, sacamos aviso de
*   LIBMOD pendiente de tratar
    CONCATENATE gc_minisemaforo_ambar
                      'Se ha recibido modificación LIBMOD pendiente de tratar.'
                 INTO zretlai013_s02-get_info_libmod
                 SEPARATED BY space.
  ELSE.
    IF zretlai013_s01-sap = 'X'.
*     Si el artículo existe en SAP, miramos si tiene modificación LIBMOD
      SELECT SINGLE *
        FROM zretlai013_t03
        INTO wa_zretlai013_t03
       WHERE ean11 = zretlai013_s01-ean11.

      IF sy-subrc = 0.
        IF wa_zretlai013_t03-tratado = 'X'.
          WRITE wa_zretlai013_t03-tratado_fecha TO ld_fecha.
          WRITE wa_zretlai013_t03-tratado_hora TO ld_hora.

          CONCATENATE gc_minisemaforo_verde
                      'Última modificación LIBMOD tratada por'
                      wa_zretlai013_t03-tratado_usuario
                      'el dia'
                      ld_fecha
                      'a las'
                      ld_hora
                      'horas.'
                 INTO zretlai013_s02-get_info_libmod
                 SEPARATED BY space.
        ELSE.
          gf_libmod = 'X'.
          CONCATENATE gc_minisemaforo_ambar
                      'Se ha recibido modificación LIBMOD pendiente de tratar.'
                 INTO zretlai013_s02-get_info_libmod
                 SEPARATED BY space.
        ENDIF.
      ENDIF.
    ENDIF.
  ENDIF.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form f_get_ekgrpt
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> ZRETLAI013_S02_GET_EKGRP
*&      <-- ZRETLAI013_S02_GET_EKGRPT
*&---------------------------------------------------------------------*
FORM f_get_ekgrpt  USING    pe_ekgrp
                   CHANGING ps_ekgrpt.

  SELECT SINGLE eknam
    FROM t024
    INTO ps_ekgrpt
   WHERE ekgrp = pe_ekgrp.
ENDFORM.

*===================================================================================================
*& Form f_get_tienda_usuario
*===================================================================================================
FORM f_get_tienda_usuario  using    pe_modificar
                           CHANGING ps_werks
                                    ps_werkst.

* 0.- Declaración de variables
*===================================================================================================
  data: wa_ZRETLAI013_T04 like ZRETLAI013_T04.

* 1.- Lógica
*===================================================================================================
*>Inicializamos campos del popup
  clear: gd_werks,
         gd_werkst.

*>Obtenemos tienda asignada actual para el usuario
  select single werks
    from ZRETLAI013_T04
    into gd_werks
   where uname = sy-uname.

  if gd_werks is not initial.
    perform f_get_werkst using gd_werks
                      CHANGING gd_werkst.
  endif.

  if pe_modificar = '' and gd_werks is not initial.
*   Si no estamos modificando la tienda y el usuario tiene tienda asignada, tomamos esa tienda y nos
*   salimos
    ps_werks = gd_werks.
    ps_werkst = gd_werkst.

    exit.
  endif.

*>Mostramos popup de tienda asignada al usuario
  call SCREEN 0800 STARTING AT 10 10.

  if gd_werks is not initial.
*   Si hay tienda informada...

*   Obtenemos denominación
    perform f_get_werkst using gd_werks CHANGING gd_werkst.

*   Miramos si esa tienda es la que tenia asignada el usuario
    select single *
      from ZRETLAI013_T04
      into wa_ZRETLAI013_T04
     where uname = sy-uname
       and werks = gd_werks.

    if sy-subrc <> 0.
*     Si no es la que tenia, la asignamos al usuario
      wa_ZRETLAI013_T04-uname = sy-uname.
      wa_ZRETLAI013_T04-werks = gd_werks.

      MODIFY ZRETLAI013_T04 from wa_ZRETLAI013_T04.
    endif.

*   Tomamos la tienda informada en el popup
    ps_werks = gd_werks.
    ps_werkst = gd_werkst.
  else.
*   Si no hay tienda informada...

*   Miramos si el usuario tenia tienda asignada
    select single *
      from ZRETLAI013_T04
      into wa_ZRETLAI013_T04
     where uname = sy-uname.

    if sy-subrc = 0.
*     Si la tenia, tomamos esa tienda
      ps_werks = wa_ZRETLAI013_T04-werks.
      perform f_get_werkst using ps_werks CHANGING ps_werkst.
    else.
*     Si no tenia tienda asignada, error

*     MsgA: Su usuario no está asignado a ninguna tienda. No es posible continuar.
      message a016(ZRETLAI013).
    endif.
  endif.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form f_get_werkst
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> PS_WERKS
*&      <-- PS_WERKST
*&---------------------------------------------------------------------*
FORM f_get_werkst  USING    pe_werks
                   CHANGING ps_werkst.

  SELECT SINGLE name1
    FROM t001w
    INTO ps_werkst
   WHERE werks = pe_werks.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form f_get_werks_zona
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> PE_WERKS
*&      <-- LD_ZONE1
*&---------------------------------------------------------------------*
FORM f_get_werks_zona  USING    pe_werks
                       CHANGING ps_land1
                                ps_land1t
                                ps_lzone
                                ps_lzonet.

  CLEAR: ps_land1,
         ps_land1t,
         ps_lzone,
         ps_lzonet.

  SELECT SINGLE land1
                zone1
    FROM t001w
    INTO (ps_land1,
          ps_lzone)
   WHERE werks = pe_werks.

  SELECT SINGLE landx
    FROM t005t
    INTO ps_land1t
   WHERE spras = sy-langu
     AND land1 = ps_land1.

  SELECT SINGLE vtext
    FROM tzont
    INTO ps_lzonet
   WHERE land1 = ps_land1
     AND zone1 = ps_lzone.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form f_crear_articulos_update_tdxx
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      <-- LF_ERROR
*&---------------------------------------------------------------------*
FORM f_crear_articulos_update_tdxx  CHANGING ps_error.
* 0.- Declaración de variables
*===================================================================================================
  DATA: lr_headdata    LIKE  bapie1mathead,
        lr_return      LIKE bapireturn1,
        lit_plantdata  LIKE bapie1marcrt       OCCURS 0 WITH HEADER LINE,
        lit_plantdatax LIKE bapie1marcrtx      OCCURS 0 WITH HEADER LINE.

* 1.- Lógica
*===================================================================================================
  CLEAR: ps_error.

*>Cabecera
  lr_headdata-function = '005'.
  lr_headdata-material = zretlai013_s02-matnr.
  lr_headdata-logst_view = 'X'.

*>Datos tienda usuario
  lit_plantdata-function    = '009'.
  lit_plantdata-material    = zretlai013_s02-matnr.                                                 "Artículo
  lit_plantdata-plant       = zretlai013_s02-get_werks_usuario.                                     "Tienda usuario
* lit_plantdata-MRPPROFILE  = git_monitor-tdmo_dispr.                                               "Material: Perfil de planificación de necesidades
* lit_plantdata-replentime  = git_monitor-tdmo_wzeit.                                               "Tiempo global de reaprovisionamiento (días laborables)
  lit_plantdata-mrp_type    = zretlai013_s02-get_dismm_tienda.                                      "Característica de planificación de necesidades
  lit_plantdata-availcheck  = zretlai013_s02-get_mtvfp_tienda.                                      "Grupo de verificación p.verificación de disponibilidad
  lit_plantdata-auto_p_ord  = 'X'.                                                                  "Indicador: pedido automático permitido
  lit_plantdata-period_ind  = zretlai013_s02-get_perkz_tienda.                                      "Indicador de período
  lit_plantdata-mrp_ctrler  = zretlai013_s02-get_dispo_tienda.                                      "Planificador de necesidades temporal
* lit_plantdata-lotsizekey  = git_monitor-tdmo_disls.                                               "Tamaño de lote de planificación de necesidades
  lit_plantdata-reorder_pt  = zretlai013_s02-get_minbe_tienda.                                      "Punto de pedido
  lit_plantdata-plnd_delry  = zretlai013_s02-get_plifz_tienda.                                      "Plazo de entrega previsto
  lit_plantdata-sup_source  = zretlai013_s02-get_bwscl_tienda.                                      "Fuente de aprovisionamiento
  lit_plantdata-sloc_exprc  = gd_tienda_modelo_lgfsb.                                               "Almacén propuesto para aprovisionamiento externo
  lit_plantdata-pur_group   = zretlai013_s02-get_ekgrp.                                             "Grupo de compras
  lit_plantdata-neg_stocks  = 'X'.                                                                  "Permitir Stocks negativos
*  lit_plantdata-proc_type   = 'F'.                                                                 "Clase de aprovisionamiento
* lit_plantdata-round_prof  = git_monitor-tdmo_rdprf.                                               "Perfil redondeo tienda
  lit_plantdata-safety_stk  = zretlai013_s02-get_eisbe_tienda.                                      "Stock de seguridad

  lit_plantdatax-function   = '009'.
  lit_plantdatax-material   = zretlai013_s02-matnr.
  lit_plantdatax-plant      = zretlai013_s02-get_werks_usuario.
* lit_plantdatax-MRPPROFILE = 'X'.
* lit_plantdatax-replentime = 'X'.
  lit_plantdatax-mrp_type   = 'X'.
  lit_plantdatax-availcheck = 'X'.
  lit_plantdatax-auto_p_ord = 'X'.
  lit_plantdatax-period_ind = 'X'.
  lit_plantdatax-mrp_ctrler = 'X'.
* lit_plantdatax-lotsizekey = 'X'.
  lit_plantdatax-reorder_pt = 'X'.
  lit_plantdatax-plnd_delry = 'X'.
  lit_plantdatax-sup_source = 'X'.
  lit_plantdatax-sloc_exprc = 'X'.
  lit_plantdatax-pur_group  = 'X'.
  lit_plantdatax-neg_stocks = 'X'.
*  lit_plantdatax-proc_type  = 'X'.
* lit_plantdatax-round_prof = 'X'.
  lit_plantdatax-safety_stk = 'X'.

  APPEND: lit_plantdata, lit_plantdatax.

  CALL FUNCTION 'BAPI_MATERIAL_MAINTAINDATA_RT'
    EXPORTING
      headdata   = lr_headdata
    IMPORTING
      return     = lr_return
    TABLES
*     VARIANTSKEYS                 =
*     CHARACTERISTICVALUE          =
*     CHARACTERISTICVALUEX         =
*     CLIENTDATA =
*     CLIENTDATAX                  =
*     CLIENTEXT  =
*     CLIENTEXTX =
*     ADDNLCLIENTDATA              =
*     ADDNLCLIENTDATAX             =
*     MATERIALDESCRIPTION          =
      plantdata  = lit_plantdata
      plantdatax = lit_plantdatax
*     PLANTEXT   =
*     PLANTEXTX  =
*     FORECASTPARAMETERS           =
*     FORECASTPARAMETERSX          =
*     FORECASTVALUES               =
*     TOTALCONSUMPTION             =
*     UNPLNDCONSUMPTION            =
*     PLANNINGDATA                 =
*     PLANNINGDATAX                =
*     STORAGELOCATIONDATA          =
*     STORAGELOCATIONDATAX         =
*     STORAGELOCATIONEXT           =
*     STORAGELOCATIONEXTX          =
*     UNITSOFMEASURE               =
*     UNITSOFMEASUREX              =
*     UNITOFMEASURETEXTS           =
*     INTERNATIONALARTNOS          =
*     VENDOREAN  =
*     LAYOUTMODULEASSGMT           =
*     LAYOUTMODULEASSGMTX          =
*     TAXCLASSIFICATIONS           =
*     VALUATIONDATA                =
*     VALUATIONDATAX               =
*     VALUATIONEXT                 =
*     VALUATIONEXTX                =
*     WAREHOUSENUMBERDATA          =
*     WAREHOUSENUMBERDATAX         =
*     WAREHOUSENUMBEREXT           =
*     WAREHOUSENUMBEREXTX          =
*     STORAGETYPEDATA              =
*     STORAGETYPEDATAX             =
*     STORAGETYPEEXT               =
*     STORAGETYPEEXTX              =
*     SALESDATA  =
*     SALESDATAX =
*     SALESEXT   =
*     SALESEXTX  =
*     POSDATA    =
*     POSDATAX   =
*     POSEXT     =
*     POSEXTX    =
*     MATERIALLONGTEXT             =
*     PLANTKEYS  =
*     STORAGELOCATIONKEYS          =
*     DISTRCHAINKEYS               =
*     WAREHOUSENOKEYS              =
*     STORAGETYPEKEYS              =
*     VALUATIONTYPEKEYS            =
*     TEXTILECOMPONENTS            =
*     FIBERCODES =
*     SEGSALESSTATUS               =
*     SEGWEIGHTVOLUME              =
*     SEGVALUATIONTYPE             =
*     SEASONS    =
*     SEGWAREHOUSENUMBERDATA       =
*     SEGSTORAGETYPEDATA           =
*     SEGMRPGENERALDATA            =
*     SEGMRPQUANTITYDATA           =
    .

  CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
    EXPORTING
      wait = 'X'
*   IMPORTING
*     RETURN        =
    .

* Grabar Log
  IF lr_return-type = 'E'.
    CLEAR git_log_all.
    git_log_all-matnr   = zretlai013_s02-matnr.
    git_log_all-matnrt  = zretlai013_s02-get_titulo.
    git_log_all-status  = gc_minisemaforo_rojo.
    git_log_all-paso    = 'P61'.
    CONCATENATE 'Actualizar datos tienda'
                zretlai013_s02-get_werks_usuario
           INTO git_log_all-pasot
           SEPARATED BY space.
    git_log_all-mensaje = lr_return-message.
    git_log_all-mm90    = lr_return-message_v2.
    APPEND git_log_all.
  ELSE.
    CLEAR git_log_all.
    git_log_all-matnr   = zretlai013_s02-matnr.
    git_log_all-matnrt  = zretlai013_s02-get_titulo.
    git_log_all-status  = gc_minisemaforo_verde.
    git_log_all-paso    = 'P61'.
    CONCATENATE 'Actualizar datos tienda'
                zretlai013_s02-get_werks_usuario
           INTO git_log_all-pasot
           SEPARATED BY space.
    git_log_all-mensaje = 'Datos actualizados correctamente'.
    APPEND git_log_all.
  ENDIF.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form f_crear_articulos_update_tdxxp
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      <-- LF_ERROR
*&---------------------------------------------------------------------*
FORM f_crear_articulos_update_tdxxp  CHANGING ps_error.
* 0.- Declaración de variables
*===================================================================================================
  DATA: lit_recipientparameters  LIKE bapi_wrpl_import  OCCURS 0 WITH HEADER LINE,
        lit_recipientparametersx LIKE bapi_wrpl_importx OCCURS 0 WITH HEADER LINE,
        lit_return               LIKE bapiret2          OCCURS 0 WITH HEADER LINE,
        ld_linea                 TYPE numc2.

* 1.- Lógica
*===================================================================================================
  CLEAR ps_error.

  IF ( zretlai013_s02-get_sobst_tienda IS NOT INITIAL OR
       zretlai013_s02-get_dismm_tienda IS NOT INITIAL ).

    REFRESH: lit_recipientparameters,
             lit_recipientparametersx.

    CLEAR:   lit_recipientparameters,
             lit_recipientparametersx.

    lit_recipientparameters-recipient     = zretlai013_s02-get_werks_usuario.
    lit_recipientparameters-material      = zretlai013_s02-matnr.
    lit_recipientparameters-mrp_type      = zretlai013_s02-get_dismm_tienda.
    lit_recipientparameters-target_stock  = zretlai013_s02-get_sobst_tienda.

    lit_recipientparametersx-recipient    = zretlai013_s02-get_werks_usuario.
    lit_recipientparametersx-material     = zretlai013_s02-matnr.
    lit_recipientparametersx-mrp_type     = 'X'.
    lit_recipientparametersx-target_stock = 'X'.

    APPEND: lit_recipientparameters,
            lit_recipientparametersx.

    REFRESH lit_return.
    CALL FUNCTION 'BAPI_RTMAT_RPL_SAVEREPLICAMULT'
      TABLES
        recipientparameters  = lit_recipientparameters
        recipientparametersx = lit_recipientparametersx
        return               = lit_return.

*     Hacemos commit
    CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
      EXPORTING
        wait = 'X'
*       IMPORTING
*       RETURN        =
      .


    LOOP AT lit_return WHERE type = 'E'.
      EXIT.
    ENDLOOP.

    IF sy-subrc = 0.
*       Activamos Flag de error
      ps_error = 'X'.

*       Registramos entrada de log
      CLEAR ld_linea.
      CLEAR git_log_all.

      ADD 1 TO ld_linea.
      git_log_all-matnr   = zretlai013_s02-matnr.
      git_log_all-matnrt  = zretlai013_s02-get_titulo.
      git_log_all-status  = gc_minisemaforo_rojo.
      git_log_all-lineam  = ld_linea.
      git_log_all-paso    = 'P62'.
      CONCATENATE 'Actualizar datos planificación tienda'
                  zretlai013_s02-get_werks_usuario
             INTO git_log_all-pasot
             SEPARATED BY space..
      git_log_all-mensaje = '>>ERROR: Inicio log.'.
      APPEND git_log_all.

      LOOP AT lit_return.
        ADD 1 TO ld_linea.
        git_log_all-lineam   = ld_linea.
        git_log_all-mensaje = lit_return-message.
        APPEND git_log_all.
      ENDLOOP.

      ADD 1 TO ld_linea.
      git_log_all-lineam  = ld_linea.
      git_log_all-mensaje = '>>ERROR: Fin log.'.
      APPEND git_log_all.
    ELSE.
*       Registramos entrada de log
      CLEAR git_log_all.
      git_log_all-matnr   = zretlai013_s02-matnr.
      git_log_all-matnrt  = zretlai013_s02-get_titulo.
      git_log_all-status  = gc_minisemaforo_verde.
      git_log_all-paso    = 'P62'.
      CONCATENATE 'Actualizar datos planificación tienda'
                  zretlai013_s02-get_werks_usuario
             INTO git_log_all-pasot
             SEPARATED BY space..
      git_log_all-mensaje = 'Paso realizado con éxito.'.
      APPEND git_log_all.
    ENDIF.

  ELSE.
    CLEAR git_log_all.
    git_log_all-matnr   = zretlai013_s02-matnr.
    git_log_all-matnrt  = zretlai013_s02-get_titulo.
    git_log_all-status  = gc_minisemaforo_ambar.
    git_log_all-paso    = 'P62'.

    git_log_all-pasot   = 'Actualizar dat'.
    git_log_all-mensaje = 'No aplica'.
    APPEND git_log_all.
  ENDIF.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form f_user_command_9000_modifp
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM f_user_command_9000_modifp USING pe_popup.
* 0.- Declaración de variables
*===================================================================================================
  DATA: ld_folder_libmod_in    LIKE zretlai013_param-valor2,
        ld_folder_libmod_proc  LIKE zretlai013_param-valor2,
        ld_fichero             TYPE text255,
        ld_linea               TYPE string,
        ld_dir_name            LIKE epsf-epsdirnam,
        ld_ean11               TYPE char17,
        lit_zretlai013_t03     LIKE zretlai013_t03 OCCURS 0 WITH HEADER LINE,
        lit_zretlai013_t03_fin LIKE zretlai013_t03 OCCURS 0 WITH HEADER LINE,
        lit_dir_list           LIKE epsfili OCCURS 0 WITH HEADER LINE.

* 1.- Lógica
*===================================================================================================
  SELECT SINGLE valor2
    FROM zretlai013_param
    INTO ld_folder_libmod_in
   WHERE param = 'CARPETA_FICHEROS_LIBMOD'
     AND valor1 = 'RECIBIDOS'.

  SELECT SINGLE valor2
    FROM zretlai013_param
    INTO ld_folder_libmod_proc
   WHERE param = 'CARPETA_FICHEROS_LIBMOD'
     AND valor1 = 'PROCESADOS'.

  ld_dir_name = ld_folder_libmod_in.

  CALL FUNCTION 'EPS_GET_DIRECTORY_LISTING'
    EXPORTING
      dir_name               = ld_dir_name
*     FILE_MASK              = ' '
*   IMPORTING
*     DIR_NAME               =
*     FILE_COUNTER           =
*     ERROR_COUNTER          =
    TABLES
      dir_list               = lit_dir_list
    EXCEPTIONS
      invalid_eps_subdir     = 1
      sapgparam_failed       = 2
      build_directory_failed = 3
      no_authorization       = 4
      read_directory_failed  = 5
      too_many_read_errors   = 6
      empty_directory_list   = 7
      OTHERS                 = 8.
  IF sy-subrc <> 0. ENDIF.

  LOOP AT lit_dir_list WHERE name CS 'LIBMOD'
                          OR name CS 'Libmod'
                          OR name CS 'libmod'.
    CONCATENATE ld_folder_libmod_in lit_dir_list-name INTO ld_fichero.

    OPEN DATASET ld_fichero FOR INPUT IN TEXT MODE ENCODING DEFAULT.

    IF sy-subrc <> 0.
      CONTINUE.
    ENDIF.

    DO.
      READ DATASET ld_fichero INTO ld_linea.

      IF sy-subrc <> 0.
        EXIT.
      ENDIF.

      IF ld_linea(1) <> 'D'.
        CONTINUE.
      ENDIF.

      CLEAR lit_zretlai013_t03.
      lit_zretlai013_t03-fichero = lit_dir_list-name.
      lit_zretlai013_t03-isbn = ld_linea+1(17).
      lit_zretlai013_t03-femod = ld_linea+18(8).
      ld_ean11 = lit_zretlai013_t03-isbn.
      REPLACE ALL OCCURRENCES OF '-' IN ld_ean11 WITH ''.
      lit_zretlai013_t03-ean11 = ld_ean11.
      SELECT SINGLE matnr
        FROM mara
        INTO lit_zretlai013_t03-matnr
       WHERE ean11 = lit_zretlai013_t03-ean11.

      IF sy-subrc = 0.
        APPEND lit_zretlai013_t03.
      ENDIF.
    ENDDO.

    CLOSE DATASET ld_fichero.

    PERFORM f_mover_fichero USING ld_folder_libmod_in
                                  ld_folder_libmod_proc
                                  lit_dir_list-name.
  ENDLOOP.

  SORT lit_zretlai013_t03 BY femod DESCENDING.

  LOOP AT lit_zretlai013_t03.
    READ TABLE lit_zretlai013_t03_fin WITH KEY matnr = lit_zretlai013_t03-matnr.

    IF sy-subrc <> 0.
      APPEND lit_zretlai013_t03 TO lit_zretlai013_t03_fin.
    ENDIF.
  ENDLOOP.

  LOOP AT lit_zretlai013_t03_fin.
    DELETE FROM zretlai013_t03
          WHERE isbn = lit_zretlai013_t03_fin-isbn.
  ENDLOOP.

  INSERT zretlai013_t03 FROM TABLE lit_zretlai013_t03_fin.

  IF pe_popup = 'X'.
    REFRESH git_libmod.
    SELECT *
      FROM zretlai013_t03
      INTO CORRESPONDING FIELDS OF TABLE git_libmod
     WHERE tratado = ''.

    IF git_libmod[] IS INITIAL.
*     MsgI: No existen modificaciones LIBMOD pendientes de tratar.
      MESSAGE i015(zretlai013).
    ELSE.
      LOOP AT git_libmod.
        PERFORM f_get_matnrt USING git_libmod-matnr CHANGING git_libmod-matnrt.

        MODIFY git_libmod.
      ENDLOOP.

      CALL SCREEN 0400 STARTING AT 1 1.
    ENDIF.

    IF gf_libmod = 'X'.
      PERFORM f_9000_pai_validar_ean11.
    ENDIF.
  ENDIF.
ENDFORM.


FORM f_mover_fichero USING pe_ruta
                         pe_procesados
                         pe_nombre.

* 0.- Declaración de variables
*===================================================================================================
  DATA: lt_lines          TYPE STANDARD TABLE OF spflist,
        lv_directory      TYPE pfeflnamel,
        lv_name           TYPE pfeflnamel,
        ls_line           TYPE spflist,
        lv_origen         TYPE string,
        lv_destino        TYPE string,
        ls_fichero        TYPE solisti1,
        ld_sourcepath     TYPE text200,
        ld_targetpath     TYPE text200,
        ld_long_file_name LIKE epsf-epsfilnam,
        ld_long_dir_name  LIKE epsf-epsdirnam.

* 1.- Lógica
*===================================================================================================

  lv_directory = pe_ruta.
  lv_name      = pe_nombre.

  CONCATENATE pe_ruta pe_nombre INTO ld_sourcepath.
  CONCATENATE pe_procesados pe_nombre INTO ld_targetpath.

  CALL FUNCTION 'ZARCHIVFILE_SERVER'
    EXPORTING
      sourcepath       = ld_sourcepath
      targetpath       = ld_targetpath
*   IMPORTING
*     LENGTH           =
    EXCEPTIONS
      error_file       = 1
      no_authorization = 2
      OTHERS           = 3.
  IF sy-subrc <> 0.
*   Implement suitable error handling here
  ELSE.
    ld_long_file_name = pe_nombre.
    ld_long_dir_name  = pe_ruta.

    CALL FUNCTION 'EPS_DELETE_FILE'
      EXPORTING
        file_name              = ld_long_file_name
*       IV_LONG_FILE_NAME      =
        dir_name               = ld_long_dir_name
*       IV_LONG_DIR_NAME       =
*     IMPORTING
*       FILE_PATH              =
*       EV_LONG_FILE_PATH      =
      EXCEPTIONS
        invalid_eps_subdir     = 1
        sapgparam_failed       = 2
        build_directory_failed = 3
        no_authorization       = 4
        build_path_failed      = 5
        delete_failed          = 6
        OTHERS                 = 7.
    IF sy-subrc <> 0.
* Implement suitable error handling here
    ENDIF.

  ENDIF.


ENDFORM.                    " MOVER_FICHERO

*&---------------------------------------------------------------------*
*& Form F_USER_COMMAND_0400
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM f_user_command_0400 .
  DATA: ld_okcode LIKE sy-ucomm.

  ld_okcode = gd_okcode_0400.

  CLEAR: gd_okcode_0400,
         sy-ucomm.

  CASE ld_okcode.
    WHEN 'CANCELAR'.
      PERFORM f_free_alv USING gr_grid_05 gr_container_05.
      LEAVE TO SCREEN 0.
  ENDCASE.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form f_get_matnrt
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> GIT_LIBMOD_MATNR
*&      <-- GIT_LIBMOD_MATNRT
*&---------------------------------------------------------------------*
FORM f_get_matnrt  USING    pe_matnr
                   CHANGING ps_matnrt.

  SELECT SINGLE maktx
    FROM makt
    INTO ps_matnrt
   WHERE spras = sy-langu
     AND matnr = pe_matnr.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form f_pbo_9000_config_ean_leido
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM f_pbo_9000_config_ean_leido .
*>Ocultar el bloque de datos de centro para que el usuario no lo vea
  LOOP AT SCREEN.
    IF screen-group3 = 'CTO'.
      screen-input = 0.
      screen-invisible = 1.
    ENDIF.

    MODIFY SCREEN.
  ENDLOOP.

*>Hacer el campo EAN de acceso no modificable
  LOOP AT SCREEN.
    IF screen-name = 'ZRETLAI013_S01-EAN11'.
      screen-input = 0.
    ENDIF.

    MODIFY SCREEN.
  ENDLOOP.

  IF zretlai013_s01-sap = ''.                                                                       "Artículo no existe
*   Ocultamos el código de artículo
    LOOP AT SCREEN.
      IF screen-name = 'ZRETLAI013_S02-MATNR' OR
         screen-name = 'TXT_MATNR'.
        screen-input = 0.
        screen-invisible = 1.
      ENDIF.

      MODIFY SCREEN.
    ENDLOOP.

*   Ocultamos los campos de última consulta CEGAL
    LOOP AT SCREEN.
      IF screen-group2 = 'UPD'.
        screen-invisible = 1.
        screen-input     = 0.
      ENDIF.

      MODIFY SCREEN.
    ENDLOOP.
  ELSE.                                                                                             "Artículo existe
*   Hacemos de salida los campos no modificables
    LOOP AT SCREEN.
      IF screen-group3 = 'MOD'.
        screen-input = 0.
      ENDIF.

      MODIFY SCREEN.
    ENDLOOP.

*   Si la editorial coincide, ocultamos los datos de nueva editorial
    IF gf_nueva_editorial = ''.
      LOOP AT SCREEN.
        IF screen-group3 = 'EDI'.
          screen-input = 0.
          screen-invisible = 1.
        ENDIF.

        MODIFY SCREEN.
      ENDLOOP.
    ENDIF.

*   Hacemos no modificables los campos de CEGAL almacenados en SAP
    LOOP AT SCREEN.
      IF screen-group2 = 'SAP'.
        screen-input = 0.
      ENDIF.

      MODIFY SCREEN.
    ENDLOOP.

    LOOP AT SCREEN.
      IF screen-name = 'ZRETLAI013_S02-GET_PRECIO_SIN_IVA' OR
         screen-name = 'ZRETLAI013_S02-GET_PRECIO_SIN_IVA_DATAB' OR
         screen-name = 'ZRETLAI013_S02-GET_PRECIO_SIN_IVA_DATBI' OR
         screen-name = 'ZRETLAI013_S02-GET_PRECIO_CON_IVA' OR
         screen-name = 'ZRETLAI013_S02-GET_PRECIO_CON_IVA_DATAB' OR
         screen-name = 'ZRETLAI013_S02-GET_PRECIO_CON_IVA_DATBI'.
        screen-input = 0.
      ENDIF.

      MODIFY SCREEN.
    ENDLOOP.

*   >APRADAS-08.03.2021 16:16:41-Inicio
    LOOP AT SCREEN.
*     Ocultamos pincho de catalogación en tienda web
      IF screen-name = 'ZRETLAI013_S02-GET_CATWEB_TIENDA'.
        screen-input = 0.
        screen-invisible = 1.
      ENDIF.

*     Ocultamos tipo producto
      IF screen-name = 'ZRETLAI013_S02-GET_TIPO_PRODUCTO' OR
         screen-name = 'ZRETLAI013_S02-GET_TIPO_PRODUCTOT'.
        screen-input = 0.
        screen-invisible = 1.
      ENDIF.

*     Tipo de articulo no modificable
      IF screen-name = 'ZRETLAI013_S02-GET_MTART'.
        screen-input = 0.
      ENDIF.

*     Grupo de artículos no modificable
      IF screen-name = 'ZRETLAI013_S02-GET_MATKL'.
        screen-input = 0.
      ENDIF.

      MODIFY SCREEN.
    ENDLOOP.
*   <APRADAS-08.03.2021 16:16:41-Fin

    LOOP AT SCREEN.
      IF screen-name = 'ZRETLAI013_S02-GET_SITUACION_DATAB'.
        screen-input = 0.
      ENDIF.

      MODIFY SCREEN.
    ENDLOOP.
  ENDIF.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form f_pbo_9000_config_ean_no_leido
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM f_pbo_9000_config_ean_no_leido .
*   Si no han leído un EAN...
  LOOP AT SCREEN.
    IF screen-group1 = '1'.
      screen-input = 0.
      screen-invisible = 1.
    ENDIF.

    MODIFY SCREEN.
  ENDLOOP.

  SET CURSOR FIELD 'ZRETLAI013_S01-EAN11'.
ENDFORM.

*===================================================================================================
*& Form f_borrar_imagenes_servidor
*===================================================================================================
* Para la carpeta recibida, elimina todos los ficheros existentes que hayan en la misma para el EAN
* recibido en las distintas extensiones contempladas (jpg, JPG, gif y GIF)
*===================================================================================================
FORM f_borrar_imagenes_servidor  USING    pe_ruta_completa
                                          pe_ean11.

* 0.- Declaración de variables
*===================================================================================================
  DATA: ld_long_filename TYPE eps2filnam,
        ld_long_dir_name TYPE eps2path.

* 1.- Lógica
*===================================================================================================
*>Inicializar carpeta de borrado
  ld_long_dir_name = pe_ruta_completa.

*>Borrar portada en jpg
  CONCATENATE pe_ean11 '.jpg' INTO ld_long_filename.

  CALL FUNCTION 'EPS_DELETE_FILE'
    EXPORTING
*     FILE_NAME              =
      iv_long_file_name      = ld_long_filename
*     DIR_NAME               =
      iv_long_dir_name       = ld_long_dir_name
*  IMPORTING
*     FILE_PATH              =
*     EV_LONG_FILE_PATH      =
    EXCEPTIONS
      invalid_eps_subdir     = 1
      sapgparam_failed       = 2
      build_directory_failed = 3
      no_authorization       = 4
      build_path_failed      = 5
      delete_failed          = 6
      OTHERS                 = 7.
  IF sy-subrc <> 0. ENDIF.

*>Borrar portada en JPG
  CONCATENATE  pe_ean11 '.JPG' INTO ld_long_filename.

  CALL FUNCTION 'EPS_DELETE_FILE'
    EXPORTING
*     FILE_NAME              =
      iv_long_file_name      = ld_long_filename
*     DIR_NAME               =
      iv_long_dir_name       = ld_long_dir_name
*  IMPORTING
*     FILE_PATH              =
*     EV_LONG_FILE_PATH      =
    EXCEPTIONS
      invalid_eps_subdir     = 1
      sapgparam_failed       = 2
      build_directory_failed = 3
      no_authorization       = 4
      build_path_failed      = 5
      delete_failed          = 6
      OTHERS                 = 7.
  IF sy-subrc <> 0. ENDIF.

*>Borrar portada en gif
  CONCATENATE   pe_ean11 '.gif' INTO ld_long_filename.

  CALL FUNCTION 'EPS_DELETE_FILE'
    EXPORTING
*     FILE_NAME              =
      iv_long_file_name      = ld_long_filename
*     DIR_NAME               =
      iv_long_dir_name       = ld_long_dir_name
*  IMPORTING
*     FILE_PATH              =
*     EV_LONG_FILE_PATH      =
    EXCEPTIONS
      invalid_eps_subdir     = 1
      sapgparam_failed       = 2
      build_directory_failed = 3
      no_authorization       = 4
      build_path_failed      = 5
      delete_failed          = 6
      OTHERS                 = 7.
  IF sy-subrc <> 0. ENDIF.

*>Borrar portada en GIF
  CONCATENATE  pe_ean11 '.GIF' INTO ld_long_filename.

  CALL FUNCTION 'EPS_DELETE_FILE'
    EXPORTING
*     FILE_NAME              =
      iv_long_file_name      = ld_long_filename
*     DIR_NAME               =
      iv_long_dir_name       = ld_long_dir_name
*  IMPORTING
*     FILE_PATH              =
*     EV_LONG_FILE_PATH      =
    EXCEPTIONS
      invalid_eps_subdir     = 1
      sapgparam_failed       = 2
      build_directory_failed = 3
      no_authorization       = 4
      build_path_failed      = 5
      delete_failed          = 6
      OTHERS                 = 7.
  IF sy-subrc <> 0. ENDIF.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form f_0500_pai_validar_mfrnr
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM f_0500_pai_validar_mfrnr .
  IF zretlai013_s02-get_mfrnr IS INITIAL.
**   MsgE: Es obligatorio informar una editorial
*    message e013(zretlai013) DISPLAY LIKE 'I'.
  ELSE.
    SELECT SINGLE lifnr
      FROM lfa1
      INTO zretlai013_s02-get_mfrnr
     WHERE lifnr = zretlai013_s02-get_mfrnr
       AND ktokk = 'Z008'.

    IF sy-subrc <> 0.
*     MsgE: & no es un proveedor editorial.
      MESSAGE e014(zretlai013) DISPLAY LIKE 'I' WITH zretlai013_s02-get_mfrnr.
    ENDIF.
  ENDIF.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form f_0500_pbo_init_data
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM f_0500_pbo_init_data .
  IF zretlai013_s02-get_mfrnr IS NOT INITIAL.
    PERFORM f_get_lifnrt USING zretlai013_s02-get_mfrnr CHANGING zretlai013_s02-get_mfrnrt.
  ELSE.
    CLEAR zretlai013_s02-get_mfrnrt.
  ENDIF.
ENDFORM.


*&---------------------------------------------------------------------*
*& Form f_user_command_0500
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM f_user_command_0500 .
  DATA: ld_okcode    LIKE sy-ucomm,
        ld_respuesta.

  ld_okcode = gd_okcode_0500.

  CLEAR: gd_okcode_0500,
         sy-ucomm.

  CASE ld_okcode.
    WHEN 'ACEPTAR'.
      IF zretlai013_s02-get_mfrnr IS INITIAL.
        PERFORM f_popup_to_confirm USING 'No se ha informado ninguna editorial para el EAN. ¿Desea continuar?' CHANGING ld_respuesta.

        IF ld_respuesta = '1'.
          LEAVE TO SCREEN 0.
        ENDIF.
      ELSE.
        LEAVE TO SCREEN 0.
      ENDIF.
  ENDCASE.
ENDFORM.


*&---------------------------------------------------------------------*
*& Form f_user_command_0600
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM f_user_command_0600 .
  DATA: ld_okcode LIKE sy-ucomm.

  ld_okcode = gd_okcode_0600.

  CLEAR: gd_okcode_0600,
         sy-ucomm.

  CASE ld_okcode.
    WHEN 'CAMBIAR'.
      gf_cambiar_editorial = 'X'.
      LEAVE TO SCREEN 0.
    WHEN 'NOCAMBIAR'.
      gf_cambiar_editorial = ''.
      LEAVE TO SCREEN 0.
  ENDCASE.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form f_0500_povr_mfrnr
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM f_0500_povr_mfrnr .
* 0.- Declaración de variables
*======================================================================
  DATA: BEGIN OF lit_mfrnr OCCURS 0,
          mfrnr  LIKE mara-mfrnr,
          mfrnrt TYPE but000-name_org1,
        END OF lit_mfrnr.

* 1.- Logica
*======================================================================
*>Determinar valores de tipo producto
*  SELECT lifnr AS mfrnr
*         name1 AS mfrnrt
*    FROM lfa1
*    INTO CORRESPONDING FIELDS OF TABLE lit_mfrnr
*   WHERE ktokk = 'Z008'.

  SELECT a~lifnr AS mfrnr
         b~name_org1 AS mfrnrt
    FROM lfa1 as a
    inner join but000 as b on ( b~partner = a~lifnr )
    INTO CORRESPONDING FIELDS OF TABLE lit_mfrnr
   WHERE ktokk = 'Z008'.


  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING
      dynpprog        = sy-repid
      dynpnr          = '0500'
      dynprofield     = 'ZRETLAI013_S02-GET_MFRNR'
      retfield        = 'MFRNR'
      value_org       = 'S'
    TABLES
      value_tab       = lit_mfrnr
    EXCEPTIONS
      parameter_error = 1
      no_values_found = 2
      OTHERS          = 3.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form f_crear_articulos_verif_surt
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      <-- LF_ERROR
*&---------------------------------------------------------------------*
FORM f_crear_articulos_verif_surt  CHANGING p_lf_error.
* 0.- Declaración de variables
*===================================================================================================
  DATA: lf_noalv TYPE char01,
        lit_wrsz LIKE wrsz OCCURS 0 WITH HEADER LINE,
        ld_index LIKE sy-tabix.

  RANGES: lran_asort FOR wrs1-asort.

* 1.- Lógica
*===================================================================================================

* Obtener los surtidos asociados a la tienda que sean distintos al surtido LIBRERIAS
  SELECT *
    FROM wrsz
    INTO TABLE lit_wrsz
   WHERE locnr = zretlai013_s02-get_werks_usuario
     AND asort <> 'LIBRERIAS'
     AND datab <= sy-datum
     AND datbi >= sy-datum.

  LOOP AT lit_wrsz.
    ld_index = sy-tabix.

    SELECT SINGLE asort
      FROM wrs1
      INTO lit_wrsz-asort
     WHERE asort = lit_wrsz-asort
       AND sotyp = 'C'.

    IF sy-subrc <> 0.
      DELETE lit_wrsz INDEX ld_index.
    ENDIF.
  ENDLOOP.

  IF zretlai013_s02-get_mtart = 'ZLIB' OR
     zretlai013_s02-get_mtart = 'ZEBK'.

    lran_asort-sign   = 'I'.
    lran_asort-option = 'EQ'.

    LOOP AT lit_wrsz.
      lran_asort-low    = lit_wrsz-asort.
      APPEND lran_asort.
    ENDLOOP.
  ENDIF.


* Añadir el surtido LIBRERIAS a la catalogación
  lran_asort-low    = 'LIBRERIAS'.
  APPEND lran_asort.

* Añadir el surtido WEB si han marcado el pincho web en la pantalla
  IF zretlai013_s02-get_catweb_tienda = 'X'.
    lran_asort-low    = 'ZWEB'.
    APPEND lran_asort.
  ENDIF.

  lf_noalv = 'X'.
  EXPORT lf_noalv TO MEMORY ID 'NOALV'.
*  BREAK-POINT .

  SUBMIT rwdifferencemarcwlk1
    WITH s_asort IN lran_asort
    WITH s_matnr BETWEEN zretlai013_s02-matnr AND ''
    WITH detail = 'X'
    WITH create = 'X'
     AND RETURN.

  FREE MEMORY ID 'NOALV'.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form f_user_command_0700
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM f_user_command_0700 .
  DATA: ld_okcode LIKE sy-ucomm.

  ld_okcode = gd_okcode_0700.

  CLEAR: sy-ucomm,
         gd_okcode_0700.

  CASE ld_okcode.
    WHEN 'CANCELAR'.
      LEAVE TO SCREEN 0.
  ENDCASE.
ENDFORM.


*&---------------------------------------------------------------------*
*& Form f_handle_hotspot_click_alv_06
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> E_ROW_ID
*&      --> E_COLUMN_ID
*&      --> ES_ROW_NO
*&---------------------------------------------------------------------*
FORM f_handle_hotspot_click_alv_06  USING    e_row_id    TYPE  lvc_s_row
                                            e_column_id TYPE  lvc_s_col
                                            es_row_no   TYPE  lvc_s_roid.


  READ TABLE git_lifnr_sel INDEX e_row_id-index.

  CASE e_column_id-fieldname.
    WHEN 'LIFNR'.
      gd_lifnr = git_lifnr_sel-lifnr.
      gd_lifnrt = git_lifnr_sel-lifnrt.

      CALL METHOD cl_gui_cfw=>set_new_ok_code
        EXPORTING
          new_code = 'CANCELAR'.
  ENDCASE.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form f_pbo_0700_config
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM f_pbo_0700_config .
  IF zretlai013_s01-sap = ''.
    LOOP AT SCREEN.
      IF screen-name = 'TXTEANEXISTE'.
        screen-invisible = 1.
      ENDIF.

      MODIFY SCREEN.
    ENDLOOP.
  ELSE.
    LOOP AT SCREEN.
      IF screen-name = 'TXTEANNUEVO'.
        screen-invisible = 1.
      ENDIF.

      MODIFY SCREEN.
    ENDLOOP.
  ENDIF.
ENDFORM.

FORM f_user_command_0800 .
  data: ld_okcode like sy-ucomm.

  ld_okcode = GD_OKCODE_0800.

  clear: sy-ucomm,
         gd_okcode_0800.

  case ld_okcode.
    when 'ACEP_0800'.
      if gd_werks is initial.
*       MsgE: Informar una tienda.
        message i017(zretlai013) DISPLAY LIKE 'E'.
      else.
        leave to SCREEN 0.
      endif.
    when 'CANC_0800'.
      leave to screen 0.
  endcase.
ENDFORM.

FORM f_0800_pai_validar_werks .
  select single werks
    into gd_werks
    from t001w
   where werks = gd_werks
     and vlfkz = 'A'.

  if sy-subrc <> 0.
*   MsgE: Tienda & no existe o no es una tienda.
    message e018(zretlai013) WITH gd_werks DISPLAY LIKE 'E'.
  endif.
ENDFORM.

FORM f_0800_pbo_init_data .
  if gd_werks is initial.
    clear gd_werkst.
  else.
    select single name1
      from t001w
      into gd_werkst
     where werks = gd_werks.
  endif.
ENDFORM.

FORM f_0800_povr_werks .
* 0.- Declaración de variables
*======================================================================
  DATA: BEGIN OF lit_werks OCCURS 0,
          werks  LIKE marc-werks,
          werkst LIKE t001w-name1,
        END OF lit_werks.

* 1.- Logica
*======================================================================
  select werks
         name1
    from t001w
    into table lit_Werks
   where vlfkz = 'A'.

  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING
      dynpprog        = sy-repid
      dynpnr          = '0800'
      dynprofield     = 'GD_WERKS'
      retfield        = 'WERKS'
      value_org       = 'S'
    TABLES
      value_tab       = lit_werks
    EXCEPTIONS
      parameter_error = 1
      no_values_found = 2
      OTHERS          = 3.
ENDFORM.


*&---------------------------------------------------------------------*
*& Form f_get_idioma_originalt
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> ZRETLAI013_S02_GET_IDIOMA_ORIG
*&      <-- ZRETLAI013_S02_GET_IDIOMA_ORIG
*&---------------------------------------------------------------------*
FORM f_get_idioma_originalt  USING    pe_idioma_original
                             CHANGING ps_idioma_originalt.

  select single description
    from ZZ1_9F245DF7AF2A
    into ps_idioma_originalt
   where code = pe_idioma_original
     and language = sy-langu.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form f_get_lengua_publicaciont
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> ZRETLAI013_S02_GET_LENGUA_PUBL
*&      <-- ZRETLAI013_S02_GET_LENGUA_PUBL
*&---------------------------------------------------------------------*
FORM f_get_lengua_publicaciont  USING    pe_lengua_publicacion
                                CHANGING ps_lengua_publicaciont.

  select single description
    from ZZ1_55E15C2ADC74
    into ps_lengua_publicaciont
   where code = pe_lengua_publicacion
     and language = sy-langu.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form f_determinar_si_es_novedad
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> ZRETLAI013_S02_GET_FECHA_PUBLI
*&      <-- ZRETLAI013_S02_GET_ZZ1_NOVEDAD
*&---------------------------------------------------------------------*
FORM f_determinar_si_es_novedad  USING    pe_fecha_primera_edicion
                                 CHANGING ps_novedad.
*===================================================================================================
* 0.- Declaración de variables
*===================================================================================================
  data: ld_numdias type int4,
        ld_numdias_t like zhardcodes-valor,
        ld_dias_transcurridos type int4.

*===================================================================================================
* 1.- Lógica
*===================================================================================================

*>Obtener parametrización de dias para considerar que un artículo deja de ser novedad
  select single valor
    from zhardcodes
    into ld_numdias_t
   where programa = 'ZRETLAI007'
     and param    = 'DIAS_NOVEDAD'.

  if sy-subrc = 0.
    ld_numdias = ld_numdias_t.
  endif.

  if pe_fecha_primera_edicion is initial.
*   Si no tenemos fecha primera edicion, no es novedad
    ps_novedad = 'NO'.
  else.
*   Si tenemos fecha primera edición

*  >Calcular los dias transcurridos desde la fecha de primera edición hasta el día de hoy
    ld_dias_transcurridos = sy-datum - pe_fecha_primera_edicion.

    if ld_dias_transcurridos >= ld_numdias.
*     Si han transcurrido los dias parametrizados, no es novedad
      ps_novedad = 'NO'.
    else.
*     Sino, es novedad
      ps_novedad = 'SI'.
    endif.
  endif.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form f_9000_pai_validar_novedad
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM f_9000_pai_validar_novedad .

  if zretlai013_s01-sap = 'X'.
    if ZRETLAI013_S02-GET_FECHA_PUBLICACION_CEGAL is not initial.
*     Determinar si el nuevo artículo debe considerarse novedad o no
      perform f_determinar_si_es_novedad using zretlai013_s02-get_fecha_publicacion_cegal
                                      CHANGING zretlai013_s02-get_zz1_novedad2_prd.
    else.
      zretlai013_s02-get_zz1_novedad2_prd = 'NO'.
    endif.

  else.
    if ZRETLAI013_S02-GET_FECHA_PUBLICACION is not initial.
*     Determinar si el nuevo artículo debe considerarse novedad o no
      perform f_determinar_si_es_novedad using zretlai013_s02-get_fecha_publicacion
                                      CHANGING zretlai013_s02-get_zz1_novedad2_prd.
    else.
      zretlai013_s02-get_zz1_novedad2_prd = 'NO'.
    endif.
  endif.


ENDFORM.
