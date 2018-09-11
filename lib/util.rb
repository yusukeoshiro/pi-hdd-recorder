require 'net/http'
require "dotenv"

Dotenv.load

def notify message

	begin
		uri = URI(ENV["NOTIFY_URL"])
		https = Net::HTTP.new(uri.host, uri.port)
		https.use_ssl = true
		req = Net::HTTP::Post.new(uri.path)
		req.body = {
			"value1" => message
		}.to_json
		req["content-type"] = "application/json"
		result = https.request(req)
		if result.code.to_i != 200
			raise result.body
		end
	rescue => e
		puts "error occured while sending push notification to IFTTT!!"
		puts e.message
	end

	return message
end
