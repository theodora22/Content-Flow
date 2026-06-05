class AddPurposeToChats < ActiveRecord::Migration[8.1]
  def change
    # A string column (not an integer-backed enum) so the stored value reads as
    # "generate_idea" rather than an opaque 0/1/2 — easier to inspect and decouples
    # the DB from the order of enum keys. No NOT NULL / default: a NULL purpose is a
    # plain free-form chat, so every existing row stays valid and behaves unchanged.
    add_column :chats, :purpose, :string
  end
end
