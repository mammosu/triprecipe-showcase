# 広域レシピの扱い

入力欄の仕様上、都市候補を選ばずに `city_display` へ自由入力するだけでレシピは保存できます（`Recipe` は `City` への関連が任意で、都市名は長さだけチェックされる設計です）。UI も「都市名を入力すると候補が表示され、候補にない場合はそのまま保存できる」と明示しているので、まずは「日本（全国）」「イタリア周遊」などをそのまま記入すれば OK です。`app/models/recipe.rb:9` `app/models/recipe.rb:21` `app/views/recipes/_form.html.erb:42`

自由入力だけでもレシピ名・スラッグ・表示ラベルには反映されます。`city_label` は `city_display` を優先し、スラッグもタイトル＋入力した地名で生成されるため、「Japan-trip」などの URL が自動で付きます。これにより、国全体を扱う記事でも一貫したリンクと表示文言を維持できます。`app/models/recipe.rb:93` `app/services/recipe_slug_service.rb:5`

将来的に「日本」「イタリア」を一覧や検索でフィルタしたい場合は、国レベルを表す `City` レコードを追加する運用にしてください。`City.match_by_alias` は別名を配列で持てるので、`aliases: ["日本","にほん","Japan","JPN"]` のように登録しておけば、作成フォームに自由入力しても自動でその `city_id` と紐づきます。種データは `db/seeds.rb` の `city_templates` を増やすだけで反映でき、オートコンプリートや表示名にも即座に出てきます。`app/models/recipe.rb:164` `app/models/city.rb:14` `app/models/city.rb:22` `app/models/city.rb:42` `db/seeds.rb:10`

公開ギャラリーの絞り込みは `city_id` ベースなので、国レベルでのフィルタを有効にしたいときは上記のように `City` レコードを用意するのが必須です。どうしても未登録の自由入力だけで運用する場合は、「都市で絞り込み」を「その他（未設定）」で探す運用になります。`app/services/recipe_index_service.rb:35` `app/views/recipes/index.html.erb:128`

補足として、`City` は JSON の `aliases` を無制限に持てるので、「日本全土」「全土（Japan）」のような呼び方をすべて列挙しておくと入力揺れを吸収できます。今後エリア階層が増える場合も、まずは `City` テーブルに「country」や「region」を表すレコードを追加するだけで MVP を保てるため、拡張してから新しいモデルを切る流れがおすすめです。`app/models/city.rb:2` `app/models/city.rb:18`
