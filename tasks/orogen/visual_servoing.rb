class VisualServoing::Task
    provides Srv::Navigator

    def configure
        super
        orogen_task.minZDistance = -0.4
        orogen_task.segmenterType = 1
        orogen_task.maxZDistance = -0.2
        orogen_task.maxGapDistance = 0.05
        orogen_task.minPathWidth = 0.55;
    end
end

Compositions::LocalNavigation.specialize Navigator, VisualServoing::Task do
    add LaserRangeFinder
    add Actuators
    add Orientation
    autoconnect
end

