*&---------------------------------------------------------------------*
*& Include          ZRETLAI013_TOP
*&---------------------------------------------------------------------*
*===================================================================================================
* CONSTANTES
*===================================================================================================
CONSTANTS: gc_cdata_si                type char1   value 'X',
           gc_cdata_no                type char1   value '',
           gc_minisemaforo_verde      TYPE icon_d  VALUE '@5B@',
           gc_minisemaforo_ambar      TYPE icon_d  VALUE '@5D@',
           gc_minisemaforo_rojo       TYPE icon_d  VALUE '@5C@',
           gc_minisemaforo_inactivo   TYPE icon_d  VALUE '@BZ@',
           gc_icono_log               type icon_d  value '@IG@',
           gc_modo_online             type char4   value 'ON',
           gc_modo_offline            type char4   value 'OFF',
           gc_icono_warning           type icon_d  VALUE '@1A@'.

*===================================================================================================
* DICCIONARIO DE DATOS
*===================================================================================================
tables: ZRETLAI013_S01, "MONITOR DESCARGA INFORMACIÓN DE ARTÍCULOS: Campos Pantalla
        ZRETLAI013_S02, "Monitor status articulo
        ZRETLAI013_S06. "Campos popup 0700: Selección proveedor

*===================================================================================================
* DEFINICIONES GLOBALES
*===================================================================================================
data: gd_okcode_9000              like sy-ucomm,
      GD_OKCODE_0300              like sy-ucomm,
      GD_OKCODE_0400              like sy-ucomm,
      GD_OKCODE_0500              like sy-ucomm,
      GD_OKCODE_0600              like sy-ucomm,
      GD_OKCODE_0700              like sy-ucomm,
      GD_OKCODE_0800              like sy-ucomm,
      gf_cargar_photo             type char1,
      gf_ean_leido                type char1,
      gd_ruta_completa            type text255,
     "Tabla con el resumen del articulo devuelto por CEGAL
      git_resumen                 like TLINE occurs 0 WITH HEADER LINE,
     "Tabla con el resumen del articulo en SAP
      git_resumen_sap             like TLINE occurs 0 WITH HEADER LINE,
      git_biografia               like tline occurs 0 WITH HEADER LINE,
      git_indice                  like tline occurs 0 WITH HEADER LINE,
      git_log                     like ZRETLAI013_S03 occurs 0 WITH HEADER LINE,
      gd_okcode_0200              like sy-ucomm,
      git_log_all                 like zretlai001s02 occurs 0 WITH HEADER LINE,
      git_lineas_texto_final(132) OCCURS 0 WITH HEADER LINE,

      git_libmod                  like ZRETLAI013_S04 occurs 0 WITH HEADER LINE,
      gf_libmod                   type char1,
      "Tienda/almacén modelo
      gd_tienda_modelo            like marc-werks,
*      gd_tienda_modelo_almacen    like mard-lgort,
      gd_tienda_modelo_LGFSB      type LGFSB,
      "Centro/almacén modelo
      gd_centro_modelo            like marc-werks,
*      gd_centro_modelo_almacen    like mard-lgort,
      gd_centro_modelo_LGFSB      type LGFSB,
      "Areas de venta en las que dar de alta el artículo
      git_areas_de_venta          like ZRETLAI001_T01 occurs 0 WITH HEADER LINE,
      git_almacenes_modelo_tdmo   like ZRETLAI001_T01 occurs 0 WITH HEADER LINE,
      git_almacenes_modelo_cdmo   like ZRETLAI001_T01 occurs 0 WITH HEADER LINE,
      begin of git_proveedores_editorial occurs 0,
        lifnr  like lfa1-lifnr,
        lifnrt like lfa1-name1,
      end of git_proveedores_editorial,
     "Flag que se activa cuando se ha detectado que la editorial que tiene el articulo que se está
     "modificando no coincide con la editorial determinada por la tabla de eans y el usuario ha
     "confirmado que quiere cambiar de editorial
      gf_nueva_editorial          type char01,
     "Flag parecido al anterior solo que en este caso se activa cuando el usuario confirma que quiere
     "cambiar la editorial del articulo por la nueva editorial determinada
      gf_cambiar_editorial        type char01,
      git_lifnr_sel               like ZRETLAI013_S05 occurs 0 WITH HEADER LINE,
      gd_lifnr                    like lfa1-lifnr,
      gd_lifnrt                   like lfa1-name1,
      gd_werks                    type werks_d,
      gd_werkst                   type name1_gp.


