class Product
  include Mongoid::Document
  include Mongoid::Timestamps

  # field :_id, type: String
  field :productName, type: String
  field :price, type: Float
  field :priceDate, type: DateTime
  field :color, type: String
  field :Image, type: String

  has_many :line_items, foreign_key: :prodId
end
