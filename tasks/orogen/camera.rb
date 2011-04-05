using_task_library "camera"


class Camera::CameraTask
    driver_for 'Camera' do
    	provides Srv::ImageProvider
    end

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