*==========================================================================
* EVENTOS ALV
*==========================================================================
CLASS lcl_event_handler DEFINITION.
  PUBLIC SECTION.
    METHODS:
*      handle_hotspot_click_alv_01   FOR EVENT hotspot_click OF cl_gui_alv_grid
*                                    IMPORTING e_row_id e_column_id es_row_no,
*      handle_hotspot_click_alv_02   FOR EVENT hotspot_click OF cl_gui_alv_grid
*                                    IMPORTING e_row_id e_column_id es_row_no,
      handle_hotspot_click_alv_04   FOR EVENT hotspot_click OF cl_gui_alv_grid
                                    IMPORTING e_row_id e_column_id es_row_no,
      handle_hotspot_click_alv_06   FOR EVENT hotspot_click OF cl_gui_alv_grid
                                    IMPORTING e_row_id e_column_id es_row_no,
      handle_hotspot_click_alv_05   FOR EVENT hotspot_click OF cl_gui_alv_grid
                                    IMPORTING e_row_id e_column_id es_row_no.
endclass.

CLASS lcl_event_handler IMPLEMENTATION.
*  METHOD handle_hotspot_click_alv_01.
*    PERFORM f_handle_hotspot_click_alv_01 USING  e_row_id
*                                                 e_column_id
*                                                 es_row_no.
*  ENDMETHOD.
*
*  METHOD handle_hotspot_click_alv_02.
*    PERFORM f_handle_hotspot_click_alv_02 USING  e_row_id
*                                                 e_column_id
*                                                 es_row_no.
*  ENDMETHOD.

  METHOD handle_hotspot_click_alv_04.
    PERFORM f_handle_hotspot_click_alv_04 USING  e_row_id
                                                 e_column_id
                                                 es_row_no.
  ENDMETHOD.

  METHOD handle_hotspot_click_alv_05.
    PERFORM f_handle_hotspot_click_alv_05 USING  e_row_id
                                                 e_column_id
                                                 es_row_no.
  ENDMETHOD.

  METHOD handle_hotspot_click_alv_06.
    PERFORM f_handle_hotspot_click_alv_06 USING  e_row_id
                                                 e_column_id
                                                 es_row_no.
  ENDMETHOD.
endclass.

*===================================================================================================
* ALVs
*===================================================================================================
data: "Imagen anexos
      gr_container_photo        TYPE REF TO cl_gui_custom_container,
      image                     TYPE REF TO cl_gui_picture,
      "Editor de textos resumen
      gr_editor_container       TYPE REF TO cl_gui_custom_container,
      gr_editor                 TYPE REF TO cl_gui_textedit,
      "Editor de textos resumen cegal (solo en modificación articulo)
      gr_editor_container_cegal TYPE REF TO cl_gui_custom_container,
      gr_editor_cegal           TYPE REF TO cl_gui_textedit,
      "Popup Log de proceso
*      gr_event_handler_03      TYPE REF TO lcl_event_handler,
      gr_grid_03                TYPE REF TO cl_gui_alv_grid,
      gr_container_03           TYPE REF TO cl_gui_custom_container,
      git_fieldcatalog_03       TYPE lvc_t_fcat,
      gr_layout_03              TYPE lvc_s_layo,
      "Popup log creación artículo
      gr_event_handler_04       TYPE REF TO lcl_event_handler,
      gr_grid_04                TYPE REF TO cl_gui_alv_grid,
      gr_container_04           TYPE REF TO cl_gui_custom_container,
      git_fieldcatalog_04       TYPE lvc_t_fcat,
      gr_layout_04              TYPE lvc_s_layo,
      "Popup: Modificaciones LIBMOD
      gr_event_handler_05       TYPE REF TO lcl_event_handler,
      gr_grid_05                TYPE REF TO cl_gui_alv_grid,
      gr_container_05           TYPE REF TO cl_gui_custom_container,
      git_fieldcatalog_05       TYPE lvc_t_fcat,
      gr_layout_05              TYPE lvc_s_layo,
      "Popup: Selección proveedor
      gr_event_handler_06       TYPE REF TO lcl_event_handler,
      gr_grid_06                TYPE REF TO cl_gui_alv_grid,
      gr_container_06           TYPE REF TO cl_gui_custom_container,
      git_fieldcatalog_06       TYPE lvc_t_fcat,
      gr_layout_06              TYPE lvc_s_layo.
