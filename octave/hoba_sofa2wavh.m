function hoba_sofa2wavh(SOFAfile,nbits,wavefile)

%------Parse inputs:--------
%error(nargchk(1,2,nargin));
if nargin < 1
    % test
    %SOFAfile = './examples/CIPIC_subject_003_hrir_final.sofa';
    SOFAfile = './examples/LISTEN_irc_1002.sofa';
    nbits = 16;
    %wavefile = './examples/CIPIC_subject_003_hrir_final.wav';
    wavefile = './examples/LISTEN_irc_1002.wav';
elseif nargin < 2
    nbits = 16;
    wavefile = './examples/convertion.wave';
end

%------Start SOFA------
cd './sofa/API_MO/'
SOFAstart;
cd '../../';;
%----------------------

%% Lfoading the full object
disp(['Loading full object: ' SOFAfile]);
tic;
ObjFull=SOFAload(SOFAfile);
disp(['  Elapsed time: ' num2str(toc) ' s.']);
x=whos('ObjFull');
disp(['  Memory requirements: ' num2str(round(x.bytes/1024)) ' kb']);

%% Determine number of bytes in chunks
% (not including pad bytes, if needed):
% ----------------------------------
%  id 'RIFF'        4 bytes
%  size             4 bytes  (of 'RIFF' chunck)
%  'WAVE'           4 bytes  Form Type
%  id 'fmt '        4 bytes
%  size             4 bytes  (of 'fmt ' chunck)
% <wave-format>     14 bytes
% <format_specific> 2 bytes (PCM)
%  id 'LIST'        4 bytes  (of 'list' chunck)
%  size             4 bytes 
%  'HRIR'           4 bytes  List Type
% <list of info and data chuncks>
%  id: 'info'       4 bytes     (sub chuncks)
%  size             4 bytes     (of 'info' chunck)
%       azimuth          4 byte
%       elevation        4 byte      
%       distance         4 byte
%       delayL           4 byte
%       delayR           4 byte
%  id: 'data'       4 bytes     (sub chuncks)
%    size           4 bytes     (of 'data' chunck)
%       <wave-data>       N bytes
% ----------------------------------

channels = 2;
Fs = ObjFull.Data.SamplingRate;
bytes_per_sample = ceil(nbits/8);

fmt_cksize   = 16;               % Don't include 'fmt ' or its size field
hinfo_cksize = 20;               % Don't include 'info' or its size field

%list_cksize = 4 + 8 + fmt_cksize;
list_cksize = 4;            % Don't include 'LIST' or its size field

hdata_cksize = zeros(1,size(ObjFull.SourcePosition,1)); 
for ii = 1:size(ObjFull.SourcePosition,1)
%ii = 1;
    samplesL = squeeze(ObjFull.Data.IR(ii,1,:)); % check L channel
    samplesR = squeeze(ObjFull.Data.IR(ii,2,:)); % check R channel
    hdata_samples = size(samplesL,1) + size(samplesR,1);
    hdata_cksize(ii) = hdata_samples * bytes_per_sample;
    list_cksize = list_cksize + 8 + hinfo_cksize + 8 + hdata_cksize(ii);
end
riff_cksize = 4 + 8 + fmt_cksize + ...  % Don't include 'RIFF' or its size field                      
                      list_cksize;

% Determine pad bytes:
list_pad    = rem(list_cksize,2);
riff_cksize = riff_cksize + list_pad; % + fmt_pad, always 0

%% Open file for output:
fid = OpenWaveWrite(wavefile);

