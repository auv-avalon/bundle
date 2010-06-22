Roby.app.orocos_engine.robot.devices.each_key do |name|
    add_mission(name)
end

add(LaserImageDemultiplexer, :as => 'front_image_acquisition').
    use 'front_camera'

