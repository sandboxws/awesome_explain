class LineItem
  include Mongoid::Document
  include Mongoid::Timestamps

  field :itemCount, type: Integer
  # field :prodId, type: String
  # field :orderId, type: String

  belongs_to :order, foreign_key: :orderId, inverse_of: :orders
  belongs_to :product, foreign_key: :prodId, inverse_of: :line_items
end
