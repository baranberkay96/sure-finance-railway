# Minimal /healthz for the Sidekiq worker (Railway healthcheck, STANDARD 8.34).
# Answers 200 while the container runs; Sidekiq is the main process, so the
# container stops (and Railway restarts it) when Sidekiq dies.
require "socket"

port = Integer(ENV.fetch("PORT", "3000"), exception: false) || 3000
server = TCPServer.new("0.0.0.0", port)
loop do
  client = server.accept
  begin
    client.gets
    client.write "HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\nContent-Length: 2\r\nConnection: close\r\n\r\nok"
  rescue StandardError
    nil
  ensure
    client.close
  end
end
