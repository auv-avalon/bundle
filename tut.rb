use_deployments_from "avalon_back"
add_mission Minimal

class LowLevelDriver::LowLevelTask
  driver_for "LowLevel"
  def configure
    robot_def = robot_device
    orogen_task.port = "/dev/lowlevel"
    period = (robot_def.period * 1000).round
    #orogen_task.device_period = period
  end
end

class XsensImu::Task 
  driver_for "Xsens"
  def configure
    robot_def = robot_device
    orogen_task.port = "/dev/xsens"
    orogen_task.scenario = "human"
    orogen_task.max_timeouts = 5
    period = (robot_def.period * 1000).round
    #orogen_task.device_period = period
  end
end

class Dsp3000::Task 
  driver_for "Dsp3000"
  def configure
    robot_def = robot_device
    orogen_task.port = "/dev/fog"
    period = (robot_def.period * 1000).round
    #orogen_task.device_period = period
  end
end

class SonarDriver::SonarDriverMicronTask
  driver_for "Micron"
  def configure
    orogen_task.port = "/dev/sonar"
  end
end

class Canbus::Task
  driver_for "Canbus"
  def configure
    orogen_task.device = "can0"
  end
end

class Hbridge::Task
  driver_for "Hbridge"
  def configure
    configArr = orogen_task.configuration
    for i in 0..6
      pid					= configArr.config[i].pid_speed
      config					= configArr.config[i].base_config
      config.openCircuit			= 1
      config.activeFieldCollapse		= 0
      config.externalTempSensor			= 0
      config.cascadedPositionController		= 0
      config.pidDebugActive			= 0
      config.maxMotorTemp			= 60
      config.maxMotorTempCount			= 200
      config.maxBoardTemp			= 60
      config.maxBoardTempCount			= 200
      config.timeout				= 1000
      config.maxCurrent				= 8000
      config.maxCurrentCount			= 250
      config.pwmStepPerMs			= 5
      pid.maxPWM				= 400
      configArr.config[i].pid_speed		= pid
      configArr.config[i].base_config		= config
     end

     orogen_task.configuration = configArr
#     orogen_task.used_hbridges 			= 6
   end
end
	
class AvalonControl::MotionControlTask
  driver_for "Motion"
  def configure
  end
end


Robot.devices do
  device(LowLevel, :as => 'depth').
    period(0.3)
  device(Xsens, :as => 'imu').
    period(0.01)
  device(Dsp3000, :as => 'fog').
    period(0.01)
  device(Micron, :as => 'sonar')
  device(Canbus, :as => 'canbus')
  device(Hbridge, :as => 'hbridge')
end
