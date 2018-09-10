require "dotenv"
require "redis"
require "json"

Dotenv.load

$redis = Redis.new(url: ENV["REDIS_URL"])

$redis.subscribe('command_request') do |on|
	on.message do |channel, msg|
		begin
			msg.force_encoding("utf-8")
			payload = JSON.parse msg
			command = payload["command"]
			show = payload["show"]
			# puts payload
			# puts show
			puts command
                        message = "Starting Recording #{show['title']}"
			p message
                        #system "curl -X POST -H \"Content-Type: application/json\" -d '{\"value1\":\"#{message}\"}' https://maker.ifttt.com/trigger/tv_update/with/key/Ax5VD0jixXuLJmYivcJk9"
			%x( curl -X POST -H "Content-Type: application/json" -d '{"value1":"#{message}"}' https://maker.ifttt.com/trigger/tv_update/with/key/Ax5VD0jixXuLJmYivcJk9 )
			result = %x( #{command} )
                	puts result
			message = "Finished Recording #{show[:title]}"
			#system "curl -X POST -H \"Content-Type: application/json\" -d '{\"value1\":\"#{message}\"}' https://maker.ifttt.com/trigger/tv_update/with/key/Ax5VD0jixXuLJmYivcJk9"
                        %x(curl -X POST -H "Content-Type: application/json" -d '{"value1":"#{message}"}' https://maker.ifttt.com/trigger/tv_update/with/key/Ax5VD0jixXuLJmYivcJk9)

		rescue
			p "failed"
		end
	end
end

