
require_relative '../procesadores_entradas/procesador_entradas_profesor'
require_relative '../usuarios/profesor'
require_relative '../estado/profesor'
require_relative '../Mensaje'
require_relative '../acciones/accion'
require_relative '../../lib/acciones/acciones_profesor/menu_principal_profesor'

class ManejadorMensajesProfesor

  def initialize()

    @profesores=Hash.new
  end

  def recibir_mensaje(mensaje,bot)

    id_telegram=mensaje.obtener_identificador_telegram
    accion=@profesores[id_telegram]
    if accion
      @profesores[id_telegram]=accion.ejecutar(mensaje)
    else
      @profesores[id_telegram]=MenuPrincipalProfesor.new
      @profesores[id_telegram]=@profesores[id_telegram].ejecutar(mensaje)
    end
#no se tiene que pasar profesores sino que es self lo que se pasa es self
  end

end