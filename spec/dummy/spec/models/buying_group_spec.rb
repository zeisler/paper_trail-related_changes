require 'paper_trail'
require 'rails_helper'

RSpec.describe BuyingGroup do
  it "builds hierarchy" do
    expect(
      PaperTrail::RelatedChanges::Hierarchy.build(BuyingGroup).to_simple
    ).to eq(
           {
             :type     => "BuyingGroup", :name => "BuyingGroup",
             :children => [
               {
                 :type     => "Customer", :name => :customers,
                 :children => [
                   {
                     :type     => "Order", :name => :orders,
                     :children => [
                       { :type => "OrderItem", :name => :items },
                       { :type => "Note", :name => :note }
                     ]
                   },
                   { :type => "Note", :name => :note }
                 ]
               }
             ]
           }
         )
  end
end
