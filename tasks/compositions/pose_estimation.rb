composition 'PoseEstimator' do
    # This is an empty shell since we don't have a generic pose estimator. It is
    # specialized for each pose estimator 

    estimator = add Pose, :as => 'estimator'
    export estimator.pose_samples
    provides Pose
end

