function [out] = sheryan(p1,p2)
nSym = 994; % The number of symbols per packet, made it 999 to make it work w/ 2/3s coderate
SNR_Vec = 1:2:16;
lenSNR = length(SNR_Vec);
numIter=200; %numer of iterations to run
M = 16; % The M-ary number
k = log2(M);
numSamplesPerSymbol=1;
berVec = zeros(numIter, lenSNR); %2D matrix to store all calculated BERs
    %channels
    %chan = 1; % No channel
    chan = [1 .2 .4]; % Somewhat invertible channel impulse response, Moderate ISI
    %chan = [0.227 0.460 0.688 0.460 0.227]; % Not so invertible, severe ISI
%conv encoding
trel=poly2trellis([5 4],[23 35 0; 0 5 13]); % Trellis
coderate=6/7; %coderate for the convolutional encoding. lower code rate, more duplicacy, but less bits sent
%coderate=1;
tb = 6*k; % Traceback length
decdelay = 2*tb; % Decoder delay
    % Linear Equalizer

    rlsobj = dfe(p1,p2, rls(0.9999, 0.1));
    rlsobj.SigConst = qammod(0:M-1,M); % Signal Constellation of the M-ary QAM Modulator
    rlsobj.ResetBeforeFiltering = 0; % Maintain continuity between iterations
    trainlen=100;
for i = 1:numIter
    display(['iteration number ' num2str(i) '.'])
    bits = randi([0 1],nSym*k*coderate,1); % Generate random bits
    msg=bits;
    bits = convenc(bits,trel);
    syms=bi2de(reshape(bits,k,length(bits)/k).','left-msb');
    qamTx=qammod(syms,M,0,'gray');
    if isequal(chan,1)
        txChan = qamTx;
    else
        txChan = filter(chan,1,qamTx); % Apply the channel.
    end
    for j = 1:lenSNR % one iteration of the simulation at each SNR Value
        txNoisy = awgn(txChan,SNR_Vec(j) + 10*log10(k*coderate)-10*log10(numSamplesPerSymbol),'measured'); % Add AWGN
        eqtx1 = equalize(rlsobj,txNoisy,qamTx(1:trainlen));
        reset(rlsobj);
        rx = qamdemod(eqtx1,M,0,'gray'); % Demodulate
        rx1 = de2bi(rx,'left-msb'); % Map Symbols to Bits
        rx2 = reshape(rx1.',numel(rx1),1);
        rx3 = vitdec(rx2,trel,tb,'cont','hard'); % Decode.
        %rx3=rx2;
            %scatter plot
            %h = scatterplot(txNoisy,1,0,'g.');
            %hold on;
            %s2=scatterplot(eqtx1,1,0,'b.',h);
            %title('Received Signal, Before and After Filtering');
            %legend('Before Filtering','After Filtering');
            %axis([-5 5 -5 5]); % Set axis ranges
            %hold off;
        % Compute and store the BER for this iteration
        [zzz berVec(i,j)] = biterr(msg(1+k*trainlen:end-decdelay), rx3(1+k*trainlen+decdelay:end)); % We're interested in the BER, which is the 2nd output of BITERR
    end % End SNR iteration
end % End all iterations
berVec_avg = mean(berVec,1);
out=berVec_avg(1);
semilogy(SNR_Vec, berVec_avg,'*')
%if isequal(M,2)
%    berTheory = berawgn(SNR_Vec,'psk',2,'nondiff'); %%binary psk with nondifferential decoding
%else
%    berTheory = berawgn(SNR_Vec,'qam',M);
%end
% Compute the theoretical BER for this scenario
%hold on
%semilogy(SNR_Vec,berTheory,'r')
%legend('BER', 'Theoretical BER')
end
