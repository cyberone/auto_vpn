require 'droplet_kit'
require 'logger'
require 'time'

@logger = Logger.new(STDOUT)
@logger.info("Obtaining token")
token = File.open('do.token').readline.chomp

@logger.info("Connecting to DO")
client = DropletKit::Client.new(access_token: token)

@logger.info "looking for VPN droplet"
vpn_droplet = client.droplets.all.find do |droplet|
  droplet.name == 'vpn-for-a-while'
end
unless vpn_droplet.nil?
  @logger.info "Found #{vpn_droplet}"
  diff = (DateTime.now - DateTime.parse(vpn_droplet.created_at)).to_f
  @logger.info("Diff is #{diff}. Needs to be > 1 to ")
  if diff * 24 > 1.0
    @logger.info "Deleting droplet"
    client.droplets.delete(id: vpn_droplet.id)
  end
end
