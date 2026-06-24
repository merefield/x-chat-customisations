# frozen_string_literal: true

RSpec.describe ChatCustomisations::TenantReplayOneboxPreprocessor do
  let(:replay_url) { "https://app.pingpod.com/replays/066380c9-0f21-43a5-91af-fbe2c98f2c4b" }
  let(:tenant_replay_url_regex) { %r{^https?://(app\.pingpod\.com)/replays?/([\-0-9a-zA-Z]+)$} }

  before { described_class.stubs(:tenant_replay_url_regex).returns(tenant_replay_url_regex) }

  it "isolates tenant replay URLs in normal text" do
    expect(described_class.call("Watch this #{replay_url} today")).to eq(
      "Watch this \n\n#{replay_url}\n\n today",
    )
  end

  it "preserves trailing punctuation after the isolated replay URL" do
    expect(described_class.call("Watch this #{replay_url}.")).to eq(
      "Watch this \n\n#{replay_url}\n\n.",
    )
  end

  it "does not isolate replay URLs for other tenants" do
    other_tenant_url =
      "https://zerozerotwo.podplay.app/replays/98c7881b-d47d-4a4b-9821-188beffcc5e2"

    expect(described_class.call("Watch this #{other_tenant_url} today")).to eq(
      "Watch this #{other_tenant_url} today",
    )
  end

  it "does not rewrite markdown link destinations" do
    expect(described_class.call("[Watch this](#{replay_url})")).to eq("[Watch this](#{replay_url})")
  end

  it "isolates parenthesized replay URLs in normal text" do
    expect(described_class.call("Watch this (#{replay_url})")).to eq(
      "Watch this (\n\n#{replay_url}\n\n)",
    )
  end

  it "does not isolate replay URLs in inline code" do
    expect(described_class.call("Use `#{replay_url}` as an example")).to eq(
      "Use `#{replay_url}` as an example",
    )
  end

  it "does not isolate replay URLs in fenced code blocks" do
    message = <<~TEXT
      ```
      #{replay_url}
      ```
    TEXT

    expect(described_class.call(message)).to eq(message)
  end

  it "does not isolate replay URLs in HTML-like lines" do
    message = %(<a href="#{replay_url}">Replay</a>)

    expect(described_class.call(message)).to eq(message)
  end

  it "does not isolate replay URLs in reference link definitions" do
    message = "[replay]: #{replay_url}"

    expect(described_class.call(message)).to eq(message)
  end

  it "returns the message unchanged when the Podplay onebox engine is not loaded" do
    described_class.stubs(:tenant_replay_url_regex).returns(nil)

    expect(described_class.call("Watch this #{replay_url} today")).to eq(
      "Watch this #{replay_url} today",
    )
  end

  it "preprocesses chat messages before cooking" do
    ChatCustomisations::TenantReplayOneboxPreprocessor
      .expects(:call)
      .with("Watch this")
      .returns("Watch this")

    Chat::Message.cook("Watch this")
  end
end
