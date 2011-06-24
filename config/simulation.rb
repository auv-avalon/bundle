Roby.app.use_deployments_from "avalon_simulation_deployments"
# Roby.app.use_deployments_from "avalon_back"
# Roby.app.use_deployments_from "avalon_front"
Roby.app.use_deployments_from "controldev" # Joystick

Robot.devices do    
    device(Dev::Joystick, :as => 'joystick')

    device(Dev::Camera, :as => 'bottom_camera', :using => AvalonSimulation::BottomCamera).
      period(0.1)

    device(Dev::Camera, :as => 'front_camera', :using => AvalonSimulation::FrontCamera).
      period(0.1)

    # TODO: Sonar device for bottom and top
end

### not finished or tested
