function [roadPoints, forwardPaths, reversePaths, inPoint, facing] = createClothoid(roadPoints, inPoint, facing, length, lanes, bidirectional, midTurnLane, startCurvature, endCurvature)
%CREATECLOTHOID Creates a clothoid line given a starting point, start and
%end curvature, and a facing direction. Returns points for driving paths as
%well

% check if curvature is changing signs, negative to positive or positive to
% negative
% also check to see if they are the same, in which case, an arc will be
% made instead
if (startCurvature < 0 && endCurvature > 0) || (startCurvature > 0 && endCurvature < 0)
    [roadPoints, fwPaths1, rvPaths1, inPoint, facing] = createClothoid(roadPoints, inPoint, facing, length/2, lanes, bidirectional, midTurnLane, startCurvature, 0);
    [roadPoints, fwPaths2, rvPaths2, inPoint, facing] = createClothoid(roadPoints, inPoint, facing, length/2, lanes, bidirectional, midTurnLane, 0, endCurvature);
    forwardPaths = [fwPaths1 fwPaths2];
    reversePaths = [rvPaths2 rvPaths1];
    return;
elseif startCurvature == endCurvature
    [roadPoints, forwardPaths, reversePaths, inPoint, facing] = createArc(roadPoints, inPoint, facing, length, startCurvature, lanes, bidirectional, midTurnLane);
    return;
end

% get global lane width
global LANE_WIDTH;

% flip correction for when a left turning road has its points
% flipped, used only for paths on road
fc = (endCurvature < 0);

% how many points make up the clothoid, including the starting point
N = 5;

% rate of change of curvature, is the constant used to determine the
% clothoid, as it remains at the same rate throughout the curve
d_k = abs(endCurvature - startCurvature) / length;

% starting length
length_start = min(abs(startCurvature), abs(endCurvature)) / d_k;

% length increments
length_iter = length / (N-1);

% set up empty matrices for paths
forwardPaths = zeros(lanes, N*3);
if bidirectional
    reversePaths = zeros(lanes, N*3);
else
    reversePaths = 0;
end

% set up empty matrix for points
clothoidPoints = zeros(N, 3);

% if either point is zero, can't use equation, so must calculate 0 points
% separately
if length_start == 0
    clothoidPoints(1,:) = [0 0 0];
    if bidirectional
        for j=1:lanes
            startPoint = [-(fc*2-1)*(LANE_WIDTH * (1/2 + midTurnLane/2 + (j-1))) 0 0];
            forwardPaths(j,1:3) = startPoint;

            startPoint = [(fc*2-1)*(LANE_WIDTH * (1/2 + midTurnLane/2 + (j-1))) 0 0];
            reversePaths(j,3*N-2:3*N) = startPoint;
        end
    else
        for j=1:lanes
            startPoint = [(LANE_WIDTH * (1/2 + (j-1) - lanes/2)) 0 0];
            forwardPaths(j,1:3) = startPoint;
        end
    end
    
    % skipping first point since we don't need to calculate 0
    p_start = 2;
else
    % calculate every point
    p_start = 1;
end

%% clothoid points calculator

for i=p_start:N
    
    % curvature
    k_c = min(abs(startCurvature),abs(endCurvature)) + (i - 1) * length_iter * d_k;
    
    % End arc radius
    R_c = 1 / k_c;
    
    % End length
    s_c = length_start + (i - 1) * length_iter;
    
    % scaling factor
    a = sqrt(2 * R_c * s_c);
    
    % get point on clothoid 
    x = a * fresnels(s_c/a);
    y = a * fresnelc(s_c/a);
    
    clothoidPoints(i,:) = [x y 0];
    
    % change in facing tangent
    theta = (s_c/a)^2;
    
    % set up lane paths up to this point & establish reverse paths 
    if bidirectional
        for j=1:lanes
            lanePoint = [x y 0] + [cos(fc * pi -theta)*(LANE_WIDTH * (1/2 + midTurnLane/2 + (j-1))) sin(fc * pi -theta)*(LANE_WIDTH * (1/2 + midTurnLane/2 + (j-1))) 0];
            forwardPaths(j,3*i-2:3*i) = lanePoint;

            lanePoint = [x y 0] + [cos(fc * pi +pi-theta)*(LANE_WIDTH * (1/2 + midTurnLane/2 + (j-1))) sin(fc * pi +pi-theta)*(LANE_WIDTH * (1/2 + midTurnLane/2 + (j-1))) 0];
            reversePaths(j,3*(N-i)+1:3*(N-i+1)) = lanePoint;
        end
    else
        for j=1:lanes
            lanePoint = [x y 0] + [cos(fc * pi -theta)*(LANE_WIDTH * (1/2 + (j-1) - lanes/2)) sin(fc * pi -theta)*(LANE_WIDTH * (1/2 + (j-1) - lanes/2)) 0];
            forwardPaths(j,3*i-2:3*i) = lanePoint;
        end
    end
    
