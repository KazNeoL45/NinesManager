class Project < ApplicationRecord
  belongs_to :user
  has_many :project_members, dependent: :destroy
  has_many :members, through: :project_members, source: :user
  has_many :tasks, dependent: :destroy
  has_many :boards, dependent: :destroy
  has_many :documents, dependent: :destroy

  validates :name, presence: true

  after_create :create_default_board

  def assignable_users
    user_ids = [user_id]
    member_ids = members.pluck(:id)
    user_ids += member_ids unless member_ids.empty?
    User.where(id: user_ids.uniq)
  end

  private

  def create_default_board
    board = boards.create!(name: 'Main Board')
    board.columns.create!([
      { name: 'To Do', position: 1 },
      { name: 'In Progress', position: 2 },
      { name: 'Done', position: 3 }
    ])
  end
end
