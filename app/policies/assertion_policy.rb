class AssertionPolicy < Struct.new(:user, :assertion)
  include PolicyHelpers

  def update?
    editor_without_coi?(user) && belongs_to_action_organization?(user)
  end

  def propose?
    user && belongs_to_action_organization?(user)
  end

  def destroy?
    editor_without_coi?(user) && belongs_to_action_organization?(user)
  end

  def accept?
    editor_without_coi?(user) && assertion.submitter.id != user.id && belongs_to_action_organization?(user)
  end

  def reject?
    editor_without_coi?(user) || assertion.submitter.id == user.id && belongs_to_action_organization?(user)
  end
end