%% Write
% file is now open, wrap the rest of the calls
% in a try catch so we can close the file if there is a failure
try
    % Prepare basic chunk structure fields:
    ck=[]; ck.fid=fid; ck.filename = wavefile;

    % Write RIFF chunk:
    ck.ID   = 'RIFF';
    ck.Size = riff_cksize;
    write_ckinfo(ck);

    % Write WAVE subchunk:
    ck.ID   = 'WAVE';
    ck.Size = [];  % Indicate a subchunk (no chunk size)
    write_ckinfo(ck);

    % Write <fmt-ck>:
    ck.ID   = 'fmt ';
    ck.Size = fmt_cksize;
    write_ckinfo(ck);
    
    % Write <wave-format>:
    fmt.filename        = wavefile;
    if nbits == 32,
        fmt.wFormatTag  = 3;            % Data encoding format (1=PCM, 3=Type 3 32-bit)
    else
        fmt.wFormatTag  = 1;
    end
    fmt.nChannels       = channels;                      % Number of channels
    fmt.nSamplesPerSec  = Fs;                            % Samples per secnd
    fmt.nAvgBytesPerSec = channels*bytes_per_sample*Fs;  % Avg transfer rate
    fmt.nBlockAlign     = channels*bytes_per_sample;     % Block alignment
    fmt.nBitsPerSample  = nbits;                         % standard <PCM-format-specific> info
    write_wavefmt(fid,fmt);
      
    ck.ID   = 'LIST';
    ck.Size = list_cksize;
    write_ckinfo(ck);
        
    ck.ID   = 'HRIR';
    ck.Size = [];  % Indicate a subchunk (no chunk size)
    write_ckinfo(ck);
      
    for ii = 1:size(ObjFull.SourcePosition,1)
         %ii = 1;
            
            % Write <info-ck>:
            ck.ID   = 'info';
            ck.Size = hinfo_cksize;
            write_ckinfo(ck);
            
            % Write <hrir-info>:
            % Extract hrir info
            hinfo.filename  = wavefile;
            hinfo.azimuth   = ObjFull.SourcePosition(ii,1); %disp(['azimuth: ' num2str(hinfo.azimuth)]);
            hinfo.elevation = ObjFull.SourcePosition(ii,2); %disp(['elevation: ' num2str(hinfo.elevation)]);
            hinfo.distance  = ObjFull.SourcePosition(ii,3); %disp(['distance: ' num2str(hinfo.distance)]);      
            if ( isempty(ObjFull.Data.Delay) == 1 || ...
                 size(ObjFull.Data.Delay,1) ~= size(ObjFull.Data.IR,2) )
                hinfo.delayL    = 0;         
                hinfo.delayR    = 0;
            else
                hinfo.delayL    = ObjFull.Data.Delay(ii,1);         
                hinfo.delayR    = ObjFull.Data.Delay(ii,2);
            end
            write_hririnfo(fid,hinfo); 
            
            
            % Write <hrir-data>, and its pad byte if needed:
            % Extract hrir data
            hdata = squeeze(ObjFull.Data.IR(ii,:,:)); %check if it is coloumn-wise
            if ndims(hdata) > 2,
                error('Data array cannot be an N-D array.');
            end
            
            ck.ID   = 'data';
            ck.Size = hdata_cksize(ii);
            write_ckinfo(ck);
            write_hrirdata(fid,fmt,hdata); %hdata: stereo signal
    end
    % Close file:
    fclose(fid);
catch
    fclose(fid);
    rethrow(lasterror);
end
% end of wavwrite()


% ------------------------------------------------------------------------
% Private functions:
% ------------------------------------------------------------------------


% ------------------------------------------------------------------------
function [fid] = OpenWaveWrite(wavefile)
% OpenWaveWrite
%   Open WAV file for writing.
%   If filename does not contain an extension, add ".wav"

fid = [];
if ~ischar(wavefile),
   error('MATLAB:wavewrite:InvalidFileNameType', 'Wave file name must be a string.'); 
end
if isempty(findstr(wavefile,'.')),
  wavefile=[wavefile '.wav'];
end
% Open file, little-endian:
[fid,err] = fopen(wavefile,'wb','l');
if (fid == -1)
    error('MATLAB:wavewrite:unableToOpenFile', err );
end
return


% ------------------------------------------------------------------------
function write_ckinfo(ck)
% WRITE_CKINFO: Writes next RIFF chunk, but not the chunk data.
%   Assumes the following fields in ck:
%         .fid   File ID to an open file
%         .ID    4-character string chunk identifier
%         .Size  Size of chunk (empty if subchunk)
%
%
%   Expects an open FID pointing to first byte of chunk header,
%   and a chunk structure.
%   ck.fid, ck.ID, ck.Size, ck.Data

errMsg = ['Failed to write ' ck.ID ' chunk to WAVE file: ' ck.filename];
errMsgID = 'MATLAB:wavewrite:failedChunkInfoWrite';

if (fwrite(ck.fid, ck.ID, 'char') ~= 4),
   error(errmsgID,errmsg);
end

if ~isempty(ck.Size),
  % Write chunk size:
  if (fwrite(ck.fid, ck.Size, 'uint32') ~= 1),
     error(errMsgID, errMsg);
  end
end

return

% ------------------------------------------------------------------------
function write_wavefmt(fid, fmt)
% WRITE_WAVEFMT: Write WAVE format chunk.
%   Assumes fid points to the wave-format subchunk.
%   Requires chunk structure to be passed, indicating
%   the length of the chunk.

errMsg = ['Failed to write WAVE format chunk to file' fmt.filename];
errMsgID = 'MATLAB:wavewrite:failedWaveFmtWrite';

% Create <wave-format> data:
if (fwrite(fid, fmt.wFormatTag,      'uint16') ~= 1) | ...
   (fwrite(fid, fmt.nChannels,       'uint16') ~= 1) | ...
   (fwrite(fid, fmt.nSamplesPerSec,  'uint32' ) ~= 1) | ...
   (fwrite(fid, fmt.nAvgBytesPerSec, 'uint32' ) ~= 1) | ...
   (fwrite(fid, fmt.nBlockAlign,     'uint16') ~= 1),
   error(errMsgID,errMsg);
