Roby.app.use_deployments_from "avalon_simulation"

Robot.devices do
#   device(Dev::Joystick)

    device(Dev::Camera, :as => 'bottom_camera', :using => AvalonSimulation::BottomCamera)
    device(Dev::Camera, :as => 'front_camera', :using => AvalonSimulation::FrontCamera)

    device(Dev::SimulatedMotionActuator)
end

### not finished or tested
