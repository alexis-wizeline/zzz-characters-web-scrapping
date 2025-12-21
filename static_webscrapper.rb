# frozen_string_literal: true

require 'nokogiri'
require 'open-uri'
require 'json'

require_relative 'table_parser'
require_relative 'lootbar_materials_scrapper'

# Runner class to execute the scraping process
class ScraperRunner
  URLS = [
    'https://lootbar.gg/blog/en/zenless-zone-zero-ye-shunguang-materials.html',
    'https://lootbar.gg/blog/en/zenless-zone-zero-dialyn-materials.html',
    'https://lootbar.gg/blog/en/zenless-zone-zero-banyue-materials.html'
  ].freeze

  OUTPUT_FILE = 'scrapped.json'

  def self.run
    scraped_data = []

    URLS.each do |url|
      next if url.empty?

      scraper = LootbarMaterialsScraper.new(url)
      result = scraper.scrape
      scraped_data << result unless result.empty?
    end

    save_to_file(scraped_data)
  end

  def self.save_to_file(data)
    File.delete(OUTPUT_FILE) if File.exist?(OUTPUT_FILE)

    File.open(OUTPUT_FILE, 'w') do |file|
      file.write(JSON.pretty_generate(data))
    end
    puts "Scraping completed. Data saved to #{OUTPUT_FILE}"
  end
end

# Execute the runner if this file is run directly
ScraperRunner.run if __FILE__ == $PROGRAM_NAME
