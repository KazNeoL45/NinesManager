class MessagesController < ApplicationController
  before_action :set_conversation
  before_action :set_message, only: [:destroy]

  def create
    @message = @conversation.messages.build(message_params)
    @message.user = current_user
    authorize @message

    if @message.save
      @conversation.touch
      @conversation.conversation_participants.where(user: current_user).update_all(last_read_at: Time.current)
      redirect_to conversation_path(@conversation), notice: 'Message sent successfully.'
    else
      @messages = @conversation.messages.includes(:user).order(created_at: :asc)
      @other_participant = @conversation.other_participant(current_user)
      @conversations = current_user.conversations.includes(:participants, messages: :user).order(updated_at: :desc)
      @available_users = User.where.not(id: current_user.id).order(:name)
      render 'conversations/show', status: :unprocessable_entity
    end
  end

  def destroy
    authorize @message
    @message.destroy
    redirect_to conversation_path(@conversation), notice: 'Message deleted successfully.'
  end

  private

  def set_conversation
    @conversation = current_user.conversations.find(params[:conversation_id])
    authorize @conversation
  end

  def set_message
    @message = @conversation.messages.find(params[:id])
  end

  def message_params
    params.require(:message).permit(:content, attachments: [])
  end
end

