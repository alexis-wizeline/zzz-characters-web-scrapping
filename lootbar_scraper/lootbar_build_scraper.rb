# frozen_string_literal: true

require_relative 'lootbar_base_scraper'

class LootbarBuildScraper < LootbarBaseScraper
  attr_reader :character_builds

  def initialize(url)
    super(url)
    @character_builds = {}
  end

  def scrape
    @character_builds
  end
end
