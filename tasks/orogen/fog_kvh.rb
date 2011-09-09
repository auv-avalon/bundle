using_task_library "fog_kvh"


class FogKvh::Dsp3000Task
  driver_for "Dsp3000"
  def configure
    robot_def = robot_device
#    orogen_task.port = robot_device.device_id
    period = (robot_def.period * 1000).round
    #orogen_task.device_period = period
  end
end
