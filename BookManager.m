classdef BookManager < handle
    %BOOKMANAGER Manage book mesh handles and poses for robot hand-offs.
    %   The manager keeps track of the mesh data and graphics handles for
    %   each book in the scene so their poses can be updated consistently as
    %   robots pick up and pass the books along a line.

    properties (Access = private)
        bookConfigs struct            % Struct array describing each book
        meshCache   struct            % Cached mesh data (faces/vertices/colours)
        bookHandles (:,1) gobjects    % Graphics handles for the plotted books
    end

    methods
        function self = BookManager(bookConfigs)
            arguments
                bookConfigs (1,:) struct
            end

            self.bookConfigs = bookConfigs;
            self.meshCache   = repmat(struct('faces',[], 'vertices',[], 'vertexColours',[]), size(bookConfigs));
            self.bookHandles = gobjects(numel(bookConfigs), 1);
        end

        function reset(self)
            %RESET Remove existing book graphics and cached handles.
            for h = self.bookHandles(:)'
                if isgraphics(h)
                    delete(h);
                end
            end
            self.bookHandles = gobjects(size(self.bookHandles));
        end

        function spawnBooks(self)
            %SPAWNBOOKS Plot every configured book at its starting pose.
            for idx = 1:numel(self.bookConfigs)
                config = self.bookConfigs(idx);

                meshData = self.loadMesh(config.mesh);
                self.meshCache(idx) = meshData;

                handle = self.createPatch(meshData, config.startPose, config.label);
                self.bookHandles(idx) = handle;
            end
        end

        function handles = getBookHandles(self)
            handles = self.bookHandles;
        end

        function count = getBookCount(self)
            count = numel(self.bookConfigs);
        end

        function configs = getBookConfigs(self)
            configs = self.bookConfigs;
        end

        function meshData = getMesh(self, idx)
            meshData = self.meshCache(idx);
        end

        function handle = getBookHandle(self, idx)
            handle = self.bookHandles(idx);
        end

        function storeBookHandles(self, handles)
            %STOREBOOKHANDLES Normalise and store references to book meshes.
            if nargin < 2 || isempty(handles)
                handles = self.bookHandles(isgraphics(self.bookHandles));
            end

            matched = self.matchBooksToPositions(handles);
            if numel(matched) ~= numel(self.bookHandles)
                self.bookHandles = gobjects(size(self.bookHandles));
                self.bookHandles(1:numel(matched)) = matched(:);
            else
                self.bookHandles = matched(:);
            end
        end

        function matched = matchBooksToPositions(self, actualBooks)
            %MATCHBOOKSTOPOSITIONS Align book handles with the configured order.
            if isempty(actualBooks)
                matched = gobjects(0,1);
                return;
            end

            if ~iscell(actualBooks)
                actualBooks = num2cell(actualBooks);
            end

            labelMap = containers.Map('KeyType','char','ValueType','any');
            for idx = 1:numel(actualBooks)
                h = actualBooks{idx};
                if ~isgraphics(h)
                    continue;
                end

                data = get(h,'UserData');
                if isstruct(data) && isfield(data,'bookLabel')
                    label = data.bookLabel;
                elseif isprop(h,'DisplayName')
                    label = get(h,'DisplayName');
                else
                    label = sprintf('Book%d', idx);
                end
                labelMap(label) = h;
            end

            matched = gobjects(numel(self.bookConfigs), 1);
            for idx = 1:numel(self.bookConfigs)
                label = self.bookConfigs(idx).label;
                if isKey(labelMap, label)
                    matched(idx) = labelMap(label);
                else
                    error('BookManager:MissingBookHandle', ...
                        'No graphics handle found for "%s".', label);
                end
            end
        end

        function updateBookPose(self, handle, meshData, pose)
            transformed = self.applyTransform(meshData.vertices, pose);
            set(handle, 'Vertices', transformed);
        end
    end

    methods (Access = private)
        function meshData = loadMesh(~, filename)
            [faces, vertices, plyData] = plyread(filename, 'tri');
            try
                vertexColours = [plyData.vertex.red, plyData.vertex.green, plyData.vertex.blue] / 255;
            catch
                vertexColours = repmat([0.5, 0.5, 0.5], size(vertices,1), 1);
            end

            meshData.faces = faces;
            meshData.vertices = vertices;
            meshData.vertexColours = vertexColours;
        end

        function handle = createPatch(~, meshData, pose, label)
            transformed = BookManager.applyTransformStatic(meshData.vertices, pose);
            handle = trisurf(meshData.faces, transformed(:,1), transformed(:,2), transformed(:,3), ...
                'FaceVertexCData', meshData.vertexColours, 'EdgeColor','none', ...
                'FaceLighting','gouraud', 'Tag', 'BookMesh', ...
                'UserData', struct('bookLabel', label), 'DisplayName', label);
        end

        function transformed = applyTransform(~, vertices, pose)
            transformed = BookManager.applyTransformStatic(vertices, pose);
        end
    end

    methods (Static, Access = private)
        function transformed = applyTransformStatic(vertices, pose)
            T = BookManager.poseToMatrix(pose);
            pts = [vertices, ones(size(vertices,1),1)] * T';
            transformed = pts(:,1:3);
        end

        function T = poseToMatrix(pose)
            if isa(pose, 'RTBPose')
                T = pose.T;
            elseif isa(pose, 'SE3')
                T = pose.T;
            elseif isnumeric(pose)
                T = pose;
            else
                error('BookManager:UnsupportedPose', ...
                    'Unsupported pose type: %s', class(pose));
            end
        end
    end
end
