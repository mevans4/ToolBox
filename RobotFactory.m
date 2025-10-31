classdef RobotFactory
        % table_height = 0.5;
        % table_width = 2.1;
        % table_depth = 1.4;

    methods (Static)

        function robots = createAllRobots()
            % Create all robots and return as cell array
            robots = {};

            % LinearUR3
            ur3_pos_x = -1.05 - 0.35; %table1_pos - 0.35 
            ur3_pos_y = 0;
            linearUR3_base = transl(ur3_pos_x, ur3_pos_y, 0) * trotz(-pi/2);
            robots{1} = LinearUR3(linearUR3_base);
            fprintf('LinearUR3 Created.\n');

            % YaskawaMotomanGP4
            YaskawaMotomanGP4_pos_x = 0;
            YaskawaMotomanGP4_pos_y = 0.25 * 2.1;
            YaskawaMotomanGP4_base = transl(YaskawaMotomanGP4_pos_x, YaskawaMotomanGP4_pos_y, 0) * trotz(-pi/2);
            robots{2} = YaskawaGP4(YaskawaMotomanGP4_base);
            fprintf('YaskawaMotomanGP4 Created.\n');

            % KukaKr3R540 (commented out but available)
            KukaKr3R540_pos_x = 0;
            KukaKr3R540_pos_y = -0.30 * 2.1;
            KukaKr3R540_base = transl(KukaKr3R540_pos_x, KukaKr3R540_pos_y, 0)*trotz(pi);
            robots{3} = KukaKr3R540(KukaKr3R540_base);
            fprintf('KukaKr3R540 Created.\n');

            % AuboI5 (commented out but available)
            % table_depth = 1.4;
            % AuboI5_pos_x = 1.4/4 + 2.1/8;
            % AuboI5_pos_y = 0;
            % AuboI5_base = transl(AuboI5_pos_x, AuboI5_pos_y, 0) * trotz(pi);
            % robots{4} = AuboI5(AuboI5_base);
            % fprintf('AuboI5 Created.\n');
        end

        function robot = createLinearUR3(position, rotation)
            % Create LinearUR3 with custom position and rotation
            if nargin < 2
                rotation = trotz(-pi/2);
            end
            if nargin < 1
                position = [-1.4, 0, 0]; % Default position
            end
            base = transl(position) * rotation;
            robot = LinearUR3(base);
            fprintf('LinearUR3 created at [%.2f, %.2f, %.2f]\n', position(1), position(2), position(3));
        end

        function robot = createYaskawaMotomanGP4(position, rotation)
            % Create YaskawaMotomanGP4 with custom position and rotation
            if nargin < 2
                rotation = trotz(-pi/2);
            end
            if nargin < 1
                position = [0, 0.525, 0]; % Default position
            end
            base = transl(position) * rotation;
            robot = YaskawaGP4(base);
            fprintf('YaskawaMotomanGP4 created at [%.2f, %.2f, %.2f]\n', position(1), position(2), position(3));
        end

        function robot = createKukaKr3R540(position, rotation)
            % Create KukaKr3R540 with custom position and rotation
            if nargin < 2
                rotation = trotz(pi/2);
            end
            if nargin < 1
                position = [0, -0.63, 0]; 
            end
            base = transl(position) * rotation;
            robot = KukaKr3R540(base);
            fprintf('KukaKr3R540 created at [%.2f, %.2f, %.2f]\n', position(1), position(2), position(3));
        end

        function robot = createAuboI5(position, rotation)
            % Create AuboI5 with custom position and rotation
            if nargin < 2
                rotation = trotz(pi);
            end
            if nargin < 1
                position = [0.875, 0, 0]; 
            end
            base = transl(position) * rotation;
            robot = AuboI5(base);
            fprintf('AuboI5 created at [%.2f, %.2f, %.2f]\n', position(1), position(2), position(3));
        end
    end
end