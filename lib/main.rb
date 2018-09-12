require "dotenv"
require "redis"
require "json"
require "./util.rb"
require "date"
require "pry"

Dotenv.load

RECORDING_PATH = "/home/yusuke/Videos/recording"
RECORDED_PATH  = "/home/yusuke/Videos/recorded"



def record_show show
	publisher = Redis.new(url: ENV["REDIS_URL"])
	puts notify "Starting Recording #{show["show"]["title"]}"

	start_time = DateTime.parse(show["show"]["start_time"]).new_offset("+09:00")
	file_name = "#{start_time.strftime("%Y%m%d_%H%M")}_#{show["show"]["uuid"]}.ts"
	p file_name
	command = "recpt1 --b25 --strip #{show["show"]["channel_number"]} #{show["footage_duration"]} #{RECORDING_PATH}/#{file_name}"
	# command = "recpt1 --b25 --strip #{show["show"]["channel_number"]} 10 #{RECORDING_PATH}/#{file_name}"
	result = %x( #{command} )
	puts result
	File.rename("#{RECORDING_PATH}/#{file_name}", "#{RECORDED_PATH}/#{file_name}")
	notify "Finished Recording #{show[:title]}"
	publisher.publish("convert_request", "#{RECORDED_PATH}/#{file_name}")
end



puts "recorder live..."
subscriber = Redis.new(url: ENV["REDIS_URL"])
subscriber.subscribe('command_request') do |on|
	on.message do |channel, data|
		begin
			data.force_encoding("utf-8")
			payload = JSON.parse data
			if payload["command"] == "RECORD"
				show = payload["show"]
				record_show show
			end
			# command = payload["command"]
			# show = payload["show"]
			#
			# notify "Starting Recording #{show['title']}"
			#
			# result = %x( #{command} )
			# puts result
			# notify "Finished Recording #{show[:title]}"
		rescue => e
			puts e.message
			puts "failed"
		end
	end
end
