function [ac, newPath, newSpeeds] = createPedestrian(drScn, pieces, pathType, speed, dimensions, position, posIndex)
%CREATEPEDESTRIAN Create pedestrian function

%Get dimensions
vLen = (dimensions(1) + 20) / 30;
vWdth = (dimensions(2) + 20) / 30;
vHght = (dimensions(3) + 20) / 30;

ac = actor(drScn, 'Length', 0.2 * vLen, 'Width', 0.2 * vWdth, 'Height', 1.75 * vHght, 'Position', position);

% create path for new actor
newPath = [];
newSpeeds = [];

% determine starting position to the right of the road
if posIndex
switch(pieces(posIndex).type)
 
    % Multilane Road
    case 1

        curv = pieces(posIndex).curvature;
        if curv ~= 0
            
            % Curved Road
            
            startPoint = pieces(posIndex).roadPoints(2,:);
            % End Curvature
            k_c = abs(pieces(posIndex).curvature) / 2;

            % End circular arc (Radius) - 1 / curvature
            R_c = 1 / k_c;

            % Arc length or length of road
            s_c = pieces(posIndex).length / 2;

            % a - scaling ratio to improve robustness while maintaining geometric
            % equivalence to Euler curve
            a = sqrt(2 * R_c * s_c);

            % theta - radians by which the line turned
            theta = (s_c/a)^2;

            if pieces(posIndex).curvature < 0
                roadFacing = pieces(posIndex).facing - theta/2;
            else
                roadFacing = pieces(posIndex).facing + theta/2;
            end

            % set up mid-point at half the road length
            x2 = a * fresnels(s_c/a);
            y2 = a * fresnelc(s_c/a);
        else
            
            % Straight road
            
            facingDir = pieces(posIndex).facing;
            
            midPoint = pieces(posIndex).roadPoints(1,:) + (pieces(posIndex).length/2) * [cos(facingDir) sin(facingDir) 0];
            
            startPoint = midPoint + pieces(posIndex).width/2 * [cos(facingDir - pi/2) sin(facingDir - pi/2) 0];
            
            endPoint = midPoint + pieces(posIndex).width * [cos(facingDir + pi/2) sin(facingDir + pi/2) 0];
            
        end
                
end % end switch - road type

% base path on path type
switch(pathType)
    
    %
    % Normal Path
    %
    % - will cross the road
    
    case 1
        
                
        
        
end % end switch

end % end function
