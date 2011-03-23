class BuoyDetector::Task 
    def configure
        super
	orogen_task.image_size_x = 1024 / 2
	orogen_task.image_size_x = 786 / 2
	orogen_task.hueMin = 0
	orogen_task.hueMax = 40
	orogen_task.saturationMin = 120
	orogen_task.saturationMax = 256
	orogen_task.valueMin = 30
	orogen_task.valueMax = 256
	orogen_task.tune_detector = false
    end

end

