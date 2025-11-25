class DocumentPolicy < ApplicationPolicy
  def index?
    project_accessible?
  end

  def show?
    project_accessible?
  end

  def create?
    project_accessible? && (user.admin? || user.editor?)
  end

  def update?
    project_accessible? && (user.admin? || user.editor?)
  end

  def destroy?
    project_accessible? && (user.admin? || user.editor?)
  end

  private

  def project_accessible?
    record.project.user_id == user.id || record.project.members.include?(user)
  end
end
