require 'droplet_kit'
require 'net/ssh'
require 'net/sftp'
require 'logger'
require 'date'

# Tool to create VPN for some hours
class VpnPoc
  def initialize(**args)
    @keys = ['~/.ssh/id_rsa']
    @logger = Logger.new(STDOUT)
    @client = args[:client] unless args[:client].nil?
    @client = DropletKit::Client.new(access_token: args[:token]) unless args[:token].nil?
    @logger.debug('Connected to DO') unless @client.nil?
    raise 'DO client is not initialized. Please pass either "client" or "token"' if @client.nil?
  end

  def do_its_best
    start_time = Time.new
    droplet_id = create_or_find_droplet
    droplet_by_id = @client.droplets.find(id: droplet_id)
    ip_address = droplet_by_id.networks['v4'].select {|net| net.type == 'public'}.first.ip_address
    Net::SSH.start(ip_address, 'root', keys: @keys, timeout: 300) do |ssh|
      @logger.debug('Connected to droplet')
      cid = ssh.exec!('docker run -d --restart=always --privileged -p 1194:1194/udp -p 443:443/tcp umputun/dockvpn 2>/dev/null')
      cid.chop!
      @logger.debug("VPN container ID: #{cid}")
      @logger.debug 'Waiting 2 minutes for container to start'
      sleep 120
      @logger.debug 'Copying VPN credentials from container'
      ssh.exec!("docker cp #{cid}:/etc/openvpn/client.ovpn ~")
    end
    Net::SFTP.start(ip_address, 'root', keys: @keys) do |sftp|
      sftp.download('/root/client.ovpn', 'vpn.ovpn')
    end
    `open vpn.ovpn`
  end

  private

  def create_or_find_droplet
    my_ssh_keys = @client.ssh_keys.all.collect(&:fingerprint)
    all_droplets = @client.droplets.all
    all_droplets.each do |droplet|
      if droplet.name == 'vpn-for-a-while'
        return droplet.id
      end
    end
    @droplet = DropletKit::Droplet.new(name: 'vpn-for-a-while', region: 'nyc1', size: 's-1vcpu-1gb', image: 87786318, ssh_keys: my_ssh_keys)
    sleep 20
    droplet_create_result = @client.droplets.create(@droplet)
    @logger.debug "Droplet created #{droplet_create_result}."
    droplet_create_result.id
  end
end
token = File.open('do.token').readline().chomp()
VpnPoc.new(token: token).do_its_best
