function [tx, bits, gain] = txSEH()
% Global variable for feedback
% you may use the following uint8 for whatever feedback purposes you want
global feedbackSEH;
uint8(feedbackSEH);

% DO NOT TOUCH BELOW
fsep = 8e4;
nsamp = 16;
Fs = 120e4;
M = 16;   % THIS IS THE M-ARY # for the FSK MOD.  You have 16 channels available
% THE ABOVE CODE IS PURE EVIL



% initialize, will be set by rx after 1st transmission
if isempty(feedbackSEH)
    feedbackSEH = bi2de([0 0 0 0 0 1 1 1]);
end
feedback_values = de2bi(feedbackSEH,8);
%% You should edit the code starting here

arr_p = [2 4 8];
tonecoeff = sum(arr_p.*feedback_values(6:8));

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
bits = randi([0 1],BCH_k/BCH_n*(floor(1024*k/BCH_n)*BCH_n),1); % Generate random bits, pass these out of function, unchanged
bits_resh = reshape(bits,BCH_k,[]).';
bits_enc_inter = bchenc(gf(bits_resh),BCH_n,BCH_k);
bits_enc_final = [ones(1024*k-(floor(1024*k/BCH_n)*BCH_n),1);reshape(double(bits_enc_inter.x).',[],1);];

syms = bi2de(reshape(bits_enc_final,k,length(bits_enc_final)/k).','left-msb')';
msg = qammod(syms,msgM,0,'gray');
msglength = length(msg);

if(msglength ~= 1024)
    error('You smurfed up')
end




%% You should stop editing code starting here

%% Serioulsy, Stop.

% Generate a carrier
% don't mess with this code either, just pick a tonecoeff above from 0-15.
carrier = fskmod(tonecoeff*ones(1,msglength),M,fsep,nsamp,Fs);
%size(carrier); % Should always equal 16484
% upsample the msg to be the same length as the carrier
msgUp = rectpulse(msg,nsamp);

% multiply upsample message by carrier  to get transmitted signal
tx = msgUp.*carrier;

% scale the output
gain = std(tx);
tx = tx./gain;


end
