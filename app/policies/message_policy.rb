class MessagePolicy < ApplicationPolicy
  def create?
    record.conversation.participants.include?(user)
  end

  def destroy?
    record.user == user
  end

  class Scope < Scope
    def resolve
      scope.all
    end
  end
end

