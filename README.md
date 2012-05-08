  Bazy NoSQL
===============

1. Dane pochodzą z serwisu LastFm (lastfm.pl) i zawierają informacje o zadanej liczbie najpopularniejszych piosenek w kilkunastu krajach.
   
   * Przykładowe dane znajdują się w folderze jsons

   * Można też pobrać aktualne dane korzystając ze skryptu ./getJSONFromLastFm.rb (i API Lastfm). Przykład:
      
      `./getJSONFromLastFm.rb -f temp.json -l 100 -c Poland,Ukraine`

      Parametry: 
                 `-f` nazwa pliku docelowego (domyślnie temp.json)
                 `-l` ilość topwych piosenek z każdego kraju (domyślnie 10)
                 `-c` lista krajów

      Wszelkie parametry są opcjonalne (posiadają wartości domyślne).

2. Aby zapisać dane w którejkolwiek z baz Mongodb, CouchDb lub ElasticSearch należy uruchomić odpowiedni skrypt (`-f` to ścieżka do pliku .json):

   `./fileToCouch.rb -f temp.json`

   `./fileToMongo.rb -f temp.json`

   `./fileToElastic.rb -f temp.json`

   Parametry baz danych (host, port, nazwa bazy/kolekcji) można ustawić przy pomocy odpowiednich przełączników. każdy skrypt posiada przełącznik -h z krótką pomocą.

3. Aby przenieść dane z jednej bazy do drugiej wystarczy posłużyć się skryptami: `[mongo|couch]To[mongo|couch|elastic].rb` (baza źródłowa i docelowa muszą być inne).
   Podobnie jak wyżej dostępna jest pomoc.
