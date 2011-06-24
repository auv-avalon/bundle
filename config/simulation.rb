Roby.app.use_deployments_from "avalon_simulation_deployment"
Roby.app.use_deployments_from "controldev" # Joystick

Robot.devices do
    device(Dev::Joystick, :as => 'joystick')

    device(Dev::Camera, :as => 'bottom_camera', :using => AvalonSimulation::BottomCamera).
        period(0.1)

    device(Dev::Camera, :as => 'front_camera', :using => AvalonSimulation::FrontCamera).
        period(0.1)

    device(Dev::Sonar, :as => 'top_sonar', :using => AvalonSimulation::SonarTop).
        period(0.1)

    # TODO: Sonar device for bottom and top
end

### not finished or tested
