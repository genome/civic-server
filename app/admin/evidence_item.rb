ActiveAdmin.register EvidenceItem do
  menu :priority => 3
  permit_params :description, :clinical_significance, :evidence_direction, :rating, :evidence_level, :evidence_type, :variant_origin, :variant, :source_id, :drug_interaction_type, :variant_id, :submitter, :disease_id, drug_ids: [], phenotype_ids: []

  config.sort_order = 'updated_at_desc'

  filter :id
  filter :description
  filter :variant_gene_id, as: :select, collection: ->(){ Gene.order(:name).all }, label: 'Gene'
  filter :variant, as: :select, collection: ->(){ Variant.order(:name).all }
  filter :clinical_significance, as: :select, collection: ->(){ EvidenceItem.clinical_significances }
  filter :rating, as: :select, collection: ->(){ 1..5 }
  filter :evidence_direction, as: :select, collection: ->(){ EvidenceItem.evidence_directions }
  filter :evidence_level, as: :select, collection: ->(){ EvidenceItem.evidence_levels }
  filter :evidence_type, as: :select, collection: ->(){ EvidenceItem.evidence_types }
  filter :variant_origin, as: :select, collection: ->(){ EvidenceItem.variant_origins }
  filter :status, as: :select, collection: ->(){ EvidenceItem.distinct.pluck(:status) }
  filter :drug_interaction_type, as: :select, collection: ->(){ EvidenceItem.drug_interaction_types }
  filter :submitter, as: :select

  controller do
    def scoped_collection
      resource_class.includes(:submitter, variant: [:gene])
    end

    def destroy
      obj = resource_class.find_by!(id: params[:id])
      obj.soft_delete!
      redirect_to admin_evidence_items_path, notice: 'Deleted'
    end
  end

  batch_action :destroy do |ids|
    resource_class.find(ids).each do |obj|
      obj.deleted = true
      obj.save
    end
    redirect_to admin_evidence_items_path, notice: 'Deleted'
  end

  form do |f|
    variants_with_gene_names = Variant.joins(:gene)
      .select('genes.name as gene_name', 'variants.name', 'variants.id')
      .order('gene_name ASC, variants.name ASC')
      .map { |v| [ "#{v.name} (#{v.gene_name})", v.id] }
    f.semantic_errors(*f.object.errors.keys)
    f.inputs do
      f.input :description
      f.input :variant, as: :select, collection: variants_with_gene_names
      f.input :clinical_significance, as: :select, collection: EvidenceItem.clinical_significances.keys, include_blank: false
      f.input :rating, as: :select, collection: 1..5, include_blank: true
      f.input :evidence_direction, as: :select, collection: EvidenceItem.evidence_directions.keys, include_blank: false
      f.input :evidence_level, as: :select, collection: EvidenceItem.evidence_levels.keys, include_blank: false
      f.input :evidence_type, as: :select, collection: EvidenceItem.evidence_types.keys, include_blank: false
      f.input :variant_origin, as: :select, collection: EvidenceItem.variant_origins.keys, include_blank: false
      f.input :disease, collection: Disease.order(:name), include_blank: true
      f.input :drug_interaction_type, as: :select, collection: EvidenceItem.drug_interaction_types.keys, include_blank: true
      f.input :source, collection: Source.order(:description), include_blank: false
      f.input :drugs, collection: Drug.order(:name), include_blank: false
      f.input :phenotypes, collection: Phenotype.order(:hpo_class)
    end
    f.actions
  end

  index do
    selectable_column
    column :gene do |ei|
      ei.variant.gene.name if ei.variant && ei.variant.gene
    end
    column :id
    column :variant
    column :description
    column :clinical_significance
    column :evidence_direction
    column :rating
    column :evidence_level
    column :evidence_type
    column :variant_origin
    column :drug_interaction_type
    column :status
    column :updated_at
    column :created_at
    column 'Submitter', :submitter
    actions
  end

  show do |f|
    attributes_table do
      row :gene do |ei|
        ei.variant.gene.name if ei.variant && ei.variant.gene
      end
      row :id
      row :variant
      row :description
      row :clinical_significance
      row :evidence_direction
      row :evidence_level
      row :evidence_type
      row :variant_origin
      row :drug_interaction_type
      row :rating
      row :status
      row :drugs do |ei|
        ei.drugs.map { |d| d.name }.join(', ')
      end
      row :disease
      row :source do |ei|
        "#{ei.source.try(:description)} (#{ei.source.try(:citation_id)})"
      end
      row :phenotypes do |ei|
        ei.phenotypes.map(&:hpo_class).join(', ')
      end
      row :updated_at
      row :created_at
      row 'submitter' do |ei|
        ei.submitter
      end
    end
  end

  member_action :accept_evidence_item, method: :post do
    resource.accept(current_user)
    redirect_to admin_evidence_item_path(id: resource.id), notice: 'Accepted'
  end

  member_action :reject_evidence_item, method: :post do
    resource.reject(current_user)
    redirect_to admin_evidence_item_path(id: resource.id), notice: 'Rejected'
  end

  member_action :resubmit_evidence_item, method: :post do
    resource.status = 'submitted'
    resource.save
    redirect_to admin_evidence_item_path(id: resource.id), notice: 'Status set to submitted'
  end

  action_item :accept_evidence_item, only: :show do
    if resource.status != 'accepted'
      link_to('Accept Evidence Item', accept_evidence_item_admin_evidence_item_path(resource), method: :post)
    end
  end

  action_item :reject_evidence_item, only: :show do
    if resource.status != 'rejected'
      link_to('Reject Evidence Item', reject_evidence_item_admin_evidence_item_path(resource), method: :post)
    end
  end

  action_item :resubmit_evidence_item, only: :show do
    if resource.status != 'submitted'
      link_to('Resubmit Evidence Item', resubmit_evidence_item_admin_evidence_item_path(resource), method: :post)
    end
  end
end
