
require_relative 'usuario'

class Profesor < UsuarioRegistrado
  attr_reader :id
  def initialize id_telegram=nil
    @id_telegram=id_telegram
    @id=id_telegram
    @nombre_usuario=nil
    ##HAY que quitar id y poner en todos donde se utilize id_telegram
  end

  def solicitar_tutoria peticion

    aceptada=true
    begin
      puts Time.new.strftime("%Y-%m-%d %H:%M:%S")
      @@db[:peticion_tutoria].where(:id_profesor => @id_telegram, :dia_semana_hora => peticion.tutoria.fecha)
        .insert(:id_profesor => @id_telegram, :dia_semana_hora => peticion.tutoria.fecha, :id_estudiante => peticion.estudiante.id_telegram, :hora_solicitud => Time.new.strftime("%Y-%m-%d %H:%M:%S"), :estado => "por aprobar")
    rescue  Sequel::ForeignKeyConstraintViolation, Sequel::UniqueConstraintViolation => boom
      aceptada=false

    end
    return aceptada
  end

  def obtener_tutorias
      tutorias=Array.new
      datos_tutorias=@@db[:tutoria].where(:id_profesor => @id_telegram).to_a
      datos_tutorias.each{ |tutoria|
        tutorias << Tutoria.new(self, tutoria[:dia_semana_hora].strftime("%Y-%m-%d %H:%M:%S"))
      }
    return tutorias
  end




  def establecer_nueva_tutoria  tutoria
    puts tutoria.fecha
    puts tutoria.fecha
    existe_tutoria=@@db[:tutoria].where(:id_profesor => @id_telegram, :dia_semana_hora => tutoria.fecha)
    if existe_tutoria.empty?
      @@db[:tutoria].insert(:id_profesor => @id_telegram, :dia_semana_hora => tutoria.fecha)
    end
  end

  def borrar_tutoria tutoria
    @@db[:tutoria].where(:id_profesor => @id_telegram, :dia_semana_hora => tutoria.fecha).delete
  end

end

require_relative 'tutoria'
