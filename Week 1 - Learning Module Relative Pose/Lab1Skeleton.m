classdef Lab1Skeleton < handle
    methods
        function self = Lab1Skeleton()
            cla;
            self.Question1();
            self.Question2();
            self.Questions3And4();
        end
    end

    methods (Static)
        %% Question 1
        function Question1()
            disp('1) Download and install the Robotics Toolbox for MATLAB.');
            disp('2) Run some example demos to test your setup.');
            % Uncomment the line below after setup
            % rtbdemo
        end  

        %% Question 2
        function Question2()
            set(gcf,'Name','Question 2');

            % 2.1) Display track image
            Lab1Skeleton.PlotRaceTrack();

            % 2.2) Create car1 initial pose at (300, 550) facing right
            % Hint: use SE2(x, y, theta) to create transform
            % car1Tr = SE2(300, 550, 0).T;

            % 2.3) Plot transform using trplot2
            % trplot2(car1Tr, 'frame', '1', 'color', 'b', 'length', 50);

            % 2.4) Compute car1 motion transform
            totalSteps = 360;
            % Hint: Use track radius to define linear motion per step
            % car1MoveTr = SE2(...).T;
            % car1TurnTr = SE2(...).T;

            for i = 1:totalSteps
                % 2.5) Update car1 pose using transform multiplication
                % car1Tr = car1Tr * car1MoveTr * car1TurnTr;

                % 2.6) Redraw updated pose
                try delete(car1Tr_h); end %#ok<TRYNC>
                try delete(text_h); end %#ok<TRYNC>

                % car1Tr_h = trplot2(car1Tr, 'frame', '1', 'color', 'b', 'length', 50);
                % message = sprintf(...); % format transform as text
                % text_h = text(10, 50, message, 'FontSize', 10, 'Color', [.6 .2 .6]);

                drawnow();
            end
        end

        %% Questions 3 and 4
        function Questions3And4()
            for question = 3:4
                set(gcf,'Name',['Question ',num2str(question)]);

                if question == 4
                    subplot(1, 2, 1);
                end

                Lab1Skeleton.PlotRaceTrack();

                % 3.1) Create car1 and car2 initial poses
                % car1Tr = SE2(300, 550, 0).T;
                % car2Tr = SE2(300, 125, 0).T;

                if question == 4
                    subplot(1, 2, 2);
                    xlabel('Timestep');
                    ylabel('Sensor reading - distance between cars');
                    hold on;
                    % dist = zeros(1, totalSteps);
                end

                totalSteps = 360;
                % Define car motion transforms
                % car1MoveTr = ...
                % car1TurnTr = ...
                % car2MoveTr = ...
                % car2TurnTr = ...

                for i = 1:totalSteps
                    % Update car poses
                    % car1Tr = car1Tr * car1MoveTr * car1TurnTr;
                    % car2Tr = car2Tr * car2MoveTr * car2TurnTr;

                    % Print relative transforms
                    % inv(car1Tr) * car2Tr;
                    % inv(car2Tr) * car1Tr;

                    if question == 4
                        subplot(1, 2, 1);
                    end

                    try delete(car1Tr_h); end %#ok<TRYNC>
                    try delete(car2Tr_h); end %#ok<TRYNC>

                    % car1Tr_h = trplot2(car1Tr, ...);
                    % car2Tr_h = trplot2(car2Tr, ...);

                    if question == 4
                        subplot(1, 2, 2);
                        % dist(i) = norm(...);
                        % plot(1:i, dist(1:i), 'b-');
                    end

                    drawnow();
                end
            end
        end

        %% Helper: PlotRaceTrack        
        function PlotRaceTrack()
            imshow('Lab1CircularRaceTrack.jpg');
            axis on;
            hold on;
        end
    end
end
