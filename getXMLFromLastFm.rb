require 'net/http'
require 'rexml/document'
require 'rubygems'
require 'json'

###############################################################
# Settings

# api-key needed to connect with Last.fm
api_key = '2d8dc0a751b42a8e4f6ca5aeb5c0c867' 

# amount of top songs from each country
limit = 100

# countries to be considered
countries = ["poland", "spain", "malta", "croatia", "ukraine", "latvia", "saudi+arabia", "iraq", "japan", "china", "mexico", "canada", "ireland", "armenia", "south+africa", "czech+republic", "portugal", "switzerland", "finland", "norway", "sweden", "turkey", "australia", "united+states", "slovakia", "united+kingdom", "germany", "netherland", "france", "belgium", "russia"]

###


###############################################################
# Api methods

class LastAPI
  def self.similiar_artists(mbid, limit, api_key)
    url = "http://ws.audioscrobbler.com/2.0/?method=artist.getsimilar&mbid=#{mbid}&api_key=#{api_key}&limit=#{limit}"

    xml_data = Net::HTTP.get_response(URI.parse(url)).body

    doc = REXML::Document.new(xml_data)

    similiar = []
    doc.root.elements.each('*/artist') do |art|
      similiar << art.elements["name"].text
    end
    similiar
  end
  
  def self.artist_top_tags(mbid, api_key)
    # how many person should tag in this way to consider this tag
    tag_eligibility = 10 

    url = "http://ws.audioscrobbler.com/2.0/?method=artist.gettoptags&mbid=#{mbid}&api_key=#{api_key}"

    xml_data = Net::HTTP.get_response(URI.parse(url)).body

    doc = REXML::Document.new(xml_data)

    tags = []
    doc.root.elements.each('*/tag') do |tag|
      tag = {
        "tagname" => tag.elements["name"].text,
        "tagcount" => tag.elements["count"].text
      }
      if Integer(tag["tagcount"]) > tag_eligibility
        tags << tag
        end
    end
    tags
  end
end


#####################################################
# Main body

songs = []
db = []

countries.each do |country|

  print "fetching #{country}...\n"
  
  url = "http://ws.audioscrobbler.com/2.0/?method=geo.gettoptracks&country=#{country}&limit=#{limit}&api_key=#{api_key}"
  
  # get the XML data as a string
  xml_data = Net::HTTP.get_response(URI.parse(url)).body
  
  # extract song information
  doc = REXML::Document.new(xml_data)
  
  doc.elements.each('lfm/toptracks/track') do |ele|
    
    mbid = ele.elements["artist"].elements["mbid"].text
    country_name = ele.parent.attributes["country"]

    # get additional info from Last.fm api

    similiar_artists = LastAPI::similiar_artists(mbid, 5, api_key)
    artist_top_tags = LastAPI::artist_top_tags(mbid, api_key)
    
    song = {
      "country" => country_name,
      "rank" => ele.attributes["rank"],
      "name" => ele.elements["name"].text,
      "duration" => ele.elements["duration"].text,
      "listeners" => ele.elements["listeners"].text,
      "artist" => ele.elements["artist"].elements["name"].text,
      "similiar_artists" => similiar_artists,
      "top_tags" => artist_top_tags
    }

    songs << song
  end
  puts ""
  db = { "top_songs"  => songs }
end

# write result to file

file = File.new("lastFm.json", "w")
file.write(db.to_json)
file.close

#print "#{db.to_json}\n"
