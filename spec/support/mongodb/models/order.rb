class Order
  include Mongoid::Document
  include Mongoid::Timestamps

  # field :_id, type: String
  field :orderDate, type: DateTime
  field :orderStatus, type: Integer
  # field :customerId, type: String

  belongs_to :customer,foreign_key: :customerId, inverse_of: :orders
  has_many :line_items, foreign_key: :orderId
end
