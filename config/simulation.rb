Roby.app.use_deployments_from "avalon_simulation_deployment"
Roby.app.use_deployments_from "controldev" # Joystick
Roby.app.use_deployment "taskmon_back"
Roby.app.use_deployment "auv_rel_pos_controller"
#Roby.app.use_deployment "uwv_dynamic_model"

Roby.app.orocos_start_all_deployments = true

Conf.orocos.log_group "images" do
    add "/RTT/extras/ReadOnlyPointer</base/samples/frame/Frame>"
end

Conf.orocos.log_group "raw_camera" do
    add "front_camera.frame_raw"
    add "front_camera.frame"
    add "bottom_camera.frame"
end

Conf.orocos.disable_log_group "images"
Conf.orocos.disable_log_group "raw_camera"

Robot.devices do
    device(Dev::Joystick, :as => 'joystick')

    device(Dev::MarsCamera, :as => 'bottom_camera', :using => AvalonSimulation::BottomCamera).
        period(0.1)

    device(Dev::MarsCamera, :as => 'front_camera', :using => AvalonSimulation::FrontCamera).
        period(0.1)

    device(Dev::MarsSonar, :as => 'sonar', :using => AvalonSimulation::SonarTop).
        period(0.1)

#    device(Dev::MarsSonarBottom, :as => 'sonar_rear', :using => AvalonSimulation::SonarBottom).
#        period(0.1)


    device(Dev::MarsAvalonThrusters, :as => 'thrusters', :using => AvalonSimulation::Actuators).
        period(0.1)

    # TODO: Sonar device for bottom and top
end
