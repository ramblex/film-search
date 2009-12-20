# This is a script which fills an sqlite database on command with films that
# are on TV in the next 14 days.

require 'cgi'
require 'net/http'
require 'uri'
require 'rubygems'
require 'sqlite3'
require 'active_support'

# Channels to get and their numbers on the Radio Times site
# (http://xmltv.radiotimes.com/xmltv/channels.dat)
@channels = [
             ["BBC ONE", 104],
             ["BBC TWO", 117],
             ["BBC THREE", 45],
             ["BBC FOUR", 47],
             ["ITV1", 36],
             ["ITV2", 185],
             ["ITV3", 1859],
             ["ITV4", 1961],
             ["E4", 158],
             ["More4", 1959],
             ["Yesterday", 801],
             ["Channel 4", 132], 
             ["Film4", 160],
             ["Five", 134],
             ["Five USA", 2008],
             ["Fiver", 2062],
            ]

@db = SQLite3::Database.new("films.db")

# Helper method that deletes the current Films table and creates a new one
# N.B. All current data in the DB will be lost!
def create_films_table
  @db.execute("DROP TABLE Films")
  @db.execute(<<EOF
CREATE TABLE films (
  title VARCHAR(200),
  date DATETIME,
  channel VARCHAR(200),
  start_time TIME,
  end_time TIME,
  year NUMBER,
  description TEXT,
  duration NUMBER,
  PRIMARY KEY(title, date, channel)
);
EOF
              )
end

def wordwrap(txt, col = 80)
  txt.gsub(/(.{1,#{col}})( +|$\n?)|(.{1,#{col}})/,
    "\\1\\3\n") 
end

class String
  def escape_single_quotes
    self.gsub(/'/, "\\\\'")
  end
end

# Insert a film into the database table
def insert_film(title, date, channel, start_time, end_time, year, desc, duration)
  title = title.gsub(/[']/, "\\'")
  desc = desc.gsub(/[']/, "")
  @db.execute("INSERT OR IGNORE INTO Films \
VALUES ('#{title.escape_single_quotes}', '#{date}', '#{channel}', \
'#{start_time}', '#{end_time}', '#{year}', '#{desc.escape_single_quotes}', #{duration})")
end

# Retrieve the listings for a channel
def get_channel(channel_name, channel_num)
  puts "Getting channel #{channel_name}, #{channel_num}"
  url = URI.parse("http://xmltv.radiotimes.com/xmltv/channels.dat")
  res = Net::HTTP.start(url.host, url.port) { |http|
    http.get("/xmltv/#{channel_num}.dat")
  }

  res.body.split("\n").each do |line|
    line = line.chomp.split("~")
    if line[16].eql? "Film"
      insert_film(line[0], line[19], channel_name, line[20], line[21], line[3], line[17], line[22])
    end
  end
end

# Whether to update the database. If this option is turned on, it can take
# a few minutes to grab and process all of the data
@update = false

# Use this sparingly. It deletes the current Films table and creates a new one
@clean = false

# The SQL WHERE clause conditions to execute
@conds = ""

# If set to true, the list of films is printed in a pretty way, otherwise it
# comes out as a ruby hash is normally output
@readable = true

# If set to false, no results are fetched from the DB. This is useful if we
# just want to clean or update the DB.
@output = true

@org_mode = false

@delete_old = false

# Process input args
ARGV.each do |arg|
  if arg.eql? "--update"
    @update = true
  elsif arg.eql? "--wipe"
    @clean = true
  elsif arg.eql? "--print-hash"
    @readable = false
  elsif arg.eql? "--no-output"
    @output = false
  elsif arg.eql? "--delete-old"
    @delete_old = true
  elsif arg.eql? "--org-mode"
    @org_mode = true
  elsif arg.eql? "--short"
    @short = true
  else
    @conds = arg
  end
end

if @delete_old
  @db.execute("DELETE FROM Films WHERE date < #{Date.today.strftime("%d/%m/%Y")}")
end

if @clean
  create_films_table
end

if @update
  @channels.each do |chan|
    get_channel(chan[0], chan[1])
  end
end

if @output == false
  exit
end

@db.results_as_hash = true

# Replace any special keywords. This makes the program easier to use for the
# user.
@conds = @conds.gsub(/today/, 
                     "(date = '#{Date.today.strftime("%d/%m/%Y")}' 
and end_time >= '#{(Time.now).strftime("%H:%M")}')
or (date = '#{Date.tomorrow.strftime("%d/%m/%Y")}' and start_time <= '03:00')")
@conds = @conds.gsub(/tomorrow/, "date = '#{Date.tomorrow.strftime("%d/%m/%Y")}'")

# Assume that if the user gives no conditions, they want all of the films 
# stored in the database
unless @conds.eql? ""
  @conds = "WHERE #{@conds}"
  unless @conds.upcase.include? "ORDER BY"
    @conds += " ORDER BY date DESC,start_time DESC"
  end
  puts "conds: #{@conds}"
end

begin
  @db.execute("SELECT * FROM Films #{@conds}") do |row|
    if @readable
      puts "---"
      puts "#{row['date']} #{row['start_time']}-#{row['end_time']} #{row['title']} (#{row['year']}) #{row['channel']} (#{row['duration']} mins)"
      unless @short
        puts wordwrap(row['description'], 80)
      end
    else
      puts row
    end
  end
rescue
  p $!
end
