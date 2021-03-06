function [facing, inPoint, pieces] = singlePedestrianCrosswalk(drScn, inPoint, facing, pieces, roadStruct)
%SINGLEPEDESTRIANCROSSWALK The single pedestrian crosswalk serves as a
% single road's crosswalk and allows for custom logic/pedestrian traffic/
% elevation for a speedbump/etc.

disp("Starting Pedestrian Crosswalk");
    
% set up variables from struct
roadType = str2double(roadStruct(1));
length = str2double(roadStruct(2));
lanes = str2double(roadStruct(3));
bidirectional = str2double(roadStruct(4));
speedLimit = str2double(roadStruct(6));
elevation = abs(str2double(roadStruct(8))); % Originally curvature=
pedPathWays = split(roadStruct(10), ':');
showMarkers = str2double(roadStruct(12));
% Fix road struct for later
roadStruct(5) = "0";

% Set up direction the road starts off going in by taking the 
% facing parameter in radians and creating a vector
dirVec = [cos(facing) sin(facing) 0];

% Get Global Variables
global LANE_WIDTH;
global TRANSITION_PIECE_LENGTH;
global fid; % test file
global MINUTE_LIMIT;
global PED_FACTOR;

% get original parameters stored
oldInPoint = inPoint;

% Shift inpoint forward to include transition piece
if size(pieces,1) >= 2
    inPoint = inPoint + (TRANSITION_PIECE_LENGTH * [cos(facing) sin(facing) 0]);
end

if bidirectional
    roadWidth = 2 * lanes * LANE_WIDTH;
else 
    roadWidth = lanes * LANE_WIDTH;
end

% set up empty matrix for road points
roadPoints = [inPoint;
              inPoint + 0.25 * dirVec;
              inPoint + (length+0.25) * dirVec;
              inPoint + (length+0.5) * dirVec];
roadPoints(2:3, 3) = elevation; % set speed bump elevation

% Set Up Paths
forwardPaths = zeros(lanes, 12);

