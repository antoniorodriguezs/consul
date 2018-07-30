class CensusCaller

  def call(document_type, document_number, postal_code)
    response = CensusvaApi.new.call(document_type, document_number, postal_code)
    response = LocalCensus.new.call(document_type, document_number) unless response.valid?

    response
  end
end
