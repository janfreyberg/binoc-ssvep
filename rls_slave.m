function [estimate, amplitude] = rls_slave(cfg, data)
	%constants & defaults
	kRlsDelta		= 100.0;
	kRlsInvDelta	= 1.0 / kRlsDelta;
	defRLSWeights	= struct( 'fWR1', 0, 'fWR2', 0, 'fP1', kRlsInvDelta, 'fP2', kRlsInvDelta);
    
	% set trial parameters
    
    trialLen = size(data, 2);
    
	period		= trialLen / cfg.n_cycles; % period of the signal in samples
    
	priodsPerBin = 15; % what exactly is this bin??
    
	binLen = period * priodsPerBin;
    
	invLambda = 1 / optimalLambda( binLen);
    
    
    stdSin = sin( linspace(0, cfg.n_cycles*2*pi, trialLen) );
    stdCos = cos( linspace(0, cfg.n_cycles*2*pi, trialLen) );
    estimate = zeros(size(data));
	
% 	figure(2);
% 	clf(2);
% 	hold on;
    
	for iChan = cfg.channel;
		rlsWeights	= defRLSWeights; % reset rslWeights for each channel
        
		channel = data(cfg.channel, :);
        
        for n = 1 : trialLen
			rawValue	= channel(n);
			estimate(iChan, n) = RLS( invLambda, rawValue, stdCos(n), stdSin(n));
            amplitude(iChan, n) = sqrt(rlsWeights.fWR1^2 + rlsWeights.fWR2^2);
        end
        
% 		plot( channel(1:trialLen), 'Color', [0.8, 0.8, 1]);
% 		plot( estimate(iChan, 1:trialLen), 'm');
%         plot( amplitude(iChan, 1:trialLen), 'g');
% 		legend( 'signal', 'RLS estimate');
	end
% 	hold off;
	
%	Perform one step of the RLS algorithm, returning the modified Raw value.
%	Note the function modifies the global rlsWeights, "adapting" them to
%	the estimated signal
	function	rawValue = RLS( invLambda, rawValue, stdCos, stdSin)
		k01 = rlsWeights.fP1 * stdCos * invLambda;
		k02 = rlsWeights.fP2 * stdSin * invLambda;
		mu	= 1.0 / ( 1.0 + ( k01 * stdCos + k02 * stdSin));
		k11 = mu * k01;
		k12 = mu * k02;

		rlsWeights.fP1	= ( rlsWeights.fP1 * invLambda) - ( k11 * k01);
		rlsWeights.fP2	= ( rlsWeights.fP2 * invLambda) - ( k12 * k02);

		e0	= rawValue - (	rlsWeights.fWR1 * stdCos + rlsWeights.fWR2 * stdSin	);
		rlsWeights.fWR1 = rlsWeights.fWR1 + e0 * k11;
		rlsWeights.fWR2 = rlsWeights.fWR2 + e0 * k12;

		rawValue = rawValue - (mu * e0);
	end

	function lambda = optimalLambda( binLen)
		lambda = binLen / ( binLen + 1);	
    end

	end