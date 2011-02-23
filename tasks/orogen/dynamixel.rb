using_task_library "dynamixel"


class Dynamixel::Task
  driver_for "Dev::Dynamixel"
  def configure
    orogen_task.device = robot_device.device_id 
    orogen_task.servo_id = 1
  end
end

