class ImagePreprocessing::Task 
    def configure
        super
	orogen_task.image_size_x = 1024
	orogen_task.image_size_y = 768
    end

end

