class Customer
  include Mongoid::Document
  include Mongoid::Timestamps

  # field :_id, type: String
  field :first_name, type: String
  field :last_name, type: String
  field :email, type: String
  field :gender, type: String
  field :Street, type: String
  field :City, type: String
  field :State, type: String
  field :ZIP, type: String
  field :SSN, type: String
  field :Phone, type: String
  field :Company, type: String
  field :DOB, type: DateTime

  has_many :orders, foreign_key: :customerId
end
