# frozen_string_literal: true
SEEN_DEFAULT_DATETIME = '2025-07-01 12:00:00'

desc "Update seen for each unseen user"
task "x_chat:make_seen", %i[limit] => :environment do |_, args|
  ENV["RAILS_DB"] ? make_seen(args) : make_seen_all_sites(args)
end

def make_seen_all_sites(args)
  RailsMultisite::ConnectionManagement.each_connection { |db| make_seen(args) }
end

desc "Restore seen for each forced seen user"
task "x_chat:make_unseen", %i[limit] => :environment do |_, args|
  ENV["RAILS_DB"] ? make_unseen(args) : make_unseen_all_sites(args)
end

def make_unseen_all_sites(args)
  RailsMultisite::ConnectionManagement.each_connection { |db| make_unseen(args) }
end

def make_seen(args)
  puts "LOADED FROM: #{__FILE__} (real: #{File.realpath(__FILE__)})"
  puts "-" * 50
  puts "Setting users seen for '#{RailsMultisite::ConnectionManagement.current_db}'"

  limit = args[:limit]&.to_i || 10000

  puts "with a limit of #{limit} users" if limit.positive?
  puts "to a datetime of #{SEEN_DEFAULT_DATETIME}"
  puts "-" * 50

  #count = User.where(last_seen_at: nil).where("id > 0").limit(limit).count
  updated_count = User.where(last_seen_at: nil).where("id > 0").limit(limit).update_all(last_seen_at: SEEN_DEFAULT_DATETIME)

  puts "Updated #{updated_count} users seen to '#{SEEN_DEFAULT_DATETIME}'!"
end

def make_unseen(args)
  puts "-" * 50
  puts "Setting forced users seen back to nil  for '#{RailsMultisite::ConnectionManagement.current_db}'"

  limit = args[:limit]&.to_i || 10000

  puts "with a limit of #{limit} users" if limit.positive?
  puts "for those with a datetime of '#{SEEN_DEFAULT_DATETIME}'"
  puts "-" * 50

  #User.where(last_seen_at: SEEN_DEFAULT_DATETIME).where("id > 0").limit(limit).count
  updated_count = User.where(last_seen_at: SEEN_DEFAULT_DATETIME).where("id > 0").limit(limit).update_all(last_seen_at: nil)

  puts "Updated #{updated_count} users seen to nil!"
end
