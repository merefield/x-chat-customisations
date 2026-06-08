# frozen_string_literal: true

RSpec.describe "X Chat Customisations mobile channel settings layout", mobile: true do
  fab!(:admin, :admin)
  fab!(:channel_1, :category_channel)

  let(:chat_page) { PageObjects::Pages::Chat.new }
  let(:channel_settings_page) { PageObjects::Pages::ChatChannelSettings.new }

  before do
    chat_system_bootstrap
    sign_in(admin)
  end

  it "does not apply top-level route clipping to nested channel settings routes" do
    chat_page.visit_channel_settings(channel_1)

    expect(channel_settings_page).to have_name(channel_1.title)

    route_styles = page.evaluate_script(<<~JS)
        (() => {
          const settingsRoute = document.querySelector(".c-routes.--channel-info-settings");
          const navRoute = document.querySelector(".c-routes.--channel-info-nav");

          return {
            settingsOverflow: getComputedStyle(settingsRoute).overflow,
            settingsDisplay: getComputedStyle(settingsRoute).display,
            navOverflow: getComputedStyle(navRoute).overflow,
          };
        })();
      JS

    expect(route_styles).to include(
      "settingsOverflow" => "visible",
      "settingsDisplay" => "block",
      "navOverflow" => "visible",
    )
  end
end
