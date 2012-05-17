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
      opts.separator " Skrypt przenosi dane z MongoDb do Elastic Search"
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
      # ElasticSearch options
            
      options.elasticport = 9200
      opts.on("-p", "--elastic-port PORT", "Port na którym uruchomiony jest ElasticSearch") do |port|
        options.elasticport = port
      end
      
      options.elasticindex = "songs"
      opts.on("-d", "--elastic-db [NAME]", "Nazwa bazy danych") do |name|
        options.elasticindex = name
      end
      
      options.elastichost = "localhost"
      opts.on("-h", "--elastic-host [HOST]", "Host ElasticSearch serwera") do |host|
        options.elastichost = host
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

## Migrating data to Elastic
logger.info "Updating ElasticSearch indexes on http://#{options.elastichost}:#{options.elasticport}/#{options.elasticindex}"
@sourceSet.each do |song|
  id = song['_id'].gsub(/\s+/, "+")
  song.delete('_id')
  RestClient.put "http://#{options.elastichost}:#{options.elasticport}/#{options.elasticindex}/song/#{id}", song.to_json, :content_type => :json
  if options.verbose
    logger.info "Added #{id}"
  end
end

logger.info "Done."