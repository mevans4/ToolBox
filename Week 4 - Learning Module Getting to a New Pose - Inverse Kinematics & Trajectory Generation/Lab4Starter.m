function Lab4Starter( )

close all;

%% Create robot and workspace
mdl_twolink

% specify workspace
workspace = [-1 2.5 -2 2 -1 2];

scale = 0.5;

qz = [0,0];

twolink.plot(qz,'workspace',workspace,'scale',scale); 

twolink.teach;

hold on;

%% Calculate joint angles for a two link planar arm
% specify an end effector position
tr = [1.7 0 0.1]; 
x = tr(1,1);
z = tr(1,3);

% using cosine rule (a^2 = b^2 + c^2 - 2bc*cos(A)), 
% where cos(pi-A) = -cos(A)
% and cosA = cos(A) 
% and x^2+z^2 = a^2 
% and a and b are the link lengths equal to 1m
cosA = ((x^2+z^2-1^2-1^2)/(2*1*1));

% calculate joint 2 for poses 1 and 2
pose1theta2 = (atan2(sqrt(1-cosA^2),cosA));
pose2theta2 = (atan2(-sqrt(1-cosA^2),cosA));

% calculate joint 1 for poses 1 and 2
pose1theta1 = (atan2(z,x)-atan2((1)*sin(pose1theta2),1+(1)*cos(pose1theta2)));
pose2theta1 = (atan2(z,x)-atan2((1)*sin(pose2theta2),1+(1)*cos(pose2theta2))); 

pose1 = [pose1theta1, pose1theta2];
pose2 = [pose2theta1, pose2theta2];

%% Confirm joint angles using fkine
qFkine1 = twolink.fkine(pose1); %#ok<NASGU>
qFkine2 = twolink.fkine(pose2); %#ok<NASGU>

%% Draw straight line
% Plot a trajectory for the end-effector which moves from x = 1.7 to x = 0.7 
% while maintaining a z height of 0.1
z = 0.1;

% preallocate matrix if you want to view the joint angles later
qMatrix = zeros(100, 2);
count = 0;

% Can also try the following joint angle guess into ikine as an example to
% how the manipulator motion changes based on the given 'q0' value.
% q0 = [pi/3, -2*pi/3];
% newQ = twolink.ikine(transl(tr), 'q0', q0, 'mask', [1,1,0,0,0,0]);

for x = 1.7:-0.05:0.7
    count = count + 1;

     cosA = ((x^2+z^2-1^2-1^2)/(2*1*1));
     qMatrix(count,2) = (atan2(-sqrt(1-cosA^2),cosA));
     qMatrix(count,1) = (atan2(z,x)-atan2((1)*sin(qMatrix(count,2)),1+(1)*cos(qMatrix(count,2)))); 
     twolink.animate(qMatrix(count,:));
     drawnow();
    
    % newQ = twolink.ikine(transl(x,0,z), 'q0', newQ, 'mask', [1,1,0,0,0,0]);
    % twolink.animate(newQ);
    % drawnow();

    twolink.fkine(qMatrix(count,:)) % Note that we don't exactly reach the goal tr
    % twolink.fkine(newQ); % Note that we don't exactly reach the goal tr
end

%% Comparing the jtraj trajectory generation method
qMatrix = qMatrix(1:count,:); % resize to be only the used rows

jTrajQMatrix = jtraj(qMatrix(1,:),qMatrix(end,:),size(qMatrix,1));

for i = 1:count
    twolink.animate(jTrajQMatrix(i,:));
    trplot(twolink.fkine(jTrajQMatrix(i,:)),'color','b')
    jTrajEndEffectorPoints(i,:) = twolink.fkine(jTrajQMatrix(i,:)).t'; %#ok<AGROW>
end

for i = 1:count
    twolink.animate(qMatrix(i,:));
    trplot(twolink.fkine(qMatrix(i,:)),'color','r')
    invKinEndEffectorPoints(i,:) = twolink.fkine(qMatrix(i,:)).t'; %#ok<AGROW>
end

%% 2D view of the end effector path. Note that z is not fixed
figure
plot(jTrajEndEffectorPoints(:,1),jTrajEndEffectorPoints(:,3),'b*-');
hold on
plot(invKinEndEffectorPoints(:,1),invKinEndEffectorPoints(:,3),'r*-');
legend({'jTrajEndEffectorPoints','invKinEndEffectorPoints'},'Location','northwest')
axis equal
xlabel('x(m)');ylabel('z(m)');