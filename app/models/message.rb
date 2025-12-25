class Message < ApplicationRecord
  belongs_to :conversation
  belongs_to :user

  has_many_attached :attachments

  validates :content, presence: true, unless: -> { attachments.attached? }
  validate :attachments_count

  def image?
    attachments.any? { |att| att.content_type&.start_with?('image/') }
  end

  def document?
    attachments.any? { |att| !att.content_type&.start_with?('image/') }
  end

  private

  def attachments_count
    if attachments.count > 10
      errors.add(:attachments, "cannot exceed 10 files")
    end
  end
end

