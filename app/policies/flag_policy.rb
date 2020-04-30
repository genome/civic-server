class FlagPolicy < Struct.new(:user, :flag)
  include PolicyHelpers

  def create?
    user && belongs_to_action_organization?(user)
  end

  def update?
    (flag.flagging_user == user || editor_without_coi?(user))
  end
end
