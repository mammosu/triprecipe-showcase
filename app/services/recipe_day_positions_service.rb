class RecipeDayPositionsService
  # 正規化: recipe_day に紐づく recipe_steps の position を 1 から順に詰める
  def self.normalize_positions!(recipe_day)
    recipe_day.recipe_steps.order(:position).each.with_index(1) do |item, index|
      next if item.position == index

      item.update_column(:position, index)
    end
  end
end
