#! /usr/bin/env ruby
# -*- coding: utf-8 -*-

require 'pipeline_detector.rb'
require 'orocos/log'
require 'yaml'

io = File.open(File.join(File.dirname(__FILE__), "..", "config.yml"))
cfg = YAML.load(io)

include Orocos

Orocos::CORBA.name_service = cfg["nameserver"].to_s

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

