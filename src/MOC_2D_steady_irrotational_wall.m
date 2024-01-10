function [xo,yo,uo,vo] = MOC_2D_steady_irrotational_wall ( xp,yp,up,vp,geom,params )
%
% This function computes the intersection of a left-running C+ characteristic
% with the wall. Output of the function is the position + data at the intersection on the wall.

   x_orig = xp ; y_orig = yp ; u_orig = up ; v_orig = vp ;
   
   step_current = 0;
   step_max = 50;
   eps_pos = 1.e-8;
   eps_vel = 1.e-5;
   
% Predictor step
% Used to provide a first estimation of the intersection of the characteristic with the wall
   [xo,yo,uo,vo] = MOC_2D_steady_irrotational_solve_wall ( xp,yp,up,vp,x_orig,y_orig,u_orig,v_orig,geom,params ) ;
   
   while 1
      step_current=step_current+1;
% Corrector step
      xcp = xp; ycp = 0.5*(yp+yo) ; ucp = 0.5*(up+uo) ; vcp = 0.5*(vp+vo) ;
     [xn,yn,un,vn] = MOC_2D_steady_irrotational_solve_wall ( xcp,ycp,ucp,vcp,x_orig,y_orig,u_orig,v_orig,geom,params ) ;
      error_pos = max( [ xo-xn , yo-yn ] );
      error_vel = max( [ uo-un , vo-vn ] );
      xo = xn ;      yo = yn ;
      uo = un ;      vo = vn ;
      % Check if we converged on the position and on the velocity components
      if (abs(error_pos)<eps_pos && abs(error_vel)<eps_vel)
        break;
      end
      if (step_current>step_max)
        error('The maximum of iterations for the predictor-corrector algorithm has been reached. Stopping the execution...')
      end
   end
   
end

function [xn,yn,un,vn] = MOC_2D_steady_irrotational_solve_wall ( xp,yp,up,vp,...
                                                                 x_orig,y_orig,u_orig,v_orig,...
                                                                 geom,params )
  
  V     = sqrt  ( up.^2 + vp.^2 ) ;
  a     = get_speed_sound( params, V ) ;
  theta = atand (vp./up) ;
  alpha = asind ( a./V ) ;
  lambda = tand ( theta + alpha ) ; % lambda+
  Q     = up.^2 - a.^2 ;
  R     = 2*up.*vp - Q.*lambda ;
  S     = geom.delta * a.^2 .* vp ./ yp ;
  
  % Get the coefficients a,b,c for the 2nd order poly for the wall
  [abcpoly,ywall,tangentwall] = MOC_2D_steady_irrotational_get_geometry(0.,1,geom) ;
  
% Solve the system matrix to get the position of the intersection of the C+ characteristic with the wall
  for i = 1:length(xp)
  % Right-running C+ characteristic
  % y4 - lambda+ * x4 = y_orig - lambda+ * x_orig
  % We get a second order equation a*x4^2 + b*x4 + c = 0
    a4    = abcpoly(1) - ( y_orig(i) - lambda.*x_orig(i) ) ;
    b4    = abcpoly(2) - lambda ;
    c4    = abcpoly(3) ;
    if (c4==0)
      xn(i) = -a4/b4 ; % Intersection between 2 lines
    else
      xn(i) = (-b4 - sqrt(b4.^2 - 4*a4.*c4))./(2*c4) ; % Intersection between line and quadratic curves
    end
    
    [abcpoly,yn(i),tangentwall] = MOC_2D_steady_irrotational_get_geometry(xn(i),2,geom) ;
    
    T     = S(i).*(xn(i)-x_orig(i)) + Q(i).*u_orig(i) + R(i).*v_orig(i) ;
    un(i) = T / ( Q(i) + R(i)*tangentwall ) ;
    vn(i) = un(i) * tangentwall ;
  end
  
end