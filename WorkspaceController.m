classdef WorkspaceController < handle
    %WORKSPACECONTROLLER Coordinates robot tasks, GUI, and safety logic.

    properties (SetObservable)
        motionState string = "idle";
    end

    properties
        robots struct = struct();
        robotOrder cell = {};
        robotHomeConfigs struct = struct();

        bookManager
        safety SafetyController

        gui struct = struct();

        isSorting logical = false;
        isEStopActive logical = false;
        resumeArmed logical = false;
        hazardReason string = "";

        statusHistory cell = {};
    end

    methods
        function self = WorkspaceController()
        end

        function launch(self)
            EnvironmentManager;
            fprintf('Spawning books...\n');
            BookSpawner.spawnBooks();
            BookSpawner.drawBookStartMarkers();

            robotArray = RobotFactory.createAllRobots();
            self.mapRobots(robotArray);

            self.bookManager = BookManager();
            self.bookManager.storeBookHandles();

            self.safety = SafetyController(self);
            self.safety.registerRobots(self.robots);

            self.createGui();
            self.updateStatus('Workspace initialised. Ready to sort.');
        end

        function startSortingSequence(self, ~, ~)
            if self.isSorting
                self.updateStatus('Sorting already in progress.');
                return;
            end

            if self.isEStopActive
                self.updateStatus('Release the E-stop before starting.');
                return;
            end

            self.isSorting = true;
            self.motionState = "running";
            self.resumeArmed = true;
            self.updateStatus('Linear UR3 beginning colour separation.');

            try
                self.bookManager.reset();
                self.bookManager.storeBookHandles();

                processed = BookPickAndPlace(self.robots.linearUR3, self.bookManager, self.safety);
                self.refreshTeachSliders();

                self.updateStatus(sprintf('UR3 completed initial sort (%d books). Dispatching colour robots...', processed));

                deliveredBlue = MotomanPickAndPlace(self.robots.motoman, self.bookManager, 'blue', self.safety);
                self.refreshTeachSliders();

                deliveredRed = KukaPickAndPlace(self.robots.kuka, self.bookManager, 'red', self.safety);
                self.refreshTeachSliders();

                deliveredGreen = AuboPickAndPlace(self.robots.aubo, self.bookManager, 'green', self.safety);
                self.refreshTeachSliders();

                summary = sprintf('Delivery complete. Blue:%d Red:%d Green:%d.', deliveredBlue, deliveredRed, deliveredGreen);
                self.updateStatus(summary);
            catch ME
                self.updateStatus(['Error: ' ME.message]);
                warning(ME.identifier, '%s', ME.message);
            end

            self.finishSorting();
        end

        function finishSorting(self)
            self.motionState = "idle";
            self.isSorting = false;
            self.resumeArmed = false;
            self.refreshTeachSliders();
        end

        function pauseForSafety(self, reason)
            if nargin < 2
                reason = 'Safety stop';
            end
            self.hazardReason = string(reason);
            if self.motionState ~= "paused"
                self.motionState = "paused";
                self.updateStatus(['Paused: ' char(reason)]);
            end
            self.resumeArmed = false;
        end

        function releaseEStop(self, ~, ~)
            if ~self.isEStopActive
                self.updateStatus('E-stop already released.');
                return;
            end
            self.isEStopActive = false;
            self.updateStatus('E-stop released. Press Resume to continue.');
        end

        function resumeMotion(self, ~, ~)
            if self.isEStopActive
                self.updateStatus('Release the E-stop before resuming.');
                return;
            end
            if self.safety.isSensorActive()
                self.updateStatus('Clear light curtain before resuming.');
                return;
            end
            self.motionState = "running";
            self.resumeArmed = true;
            if strlength(self.hazardReason) > 0
                self.updateStatus(['Resuming after: ' char(self.hazardReason)]);
            else
                self.updateStatus('Resuming operations.');
            end
        end

        function onEStopPressed(self, ~, ~)
            if self.isEStopActive
                self.updateStatus('E-stop already active.');
                return;
            end
            self.isEStopActive = true;
            self.pauseForSafety('Emergency stop engaged');
            self.updateStatus('Emergency stop engaged. Release then resume.');
        end

        function onSensorToggle(self, src, ~)
            state = get(src, 'Value');
            self.safety.setSensorActive(state);
            if state
                set(src, 'String', 'Light Curtain ACTIVE');
            else
                set(src, 'String', 'Light Curtain Clear');
            end
        end

        function triggerHardwareEStop(self)
            self.onEStopPressed();
            self.updateStatus('Hardware E-stop signal received.');
        end

        function onKeyPress(self, event)
            if strcmp(event.Key, 'escape') || strcmp(event.Key, 'space')
                self.triggerHardwareEStop();
            end
        end

        function onGuiClose(self, src, ~)
            try
                self.finishSorting();
            catch
            end
            delete(src);
        end

        function updateStatus(self, message)
            msg = char(message);
            if isfield(self.gui, 'statusText') && isgraphics(self.gui.statusText)
                set(self.gui.statusText, 'String', msg);
            end

            if isfield(self.gui, 'statusLamp') && isgraphics(self.gui.statusLamp)
                color = self.getStatusColor();
                set(self.gui.statusLamp, 'BackgroundColor', color);
            end

            self.statusHistory{end+1} = struct('time', datetime('now'), 'message', msg); %#ok<AGROW>
            drawnow('limitrate');
        end

        function color = getStatusColor(self)
            switch self.motionState
                case "running"
                    color = [0.0, 0.7, 0.2];
                case "paused"
                    color = [0.95, 0.65, 0.1];
                otherwise
                    color = [0.3, 0.6, 0.9];
            end
        end

        function robot = getSelectedRobot(self)
            robot = [];
            if ~isfield(self.gui, 'robotPopup') || ~isgraphics(self.gui.robotPopup)
                return;
            end
            idx = get(self.gui.robotPopup, 'Value');
            if idx < 1 || idx > numel(self.robotOrder)
                return;
            end
            key = self.robotOrder{idx};
            robot = self.robots.(key);
        end

        function onRobotSelectionChanged(self, src, ~)
            idx = get(src, 'Value');
            if idx < 1 || idx > numel(self.robotOrder)
                return;
            end
            self.setupJointSliders();
            self.refreshTeachSliders();
        end

        function onJointSliderChanged(self, jointIdx, slider)
            robot = self.getSelectedRobot();
            if isempty(robot)
                return;
            end

            targetValue = get(slider, 'Value');

            try
                qlim = robot.model.qlim;
                if size(qlim, 1) >= jointIdx
                    targetValue = min(max(targetValue, qlim(jointIdx, 1)), qlim(jointIdx, 2));
                    set(slider, 'Value', targetValue);
                end
            catch
                % Leave targetValue unchanged if limits unavailable.
            end
            currentQ = robot.model.getpos();
            targetQ = currentQ;
            targetQ(jointIdx) = targetValue;

            if ~self.safety.ensureMotionPermitted(robot, targetQ)
                set(slider, 'Value', currentQ(jointIdx));
                return;
            end

            robot.model.animate(targetQ);
            self.safety.notifyRobotPose(robot, targetQ);
            self.refreshTeachSliders();
        end

        function onCartesianJog(self, axis, direction)
            robot = self.getSelectedRobot();
            if isempty(robot)
                return;
            end

            step = str2double(get(self.gui.stepSizeEdit, 'String'));
            if isnan(step) || step <= 0
                step = 0.02;
            end
            step = min(max(step, 0.005), 0.2);

            currentQ = robot.model.getpos();
            try
                currentPose = robot.model.fkine(currentQ);
            catch
                currentPose = robot.model.fkineUTS(currentQ);
            end
            target = transl(currentPose);
            axisIndex = find('xyz' == axis, 1);
            if isempty(axisIndex)
                return;
            end
            target(axisIndex) = target(axisIndex) + direction * step;

            if SafeMotion.moveRobotWithConfig(robot, target', currentQ, self.safety)
                self.refreshTeachSliders();
            end
        end

        function refreshTeachSliders(self)
            robot = self.getSelectedRobot();
            if isempty(robot) || ~isfield(self.gui, 'jointSliders')
                return;
            end
            q = robot.model.getpos();
            for i = 1:numel(self.gui.jointSliders)
                slider = self.gui.jointSliders{i};
                if isgraphics(slider)
                    set(slider, 'Value', q(i));
                end
            end
        end
    end

    methods (Access = private)
        function mapRobots(self, robotArray)
            if ~iscell(robotArray)
                robotArray = {robotArray};
            end

            names = {'linearUR3', 'motoman', 'kuka', 'aubo'};
            for i = 1:min(numel(robotArray), numel(names))
                self.robots.(names{i}) = robotArray{i};
            end
            self.robotOrder = names(1:numel(robotArray));

            fields = fieldnames(self.robots);
            for i = 1:numel(fields)
                key = fields{i};
                robot = self.robots.(key);
                q = robot.model.getpos();
                if isempty(q)
                    q = zeros(1, robot.model.n);
                end
                self.robotHomeConfigs.(key) = q;
            end
        end

        function createGui(self)
            fig = figure('Name', 'Book Sorting Control', ...
                'NumberTitle', 'off', ...
                'MenuBar', 'none', ...
                'ToolBar', 'none', ...
                'Color', [0.15, 0.15, 0.18], ...
                'Position', [50, 50, 520, 640], ...
                'CloseRequestFcn', @(src, evt) self.onGuiClose(src, evt), ...
                'WindowKeyPressFcn', @(~, evt) self.onKeyPress(evt));

            self.gui.fig = fig;

            ctrlPanel = uipanel('Parent', fig, 'Title', 'System Control', ...
                'Units', 'normalized', 'Position', [0.02, 0.55, 0.46, 0.43], ...
                'BackgroundColor', [0.18, 0.18, 0.2], 'ForegroundColor', [1, 1, 1]);

            statusLamp = uicontrol('Parent', ctrlPanel, 'Style', 'text', ...
                'Units', 'normalized', 'Position', [0.03, 0.75, 0.12, 0.18], ...
                'BackgroundColor', self.getStatusColor(), 'String', '', 'Enable', 'inactive');
            statusText = uicontrol('Parent', ctrlPanel, 'Style', 'text', ...
                'Units', 'normalized', 'Position', [0.18, 0.73, 0.78, 0.22], ...
                'String', 'Status', 'BackgroundColor', [0.18, 0.18, 0.2], ...
                'ForegroundColor', [1, 1, 1], 'HorizontalAlignment', 'left', 'FontSize', 11);

            startButton = uicontrol('Parent', ctrlPanel, 'Style', 'pushbutton', ...
                'Units', 'normalized', 'Position', [0.05, 0.5, 0.4, 0.18], ...
                'String', 'Start Sorting', 'FontWeight', 'bold', ...
                'Callback', @(src, evt) self.startSortingSequence());

            resumeButton = uicontrol('Parent', ctrlPanel, 'Style', 'pushbutton', ...
                'Units', 'normalized', 'Position', [0.55, 0.5, 0.4, 0.18], ...
                'String', 'Resume Motion', ...
                'Callback', @(src, evt) self.resumeMotion());

            estopButton = uicontrol('Parent', ctrlPanel, 'Style', 'pushbutton', ...
                'Units', 'normalized', 'Position', [0.05, 0.25, 0.4, 0.18], ...
                'String', 'Emergency Stop', 'ForegroundColor', [1, 0.1, 0.1], ...
                'Callback', @(src, evt) self.onEStopPressed());

            releaseButton = uicontrol('Parent', ctrlPanel, 'Style', 'pushbutton', ...
                'Units', 'normalized', 'Position', [0.55, 0.25, 0.4, 0.18], ...
                'String', 'Release E-Stop', ...
                'Callback', @(src, evt) self.releaseEStop());

            sensorToggle = uicontrol('Parent', ctrlPanel, 'Style', 'togglebutton', ...
                'Units', 'normalized', 'Position', [0.05, 0.05, 0.9, 0.15], ...
                'String', 'Light Curtain Clear', ...
                'Callback', @(src, evt) self.onSensorToggle(src, evt));

            teachPanel = uipanel('Parent', fig, 'Title', 'Teach Jog Controls', ...
                'Units', 'normalized', 'Position', [0.52, 0.28, 0.46, 0.70], ...
                'BackgroundColor', [0.18, 0.18, 0.2], 'ForegroundColor', [1, 1, 1]);

            robotPopup = uicontrol('Parent', teachPanel, 'Style', 'popupmenu', ...
                'Units', 'normalized', 'Position', [0.05, 0.88, 0.9, 0.1], ...
                'String', self.buildRobotNames(), ...
                'Callback', @(src, evt) self.onRobotSelectionChanged(src, evt));

            self.gui.robotPopup = robotPopup;
            self.gui.statusText = statusText;
            self.gui.statusLamp = statusLamp;
            self.gui.estopButton = estopButton;
            self.gui.releaseButton = releaseButton;
            self.gui.resumeButton = resumeButton;
            self.gui.sensorToggle = sensorToggle;
            self.gui.controlPanel = ctrlPanel;
            self.gui.teachPanel = teachPanel;

            cartPanel = uipanel('Parent', fig, 'Title', 'Cartesian Jog', ...
                'Units', 'normalized', 'Position', [0.02, 0.05, 0.46, 0.47], ...
                'BackgroundColor', [0.18, 0.18, 0.2], 'ForegroundColor', [1, 1, 1]);

            stepLabel = uicontrol('Parent', cartPanel, 'Style', 'text', ...
                'Units', 'normalized', 'Position', [0.05, 0.8, 0.5, 0.15], ...
                'String', 'Step (m):', 'BackgroundColor', [0.18, 0.18, 0.2], ...
                'ForegroundColor', [1, 1, 1], 'HorizontalAlignment', 'left');
            stepEdit = uicontrol('Parent', cartPanel, 'Style', 'edit', ...
                'Units', 'normalized', 'Position', [0.6, 0.8, 0.35, 0.18], ...
                'String', '0.05');

            btnNames = {'X+', 'X-', 'Y+', 'Y-', 'Z+', 'Z-'};
            axesMap = {'x', 'x', 'y', 'y', 'z', 'z'};
            directions = [1, -1, 1, -1, 1, -1];
            for i = 1:6
                xpos = 0.05 + 0.45 * mod(i-1, 2);
                ypos = 0.55 - 0.18 * floor((i-1)/2);
                uicontrol('Parent', cartPanel, 'Style', 'pushbutton', ...
                    'Units', 'normalized', 'Position', [xpos, ypos, 0.4, 0.16], ...
                    'String', btnNames{i}, ...
                    'Callback', @(~, ~) self.onCartesianJog(axesMap{i}, directions(i)));
            end

            self.gui.stepSizeEdit = stepEdit;

            self.setupJointSliders();
            self.refreshTeachSliders();
        end

        function names = buildRobotNames(self)
            pretty = containers.Map({'linearUR3','motoman','kuka','aubo'}, ...
                {'Linear UR3','Motoman GP4','KUKA KR3','AUBO i5'});
            names = cell(1, numel(self.robotOrder));
            for i = 1:numel(self.robotOrder)
                key = self.robotOrder{i};
                if pretty.isKey(key)
                    names{i} = pretty(key);
                else
                    names{i} = key;
                end
            end
        end

        function setupJointSliders(self)
            if ~isfield(self.gui, 'teachPanel') || ~isgraphics(self.gui.teachPanel)
                return;
            end

            panel = self.gui.teachPanel;
            existing = findall(panel, 'Tag', 'JointSlider');
            delete(existing);

            robot = self.getSelectedRobot();
            if isempty(robot)
                self.gui.jointSliders = {};
                return;
            end

            qlim = robot.model.qlim;
            sliderCount = size(qlim, 1);
            sliders = cell(1, sliderCount);
            for i = 1:sliderCount
                ypos = 0.8 - 0.08 * i;
                uicontrol('Parent', panel, 'Style', 'text', 'Units', 'normalized', ...
                    'Position', [0.05, ypos + 0.04, 0.2, 0.05], 'String', sprintf('J%d', i), ...
                    'BackgroundColor', [0.18, 0.18, 0.2], 'ForegroundColor', [1, 1, 1]);
                slider = uicontrol('Parent', panel, 'Style', 'slider', 'Units', 'normalized', ...
                    'Position', [0.25, ypos, 0.65, 0.05], 'Min', qlim(i, 1), 'Max', qlim(i, 2), ...
                    'Tag', 'JointSlider', ...
                    'Callback', @(src, ~) self.onJointSliderChanged(i, src));
                sliders{i} = slider;
            end
            self.gui.jointSliders = sliders;
        end
    end
end
