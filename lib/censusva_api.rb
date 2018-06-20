require 'csv'
class CensusvaApi

	def call( document_type, document_number, postal_code )
		response = nil

		nonce = 18.times.map{rand(10)}.join	
		response = Response.new( get_response_body( document_type, document_number, nonce, postal_code ), nonce )

		return response
	end

	class Response

		def initialize( body, nonce )

			@data = Nokogiri::XML (Nokogiri::XML(body).at_css("servicioReturn"))
			@nonce = nonce

		end

		def valid?
			return (exito == "-1") && (response_nonce==@nonce) && (is_habitante == "-1")
		end

		def exito
			@data.at_css("exito").content
		end

		def response_nonce
			@data.at_css("nonce").content
		end

#		def postal_code
#			Base64.decode64 (@data.at_css("codigoPostal").content)
#		end

		def is_habitante
			@data.at_css("isHabitante").content
		end

		def date_of_birth
			@data.at_css("fechaNacimiento").content
		end
		
#		def document_number
#			Base64.decode64 (@data.at_css("documento").content)
#		end
	end

	private


	def codificar( origen )
		Digest::SHA512.base64digest( origen )
	end

	def cod64 (entrada)
		Base64.encode64( entrada ).delete("\n")
	end

	def get_response_body( document_type, document_number, nonce, postal_code )

		fecha = Time.now.strftime("%Y%m%d%H%M%S")

		origen = nonce + fecha + Rails.application.secrets.padron_public_key
		token = codificar( origen )
		if Rails.application.secrets.padron_entity == 999
			padrones = CSV.read(Rails.application.secrets.padrones_route, { encoding: "UTF-8", headers: true, header_converters: :symbol, converters: :all})
			encontrados = padrones.select {|Entity| Entity["CP"] = postal_code }
			resultado = false
			for entityCode in encontrados
				if resultado == false
					peticion= "<?xml version=\"1.0\" encoding=\"utf-8\"?>"
					peticion += "<SOAP-ENV:Envelope xmlns:SOAP-ENV=\"http://schemas.xmlsoap.org/soap/envelope/\" SOAP-ENV:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\">"
					peticion += "<SOAP-ENV:Body>"
					peticion += "<m:servicio xmlns:m=\""+Rails.application.secrets.padron_host+"\">"
					peticion += "<sml>"

					peticion += Rack::Utils.escape_html("<E>\n\t<OPE>\n\t\t<APL>PAD</APL>\n\t\t<TOBJ>HAB</TOBJ>\n\t\t<CMD>ISHABITANTE</CMD>\n\t\t<VER>2.0</VER>\n\t</OPE>\n\t<SEC>\n\t\t<CLI>ACCEDE</CLI>\n\t\t<ORG>"+entityCode+"</ORG>\n\t\t<ENT>"+entityCode+"</ENT>\n\t\t<USU>"+Rails.application.secrets.padron_host+"</USU>\n\t\t<PWD>" + Rails.application.secrets.padron_password + "</PWD>\n\t\t<FECHA>" + fecha + "</FECHA>\n\t\t<NONCE>" + nonce + "</NONCE>\n\t\t<TOKEN>" + token + "</TOKEN>\n\t</SEC>\n\t<PAR>\n\t\t<nia></nia>\n\t\t<codigoTipoDocumento>" + document_type + "</codigoTipoDocumento>\n\t\t<documento>" + cod64(document_number) + "</documento>\n\t\t<mostrarFechaNac>-1</mostrarFechaNac>\n\t</PAR>\n</E>")
		
					peticion += "</sml>"
					peticion += "</m:servicio>"
					peticion += "</SOAP-ENV:Body></SOAP-ENV:Envelope>"


					respuesta = RestClient.post( Rails.application.secrets.padron_host, peticion,  {:content_type => "text/xml; charset=utf-8", :SOAPAction => Rails.application.secrets.padron_host } )
					if respuesta.exito == "-1" && respuesta.is_habitante == "-1"
						resultado = true
					end
				end
			end
		else
			peticion= "<?xml version=\"1.0\" encoding=\"utf-8\"?>"
			peticion += "<SOAP-ENV:Envelope xmlns:SOAP-ENV=\"http://schemas.xmlsoap.org/soap/envelope/\" SOAP-ENV:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\">"
			peticion += "<SOAP-ENV:Body>"
			peticion += "<m:servicio xmlns:m=\""+Rails.application.secrets.padron_host+"\">"
			peticion += "<sml>"

			peticion += Rack::Utils.escape_html("<E>\n\t<OPE>\n\t\t<APL>PAD</APL>\n\t\t<TOBJ>HAB</TOBJ>\n\t\t<CMD>ISHABITANTE</CMD>\n\t\t<VER>2.0</VER>\n\t</OPE>\n\t<SEC>\n\t\t<CLI>ACCEDE</CLI>\n\t\t<ORG>"+Rails.application.secrets.padron_host+"</ORG>\n\t\t<ENT>"+Rails.application.secrets.padron_host+"</ENT>\n\t\t<USU>"+Rails.application.secrets.padron_host+"</USU>\n\t\t<PWD>" + Rails.application.secrets.padron_password + "</PWD>\n\t\t<FECHA>" + fecha + "</FECHA>\n\t\t<NONCE>" + nonce + "</NONCE>\n\t\t<TOKEN>" + token + "</TOKEN>\n\t</SEC>\n\t<PAR>\n\t\t<nia></nia>\n\t\t<codigoTipoDocumento>" + document_type + "</codigoTipoDocumento>\n\t\t<documento>" + cod64(document_number) + "</documento>\n\t\t<mostrarFechaNac>-1</mostrarFechaNac>\n\t</PAR>\n</E>")
		
			peticion += "</sml>"
			peticion += "</m:servicio>"
			peticion += "</SOAP-ENV:Body></SOAP-ENV:Envelope>"


			respuesta = RestClient.post( Rails.application.secrets.padron_host, peticion,  {:content_type => "text/xml; charset=utf-8", :SOAPAction => Rails.application.secrets.padron_host } )
		end

		respuesta
	end
end