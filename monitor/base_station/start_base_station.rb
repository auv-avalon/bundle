require 'vizkit'
require 'orocos/log'
require File.join(File.dirname(__FILE__),"base_station.rb")


if ARGV.size > 0
    Orocos.initialize
    puts 'loading from logfile'
    log = Orocos::Log::Replay.open(ARGV,Typelib::Registry.new)
    Vizkit.use_tasks log.tasks

    #activate some optional tasks
    #log.offshore_pipeline_detector.track true
else
    Orocos::CORBA.name_service = '192.168.128.50'
    Orocos.initialize
end

base_station = BaseStation.new
base_station.show

Vizkit.control log if log
Vizkit.exec
