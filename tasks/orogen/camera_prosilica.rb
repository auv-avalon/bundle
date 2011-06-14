using_task_library "camera_prosilica"

class CameraProsilica::Task
    driver_for 'Dev::Camera'
    provides Srv::ImageProvider, "images" => "frame"

    def configure
    	super
        orogen_task.camera_id = robot_device.device_id
    end

    #on :start do |event|
    #    each_output_connection('frame') do |*value|
    #        puts "CONN: #{value.inspect}"
    #    end
    #end

end

