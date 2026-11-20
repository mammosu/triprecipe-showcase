class RecipeCreateService
  # params: permitted recipe params hash
  # returns a hash: { success: bool, recipe: Recipe }
  def self.call(user, params)
    recipe = user.recipes.build(params)
    recipe.last_edited_by = user
    recipe.last_edited_by_email = user.email

    success = recipe.save

    { success: success, recipe: recipe }
  end
end
