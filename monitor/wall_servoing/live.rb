require 'vizkit'
require 'orocos'
include Orocos

io = File.open(File.join(File.dirname(__FILE__), "..", "config.yml"))
cfg = YAML.load(io)
Orocos::CORBA.name_service = cfg["nameserver"].to_s
Orocos.initialize

## get wall_servoing
wall_servoing = Orocos::TaskContext.get 'wall_servoing'
wall_servoing.enable_debug_output = true

## run visualizations
view3d = Vizkit.default_loader.create_widget('vizkit::Vizkit3DWidget')
view3d.show()
sonarfeatureviz = view3d.createPlugin('sonarfeature', 'SonarFeatureVisualization')
wallviz = view3d.createPlugin('wall', 'WallVisualization')

## connect to debug port
Vizkit.connect_port_to 'wall_servoing', 'wall_servoing_debug', :pull => false, :update_frequency => 100 do |sample, name|
    sonarfeatureviz.updatePointCloud(sample.pointCloud)
    wallviz.updateWallData(sample.wall)
end

begin
    Vizkit.exec
rescue Interrupt => e
    wall_servoing.enable_debug_output = false
end
