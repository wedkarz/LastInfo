#!/bin/bash

# create index
curl -XPUT 'http://localhost:9200/songs/'

# create mapping
curl -XPUT 'localhost:9200/songs/song/_mapping' -d '
{
    "song" : {
        "properties" : {
            "artist": { "type": "string", "index": "not_analyzed"},
			"duration": { "type": "integer"},
			"name": { "type": "string" },
			"country": { "type": "string", "index": "not_analyzed"},
			"rank": {"type": "integer"},
			"listeners": {"type": "integer"}
        }
    }
}
'
