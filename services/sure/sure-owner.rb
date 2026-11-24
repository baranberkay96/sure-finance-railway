# Create the Sure owner account from variables (rails runner, before Puma).
#
# No users yet: create a family and its first user exactly like the sign-up
# page does for a new family (the first user becomes super_admin).
# Users exist: if RAILWAY_OWNER_MODE is "set" and the password of the user
# with RAILWAY_OWNER_EMAIL differs, update it (the variable is the source of
# truth) and end that user's sessions. Mode "lock" never changes a password.
require "securerandom"

def railway_log(message)
  $stdout.puts "#{Time.now.utc.iso8601} railway-owner: #{message}"
  $stdout.flush
end

email = ENV.fetch("RAILWAY_OWNER_EMAIL")
mode = ENV.fetch("RAILWAY_OWNER_MODE", "lock")
file = ENV["RAILWAY_OWNER_PASSWORD_FILE"].to_s
given = file.empty? || !File.readable?(file) ? "" : File.read(file)
File.delete(file) if !file.empty? && File.exist?(file)
mode = "lock" if given.empty?
password = mode == "set" ? given : SecureRandom.base58(40)

if User.exists?
  if mode != "set"
    railway_log "SURE_OWNER_PASSWORD is not valid; no password was changed"
  elsif (user = User.find_by(email: email.strip.downcase)).nil?
    railway_log "no user with SURE_OWNER_EMAIL=#{email}; nothing changed (the email is only used to create the first owner)"
  elsif user.authenticate(password)
    railway_log "password of #{email} matches SURE_OWNER_PASSWORD"
  else
    user.update!(password: password)
    user.sessions.destroy_all if user.respond_to?(:sessions)
    railway_log "password of #{email} changed to SURE_OWNER_PASSWORD"
  end
  exit 0
end

ActiveRecord::Base.transaction do
  User.lock_first_user_role!
  family = Family.new
  user = User.new(email: email, password: password, password_confirmation: password, family: family,
                  role: User.role_for_new_family_creator)
  user.save!
end
railway_log(mode == "set" ? "created owner #{email} (super admin, password from SURE_OWNER_PASSWORD)" :
                            "created owner #{email} with a random password; set SURE_OWNER_PASSWORD (12-72 characters) and redeploy to log in")
