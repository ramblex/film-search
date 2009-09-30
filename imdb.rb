require 'cgi'
require 'rubygems'
require 'hpricot'
require 'open-uri'

if (ARGV.length != 1)
  puts "USAGE: ruby imdb.rb [FILM NAME AND YEAR]"
  puts "e.g. ruby imdb.rb \"Troy (2004)\""
  exit
end

puts "Looking up '#{ARGV[0]}'"

google_search = "http://www.google.com/search?hl=en&q=imdb+#{CGI::escape(ARGV[0])}&btnI=I%27m+Feeling+Lucky"

doc = open(google_search) { |f| Hpricot(f) }
(doc/"div.info").each do |section|
  header = section.search("h5").inner_html
  if (header == "Plot:")
    puts section.inner_html.strip!.gsub(/<\/?h5>/, "").split("<a")[0]
  elsif (header == "Genre:")
    print "#{header} "
    puts section.search("a").map { |l| l.inner_html }.join(", ")
  end
end
