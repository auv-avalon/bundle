using_task_library "sonar_driver"


class SonarDriver::Micron
  driver_for "Dev::Micron"
  def configure
    orogen_task.port = "/dev/sonar"
  end
end

