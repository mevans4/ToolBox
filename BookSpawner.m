classdef BookSpawner
    %BOOKSPAWNER Places books and exposes configurable layout metadata.

    methods (Static)
        function spawnBooks()
            %SPAWNBOOKS Place all books according to the configured layout.
            layout = BookSpawner.getInitialBookLayout();
            if isempty(layout)
                warning('BookSpawner:NoBooksConfigured', 'No initial books configured for spawning.');
                return;
            end

            for idx = 1:numel(layout)
                entry = layout(idx);

                if ~isfield(entry, 'position') || isempty(entry.position)
                    warning('BookSpawner:MissingPosition', 'Book entry %d is missing a position.', idx);
                    continue;
                end

                colorName = BookSpawner.normaliseColorName(entry);
                colorDef = BookSpawner.getColorDefinition(colorName);

                sourceFile = colorDef.sourceFile;
                if isfield(entry, 'sourceFile') && ~isempty(entry.sourceFile)
                    sourceFile = entry.sourceFile;
                end

                bookHandle = PlaceObject(sourceFile, entry.position);
                set(bookHandle, 'FaceColor', colorDef.faceColor);
                set(bookHandle, 'EdgeColor', 'none');

                userData = struct('sourceFile', sourceFile, 'colorName', colorName);
                if isfield(entry, 'userData') && isstruct(entry.userData)
                    userData = BookSpawner.mergeStructs(userData, entry.userData);
                end
                set(bookHandle, 'UserData', userData);

                BookSpawner.applyOptionalTransform(bookHandle, entry);
            end
        end

        function drawBookStartMarkers()
            %DRAWBOOKSTARTMARKERS Visualise the configured start zones.
            layout = BookSpawner.getInitialBookLayout();
            if isempty(layout)
                return;
            end

            markerSize = 0.3;
            seen = containers.Map('KeyType', 'char', 'ValueType', 'logical');

            for idx = 1:numel(layout)
                entry = layout(idx);
                if ~isfield(entry, 'position') || numel(entry.position) < 2
                    continue;
                end

                pos = entry.position(1:2);
                key = sprintf('%.4f_%.4f', pos(1), pos(2));
                if isKey(seen, key)
                    continue;
                end
                seen(key) = true;

                colorName = BookSpawner.normaliseColorName(entry);
                colorDef = BookSpawner.getColorDefinition(colorName);

                rectangle('Position', [pos(1) - markerSize/2, pos(2) - markerSize/2, markerSize, markerSize], ...
                    'FaceColor', colorDef.markerFaceColor, ...
                    'EdgeColor', colorDef.faceColor, ...
                    'LineWidth', 2, ...
                    'Curvature', [0.15, 0.15], ...
                    'FaceAlpha', 0.18);
            end
        end

        function layout = getInitialBookLayout()
            %GETINITIALBOOKLAYOUT Configure the initial pile of books.
            %   Modify this layout to reposition the starting stack without
            %   changing the rest of the codebase.

            layout = [ ...
                struct('color', 'green', 'position', [-1.75, 0.20, 0.079 * 0]);
                struct('color', 'green', 'position', [-1.75, -0.20, 0.079 * 0]);
                struct('color', 'blue',  'position', [-1.75, 0.20, 0.079 * 1]);
                struct('color', 'blue',  'position', [-1.75, -0.20, 0.079 * 1]);
                struct('color', 'red',   'position', [-1.75, 0.20, 0.079 * 2]);
                struct('color', 'red',   'position', [-1.75, -0.20, 0.079 * 2]) ...
                ];
        end

        function layout = getColorStackLayout()
            %GETCOLORSTACKLAYOUT Centres for the UR3 colour stacks.
            defaultHeight = 0.079 - 0.05;
            layout = [ ...
                struct('color', 'green', 'position', [0.45, -0.525, defaultHeight]);
                struct('color', 'blue',  'position', [0.15, -0.525, defaultHeight]);
                struct('color', 'red',   'position', [-0.15, -0.525, defaultHeight]) ...
                ];
        end

        function layout = getDeliveryZoneLayout()
            %GETDELIVERYZONELAYOUT Delivery zones for the colour robots.
            defaultHeight = 0.079 - 0.05;
            layout = [ ...
                struct('robot', 'Motoman', 'position', [0.85, 1.05, defaultHeight]);
                struct('robot', 'Kuka',    'position', [-0.85, -1.05, defaultHeight]);
                struct('robot', 'Aubo',    'position', [1.35, -0.25, defaultHeight]) ...
                ];
        end
    end

    methods (Static, Access = private)
        function colorName = normaliseColorName(entry)
            if isstruct(entry) && isfield(entry, 'color') && ~isempty(entry.color)
                colorName = lower(char(entry.color));
            else
                colorName = 'unknown';
            end
        end

        function colorDef = getColorDefinition(colorName)
            switch lower(colorName)
                case 'green'
                    faceColor = [0.0, 1.0, 0.0];
                    markerFaceColor = [0.6, 1.0, 0.6];
                    sourceFile = fullfile('Environment', 'greenBook.ply');
                case 'blue'
                    faceColor = [0.0, 0.0, 1.0];
                    markerFaceColor = [0.6, 0.7, 1.0];
                    sourceFile = fullfile('Environment', 'blueBook.ply');
                case 'red'
                    faceColor = [1.0, 0.0, 0.0];
                    markerFaceColor = [1.0, 0.7, 0.7];
                    sourceFile = fullfile('Environment', 'redBook.ply');
                otherwise
                    faceColor = [0.8, 0.8, 0.8];
                    markerFaceColor = [0.9, 0.9, 0.9];
                    sourceFile = fullfile('Environment', 'book3.ply');
            end

            colorDef = struct();
            colorDef.faceColor = faceColor;
            colorDef.markerFaceColor = markerFaceColor;
            colorDef.sourceFile = sourceFile;
        end

        function applyOptionalTransform(handle, entry)
            if ~ishandle(handle)
                return;
            end

            vertices = get(handle, 'Vertices');
            if isempty(vertices)
                return;
            end

            if isfield(entry, 'rotationMatrix') && ~isempty(entry.rotationMatrix)
                rot = entry.rotationMatrix;
                if ~all(size(rot) == [3, 3])
                    return;
                end
            elseif isfield(entry, 'orientation') && numel(entry.orientation) >= 3
                rpy = entry.orientation(:)';
                rot = trotz(rpy(3)) * troty(rpy(2)) * trotx(rpy(1));
            else
                return;
            end

            center = mean(vertices, 1);
            rotated = (rot * (vertices - center)')';
            set(handle, 'Vertices', rotated + center);
        end

        function result = mergeStructs(baseStruct, overrideStruct)
            result = baseStruct;
            fields = fieldnames(overrideStruct);
            for i = 1:numel(fields)
                field = fields{i};
                result.(field) = overrideStruct.(field);
            end
        end
    end
end

