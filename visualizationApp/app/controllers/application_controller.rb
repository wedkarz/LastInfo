class ApplicationController < ActionController::Base
  protect_from_forgery
end

# def self.all_top_artists
#   @facet = '{
#       "facets" : {
#         "all_artists" : {
#             "terms" : {
#           "field": "artist",
#           "size": 100
#             }
#         }
#       }
#   }'
#   
#   @songs = RestClient.post "localhost:9200/songs/_search?pretty=true", @facet, content_type: :json
#   
#   @wynik = []
#   JSON.parse(@songs)['facets']['all_artists']['terms'].each do |term|
#     @wynik << { 'artist' => term['term'], 'count' => term['count'] }
#   end
#   # respond_to do |format|
#   #   format.html # all_top_artists.html.erb
#   #   format.json { render :json => @wynik}
#   # end
# end
