# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end
require_relative "seeds/cities"

def ensure_tags!
  tags = [
    { key: "family", label_ja: "子連れ", position: 1 },
    { key: "rainy", label_ja: "雨の日", position: 2 },
    { key: "budget", label_ja: "節約", position: 3 },
    { key: "walkable", label_ja: "徒歩中心", position: 4 },
    { key: "museum", label_ja: "美術館・博物館", position: 5 },
    { key: "food", label_ja: "グルメ中心", position: 6 },
    { key: "short", label_ja: "半日/日帰り", position: 7 }
  ]

  Tag.upsert_all(
    tags.map { |attrs| attrs.merge(active: true) },
    unique_by: :key
  )
end

ensure_tags!

if Rails.env.development?
  def parse_time_of_day(value)
    return if value.blank?

    (Time.zone || Time).parse(value)
  end

  def ensure_recipe_with_details!(data)
    plan = Recipe.find_or_initialize_by(title: data[:title], user: data[:user])
    city_value = data[:city_display] || data[:city]
    plan.assign_attributes(
      city_display: city_value,
      days_count: data[:days]&.size || data[:days_count],
      description: data[:description],
      public: true
    )
    plan.save!

    Array(data[:days]).each_with_index do |day_data, index|
      recipe_day = plan.recipe_days.find_or_initialize_by(day_order: index + 1)
      recipe_day.title = day_data[:title]
      recipe_day.notes = day_data[:notes]
      recipe_day.starts_on = day_data[:starts_on]
      recipe_day.save!

      Array(day_data[:recipe_steps]).each_with_index do |item_data, position|
        recipe_step = recipe_day.recipe_steps.find_or_initialize_by(position: position + 1)
        recipe_step.title = item_data[:title]
        recipe_step.category = item_data[:category] || "activity"
        recipe_step.starts_at = parse_time_of_day(item_data[:starts_at])
        recipe_step.ends_at = parse_time_of_day(item_data[:ends_at])
        recipe_step.notes = item_data[:notes]
        recipe_step.save!
      end
    end
  end

  current_year = Date.current.year

  # Create sample users
  user1 = User.find_or_create_by!(email: "alice@example.com") do |u|
    u.password = "password123"
    u.password_confirmation = "password123"
  end

  user2 = User.find_or_create_by!(email: "bob@example.com") do |u|
    u.password = "password123"
    u.password_confirmation = "password123"
  end

  user3 = User.find_or_create_by!(email: "carol@example.com") do |u|
    u.password = "password123"
    u.password_confirmation = "password123"
  end

  # Create sample recipes with days and recipe steps
  plans_data = [
    {
      title: "東京3日間の旅",
      city_display: "東京",
      description: "浅草、スカイツリー、お台場を巡る旅",
      user: user1,
      days: [
        {
          title: "1日目: 浅草と下町散策",
          notes: "浅草寺とスカイツリーで東京の定番を満喫",
          starts_on: Date.new(current_year, 5, 10),
          recipe_steps: [
            { title: "羽田空港に到着", category: "move", starts_at: "09:00", ends_at: "10:00", notes: "京急で浅草へ" },
            { title: "浅草寺と仲見世散策", category: "activity", starts_at: "10:30", ends_at: "12:30", notes: "人形焼をお土産に" },
            { title: "雷門周辺でもんじゃランチ", category: "food", starts_at: "13:00", ends_at: "14:00" }
          ]
        },
        {
          title: "2日目: スカイツリーとお台場",
          notes: "展望台と夜景スポットをはしご",
          starts_on: Date.new(current_year, 5, 11),
          recipe_steps: [
            { title: "ソラマチで朝食", category: "food", starts_at: "09:00", ends_at: "10:00" },
            { title: "東京スカイツリー展望台", category: "activity", starts_at: "10:00", ends_at: "12:00" },
            { title: "お台場で夜景散歩", category: "activity", starts_at: "19:00", ends_at: "21:00" }
          ]
        },
        {
          title: "3日目: カフェでゆったり",
          notes: "谷中の古民家カフェで締め",
          starts_on: Date.new(current_year, 5, 12),
          recipe_steps: [
            { title: "清澄白河でコーヒー", category: "food", starts_at: "10:00", ends_at: "11:00" },
            { title: "谷中銀座を散歩", category: "activity", starts_at: "12:00", ends_at: "14:00" }
          ]
        }
      ]
    },
    {
      title: "京都の寺社巡り",
      city_display: "京都",
      description: "金閣寺、清水寺、伏見稲荷大社を訪問",
      user: user2,
      days: [
        {
          title: "1日目: 北山エリア",
          notes: "金閣寺からスタート",
          starts_on: Date.new(current_year, 4, 15),
          recipe_steps: [
            { title: "金閣寺を拝観", category: "activity", starts_at: "09:30", ends_at: "11:00" },
            { title: "嵐山で湯豆腐ランチ", category: "food", starts_at: "12:00", ends_at: "13:00" },
            { title: "竹林散策", category: "activity", starts_at: "13:00", ends_at: "15:00" }
          ]
        },
        {
          title: "2日目: 東山の名所",
          notes: "清水寺と祇園",
          starts_on: Date.new(current_year, 4, 16),
          recipe_steps: [
            { title: "清水寺で朝拝", category: "activity", starts_at: "08:00", ends_at: "10:00" },
            { title: "祇園で抹茶スイーツ", category: "food", starts_at: "11:00", ends_at: "12:00" },
            { title: "八坂神社と円山公園", category: "activity", starts_at: "12:30", ends_at: "14:30" }
          ]
        },
        {
          title: "3日目: 伏見稲荷と伏見の町",
          notes: "千本鳥居と酒蔵めぐり",
          starts_on: Date.new(current_year, 4, 17),
          recipe_steps: [
            { title: "伏見稲荷の千本鳥居", category: "activity", starts_at: "07:00", ends_at: "09:00" },
            { title: "伏見の酒蔵見学", category: "activity", starts_at: "11:00", ends_at: "13:00" },
            { title: "京料理ランチ", category: "food", starts_at: "13:30", ends_at: "14:30" }
          ]
        },
        {
          title: "4日目: 雑貨とカフェ",
          notes: "河原町でショッピング",
          starts_on: Date.new(current_year, 4, 18),
          recipe_steps: [
            { title: "鴨川沿いを散歩", category: "activity", starts_at: "09:00", ends_at: "10:00" },
            { title: "町家カフェで朝食", category: "food", starts_at: "10:30", ends_at: "11:30" }
          ]
        }
      ]
    },
    {
      title: "大阪グルメツアー",
      city_display: "大阪",
      description: "たこ焼き、お好み焼き、串カツを食べ歩き",
      user: user1,
      days: [
        {
          title: "1日目: 道頓堀食べ歩き",
          notes: "粉もんを制覇",
          starts_on: Date.new(current_year, 6, 2),
          recipe_steps: [
            { title: "なんばでたこ焼き", category: "food", starts_at: "11:00", ends_at: "12:00" },
            { title: "心斎橋ショッピング", category: "activity", starts_at: "12:30", ends_at: "14:00" },
            { title: "串カツだるまで夕食", category: "food", starts_at: "18:00", ends_at: "19:00" }
          ]
        },
        {
          title: "2日目: 大阪城とカフェ",
          notes: "歴史とカフェ巡り",
          starts_on: Date.new(current_year, 6, 3),
          recipe_steps: [
            { title: "大阪城公園を散歩", category: "activity", starts_at: "09:00", ends_at: "11:00" },
            { title: "中之島カフェで休憩", category: "food", starts_at: "14:00", ends_at: "15:00" }
          ]
        }
      ]
    },
    {
      title: "北海道自然の旅",
      city_display: "札幌",
      description: "富良野、美瑛、旭川動物園を訪れる",
      user: user3,
      days: [
        {
          title: "1日目: 札幌市内観光",
          starts_on: Date.new(current_year, 7, 5),
          notes: "大通公園と市場",
          recipe_steps: [
            { title: "二条市場で海鮮丼", category: "food", starts_at: "09:00", ends_at: "10:00" },
            { title: "大通公園を散歩", category: "activity", starts_at: "10:30", ends_at: "12:00" }
          ]
        },
        {
          title: "2日目: 富良野ラベンダー",
          starts_on: Date.new(current_year, 7, 6),
          notes: "ファーム富田を訪問",
          recipe_steps: [
            { title: "札幌から富良野へ移動", category: "move", starts_at: "08:00", ends_at: "11:00" },
            { title: "ラベンダー畑散策", category: "activity", starts_at: "11:30", ends_at: "13:00" }
          ]
        },
        {
          title: "3日目: 美瑛と旭川",
          starts_on: Date.new(current_year, 7, 7),
          notes: "青い池と旭山動物園",
          recipe_steps: [
            { title: "美瑛 青い池", category: "activity", starts_at: "09:00", ends_at: "10:30" },
            { title: "旭山動物園", category: "activity", starts_at: "12:00", ends_at: "15:00" }
          ]
        }
      ]
    },
    {
      title: "沖縄リゾート",
      city_display: "那覇",
      description: "美ら海水族館、首里城、離島巡り",
      user: user2,
      days: [
        {
          title: "1日目: 那覇の伝統文化",
          starts_on: Date.new(current_year, 3, 20),
          notes: "首里城と市場",
          recipe_steps: [
            { title: "首里城を見学", category: "activity", starts_at: "09:00", ends_at: "11:00" },
            { title: "国際通りでソーキそば", category: "food", starts_at: "12:00", ends_at: "13:00" }
          ]
        },
        {
          title: "2日目: 美ら海水族館",
          starts_on: Date.new(current_year, 3, 21),
          notes: "北部ドライブ",
          recipe_steps: [
            { title: "那覇から北部へ移動", category: "move", starts_at: "08:00", ends_at: "10:00" },
            { title: "美ら海水族館", category: "activity", starts_at: "10:00", ends_at: "13:00" }
          ]
        },
        {
          title: "3日目: 離島ビーチ",
          starts_on: Date.new(current_year, 3, 22),
          notes: "渡嘉敷島でのんびり",
          recipe_steps: [
            { title: "高速船で渡嘉敷島へ", category: "move", starts_at: "09:00", ends_at: "10:00" },
            { title: "阿波連ビーチで海水浴", category: "activity", starts_at: "10:30", ends_at: "14:00" }
          ]
        }
      ]
    },
    {
      title: "広島平和学習",
      city_display: "広島",
      description: "原爆ドーム、平和記念公園、宮島",
      user: user1,
      days: [
        {
          title: "1日目: 平和学習",
          starts_on: Date.new(current_year, 10, 5),
          notes: "原爆資料館中心",
          recipe_steps: [
            { title: "平和記念資料館", category: "activity", starts_at: "10:00", ends_at: "12:00" },
            { title: "お好み村でランチ", category: "food", starts_at: "12:30", ends_at: "13:30" }
          ]
        },
        {
          title: "2日目: 宮島観光",
          starts_on: Date.new(current_year, 10, 6),
          notes: "厳島神社と弥山",
          recipe_steps: [
            { title: "宮島へフェリー移動", category: "move", starts_at: "08:30", ends_at: "09:00" },
            { title: "厳島神社参拝", category: "activity", starts_at: "09:00", ends_at: "11:00" },
            { title: "もみじ饅頭休憩", category: "food", starts_at: "11:30", ends_at: "12:00" }
          ]
        }
      ]
    },
    {
      title: "福岡温泉旅行",
      city_display: "福岡",
      description: "太宰府天満宮と由布院温泉",
      user: user3,
      days: [
        {
          title: "1日目: 太宰府参拝",
          starts_on: Date.new(current_year, 11, 12),
          notes: "学問の神様にご挨拶",
          recipe_steps: [
            { title: "太宰府天満宮参拝", category: "activity", starts_at: "10:00", ends_at: "11:30" },
            { title: "梅ヶ枝餅を食べ歩き", category: "food", starts_at: "11:30", ends_at: "12:30" }
          ]
        },
        {
          title: "2日目: 由布院温泉",
          starts_on: Date.new(current_year, 11, 13),
          notes: "金鱗湖散策と温泉",
          recipe_steps: [
            { title: "博多から由布院へ特急", category: "move", starts_at: "08:00", ends_at: "10:30" },
            { title: "金鱗湖を散策", category: "activity", starts_at: "11:00", ends_at: "12:30" },
            { title: "旅館で温泉", category: "stay", starts_at: "15:00", ends_at: "17:00" }
          ]
        },
        {
          title: "3日目: 博多グルメ",
          starts_on: Date.new(current_year, 11, 14),
          notes: "屋台文化を体験",
          recipe_steps: [
            { title: "博多ラーメンで締め", category: "food", starts_at: "12:00", ends_at: "13:00" },
            { title: "中洲屋台めぐり", category: "food", starts_at: "19:00", ends_at: "21:00" }
          ]
        }
      ]
    }
  ]

  simple_city_templates = [
    {
      title: "名古屋食べ歩き週末",
      city_display: "名古屋",
      description: "味噌カツとひつまぶしで締める名古屋グルメ旅。",
      day_title: "1日目: 栄と大須",
      notes: "地下鉄移動中心で少し早めに行動。",
      steps: [
        { title: "栄で喫茶モーニング", category: "food", starts_at: "08:30", ends_at: "09:30" },
        { title: "名古屋城を見学", category: "activity", starts_at: "10:00", ends_at: "11:30" },
        { title: "大須商店街で食べ歩き", category: "activity", starts_at: "12:00", ends_at: "14:00" },
        { title: "矢場とんで味噌カツディナー", category: "food", starts_at: "18:00", ends_at: "19:00" }
      ]
    },
    {
      title: "仙台ずんだ散歩",
      city_display: "仙台",
      description: "牛たんとずんだスイーツでリフレッシュする日帰り旅。",
      day_title: "1日目: 仙台中心部",
      notes: "地下鉄と徒歩で十分回れる距離。",
      steps: [
        { title: "瑞鳳殿を参拝", category: "activity", starts_at: "09:00", ends_at: "10:00" },
        { title: "定禅寺通りを散歩", category: "activity", starts_at: "10:30", ends_at: "11:30" },
        { title: "牛たんランチ", category: "food", starts_at: "12:00", ends_at: "13:00" },
        { title: "ずんだシェイク休憩", category: "food", starts_at: "15:00", ends_at: "15:30" }
      ]
    },
    {
      title: "金沢アートと和菓子",
      city_display: "金沢",
      description: "21世紀美術館とひがし茶屋街を巡るカルチャートリップ。",
      day_title: "1日目: 兼六園界隈",
      notes: "徒歩移動でアートと庭園をバランスよく巡る。",
      steps: [
        { title: "兼六園を散策", category: "activity", starts_at: "09:00", ends_at: "10:30" },
        { title: "金沢21世紀美術館", category: "activity", starts_at: "11:00", ends_at: "12:30" },
        { title: "近江町市場で寿司ランチ", category: "food", starts_at: "13:00", ends_at: "14:00" },
        { title: "ひがし茶屋街で和菓子", category: "food", starts_at: "15:00", ends_at: "16:00" }
      ]
    },
    {
      title: "長野善光寺リトリート",
      city_display: "長野",
      description: "善光寺参拝と門前そばで心を整える週末。",
      day_title: "1日目: 善光寺門前",
      notes: "朝いちで善光寺へ行き混雑を回避。",
      steps: [
        { title: "善光寺で朝のお参り", category: "activity", starts_at: "08:00", ends_at: "09:00" },
        { title: "仲見世でおやき", category: "food", starts_at: "09:15", ends_at: "09:45" },
        { title: "門前そばランチ", category: "food", starts_at: "12:00", ends_at: "13:00" },
        { title: "長野駅周辺で土産探し", category: "activity", starts_at: "14:00", ends_at: "15:00" }
      ]
    },
    {
      title: "神戸ベイサイド散策",
      city_display: "神戸",
      description: "北野異人館とハーバーランドで洋館ムードを味わう。",
      day_title: "1日目: 北野と港",
      notes: "シティループバスでエリアを移動。",
      steps: [
        { title: "北野異人館街を散策", category: "activity", starts_at: "09:30", ends_at: "11:00" },
        { title: "南京町で点心ランチ", category: "food", starts_at: "12:00", ends_at: "13:00" },
        { title: "ハーバーランドでカフェ", category: "food", starts_at: "15:00", ends_at: "16:00" },
        { title: "ポートタワーの夜景", category: "activity", starts_at: "19:00", ends_at: "20:00" }
      ]
    },
    {
      title: "横浜みなと夜景",
      city_display: "横浜",
      description: "赤レンガ倉庫から山下公園まで夜景散歩を楽しむレシピ。",
      day_title: "1日目: みなとみらい",
      notes: "夕方以降のライトアップをメインに設定。",
      steps: [
        { title: "横浜美術館でアート鑑賞", category: "activity", starts_at: "13:00", ends_at: "14:30" },
        { title: "赤レンガ倉庫でショッピング", category: "activity", starts_at: "15:00", ends_at: "16:30" },
        { title: "中華街でディナー", category: "food", starts_at: "18:00", ends_at: "19:30" },
        { title: "山下公園で夜景散歩", category: "activity", starts_at: "20:00", ends_at: "21:00" }
      ]
    },
    {
      title: "熊本城と水前寺公園",
      city_display: "熊本",
      description: "城下町の歴史と庭園をゆったり巡る1日レシピ。",
      day_title: "1日目: 城と庭園",
      notes: "市電で移動しやすいスポットを集約。",
      steps: [
        { title: "熊本城天守を散策", category: "activity", starts_at: "09:00", ends_at: "10:30" },
        { title: "城彩苑で名物ランチ", category: "food", starts_at: "11:30", ends_at: "12:30" },
        { title: "水前寺成趣園で抹茶", category: "food", starts_at: "14:00", ends_at: "15:00" },
        { title: "上通アーケードでお土産", category: "activity", starts_at: "16:00", ends_at: "17:00" }
      ]
    },
    {
      title: "鹿児島桜島ビュー",
      city_display: "鹿児島",
      description: "桜島フェリーと温泉で火山の迫力を味わう旅。",
      day_title: "1日目: 桜島と市内",
      notes: "桜島フェリーの時間を事前にチェックする想定。",
      steps: [
        { title: "桜島フェリーで移動", category: "move", starts_at: "09:00", ends_at: "09:20" },
        { title: "湯之平展望所で風景撮影", category: "activity", starts_at: "10:00", ends_at: "11:00" },
        { title: "しろくまかき氷休憩", category: "food", starts_at: "13:30", ends_at: "14:00" },
        { title: "砂むし温泉でリラックス", category: "stay", starts_at: "16:00", ends_at: "17:00" }
      ]
    },
    {
      title: "那須高原リラックス",
      city_display: "那須",
      description: "那須塩原の森カフェと牧場を巡る癒やし旅。",
      day_title: "1日目: 高原ドライブ",
      notes: "レンタカー移動で寄り道がしやすい構成。",
      steps: [
        { title: "那須どうぶつ王国", category: "activity", starts_at: "10:00", ends_at: "12:00" },
        { title: "チーズガーデンでランチ", category: "food", starts_at: "12:30", ends_at: "13:30" },
        { title: "南ヶ丘牧場でジェラート", category: "food", starts_at: "14:00", ends_at: "14:30" },
        { title: "那須温泉で足湯", category: "stay", starts_at: "15:30", ends_at: "16:30" }
      ]
    },
    {
      title: "熱海温泉チル",
      city_display: "熱海",
      description: "レトロな商店街とビーチを散歩する温泉デイ。",
      day_title: "1日目: 駅前と海",
      notes: "遅めスタートで列車移動後の疲れを癒やす。",
      steps: [
        { title: "熱海銀座商店街を散策", category: "activity", starts_at: "11:00", ends_at: "12:00" },
        { title: "海の見えるカフェでランチ", category: "food", starts_at: "12:30", ends_at: "13:30" },
        { title: "サンビーチでのんびり", category: "activity", starts_at: "14:00", ends_at: "15:00" },
        { title: "旅館の温泉", category: "stay", starts_at: "17:00", ends_at: "18:00" }
      ]
    },
    {
      title: "高松うどんホッピング",
      city_display: "高松",
      description: "さぬきうどん店を3軒巡る食べ歩きレシピ。",
      day_title: "1日目: うどん街道",
      notes: "レンタカーまたはバスで移動。",
      steps: [
        { title: "朝うどん@がもう", category: "food", starts_at: "08:00", ends_at: "08:30" },
        { title: "栗林公園で散策", category: "activity", starts_at: "09:30", ends_at: "10:30" },
        { title: "昼うどん@山越", category: "food", starts_at: "11:30", ends_at: "12:00" },
        { title: "高松港で夕景", category: "activity", starts_at: "17:30", ends_at: "18:00" }
      ]
    },
    {
      title: "松江城下町さんぽ",
      city_display: "松江",
      description: "国宝松江城と宍道湖夕景で静かな時間を楽しむ。",
      day_title: "1日目: 城下町",
      notes: "堀川遊覧船の時間に合わせて移動。",
      steps: [
        { title: "松江城を登城", category: "activity", starts_at: "09:30", ends_at: "11:00" },
        { title: "堀川遊覧船", category: "activity", starts_at: "11:15", ends_at: "12:00" },
        { title: "出雲そばランチ", category: "food", starts_at: "12:30", ends_at: "13:30" },
        { title: "宍道湖サンセット", category: "activity", starts_at: "17:30", ends_at: "18:30" }
      ]
    },
    {
      title: "奈良古都散策",
      city_display: "奈良",
      description: "東大寺とならまちでクラフト巡りを楽しむ。",
      day_title: "1日目: 奈良公園",
      notes: "鹿とのふれあい時間を長めに確保。",
      steps: [
        { title: "東大寺大仏殿", category: "activity", starts_at: "09:00", ends_at: "10:00" },
        { title: "奈良公園で鹿せんべい", category: "activity", starts_at: "10:15", ends_at: "11:00" },
        { title: "ならまちカフェ", category: "food", starts_at: "12:30", ends_at: "13:30" },
        { title: "春日大社参拝", category: "activity", starts_at: "14:00", ends_at: "15:00" }
      ]
    },
    {
      title: "日光世界遺産デイ",
      city_display: "日光",
      description: "東照宮から華厳の滝まで王道ルートを凝縮。",
      day_title: "1日目: 世界遺産",
      notes: "東武日光駅からバス利用の想定。",
      steps: [
        { title: "日光東照宮参拝", category: "activity", starts_at: "09:00", ends_at: "10:30" },
        { title: "輪王寺で写経体験", category: "activity", starts_at: "11:00", ends_at: "12:00" },
        { title: "湯葉御膳ランチ", category: "food", starts_at: "12:30", ends_at: "13:30" },
        { title: "華厳の滝を鑑賞", category: "activity", starts_at: "14:30", ends_at: "15:30" }
      ]
    },
    {
      title: "青森ねぶた気分",
      city_display: "青森",
      description: "ねぶたの家ワ・ラッセで祭りを一年中楽しむ。",
      day_title: "1日目: 青森港",
      notes: "雪の時期も動きやすい屋内中心ルート。",
      steps: [
        { title: "ねぶたの家ワ・ラッセ", category: "activity", starts_at: "09:30", ends_at: "11:00" },
        { title: "A-FACTORYでりんごスイーツ", category: "food", starts_at: "11:15", ends_at: "12:00" },
        { title: "青森魚菜センターで海鮮丼", category: "food", starts_at: "12:30", ends_at: "13:30" },
        { title: "八甲田丸を見学", category: "activity", starts_at: "14:00", ends_at: "15:00" }
      ]
    },
    {
      title: "盛岡三大麺めぐり",
      city_display: "盛岡",
      description: "冷麺・じゃじゃ麺・わんこそばを制覇するグルメ旅。",
      day_title: "1日目: 駅前グルメ",
      notes: "食べ歩きメインなので歩く距離は短め。",
      steps: [
        { title: "駅ビルで朝のわんこそば", category: "food", starts_at: "09:00", ends_at: "10:00" },
        { title: "盛岡城跡公園を散歩", category: "activity", starts_at: "10:30", ends_at: "11:30" },
        { title: "じゃじゃ麺ランチ", category: "food", starts_at: "12:30", ends_at: "13:30" },
        { title: "冷麺ディナー", category: "food", starts_at: "18:00", ends_at: "19:00" }
      ]
    },
    {
      title: "松山道後温泉",
      city_display: "松山",
      description: "道後温泉本館と路面電車で街を巡る癒やし旅。",
      day_title: "1日目: 道後エリア",
      notes: "路面電車一日券を使う想定。",
      steps: [
        { title: "松山城ロープウェイ", category: "activity", starts_at: "09:30", ends_at: "10:30" },
        { title: "道後商店街で坊っちゃん団子", category: "food", starts_at: "11:00", ends_at: "11:30" },
        { title: "道後温泉本館で入浴", category: "stay", starts_at: "12:00", ends_at: "13:30" },
        { title: "道後公園で読書", category: "activity", starts_at: "14:00", ends_at: "15:00" }
      ]
    },
    {
      title: "高山古い町並み",
      city_display: "高山",
      description: "朝市と古い町並みを巡る飛騨牛グルメ旅。",
      day_title: "1日目: 古い町並み",
      notes: "朝市スタートで新鮮野菜を購入。",
      steps: [
        { title: "宮川朝市で食べ歩き", category: "food", starts_at: "08:00", ends_at: "09:00" },
        { title: "古い町並みを散策", category: "activity", starts_at: "09:30", ends_at: "11:00" },
        { title: "飛騨牛寿司ランチ", category: "food", starts_at: "12:00", ends_at: "13:00" },
        { title: "高山陣屋の見学", category: "activity", starts_at: "14:00", ends_at: "15:00" }
      ]
    },
    {
      title: "甲府フルーツ日帰り",
      city_display: "甲府",
      description: "ワイナリーと果樹園で山梨の恵みを味わう日帰りレシピ。",
      day_title: "1日目: フルーツライン",
      notes: "レンタカーで勝沼周辺を巡る。",
      steps: [
        { title: "ぶどう畑見学", category: "activity", starts_at: "09:30", ends_at: "10:30" },
        { title: "ワイナリー試飲", category: "activity", starts_at: "11:00", ends_at: "12:00" },
        { title: "ほうとうランチ", category: "food", starts_at: "12:30", ends_at: "13:30" },
        { title: "フルーツパークでデザート", category: "food", starts_at: "14:30", ends_at: "15:30" }
      ]
    },
    {
      title: "旭川街歩き",
      city_display: "旭川",
      description: "旭山動物園と買物公園をセットにした1日。",
      day_title: "1日目: 動物園と街",
      notes: "冬場はバス移動時間を多めに確保。",
      steps: [
        { title: "旭山動物園をじっくり", category: "activity", starts_at: "09:30", ends_at: "12:00" },
        { title: "旭川ラーメンランチ", category: "food", starts_at: "12:30", ends_at: "13:30" },
        { title: "買物公園で雑貨探し", category: "activity", starts_at: "14:00", ends_at: "15:00" },
        { title: "北の恵みキッチンで地産ディナー", category: "food", starts_at: "18:00", ends_at: "19:00" }
      ]
    },
    {
      title: "別府地獄めぐり",
      city_display: "別府",
      description: "7つの地獄を巡ってから砂むし温泉で締める。",
      day_title: "1日目: 鉄輪エリア",
      notes: "路線バスで移動しつつ温泉蒸し料理も楽しむ。",
      steps: [
        { title: "海地獄を見学", category: "activity", starts_at: "09:00", ends_at: "10:00" },
        { title: "鬼石坊主地獄", category: "activity", starts_at: "10:15", ends_at: "11:00" },
        { title: "地獄蒸し工房でランチ", category: "food", starts_at: "12:00", ends_at: "13:00" },
        { title: "砂むし温泉でリラックス", category: "stay", starts_at: "15:00", ends_at: "16:00" }
      ]
    },
    {
      title: "高知ひろめ市場",
      city_display: "高知",
      description: "朝どれカツオと路面電車で巡るローカルTrip。",
      day_title: "1日目: ひろめ市場",
      notes: "市場内のテーブル確保は早めに行う前提。",
      steps: [
        { title: "日曜市で野菜チェック", category: "activity", starts_at: "08:00", ends_at: "09:00" },
        { title: "ひろめ市場でカツオのたたき", category: "food", starts_at: "11:00", ends_at: "12:00" },
        { title: "高知城を見学", category: "activity", starts_at: "13:00", ends_at: "14:00" },
        { title: "はりまや橋周辺を散策", category: "activity", starts_at: "15:00", ends_at: "16:00" }
      ]
    },
    {
      title: "下関門司港はしご",
      city_display: "下関",
      description: "唐戸市場と関門トンネル人道を楽しむ2都市プラン。",
      day_title: "1日目: 海峡散策",
      notes: "徒歩と船を組み合わせて関門海峡を満喫。",
      steps: [
        { title: "唐戸市場でふぐ寿司", category: "food", starts_at: "09:00", ends_at: "10:00" },
        { title: "関門トンネル人道を徒歩で渡る", category: "activity", starts_at: "10:30", ends_at: "11:30" },
        { title: "門司港レトロでカフェ", category: "food", starts_at: "12:00", ends_at: "13:00" },
        { title: "海峡クルーズ", category: "activity", starts_at: "14:30", ends_at: "15:30" }
      ]
    }
  ]

  simple_city_templates.each_with_index do |template, idx|
    start_month = ((idx + 1) % 12) + 1
    start_day = ((idx * 2) % 20) + 5
    plans_data << {
      title: template[:title],
      city_display: template[:city],
      description: template[:description],
      user: [ user1, user2, user3 ][idx % 3],
      days: [
        {
          title: template[:day_title] || "1日目: #{template[:city]}ハイライト",
          notes: template[:notes],
          starts_on: Date.new(current_year, start_month, start_day),
          recipe_steps: template[:steps]
        }
      ]
    }
  end

  plans_data.each { |plan_data| ensure_recipe_with_details!(plan_data) }

  # Add saved recipes to create popular plans
  tokyo_plan = Recipe.find_by(title: "東京3日間の旅")
  kyoto_plan = Recipe.find_by(title: "京都の寺社巡り")
  osaka_plan = Recipe.find_by(title: "大阪グルメツアー")
  hokkaido_plan = Recipe.find_by(title: "北海道自然の旅")
  okinawa_plan = Recipe.find_by(title: "沖縄リゾート")

  # Create saved recipes (tokyo_plan is most popular)
  [ user2, user3 ].each do |user|
    SavedRecipe.find_or_create_by!(user: user, recipe: tokyo_plan)
  end

  # kyoto_plan second popular
  SavedRecipe.find_or_create_by!(user: user3, recipe: kyoto_plan)
  SavedRecipe.find_or_create_by!(user: user1, recipe: kyoto_plan)

  # osaka_plan
  SavedRecipe.find_or_create_by!(user: user2, recipe: osaka_plan)

  # hokkaido_plan
  SavedRecipe.find_or_create_by!(user: user1, recipe: hokkaido_plan)

  # okinawa_plan
  SavedRecipe.find_or_create_by!(user: user3, recipe: okinawa_plan)

  puts "✅ Seed data created successfully!"
  puts "Users: #{User.count}"
  puts "Recipes: #{Recipe.count}"
  puts "Recipe Days: #{RecipeDay.count}"
  puts "Recipe Steps: #{RecipeStep.count}"
  puts "Saved Recipes: #{SavedRecipe.count}"
end
