class ConversationsController < ApplicationController
  before_action :set_conversation, only: [:show]

  def index
    @conversations = current_user.conversations.includes(:participants, messages: :user)
      .order(updated_at: :desc)
    @available_users = User.where.not(id: current_user.id).order(:name).includes(:conversation_participants)
  end

  def show
    @conversations = current_user.conversations.includes(:participants, messages: :user)
      .order(updated_at: :desc)
    @messages = @conversation.messages.includes(:user).order(created_at: :asc)
    @message = @conversation.messages.build
    @other_participant = @conversation.other_participant(current_user)
    @available_users = User.where.not(id: current_user.id).order(:name)
    
    participant = @conversation.conversation_participants.find_by(user: current_user)
    if participant
      participant.update_column(:last_read_at, Time.current)
    end
  end

  def create
    other_user = User.find(params[:user_id])
    
    if other_user == current_user
      redirect_to conversations_path, alert: 'You cannot start a conversation with yourself.'
      return
    end

    conversation = Conversation.joins(:conversation_participants)
      .where(conversation_participants: { user_id: [current_user.id, other_user.id] })
      .group('conversations.id')
      .having('COUNT(DISTINCT conversation_participants.user_id) = 2')
      .first

    unless conversation
      conversation = Conversation.create!
      ConversationParticipant.create!(conversation: conversation, user: current_user)
      ConversationParticipant.create!(conversation: conversation, user: other_user)
    end
    conversation.reload
    authorize conversation

    redirect_to conversation_path(conversation)
  end

  private

  def set_conversation
    @conversation = current_user.conversations.find(params[:id])
    authorize @conversation
  end
end

