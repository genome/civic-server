require 'rbconfig'

class UpdateAlleleRegistryIds < AlleleRegistryIds

  attr_reader :recurring

  after_perform do |job|
    job.reschedule if job.recurring
  end

  def perform(recurring = true)
    @recurring = recurring
    Variant.where.not(allele_registry_id: nil).each do |v|
      old_allele_registry_id = v.allele_registry_id
      allele_registry_id = get_allele_registry_id(v)
      if allele_registry_id != old_allele_registry_id
        v.allele_registry_id = allele_registry_id
        v.save
        add_allele_registry_link(allele_registry_id)
        #delete the linkout if no other variant has this allele registry ID
        if Variant.where(allele_registry_id: old_allele_registry_id).exists?
            delete_allele_registry_link(old_allele_registry_id)
        end
      end
    end
  end

  def reschedule
    self.class.set(wait_until: next_week).perform_later
  end

  def next_week
    Date.today
      .beginning_of_week
      .next_week
      .midnight
  end
end
