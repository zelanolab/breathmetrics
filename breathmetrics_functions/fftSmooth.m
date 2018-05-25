function y = fftSmooth(resp,srateCorrectedSmoothedWindow)

% create the window
L      = length(resp);
window = zeros(1,L);
window(floor((L-srateCorrectedSmoothedWindow+1)/2):floor((L+srateCorrectedSmoothedWindow)/2))=1;

% check the size of the input
if size(resp',2) == size(window,2),   resp = resp'; end

% zero phase low pass filtering
tmp = ifft(fft(resp).*fft(window)/srateCorrectedSmoothedWindow);
y = -1*ifft(fft(-1*tmp).*fft(window)/srateCorrectedSmoothedWindow);

% check if y is column vector
if size(y,1)< size(y,2), y = y';end
    
end