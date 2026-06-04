class AddChattableToChats < ActiveRecord::Migration[8.1]
  def change
    # polymorphic: true generates two columns + a composite index:
    #   chattable_type (string), chattable_id (bigint),
    #   index on [chattable_type, chattable_id].
    # null: true keeps standalone/owner-less chats valid (a polymorphic ref
    # can't carry a DB foreign-key constraint anyway, since it spans tables).
    add_reference :chats, :chattable, polymorphic: true, null: true
  end
end
