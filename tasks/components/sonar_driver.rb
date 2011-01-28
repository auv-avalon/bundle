using_task_library "sonar_driver"


class SonarDriver::Task
  driver_for "Micron"
  def configure
    orogen_task.port = "/dev/sonar"
  end
end

