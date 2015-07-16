%This program is meant to provide a graphical representation of what's
%going on in the C++ flux calculator.
%Made by David Jackson, Summer 2015

%assumes half angle for sun visibility, since sun is so far away.
function [unitVectMatrix,dFluxMatrix]=optimizedCalculation(SAT_VECT,SUN_VECT,albedo)
tic;
close all;
figure;
EARTH_RADIUS=6371000;
E_s=1360;
e=1-albedo;
M_b=E_s/4;

SUN_ORIGINAL_X=SUN_VECT(1,1);
SUN_ORIGINAL_Y=SUN_VECT(1,2);
SUN_ORIGINAL_Z=SUN_VECT(1,3);

SAT_X=SAT_VECT(1,1);
SAT_Y=SAT_VECT(1,2);
SAT_Z=SAT_VECT(1,3);

[SAT_X,SAT_Y,SAT_Z,SUN_X,SUN_Y,SUN_Z,R]=adjustSatAndSunPositions(SAT_X,SAT_Y,SAT_Z,SUN_ORIGINAL_X,SUN_ORIGINAL_Y,SUN_ORIGINAL_Z);

%Plotting sun to center of earth, for debugging...
P1 = [0,0,0];

P2 = [SUN_X,SUN_Y,SUN_Z]/100000;
P2=1.3*EARTH_RADIUS*P2/norm(P2);

% Their vertial concatenation is what you want
pts = [P1; P2];

% Because that's what line() wants to see
line(pts(:,1), pts(:,2), pts(:,3))
hold on;
% % Alternatively, you could use plot3:
% plot3(pts(:,1), pts(:,2), pts(:,3))

scatter3(SAT_X,SAT_Y,SAT_Z,'cyan');
hold on;
%%%%%End for debugging.

DISTANCE_FROM_EARTH_CENTER_TO_SAT=(SAT_X^2+SAT_Y^2+SAT_Z^2)^.5;

MAX_ALPHA=acos(EARTH_RADIUS/DISTANCE_FROM_EARTH_CENTER_TO_SAT);

NUM_STEPS_ALPHA=15;
NUM_STEPS_THETA=25;

ALPHA_INTERVAL=MAX_ALPHA/(NUM_STEPS_ALPHA);

%Preallocation, the maximum number of possible spots...
maxCounterValue=(NUM_STEPS_THETA+1)*(NUM_STEPS_ALPHA+1);
dFluxMatrix=zeros(maxCounterValue,1);
unitVectMatrix=zeros(maxCounterValue,3);

counter=0;

