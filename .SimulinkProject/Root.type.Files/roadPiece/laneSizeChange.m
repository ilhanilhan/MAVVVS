function [inPoint, facing, pieces] = laneSizeChange(drScn, inPoint, facing, newWidth, pieces, dirVec, lanes, bidirectional, midTurnLane, sLimit, rSlick)
    %LANESIZECHANGE
    %   Creates the transition piece between two road pieces to account for
    %   difference in number of lanes or size
    
    oldPoint = inPoint;

    rWidth = pieces(length(pieces)).width;

    change = newWidth - rWidth;

    % How many pieces the transition will take place over
    numPieces = 8;
    
    % Total length of transition piece
    transitionSize = 10;
    
    % Lane Markings
    lm = [laneMarking('Solid','Color','w'); ...
        laneMarking('DoubleSolid','Color','y'); ...
        laneMarking('Solid','Color','w')];
    
    % Calculate Transition pieces and place on road
    for i = 1:numPieces
        rWidth = rWidth + change/numPieces;
        newPoint = oldPoint + transitionSize*dirVec/numPieces;
        
        % Lane Specifications
        ls = lanespec(2,'Width',rWidth/2,'Marking',lm);
        
        road(drScn, [oldPoint; newPoint], 'Lanes', ls);
        oldPoint = newPoint;
    end
    
    % set up bounding box
    if facing >= 0 && facing < pi/2
        botLeftCorner = inPoint + [-cos(facing+pi/2)*newWidth/2 -sin(facing-pi/2)*newWidth/2 0];
        topRightCorner = inPoint + transitionSize*dirVec + [cos(facing-pi/2)*newWidth/2 sin(facing+pi/2)*newWidth/2 0];
    elseif facing >= pi/2 && facing < pi
        botLeftCorner = inPoint + [-cos(facing-pi/2)*newWidth/2 -sin(facing+pi/2)*newWidth/2 0];
        topRightCorner = inPoint + transitionSize*dirVec + [cos(facing+pi/2)*newWidth/2 sin(facing-pi/2)*newWidth/2 0];
    elseif facing >= pi && facing < 3*pi/2
        botLeftCorner = inPoint + transitionSize*dirVec + [-cos(facing-pi/2)*newWidth/2 -sin(facing+pi/2)*newWidth/2 0];
        topRightCorner = inPoint + [cos(facing+pi/2)*newWidth/2 sin(facing-pi/2)*newWidth/2 0];
    else
        botLeftCorner = inPoint + transitionSize*dirVec + [-cos(facing+pi/2)*newWidth/2 -sin(facing-pi/2)*newWidth/2 0];
        topRightCorner = inPoint + [cos(facing-pi/2)*newWidth/2 sin(facing+pi/2)*newWidth/2 0];
    end

    
    rPiece.type = 0;
    rPiece.roadPoints = [inPoint; newPoint];
    rPiece.range = [botLeftCorner; topRightCorner];
    rPiece.facing = facing;
    rPiece.length = 10;
    rPiece.curvature = 0;
    rPiece.midTurnLane = midTurnLane;
    rPiece.bidirectional = bidirectional;
    rPiece.lanes = lanes;
    rPiece.forwardDrivingPaths = 0;
    rPiece.reverseDrivingPaths = 0;
    rPiece.occupiedLanes = [0];
    rPiece.width = rWidth;
    rPiece.weather = 0;
    rPiece.roadConditions = 0;
    rPiece.speedLimit = sLimit;
    rPiece.slickness = rSlick;

    inPoint = newPoint;
    
    pieces = [pieces; rPiece];

end

