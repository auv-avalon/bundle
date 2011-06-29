Roby.app.use_deployments_from "avalon_simulation_deployment"
Roby.app.use_deployments_from "controldev" # Joystick
Roby.app.use_deployment "taskmon_back"

# Selectively get deployments from avalonFront / avalonBack
Roby.app.use_deployment "pipeline_follower"
Roby.app.use_deployment "buoy_detector"
Roby.app.use_deployment "auv_rel_pos_controller"
Roby.app.use_deployment "sonardetector"

Robot.devices do
    device(Dev::Joystick, :as => 'joystick')

    device(Dev::MarsCamera, :as => 'bottom_camera', :using => AvalonSimulation::BottomCamera).
        period(0.1)

    device(Dev::MarsCamera, :as => 'front_camera', :using => AvalonSimulation::FrontCamera).
        period(0.1)

    device(Dev::MarsSonar, :as => 'sonar', :using => AvalonSimulation::SonarTop).
        period(0.1)

    device(Dev::MarsAvalonThrusters, :as => 'thrusters', :using => AvalonSimulation::Actuators).
        period(0.1)

    # TODO: Sonar device for bottom and top
end

### not finished or tested
