function a = get_speed_sound(params,V)
% Speed of sound a� = a0�       - 0.5*(gamma-1)*V�
%                   = gamma*R*T - 0.5*(gamma-1)*V�
  a = sqrt ( params.gamma * params.R * params.T - ...
             0.5 * ( params.gamma - 1.) * V.^2 ) ;
end