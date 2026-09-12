% timushenko Beam formulation Under UDL
% Material parameters

E = 210e9;         % Young's Modulus (Pa),  Steel
G = 80e9;          % Shear Modulus (Pa)
b = 0.05;          % Width of the beam (m)
t = 0.10;          % Height/Thickness of the beam (m)
I = b * t^3 / 12;  % Moment of Inertia (m^4)
A = b * t;         % Cross-sectional Area (m^2)
k = 5/6;           % shear correction factor
% nodes and element
L_Beam=1; % in (m)
No_element= 60;
No_node=No_element+1;
L_elem=L_Beam/No_element;
% load 
q_load= -10000 ; % N/m Unit(UDL)
% degree of Freedom per node=2
no_dof=No_node*2;

K_global = zeros(n_dof, n_dof);
F_global = zeros(n_dof, 1);

% Loop through each element, calculate Ke and fe, and assemble.
for i = 1:n_elements
    % Calculate element matrices
    [Ke, fe] = timoshenkoElement(E, I, G, A, k, L_elem, q_load);
    
    % Map local DOFs (1 to 4) to global DOFs (1 to 2*n_nodes)
    node1 = i;
    node2 = i + 1;
    
    % Global DOF indices: [v1, theta1, v2, theta2]
    dof_indices = [2*node1-1, 2*node1, 2*node2-1, 2*node2];
    
    % Assembly: Add element matrices/vectors to the global system
    K_global(dof_indices, dof_indices) = K_global(dof_indices, dof_indices) + Ke;
    F_global(dof_indices) = F_global(dof_indices) + fe;
end


  