end

% Write format-specific info:
if fmt.wFormatTag==1 | fmt.wFormatTag==3,
  % Write standard <PCM-format-specific> info:
  if (fwrite(fid, fmt.nBitsPerSample, 'uint16') ~= 1),
     error(errMsgID,errMsg);
  end
  
else
  error('MATLAB:wavewrite:unknownDataFormat','Unknown data format.');
end

return


% -----------------------------------------------------------------------
function y = PCM_Quantize(x, fmt)
% PCM_Quantize:
%   Scale and quantize input data, from [-1, +1] range to
%   either an 8-, 16-, or 24-bit data range.

% Clip data to normalized range [-1,+1]:
ClipMsg  = ['Data clipped during write to file:' fmt.filename];
ClipMsgID = 'MATLAB:wavwrite:dataClipped';
ClipWarn = 0;

% Determine slope (m) and bias (b) for data scaling:
nbits = fmt.nBitsPerSample;
m = 2.^(nbits-1);

switch nbits
case 8,
   b=128;
case {16,24},
   b=0;
otherwise,
   error('MATLAB:wavwrite:invalidBitsPerSample','Invalid number of bits specified.');
end

y = round(m .* x + b);

% Determine quantized data limits, based on the
% presumed input data limits of [-1, +1]:
ylim = [-1 +1];
qlim = m * ylim + b;
qlim(2) = qlim(2)-1;

% Clip data to quantizer limits:
i = find(y < qlim(1));
if ~isempty(i),
   warning(ClipMsgID,ClipMsg); ClipWarn=1;
   y(i) = qlim(1);
end

i = find(y > qlim(2));
if ~isempty(i),
   if ~ClipWarn, warning(ClipMsgID,ClipMsg); end
   y(i) = qlim(2);
end

return

% ------------------------------------------------------------------------
function write_hririnfo(fid, hinfo)
% WRITE_WAVEFMT: Write WAVE format chunk.
%   Assumes fid points to the wave-format subchunk.
%   Requires chunk structure to be passed, indicating
%   the length of the chunk.

errMsg = ['Failed to write WAVE format chunk to file' hinfo.filename];
errMsgID = 'MATLAB:wavewrite:failedHrirInfoWrite';

% Create <wave-format> data:
if (fwrite(fid, hinfo.azimuth,      'float') ~= 1) | ...
   (fwrite(fid, hinfo.elevation,    'float') ~= 1) | ...
   (fwrite(fid, hinfo.distance,     'float' ) ~= 1) | ...
   (fwrite(fid, hinfo.delayL,       'float' ) ~= 1) | ...
   (fwrite(fid, hinfo.delayR,       'float') ~= 1),
   error(errMsgID,errMsg);
end

return

% -----------------------------------------------------------------------
function write_hrirdata(fid,fmt,data)
% WRITE_WAVEDAT: Write WAVE data chunk
%   Assumes fid points to the wave-data chunk
%   Requires <wave-format> structure to be passed.

if fmt.wFormatTag==1 | fmt.wFormatTag==3,
   % PCM Format
   
   % 32-bit Type 3 is normalized, so no scaling needed.
   if fmt.nBitsPerSample ~= 32,
       data = PCM_Quantize(data, fmt);
   end
   
   switch fmt.nBitsPerSample
   case 8,
      dtype='uchar'; % unsigned 8-bit
   case 16,
      dtype='int16'; % signed 16-bit
   case 24,
	  dtype='bit24'; % signed 24-bit
   case 32,
      dtype='float'; % normalized 32-bit floating point
   otherwise,
      error('MATLAB:wavewrite:invalidBitsPerSample','Invalid number of bits specified.');
   end
   
   % Write data, one row at a time (one sample from each channel):
   [samples,channels] = size(data);
   total_samples = samples*channels;
   
   if (fwrite(fid, reshape(data',total_samples,1), dtype) ~= total_samples),
      error('MATLAB:wavewrite:failedToWriteSamples','Failed to write PCM data samples.');
   end
   
   % Determine # bytes/sample - format requires rounding
   %  to next integer number of bytes:
   BytesPerSample = ceil(fmt.nBitsPerSample/8);
   
   % Determine if a pad-byte must be appended to data chunk:
   if rem(total_samples*BytesPerSample, 2) ~= 0,
      fwrite(fid,0,'uchar');
   end
   
else
  % Unknown wave-format for data.
  error('MATLAB:wavewrite:unsupportedDataFormat','Unsupported data format.');
end

return

% end of wavwrite.m
