class TorqueEstimator::Task

    def configure
        super
        orogen_task.A     = 0.601612
        orogen_task.beta  = 0.871868
        orogen_task.gamma = 0.988168
        orogen_task.n     = 4.475258 
        orogen_task.a     = 0.355835 
        orogen_task.ki    = 1.325468
        orogen_task.nu    = 1.039960
        orogen_task.eta   = 1.166183
        orogen_task.h     = 1.0

        orogen_task.velSmoothFactor = 0.005

        orogen_task.gearPlayRL = 5.0
        orogen_task.gearPlayRR = 4.0
        orogen_task.gearPlayFR = 3.8
        orogen_task.gearPlayFL = 7.0
    end
  
end

