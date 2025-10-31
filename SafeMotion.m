classdef SafeMotion
    %SAFEMOTION Shared motion helpers that integrate safety checks.
    methods (Static)
        function success = moveRobotWithConfig(robot, targetPosition, referenceConfig, safetyController)
            if nargin < 4
                safetyController = [];
            end

            steps = 25;
            qCurrent = robot.model.getpos();
            fprintf('  Moving to [%.3f, %.3f, %.3f] with reference config\n', targetPosition(1), targetPosition(2), targetPosition(3));

            referencePose = robot.model.fkine(referenceConfig);
            targetTransform = referencePose;
            targetTransform(1:3, 4) = targetPosition(:);

            qTarget = robot.model.ikcon(targetTransform, referenceConfig);

            if any(isnan(qTarget))
                fprintf('  WARNING: IK failed with reference config, trying current position\n');
                qTarget = robot.model.ikcon(targetTransform, qCurrent);
            end

            if any(isnan(qTarget))
                fprintf('  ERROR: IK failed completely\n');
                success = false;
                return;
            end

            qTraj = jtraj(qCurrent, qTarget, steps);

            for i = 1:steps
                qStep = qTraj(i, :);
                if ~isempty(safetyController)
                    if ~safetyController.ensureMotionPermitted(robot, qStep)
                        success = false;
                        return;
                    end
                end

                robot.model.animate(qStep);

                if ~isempty(safetyController)
                    safetyController.notifyRobotPose(robot, qStep);
                end

                drawnow('limitrate');
                pause(0.01);
            end

            success = true;
        end

        function success = moveRobotWithBookPerfectPlacement(robot, targetPosition, bookHandle, bookData, referenceConfig, safetyController)
            if nargin < 6
                safetyController = [];
            end

            steps = 25;
            qCurrent = robot.model.getpos();
            fprintf('  Moving with book to [%.3f, %.3f, %.3f]\n', targetPosition(1), targetPosition(2), targetPosition(3));

            referencePose = robot.model.fkine(referenceConfig);
            targetTransform = referencePose;
            targetTransform(1:3, 4) = targetPosition(:);

            qTarget = robot.model.ikcon(targetTransform, referenceConfig);

            if any(isnan(qTarget))
                fprintf('  WARNING: IK failed with reference config, trying current position\n');
                qTarget = robot.model.ikcon(targetTransform, qCurrent);
            end

            if any(isnan(qTarget))
                fprintf('  WARNING: IK failed with current config, trying analytical IK\n');
                qTarget = robot.model.ikine(targetTransform, 'q0', referenceConfig, 'mask', [1 1 1 1 1 1], 'tol', 0.01);
            end

            if any(isnan(qTarget))
                fprintf('  WARNING: Analytical IK failed, trying with relaxed orientation\n');
                qTarget = robot.model.ikine(targetTransform, 'q0', referenceConfig, 'mask', [1 1 1 1 1 0], 'tol', 0.02);
            end

            if any(isnan(qTarget))
                fprintf('  ERROR: All IK methods failed, using best approximation\n');
                qTarget = qCurrent;
            end

            qTraj = jtraj(qCurrent, qTarget, steps);
            initialEePose = robot.model.fkineUTS(qCurrent);

            for i = 1:steps
                q = qTraj(i, :);
                if ~isempty(safetyController)
                    if ~safetyController.ensureMotionPermitted(robot, q)
                        success = false;
                        return;
                    end
                end

                robot.model.animate(q);

                try
                    currentEePose = robot.model.fkineUTS(q);
                    relativeTransform = currentEePose / initialEePose;
                    currentVerts = bookData.originalVerts;
                    originalCenter = mean(currentVerts, 1);
                    centeredVerts = currentVerts - originalCenter;
                    rotatedVerts = (relativeTransform(1:3, 1:3) * centeredVerts')';
                    calculatedBookPos = currentEePose(1:3, 4)' + bookData.offset;
                    newVerts = rotatedVerts + calculatedBookPos;
                    set(bookHandle, 'Vertices', newVerts);
                catch ME
                    fprintf('  WARNING: Failed to update book position: %s\n', ME.message);
                    try
                        currentEePose = robot.model.fkineUTS(q);
                    catch
                        currentEePose = robot.model.fkine(q);
                    end
                    eePos = transl(currentEePose)';
                    calculatedBookPos = eePos + bookData.offset;
                    originalVerts = bookData.originalVerts;
                    originalCenter = mean(originalVerts, 1);
                    translation = calculatedBookPos - originalCenter;
                    set(bookHandle, 'Vertices', originalVerts + translation);
                end

                if ~isempty(safetyController)
                    safetyController.notifyRobotPose(robot, q);
                end

                drawnow('limitrate');
                pause(0.01);
            end

            if isfield(bookData, 'targetPos')
                finalVerts = get(bookHandle, 'Vertices');
                currentCenter = mean(finalVerts, 1);
                targetCenter = bookData.targetPos;

                if norm(targetPosition - bookData.targetPos) < 0.1
                    positionError = targetCenter - currentCenter;
                    if norm(positionError) > 0.001
                        fprintf('  Final position adjustment: [%.3f, %.3f, %.3f]\n', ...
                            positionError(1), positionError(2), positionError(3));
                        set(bookHandle, 'Vertices', finalVerts + positionError);
                    end
                end
            end

            success = true;
        end

        function success = moveRobotWithEnhancedPlacement(robot, targetPosition, bookHandle, bookData, referenceConfig, safetyController)
            if nargin < 6
                safetyController = [];
            end

            steps = 25;
            qCurrent = robot.model.getpos();
            fprintf('  Using ENHANCED placement for [%.3f, %.3f, %.3f]\n', targetPosition(1), targetPosition(2), targetPosition(3));

            referencePose = robot.model.fkine(referenceConfig);
            targetTransform = referencePose;
            targetTransform(1:3, 4) = targetPosition(:);

            qTarget = qCurrent;
            qTraj = jtraj(qCurrent, qTarget, steps);

            for i = 1:steps
                q = qTraj(i, :);
                if ~isempty(safetyController)
                    if ~safetyController.ensureMotionPermitted(robot, q)
                        success = false;
                        return;
                    end
                end

                robot.model.animate(q);

                try
                    currentEePose = robot.model.fkineUTS(q);
                catch
                    currentEePose = robot.model.fkine(q);
                end
                eePos = transl(currentEePose)';
                calculatedBookPos = eePos + bookData.offset;
                originalVerts = bookData.originalVerts;
                originalCenter = mean(originalVerts, 1);
                translation = calculatedBookPos - originalCenter;
                set(bookHandle, 'Vertices', originalVerts + translation);

                if ~isempty(safetyController)
                    safetyController.notifyRobotPose(robot, q);
                end

                drawnow('limitrate');
                pause(0.01);
            end

            if isfield(bookData, 'targetPos')
                finalVerts = get(bookHandle, 'Vertices');
                currentCenter = mean(finalVerts, 1);
                targetCenter = bookData.targetPos;
                horizontalError = [targetCenter(1)-currentCenter(1), targetCenter(2)-currentCenter(2), 0];
                if norm(horizontalError(1:2)) > 0.001
                    fprintf('  Horizontal adjustment only: [%.3f, %.3f, 0.000]\n', ...
                        horizontalError(1), horizontalError(2));
                    set(bookHandle, 'Vertices', finalVerts + horizontalError);
                end
            end

            success = true;
        end

        function moveToHomePosition(robot, homeQ, safetyController)
            fprintf('  Moving to home position\n');

            qCurrent = robot.model.getpos();

            if max(abs(qCurrent - homeQ)) < 0.01
                fprintf('  Already at home position\n');
                return;
            end

            if nargin < 3
                safetyController = [];
            end

            steps = 25;
            qTraj = jtraj(qCurrent, homeQ, steps);

            for i = 1:steps
                qStep = qTraj(i, :);
                if ~isempty(safetyController)
                    if ~safetyController.ensureMotionPermitted(robot, qStep)
                        return;
                    end
                end
                robot.model.animate(qStep);

                if ~isempty(safetyController)
                    safetyController.notifyRobotPose(robot, qStep);
                end

                drawnow('limitrate');
                pause(0.01);
            end

            fprintf('  Reached home position\n');
        end
    end
end
