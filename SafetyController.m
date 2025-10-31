classdef SafetyController < handle
    %SAFETYCONTROLLER Coordinates global safety interlocks and collision checks.

    properties
        controller
        robots = struct();
        collisionThreshold = 0.25;
        restrictedZones
        sensorActive logical = false;
        hazardHistory cell = {};
    end

    methods
        function self = SafetyController(controller)
            if nargin < 1
                error('SafetyController requires a WorkspaceController reference.');
            end
            self.controller = controller;
            self.restrictedZones = self.createDefaultZones();
        end

        function registerRobots(self, robots)
            if isempty(robots)
                return;
            end
            self.robots = robots;
        end

        function setSensorActive(self, active)
            self.sensorActive = logical(active);
            if self.sensorActive
                self.controller.pauseForSafety('Light curtain triggered');
                self.logHazard('Light curtain trigger activated');
            else
                self.controller.updateStatus('Light curtain cleared - press Resume to continue.');
            end
        end

        function active = isSensorActive(self)
            active = self.sensorActive;
        end

        function allowed = ensureMotionPermitted(self, robot, qCandidate)
            allowed = true;

            if isempty(robot) || ~isprop(robot, 'model')
                allowed = false;
                return;
            end

            if self.controller.isEStopActive
                self.controller.pauseForSafety('Emergency stop engaged');
            end

            if self.sensorActive
                self.controller.pauseForSafety('Light curtain triggered');
            end

            if self.controller.motionState ~= "running"
                self.waitForClearance();
                allowed = self.controller.motionState == "running";
                if ~allowed
                    return;
                end
            end

            try
                qlim = robot.model.qlim;
                lower = qlim(:, 1);
                upper = qlim(:, 2);
                qRow = double(qCandidate(:))';
                if any(qRow < lower' - 1e-6) || any(qRow > upper' + 1e-6)
                    self.controller.pauseForSafety('Requested joint move exceeds limits');
                    self.logHazard('Joint limit violation prevented');
                    allowed = false;
                    return;
                end
                qCandidate = reshape(qRow, size(qCandidate));
            catch
            end

            if self.detectPotentialCollision(robot, qCandidate)
                self.waitForClearance();
                allowed = self.controller.motionState == "running";
            end
        end

        function notifyRobotPose(self, robot, qState)
            if nargin < 3
                qState = robot.model.getpos();
            end
            self.detectPotentialCollision(robot, qState, 'notify');
        end

        function waitForClearance(self)
            waitfor(self.controller, 'motionState', "running");
        end

        function setCollisionThreshold(self, value)
            self.collisionThreshold = max(0.05, double(value));
        end

        function logHazard(self, message)
            entry = struct('message', char(message), 'time', datetime('now'));
            self.hazardHistory{end+1} = entry;
        end
    end

    methods (Access = private)
        function collision = detectPotentialCollision(self, robot, qCandidate, mode)
            if nargin < 4
                mode = 'check';
            end

            collision = false;
            if isempty(robot) || ~isprop(robot, 'model')
                return;
            end

            candidatePose = [];
            try
                candidatePose = robot.model.fkine(qCandidate);
            catch
            end
            if isempty(candidatePose)
                try
                    candidatePose = robot.model.fkineUTS(qCandidate);
                catch
                    candidatePose = [];
                end
            end

            candidatePos = transl(candidatePose);
            if isempty(candidatePos)
                return;
            end

            for zoneIdx = 1:numel(self.restrictedZones)
                zone = self.restrictedZones(zoneIdx);
                if norm(candidatePos - zone.center) < zone.radius
                    collision = true;
                    reason = sprintf('Proximity alert: %s zone', zone.name);
                    self.controller.pauseForSafety(reason);
                    self.logHazard(reason);
                    break;
                end
            end

            if collision
                return;
            end

            robotNames = fieldnames(self.robots);
            for idx = 1:numel(robotNames)
                other = self.robots.(robotNames{idx});
                if isempty(other) || isequal(other, robot)
                    continue;
                end

                otherPose = [];
                try
                    otherPose = other.model.fkine(other.model.getpos());
                catch
                end
                if isempty(otherPose)
                    try
                        otherPose = other.model.fkineUTS(other.model.getpos());
                    catch
                        otherPose = [];
                    end
                end
                otherPos = transl(otherPose);

                if isempty(otherPos)
                    continue;
                end

                if norm(candidatePos - otherPos) < self.collisionThreshold
                    collision = true;
                    reason = sprintf('Proximity to %s below threshold', other.model.name);
                    self.controller.pauseForSafety(reason);
                    self.logHazard(reason);
                    break;
                end
            end

            if collision && strcmp(mode, 'notify')
                % Already handled via pause/log.
            end
        end

        function zones = createDefaultZones(~)
            zones = struct( ...
                'name', {'Human Observer', 'North Barrier', 'South Barrier'}, ...
                'center', {[-3, 0, 0], [0, 1.5, 0], [0, -1.5, 0]}, ...
                'radius', {0.6, 0.45, 0.45});
        end
    end
end
