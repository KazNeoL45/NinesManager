class Task < ApplicationRecord
  belongs_to :project
  belongs_to :column, optional: true
  belongs_to :user, optional: true

  PRIORITIES = %w[low medium high urgent]

  validates :title, presence: true
  validates :status, inclusion: { in: %w[todo in_progress done] }, allow_blank: true
  validates :priority, inclusion: { in: PRIORITIES }, allow_blank: true

  before_validation :set_defaults, on: :create

  scope :recurring, -> { where(recurring: true) }
  scope :non_recurring, -> { where(recurring: false) }
  scope :by_priority, -> { order(Arel.sql("CASE priority WHEN 'urgent' THEN 1 WHEN 'high' THEN 2 WHEN 'medium' THEN 3 WHEN 'low' THEN 4 END")) }

  private

  def set_defaults
    self.status ||= 'todo'
    self.priority ||= 'medium'
    self.recurring ||= false
  end
end
