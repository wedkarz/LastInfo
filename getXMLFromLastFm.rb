#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

require 'net/http'
require 'rexml/document'
require 'rubygems'
require 'json'
require 'optparse'
require 'ostruct'
require 'couchrest'
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
      opts.separator " wg. serwisu LastFm, a także zapisuje je do bazy XXX."
      opts.separator " Pozwala także na skopiowanie ich z bazy XXX do bazy YYY."
      opts.separator ""
      opts.separator ""
      opts.separator " Przykłady:"
      opts.separator ""
      opts.separator "Pobieranie:"
      opts.separator " #{$0} -w filename.json -l 10 -x"
      opts.separator ""
      opts.separator "Kopiowanie"
      opts.separator " #{$0} -v -p 5984 -o 27017 -d ksiazki -c ksiazki -a 192.168.0.1 -j 192.168.0.2"
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

      #####################################################
      # Databse XXX options

      #####################################################
      # Databse YYY options

      #####################################################
      # Runtime options

      options.get_web = false
      opts.on("-w", "--[no-]get-from-web", "Get data from web") do
        options.get_web = true
      end

      options.proccess = false
      opts.on("-x", "--[no-]proccess", "Proccess data from specified file") do
        options.proccess = true
      end
      
      options.write_to_file = true
      opts.on("-t", "--[no-]write-to-temp", "Writes to temp file (by default)") do
        options.write_to_file = true
      end
      
      options.filename = 'temp.json'
      opts.on("-f", "--filename [FILENAME]", "Nazwa pliku przechowującego jsona") do |filename|
        options.filename = filename
      end
      
      options.datasource = "web"
      opts.on("-s", "--datasource TYPE [web, couch, mongo, elastic]", "Ustawia źródło danych (web, couch, mongo, elastic)") do |type|
        options.datasource = type
      end
      
      options.output = "file"
      opts.on("-o", "--output TYPE [file, couch, mongo, elastic]", "Ustawia miejsce docelowe dla danych") do |type|
        options.output = type
      end
      
      options.couchport = 5984
      opts.on("-p", "--couch-port PORT", "Port na którym uruchomiony jest CouchDB") do |port|
        options.couchport = port
      end
      
      options.couchdatabase = "last_info"
      opts.on("-d", "--couch-db [NAME]", "Nazwa bazy danych") do |name|
        options.couchdatabase = name
      end
      
      options.couchhost = "localhost"
      opts.on("-h", "--couch-host [HOST]", "Host Couch serwera") do |host|
        options.couchhost = host
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

  #options.mongoport = 27017
  #options.mongodatabase = "couch"
  #options.mongocollection = "gutenberg"
  #options.mongohost = "localhost"
  
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

 if options.datasource == "web"
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
        "rank" => ele.attributes["rank"],
        "name" => ele.elements["name"].text,
        "duration" => ele.elements["duration"].text,
        "listeners" => ele.elements["listeners"].text,
        "artist" => ele.elements["artist"].elements["name"].text,
        #"similiar_artists" => similiar_artists,
        #"top_tags" => artist_top_tags
      }

      songs << song
    end
    db = { "docs"  => songs }
  end
  
 if options.datasource == "file"
   file = File.new(options.filename, "r")
 end
 
 if options.output == "file"
    # write result to file
    json = db.to_json
    file = File.new(options.filename, "w")
  file.write(songs.to_json)
  file.close
  end
end

if options.output == "couch"
  @outputDb = CouchRest.database("http://#{options.couchhost}:#{options.couchport}/#{options.couchdatabase}")
  @outputDb.bulk_save(songs)
end
#print "#{db.to_json}\n"
