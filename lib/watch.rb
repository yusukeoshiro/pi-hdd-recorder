require "listen"
require "streamio-ffmpeg"
require "./util.rb"
require "securerandom"
require "dotenv"
require "json"
require "oauth2"
require "redis"
require 'net/http'

Dotenv.load

RECORD_PATH = "/mnt/PIHDD/original"
CONVERTED_PATH = "/mnt/PIHDD/converted"

def upload_to_google_photo file_path, description
	start = Time.now
	puts notify "Uploading #{file_path} to Google Photos"

	google_auth_client = OAuth2::Client.new(ENV["GOOGLE_CLIENT_ID"], ENV["GOOGLE_CLIENT_SECRET"], :site => "https://accounts.google.com", :authorize_url => "o/oauth2/auth", :token_url => "o/oauth2/token")
	redis = Redis.new(url: ENV["REDIS_URL"])

	hash =  JSON.parse(redis.get("google_auth_hash"))
	token = OAuth2::AccessToken.new( google_auth_client, hash["access_token"], hash )

	puts "getting the upload token..."
	uri = URI("https://photoslibrary.googleapis.com/v1/uploads")
	https = Net::HTTP.new(uri.host, uri.port)
	https.use_ssl = true
	req = Net::HTTP::Post.new(uri.path)
	req.body = File.read(file_path) ;0
	req["X-Goog-Upload-File-Name"] = File.basename(file_path)
	req["X-Goog-Upload-Protocol"] = "raw"
	req["content-type"] = "application/octet-stream"
	req["Authorization"] = "Bearer #{token.token}"
	result = https.request(req)
	if result.code.to_i == 200
		upload_token = result.body
		puts "creating media..."
		uri = URI("https://photoslibrary.googleapis.com/v1/mediaItems:batchCreate")
		https = Net::HTTP.new(uri.host, uri.port)
		https.use_ssl = true
		req = Net::HTTP::Post.new(uri.path)
		req.body = {
			"newMediaItems" => [
				{
					"description" => "this is a test",
					"simpleMediaItem" => {
						"uploadToken" => upload_token
					}
				}
			]
		}.to_json
		req["content-type"] = "application/json"
		req["Authorization"] = "Bearer #{token.token}"
		result = https.request(req)
		if result.code.to_i == 200
			elapsed = Time.now - start
			File.delete(file_path)
			puts notify "Finished uploading #{file_path} in #{elapsed} seconds"
		else
			puts notify "error occured while creating the media!!"
			puts result.body
		end
	else
		puts notify "error occured while uploading the video!!"
		puts result.body
	end
end


def encode_ts_to_mp4 file_path, is_delete=true
	start = Time.now
	puts notify "Starting Encoding #{file_path}..."

	new_file_name = File.basename(file_path,File.extname(file_path)) + ".mp4"

	File.delete("#{CONVERTED_PATH}/#{new_file_name}") if File.file?("#{CONVERTED_PATH}/#{new_file_name}")
	tmp_name = SecureRandom.hex(3) + ".mp4"

	#puts "----------------------"
	#puts "ffmpeg -fflags +discardcorrupt -i #{file_path} -bsf:a aac_adtstoasc -c:a copy -b:v 5000k -c:v h264_omx -y #{RECORD_PATH}/#{tmp_name}"
	#result = %x(ffmpeg -fflags +discardcorrupt -i #{file_path} -bsf:a aac_adtstoasc -c:a copy -b:v 5000k -c:v h264_omx -y #{RECORD_PATH}/#{tmp_name} &)

	movie = FFMPEG::Movie.new(file_path)
	options = %w( -fflags +discardcorrupt -bsf:a aac_adtstoasc -c:a copy -b:v 5000k -c:v h264_omx -vf scale=1440x1080 )
	movie.transcode("#{CONVERTED_PATH}/#{tmp_name}", options) do |progress|
		puts progress
	end

	File.rename("#{CONVERTED_PATH}/#{tmp_name}", "#{CONVERTED_PATH}/#{new_file_name}")
	File.delete(file_path) if is_delete

	elapsed = Time.now - start
	puts notify "Finished Encoding #{new_file_name} in #{elapsed} seconds"
	return "#{CONVERTED_PATH}/#{new_file_name}"
end


if $0 == __FILE__ then
	puts "converter live..."

	videos = Dir["/mnt/PIHDD/original/*.ts"]
	videos.each do |video|
		path = encode_ts_to_mp4(video)
		upload_to_google_photo( path, "test")
	end


	listener = Listen.to( RECORD_PATH ) do |modified, added, removed|
		files = modified || added
		puts files
		files.each do |file|
			if file.end_with? ".ts"
				path = encode_ts_to_mp4(file)
				upload_to_google_photo( path, "test")
			end
		end
	end

	listener.start # not blocking
	sleep
end
