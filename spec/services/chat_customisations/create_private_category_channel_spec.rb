# frozen_string_literal: true

RSpec.describe ChatCustomisations::CreatePrivateCategoryChannel do
  describe described_class::Contract, type: :model do
    subject(:contract) { described_class.new(name: "private channel") }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_length_of(:name).is_at_most(SiteSetting.max_topic_title_length) }
  end

  describe ".call" do
    subject(:result) { described_class.call(params:, **dependencies) }

    fab!(:admin) { Fabricate(:admin, refresh_auto_groups: true) }
    fab!(:user)

    let(:params) do
      {
        name: "whats up there",
        slug: "whats-up-there",
        description: "My new private channel",
        threading_enabled: true,
      }
    end
    let(:dependencies) { { guardian: admin.guardian } }

    before do
      SiteSetting.chat_enabled = true
      SiteSetting.chat_allowed_groups = Group::AUTO_GROUPS[:everyone]
      SiteSetting.enable_public_channels = true
    end

    context "when contract is invalid" do
      let(:params) { super().merge(name: nil) }

      it { is_expected.to fail_a_contract }
    end

    context "when public channels are disabled" do
      before { SiteSetting.enable_public_channels = false }

      it { is_expected.to fail_a_policy(:public_channels_enabled) }
    end

    context "when the acting user cannot create a channel" do
      let(:dependencies) { { guardian: user.guardian } }

      it { is_expected.to fail_a_policy(:can_create_channel) }
    end

    context "when a category already exists with the requested name" do
      fab!(:existing_category) { Fabricate(:category, name: "whats up there") }

      it { is_expected.to fail_a_policy(:backing_records_do_not_exist) }
    end

    context "when a group already exists with the derived name" do
      fab!(:existing_group) { Fabricate(:group, name: "whats_up_there") }

      it { is_expected.to fail_a_policy(:backing_records_do_not_exist) }
    end

    context "when channel creation is invalid" do
      fab!(:existing_channel) { Fabricate(:category_channel, slug: "whats-up-there") }

      it { is_expected.to fail_with_an_invalid_model(:channel) }

      it "rolls back the backing records" do
        result

        expect(Category.find_by(name: params[:name])).to be_nil
        expect(Group.find_by(name: params[:name].parameterize(separator: "_"))).to be_nil
        expect(Chat::Channel.find_by(name: params[:name])).to be_nil
      end
    end

    context "when everything is valid" do
      it { is_expected.to run_successfully }

      it "creates the backing records and channel" do
        result

        expect(result[:category]).to have_attributes(
          name: params[:name],
          read_restricted: true,
          user_id: admin.id,
        )
        expect(result[:group]).to have_attributes(name: "whats_up_there")
        expect(result[:category_group]).to have_attributes(
          category_id: result[:category].id,
          group_id: result[:group].id,
          permission_type: CategoryGroup.permission_types[:full],
        )
        expect(result[:group_user]).to have_attributes(
          group_id: result[:group].id,
          user_id: admin.id,
          owner: true,
        )
        expect(result[:channel]).to have_attributes(
          name: params[:name],
          slug: params[:slug],
          description: params[:description],
          chatable_id: result[:category].id,
          chatable_type: "Category",
        )
        expect(result[:membership]).to have_attributes(
          chat_channel_id: result[:channel].id,
          user_id: admin.id,
          following: true,
        )
      end

      context "when auto join users is enabled" do
        let(:params) { super().merge(auto_join_users: true) }

        it "runs the auto join service after creating the channel" do
          Chat::AutoJoinChannels
            .expects(:call)
            .with(params: has_entries(channel_id: kind_of(Integer)))
            .once

          result

          expect(result[:channel].auto_join_users).to eq(true)
        end
      end
    end
  end
end
