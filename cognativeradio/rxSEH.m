function [numCorrect] = rxSEH(sig, bits, gain)
%% Receive input sig, compute BER relative to bits

% DO NOT TOUCH BELOW
fsep = 8e4;
nsamp = 16;
Fs = 120e4;
M = 16;
%M = 4; fsep = 8; nsamp = 8; Fs = 32;

% THE ABOVE CODE IS PURE EVIL

numCorrect = 0; % initialize the # of correct Rx bits
% Global variable for feedback
global feedbackSEH SNR_arr;
uint8(feedbackSEH);
feedback_values = de2bi(feedbackSEH,8);

% in this example, just using feedback to set the freq index
arr_p = [2 4 8];
tonecoeff = sum(arr_p.*feedback_values(6:8));

%% I don't recommend touching the code below
% Generate a carrier
carrier = fskmod(tonecoeff*ones(1,1024),M,fsep,nsamp,Fs);
rx = sig.*conj(carrier)*gain;
rx = intdump(rx,nsamp);
%% Recover your signal here

Mod_Bit_values = {[4 1003],[8 828],[16 698],[16 808],[16 873],[16 923],[16 973],[16 993],[16 1003],[64 708],[64 788],...
                  [64 838],[64 893],[64 933],[64 963],[64 983],[64 983],[64 1003],[64 1013],[64 1013],[64 1013]};
chan_values = {0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20};
           
ChanToMod = containers.Map(chan_values,Mod_Bit_values);

arr_p = [1 2 4 8 16];
chan_num = sum(arr_p.*feedback_values(1:5));
tot = ChanToMod(chan_num);
msgM = tot(1);
BCH_k = tot(2);

k = log2(msgM);

BCH_n = 1023;
rxMsg = qamdemod(rx,msgM,0,'gray');
rx1 = de2bi(rxMsg,'left-msb');
rx1_resh = reshape(rx1.',[],1);
rx1_bits = rx1_resh(1024*k-(floor(1024*k/BCH_n)*BCH_n)+1:end);
rx1_bits_dec = bchdec(gf(reshape(rx1_bits,BCH_n,[])).',BCH_n,BCH_k);
rx1_bits_final = reshape(double(rx1_bits_dec.x).',[],1);

%% Check the BER. If zero BER, output the # of correctly received bits.
ber = biterr(rx1_bits_final, bits);
if ber == 0
  %  disp('Sucessful frame User 1')
    numCorrect = length(bits);
else 
   % scatterplot(rx); 
end
%% SNR calculation
SNR_val = (round(-10*log10(abs(var(sig)-2))+1));
SNR_arr = [SNR_arr SNR_val];
SNR_val = mode(SNR_arr);
if SNR_val>20
    SNR_val = 20;
end
SNR_val
%% Check for overlap w/ opponent and evade 
%check1 = ones((1024*k-(floor(1024*k/BCH_n)*BCH_n)),1);
%check2 = rx1_resh(1:1024*k-(floor(1024*k/BCH_n)*BCH_n));
%if rx1_resh(1:1024*k-(floor(1024*k/BCH_n)*BCH_n)) ~= ones((1024*k-(floor(1024*k/BCH_n)*BCH_n)),1)
feedback_values([6:8]) = randi([0 1],1,3);
%    disp('yes overlap');
%end

%% Transmit new value for channel
SNR_values = {0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20};
chan_values = {[0 0 0 0 0],[1 0 0 0 0],[0 1 0 0 0],[1 1 0 0 0],[0 0 1 0 0],[1 0 1 0 0],[0 1 1 0 0],[1 1 1 0 0],[0 0 0 1 0],[1 0 0 1 0],[0 1 0 1 0],...
               [1 1 0 1 0],[0 0 1 1 0],[1 0 1 1 0],[0 1 1 1 0],[1 1 1 1 0],[0 0 0 0 1],[1 0 0 0 1],[0 1 0 0 1],[1 1 0 0 1],[0 0 1 0 1]};
           
SNRtoChan = containers.Map(SNR_values,chan_values);

feedback_values([1:5]) = SNRtoChan(SNR_val);
feedbackSEH = bi2de(feedback_values);

end
