#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

require 'net/http'
require 'rexml/document'
require 'rubygems'
require 'json'
require 'optparse'
require 'ostruct'
require 'mongo'
require 'couchrest'
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
      opts.separator " Skrypt przenosi dane z MongoDb do CouchDb"
      opts.separator "------------------------------------------------------------------------------"
      opts.separator ""

      #####################################################
      # Mongodb options

      options.mongoport = 27017
      opts.on("-i", "--mongo-port PORT", "Port na którym uruchomiony jest MongoDb") do |port|
        options.mongoport = port
      end
      
      options.mongodatabase = "songs"
      opts.on("-o", "--mongo-db [NAME]", "Nazwa bazy danych") do |name|
        options.mongodatabase = name
      end
      
      options.mongohost = "localhost"
      opts.on("-s", "--mongo-host [HOST]", "Host Mongo serwera") do |host|
        options.mongohost = host
      end
      
      #####################################################
      # CouchDB options

      options.couchport = 5984
      opts.on("-p", "--couch-port PORT", "Port na którym uruchomiony jest CouchDB") do |port|
        options.couchport = port
      end
      
      options.couchdatabase = "songs"
      opts.on("-d", "--couch-db [NAME]", "Nazwa bazy danych (baza musi istnieć)") do |name|
        options.couchdatabase = name
      end
      
      options.couchhost = "localhost"
      opts.on("-a", "--couch-host [HOST]", "Host Couch serwera") do |host|
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
  
  end # parse()
end # class OptParserLastFm

#####################################################
# Main body

## Logger
logger = Logger.new(STDERR)
logger.level = Logger::INFO  # default logging level

## Options
options = OptParserLastFm.parse(ARGV)

## Connecting to source database
logger.info "Connecting to MongoDb on http://#{options.mongohost}:#{options.mongoport}/#{options.mongodatabase}"
@connection = Mongo::Connection.new("#{options.mongohost}", options.mongoport)
@db = @connection.db("#{options.mongodatabase}")
@collection = @db["#{options.mongodatabase}"]

## Obtaining data
logger.info "Getting source data from Mongo"
@sourceSet = @collection.find.to_a

## Connecting to destinantion database
logger.info "Connecting to CouchDb on http://#{options.couchhost}:#{options.couchport}/#{options.couchdatabase}"
@outputDb = CouchRest.database!("http://#{options.couchhost}:#{options.couchport}/#{options.couchdatabase}")

## Migrating data to CouchDb
logger.info "Migrating data to CouchDb"
@outputDb.bulk_save(@sourceSet)

logger.info "Done."