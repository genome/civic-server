class AddAlleleRegistryIdToVariant < ActiveRecord::Migration[4.2]
  def up
    add_column :variants, :allele_registry_id, :text, null: true, index: true

    UpdateAlleleRegistryIds.perform_now
  end

  def down
    remove_column :variants, :allele_registry_id
  end
end
