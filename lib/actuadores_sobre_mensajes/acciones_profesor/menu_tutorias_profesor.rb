require_relative  'establecer_tutorias'
require_relative '../menu_acciones'
require_relative 'accion_sobre_tutoria.rb'

class MenuTutoriasProfesor < MenuDeAcciones
  @nombre= 'Tutorías'
  def initialize accion_padre
    @accion_padre=accion_padre
    @acciones=Hash.new
    inicializar_acciones
  end

  def ejecutar(mensaje)
  @ultimo_mensaje=mensaje
  kb= Array.new
  fila_botones=Array.new
  array_botones=Array.new
  @acciones.keys.each{
      |accion|
    kb <<   Telegram::Bot::Types::KeyboardButton.new( text: accion, )
    array_botones << Telegram::Bot::Types::KeyboardButton.new( text: accion, )
    if array_botones.size == 2
      fila_botones << array_botones.dup
      array_botones.clear
    end
  }
  fila_botones << array_botones

  iniciar_acciones_defecto(fila_botones)

    markup = Telegram::Bot::Types::ReplyKeyboardMarkup.new(keyboard: fila_botones)
    @@bot.api.send_message( chat_id: @ultimo_mensaje.usuario.id_telegram, text: "Elija entre las opciones del menu",  reply_markup: markup)
    if(@acciones[AccionEstablecerTutorias.nombre].teclado_menu_padre.nil?)
      @acciones[AccionEstablecerTutorias.nombre].teclado_menu_padre=markup
    end
    return self
  end

  def obtener_accion_recibe_mensaje(datos_mensaje)
    siguiente_accion=nil


    if datos_mensaje== "Atras" && @accion_padre
      siguiente_accion=@accion_padre
      if @accion_pulsada
        @accion_pulsada.reiniciar
      end
      @accion_pulsada=nil
    elsif datos_mensaje =~ /Volver al men/
      siguiente_accion=self

      if @accion_pulsada
        @accion_pulsada.reiniciar
      end
      @accion_pulsada=nil
    else
      ha_pulsado_accion(datos_mensaje)
      if siguiente_accion.nil? && @accion_pulsada.nil?
        siguiente_accion=self
      else
        siguiente_accion=@accion_pulsada
      end
    end
    return siguiente_accion
  end

  def inicializar_acciones
    @acciones[AccionEstablecerTutorias.nombre] = AccionEstablecerTutorias.new
    @acciones[AccionSobreTutoria.nombre]= AccionSobreTutoria.new
  end

  private :inicializar_acciones

end
