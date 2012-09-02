# FIRST gem install highline

# Credits:
#  http://www.zacharyfox.com/blog/ruby-on-rails/password-hashing
#  http://stackoverflow.com/questions/7266001/heroku-and-writing-oauth-credentials
#  http://stackoverflow.com/questions/3699134/ruby-stdin-gets-without-showing-chars-on-screen

require './lib/password'
require 'highline/import'

username = ask("Desired login? ")
password = ask("Your new password (hidden)? ") { |q| q.echo = "*" }
password = Password.update(password)
confirm = ask("Confirm (hidden):  ") { |q| q.echo = "*" }
if (Password.check(confirm, password))
  puts "Execute: 'heroku config:add amkt_client_username=#{username} amkt_client_password=#{password}'"
end
