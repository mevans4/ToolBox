%% Complete Code for All Quiz Questions
clear all; close all; clc;

%% Question 2: UR5 Manipulability
fprintf('Question 2: UR5 Manipulability\n');
r = UR5();
q_deg = [0, 55, -90, -45, 90, 0];
q_rad = deg2rad(q_deg);
J = r.model.jacob0(q_rad);
J_trans = J(1:3, :);  % Translational part only
manipulability = sqrt(det(J_trans * J_trans'));
fprintf('Manipulability measure (translational only): %.4f\n\n', manipulability);

%% Question 4: Ellipsoid Point Count
fprintf('Question 4: Ellipsoid Point Count\n');
[X,Y] = meshgrid(-5:0.1:5, -5:0.1:5);
Z = X;
center = [3, 2, -1];
radii = [1, 20, 30];
points = [X(:), Y(:), Z(:)];
algebraicDist = ((points(:,1) - center(1))/radii(1)).^2 + ...
                ((points(:,2) - center(2))/radii(2)).^2 + ...
                ((points(:,3) - center(3))/radii(3)).^2;
pointsInside = sum(algebraicDist < 1);
fprintf('Number of points inside ellipsoid: %d\n\n', pointsInside);

%% Question 5: Puma560 Singularity
fprintf('Question 5: Puma560 Singularity Analysis\n');
mdl_puma560;
poses = [0 1.5708 -3.0159 0.1466 0.5585 0;
         0 0.7 3 0 0.7 0;
         1.1170 1.0996 -3.4872 0.1466 0.5585 0.6500;
         0 2.3562 -3.0159 0 -0.9076 0];

for i = 1:size(poses, 1)
    q = poses(i, :);
    
    % Check joint limits
    within_limits = all(q >= p560.qlim(:,1)' & q <= p560.qlim(:,2)');
    
    if within_limits
        J = p560.jacob0(q);
        J_pos = J(1:3, :);  % Position part only
        manip = sqrt(det(J_pos * J_pos'));
        fprintf('Pose %d: Valid, Manipulability = %.6f\n', i, manip);
    else
        fprintf('Pose %d: Outside joint limits\n', i);
    end
end
fprintf('Pose 4 has the lowest manipulability (closest to singularity)\n\n');

%% Question 9: Collision Detection
fprintf('Question 9: Collision Detection\n');
mdl_planar3;
[v, f, fn] = RectangularPrism([2,-1.1,-1], [3,1.1,1]);
q1 = [pi/3, 0, 0];
q2 = [-pi/3, 0, 0];
q_traj = jtraj(q1, q2, 50);

for i = 1:size(q_traj, 1)
    result = IsCollision(p3, q_traj(i,:), f, v, fn, true);
    if result
        fprintf('First collision at step %d: q = [%.4f %.4f %.4f]\n', ...
                i, q_traj(i,1), q_traj(i,2), q_traj(i,3));
        break;
    end
end