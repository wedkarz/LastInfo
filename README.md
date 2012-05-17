  Bazy NoSQL
===============

### 1. Ciekawe dane

Dane pochodzą z serwisu [LastFm](http://lastfm.pl/) i zawierają informacje o zadanej liczbie (domyślnie 10) najpopularniejszych piosenek w kilkunastu krajach.
   
   * Przykładowe dane znajdują się w folderze jsons (zawierające większą ilość danych)

   * Można też pobrać aktualne dane korzystając ze skryptu ./getJSONFromLastFm.rb (i API Lastfm). Przykład:
      
      `./getJSONFromLastFm.rb -f temp.json -l 100 -c Poland,Ukraine`

      * Parametry: 
                 `-f` nazwa pliku docelowego (domyślnie temp.json)
                 `-l` ilość topwych piosenek z każdego kraju (domyślnie 10)
                 `-c` lista krajów

      * Wszelkie parametry są opcjonalne (posiadają wartości domyślne).
      
   * Poniżej fragment przyladowego pliku JSON
      
```json
{
    "songs": [
        {
            "_id": "2012-05-17_Poland_1", 
            "artist": "Metallica", 
            "country": "Poland", 
            "duration": 407, 
            "listeners": 2826, 
            "name": "Enter Sandman", 
            "rank": 1
        }, 
        ...
]}
```


### 2. Eksport do bazy

Aby zapisać dane w którejkolwiek z baz Mongodb, CouchDb lub ElasticSearch należy uruchomić odpowiedni skrypt (`-f` to ścieżka do pliku .json)

_UWAGA!_ Dla poprawności dzialania Map Reduce, zanim skorzystamy z ElasticSearch proszę o upewnienie się, że:
   * nie istnieje jeszcze indeks "songs" - można go usunąć skryptem `./deleteIndex.sh`
   * utworzyliśmy sensowny mapping dla danych, które będziemy przesylać w JSONach - skrypt `./createMapping.sh`
   Jeśli nie wykonamy czyszczenia indeksu możemy natknąć się na konflikt przy definiowaniu mappingu.

   `./fileToCouch.rb -f temp.json`

   `./fileToMongo.rb -f temp.json`

   `./fileToElastic.rb -f temp.json`

   Parametry baz danych (host, port, nazwa bazy/kolekcji) można ustawić przy pomocy odpowiednich przełączników. każdy skrypt posiada przełącznik -h z krótką pomocą.
   
   Nie zapominajmy aby wcześniej niezbędne bazy danych uruchomić ;)


### 3. Przenoszenie między bazami

Aby przenieść dane z jednej bazy do drugiej wystarczy posłużyć się skryptami: `[mongo|couch]To[mongo|couch|elastic].rb` (baza źródłowa i docelowa muszą być inne).
Podobnie jak wyżej dostępna jest pomoc.


### 4. Map Reduce

Map reduce zostal osiągnięty poprzez wyszukiwanie facetowe w bazie Elastic Search. W repozytorium znajdują się skrypty shellowe, których treść wykorzystywana jest w późniejszej aplikacji.
Do wyszukiwania facetowego potrzebny jest nam jednak dobry mapping, więc...

  
   * `./mapReduce1.sh` - zawiera przyklad zgrupowanej statysyki odsluchan w danym kraju dla wybranego artysty. Poniżej treść skryptu:

```
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
```

  * `./mapReduce2.sh` - Grupuje wyniki wyszukiwania 50 najpopularniejszych artystów (wyznaczanych poprzez lączną ilość topowych piosenek na listach poszczególnych krajów). Poniżej treść skryptu:

```
curl 'localhost:9200/songs/_search?pretty=true' -d '
{
    "facets" : {
      "all_artists" : {
	        "terms" : {
				"field": "artist",
				"size": 50
	        }
	    }
    }
}
'
```


### 5. Wizualizacja danych

Do wizualizacji danych pozwolilem sobie skorzystać z kilku narzędzi:
* __[Ruby on Rails](http://rubyonrails.pl/)__ jako backend i datasource oraz twór który wszystko ogarnie
* __[Google charts API](https://developers.google.com/chart/)__ a konktretniej [Geo chart](https://developers.google.com/chart/interactive/docs/gallery/geochart)
* __[Twitter bootstrap](http://twitter.github.com/bootstrap/)__, żeby nie przejmować się zanadto layoutem, ale i by wszystko wyglądalo dość przyzwoicie

Aby odpalić aplikację przechodzimy do katalogu `visualizationApp` i standardowo uruchamiamy aplikację railsową, pamiętając by dociągnąć potrzebne gemy, np.:
* `bundle install`
* `rails server thin`

i cieszymy się widokiem aplikacji pod adresem `localhost:3000`.

### 6. TODO?
4. TODO: 
  * z braku czasu i motywacji nie używalem w aplikacji wizualizującej gemu 'tire', toteż celem uporządkowania warto będzie do niego jeszcze sięgnąć,
  * można rozszerzyć i sparametryzować aplikację tak by użytkownik mógl jak najlepiej dostosować zapytanie do potrzeb i ciekawości,
  * chętnie przyjrzę się także bibliotece d3.js, żeby troszeczkę wizualizację zdynamizować i urozmaicić.

### Credits

Pozdrawiam,
Artur Rybak