%%% Due to our transformation, we now know the sun, the satelite and x axis are all in the same place. We need to calculate the angle between the sun and the y axis.
%%% (let's call this angle kappa);
SUN_V=[SUN_X SUN_Y SUN_Z];
normal=[0 0 1]; %Bearing angle from axis of the satellite...

kappa=acos(dot(SUN_V,normal)/(norm(SUN_V)*norm(normal)));

%We can also determine a "minimum alpha" for our calculations
MIN_ALPHA=0;

%If the sun is below zero, we know the sun can't see the very top of the
%satellit visibility area; thus we can constrain our minimum alpha.
if SUN_Z<0
    MIN_ALPHA=kappa-pi/2;
end

if MIN_ALPHA==0 %Start at alpha interval and work our way outward...
    MIN_ALPHA=ALPHA_INTERVAL;
end

%Now we can use geometry to calculate how far around

[betaBool]=BETA_CHECK_PASSED(SUN_V,MAX_ALPHA); %Check it in the worst case...
if ~betaBool % if can't even see sun.
    dFluxMatrix=[];
    unitVectMatrix=[];
    disp('#################################################');
    disp('Sun and satellite have no common visibility area');
    disp('#################################################');
else
    for alpha=MIN_ALPHA:ALPHA_INTERVAL:MAX_ALPHA
        
        [betaBool]=BETA_CHECK_PASSED(SUN_V,alpha);
        if ~betaBool % if can't even see sun.
            dFluxMatrix=[];
            unitVectMatrix=[];
            continue;
        end
        
        %For every alpha, we can use our trigonometry calculations
        
        %We're just going to run over one side of the band for y=y && y=-y since the problem is symmetric the way we've set up the
        %axes.
        THETA_LOWER_BOUND=0;
        
        kappaCopy=kappa;
        if (kappaCopy>pi/2)
            kappaCopy=kappaCopy-pi/2;
        else
            kappaCopy=pi/2-kappaCopy;
        end
        [boolAllBandVisible]=allBandVisible(alpha,kappa);
        THETA_UPPER_BOUND=0;
        if (boolAllBandVisible)
            THETA_UPPER_BOUND=pi;
        else
            q=EARTH_RADIUS*cos(alpha);
            h=EARTH_RADIUS*(1-cos(alpha));
            
            d=q*sin(kappaCopy);
            
            zed=EARTH_RADIUS*sin(alpha);
            
            sci=acos(d/zed);
            
            if SUN_Z<0
                lambda=sci;
            else
                lambda=pi-sci;
            end
            
            THETA_UPPER_BOUND=lambda;
        end
        
        if (SUN_X<0)
            THETA_LOWER_BOUND=THETA_LOWER_BOUND+pi;
            THETA_UPPER_BOUND=THETA_UPPER_BOUND+pi;
        end
        
        THETA_INTERVAL=(THETA_UPPER_BOUND-THETA_LOWER_BOUND)/NUM_STEPS_THETA;
        
        for theta=THETA_LOWER_BOUND:THETA_INTERVAL:(THETA_UPPER_BOUND-THETA_INTERVAL)
            
            x=EARTH_RADIUS*sin(alpha)*cos(theta);
            y=EARTH_RADIUS*sin(alpha)*sin(theta);
            z=EARTH_RADIUS*cos(alpha);
            
            for (i=1:-2:-1) %little hack just sets x=x and x=-x (since we're dealing with a symmetric problem).
                if (i==-1 && y==0) %dont double count the x=0 (reflected is equivalent)
                    continue;
                end
                
                y=i*y;
                
                scatter3(x,y,z,'red'); % TODO DELETE IN FINAL VERSION...
                hold on;
                
                %find the unit vector from earth element to satellite
                earthElementToSatVect=[SAT_X-x,SAT_Y-y,SAT_Z-z];
                unitElementToSatVect=earthElementToSatVect/norm(earthElementToSatVect);
                Rtrans=transpose(R);
                unitElementToSatVect=unitElementToSatVect*Rtrans;
                
                %Calculate flux
                r = ( (x-SAT_X)^2 + (y-SAT_Y)^2 + (z-SAT_Z)^2 )^.5;  %distance between area element and the satellite.
                
                areaEarthElement=EARTH_RADIUS^2*sin(alpha)*THETA_INTERVAL*ALPHA_INTERVAL;
                
                a=[x,y,z]; %vector normal to earth element.
                b=[SUN_X-x,SUN_Y-y,SUN_Z-z]; % vector from earth element to sun
                
                sunAngle=acos(dot(a,b)/(norm(a)*norm(b))); %angle between a and b
                
                dflux=(albedo*E_s*cos(sunAngle)+e*M_b)/(pi*r^2)*cos(alpha)*areaEarthElement; %flux calculation, value in watts/m^2
                
                if dflux>0 %~dflux==0
                    counter=counter+1;
                    unitVectMatrix(counter,1)=unitElementToSatVect(1,1);
                    unitVectMatrix(counter,2)=unitElementToSatVect(1,2);
                    unitVectMatrix(counter,3)=unitElementToSatVect(1,3);
                    
                    dFluxMatrix(counter,1)=dflux;
                end
            end
        end
    end
    
    %Eliminate extra rows:
    unitVectMatrix = unitVectMatrix(1:counter,1:3);
    dFluxMatrix=sparse(dFluxMatrix);
    
    %as a check, let's calculate dflux. We can check this against our other
    %program,
    %TODO DELETE Netflux calculation in final version of program.
    disp('**************')
    disp('NET FLUX:')
    NET_FLUX=sum(dFluxMatrix);
    disp(NET_FLUX);
    disp('**************')
    toc
    
    xlabel('x axis');
    ylabel('y axis');
    zlabel('z axis');
    
end

%%%%%%BETEWEEN THESE LINES IS VERIFICATION CODE:
DISTANCE_FROM_EARTH_CENTER_TO_SUN=(SUN_X^2+SUN_Y^2+SUN_Z^2)^.5;
MAX_SUN_ANGLE=acos(EARTH_RADIUS/DISTANCE_FROM_EARTH_CENTER_TO_SUN);
MAX_DISTANCE_TO_SUN=DISTANCE_FROM_EARTH_CENTER_TO_SUN*sin(MAX_SUN_ANGLE);
for alpha=0:.1:pi
    for theta=0:.1:2*pi
        x=EARTH_RADIUS*sin(alpha)*cos(theta);
        y=EARTH_RADIUS*sin(alpha)*sin(theta);
        z=EARTH_RADIUS*cos(alpha);
        ACTUAL_DISTANCE_TO_SUN=((x-SUN_X)^2+(y-SUN_Y)^2+(z-SUN_Z)^2)^.5;
        if ACTUAL_DISTANCE_TO_SUN<MAX_DISTANCE_TO_SUN % only visible to the sun.
            scatter3(x,y,z,'yellow');
        else % not visible to the sun or the satellite
            scatter3(x,y,z,'green');
        end
        hold on;
    end
end

%%%%%%%%%%%%

end

%adjusts the coordinate system so the sun and the satellite are in the same
%plane...
function [SAT_X0,SAT_Y0,SAT_Z0,SUN_X0,SUN_Y0,SUN_Z0,R]=adjustSatAndSunPositions(SAT_X,SAT_Y,SAT_Z,SUN_X,SUN_Y,SUN_Z)
SUN_VECTOR=[SUN_X,SUN_Y,SUN_Z];
a=SUN_VECTOR;

new_z=[SAT_X,SAT_Y,SAT_Z];
new_z=new_z/norm(new_z);
b=new_z;

angle=acos(dot(a,b)/(norm(a)*norm(b)));
if (angle==0 || angle==pi) % Satellite and sun already on vertical; no need to rotate...
    SHOULD_FLIP_SUN=false;
    
    %Find the magnitude of the satellit vector
    
    MAG_SAT_VECTOR=norm([SAT_X,SAT_Y,SAT_Z]);
    
    SAT_X0=0;
    SAT_Y0=0;
    SAT_Z0=MAG_SAT_VECTOR;
    
    MAG_SUN_VECTOR=norm([SUN_X SUN_Y SUN_Z]);
    
    SUN_X0=0;
    SUN_Y0=0;
    
    if angle==pi
        SUN_Z0=-MAG_SUN_VECTOR;
    else
        SUN_Z0=MAG_SUN_VECTOR;
    end
    
    R=[1,0,0;0,1,0;0,0,1]; % return Indentity matrix, since we require that this function return a rotation matrix.
    
else % We do the transformation
    
    %In this fashion we ensure that the axis which we use for positive x is always
    %pointed in the right direction...
    if SUN_Y>0
        new_y=cross(new_z,SUN_VECTOR);
    else
        new_y=cross(SUN_VECTOR,new_z);
    end
    
    new_y=new_y/norm(new_y);
    
    new_x=[];
    new_x=cross(new_y,new_z);
    new_x=new_x/norm(new_x);
    
    R=[new_x;new_y;new_z];
    
    SUN_NEW_VECTOR=R*[SUN_X;SUN_Y;SUN_Z];
    SUN_X0=SUN_NEW_VECTOR(1,1);
    SUN_Y0=SUN_NEW_VECTOR(2,1);
    SUN_Z0=SUN_NEW_VECTOR(3,1);
    
    SAT_OLD=[SAT_X;SAT_Y;SAT_Z];
    SAT_NEW_VECTOR=R*SAT_OLD;
    SAT_X0=SAT_NEW_VECTOR(1,1);
    SAT_Y0=SAT_NEW_VECTOR(2,1);
    SAT_Z0=SAT_NEW_VECTOR(3,1);
end
end

%Beta angle provides a limit on where the sun can be to contribute light...
function [boolBetaCheckPassed]=BETA_CHECK_PASSED(SUN_VECT,alpha)
boolBetaCheckPassed=true;
SUN_Z=SUN_VECT(1,3);
if SUN_Z<0
    if (SUN_VECT(1,2)<0) % If y is less than zero, flip y.
        SUN_VECT(1,2)=abs(SUN_VECT(1,2))
    end
    N_0=[0 0 1];
    angle=returnAngleBetweenVectors(N_0,SUN_VECT);
    if angle-pi/2>alpha % can't see the sun
        boolBetaCheckPassed=false;
    end
end
end

%This function returns true if all of a band can see the sun...
function [boolAllBandVisible]=allBandVisible(alpha,sunAngleToPolar)
boolAllBandVisible=(sunAngleToPolar<pi/2-alpha);
end

function [angle]=returnAngleBetweenVectors(a,b)
angle=acos(dot(a,b)/(norm(a)*norm(b)));
end