end

%% Adjust points back to zero if not starting at zero
if length_start ~= 0
    for i=1:N
        clothoidPoints(i,:) = clothoidPoints(i,:) - clothoidPoints(1,:);
        for j=1:lanes
            forwardPaths(j,3*i-2:3*i) =  forwardPaths(j,3*i-2:3*i) - clothoidPoints(1,:);
            if bidirectional
                reversePaths(j,3*i-2:3*i) = reversePaths(j,3*i-2:3*i) - clothoidPoints(1,:);
            end
        end
    end
end

%% Adjust points for a decreasing curvature
% have to flip over the x axis, shift back to 0 using the last point, and
% rotate 90 degrees clockwise
if abs(startCurvature) > abs(endCurvature)
    
    R = [cos(pi/2) -sin(pi/2); sin(pi/2) cos(pi/2)];
    clothoidPoints(:,2) = -clothoidPoints(:,2);
    clothoidPoints(:,1:2) = [(clothoidPoints(:,1)-clothoidPoints(N,1)) (clothoidPoints(:,2)-clothoidPoints(N,2))];
    for i=1:N
        clothoidPoints(i,1:2) = [clothoidPoints(i,1) clothoidPoints(i,2)]*R;
    end
    % flip all the coordinates, since they are all now reversed
    clothoidPoints = flipud(clothoidPoints);

    tempFwd = zeros(lanes,N*3);
    tempRv = zeros(lanes,N*3);
    for k=1:3:3*N
        tempFwd(:,k:k+2) = forwardPaths(:,3*N-k-1:3*N-k+1);
        if bidirectional
            tempRv(:,k:k+2) = reversePaths(:,3*N-k-1:3*N-k+1);
        end
    end
    forwardPaths = tempFwd;
    if bidirectional
        reversePaths = tempRv;
    end
end

%% adjust points for negative direction, flip over y axis
if startCurvature < 0 || endCurvature < 0
    theta = -1 * theta;
    clothoidPoints(:,1) = -clothoidPoints(:,1);
    forwardPaths(:,1:3:3*N) = -forwardPaths(:,1:3:3*N);
    reversePaths(:,1:3:3*N) = -reversePaths(:,1:3:3*N);
end

%% Rotate points to facing and adjust to inPoint
% Rotate path points and road points to orient to facing
% Flip over y axis if necessary (negative curvature)
% Add inPoint to place it in the correct location
R = [cos(facing - pi/2) sin(facing - pi/2); -sin(facing - pi/2) cos(facing - pi/2)];
disp("Facing (clothoid) : " + facing);
for i=1:N
	clothoidPoints(i,:) = [[clothoidPoints(i,1) clothoidPoints(i,2)]*R clothoidPoints(i,3)] + inPoint;
end

for i=1:lanes
    for n=1:3:3*N
        forwardPaths(i,n:n+2) = [[forwardPaths(i,n) forwardPaths(i,n+1)]*R forwardPaths(i,n+2)] + inPoint;
        if bidirectional
            reversePaths(i,n:n+2) = [[reversePaths(i,n) reversePaths(i,n+1)]*R reversePaths(i,n+2)] + inPoint;
        end
    end
end

% for i=1:lanes
%     for n=1:3:size(forwardPaths,2)
%         if bidirectional
%             reversePaths(i,n:n+2) = [[-reversePaths(i,n) reversePaths(i,n+1)]*R reversePaths(i,n+2)] + inPoint;
%             forwardPaths(i,n:n+2) = [[-forwardPaths(i,n) forwardPaths(i,n+1)]*R forwardPaths(i,n+2)] + inPoint;
%         else
%             if n <= 4
%                 % don't flip first two points, for some reason get flipped
%                 % twice (one-way road)
%                 forwardPaths(i,n:n+2) = [ [forwardPaths(i,n) forwardPaths(i,n+1)]*R forwardPaths(i,n+2)] + inPoint;
%             else
%                 forwardPaths(i,n:n+2) = [ [-forwardPaths(i,n) forwardPaths(i,n+1)]*R forwardPaths(i,n+2)] + inPoint;
%             end
%         end
%     end
% end

%% update values

% update inPoint
inPoint = clothoidPoints(N,:);

% update facing
facing = mod(facing - theta, 2*pi);

disp("Clothoid Stats");
disp("Curvatures: " + startCurvature + " to " + endCurvature);
disp("inPoint:");
disp(inPoint);
disp("Updated Facing: " + facing);
disp("Points:");
disp(clothoidPoints);
disp("------------------");

%update road points with new curve points
roadPoints = [roadPoints; clothoidPoints];

end

