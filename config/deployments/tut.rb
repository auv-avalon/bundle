use_deployments_from "avalon_back"
add Minimal 

class LowLevelDriver::LowLevelTask
  def configure
    orogen_task.port = "/dev/lowlevel"
  end
end

class XsensImu::Task 
  def configure
    orogen_task.port = "/dev/xsens"
    orogen_task.scenario = "human"
    orogen.task.max_timeouts = 5
  end
end

class Dsp3000::Task 
  def configure
    orogen_task.port = "/dev/fog"
  end
end

class SonarDriver::SonarDriverMicronTask
  def configure
    orogen_task.port = "/dev/sonar"
  end
end

class Canbus::Task
  def configure
    orogen_task.port = "can0"
  end
end

class Hbridge::Task
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

     hbridge.configuration = configArr
     hbridge.used_hbridges 			= 6
   end
end
	
class AvalonControl::MotionControlTask
  def configure
    pid_settings = orogen_task.x_pid
    pid_settings.zero!
    pid_settings.p = 0.2
#    pid_settings.d = 0.0025
    pid_settings.min = -0.2
    pid_settings.max = 0.2
    orogen_task.x_pid = pid_settings

    pid_settings = orogen_task.y_pid
    pid_settings.zero!
    pid_settings.p = 0.2
#    pid_settings.d = 0.05
    pid_settings.min = -0.4
    pid_settings.max = 0.4
    orogen_task.y_pid = pid_settings
  end
end
