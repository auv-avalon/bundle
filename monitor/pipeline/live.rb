#! /usr/bin/env ruby
# -*- coding: utf-8 -*-

require 'pipeline_detector.rb'
require 'orocos/log'

include Orocos

Orocos::CORBA.name_service = "192.168.128.50"

Orocos.initialize
Orocos.run do
  
  camera = Orocos::TaskContext.get 'bottom_camera'
  pipeline_detector = TaskContext.get 'pipeline_follower'

  Vizkit.control camera
  Vizkit.display camera.frame

  gui = PipelineDetector.new(camera.frame, pipeline_detector)
  gui.show

  Vizkit.exec
  STDERR.puts "shutting down"
end

