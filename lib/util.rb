def notify message
	return %x( curl -X POST -H "Content-Type: application/json" -d '{"value1":"#{message}"}' https://maker.ifttt.com/trigger/tv_update/with/key/Ax5VD0jixXuLJmYivcJk9 )
	
end
