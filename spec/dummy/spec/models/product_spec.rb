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
                   { :type => "Note", :name => :notes }
                 ]
               },
               { :type => "Note", :name => :notes }
             ]
           }
         )
  end

  it "only_include_children" do
    expect(
      PaperTrail::RelatedChanges::Hierarchy.build(Product, only_include_children: [:notes]).to_simple
    ).to eq(
           {
             :type     => "Product", :name => "Product",
             :children => [
               { :type => "Note", :name => :notes }
             ]
           }
         )
  end
end
