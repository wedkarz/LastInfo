#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

require 'net/http'
require 'rexml/document'
require 'rubygems'
require 'json'
require 'optparse'
require 'ostruct'
require 'mongo'
require 'date'
require 'logger'

###############################################################
# Settings - Option Parser
class OptParserLastFm
  def self.parse(args)

    options = OpenStruct.new

    @opts = OptionParser.new do |opts|
      opts.banner = "Użycie: #{$0} [OPCJE]"
      opts.separator ""
      opts.separator "------------------------------------------------------------------------------"
      opts.separator " Skrypt zapisuje dane o piosenkach (LastFm) z pliku json do bazy MongoDb"
      opts.separator "------------------------------------------------------------------------------"
      opts.separator ""

      #####################################################
      # Datasource options      

      options.filename = 'temp.json'
      opts.on("-f", "--filename [FILENAME]", "Nazwa pliku przechowującego jsona") do |filename|
        options.filename = filename
      end

      #####################################################
      # CouchDB options

      options.mongoport = 27017
      opts.on("-p", "--couch-port PORT", "Port na którym uruchomiony jest MongoDb") do |port|
        options.mongoport = port
      end
      
      options.mongodatabase = "last_info"
      opts.on("-d", "--couch-db [NAME]", "Nazwa bazy danych") do |name|
        options.mongodatabase = name
      end
      
      options.mongohost = "localhost"
      opts.on("-h", "--couch-host [HOST]", "Host Mongo serwera") do |host|
        options.mongohost = host
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

#####################################################
# Main body

## Logger
logger = Logger.new(STDERR)
logger.level = Logger::INFO  # default logging level

## Options
options = OptParserLastFm.parse(ARGV)

## Filename
file = File.new(options.filename, "r")
logger.info "Loading data from file #{options.filename}"

parsed_file = JSON.parse(file.read)
output_data = { "docs" => parsed_file["songs"] }.to_json
#logger.info "#{options.filename} parsed: #{output_data}"

@connection = Mongo::Connection.new("#{options.mongohost}", options.mongoport)
@db = @connection.db("#{options.mongodatabase}")
@collection = @db["#{options.mongodatabase}"]
#@outputDb = CouchRest.database!("http://#{options.couchhost}:#{options.couchport}/#{options.couchdatabase}")
logger.info "Connecting to MongoDb on http://#{options.mongohost}:#{options.mongoport}/#{options.mongodatabase}"


logger.info "Updating database result set"
@collection.insert(parsed_file["songs"])
logger.info "Done."
