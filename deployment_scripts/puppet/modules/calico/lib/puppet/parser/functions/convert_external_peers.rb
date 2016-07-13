Puppet::Parser::Functions::newfunction( :convert_external_peers,
                                        :type => :rvalue, :doc => <<-EOS
    This function get text in format
      name:asnum:ipaddr:flags...
    and convert to hash, used into generate_bgp_peers()
      {
        peer_name => {
          ipaddr    => '1.2.3.4',
          as_number => '64646'
        }
      }

    EOS
  ) do |argv|

    if argv.size != 1
      raise(
        Puppet::ParseError,
        "convert_external_peers(): Wrong number of arguments. Should be one."
      )
    end

    peers = argv[0]
    as_number = argv[1]

    Hash[*peers.split(/\n/).map{|v| v.gsub(/\s+/, "")}.reject{|c| c.empty?}.map{|v| v.split(':')}.reject{|v| v.size<3}.map{|l| [l[0],{'as_number'=>l[1],'ipaddr'=> l[2]}]}.flatten]
end
# vim: set ts=2 sw=2 et :