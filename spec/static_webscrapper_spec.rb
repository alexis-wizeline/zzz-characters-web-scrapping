# frozen_string_literal: true

require 'rspec'
require 'webmock/rspec'
require_relative '../static_webscrapper'

RSpec.describe TableParser do
  let(:table_html) do
    <<~HTML
      <table>
        <tbody>
          <tr>
            <td>Item 1</td>
            <td><img src="test.jpg" />Item 2</td>
          </tr>
        </tbody>
      </table>
    HTML
  end

  let(:table_node) { Nokogiri::HTML4::DocumentFragment.parse(table_html).at_css('table') }
  subject { described_class.new(table_node) }

  describe '#parse' do
    it 'parses rows correctly' do
      result = subject.parse
      expect(result).to be_an(Array)
      expect(result.first).to eq(['Item 1', '(test.jpg) - Item 2'])
    end

    it 'returns empty array if table node is nil' do
      parser = described_class.new(nil)
      expect(parser.parse).to eq([])
    end
  end
end

RSpec.describe LootbarMaterialsScraper do
  let(:url) { 'https://example.com/materials' }
  subject { described_class.new(url) }

  before do
    stub_request(:get, url).to_return(body: <<~HTML)
      <html>
        <head><title>Test Page</title></head>
        <body>
          <h2>Section 1</h2>
          <h2>Section 2</h2>
          <table>
            <tbody><tr><td>Mat 1</td></tr></tbody>
          </table>
          <table>
            <tbody><tr><td>Mat 2</td></tr></tbody>
          </table>
        </body>
      </html>
    HTML
  end

  describe '#scrape' do
    it 'scrapes data correctly' do
      stub_const('LootbarMaterialsScraper::TABLES_INDEXES_SECTIONS', [0, 1])

      result = subject.scrape

      expect(result['page_name']).to eq('Test Page')
      expect(result['sections']).to be_an(Array)
      expect(result['sections'].size).to eq(2)

      expect(result['sections'][0]['title']).to eq('Section 1')
      expect(result['sections'][0]['materials']).to eq([['Mat 1']])

      expect(result['sections'][1]['title']).to eq('Section 2')
      expect(result['sections'][1]['materials']).to eq([['Mat 2']])
    end

    it 'handles fetch errors gracefully' do
      stub_request(:get, url).to_return(status: 404)

      allow(subject).to receive(:warn)

      expect(subject.scrape).to eq({})
    end
  end
end
