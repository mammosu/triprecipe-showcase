namespace :cities do
  desc "Link existing recipes to City by matching `city_display` to City aliases.\nUse DRY_RUN=true for preview, VERBOSE=true for per-row logs, LIMIT=n to limit processed rows, FORCE=true to overwrite existing city_id."
  task link_recipes: :environment do
    dry_run = ENV["DRY_RUN"].present?
    verbose = ENV["VERBOSE"].present?
    force = ENV["FORCE"].present?
    limit = ENV["LIMIT"] ? ENV["LIMIT"].to_i : nil

    scope = Recipe.where.not(city_display: [ nil, "" ])
    scope = scope.where(city_id: nil) unless force
    scope = scope.limit(limit) if limit

    total = scope.count
    puts "Found #{total} candidate recipes. Dry run=#{dry_run} Force=#{force}"

    processed = 0
    matched = 0

    scope.find_each do |recipe|
      processed += 1
      begin
        candidate = recipe.city_display.to_s
        matched_city = City.match_by_alias(candidate)

        if matched_city
          matched += 1
          puts "[MATCH] Recipe id=#{recipe.id} title='#{recipe.title}' city_display='#{candidate}' => #{matched_city.display_name} (id=#{matched_city.id})" if verbose || dry_run

          unless dry_run
            recipe.update!(city: matched_city)
          end
        else
          puts "[NO MATCH] Recipe id=#{recipe.id} city_display='#{candidate}'" if verbose
        end
      rescue => e
        puts "[ERROR] Recipe id=#{recipe.id} failed: #{e.class} #{e.message}"
      end
    end

    puts "Done. Processed=#{processed} Matched=#{matched}"
  end
end
