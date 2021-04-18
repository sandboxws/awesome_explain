class FilmActor < ApplicationRecord
  self.table_name = 'film_actor'

  belongs_to :actor
  belongs_to :film
end
