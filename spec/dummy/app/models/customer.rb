class Customer < ApplicationRecord
  belongs_to :buying_group
  has_many :orders

  has_one :note, as: :notable
end
