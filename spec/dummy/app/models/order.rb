class Order < ApplicationRecord
  belongs_to :customer
  has_many :items, class_name: 'OrderItem'

  has_one :note, as: :notable
end
