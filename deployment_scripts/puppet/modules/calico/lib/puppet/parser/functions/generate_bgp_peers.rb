Puppet::Parser::Functions::newfunction( :generate_bgp_peers,
                                        :type => :statement, :doc => <<-EOS
    This function get internal peers map, connectivity options
    and create corresponded resources.
    Usage:
      generate_bgp_peers(
        $peers_hash,
        $template_name,
        $local_ipaddr,
        $local_as_number,
      )

    Peers_hash should be in format:
      {
        peer_name => {
          ipaddr => '1.2.3.4',
          as_number  => '64646'
        }
      }
    EOS
  ) do |argv|

    if argv.size != 4
      raise(
        Puppet::ParseError,
        "generate_bgp_peers(): Wrong number of arguments. Should be four."
      )
    end
    if !argv[0].is_a?(Hash)
      raise(
        Puppet::ParseError,
        "generate_bgp_peers(): Wrong peers map."
      )
    end

    peers = argv[0]
    template = argv[1]
    local_ipaddr = argv[2]
    local_as_number = argv[3]

    resources = {}
    peers.each do |name, peer_hash|
      #file_name = "/etc/bird/peers/#{template}__#{name}.conf"
      resources[name] = {
        'template'         => template,
        'local_ipaddr'     => local_ipaddr,
        'remote_ipaddr'    => peer_hash['ipaddr'],
        'local_as_number'  => local_as_number,
        'remote_as_number' => peer_hash['as_number'],
      }
    end
    function_create_resources(['calico::bird::bgp_peer_record', resources])
    return true
end
# vim: set ts=2 sw=2 et :