require 'droplet_kit'
token = File.open('do.token').readline().chomp()
client = DropletKit::Client.new(access_token: token)

images = client.images.all(type: 'application')
images.each do |image|
  p image # if image.to_s =~ /.*docker.*/i
end