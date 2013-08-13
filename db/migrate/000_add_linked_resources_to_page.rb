class AddLinkedResourcesToPage
  def up(c)
    c.add_column :pages, :linked_resources, :text, :default => ''
  end

  def down(c)
    c.remove_column :pages, :linked_resources
  end
end