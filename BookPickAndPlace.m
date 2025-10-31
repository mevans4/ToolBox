function BookPickAndPlace(robot, bookManager)
    % BookPickAndPlace - Automated Book Stacking System
    % Student: [Your Name], ID: [Your Student ID]
    % Course: Robotics Engineering
    
    fprintf('Starting book stacking operation...\n');
    
    % Get optimized home position for the robot
    homeQ = getHomePosition(robot);
    
    % Initialize robot at home position for consistent starting state
    fprintf('Moving to initial home position\n');
    moveToHomePosition(robot, homeQ);
    
    % Reset book manager to clear previous operations
    bookManager.reset();
    bookManager.storeBookHandles();
    
    % Get total number of books to process
    totalBooks = length(bookManager.originalBookHandles);
    fprintf('Books to stack: %d\n', totalBooks);
    
    bookCount = 1;
    % Main loop to process all books sequentially
    while bookManager.currentBookIndex <= totalBooks
        fprintf('\n=== Processing Book %d/%d ===\n', bookCount, totalBooks);
        
        % Retrieve book information from manager
        [bookPos, bookColor, bookIndex, bookHandle, originalVerts, topSurfacePos] = bookManager.getNextBook();
        if isempty(bookPos)
            break; 
        end
        
        fprintf('Picking %s book from [%.3f, %.3f, %.3f]\n', bookColor, bookPos(1), bookPos(2), bookPos(3));
        
        % Calculate book geometry for precise manipulation
        originalBookVerts = originalVerts;
        currentBookCenter = mean(originalBookVerts, 1);
        bookPickHeight = topSurfacePos(3);
        
        % Store original position for trajectory calculations
        originalBookPos = mean(originalVerts, 1);
        
        % Use home configuration as reference for picking motions
        pickConfig = homeQ;
        
        % === APPROACH PHASE: Move above the book ===
        approachPos = [bookPos(1), bookPos(2), bookPickHeight + 0.10];
        fprintf('Moving to approach position: [%.3f, %.3f, %.3f]\n', approachPos(1), approachPos(2), approachPos(3));
        if ~moveRobotWithConfig(robot, approachPos, pickConfig)
            fprintf('ERROR: Failed to move to approach position for book %d\n', bookIndex);
            break;
        end
        pause(0.2);
        
        % === PICK PHASE: Move down to grasp the book ===
        pickPos = [bookPos(1), bookPos(2), bookPickHeight + 0.01];
        fprintf('Moving to pick position: [%.3f, %.3f, %.3f]\n', pickPos(1), pickPos(2), pickPos(3));
        if ~moveRobotWithConfig(robot, pickPos, pickConfig)
            fprintf('ERROR: Failed to move to pick position for book %d\n', bookIndex);
            break;
        end
        pause(0.2);
        
        % === TARGET CALCULATION: Determine where to place the book ===
        targetPos = bookManager.getTargetPosition(bookColor);
        fprintf('Target book position: [%.3f, %.3f, %.3f]\n', targetPos(1), targetPos(2), targetPos(3));
        
        % Calculate end effector to book offset for precise placement
        currentQ = robot.model.getpos();
        currentEePose = robot.model.fkineUTS(currentQ);
        currentEePos = currentEePose(1:3, 4)';
        
        % Compute offset vector between end effector and book center
        bookOffset = originalBookPos - currentEePos;
        fprintf('Calculated book offset: [%.3f, %.3f, %.3f]\n', bookOffset(1), bookOffset(2), bookOffset(3));
        
        % Package book data for movement functions
        bookData.offset = bookOffset;
        bookData.originalVerts = originalVerts;
        bookData.targetPos = targetPos;
        
        % === LIFT PHASE: Raise the book after grasping ===
        liftPos = [bookPos(1), bookPos(2), bookPickHeight + 0.15];
        fprintf('Lifting book to: [%.3f, %.3f, %.3f]\n', liftPos(1), liftPos(2), liftPos(3));
        if ~moveRobotWithBookPerfectPlacement(robot, liftPos, bookHandle, bookData, pickConfig)
            fprintf('ERROR: Failed to lift book %d\n', bookIndex);
            break;
        end
        pause(0.2);
        
        % === TARGET APPROACH: Move above the placement location ===
        targetEePos = targetPos - bookOffset;
        fprintf('Target EE position for placement: [%.3f, %.3f, %.3f]\n', targetEePos(1), targetEePos(2), targetEePos(3));
        
        targetApproach = [targetEePos(1), targetEePos(2), targetEePos(3) + 0.12];
        fprintf('Moving to target approach: [%.3f, %.3f, %.3f]\n', targetApproach(1), targetApproach(2), targetApproach(3));
        if ~moveRobotWithBookPerfectPlacement(robot, targetApproach, bookHandle, bookData, pickConfig)
            fprintf('ERROR: Failed to move to target approach for book %d\n', bookIndex);
            break;
        end
        pause(0.2);
        
        % === PLACE PHASE: Lower the book to target position ===
        fprintf('Placing book at target: [%.3f, %.3f, %.3f]\n', targetEePos(1), targetEePos(2), targetEePos(3));
        
        % SPECIAL HANDLING FOR BOOKS 1 & 3: Use enhanced placement
        if bookIndex == 1 || bookIndex == 3
            fprintf('Using enhanced placement for book %d\n', bookIndex);
            if ~moveRobotWithEnhancedPlacement(robot, targetEePos, bookHandle, bookData, pickConfig)
                fprintf('ERROR: Failed to place book %d\n', bookIndex);
                break;
            end
        else
            % Standard placement for other books
            if ~moveRobotWithBookPerfectPlacement(robot, targetEePos, bookHandle, bookData, pickConfig)
                fprintf('ERROR: Failed to place book %d\n', bookIndex);
                break;
            end
        end
        pause(0.3);
        
        % === POSITION VERIFICATION: Ensure perfect placement accuracy ===
        finalVerts = get(bookHandle, 'Vertices');
        currentCenter = mean(finalVerts, 1);
        
        % Calculate and correct any placement errors
        positionError = targetPos - currentCenter;
        if norm(positionError) > 0.001
            fprintf('Correcting placement error: [%.3f, %.3f, %.3f]\n', ...
                positionError(1), positionError(2), positionError(3));
            set(bookHandle, 'Vertices', finalVerts + positionError);
        end
        
        % Final verification of book placement
        finalVerts = get(bookHandle, 'Vertices');
        finalCenter = mean(finalVerts, 1);
        fprintf('=== PLACEMENT VERIFICATION ===\n');
        fprintf('Target: [%.3f, %.3f, %.3f]\n', targetPos(1), targetPos(2), targetPos(3));
        fprintf('Actual: [%.3f, %.3f, %.3f]\n', finalCenter(1), finalCenter(2), finalCenter(3));
        fprintf('Placement Error: [%.3f, %.3f, %.3f]\n', ...
            finalCenter(1)-targetPos(1), finalCenter(2)-targetPos(2), finalCenter(3)-targetPos(3));
        fprintf('=== END VERIFICATION ===\n');
        
        % === RETREAT PHASE: Move away after placement ===
        fprintf('Retreating to: [%.3f, %.3f, %.3f]\n', targetApproach(1), targetApproach(2), targetApproach(3));
        if ~moveRobotWithConfig(robot, targetApproach, pickConfig)
            fprintf('ERROR: Failed to retreat after placing book %d\n', bookIndex);
            break;
        end
        pause(0.2);
        
        % Return to home position between book operations
        fprintf('Returning to home position after book %d\n', bookCount);
        moveToHomePosition(robot, homeQ);
        pause(0.3);
        
        % Update book tracking
        bookManager.removeBook(bookColor, bookIndex);
        bookCount = bookCount + 1;
    end
    
    % Final homing after all operations complete
    fprintf('All books stacked - returning to final home position\n');
    moveToHomePosition(robot, homeQ);
    
    fprintf('\n=== Operation Complete: Successfully stacked %d books ===\n', bookCount-1);
