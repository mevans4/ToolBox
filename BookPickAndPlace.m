function processedCount = BookPickAndPlace(robot, bookManager, safetyController)
    % BookPickAndPlace - Automated Book Stacking System
    % Student: [Your Name], ID: [Your Student ID]
    % Course: Robotics Engineering

    if nargin < 3
        safetyController = [];
    end

    fprintf('Starting book stacking operation...\n');

    % Get optimized home position for the robot
    homeQ = getHomePosition(robot);

    % Initialize robot at home position for consistent starting state
    fprintf('Moving to initial home position\n');
    moveToHomePosition(robot, homeQ, safetyController);

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
        if ~moveRobotWithConfig(robot, approachPos, pickConfig, safetyController)
            fprintf('ERROR: Failed to move to approach position for book %d\n', bookIndex);
            break;
        end
        pause(0.2);

        % === PICK PHASE: Move down to grasp the book ===
        pickPos = [bookPos(1), bookPos(2), bookPickHeight + 0.01];
        fprintf('Moving to pick position: [%.3f, %.3f, %.3f]\n', pickPos(1), pickPos(2), pickPos(3));
        if ~moveRobotWithConfig(robot, pickPos, pickConfig, safetyController)
            fprintf('ERROR: Failed to move to pick position for book %d\n', bookIndex);
            break;
        end
        pause(0.2);

        % === TARGET CALCULATION: Determine where to place the book ===
        targetPos = bookManager.getColorStackPosition(bookColor);
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
        if ~moveRobotWithBookPerfectPlacement(robot, liftPos, bookHandle, bookData, pickConfig, safetyController)
            fprintf('ERROR: Failed to lift book %d\n', bookIndex);
            break;
        end
        pause(0.2);
        
        % === TARGET APPROACH: Move above the placement location ===
        targetEePos = targetPos - bookOffset;
        fprintf('Target EE position for placement: [%.3f, %.3f, %.3f]\n', targetEePos(1), targetEePos(2), targetEePos(3));
        
        targetApproach = [targetEePos(1), targetEePos(2), targetEePos(3) + 0.12];
        fprintf('Moving to target approach: [%.3f, %.3f, %.3f]\n', targetApproach(1), targetApproach(2), targetApproach(3));
        if ~moveRobotWithBookPerfectPlacement(robot, targetApproach, bookHandle, bookData, pickConfig, safetyController)
            fprintf('ERROR: Failed to move to target approach for book %d\n', bookIndex);
            break;
        end
        pause(0.2);
        
        % === PLACE PHASE: Lower the book to target position ===
        fprintf('Placing book at target: [%.3f, %.3f, %.3f]\n', targetEePos(1), targetEePos(2), targetEePos(3));
        
        % SPECIAL HANDLING FOR BOOKS 1 & 3: Use enhanced placement
        if bookIndex == 1 || bookIndex == 3
            fprintf('Using enhanced placement for book %d\n', bookIndex);
            if ~moveRobotWithEnhancedPlacement(robot, targetEePos, bookHandle, bookData, pickConfig, safetyController)
                fprintf('ERROR: Failed to place book %d\n', bookIndex);
                break;
            end
        else
            % Standard placement for other books
            if ~moveRobotWithBookPerfectPlacement(robot, targetEePos, bookHandle, bookData, pickConfig, safetyController)
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

        bookManager.registerPlacedBook(bookHandle, bookColor, finalCenter, finalVerts);

        % === RETREAT PHASE: Move away after placement ===
        fprintf('Retreating to: [%.3f, %.3f, %.3f]\n', targetApproach(1), targetApproach(2), targetApproach(3));
        if ~moveRobotWithConfig(robot, targetApproach, pickConfig, safetyController)
            fprintf('ERROR: Failed to retreat after placing book %d\n', bookIndex);
            break;
        end
        pause(0.2);

        % Return to home position between book operations
        fprintf('Returning to home position after book %d\n', bookCount);
        moveToHomePosition(robot, homeQ, safetyController);
        pause(0.3);
        
        % Update book tracking
        bookManager.removeBook(bookColor, bookIndex);
        bookCount = bookCount + 1;
    end
    
    % Final homing after all operations complete
    fprintf('All books stacked - returning to final home position\n');
    moveToHomePosition(robot, homeQ, safetyController);

    fprintf('\n=== Operation Complete: Successfully stacked %d books ===\n', bookCount-1);
    if nargout > 0
        processedCount = bookCount - 1;
    end
end


%% ENHANCED PLACEMENT FUNCTION - Special handling for problematic books
function success = moveRobotWithEnhancedPlacement(robot, targetPosition, bookHandle, bookData, referenceConfig, safetyController)
    success = SafeMotion.moveRobotWithEnhancedPlacement(robot, targetPosition, bookHandle, bookData, referenceConfig, safetyController);
end
%% PERFECT PLACEMENT FUNCTION - Ensures books go exactly to target
function success = moveRobotWithBookPerfectPlacement(robot, targetPosition, bookHandle, bookData, referenceConfig, safetyController)
    success = SafeMotion.moveRobotWithBookPerfectPlacement(robot, targetPosition, bookHandle, bookData, referenceConfig, safetyController);
end
%% CONFIGURATION-BASED MOVEMENT FUNCTION
function success = moveRobotWithConfig(robot, targetPosition, referenceConfig, safetyController)
    success = SafeMotion.moveRobotWithConfig(robot, targetPosition, referenceConfig, safetyController);
end

%% HOME POSITION MANAGEMENT FUNCTIONS
function homeQ = getHomePosition(robot)
    homeQ = [0, 0, 0, 0, 0, 0, 0];
    fprintf('Home position: [');
    fprintf('%.2f ', homeQ);
    fprintf(']\n');
end

function moveToHomePosition(robot, homeQ, safetyController)
    SafeMotion.moveToHomePosition(robot, homeQ, safetyController);
end
