class Column < ApplicationRecord
  belongs_to :board
  has_many :tasks, dependent: :nullify

  validates :name, presence: true
  validates :position, presence: true, numericality: { only_integer: true }

  default_scope { order(position: :asc) }
end
