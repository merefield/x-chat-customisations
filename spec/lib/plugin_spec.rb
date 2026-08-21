# frozen_string_literal: true

RSpec.describe "X Chat Customisations plugin" do
  it "re-registers the auto join users scheduled job to run every 10 minutes" do
    expect(Jobs::Chat::AutoJoinUsers.every).to eq(10.minutes)
  end
end
