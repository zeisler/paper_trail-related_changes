require "rails_helper"

RSpec.describe "Request", type: :request do
  describe "#GET" do
    it "shows related versions", versioning: true do
      User.create!(name: "Dustin")
      buying_group = BuyingGroup.create!(name: "Sams Club")
      customer     = Customer.create!(buying_group: buying_group)
      get "/related_changes", params: { type: "Customer", id: customer.id }
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body).keys).to eq(["data", "meta"])
      expect(
        JSON.parse(response.body)["data"].map { |d| d.except("timestamp", "version_id") }
      ).to eq([{ "diffs"          =>
                   [{
                      "attribute" => "buying_group",
                      "new"       => "Sams Club",
                      "old"       => nil,
                    }],
                 "children"       => [],
                 "description"    => { "name" => "Customer", "value" => nil },
                 "event"          => "create",
                 "requested_root" => true,
                 "resource"       => "Customer",
                 "resource_id"    => customer.id.to_s,
                 "user"           => "system" }])
    end

    it "shows related versions with limit", versioning: true do
      User.create!(name: "Dustin")
      buying_group = BuyingGroup.create!(name: "Sams Club")
      customer     = Customer.create!(buying_group: buying_group)
      customer.update(name: "Fred")
      customer.update(name: "Sam")
      get "/related_changes", params: { type: "Customer", id: customer.id, limit: 2 }
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body).keys).to eq(["data", "meta"])
      expect(JSON.parse(response.body)["data"].count).to eq(2)
    end
  end
end
