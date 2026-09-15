clc
clear
close all

%% Open input file

fid = fopen('Job-2.inp','r');

%% Read complete file

C = textscan(fid,'%s','Delimiter','\n');
C = C{1};

fclose(fid);

%% Find *Node section

nodeStart = find(contains(C,'*Node'));

%% Find first section after nodes

nodeEnd = find(contains(C,'*Element'),1) - 1;

%% Extract node lines

nodeLines = C(nodeStart+1:nodeEnd);

%% Initialize node matrix

nodes = [];

%% Read node data

for i = 1:length(nodeLines)

    line = strtrim(nodeLines{i});

    vals = sscanf(line,'%f,');

    if length(vals) >= 3

        nodeNumber = vals(1);
        x = vals(2);
        y = vals(3);

        nodes = [nodes;
                 nodeNumber x y];
    end
end

%% Display first few nodes

disp(nodes(1:10,:))
%% Find OuterBoundary set

setStart = find(contains(C,'*Nset, nset=OuterBoundary'),1);

%% Read boundary node numbers

boundaryNodes = [];

i = setStart + 1;

while ~startsWith(strtrim(C{i}),'*')

    nums = sscanf(C{i},'%f,');

    boundaryNodes = [boundaryNodes; nums];

    i = i + 1;
end

%% Remove duplicates

boundaryNodes = unique(boundaryNodes);

%% Display

disp(boundaryNodes(1:20))
disp(length(boundaryNodes))
%% Extract boundary node coordinates

nodeBC = [];

for i = 1:length(boundaryNodes)

    n = boundaryNodes(i);

    idx = find(nodes(:,1)==n);

    nodeBC = [nodeBC;
              nodes(idx,:)];
end

%% Display first few rows

disp(nodeBC(1:10,:))
%% Crack tip coordinates

xTip = 0.5;
yTip = 0.0;

%% Material properties

E  = 210000;      % MPa
nu = 0.3;

%% Shear modulus

G = E/(2*(1+nu));

%% Plane strain parameter

kappa = 3 - 4*nu;

%% Stress intensity factor

K1 = 30;      % MPa*sqrt(mm)

%% Initialize

radius = zeros(length(nodeBC),1);
theta  = zeros(length(nodeBC),1);

%% Compute r and theta

for i = 1:length(nodeBC)

    x = nodeBC(i,2);
    y = nodeBC(i,3);

    dx = x - xTip;
    dy = y - yTip;

    radius(i) = sqrt(dx^2 + dy^2);

    theta(i) = atan2(dy,dx);
end

%% Display

disp(radius(1:10))
disp(theta(1:10))
%% Initialize displacement vectors

ux = zeros(length(nodeBC),1);
uy = zeros(length(nodeBC),1);

%% Compute displacement field

for i = 1:length(nodeBC)

    r = radius(i);
    th = theta(i);

    factor = (K1/(2*G))*sqrt(r/(2*pi));

    ux(i) = factor*cos(th/2)*(kappa - cos(th));

    uy(i) = factor*sin(th/2)*(kappa - cos(th));
end

%% Append to nodeBC matrix

nodeBC = [nodeBC radius theta ux uy];

%% Display

disp(nodeBC(1:10,:))
%% Create node_sets.inp

fid = fopen('node_sets.inp','w');

for i = 1:length(nodeBC)

    fprintf(fid,'*Nset, nset=NODESET-%d, instance=Part-1-1\n',i);
    fprintf(fid,'%d,\n',nodeBC(i,1));

end

fclose(fid);

disp('node_sets.inp created')
%% Create node_bc.inp

fid = fopen('node_bc.inp','w');

for i = 1:length(nodeBC)

    ux_val = nodeBC(i,6);
    uy_val = nodeBC(i,7);

    fprintf(fid,'** Name: BC-%d Type: Displacement/Rotation\n',i);

    fprintf(fid,'*Boundary\n');

    fprintf(fid,'NODESET-%d, 1, 1, %e\n',i,ux_val);

    fprintf(fid,'NODESET-%d, 2, 2, %e\n',i,uy_val);

end

fclose(fid);

disp('node_bc.inp created')