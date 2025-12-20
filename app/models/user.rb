class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :confirmable

  has_many :owned_projects, class_name: 'Project', dependent: :destroy
  has_many :project_members, dependent: :destroy
  has_many :projects, through: :project_members
  has_many :tasks, dependent: :nullify
  has_many :task_assignments, dependent: :destroy
  has_many :assigned_tasks, through: :task_assignments, source: :task
  has_many :documents, dependent: :destroy

  validates :name, presence: true
  validates :role, inclusion: { in: %w[admin editor viewer] }, allow_blank: true

  before_validation :set_default_role, on: :create

  def admin?
    role == 'admin'
  end

  def editor?
    role == 'editor'
  end

  def viewer?
    role == 'viewer'
  end

  private

  def set_default_role
    self.role ||= 'editor'
  end
end
