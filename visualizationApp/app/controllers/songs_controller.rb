class SongsController < ApplicationController
  # GET /songs
  # GET /songs.json
  def index
    @all_artists = SongsController::all_artists
  end

  # GET /artist_per_country/Lana+Del+Rey
  # GET /artist_per_country/Lana+Del+Rey.json
  def artist_per_country
    @all_artists = SongsController::all_artists
    
    @facet = '{
    "facets" : {
      "artist_per_country" : {
        "terms_stats" : {
          "size": 0,
          "key_field" : "country",
          "value_field": "listeners"
        }
      }
    }
    }'
    @songs = RestClient.post "localhost:9200/songs/_search?pretty=true&q=artist:#{params['artist']}", @facet, content_type: :json 

    @wynik = []
    JSON.parse(@songs)['facets']['artist_per_country']['terms'].each do |term|
      @wynik << { 'country' => term['term'], 'total' => term['total'] }
    end
    
    respond_to do |format|
      format.html # artist_per_country.html.erb
      format.json { render :json => @wynik}
    end
  end
  
  #### all_artists for sidebar
  def self.all_artists
      @facet = '{
          "facets" : {
      	    "all_artists" : {
      	        "terms" : {
      				"field": "artist",
      				"size": 100
      	        }
      	    }
          }
      }'

      @songs = RestClient.post "localhost:9200/songs/_search?pretty=true", @facet, content_type: :json

      @all_artists = []
      JSON.parse(@songs)['facets']['all_artists']['terms'].each do |term|
        @all_artists << { 'artist' => term['term'], 'count' => term['count'] }
      end
      
      @all_artists
  end
end
