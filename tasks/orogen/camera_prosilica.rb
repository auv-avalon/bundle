using_task_library "camera_prosilica"

device_type 'Camera' do
    provides Srv::ImageProvider
end



class CameraProsilica::Task
    driver_for Dev::Camera, 'images' => 'frame'

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

