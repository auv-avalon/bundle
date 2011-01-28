using_task_library "low_level_driver"


class LowLevelDriver::LowLevelTask
  driver_for "LowLevel"
  def configure
    robot_def = robot_device
    orogen_task.port = "/dev/lowlevel"
    period = (robot_def.period * 1000).round
    #orogen_task.device_period = period
  end
end
