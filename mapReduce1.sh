#!/bin/bash

curl 'localhost:9200/songs/_search?pretty=true&q=artist:Lana+Del+Ray' -d '
{
    "facets" : {
	    "artist_per_country" : {
	        "terms_stats" : {
				"size": 0,
	            "key_field" : "country",
				"value_field": "listeners"
	        }
	    }
    }
}
'
