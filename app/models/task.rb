class Task < ApplicationRecord
  belongs_to :project
  belongs_to :column, optional: true
  belongs_to :user, optional: true
  has_many :task_assignments, dependent: :destroy
  has_many :assignees, through: :task_assignments, source: :user

  PRIORITIES = %w[low medium high urgent]

  validates :title, presence: true
  validates :status, inclusion: { in: %w[todo in_progress done] }, allow_blank: true
  validates :priority, inclusion: { in: PRIORITIES }, allow_blank: true

  before_validation :set_defaults, on: :create
  before_save :sync_status_with_column, if: :column_id_changed?

  scope :recurring, -> { where(recurring: true) }
  scope :non_recurring, -> { where(recurring: false) }
  scope :by_priority, -> { order(Arel.sql("CASE priority WHEN 'urgent' THEN 1 WHEN 'high' THEN 2 WHEN 'medium' THEN 3 WHEN 'low' THEN 4 END")) }

  private

  def set_defaults
    self.status ||= 'todo'
    self.priority ||= 'medium'
    self.recurring ||= false
  end

  def sync_status_with_column
    return unless column

    column_name = column.name.downcase
    if column_name.include?('done')
      self.status = 'done'
    elsif column_name.include?('progress') || column_name.include?('in progress')
      self.status = 'in_progress'
    elsif column_name.include?('todo') || column_name.include?('to do')
      self.status = 'todo'
    end
  end
end
