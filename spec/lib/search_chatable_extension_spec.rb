# frozen_string_literal: true

RSpec.describe Chat::SearchChatable do
  describe ".call" do
    subject(:result) { described_class.call(params:, guardian:) }

    fab!(:current_user, :user) { Fabricate(:user, username: "bob-user") }
    fab!(:following_user, :user) { Fabricate(:user, username: "sam-user") }
    fab!(:non_following_user, :user) { Fabricate(:user, username: "charlie-user") }
    fab!(:exact_match_user, :user) { Fabricate(:user, username: "sam") }
    fab!(:prefix_match_user, :user) { Fabricate(:user, username: "samwise") }
    fab!(:public_channel, :chat_channel)
    fab!(:private_group, :group)
    fab!(:private_channel, :private_category_channel) do
      Fabricate(:private_category_channel, group: private_group)
    end

    let(:guardian) { Guardian.new(current_user) }
    let(:params) { { term: "", include_users: true, excluded_memberships_channel_id: channel_id } }
    let(:channel_id) { public_channel.id }

    before do
      SiteSetting.direct_message_enabled_groups = Group::AUTO_GROUPS[:everyone]
      SiteSetting.enable_names = false

      public_channel.add(current_user)
      public_channel.add(following_user)
      public_channel.add(non_following_user).update!(following: false)
      public_channel.add(exact_match_user).update!(following: false)
      public_channel.add(prefix_match_user).update!(following: false)

      private_channel.add(following_user)
    end

    it "excludes only users following the visible channel" do
      expect(result.users).not_to include(following_user)
      expect(result.users).to include(non_following_user)
    end

    it "preserves match_quality for serializer consumers" do
      expect(result.users).to all(respond_to(:match_quality))
    end

    context "when the excluded channel is not visible to the acting user" do
      let(:channel_id) { private_channel.id }

      it "does not apply the membership exclusion filter" do
        expect(result.users).to include(following_user)
      end
    end

    context "when the excluded channel is visible and private" do
      let(:channel_id) { private_channel.id }

      before do
        Fabricate(:group_user, group: private_group, user: current_user)
        private_channel.add(non_following_user).update!(following: false)
      end

      it "excludes only users following the private channel" do
        expect(result.users).not_to include(following_user)
        expect(result.users).to include(non_following_user)
      end
    end

    context "when searching with a term" do
      let(:params) { { term: "sam", include_users: true } }

      it "orders exact matches before prefix matches" do
        expect(result.users.first).to eq(exact_match_user)
        expect(result.users.first.match_quality).to eq(Chat::ChannelFetcher::MATCH_QUALITY_EXACT)

        prefix_results =
          result.users.select do |user|
            user.match_quality == Chat::ChannelFetcher::MATCH_QUALITY_PREFIX
          end

        expect(prefix_results.map(&:username)).to include(
          following_user.username,
          prefix_match_user.username,
        )
      end
    end
  end
end
