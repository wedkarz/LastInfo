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
      opts.separator " Skrypt zapisuje dane o piosenkach (LastFm) z pliku json do bazy CouchDB"
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
      opts.on("-p", "--couch-port PORT", "Port na którym uruchomiony jest CouchDB") do |port|
        options.couchport = port
      end
      
      options.couchdatabase = "last_info"
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

## Filename
file = File.new(options.filename, "r")
logger.info "Loading data from file #{options.filename}"

parsed_file = JSON.parse(file.read)
output_data = { "docs" => parsed_file["songs"] }.to_json
#logger.info "#{options.filename} parsed: #{output_data}"

@outputDb = CouchRest.database!("http://#{options.couchhost}:#{options.couchport}/#{options.couchdatabase}")
logger.info "Connecting to CouchDb on http://#{options.couchhost}:#{options.couchport}/#{options.couchdatabase}"

logger.info "Updating database result set"
result = @outputDb.bulk_save(parsed_file["songs"])
logger.info "Done."
#logger.info "Save result #{result.to_json}"