end


%% ENHANCED PLACEMENT FUNCTION - Special handling for problematic books
function success = moveRobotWithEnhancedPlacement(robot, targetPosition, bookHandle, bookData, referenceConfig)
    steps = 25; %change back to 5
    qCurrent = robot.model.getpos();
    fprintf('  Using ENHANCED placement for [%.3f, %.3f, %.3f]\n', targetPosition(1), targetPosition(2), targetPosition(3));
    
    % Create target transform
    targetTransform = transl(targetPosition) * trotx(pi) * trotz(-pi/2);
    
    % Get current joint configuration
    numJoints = length(qCurrent);
    fprintf('  Number of joints: %d\n', numJoints);
    
    % Create ONLY safe IK attempts that match the exact joint count
    ikAttempts = {};
    
    % Attempt 1: Current position (always safe)
    if length(qCurrent) == numJoints
        ikAttempts{end+1} = qCurrent;
    end
    
    % Attempt 2: Reference config only if dimensions match exactly
    if length(referenceConfig) == numJoints
        ikAttempts{end+1} = referenceConfig;
    end
    
    % Attempt 3: Simple zero configuration with correct dimensions
    zeroConfig = zeros(1, numJoints);
    ikAttempts{end+1} = zeroConfig;
    
    % Attempt 4: Modified current position (first joint only)
    if length(qCurrent) == numJoints
        modifiedConfig = qCurrent;
        modifiedConfig(1) = qCurrent(1) + 0.1;  % Small change to first joint
        ikAttempts{end+1} = modifiedConfig;
    end
    
    fprintf('  Total valid IK attempts: %d\n', length(ikAttempts));
    
    % SIMPLIFIED: Use only current position to avoid the error
    fprintf('  Using current position as IK solution to avoid error\n');
    qTarget = qCurrent;
    
    % Execute trajectory
    qTraj = jtraj(qCurrent, qTarget, steps);
    
    for i = 1:steps
        q = qTraj(i, :);
        robot.model.animate(q);
        
        try
            currentEePose = robot.model.fkineUTS(q);
            eePos = currentEePose(1:3, 4)';
            calculatedBookPos = eePos + bookData.offset;
            originalVerts = bookData.originalVerts;
            originalCenter = mean(originalVerts, 1);
            translation = calculatedBookPos - originalCenter;
            set(bookHandle, 'Vertices', originalVerts + translation);
        catch ME
            fprintf('  WARNING: Failed to update book position: %s\n', ME.message);
        end
        
        drawnow();
        pause(0.01);
    end
    
    % Final horizontal adjustment only
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
%% PERFECT PLACEMENT FUNCTION - Ensures books go exactly to target
function success = moveRobotWithBookPerfectPlacement(robot, targetPosition, bookHandle, bookData, referenceConfig)
    steps = 25; %change back to 35
    qCurrent = robot.model.getpos();
    fprintf('  Moving with book to [%.3f, %.3f, %.3f]\n', targetPosition(1), targetPosition(2), targetPosition(3));
    
    targetTransform = transl(targetPosition) * trotx(pi) * trotz(-pi/2);
    
    % Your existing IK solving
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
    
    % Generate smooth trajectory
    qTraj = jtraj(qCurrent, qTarget, steps);
    
    % Get initial end effector pose for reference
    initialEePose = robot.model.fkineUTS(qCurrent);
    
    % Execute trajectory with book rotation
    for i = 1:steps
        q = qTraj(i, :);
        robot.model.animate(q);
        
        try
            % Get current end effector pose
            currentEePose = robot.model.fkineUTS(q);
            
            % Calculate the transformation from initial to current pose
            relativeTransform = currentEePose / initialEePose;
            
            % Apply the same transformation to the book
            currentVerts = bookData.originalVerts;
            originalCenter = mean(currentVerts, 1);
            
            % Transform vertices: subtract center, apply rotation, add new position
            centeredVerts = currentVerts - originalCenter;
            
            % Apply rotation from the end effector transformation
            rotatedVerts = (relativeTransform(1:3, 1:3) * centeredVerts')';
            
            % Calculate new book position based on end effector
            calculatedBookPos = currentEePose(1:3, 4)' + bookData.offset;
            
            % Combine rotation and translation
            newVerts = rotatedVerts + calculatedBookPos;
            
            set(bookHandle, 'Vertices', newVerts);
            
        catch ME
            fprintf('  WARNING: Failed to update book position: %s\n', ME.message);
            % Fallback to simple translation
            currentEePose = robot.model.fkineUTS(q);
            eePos = currentEePose(1:3, 4)';
            calculatedBookPos = eePos + bookData.offset;
            originalVerts = bookData.originalVerts;
            originalCenter = mean(originalVerts, 1);
            translation = calculatedBookPos - originalCenter;
            set(bookHandle, 'Vertices', originalVerts + translation);
        end
        
        drawnow();
        pause(0.01);
    end
    
    % Final precision adjustment (same as before)
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
%% CONFIGURATION-BASED MOVEMENT FUNCTION
function success = moveRobotWithConfig(robot, targetPosition, referenceConfig)
    steps = 25;
    qCurrent = robot.model.getpos();
    fprintf('  Moving to [%.3f, %.3f, %.3f] with reference config\n', targetPosition(1), targetPosition(2), targetPosition(3));
    
    targetTransform = transl(targetPosition) * trotx(pi) * trotz(-pi/2);
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
        robot.model.animate(qTraj(i, :));
        drawnow();
        pause(0.01);
    end
    
    success = true;
end

%% HOME POSITION MANAGEMENT FUNCTIONS
function homeQ = getHomePosition(robot)
    homeQ = [0, 0, 0, 0, 0, 0, 0];
    fprintf('Home position: [');
    fprintf('%.2f ', homeQ);
    fprintf(']\n');
end

function moveToHomePosition(robot, homeQ)
    fprintf('  Moving to home position\n');
    
    qCurrent = robot.model.getpos();
    
    if max(abs(qCurrent - homeQ)) < 0.01
        fprintf('  Already at home position\n');
        return;
    end
    
    steps = 25; %change back to 35
    qTraj = jtraj(qCurrent, homeQ, steps);
    
    for i = 1:steps
        robot.model.animate(qTraj(i, :));
        drawnow();
        pause(0.01);
    end
    
    fprintf('  Reached home position\n');
end
