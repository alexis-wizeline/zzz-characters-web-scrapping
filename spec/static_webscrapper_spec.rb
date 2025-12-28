# frozen_string_literal: true

require 'rspec'
require 'webmock/rspec'
require_relative '../static_webscraper'

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

RSpec.describe LootbarBuildsScraper do
  let(:url) { 'https://example.com/builds' }
  subject { described_class.new(url) }

  before do
    stub_request(:get, url).to_return(body: <<~HTML)
      <html>
        <head><title>Test Page</title></head>
        <body>
        <h2>1.- random title 1</h2>
        <p>p.1 - P for title 1</p>
        <table><tbody><tr><td>build 1</td></tr></tbody></table>
        <h2> 2.- random title 2 </h2>
        <ul><h3> 2.1- random sub for title 2 </h3></ul>
        <p>overview paragraph</p>
        <table><tbody><tr><td>build 2</td></tr></tbody></table>
        <h2> extra node </h2>
        </body>
      </html>
    HTML
  end

  describe '#scrape' do
    it 'scrape data correctly' do
      stub_const('LootbarBuildsScraper::SECTION_BY_INDEX_TYPE', { 0 => :with_paragraph_table, 1 => :with_sub_sections })
      stub_const('LootbarBuildsScraper::PARAGRAPH_TABLE_SUB_TITLE_INDEXES', { 0 => 0 })
      stub_const('LootbarBuildsScraper::SECTION_PARAGRAPH_INDEXES', { 0 => 0 })
      stub_const('LootbarBuildsScraper::SECTION_H3_INDEXES', { 1 => [0] })
      stub_const('LootbarBuildsScraper::H3_TABLE_INDEXES', [1])

      result = subject.scrape

      expect(result[:type]).to eq(:builds)
      expect(result['page_name']).to eq('Test Page')

      sections = result['sections']
      expect(sections).to be_an(Array)
      expect(sections.size).to eq(2)

      expect(sections[0]['title']).to eq('1.- random title 1')
      expect(sections[0]['text']).to eq('p.1 - P for title 1')

      expect(sections[1]['title']).to eq(' 2.- random title 2 ')
      expect(sections[1]['sub_sections']).to be_an(Array)
      expect(sections[1]['sub_sections'].size).to eq(1)
    end
  end
end
