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
require 'couchrest'
require 'logger'
require "enumerator"

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

      options.couchport = 5984
      opts.on("-i", "--couch-port PORT", "Port na którym uruchomiony jest CouchDB") do |port|
        options.couchport = port
      end
      
      options.couchdatabase = "songs"
      opts.on("-o", "--couch-db [NAME]", "Nazwa bazy danych (baza musi istnieć)") do |name|
        options.couchdatabase = name
      end
      
      options.couchhost = "localhost"
      opts.on("-s", "--couch-host [HOST]", "Host Couch serwera") do |host|
        options.couchhost = host
      end
      
      #####################################################
      # Mongodb options
            
      options.mongoport = 27017
      opts.on("-p", "--mongo-port PORT", "Port na którym uruchomiony jest MongoDb") do |port|
        options.mongoport = port
      end
      
      options.mongodatabase = "songs"
      opts.on("-d", "--mongo-db [NAME]", "Nazwa bazy danych") do |name|
        options.mongodatabase = name
      end
      
      options.mongohost = "localhost"
      opts.on("-a", "--mongo-host [HOST]", "Host Mongo serwera") do |host|
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

## Connecting to source
logger.info "Connecting to CouchDb on http://#{options.couchhost}:#{options.couchport}/#{options.couchdatabase}"
@inputDb = CouchRest.database("http://#{options.couchhost}:#{options.couchport}/#{options.couchdatabase}")

## Fetching data
@allDocsWithMeta = @inputDb.all_docs :include_docs => true 

## Some cleanup
@docs = []
@allDocsWithMeta['rows'].each do |row|
  @docs << row['doc']
end

## Connecting to destination db
logger.info "Connecting to MongoDb on http://#{options.mongohost}:#{options.mongoport}/#{options.mongodatabase}"
@connection = Mongo::Connection.new("#{options.mongohost}", options.mongoport)
@db = @connection.db("#{options.mongodatabase}")
@collection = @db["#{options.mongodatabase}"]

## insterting data
logger.info "Updating Mongo database result set"
@collection.insert(@docs)
logger.info "Done."
