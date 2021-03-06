class VariantGroupPolicy < Struct.new(:user, :variant_group)
  include PolicyHelpers

  def create?
    user.present? && belongs_to_action_organization?(user)
  end

  def destroy?
    editor_without_coi?(user)
  end
end
