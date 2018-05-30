class CensusvaApi

	def call( document_type, document_number )
		response = nil	
		response = Response.new( get_response_body( document_type, document_number ) )

		return response
	end

	class Response
		def initialize( body )

			@data = Nokogiri::XML( body )

		end

		def valid?
			return (exito == "-1") && (numero_habitantes == "1")
		end

		def exito
			@data.at_css("exito").content
		end

		def numero_habitantes
			@data.at_css("numeroHabitantes").content
		end

		def postal_code
			@data.at_css("codigoPostal").content
		end

		def date_of_birth
			@data.at_css("fechaNacimiento").content
		end
		
		def document_number
			@data.at_css("documento").content
		end
	end

	private


	def codificar( origen )
		Digest::SHA512.base64digest( origen )
	end

	def get_response_body( document_type, document_number )

		fecha = Time.now.strftime("%Y%m%d%H%M%S")
		nonce = 18.times.map{rand(10)}.join

		origen = nonce + fecha + Rails.application.secrets.padron_public_key
		token = codificar( origen )

		respuesta = RestClient.post( Rails.application.secrets.padron_host, "<E>\n <OPE>\n\t <APL>PAD</APL>\n\t <TOBJ>HAB</TOBJ>\n\t <CMD>CONSULTAESTADO</CMD>\n\t <VER>2.0</VER>\n </OPE>\n <SEC>\n\t <CLI>ACCEDE</CLI>\n\t <ORG>0</ORG>\n\t <ENT>"+ Rails.application.secrets.padron_entity +"</ENT>\n\t <USU>"+ Rails.application.secrets.padron_user +"</USU>\n\t <PWD>" + Rails.application.secrets.padron_password + "</PWD>\n\t <FECHA>" + fecha + "</FECHA>\n\t <NONCE>" + nonce + "</NONCE>\n\t <TOKEN>" + token + "</TOKEN>\n </SEC>\n <PAR>\n\t <codigoTipoDocumento>" + document_type + "</codigoTipoDocumento>\n\t <documento>" + document_number + "</documento>\n\t <nombre></nombre>\n\t <particula1></particula1>\n\t <apellido1></apellido1>\n\t <particula2></particula2>\n\t <apellido2></apellido2>\n\t <fechaNacimiento></fechaNacimiento>\n\t <busquedaExacta>-1</busquedaExacta>\n </PAR>\n</E>",  {:content_type => :xml} )

		Logger.new(STDOUT).info( respuesta )

		respuesta
	end
end
