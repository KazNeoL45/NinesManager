class ConversationPolicy < ApplicationPolicy
  def index?
    true
  end

  def show?
    record.participants.include?(user)
  end

  def create?
    true
  end

  class Scope < Scope
    def resolve
      user.conversations
    end
  end
end

