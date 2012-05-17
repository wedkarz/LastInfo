#!/bin/bash

curl 'localhost:9200/songs/_search?pretty=true' -d '
{
	"query": {
		"term": {
			"artist": "Lana Del Rey"
		}
	},
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
