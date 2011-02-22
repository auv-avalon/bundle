using_task_library "dynamixel"


class Dynamixel::Task
  driver_for "Dev::Dynamixel"
  def configure
    orogen_task.port = robot_device.device_id 
  end
end

