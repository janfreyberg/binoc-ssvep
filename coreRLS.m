function coreRLS( varargin )
	%constants & defaults
	kRlsDelta		= 100.0;
	kRlsInvDelta	= 1.0 / kRlsDelta;
	defRLSWeights	= struct( 'fWR1', 0, 'fWR2', 0, 'fP1', kRlsInvDelta, 'fP2', kRlsInvDelta);
    
	% set trial parameters
	nmbChannels = 1;
	period		= 56;	% period of the signal in samples 
	priodsPerBin= 9;
	binLen		= period * priodsPerBin;
	nmbBins		= 7;
	trialLen	= nmbBins * binLen;
	invLambda	= 1 / optimalLambda( binLen);

	stdSin			= sin( linspace(0, 2* pi * trialLen / period, trialLen));
	stdCos			= cos( linspace(0, 2* pi * trialLen / period, trialLen));
    
	modulation		= sin( linspace(0, 2* pi * trialLen / (20 * period), trialLen)) + 10;
	
	figure(2);
	clf(2);
	hold on;

	for iChan = 1 : nmbChannels
		rlsWeights	= defRLSWeights;
		channel		= stdSin .* modulation;	% amplitude-modulated sin
% 		channel		= stdSin * 5;
        channel = channel + rand(size(channel)) * 1 - 0.5;
        channel = circshift(channel, round(period/4), 2);
		estimate	= zeros( trialLen,1);
		for n = 1 : trialLen
			rawValue	= channel(n);
			estimate(n) = RLS( invLambda, rawValue, stdCos(n), stdSin(n));
		end
		plot( channel(1:trialLen), 'b');
		plot( modulation(1:trialLen), 'k');
		plot( estimate(1:trialLen), 'm');
		legend( 'signal', 'RLS estimate');
	end
	hold off;
	
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