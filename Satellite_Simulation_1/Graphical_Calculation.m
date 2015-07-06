    %This program is meant to provide a graphical representation of what's
    %going on in the C++ flux calculator5. I'm using
    %this as a graphical representation of what's going on in the other
    %program.
function main
    clc;
    clear all;
    close all;
    EARTH_RADIUS=6371000;

    SUN_X=3.581118709561659*10^10;
    SUN_Y=-1.308927327368016*10^11;
    SUN_Z=-5.677199113568006*10^10;

    SAT_X=0;
    SAT_Y=0;
    SAT_Z=0;

    fileID = fopen('satPositionsTest.txt','r');
    imageNameCounter=1;
    tline = fgets(fileID);
    while ischar(tline)

        tline=strtrim(tline);
        %break up the line by spaces into an array...
        stringsArray = strsplit(tline,' ');

        cell1=stringsArray(1);
        SAT_X=str2num(cell1{1,1});

        cell2=stringsArray(2);
        SAT_Y=str2num(cell2{1,1});

        cell3=stringsArray(3);
        SAT_Z=str2num(cell3{1,1});

%         [SAT_X,SAT_Y,SAT_Z,SUN_X,SUN_Y,SUN_Z]=adjustSunAndSatPositions(SAT_X,SAT_Y,SAT_Z,SUN_X,SUN_Y,SUN_Z);
        
        scatter3(SAT_X,SAT_Y,SAT_Z,'cyan');
        hold on;
        
        DISTANCE_FROM_EARTH_CENTER_TO_SAT=(SAT_X^2+SAT_Y^2+SAT_Z^2)^.5;
        DISTANCE_FROM_EARTH_CENTER_TO_SUN=(SUN_X^2+SUN_Y^2+SUN_Z^2)^.5;

        MAX_SAT_ANGLE=acos(EARTH_RADIUS/DISTANCE_FROM_EARTH_CENTER_TO_SAT);
        MAX_SUN_ANGLE=acos(EARTH_RADIUS/DISTANCE_FROM_EARTH_CENTER_TO_SUN);

        MAX_DISTANCE_TO_SATELLITE=DISTANCE_FROM_EARTH_CENTER_TO_SAT*sin(MAX_SAT_ANGLE);
        MAX_DISTANCE_TO_SUN=DISTANCE_FROM_EARTH_CENTER_TO_SUN*sin(MAX_SUN_ANGLE);
        
        NUM_STEPS_BETA=20;
        NUM_STEPS_THETA=80;
        
        INTERVAL_BETA=MAX_SAT_ANGLE/NUM_STEPS_BETA;
        THETA_MAX=2*pi;
        INTERVAL_THETA=THETA_MAX/NUM_STEPS_THETA;
        
        for alpha=0:INTERVAL_BETA:pi %MAX_SAT_ANGLE
            for theta=0:INTERVAL_THETA:THETA_MAX
                x=EARTH_RADIUS*sin(alpha)*cos(theta);
                y=EARTH_RADIUS*sin(alpha)*sin(theta);
                z=EARTH_RADIUS*cos(alpha);

                ACTUAL_DISTANCE_TO_SATELLITE=((x-SAT_X)^2+(y-SAT_Y)^2+(z-SAT_Z)^2)^.5;
                ACTUAL_DISTANCE_TO_SUN=((x-SUN_X)^2+(y-SUN_Y)^2+(z-SUN_Z)^2)^.5;

                if ACTUAL_DISTANCE_TO_SATELLITE<MAX_DISTANCE_TO_SATELLITE && ACTUAL_DISTANCE_TO_SUN<MAX_DISTANCE_TO_SUN
                    %visible to both satellite and the sun.
                    scatter3(x,y,z,'red');
                    
                    %This is the case where we calculate flux...
                    %TODO UNCOMMENT THIS SECTION AND IMPLEMENT...
