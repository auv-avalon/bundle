class MoveCommand < Roby::Task
    #give command as vector3d
    argument :xy_speed
    argument :z
    argument :heading

    event :start do |context|
        @motion_writer = data_writer 'control_loop', 'controller', 'motion_commands'

        @motion_sample = @motion_writer.new_sample
        @motion_sample.x_speed = command[0]
        @motion_sample.y_speed = command[1]
        @motion_sample.z = command[2]
        @motion_sample.heading = 0
        emit :start
    end

    poll do
        @motion_writer.write(@motion_sample)
    end

    #This task does not need any specific action to stop
    terminates
end

