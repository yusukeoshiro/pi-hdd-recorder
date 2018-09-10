require "listen"
require "./util.rb"

RECORD_PATH = "/mnt/PIHDD"

def encode_ts_to_mp4 file_name
	notify "Starting Encoding #{file_path}"
	print "converting #{file_path}..."
	new_file_name = File.basename(file_path,File.extname(file_path)) + ".mp4"
	result = %x(ffmpeg -fflags +discardcorrupt -i #{file_path} -bsf:a aac_adtstoasc -c:a copy -b:v 5000k -c:v h264_omx -y #{RECORD_PATH}/#{new_file_name} &)
	print "complete"
        # system("rm #{file}")
        notify = "Finished Encoding #{new_file_name}"
end


if $0 == __FILE__ then

	listener = Listen.to( RECORD_PATH ) do |modified, added, removed|
		start = Time.now
       		files = modified || added
		puts files

        	files.each do |file|
                	if file.end_with? ".ts"
                       		encode_ts_to_mp4 file
                	end
        	end
		elapsed = Time.now - start
		puts ""	
		puts "it took #{elapsed} seconds."
	end

	listener.start # not blocking
	sleep
end
