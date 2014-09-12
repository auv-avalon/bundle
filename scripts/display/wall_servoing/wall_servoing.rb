#!/usr/bin/ruby1.9.1
require 'vizkit'
require 'rock/bundle'

Orocos::CORBA.max_message_size = 80000000

Bundles.initialize

if ARGV.size < 1
    puts "usage: wall_servoing.rb host-address or log-files"
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
wall_servoing = Orocos::Async.proxy 'wall_servoing'
sonar = Orocos::Async.proxy 'sonar'
sonar_feature_estimator = Orocos::Async.proxy 'sonar_feature_estimator'
depth_orientation_fusion = Orocos::Async.proxy 'depth_orientation_fusion'

task_inspector = Vizkit.default_loader.TaskInspector
sonarfeatureviz = Vizkit.default_loader.SonarFeatureVisualization
wallviz = Vizkit.default_loader.WallVisualization
auv_avalon = Vizkit.default_loader.AUVAvalonVisualization
auv_avalon.showDesiredModelPosition(true)

wall_servoing.once_on_reachable do 
    Vizkit.display wall_servoing, :widget => task_inspector
    wall_servoing.enable_debug_output = true if replay.nil?
end

sonar.once_on_reachable do 
    Vizkit.display sonar, :widget => task_inspector
end

sonar_feature_estimator.once_on_reachable do 
    Vizkit.display sonar_feature_estimator, :widget => task_inspector
end

wall_servoing.port("wall_servoing_debug").once_on_reachable do
    Vizkit.connect_port_to 'wall_servoing', 'wall_servoing_debug', :update_frequency => 100 do |sample, name|
        sonarfeatureviz.updatePointCloud(sample.pointCloud)
        wallviz.updateWallData(sample.wall)
    end
end

wall_servoing.port("position_command").once_on_reachable do
    Vizkit.connect_port_to 'wall_servoing', 'position_command', :update_frequency => 100 do |sample, name|
        auv_avalon.updateDesiredPosition(sample)
    end
end

depth_orientation_fusion.port("pose_samples").once_on_reachable do
    Vizkit.display depth_orientation_fusion.port("pose_samples"), :widget => auv_avalon
end

Vizkit.control replay unless replay.nil?
Vizkit.exec
