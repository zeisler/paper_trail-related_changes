require 'rails_helper'

RSpec.describe Product do
  it "builds hierarchy" do
    expect(
      PaperTrail::RelatedChanges::Hierarchy.build(Product).to_simple
    ).to eq(
           {
             :type     => "Product", :name => "Product",
             :children => [
               {
                 :type     => "OrderItem", :name => :items,
                 :children => [
                   { :type => "Note", :name => :note }
                 ]
               },
               { :type => "Note", :name => :notes }
             ]
           }
         )
  end
end
