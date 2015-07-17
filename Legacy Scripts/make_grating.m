function stimmat = make_grating(pxsize, cycles, contr, orient, luminance)

[x, y] = meshgrid(linspace(-cycles*pi, cycles*pi, pxsize));
        
        

% rings = cos(2*pi*sqrt(x.^2 + y.^2)/1.4 - pi/1.2);
% rings( sqrt(x.^2 + y.^2) < 0.5 ) = 1;
% rings( rings<0 ) = 0;


x2 = x * cosd(orient); y2 = y * sind(orient);
wave = luminance+ contr* luminance* cos((x2 + y2));

alpha = 255*Circle(pxsize/2);

stimmat = cat(3, wave, wave, wave, alpha);