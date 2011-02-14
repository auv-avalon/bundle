require 'highline'
CONSOLE = HighLine.new
def color(string, *args)
    CONSOLE.color(string, *args)
end

def q_to_yaw(q)
    q0, q1, q2, q3 = q.re, *q.im
    a = 2 * q1 * q2 + 2 * q0 * q3
    b = 2 * q0 * q0 + 2 * q1 * q1 - 1
    Math.atan2(a, b)
end

def add_status(status, name, format, obj, field, *colors)
    if obj.respond_to?(field)
        value = obj.send(field)
        if block_given?
            value = yield(value)
        end
        if value
            if format
                if !value.respond_to?(:to_ary)
                    value = [value]
                end

                status << color("#{name}=#{format}" % value, *colors)
            else
                status << color(name, *colors)
            end
        end
    else
        status << "#{name}=-"
    end
end


ERR_TIME_DIFF = 0.2
Roby.every(1, :on_error => :disable) do
    status = []
    #add_status(status, "needs_external_encoders_calibration", nil, State, :external_encoders_calibrated, :bold, :red) do |s|
    #    !s
    #end

    #add_status(status, "time_sync", "%.2f", State.gps, :time, :bold, :red) do |s|
    #    cpu = s.cpu_time
    #    gps = s.gps_time
#   #     diff = (cpu - gps).abs 
    #    diff = 0
    #    if diff > ERR_TIME_DIFF
    #        diff
    #    end
    #end

    #add_status(status, "syslevel", "%i", State, :lowlevel_state)
    #add_status(status, "pos", "(x=%.2f y=%.2f z=%.2f th=%.2f)", State, :pose) do |p|
    #    q = p.orientation
    #    xyzth = p.position.to_a
    #    xyzth << q.to_euler(2, 1, 0)[0] * 180.0 / Math::PI
    #end
    #add_status(status, "gps", "(%s %.2f %.2f %.2f)", State.gps, :solution) do |s|
    #    [s.positionType.to_s, s.deviationLatitude, s.deviationLongitude, s.deviationAltitude]
    #end
    #add_status(status, "gps_pos", "(%.2f %.2f %.2f)", State.gps, :position) do |s|
    #    [s.position.to_a]
    #end
    ##add_status(status, "wheel_pos", "(%.2f %.2f %.2f %.2f)", State, :wheel_pos) do |s|
    ##      s
    ##end
#
    #Robot.info status.join(' ') if !status.empty?
end
