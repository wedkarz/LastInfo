class Song < ActiveRecord::Base 
   def self.search_artist_per_country
     print RestClient.get 'localhost:9200/songs/_search?pretty=true&q=artist:Lana+Del+Ray'
   end
end