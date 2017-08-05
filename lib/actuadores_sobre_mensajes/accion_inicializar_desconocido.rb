

class AccionInicializarDesconocido < Accion
  def initialize
    @fase='inicio'
    @ultimo_mensaje=nil
    @usuario_desconocido=nil
    @moodle=Moodle.new(ENV['TOKEN_BOT_MOODLE'])
  end

  def reiniciar
    @fase='inicio'
    usuario=Usuario.new
  end

  def ejecutar(id_telegram)
    @@bot.api.send_message( chat_id: id_telegram, text: "Para empezar a utilizar el bot es necesario identificarse. Introduzca su email:", parse_mode: 'Markdown')
    @fase='peticion_email'
    return self
  end

  def recibir_mensaje(mensaje)
    if @usuario_desconocido.nil?
      @usuario_desconocido=UsuarioDesconocido.new(mensaje.usuario.id_telegram, mensaje.usuario.nombre_usuario)
    end
    @ultimo_mensaje=mensaje
    datos_mensaje=@ultimo_mensaje.obtener_datos_mensaje
    siguiente_accion=self

    case @fase
      when 'peticion_email'
        @usuario_desconocido.email=datos_mensaje
        @@bot.api.send_message( chat_id: @usuario_desconocido.id_telegram, text: "Introduzca su contraseña:", parse_mode: 'Markdown')
        @fase='peticion_contraseña'
      when 'peticion_contraseña'
        @usuario_desconocido.contrasena=datos_mensaje
        token=Moodle.obtener_token(@usuario_desconocido.email, datos_mensaje, ENV['WEBSERVICE_PROFESOR_MOODLE'])['token']
        if token
          @usuario_desconocido.rol='profesor'
        else
          token=Moodle.obtener_token(@usuario_desconocido.email, datos_mensaje, ENV['WEBSERVICE_ESTUDIANTES_MOODLE'])['token']
          if token
            @usuario_desconocido.rol='estudiante'
          end
        end
        if token
          @usuario_desconocido.id_moodle=@moodle.obtener_identificador_moodle(@usuario_desconocido.email)
          cursos=@moodle.obtener_cursos_usuario(@usuario_desconocido.id_moodle)
          if cursos.empty?
            @@bot.api.send_message( chat_id: @usuario_desconocido.id_telegram, text: "Fallo: Datos login correctos pero no está matriculado en ningún curso que utilize al bot luego no puede usarlo.", parse_mode: 'Markdown' )
          else
            @usuario_desconocido.anadir_cursos_moodle(cursos)
            @usuario_desconocido.token=token
            @usuario_desconocido.nombre_usuario=mensaje.usuario.nombre_usuario
            @usuario_desconocido.registrarme_en_el_sistema
            @@bot.api.send_message( chat_id: @usuario_desconocido.id_telegram, text: "Dado de alta en el bot con exito, ya puede empezar a utilizarlo", parse_mode: 'Markdown' )

            usuario=UsuarioRegistrado.new(id_telegram)
            cursos=usuario.obtener_cursos_usuario

            menu.iniciar_cambio_curso(id_telegram,cursos[0].id_curso)
            if @usuario_desconocido.rol == "profesor"
                    
              siguiente_accion=MenuPrincipalProfesor.new
            elsif @usuario_desconocido.rol == "estudiante"
              siguiente_accion=MenuPrincipalEstudiante.new
            end
            siguiente_accion.iniciar_cambio_curso(@ultimo_mensaje.usuario.id_telegram,cursos[0].id_curso)
          end
        else
          @@bot.api.send_message( chat_id: @usuario_desconocido.id_telegram, text: 'Datos de login incorrectos o bien el usuario no esta autorizado a utilizar el bot', parse_mode: 'Markdown' )
        end
        reiniciar
      else
        ejecutar(@ultimo_mensaje.usuario.id_telegram)
    end


    return siguiente_accion
  end






  public_class_method :new
end

require_relative '../../lib/contenedores_datos/mensaje'
require_relative '../moodle_api'
require_relative '../contenedores_datos/usuario_desconocido'
require_relative 'accion'
require_relative '../../lib/actuadores_sobre_mensajes/acciones_estudiante/menu_principal_estudiante'
require_relative '../../lib/actuadores_sobre_mensajes/acciones_profesor/menu_principal_profesor'
