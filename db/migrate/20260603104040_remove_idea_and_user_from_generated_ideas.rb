class RemoveIdeaAndUserFromGeneratedIdeas < ActiveRecord::Migration[8.1]
  def change
    remove_reference :generated_ideas, :idea, null: false, foreign_key: true
    remove_reference :generated_ideas, :user, null: false, foreign_key: true
  end
end
