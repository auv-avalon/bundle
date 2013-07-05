class MovementExperiment::Task
    def configure
        super
        orogen_task.testMode = 'UP_AND_DOWN'
        orogen_task.pathlen = 555
    end
end
