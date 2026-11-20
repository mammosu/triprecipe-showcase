require "rails_helper"

RSpec.describe RecipeStep, type: :model do
  it "保持されるべき位置が重複せず 1..n となる（同時リオーダー）" do
    user = User.create!(email: "concurrent@example.com", password: "password123", password_confirmation: "password123")
    recipe = Recipe.create!(title: "並行テスト", user: user, public: true)
    recipe_day = RecipeDay.create!(title: "1日目", recipe: recipe, day_order: 1)

    items = (1..5).map do |i|
      RecipeStep.create!(recipe_day: recipe_day, title: "item#{i}", starts_at: Time.zone.now + i.hours, position: i)
    end

    # 同時開始のシグナル用キュー
    start_signal = Queue.new

    exceptions = []

    t1 = Thread.new do
      ActiveRecord::Base.connection_pool.with_connection do
        begin
          start_signal.pop
          items[1].reload.move_up! # pos 2 -> 1
        rescue => e
          # store full message for debugging in test output
          exceptions << e.full_message
        end
      end
    end

    t2 = Thread.new do
      ActiveRecord::Base.connection_pool.with_connection do
        begin
          start_signal.pop
          items[2].reload.move_up! # pos 3 -> 2
        rescue => e
          exceptions << e
        end
      end
    end

    # 同時開始
    start_signal << true
    start_signal << true

    t1.join
    t2.join

    # 例外が発生していれば失敗として報告（テスト目的で現状の安定性を確認）
    expect(exceptions).to be_empty, "例外が発生しました: #{exceptions.join("\n----\n") }"

    positions = RecipeStep.where(recipe_day: recipe_day).order(:id).pluck(:position).sort
    expect(positions).to eq((1..5).to_a)
  end
end
