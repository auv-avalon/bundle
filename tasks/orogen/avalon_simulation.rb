class AvalonSimulation::Task 
end

class AvalonSimulation::BottomCamera
  driver_for Dev::Camera
end

class AvalonSimulation::FrontCamera
  driver_for Dev::Camera
end

class AvalonSimulation::SonarTop
  driver_for Dev::Sonar
end

class AvalonSimulation::Actuators
  provides Srv::Actuators
end

class AvalonSimulation::StateEstimator
  provides Srv::Pose
end
