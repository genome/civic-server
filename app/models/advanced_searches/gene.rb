module AdvancedSearches
  class Gene
    include Base

    def initialize(params)
      @params = params
      @presentation_class = GeneWithStateParamsPresenter
    end

    def model_class
      ::Gene
    end

    private
    def handler_for_field(field)
      default_handler = method(:default_handler).to_proc
      @handlers ||= {
        'id' => default_handler.curry['genes.id'],
        'entrez_id' => default_handler.curry['genes.entrez_id'],
        'name' => default_handler.curry['genes.name'],
        'description' => default_handler.curry['genes.description'],
        'aliases' => default_handler.curry['gene_aliases.name'],
        'variants' => default_handler.curry['variants.name'],
        'suggested_changes_count' => method(:handle_suggested_changes_count),
        'assertion_count' => method(:handle_assertion_count),
      }
      @handlers[field]
    end

    def handle_suggested_changes_count(operation_type, parameters)
      sanitized_status = ActiveRecord::Base.connection.quote(parameters.shift)
      having_clause = comparison(operation_type, 'COUNT(DISTINCT(suggested_changes.id))')

      condition = ::Gene.select('genes.id')
        .joins("LEFT OUTER JOIN suggested_changes ON suggested_changes.moderated_id = genes.id AND suggested_changes.status = #{sanitized_status} AND suggested_changes.moderated_type = 'Gene'")
        .group('genes.id')
        .having(having_clause, *parameters.map(&:to_i)).to_sql

      [
        ["genes.id IN (#{condition})"],
        []
      ]
    end

    def handle_assertion_count(operation_type, parameters)
      query = ::Gene.select('genes.id')
        .joins(:assertions).to_sql

      if operation_type == 'is'
        [
          ["genes.id IN (#{query})"],
          []
        ]
      elsif operation_type == 'is_not'
        [
          ["genes.id NOT IN (#{query})"],
          []
        ]
      end
    end
  end
end
