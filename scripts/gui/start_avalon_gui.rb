#!/usr/bin/ruby1.9.1
require 'vizkit'
require 'rock/bundle'
require './avalon_gui.rb'

if ARGV.size < 1
    puts "usage: avalon_gui.rb host-address or log-files"
    exit(0)
end

Orocos::CORBA.max_message_size = 80000000

Bundles.initialize

host_address = '127.0.0.1'

replay = nil
if File.directory? ARGV[0] or File.exists? ARGV[0]
    replay = Orocos::Log::Replay.open(ARGV)
else
    host_address = ARGV[0]
end

Orocos::Async.name_service.clear
Orocos::Async.name_service << Orocos::Async::CORBA::NameService.new(host_address)
#Orocos::CORBA.name_service = host_address

Orocos.run "video_streamer_vlc::Capturer" => "vlc_consumer"  do 

    vlc_consumer = Orocos::TaskContext.get "vlc_consumer"
    options = {:host_address => host_address, :vlc_server => "192.168.128.50", :show_loggers => false, :state_viewer_max_rows => 20, :vlc_front_cam_port => 5005, :vlc_bottom_cam_port => 5004}
    avalon_gui = AvalonGUI.new options, vlc_consumer
    avalon_gui.show

    Vizkit.control replay unless replay.nil?
    Vizkit.exec
end


