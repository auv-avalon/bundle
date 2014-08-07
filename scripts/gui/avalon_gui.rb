#!/usr/bin/ruby1.9.1
require 'vizkit'
require 'rock/bundle'

if ARGV.size < 1
    puts "usage: avalon_gui.rb host-address or log-files"
    exit(0)
end

Orocos::CORBA.max_message_size = 80000000

Bundles.initialize

replay = nil
Orocos::Async.name_service.clear
if File.directory? ARGV[0] or File.exists? ARGV[0]
    replay = Orocos::Log::Replay.open(ARGV)
    Orocos::Async.name_service << Orocos::Async::CORBA::NameService.new('127.0.0.1')
else
    host_address = ARGV[0]
    Orocos::Async.name_service << Orocos::Async::CORBA::NameService.new(host_address)
end

## setup gui
widget = Vizkit::load File.join(File.dirname(__FILE__),'avalon_gui.ui')
state_viewer = Vizkit.default_loader.StateViewer 
puts widget.scrollarea_widget
state_viewer.options(:max_rows => 20)
state_viewer.show
widget.scrollarea.setWidget state_viewer


name_service = Orocos::Async.name_service
name_service.names.each do |name|
    task = Orocos::Async.proxy name
    state_viewer.add(task)
end
name_service.once_on_task_added do |name|
    task = Orocos::Async.proxy name
    state_viewer.add(task)
end
  
#get task context   
sonar = Orocos::Async.proxy 'sonar'
orientation_estimator = Orocos::Async.proxy 'orientation_estimator'
imu_sim = Orocos::Async.proxy 'imu'
front_camera = Orocos::Async.proxy 'front_camera'
bottom_camera = Orocos::Async.proxy 'bottom_camera'


orientation_estimator.port("attitude_b_g").once_on_reachable do
    Vizkit.display orientation_estimator.port("attitude_b_g"), :widget => widget.orientationview
end

imu_sim.port("pose_samples").once_on_reachable do
    Vizkit.display imu_sim.port("pose_samples"), :widget => widget.orientationview
end

sonar.port("sonar_beam").once_on_reachable do
    Vizkit.display sonar.port("sonar_beam"), :widget => widget.sonarview
end

front_camera.port("frame").once_on_reachable do
    Vizkit.display front_camera.port("frame"), :widget => widget.imageview_front
end

bottom_camera.port("frame").once_on_reachable do
    Vizkit.display bottom_camera.port("frame"), :widget => widget.imageview_bottom
end


Vizkit.control replay unless replay.nil?
widget.show
Vizkit.exec
