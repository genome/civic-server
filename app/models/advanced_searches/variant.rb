module AdvancedSearches
  class Variant
    include Base

    def initialize(params)
      @params = params
      @presentation_class = VariantWithStateParamsPresenter
    end

    def model_class
      ::Variant
    end

    private
    def handler_for_field(field)
      default_handler = method(:default_handler).to_proc
      @handlers ||= {
        'id' => default_handler.curry['variants.id'],
        'name' => default_handler.curry['variants.name'],
        'description' => default_handler.curry['variants.description'],
        'variant_group' => default_handler.curry['variant_groups.name'],
        'ensembl_version' => default_handler.curry['variants.ensembl_version'],
        'reference_build' => method(:handle_reference_build),
        'reference_bases' => default_handler.curry['variants.reference_bases'],
        'variant_bases' => default_handler.curry['variants.variant_bases'],
        'chromosome' => default_handler.curry['variants.chromosome'],
        'start' => default_handler.curry['variants.start'],
        'stop' => default_handler.curry['variants.stop'],
        'representative_transcript' => default_handler.curry['variants.representative_transcript'],
        'chromosome2' => default_handler.curry['variants.chromosome2'],
        'start2' => default_handler.curry['variants.start2'],
        'stop2' => default_handler.curry['variants.stop2'],
        'representative_transcript2' => default_handler.curry['variants.representative_transcript2'],
        'variant_types' => default_handler.curry['variant_types.display_name'],
        'variant_types_soids' => default_handler.curry['variant_types.soid'],
        'hgvs_expressions' => default_handler.curry['hgvs_expressions.expression'],
        'variant_alias' => default_handler.curry['variant_aliases.name'],
        'gene' => default_handler.curry[['genes.name', 'secondary_genes_variants.name']],
        'suggested_changes_count' => method(:handle_suggested_changes_count),
        'evidence_item_count' => method(:handle_evidence_item_count),
        'civic_actionability_score' => default_handler.curry['variants.civic_actionability_score'],
        'pipeline_type' => method(:handle_pipeline_type),
        'allele_registry_id' => default_handler.curry['allele_registry_id'],
        'assertion_count' => method(:handle_assertion_count),
        'disease_name' => method(:handle_disease_name),
        'disease_doid' => method(:handle_disease_doid),
      }
      @handlers[field]
    end

    def handle_reference_build(operation_type, parameters)
      [
        [comparison(operation_type, 'variants.reference_build')],
        ::Variant.reference_builds[parameters.first]
      ]
    end

    def handle_suggested_changes_count(operation_type, parameters)
      sanitized_status = ActiveRecord::Base.connection.quote(parameters.shift)
      having_clause = comparison(operation_type, 'COUNT(DISTINCT(suggested_changes.id))')

      condition = ::Variant.select('variants.id')
        .joins("LEFT OUTER JOIN suggested_changes ON suggested_changes.moderated_id = variants.id AND suggested_changes.status = #{sanitized_status} AND suggested_changes.moderated_type = 'Variant'")
        .group('variants.id')
        .having(having_clause, *parameters.map(&:to_i)).to_sql

      [
        ["variants.id IN (#{condition})"],
        []
      ]
    end

    def handle_evidence_item_count(operation_type, parameters)
      status = parameters.shift
      comparison_operand = case status
                           when 'not rejected'
                             '(accepted_count + submitted_count)'
                           when 'any'
                             '(accepted_count + submitted_count + rejected_count)'
                           when 'accepted'
                             'accepted_count'
                           when 'rejected'
                             'rejected_count'
                           when 'submitted'
                             'submitted_count'
                           end
      where_clause = comparison(operation_type, comparison_operand)

      condition = ::Variant.select('variants.id')
        .joins(:evidence_items_by_status)
        .where(where_clause, *parameters.map(&:to_i))
        .distinct
        .to_sql

      [
        ["variants.id IN (#{condition})"],
        []
      ]
    end

    def handle_pipeline_type(operation_type, parameters)
      type_query = parameters.shift

      condition = ::Variant.select('variants.id')
        .joins(variant_types: [:pipeline_types])

      query = condition.where("pipeline_types.name = ?", type_query).to_sql

      if operation_type == 'is_not'
        [
          ["variants.id NOT IN (#{query})"],
          []
        ]
      else
        [
          ["variants.id IN (#{query})"],
          []
        ]
      end
    end

    def handle_disease_name(operation_type, parameters)
      name_query = parameters.shift

      condition = ::Variant.select('variants.id')
        .joins("INNER JOIN evidence_items ON evidence_items.variant_id = variants.id")
        .joins("INNER JOIN diseases ON evidence_items.disease_id = diseases.id")

      query = case operation_type
        when 'is_equal_to'
          condition.where("diseases.name = ?", name_query).to_sql
        when 'contains'
          condition.where("diseases.name LIKE ?", "%#{name_query}%").to_sql
        when 'begins_with'
          condition.where("diseases.name LIKE ?", "#{name_query}%").to_sql
        when 'is_not'
          condition.where("diseases.name = ?", name_query).to_sql
      end
      query += " AND evidence_items.deleted = 'f'"

      if operation_type == 'is_not'
        [
          ["variants.id NOT IN (#{query})"],
          []
        ]
      else
        [
          ["variants.id IN (#{query})"],
          []
        ]
      end
    end

    def handle_disease_doid(operation_type, parameters)
      doid_query = parameters.shift

      query = ::Variant.select('variants.id')
        .joins(:diseases)
        .where("diseases.doid = ?", doid_query).to_sql

      if operation_type == 'is_not'
        [
          ["variants.id NOT IN (#{query})"],
          []
        ]
      else
        [
          ["variants.id IN (#{query})"],
          []
        ]
      end
    end

    def handle_assertion_count(operation_type, parameters)
      query = ::Variant.select('variants.id')
        .joins(:assertions).to_sql
       if operation_type == 'is'
        [
          ["variants.id IN (#{query})"],
          []
        ]
      elsif operation_type == 'is_not'
        [
          ["variants.id NOT IN (#{query})"],
          []
        ]
      end
    end
  end
end
