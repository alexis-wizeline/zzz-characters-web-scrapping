class LootbarMaterialsScraper
  TABLES_INDEXES_SECTIONS = [0, 1, [2, 3], [4, 5, 6]].freeze

  attr_reader :character_materials

  def initialize(url)
    @url = url
    @doc = nil
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

  def fetch_page
    @doc = Nokogiri::HTML4(URI.open(@url))
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

  def map_table(table_node)
    TableParser.new(table_node).parse
  end

  def map_tables(all_tables, indexes)
    indexes.map { |index| map_table(all_tables[index]) }
  end
end
