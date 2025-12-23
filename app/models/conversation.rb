class Conversation < ApplicationRecord
  has_many :conversation_participants, dependent: :destroy
  has_many :participants, through: :conversation_participants, source: :user
  has_many :messages, dependent: :destroy

  def other_participant(current_user)
    participants.where.not(id: current_user.id).first
  end

  def last_message
    messages.order(created_at: :desc).first
  end

  def unread_count_for(user)
    participant = conversation_participants.find_by(user: user)
    return 0 unless participant
    
    last_read = participant.last_read_at || 1.year.ago
    messages.where('created_at > ?', last_read).where.not(user: user).count
  end
end

