require_relative '../accion'
require_relative '../../contenedores_datos/tutoria'
require_relative '../menu_inline_telegram'
require 'active_support/inflector'
class PeticionesPendientesTutoria < Accion

  attr_accessor :teclado_menu_padre
  @nombre='Aprobar/Denegar peticiones.'
  def initialize selector_tutorias, tutoria
    @profesor=nil
    @selector_tutorias=selector_tutorias
    @tutoria=tutoria
    @peticiones=nil
    @peticion_elegida=nil
    @ultimo_mensaje=nil
  end

  def generar_respuesta_mensaje(mensaje)
    @ultimo_mensaje=mensaje
    datos_mensaje=@ultimo_mensaje.obtener_datos_mensaje
    if @profesor.nil?
      @profesor=Profesor.new(@ultimo_mensaje.usuario.id_telegram)
    end
    respuesta_segun_datos_mensaje(datos_mensaje)
  end

 def respuesta_segun_datos_mensaje datos_mensaje
    case datos_mensaje
      when  /\#\#\$\$Indice/
        datos_mensaje.slice! "peticion_"
        id_estudiante_peticion=datos_mensaje[/[^_]*/]
        solicitar_accion_sobre_peticion id_estudiante_peticion
        @fase="peticion_elegida"
      when /(\#\#\$\$Aceptar|\#\#\$\$Denegar)/
        aceptar_denegar_peticion( datos_mensaje)
      when /\#\#\$\$Volver/
        mostrar_menu_anterior
      else
        mostrar_peticiones_pendientes
        fase="mostrando_peticiones"
      end




 end


  def reiniciar
    @profesor=nil
    @tutoria=nil
    @peticiones=nil
    @peticion_elegida=nil
  end

  private

  def mostrar_peticiones_pendientes

    @peticiones=@tutoria.peticiones
    peticiones_pendientes=Array.new
    @peticiones.each{ |peticion|
      if(peticion.estado=="por aprobar")
      peticiones_pendientes << peticion
      end
    }

      if peticiones_pendientes.empty?
        menu=MenuInlineTelegram.crear(Array.new << "Volver")
        @@bot.api.edit_message_text(:chat_id => @ultimo_mensaje.id_chat ,:message_id => @ultimo_mensaje.id_mensaje, text: "No tiene peticiones para la tutoría elegida.", parse_mode: "Markdown", reply_markup: menu)
      else

        texto="Seleccione la petición la cual  desea aprobar/denegar:\n"
        contador=0
        indices_peticiones=[*0..peticiones_pendientes.size-1]
        menu=MenuInlineTelegram.crear_menu_indice(peticiones_pendientes, "Peticion", "no_final")
        peticiones_pendientes.each{ |peticion|
            texto+= "\t (*#{contador}*) \tNombre telegram estudiante:\t *#{peticion.estudiante.nombre_usuario}*\n"
            texto+= "    Fecha realización petición: *\t#{peticion.hora.strftime('%d %b %Y %H:%M:%S')}* \n"
            contador+=1
        }
        @@bot.api.edit_message_text(:chat_id => @ultimo_mensaje.id_chat ,:message_id => @ultimo_mensaje.id_mensaje, text: texto, parse_mode: "Markdown", reply_markup: menu)
      end

  end


  def solicitar_accion_sobre_peticion id_estudiante_peticion

    @peticion_elegida=nil
    cont=0
    while(@peticion_elegida.nil? && cont < @peticiones.size)
      if @peticiones[cont].estudiante.id.to_i== id_estudiante_peticion.to_i
        @peticion_elegida=@peticiones[cont]

      end
      cont+=1
    end
    if @peticion_elegida.nil?
      @@bot.api.send_message( chat_id: @profesor.id, text: "Vuelva a intentarlo", parse_mode: "Markdown" )
    else
      text="Petición seleccionada:\n"
      text+="\t Hora petición: *#{@peticion_elegida.hora}*\n"
      text+="\t Nombre usuario estudiante: #{@peticion_elegida.estudiante.nombre_usuario}"
      opciones= Array.new
      opciones << "Aceptar"
      opciones << "Denegar"
      menu=MenuInlineTelegram.crear(opciones)
      @@bot.api.send_message( chat_id: @profesor.id, text: text,reply_markup: menu, parse_mode: "Markdown"  )
    end

  end


  def aceptar_denegar_peticion que_hacer

    if que_hacer =~ /\#\#\$\$Aceptar/
      @peticion_elegida.aceptar
      @@bot.api.answer_callback_query(callback_query_id: @ultimo_mensaje.id_mensaje, text: "Aceptada!")
      @@bot.api.send_message( chat_id: @profesor.id, text: "Petición aceptada", parse_mode: "Markdown"  )

    elsif que_hacer =~ /\#\#\$\$Denegar/
      @@bot.api.answer_callback_query(callback_query_id: @ultimo_mensaje.id_mensaje, text: "Denegada")
      @@bot.api.send_message( chat_id: @profesor.id, text: "Petición rechazada", parse_mode: "Markdown"  )
      @peticion_elegida.denegar
    else
      @@bot.api.send_message( chat_id: @profesor.id, text: "Error vuelva a intentarlo",reply_markup: markup, parse_mode: "Markdown"  )
    end
    reiniciar
  end






  def mostrar_menu_anterior

    case @fase
      when "peticion_elegida"
        mostrar_peticiones_pendientes
        @fase="mostrando_peticiones"
      else
        @selector_tutorias.reiniciar
        @selector_tutorias.solicitar_seleccion_tutoria "editar"
        @fase=""
    end
  end



  public_class_method :new

end
