require 'resolv'

module Puppet::Parser::Functions
  newfunction(:all_host_ipv4, :type => :rvalue) do
    interfaces = lookupvar('interfaces').split(',')
    ipaddresses = []
    interfaces.each do |interface|
      next if interface.eql? 'lo'
      ip = lookupvar("ipaddress_#{interface}")
      ipaddresses << ip if !!(ip =~ Resolv::IPv4::Regex)
    end

    ipaddresses
  end
end
