line = %x(sudo lsblk -o UUID,FSTYPE | grep exfat)
uuid = line.split(' ').first

if uuid 
	puts 'uuid is found: ' + uuid
else 
	puts 'uuid is not found terminating...'
	exit(1);
end


mount_path = '/mnt/PIHDD'
fstab_path = '/etc/fstab'

if !File.directory? mount_path
	Dir.mkdir mount_path
else
	puts '/mnt/PIHDD already exists!'
end


# open fstab
is_add_line = true
File.open( fstab_path ).each do |line| 
	if line.include? uuid
		is_add_line = false
		break	
	end
end

if is_add_line
	system("echo UUID=#{uuid} #{mount_path} exfat defaults,auto,umask=000,users,rw 0 0 >> #{fstab_path}")
	puts 'line was injected to ' + fstab_path
else
	puts 'nothing is done to fstab... its already installed!'
end

exit(0)
