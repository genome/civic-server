module Importer
  class DiseaseOntologyMirror
    attr_reader :parser, :version

    def initialize(path, version = Time.now.utc.iso8601)
      @parser = Obo::Parser.new(path)
      @version = version
    end

    def import
      parser.elements.each do |elem|
        next unless valid_entry?(elem)
        create_object_from_entry(elem)
      end
    end

    private
    def populate_ontology_entry
      Ontology.where(name: 'disease_ontology').first_or_create.tap do |o|
        o.version = version
        o.import_date = DateTime.now
        o.permalink_format = "http://purl.obolibrary.org/obo/DOID_"
        o.civic_class = 'Disease'
        o.id_name = 'doid'
        o.save
      end
    end

    def valid_entry?(entry)
      entry['id'].present? && entry['name'].present? && entry.respond_to?(:name) && entry.name == 'Term'
    end

    def create_object_from_entry(entry)
      display_name = Disease.capitalize_name(entry['name'])
      name = entry['name']
      doid = parse_doid(entry['id'])
      synonyms = process_synonyms(entry['synonym'])
      disease = if ( d = ::Disease.find_by(doid: doid) )
                  d
                elsif ( d = ::Disease.find_by(name: name) )
                  d
                else ( d = ::Disease.where(doid: doid).first_or_initialize)
                  d
                end
      disease.name = name
      disease.doid = doid
      disease.display_name = display_name
      disease.save
      synonyms.each do |syn|
        disease_alias = ::DiseaseAlias.where(name: syn).first_or_create
        current_aliases = disease.disease_aliases.to_a
        current_aliases << disease_alias
        disease.disease_aliases = current_aliases.uniq
      end
      removed_aliases = disease.disease_aliases.map{|a| a.name} - synonyms
      removed_aliases.each do |a|
        alias_to_remove = DiseaseAlias.find_by(name: a)
        disease.disease_aliases.delete(alias_to_remove)
      end
    end

    def process_synonyms(synonym_element)
      vals = if synonym_element.blank?
        []
      elsif synonym_element.is_a?(String)
        [extract_synonym(synonym_element)]
      elsif synonym_element.is_a?(Array)
        synonym_element.map { |s| extract_synonym(s) }
      end
      vals.compact
    end

    def extract_synonym(value)
      if match_data = value.match(/^"(?<name>.+)" EXACT \[.*\]$/)
        Disease.capitalize_name(match_data[:name])
      else
        nil
      end
    end

    def parse_doid(doid)
      doid.gsub('DOID:', '')
    end
  end
end
