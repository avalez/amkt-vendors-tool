# unicorn.rb

port = ENV['PORT'] ? ENV['PORT'].to_i : 3000
listen port, :tcp_nopush => false