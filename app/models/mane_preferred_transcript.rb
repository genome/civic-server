class ManePreferredTranscript
  attr_reader :variant

  def initialize(variant_id)
    @variant = Variant.find(variant_id)
  end

  def mane_preferred_transcript
    Rails.cache.fetch(cache_key(variant), expires_in: 24.hours) do
      if mane_preferred_ref_seq = get_mane_preferred_ref_seq(variant)
        transcripts = get_allele_registry_transcripts(variant)
        transcripts.find{ |t| t['hgvs'][0].start_with?(mane_preferred_ref_seq) }
      end
    end
  end

  def get_allele_registry_transcripts(variant)
    allele_response = make_allele_request(variant.allele_registry_id)
    JSON.parse(allele_response)['transcriptAlleles']
  end

  def get_mane_preferred_ref_seq(variant)
    gene_response = make_gene_request(variant.gene.name)
    JSON.parse(gene_response)[0]['externalRecords']['MANEPrefRefSeq']['id'] rescue nil
  end

  private
  def make_gene_request(gene_name)
    Scrapers::Util.make_get_request(gene_url(gene_name))
  rescue StandardError
    '{}'
  end

  def make_allele_request(allele_registry_id)
    Scrapers::Util.make_get_request(allele_url(allele_registry_id))
  rescue StandardError
    '{}'
  end

  def gene_url(gene_name)
    URI.encode("http://reg.genome.network/genes?name=#{gene_name}")
  end

  def allele_url(allele_registry_id)
    URI.encode("http://reg.genome.network/allele/#{allele_registry_id}")
  end

  def cache_key(variant)
    "mane_preferred_transcript_#{variant.id}_#{variant.hash}"
  end
end
