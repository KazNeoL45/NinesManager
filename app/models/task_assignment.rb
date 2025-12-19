class TaskAssignment < ApplicationRecord
  belongs_to :task
  belongs_to :user

  validates :user_id, uniqueness: { scope: :task_id }
  validate :user_must_be_project_member_or_owner

  private

  def user_must_be_project_member_or_owner
    return if user.nil? || task.nil?
    unless task.project.user_id == user.id || task.project.members.include?(user)
      errors.add(:user_id, "must be a project member or owner")
    end
  end
end

