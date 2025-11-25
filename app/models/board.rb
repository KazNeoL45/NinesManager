class Board < ApplicationRecord
  belongs_to :project
  has_many :columns, dependent: :destroy

  validates :name, presence: true
end
