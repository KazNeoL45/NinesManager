class AddLastReadAtToConversationParticipants < ActiveRecord::Migration[7.1]
  def change
    add_column :conversation_participants, :last_read_at, :datetime
    add_index :conversation_participants, :last_read_at
  end
end
