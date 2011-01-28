class Gps::BaseTask
    on :start do |event|
        @position_reader = data_reader 'position_samples'
        @time_reader     = data_reader 'time'
    end

    def position; @position_reader.read end
    def time; @time_reader.read end

    poll do
        if sample = position
            State.gps.position = sample
        end
        if sample = time
            State.gps.time = sample
        end
    end

    on :stop do |_|
        if State.gps.position?
            State.gps.delete(:position)
        end
        if State.gps.time?
            State.gps.delete(:time)
        end
    end
end

# MB500 driver module from the modules/dgps orogen project
#
# The device definition should look like:
#
#   device(Mb500).
#       period(1.0).
#       device_id("/dev/com_port"[, port_id[, correction_port]])
#
# The optional +port_id+ parameter is used to specify the board's communication
# port to which we are connected. +correction_port+ specifies where to get the
# DGPS corrections. It can either be a board port name (A, B, C or D) or a
# number. In the latter case, it specifies an UDP port number at which the
# module will read the corrections.
#
# Additional properties:
# 
# dynamics_model::
#   can either be set to one of the values of the gps::DYNAMICS_MODEL
#   enumeration (:STATIC, :QUASI_STATIC, :WALKING, :SHIP, :AUTOMOBILE,
#   :AIRCRAFT, :UNLIMITED, :ADAPTIVE) or an array of [hVelocity, hAccel,
#   vVelocity, vAccel] where velocities are in m/s and accelerations in m/s^2.
#
#   Example:
#
#     device(Mb500).
#         period(1.0).
#         device_id("/dev/com_port").
#         set('dynamics_model', :WALKING)
#
class Gps::MB500Task
    driver_for 'MB500', :provides => Position

    def configure
        super

        device_file, port_id, correction_port = *robot_device.device_id
        period = robot_device.period

        orogen_task.device = device_file
        if port_id
            orogen_task.port   = port_id
        end
        if correction_port
            orogen_task.correction_port = correction_port.to_s
        end
	orogen_task.correction_port = "5000"
        orogen_task.period = period

        if State.local_origin?
            orogen_task.origin = State.local_origin
        end
    end

    on :start do |event|
        @solution_reader = data_reader 'solution'
    end

    def solution; @solution_reader.read end
    poll do
        super()

        if sample = solution
            State.gps.solution = sample
        end
    end
    on :stop do |_|
        if State.gps.solution?
            State.gps.delete(:solution)
        end
    end
end

