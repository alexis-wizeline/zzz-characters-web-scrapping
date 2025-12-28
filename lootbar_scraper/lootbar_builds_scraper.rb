# frozen_string_literal: true

require_relative 'lootbar_base_scraper'

# lootbar web scraper for ZZZ characters builds and teams
class LootbarBuildsScraper < LootbarBaseScraper
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

  SECTION_H3_INDEXES = {
    0 => [0, 1],
    4 => [2, 3],
    5 => [4, 5, 6]
  }.freeze

  H3_TABLE_INDEXES = [0, nil, 4, 5, 6, 7, 8].freeze

  attr_reader :character_builds

  def initialize(url)
    super(url)
    @character_builds = { type: :builds }
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
    paragraph_sections = page_sub_title_paragraphs
    p_nodes = {
      'tables' => page_paragraph_tables,
      'p' => paragraph_sections
    }

    sub_nodes = {
      'h3' => page_h3_titles,
      'h2_p' => paragraph_sections,
      'tables' => page_tables
    }

    sub_titles = page_sub_titles.take(page_sub_titles.size - 1) # we don't want the las element
    sub_titles.map.with_index do |sub, i|
      case SECTION_BY_INDEX_TYPE[i]
      when :with_sub_sections
        process_with_sub_sections(sub, i, sub_nodes)
      when :with_paragraph_table
        process_section_with_paragrap_table(sub, i, p_nodes)
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
    section['text'] = clean_content(paragraphs[paragraph_index])

    section
  end

  def process_with_sub_sections(root, index, nodes)
    return {} unless root

    h2_p = nodes['h2_p']

    h2_index = SECTION_PARAGRAPH_INDEXES[index]

    sub_sections = SECTION_H3_INDEXES[index].map { |h3_index| h3_sub_section(h3_index, nodes) }

    section = { 'title' => root.content,
                'sub_sections' => sub_sections }

    section['text'] = clean_content(h2_p[h2_index]) unless h2_index.nil?
    section
  end

  def h3_sub_section(index, nodes)
    h3 = nodes['h3']
    tables = nodes['tables']
    h3_table_index = H3_TABLE_INDEXES[index]
    sub_sec = { 'title' => clean_content(h3[index]) }
    # only the overview has data so no need to think in an index stuff
    sub_sec['text'] = page_overview_paragraph unless index != 1
    sub_sec['table'] = map_table(tables[h3_table_index]) unless h3_table_index.nil?
    sub_sec
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

  def page_h3_titles
    @doc.xpath('//h3')
  end

  def page_overview_paragraph
    clean_content(@doc.at_css('ul + p'))
  end

  def clean_content(node)
    node.content.gsub("\u00A0", ' ')
  end
end
