class AddLensToBookmark < ActiveRecord::Migration[5.2]
  def change
    add_column :bookmarks, :lens, :string
  end
end
