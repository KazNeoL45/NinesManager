class ProjectMemberPolicy < ApplicationPolicy
  def create?
    project_owner_and_admin?
  end

  def destroy?
    project_owner_and_admin?
  end

  private

  def project_owner_and_admin?
    record.project.user_id == user.id && user.admin?
  end
end

