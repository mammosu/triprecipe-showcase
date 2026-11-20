# frozen_string_literal: true

# Basic Pagy configuration for TripRecipe
require "pagy"

# Compatibility for gems expecting Pagy::Backend/Frontend constants.
if defined?(Pagy::Method) && !defined?(Pagy::Backend)
  Pagy::Backend = Pagy::Method
end
if defined?(Pagy::Loader) && !defined?(Pagy::Frontend)
  Pagy::Frontend = Pagy::Loader
end

# Default items per page
Pagy::DEFAULT[:items] = 20

# You can enable extras here, e.g. :overflow or :items
# require 'pagy/extras/overflow'
# Pagy::VARS[:overflow] = :last_page
