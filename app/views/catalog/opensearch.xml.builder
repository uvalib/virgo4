# app/views/catalog/opensearch.xml.builder

name       = application_name
lens       = current_lens_key.to_s
lens_name  = lens.capitalize
favicon    = asset_url('favicon.ico')
url_opt    = { controller: lens, only_path: false }
search_url = url_for(url_opt)
json_url   = url_for(url_opt.merge(action: 'opensearch', format: 'json'))
query      = 'q={searchTerms}'
page       = 'page={startPage?}'

search_types = {
  'text/html'                      => "#{search_url}?#{query}&amp;#{page}",
  'application/rss+xml'            => "#{search_url}.rss?#{query}&amp;#{page}",
  'application/x-suggestions+json' => "#{json_url}?#{query}"
}

xml.instruct! :xml, version: '1.0'
xml.OpenSearchDescription(xmlns: 'http://a9.com/-/spec/opensearch/1.1/') do
  xml.ShortName   name
  xml.Description "#{name} #{lens_name} Search"
  xml.Image       favicon, height: 16, width: 16, type: 'image/x-icon'
  xml.Contact
  search_types.each_pair do |mime_type, path|
    xml.Url type: mime_type, method: 'get', template: path
  end
end
