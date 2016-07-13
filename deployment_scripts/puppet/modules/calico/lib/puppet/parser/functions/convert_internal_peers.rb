Puppet::Parser::Functions::newfunction( :convert_internal_peers,
                                        :type => :rvalue, :doc => <<-EOS
    This function get peers name-to-ipaddr map, as_number
    and convert to hassh, used into generate_bgp_peers()
    Usage:
      convert_internal_peers(
        $peers_hash,
        $local_as_number,
      )

    Hash
      {
        peer_name -> '1.2.3.4'
      }
    will be converted to
      {
        peer_name => {
          ipaddr    => '1.2.3.4',
          as_number => '64646'
        }
      }

    EOS
  ) do |argv|

    if argv.size != 2
      raise(
        Puppet::ParseError,
        "convert_internal_peers(): Wrong number of arguments. Should be two."
      )
    end
    if !argv[0].is_a?(Hash)
      raise(
        Puppet::ParseError,
        "convert_internal_peers(): Wrong peers map."
      )
    end

    peers = argv[0]
    as_number = argv[1]

    rv = {}
    peers.each do |name, ipaddr|
      rv[name] = {
        'ipaddr'    => ipaddr,
        'as_number' => as_number,
      }
    end
    return rv
end
# vim: set ts=2 sw=2 et :