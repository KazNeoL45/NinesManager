class ProjectMember < ApplicationRecord
  belongs_to :project
  belongs_to :user

  validates :role, inclusion: { in: %w[admin editor viewer] }
  validates :user_id, uniqueness: { scope: :project_id }

  before_validation :set_default_role, on: :create

  private

  def set_default_role
    self.role ||= 'editor'
  end
end
