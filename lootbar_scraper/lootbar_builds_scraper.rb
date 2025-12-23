# frozen_string_literal: true

require_relative 'lootbar_base_scraper'

# lootbar web scraper for ZZZ characters builds and teams
class LootbarBuilsdScraper < LootbarBaseScraper
  PARAGRAPH_TABLE_SUB_TITLE_INDEXES = {
    1 => 0,
    2 => 1,
    3 => 2
  }.freeze

  SECTION_PARAGRAPH_INDEXES = {
    1 => 0,
    2 => 1,
    3 => 2,
    4 => 3,
    5 => 4
  }.freeze

  SECTION_BY_INDEX_TYPE = {
    0 => :with_sub_sections,
    1 => :with_paragraph_table,
    2 => :with_paragraph_table,
    3 => :with_paragraph_table,
    4 => :with_sub_sections,
    5 => :with_sub_sections
  }.freeze

  attr_reader :character_builds

  def initialize(url)
    super(url)
    @character_builds = {}
  end

  def scrape
    fetch_page
    return {} unless @doc

    @character_builds['page_name'] = page_title
    @character_builds['sections'] = process_sections

    @character_builds
  end

  private

  def process_sections
    paragraph_tables = page_paragraph_tables
    paragraph_sections = page_sub_title_paragraphs

    nodes = {
      'tables' => paragraph_tables,
      'p' => paragraph_sections
    }

    sub_titles = page_sub_titles.take(page_sub_titles.size - 1) # we don't want the las element
    sub_titles.map.with_index do |sub, i|
      case SECTION_BY_INDEX_TYPE[i]
      when :with_sub_sections
        { 'title' => sub.content }
      when :with_paragraph_table
        process_section_with_paragrap_table(sub, i, nodes)
      end
    end
  end

  def process_section_with_paragrap_table(node, index, nodes)
    return {} unless node

    tables = nodes['tables']
    paragraphs = nodes['p']

    section = { 'title' => node.content }
    table_index = PARAGRAPH_TABLE_SUB_TITLE_INDEXES[index]
    table = tables[table_index]
    section['table'] = map_table(table)

    paragraph_index = SECTION_PARAGRAPH_INDEXES[index]
    paragraph = paragraphs[paragraph_index].content.gsub("\u00A0", ' ')
    section['text'] = paragraph

    section
  end

  def page_sub_title_paragraphs
    @doc.css('h2 + p')
  end

  # < table /> element next to a <p /> element
  # for lootbar in the builds, found 3 so far
  # they belong to the sub title indexes [1, 2, 3]
  def page_paragraph_tables
    @doc.css('p + table')
  end
end
