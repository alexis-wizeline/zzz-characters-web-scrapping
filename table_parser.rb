class TableParser
  def initialize(table_node)
    @table_node = table_node
  end

  def parse
    return [] unless @table_node

    rows = []
    tbody = @table_node.at_css('tbody')
    return [] unless tbody

    tbody.css('tr').each do |row|
      rows << parse_row(row)
    end
    rows
  end

  private

  def parse_row(row)
    data = []
    row.css('td').each do |td|
      img = td.at_css('img')
      content = td.content.gsub("\u00A0", '').strip
      data << if img
                "(#{img['src']}) - #{content}"
              else
                content
              end
    end
    data
  end
end
