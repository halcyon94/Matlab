% A skeleton BER script for a wireless link simulation
% Illustrates how to simulate modulation and compare it to a theoretical
% BER
clear all;close all;clc
% For the final version of this project, you must use these 3
% parameter. You will likely want to set numIter to 1 while you debug your
% link, and then increase it to get an average BER.
nSym = 999;    % The number of symbols per packet, made it 999 to make it work w/ 2/3s coderate
SNR_Vec = 0:1:15;
lenSNR = length(SNR_Vec);
numIter=500;

M = 2;        % The M-ary number, 2 corresponds to binary modulation
k = log2(M);
%chan = 1;          % No channel
chan = [1 .2 .4]; % Somewhat invertible channel impulse response, Moderate ISI
%chan = [0.227 0.460 0.688 0.460 0.227];   % Not so invertible, severe ISI

coderate=2/3;
trel=poly2trellis([5 4],[23 35 0; 0 5 13]); % Trellis

% Linear Equalizer
rls = lineareq(6, rls(0.999, 0.1));
rls.SigConst = qammod(0:M-1,M); % Signal Constellation of the M-ary QAM Modulator
rls.ResetBeforeFiltering = 0; % Maintain continuity between iterations
numSamplesPerSymbol=1;
trainlen=50;
%span = 10;        % Filter span in symbols
%rolloff = 0.9;   % Rolloff factor of filter
%rrcFilter = rcosdesign(rolloff, span, numSamplesPerSymbol);

tb = 16; % Traceback length
decdelay = 2*tb; % Decoder delay

% Create a vector to store the BER computed during each iteration
berVec = zeros(numIter, lenSNR);
for i = 1:numIter
    bits = randint(nSym*k*coderate,1,[0 1]);     % Generate random bits
    msg=bits;
    bits = convenc(bits,trel);
    syms=bi2de(reshape(bits,k,length(bits)/k).','left-msb');
    qamTx=qammod(syms,M,0,'gray');
    %txSignal = upfirdn(qamTx, rrcFilter, numSamplesPerSymbol, 1);
    txSignal = qamTx;
    %tx = qammod(msg,M);  % BPSK modulate the signal
    if isequal(chan,1)
        txChan = txSignal;
    else
        txChan = filter(chan,1,txSignal);  % Apply the channel.
    end
    
    for j = 1:lenSNR % one iteration of the simulation at each SNR Value

        txNoisy = awgn(txChan,SNR_Vec(j) + 10*log10(k*coderate)-10*log10(numSamplesPerSymbol),'measured'); % Add AWGN
        %rxFiltSignal = upfirdn(txNoisy,rrcFilter,1,numSamplesPerSymbol);   % Downsample and filter
        %rxFiltSignal = rxFiltSignal(span+1:end-span);                       % Account for delay
        %eqtx1 = equalize(rls,rxFiltSignal,qamTx(1:trainlen));
        eqtx1 = equalize(rls,txNoisy,qamTx(1:trainlen));
        rx = qamdemod(eqtx1,M,0,'gray'); % Demodulate
        rx1 = de2bi(rx,'left-msb'); % Map Symbols to Bits
        rx2 = reshape(rx1.',numel(rx1),1);
        rx3 = vitdec(rx2,trel,tb,'cont','hard'); % Decode.

        % Compute and store the BER for this iteration
        [zzz berVec(i,j)] = biterr(msg(1+trainlen:end-decdelay), rx3(decdelay+1+trainlen:end));  % We're interested in the BER, which is the 2nd output of BITERR

    end  % End SNR iteration
end  % End all iterations

berVec_avg = mean(berVec,1);
semilogy(SNR_Vec, berVec_avg)
if isequal(M,2)
   berTheory = berawgn(SNR_Vec,'psk',2,'nondiff'); %%binary psk with nondifferential decoding
else
    berTheory = berawgn(SNR_Vec,'qam',M);
end    
% Compute the theoretical BER for this scenario
hold on
semilogy(SNR_Vec,berTheory,'r')
legend('BER', 'Theoretical BER')