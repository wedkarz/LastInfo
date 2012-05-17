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
      opts.separator " Skrypt przenosi dane z CouchDb do ElasticSearch"
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
      opts.on("-a", "--elastic-host [HOST]", "Host ElasticSearch serwera") do |host|
        options.elastichost = host
      end
      
      opts.on_tail("-h", "--help", "wypisz pomoc") do
        puts opts
        exit
      end

      options.verbose = false
      opts.on_tail("-v", "--[no-]verbose", "Run verbosely") do
        options.verbose = true
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

## insterting data
logger.info "Updating ElasticSearch indexes on http://#{options.elastichost}:#{options.elasticport}/#{options.elasticindex}"
@docs.each do |song|
  id = song['_id'].gsub(/\s+/, "+")
  song.delete('_id')
  
  RestClient.put "http://#{options.elastichost}:#{options.elasticport}/#{options.elasticindex}/song/#{id}", song.to_json, :content_type => :json
  if options.verbose
    logger.info "Added #{id}"
  end
end

logger.info "Done."
