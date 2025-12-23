# frozen_string_literal: true

require_relative 'lootbar_base_scraper'
# lootbar web scrapper for ZZZ characters level up materials
class LootbarMaterialsScraper < LootbarBaseScraper
  TABLES_INDEXES_SECTIONS = [0, 1, [2, 3], [4, 5, 6]].freeze

  attr_reader :character_materials

  def initialize(url)
    super(url)
    @character_materials = {}
  end

  def scrape
    fetch_page
    return {} unless @doc

    @character_materials['page_name'] = page_title
    @character_materials['sections'] = process_sections
    @character_materials
  end

  private

  def process_sections
    tables = page_tables
    page_sub_titles.map.with_index do |sub_title, i|
      section = { 'title' => sub_title.content }
      table_indexes = TABLES_INDEXES_SECTIONS[i]

      section['materials'] = if table_indexes.is_a?(Array)
                               map_tables(tables, table_indexes)
                             else
                               map_table(tables[table_indexes])
                             end
      section
    end
  end
end
