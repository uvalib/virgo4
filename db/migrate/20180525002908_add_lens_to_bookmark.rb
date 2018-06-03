class AddLensToBookmark < ActiveRecord::Migration[5.2]
  def change
    add_column :bookmarks, :search_lens, :string
  end
end
