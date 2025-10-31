classdef Lab1Solution < handle

    methods
        function self = Lab1Solution()
            cla;
            self.Question1();
			self.Question2();
            self.Questions3And4();
        end
    end

    methods (Static)
		%% Question 1
        function Question1()
            disp('Download and setup the Robotics Toolbox. See videos and links in Canvas.')
            disp('Uncomment and running "rtbdemo". Close figure when you have finished')
            % rtbdemo % <- Uncomment this
        end  
    
		%% Question 2
        function Question2()			
            set(gcf,'Name',['Question ',num2str(2)])
            
            Lab1Solution.PlotRaceTrack();

            car1Tr = SE2(300, 550, 0).T;
            car1Tr_h = trplot2(car1Tr, 'frame', '1', 'color', 'b','length',50);
            
            % The track diameter to outside lane is (550-66) = 484
            % Approx circumference = pi * 484 = 1521
            
            totalSteps = 360; % step could per revolulation 
            
            % So the transform at each step is
            car1MoveTr = SE2((pi * 484)/totalSteps, 0, 0).T;
            car1TurnTr = SE2(0, 0, -2*pi/totalSteps).T;
            
            for i = 1:totalSteps
                car1Tr = car1Tr * car1MoveTr * car1TurnTr;
                try delete(car1Tr_h);end %#ok<TRYNC>
                try delete(text_h);end %#ok<TRYNC>
                car1Tr_h = trplot2(car1Tr, 'frame', '1', 'color', 'b','length',50);
                message = sprintf([num2str(round(car1Tr(1,:),2,'significant')),'\n' ...
                                  ,num2str(round(car1Tr(2,:),2,'significant')),'\n' ...
                                  ,num2str(round(car1Tr(3,:),2,'significant'))]);
                text_h = text(10, 50, message, 'FontSize', 10, 'Color', [.6 .2 .6]);
                drawnow();
            end
        end
    
		%% Questions 3 and 4
        function Questions3And4()
            for question = 3:4
				set(gcf,'Name',['Question ',num2str(question)])
				if question == 4
					subplot(1,2,1);
				end
    
                Lab1Solution.PlotRaceTrack();
				car1Tr = SE2(300, 550, 0).T;
				car2Tr = SE2(300, 125, 0).T;
                
				% For distance plot (i.e. question 4)
				if question == 4
					subplot(1,2,2);
					xlabel('Timestep');
					ylabel('Sensor reading - distance between cars');
					hold on;
				end     
            
                % The track diameter to outside lane is (550 - 66) = 484
                % Approx circumference = pi * 484 = 1521
                % The track diameter to inside lane is (500 - 125) = 375
                % Approx circumference = pi * 375 = 1178
            
                totalSteps = 360;
                % So the transform each step is
                car1MoveTr = SE2((pi * 484)/totalSteps, 0, 0).T;
                car1TurnTr = SE2(0, 0, -2*pi/totalSteps).T;
                
                car2MoveTr = SE2((pi * 375)/totalSteps, 0, 0).T;
                car2TurnTr = SE2(0, 0, 2*pi/totalSteps).T;
                dist = zeros(1,totalSteps);
            
                for i = 1:totalSteps
                    car1Tr = car1Tr * car1MoveTr * car1TurnTr;
                    car2Tr = car2Tr * car2MoveTr * car2TurnTr;
                    
                    disp('car1_to_2Tr = ');
                    inv(car1Tr) * car2Tr %#ok<NOPRT,MINV>
                    disp('car2_to_1Tr = '); 
                    inv(car2Tr) * car1Tr %#ok<NOPRT,MINV>
                    
					if question == 4
						subplot(1,2,1);
					end
					
                    try delete(car1Tr_h);end %#ok<TRYNC>
                    try delete(car2Tr_h);end %#ok<TRYNC>
                    
                    car1Tr_h = trplot2(car1Tr, 'frame', '1', 'color', 'b','length',50);
                    car2Tr_h = trplot2(car2Tr, 'frame', '2', 'color', 'r','length',50);
                    
					if question == 4            
						subplot(1,2,2);
						try delete(distPlot_h);end %#ok<TRYNC>
						dist(i) = sqrt(sum((car1Tr(1:2,3) - car2Tr(1:2,3)).^2));
						distPlot_h = plot(1:i,dist(1:i),'b-');
					end
                    
                    drawnow();
                end
            end
        end

		%% PlotRaceTrack        
        function PlotRaceTrack()
            imshow('Lab1CircularRaceTrack.jpg');
            axis on
            hold on;
        end
    end
end
