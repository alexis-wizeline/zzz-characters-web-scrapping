# frozen_string_literal: true

require 'nokogiri'
require 'open-uri'
require 'json'

require_relative 'table_parser'
require_relative 'lootbar_scraper/lootbar_materials_scraper'
require_relative 'lootbar_scraper/lootbar_builds_scraper'

# The scraper runner
class ScraperRunner
  ELEMENTS = [
    { url: 'https://lootbar.gg/blog/en/zenless-zone-zero-ye-shunguang-materials.html', type: :materials },
    { url: 'https://lootbar.gg/blog/en/zenless-zone-zero-dialyn-materials.html', type: :materials },
    { url: 'https://lootbar.gg/blog/en/zenless-zone-zero-banyue-materials.html', type: :materials },
    { url: 'https://lootbar.gg/blog/en/zenless-zone-zero-ye-shunguang-build-guide.html', type: :builds }
  ].freeze

  OUTPUT_FILE = 'scraped.json'

  def self.run
    scraped_data = []

    ELEMENTS.each do |element|
      next if element.empty?

      url = element[:url]
      scraper = case element[:type]
                when :materials
                  LootbarMaterialsScraper.new(url)
                when :builds
                  LootbarBuildsScraper.new(url)
                end
      next if scraper.nil?

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

ScraperRunner.run if __FILE__ == $PROGRAM_NAME
