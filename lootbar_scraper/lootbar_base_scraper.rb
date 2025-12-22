# frozen_string_literal: true

require 'nokogiri'
# base lootbar web scraper
class LootbarBaseScraper
  def initialize(url)
    @url = url
    @doc = nil
  end

  private

  def fetch_page
    @doc = Nokogiri::HTML4(URI.parse(@url).open)
  rescue StandardError => e
    warn "Failed to fetch #{@url}: #{e.message}"
    nil
  end

  def page_title
    @doc.title
  end

  def page_sub_titles
    @doc.xpath('//h2')
  end

  def page_tables
    @doc.xpath('//table')
  end
end
