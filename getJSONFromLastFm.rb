#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

require 'net/http'
require 'rexml/document'
require 'rubygems'
require 'json'
require 'optparse'
require 'ostruct'
require 'date'

###############################################################
# Settings - Option Parser
class OptParserLastFm
  def self.parse(args)

    options = OpenStruct.new

    @opts = OptionParser.new do |opts|
      opts.banner = "Użycie: #{$0} [OPCJE]"
      opts.separator ""
      opts.separator "------------------------------------------------------------------------------"
      opts.separator " Skrypt pobiera dane o najczęściej odsłuchiwanych piosenkach"
      opts.separator " wg. serwisu LastFm"
      opts.separator ""
      opts.separator "------------------------------------------------------------------------------"
      opts.separator ""

      #####################################################
      # Datasource options

      options.topSongsLimit = 10
      opts.on("-l", "--limit N", Numeric, "Ilość najlepszych piosenek brana pod uwagę w każdym kraju") do |n|
        options.topSongsLimit = n
      end

      options.countries = ["poland", "spain", "malta", "croatia", "ukraine", "latvia", "saudi+arabia", "iraq", "japan", "china", "mexico", "canada", "ireland", "armenia", "south+africa", "czech+republic", "portugal", "switzerland", "finland", "norway", "sweden", "turkey", "australia", "united+states", "slovakia", "united+kingdom", "germany", "netherland", "france", "belgium", "russia"]
      opts.on("-c", "--countries COUNTRIES", Array, "Państwa o których informacje chcemy uzyskać") do |countries|
        options.countries = countries
      end

      options.api_key = '2d8dc0a751b42a8e4f6ca5aeb5c0c867'
      opts.on("-k", "--api-key API_KEY", "Klucz API do pobieranie danych z LastFm") do |api_key|
        options.api_key = api_key
      end
      
      options.filename = 'temp.json'
      opts.on("-f", "--filename [FILENAME]", "Nazwa pliku przechowującego jsona") do |filename|
        options.filename = filename
      end
      
      opts.on_tail("-h", "--help", "wypisz pomoc") do
        puts opts
        exit
      end

      opts.on_tail("-v", "--[no-]verbose", "Run verbosely") do |v|
        options.verbose = v
      end
    end

    @opts.parse!(args)
    options
  
  end # parse()
end # class OptParserLastFm


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

options = OptParserLastFm.parse(ARGV)

songs = []
db = []

puts ">>> Fetching data from LastFm >>>"
options.countries.each do |country|

  printf "fetching #{country}...\n"

  url = "http://ws.audioscrobbler.com/2.0/?method=geo.gettoptracks&country=#{country}&limit=#{options.topSongsLimit}&api_key=#{options.api_key}"

  # get the XML data as a string
  xml_data = Net::HTTP.get_response(URI.parse(url)).body

  # extract song information
  doc = REXML::Document.new(xml_data)

  doc.elements.each('lfm/toptracks/track') do |ele|

    mbid = ele.elements["artist"].elements["mbid"].text
    country_name = ele.parent.attributes["country"]

    # get additional info from Last.fm api

    #similiar_artists = LastAPI::similiar_artists(mbid, 5, options.api_key)
    #artist_top_tags = LastAPI::artist_top_tags(mbid, options.api_key)

    song = {
      "_id" => "#{Date.today}_#{country_name}_#{ele.attributes["rank"]}",
      "country" => country_name,
      "rank" => Integer(ele.attributes["rank"]),
      "name" => ele.elements["name"].text,
      "duration" => Integer(ele.elements["duration"].text),
      "listeners" => Integer(ele.elements["listeners"].text),
      "artist" => ele.elements["artist"].elements["name"].text,
      #"similiar_artists" => similiar_artists,
      #"top_tags" => artist_top_tags
    }

    songs << song
  end
  db = { "songs"  => songs }
end

# write result to file
json = db.to_json
file = File.new(options.filename, "w")
file.write(db.to_json)
file.close
