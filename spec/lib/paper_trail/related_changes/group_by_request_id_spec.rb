require 'rails_helper'

RSpec.describe PaperTrail::RelatedChanges::GroupedByRequestId do
  let(:request_id) { SecureRandom.uuid }

  it "test case 1", versioning: true do
    PaperTrail.request.controller_info = { request_id: group1 = SecureRandom.uuid }
    buying_group1                      = BuyingGroup.create!(name: 'Sam Club')
    buying_group2                      = BuyingGroup.create!(name: 'Costco')
    PaperTrail.request.controller_info = { request_id: group2 = SecureRandom.uuid }
    customers                          = [
      Customer.create!(name: 'Jack', buying_group: buying_group2),
      Customer.create!(name: 'Jill', buying_group: buying_group2),
    ]
    PaperTrail.request.controller_info = { request_id: group3 = SecureRandom.uuid }
    products                           = [
      Product.create!(name: 'Toilet Paper', amount: 12),
      Product.create!(name: 'Apple Sauce', amount: 6),
      Product.create!(name: 'Hot Sauce', amount: 5),
      Product.create!(name: 'Light Bulb', amount: 4),
    ]

    PaperTrail.request.controller_info = { request_id: group4 = SecureRandom.uuid }
    order1                             = Order.create!(customer: customers[0], items: [OrderItem.new(product: products[0], quantity: 100)]).tap { |o| o.build_note(message: "Corona Virus!") }
    PaperTrail.request.controller_info = { request_id: group5 = SecureRandom.uuid }

    order2                             = Order.create!(customer: customers[1],
                                                       note:     Note.new(message: "Birthday Party"),
                                                       items:    [
                                                                   OrderItem.new(product: products[1], quantity: 2),
                                                                   OrderItem.new(product: products[2], quantity: 1),
                                                                   OrderItem.new(product: products[3], quantity: 1).tap { |o| o.build_note(message: "The one in the kitchen went out") },
                                                                 ],
    )
    PaperTrail.request.controller_info = { request_id: nil }

    aggregate_failures "buying_group" do
      results = described_class.new(
        item_type: 'buying_group',
        item_id:   buying_group2.id
      ).to_a

      expect(results.count).to eq(4)
      expect(results.map(&:to_h)[0]).to eq(
                                          { :children       =>
                                              [{ :description    => { :name => "Note", :value => nil },
                                                 :diffs          => [{ :attribute => "Note", :new => "Birthday Party", :old => nil }],
                                                 :event          => "create",
                                                 :requested_root => false,
                                                 :resource       => "Note",
                                                 :resource_id    => order2.note.id.to_s,
                                                 :timestamp      => order2.note.created_at,
                                                 :user           => "system",
                                                 :version_id     => order2.note.versions.last.id },
                                               { :description    => { :name => "Order Item", :value => nil },
                                                 :diffs          =>
                                                   [{ :attribute => :quantity, :new => 2, :old => nil },
                                                    { :attribute => :product, :new => "Apple Sauce", :old => nil }],
                                                 :event          => "create",
                                                 :requested_root => false,
                                                 :resource       => "OrderItem",
                                                 :resource_id    => order2.items.first.id.to_s,
                                                 :timestamp      => order2.items.first.created_at,
                                                 :user           => "system",
                                                 :version_id     => order2.items.first.versions.last.id },
                                               { :description    => { :name => "Order Item", :value => nil },
                                                 :diffs          =>
                                                   [{ :attribute => :quantity, :new => 1, :old => nil },
                                                    { :attribute => :product, :new => "Hot Sauce", :old => nil }],
                                                 :event          => "create",
                                                 :requested_root => false,
                                                 :resource       => "OrderItem",
                                                 :resource_id    => order2.items.second.id.to_s,
                                                 :timestamp      => order2.items.second.created_at,
                                                 :user           => "system",
                                                 :version_id     => order2.items.second.versions.last.id },
                                               { :description    => { :name => "Order Item", :value => nil },
                                                 :diffs          =>
                                                   [{ :attribute => :quantity, :new => 1, :old => nil },
                                                    { :attribute => :product, :new => "Light Bulb", :old => nil }],
                                                 :event          => "create",
                                                 :requested_root => false,
                                                 :resource       => "OrderItem",
                                                 :resource_id    => order2.items.third.id.to_s,
                                                 :timestamp      => order2.items.third.created_at,
                                                 :user           => "system",
                                                 :version_id     => order2.items.third.versions.last.id }],
                                            :description    => { :name => "Order", :value => nil },
                                            :diffs          => [{ :attribute => :customer, :new => "Jill", :old => nil }],
                                            :event          => "create",
                                            :requested_root => false,
                                            :resource       => "Order",
                                            :resource_id    => order2.id.to_s,
                                            :timestamp      => order2.created_at,
                                            :user           => "system",
                                            :version_id     => group5
                                          }
                                        )
      expect(results.map(&:to_h)[1]).to eq(
                                          {
                                            :children       =>
                                              [{ :description    => { :name => "Order Item", :value => nil },
                                                 :diffs          =>
                                                   [{ :attribute => :quantity, :new => 100, :old => nil },
                                                    { :attribute => :product, :new => "Toilet Paper", :old => nil }],
                                                 :event          => "create",
                                                 :requested_root => false,
                                                 :resource       => "OrderItem",
                                                 :resource_id    => order1.items.first.id.to_s,
                                                 :timestamp      => order1.items.first.created_at,
                                                 :user           => "system",
                                                 :version_id     => order1.items.first.versions.last.id }],
                                            :description    => { :name => "Order", :value => nil },
                                            :diffs          => [{ :attribute => :customer, :new => "Jack", :old => nil }],
                                            :event          => "create",
                                            :requested_root => false,
                                            :resource       => "Order",
                                            :resource_id    => order1.id.to_s,
                                            :timestamp      => order1.created_at,
                                            :user           => "system",
                                            :version_id     => group4
                                          }
                                        )
      expect(results.map(&:to_h)[2]).to eq(
                                          {
                                            :children       =>
                                              [{ :description    => { :name => "Customer", :value => "Jack" },
                                                 :diffs          => [{ :attribute => :name, :new => "Jack", :old => nil }],
                                                 :event          => "create",
                                                 :requested_root => false,
                                                 :resource       => "Customer",
                                                 :resource_id    => customers.first.id.to_s,
                                                 :timestamp      => customers.first.created_at,
                                                 :user           => "system",
                                                 :version_id     => customers.first.versions.last.id },
                                               { :description    => { :name => "Customer", :value => "Jill" },
                                                 :diffs          => [{ :attribute => :name, :new => "Jill", :old => nil }],
                                                 :event          => "create",
                                                 :requested_root => false,
                                                 :resource       => "Customer",
                                                 :resource_id    => customers.last.id.to_s,
                                                 :timestamp      => customers.last.created_at,
                                                 :user           => "system",
                                                 :version_id     => customers.last.versions.last.id }],
                                            :description    => { :name => "Buying Group", :value => "Costco" },
                                            :diffs          => [],
                                            :event          => "create",
                                            :requested_root => true,
                                            :resource       => "BuyingGroup",
                                            :resource_id    => buying_group2.id.to_s,
                                            :timestamp      => customers.map(&:created_at).min,
                                            :user           => "system",
                                            :version_id     => group2
                                          }
                                        )
      expect(results.map(&:to_h)[3]).to eq(
                                          {
                                            :children       => [],
                                            :description    => { :name => "Buying Group", :value => "Costco" },
                                            :diffs          => [{ :attribute => :name, :new => "Costco", :old => nil }],
                                            :event          => "create",
                                            :requested_root => true,
                                            :resource       => "BuyingGroup",
                                            :resource_id    => buying_group2.id.to_s,
                                            :timestamp      => buying_group2.versions.last.created_at,
                                            :user           => "system",
                                            :version_id     => group1
                                          }
                                        )
    end
  end
end
