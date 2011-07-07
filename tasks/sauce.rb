class SaucE < Roby::Task
    terminates
end

class LookForBuoy < Roby::Task
    event :found
    forward :found => :success
    event :not_found
    forward :not_found => :success
end

