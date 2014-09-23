#!/usr/bin/ruby1.9.1
require 'vizkit'
require 'rock/bundle'

Orocos::CORBA.max_message_size = 80000000

Bundles.initialize

if ARGV.size < 1
    puts "usage: sonar_feature_estimator.rb host-address or log-files"
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
sonar = Orocos::Async.proxy 'sonar'
sonar_feature_estimator = Orocos::Async.proxy 'sonar_feature_estimator'

task_inspector = Vizkit.default_loader.TaskInspector
sonarfeatureviz = Vizkit.default_loader.SonarFeatureVisualization
sonarfeaturediffviz = Vizkit.default_loader.SonarFeatureVisualization
color = Qt::Color.new
color.red = 255
sonarfeaturediffviz.setDefaultFeatureColor(color)

sonar.once_on_reachable do 
    Vizkit.display sonar, :widget => task_inspector
end

sonar_feature_estimator.once_on_reachable do 
    Vizkit.display sonar_feature_estimator, :widget => task_inspector
    if replay.nil?
        p = sonar_feature_estimator.property("enable_debug_output")
        p = true
    end
end


sonar_feature_estimator.port("2d_debug_output").once_on_reachable do
    Vizkit.connect_port_to 'sonar_feature_estimator', '2d_debug_output', :update_frequency => 100 do |sample, name|
        sonarfeatureviz.updatePointCloud(sample.point_cloud)
        sonarfeaturediffviz.updatePointCloud(sample.point_cloud_force_line)
    end
end

Vizkit.control replay unless replay.nil?
Vizkit.exec
