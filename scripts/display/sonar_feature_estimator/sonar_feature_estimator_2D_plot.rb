#!/usr/bin/ruby1.9.1
require 'vizkit'
require 'rock/bundle'

Orocos::CORBA.max_message_size = 80000000

Bundles.initialize

if ARGV.size < 1
    puts "usage: sonar_feature_estimator_2D_plot.rb host-address or log-files"
    exit(0)
end

replay = nil
if File.directory? ARGV[0] or File.exists? ARGV[0]
    replay = Orocos::Log::Replay.open(ARGV)
    Orocos::Async.name_service << Orocos::Async::CORBA::NameService.new('127.0.0.1')
else
    host_address = ARGV[0]
    Orocos::Async.name_service << Orocos::Async::CORBA::NameService.new(host_address)
end
  
#get task context   
sonar_feature_estimator = Orocos::Async.proxy 'sonar_feature_estimator'

task_inspector = Vizkit.default_loader.TaskInspector
plotter = Vizkit.default_loader.Plot2d
#plotter.setZoomAble(true)
#plotter.setRangeAble(true)
plotter.show

marker_height = 200

sonar_feature_estimator.once_on_reachable do 
    Vizkit.display sonar_feature_estimator, :widget => task_inspector
    if replay.nil?
        p = sonar_feature_estimator.property("enable_debug_output")
        p = true
    end
end

sonar_feature_estimator.port("debug_output").once_on_reachable do
    Vizkit.connect_port_to 'sonar_feature_estimator', 'debug_output', :update_frequency => 100 do |sample, name|
        plotter.update_vector sample.filteredBeam,"filteredBeam"
        plotter.update_vector sample.device_noise_distribution,"device_noise_distribution"
        plotter.update_vector sample.gaussian_distribution,"gaussian_distribution"
        plotter.update_vector sample.derivative,"derivative"
        
        if (sample.bestPos >= 0) then
            bestPos = Array.new(sample.bestPos + 1)
            bestPos[sample.bestPos] = marker_height
            plotter.update_vector bestPos,"bestPos"
        else
            bestPos = Array.new(1)
            bestPos[0] = marker_height
            plotter.update_vector bestPos,"bestPos"
        end
        
        if (sample.pos_surface >= 0) then
            pos_surface = Array.new(sample.pos_surface + 1)
            pos_surface[sample.pos_surface] = marker_height
            plotter.update_vector pos_surface,"pos_surface"
        else
            pos_surface = Array.new(1)
            pos_surface[0] = marker_height
            plotter.update_vector pos_surface,"pos_surface"
        end

        if (sample.pos_ground >= 0) then
            pos_ground = Array.new(sample.pos_ground + 1)
            pos_ground[sample.pos_ground] = marker_height
            plotter.update_vector pos_ground,"pos_ground"
        else
            pos_ground = Array.new(1)
            pos_ground[0] = marker_height
            plotter.update_vector pos_ground,"pos_ground"
        end
    end
end

Vizkit.control replay unless replay.nil?
Vizkit.exec