%                     double r = returnDistanceBetweenPoints(x, y, z, SAT_X, SAT_Y, SAT_Z);  //distance between area element and the satellite.
%     
%                     %We have been using the variable beta to denote the limits of our discretization.
%                     %Note that alpha is used the paper to describe the angle between the normal vector to the area element and the satellite vector. This is different than the beta we have been using an an for loop variable.
%                     %double alpha=returnAngleBetweenTwoVectors(x, y, z, SAT_X, SAT_Y, SAT_Z);
%     
%                     double areaEarthElement=pow(EARTH_RADIUS,2)*sin(theta)*theta_interval*beta_interval;
%     
%                     dflux=(albedo*E_s*cos(returnSunAngleForAreaElementAt(beta,theta))+e*M_b)*Ac/(M_PI*pow(r,2))*cos(alpha)* areaEarthElement;
                    
                    
                elseif ACTUAL_DISTANCE_TO_SATELLITE<MAX_DISTANCE_TO_SATELLITE %only visible to the satellite.
                    scatter3(x,y,z,'black');
                elseif ACTUAL_DISTANCE_TO_SUN<MAX_DISTANCE_TO_SUN % only visible to the sun.
                    scatter3(x,y,z,'yellow');
                else % not visible to the sun or the satellite
                    scatter3(x,y,z,'green');
                end
                hold on;

%                 z=-z;
% 
%                 DISTANCE_FROM_EARTH_CENTER_TO_SAT=(SAT_X^2+SAT_Y^2+SAT_Z^2)^.5;
%                 DISTANCE_FROM_EARTH_CENTER_TO_SUN=(SUN_X^2+SUN_Y^2+SUN_Z^2)^.5;
% 
%                 MAX_SUN_ANGLE=acos(EARTH_RADIUS/DISTANCE_FROM_EARTH_CENTER_TO_SAT);
%                 MAX_SAT_ANGLE=acos(EARTH_RADIUS/DISTANCE_FROM_EARTH_CENTER_TO_SUN);
% 
%                 MAX_DISTANCE_TO_SATELLITE=DISTANCE_FROM_EARTH_CENTER_TO_SAT*sin(MAX_SUN_ANGLE);
%                 MAX_DISTANCE_TO_SUN=DISTANCE_FROM_EARTH_CENTER_TO_SUN*sin(MAX_SAT_ANGLE);
% 
%                 ACTUAL_DISTANCE_TO_SATELLITE=((x-SAT_X)^2+(y-SAT_Y)^2+(z-SAT_Z)^2)^.5;
%                 ACTUAL_DISTANCE_TO_SUN=((x-SUN_X)^2+(y-SUN_Y)^2+(z-SUN_Z)^2)^.5;
% 
%                 if ACTUAL_DISTANCE_TO_SATELLITE<MAX_DISTANCE_TO_SATELLITE && ACTUAL_DISTANCE_TO_SUN<MAX_DISTANCE_TO_SUN
%                     %visible to both satellite and the sun.
%                     scatter3(x,y,z,'red');   
%                 elseif ACTUAL_DISTANCE_TO_SATELLITE<MAX_DISTANCE_TO_SATELLITE %only visible to the satellite.
%                     scatter3(x,y,z,'black');
%                 elseif ACTUAL_DISTANCE_TO_SUN<MAX_DISTANCE_TO_SUN % only visible to the sun.
%                     scatter3(x,y,z,'yellow');
%                 else % not visible to the sun or the satellite
%                     scatter3(x,y,z,'green');
%                 end
%                 hold on;

            end
        end

        tline = fgets(fileID);
        xlabel('x (meters)');
        ylabel('y (meters)');
        zlabel('z (meters)');

        saveas( gcf, int2str(strcat(imageNameCounter,'nonrotated')), 'jpg' );
        imageNameCounter=imageNameCounter+1;
        pause(2);

        close all;
    end
end

function [SAT_X0,SAT_Y0,SAT_Z0,SUN_X0,SUN_Y0,SUN_Z0]=adjustSunAndSatPositions(SAT_X,SAT_Y,SAT_Z,SUN_X,SUN_Y,SUN_Z)

    %taking the cross product. %TODO CHECK ALL THIS MATH THOROUGHLY.......
    u = (SAT_Y*1)-(0*SAT_Z);
    v = -(SAT_X*1)+(0*SAT_Z);
    w = (SAT_X*0)-(SAT_Y*0);
    
    %now calculate the angle...
    
    MAG_1=(SAT_X^2 + SAT_Y^2  + SAT_Z^2) ^.5;
    MAG_2=1;
    DOT_PROD=SAT_X*0+SAT_Y*0+SAT_Z*1;
    angle=acos(DOT_PROD/(MAG_1*MAG_2));
    
    %   Before we run our simulation, we need to reorient our axes.
    %   We're going to rotate our axes to make the new frame...
    %   We must therefore construct a rotation matrix.
    
    %new axes directions expressed in the old reference frame:
    new_z=[SAT_X,SAT_Y,SAT_Z]
    new_z=norm(new_z)
    
    little_x
    
    

end


