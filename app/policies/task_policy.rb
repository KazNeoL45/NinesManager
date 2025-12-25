class TaskPolicy < ApplicationPolicy
  def index?
    project_accessible?
  end

  def show?
    project_accessible?
  end

  def create?
    project_accessible?
  end

  def update?
    project_accessible?
  end

  def destroy?
    project_accessible?
  end

  def move?
    update?
  end

  def remove_document?
    update?
  end

  private

  def project_accessible?
    record.project.user_id == user.id || record.project.members.include?(user)
  end
end
