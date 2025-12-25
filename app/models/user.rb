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
  has_many :conversation_participants, dependent: :destroy
  has_many :conversations, through: :conversation_participants
  has_many :messages, dependent: :destroy

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

  def online?
    return false unless last_seen_at
    last_seen_at > 5.minutes.ago
  end

  def away?
    return false unless last_seen_at
    last_seen_at > 30.minutes.ago && last_seen_at <= 5.minutes.ago
  end

  def status
    if online?
      'online'
    elsif away?
      'away'
    else
      'offline'
    end
  end

  private

  def set_default_role
    self.role ||= 'editor'
  end
end
