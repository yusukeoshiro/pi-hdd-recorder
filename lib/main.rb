require "dotenv"
require "redis"
require "json"
require "./util.rb"

Dotenv.load

redis = Redis.new(url: ENV["REDIS_URL"])
puts "recorder live..."
redis.subscribe('command_request') do |on|
	on.message do |channel, msg|
		begin
			msg.force_encoding("utf-8")
			payload = JSON.parse msg
			command = payload["command"]
			show = payload["show"]

			notify "Starting Recording #{show['title']}"

			result = %x( #{command} )
			puts result
			notify "Finished Recording #{show[:title]}"
		rescue => e
			puts e.message
			puts "failed"
		end
	end
end
