class Film < ApplicationRecord
  self.table_name = 'film'

  has_many :film_actors
  has_many :actors, through: :film_actors
end
