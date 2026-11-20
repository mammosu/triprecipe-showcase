class RecipeUpdateService
  # recipe: Recipe instance
  # params: permitted recipe params hash
  # editor: User who triggers the update (for last_edited_by)
  # returns a hash: { success: bool, recipe: Recipe }
  def self.call(recipe, params, editor: nil)
    recipe.assign_attributes(params)
    if editor
      recipe.last_edited_by = editor
      recipe.last_edited_by_email = editor.email
    end

    success = recipe.save

    { success: success, recipe: recipe }
  end
end
