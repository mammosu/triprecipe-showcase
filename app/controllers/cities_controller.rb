class CitiesController < ApplicationController
  def index
    cities = City.autocomplete(params[:query]).first(10)

    render json: cities.map { |city|
      {
        id: city.id,
        name_ja: city.name_ja,
        name_en: city.name_en,
        country_code: city.country_code,
        display_name: city.display_name
      }
    }
  end
end
