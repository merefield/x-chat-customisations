# frozen_string_literal: true

describe "x_chat rake tasks" do
  fab!(:user_1, :user)
  fab!(:user_2, :user)
  fab!(:user_3, :user)
  fab!(:user_4, :user)

  let(:forced_seen_at) { Time.zone.parse("2025-07-01 12:00:00") }
  let(:user_ids) { [user_1.id, user_2.id, user_3.id, user_4.id] }

  before do
    Rake::Task.clear
    silence_warnings { Discourse::Application.load_tasks }
  end

  after { ENV.delete("RAILS_DB") }

  def invoke_task(name, *args)
    Rake::Task[name].reenable
    capture_stdout { Rake::Task[name].invoke(*args) }
  end

  describe "x_chat:make_seen" do
    before do
      ENV["RAILS_DB"] = "default"

      user_1.update_columns(last_seen_at: nil)
      user_2.update_columns(last_seen_at: nil)
      user_3.update_columns(last_seen_at: nil)
      user_4.update_columns(last_seen_at: 1.day.ago)
    end

    it "marks unseen users as seen up to the requested limit" do
      invoke_task("x_chat:make_seen", 2)

      expect(User.where(id: user_ids, last_seen_at: forced_seen_at).count).to eq(2)
      expect(User.where(id: user_ids, last_seen_at: nil).count).to eq(1)
      expect(user_4.reload.last_seen_at).not_to eq_time(forced_seen_at)
    end
  end

  describe "x_chat:make_unseen" do
    before do
      ENV["RAILS_DB"] = "default"

      user_1.update_columns(last_seen_at: forced_seen_at)
      user_2.update_columns(last_seen_at: forced_seen_at)
      user_3.update_columns(last_seen_at: forced_seen_at)
      user_4.update_columns(last_seen_at: 1.day.ago)
    end

    it "restores forced seen users back to unseen up to the requested limit" do
      invoke_task("x_chat:make_unseen", 2)

      expect(User.where(id: user_ids, last_seen_at: nil).count).to eq(2)
      expect(User.where(id: user_ids, last_seen_at: forced_seen_at).count).to eq(1)
      expect(user_4.reload.last_seen_at).not_to eq(nil)
    end
  end
end
