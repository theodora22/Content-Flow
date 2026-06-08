class CreateTwitterPosts < ActiveRecord::Migration[8.1]
  def change
    create_table :twitter_posts do |t|
      t.string :title
      t.text :hook
      t.text :body
      t.references :script, null: false, foreign_key: true

      t.timestamps
    end
  end
end
