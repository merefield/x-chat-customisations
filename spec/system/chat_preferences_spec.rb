# frozen_string_literal: true

RSpec.describe "X Chat Customisations chat preferences" do
  fab!(:current_user, :user)

  let(:chat_preferences_page) { PageObjects::Pages::UserPreferencesChat.new }
  let(:form) { PageObjects::Components::FormKit.new(".form-kit") }

  before do
    chat_system_bootstrap
    sign_in(current_user)
  end

  it "restores chat email notification settings on the Chat Preferences page" do
    current_user.user_option.update!(
      chat_email_frequency: UserOption.chat_email_frequencies[:when_away],
    )

    chat_preferences_page.visit

    expect(form.field("chat_email_frequency").value).to eq("when_away")

    form.field("chat_email_frequency").select("never")
    form.submit

    expect(current_user.user_option.reload.chat_email_frequency).to eq("never")
  end
end
