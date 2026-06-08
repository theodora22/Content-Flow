class Message < ApplicationRecord
  acts_as_message
  has_many_attached :attachments

  broadcasts_to ->(message) { "chat_#{message.chat_id}" }, inserts_by: :append

end
