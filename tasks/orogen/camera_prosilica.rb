using_task_library "camera_prosilica"


class CameraProsilica::Task
    driver_for 'Camera' do
    	provides Srv::ImageProvider, "images" => "frame" 
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

