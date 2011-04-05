using_task_library "camera"


class Camera::CameraTask
    find_output_port('frame').
        triggered_once_per_update

    driver_for 'Camera' do
    	provides Srv::ImageProvider
    end

    driver_for 'StructuredLight' do
    	provides Srv::StructuredLightImage
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

