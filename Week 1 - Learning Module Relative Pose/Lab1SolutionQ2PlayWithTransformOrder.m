function Lab1SolutionQ2PlayWithTransformOrder(  )

close all;

%% Question 2 (Play with changes in the order of transforms)
set(gcf,'Name',['Question ',num2str(2)])
imshow('Lab1CircularRaceTrack.jpg');
axis on
hold on;

car1Tr = SE2(300, 550, 0).T;
car2Tr = SE2(300, 550, 0).T;
car3Tr = SE2(300, 550, 0).T;
car1Tr_h = trplot2(car1Tr, 'frame', '1', 'color', 'b','length',50);
car2Tr_h = trplot2(car2Tr, 'frame', '2', 'color', 'r','length',50);
car3Tr_h = trplot2(car3Tr, 'frame', '3', 'color', 'g','length',50);

% The track diameter to outside lane is (550-66) = 484
% Approx circumference = pi * 484 = 1521
forLoopIncrements = 360;

% So the transform each step is
carMoveTr = SE2((pi * 484)/forLoopIncrements, 0, 0).T;
carTurnTr = SE2(0, 0, -2*pi/forLoopIncrements).T;
carMoveAndTurnTr = SE2((pi * 484)/forLoopIncrements, 0, -2*pi/forLoopIncrements).T;

for i = 1:forLoopIncrements
    car1Tr = car1Tr * carMoveTr * carTurnTr;    
    car2Tr = car2Tr * carMoveAndTurnTr;
    car3Tr = car3Tr * carTurnTr * carMoveTr;
    
    try delete(car1Tr_h);end
    try delete(car2Tr_h);end
    try delete(car3Tr_h);end
    try delete(text1_h);end;
    try delete(text2_h);end;
    try delete(text3_h);end;

    car1Tr_h = trplot2(car1Tr, 'frame', '1', 'color', 'b','length',50);
    car2Tr_h = trplot2(car2Tr, 'frame', '2', 'color', 'r','length',50);
    car3Tr_h = trplot2(car3Tr, 'frame', '3', 'color', 'g','length',50);

    message1 = sprintf(['Frame 1 (BLUE) Move THEN Turn \n' ...
        ,num2str(round(car1Tr(1,:),3,'significant')),'\n' ...
                      ,num2str(round(car1Tr(2,:),3,'significant')),'\n' ...
                      ,num2str(round(car1Tr(3,:),3,'significant'))]);
    message2 = sprintf(['Frame 2 (RED) Move AND Turn \n' ...
        ,num2str(round(car2Tr(1,:),3,'significant')),'\n' ...
                      ,num2str(round(car2Tr(2,:),3,'significant')),'\n' ...
                      ,num2str(round(car2Tr(3,:),3,'significant'))]);
    message3 = sprintf(['Frame 3 (GREEN) Turn THEN Move \n' ...
        ,num2str(round(car3Tr(1,:),3,'significant')),'\n' ...
                      ,num2str(round(car3Tr(2,:),3,'significant')),'\n' ...
                      ,num2str(round(car3Tr(3,:),3,'significant'))]);
                  
    text1_h = text(10, 50, message1, 'FontSize', 10, 'Color', [0 0 0]);
    text2_h = text(450, 50, message2, 'FontSize', 10, 'Color', [0 0 0]);
    text3_h = text(450, 570, message3, 'FontSize', 10, 'Color', [0 0 0]);
    
    drawnow();
end