if bidirectional
    reversePaths = zeros(lanes, 12);
    for i=1:lanes
        forwardPaths(i,:) = reshape((roadPoints + (LANE_WIDTH * (i - 1/2)) * [cos(facing-pi/2) sin(facing-pi/2) 0]).', [1,12]);
        reversePaths(i,:) = reshape((roadPoints + ( LANE_WIDTH * (i - 1/2) ) * [cos(facing+pi/2) sin(facing+pi/2) 0]).', [1,12]);
    end
else
    reversePaths = 0;
    for i=1:lanes
        forwardPaths(i,:) = reshape((roadPoints + (LANE_WIDTH * (i - (lanes+1)/2)) * [cos(facing-pi/2) sin(facing-pi/2) 0]).', [1,12]);
        % forwardPaths(i,:) = [startPoint + dirVec * 0.05, startPoint + 0.25 * length * dirVec, startPoint + 0.5 * length * dirVec, startPoint + 0.75 * length * dirVec, startPoint + 0.95 * length * dirVec];
    end
end

endPoint = roadPoints(4,:);

% Set up matrix to store corner points
corners = zeros(4,3);

% Set up corners to make boundaries
corners(1,:) = inPoint + roadWidth/2*[cos(facing+pi/2) sin(facing+pi/2) 0];
corners(2,:) = inPoint - roadWidth/2*[cos(facing+pi/2) sin(facing+pi/2) 0];
corners(3,:) = endPoint + roadWidth/2*[cos(facing+pi/2) sin(facing+pi/2) 0];
corners(4,:) = endPoint - roadWidth/2*[cos(facing+pi/2) sin(facing+pi/2) 0];

% Update inPoint
inPoint = endPoint;

% Creates a rectangle around the area occupied by the road piece
botLeftCorner = [min([corners(1,1) corners(2,1) corners(3,1) corners(4,1)])...
    min([corners(1,2) corners(2,2) corners(3,2) corners(4,2)])...
    0];
topRightCorner = [max([corners(1,1) corners(2,1) corners(3,1) corners(4,1)])...
    max([corners(1,2) corners(2,2) corners(3,2) corners(4,2)])...
    0];

% If conflicts with any other piece, will stop placing
if ~checkAvailability(pieces, botLeftCorner, topRightCorner, [oldInPoint(1:2);inPoint(1:2)], facing, length)
    disp("@ Multi Lane Road : Could Not Place Piece");
    inPoint = oldInPoint;
    try
        fprintf(fid, "%d,", roadType);
    catch
        disp("Error printing");
        fid = fopen("placedRoadNet.txt","a");
        fprintf(fid, "%d,", roadType);
    end
    return
end

% Plot Paths 
hold on;
plot(roadPoints(:,1),roadPoints(:,2));

% Transition the lane width from the previous piece to the current one
% creating a new middle piece in the shape of a trapezoid.
% Checks to see if this isn't the first piece placed
if size(pieces,1) >= 2
    [xinPoint, xfacing, pieces] = laneSizeChange(drScn, oldInPoint, facing, ...
        roadWidth, pieces, dirVec, roadStruct);
end


% Create Road Piece in Scenario
road(drScn, roadPoints, roadWidth);

% Add Pedestrians to Crosswalk
leftFreq = char(pedPathWays(1));
leftFreq = str2double(leftFreq(3)) * PED_FACTOR;
rightFreq = char(pedPathWays(2));
rightFreq = str2double(rightFreq(3)) * PED_FACTOR;

for i=1:MINUTE_LIMIT
    
    % Right to Left
    for j=1:leftFreq
        %Get dimensions
        pLen = (randi(10) + 40) / 45;
        pWdth = (randi(10) + 40) / 45;
        pHght = (randi(10) + 40) / 45;

        ac = actor(drScn, 'Length', 0.2 * pLen, 'Width', 0.2 * pWdth, 'Height', 1.75 * pHght);
        
        % Sets the time before ped. crosses
        pedStartSpeed = 1 / (60*(i-1) + randi(60)); % sets speed to start at random point during given minuteT
        pedCrossSpeed = (randi(10)/10) + 0.9; % Sets a random walking speed based on avg speed 1.4mps +- 0.5 mps
        
        pedStartPos = roadPoints(1,:) + (roadWidth/2 + 1) * [cos(facing-pi/2) sin(facing-pi/2) 0] + randi(100) * length/100 * dirVec;
        pedStartPos(3) = elevation;
        
        walkingDir = [cos(facing+pi/2) sin(facing+pi/2) 0];
        
        pedPath = [pedStartPos; ...
                    pedStartPos + walkingDir; ...
                    pedStartPos + (roadWidth+1) * walkingDir; ...
                    pedStartPos + (roadWidth+2) * walkingDir];
                
        trajectory(ac, pedPath, [pedStartSpeed pedStartSpeed pedCrossSpeed 0.00001]);
        
    end
    
    % Left to Right
    for j=1:rightFreq
        
        %Get dimensions
        pLen = (randi(10) + 40) / 45;
        pWdth = (randi(10) + 40) / 45;
        pHght = (randi(10) + 40) / 45;

        ac = actor(drScn, 'Length', 0.2 * pLen, 'Width', 0.2 * pWdth, 'Height', 1.75 * pHght);
        
        % Sets the time before ped. crosses
        pedStartSpeed = 10 * (1 / (60*(i-1) + randi(60))); % sets speed to start at random point during given minute
        pedCrossSpeed = (randi(10)/10) + 0.9; % Sets a random walking speed based on avg speed 1.4mps +- 0.5 mps
        
        pedStartPos = roadPoints(1,:) + (roadWidth/2 + 1) * [cos(facing+pi/2) sin(facing+pi/2) 0] + randi(100) * length/100 * dirVec;
        pedStartPos(3) = elevation;
        
        walkingDir = [cos(facing-pi/2) sin(facing-pi/2) 0];
        
        pedPath = [pedStartPos; ...
                    pedStartPos + walkingDir; ...
                    pedStartPos + (roadWidth+1) * walkingDir; ...
                    pedStartPos + [(roadWidth+2) * walkingDir(1:2) 1000]];
                
        trajectory(ac, pedPath, [pedStartSpeed pedStartSpeed pedCrossSpeed 0.01]);
    end
end


% Sets up parameters to pass into the road info array

rPiece.type = 1;
rPiece.lineType = 0;
rPiece.roadPoints = roadPoints;
rPiece.range = [botLeftCorner; topRightCorner];
rPiece.facing = facing;
rPiece.length = length;
rPiece.curvature1 = elevation;
rPiece.curvature2 = 0;
rPiece.midLane = 0;
rPiece.bidirectional = bidirectional;
rPiece.lanes = lanes;
rPiece.forwardDrivingPaths = forwardPaths;
rPiece.reverseDrivingPaths = reversePaths;
rPiece.occupiedLanes = zeros(1,lanes + bidirectional*lanes);
rPiece.width = roadWidth;
rPiece.weather = 0;
rPiece.roadConditions = 0;
rPiece.speedLimit = speedLimit;
rPiece.pedPathWays = pedPathWays;
rPiece.showMarkers = showMarkers;

pieces = [pieces; rPiece];

end