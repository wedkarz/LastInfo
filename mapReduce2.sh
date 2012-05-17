#!/bin/bash

curl 'localhost:9200/songs/_search?pretty=true' -d '
{
    "facets" : {
	    "all_artists" : {
	        "terms" : {
				"field": "artist",
				"size": 100
	        }
	    }
    }
}
'