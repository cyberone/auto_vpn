# VPN up script

Usage:
1. Get DO API token at https://cloud.digitalocean.com/account/api/tokens
2. Save it to 'do.token'
3. Install openvpn unless you have one. `brew install openvpn`
4. `bundle exec ruby vpn_poc.rb`
5. Enter your password to launch openvpn with default route