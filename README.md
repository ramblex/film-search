These ruby scripts make it easy to check which films are on TV in the next 7
days (in the UK). An sqlite database is used to store the films to allow
offline viewing.

Prerequisites
-------------

Ruby must be installed and the following rubygems are required.

- sqlite3
- active_support

film-search.rb
--------------

To get started, update the database with the following command

    ruby film_search.rb --update

This will update the database with films from the next 7 days and list any 
films it finds.

In general film_search usage is as follows:

    ruby film_search.rb [Options] [SQL conditions]

so, for example we could get all films that were released after 2002 by using 
the following:

    ruby film_search.rb "year > 2002"

By default (and unless an order is specified), films will be output in order of
date and start time.

The columns stored in the database are as follows and can be used in the 
'SQL conditions'

-  title (Title of the film)
-  date (Date the film starts)
-  year (Year the film was released)
-  start_time (Time the film starts)
-  channel (Which TV channel the film is on)
-  description (A description of the film)

### Shortcuts ###

There are a few shortcuts that film_search understands to make it easier to
perform frequently used functions:

The following will output all of today's films as well as those which start in
the early hours of tomorrow (up until 3 a.m.)

    ruby film_search.rb today

The following will output films which are on tomorrow

    ruby film_search.rb tomorrow

### Options ###

There are a number of options which can be given to film_search as arguments

-  `--update`     Updates the database with films from the next 7 days
-  `--delete-old` Deletes films which have already happened
-  `--print-hash` Prints the whole hash that is returned from the database (i.e. 
  does 'SELECT * FROM films.db')
-  `--no-output`  Don't print any output. This is sometimes useful to avoid 
  cluttering up the screen - particularly when updating
-  `--org-mode`   Output text which is suitable for emacs org-mode - provides 
  links to IMDB for each of the films
-  `--wipe`       Delete the database and create a fresh one

### imdb.rb ###

This is a work in progress and scrapes IMDB to get information about a given
film. Usage is as follows:

    ruby imdb.rb [FILM]

For example, 

    ruby imdb.rb "Troy (2004)"

returns

    Looking up 'Troy (2004)'
    Genre: Action, History, Romance, more
    Plot:
    An adaptation of Homer's great epic, the film follows the assault on Troy by the united Greek forces and chronicles the fates of the men involved.
