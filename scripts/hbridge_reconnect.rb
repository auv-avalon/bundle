#!/usr/bin/env ruby

require 'orocos'

Orocos::CORBA.name_service = '192.168.128.50'
Orocos.initialize

mc = Orocos::TaskContext.get('motion_control')
hb = Orocos::TaskContext.get('hbridge')

begin
	#if((hb.state == :TIMEOUT || hb.state == :RUNTIME_ERROR) and mc.state == :RUNNING)
		hb.cmd_motors.disconnect_all
		hb.cmd_motors.connect_to mc.hbridge_commands
		pp "Reconnect motion_control::Task to HBridge"
	#end
	rescue Exception => e
		pp "An error occure during reconnection of the hbridges: #{e}"
end

