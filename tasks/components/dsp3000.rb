using_task_library "dsp3000"


class Dsp3000::Task 
  driver_for "Dsp3000"
  def configure
    robot_def = robot_device
    orogen_task.port = "/dev/fog"
    period = (robot_def.period * 1000).round
    #orogen_task.device_period = period
  end
end
