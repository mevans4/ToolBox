function Lab3Starter()
%% Lab3Starter Create a Puma 560 DH SerialLink Model
% Although there is a Puma 560 Model in the toolbox, this code creates a model 
% from the basic DH parameters that we derived in the previous theory exercise.  

% Link('theta',__,'d',__,'a',__,'alpha',__,'offset',__,'qlim',[ ... ])

link1 = Link('d',0,'a',0,'alpha',pi/2,'offset',0)

link2 = Link('d',0,'a',0.4318,'alpha',0,'offset',0)

link3 = Link('d',0.15,'a',0.0203,'alpha',-pi/2,'offset',0)

link4 = Link('d',0.4318,'a',0,'alpha',pi/2,'offset',0)

link5 = Link('d',0,'a',0,'alpha',-pi/2,'offset',0)

link6 = Link('d',0,'a',0,'alpha',0,'offset',0)

myRobot = SerialLink([link1 link2 link3 link4 link5 link6], 'name', 'Puma560')

q = zeros(1,6);

myRobot.plot(q)

myRobot.gravity
myRobot.base
myRobot.tool

%% Teach
myRobot.teach

% profile clear;
% profile on;

% for i = 0:0.001:1
%     q = [i,i,i,i,i,i];

    %% fkine
    fkineTr = myRobot.fkine(q);
    
    %% Manual calculation of link transforms
    baseTr = eye(4);
    joint0to1Tr = GetJointToJointTr(q(1),0,     0,      pi/2);
    joint1to2Tr = GetJointToJointTr(q(2),0,     0.4318, 0);
    joint2to3Tr = GetJointToJointTr(q(3),0.15,  0.0203, -pi/2);
    joint3to4Tr = GetJointToJointTr(q(4),0.4318,0,      pi/2);
    joint4to5Tr = GetJointToJointTr(q(5),0,     0,      -pi/2);
    joint5to6Tr = GetJointToJointTr(q(6),0,     0,      0); 
    toolTr = eye(4);
    myFkineTr = baseTr * joint0to1Tr * joint1to2Tr * joint2to3Tr * joint3to4Tr * joint4to5Tr * joint5to6Tr * toolTr; 
    
% end

% profile off;
% profile viewer;

%% GetJointToJointTr
function tr = GetJointToJointTr(q,d,a,alpha)
    tr = trotz(q) * transl([0,0,d]) * transl([a,0,0]) * trotx(alpha);
end
end
