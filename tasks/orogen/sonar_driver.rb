using_task_library "sonar_driver"


class SonarDriver::Micron
  driver_for "Dev::Micron"
  def configure
    orogen_task.port = robot_device.device_id
    super 
  end
end

class SonarDriver::Profiling
  driver_for "Dev::Profiling"
  def configure
    orogen_task.port = robot_device.device_id 
    super
  end
end

