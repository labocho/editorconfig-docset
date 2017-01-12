# encoding: UTF-8
require "sqlite3"
require "active_record"
require "fileutils"
require "pp"
require "shellwords"
require "nokogiri"
require "uri"

include FileUtils

docset = "editorconfig.docset"
html_dir = "#{docset}/Contents/Resources/Documents"
mkdir_p html_dir
exit $?.exitstatus unless system("cp -R src/_site/* #{html_dir.shellescape}")
cp "#{html_dir}/logo.png", "#{docset}/icon.png"

open("#{docset}/Contents/Info.plist", "w") do |f|
  f.write <<-XML
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
      <dict>
        <key>CFBundleIdentifier</key>
        <string>editorconfig</string>
        <key>CFBundleName</key>
        <string>editorconfig</string>
        <key>DocSetPlatformFamily</key>
        <string>editorconfig</string>
        <key>isDashDocset</key>
        <true/>
        <key>dashIndexFilePath</key>
        <string>index.html</string>
        <key>DashDocSetFallbackURL</key>
        <string>http://editorconfig.org/</string>
      </dict>
    </plist>
  XML
end

rm "#{docset}/Contents/Resources/docSet.dsidx", force: true

ActiveRecord::Base.establish_connection(
  adapter: "sqlite3",
  database: "#{docset}/Contents/Resources/docSet.dsidx"
)

ActiveRecord::Base.connection.execute <<-SQL
  CREATE TABLE searchIndex(id INTEGER PRIMARY KEY, name TEXT, type TEXT, path TEXT)
SQL

class SearchIndex < ActiveRecord::Base
  self.table_name = "searchIndex"
end

path = "#{html_dir}/index.html"
relative_path = "index.html"
html = File.read(path)

doc = Nokogiri.parse(html)

# convert absolute path to relative path
doc.css("[href]").each do |el|
  if el["href"].to_s =~ %r{^/}
    el["href"] = el["href"][1..-1]
  end
end

doc.css("[src]").each do |el|
  if el["src"].to_s =~ %r{^/}
    el["src"] = el["src"][1..-1]
  end
end

# index sections
doc.css("section[id]").each do |el|
  index = SearchIndex.new
  index.name = el.css("h2, h3, h4")[0].text
  index.type = "Guide"
  index.path = relative_path + "#" + el["id"]
  index.save!
  pp index.attributes
end

# index wildcard pattern
doc.css("#wildcards").each do |el|
  el.css("tr").each do |tr|
    name = tr.css("code")[0].text
    tr["id"] = "wildcards-#{name}"
    index = SearchIndex.new
    index.name = name
    index.type = "Value"
    index.path = relative_path + "#" + tr["id"]
    index.save!
    pp index.attributes
  end
end

# index properties
doc.css("#supported-properties").each do |el|
  el.css(".property-definitions > li").each do |li|
    name = li.css("code")[0].text
    li["id"] = "supported-properties-#{name}"
    index = SearchIndex.new
    index.name = name
    index.type = "Property"
    index.path = relative_path + "#" + li["id"]
    index.save!
    pp index.attributes
  end
end

File.write(path, doc.to_html)
