class AddUserIdAndIdeaIdToGeneratedIdeas < ActiveRecord::Migration[8.1]
  def change
    # Clear any orphaned rows before adding the NOT NULL foreign key.
    # generated_ideas had no user_id column previously so all rows are orphaned.
    execute "DELETE FROM generated_ideas"

    add_reference :generated_ideas, :user, null: false, foreign_key: true
    # idea_id is nullable — a saved feed card may not have a parent idea yet.
    add_reference :generated_ideas, :idea, null: true, foreign_key: true
  end
end
