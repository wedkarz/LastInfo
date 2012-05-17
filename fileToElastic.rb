#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

require 'net/http'
require 'rexml/document'
require 'rubygems'
require 'json'
require 'optparse'
require 'ostruct'
require 'tire'
require 'date'
require 'logger'
require 'rest_client'

###############################################################
# Settings - Option Parser
class OptParserLastFm
  def self.parse(args)

    options = OpenStruct.new

    @opts = OptionParser.new do |opts|
      opts.banner = "Użycie: #{$0} [OPCJE]"
      opts.separator ""
      opts.separator "------------------------------------------------------------------------------"
      opts.separator " Skrypt zapisuje dane o piosenkach (LastFm) z pliku json do bazy ElasticSearch"
      opts.separator "------------------------------------------------------------------------------"
      opts.separator ""

      #####################################################
      # Datasource options      

      options.filename = 'temp.json'
      opts.on("-f", "--filename [FILENAME]", "Nazwa pliku przechowującego jsona") do |filename|
        options.filename = filename
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

## Filename
file = File.new(options.filename, "r")
logger.info "Loading data from file #{options.filename} to index 'http://#{options.elastichost}:#{options.elasticport}/#{options.elasticindex}'"

parsed_file = JSON.parse(file.read)

parsed_file["songs"].each do |song|
  id = song['_id'].gsub(/\s+/, "+")
  song.delete('_id')
  RestClient.put "http://#{options.elastichost}:#{options.elasticport}/#{options.elasticindex}/song/#{id}", song.to_json, :content_type => :json
  if options.verbose
    logger.info "Added #{id}"
  end
end

logger.info "Done."
