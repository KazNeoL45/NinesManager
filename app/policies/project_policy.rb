class ProjectPolicy < ApplicationPolicy
  def index?
    true
  end

  def show?
    user_is_owner_or_member?
  end

  def create?
    user.admin? || user.editor?
  end

  def update?
    user_is_owner? && (user.admin? || user.editor?)
  end

  def destroy?
    user_is_owner? && user.admin?
  end

  private

  def user_is_owner?
    record.user_id == user.id
  end

  def user_is_owner_or_member?
    user_is_owner? || record.members.include?(user)
  end
end
